import 'package:flutter/material.dart';

class AppLabeledTextField extends StatelessWidget {
  const AppLabeledTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.prefixIcon,
    this.enabled = true,
    this.interactive = true,
    this.hintText,
  });

  final String label;
  final TextEditingController controller;
  final IconData prefixIcon;
  final bool enabled;
  final bool interactive;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canInteract = enabled && interactive;
    final mutedColor = colorScheme.onSurface.withValues(alpha: 0.62);

    Widget textField = TextField(
      controller: controller,
      enabled: enabled,
      readOnly: !canInteract,
      canRequestFocus: canInteract,
      enableInteractiveSelection: canInteract,
      style: canInteract
          ? null
          : theme.textTheme.bodyLarge?.copyWith(color: mutedColor),
      decoration: InputDecoration(
        hintText: hintText ?? label,
        isDense: true,
        fillColor: canInteract
            ? null
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.52),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: canInteract
              ? null
              : colorScheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
    );

    if (!canInteract) {
      textField = IgnorePointer(child: textField);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            color: canInteract
                ? null
                : colorScheme.onSurface.withValues(alpha: 0.76),
          ),
        ),
        const SizedBox(height: 6),
        textField,
      ],
    );
  }
}
