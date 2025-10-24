import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/order.dart';
import '../models/book.dart';
import '../services/cart_service.dart';
import '../services/localization_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CheckoutPage extends StatefulWidget {
  final List<CartItem> cartItems;
  final double subtotal;
  final double shippingCost;
  final String shippingMethod;
  final Map<String, dynamic> shippingAddress;

  const CheckoutPage({
    Key? key,
    required this.cartItems,
    required this.subtotal,
    required this.shippingCost,
    required this.shippingMethod,
    required this.shippingAddress,
  }) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String _selectedPaymentMethod = 'paypal';
  final TextEditingController _couponController = TextEditingController();
  bool _isProcessing = false;
  double _discount = 0.0;
  String _appliedCoupon = '';

  double get total => widget.subtotal + widget.shippingCost - _discount;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7FC),
      appBar: AppBar(
        title: Text(
          'checkout_page_title'.tr,
          style: GoogleFonts.tajawal(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book Information Section
                  _buildBookSection(),
                  const SizedBox(height: 24),
                  
                  // Shipping Information Section
                  _buildShippingSection(),
                  const SizedBox(height: 24),
                  
                  // Order Summary Section
                  _buildOrderSummary(),
                  const SizedBox(height: 24),
                  
                  // Coupon Code Section
                  _buildCouponSection(),
                  const SizedBox(height: 24),
                  
                  // Payment Method Section
                  _buildPaymentSection(),
                  const SizedBox(height: 100), // Space for bottom section
                ],
              ),
            ),
          ),
          
          // Bottom Payment Section
          _buildBottomPaymentSection(),
        ],
      ),
    );
  }

  Widget _buildBookSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.book,
                color: const Color(0xFFB47AFF),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                widget.cartItems.length > 1 ? 'checkout_page_your_books'.tr : 'checkout_page_your_book'.tr,
                style: GoogleFonts.tajawal(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Book Items
          ...widget.cartItems.map((item) => _buildBookItem(item)),
        ],
      ),
    );
  }

  Widget _buildBookItem(CartItem item) {
    final book = item.book;
    if (book == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book Cover
          Container(
            width: 80,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildBookImage(item),
            ),
          ),
          const SizedBox(width: 16),
          
          // Book Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: GoogleFonts.tajawal(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${'checkout_page_hardcover'.tr} | ${book.availableLanguages.isNotEmpty ? book.availableLanguages.first : 'checkout_page_english_default'.tr}',
                  style: GoogleFonts.tajawal(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                
                // Personalization Info
                if (item.personalizationData.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF784D9C).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${'checkout_page_personalized_for'.tr}${item.personalizationData['child_name'] ?? 'checkout_page_child_default'.tr}',
                      style: GoogleFonts.tajawal(
                        fontSize: 11,
                        color: const Color(0xFF784D9C),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${'checkout_page_qty'.tr}${item.quantity}',
                      style: GoogleFonts.tajawal(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '\$${book.discountedPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.tajawal(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookImage(CartItem item) {
    // Check if there's a personalized cover
    final personalizedCover = item.personalizationData['generated_cover_url'] as String?;
    if (personalizedCover != null && personalizedCover.isNotEmpty) {
      if (personalizedCover.startsWith('data:image/')) {
        // Base64 image
        try {
          final base64Data = personalizedCover.split(',')[1];
          final bytes = base64Decode(base64Data);
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildFallbackImage(item.book),
          );
        } catch (e) {
          return _buildFallbackImage(item.book);
        }
      } else {
        // Network URL
        return CachedNetworkImage(
          imageUrl: personalizedCover,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => _buildFallbackImage(item.book),
        );
      }
    }
    
    return _buildFallbackImage(item.book);
  }

  Widget _buildFallbackImage(Book? book) {
    if (book?.coverImageUrl != null && book!.coverImageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: book.coverImageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[200],
          child: const Icon(Icons.book, color: Colors.grey, size: 40),
        ),
      );
    }
    
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.book, color: Colors.grey, size: 40),
    );
  }

  Widget _buildShippingSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF784D9C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.local_shipping,
                  color: const Color(0xFF784D9C),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'checkout_page_shipping_information'.tr,
                style: GoogleFonts.tajawal(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Shipping Address
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.shippingAddress['full_name'] ?? '',
                  style: GoogleFonts.tajawal(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.shippingAddress['phone'] ?? '',
                  style: GoogleFonts.tajawal(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  [
                    widget.shippingAddress['street'],
                    widget.shippingAddress['city'],
                    widget.shippingAddress['state'],
                    widget.shippingAddress['postal_code'],
                    widget.shippingAddress['country'],
                  ].where((e) => e != null && e.toString().isNotEmpty).join(', '),
                  style: GoogleFonts.tajawal(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Shipping Method
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF784D9C).withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF784D9C).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  widget.shippingMethod == 'express' 
                    ? Icons.flash_on 
                    : Icons.local_shipping_outlined,
                  color: const Color(0xFF784D9C),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.shippingMethod == 'express' ? 'checkout_page_express_shipping'.tr : 'checkout_page_standard_shipping'.tr,
                        style: GoogleFonts.tajawal(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        widget.shippingMethod == 'express' 
                          ? 'checkout_page_express_duration'.tr
                          : 'checkout_page_standard_duration'.tr,
                        style: GoogleFonts.tajawal(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${widget.shippingCost.toStringAsFixed(2)}',
                  style: GoogleFonts.tajawal(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF784D9C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'checkout_page_order_summary'.tr,
            style: GoogleFonts.tajawal(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          // Book count and subtotal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${'checkout_page_books'.tr} (${widget.cartItems.length})',
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '\$${widget.subtotal.toStringAsFixed(2)}',
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Shipping
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.shippingMethod == 'express' ? 'checkout_page_express_shipping'.tr : 'checkout_page_standard_shipping'.tr}',
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '\$${widget.shippingCost.toStringAsFixed(2)}',
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          
          // Discount if applied
          if (_discount > 0) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${'checkout_page_discount'.tr} ($_appliedCoupon)',
                  style: GoogleFonts.tajawal(
                    fontSize: 14,
                    color: Colors.green[700],
                  ),
                ),
                Text(
                  '-\$${_discount.toStringAsFixed(2)}',
                  style: GoogleFonts.tajawal(
                    fontSize: 14,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'checkout_page_total'.tr,
                style: GoogleFonts.tajawal(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: GoogleFonts.tajawal(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF784D9C),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCouponSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'checkout_page_got_coupon'.tr,
            style: GoogleFonts.tajawal(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _couponController,
                  decoration: InputDecoration(
                    hintText: 'checkout_page_coupon_placeholder'.tr,
                    hintStyle: GoogleFonts.tajawal(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF784D9C)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  style: GoogleFonts.tajawal(fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _applyCoupon,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'checkout_page_apply'.tr,
                  style: GoogleFonts.tajawal(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'checkout_page_payment_method'.tr,
            style: GoogleFonts.tajawal(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          // PayPal Option
          _buildPaymentOption(
            'paypal',
            'checkout_page_paypal'.tr,
            Icons.payment,
            Colors.blue[600]!,
          ),
          const SizedBox(height: 12),
          
          // Credit Card Option  
          _buildPaymentOption(
            'card',
            'checkout_page_credit_card'.tr,
            Icons.credit_card,
            Colors.grey[700]!,
          ),
          const SizedBox(height: 12),
          
          // Apple Pay Option
          _buildPaymentOption(
            'apple_pay',
            'checkout_page_apple_pay'.tr,
            Icons.phone_iphone,
            Colors.black,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String value, String title, IconData icon, Color color) {
    final isSelected = _selectedPaymentMethod == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF784D9C) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? const Color(0xFF784D9C).withOpacity(0.05) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.tajawal(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: const Color(0xFF784D9C),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPaymentSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Total Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'checkout_page_total'.tr,
                  style: GoogleFonts.tajawal(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: GoogleFonts.tajawal(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF784D9C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Payment Buttons
            if (_selectedPaymentMethod == 'paypal') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processPayPalPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'checkout_page_pay_with_paypal'.tr,
                        style: GoogleFonts.tajawal(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                ),
              ),
            ] else if (_selectedPaymentMethod == 'apple_pay') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processApplePayPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'checkout_page_pay_with_apple_pay'.tr,
                        style: GoogleFonts.tajawal(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processCreditCardPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF784D9C),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        '${'checkout_page_pay_now'.tr} \$${total.toStringAsFixed(2)}',
                        style: GoogleFonts.tajawal(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _applyCoupon() {
    final couponCode = _couponController.text.trim().toLowerCase();
    
    if (couponCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('checkout_page_please_enter_coupon'.tr),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Simple coupon validation (you can expand this)
    double discount = 0.0;
    String message = '';
    
    switch (couponCode) {
      case 'save10':
        discount = widget.subtotal * 0.10; // 10% off
        message = 'checkout_page_discount_10_applied'.tr;
        break;
      case 'welcome5':
        discount = 5.0; // $5 off
        message = 'checkout_page_discount_5_applied'.tr;
        break;
      case 'freeship':
        discount = widget.shippingCost; // Free shipping
        message = 'checkout_page_freeship_applied'.tr;
        break;
      default:
        message = 'checkout_page_invalid_coupon'.tr;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
        return;
    }

    setState(() {
      _discount = discount;
      _appliedCoupon = couponCode.toUpperCase();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _processPayPalPayment() async {
    setState(() => _isProcessing = true);

    try {
      // Simulate PayPal payment processing
      await Future.delayed(const Duration(seconds: 2));
      
      await _createOrder();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('checkout_page_paypal_success'.tr),
            backgroundColor: Colors.green,
          ),
        );
        _navigateToOrderComplete();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'checkout_page_paypal_failed'.tr}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _processApplePayPayment() async {
    setState(() => _isProcessing = true);

    try {
      // Simulate Apple Pay processing
      await Future.delayed(const Duration(seconds: 2));
      
      await _createOrder();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('checkout_page_applepay_success'.tr),
            backgroundColor: Colors.green,
          ),
        );
        _navigateToOrderComplete();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'checkout_page_applepay_failed'.tr}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _processCreditCardPayment() async {
    setState(() => _isProcessing = true);

    try {
      // Simulate credit card processing
      await Future.delayed(const Duration(seconds: 3));
      
      await _createOrder();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('checkout_page_payment_success'.tr),
            backgroundColor: Colors.green,
          ),
        );
        _navigateToOrderComplete();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'checkout_page_payment_failed'.tr}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _createOrder() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Create order data
    final orderData = {
      'user_id': user.id,
      'total_amount': total,
      'subtotal': widget.subtotal,
      'shipping_cost': widget.shippingCost,
      'discount_amount': _discount,
      'currency': 'USD',
      'status': 'paid',
      'payment_method': _selectedPaymentMethod,
      'shipping_method': widget.shippingMethod,
      'shipping_address': widget.shippingAddress,
      'applied_coupon': _appliedCoupon.isNotEmpty ? _appliedCoupon : null,
      'created_at': DateTime.now().toIso8601String(),
    };

    // Here you would typically:
    // 1. Create order in database
    // 2. Create order items
    // 3. Clear cart
    // 4. Send confirmation email

    print('Order created: $orderData');
    
    // Clear cart after successful order
    final cartService = CartService();
    await cartService.clearCart();
  }

  void _navigateToOrderComplete() {
    // Navigate to order complete page
    // For now, just pop back to main screen
    Navigator.of(context).popUntil((route) => route.isFirst);
    
    // You could also navigate to a specific order confirmation page
    // Navigator.of(context).pushReplacement(
    //   MaterialPageRoute(builder: (_) => OrderCompletePage()),
    // );
  }
}
