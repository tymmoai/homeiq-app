import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../services/user_service.dart';
import '../../../theme/asset_detail_colors.dart';
import '../../../utils/responsive_utils.dart';

class ServiceBookingScreen extends StatefulWidget {
  final String categoryName;
  final Map<String, dynamic> service;

  const ServiceBookingScreen({
    super.key,
    required this.categoryName,
    required this.service,
  });

  @override
  State<ServiceBookingScreen> createState() => _ServiceBookingScreenState();
}

class _ServiceBookingScreenState extends State<ServiceBookingScreen> {
  ResponsiveUtils get responsive => ResponsiveUtils(context);
  // Current step in the booking flow
  int _currentStep = 0;
  final int _totalSteps = 7;

  String _buildUserAddress() {
    final user = UserService.instance;
    final parts = <String>[];
    final addr = user.getUserAddress();
    if (addr.isNotEmpty) parts.add(addr);
    final apt = user.getUserApartmentUnit();
    if (apt.isNotEmpty) parts.add('Apt $apt');
    final city = user.getUserCity();
    if (city.isNotEmpty) parts.add(city);
    final state = user.getUserState();
    if (state.isNotEmpty) parts.add(state);
    final zip = user.getUserZipCode();
    if (zip.isNotEmpty) parts.add(zip);
    return parts.isNotEmpty ? parts.join(', ') : 'No address on file';
  }

  // Step 0: Service Overview (not counted in progress)
  bool _showOverview = true;

  // Step 1: Item Selection
  final Map<String, int> _selectedItems = {};
  final TextEditingController _otherItemController = TextEditingController();

  // Step 2: Additional Details
  final TextEditingController _notesController = TextEditingController();
  final List<String> _uploadedPhotos = [];

  // Step 3: Schedule
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  String _dateSelectionType = 'today'; // 'today', 'tomorrow', 'custom'

  // Step 4: Location
  String? _selectedHomeId;
  final TextEditingController _roomDetailsController = TextEditingController();

  // Step 5: Review
  bool _termsAccepted = false;

  // Step 6: Payment
  String? _selectedPaymentMethod;

