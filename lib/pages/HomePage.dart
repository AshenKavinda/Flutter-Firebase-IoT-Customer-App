import 'package:customer_app/component/CustomNavBar.dart';
import 'package:customer_app/pages/MyReservationPage.dart';
import 'package:customer_app/pages/ViewUnitsPage.dart';
import 'package:customer_app/pages/Profile.dart';
import 'package:customer_app/utils/theme.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  final int initialTab;
  const HomePage({Key? key, this.initialTab = 0}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late int _selectedIndex;
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  final List<Widget> _pages = [
    ViewUnitsPage(),
    MyReservationPage(),
    ProfilePage(),
  ];

  final List<String> _pageTitles = [
    'Explore Units',
    'My Reservations',
    'Profile',
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
    );
    _animationController!.forward();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_selectedIndex != index) {
      _animationController?.reset();
      setState(() {
        _selectedIndex = index;
      });
      _animationController?.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.navyBlue, AppColors.tealBlue],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome Back!',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 5),
                          _fadeAnimation != null
                              ? FadeTransition(
                                opacity: _fadeAnimation!,
                                child: Text(
                                  _pageTitles[_selectedIndex],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                              : Text(
                                _pageTitles[_selectedIndex],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          _getPageIcon(_selectedIndex),
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey[50]!, Colors.white],
          ),
        ),
        child:
            _fadeAnimation != null
                ? FadeTransition(
                  opacity: _fadeAnimation!,
                  child: _pages[_selectedIndex],
                )
                : _pages[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          child: CustomNavBar(
            currentIndex: _selectedIndex,
            onTap: _onTabTapped,
          ),
        ),
      ),
    );
  }

  IconData _getPageIcon(int index) {
    switch (index) {
      case 0:
        return Icons.location_on_rounded;
      case 1:
        return Icons.bookmark_rounded;
      case 2:
        return Icons.person_rounded;
      default:
        return Icons.home_rounded;
    }
  }
}
