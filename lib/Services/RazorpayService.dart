import 'dart:async';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayService {
  late Razorpay _razorpay;
  late Completer<void> _paymentCompleter;

  RazorpayService() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _paymentCompleter.complete();
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _paymentCompleter.completeError(
      Exception('Payment failed: ${response.message ?? 'Unknown error'}'),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Optionally handle external wallets
  }

  Future<void> makePayment(
    String orderId,
    String key,
    double amount,
    String currency,
  ) async {
    _paymentCompleter = Completer<void>();

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
    } catch (e) {
      _paymentCompleter.completeError(Exception('Payment launch failed: $e'));
    }

    return _paymentCompleter.future;
  }

  void dispose() {
    _razorpay.clear();
  }
}
