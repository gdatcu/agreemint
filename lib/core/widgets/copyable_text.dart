import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A reusable widget that renders text with a 1-tap/click copy interaction,
/// displaying a clean confirmation SnackBar with the copied content.
class CopyableText extends StatelessWidget {
  final String text;
  final String? label;
  final TextStyle? style;
  final IconData? icon;
  final double iconSize;
  final Color? iconColor;
  final int? maxLines;
  final TextOverflow? overflow;

  const CopyableText({
    super.key,
    required this.text,
    this.label,
    this.style,
    this.icon,
    this.iconSize = 13,
    this.iconColor,
    this.maxLines,
    this.overflow,
  });

  /// Static helper to copy arbitrary text to clipboard with feedback snackbar.
  static Future<void> copy(
    BuildContext context, {
    required String text,
    String? label,
  }) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      final msg = label != null ? '$label copiat: $text' : 'Copiat: $text';
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  msg,
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? Theme.of(context).colorScheme.outline;

    return Tooltip(
      message: 'Apasă pentru a copia ${label?.toLowerCase() ?? ""}'.trim(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () => copy(context, text: text, label: label),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 2.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: iconSize,
                    color: effectiveIconColor,
                  ),
                  const SizedBox(width: 5),
                ],
                Flexible(
                  child: Text(
                    text,
                    style: style ?? Theme.of(context).textTheme.bodyMedium,
                    maxLines: maxLines,
                    overflow: overflow,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
