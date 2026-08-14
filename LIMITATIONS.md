# Limitations

- RadioKit supports iOS 17 or later and macOS 14 or later. It does not support Linux, Windows, or non-Apple runtimes.
- Live streams depend on remote endpoints, network paths, DNS, TLS, and server behavior that RadioKit does not control.
- `AVPlayer` determines supported codecs, containers, redirects, buffering, and transport behavior. A candidate's `codec` value is informational.
- Failover starts when `AVPlayer` marks an item as failed. A stalled endpoint can remain in a buffering state.
- The `isOffline` value is a catalog hint. RadioKit does not probe candidate availability before playback.
- App Transport Security applies to stream and artwork URLs. The host app owns any exceptions.
- Timed song metadata must contain `Artist - Title`. RadioKit preserves later separators in the title.
- Apple Music enrichment uses the first catalog result. The result can be absent or incorrect.
- `RadioPlayer` is a main-actor singleton. Playback and system media integration are global within the process.
- System integration starts on the first playback request and remains active until the selected station becomes `nil`.
- Remote artwork must use HTTP or HTTPS and cannot contain URL credentials.
- Artwork responses cannot exceed 8 MiB, 4096 pixels per dimension, or 16,777,216 total pixels.
- RadioKit does not block private-network artwork addresses. Platform permissions and host-app network policy still apply.
- The App Group synchronizer stores only the last station and current playing flag. It does not synchronize an audio session.
- Background audio, interruptions, lock-screen controls, and media-key behavior require validation in a signed host app.
- Some iOS background and remote-control behavior can only be validated reliably on a physical device.
