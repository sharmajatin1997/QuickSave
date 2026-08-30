import 'dart:io';

import 'package:flutter/material.dart';
import '../utils/string_helper.dart';

class NeuColors {
  static const Color black = Colors.black;
  static const Color white = Colors.white;
  static const Color bg = Color(0xFFF0F0F0);
  static const Color accent = Color(0xFF00E5FF); // Cyan
  static const Color primary = Color(0xFFFF5252); // Coral
  static const Color secondary = Color(0xFFFFD740); // Amber
  static const Color header = Color(0xFFDF7A0C); // Orange/Amber
  static const Color card = Colors.white;
}

class NeuContainer extends StatelessWidget {
  final Widget child;
  final Color? color;
  final double borderRadius;
  final double shadowOffset;
  final EdgeInsets? padding;
  final BoxBorder? border;
  final double? width;
  final double? height;

  const NeuContainer({
    super.key,
    required this.child,
    this.color,
    this.borderRadius = 12,
    this.shadowOffset = 4,
    this.padding,
    this.border,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color effectiveColor = color ?? (isDark ? const Color(0xFF1E1E1E) : Colors.white);
    final Color borderColor = isDark ? Colors.white : Colors.black;
    final Color shadowColor = isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black;

    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            offset: Offset(shadowOffset, shadowOffset),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}

class NeuButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  final Color color;
  final double height;

  const NeuButton({
    super.key,
    this.onTap,
    required this.child,
    this.color = NeuColors.white,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    Color effectiveBtnColor = color;
    if (color == NeuColors.white && isDark) {
      effectiveBtnColor = const Color(0xFF333333);
    }

    // Determine text/icon color based on background brightness
    final double luminance = effectiveBtnColor.computeLuminance();
    final Color contentColor = luminance > 0.5 ? Colors.black : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: NeuContainer(
        color: onTap == null ? effectiveBtnColor.withValues(alpha: 0.5) : effectiveBtnColor,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          height: height,
          child: Center(
            child: IconTheme(
              data: IconThemeData(color: contentColor),
              child: DefaultTextStyle(
                style: TextStyle(
                  color: contentColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NeuTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData? prefixIcon;
  final Function(String)? onChanged;

  const NeuTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.prefixIcon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;

    return NeuContainer(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textAlignVertical: TextAlignVertical.center,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w900),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.normal),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: textColor) : null,
        ),
      ),
    );
  }
}

class NeuAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final double? fontSize;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;

  const NeuAppBar({
    super.key,
    required this.title,
    this.fontSize,
    this.leading,
    this.actions,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color borderColor = isDark ? Colors.white : Colors.black;
    
    return Container(
      height: preferredSize.height,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        color: NeuColors.header,
        border: Border(bottom: BorderSide(color: borderColor, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 44,
            child: leading ?? const SizedBox.shrink(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                title,
                textAlign: centerTitle ? TextAlign.center : TextAlign.start,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: fontSize ?? 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
            ),
          ),
          SizedBox(
            width: actions != null ? null : 44,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions ?? [const SizedBox.shrink()],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(Platform.isAndroid ? 100 : 120);
}

void showNeuDialog({
  required BuildContext context,
  required String title,
  required String body,
  void Function(BuildContext)? onConfirm,
  String? confirmText,
  List<Widget>? actions,
}) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      final bool isDark = Theme.of(dialogContext).brightness == Brightness.dark;
      final Color textColor = isDark ? Colors.white : Colors.black;

      return Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450), // Standard mobile-like width
          child: NeuContainer(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textColor),
                ),
                const SizedBox(height: 12),
                Text(
                  body,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF666666)),
                ),
                const SizedBox(height: 24),
                if (actions != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: actions,
                  )
                else
                  NeuButton(
                    onTap: () {
                      if (onConfirm != null) {
                        onConfirm(dialogContext);
                      } else {
                        Navigator.pop(dialogContext);
                      }
                    },
                    color: NeuColors.accent,
                    height: 48,
                    child: Text(confirmText ?? StringHelper.ok),
                  ),
              ],
            ),
          ),
        ));
    },
  );
}

Widget buildCircleIcon(IconData icon, VoidCallback onTap) {
  return Builder(builder: (context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color borderColor = isDark ? Colors.white : Colors.black;
    final Color bgColor = isDark ? const Color(0xFF333333) : Colors.white;
    final Color iconColor = isDark ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(color: borderColor.withValues(alpha: 1), offset: const Offset(2, 2)),
          ],
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
    );
  });
}
