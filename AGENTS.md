# Codex instructions for Tic Tac Toe P2P

Goal: minimal, stable two-player iOS/Android Flutter Tic Tac Toe that works across independent cellular connections by IP, with Tailscale installed on both phones. Do not silently replace this with LAN-only multiplayer or invent a publicly reachable cellular IP.

Architecture:
- Pure rules live in `lib/model/game_state.dart`.
- `lib/network/game_session.dart` hosts a single TCP socket on port 45454; host is authoritative for all moves.
- `lib/main.dart` displays connection flow and gameplay.
- Cross-cellular reliability comes from Tailscale's NAT traversal/relays; cannot guarantee a strictly direct underlying path on every carrier.

Before claiming the app works:
1. Run `flutter create --project-name tic_tac_toe_p2p --platforms=android,ios .` to generate standard platform directories, without overwriting existing game code.
2. Ensure `INTERNET` Android permission and `NSLocalNetworkUsageDescription` iOS purpose string.
3. Run `dart format .`, `flutter analyze`, and `flutter test`; fix all actual diagnostics.
4. Build a signed Android artifact and iOS artifact on a suitable build host. iOS requires macOS/Xcode/Apple signing; do not assert Windows can build an IPA alone.
5. Test real iOS-to-Android cellular path using two phones with Wi-Fi disabled and Tailscale running, in **both** host directions.
6. Validate legal/illegal moves, simultaneous taps, wins, draws, rematches, a guest disconnect, host leave, and no moves from a disconnected peer.
7. Keep secrets, API keys, certificates, and Tailscale auth keys OUT of the repository.

Follow-up enhancements after MVP: better reconnect/resume, inviting a tailnet friend, secure session pairing code, automatic host IP discovery via platform-specific integration, keepalive/connection timeout, socket input size limit at streaming layer, UI and integration tests.