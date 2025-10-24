import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'checkout_page.dart';
import '../models/order.dart';
import '../services/localization_service.dart';

class ShippingPage extends StatefulWidget {
  final double cartTotal;
  final List<CartItem> cartItems;

  const ShippingPage({
    Key? key,
    required this.cartTotal,
    required this.cartItems,
  }) : super(key: key);

  @override
  State<ShippingPage> createState() => _ShippingPageState();
}

class _ShippingPageState extends State<ShippingPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  
  // State variables
  String? _selectedCountry = 'India';
  String? _selectedState;
  bool _saveShippingDetails = false;
  bool _isLoading = false;
  String _userEmail = '';
  String _selectedShippingMethod = 'standard';
  double _shippingCost = 17.00;

  // Country and state options
  final List<String> _countries = [
    'India',
    'United States',
    'United Kingdom',
    'Canada',
    'Australia',
    'Germany',
    'France',
    'Japan',
  ];

  final Map<String, List<String>> _statesByCountry = {
    'India': [
      'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
      'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
      'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram',
      'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu',
      'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
      'Andaman and Nicobar Islands', 'Chandigarh', 'Dadra and Nagar Haveli and Daman and Diu',
      'Delhi', 'Jammu and Kashmir', 'Ladakh', 'Lakshadweep', 'Puducherry'
    ],
    'United States': [
      'Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 'Colorado',
      'Connecticut', 'Delaware', 'Florida', 'Georgia', 'Hawaii', 'Idaho',
      'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky', 'Louisiana',
      'Maine', 'Maryland', 'Massachusetts', 'Michigan', 'Minnesota',
      'Mississippi', 'Missouri', 'Montana', 'Nebraska', 'Nevada',
      'New Hampshire', 'New Jersey', 'New Mexico', 'New York',
      'North Carolina', 'North Dakota', 'Ohio', 'Oklahoma', 'Oregon',
      'Pennsylvania', 'Rhode Island', 'South Carolina', 'South Dakota',
      'Tennessee', 'Texas', 'Utah', 'Vermont', 'Virginia', 'Washington',
      'West Virginia', 'Wisconsin', 'Wyoming'
    ],
    'Canada': [
      'Alberta', 'British Columbia', 'Manitoba', 'New Brunswick',
      'Newfoundland and Labrador', 'Northwest Territories', 'Nova Scotia',
      'Nunavut', 'Ontario', 'Prince Edward Island', 'Quebec', 'Saskatchewan', 'Yukon'
    ],
    'United Kingdom': [
      'England', 'Scotland', 'Wales', 'Northern Ireland'
    ],
    'Australia': [
      'New South Wales', 'Victoria', 'Queensland', 'Western Australia',
      'South Australia', 'Tasmania', 'Australian Capital Territory', 'Northern Territory'
    ],
  };

  @override
  void initState() {
    super.initState();
    _testDatabaseConnection();
    _loadUserDetails();
    _loadSavedShippingAddress();
  }

  Future<void> _testDatabaseConnection() async {
    try {
      print('Testing database connection...');
      final user = Supabase.instance.client.auth.currentUser;
      print('Current user: ${user?.id} (${user?.email})');
      
      // Test a simple query to verify connection
      final testQuery = await Supabase.instance.client
          .from('shipping_addresses')
          .select('count')
          .count(CountOption.exact);
      
      print('Database connection test successful. Total records: ${testQuery.count}');
    } catch (e) {
      print('Database connection test failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'shipping_page_database_error'.tr}${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _loadUserDetails() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _userEmail = user.email ?? '';
      });
    }
  }

  Future<void> _loadSavedShippingAddress() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    print('Loading shipping address for user: ${user.id}');

    try {
      // Try to load from shipping_addresses table first
      print('Querying shipping_addresses table...');
      final response = await Supabase.instance.client
          .from('shipping_addresses')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      print('Database query result: $response');

      if (response != null) {
        print('Found saved shipping address in database');
        setState(() {
          _fullNameController.text = response['full_name'] ?? '';
          _phoneController.text = response['phone'] ?? '';
          _streetController.text = response['street'] ?? '';
          _cityController.text = response['city'] ?? '';
          _postalCodeController.text = response['postal_code'] ?? '';
          _selectedCountry = response['country'] ?? 'India';
          
          // Handle state selection more carefully
          final savedState = response['state'] as String?;
          if (savedState != null && _selectedCountry != null && 
              _statesByCountry.containsKey(_selectedCountry!) &&
              _statesByCountry[_selectedCountry!]!.contains(savedState)) {
            _selectedState = savedState;
            _stateController.text = savedState;
          } else {
            _selectedState = null;
            _stateController.text = savedState ?? '';
          }
          
          _saveShippingDetails = true; // Auto-check the save box if data exists
        });
      } else {
        print('No shipping address found in database, checking user metadata...');
        // Fallback to user metadata
        final shippingData = user.userMetadata?['shipping_address'];
        if (shippingData != null && shippingData is Map) {
          print('Found shipping address in user metadata');
          setState(() {
            _fullNameController.text = shippingData['full_name'] ?? '';
            _phoneController.text = shippingData['phone'] ?? '';
            _streetController.text = shippingData['street'] ?? '';
            _cityController.text = shippingData['city'] ?? '';
            _postalCodeController.text = shippingData['postal_code'] ?? '';
            _selectedCountry = shippingData['country'] ?? 'India';
            
            // Handle state selection more carefully
            final savedState = shippingData['state'] as String?;
            if (savedState != null && _selectedCountry != null && 
                _statesByCountry.containsKey(_selectedCountry!) &&
                _statesByCountry[_selectedCountry!]!.contains(savedState)) {
              _selectedState = savedState;
              _stateController.text = savedState;
            } else {
              _selectedState = null;
              _stateController.text = savedState ?? '';
            }
            
            _saveShippingDetails = true; // Auto-check the save box if data exists
          });
        } else {
          print('No shipping address found in user metadata either');
        }
      }
    } catch (e) {
      print('Error loading shipping address: $e');
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'shipping_page_error_loading_address'.tr}${e.toString()}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _saveShippingAddress() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final shippingData = {
      'user_id': user.id, // This is already a string UUID
      'full_name': _fullNameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'street': _streetController.text.trim(),
      'city': _cityController.text.trim(),
      'postal_code': _postalCodeController.text.trim(),
      'country': _selectedCountry,
      'state': _selectedState ?? _stateController.text.trim(),
    };

    print('Attempting to save shipping data: $shippingData');

    try {
      // Check if record exists
      final existing = await Supabase.instance.client
          .from('shipping_addresses')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      print('Existing record check result: $existing');

      if (existing != null) {
        // Update existing record (remove user_id from update data as it's not needed)
        final updateData = Map<String, dynamic>.from(shippingData);
        updateData.remove('user_id');
        
        print('Updating existing record with data: $updateData');
        
        final updateResult = await Supabase.instance.client
            .from('shipping_addresses')
            .update(updateData)
            .eq('user_id', user.id)
            .select();
        
        print('Update result: $updateResult');
        print('Updated existing shipping address in database');
      } else {
        // Insert new record
        print('Inserting new record with data: $shippingData');
        
        final insertResult = await Supabase.instance.client
            .from('shipping_addresses')
            .insert(shippingData)
            .select();
        
        print('Insert result: $insertResult');
        print('Inserted new shipping address into database');
      }

      // Also save to user metadata as backup
      if (_saveShippingDetails) {
        final currentMetadata = user.userMetadata ?? {};
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(
            data: {
              ...currentMetadata,
              'shipping_address': shippingData,
            },
          ),
        );
        print('Saved shipping address to user metadata');
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('shipping_page_address_saved'.tr),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error saving shipping address: $e');
      print('Error type: ${e.runtimeType}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'shipping_page_error_saving_address'.tr}${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      rethrow; // Re-throw to handle in calling function
    }
  }

  void _updateShippingCost(String method) {
    setState(() {
      _selectedShippingMethod = method;
      _shippingCost = method == 'express' ? 31.00 : 17.00;
    });
  }

  Future<void> _proceedToPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Always save shipping address to database for order processing
      await _saveShippingAddress();

      // Prepare shipping address data
      final shippingAddress = {
        'full_name': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'street': _streetController.text.trim(),
        'city': _cityController.text.trim(),
        'postal_code': _postalCodeController.text.trim(),
        'country': _selectedCountry,
        'state': _selectedState ?? _stateController.text.trim(),
      };

      if (mounted) {
        // Navigate to checkout page
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CheckoutPage(
              cartItems: widget.cartItems,
              subtotal: widget.cartTotal,
              shippingCost: _shippingCost,
              shippingMethod: _selectedShippingMethod,
              shippingAddress: shippingAddress,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error processing order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'shipping_page_error_processing'.tr}${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7FC),
      appBar: AppBar(
        title: Text('shipping_page_title'.tr),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Email display section
            _buildEmailSection(),
            const SizedBox(height: 24),
            
            // Shipping details section
            _buildShippingDetailsSection(),
            const SizedBox(height: 24),
            
            // Shipping method section
            _buildShippingMethodSection(),
            const SizedBox(height: 24),
            
            // Order summary
            _buildOrderSummary(),
            const SizedBox(height: 24),
            
            // Continue button
            _buildContinueButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF784D9C).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.email_outlined,
              color: Color(0xFF784D9C),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'shipping_page_email_address'.tr,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _userEmail,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'shipping_page_email_info'.tr,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingDetailsSection() {
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
            'shipping_page_shipping_details'.tr,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          // Country dropdown
          _buildDropdownField(
            label: 'shipping_page_country'.tr,
            value: _selectedCountry,
            items: _countries,
            onChanged: (value) {
              setState(() {
                _selectedCountry = value;
                _selectedState = null;
                _stateController.clear();
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Full name
          _buildTextFormField(
            controller: _fullNameController,
            label: 'shipping_page_full_name'.tr,
            hintText: 'shipping_page_enter_full_name'.tr,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'shipping_page_please_enter_full_name'.tr;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Phone number
          _buildTextFormField(
            controller: _phoneController,
            label: 'shipping_page_phone_number'.tr,
            hintText: 'shipping_page_enter_phone'.tr,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'shipping_page_please_enter_phone'.tr;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Street address
          _buildTextFormField(
            controller: _streetController,
            label: 'shipping_page_street'.tr,
            hintText: 'shipping_page_enter_street'.tr,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'shipping_page_please_enter_street'.tr;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // City
          _buildTextFormField(
            controller: _cityController,
            label: 'shipping_page_city'.tr,
            hintText: 'shipping_page_enter_city'.tr,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'shipping_page_please_enter_city'.tr;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Postal/Zip code
          _buildTextFormField(
            controller: _postalCodeController,
            label: 'shipping_page_postal_code'.tr,
            hintText: 'shipping_page_enter_postal'.tr,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'shipping_page_please_enter_postal'.tr;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // State/Province
          if (_selectedCountry != null && _statesByCountry.containsKey(_selectedCountry))
            _buildDropdownField(
              label: 'shipping_page_state_province'.tr,
              value: _selectedState,
              items: _statesByCountry[_selectedCountry!]!,
              onChanged: (value) {
                setState(() {
                  _selectedState = value;
                  _stateController.text = value ?? '';
                });
              },
            )
          else
            _buildTextFormField(
              controller: _stateController,
              label: 'shipping_page_state_province'.tr,
              hintText: 'shipping_page_enter_state'.tr,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'shipping_page_please_enter_state'.tr;
                }
                return null;
              },
            ),
          
          const SizedBox(height: 20),
          
          // Save shipping details checkbox
          Row(
            children: [
              Checkbox(
                value: _saveShippingDetails,
                onChanged: (value) {
                  setState(() {
                    _saveShippingDetails = value ?? false;
                  });
                },
                activeColor: const Color(0xFF784D9C),
              ),
              Expanded(
                child: Text(
                  'shipping_page_save_shipping_details'.tr,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Test save button for debugging
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : () async {
                if (_formKey.currentState!.validate()) {
                  setState(() => _isLoading = true);
                  try {
                    await _saveShippingAddress();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('shipping_page_test_save_success'.tr),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${'shipping_page_test_save_failed'.tr}$e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  }
                }
              },
              icon: const Icon(Icons.save_outlined),
              label: Text('shipping_page_test_save'.tr),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF784D9C),
                side: const BorderSide(color: Color(0xFF784D9C)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingMethodSection() {
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
            'shipping_page_shipping_method'.tr,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Standard shipping option
          _buildShippingOption(
            'standard',
            'shipping_page_standard'.tr,
            'shipping_page_standard_duration'.tr,
            17.00,
            Icons.local_shipping_outlined,
          ),
          
          const SizedBox(height: 12),
          
          // Express shipping option
          _buildShippingOption(
            'express',
            'shipping_page_express'.tr,
            'shipping_page_express_duration'.tr,
            31.00,
            Icons.flash_on_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildShippingOption(String value, String title, String duration, double cost, IconData icon) {
    final isSelected = _selectedShippingMethod == value;
    
    return GestureDetector(
      onTap: () => _updateShippingCost(value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF784D9C) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? const Color(0xFF784D9C).withOpacity(0.05) : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF784D9C) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? const Color(0xFF784D9C) : Colors.black,
                    ),
                  ),
                  Text(
                    duration,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '\$${cost.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFF784D9C) : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    final total = widget.cartTotal + _shippingCost;
    
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
            'shipping_page_order_summary'.tr,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${'shipping_page_subtotal'.tr} (${widget.cartItems.length} ${'shipping_page_items'.tr})',
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                '\$${widget.cartTotal.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'shipping_page_shipping'.tr,
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                '\$${_shippingCost.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          
          const Divider(height: 24),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'shipping_page_total'.tr,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF784D9C),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _proceedToPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF784D9C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                'shipping_page_continue'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey.shade400),
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
              borderSide: const BorderSide(color: Color(0xFF784D9C), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          onChanged: onChanged,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '${'shipping_page_please_select'.tr}$label';
            }
            return null;
          },
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          decoration: InputDecoration(
            hintText: 'Select $label',
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
              borderSide: const BorderSide(color: Color(0xFF784D9C), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}
