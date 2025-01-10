import 'dart:convert';
import 'package:http/http.dart' as http;

class DailyRevenue {
  final DateTime date;
  final double amount;

  DailyRevenue({required this.date, required this.amount});
}

Future<List<DailyRevenue>> fetchStripeRevenue() async {
  try {
    // Replace with your Stripe Secret Key
    const String stripeSecretKey = "sk_test_51QNyfBKoUnO9DwNCB4F6XVvNxvsKDou7MWK4EVMEi6CFbztd8cK0xeFche75RbluMJlodblbZCoVzRIAszadYzps0020wvnUlm";

    // Calculate the UNIX timestamp for (today - 7 days)
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final unix7DaysAgo = (sevenDaysAgo.millisecondsSinceEpoch / 1000).floor();

    final url = Uri.parse(
        "https://api.stripe.com/v1/charges?created[gte]=$unix7DaysAgo&limit=100");

    // Make the GET request
    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $stripeSecretKey",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to load charges from Stripe. Status: ${response.statusCode}");
    }

    final data = jsonDecode(response.body);
    final List charges = data["data"];

    // We’ll keep a map of dateString -> totalAmount for that date
    Map<String, double> dailyTotals = {};

    for (var charge in charges) {
      // "created" is a Unix timestamp in seconds
      final created = charge["created"];
      final date = DateTime.fromMillisecondsSinceEpoch(created * 1000);
      final dateString = date.toString().split(" ")[0]; // "YYYY-MM-DD"

      // If charge is refunded or incomplete, skip if you want net only
      // For simplicity, we take "amount" field. It's in cents.
      final amountInCents = charge["amount"] ?? 0;
      final amountInDollars = amountInCents / 100.0;

      if (!dailyTotals.containsKey(dateString)) {
        dailyTotals[dateString] = 0;
      }
      dailyTotals[dateString] = (dailyTotals[dateString] ?? 0) + amountInDollars;
    }

    // Convert map to a sorted list of DailyRevenue
    List<DailyRevenue> revenueList = [];
    dailyTotals.forEach((dateString, total) {
      final dateParts = dateString.split("-");
      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);
      revenueList.add(DailyRevenue(
        date: DateTime(year, month, day),
        amount: total,
      ));
    });

    // Sort by date ascending
    revenueList.sort((a, b) => a.date.compareTo(b.date));

    return revenueList;
  } catch (e) {
    rethrow;
  }
}
