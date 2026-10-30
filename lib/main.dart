import 'package:flutter/material.dart';
import 'network/game_session.dart';

void main() => runApp(const TicTacToeApp());

class TicTacToeApp extends StatelessWidget {
  const TicTacToeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tic Tac Toe P2P',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff6ce3d0),
          brightness: Brightness.dark,
          surface: const Color(0xff101a24),
        ),
        scaffoldBackgroundColor: const Color(0xff0b131d),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xff1b2935),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      home: const GameHome(),
    );
  }
}

class GameHome extends StatefulWidget {
  const GameHome({super.key});

  @override
  State<GameHome> createState() => _GameHomeState();
}

class _GameHomeState extends State<GameHome> {
  final GameSession session = GameSession();
  final TextEditingController address = TextEditingController();

  @override
  void dispose() {
    address.dispose();
    session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('TIC TAC TOE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2.6)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
                children: [
                  _heading(),
                  const SizedBox(height: 20),
                  _statusPanel(),
                  const SizedBox(height: 24),
                  if (session.stage == ConnectionStage.idle ||
                      session.stage == ConnectionStage.disconnected)
                    _startPanel()
                  else ...[
                    if (session.stage == ConnectionStage.hosting) _hostingPanel(),
                    if (session.stage == ConnectionStage.connecting)
                      const Center(child: Padding(
                        padding: EdgeInsets.all(28),
                        child: CircularProgressIndicator(),
                      )),
                    if (session.stage == ConnectionStage.connected) _gamePanel(),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () => session.leave(),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Leave match'),
                    ),
                  ],
                  const SizedBox(height: 28),
                  const Text(
                    'CELLULAR MODE  •  Both phones must have Tailscale connected. '
                    'Keep this game open in the foreground while playing.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xff8fa4b2), fontSize: 11, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _heading() => Column(
        children: [
          const Icon(Icons.grid_3x3_rounded, size: 52, color: Color(0xff6ce3d0)),
          const SizedBox(height: 12),
          Text('Cross-platform. Direct IP.',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          const Text('Two phones. One match. No game server.',
              style: TextStyle(color: Color(0xffa6b4c2))),
        ],
      );

  Widget _statusPanel() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xff172632),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xff365060)),
        ),
        child: Row(children: [
          Icon(
            session.stage == ConnectionStage.connected
                ? Icons.check_circle_rounded
                : Icons.wifi_tethering_rounded,
            color: const Color(0xff6ce3d0),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(session.message, style: const TextStyle(height: 1.4))),
        ]),
      );

  Widget _startPanel() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: () => session.host(),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Host game  ·  Play X'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(18)),
          ),
          const SizedBox(height: 22),
          const Row(children: [
            Expanded(child: Divider()),
            Padding(padding: EdgeInsets.symmetric(horizontal: 14), child: Text('OR JOIN A FRIEND')),
            Expanded(child: Divider()),
          ]),
          const SizedBox(height: 22),
          TextField(
            controller: address,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(
              labelText: 'Host Tailscale IP',
              hintText: '100.101.102.103',
              prefixIcon: Icon(Icons.language_rounded),
            ),
            onSubmitted: (value) => session.join(value),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => session.join(address.text),
            icon: const Icon(Icons.login_rounded),
            label: const Text('Join game  ·  Play O'),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(17)),
          ),
          const SizedBox(height: 13),
          const Text('Enter the 100.x.x.x address shown in the host\'s Tailscale app.',
              style: TextStyle(color: Color(0xffa6b4c2), fontSize: 13)),
        ],
      );

  Widget _hostingPanel() => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xff172632),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 18),
          const Text('Waiting for Player O', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
          const SizedBox(height: 8),
          const Text('Open Tailscale on this phone, copy its IPv4 address, and send it to your friend.',
              textAlign: TextAlign.center, style: TextStyle(color: Color(0xffb2c4cc))),
          const SizedBox(height: 12),
          Text('TCP PORT ${GameSession.port}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xff6ce3d0))),
        ]),
      );

  Widget _gamePanel() {
    final game = session.game;
    final turnLabel = game.winner == 'draw'
        ? 'Draw!'
        : game.winner != null
            ? '${game.winner} wins!'
            : session.isMyTurn
                ? 'Your turn · ${session.mySymbol}'
                : 'Opponent\'s turn · ${game.turn}';

    return Column(children: [
      Text(turnLabel,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
      const SizedBox(height: 8),
      Text('Round ${game.round}  ·  You are ${session.mySymbol}',
          style: const TextStyle(color: Color(0xffa6b4c2))),
      const SizedBox(height: 22),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 370),
        child: AspectRatio(
          aspectRatio: 1,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 9,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 9,
              crossAxisSpacing: 9,
            ),
            itemBuilder: (context, index) {
              final symbol = game.board[index];
              final canPlay = session.isMyTurn && game.canMove(index, session.mySymbol);
              return Material(
                color: const Color(0xff21303e),
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: canPlay ? () => session.play(index) : null,
                  child: Center(child: FittedBox(
                    child: Text(symbol ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 65,
                          color: symbol == 'X'
                              ? const Color(0xff6ce3d0)
                              : const Color(0xffffad78),
                        )),
                  )),
                ),
              );
            },
          ),
        ),
      ),
      const SizedBox(height: 24),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _score('X', game.xWins, const Color(0xff6ce3d0)),
        _score('DRAWS', game.draws, const Color(0xffd0dde4)),
        _score('O', game.oWins, const Color(0xffffad78)),
      ]),
      if (game.finished) ...[
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: session.rematch,
          icon: const Icon(Icons.restart_alt_rounded),
          label: const Text('Next round'),
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16)),
        ),
      ],
    ]);
  }

  Widget _score(String label, int score, Color color) => Column(children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text('$score', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
      ]);
}
