import 'package:classipod/core/extensions/build_context_extensions.dart';
import 'package:classipod/core/utils/enum_from_name.dart';
import 'package:cupertino_ui/cupertino_ui.dart';

enum VolumeMode {
  app,
  system;

  static VolumeMode fromName(String? raw) => enumFromName(values, raw, app);

  String title(BuildContext context) {
    switch (this) {
      case app:
        return context.localization.appVolumeMode;
      case system:
        return context.localization.systemVolumeMode;
    }
  }
}
