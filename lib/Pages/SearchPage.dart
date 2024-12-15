import 'package:flutter/material.dart';
import '../NetworkHandler.dart';
import 'IndividualPage.dart'; // 🔥 Import your network handler

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<dynamic> customers = []; // 🔥 List of all customers
  List<dynamic> filteredCustomers = []; // 🔥 Filtered list of customers
  TextEditingController searchController = TextEditingController(); // 🔥 For search bar input

  @override
  void initState() {
    super.initState();
    fetchCustomers(); // Fetch customers when the page loads
  }

  /// 🔥 Fetch customers from the server
  Future<void> fetchCustomers() async {
    try {
      var response = await NetworkHandler().get('/user/customers');
      if (response != null && response is List) {
        setState(() {
          customers = response;
          filteredCustomers = customers;
        });
      } else {
        setState(() {
          customers = [];
        });
        print('Error fetching customers');
      }
    } catch (e) {
      setState(() {
        customers = [];
      });
      print('Error: $e');
    }
  }


  /// 🔥 Filter the customer list based on search input
  void filterCustomers(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredCustomers = customers; // Reset to full list
      } else {
        filteredCustomers = customers.where((customer) {
          final customerName = customer['username'].toLowerCase();
          final searchQuery = query.toLowerCase();
          return customerName.contains(searchQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: searchController,
          onChanged: (value) => filterCustomers(value), // 🔥 Call filter as user types
          decoration: const InputDecoration(
            hintText: 'Search for customers...',
            border: InputBorder.none,
          ),
        ),
      ),
      body: customers.isEmpty
          ? const Center( child: Text(
        'No shops found',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
      )
          : filteredCustomers.isEmpty
          ? const Center(
        child: Text(
          'No matching shops',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
        ),) // Loading state
          : ListView.builder(
        itemCount: filteredCustomers.length,
        itemBuilder: (context, index) {
          final customer = filteredCustomers[index];
          return ListTile(
            leading: CircleAvatar(
              child: Text(customer['username'][0].toUpperCase()),
            ),
            title: Text(customer['username']),
            subtitle: Text(customer['email']),
              onTap: () {
                // 🔥 When user taps on customer, navigate to chat
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => IndividualPage(
                      initialChatId: '', // New chat, so no chatId yet
                      chatPartnerEmail: customer['email'],
                      chatPartnerName: customer['username'],
                    ),
                  ),
                );
              },
          );
        },
      ),
    );
  }
}
