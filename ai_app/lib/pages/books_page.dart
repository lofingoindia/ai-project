import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../models/book.dart';
import '../services/book_service.dart';
import '../services/user_preference_service.dart';
import '../services/favorite_service.dart';
import '../services/localization_service.dart';
import 'product_detail_page.dart';

class BooksPage extends StatefulWidget {
  final String? initialAgeFilter;
  
  const BooksPage({Key? key, this.initialAgeFilter}) : super(key: key);

  @override
  State<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> {
  final BookService _bookService = BookService();
  final LocalizationService _localizationService = LocalizationService();
  List<Book> _books = [];
  List<Book> _filteredBooks = [];
  bool _isLoading = true;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  Set<String> _favoriteIds = {};
  
  // Filter states
  String? _selectedGender;
  String? _selectedAge;
  String? _selectedCategory; // Genre/Category filter
  String _selectedLanguage = 'English';
  
  // Available languages
  final List<String> _languages = [
    'English',
    'العربية',
  ];

  // All available age ranges - predefined to show all options
  final List<String> _ageRanges = [
    '0-2',
    '3-5',
    '6-8',
    '9-12',
    '13+',
    // 'All ages'
  ];

  // Available categories/genres from backend
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    
    // Set initial age filter FIRST before loading anything
    if (widget.initialAgeFilter != null) {
      _selectedAge = widget.initialAgeFilter;
    }
    
    _initializeVideo();
    _loadUserPreferencesAndBooks();
    _loadFavorites();
    _loadCategories(); // Load categories from backend
  }

  Future<void> _loadFavorites() async {
    final favorites = await FavoriteService.getFavoriteBookIds();
    setState(() {
      _favoriteIds = favorites;
    });
  }

  Future<void> _loadCategories() async {
    try {
      final genres = await _bookService.getGenres();
      setState(() {
        _categories = genres;
      });
    } catch (e) {
      print('Error loading categories: $e');
      // Keep empty list if error
    }
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
      final controller = VideoPlayerController.asset('assets/vd.mp4');
      _videoController = controller;
      await controller.initialize();
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
        controller.play();
        controller.setLooping(true);
        controller.setVolume(0); // Mute the video
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isVideoInitialized = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadUserPreferencesAndBooks() async {
    try {
      final selectedCategory = await UserPreferenceService.getSelectedCategoryWithFallback();
      // Pre-set the gender filter based on selected category
      if (selectedCategory == 'girl') {
        setState(() {
          _selectedGender = 'Girl';
        });
      } else if (selectedCategory == 'boy') {
        setState(() {
          _selectedGender = 'Boy';
        });
      }
      _loadBooks();
    } catch (e) {
      _loadBooks();
    }
  }

  Future<void> _loadBooks() async {
    try {
      final books = await _bookService.getAllBooks();
      setState(() {
        _books = books;
        _filteredBooks = books;
        _isLoading = false;
      });
      // Apply initial filters based on category preference
      _applyFilters();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'books_page_error_loading'.tr}$e')),
      );
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredBooks = _books.where((book) {
        // Gender filter - improved to handle Supabase 'category' field
        if (_selectedGender != null && _selectedGender!.isNotEmpty) {
          final bookGender = book.genderTarget.toLowerCase().trim();
          final selectedGender = _selectedGender!.toLowerCase().trim();
          
          // Show book if:
          // 1. It matches the selected gender (girl/boy)
          // 2. OR book is marked as 'all', 'any', or 'both'
          // 3. OR book category is empty (show all when no specific category)
          if (bookGender.isNotEmpty && 
              bookGender != selectedGender && 
              bookGender != 'all' && 
              bookGender != 'any' &&
              bookGender != 'both') {
            return false;
          }
        }

        // Age filter
        if (_selectedAge != null && _selectedAge!.isNotEmpty && _selectedAge != 'All ages') {
          // First, try to match using the age_range string field from database
          if (book.ageRange != null && book.ageRange!.isNotEmpty) {
            // Extract age range from string like "3-5 years old" or "6-8 years old"
            String bookAgeRange = book.ageRange!.replaceAll(RegExp(r'\s*years?\s*old'), '').trim();
            
            // Debug print
            print('Checking book: ${book.title}, ageRange field: "${book.ageRange}", extracted: "$bookAgeRange", selected: "$_selectedAge"');
            
            // Direct match: if book's age range matches selected range
            if (bookAgeRange != _selectedAge) {
              return false;
            }
          } else {
            // Fallback to numeric age_min and age_max if age_range field is not available
            int minAge = 0;
            int maxAge = 100;
            
            if (_selectedAge!.contains('+')) {
              // Handle "13+" format
              minAge = int.tryParse(_selectedAge!.replaceAll('+', '').trim()) ?? 0;
              maxAge = 100;
            } else if (_selectedAge!.contains('-')) {
              // Handle "0-2", "3-5", etc. format
              List<String> parts = _selectedAge!.split('-');
              minAge = int.tryParse(parts[0].trim()) ?? 0;
              maxAge = int.tryParse(parts[1].trim()) ?? 100;
            }

            print('Checking book: ${book.title}, ageMin: ${book.ageMin}, ageMax: ${book.ageMax}, selected range: $minAge-$maxAge');

            // Check if book's age range falls within selected range
            if (book.ageMin < minAge || book.ageMax > maxAge) {
              return false;
            }
          }
        }

        // Category/Genre filter
        if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
          if (book.genre == null || book.genre != _selectedCategory) {
            return false;
          }
        }

        // Language filter
        if (_selectedLanguage != 'Select Language') {
          if (!book.availableLanguages.contains(_selectedLanguage)) {
            return false;
          }
        }

        return true;
      }).toList();
      
