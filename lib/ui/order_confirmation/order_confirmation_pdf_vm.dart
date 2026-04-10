import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

import 'package:invoiceninja_flutter/redux/app/app_state.dart';
import 'package:invoiceninja_flutter/ui/invoice/invoice_pdf.dart';
import 'package:invoiceninja_flutter/ui/quote/quote_pdf_vm.dart';

class OrderConfirmationPdfScreen extends StatelessWidget {
  const OrderConfirmationPdfScreen({Key? key, this.showAppBar = true})
      : super(key: key);

  final bool showAppBar;

  static const String route = '/order_confirmation/pdf';

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, QuotePdfVM>(
      converter: (Store<AppState> store) {
        return QuotePdfVM.fromStore(store);
      },
      builder: (context, vm) {
        return InvoicePdfView(
          key: ValueKey('__order_confirmation_pdf_${vm.invoice!.id}__'),
          viewModel: vm,
          showAppBar: showAppBar,
        );
      },
    );
  }
}
