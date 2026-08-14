//
//  RadioArtwork.swift
//  RadioKit
//
//  Created by Leonid Frolov on 18.05.2023.
//

@preconcurrency import Foundation
import ImageIO
import MediaPlayer

#if canImport(UIKit)
  import UIKit
#elseif os(macOS)
  import Cocoa
#endif

/// Artwork loaded for a radio station or song.
@MainActor
@Observable public final class RadioArtwork: Equatable {
  /// The source URL of the artwork image.
  public let url: URL
  /// The dominant background color derived from the artwork image.
  public internal(set) var backgroundColor: CGColor?
  /// The color for primary text drawn over the artwork.
  public internal(set) var primaryTextColor: CGColor?
  /// The color for secondary text drawn over the artwork.
  public internal(set) var secondaryTextColor: CGColor?
  /// Whether the derived background color is dark.
  public internal(set) var isBackgroundDark: Bool?

  var image: PlatformImage?

  private static let maximumResponseSize = 8 * 1_024 * 1_024
  private static let maximumDimension = 4_096
  private static let maximumPixelCount = 16_777_216
  private static let cache = URLCache(
    memoryCapacity: 16 * 1_024 * 1_024,
    diskCapacity: 64 * 1_024 * 1_024
  )
  private static let sessionDelegate = ArtworkSessionDelegate()
  private static let session: URLSession = {
    let configuration = URLSessionConfiguration.default
    configuration.httpCookieStorage = nil
    configuration.httpShouldSetCookies = false
    configuration.urlCredentialStorage = nil
    configuration.urlCache = cache
    configuration.requestCachePolicy = .useProtocolCachePolicy
    configuration.timeoutIntervalForRequest = 30
    configuration.timeoutIntervalForResource = 60
    return URLSession(
      configuration: configuration,
      delegate: sessionDelegate,
      delegateQueue: nil
    )
  }()

  private var fetchTask: Task<Void, Never>?

  init(
    url: URL,
    backgroundColor: CGColor? = nil,
    primaryTextColor: CGColor? = nil,
    secondaryTextColor: CGColor? = nil
  ) {
    self.url = url
    self.primaryTextColor = primaryTextColor
    self.secondaryTextColor = secondaryTextColor

    let cached = cachedArtwork()
    self.image = cached?.image

    if let backgroundColor {
      self.backgroundColor = backgroundColor
      self.isBackgroundDark = backgroundColor.isDark
    }

    guard isAllowedArtworkURL(url) else {
      Log.error(Error.invalidURL.localizedDescription)
      return
    }

    self.fetchTask = Task { [weak self] in
      if let cachedImage = cached?.image, backgroundColor == nil {
        let cachedColor = await Self.averageColor(of: cachedImage)

        if let cachedColor, let self {
          self.backgroundColor = cachedColor
          self.isBackgroundDark = cachedColor.isDark
        }
      }

      do {
        guard
          let self,
          let currentImage = try await revalidatedImage(against: cached)
        else { return }

        self.image = currentImage

        if backgroundColor == nil,
          let newColor = await Self.averageColor(of: currentImage)
        {
          self.backgroundColor = newColor
          self.isBackgroundDark = newColor.isDark
        }
      } catch is CancellationError {
        return
      } catch {
        Log.error("Artwork loading failed: \(error.localizedDescription)")
      }
    }
  }

  isolated deinit {
    fetchTask?.cancel()
  }

  /// Returns whether two artwork values use the same source URL.
  /// - Parameters:
  ///   - lhs: The first artwork value to compare.
  ///   - rhs: The second artwork value to compare.
  /// - Returns: `true` if both values use the same source URL.
  public nonisolated static func == (lhs: RadioArtwork, rhs: RadioArtwork) -> Bool {
    lhs.url == rhs.url
  }

  @concurrent nonisolated static func averageColor(
    of image: PlatformImage
  ) async -> CGColor? {
    image.averageColor
  }
}

// MARK: - Cache and Loading

extension RadioArtwork {
  fileprivate struct CachedArtwork {
    let image: PlatformImage
    let data: Data
    let response: HTTPURLResponse

    var revalidationHeader: (field: String, value: String)? {
      guard
        response.value(forHTTPHeaderField: "Cache-Control") == nil,
        response.value(forHTTPHeaderField: "Expires") == nil
      else { return nil }

      if let tag = response.value(forHTTPHeaderField: "ETag") {
        return ("If-None-Match", tag)
      }

      if let modified = response.value(forHTTPHeaderField: "Last-Modified") {
        return ("If-Modified-Since", modified)
      }

      return nil
    }
  }

