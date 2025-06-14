import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:perpusglo/features/borrow/view/borrow_history_page.dart';
import '../../books/view/books_page.dart';
import '../../notification/providers/notification_provider.dart';
import '../../notification/view/notification_page.dart';
import '../../profile/view/profile_page.dart';
import 'home_page.dart';

class MainNavigationPage extends ConsumerStatefulWidget {
  const MainNavigationPage({Key? key, this.initialIndex = 0}) : super(key: key);

  final int initialIndex;

  @override
  ConsumerState<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends ConsumerState<MainNavigationPage> {
  late int _currentIndex;

  // Pages to show in the navigation
  final List<Widget> _pages = [
    const HomePage(),
    const BooksPage(),
    const BorrowHistoryPage(),
    const NotificationPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }


  @override
  Widget build(BuildContext context) {
    final unreadCount =
        ref.watch(unreadNotificationCountProvider).asData?.value ?? 0;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Buku',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: 'Pinjaman',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              child: const Icon(Icons.notifications),
            ),
            label: 'Notifikasi',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}