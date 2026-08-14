# Privacy And Security

Understand network access, local storage, and the host application's responsibilities.

## Network Access

RadioKit can make these outbound requests:

- `AVPlayer` requests the selected live stream.
- The artwork loader requests station or song images.
- MusicKit requests catalog data after the user authorizes Apple Music access.

The package does not include an analytics SDK or a third-party package dependency.
Stream and artwork providers can still receive normal network request information.

Artwork URLs must use HTTP or HTTPS and cannot include a user name or password.
RadioKit does not block private-network addresses.
The host app must apply the required App Transport Security, local-network, and endpoint policies.

The artwork session disables cookie storage and credential storage.
It also limits response size and decoded image dimensions.
See <doc:MetadataAndArtwork> for the exact limits.

## Local Storage

``RadioPlayer/volume`` persists in standard `UserDefaults`.
An attached ``RadioGroupSynchronizer`` writes the last station and playing flag to its configured App Group suite.

The package privacy manifest declares the `UserDefaults` required-reason API category.
It includes reason codes `CA92.1`, `1C8F.1`, and `C56D.1`.

The host app must include RadioKit behavior in its own privacy review and store disclosures.
The package manifest does not replace the host app's declarations.

## Untrusted Endpoints

Treat station and artwork URLs as untrusted input.
Do not embed credentials in either URL.
Do not ship private endpoint details in logs, tests, issue reports, or demo data.

The host app owns the station catalog and the legal right to access each endpoint.
RadioKit's MIT License does not grant rights to stream audio, artwork, service names, or trademarks.
