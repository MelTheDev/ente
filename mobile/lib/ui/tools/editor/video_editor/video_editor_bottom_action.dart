import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";

class VideoEditorBottomAction extends StatelessWidget {
  const VideoEditorBottomAction({
    super.key,
    required this.label,
    this.icon,
    this.svgPath,
    this.child,
    required this.onPressed,
    this.isSelected = false,
  }) : assert(icon != null || svgPath != null || child != null);

  final String label;
  final IconData? icon;
  final String? svgPath;
  final Widget? child;
  final VoidCallback onPressed;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.translucent,
      child: Column(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFFF5F5F5)
                  : const Color(0xFF252525),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).brightness == Brightness.light
                        ? const Color(0xFF424242)
                        : const Color(0xFFFFFFFF)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: icon != null
                ? Icon(icon!)
                : svgPath != null
                    ? SvgPicture.asset(
                        svgPath!,
                        colorFilter: ColorFilter.mode(
                          Theme.of(context).colorScheme.onSurface,
                          BlendMode.srcIn,
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(2),
                        child: child!,
                      ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
