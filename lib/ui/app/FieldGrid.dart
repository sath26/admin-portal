import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:invoiceninja_flutter/ui/app/lists/list_divider.dart';
import 'package:invoiceninja_flutter/utils/localization.dart';

class FieldGrid extends StatelessWidget {
  const FieldGrid(this.fields);

  final Map<String, String> fields;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalization.of(context);
    final textColor = Theme.of(context).textTheme.bodyText1.color;
    final List<Widget> fieldWidgets = [];

    fields.forEach((field, value) {
      if (value != null) {
        Widget text = Text(
          value.replaceAll('\n', ' '),
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 18),
        );

        if (value.contains('\n')) {
          text = Tooltip(
            message: value,
            child: text,
          );
        }

        if (value != null && value.isNotEmpty) {
          fieldWidgets.add(Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                showToast(
                  localization.copiedToClipboard.replaceFirst(
                    ':value',
                    value.replaceAll('\n', ' '),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Flexible(
                    child: Text(
                      localization.lookup(field),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor.withOpacity(.65),
                      ),
                    ),
                  ),
                  SizedBox(height: 4),
                  text,
                ],
              ),
            ),
          ));
        }
      }
    });

    if (fieldWidgets.isEmpty) {
      return Container();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          color: Theme.of(context).cardColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: LayoutBuilder(builder: (context, constraints) {
              return GridView.count(
                physics: NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                shrinkWrap: true,
                primary: true,
                crossAxisCount: 2,
                children: fieldWidgets,
                childAspectRatio: ((constraints.maxWidth / 2) - 8) / 54,
              );
            }),
          ),
        ),
        ListDivider(),
      ],
    );
  }
}
