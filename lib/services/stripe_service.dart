import 'package:blogapp/consts.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../main.dart';

class StripeService {
  StripeService._();

  static final StripeService instance = StripeService._();
  bool paymentSuccessful = false;
  Future<void> makePayment(Function(bool) onPaymentStatus) async {

    final BuildContext? context = navigationKey.currentContext;
    if (context == null) {
      onPaymentStatus(false);
      return;
    }


    try {
      print("Creating payment intent...");
      String? paymentIntentClientSecret = await _createPaymentIntent(1, "usd");
      if (paymentIntentClientSecret == null) {
        print("Failed to create payment intent.");
        onPaymentStatus(false);
        return;
      }

      print("Payment intent created. Initializing payment sheet...");
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentClientSecret,
          merchantDisplayName: AppLocalizations.of(context)!.upgradeToCustomer,
        ),
      );
      print("Payment sheet initialized.");

      try {
        print("Presenting payment sheet...");
        await Stripe.instance.presentPaymentSheet();

        print("Confirming payment...");
        await onPaymentStatus(true); // Notify success
        await Stripe.instance.confirmPaymentSheetPayment();

        print("Payment successful!");
      } catch (e, stackTrace) {
        print("Error during payment confirmation: $e");
        print("Stack trace: $stackTrace");
      }

    } catch (e) {
      print("Payment failed or was cancelled: $e");
      onPaymentStatus(false); // Notify failure
    }
  }

  Future<String?> _createPaymentIntent(int amount, String currency) async {
    try {
      final Dio dio = Dio();
      Map<String, dynamic> data = {
        "amount": _calculateAmount(amount),
        // 100 cents which equals to 1 dollar
        "currency": currency,
        // "payment_method_types[]": "card",
      };
      var response = await dio.post(
        "https://api.stripe.com/v1/payment_intents",
        data: data,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            "Authorization": "Bearer ${stripeSecretKey}",
            "Content-Type": "application/x-www-form-urlencoded"
          },
        ),
      );
      if (response.data != null) {
        print(response.data);
        return response
            .data["client_secret"]; //we can store this secret in database
      }
      return null;
    } catch (e) {
      print(e);
      throw e;
    }
    return null;
  }

  Future<void> _processPayment() async {
    try {
      Stripe.instance.presentPaymentSheet();
      await Stripe.instance.confirmPaymentSheetPayment();
    } catch (e) {
      print(e);
    }
  }

  String _calculateAmount(int amount) {
    final calculatedAmount = amount * 100;//cents
    return calculatedAmount.toString();
  }
}
