import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:http/http.dart';
import 'package:invoiceninja_flutter/utils/localization.dart';
import 'package:redux/redux.dart';

import 'package:invoiceninja_flutter/data/models/models.dart';
import 'package:invoiceninja_flutter/main_app.dart';
import 'package:invoiceninja_flutter/redux/app/app_actions.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';
import 'package:invoiceninja_flutter/redux/quote/quote_actions.dart';
import 'package:invoiceninja_flutter/redux/ui/ui_actions.dart';
import 'package:invoiceninja_flutter/ui/app/dialogs/error_dialog.dart';
import 'package:invoiceninja_flutter/ui/invoice/edit/invoice_edit_vm.dart';
import 'package:invoiceninja_flutter/ui/order_confirmation/view/order_confirmation_view_vm.dart';
import 'package:invoiceninja_flutter/ui/quote/edit/quote_edit.dart';
import 'package:invoiceninja_flutter/utils/completers.dart';

class OrderConfirmationEditScreen extends StatelessWidget {
  const OrderConfirmationEditScreen({Key? key}) : super(key: key);

  static const String route = '/order_confirmation/edit';

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, OrderConfirmationEditVM>(
      converter: (Store<AppState> store) {
        return OrderConfirmationEditVM.fromStore(store);
      },
      builder: (context, viewModel) {
        return QuoteEdit(
          viewModel: viewModel,
          key: ValueKey(viewModel.invoice!.updatedAt),
        );
      },
    );
  }
}

class OrderConfirmationEditVM extends AbstractInvoiceEditVM {
  OrderConfirmationEditVM({
    AppState? state,
    CompanyEntity? company,
    InvoiceEntity? invoice,
    int? invoiceItemIndex,
    InvoiceEntity? origInvoice,
    Function(BuildContext, [EntityAction?])? onSavePressed,
    Function(List<InvoiceItemEntity>, String?, String?)? onItemsAdded,
    bool? isSaving,
    Function(BuildContext)? onCancelPressed,
    Function(BuildContext, List<MultipartFile>, bool?)? onUploadDocument,
  }) : super(
          state: state,
          company: company,
          invoice: invoice,
          invoiceItemIndex: invoiceItemIndex,
          origInvoice: origInvoice,
          onSavePressed: onSavePressed,
          onItemsAdded: onItemsAdded,
          isSaving: isSaving,
          onCancelPressed: onCancelPressed,
          onUploadDocuments: onUploadDocument,
        );

  factory OrderConfirmationEditVM.fromStore(Store<AppState> store) {
    final AppState state = store.state;
    final orderConfirmation = state.quoteUIState.editing!;

    return OrderConfirmationEditVM(
      state: state,
      company: state.company,
      isSaving: state.isSaving,
      invoice: orderConfirmation,
      invoiceItemIndex: state.quoteUIState.editingItemIndex,
      origInvoice: store.state.quoteState.map[orderConfirmation.id],
      onSavePressed: (BuildContext context, [EntityAction? action]) {
        Debouncer.runOnComplete(() {
          final orderConfirmation = store.state.quoteUIState.editing!;
          final localization = navigatorKey.localization;
          final navigator = navigatorKey.currentState;
          if (orderConfirmation.clientId.isEmpty) {
            showDialog<ErrorDialog>(
                context: navigatorKey.currentContext!,
                builder: (BuildContext context) {
                  return ErrorDialog(localization!.pleaseSelectAClient);
                });
            return null;
          }

          final Completer<InvoiceEntity> completer = Completer<InvoiceEntity>();
          store.dispatch(SaveQuoteRequest(
            completer: completer,
            quote: orderConfirmation,
            action: action,
          ));

          return completer.future.then((savedOrderConfirmation) {
            showToast(orderConfirmation.isNew
                ? localization!.lookup('created_order_confirmation')
                : localization!.lookup('updated_order_confirmation'));

            if (state.prefState.isMobile) {
              store.dispatch(UpdateCurrentRoute(OrderConfirmationViewScreen.route));
              if (orderConfirmation.isNew) {
                navigator!.pushReplacementNamed(OrderConfirmationViewScreen.route);
              } else {
                navigator!.pop(savedOrderConfirmation);
              }
            } else {
              if (!state.prefState.isPreviewVisible) {
                store.dispatch(TogglePreviewSidebar());
              }

              store.dispatch(
                  ViewOrderConfirmation(orderConfirmationId: savedOrderConfirmation.id));

              if (state.prefState.isEditorFullScreen(EntityType.invoice) &&
                  state.prefState.editAfterSaving) {
                store.dispatch(
                    EditOrderConfirmation(orderConfirmation: savedOrderConfirmation));
              }
            }

            if (action != null && action.isClientSide) {
              handleEntityAction(savedOrderConfirmation, action);
            } else if (action != null && action.requiresSecondRequest) {
              handleEntityAction(savedOrderConfirmation, action);
              store.dispatch(
                  ViewOrderConfirmation(orderConfirmationId: savedOrderConfirmation.id));
            }
          }).catchError((Object error) {
            showDialog<ErrorDialog>(
                context: navigatorKey.currentContext!,
                builder: (BuildContext context) {
                  return ErrorDialog(error);
                });
          });
        });
      },
      onItemsAdded: (items, clientId, projectId) {
        if (items.length == 1) {
          store.dispatch(EditQuoteItem(orderConfirmation.lineItems.length));
        }
        store.dispatch(AddQuoteItems(items));
      },
      onCancelPressed: (BuildContext context) {
        createEntity(entity: InvoiceEntity(), force: true);
        if (state.uiState.previousRoute.startsWith('/order_confirmation')) {
          store.dispatch(UpdateCurrentRoute(state.uiState.previousRoute));
        } else {
          store.dispatch(ViewOrderConfirmationList());
        }
      },
      onUploadDocument: (BuildContext context,
          List<MultipartFile> multipartFile, bool? isPrivate) {
        final completer = Completer<List<DocumentEntity>>();
        store.dispatch(SaveQuoteDocumentRequest(
            isPrivate: isPrivate,
            multipartFile: multipartFile,
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
    );
  }
}
