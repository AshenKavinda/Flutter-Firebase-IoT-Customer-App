import 'package:customer_app/component/CustomNavBar.dart';
import 'package:customer_app/pages/MyReservationPage.dart';
import 'package:customer_app/pages/ViewUnitsPage.dart';
import 'package:customer_app/pages/Profile.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  final int initialTab;
  const HomePage({Key? key, this.initialTab = 0}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int _selectedIndex;

  final List<Widget> _pages = [
    ViewUnitsPage(),
    MyReservationPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
  }

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
