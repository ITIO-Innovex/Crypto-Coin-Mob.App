import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'dart:async';

class RazorpayService {
  late Razorpay _razorpay;
  late Completer<String?> _paymentCompleter;

  RazorpayService() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _paymentCompleter.complete(response.paymentId);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _paymentCompleter.completeError(
      Exception('Payment failed: ${response.message ?? 'Unknown error'}'),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _paymentCompleter.completeError(
      Exception('External wallet selected: ${response.walletName}'),
    );
  }

  Future<String?> makePayment(
    String orderId,
    String key,
    double amount,
    String currency,
  ) async {
    _paymentCompleter = Completer<String?>();

    var options = {
      'key': key,
      'amount': (amount * 100).toInt(),
      'currency': currency,
      'order_id': orderId,
      'name': 'CoinCraze',
      'description': 'Wallet Top-up',
      'prefill': {'contact': '7017174051', 'email': 'sharmavikas@itio.in'},
    };

    try {
      _razorpay.open(options);
      return await _paymentCompleter.future;
    } catch (e) {
      _paymentCompleter.completeError(Exception('Payment launch failed: $e'));
      rethrow;
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}