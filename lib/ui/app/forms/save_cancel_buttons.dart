import 'package:flutter/material.dart';
import 'package:invoiceninja_flutter/ui/app/buttons/action_flat_button.dart';
import 'package:invoiceninja_flutter/ui/app/buttons/app_text_button.dart';
import 'package:invoiceninja_flutter/utils/localization.dart';

class SaveCancelButtons extends StatelessWidget {
  const SaveCancelButtons({
    this.onSavePressed,
    this.onCancelPressed,
    this.saveLabel,
    this.cancelLabel,
    this.isHeader = true,
    this.isSaving = false,
    this.isEnabled = true,
    this.isCancelEnabled = false,
  });

  final bool isEnabled;
  final bool isCancelEnabled;
  final bool isSaving;
  final String saveLabel;
  final String cancelLabel;
  final bool isHeader;
  final Function(BuildContext) onCancelPressed;
  final Function(BuildContext) onSavePressed;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalization.of(context);

    return Row(
      crossAxisAlignment:
          isHeader ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
      children: <Widget>[
        if (onCancelPressed != null && !isSaving)
          Builder(builder: (BuildContext context) {
            return AppTextButton(
              label: cancelLabel ?? localization.cancel,
              isInHeader: isHeader && (isEnabled || isCancelEnabled),
              onPressed: isEnabled || isCancelEnabled
                  ? () => onCancelPressed(context)
                  : null,
            );
          }),
        Builder(builder: (BuildContext context) {
          return ActionTextButton(
            tooltip: saveLabel ?? localization.save,
            isVisible: true,
            isSaving: isSaving,
            isHeader: isHeader,
            onPressed: isEnabled ? () => onSavePressed(context) : null,
          );
        }),
      ],
    );
  }
}
