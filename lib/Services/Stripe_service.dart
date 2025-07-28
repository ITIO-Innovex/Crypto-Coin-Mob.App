import 'package:flutter_stripe/flutter_stripe.dart';

class StripeService {
  static Future<void> init() async {
    Stripe.publishableKey = 'pk_test_51Rkh41RqitvdN8h5FVvUfp9ee99CChV4jzBSDyBxQ5sscD6tsXBvysVzCwtELY6zTbC4niX3uON88GrAKGtj59LO00ZWMo2Xq1';
    await Stripe.instance.applySettings();
  }

  static Future<void> makePayment(String clientSecret) async {
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Coin Craze',
        ),
      );
      await Stripe.instance.presentPaymentSheet();
    } catch (e) {
      throw Exception('Payment failed: $e');
    }
  }
}