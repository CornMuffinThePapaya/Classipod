import 'package:classipod/features/settings/models/exclude_directory_model.dart';

enum DirectoryExclusionState { inherited, excluded, included }

/// Normalizes a directory path for comparison: backslashes become forward
/// slashes and trailing separators are removed.
String normalizeDirectoryPath(String path) {
  var normalized = path.replaceAll('\\', '/');
  while (normalized.endsWith('/') && normalized.length > 1) {
    normalized = normalized.substring(0, normalized.length - 1);
  }
  return normalized;
}

/// Returns the parent directory of a file path using the same normalization
/// rules as [normalizeDirectoryPath], or null when the path has no parent.
String? parentDirectoryOf(String? filePath) {
  if (filePath == null) return null;
  final normalized = normalizeDirectoryPath(filePath);
  final separatorIndex = normalized.lastIndexOf('/');
  if (separatorIndex <= 0) return null;
  return normalized.substring(0, separatorIndex);
}

/// Whether [child] equals [parent] or lives anywhere beneath it. Matching
/// happens on directory boundaries only, so `/Music/Artist` does not match
/// `/Music/Artist2`.
bool isSubdirectoryOf({required String child, required String parent}) {
  final normalizedChild = normalizeDirectoryPath(child);
  final normalizedParent = normalizeDirectoryPath(parent);
  if (normalizedParent.isEmpty) return false;
  if (normalizedChild == normalizedParent) return true;
  if (normalizedChild.length <= normalizedParent.length) return false;
  if (!normalizedChild.startsWith(normalizedParent)) return false;
  return normalizedChild.codeUnitAt(normalizedParent.length) == 0x2F;
}

int _depthOf(String directoryPath) =>
    normalizeDirectoryPath(directoryPath).split('/').length;

/// Resolves the effective exclusion state of [directoryPath] against the
/// stored exclusion entries. The deepest matching entry wins, so an excluded
/// folder hides its entire subtree while an explicit included entry can
/// override an excluded ancestor.
DirectoryExclusionState resolveDirectoryExclusion({
  required String? directoryPath,
  required Iterable<ExcludeDirectoryModel> entries,
}) {
  if (directoryPath == null) return DirectoryExclusionState.inherited;
  DirectoryExclusionState? resolved;
  var bestDepth = -1;
  for (final entry in entries) {
    if (!isSubdirectoryOf(child: directoryPath, parent: entry.directoryPath)) {
      continue;
    }
    final depth = _depthOf(entry.directoryPath);
    if (depth > bestDepth) {
      bestDepth = depth;
      resolved = entry.isExcluded
          ? DirectoryExclusionState.excluded
          : DirectoryExclusionState.included;
    }
  }
  return resolved ?? DirectoryExclusionState.inherited;
}

/// Returns the direct child directories of [directoryPath] among [allDirectories].
List<String> childDirectoriesOf({
  required String directoryPath,
  required Iterable<String> allDirectories,
}) {
  final depth = _depthOf(directoryPath);
  return [
    ...{for (final directory in allDirectories)
      if (isSubdirectoryOf(child: directory, parent: directoryPath) &&
          _depthOf(directory) == depth + 1)
        normalizeDirectoryPath(directory)},
  ]..sort();
}

/// Computes the deepest directory that is an ancestor of every path in
/// [directoryPaths], or null when the set is empty. Used as the browser's
/// starting point.
String? commonAncestorOf(Iterable<String> directoryPaths) {
  final paths = directoryPaths.map(normalizeDirectoryPath).toList()..sort();
  if (paths.isEmpty) return null;
  final first = paths.first.split('/');
  final last = paths.last.split('/');
  final common = <String>[];
  for (var index = 0; index < first.length && index < last.length; index++) {
    if (first[index] != last[index]) break;
    common.add(first[index]);
  }
  if (common.isEmpty) return null;
  return common.join('/');
}
