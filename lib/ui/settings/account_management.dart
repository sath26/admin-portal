import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:invoiceninja_flutter/constants.dart';
import 'package:invoiceninja_flutter/data/models/entities.dart';
import 'package:invoiceninja_flutter/data/web_client.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';
import 'package:invoiceninja_flutter/redux/settings/settings_actions.dart';
import 'package:invoiceninja_flutter/ui/app/app_header.dart';
import 'package:invoiceninja_flutter/ui/app/buttons/elevated_button.dart';
import 'package:invoiceninja_flutter/ui/app/dialogs/loading_dialog.dart';
import 'package:invoiceninja_flutter/ui/app/form_card.dart';
import 'package:invoiceninja_flutter/ui/app/forms/app_dropdown_button.dart';
import 'package:invoiceninja_flutter/ui/app/forms/app_form.dart';
import 'package:invoiceninja_flutter/ui/app/edit_scaffold.dart';
import 'package:invoiceninja_flutter/ui/app/forms/bool_dropdown_button.dart';
import 'package:invoiceninja_flutter/ui/app/forms/decorated_form_field.dart';
import 'package:invoiceninja_flutter/ui/app/forms/learn_more.dart';
import 'package:invoiceninja_flutter/ui/app/icon_text.dart';
import 'package:invoiceninja_flutter/ui/app/lists/list_divider.dart';
import 'package:invoiceninja_flutter/ui/app/scrollable_listview.dart';
import 'package:invoiceninja_flutter/ui/settings/account_management_vm.dart';
import 'package:invoiceninja_flutter/utils/completers.dart';
import 'package:invoiceninja_flutter/utils/dialogs.dart';
import 'package:invoiceninja_flutter/utils/formatting.dart';
import 'package:invoiceninja_flutter/utils/icons.dart';
import 'package:invoiceninja_flutter/utils/localization.dart';
import 'package:invoiceninja_flutter/utils/platforms.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AccountManagement extends StatefulWidget {
  const AccountManagement({
    Key key,
    @required this.viewModel,
  }) : super(key: key);

  final AccountManagementVM viewModel;

  @override
  _AccountManagementState createState() => _AccountManagementState();
}

