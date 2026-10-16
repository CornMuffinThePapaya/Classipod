import 'package:classipod/core/utils/enum_from_name.dart';
import 'package:classipod/features/settings/models/click_wheel_sensitivity.dart';
import 'package:classipod/features/settings/models/click_wheel_size.dart';
import 'package:classipod/features/settings/models/click_wheel_step.dart';
import 'package:classipod/features/settings/models/repeat_mode.dart';
import 'package:classipod/features/settings/models/volume_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('enumFromName', () {
    test('returns the matching value for a known name', () {
      expect(
        enumFromName(ClickWheelSize.values, 'large', ClickWheelSize.medium),
        ClickWheelSize.large,
      );
    });

    test('returns the fallback for an unknown name', () {
      expect(
        enumFromName(ClickWheelSize.values, 'gigantic', ClickWheelSize.medium),
        ClickWheelSize.medium,
      );
    });

    test('returns the fallback for null', () {
      expect(
        enumFromName(ClickWheelSize.values, null, ClickWheelSize.medium),
        ClickWheelSize.medium,
      );
    });
  });

  group('ClickWheelSize.fromName', () {
    test('parses every enum name', () {
      for (final value in ClickWheelSize.values) {
        expect(ClickWheelSize.fromName(value.name), value);
      }
    });

    test('falls back to medium for unknown names', () {
      expect(ClickWheelSize.fromName('xLarge'), ClickWheelSize.medium);
      expect(ClickWheelSize.fromName(null), ClickWheelSize.medium);
    });
  });

  group('ClickWheelSensitivity.fromName', () {
    test('parses every enum name', () {
      for (final value in ClickWheelSensitivity.values) {
        expect(ClickWheelSensitivity.fromName(value.name), value);
      }
    });

    test('falls back to medium for unknown names', () {
      expect(
        ClickWheelSensitivity.fromName('ultraLow'),
        ClickWheelSensitivity.medium,
      );
      expect(ClickWheelSensitivity.fromName(null), ClickWheelSensitivity.medium);
    });
  });

  group('ClickWheelStep.fromName', () {
    test('parses every enum name', () {
      for (final value in ClickWheelStep.values) {
        expect(ClickWheelStep.fromName(value.name), value);
      }
    });

    test('falls back to normal for unknown names', () {
      expect(ClickWheelStep.fromName('ultraCoarse'), ClickWheelStep.normal);
      expect(ClickWheelStep.fromName(null), ClickWheelStep.normal);
    });
  });

  group('RepeatMode.fromName', () {
    test('parses every enum name', () {
      for (final value in RepeatMode.values) {
        expect(RepeatMode.fromName(value.name), value);
      }
    });

    test('falls back to off for unknown names', () {
      expect(RepeatMode.fromName('sometimes'), RepeatMode.off);
      expect(RepeatMode.fromName(null), RepeatMode.off);
    });
  });

  group('VolumeMode.fromName', () {
    test('parses every enum name', () {
      for (final value in VolumeMode.values) {
        expect(VolumeMode.fromName(value.name), value);
      }
    });

    test('falls back to app for unknown names', () {
      expect(VolumeMode.fromName('balanced'), VolumeMode.app);
      expect(VolumeMode.fromName(null), VolumeMode.app);
    });
  });
}