      // Debug: Print filter results
      print('======= FILTER APPLIED =======');
      print('Gender: $_selectedGender, Age: $_selectedAge, Category: $_selectedCategory, Language: $_selectedLanguage');
      print('Total books: ${_books.length}, Filtered books: ${_filteredBooks.length}');
      if (_filteredBooks.isNotEmpty) {
        print('Sample filtered books:');
        _filteredBooks.take(3).forEach((b) {
          print('  - ${b.title} (Age: ${b.ageMin}-${b.ageMax}, Gender: ${b.genderTarget})');
        });
      } else {
        print('No books matched the filters');
        if (_selectedAge != null) {
          print('Sample of all books age ranges:');
          _books.take(5).forEach((b) {
            print('  - ${b.title}: Age ${b.ageMin}-${b.ageMax}');
          });
        }
      }
      print('==============================');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Directionality(
              textDirection: _localizationService.textDirection,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                  // Header section with video
                  Container(
                    height: 200 + MediaQuery.of(context).padding.top,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        // Video or fallback image
                        Container(
                          height: 200 + MediaQuery.of(context).padding.top,
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
                              bottomLeft: Radius.circular(2),
                              bottomRight: Radius.circular(2),
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
                                              Color(0xFF784D9C),
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
                      ],
                    ),
                  ),

