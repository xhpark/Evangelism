import 'dart:io';

void main(List<String> arguments) {
  if (arguments.length != 2) {
    stderr.writeln(
      'Usage: dart run scripts/check_coverage.dart <lcov.info> <minimum-percent>',
    );
    exitCode = 64;
    return;
  }

  final file = File(arguments[0]);
  final minimum = double.tryParse(arguments[1]);
  if (!file.existsSync() || minimum == null) {
    stderr.writeln('Coverage file or minimum percentage is invalid.');
    exitCode = 64;
    return;
  }

  var found = 0;
  var hit = 0;
  final expression = RegExp(r'^DA:\d+,(\d+)');
  for (final line in file.readAsLinesSync()) {
    final match = expression.firstMatch(line);
    if (match == null) continue;
    found += 1;
    if (int.parse(match.group(1)!) > 0) hit += 1;
  }

  if (found == 0) {
    stderr.writeln('No executable lines were found in the coverage report.');
    exitCode = 65;
    return;
  }

  final percentage = hit * 100 / found;
  stdout.writeln(
    'Line coverage: ${percentage.toStringAsFixed(1)}% ($hit/$found), minimum ${minimum.toStringAsFixed(1)}%',
  );
  if (percentage < minimum) exitCode = 1;
}
