import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:built_collection/built_collection.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

import 'package:invoiceninja_flutter/data/models/models.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';
import 'package:invoiceninja_flutter/redux/quote/quote_actions.dart';
import 'package:invoiceninja_flutter/redux/quote/quote_selectors.dart';
import 'package:invoiceninja_flutter/ui/app/tables/entity_list.dart';
import 'package:invoiceninja_flutter/ui/invoice/invoice_list_vm.dart';
import 'package:invoiceninja_flutter/ui/quote/quote_list_item.dart';
import 'package:invoiceninja_flutter/ui/quote/quote_presenter.dart';
import 'package:invoiceninja_flutter/utils/completers.dart';
import 'package:invoiceninja_flutter/utils/localization.dart';

class OrderConfirmationListBuilder extends StatelessWidget {
  const OrderConfirmationListBuilder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, OrderConfirmationListVM>(
      converter: OrderConfirmationListVM.fromStore,
      builder: (context, viewModel) {
        return EntityList(
          onClearMultiselect: viewModel.onClearMultiselect,
          entityType: EntityType.quote,
          presenter: QuotePresenter(),
          state: viewModel.state,
          entityList: viewModel.invoiceList,
          tableColumns: viewModel.tableColumns,
          onRefreshed: viewModel.onRefreshed,
          onSortColumn: viewModel.onSortColumn,
          onTapEntity: (entity) {
            viewModel.onViewOrderConfirmation(entity as InvoiceEntity);
          },
          onViewEntityId: (entityId) {
            if ((entityId ?? '').isNotEmpty) {
              viewModel.onViewOrderConfirmationById(entityId!);
            }
          },
          itemBuilder: (BuildContext context, index) {
            final invoiceId = viewModel.invoiceList[index];
            final invoice = viewModel.invoiceMap[invoiceId]!;

            return QuoteListItem(
              filter: viewModel.filter,
              quote: invoice,
              onTap: () => viewModel.onViewOrderConfirmation(invoice),
              onLongPress: () =>
                  viewModel.onEditOrderConfirmation(invoice),
              onEntityAction: (action) =>
                  viewModel.onEntityAction(context, [invoice], action),
            );
          },
        );
      },
    );
  }
}

class OrderConfirmationListVM extends EntityListVM {
  OrderConfirmationListVM({
    required AppState state,
    required List<String> invoiceList,
    required BuiltMap<String, InvoiceEntity> invoiceMap,
    required BuiltMap<String, ClientEntity> clientMap,
    required String? filter,
    required bool isLoading,
    required Function(BuildContext) onRefreshed,
    required this.onViewOrderConfirmation,
    required this.onViewOrderConfirmationById,
    required this.onEditOrderConfirmation,
    required Function(BuildContext, List<InvoiceEntity>, EntityAction?)
        onEntityAction,
    required List<String> tableColumns,
    required EntityType entityType,
    required Function(String) onSortColumn,
    required Function onClearMultiselect,
  }) : super(
          state: state,
          invoiceList: invoiceList,
          invoiceMap: invoiceMap,
          clientMap: clientMap,
          filter: filter,
          isLoading: isLoading,
          onRefreshed: onRefreshed,
          tableColumns: tableColumns,
          entityType: entityType,
          onSortColumn: onSortColumn,
          onClearMultiselect: onClearMultiselect,
        ) {
    this.onEntityAction = onEntityAction;
  }

  late final Function(BuildContext, List<InvoiceEntity>, EntityAction?)
      onEntityAction;
  final Function(InvoiceEntity) onViewOrderConfirmation;
  final Function(String) onViewOrderConfirmationById;
  final Function(InvoiceEntity) onEditOrderConfirmation;

  static OrderConfirmationListVM fromStore(Store<AppState> store) {
    Future<Null> _handleRefresh(BuildContext context) {
      if (store.state.isLoading) {
        return Future<Null>.value();
      }
      final completer =
          snackBarCompleter<Null>(AppLocalization.of(context)!.refreshComplete);
      store.dispatch(LoadOrderConfirmations(completer: completer));
      return completer.future;
    }

    final state = store.state;

    return OrderConfirmationListVM(
      state: state,
      invoiceList: memoizedFilteredOrderConfirmationList(
        state.getUISelection(EntityType.quote),
        state.quoteState.map,
        state.quoteState.list,
        state.clientState.map,
        state.vendorState.map,
        state.quoteListState,
        state.userState.map,
      ),
      invoiceMap: state.quoteState.map,
      clientMap: state.clientState.map,
      isLoading: state.isLoading,
      filter: state.quoteListState.filter,
      onRefreshed: (context) => _handleRefresh(context),
      onViewOrderConfirmation: (quote) {
        store.dispatch(ViewOrderConfirmation(orderConfirmationId: quote.id));
      },
      onViewOrderConfirmationById: (quoteId) {
        store.dispatch(ViewOrderConfirmation(orderConfirmationId: quoteId));
      },
      onEditOrderConfirmation: (quote) {
        store.dispatch(EditOrderConfirmation(orderConfirmation: quote));
      },
      onEntityAction: (BuildContext context, List<InvoiceEntity> quotes,
              EntityAction? action) =>
          handleQuoteAction(context, quotes, action),
      tableColumns:
          state.userCompany.settings.getTableColumns(EntityType.quote) ??
              QuotePresenter.getDefaultTableFields(state.userCompany),
      onSortColumn: (field) => store.dispatch(SortQuotes(field)),
      onClearMultiselect: () => store.dispatch(ClearQuoteMultiselect()),
      entityType: EntityType.quote,
    );
  }
}
