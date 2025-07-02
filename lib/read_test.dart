import 'dart:io';

void main() {
  final path =
      'D:/reflutter/nayanasartistry/assets/keys/serviceAccountKey.json';
  print('🔎 Checking path: $path');
  print(
    File(path).existsSync()
        ? "✅ File is visible and accessible"
        : "❌ Still missing",
  );
}
