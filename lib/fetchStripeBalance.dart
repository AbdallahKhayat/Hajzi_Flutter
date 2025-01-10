import 'dart:convert';
import 'package:http/http.dart' as http;

Future<double> fetchStripeBalance() async {
  // Replace with your actual secret key
  const stripeSecretKey = "sk_test_51QNyfBKoUnO9DwNCB4F6XVvNxvsKDou7MWK4EVMEi6CFbztd8cK0xeFche75RbluMJlodblbZCoVzRIAszadYzps0020wvnUlm";

  final url = Uri.parse("https://api.stripe.com/v1/balance");
  final response = await http.get(
    url,
    headers: {
      "Authorization": "Bearer $stripeSecretKey",
    },
  );

  if (response.statusCode != 200) {
    throw Exception("Failed to retrieve Stripe balance. Status: ${response.statusCode}");
  }

  final data = jsonDecode(response.body);
  // data["available"] is an array, each entry has "amount" in cents
  // e.g. "available": [ { "amount": 6901, "currency": "usd" }, ... ]
  final List available = data["available"] ?? [];
  if (available.isNotEmpty) {
    final amountInCents = available[0]["amount"] ?? 0;
    return amountInCents / 100.0;
  }

  return 0.0; // If no data was returned, fallback to 0
}
