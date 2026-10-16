import 'package:classipod/core/utils/exclusion_matcher.dart';
import 'package:classipod/features/settings/models/exclude_directory_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeDirectoryPath', () {
    test('converts backslashes and strips trailing separators', () {
      expect(normalizeDirectoryPath(r'C:\Music\Artist'), 'C:/Music/Artist');
      expect(normalizeDirectoryPath('/Music/Artist/'), '/Music/Artist');
      expect(normalizeDirectoryPath('/Music/Artist//'), '/Music/Artist');
    });
  });

  group('parentDirectoryOf', () {
    test('returns the parent directory', () {
      expect(parentDirectoryOf('/Music/Artist/Album/Song.mp3'), '/Music/Artist/Album');
      expect(parentDirectoryOf(r'C:\Music\Song.mp3'), 'C:/Music');
    });

    test('returns null for paths without a parent', () {
      expect(parentDirectoryOf('Song.mp3'), isNull);
      expect(parentDirectoryOf(null), isNull);
    });
  });

  group('isSubdirectoryOf', () {
    test('matches equal paths and descendants', () {
      expect(
        isSubdirectoryOf(child: '/Music/Artist', parent: '/Music/Artist'),
        isTrue,
      );
      expect(
        isSubdirectoryOf(
          child: '/Music/Artist/Album',
          parent: '/Music/Artist',
        ),
        isTrue,
      );
    });

    test('does not match sibling folders with shared prefixes', () {
      expect(
        isSubdirectoryOf(child: '/Music/Artist2', parent: '/Music/Artist'),
        isFalse,
      );
    });

    test('is separator-style agnostic', () {
      expect(
        isSubdirectoryOf(child: r'C:\Music\Artist', parent: 'C:/Music'),
        isTrue,
      );
    });
  });

  group('resolveDirectoryExclusion', () {
    test('returns inherited when no entry matches', () {
      expect(
        resolveDirectoryExclusion(
          directoryPath: '/Music/Artist',
          entries: const [],
        ),
        DirectoryExclusionState.inherited,
      );
    });

    test('an excluded ancestor hides its subtree', () {
      expect(
        resolveDirectoryExclusion(
          directoryPath: '/Music/Artist/Album',
          entries: [ ExcludeDirectoryModel(directoryPath: '/Music/Artist', isExcluded: true),
          ],
        ),
        DirectoryExclusionState.excluded,
      );
    });

    test('the deepest matching entry wins', () {
      expect(
        resolveDirectoryExclusion(
          directoryPath: '/Music/Artist/Album',
          entries: [ ExcludeDirectoryModel(directoryPath: '/Music', isExcluded: true), ExcludeDirectoryModel(
              directoryPath: '/Music/Artist',
              isExcluded: false,
            ),
          ],
        ),
        DirectoryExclusionState.included,
      );
      expect(
        resolveDirectoryExclusion(
          directoryPath: '/Music/Artist/Album/Track',
          entries: [ ExcludeDirectoryModel(directoryPath: '/Music', isExcluded: true), ExcludeDirectoryModel(
              directoryPath: '/Music/Artist/Album',
              isExcluded: false,
            ),
          ],
        ),
        DirectoryExclusionState.included,
      );
    });

    test('tracks directly inside an excluded folder are excluded', () {
      expect(
        resolveDirectoryExclusion(
          directoryPath: '/Music',
          entries: [ ExcludeDirectoryModel(directoryPath: '/Music', isExcluded: true),
          ],
        ),
        DirectoryExclusionState.excluded,
      );
    });
  });

  group('childDirectoriesOf', () {
    test('returns only direct children', () {
      expect(
        childDirectoriesOf(directoryPath: '/Music', allDirectories: [
          '/Music/A',
          '/Music/A/Album',
          '/Music/B',
          '/Other',
        ]),
        ['/Music/A', '/Music/B'],
      );
    });
  });

  group('commonAncestorOf', () {
    test('finds the deepest shared ancestor', () {
      expect(
        commonAncestorOf(['/Music/A/One', '/Music/B/Two']),
        '/Music',
      );
      expect(commonAncestorOf(['/Music/A']), '/Music/A');
      expect(commonAncestorOf(const []), isNull);
    });

    test('respects directory boundaries', () {
      expect(
        commonAncestorOf(['/Music/Artist2/X', '/Music/Artist/Y']),
        '/Music',
      );
    });
  });
}

