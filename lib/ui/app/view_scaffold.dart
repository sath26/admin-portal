import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:invoiceninja_flutter/data/models/entities.dart';
import 'package:invoiceninja_flutter/data/models/models.dart';
import 'package:invoiceninja_flutter/redux/app/app_actions.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';
import 'package:invoiceninja_flutter/redux/ui/ui_actions.dart';
import 'package:invoiceninja_flutter/ui/app/actions_menu_button.dart';
import 'package:invoiceninja_flutter/ui/app/blank_screen.dart';
import 'package:invoiceninja_flutter/ui/app/buttons/app_text_button.dart';
import 'package:invoiceninja_flutter/ui/app/presenters/entity_presenter.dart';
import 'package:invoiceninja_flutter/utils/localization.dart';
import 'package:invoiceninja_flutter/utils/platforms.dart';

class ViewScaffold extends StatelessWidget {
  const ViewScaffold({
    @required this.body,
    @required this.entity,
    this.floatingActionButton,
    this.appBarBottom,
    this.isFilter = false,
    this.onBackPressed,
  });

  final bool isFilter;
  final BaseEntity entity;
  final Widget body;
  final Function onBackPressed;
  final Widget floatingActionButton;
  final Widget appBarBottom;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalization.of(context);
    final store = StoreProvider.of<AppState>(context);
    final state = store.state;
    final userCompany = state.userCompany;
    final isSettings = entity.entityType.isSetting;

    String title;
    if (entity.isNew) {
      title = '';
    } else {
      final presenter = EntityPresenter().initialize(entity, context);
      title = presenter.title;
    }

    Widget leading;
    if (isDesktop(context)) {
      if (isFilter == true &&
          entity.entityType == state.uiState.filterEntityType) {
        if (state.uiState.filterStack.length > 1) {
          leading = IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => store.dispatch(PopFilterStack()),
          );
        } else {
          leading = IconButton(
            icon: Icon(Icons.clear),
            onPressed: () {
              store.dispatch(UpdateUserPreferences(isFilterVisible: false));
            },
          );
        }
      } else if (state.uiState.previewStack.isNotEmpty) {
        leading = IconButton(
            tooltip: localization.back,
            icon: Icon(Icons.arrow_back),
            onPressed: () => store.dispatch(PopPreviewStack()));
      } else if (isDesktop(context) && !entity.entityType.isSetting) {
        leading = IconButton(
          icon: Icon(Icons.clear),
          onPressed: () {
            store.dispatch(UpdateUserPreferences(isPreviewVisible: false));
          },
        );
      }
    }

    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: FocusTraversalGroup(
        child: Scaffold(
          backgroundColor: Theme.of(context).cardColor,
          appBar: AppBar(
            centerTitle: false,
            leading: leading,
            automaticallyImplyLeading: isMobile(context),
            title: Text(title),
            bottom: appBarBottom,
            actions: entity.isNew
                ? []
                : [
                    if (isSettings && isDesktop(context) && !isFilter)
                      TextButton(
                          onPressed: () {
                            onBackPressed != null
                                ? onBackPressed()
                                : store.dispatch(UpdateCurrentRoute(
                                    state.uiState.previousRoute));
                          },
                          child: Text(
                            localization.back,
                            style: TextStyle(color: state.headerTextColor),
                          )),
                    if (userCompany.canEditEntity(entity))
                      Builder(builder: (context) {
                        final isDisabled = state.uiState.isEditing &&
                            state.uiState.mainRoute ==
                                state.uiState.filterEntityType.toString();

                        return AppTextButton(
                          label: localization.edit,
                          isInHeader: true,
                          onPressed: isDisabled
                              ? null
                              : () {
                                  editEntity(context: context, entity: entity);
                                },
                        );
                      }),
                    ViewActionMenuButton(
                      isSaving: state.isSaving && !isFilter,
                      entity: entity,
                      onSelected: (context, action) =>
                          handleEntityAction(entity, action, autoPop: true),
                      entityActions: entity.getActions(
                        userCompany: userCompany,
                        client: entity is BelongsToClient
                            ? state.clientState
                                .map[(entity as BelongsToClient).clientId]
                            : null,
                      ),
                    ),
                  ],
          ),
          body:
              entity.isNew ? BlankScreen(localization.noRecordSelected) : body,
        ),
      ),
    );
  }
}
