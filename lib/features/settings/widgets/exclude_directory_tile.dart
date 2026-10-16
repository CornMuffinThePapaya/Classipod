import 'package:classipod/core/constants/app_palette.dart';
import 'package:classipod/core/extensions/build_context_extensions.dart';
import 'package:classipod/core/theme/ipod_gradients.dart';
import 'package:classipod/core/theme/ipod_typography.dart';
import 'package:classipod/core/utils/exclusion_matcher.dart';
import 'package:classipod/core/widgets/selected_marquee_text.dart';
import 'package:cupertino_ui/cupertino_ui.dart';

class ExcludeDirectoryTile extends StatelessWidget {
  final String title;
  final DirectoryExclusionState state;
  final IconData? trailingIcon;
  final Color? trailingIconColor;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ExcludeDirectoryTile({
    super.key,
    required this.title,
    required this.state,
    this.trailingIcon,
    this.trailingIconColor,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final icon = trailingIcon ?? switch (state) {
      DirectoryExclusionState.excluded => CupertinoIcons.xmark_square_fill,
      DirectoryExclusionState.included =>
        CupertinoIcons.checkmark_alt_circle_fill,
      DirectoryExclusionState.inherited => CupertinoIcons.folder_fill,
    };
    final iconColor = trailingIconColor ?? switch (state) {
      DirectoryExclusionState.excluded =>
        AppPalette.lowBatteryBarGradientColor2,
      DirectoryExclusionState.included => AppPalette.batteryBarGradientColor6,
      DirectoryExclusionState.inherited => context.appSecondaryTextColor,
    };
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: SizedBox(
        height: 30,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: isSelected
                ? const Border(
                    top: BorderSide(
                      color: AppPalette.selectedTileTopBorderColor,
                    ),
                    bottom: BorderSide(
                      color: AppPalette.selectedTileBottomBorderColor,
                    ),
                  )
                : null,
            gradient: isSelected ? IpodGradients.selectionFor(context) : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: SelectedMarqueeText(
                    title,
                    isSelected: isSelected,
                    style: IpodTypography.menu.copyWith(
                      color: isSelected
                          ? context.appInverseTextColor
                          : context.appPrimaryTextColor,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Icon(icon, color: isSelected ? null : iconColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
