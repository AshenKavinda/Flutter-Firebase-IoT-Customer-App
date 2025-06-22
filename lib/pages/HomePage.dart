import 'package:customer_app/component/CustomNavBar.dart';
import 'package:customer_app/pages/MakeReservation.dart';
import 'package:customer_app/pages/ViewUnitsPage.dart';
import 'package:customer_app/pages/Profile.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    ViewUnitsPage(),
    MakeReservationPage(),
    Center(child: Text('Alerts Page')),
    ProfilePage(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: CustomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
