import 'dart:collection';

import 'package:classipod/core/models/music_metadata.dart';
import 'package:classipod/core/services/audio_files_service.dart';
import 'package:classipod/core/utils/duplicate_tracks.dart';
import 'package:classipod/core/utils/exclusion_matcher.dart';
import 'package:classipod/features/settings/controller/exclude_directories_controller.dart';
import 'package:classipod/features/settings/controller/prevent_duplicate_tracks_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final filteredAudioFilesProvider =
    FutureProvider<UnmodifiableListView<MusicMetadata>>((ref) async {
      final preventDuplicates = ref.watch(preventDuplicateTracksProvider);
      final metadataFuture = ref.watch(audioFilesServiceProvider.future);
      ref.listen(excludedDirectoriesProvider, (previous, next) {
        if (!listEquals(previous, next)) ref.invalidateSelf();
      });
      final exclusionEntries = ref
          .read(excludedDirectoriesProvider)
          .map((entry) => entry.model)
          .toList();
      final audioFilesMetadata = await metadataFuture;

      final List<MusicMetadata> filteredList = [];
      for (final audioFileMetadata in audioFilesMetadata) {
        if (audioFileMetadata.isSubsonic ||
            resolveDirectoryExclusion(
                  directoryPath: audioFileMetadata.parentDirectoryPath,
                  entries: exclusionEntries,
                ) !=
                DirectoryExclusionState.excluded) {
          filteredList.add(audioFileMetadata);
        }
      }

      return UnmodifiableListView(
        preventDuplicates
            ? withoutDuplicateFileNames(filteredList)
            : filteredList,
      );
    });
