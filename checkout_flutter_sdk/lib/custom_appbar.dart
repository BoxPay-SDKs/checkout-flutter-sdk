import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const CustomAppBar({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getMerchantDetailsFromSharedPreferences(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AppBar(
            backgroundColor: Color.fromARGB(255, 14, 93, 158),
            title: Text(title),
          );
        } else if (snapshot.hasError) {
          return AppBar(
            backgroundColor: Color.fromARGB(255, 14, 93, 158),
            title: Text(title),
          );
        } else {
          final merchantDetails = jsonDecode(snapshot.data!);
          final merchantName = merchantDetails['merchantName'];
          final headerColor = merchantDetails['checkoutTheme']['headerColor'];
          final logoUrl = merchantDetails['logoUrl'];
          final font = merchantDetails['checkoutTheme']['font'] ?? "Poppins";
          final headerTextColor =
              merchantDetails['checkoutTheme']['headerTextColor'];

          final color = Color(
              int.parse(headerColor.substring(1, 7), radix: 16) + 0xFF000000);

          List<Widget> actions = [];

          if (logoUrl != null && logoUrl.isNotEmpty) {
            actions.add(
              Padding(
                padding: const EdgeInsets.all(0),
                child: CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(logoUrl),
                ),
              ),
            );
          }

          Widget appBarTitle = Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              if (actions.isNotEmpty) ...[
                actions[0], 
                SizedBox(width: 8),
              ],
              Text(
                merchantName,
                style: TextStyle(
                  color: Color(
                      int.parse(headerTextColor.substring(1, 7), radix: 16) +
                          0xFF000000),
                  fontFamily: font,
                ),
                
              ),
            ],
          );

          return AppBar(
            titleSpacing: 0.0,
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
