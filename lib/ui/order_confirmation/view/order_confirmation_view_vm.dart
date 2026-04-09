import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:http/http.dart';
import 'package:invoiceninja_flutter/main_app.dart';
import 'package:redux/redux.dart';

import 'package:invoiceninja_flutter/data/models/models.dart';
import 'package:invoiceninja_flutter/redux/app/app_actions.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';
import 'package:invoiceninja_flutter/redux/quote/quote_actions.dart';
import 'package:invoiceninja_flutter/ui/app/dialogs/error_dialog.dart';
import 'package:invoiceninja_flutter/ui/invoice/view/invoice_view.dart';
import 'package:invoiceninja_flutter/ui/invoice/view/invoice_view_vm.dart';
import 'package:invoiceninja_flutter/utils/completers.dart';
import 'package:invoiceninja_flutter/utils/localization.dart';

class OrderConfirmationViewScreen extends StatelessWidget {
  const OrderConfirmationViewScreen({
    Key? key,
    this.isFilter = false,
  }) : super(key: key);

  static const String route = '/order_confirmation/view';

  final bool isFilter;

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, OrderConfirmationViewVM>(
      converter: (Store<AppState> store) {
        return OrderConfirmationViewVM.fromStore(store);
      },
      builder: (context, viewModel) {
        return InvoiceView(
          viewModel: viewModel,
          isFilter: isFilter,
          tabIndex: viewModel.state!.quoteUIState.tabIndex,
        );
      },
    );
  }
}

class OrderConfirmationViewVM extends AbstractInvoiceViewVM {
  OrderConfirmationViewVM({
    AppState? state,
    CompanyEntity? company,
    InvoiceEntity? invoice,
    ClientEntity? client,
    bool? isSaving,
    bool? isDirty,
    Function(BuildContext, EntityAction)? onEntityAction,
    Function(BuildContext, [int])? onEditPressed,
    Function(BuildContext)? onPaymentsPressed,
    Function(BuildContext, PaymentEntity)? onPaymentPressed,
    Function(BuildContext)? onRefreshed,
    Function(BuildContext, List<MultipartFile>, bool)? onUploadDocuments,
    Function(BuildContext, DocumentEntity)? onViewExpense,
    Function(BuildContext, InvoiceEntity, [String?])? onViewPdf,
  }) : super(
          state: state,
          company: company,
          invoice: invoice,
          client: client,
          isSaving: isSaving,
          isDirty: isDirty,
          onActionSelected: onEntityAction,
          onEditPressed: onEditPressed,
          onPaymentsPressed: onPaymentsPressed,
          onRefreshed: onRefreshed,
          onUploadDocuments: onUploadDocuments,
          onViewExpense: onViewExpense,
          onViewPdf: onViewPdf,
        );

  factory OrderConfirmationViewVM.fromStore(Store<AppState> store) {
    final state = store.state;
    final orderConfirmation =
        state.quoteState.map[state.quoteUIState.selectedId] ??
            InvoiceEntity(id: state.quoteUIState.selectedId);
    final client = store.state.clientState.map[orderConfirmation.clientId] ??
        ClientEntity(id: orderConfirmation.clientId);

    Future<Null> _handleRefresh(BuildContext context) {
      final completer =
          snackBarCompleter<Null>(AppLocalization.of(context)!.refreshComplete);
      store.dispatch(
          LoadQuote(completer: completer, quoteId: orderConfirmation.id));
      return completer.future;
    }

    return OrderConfirmationViewVM(
      state: state,
      company: state.company,
      isSaving: state.isSaving,
      isDirty: orderConfirmation.isNew,
      invoice: orderConfirmation,
      client: client,
      onEditPressed: (BuildContext context, [int? index]) {
        store.dispatch(EditOrderConfirmation(
          orderConfirmation: orderConfirmation,
          quoteItemIndex: index,
          completer: snackBarCompleter<InvoiceEntity>(
              AppLocalization.of(context)!
                  .lookup('updated_order_confirmation')),
        ));
      },
      onRefreshed: (context) => _handleRefresh(context),
      onEntityAction: (BuildContext context, EntityAction action) =>
          handleQuoteAction(context, [orderConfirmation], action),
      onUploadDocuments: (BuildContext context,
          List<MultipartFile> multipartFiles, bool isPrivate) {
        final completer = Completer<List<DocumentEntity>>();
        store.dispatch(SaveQuoteDocumentRequest(
            isPrivate: isPrivate,
            multipartFile: multipartFiles,
            quote: orderConfirmation,
            completer: completer));
        completer.future.then((client) {
          showToast(AppLocalization.of(navigatorKey.currentContext!)!
              .uploadedDocument);
        }).catchError((Object error) {
          showDialog<ErrorDialog>(
              context: navigatorKey.currentContext!,
              builder: (BuildContext context) {
                return ErrorDialog(error);
              });
        });
      },
      onViewPdf: (context, quote, [activityId]) {
        store.dispatch(
            ShowPdfQuote(context: context, quote: quote, activityId: activityId));
      },
    );
  }
}
