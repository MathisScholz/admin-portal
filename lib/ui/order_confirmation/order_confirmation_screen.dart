import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:invoiceninja_flutter/constants.dart';
import 'package:invoiceninja_flutter/data/models/models.dart';
import 'package:invoiceninja_flutter/data/models/quote_model.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';
import 'package:invoiceninja_flutter/redux/quote/quote_actions.dart';
import 'package:invoiceninja_flutter/ui/app/app_bottom_bar.dart';
import 'package:invoiceninja_flutter/ui/app/list_filter.dart';
import 'package:invoiceninja_flutter/ui/app/list_scaffold.dart';
import 'package:invoiceninja_flutter/ui/order_confirmation/order_confirmation_list_vm.dart';
import 'package:invoiceninja_flutter/ui/order_confirmation/order_confirmation_screen_vm.dart';
import 'package:invoiceninja_flutter/ui/quote/quote_presenter.dart';
import 'package:invoiceninja_flutter/utils/localization.dart';

class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({
    Key? key,
    required this.viewModel,
  }) : super(key: key);

  static const String route = '/order_confirmation';

  final OrderConfirmationScreenVM viewModel;

  @override
  Widget build(BuildContext context) {
    final store = StoreProvider.of<AppState>(context);
    final state = store.state;
    final company = state.company;
    final userCompany = state.userCompany;
    final localization = AppLocalization.of(context)!;
    final statuses = [
      InvoiceStatusEntity().rebuild((b) => b
        ..id = kQuoteStatusDraft
        ..name = localization.draft),
      InvoiceStatusEntity().rebuild((b) => b
        ..id = kQuoteStatusSent
        ..name = localization.sent),
      InvoiceStatusEntity().rebuild((b) => b
        ..id = kQuoteStatusViewed
        ..name = localization.viewed),
      InvoiceStatusEntity().rebuild((b) => b
        ..id = kQuoteStatusApproved
        ..name = localization.approved),
      InvoiceStatusEntity().rebuild((b) => b
        ..id = kQuoteStatusConverted
        ..name = localization.converted),
      InvoiceStatusEntity().rebuild((b) => b
        ..id = kQuoteStatusExpired
        ..name = localization.expired),
      InvoiceStatusEntity().rebuild((b) => b
        ..id = kQuoteStatusBounced
        ..name = localization.bounced),
    ];

    return ListScaffold(
      entityType: EntityType.quote,
      onHamburgerLongPress: () => store.dispatch(StartQuoteMultiselect()),
      appBarTitle: ListFilter(
        key: ValueKey('__filter_${state.quoteListState.filterClearedAt}__'),
        entityType: EntityType.quote,
        entityIds: viewModel.orderConfirmationList,
        filter: state.quoteListState.filter,
        onFilterChanged: (value) => store.dispatch(FilterQuotes(value)),
        onSelectedState: (EntityState state, value) {
          store.dispatch(FilterQuotesByState(state));
        },
        onSelectedStatus: (EntityStatus status, value) {
          store.dispatch(FilterQuotesByStatus(status));
        },
        statuses: statuses,
      ),
      onCheckboxPressed: () {
        if (store.state.quoteListState.isInMultiselect()) {
          store.dispatch(ClearQuoteMultiselect());
        } else {
          store.dispatch(StartQuoteMultiselect());
        }
      },
      body: OrderConfirmationListBuilder(),
      bottomNavigationBar: AppBottomBar(
        entityType: EntityType.quote,
        tableColumns: QuotePresenter.getAllTableFields(userCompany),
        defaultTableColumns: QuotePresenter.getDefaultTableFields(userCompany),
        onSelectedSortField: (value) => store.dispatch(SortQuotes(value)),
        customValues1:
            company.getCustomFieldValues(CustomFieldType.invoice1, excludeBlank: true),
        customValues2:
            company.getCustomFieldValues(CustomFieldType.invoice2, excludeBlank: true),
        customValues3:
            company.getCustomFieldValues(CustomFieldType.invoice3, excludeBlank: true),
        customValues4:
            company.getCustomFieldValues(CustomFieldType.invoice4, excludeBlank: true),
        onSelectedCustom1: (value) =>
            store.dispatch(FilterQuotesByCustom1(value)),
        onSelectedCustom2: (value) =>
            store.dispatch(FilterQuotesByCustom2(value)),
        onSelectedCustom3: (value) =>
            store.dispatch(FilterQuotesByCustom3(value)),
        onSelectedCustom4: (value) =>
            store.dispatch(FilterQuotesByCustom4(value)),
        sortFields: [
          QuoteFields.number,
          QuoteFields.date,
          QuoteFields.validUntil,
          QuoteFields.updatedAt,
        ],
        onSelectedState: (EntityState state, value) {
          store.dispatch(FilterQuotesByState(state));
        },
        onSelectedStatus: (EntityStatus status, value) {
          store.dispatch(FilterQuotesByStatus(status));
        },
        statuses: statuses,
        onCheckboxPressed: () {
          if (store.state.quoteListState.isInMultiselect()) {
            store.dispatch(ClearQuoteMultiselect());
          } else {
            store.dispatch(StartQuoteMultiselect());
          }
        },
      ),
      floatingActionButton: state.prefState.isMenuFloated &&
              userCompany.canCreate(EntityType.quote)
          ? FloatingActionButton(
              heroTag: 'order_confirmation_fab',
              backgroundColor: Theme.of(context).primaryColorDark,
              onPressed: () {
                store.dispatch(EditOrderConfirmation(
                  orderConfirmation: InvoiceEntity(
                    state: state,
                    entityType: EntityType.quote,
                    user: state.user,
                  ).rebuild((b) => b..documentType = 'order_confirmation'),
                ));
              },
              child: const Icon(
                Icons.add,
                color: Colors.white,
              ),
              tooltip: localization.lookup('new_order_confirmation'),
            )
          : null,
    );
  }
}
