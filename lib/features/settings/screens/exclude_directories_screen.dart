import 'dart:async';
import 'dart:io';

import 'package:classipod/core/extensions/build_context_extensions.dart';
import 'package:classipod/core/navigation/routes.dart';
import 'package:classipod/core/services/audio_files_service.dart';
import 'package:classipod/core/utils/exclusion_matcher.dart';
import 'package:classipod/core/widgets/empty_state_widget.dart';
import 'package:classipod/features/custom_screen_elements/custom_screen.dart';
import 'package:classipod/features/settings/controller/exclude_directories_controller.dart';
import 'package:classipod/features/settings/widgets/exclude_directory_tile.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _ExcludeRowType { addFolder, up, toggleCurrent, folder }

class _ExcludeRow {
  final _ExcludeRowType type;
  final String? directory;

  const _ExcludeRow(this.type, {this.directory});
}

class ExcludeDirectoriesScreen extends ConsumerStatefulWidget {
  const ExcludeDirectoriesScreen({super.key});

  @override
  ConsumerState createState() => _ExcludeDirectoriesScreenState();
}

class _ExcludeDirectoriesScreenState
    extends ConsumerState<ExcludeDirectoriesScreen>
    with CustomScreen {
  String? _currentDirectory;
  String? _prunedForRoot;

  bool get _supportsFolderPicker =>
      !kIsWeb &&
      (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  @override
  void initState() {
    super.initState();
    ref.read(excludedDirectoriesProvider.notifier).beginEditing();
    ref.listenManual(audioFilesServiceProvider, (_, _) => _pruneStaleEntries());
  }

  void _pruneStaleEntries() {
    final root = _libraryRoot;
    if (root == null || _prunedForRoot == root) return;
    _prunedForRoot = root;
    unawaited(
      ref
          .read(excludedDirectoriesProvider.notifier)
          .pruneStaleEntries(_scannedDirectories()),
    );
  }

  String? get _libraryRoot => commonAncestorOf(_scannedDirectories());

  Set<String> _scannedDirectories() {
    final metadata = ref.read(audioFilesServiceProvider).value;
    if (metadata == null) return const {};
    return {
      for (final item in metadata)
        if (!item.isSubsonic && item.parentDirectoryPath != null)
          normalizeDirectoryPath(item.parentDirectoryPath!),
    };
  }

  @override
  String get routeName => Routes.excludeDirectories.name;

  @override
  List<_ExcludeRow> get displayItems {
    final root = _libraryRoot;
    if (root == null) return const [];
    final current = _currentDirectory ?? root;
    final rows = <_ExcludeRow>[
      if (_supportsFolderPicker) const _ExcludeRow(_ExcludeRowType.addFolder),
      if (_currentDirectory != null) ...[
        const _ExcludeRow(_ExcludeRowType.up),
        _ExcludeRow(_ExcludeRowType.toggleCurrent, directory: _currentDirectory),
      ],
      for (final child in childDirectoriesOf(
        directoryPath: current,
        allDirectories: _scannedDirectories(),
      ))
        _ExcludeRow(_ExcludeRowType.folder, directory: child),
    ];
    return rows;
  }

  String _folderTitle(String? directory) {
    if (directory == null) return context.localization.upOneLevel;
    return directory.split('/').where((segment) => segment.isNotEmpty).last;
  }

  DirectoryExclusionState _stateOf(String? directory) {
    if (directory == null) return DirectoryExclusionState.inherited;
    return resolveDirectoryExclusion(
      directoryPath: directory,
      entries: ref.read(excludedDirectoriesProvider).map(
        (entry) => entry.model,
      ),
    );
  }

  void _navigateUp() {
    final root = _libraryRoot;
    if (_currentDirectory == null || root == null) return;
    final parent = parentDirectoryOf(_currentDirectory);
    setState(() {
      _currentDirectory =
          parent != null && isSubdirectoryOf(child: parent, parent: root)
          ? parent
          : null;
      selectedDisplayItem = 0;
      scrollController.jumpTo(0);
    });
  }

  Future<void> _pickFolder() async {
    final result = await FilePicker.getDirectoryPath(
      dialogTitle: context.localization.addFolder,
    );
    if (result == null || !mounted) return;
    await ref
        .read(excludedDirectoriesProvider.notifier)
        .setExcluded(directoryPath: result, isExcluded: true);
  }

  @override
  void onSelectPressed() {
    final row = displayItems[selectedDisplayItem];
    switch (row.type) {
      case _ExcludeRowType.addFolder:
        unawaited(_pickFolder());
      case _ExcludeRowType.up:
        _navigateUp();
      case _ExcludeRowType.toggleCurrent:
        unawaited(
          ref
              .read(excludedDirectoriesProvider.notifier)
              .toggleExcluded(row.directory!),
        );
      case _ExcludeRowType.folder:
        setState(() {
          _currentDirectory = row.directory;
          selectedDisplayItem = 0;
          scrollController.jumpTo(0);
        });
    }
  }

  @override
  void onSelectLongPress() {
    final row = displayItems[selectedDisplayItem];
    if (row.directory == null) return;
    unawaited(
      ref
          .read(excludedDirectoriesProvider.notifier)
          .toggleExcluded(row.directory!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final metadata = ref.watch(audioFilesServiceProvider).value;
    _pruneStaleEntries();
    if (metadata == null || displayItems.isEmpty) {
      return CupertinoPageScaffold(
        child: Column(
          children: [
            Expanded(
              child: EmptyStateWidget(
                emptyDescription: context.localization.noMusicFilesFound,
              ),
            ),
          ],
        ),
      );
    }
    return CupertinoPageScaffold(
      child: Column(
        children: [
          Flexible(
            child: CupertinoScrollbar(
              controller: scrollController,
              child: ListView.builder(
                controller: scrollController,
                itemCount: displayItems.length,
                prototypeItem: const ExcludeDirectoryTile(
                  title: 'prototype',
                  state: DirectoryExclusionState.inherited,
                  isSelected: false,
                  onTap: _noop,
                ),
                itemBuilder: (context, index) {
                  final row = displayItems[index];
                  return ExcludeDirectoryTile(
                    key: ValueKey('${row.type}-${row.directory}'),
                    title: switch (row.type) {
                      _ExcludeRowType.addFolder =>
                        context.localization.addFolder,
                      _ExcludeRowType.up => context.localization.upOneLevel,
                      _ExcludeRowType.toggleCurrent => _stateOf(
                        row.directory,
                      ) ==
                          DirectoryExclusionState.excluded
                          ? context.localization.includeThisFolder
                          : context.localization.excludeThisFolder,
                      _ExcludeRowType.folder => _folderTitle(row.directory),
                    },
                    state: switch (row.type) {
                      _ExcludeRowType.up ||
                      _ExcludeRowType.addFolder =>
                        DirectoryExclusionState.inherited,
                      _ => _stateOf(row.directory),
                    },
                    trailingIcon: switch (row.type) {
                      _ExcludeRowType.addFolder => CupertinoIcons
                          .plus_circle_fill,
                      _ExcludeRowType.up => CupertinoIcons
                          .arrow_up_left_circle_fill,
                      _ => null,
                    },
                    isSelected: selectedDisplayItem == index,
                    onTap: () {
                      setState(() => selectedDisplayItem = index);
                      onSelectPressed();
                    },
                    onLongPress: row.directory == null
                        ? null
                        : () {
                            setState(() => selectedDisplayItem = index);
                            onSelectLongPress();
                          },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void _noop() {}
}

