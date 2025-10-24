import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/book.dart';
import '../pages/start_personalisation_page.dart';
import '../services/localization_service.dart';

class ProductDetailPage extends StatefulWidget {
  final Book book;

  const ProductDetailPage({Key? key, required this.book}) : super(key: key);

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final PageController _imagePageController = PageController(viewportFraction: 1.0);
  final LocalizationService _localizationService = LocalizationService();
  bool _showBackToTopButton = false;
  String _selectedLanguage = 'English';
  int _currentImageIndex = 0;
  String _selectedTab = 'Reviews'; // Track which tab is selected
  

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset >= 400) {
        setState(() {
          _showBackToTopButton = true;
        });
      } else {
        setState(() {
          _showBackToTopButton = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _imagePageController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    _scrollController.animateTo(0,
        duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Center(
                      child: Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBookStat(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFFfaa61a),
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.tajawal(
            fontSize: 12,
            color: const Color(0xFFfaa61a),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewItem(String name, String review, int stars) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: GoogleFonts.tajawal(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                Icons.star,
                color: index < stars ? const Color(0xFFFFB800) : Colors.grey[300],
                size: 18,
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            review,
            style: GoogleFonts.tajawal(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          title: Text(
            question,
            style: GoogleFonts.tajawal(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          trailing: const Icon(
            Icons.expand_more,
            color: Color.fromARGB(255, 166, 116, 226),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                answer,
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: const Color.fromARGB(255, 174, 149, 232),
      // floatingActionButton: _showBackToTopButton
          // ? FloatingActionButton(
          //     onPressed: _scrollToTop,
          //     backgroundColor: const Color(0xFF784D9C),
          //     child: const Icon(Icons.arrow_upward),
          //   )
          // : null,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        // decoration: BoxDecoration(
        //   color: Colors.white,
        //   boxShadow: [
        //     BoxShadow(
        //       color: Colors.black.withOpacity(0.1),
        //       blurRadius: 10,
        //       offset: const Offset(0, -2),
        //     ),
        //   ],
        // ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StartPersonalisationPage(
                      book: widget.book,
                      bookTitle: widget.book.title,
                      bookDescription: widget.book.description,
                      accentColor: const Color(0xFF9C4DFF),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF784D9C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: Text(
                'product_detail_personalise'.tr,
                style: GoogleFonts.tajawal(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Main scrollable content - starts from very top of screen
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Section with Book Cover - starts from top edge
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    // gradient: LinearGradient(
                    //   begin: Alignment.topCenter,
                    //   end: Alignment.bottomCenter,
                    //   // colors: [
                    //   //   Color(0xFF8B5CF6),
                    //   //   Color(0xFF8B5CF6),
                    //   // ],
                    // ),
                  ),
                  child: Column(
                    children: [
                      // Book Cover Images Slider - Full width and height starting from very top
                      Container(
                        height: 450, // Increased height to account for status bar area
                        width: double.infinity,
                        child: widget.book.allImages.isNotEmpty
                            ? PageView.builder(
                                controller: _imagePageController,
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentImageIndex = index;
                                  });
                                },
                                itemCount: widget.book.allImages.length,
                                itemBuilder: (context, index) {
                                  return GestureDetector(
                                    onTap: () => _showFullScreenImage(context, widget.book.allImages[index]),
                                    child: Container(
                                      width: double.infinity,
                                      child: Image.network(
                                        widget.book.allImages[index],
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Container(
                                            // color: Colors.grey[200],
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                                value: loadingProgress.expectedTotalBytes != null
                                                    ? loadingProgress.cumulativeBytesLoaded /
                                                        loadingProgress.expectedTotalBytes!
                                                    : null,
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) =>
                                            Container(
                                          color: Colors.grey[300],
                                          child: const Center(
                                            child: Icon(Icons.error_outline, size: 50),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Container(
                                width: double.infinity,
                                height: 450,
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(Icons.menu_book, size: 80, color: Colors.grey),
                                ),
                              ),
                      ),
                      
                      // Image indicators if multiple images
                      if (widget.book.allImages.length > 1) ...[
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            widget.book.allImages.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: _currentImageIndex == index ? 20 : 8,
                              height: 2,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: _currentImageIndex == index 
                                    ? const Color.fromARGB(255, 142, 142, 142) 
                                    : const Color.fromARGB(255, 162, 161, 161).withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 15),
                      
                      // Book Stats Row - positioned below the image
                     
                      
                      const SizedBox(height: 15),
                      
                      // Book Title - Left aligned
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            widget.book.title,
                            textAlign: TextAlign.left,
                            style: GoogleFonts.tajawal(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 0, 0, 0),
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      //  const SizedBox(height: 32),
                      
                      // Divider line
                      Container(
                        width: double.infinity,
                        height: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        color: const Color.fromARGB(255, 78, 78, 78).withOpacity(0.3),
                      ),
                     const SizedBox(height: 32),
                      // Book Details Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            // Left Column
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // IDEAL FOR
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'product_detail_ideal_for'.tr,
                                        style: GoogleFonts.tajawal(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.book.idealFor ?? widget.book.genderTarget,
                                        style: GoogleFonts.tajawal(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // CHARACTERS
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'product_detail_characters'.tr,
                                        style: GoogleFonts.tajawal(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.book.characters.isNotEmpty 
                                            ? widget.book.characters.join(', ')
                                            : 'product_detail_not_specified'.tr,
                                        style: GoogleFonts.tajawal(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Right Column
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // AGE RANGE
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'product_detail_age_range'.tr,
                                        style: GoogleFonts.tajawal(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.book.ageRange ?? '${widget.book.ageMin} - ${widget.book.ageMax} ${'product_detail_years_old'.tr}',
                                        style: GoogleFonts.tajawal(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // GENRE
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'product_detail_genre'.tr,
                                        style: GoogleFonts.tajawal(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.book.genre ?? 'product_detail_adventure'.tr,
                                        style: GoogleFonts.tajawal(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Divider line
                      Container(
                        width: double.infinity,
                        height: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        color: const Color.fromARGB(255, 90, 89, 89).withOpacity(0.3),
                      ),
                      
                      const SizedBox(height: 15),
                    ],
                  ),
                ),
                
                // White Content Section
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(5),
                      topRight: Radius.circular(5),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Language Selection
                        // Container(
                        //   width: double.infinity,
                        //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        //   decoration: BoxDecoration(
                        //     border: Border.all(color: Colors.grey.shade300),
                        //     borderRadius: BorderRadius.circular(12),
                        //   ),
                        //   child: DropdownButton<String>(
                        //     value: _selectedLanguage,
                        //     underline: const SizedBox(),
                        //     isExpanded: true,
                        //     icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                        //     items: ['English', 'Arabic']
                        //         .map((String value) {
                        //       return DropdownMenuItem<String>(
                        //         value: value,
                        //         child: Text(
                        //           value,
                        //           style: GoogleFonts.tajawal(
                        //             fontSize: 16,
                        //             color: Colors.black87,
                        //           ),
                        //         ),
                        //       );
                        //     }).toList(),
                        //     onChanged: (String? newValue) {
                        //       if (newValue != null) {
                        //         setState(() {
                        //           _selectedLanguage = newValue;
                        //         });
                        //       }
                        //     },
                        //   ),
                        // ),
                        
                        // const SizedBox(height: 32),
                        
                        // Description Section with Large Bold First Letter
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: widget.book.description.isNotEmpty 
                                        ? widget.book.description[0].toUpperCase() 
                                        : 'O',
                                    style: GoogleFonts.tajawal(
                                      fontSize: 72,
                                      fontWeight: FontWeight.bold,
                                      color: const Color.fromARGB(255, 120, 77, 156),
                                      height: 0.8,
                                    ),
                                  ),
                                  TextSpan(
                                    text: widget.book.description.isNotEmpty 
                                        ? widget.book.description.substring(1) 
                                        : 'nce upon a time, in a quaint village nestled between lush forests and rolling hills, lived a curious little fox named Luna. Every night, she would gaze up at the twinkling stars and wonder about the magical worlds beyond her forest home.',
                                    style: GoogleFonts.tajawal(
                                      fontSize: 16,
                                      color: Colors.black87,
                                      height: 1.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        // const SizedBox(height: 32),
                        
                        // Preview and Listen buttons
                        Row(
                          children: [
                            // Expanded(
                            //   child: OutlinedButton(
                            //     onPressed: () {
                            //       // Handle preview action
                            //     },
                            //     style: OutlinedButton.styleFrom(
                            //       side: const BorderSide(color: Color(0xFF8B5CF6)),
                            //       padding: const EdgeInsets.symmetric(vertical: 12),
                            //       shape: RoundedRectangleBorder(
                            //         borderRadius: BorderRadius.circular(25),
                            //       ),
                            //     ),
                            //     child: Row(
                            //       mainAxisAlignment: MainAxisAlignment.center,
                            //       children: [
                            //         const Icon(
                            //           Icons.visibility_outlined,
                            //           color: Color(0xFF8B5CF6),
                            //           size: 20,
                            //         ),
                            //         const SizedBox(width: 8),
                            //         // Text(
                            //         //   'Preview',
                            //         //   style: GoogleFonts.tajawal(
                            //         //     color: Color(0xFF8B5CF6),
                            //         //     fontSize: 14,
                            //         //     fontWeight: FontWeight.w600,
                            //         //   ),
                            //         // ),
                            //       ],
                            //     ),
                            //   ),
                            // ),
                            // const SizedBox(width: 16),
                            // Expanded(
                            //   child: ElevatedButton(
                            //     onPressed: () {
                            //       // Handle listen action
                            //     },
                            //     style: ElevatedButton.styleFrom(
                            //     //   backgroundColor: const Color(0xFF8B5CF6),
                            //     //   foregroundColor: Colors.white,
                            //     //   padding: const EdgeInsets.symmetric(vertical: 12),
                            //     //   shape: RoundedRectangleBorder(
                            //     //     borderRadius: BorderRadius.circular(25),
                            //     //   ),
                            //     //   elevation: 0,
                            //     // ),
                            //     child: Row(
                            //       mainAxisAlignment: MainAxisAlignment.center,
                            //       // children: [
                            //       //   const Icon(
                            //       //     Icons.headphones,
                            //       //     color: Colors.white,
                            //       //     size: 20,
                            //       //   ),
                            //       //   const SizedBox(width: 8),
                            //       //   // Text(
                            //       //   //   'Listen',
                            //       //   //   style: GoogleFonts.tajawal(
                            //       //   //     color: Colors.white,
                            //       //   //     fontSize: 14,
                            //       //   //     fontWeight: FontWeight.w600,
                            //       //   //   ),
                            //       //   // ),
                            //       // ],
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),
                        
                        const SizedBox(height: 48),

                        // Tab Buttons for Reviews and FAQ
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedTab = 'Reviews';
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _selectedTab == 'Reviews' 
                                          ? const Color(0xFF784D9C) 
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'product_detail_reviews'.tr,
                                        style: GoogleFonts.tajawal(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: _selectedTab == 'Reviews' 
                                              ? Colors.white 
                                              : Colors.black54,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedTab = 'FAQ';
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _selectedTab == 'FAQ' 
                                          ? const Color(0xFF784D9C) 
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'product_detail_faq'.tr,
                                        style: GoogleFonts.tajawal(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: _selectedTab == 'FAQ' 
                                              ? Colors.white 
                                              : Colors.black54,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Content based on selected tab
                        if (_selectedTab == 'Reviews') ...[
                          // Reviews Section
                          Column(
                            children: [
                              // Purple box with stars and rating only
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0E6FF),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.star, color: const Color(0xFFFFB800), size: 28),
                                        const SizedBox(width: 4),
                                        Icon(Icons.star, color: const Color(0xFFFFB800), size: 28),
                                        const SizedBox(width: 4),
                                        Icon(Icons.star, color: const Color(0xFFFFB800), size: 28),
                                        const SizedBox(width: 4),
                                        Icon(Icons.star, color: const Color(0xFFFFB800), size: 28),
                                        const SizedBox(width: 4),
                                        Icon(Icons.star, color: const Color(0xFFFFB800), size: 28),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'product_detail_rated_out_of'.tr,
                                      style: GoogleFonts.tajawal(
                                        fontSize: 16,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 32),
                              
                              // Individual Reviews outside with white background and lines
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    _buildReviewItem(
                                      'product_detail_review_tanu_name'.tr, 
                                      'product_detail_review_tanu_text'.tr, 
                                      5
                                    ),
                                    Container(
                                      height: 1,
                                      color: Colors.grey[200],
                                      margin: const EdgeInsets.symmetric(horizontal: 24),
                                    ),
                                    _buildReviewItem(
                                      'product_detail_review_nivedita_name'.tr, 
                                      'product_detail_review_nivedita_text'.tr, 
                                      5
                                    ),
                                    Container(
                                      height: 1,
                                      color: Colors.grey[200],
                                      margin: const EdgeInsets.symmetric(horizontal: 24),
                                    ),
                                    _buildReviewItem(
                                      'product_detail_review_avinash_name'.tr, 
                                      'product_detail_review_avinash_text'.tr, 
                                      4
                                    ),
                                    Container(
                                      height: 1,
                                      color: Colors.grey[200],
                                      margin: const EdgeInsets.symmetric(horizontal: 24),
                                    ),
                                    _buildReviewItem(
                                      'product_detail_review_aditya_name'.tr, 
                                      'product_detail_review_aditya_text'.tr, 
                                      5
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          // FAQ Section
                          // FAQ items in white background with lines
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                _buildFAQItem(
                                    'product_detail_faq_shipping_question'.tr,
                                    'product_detail_faq_shipping_answer'.tr,
                                  ),
                                  Container(
                                    height: 1,
                                    color: Colors.grey[200],
                                    margin: const EdgeInsets.symmetric(horizontal: 24),
                                  ),
                                  _buildFAQItem(
                                    'product_detail_faq_shipping_time_question'.tr,
                                    'product_detail_faq_shipping_time_answer'.tr,
                                  ),
                                  Container(
                                    height: 1,
                                    color: Colors.grey[200],
                                    margin: const EdgeInsets.symmetric(horizontal: 24),
                                  ),
                                  _buildFAQItem(
                                    'product_detail_faq_order_question'.tr,
                                    'product_detail_faq_order_answer'.tr,
                                  ),
                                  Container(
                                    height: 1,
                                    color: Colors.grey[200],
                                    margin: const EdgeInsets.symmetric(horizontal: 24),
                                  ),
                                  _buildFAQItem(
                                    'product_detail_faq_satisfaction_question'.tr,
                                    'product_detail_faq_satisfaction_answer'.tr,
                                  ),
                                  Container(
                                    height: 1,
                                    color: Colors.grey[200],
                                    margin: const EdgeInsets.symmetric(horizontal: 24),
                                  ),
                                  _buildFAQItem(
                                    'product_detail_faq_refund_question'.tr,
                                    'product_detail_faq_refund_answer'.tr,
                                  ),
                                  Container(
                                    height: 1,
                                    color: Colors.grey[200],
                                    margin: const EdgeInsets.symmetric(horizontal: 24),
                                  ),
                                  _buildFAQItem(
                                    'product_detail_faq_languages_question'.tr,
                                    'product_detail_faq_languages_answer'.tr,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Overlay App Bar - positioned on top of the image with transparent background
          SafeArea(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Container(
                    // decoration: BoxDecoration(
                    //   color: Colors.black.withOpacity(0.3),
                    //   borderRadius: BorderRadius.circular(20),
                    // ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ArrowPainter extends CustomPainter {
  final Color color;
  
  ArrowPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final path = Path();
    path.moveTo(0, size.height / 2);
    path.lineTo(size.width * 0.7, 0);
    path.lineTo(size.width * 0.7, size.height * 0.3);
    path.lineTo(size.width, size.height * 0.3);
    path.lineTo(size.width, size.height * 0.7);
    path.lineTo(size.width * 0.7, size.height * 0.7);
    path.lineTo(size.width * 0.7, size.height);
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
