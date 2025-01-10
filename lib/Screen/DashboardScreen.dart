import 'dart:convert';
import 'package:blogapp/constants.dart';
import 'package:blogapp/NetworkHandler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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

  /// We'll store everyone (both user & customer) in here.
  List<dynamic> allUsers = [];

  bool isLoading = true;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
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
      final revenue = countCustomers * 1.0;

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
        totalRevenue = revenue;
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
                _buildStatCard(
                  title: AppLocalizations.of(context)!.revenue,
                  value: "\$$totalRevenue",
                  color: Colors.purple,
                  icon: Icons.attach_money,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // =============== Title "All Users & Customers" (or "New Comers") ========
          Row(
            mainAxisAlignment: kIsWeb ? MainAxisAlignment.center : MainAxisAlignment.start,
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
                  headingRowColor: MaterialStateColor.resolveWith((states) => Colors.blueGrey.shade200),
                  dataRowHeight: kIsWeb ? 60 : 48,
                  headingRowHeight: kIsWeb ? 60 : 48,
                  columnSpacing: kIsWeb ? 40 : 20,
                  columns: [
                    DataColumn(
                      label: Text(
                          AppLocalizations.of(context)!.username,
                        style: const TextStyle(fontWeight: FontWeight.bold,fontSize: kIsWeb ? 18 : 14),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                          AppLocalizations.of(context)!.email,
                        style: const TextStyle(fontWeight: FontWeight.bold,fontSize: kIsWeb ? 18 : 14),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        AppLocalizations.of(context)!.role,
                        style: const TextStyle(fontWeight: FontWeight.bold,fontSize: kIsWeb ? 18 : 14),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        AppLocalizations.of(context)!.createdAt,
                        style: const TextStyle(fontWeight: FontWeight.bold,fontSize: kIsWeb ? 18 : 14),
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
                            AppLocalizations.of(context)!.translateRole(user["role"] ?? ""),
                            style: TextStyle(
                              fontSize: kIsWeb ? 18 : 14,
                              color: user["role"] == "customer" ? Colors.green : Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            user["createdAt"]?.toString().split("T").first ?? "",
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
  }) {
    return Card(
      color: color,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        // give a fixed width so they align nicely side by side
        width: 200,
        height: 139,
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
    );
  }
}