                  // Filters section
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Show active filters indicator
                        // if (_selectedGender != null || _selectedAge != null || _selectedLanguage != 'English')
                        //   Container(
                        //     margin: const EdgeInsets.only(bottom: 12),
                        //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        //     decoration: BoxDecoration(
                        //       color: Color(0xFF784D9C).withOpacity(0.1),
                        //       borderRadius: BorderRadius.circular(8),
                        //       border: Border.all(color: Color(0xFF784D9C).withOpacity(0.3)),
                        //     ),
                        //     child: Row(
                        //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        //       children: [
                        //         Row(
                        //           children: [
                        //             Icon(Icons.filter_list, size: 16, color: Color(0xFF784D9C)),
                        //             SizedBox(width: 8),
                        //             // Text(
                        //             //   'Active filters',
                        //             //   style: GoogleFonts.tajawal(
                        //             //     fontSize: 12,
                        //             //     fontWeight: FontWeight.w500,
                        //             //     color: Color(0xFF784D9C),
                        //             //   ),
                        //             // ),
                        //             if (_selectedGender != null) ...[
                        //               SizedBox(width: 8),
                        //               Container(
                        //                 padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        //                 decoration: BoxDecoration(
                        //                   color: Color(0xFF784D9C),
                        //                   borderRadius: BorderRadius.circular(12),
                        //                 ),
                        //                 child: Text(
                        //                   _selectedGender!,
                        //                   style: GoogleFonts.tajawal(
                        //                     fontSize: 10,
                        //                     color: Colors.white,
                        //                   ),
                        //                 ),
                        //               ),
                        //             ],
                        //             if (_selectedAge != null) ...[
                        //               SizedBox(width: 4),
                        //               Container(
                        //                 padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        //                 decoration: BoxDecoration(
                        //                   color: Color(0xFF784D9C),
                        //                   borderRadius: BorderRadius.circular(12),
                        //                 ),
                        //                 child: Text(
                        //                   _selectedAge!,
                        //                   style: GoogleFonts.tajawal(
                        //                     fontSize: 10,
                        //                     color: Colors.white,
                        //                   ),
                        //                 ),
                        //               ),
                        //             ],
                        //           ],
                        //         ),
                        //         TextButton(
                        //           onPressed: () {
                        //             setState(() {
                        //               _selectedGender = null;
                        //               _selectedAge = null;
                        //               _selectedLanguage = 'English';
                        //               _applyFilters();
                        //             });
                        //           },
                        //           style: TextButton.styleFrom(
                        //             padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        //             minimumSize: Size(0, 0),
                        //           ),
                        //           child: Text(
                        //             'Clear all',
                        //             style: GoogleFonts.tajawal(
                        //               fontSize: 12,
                        //               color: Color(0xFF784D9C),
                        //               fontWeight: FontWeight.w600,
                        //             ),
                        //           ),
                        //         ),
                        //       ],
                        //     ),
                        //   ),
                        
                        // Gender filter
                        // Row(
                        //   children: [
                        //     Icon(Icons.person_outline, size: 18, color: Colors.grey[600]),
                        //     const SizedBox(width: 8),
                        //     Text(
                        //       'books_page_gender'.tr,
                        //       style: GoogleFonts.tajawal(
                        //         fontSize: 14,
                        //         fontWeight: FontWeight.w500,
                        //         color: Colors.black87,
                        //       ),
                        //     ),
                        //   ],
                        // ),
                        // const SizedBox(height: 8),
                        // Wrap(
                        //   spacing: 8,
                        //   children: [
                        //     _buildFilterChip(
                        //       'boy'.tr,
                        //       _selectedGender == 'Boy',
                        //       () {
                        //         setState(() {
                        //           // Toggle: if already selected, clear filter; otherwise select Boy
                        //           if (_selectedGender == 'Boy') {
                        //             _selectedGender = null;
                        //           } else {
                        //             _selectedGender = 'Boy';
                        //           }
                        //           _applyFilters();
                        //         });
                        //       },
                        //     ),
                        //     _buildFilterChip(
                        //       'girl'.tr,
                        //       _selectedGender == 'Girl',
                        //       () {
                        //         setState(() {
                        //           // Toggle: if already selected, clear filter; otherwise select Girl
                        //           if (_selectedGender == 'Girl') {
                        //             _selectedGender = null;
                        //           } else {
                        //             _selectedGender = 'Girl';
                        //           }
                        //           _applyFilters();
                        //         });
                        //       },
                        //     ),
                        //   ],
                        // ),

                        const SizedBox(height: 16),

