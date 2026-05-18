import 'dart:io';

/// Creates a root `.env` from `.env.example` if missing (for `flutter run` / CI).
///
/// Usage: `dart run tool/bootstrap_env.dart`
void main() {
  final root = Directory.current.path;
  final env = File('$root/.env');
  if (env.existsSync()) {
    stdout.writeln('.env already exists — leaving it unchanged.');
    return;
  }
  final example = File('$root/.env.example');
  if (!example.existsSync()) {
    stderr.writeln('Missing .env.example');
    exitCode = 1;
    return;
  }
  env.writeAsStringSync(example.readAsStringSync());
  stdout.writeln('Created .env from .env.example — add your keys locally.');
}
