import 'package:classipod/core/extensions/build_context_extensions.dart';
import 'package:classipod/core/utils/enum_from_name.dart';
import 'package:cupertino_ui/cupertino_ui.dart';

enum ClickWheelSize {
  small,
  medium,
  large;

  static ClickWheelSize fromName(String? raw) =>
      enumFromName(values, raw, medium);

  String title(BuildContext context) {
    switch (this) {
      case small:
        return context.localization.small;
      case medium:
        return context.localization.medium;
      case large:
        return context.localization.large;
    }
  }
}