                        // Age filter
                        Row(
                          children: [
                            Icon(Icons.child_care, size: 18, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              'books_page_child_age'.tr,
                              style: GoogleFonts.tajawal(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            ..._ageRanges.map((age) {
                              final isSelected = _selectedAge == age;
                              return _buildFilterChip(
                                age,
                                isSelected,
                                () {
                                  setState(() {
                                    _selectedAge = _selectedAge == age ? null : age;
                                    _applyFilters();
                                  });
                                },
                              );
                            }),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Category/Genre filter
                        if (_categories.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(Icons.category_outlined, size: 18, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Text(
                                'books_page_category'.tr,
                                style: GoogleFonts.tajawal(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ..._categories.map((category) {
                                final isSelected = _selectedCategory == category;
                                return _buildFilterChip(
                                  category,
                                  isSelected,
                                  () {
                                    setState(() {
                                      _selectedCategory = _selectedCategory == category ? null : category;
                                      _applyFilters();
                                    });
                                  },
                                );
                              }),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Language filter
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.language, size: 20, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Text(
                                  'books_page_language'.tr,
                                  style: GoogleFonts.tajawal(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            // Language selector with horizontal chips
                            Row(
                              children: _languages.map((language) {
                                final isSelected = _selectedLanguage == language;
                                return Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedLanguage = language;
                                        _applyFilters();
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isSelected ?Color(0xFF784D9C) : Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected ? Color(0xFF784D9C) : Colors.grey[300]!,
                                        ),
                                      ),
                                      child: Text(
                                        language,
                                        style: GoogleFonts.tajawal(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: isSelected ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Books grid section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0.5, 16, 16),
                    child: _filteredBooks.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 60,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'books_page_no_books_found'.tr,
                                  style: GoogleFonts.tajawal(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'books_page_try_adjusting_filters'.tr,
                                  style: GoogleFonts.tajawal(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75, // Adjusted to match home screen card proportions
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 20,
                            ),
                            itemCount: _filteredBooks.length,
                            itemBuilder: (context, index) {
                              final book = _filteredBooks[index];
                              return _buildBookCard(book);
                            },
                          ),
                  ),

                  // Browse Stories by Age section
                  SizedBox(height: 40),
                  Text(
                    'books_page_browse_stories_by_age'.tr,
                    style: GoogleFonts.libreBaskerville(
                      fontSize: MediaQuery.of(context).size.width < 500 ? 24 : 28,
                      fontWeight: FontWeight.w400,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: 5),
                  
                  // Age groups - 2x2 grid layout with images
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      constraints: BoxConstraints(maxWidth: 700),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                        ),
                        // Show first 4 age ranges (excluding "All ages")
                        itemCount: _ageRanges.where((range) => range != 'All ages').length > 4 
                            ? 4 
                            : _ageRanges.where((range) => range != 'All ages').length,
                        itemBuilder: (context, index) {
                          final agesWithoutAll = _ageRanges.where((range) => range != 'All ages').toList();
                          final ageRange = agesWithoutAll[index];
                          // Map age ranges to image assets
                          final imageAssets = [
                            'assets/11 copy.png',     // 0-2
                            'assets/22 copy.png',     // 3-5
                            'assets/33 copy.png',     // 6-8
                            'assets/44444 copy.png',  // 9-12
                          ];
                          final imagePath = index < imageAssets.length 
                              ? imageAssets[index] 
                              : 'assets/11 copy.png';
                          return _buildAgeGroupCard(ageRange, imagePath);
                        },
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 60),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF784D9C) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF784D9C) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.tajawal(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildBookCard(Book book) {
    final isFavorite = _favoriteIds.contains(book.id);
    
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailPage(book: book),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book Image with title overlay - matching home screen style
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
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      child: book.displayImage.isNotEmpty
                          ? Image.network(
                              book.displayImage,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF6C63FF),
                                        Color(0xFF5A52A0),
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.book,
                                      size: 60,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF6C63FF),
                                    Color(0xFF5A52A0),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.book,
                                  size: 60,
                                  color: Colors.white.withOpacity(0.7),
                                ),
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
                      padding: const EdgeInsets.all(6),
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
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Title below the image - matching home screen style
          const SizedBox(height: 8),
          Text(
            book.title,
            style: GoogleFonts.tajawal(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Helper method to build age group cards with images and discover buttons
  Widget _buildAgeGroupCard(String ageRange, String imagePath) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: Icon(
                    Icons.image_not_supported,
                    color: Colors.grey[600],
                    size: 50,
                  ),
                );
              },
            ),
            // Gradient overlay for better text visibility
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                  ],
                  stops: [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
            // Content positioned like in the image
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top section - Age label and range centered
                  Column(
                    children: [
                      // "Age" label centered at top
                      Text(
                        'age'.tr,
                        style: GoogleFonts.tajawal(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      // Age range centered below "Age"
                      Text(
                        ageRange,
                        style: GoogleFonts.tajawal(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  
                  // Bottom section - Discover button centered
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Apply age filter and scroll to books
                        setState(() {
                          _selectedAge = ageRange;
                          _applyFilters();
                        });
                        // Scroll to top to show filtered results
                        Scrollable.ensureVisible(
                          context,
                          duration: Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.white, width: 1.5),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'books_page_discover'.tr,
                        style: GoogleFonts.tajawal(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