  fileprivate func cachedArtwork() -> CachedArtwork? {
    let request = URLRequest(url: url)
    guard
      isAllowedArtworkURL(url),
      let cached = Self.cache.cachedResponse(for: request),
      let response = cached.response as? HTTPURLResponse,
      cached.data.count <= Self.maximumResponseSize,
      let image = try? Self.decodeImage(from: cached.data)
    else {
      Self.cache.removeCachedResponse(for: request)
      return nil
    }

    return CachedArtwork(image: image, data: cached.data, response: response)
  }

  fileprivate func revalidatedImage(against cached: CachedArtwork?) async throws -> PlatformImage? {
    guard isAllowedArtworkURL(url) else {
      throw Error.invalidURL
    }

    var request = URLRequest(url: url)

    if let header = cached?.revalidationHeader {
      request.cachePolicy = .reloadIgnoringLocalCacheData
      request.setValue(header.value, forHTTPHeaderField: header.field)
    }

    let (bytes, response) = try await Self.session.bytes(for: request)
    guard
      let httpResponse = response as? HTTPURLResponse,
      isAllowedArtworkURL(httpResponse.url)
    else {
      throw Error.invalidServerResponse
    }

    guard httpResponse.statusCode != 304 else { return nil }
    guard httpResponse.statusCode == 200 else {
      throw Error.invalidServerResponse
    }

    let expectedLength = httpResponse.expectedContentLength
    guard expectedLength < 0 || expectedLength <= Self.maximumResponseSize else {
      throw Error.responseTooLarge
    }

    var data = Data()
    if expectedLength > 0 {
      data.reserveCapacity(Int(expectedLength))
    }

    for try await byte in bytes {
      try Task.checkCancellation()
      guard data.count < Self.maximumResponseSize else {
        throw Error.responseTooLarge
      }
      data.append(byte)
    }

    guard data != cached?.data else { return nil }
    return try Self.decodeImage(from: data)
  }

  fileprivate static func decodeImage(from data: Data) throws -> PlatformImage {
    guard data.count <= maximumResponseSize else {
      throw Error.responseTooLarge
    }

    guard
      let source = CGImageSourceCreateWithData(data as CFData, nil),
      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
        as? [CFString: Any],
      let width = (properties[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue,
      let height = (properties[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue
    else {
      throw Error.unsupportedImageType
    }

    guard
      width > 0,
      height > 0,
      width <= maximumDimension,
      height <= maximumDimension,
      width <= maximumPixelCount / height
    else {
      throw Error.imageDimensionsTooLarge
    }

    guard let image = PlatformImage(data: data) else {
      throw Error.unsupportedImageType
    }

    return image
  }
}

private final class ArtworkSessionDelegate: NSObject, URLSessionTaskDelegate {
  nonisolated func urlSession(
    _ session: URLSession,
    task: URLSessionTask,
    willPerformHTTPRedirection response: HTTPURLResponse,
    newRequest request: URLRequest,
    completionHandler: @escaping (URLRequest?) -> Void
  ) {
    completionHandler(isAllowedArtworkURL(request.url) ? request : nil)
  }
}

private func isAllowedArtworkURL(_ url: URL?) -> Bool {
  guard
    let url,
    let scheme = url.scheme?.lowercased(),
    scheme == "http" || scheme == "https"
  else { return false }

  return url.user == nil && url.password == nil
}

// MARK: - Errors

extension RadioArtwork {
  enum Error: LocalizedError {
    case invalidURL
    case invalidServerResponse
    case responseTooLarge
    case imageDimensionsTooLarge
    case unsupportedImageType

    var errorDescription: String? {
      switch self {
      case .invalidURL: "The artwork URL is not allowed"
      case .invalidServerResponse: "The artwork server response is invalid"
      case .responseTooLarge: "The artwork response exceeds the size limit"
      case .imageDimensionsTooLarge: "The artwork dimensions exceed the pixel limit"
      case .unsupportedImageType: "The artwork image type is not supported"
      }
    }
  }
}
