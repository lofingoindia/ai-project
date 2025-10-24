import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'home_page.dart';
import 'pages/books_page.dart';
import 'pages/cart_page.dart';
import 'my_account_page.dart';
import 'services/localization_service.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();

  // Static method to switch tabs from anywhere in the app
  static void switchTab(BuildContext context, int tabIndex) {
    final state = context.findAncestorStateOfType<_MainNavigationState>();
    state?.switchToTab(tabIndex);
  }

  // Static method to switch to Shop tab with age filter
  static void switchToShopWithAgeFilter(BuildContext context, String ageFilter) {
    final state = context.findAncestorStateOfType<_MainNavigationState>();
    state?.switchToShopWithAge(ageFilter);
  }
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  String? _pendingAgeFilter; // Store age filter to pass to BooksPage
  int _booksPageKey = 0; // Key to force BooksPage recreation
  
  // Create global keys for each navigator to maintain their state
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  // Method to switch tabs programmatically
  void switchToTab(int index) {
    if (index >= 0 && index < 4) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  // Method to switch to Shop tab with age filter
  void switchToShopWithAge(String ageFilter) {
    // First, reset the Shop tab navigator to ensure fresh state
    _navigatorKeys[1].currentState?.popUntil((route) => route.isFirst);
    
    setState(() {
      _pendingAgeFilter = ageFilter;
      _currentIndex = 1; // Switch to Shop tab (index 1)
    });
    
    // Force rebuild of the navigator
    Future.microtask(() {
      if (mounted) {
        _navigatorKeys[1].currentState?.pushReplacement(
          MaterialPageRoute(
            builder: (context) => BooksPage(initialAgeFilter: ageFilter),
          ),
        );
      }
    });
  }

  // Build each tab with its own Navigator
  Widget _buildNavigator(int index) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (RouteSettings settings) {
        return MaterialPageRoute(
          builder: (context) {
            switch (index) {
              case 0:
                return HomePage();
              case 1:
                // Pass the pending age filter to BooksPage
                final ageFilter = _pendingAgeFilter;
                // Clear the pending filter after using it
                if (_pendingAgeFilter != null) {
                  Future.microtask(() {
                    if (mounted) {
                      setState(() {
                        _pendingAgeFilter = null;
                      });
                    }
                  });
                }
                // Use a key to force recreation when needed
                return BooksPage(
                  key: ValueKey('books_$_booksPageKey'),
                  initialAgeFilter: ageFilter,
                );
              case 2:
                return CartPage();
              case 3:
                return MyAccountPage();
              default:
                return HomePage();
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Handle back button: pop current tab's navigation stack
        final isFirstRouteInCurrentTab =
            !await _navigatorKeys[_currentIndex].currentState!.maybePop();
        
        // If we're on the first route of the current tab
        if (isFirstRouteInCurrentTab) {
          // If not on Home tab, switch to Home tab
          if (_currentIndex != 0) {
            setState(() {
              _currentIndex = 0;
            });
            return false;
          }
        }
        // If on Home tab and first route, allow app to exit
        return isFirstRouteInCurrentTab;
      },
      child: Scaffold(
        body: Stack(
          children: List.generate(
            4,
            (index) => Offstage(
              offstage: _currentIndex != index,
              child: _buildNavigator(index),
            ),
          ),
        ),
        bottomNavigationBar: Container(
          color: const Color.fromARGB(0, 201, 131, 131),
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 255, 255),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                  spreadRadius: -2,
                ),
              ],
            ),
            height: 62,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: FontAwesomeIcons.house,
                  activeIcon: FontAwesomeIcons.house,
                  label: 'Home',
                ),
                _buildNavItem(
                  index: 1,
                  icon: FontAwesomeIcons.book,
                  activeIcon: FontAwesomeIcons.book,
                  label: 'Library',
                ),
                _buildNavItem(
                  index: 2,
                  icon: FontAwesomeIcons.heart,
                  activeIcon: FontAwesomeIcons.solidHeart,
                  label: 'Favorites',
                ),
                _buildNavItem(
                  index: 3,
                  icon: FontAwesomeIcons.user,
                  activeIcon: FontAwesomeIcons.solidUser,
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build custom navigation item with elegant styling
  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          // Reset the navigation stack for the tab being switched to
          if (index != _currentIndex) {
            // If switching away from Shop tab, clear any pending filters
            if (_currentIndex == 1) {
              _pendingAgeFilter = null;
              _booksPageKey++;
            }
            
            // Reset ALL navigation stacks to their root pages
            for (int i = 0; i < _navigatorKeys.length; i++) {
              if (i == index || i == _currentIndex) {
                _navigatorKeys[i].currentState?.popUntil((route) => route.isFirst);
              }
            }
            
            // If switching TO Shop tab, force a fresh BooksPage without filters
            if (index == 1 && _pendingAgeFilter == null) {
              Future.microtask(() {
                if (mounted) {
                  _navigatorKeys[1].currentState?.pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => BooksPage(
                        key: ValueKey('books_$_booksPageKey'),
                      ),
                    ),
                  );
                }
              });
            }
          }
          setState(() {
            _currentIndex = index;
          });
        },
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: isSelected ? 1 : 1),
          padding: EdgeInsets.symmetric(
            horizontal: isSelected ? 10 : 10,
            vertical: isSelected ? 6 : 6
          ),
          decoration: isSelected
              ? BoxDecoration(
                  color: Color(0xFF784D9C),
                  borderRadius: BorderRadius.circular(24),
                )
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                isSelected ? activeIcon : icon,
                size: isSelected ? 20 : 20,
                color: isSelected ? Colors.white : Color(0xFF784D9C),
              ),
              if (isSelected) ...[
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 90),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
