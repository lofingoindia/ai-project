import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'models/book.dart';
import 'services/book_service.dart';
import 'services/user_preference_service.dart';
import 'services/favorite_service.dart';
import 'services/localization_service.dart';
import 'pages/product_detail_page.dart';
import 'pages/search_page.dart';
import 'main_navigation.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final BookService _bookService = BookService();
  final LocalizationService _localizationService = LocalizationService();
  List<Book> _featuredBooks = [];
  List<String> _categories = ['all', 'boy', 'girl'];
  String _selectedCategory = 'all';
  bool _isLoading = true;
  bool _categoriesLoading = true;
  List<String> _genreCategories = [];
  bool _genreCategoriesLoading = true;
  Map<String, List<Book>> _booksByGenre = {};
  bool _genreBooksLoading = false;
  late PageController _pageController;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  Set<String> _favoriteIds = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializeVideo();
    _loadUserPreferencesAndBooks();
    _loadCategories();
    _loadGenreCategories();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favorites = await FavoriteService.getFavoriteBookIds();
    setState(() {
      _favoriteIds = favorites;
    });
  }

  Future<void> _toggleFavorite(String bookId) async {
    await FavoriteService.toggleFavorite(bookId);
    _loadFavorites();
    
    // Show feedback
    final isFavorite = await FavoriteService.isFavorite(bookId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFavorite ? 'added_to_my_books'.tr : 'removed_from_my_books'.tr,
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: isFavorite ? Colors.green : Colors.grey[700],
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _initializeVideo() async {
    try {
      // print('Starting video initialization...');
      final controller = VideoPlayerController.asset('assets/vd.mp4');
      _videoController = controller;
      // print('VideoController created');
      await controller.initialize();
      // print('Video initialized successfully');
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
        controller.play();
        controller.setLooping(true);
        controller.setVolume(0); // Mute the video
        // print('Video is now playing');
      }
    } catch (error) {
      // print('Error initializing video: $error');
      if (mounted) {
        setState(() {
          _isVideoInitialized = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadUserPreferencesAndBooks() async {
    try {
      final selectedCategory =
          await UserPreferenceService.getSelectedCategoryWithFallback();
      setState(() {
        _selectedCategory = selectedCategory;
      });

      _loadFeaturedBooks();
    } catch (e) {
      _loadFeaturedBooks();
    }
  }

  Future<void> _loadFeaturedBooks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Book> books;

      if (_selectedCategory == 'all') {
        books = await _bookService.getFeaturedBooks(limit: 6);
      } else if (_selectedCategory == 'boy' || _selectedCategory == 'girl') {
        books = await _bookService.getBooksByGender(
          _selectedCategory,
          limit: 6,
        );
      } else {
        books = await _bookService.getBooksByCategory(
          _selectedCategory,
          limit: 6,
        );
      }

      setState(() {
        _featuredBooks = books;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _bookService.getCategories();
      final validCategories = categories
          .where(
            (c) =>
                c.toLowerCase() == 'boy' ||
                c.toLowerCase() == 'girl' ||
                c.toLowerCase() == 'fiction' ||
                c.toLowerCase() == 'fantasy' ||
                c.toLowerCase() == 'mystery',
          )
          .map((c) => c.toLowerCase())
          .toList();

      final allCategories = ['all', ...validCategories];
      setState(() {
        _categories = allCategories;
        _categoriesLoading = false;
      });
    } catch (e) {
      setState(() {
        _categoriesLoading = false;
        _categories = ['all', 'boy', 'girl'];
      });
    }
  }

  Future<void> _loadGenreCategories() async {
    try {
      final genres = await _bookService.getGenres();
      setState(() {
        _genreCategories = genres;
        _genreCategoriesLoading = false;
      });
      
      // Load books for all genres
      _loadBooksForAllGenres();
    } catch (e) {
      print('Error loading genre categories: $e');
      setState(() {
        _genreCategoriesLoading = false;
        _genreCategories = [];
      });
    }
  }

  Future<void> _loadBooksForAllGenres() async {
    setState(() {
      _genreBooksLoading = true;
    });

    try {
      final allBooks = await _bookService.getAllBooks();
      final Map<String, List<Book>> genreBooks = {};
      
      for (String genre in _genreCategories) {
        final booksInGenre = allBooks
            .where((book) => book.genre == genre)
            .take(6)
            .toList();
        if (booksInGenre.isNotEmpty) {
          genreBooks[genre] = booksInGenre;
        }
      }
      
      setState(() {
        _booksByGenre = genreBooks;
        _genreBooksLoading = false;
      });
    } catch (e) {
      print('Error loading books for genres: $e');
      setState(() {
        _genreBooksLoading = false;
        _booksByGenre = {};
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _localizationService.textDirection,
      child: Scaffold(
        body: _buildHomeScreen(),
      ),
    );
  }

  Widget _buildHomeScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(255, 255, 255, 255),
            Color(0xFFEDE9FE),
            const Color.fromARGB(255, 255, 255, 255),
          ],
          stops: [0.0, 0.3, 1.0],
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Image - starts from top
            Container(
              height: 300,
              child: Stack(
                children: [
                  // Image
                  Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 15,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(25),
                        bottomRight: Radius.circular(25),
                      ),
                      child: _isVideoInitialized && 
                             _videoController != null && 
                             _videoController!.value.isInitialized
                          ? SizedBox.expand(
                              child: FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: _videoController!.value.size.width,
                                  height: _videoController!.value.size.height,
                                  child: VideoPlayer(_videoController!),
                                ),
                              ),
                            )
                          : Image.asset(
                              'assets/aibn.png',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF784D9C),
                                        Color(0xFF5B21B6),
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.video_library,
                                      size: 60,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                  // Safe area padding for top content
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 20),
                          // Hello text
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '${'hello'.tr} ',
                                      style: GoogleFonts.tajawal(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      '📚',
                                      style: TextStyle(fontSize: 24),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'bookish_adventure_1'.tr,
                                  style: GoogleFonts.tajawal(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'bookish_adventure_2'.tr,
                                  style: GoogleFonts.tajawal(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Search bar
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SearchPage(),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: AbsorbPointer(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: 'search_hint'.tr,
                                      hintStyle: GoogleFonts.tajawal(
                                        color: const Color.fromARGB(255, 0, 0, 0),
                                        fontSize: 15,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search,
                                        color: const Color.fromARGB(255, 0, 0, 0),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(30),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 15,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Categories Section with inline buttons
            _buildCategoriesSection(),

            // const SizedBox(height: 25),

            // // Age Range Cards Section
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 20),
            //   child: Text(
            //     'Shop by Age',
            //     style: GoogleFonts.tajawal(
            //       fontSize: 22,
            //       fontWeight: FontWeight.bold,
            //       color: Colors.black87,
            //     ),
            //   ),
            // ),

            const SizedBox(height: 15),

            _buildAgeRangeCards(),

            const SizedBox(height: 30),

            // Popular Places Section
            _buildPopularPlacesSection(),

            const SizedBox(height: 30),

            // Genre Categories with Books Section (Vertical)
            _buildAllGenresWithBooksSection(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Empty space for alignment
          SizedBox(),
          // Menu and Cart icons
          Row(
            children: [
              // 4-dot menu icon
              GestureDetector(
                onTap: () {
                  // Add your menu action here
                  print('Menu tapped');
                },
                child: Container(
                  width: 30,
                  height: 30,
                  // decoration: BoxDecoration(
                  //   color: Colors.white.withOpacity(0.9),
                  //   borderRadius: BorderRadius.circular(5),
                  //   // boxShadow: [
                  //   //   BoxShadow(
                  //   //     color: Colors.black.withOpacity(0.1),
                  //   //     blurRadius: 8,
                  //   //     offset: Offset(0, 2),
                  //   //   ),
                  //   // ],
                  // ),
                  // child: Icon(
                  //   Icons.apps,
                  //   color: Color.fromARGB(255, 13, 68, 38),
                  //   size: 22,
                  // ),
                ),
              ),
              const SizedBox(width: 12),
              // Shopping cart icon
              GestureDetector(
                onTap: () {
                  // Add your cart navigation here
                  print('Cart tapped');
                },
                child: Container(
                  width: 30,
                  height: 30,
                  // decoration: BoxDecoration(
                  //   color: const Color.fromARGB(255, 120, 77, 156),
                  //   borderRadius: BorderRadius.circular(5),
                  //   // boxShadow: [
                  //   //   BoxShadow(
                  //   //     color: Colors.black.withOpacity(0.1),
                  //   //     blurRadius: 8,
                  //   //     offset: Offset(0, 2),
                  //   //   ),
                  //   // ],
                  // ),
                  child: Stack(
                    children: [
                      // Center(
                      //   child: Icon(
                      //     Icons.shopping_cart_outlined,
                      //     color:  Color.fromARGB(255, 253, 255, 254),
                      //     size: 22,
                      //   ),
                      // ),
                      // Badge for cart count (optional)
                      // Positioned(
                      //   right: 6,
                      //   top: 6,
                      //   child: Container(
                      //     padding: EdgeInsets.all(4),
                      //     decoration: BoxDecoration(
                      //       color: Colors.red,
                      //       shape: BoxShape.circle,
                      //     ),
                      //     constraints: BoxConstraints(
                      //       minWidth: 16,
                      //       minHeight: 16,
                      //     ),
                      //     child: Text(
                      //       '3',
                      //       style: TextStyle(
                      //         color: Colors.white,
                      //         fontSize: 10,
                      //         fontWeight: FontWeight.bold,
                      //       ),
                      //       textAlign: TextAlign.center,
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    if (_categoriesLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Categories',
              style: GoogleFonts.tajawal(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(221, 0, 0, 0),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 35,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 60,
                  height: 35,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Show Boy and Girl categories as small buttons next to title
    final displayCategories = _categories.where((c) => c == 'boy' || c == 'girl').toList();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.dashboard,
                size: 24,
                color: const Color.fromARGB(221, 17, 41, 8),
              ),
              const SizedBox(width: 8),
              Text(
                'age'.tr,
                style: GoogleFonts.tajawal(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(221, 0, 0, 0),
                ),
              ),
            ],
          ),
          Row(
            children: displayCategories.map((category) {
              final isSelected = category == _selectedCategory;
              return Container(
                margin: const EdgeInsets.only(left: 8),
                child: GestureDetector(
                  onTap: () async {
                    setState(() {
                      _selectedCategory = category;
                    });
                    await UserPreferenceService.setSelectedCategory(category);
                    _loadFeaturedBooks();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF784D9C), Color(0xFF784D9C)],
                            )
                          : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : Color.fromARGB(255, 200, 200, 200),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      category.tr,
                      style: GoogleFonts.tajawal(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Color.fromARGB(255, 100, 100, 100),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeRangeCards() {
    final ageRanges = ['0-2', '3-5', '6-8', '9-12'];
    final ageImages = [
      'assets/11 copy.png',
      'assets/22 copy.png',
      'assets/33 copy.png',
      'assets/4444 copy.png',
    ];

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: ageRanges.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              print('🎯 Age card tapped: ${ageRanges[index]}');
              MainNavigation.switchToShopWithAgeFilter(context, ageRanges[index]);
            },
            child: Container(
              width: MediaQuery.of(context).size.width * 0.35,
              margin: EdgeInsets.only(right: index < ageRanges.length - 1 ? 16 : 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    flex: 3,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12)
                      ),
                      child: Image.asset(
                        ageImages[index],
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(12)
                      ),
                    ),
                    child: Text(
                      'Age ${ageRanges[index]}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF784D9C),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPopularPlacesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_graph,
                    size: 24,
                    color: const Color.fromARGB(221, 0, 0, 0),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'popular_books'.tr,
                    style: GoogleFonts.tajawal(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(221, 0, 0, 0),
                    ),
                  ),
                ],
              ),
              // Icon(
              //   Icons.arrow_forward,
              //   color: Colors.black87,
              //   size: 20,
              // ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        
        if (_isLoading)
          Container(
            height: 220,
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
            ),
          )
        else
          _buildBooksList(),
      ],
    );
  }

  Widget _buildBooksList() {
    final booksToShow = _featuredBooks.isNotEmpty
        ? _featuredBooks
        : _getDummyBooks();

    if (booksToShow.isEmpty) {
      return Container(
        height: 250,
        child: Center(
          child: Text(
            'no_books_available'.tr,
            style: GoogleFonts.tajawal(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return Container(
      height: 380,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: booksToShow.length,
        itemBuilder: (context, index) {
          return _buildBookCard(booksToShow[index], index);
        },
      ),
    );
  }

  Widget _buildBookCard(Book book, int index) {
    final isFavorite = _favoriteIds.contains(book.id);
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(book: book),
          ),
        );
      },
      child: Container(
        width: 300,
        margin: EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book cover image
            Stack(
              children: [
                Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 250,
                      height: 250,
                      color: _getBookColors()[book.hashCode % _getBookColors().length],
                      child: book.displayImage.isNotEmpty
                          ? Image.network(
                              book.displayImage,
                              fit: BoxFit.cover,
                              width: 250,
                              height: 220,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholderBookCover(book.hashCode % 6);
                              },
                            )
                          : _buildPlaceholderBookCover(book.hashCode % 6),
                    ),
                  ),
                ),
                // Favorite icon button
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _toggleFavorite(book.id),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey[600],
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Book title
            Text(
              book.title.isNotEmpty
                  ? book.title
                  : _getDummyTitles()[book.hashCode % _getDummyTitles().length],
              style: GoogleFonts.tajawal(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Location
            // Row(
            //   children: [
            //     Icon(
            //       Icons.location_on,
            //       size: 14,
            //       color: Colors.grey.shade600,
            //     ),
            //     const SizedBox(width: 4),
            //     Text(
            //       'London, UK',
            //       style: GoogleFonts.tajawal(
            //         fontSize: 12,
            //         color: Colors.grey.shade600,
            //       ),
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderBookCover(int index) {
    final colors = _getBookColors();
    return Container(
      width: 200,
      height: 220,
      color: colors[index % colors.length],
      child: Center(
        child: Icon(Icons.book, size: 60, color: Colors.white.withOpacity(0.7)),
      ),
    );
  }

  List<Book> _getDummyBooks() {
    return List.generate(
      6,
      (index) => Book(
        id: 'dummy-$index',
        name: _getDummyTitles()[index % _getDummyTitles().length],
        description:
            _getDummyDescriptions()[index % _getDummyDescriptions().length],
        price: 19.99,
        discountPercentage: 0,
        ageMin: 3,
        ageMax: 8,
        genderTarget: 'all',
        coverImageUrl: '',
        previewImages: [],
        images: [],
        videos: [],
        availableLanguages: ['English'],
        isFeatured: true,
        isBestseller: false,
        isActive: true,
        stockQuantity: 10,
        characters: [], // Required field - empty array for dummy books
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        level: 1,
        path: '1',
        sortOrder: index,
      ),
    );
  }

  List<String> _getDummyTitles() {
    return [
      'The Book Cellar',
      'Shakespeare and Company',
      'Atlantis Books',
      'Libreria Acqua Alta',
      'El Ateneo Grand Splendid',
      'Livraria Lello',
    ];
  }

  List<String> _getDummyDescriptions() {
    return [
      'An enchanting bookstore filled with literary treasures',
      'Historic bookshop in the heart of Paris',
      'A charming bookstore on a Greek island',
      'Venice\'s most beautiful floating bookshop',
      'A stunning theatre converted into a bookstore',
      'One of the world\'s most beautiful bookstores',
    ];
  }



  List<Color> _getBookColors() {
    return [
      Color(0xFF6C63FF),
      Color(0xFF4ECDC4),
      Color(0xFFFF6B6B),
      Color(0xFF45B7D1),
      Color(0xFF96CEB4),
      Color(0xFFD63384),
    ];
  }

  Widget _buildAllGenresWithBooksSection() {
    if (_genreCategoriesLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF784D9C)),
        ),
      );
    }

    if (_genreCategories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Text(
          'No categories available',
          style: GoogleFonts.tajawal(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 0),
          child: Row(
            children: [
              Icon(
                Icons.category_outlined,
                size: 20,
                color: const Color.fromARGB(221, 0, 0, 0),
              ),
              const SizedBox(width: 8),
              Text(
                'Genre Category'.tr,
                style: GoogleFonts.tajawal(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(221, 0, 0, 0),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        
        // Genre sections stacked vertically
        if (_genreBooksLoading)
          Container(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF784D9C)),
            ),
          )
        else
          ..._genreCategories.map((genre) {
            final booksInGenre = _booksByGenre[genre] ?? [];
            if (booksInGenre.isEmpty) return const SizedBox.shrink();
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Genre name
                Padding(
                  padding: const EdgeInsets.fromLTRB(25, 2, 5, 2),
                  child: Text(
                    genre,
                    style: GoogleFonts.tajawal(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF784D9C),
                    ),
                  ),
                ),
                
                // Books grid (2 columns)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: booksInGenre.length > 6 ? 6 : booksInGenre.length,
                    itemBuilder: (context, index) {
                      return _buildGridBookCard(booksInGenre[index]);
                    },
                  ),
                ),
                const SizedBox(height: 5),
              ],
            );
          }).toList(),
      ],
    );
  }

  Widget _buildGridBookCard(Book book) {
    final isFavorite = _favoriteIds.contains(book.id);
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(book: book),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book cover image
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      color: _getBookColors()[book.hashCode % _getBookColors().length],
                      child: book.displayImage.isNotEmpty
                          ? Image.network(
                              book.displayImage,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.book,
                                    size: 50,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                );
                              },
                            )
                          : Center(
                              child: Icon(
                                Icons.book,
                                size: 50,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                    ),
                  ),
                ),
                // Favorite icon button
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _toggleFavorite(book.id),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey[600],
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Book title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              book.title.isNotEmpty ? book.title : book.name,
              style: GoogleFonts.tajawal(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}