  // User homes from stored profile data
  late final List<Map<String, dynamic>> _userHomes = [
    {
      'id': 'home_1',
      'name': 'My Home',
      'address': _buildUserAddress(),
      'isDefault': true,
    },
    {
      'id': 'home_2',
      'name': 'Vacation Home',
      'address': '456 Beach Road, Santa Cruz, CA 95060',
      'isDefault': false,
    },
  ];

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'card_1',
      'type': 'visa',
      'last4': '4242',
      'icon': Icons.credit_card,
      'isDefault': true,
    },
    {
      'id': 'wallet',
      'type': 'wallet',
      'last4': '',
      'icon': Icons.account_balance_wallet,
      'isDefault': false,
      'balance': '\$125.00',
    },
  ];

  // Assembly service items with prices
  List<Map<String, dynamic>> get _assemblyItems => [
    {'name': 'Chair', 'price': 15, 'icon': Icons.chair_outlined},
    {'name': 'Table', 'price': 25, 'icon': Icons.table_restaurant_outlined},
    {'name': 'Bed Frame', 'price': 40, 'icon': Icons.bed_outlined},
    {'name': 'Bookshelf', 'price': 30, 'icon': Icons.shelves},
    {'name': 'TV Stand', 'price': 35, 'icon': Icons.tv_outlined},
    {'name': 'Wardrobe', 'price': 50, 'icon': Icons.door_sliding_outlined},
    {'name': 'Desk', 'price': 35, 'icon': Icons.desk_outlined},
    {'name': 'Cabinet', 'price': 40, 'icon': Icons.kitchen_outlined},
  ];

  List<String> get _timeSlots => [
    'Morning (9 AM - 12 PM)',
    'Afternoon (12 PM - 4 PM)',
    'Evening (4 PM - 7 PM)',
  ];

  @override
  void initState() {
    super.initState();
    // Auto-select default home
    final defaultHome = _userHomes.firstWhere(
      (h) => h['isDefault'] == true,
      orElse: () => _userHomes.first,
    );
    _selectedHomeId = defaultHome['id'];

    // Auto-select default payment
    final defaultPayment = _paymentMethods.firstWhere(
      (p) => p['isDefault'] == true,
      orElse: () => _paymentMethods.first,
    );
    _selectedPaymentMethod = defaultPayment['id'];

    // Auto-select today as default date
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    _dateSelectionType = 'tomorrow';
  }

  @override
  void dispose() {
    _otherItemController.dispose();
    _notesController.dispose();
    _roomDetailsController.dispose();
    super.dispose();
  }

  double get _totalItemsPrice {
    double total = 0;
    _selectedItems.forEach((item, qty) {
      final itemData = _assemblyItems.firstWhere(
        (i) => i['name'] == item,
        orElse: () => {'price': 0},
      );
      total += (itemData['price'] as int) * qty;
    });
    return total;
  }

  double get _basePrice =>
      double.tryParse(
        (widget.service['price'] as String?)?.replaceAll(
              RegExp(r'[^\d.]'),
              '',
            ) ??
            '40',
      ) ??
      40;

  double get _totalPrice => _basePrice + _totalItemsPrice;

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Item Selection
        return _selectedItems.isNotEmpty;
      case 1: // Additional Details
        return true; // Optional
      case 2: // Schedule
        return _selectedDate != null && _selectedTimeSlot != null;
      case 3: // Location
        return _selectedHomeId != null;
      case 4: // Review
        return _termsAccepted;
      case 5: // Payment
        return _selectedPaymentMethod != null;
      default:
        return true;
    }
  }

  void _startBooking() {
    setState(() {
      _showOverview = false;
    });
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      if (_currentStep < _totalSteps - 1) {
        setState(() {
          _currentStep++;
        });
      } else {
        _completeBooking();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required fields'),
          backgroundColor: AssetDetailColors.errorColor,
        ),
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      setState(() {
        _showOverview = true;
      });
    }
  }

  void _completeBooking() {
    setState(() {
      _currentStep = _totalSteps; // Move to confirmation
    });
  }

  String _getFormattedDate() {
    if (_selectedDate == null) return '';
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return '${days[_selectedDate!.weekday % 7]}, ${months[_selectedDate!.month - 1]} ${_selectedDate!.day}, ${_selectedDate!.year}';
  }

  Map<String, dynamic>? _getSelectedHome() {
    return _userHomes.firstWhere(
      (h) => h['id'] == _selectedHomeId,
      orElse: () => <String, dynamic>{},
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show confirmation screen
    if (_currentStep == _totalSteps) {
      return _buildConfirmationScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundGray50,
      appBar: _showOverview ? null : _buildAppBar(),
      body: _showOverview
          ? _buildServiceOverview()
          : Column(
              children: [
                _buildProgressHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(responsive.spacing(20)),
                    child: _buildCurrentStep(),
                  ),
                ),
                _buildBottomNavigation(),
              ],
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final stepTitles = [
      'Select Items',
      'Additional Details',
      'Schedule',
      'Location',
      'Review',
      'Payment',
    ];
    return AppBar(
      backgroundColor: AppColors.headerBackground,
      elevation: 2,
      systemOverlayStyle: AppColors.headerBackground.computeLuminance() > 0.5
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios,
          color: AppColors.headerForeground,
          size: responsive.iconSize(20),
        ),
        onPressed: _previousStep,
      ),
      title: Text(
        _currentStep < stepTitles.length ? stepTitles[_currentStep] : '',
        style: TextStyle(
          color: AppColors.headerForeground,
          fontSize: responsive.fontSize(18),
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: false,
    );
  }

  Widget _buildProgressHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.spacing(20),
        vertical: responsive.spacing(12),
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Step ${_currentStep + 1} of ${_totalSteps - 1}',
                style: TextStyle(
                  fontSize: responsive.fontSize(12),
                  fontWeight: FontWeight.w500,
                  color: AssetDetailColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                widget.service['name'] as String,
                style: TextStyle(
                  fontSize: responsive.fontSize(12),
                  fontWeight: FontWeight.w600,
                  color: AssetDetailColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.spacing(8)),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / (_totalSteps - 1),
              backgroundColor: AppColors.gray200,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildItemSelectionStep();
      case 1:
        return _buildAdditionalDetailsStep();
      case 2:
        return _buildScheduleStep();
      case 3:
        return _buildLocationStep();
      case 4:
        return _buildReviewStep();
      case 5:
        return _buildPaymentStep();
      default:
        return const SizedBox();
    }
  }

  // ============================================
  // SERVICE OVERVIEW (Before booking starts)
  // ============================================
  Widget _buildServiceOverview() {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Image
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        widget.service['icon'] as IconData? ?? Icons.build,
                        size: responsive.iconSize(80),
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    // Back button
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 16,
                      child: GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadowDark,
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            size: responsive.iconSize(18),
                            color: AssetDetailColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: EdgeInsets.all(responsive.spacing(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service Title & Rating
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.service['name'] as String,
                                style: TextStyle(
                                  fontSize: responsive.fontSize(24),
                                  fontWeight: FontWeight.bold,
                                  color: AssetDetailColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: responsive.spacing(4)),
                              Text(
                                widget.categoryName,
                                style: TextStyle(
                                  fontSize: responsive.fontSize(14),
                                  color: AssetDetailColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusBadge,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: AppColors.amber,
                                size: responsive.iconSize(16),
                              ),
                              SizedBox(width: responsive.spacing(4)),
                              Text(
                                '${widget.service['rating'] ?? 4.8}',
                                style: TextStyle(
                                  fontSize: responsive.fontSize(14),
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.amber,
                                ),
                              ),
                              Text(
                                ' (124)',
                                style: TextStyle(
                                  fontSize: responsive.fontSize(12),
                                  color: AppColors.amber,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: responsive.spacing(20)),

                    // Price & Duration
                    Container(
                      padding: EdgeInsets.all(responsive.spacing(16)),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadowMedium,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.attach_money,
                                  color: AssetDetailColors.successColor,
                                  size: responsive.iconSize(28),
                                ),
                                SizedBox(height: responsive.spacing(8)),
                                Text(
                                  'Starting From',
                                  style: TextStyle(
                                    fontSize: responsive.fontSize(12),
                                    color: AssetDetailColors.textSecondary,
                                  ),
                                ),
                                SizedBox(height: responsive.spacing(4)),
                                Text(
                                  widget.service['price'] as String? ?? '\$49',
                                  style: TextStyle(
                                    fontSize: responsive.fontSize(18),
                                    fontWeight: FontWeight.bold,
                                    color: AssetDetailColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 60,
                            color: AppColors.gray200,
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: AppColors.primary,
                                  size: responsive.iconSize(28),
                                ),
                                SizedBox(height: responsive.spacing(8)),
                                Text(
                                  'Duration',
                                  style: TextStyle(
                                    fontSize: responsive.fontSize(12),
                                    color: AssetDetailColors.textSecondary,
                                  ),
                                ),
                                SizedBox(height: responsive.spacing(4)),
                                Text(
                                  '1-2 hours',
                                  style: TextStyle(
                                    fontSize: responsive.fontSize(18),
                                    fontWeight: FontWeight.bold,
                                    color: AssetDetailColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: responsive.spacing(24)),

                    // Description
                    Text(
                      'About this service',
                      style: TextStyle(
                        fontSize: responsive.fontSize(18),
                        fontWeight: FontWeight.bold,
                        color: AssetDetailColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: responsive.spacing(12)),
                    Text(
                      'Professional assembly service for all types of furniture. Our skilled technicians will assemble your furniture quickly and correctly, ensuring all pieces are secure and stable.',
                      style: TextStyle(
                        fontSize: responsive.fontSize(14),
                        color: AssetDetailColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                    SizedBox(height: responsive.spacing(24)),

                    // What's Included
                    Text(
                      'What\'s included',
                      style: TextStyle(
                        fontSize: responsive.fontSize(18),
                        fontWeight: FontWeight.bold,
                        color: AssetDetailColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: responsive.spacing(12)),
                    _buildIncludedItem(
                      Icons.build_outlined,
                      'All tools provided',
                    ),
                    _buildIncludedItem(
                      Icons.cleaning_services_outlined,
                      'Clean-up after assembly',
                    ),
                    _buildIncludedItem(
                      Icons.verified_outlined,
                      'Quality check & stability test',
                    ),
                    _buildIncludedItem(
                      Icons.support_agent_outlined,
                      '30-day service guarantee',
                    ),

                    SizedBox(
                      height: responsive.spacing(100),
                    ), // Space for bottom button
                  ],
                ),
              ),
            ],
          ),
        ),

        // Book Now Button
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.all(responsive.spacing(20)),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowDark,
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: ElevatedButton(
                onPressed: _startBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: EdgeInsets.symmetric(
                    vertical: responsive.spacing(16),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Book Now',
                      style: TextStyle(
                        fontSize: responsive.fontSize(16),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: responsive.spacing(8)),
                    Icon(Icons.arrow_forward, size: responsive.iconSize(20)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIncludedItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AssetDetailColors.successColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
            ),
            child: Icon(
              icon,
              size: responsive.iconSize(18),
              color: AssetDetailColors.successColor,
            ),
          ),
          SizedBox(width: responsive.spacing(12)),
          Text(
            text,
            style: TextStyle(
              fontSize: responsive.fontSize(14),
              color: AssetDetailColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // STEP 1: ITEM SELECTION
  // ============================================
  Widget _buildItemSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What furniture needs assembly?',
          style: TextStyle(
            fontSize: responsive.fontSize(20),
            fontWeight: FontWeight.bold,
            color: AssetDetailColors.textPrimary,
          ),
        ),
        SizedBox(height: responsive.spacing(8)),
        Text(
          'Select items and specify quantity',
          style: TextStyle(
            fontSize: responsive.fontSize(14),
            color: AssetDetailColors.textSecondary,
          ),
        ),
        SizedBox(height: responsive.spacing(20)),

        // Items Grid
        ...List.generate(_assemblyItems.length, (index) {
          final item = _assemblyItems[index];
          final itemName = item['name'] as String;
          final isSelected = _selectedItems.containsKey(itemName);
          final quantity = _selectedItems[itemName] ?? 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.transparent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowMedium,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(responsive.spacing(16)),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.backgroundGray100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: isSelected ? AppColors.primary : AppColors.gray600,
                      size: responsive.iconSize(24),
                    ),
                  ),
                  SizedBox(width: responsive.spacing(14)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemName,
                          style: TextStyle(
                            fontSize: responsive.fontSize(15),
                            fontWeight: FontWeight.w600,
                            color: AssetDetailColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: responsive.spacing(2)),
                        Text(
                          '\$${item['price']} each',
                          style: TextStyle(
                            fontSize: responsive.fontSize(13),
                            color: AssetDetailColors.successColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Quantity Controls
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundGray100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              if (quantity > 1) {
                                _selectedItems[itemName] = quantity - 1;
                              } else if (quantity == 1) {
                                _selectedItems.remove(itemName);
                              }
                            });
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.gray300,
                              borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(8),
                              ),
                            ),
                            child: Icon(
                              Icons.remove,
                              size: responsive.iconSize(18),
                              color: isSelected
                                  ? AppColors.white
                                  : AppColors.gray600,
                            ),
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 36,
                          color: AppColors.white,
                          child: Center(
                            child: Text(
                              '$quantity',
                              style: TextStyle(
                                fontSize: responsive.fontSize(15),
                                fontWeight: FontWeight.w600,
                                color: AssetDetailColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _selectedItems[itemName] = quantity + 1;
                            });
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: const BorderRadius.horizontal(
                                right: Radius.circular(8),
                              ),
                            ),
                            child: Icon(
                              Icons.add,
                              size: responsive.iconSize(18),
                              color: AppColors.white,
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
        }),

        SizedBox(height: responsive.spacing(16)),

        // Other Item Input
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowMedium,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _otherItemController,
            decoration: InputDecoration(
              hintText: 'Other item (specify)',
              hintStyle: TextStyle(
                color: AppColors.gray400,
                fontSize: responsive.fontSize(14),
              ),
              prefixIcon: Icon(
                Icons.add_circle_outline,
                color: AppColors.primary,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(responsive.spacing(16)),
            ),
          ),
        ),

        // Total
        if (_selectedItems.isNotEmpty) ...[
          SizedBox(height: responsive.spacing(24)),
          Container(
            padding: EdgeInsets.all(responsive.spacing(16)),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Items Total',
                  style: TextStyle(
                    fontSize: responsive.fontSize(16),
                    fontWeight: FontWeight.w600,
                    color: AssetDetailColors.textPrimary,
                  ),
                ),
                Text(
                  '\$${_totalItemsPrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: responsive.fontSize(20),
                    fontWeight: FontWeight.bold,
                    color: AssetDetailColors.successColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ============================================
  // STEP 2: ADDITIONAL DETAILS
  // ============================================
  Widget _buildAdditionalDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Any special requirements?',
          style: TextStyle(
            fontSize: responsive.fontSize(20),
            fontWeight: FontWeight.bold,
            color: AssetDetailColors.textPrimary,
          ),
        ),
        SizedBox(height: responsive.spacing(8)),
        Text(
          'Add notes or photos to help our professional',
          style: TextStyle(
            fontSize: responsive.fontSize(14),
            color: AssetDetailColors.textSecondary,
          ),
        ),
        SizedBox(height: responsive.spacing(24)),

        // Notes
        Text(
          'Additional Notes',
          style: TextStyle(
            fontSize: responsive.fontSize(14),
            fontWeight: FontWeight.w600,
            color: AssetDetailColors.textPrimary,
          ),
        ),
        SizedBox(height: responsive.spacing(8)),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowMedium,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText:
                  'e.g., Heavy item - may need 2 professionals\nFurniture is on 2nd floor\nPlease bring extra screws',
              hintStyle: TextStyle(
                color: AppColors.gray400,
                fontSize: responsive.fontSize(14),
                height: 1.5,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(responsive.spacing(16)),
            ),
          ),
        ),
        SizedBox(height: responsive.spacing(24)),

        // Photo Upload
        Text(
          'Add Photos (Optional)',
          style: TextStyle(
            fontSize: responsive.fontSize(14),
            fontWeight: FontWeight.w600,
            color: AssetDetailColors.textPrimary,
          ),
        ),
        SizedBox(height: responsive.spacing(8)),
        Text(
          'Upload photos of furniture or assembly instructions',
          style: TextStyle(
            fontSize: responsive.fontSize(13),
            color: AssetDetailColors.textSecondary,
          ),
        ),
        SizedBox(height: responsive.spacing(12)),

        GestureDetector(
          onTap: () {
            // Add photo upload logic
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Photo upload is not yet available.'),
              ),
            );
          },
          child: Container(
            padding: EdgeInsets.all(responsive.spacing(24)),
            decoration: BoxDecoration(
              color: AppColors.backgroundGray50,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.add_photo_alternate_outlined,
                    size: responsive.iconSize(28),
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: responsive.spacing(12)),
                Text(
                  'Tap to add photos',
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    fontWeight: FontWeight.w500,
                    color: AssetDetailColors.textPrimary,
                  ),
                ),
                SizedBox(height: responsive.spacing(4)),
                Text(
                  'JPG, PNG up to 10MB',
                  style: TextStyle(
                    fontSize: responsive.fontSize(12),
                    color: AssetDetailColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (_uploadedPhotos.isNotEmpty) ...[
          SizedBox(height: responsive.spacing(16)),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _uploadedPhotos.map((photo) {
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.gray200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image, color: AppColors.gray400),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // ============================================
  // STEP 3: SCHEDULE
  // ============================================
  Widget _buildScheduleStep() {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    final customDates = List.generate(
      14,
      (i) => today.add(Duration(days: i + 2)),
    );
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    String formatQuickDate(DateTime date) {
      return '${days[date.weekday % 7]}, ${months[date.month - 1]} ${date.day}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'When do you need this service?',
          style: TextStyle(
            fontSize: responsive.fontSize(20),
            fontWeight: FontWeight.bold,
            color: AssetDetailColors.textPrimary,
          ),
        ),
        SizedBox(height: responsive.spacing(8)),
        Text(
          'Select a date and time slot',
          style: TextStyle(
            fontSize: responsive.fontSize(14),
            color: AssetDetailColors.textSecondary,
          ),
        ),
        SizedBox(height: responsive.spacing(24)),

        // Quick Date Selection - Today/Tomorrow/Custom
        Text(
          'Select Date',
          style: TextStyle(
            fontSize: responsive.fontSize(14),
            fontWeight: FontWeight.w600,
            color: AssetDetailColors.textPrimary,
          ),
        ),
        SizedBox(height: responsive.spacing(12)),

        // Today Option
        GestureDetector(
          onTap: () {
            setState(() {
              _dateSelectionType = 'today';
              _selectedDate = today;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: EdgeInsets.all(responsive.spacing(16)),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowMedium,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: _dateSelectionType == 'today'
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _dateSelectionType == 'today'
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.backgroundGray100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.today_outlined,
                    color: _dateSelectionType == 'today'
                        ? AppColors.primary
                        : AppColors.gray600,
                  ),
                ),
                SizedBox(width: responsive.spacing(14)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today',
                        style: TextStyle(
                          fontSize: responsive.fontSize(15),
                          fontWeight: FontWeight.w600,
                          color: _dateSelectionType == 'today'
                              ? AppColors.primary
                              : AssetDetailColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: responsive.spacing(2)),
                      Text(
                        formatQuickDate(today),
                        style: TextStyle(
                          fontSize: responsive.fontSize(13),
                          color: AssetDetailColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _dateSelectionType == 'today'
                          ? AppColors.primary
                          : AppColors.gray300,
                      width: 2,
                    ),
                    color: _dateSelectionType == 'today'
                        ? AppColors.primary
                        : AppColors.white,
                  ),
                  child: _dateSelectionType == 'today'
                      ? Icon(
                          Icons.check,
                          size: responsive.iconSize(14),
                          color: AppColors.textOnPrimary,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),

        // Tomorrow Option
        GestureDetector(
          onTap: () {
            setState(() {
              _dateSelectionType = 'tomorrow';
              _selectedDate = tomorrow;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: EdgeInsets.all(responsive.spacing(16)),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowMedium,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: _dateSelectionType == 'tomorrow'
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _dateSelectionType == 'tomorrow'
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.backgroundGray100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.event_outlined,
                    color: _dateSelectionType == 'tomorrow'
                        ? AppColors.primary
                        : AppColors.gray600,
                  ),
                ),
                SizedBox(width: responsive.spacing(14)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tomorrow',
                        style: TextStyle(
                          fontSize: responsive.fontSize(15),
                          fontWeight: FontWeight.w600,
                          color: _dateSelectionType == 'tomorrow'
                              ? AppColors.primary
                              : AssetDetailColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: responsive.spacing(2)),
                      Text(
                        formatQuickDate(tomorrow),
                        style: TextStyle(
                          fontSize: responsive.fontSize(13),
                          color: AssetDetailColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _dateSelectionType == 'tomorrow'
                          ? AppColors.primary
                          : AppColors.gray300,
                      width: 2,
                    ),
                    color: _dateSelectionType == 'tomorrow'
                        ? AppColors.primary
                        : AppColors.white,
                  ),
                  child: _dateSelectionType == 'tomorrow'
                      ? Icon(
                          Icons.check,
                          size: responsive.iconSize(14),
                          color: AppColors.textOnPrimary,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),

        // Custom Date Option
        GestureDetector(
          onTap: () {
            setState(() {
              _dateSelectionType = 'custom';
              if (_selectedDate == null ||
                  _selectedDate!.day == today.day ||
                  _selectedDate!.day == tomorrow.day) {
                _selectedDate = customDates.first;
              }
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: EdgeInsets.all(responsive.spacing(16)),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowMedium,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: _dateSelectionType == 'custom'
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _dateSelectionType == 'custom'
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.backgroundGray100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.calendar_month_outlined,
                    color: _dateSelectionType == 'custom'
                        ? AppColors.primary
                        : AppColors.gray600,
                  ),
                ),
                SizedBox(width: responsive.spacing(14)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose a Date',
                        style: TextStyle(
                          fontSize: responsive.fontSize(15),
                          fontWeight: FontWeight.w600,
                          color: _dateSelectionType == 'custom'
                              ? AppColors.primary
                              : AssetDetailColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: responsive.spacing(2)),
                      Text(
                        _dateSelectionType == 'custom' && _selectedDate != null
                            ? formatQuickDate(_selectedDate!)
                            : 'Select from calendar',
                        style: TextStyle(
                          fontSize: responsive.fontSize(13),
                          color: AssetDetailColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _dateSelectionType == 'custom'
                          ? AppColors.primary
                          : AppColors.gray300,
                      width: 2,
                    ),
                    color: _dateSelectionType == 'custom'
                        ? AppColors.primary
                        : AppColors.white,
                  ),
                  child: _dateSelectionType == 'custom'
                      ? Icon(
                          Icons.check,
                          size: responsive.iconSize(14),
                          color: AppColors.textOnPrimary,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),

        // Custom Date Picker (shown when custom is selected)
        if (_dateSelectionType == 'custom') ...[
          SizedBox(height: responsive.spacing(16)),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: customDates.length,
              itemBuilder: (context, index) {
                final date = customDates[index];
                final isSelected =
                    _selectedDate?.day == date.day &&
                    _selectedDate?.month == date.month &&
                    _selectedDate?.year == date.year;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                  child: Container(
                    width: 65,
                    margin: EdgeInsets.only(
                      right: index < customDates.length - 1 ? 10 : 0,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowMedium,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          days[date.weekday % 7],
                          style: TextStyle(
                            fontSize: responsive.fontSize(12),
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? AppColors.white.withValues(alpha: 0.8)
                                : AssetDetailColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: responsive.spacing(4)),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: responsive.fontSize(22),
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppColors.white
                                : AssetDetailColors.textPrimary,
                          ),
                        ),
                        Text(
                          months[date.month - 1],
                          style: TextStyle(
                            fontSize: responsive.fontSize(11),
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? AppColors.white.withValues(alpha: 0.8)
                                : AssetDetailColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],

        SizedBox(height: responsive.spacing(28)),

        // Time Slot Selection
        Text(
          'Select Time Slot',
          style: TextStyle(
            fontSize: responsive.fontSize(14),
            fontWeight: FontWeight.w600,
            color: AssetDetailColors.textPrimary,
          ),
        ),
        SizedBox(height: responsive.spacing(12)),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.8,
          ),
          itemCount: _timeSlots.length,
          itemBuilder: (context, index) {
            final slot = _timeSlots[index];
            final isSelected = _selectedTimeSlot == slot;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTimeSlot = slot;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.gray300,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    slot,
                    style: TextStyle(
                      fontSize: responsive.fontSize(13),
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? AppColors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // Estimated Duration
        SizedBox(height: responsive.spacing(16)),
        Container(
          padding: EdgeInsets.all(responsive.spacing(16)),
          decoration: BoxDecoration(
            color: AppColors.amber,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.access_time,
                color: AppColors.amber,
                size: responsive.iconSize(20),
              ),
              SizedBox(width: responsive.spacing(12)),
              Text(
                'Estimated duration: 1-2 hours',
                style: TextStyle(
                  fontSize: responsive.fontSize(14),
                  color: AppColors.amber,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================
  // STEP 4: LOCATION
  // ============================================
  Widget _buildLocationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Where do you need this service?',
          style: TextStyle(
            fontSize: responsive.fontSize(20),
            fontWeight: FontWeight.bold,
            color: AssetDetailColors.textPrimary,
          ),
        ),
        SizedBox(height: responsive.spacing(8)),
        Text(
          'Select or confirm service location',
          style: TextStyle(
            fontSize: responsive.fontSize(14),
            color: AssetDetailColors.textSecondary,
          ),
        ),
        SizedBox(height: responsive.spacing(24)),

        // Home Selection
        Text(
          'Select Home',
          style: TextStyle(
            fontSize: responsive.fontSize(14),
            fontWeight: FontWeight.w600,
            color: AssetDetailColors.textPrimary,
          ),
        ),
        SizedBox(height: responsive.spacing(12)),
        ...List.generate(_userHomes.length, (index) {
          final home = _userHomes[index];
          final isSelected = _selectedHomeId == home['id'];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedHomeId = home['id'];
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(responsive.spacing(16)),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowMedium,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.backgroundGray100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.home_outlined,
                      color: isSelected ? AppColors.primary : AppColors.gray600,
                      size: responsive.iconSize(24),
                    ),
                  ),
                  SizedBox(width: responsive.spacing(14)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              home['name'] as String,
                              style: TextStyle(
                                fontSize: responsive.fontSize(15),
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? AppColors.primary
                                    : AssetDetailColors.textPrimary,
                              ),
                            ),
                            if (home['isDefault'] == true) ...[
                              SizedBox(width: responsive.spacing(8)),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusBadge,
                                  ),
                                ),
                                child: Text(
                                  'Default',
                                  style: TextStyle(
                                    fontSize: responsive.fontSize(10),
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: responsive.spacing(4)),
                        Text(
                          home['address'] as String,
                          style: TextStyle(
                            fontSize: responsive.fontSize(13),
                            color: AssetDetailColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.gray300,
                        width: 2,
                      ),
                      color: isSelected ? AppColors.primary : AppColors.white,
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            size: responsive.iconSize(14),
                            color: AppColors.white,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          );
        }),

        SizedBox(height: responsive.spacing(24)),

        // Room Details
        Text(
          'Room/Floor Details (Optional)',
          style: TextStyle(
            fontSize: responsive.fontSize(14),
            fontWeight: FontWeight.w600,
            color: AssetDetailColors.textPrimary,
          ),
        ),
        SizedBox(height: responsive.spacing(8)),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowMedium,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _roomDetailsController,
            decoration: InputDecoration(
              hintText: 'e.g., Living room, 2nd floor, Apt 4B',
              hintStyle: TextStyle(
                color: AppColors.gray400,
                fontSize: responsive.fontSize(14),
              ),
              prefixIcon: Icon(
                Icons.meeting_room_outlined,
                color: AppColors.primary,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(responsive.spacing(16)),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================
  // STEP 5: REVIEW
  // ============================================
  Widget _buildReviewStep() {
    final selectedHome = _getSelectedHome();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review your booking',
          style: TextStyle(
            fontSize: responsive.fontSize(20),
            fontWeight: FontWeight.bold,
            color: AssetDetailColors.textPrimary,
          ),
        ),
        SizedBox(height: responsive.spacing(8)),
        Text(
          'Please confirm all details are correct',
          style: TextStyle(
            fontSize: responsive.fontSize(14),
            color: AssetDetailColors.textSecondary,
          ),
        ),
        SizedBox(height: responsive.spacing(24)),

        // Summary Card
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowMedium,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Service
              _buildReviewRow(
                icon: Icons.home_repair_service_outlined,
                label: 'Service',
                value: widget.service['name'] as String,
              ),
              _buildReviewDivider(),

              // Items
              _buildReviewRow(
                icon: Icons.inventory_2_outlined,
                label: 'Items',
                value: _selectedItems.entries
                    .map((e) => '${e.value}x ${e.key}')
                    .join(', '),
              ),
              _buildReviewDivider(),

              // Date & Time
              _buildReviewRow(
                icon: Icons.calendar_today_outlined,
                label: 'Date & Time',
                value: '${_getFormattedDate()}\n$_selectedTimeSlot',
              ),
              _buildReviewDivider(),

              // Location
              if (selectedHome != null)
                _buildReviewRow(
                  icon: Icons.location_on_outlined,
                  label: 'Location',
                  value:
                      '${selectedHome['name']}\n${selectedHome['address']}${_roomDetailsController.text.isNotEmpty ? '\n${_roomDetailsController.text}' : ''}',
                ),
              _buildReviewDivider(),

              // Professional
              _buildReviewRow(
                icon: Icons.person_outlined,
                label: 'Professional',
                value: 'Auto-assigned (Best Match)',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AssetDetailColors.successColor.withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusBadge,
                    ),
                  ),
                  child: Text(
                    'Recommended',
                    style: TextStyle(
                      fontSize: responsive.fontSize(10),
                      fontWeight: FontWeight.w600,
                      color: AssetDetailColors.successColor,
                    ),
                  ),
                ),
              ),

              // Notes (if any)
              if (_notesController.text.isNotEmpty) ...[
                _buildReviewDivider(),
                _buildReviewRow(
                  icon: Icons.note_outlined,
                  label: 'Notes',
                  value: _notesController.text,
                ),
              ],
            ],
          ),
        ),

        SizedBox(height: responsive.spacing(24)),

        // Price Breakdown
        Container(
          padding: EdgeInsets.all(responsive.spacing(16)),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowMedium,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Base Price',
                    style: TextStyle(fontSize: responsive.fontSize(14)),
                  ),
                  Text(
                    '\$${_basePrice.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: responsive.fontSize(14),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: responsive.spacing(8)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Items',
                    style: TextStyle(fontSize: responsive.fontSize(14)),
                  ),
                  Text(
                    '\$${_totalItemsPrice.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: responsive.fontSize(14),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: responsive.spacing(12)),
              Divider(color: AppColors.gray200),
              SizedBox(height: responsive.spacing(12)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      fontSize: responsive.fontSize(18),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '\$${_totalPrice.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: responsive.fontSize(22),
                      fontWeight: FontWeight.bold,
                      color: AssetDetailColors.successColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: responsive.spacing(24)),

        // Terms and Conditions
        GestureDetector(
          onTap: () {
            setState(() {
              _termsAccepted = !_termsAccepted;
            });
          },
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: responsive.spacing(8)),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: _termsAccepted
                        ? AppColors.success
                        : AppColors.transparent,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusBadge,
                    ),
                    border: _termsAccepted
                        ? null
                        : Border.all(color: AppColors.gray400, width: 1.5),
                  ),
                  child: _termsAccepted
                      ? Icon(
                          Icons.check,
                          color: AppColors.white,
                          size: responsive.iconSize(16),
                        )
                      : null,
                ),
                SizedBox(width: responsive.spacing(12)),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: responsive.fontSize(13),
                        color: AppColors.textQuaternary,
                      ),
                      children: [
                        const TextSpan(text: 'I agree to the '),
                        TextSpan(
                          text: 'Terms of Service',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Cancellation Policy',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (!_termsAccepted) ...[
          SizedBox(height: responsive.spacing(8)),
          Text(
            'Please accept the terms to continue',
            style: TextStyle(
              fontSize: responsive.fontSize(12),
              color: AppColors.warningOrange,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReviewRow({
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Padding(
      padding: EdgeInsets.all(responsive.spacing(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: responsive.iconSize(20), color: AppColors.primary),
          SizedBox(width: responsive.spacing(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: responsive.fontSize(12),
                    color: AssetDetailColors.textSecondary,
                  ),
                ),
                SizedBox(height: responsive.spacing(4)),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    fontWeight: FontWeight.w500,
                    color: AssetDetailColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _buildReviewDivider() {
    return Divider(height: 1, color: AppColors.backgroundGray100, indent: 48);
  }

  // ============================================
  // STEP 6: PAYMENT
  // ============================================
  Widget _buildPaymentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment',
          style: TextStyle(
            fontSize: responsive.fontSize(20),
            fontWeight: FontWeight.bold,
            color: AssetDetailColors.textPrimary,
          ),
        ),
        SizedBox(height: responsive.spacing(8)),
        Text(
          'Select payment method',
          style: TextStyle(
            fontSize: responsive.fontSize(14),
            color: AssetDetailColors.textSecondary,
          ),
        ),
        SizedBox(height: responsive.spacing(24)),

        // Payment Methods
        ...List.generate(_paymentMethods.length, (index) {
          final method = _paymentMethods[index];
          final isSelected = _selectedPaymentMethod == method['id'];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedPaymentMethod = method['id'] as String;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(responsive.spacing(16)),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowMedium,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.backgroundGray100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      method['icon'] as IconData,
                      color: isSelected ? AppColors.primary : AppColors.gray600,
                      size: responsive.iconSize(24),
                    ),
                  ),
                  SizedBox(width: responsive.spacing(14)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          method['type'] == 'wallet'
                              ? AppStrings.walletName
                              : '${(method['type'] as String).toUpperCase()} •••• ${method['last4']}',
                          style: TextStyle(
                            fontSize: responsive.fontSize(15),
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.primary
                                : AssetDetailColors.textPrimary,
                          ),
                        ),
                        if (method['balance'] != null) ...[
                          SizedBox(height: responsive.spacing(2)),
                          Text(
                            'Balance: ${method['balance']}',
                            style: TextStyle(
                              fontSize: responsive.fontSize(13),
                              color: AssetDetailColors.successColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.gray300,
                        width: 2,
                      ),
                      color: isSelected ? AppColors.primary : AppColors.white,
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            size: responsive.iconSize(14),
                            color: AppColors.textOnPrimary,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          );
        }),

        // Add Payment Method
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Adding a payment method is not yet available.'),
              ),
            );
          },
          child: Container(
            padding: EdgeInsets.all(responsive.spacing(16)),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: AppColors.primary),
                SizedBox(width: responsive.spacing(8)),
                Text(
                  'Add Payment Method',
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: responsive.spacing(32)),

        // Total Amount
        Container(
          padding: EdgeInsets.all(responsive.spacing(20)),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: responsive.fontSize(14),
                      color: AssetDetailColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(4)),
                  Text(
                    'Pay now to confirm booking',
                    style: TextStyle(
                      fontSize: responsive.fontSize(12),
                      color: AssetDetailColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Text(
                '\$${_totalPrice.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: responsive.fontSize(28),
                  fontWeight: FontWeight.bold,
                  color: AssetDetailColors.successColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================
  // CONFIRMATION SCREEN
  // ============================================
  Widget _buildConfirmationScreen() {
    final selectedHome = _getSelectedHome();
    final bookingId =
        '#${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(responsive.spacing(24)),
          child: Column(
            children: [
              const Spacer(),

              // Success Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AssetDetailColors.successColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: responsive.iconSize(60),
                  color: AssetDetailColors.successColor,
                ),
              ),
              SizedBox(height: responsive.spacing(24)),

              // Title
              Text(
                'Booking Confirmed!',
                style: TextStyle(
                  fontSize: responsive.fontSize(26),
                  fontWeight: FontWeight.bold,
                  color: AssetDetailColors.textPrimary,
                ),
              ),
              SizedBox(height: responsive.spacing(8)),
              Text(
                'Booking ID: $bookingId',
                style: TextStyle(
                  fontSize: responsive.fontSize(14),
                  color: AssetDetailColors.textSecondary,
                ),
              ),
              SizedBox(height: responsive.spacing(32)),

              // Details Card
              Container(
                padding: EdgeInsets.all(responsive.spacing(20)),
                decoration: BoxDecoration(
                  color: AppColors.backgroundGray50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildConfirmationRow(
                      Icons.calendar_today_outlined,
                      _getFormattedDate(),
                    ),
                    SizedBox(height: responsive.spacing(16)),
                    _buildConfirmationRow(
                      Icons.access_time,
                      _selectedTimeSlot ?? '',
                    ),
                    SizedBox(height: responsive.spacing(16)),
                    _buildConfirmationRow(
                      Icons.location_on_outlined,
                      selectedHome?['address'] as String? ?? '',
                    ),
                    SizedBox(height: responsive.spacing(16)),
                    _buildConfirmationRow(
                      Icons.attach_money,
                      '\$${_totalPrice.toStringAsFixed(0)}',
                    ),
                  ],
                ),
              ),

              SizedBox(height: responsive.spacing(24)),

              // Professional Info
              Container(
                padding: EdgeInsets.all(responsive.spacing(16)),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: AppColors.shadowMedium, blurRadius: 8),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.auto_awesome,
                          color: AppColors.white,
                          size: responsive.iconSize(24),
                        ),
                      ),
                    ),
                    SizedBox(width: responsive.spacing(14)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Professional will be assigned',
                            style: TextStyle(
                              fontSize: responsive.fontSize(14),
                              fontWeight: FontWeight.w600,
                              color: AssetDetailColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: responsive.spacing(2)),
                          Text(
                            'You\'ll receive details before the service',
                            style: TextStyle(
                              fontSize: responsive.fontSize(12),
                              color: AssetDetailColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: responsive.spacing(24)),

              // What's Next Section
              Container(
                padding: EdgeInsets.all(responsive.spacing(16)),
                decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: responsive.iconSize(20),
                          color: AppColors.info,
                        ),
                        SizedBox(width: responsive.spacing(8)),
                        Text(
                          'What\'s Next?',
                          style: TextStyle(
                            fontSize: responsive.fontSize(15),
                            fontWeight: FontWeight.bold,
                            color: AppColors.infoDark,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: responsive.spacing(12)),
                    _buildWhatsNextItem(
                      '1.',
                      'You\'ll receive a confirmation email shortly',
                    ),
                    SizedBox(height: responsive.spacing(8)),
                    _buildWhatsNextItem(
                      '2.',
                      'Professional details will be shared 24 hours before your appointment.',
                    ),
                    SizedBox(height: responsive.spacing(8)),
                    _buildWhatsNextItem('3.', 'Track your booking in the app'),
                  ],
                ),
              ),

              const Spacer(),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Receipt downloaded')),
                        );
                      },
                      icon: Icon(
                        Icons.download_outlined,
                        size: responsive.iconSize(18),
                      ),
                      label: const Text('Download Receipt'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(
                          vertical: responsive.spacing(14),
                        ),
                        side: BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                  SizedBox(width: responsive.spacing(12)),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added to calendar')),
                        );
                      },
                      icon: Icon(
                        Icons.calendar_month,
                        size: responsive.iconSize(18),
                      ),
                      label: const Text('Add to Calendar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(
                          vertical: responsive.spacing(14),
                        ),
                        side: BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: responsive.spacing(12)),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: EdgeInsets.symmetric(
                      vertical: responsive.spacing(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Go to Home',
                    style: TextStyle(
                      fontSize: responsive.fontSize(16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWhatsNextItem(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: TextStyle(
            fontSize: responsive.fontSize(13),
            fontWeight: FontWeight.w600,
            color: AppColors.info,
          ),
        ),
        SizedBox(width: responsive.spacing(8)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: responsive.fontSize(13),
              color: AppColors.infoDark,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: responsive.iconSize(20), color: AppColors.primary),
        SizedBox(width: responsive.spacing(14)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: responsive.fontSize(14),
              fontWeight: FontWeight.w500,
              color: AssetDetailColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================
  // BOTTOM NAVIGATION
  // ============================================
  Widget _buildBottomNavigation() {
    String buttonText;
    switch (_currentStep) {
      case 4:
        buttonText = 'Proceed to Payment';
        break;
      case 5:
        buttonText = 'Pay \$${_totalPrice.toStringAsFixed(0)}';
        break;
      default:
        buttonText = 'Continue';
    }

    return Container(
      padding: EdgeInsets.all(responsive.spacing(20)),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowDark,
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Price Summary (show on steps after item selection)
            if (_currentStep > 0 && _selectedItems.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      fontSize: responsive.fontSize(14),
                      color: AssetDetailColors.textSecondary,
                    ),
                  ),
                  Text(
                    '\$${_totalPrice.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: responsive.fontSize(18),
                      fontWeight: FontWeight.bold,
                      color: AssetDetailColors.successColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: responsive.spacing(12)),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: EdgeInsets.symmetric(
                    vertical: responsive.spacing(16),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      buttonText,
                      style: TextStyle(
                        fontSize: responsive.fontSize(16),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_currentStep < 5) ...[
                      SizedBox(width: responsive.spacing(8)),
                      Icon(Icons.arrow_forward, size: responsive.iconSize(18)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
