import 'package:flutter/material.dart';
import 'package:watch_next/pages/main_menu_page.dart';
import 'package:watch_next/pages/search_media_page.dart';
import 'package:watch_next/pages/watchlist_page.dart';

class TabNavigationPage extends StatefulWidget {
  const TabNavigationPage({super.key});

  @override
  State<TabNavigationPage> createState() => _TabNavigationPageState();
}

class _TabNavigationPageState extends State<TabNavigationPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(11, 14, 23, 1),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Tab content
          Positioned.fill(
            bottom: MediaQuery.of(context).padding.bottom + 70,
            child: TabBarView(
              controller: _tabController,
              children: const [
                WatchlistPage(isTab: true),
                MainMenuPage(isTab: true),
                SearchMediaPage(isTab: true),
              ],
            ),
          ),
          // Tab bar at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: const Color.fromRGBO(11, 14, 23, 1),
                border: Border(
                  top: BorderSide(
                    color: Colors.grey[800]!,
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.orange,
                  indicatorWeight: 3,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.orange,
                  unselectedLabelColor: Colors.grey[400],
                  labelStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.bookmark_border, size: 22),
                      text: 'Watchlist',
                    ),
                    Tab(
                      icon: Icon(Icons.home_rounded, size: 22),
                      text: 'Home',
                    ),
                    Tab(
                      icon: Icon(Icons.search, size: 22),
                      text: 'Search',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
