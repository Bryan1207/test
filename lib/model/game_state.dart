/// Deterministic, host-authoritative rules. No Flutter dependency.
class GameState {
  const GameState._({
    required this.board,
    required this.turn,
    required this.winner,
    required this.xWins,
    required this.oWins,
    required this.draws,
    required this.round,
  });

  factory GameState.initial() => GameState._(
        board: List<String?>.filled(9, null),
        turn: 'X',
        winner: null,
        xWins: 0,
        oWins: 0,
        draws: 0,
        round: 1,
      );

  final List<String?> board;
  final String turn;

  /// Null until the round is finished; then X, O or draw.
  final String? winner;
  final int xWins;
  final int oWins;
  final int draws;
  final int round;

  bool get finished => winner != null;

  bool canMove(int index, String symbol) =>
      !finished &&
      (symbol == 'X' || symbol == 'O') &&
      symbol == turn &&
      index >= 0 &&
      index < 9 &&
      board[index] == null;

  /// Returns null for an illegal move, leaving this state unchanged.
  GameState? move(int index, String symbol) {
    if (!canMove(index, symbol)) return null;
    final updatedBoard = List<String?>.from(board);
    updatedBoard[index] = symbol;
    final result = _result(updatedBoard);
    return GameState._(
      board: updatedBoard,
      turn: result == null ? (symbol == 'X' ? 'O' : 'X') : symbol,
      winner: result,
      xWins: xWins + (result == 'X' ? 1 : 0),
      oWins: oWins + (result == 'O' ? 1 : 0),
      draws: draws + (result == 'draw' ? 1 : 0),
      round: round,
    );
  }

  GameState nextRound() => GameState._(
        board: List<String?>.filled(9, null),
        turn: 'X',
        winner: null,
        xWins: xWins,
        oWins: oWins,
        draws: draws,
        round: round + 1,
      );

  Map<String, dynamic> toJson() => {
        'board': board,
        'turn': turn,
        'winner': winner,
        'xWins': xWins,
        'oWins': oWins,
        'draws': draws,
        'round': round,
      };

  factory GameState.fromJson(Map<String, dynamic> json) {
    final raw = json['board'];
    if (raw is! List || raw.length != 9 ||
        raw.any((cell) => cell != null && cell != 'X' && cell != 'O')) {
      throw const FormatException('Invalid board');
    }
    final turn = json['turn'];
    final winner = json['winner'];
    if ((turn != 'X' && turn != 'O') ||
        (winner != null && winner != 'X' && winner != 'O' && winner != 'draw')) {
      throw const FormatException('Invalid turn or winner');
    }
    int nonnegative(String key, {int min = 0}) {
      final value = json[key];
      if (value is! int || value < min) {
        throw FormatException('Invalid $key');
      }
      return value;
    }

    return GameState._(
      board: List<String?>.from(raw),
      turn: turn as String,
      winner: winner as String?,
      xWins: nonnegative('xWins'),
      oWins: nonnegative('oWins'),
      draws: nonnegative('draws'),
      round: nonnegative('round', min: 1),
    );
  }

  static String? _result(List<String?> board) {
    const wins = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6],
    ];
    for (final line in wins) {
      final mark = board[line[0]];
      if (mark != null && mark == board[line[1]] && mark == board[line[2]]) {
        return mark;
      }
    }
    return board.every((cell) => cell != null) ? 'draw' : null;
  }
}
