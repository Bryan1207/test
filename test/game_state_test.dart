import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_p2p/model/game_state.dart';

void main() {
  test('X plays first; invalid and out-of-turn moves are rejected', () {
    final start = GameState.initial();
    expect(start.canMove(0, 'X'), isTrue);
    expect(start.move(0, 'O'), isNull);
    final played = start.move(0, 'X')!;
    expect(played.turn, 'O');
    expect(played.move(0, 'O'), isNull);
    expect(played.move(-1, 'O'), isNull);
    expect(played.move(9, 'O'), isNull);
    expect(start.board[0], isNull); // immutable move behavior
  });

  test('host-authoritative rules detect a row win and preserve score', () {
    var game = GameState.initial();
    for (final step in [(0, 'X'), (3, 'O'), (1, 'X'), (4, 'O'), (2, 'X')]) {
      game = game.move(step.$1, step.$2)!;
    }
    expect(game.winner, 'X');
    expect(game.xWins, 1);
    expect(game.move(5, 'O'), isNull);
    game = game.nextRound();
    expect(game.round, 2);
    expect(game.xWins, 1);
    expect(game.winner, isNull);
    expect(game.turn, 'X');
  });

  test('detects a draw without modifying scores incorrectly', () {
    var game = GameState.initial();
    for (final step in [
      (0, 'X'), (1, 'O'), (2, 'X'),
      (4, 'O'), (3, 'X'), (5, 'O'),
      (7, 'X'), (6, 'O'), (8, 'X'),
    ]) {
      game = game.move(step.$1, step.$2)!;
    }
    expect(game.winner, 'draw');
    expect(game.draws, 1);
    expect(game.xWins, 0);
    expect(game.oWins, 0);
  });

  test('JSON snapshots round-trip and reject invalid boards', () {
    var game = GameState.initial().move(4, 'X')!;
    game = GameState.fromJson(game.toJson());
    expect(game.board[4], 'X');
    expect(game.turn, 'O');
    expect(() => GameState.fromJson({'board': [1]}), throwsFormatException);
  });
}
