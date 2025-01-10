import 'dart:convert';
import 'package:blogapp/constants.dart';
import 'package:blogapp/NetworkHandler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import '../DailyRevenue.dart';
import 'package:http/http.dart' as http;

import '../fetchStripeBalance.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final NetworkHandler networkHandler = NetworkHandler();

  int totalUsers = 0; // # of users with role="user"
  int totalCustomers = 0; // # of users with role="customer"
  double totalRevenue = 0.0; // 1$ for each user who converted to "customer"
  List<DailyRevenue> stripeRevenueData = [];
  double stripeBalance = 0.0;

  /// We'll store everyone (both user & customer) in here.
  List<dynamic> allUsers = [];

  bool isLoading = true;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
    fetchStripeData();
    fetchCurrentBalance(); // <--- We'll create a helper for that
  }

  Future<void> fetchCurrentBalance() async {
    try {
      final bal = await fetchStripeBalance();
      setState(() {
        stripeBalance = bal;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Error fetching Stripe balance: $e";
      });
    }
  }

  // Calls Stripe API for last 7 days of charges
  Future<List<DailyRevenue>> fetchStripeRevenue() async {
    const stripeSecretKey =
        "sk_test_51QNyfBKoUnO9DwNCB4F6XVvNxvsKDou7MWK4EVMEi6CFbztd8cK0xeFche75RbluMJlodblbZCoVzRIAszadYzps0020wvnUlm";
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final unix7DaysAgo = (sevenDaysAgo.millisecondsSinceEpoch / 1000).floor();
    final url = Uri.parse(
        "https://api.stripe.com/v1/charges?created[gte]=$unix7DaysAgo&limit=100");

    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $stripeSecretKey",
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
          "Failed to load charges from Stripe. Status: ${response.statusCode}");
    }

    final data = jsonDecode(response.body);
    final List charges = data["data"];

    Map<String, double> dailyTotals = {};

    for (var charge in charges) {
      final created = charge["created"]; // Unix timestamp
      final date = DateTime.fromMillisecondsSinceEpoch(created * 1000);
      final dateStr = date.toString().split(" ")[0];

      final amountInCents = charge["amount"] ?? 0;
      final amountInDollars = amountInCents / 100.0;

      if (!dailyTotals.containsKey(dateStr)) {
        dailyTotals[dateStr] = 0;
      }
      dailyTotals[dateStr] = (dailyTotals[dateStr] ?? 0) + amountInDollars;
    }

    List<DailyRevenue> revenueList = [];
    dailyTotals.forEach((dStr, amt) {
      final parts = dStr.split("-");
      revenueList.add(DailyRevenue(
        date: DateTime(
            int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2])),
        amount: amt,
      ));
    });

    revenueList.sort((a, b) => a.date.compareTo(b.date));
    return revenueList;
  }

  /// This will fetch from Stripe and compute total
  Future<void> fetchStripeData() async {
    try {
      setState(() {
        isLoading = true;
      });

      final List<DailyRevenue> data = await fetchStripeRevenue();
      // Save data to state
      setState(() {
        stripeRevenueData = data;
        // The total is sum of all daily amounts
        totalRevenue = data.fold(0.0, (sum, item) => sum + item.amount);
        print("DEBUG: final totalRevenue = $totalRevenue");
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Error fetching Stripe data: $e";
        isLoading = false;
      });
    }
  }

  Future<void> fetchDashboardData() async {
    try {
      // Re-use the same endpoint from your UsersScreen: "/user/getUsers"
      // which returns something like:
      // { "data": [ { "role": "user|customer", "createdAt": "...", ... } ] }

      final response = await networkHandler.get("/user/getUsers");
      if (response == null || response["data"] == null) {
        setState(() {
          errorMessage = "No data returned from server";
          isLoading = false;
        });
        return;
      }

      // The "data" array
      final List<dynamic> usersData = response["data"];

      int countUsers = 0;
      int countCustomers = 0;

      // Tally up roles
      for (final item in usersData) {
        final role = item["role"];
        if (role == "user") {
          countUsers++;
        } else if (role == "customer") {
          countCustomers++;
        }
      }

      // total revenue = # of customers * 1$
      //  final revenue = countCustomers * 1.0;

      // Sort them by createdAt descending if desired
      // (only if your user doc has "createdAt")
      usersData.sort((a, b) {
        final dateA = DateTime.tryParse(a["createdAt"] ?? "") ?? DateTime(1970);
        final dateB = DateTime.tryParse(b["createdAt"] ?? "") ?? DateTime(1970);
        // Sort descending => newer first
        return dateB.compareTo(dateA);
      });

      setState(() {
        allUsers = usersData;
        totalUsers = countUsers;
        totalCustomers = countCustomers;
        //  totalRevenue = revenue;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Error: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(child: Text(errorMessage));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // =============== Row of Stats (with horizontal scroll) ==================
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              // If screen is wide, they appear side-by-side; narrow => user can scroll
              children: [
                _buildStatCard(
                  title: AppLocalizations.of(context)!.totalUsers,
                  value: "$totalUsers",
                  color: Colors.blueAccent,
                  icon: Icons.group,
                ),
                const SizedBox(width: 8),
                _buildStatCard(
                  title: AppLocalizations.of(context)!.totalCustomers,
                  value: "$totalCustomers",
                  color: Colors.green,
                  icon: Icons.person_add_alt,
                ),
                const SizedBox(width: 8),
                // _buildStatCard(
                //   title: AppLocalizations.of(context)!.revenue,
                //   value: "\$$totalRevenue",
                //   color: Colors.purple,
                //   icon: Icons.attach_money,
                //   // When user taps revenue, show chart
                //   onTap: () {
                //     showDialog(
                //       context: context,
                //       builder: (_) => _buildRevenueChartDialog(),
                //     );
                //   },
                // ),
                _buildStatCard(
                  title: AppLocalizations.of(context)!.revenue,
                  // or translate as you wish
                  value: "\$${stripeBalance.toStringAsFixed(2)}",
                  color: Colors.orange,
                  icon: Icons.account_balance_wallet,
                  onTap: () {
                    // Maybe show a bar chart for daily revenue, or do nothing
                    showDialog(
                      context: context,
                      builder: (_) =>
                          _buildBarChartDialog(), // we'll define this
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // =============== Title "All Users & Customers" (or "New Comers") ========
          Row(
            mainAxisAlignment:
                kIsWeb ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.usersAndCustomers,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // =============== Enhanced Data Table with Card =======================
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateColor.resolveWith(
                      (states) => Colors.blueGrey.shade200),
                  dataRowHeight: kIsWeb ? 60 : 48,
                  headingRowHeight: kIsWeb ? 60 : 48,
                  columnSpacing: kIsWeb ? 40 : 20,
                  columns: [
                    DataColumn(
                      label: Text(
                        AppLocalizations.of(context)!.username,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: kIsWeb ? 18 : 14),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        AppLocalizations.of(context)!.email,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: kIsWeb ? 18 : 14),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        AppLocalizations.of(context)!.role,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: kIsWeb ? 18 : 14),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        AppLocalizations.of(context)!.createdAt,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: kIsWeb ? 18 : 14),
                      ),
                    ),
                  ],
                  rows: allUsers.map((user) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            user["username"] ?? "",
                            style: TextStyle(fontSize: kIsWeb ? 18 : 14),
                          ),
                        ),
                        DataCell(
                          Text(
                            user["email"] ?? "",
                            style: TextStyle(fontSize: kIsWeb ? 18 : 14),
                          ),
                        ),
                        DataCell(
                          Text(
                            AppLocalizations.of(context)!
                                .translateRole(user["role"] ?? ""),
                            style: TextStyle(
                              fontSize: kIsWeb ? 18 : 14,
                              color: user["role"] == "customer"
                                  ? Colors.green
                                  : Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            user["createdAt"]?.toString().split("T").first ??
                                "",
                            style: TextStyle(fontSize: kIsWeb ? 18 : 14),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// A helper method to build a single card for a dashboard statistic
  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: color,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          width: 200,
          height: 142,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueChartDialog() {
    return AlertDialog(
      title: const Text(
        "Revenue (Last 7 Days)",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 300,
        height: 300,
        child: _buildLineChart(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Close"),
        ),
      ],
    );
  }

  Widget _buildLineChart() {
    // For safety, if stripeRevenueData is empty, show an empty chart
    if (stripeRevenueData.isEmpty) {
      return const Center(child: Text("No revenue data for the last 7 days"));
    }

    // Build a list of the last 7 days in ascending order
    final now = DateTime.now();
    final dayLabels = <String>[];
    final spots = <FlSpot>[];

    // We assume stripeRevenueData is sorted ascending by date
    // We'll map them by day "YYYY-MM-DD" to the amount
    final Map<String, double> dailyMap = {
      // We'll fill below
    };
    for (var dr in stripeRevenueData) {
      final key = dr.date.toString().split(" ")[0]; // "YYYY-MM-DD"
      dailyMap[key] = dr.amount;
    }

    // Generate exactly 7 days (including today) in ascending order
    final List<DateTime> last7Days = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return DateTime(d.year, d.month, d.day);
    });

    for (int i = 0; i < 7; i++) {
      final date = last7Days[i];
      final dateString = date.toString().split(" ")[0];

      final double amount = dailyMap[dateString] ?? 0.0;
      // We'll use i as the X-value, amount as Y-value
      spots.add(FlSpot(i.toDouble(), amount));

      // Label like "Jan 03"
      dayLabels.add("${date.month}/${date.day}");
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 6,
        minY: 0,
        // If you have higher amounts, adjust maxY or set it dynamically
        // Or let FLChart handle it by not specifying
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 3,
            color: Colors.purple,
            dotData: FlDotData(show: true),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index > 6) return const SizedBox.shrink();
                return Text(dayLabels[index],
                    style: const TextStyle(fontSize: 12));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
        ),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: true),
      ),
    );
  }

  Widget _buildBarChartDialog() {
    return AlertDialog(
      title: const Text("Daily Revenue (Bar Chart)"),
      content: SizedBox(
        width: 300,
        height: 300,
        child: _buildBarChart(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Close"),
        ),
      ],
    );
  }

  Widget _buildBarChart() {
    if (stripeRevenueData.isEmpty) {
      return const Center(child: Text("No revenue data available"));
    }

    final now = DateTime.now();
    final Map<String, double> dailyMap = {};

    // 1) Aggregate amounts by day "YYYY-MM-DD"
    for (var dr in stripeRevenueData) {
      final dateStr = dr.date.toString().split(" ")[0];
      dailyMap[dateStr] = (dailyMap[dateStr] ?? 0) + dr.amount;
    }

    // 2) Generate a list of the last 7 days in ascending order
    final last7Days = List.generate(7, (index) {
      final d = now.subtract(Duration(days: 6 - index));
      return DateTime(d.year, d.month, d.day);
    });

    // 3) Prepare bar chart data
    double maxBuyers = 0;
    final barSpots = <BarChartGroupData>[];

    for (int i = 0; i < last7Days.length; i++) {
      final date = last7Days[i];
      // "YYYY-MM-DD"
      final dateStr = date.toString().split(" ")[0];
      final amount = dailyMap[dateStr] ?? 0.0;

      if (amount > maxBuyers) {
        maxBuyers = amount;
      }

      // Create a bar group with one rod
      barSpots.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: amount,
              width: 16,
              color: Colors.purple,
            ),
          ],
        ),
      );
    }

    // 4) Build bottom labels like "1/4", "1/5", ...
    final dayLabels = last7Days.map((d) => "${d.month}/${d.day}").toList();

    // Round up so top line is an integer
    final topY = maxBuyers < 1 ? 1.0 : maxBuyers.ceil().toDouble();

    // 5) Return the BarChart
    return Padding(
      padding: const EdgeInsets.only(top: 16.0), // Adjust the top padding
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: topY,
          barGroups: barSpots,

          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              axisNameSize: 20, // Adjust this value for more space
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40, // Reserve space for the top titles
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),

            // Bottom (X-axis) — show each day
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= dayLabels.length) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    dayLabels[index],
                    style: const TextStyle(fontSize: 12),
                  );
                },
              ),
            ),

            // Left (Y-axis) — show only integer values
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1, // Steps of 1
                getTitlesWidget: (value, meta) {
                  if (value % 1 != 0) {
                    // Hide fractional labels
                    return const SizedBox.shrink();
                  }
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 12),
                  );
                },
              ),
            ),
          ),

          // 6) Grid lines at integer x and y values
          gridData: FlGridData(
            show: true,
            horizontalInterval: 1,
            // Only show horizontal lines at integer y
            checkToShowHorizontalLine: (val) => val % 1 == 0,

            verticalInterval: 1,
            // Only show vertical lines at integer x
            checkToShowVerticalLine: (val) => val % 1 == 0,
          ),

          // 7) Hide the border around the chart
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}
