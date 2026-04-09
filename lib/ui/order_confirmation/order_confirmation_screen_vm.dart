import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:invoiceninja_flutter/data/models/models.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';
import 'package:invoiceninja_flutter/redux/quote/quote_selectors.dart';
import 'package:redux/redux.dart';

import 'order_confirmation_screen.dart';

class OrderConfirmationScreenBuilder extends StatelessWidget {
  const OrderConfirmationScreenBuilder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, OrderConfirmationScreenVM>(
      converter: OrderConfirmationScreenVM.fromStore,
      builder: (context, vm) {
        return OrderConfirmationScreen(viewModel: vm);
      },
    );
  }
}

class OrderConfirmationScreenVM {
  OrderConfirmationScreenVM({
    required this.isInMultiselect,
    required this.orderConfirmationList,
    required this.userCompany,
    required this.quoteMap,
  });

  final bool isInMultiselect;
  final UserCompanyEntity? userCompany;
  final List<String> orderConfirmationList;
  final BuiltMap<String, InvoiceEntity> quoteMap;

  static OrderConfirmationScreenVM fromStore(Store<AppState> store) {
    final state = store.state;

    return OrderConfirmationScreenVM(
      quoteMap: state.quoteState.map,
      orderConfirmationList: memoizedFilteredOrderConfirmationList(
        state.getUISelection(EntityType.quote),
        state.quoteState.map,
        state.quoteState.list,
        state.clientState.map,
        state.vendorState.map,
        state.quoteListState,
        state.userState.map,
      ),
      userCompany: state.userCompany,
      isInMultiselect: state.quoteListState.isInMultiselect(),
    );
  }
}
