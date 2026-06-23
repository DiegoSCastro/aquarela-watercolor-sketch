import 'dart:io';

import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Test double for [PathProviderPlatform] that pretends the
/// system has a writable documents directory and lets tests seed
/// PNG files into a fake "gallery" subfolder.
class FakePathProvider extends PathProviderPlatform {
  final Directory _root = Directory.systemTemp.createTempSync('aquarela_test_');

  void reset() {
    final gallery = Directory('${_root.path}/gallery');
    if (gallery.existsSync()) {
      gallery.deleteSync(recursive: true);
    }
  }

  /// Write zero-byte files with the given names into the
  /// fake gallery directory. Modified timestamps are set so
  /// the gallery's "newest first" sort is deterministic.
  void seedPngs(List<String> fileNames) {
    final gallery = Directory('${_root.path}/gallery');
    gallery.createSync(recursive: true);
    var i = 0;
    for (final name in fileNames) {
      final f = File('${gallery.path}/$name');
      f.writeAsBytesSync(<int>[]);
      f.setLastModifiedSync(
        DateTime(2026, 1, 1).add(Duration(seconds: i++)),
      );
    }
  }

  @override
  Future<String?> getApplicationDocumentsPath() async => _root.path;

  @override
  Future<String?> getTemporaryPath() async => _root.path;

  @override
  Future<String?> getApplicationSupportPath() async => _root.path;
}
