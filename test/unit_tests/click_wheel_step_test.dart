import 'package:classipod/core/constants/constants.dart';
import 'package:classipod/features/settings/models/click_wheel_sensitivity.dart';
import 'package:classipod/features/settings/models/click_wheel_step.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClickWheelStep', () {
    test('normal is the default multiplier of one', () {
      expect(ClickWheelStep.normal.multiplier, 1);
    });

    test('step order goes from coarse to very fine', () {
      expect(ClickWheelStep.coarse.index, 0);
      expect(ClickWheelStep.normal.index, 1);
      expect(ClickWheelStep.fine.index, 2);
      expect(ClickWheelStep.veryFine.index, 3);
    });

    test('coarse doubles the step threshold', () {
      expect(
        Constants.clickWheelMediumSensitivityThreshold /
            ClickWheelStep.coarse.multiplier,
        Constants.clickWheelMediumSensitivityThreshold * 2,
      );
    });

    test('very fine quarters the step threshold', () {
      expect(
        Constants.clickWheelMediumSensitivityThreshold /
            ClickWheelStep.veryFine.multiplier,
        Constants.clickWheelMediumSensitivityThreshold / 4,
      );
    });

    test('combined with sensitivity there are 16 gradations', () {
      expect(
        ClickWheelSensitivity.values.length * ClickWheelStep.values.length,
        16,
      );
    });
  });
}
