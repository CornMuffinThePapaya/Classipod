import 'dart:async';

import 'package:classipod/core/constants/constants.dart';
import 'package:classipod/core/utils/exclusion_matcher.dart';
import 'package:classipod/features/settings/models/exclude_directory_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// A stored exclusion entry together with its Hive key.
class ExcludeDirectoryEntry {
  final dynamic key;
  final ExcludeDirectoryModel model;

  const ExcludeDirectoryEntry({required this.key, required this.model});

  String get directoryPath => model.directoryPath;

  bool get isExcluded => model.isExcluded;
}

final excludedDirectoriesProvider =
    NotifierProvider<ExcludeDirectoryNotifier, List<ExcludeDirectoryEntry>>(
      ExcludeDirectoryNotifier.new,
    );

class ExcludeDirectoryNotifier
    extends Notifier<List<ExcludeDirectoryEntry>> {
  final Box<ExcludeDirectoryModel> _excludeDirectoryBox =
      Hive.box<ExcludeDirectoryModel>(Constants.excludedDirectoriesBoxName);

  List<ExcludeDirectoryModel>? _exclusionsOnEntry;

  @override
  List<ExcludeDirectoryEntry> build() {
    return [
      for (final key in _excludeDirectoryBox.keys)
        ExcludeDirectoryEntry(
          key: key,
          model: _excludeDirectoryBox.get(key)!,
        ),
    ];
  }

  List<ExcludeDirectoryModel> _entryModels() => [
    for (final entry in state) entry.model,
  ];

  void beginEditing() {
    _exclusionsOnEntry = _entryModels();
  }

  bool takeExclusionChanges() {
    final initial = _exclusionsOnEntry;
    _exclusionsOnEntry = null;
    return initial != null && !listEquals(initial, _entryModels());
  }

  dynamic _keyOf(String directoryPath) {
    for (final entry in state) {
      if (normalizeDirectoryPath(entry.directoryPath) ==
          normalizeDirectoryPath(directoryPath)) {
        return entry.key;
      }
    }
    return null;
  }

  /// Resolves the effective exclusion state the user sees for a folder,
  /// accounting for overrides of excluded ancestors.
  bool isEffectivelyExcluded(String directoryPath) =>
      resolveDirectoryExclusion(
            directoryPath: directoryPath,
            entries: state.map((entry) => entry.model),
          ) ==
      DirectoryExclusionState.excluded;

  /// Creates, updates or removes the entry for [directoryPath] so its
  /// effective exclusion state matches [isExcluded].
  Future<void> setExcluded({
    required String directoryPath,
    required bool isExcluded,
  }) async {
    final key = _keyOf(directoryPath);
    if (key == null) {
      await _excludeDirectoryBox.add(
        ExcludeDirectoryModel(
          directoryPath: normalizeDirectoryPath(directoryPath),
          isExcluded: isExcluded,
        ),
      );
    } else {
      final entry = _excludeDirectoryBox.get(key)!;
      if (entry.isExcluded == isExcluded) return;
      await _excludeDirectoryBox.put(
        key,
        entry.copyWith(isExcluded: isExcluded),
      );
    }
    _refreshState();
  }

  /// Flips the visible exclusion state of [directoryPath].
  Future<void> toggleExcluded(String directoryPath) => setExcluded(
    directoryPath: directoryPath,
    isExcluded: !isEffectivelyExcluded(directoryPath),
  );

  /// Removes entries whose folder is no longer part of the scanned library.
  Future<void> pruneStaleEntries(Iterable<String> currentDirectories) async {
    final directories = currentDirectories.map(normalizeDirectoryPath).toSet();
    var changed = false;
    for (final entry in state) {
      if (!directories.contains(normalizeDirectoryPath(entry.directoryPath))) {
        await _excludeDirectoryBox.delete(entry.key);
        changed = true;
      }
    }
    if (changed) _refreshState();
  }

  void _refreshState() {
    if (ref.mounted) state = build();
  }
}
