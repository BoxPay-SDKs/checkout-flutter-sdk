import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const CustomAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getMerchantDetailsFromSharedPreferences(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Return a default AppBar while waiting for data
          return AppBar(
            backgroundColor: Color.fromARGB(255, 14, 93, 158),
            title: Text(title),
          );
        } else if (snapshot.hasError) {
          // Return a default AppBar if an error occurs
          return AppBar(
            backgroundColor: Color.fromARGB(255, 14, 93, 158),
            title: Text(title),
          );
        } else {
          final merchantDetails = jsonDecode(snapshot.data!);

          final merchantName = merchantDetails['merchantName'];
          final headerColor = merchantDetails['checkoutTheme']['headerColor'];
          final logoUrl = merchantDetails['logoUrl'];

          final color = Color(int.parse(headerColor.substring(1, 7), radix: 16) + 0xFF000000);

          // List of widgets for the app bar actions
          List<Widget> actions = [];

          if (logoUrl != null && logoUrl.isNotEmpty) {
            actions.add(
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(logoUrl),
                ),
              ),
            );
          }

          // Create a row with logo and title
          Widget appBarTitle = Row(
            children: [
              if (actions.isNotEmpty) ...[
                actions[0], // Display the logo
                SizedBox(width: 8), // Add some spacing between logo and title
              ],
              Text(merchantName), // Display the title
            ],
          );

          return AppBar(
            title: appBarTitle,
            backgroundColor: color,
          );
        }
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  Future<String> _getMerchantDetailsFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('merchant_details') ?? '';
  }
}
