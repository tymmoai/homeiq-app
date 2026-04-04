import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../utils/responsive_utils.dart';

/// Full-screen editor for asset details with sections for basic info, purchase,
/// and additional details. All fields pre-filled and styled consistently.
class EditAssetDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> asset;
  final void Function(Map<String, dynamic> updatedFields) onSave;

  const EditAssetDetailsScreen({
    super.key,
    required this.asset,
    required this.onSave,
  });

  @override
  State<EditAssetDetailsScreen> createState() => _EditAssetDetailsScreenState();
}

class _EditAssetDetailsScreenState extends State<EditAssetDetailsScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _serialController;
  late final TextEditingController _locationController;
  late final TextEditingController _purchaseDateController;
  late final TextEditingController _warrantyExpiryController;
  late final TextEditingController _manufacturerController;
  late final TextEditingController _colorController;

  DateTime? _selectedPurchaseDate;
  DateTime? _selectedWarrantyExpiry;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.asset;

    _nameController =
        TextEditingController(text: a['name']?.toString() ?? '');
    _brandController =
        TextEditingController(text: a['brand']?.toString() ?? '');
    _modelController =
        TextEditingController(text: a['model']?.toString() ?? '');
    _serialController = TextEditingController(
      text: a['serial']?.toString() ?? a['serialNumber']?.toString() ?? '',
    );
    _locationController =
        TextEditingController(text: a['location']?.toString() ?? '');

    // Purchase date - prefer full ISO date (purchasedAt), fall back to formatted text or year
    var purchaseDateText = '';
    final purchasedAtIso = a['purchasedAt']?.toString();
    if (purchasedAtIso != null && purchasedAtIso.isNotEmpty && purchasedAtIso != 'null') {
      try {
        final parsed = DateTime.parse(purchasedAtIso);
        _selectedPurchaseDate = parsed;
        purchaseDateText = _formatDate(parsed);
      } on Object catch (_) {
        // Fall back to purchaseDate or purchaseYear
        final rawPurchaseDate = a['purchaseDate'] ?? a['purchaseYear'];
        purchaseDateText = rawPurchaseDate?.toString() ?? '';
        if (rawPurchaseDate != null) {
          final year = int.tryParse(rawPurchaseDate.toString());
          if (year != null && year > 1900 && year <= DateTime.now().year) {
            _selectedPurchaseDate = DateTime(year, 1, 1);
          }
        }
      }
    } else {
      // Fallback: use purchaseDate or purchaseYear
      final rawPurchaseDate = a['purchaseDate'] ?? a['purchaseYear'];
      purchaseDateText = rawPurchaseDate?.toString() ?? '';
      if (rawPurchaseDate != null) {
        final year = int.tryParse(rawPurchaseDate.toString());
        if (year != null && year > 1900 && year <= DateTime.now().year) {
          _selectedPurchaseDate = DateTime(year, 1, 1);
        }
      }
    }
    _purchaseDateController = TextEditingController(text: purchaseDateText);

    // Warranty expiry
    final rawWarrantyExpiry =
        a['warrantyEndDate'] ?? a['warrantyExpiresAt'];
    String warrantyStr = '';
    if (rawWarrantyExpiry != null) {
      final parsed = DateTime.tryParse(rawWarrantyExpiry.toString());
      if (parsed != null) {
        _selectedWarrantyExpiry = parsed;
        warrantyStr = _formatDate(parsed);
      } else {
        warrantyStr = rawWarrantyExpiry.toString();
      }
    }
    _warrantyExpiryController = TextEditingController(text: warrantyStr);

    _manufacturerController =
        TextEditingController(text: a['manufacturer']?.toString() ?? '');
    _colorController =
        TextEditingController(text: a['productColor']?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _serialController.dispose();
    _locationController.dispose();
    _purchaseDateController.dispose();
    _warrantyExpiryController.dispose();
    _manufacturerController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _pickPurchaseDate(ResponsiveUtils responsive) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedPurchaseDate ?? DateTime(DateTime.now().year - 2, 1, 1),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: Theme.of(context).colorScheme.primary,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedPurchaseDate = picked;
        _purchaseDateController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _pickWarrantyExpiry(ResponsiveUtils responsive) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedWarrantyExpiry ??
          DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime(1990),
      lastDate: DateTime(DateTime.now().year + 20),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: Theme.of(context).colorScheme.primary,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedWarrantyExpiry = picked;
        _warrantyExpiryController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);

    final updates = <String, dynamic>{
      'name': _nameController.text.trim(),
      'brand': _brandController.text.trim(),
      'model': _modelController.text.trim(),
      'serial': _serialController.text.trim(),
      'serialNumber': _serialController.text.trim(),
      'location': _locationController.text.trim(),
      'purchaseDate': _purchaseDateController.text,
      'manufacturer': _manufacturerController.text.trim(),
      'productColor': _colorController.text.trim(),
    };

    if (_selectedPurchaseDate != null) {
      // Send full purchase date as UTC ISO string for consistent backend storage
      // Construct UTC date from the year/month/day
      final purchaseGmt = _selectedPurchaseDate!.isUtc 
          ? _selectedPurchaseDate!
          : DateTime.utc(
              _selectedPurchaseDate!.year,
              _selectedPurchaseDate!.month,
              _selectedPurchaseDate!.day,
            );
      updates['purchasedAt'] = purchaseGmt.toIso8601String();
      updates['purchaseYear'] = _selectedPurchaseDate!.year;
      updates['purchaseMonth'] = _selectedPurchaseDate!.month;
    }

    if (_selectedWarrantyExpiry != null) {
      // Ensure warranty date is sent as UTC ISO string for consistent backend storage
      // If the selected date is already in UTC (from parse), use it directly
      // Otherwise, construct a UTC date from the year/month/day values
      final gmt = _selectedWarrantyExpiry!.isUtc 
          ? _selectedWarrantyExpiry!
          : DateTime.utc(
              _selectedWarrantyExpiry!.year,
              _selectedWarrantyExpiry!.month,
              _selectedWarrantyExpiry!.day,
            );
      updates['warrantyExpiresAt'] = gmt.toIso8601String();
      updates['warrantyEndDate'] = gmt.toIso8601String();
    }

    widget.onSave(updates);

    // Small delay for visual feedback
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Asset details updated successfully'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          'Edit Asset Details',
          style: TextStyle(
            fontSize: responsive.fontSize(18.0),
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(responsive.spacing(20.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── BASIC INFO ────────────────────────────────────────────────
            _sectionHeader('BASIC INFO', responsive, primaryColor),
            _buildField(
              controller: _nameController,
              label: 'Asset Name',
              icon: Icons.label_outlined,
              responsive: responsive,
              backgroundColor: backgroundColor,
              primaryColor: primaryColor,
            ),
            SizedBox(height: responsive.spacing(14.0)),
            _buildField(
              controller: _brandController,
              label: 'Brand',
              icon: Icons.business_outlined,
              hint: 'e.g., Samsung, LG',
              responsive: responsive,
              backgroundColor: backgroundColor,
              primaryColor: primaryColor,
            ),
            SizedBox(height: responsive.spacing(14.0)),
            _buildField(
              controller: _modelController,
              label: 'Model',
              icon: Icons.devices_outlined,
              hint: 'e.g., XYZ-123',
              responsive: responsive,
              backgroundColor: backgroundColor,
              primaryColor: primaryColor,
            ),
            SizedBox(height: responsive.spacing(14.0)),
            _buildField(
              controller: _serialController,
              label: 'Serial Number',
              icon: Icons.pin_outlined,
              responsive: responsive,
              backgroundColor: backgroundColor,
              primaryColor: primaryColor,
            ),
            SizedBox(height: responsive.spacing(14.0)),
            _buildField(
              controller: _locationController,
              label: 'Location',
              icon: Icons.location_on_outlined,
              hint: 'e.g., Kitchen, Living Room',
              responsive: responsive,
              backgroundColor: backgroundColor,
              primaryColor: primaryColor,
            ),

            // ── PURCHASE & WARRANTY ───────────────────────────────────────
            _sectionHeader('PURCHASE & WARRANTY', responsive, primaryColor),
            SizedBox(height: responsive.spacing(8.0)),
            _buildField(
              controller: _purchaseDateController,
              label: 'Purchase Date',
              icon: Icons.calendar_today_outlined,
              readOnly: true,
              onTap: () => _pickPurchaseDate(responsive),
              hint: 'Tap to select date',
              suffix: GestureDetector(
                onTap: () => _pickPurchaseDate(responsive),
                child: Padding(
                  padding: EdgeInsets.only(right: responsive.spacing(14.0)),
                  child: Icon(
                    Icons.calendar_month_outlined,
                    size: responsive.iconSize(20.0),
                    color: primaryColor,
                  ),
                ),
              ),
              responsive: responsive,
              backgroundColor: backgroundColor,
              primaryColor: primaryColor,
            ),
            SizedBox(height: responsive.spacing(14.0)),
            _buildField(
              controller: _warrantyExpiryController,
              label: 'Warranty Expires',
              icon: Icons.shield_outlined,
              readOnly: true,
              onTap: () => _pickWarrantyExpiry(responsive),
              hint: 'Tap to select date',
              suffix: GestureDetector(
                onTap: () => _pickWarrantyExpiry(responsive),
                child: Padding(
                  padding: EdgeInsets.only(right: responsive.spacing(14.0)),
                  child: Icon(
                    Icons.calendar_month_outlined,
                    size: responsive.iconSize(20.0),
                    color: primaryColor,
                  ),
                ),
              ),
              responsive: responsive,
              backgroundColor: backgroundColor,
              primaryColor: primaryColor,
            ),

            // ── MORE DETAILS ──────────────────────────────────────────────
            _sectionHeader('MORE DETAILS', responsive, primaryColor),
            SizedBox(height: responsive.spacing(8.0)),
            _buildField(
              controller: _manufacturerController,
              label: 'Manufacturer',
              icon: Icons.domain_outlined,
              responsive: responsive,
              backgroundColor: backgroundColor,
              primaryColor: primaryColor,
            ),
            SizedBox(height: responsive.spacing(14.0)),
            _buildField(
              controller: _colorController,
              label: 'Color',
              icon: Icons.palette_outlined,
              hint: 'e.g., Black, Silver, Rose Gold',
              responsive: responsive,
              backgroundColor: backgroundColor,
              primaryColor: primaryColor,
            ),

            // ── SAVE BUTTON ───────────────────────────────────────────────
            SizedBox(height: responsive.spacing(32.0)),
            SizedBox(
              width: double.infinity,
              height: responsive.spacing(50.0),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: primaryColor.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      responsive.borderRadius(12.0),
                    ),
                  ),
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    vertical: responsive.spacing(14.0),
                  ),
                ),
                child: _isSaving
                    ? SizedBox(
                        height: responsive.spacing(24.0),
                        width: responsive.spacing(24.0),
                        child: const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: responsive.fontSize(16.0),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
            ),
            SizedBox(height: responsive.spacing(20.0)),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(
      String title, ResponsiveUtils responsive, Color primaryColor) {
    return Padding(
      padding: EdgeInsets.only(top: responsive.spacing(24.0)),
      child: Row(
        children: [
          Container(
            width: responsive.spacing(3.0),
            height: responsive.spacing(16.0),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(responsive.spacing(2.0)),
            ),
          ),
          SizedBox(width: responsive.spacing(8.0)),
          Text(
            title,
            style: TextStyle(
              fontSize: responsive.fontSize(12.0),
              fontWeight: FontWeight.w700,
              color: primaryColor,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ResponsiveUtils responsive,
    required Color backgroundColor,
    required Color primaryColor,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    int maxLines = 1,
    String? hint,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: responsive.fontSize(12.0),
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: responsive.spacing(6.0)),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          maxLines: maxLines,
          style: TextStyle(
            fontSize: responsive.fontSize(14.0),
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint ?? label,
            hintStyle: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.55),
              fontSize: responsive.fontSize(14.0),
            ),
            prefixIcon: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.spacing(12.0),
                vertical: maxLines > 1 ? responsive.spacing(12.0) : 0,
              ),
              child: Icon(
                icon,
                size: responsive.iconSize(18.0),
                color: AppColors.textSecondary,
              ),
            ),
            prefixIconConstraints: BoxConstraints(
              minWidth: responsive.spacing(44.0),
              minHeight: responsive.spacing(44.0),
            ),
            suffixIcon: suffix,
            filled: true,
            fillColor: backgroundColor,
            border: InputBorder.none,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                responsive.borderRadius(10.0),
              ),
              borderSide: BorderSide(
                color: AppColors.divider,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                responsive.borderRadius(10.0),
              ),
              borderSide: BorderSide(
                color: primaryColor,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: responsive.spacing(4.0),
              vertical: maxLines > 1 ? responsive.spacing(12.0) : 0,
            ),
          ),
        ),
      ],
    );
  }
}