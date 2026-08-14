# Metadata And Artwork

Use timed stream metadata and bounded remote artwork.

## Timed Metadata

RadioKit attaches an `AVPlayerItemMetadataOutput` to each player item.
The output accepts metadata formats that `AVPlayer` exposes, including common ICY timed metadata.

``RadioPlayer/rawMetadata`` contains the last unparsed string.
RadioKit creates ``RadioSong`` only when that string contains `Artist - Title`.
It splits at the first separator and preserves later separators in the title.

When parsing fails, `rawMetadata` remains available and ``RadioPlayer/songMetadata`` becomes `nil`.

## Apple Music Enrichment

When Apple Music access is authorized, ``RadioSong`` searches the catalog with its artist and title.
It uses the first result as ``RadioSong/fullMetadata`` and adopts that result's artwork when available.

The first result is not a verified identity match.
It can refer to another recording or another song with similar text.

Without authorization, parsed artist and title values remain available.
The host app owns the MusicKit capability, usage description, and authorization request.

## Artwork Loading

Station artwork comes from ``RadioStation/artworkURL``.
Song artwork can replace station artwork after Apple Music enrichment.
``RadioPlayer/artwork`` always exposes the current choice.

``RadioArtwork`` accepts HTTP and HTTPS URLs without embedded user credentials.
Redirects must meet the same rule.
The host app's App Transport Security and local-network policy still apply.

The loader enforces these limits before it creates a platform image:

- 8 MiB for the response body.
- 4096 pixels for width or height.
- 16,777,216 total pixels.

The artwork object publishes its average background color and suggested text colors through Observation.
Network or decode failures leave the image unavailable and do not stop audio playback.
