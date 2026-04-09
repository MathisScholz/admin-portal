import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

import 'package:invoiceninja_flutter/data/models/models.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';
import 'package:invoiceninja_flutter/redux/client/client_actions.dart';
import 'package:invoiceninja_flutter/redux/quote/quote_actions.dart';
import 'package:invoiceninja_flutter/ui/app/invoice/invoice_email_view.dart';
import 'package:invoiceninja_flutter/ui/invoice/invoice_email_vm.dart';
import 'package:invoiceninja_flutter/utils/completers.dart';
import 'package:invoiceninja_flutter/utils/localization.dart';
import 'package:invoiceninja_flutter/utils/platforms.dart';

class OrderConfirmationEmailScreen extends StatelessWidget {
  const OrderConfirmationEmailScreen({Key? key}) : super(key: key);

  static const String route = '/order_confirmation/email';

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, EmailOrderConfirmationVM>(
      onInit: (Store<AppState> store) {
        final state = store.state;
        final orderConfirmationId = state.uiState.quoteUIState.selectedId;
        final orderConfirmation = state.quoteState.map[orderConfirmationId]!;
        final client = state.clientState.map[orderConfirmation.clientId]!;
        if (client.isStale) {
          store.dispatch(LoadClient(clientId: client.id));
        }
      },
      converter: (Store<AppState> store) {
        final state = store.state;
        final orderConfirmationId = state.uiState.quoteUIState.selectedId;
        final orderConfirmation = state.quoteState.map[orderConfirmationId]!;
        return EmailOrderConfirmationVM.fromStore(store, orderConfirmation);
      },
      builder: (context, viewModel) {
        return InvoiceEmailView(
          key: ValueKey('__order_confirmation_email_${viewModel.invoice!.id}__'),
          viewModel: viewModel,
        );
      },
    );
  }
}

class EmailOrderConfirmationVM extends EmailEntityVM {
  EmailOrderConfirmationVM({
    required AppState state,
    required bool isLoading,
    required bool isSaving,
    required CompanyEntity? company,
    required InvoiceEntity invoice,
    required ClientEntity? client,
    required VendorEntity? vendor,
    required Function(BuildContext, EmailTemplate, String, String, String)
        onSendPressed,
  }) : super(
          state: state,
          isLoading: isLoading,
          isSaving: isSaving,
          company: company,
          invoice: invoice,
          client: client,
          vendor: vendor,
          onSendPressed: onSendPressed,
        );

  factory EmailOrderConfirmationVM.fromStore(
      Store<AppState> store, InvoiceEntity orderConfirmation) {
    final state = store.state;

    return EmailOrderConfirmationVM(
      state: state,
      isLoading: state.isLoading,
      isSaving: state.isSaving,
      company: state.company,
      invoice: orderConfirmation,
      client: state.clientState.map[orderConfirmation.clientId],
      vendor: state.vendorState.map[orderConfirmation.vendorId],
      onSendPressed: (context, template, subject, body, ccEmail) {
        final completer = snackBarCompleter<Null>(
            AppLocalization.of(context)!.lookup('emailed_order_confirmation'),
            shouldPop: isMobile(context));
        if (!isMobile(context)) {
          completer.future.then<Null>((_) {
            store.dispatch(ViewOrderConfirmation(
                orderConfirmationId: orderConfirmation.id));
          });
        }
        store.dispatch(EmailQuoteRequest(
          completer: completer,
          quoteId: orderConfirmation.id,
          template: template,
          subject: subject,
          body: body,
          ccEmail: ccEmail,
        ));
      },
    );
  }
}
