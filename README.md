# Tic Tac Toe P2P · iOS + Android

A tiny, host-authoritative, cross-platform Flutter game. The host plays X, the joining phone plays O. Moves travel over a TCP connection to the host's IP on port **45454**. No game accounts, database, matchmaking service, or custom game backend.

## Works over cellular

**Directly connecting to a random phone's cellular public IP is unreliable** because mobile carriers frequently use carrier-grade NAT and firewalls. For this prototype, both devices use the **Tailscale** app to join the same tailnet. Tailscale assigns each phone a stable **100.x.y.z** address and handles NAT traversal. Whenever possible it uses direct encrypted peer-to-peer transport; otherwise it routes encrypted traffic through a relay. The game's own TCP socket always connects to the other phone's Tailscale address, with no game server.

Tailscale is a dependency for the *cellular* scenario, and both players must be authorized in the same tailnet (or the host device shared appropriately). No guarantee that every connection is direct end-to-end at the underlying network layer.

## Features

- Host / join over explicit IP address
- Turns validated by the host (X goes first)
- Win, loss, tie detection
- Scoreboard across rounds
- Rematches initiated by either player
- Graceful host wait / player-disconnect status
- Android and iOS from one Flutter source tree
- Pure deterministic rules with unit tests

## Development on Windows

1. Install the [Flutter SDK](https://docs.flutter.dev/get-started/install/windows/mobile) and Android Studio / Android SDK.
2. Download this repository or the source ZIP and extract it.
3. In the project folder run:

```powershell
flutter create --project-name tic_tac_toe_p2p --platforms=android,ios .
flutter pub get
flutter test
flutter run
```

`flutter create` supplies standard platform folders for this lightweight source distribution. It will preserve our existing Dart files. If Flutter asks about overwriting, **do not overwrite** `lib/`, `test/`, `pubspec.yaml`, or `analysis_options.yaml`.

For an Android APK:

```powershell
flutter build apk --release
```

Look in `build/app/outputs/flutter-apk/app-release.apk`.

### Platform permissions

In `android/app/src/main/AndroidManifest.xml`, ensure this exists directly under `<manifest>`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

On iOS, add a reason for local networking to `ios/Runner/Info.plist` before `</dict>`:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>Connect directly to a friend's Tic Tac Toe game on a local or private network.</string>
```

Dart's TCP sockets do not need a cloud backend. If a future Android target enforces local-network runtime permission, handle it in the platform code before connecting to a LAN address; see the Flutter Android local-network permission documentation.

**iOS binaries cannot be compiled on Windows with the normal Flutter toolchain.** Use a Mac with Xcode or a macOS cloud build service, plus the required Apple signing credentials. TestFlight distribution generally requires the Apple Developer Program. This ZIP contains source, **not** a signed iOS IPA or Android APK.

## Playing from different cellular networks

1. Install Tailscale on the **iPhone** and **Android phone** and connect both devices to the same tailnet (using a Tailscale invitation or a shared device as appropriate).
2. Turn Wi-Fi off on both phones to verify actual cellular operation; leave Tailscale connected.
3. On Player 1's phone, open Tic Tac Toe and tap **Host game**. The host must leave the app open.
4. In the host's Tailscale app, find the phone's **100.x.x.x IPv4 address** and send it to Player 2.
5. Player 2 opens Tic Tac Toe, enters that address, and taps **Join game**. The port is fixed at `45454`.
6. Play! Player 1 = X; Player 2 = O. Either can request another round after a result.

If no connection is established: confirm both Tailscale apps say connected; check the tailnet access control grants, try a Tailscale ping using another tailnet device if available, and keep the host foregrounded. The game also works over Wi-Fi using the host's LAN IP, when connectivity and local-network permissions allow it.

## Network protocol

Newline-delimited JSON messages over one TCP connection:

- Guest sends `{"type":"move","index":4}`. Index is 0 through 8.
- Host validates the O move, updates the authoritative board, and broadcasts `{"type":"state","game":{...}}`.
- Host X moves are validated locally and broadcast in the same format.
- Guest sends `{"type":"rematch"}` after a round ends; the host resets the board while preserving scores.

There is **no password/authentication in the prototype** beyond tailnet access controls. The host binds to all IPv4 interfaces on TCP port 45454. Do not expose that TCP port directly to the public Internet. The game must remain in the foreground on both phones. The prototype is not hardened for malicious peers, network changes, background execution, or store release.

## Project map

- `lib/main.dart` — screen, board, controls and scores
- `lib/network/game_session.dart` — TCP host/client and synchronization
- `lib/model/game_state.dart` — pure game rules
- `test/game_state_test.dart` — rules tests
- `AGENTS.md` — Codex implementation guidance

## Next step for Codex

Import the repository into Codex and ask it to run the test suite on a machine with Flutter installed, generate platform scaffolding, run static analysis, and produce Android/iOS builds through appropriate build hosts. `AGENTS.md` contains acceptance criteria.