class _AccountManagementState extends State<AccountManagement>
    with SingleTickerProviderStateMixin {
  static final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>(debugLabel: '_accountManagement');
  FocusScopeNode _focusNode;
  TabController _controller;

  final _debouncer = Debouncer();
  final _trackingIdController = TextEditingController();

  List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();
    _focusNode = FocusScopeNode();

    final settingsUIState = widget.viewModel.state.settingsUIState;
    _controller = TabController(
        vsync: this, length: 4, initialIndex: settingsUIState.tabIndex);
    _controller.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    final store = StoreProvider.of<AppState>(context);
    store.dispatch(UpdateSettingsTab(tabIndex: _controller.index));
  }

  @override
  void didChangeDependencies() {
    _controllers = [
      _trackingIdController,
    ];

    _controllers
        .forEach((dynamic controller) => controller.removeListener(_onChanged));

    final viewModel = widget.viewModel;

    _trackingIdController.text = viewModel.company.googleAnalyticsKey;

    _controllers
        .forEach((dynamic controller) => controller.addListener(_onChanged));

    super.didChangeDependencies();
  }

  void _onChanged() {
    final company = widget.viewModel.company.rebuild(
        (b) => b..googleAnalyticsKey = _trackingIdController.text.trim());
    if (company != widget.viewModel.company) {
      _debouncer.run(() {
        widget.viewModel.onCompanyChanged(company);
      });
    }
  }

  @override
  void dispose() {
    _controllers.forEach((dynamic controller) {
      controller.removeListener(_onChanged);
      controller.dispose();
    });
    _focusNode.dispose();
    _controller.removeListener(_onTabChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalization.of(context);
    final viewModel = widget.viewModel;
    final state = viewModel.state;
    final company = viewModel.company;

    final durations = [
      if (!kReleaseMode)
        DropdownMenuItem<int>(
          child: Text('2 minutes'),
          value: 1000 * 60 * 2,
        ),
      DropdownMenuItem<int>(
        child: Text(localization.countMinutes.replaceFirst(':count', '30')),
        value: 1000 * 60 * 30,
      ),
      DropdownMenuItem<int>(
        child: Text(localization.countHours.replaceFirst(':count', '2')),
        value: 1000 * 60 * 60 * 2,
      ),
      DropdownMenuItem<int>(
        child: Text(localization.countHours.replaceFirst(':count', '8')),
        value: 1000 * 60 * 60 * 8,
      ),
      DropdownMenuItem<int>(
        child: Text(localization.countDay),
        value: 1000 * 60 * 60 * 24,
      ),
      DropdownMenuItem<int>(
        child: Text(localization.countDays.replaceFirst(':count', '7')),
        value: 1000 * 60 * 60 * 24 * 7,
      ),
      DropdownMenuItem<int>(
        child: Text(localization.countDays.replaceFirst(':count', '30')),
        value: 1000 * 60 * 60 * 24 * 30,
      ),
      DropdownMenuItem<int>(
        child: Text(localization.never),
        value: 0,
      ),
    ];

    return EditScaffold(
      title: localization.accountManagement,
      onSavePressed: viewModel.onSavePressed,
      appBarBottom: TabBar(
        key: ValueKey(state.settingsUIState.updatedAt),
        controller: _controller,
        isScrollable: true,
        tabs: [
          Tab(
            text: localization.overview,
          ),
          Tab(
            text: localization.enabledModules,
          ),
          Tab(
            text: localization.integrations,
          ),
          Tab(
            text: localization.securitySettings,
          ),
        ],
      ),
      body: AppTabForm(
        formKey: _formKey,
        focusNode: _focusNode,
        tabController: _controller,
        children: <Widget>[
          _AccountOverview(viewModel: viewModel),
          ScrollableListView(
            children: <Widget>[
              FormCard(
                  // TODO change to kModules.keys
                  children: kModules.keys.map((module) {
                return CheckboxListTile(
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(localization.lookup(kModules[module])),
                  value: company.enabledModules & module != 0,
                  activeColor: Theme.of(context).accentColor,
                  onChanged: (value) {
                    int enabledModules = company.enabledModules;
                    if (value) {
                      enabledModules = enabledModules | module;
                    } else {
                      enabledModules = enabledModules ^ module;
                    }
                    viewModel.onCompanyChanged(company
                        .rebuild((b) => b..enabledModules = enabledModules));
                  },
                );
              }).toList()),
            ],
          ),
          ScrollableListView(children: [
            FormCard(
              children: [
                LearnMoreUrl(
                  url: kGoogleAnalyticsUrl,
                  child: DecoratedFormField(
                    label: localization.googleAnalyticsTrackingId,
                    controller: _trackingIdController,
                  ),
                ),
              ],
            )
          ]),
          ScrollableListView(
            children: [
              FormCard(
                children: [
                  AppDropdownButton<int>(
                    labelText: localization.passwordTimeout,
                    value: company.passwordTimeout,
                    onChanged: (dynamic value) => viewModel.onCompanyChanged(
                        company.rebuild((b) => b..passwordTimeout = value)),
                    items: durations,
                  ),
                  AppDropdownButton<int>(
                    labelText: localization.webSessionTimeout,
                    value: company.sessionTimeout,
                    onChanged: (dynamic value) => viewModel.onCompanyChanged(
                        company.rebuild((b) => b..sessionTimeout = value)),
                    items: durations,
                  ),
                  BoolDropdownButton(
                      label: localization.requirePasswordWithSocialLogin,
                      value: company.oauthPasswordRequired,
                      onChanged: (value) {
                        viewModel.onCompanyChanged(company
                            .rebuild((b) => b.oauthPasswordRequired = value));
                      }),
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}

class _AccountOverview extends StatelessWidget {
  const _AccountOverview({
    Key key,
    @required this.viewModel,
  }) : super(key: key);

  final AccountManagementVM viewModel;

  @override
  Widget build(BuildContext context) {
    final store = StoreProvider.of<AppState>(context);
    final localization = AppLocalization.of(context);
    final state = viewModel.state;
    final account = state.account;
    final company = viewModel.company;
    final companies = state.companies;

    String _getDataStats() {
      String stats = '\n';
      final localization = AppLocalization.of(context);
      final state = viewModel.state;

      if (state.clientState.list.isNotEmpty) {
        final count = state.clientState.list.length;
        stats += '\n- $count ' +
            (count == 1 ? localization.client : localization.clients);
      }

      if (state.productState.list.isNotEmpty) {
        final count = state.productState.list.length;
        stats += '\n- $count ' +
            (count == 1 ? localization.product : localization.products);
      }

      if (state.invoiceState.list.isNotEmpty && !state.company.isLarge) {
        final count = state.invoiceState.list.length;
        stats += '\n- $count ' +
            (count == 1 ? localization.invoice : localization.invoices);
      }

      return stats;
    }

    String secondValue;
    String secondLabel;

    if (state.isHosted && (account.plan.isEmpty || account.isTrial)) {
      final clientLimit = viewModel.company.isMigrated ? 100 : 50;
      secondLabel = localization.clients;
      secondValue = '${viewModel.state.clientState.list.length} / $clientLimit';
    } else if (account.planExpires.isNotEmpty) {
      secondLabel = localization.expiresOn;
      secondValue = formatDate(account.planExpires, context);
    }

    return ScrollableListView(
      children: <Widget>[
        AppHeader(
          label: localization.plan,
          value: account.plan.isEmpty
              ? localization.free
              : account.isTrial
                  ? '${localization.pro} • ${localization.freeTrial}'
                  : localization.lookup(account.plan),
          secondLabel: secondLabel,
          secondValue: secondValue,
          message: account.isTrial ? localization.freeTrialHelp : null,
        ),
        if (state.userCompany.ninjaPortalUrl.isNotEmpty &&
            !isApple() &&
            state.isHosted)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 16, right: 16),
            child: Expanded(
              child: OutlinedButton(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconText(
                    icon: MdiIcons.openInNew,
                    text: localization.changePlan.toUpperCase(),
                  ),
                ),
                onPressed: () => launch(state.userCompany.ninjaPortalUrl),
              ),
            ),
          ),
        FormCard(
          children: [
            SwitchListTile(
              value: !company.isDisabled,
              onChanged: (value) {
                viewModel.onCompanyChanged(
                    company.rebuild((b) => b..isDisabled = !value));
              },
              title: Text(localization.activateCompany),
              subtitle: Text(localization.activateCompanyHelp),
              activeColor: Theme.of(context).accentColor,
            ),
            SwitchListTile(
              value: company.markdownEnabled,
              onChanged: (value) {
                viewModel.onCompanyChanged(
                    company.rebuild((b) => b..markdownEnabled = value));
              },
              title: Text(localization.enableMarkdown),
              subtitle: Text(localization.enableMarkdownHelp),
              activeColor: Theme.of(context).accentColor,
            ),
            SwitchListTile(
              value: company.reportIncludeDrafts,
              onChanged: (value) {
                viewModel.onCompanyChanged(
                    company.rebuild((b) => b..reportIncludeDrafts = value));
              },
              title: Text(localization.includeDrafts),
              subtitle: Text(localization.includeDraftsHelp),
              activeColor: Theme.of(context).accentColor,
            ),
          ],
        ),
        if (state.isSelfHosted) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: localization.purchaseLicense.toUpperCase(),
                    iconData: isMobile(context) ? null : Icons.cloud_download,
                    onPressed: () async {
                      if (await canLaunch(kWhiteLabelUrl)) {
                        launch(kWhiteLabelUrl);
                      }
                    },
                  ),
                ),
                SizedBox(width: kGutterWidth),
                Expanded(
                  child: AppButton(
                    label: localization.applyLicense.toUpperCase(),
                    iconData: isMobile(context) ? null : Icons.cloud_done,
                    onPressed: () {
                      fieldCallback(
                          context: context,
                          title: localization.applyLicense,
                          field: localization.license,
                          maxLength: 24,
                          callback: (value) {
                            final state = viewModel.state;
                            final credentials = state.credentials;
                            final url =
                                '${credentials.url}/claim_license?license_key=$value';

                            showDialog<AlertDialog>(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) => SimpleDialog(
                                      children: <Widget>[LoadingDialog()],
                                    ));

                            WebClient()
                                .post(
                              url,
                              credentials.token,
                            )
                                .then((dynamic response) {
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              }
                              viewModel.onAppliedLicense();
                            }).catchError((dynamic error) {
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              }
                              showErrorDialog(
                                  context: context, message: '$error');
                            });
                          });
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16, right: 16, left: 16),
            child: ListDivider(),
          ),
        ],
        if (state.isProPlan || state.isTrial)
          Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(
                  child: AppButton(
                    label: localization.apiTokens.toUpperCase(),
                    iconData: isMobile(context)
                        ? null
                        : getEntityIcon(EntityType.token),
                    onPressed: () {
                      store.dispatch(ViewSettings(
                        section: kSettingsTokens,
                      ));
                    },
                  ),
                ),
                SizedBox(width: kGutterWidth),
                Expanded(
                  child: AppButton(
                    label: localization.apiWebhooks.toUpperCase(),
                    iconData: isMobile(context)
                        ? null
                        : getEntityIcon(EntityType.webhook),
                    onPressed: () {
                      store.dispatch(ViewSettings(
                        section: kSettingsWebhooks,
                      ));
                    },
                  ),
                ),
              ])),
        Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(
                child: AppButton(
                  label: localization.apiDocs.toUpperCase(),
                  iconData: isMobile(context) ? null : MdiIcons.bookshelf,
                  onPressed: () => launch(kApiDocsURL),
                ),
              ),
              SizedBox(width: kGutterWidth),
              Expanded(
                child: AppButton(
                  label: 'Zapier',
                  iconData: isMobile(context) ? null : MdiIcons.cloud,
                  onPressed: () => launch(kZapierURL),
                ),
              ),
            ])),
        Padding(
          padding: const EdgeInsets.only(top: 16, right: 16, left: 16),
          child: ListDivider(),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: localization.purgeData.toUpperCase(),
                  color: Colors.red,
                  iconData: isMobile(context) ? null : Icons.delete,
                  onPressed: () {
                    confirmCallback(
                        context: context,
                        message:
                            localization.purgeDataMessage + _getDataStats(),
                        typeToConfirm: localization.purge.toLowerCase(),
                        callback: () {
                          passwordCallback(
                              alwaysRequire: true,
                              context: context,
                              callback: (password, idToken) {
                                viewModel.onPurgeData(
                                    context, password, idToken);
                              });
                        });
                  },
                ),
              ),
              SizedBox(width: kGutterWidth),
              Expanded(
                child: AppButton(
                  label: companies.length == 1
                      ? localization.cancelAccount.toUpperCase()
                      : localization.deleteCompany.toUpperCase(),
                  color: Colors.red,
                  iconData: isMobile(context) ? null : Icons.delete,
                  onPressed: () {
                    String message = companies.length == 1
                        ? localization.cancelAccountMessage
                        : localization.deleteCompanyMessage;

                    message = message.replaceFirst(
                        ':company',
                        company.displayName.isEmpty
                            ? localization.newCompany
                            : company.displayName);
                    message += _getDataStats();

                    confirmCallback(
                        context: context,
                        message: message,
                        typeToConfirm: localization.delete.toLowerCase(),
                        callback: () {
                          passwordCallback(
                              alwaysRequire: true,
                              context: context,
                              callback: (password, idToken) {
                                viewModel.onCompanyDelete(
                                    context, password, idToken);
                              });
                        });
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
