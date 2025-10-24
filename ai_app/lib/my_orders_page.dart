import 'package:flutter/material.dart';
import 'main_navigation.dart';
import 'services/localization_service.dart';

class MyOrdersPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text('my_orders_page_title'.tr, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          decoration: BoxDecoration(
            color: Color(0xFFF7F0FC),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'my_orders_page_add_personalised_book'.tr,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Color(0xFFB47AFF)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  backgroundColor: Colors.white,
                ),
                onPressed: () {
                  // Pop this page first
                  Navigator.of(context).pop();
                  // Switch to Shop tab (index 1)
                  MainNavigation.switchTab(context, 1);
                },
                child: Text('my_orders_page_add_books'.tr, style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
