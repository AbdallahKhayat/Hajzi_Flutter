import 'package:flutter/material.dart';

import '../constants.dart';

class CustomCard extends StatelessWidget {
  const CustomCard({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Column(
        children: [
          ListTile(
            leading: ValueListenableBuilder<Color>(
              // ***
              valueListenable: appColorNotifier, // ***
              builder: (context, currentColor, child) {
                // ***
                return CircleAvatar(
                  radius: 30,
                  child: Icon(
                    Icons.groups,
                    color: Colors.white,
                    size: 37,
                  ),
                  backgroundColor: currentColor, // ***
                );
              }, // ***
            ),
            title: Text(
              "Jack",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            subtitle: Row(
              children: [
                Icon(Icons.done_all),
                SizedBox(
                  width: 3,
                ),
                Text(
                  "Hello Jack",
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
            trailing: Text("18:04"),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 20, left: 80),
            child: Divider(
              thickness: 1,
            ),
          )
        ],
      ),
    );
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Dynamic Color Example'),
        ),
        body: Column(
          children: [
            CustomCard(),
            ElevatedButton(
              onPressed: () {
                // ***
                // Change the color dynamically
                appColorNotifier.value =
                    Colors.blue; // *** Update to a new color
              }, // ***
              child: Text("Change Color"), // ***
            ),
          ],
        ),
      ),
    );
  }
}
