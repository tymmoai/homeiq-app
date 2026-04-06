import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../theme/asset_detail_colors.dart';

/// Bottom sheet for editing all editable asset details.
///
/// Three sections:
///   1. Basic Info      — name, brand, model, serial number, location
///   2. Purchase Info   — purchase date, warranty expiry
///   3. More Details    — manufacturer, color, barcode, notes
class EditAssetDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> asset;
  final void Function(Map<String, dynamic> updatedFields) onSave;

  const EditAssetDetailsSheet({
    super.key,
    required this.asset,
    required this.onSave,
  });

  @override
  State<EditAssetDetailsSheet> createState() => _EditAssetDetailsSheetState();
}

class _EditAssetDetailsSheetState extends State<EditAssetDetailsSheet> {
  // ── Basic Info ───────────────────────────────────────────────────────────
  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _serialController;
  late final TextEditingController _locationController;

  // ── Purchase & Warranty ──────────────────────────────────────────────────
  late final TextEditingController _purchaseDateController;
  late final TextEditingController _warrantyExpiryController;
  DateTime? _selectedPurchaseDate;
  DateTime? _selectedWarrantyExpiry;

  // ── More Details  ────────────────────────────────────────────────────────
  late final TextEditingController _manufacturerController;
  late final TextEditingController _colorController;

  @override
  void initState() {
    super.initState();
    final a = widget.asset;

    _nameController = TextEditingController(text: a['name']?.toString() ?? '');
    _brandController = TextEditingController(
      text: a['brand']?.toString() ?? '',
    );
    _modelController = TextEditingController(
      text: a['model']?.toString() ?? '',
    );
    _serialController = TextEditingController(
      text: a['serial']?.toString() ?? a['serialNumber']?.toString() ?? '',
    );
    _locationController = TextEditingController(
      text: a['location']?.toString() ?? '',
    );

    // Purchase date — stored as year int or displayable string
    final rawPurchaseDate = a['purchaseDate'] ?? a['purchaseYear'];
    _purchaseDateController = TextEditingController(
      text: rawPurchaseDate?.toString() ?? '',
    );
    if (rawPurchaseDate != null) {
      final year = int.tryParse(rawPurchaseDate.toString());
      if (year != null && year > 1900 && year <= DateTime.now().year) {
        _selectedPurchaseDate = DateTime(year, 1, 1);
      }
    }

    // Warranty expiry — ISO string or display string
    final rawWarrantyExpiry = a['warrantyEndDate'] ?? a['warrantyExpiresAt'];
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

    _manufacturerController = TextEditingController(
      text: a['manufacturer']?.toString() ?? '',
    );
    _colorController = TextEditingController(
      text: a['productColor']?.toString() ?? '',
    );
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
    return '${months[date.month - 1]} ${date.year}';
  }

  ThemeData _datePickerTheme(BuildContext ctx) => Theme.of(ctx).copyWith(
    colorScheme: ColorScheme.light(
      primary: AssetDetailColors.primaryDark,
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: Colors.black,
    ),
  );

  Future<void> _pickPurchaseDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedPurchaseDate ?? DateTime(DateTime.now().year - 2, 1, 1),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      builder: (ctx, child) =>
          Theme(data: _datePickerTheme(ctx), child: child!),
    );
    if (picked != null) {
      setState(() {
        _selectedPurchaseDate = picked;
        _purchaseDateController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _pickWarrantyExpiry() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedWarrantyExpiry ??
          DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime(1990),
      lastDate: DateTime(DateTime.now().year + 20),
      builder: (ctx, child) =>
          Theme(data: _datePickerTheme(ctx), child: child!),
    );
    if (picked != null) {
      setState(() {
        _selectedWarrantyExpiry = picked;
        _warrantyExpiryController.text = _formatDate(picked);
      });
    }
  }

  void _handleSave() {
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
      updates['purchaseYear'] = _selectedPurchaseDate!.year;
    }
    if (_selectedWarrantyExpiry != null) {
      updates['warrantyExpiresAt'] = _selectedWarrantyExpiry!.toIso8601String();
      updates['warrantyEndDate'] = _selectedWarrantyExpiry!.toIso8601String();
    }
    widget.onSave(updates);
    Navigator.of(context).pop();
  }

  // ── UI helpers ───────────────────────────────────────────────────────────

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AssetDetailColors.primaryDark,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AssetDetailColors.primaryDark,
            letterSpacing: 0.8,
          ),
        ),
      ],
    ),
  );

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    int maxLines = 1,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AssetDetailColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundGray50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AssetDetailColors.borderColor, width: 1),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            onTap: onTap,
            maxLines: maxLines,
            style: TextStyle(
              fontSize: 14,
              color: AssetDetailColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint ?? label,
              hintStyle: TextStyle(
                color: AssetDetailColors.textSecondary.withValues(alpha: 0.55),
                fontSize: 14,
              ),
              prefixIcon: Padding(
                padding: EdgeInsets.only(top: maxLines > 1 ? 12 : 0),
                child: Icon(
                  icon,
                  size: 18,
                  color: AssetDetailColors.textSecondary,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 44,
                minHeight: 44,
              ),
              suffixIcon: readOnly && onTap != null
                  ? const Icon(Icons.chevron_right, size: 18)
                  : null,
              filled: true,
              fillColor: Colors.transparent,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 4,
                vertical: maxLines > 1 ? 12 : 0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 2),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AssetDetailColors.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Edit Asset Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AssetDetailColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  color: AssetDetailColors.textSecondary,
                ),
              ],
            ),
          ),
          // Scrollable fields
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Basic Info ─────────────────────────────────────────
                  _sectionHeader('BASIC INFO'),
                  _buildField(
                    controller: _nameController,
                    label: 'Asset Name',
                    icon: Icons.label_outline,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _brandController,
                    label: 'Brand',
                    icon: Icons.business_outlined,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _modelController,
                    label: 'Model',
                    icon: Icons.devices_outlined,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _serialController,
                    label: 'Serial Number',
                    icon: Icons.pin_outlined,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _locationController,
                    label: 'Location',
                    icon: Icons.location_on_outlined,
                    hint: 'e.g., Kitchen, Living Room',
                  ),

                  // ── Purchase & Warranty ────────────────────────────────
                  _sectionHeader('PURCHASE & WARRANTY'),
                  _buildField(
                    controller: _purchaseDateController,
                    label: 'Purchase Date',
                    icon: Icons.calendar_today_outlined,
                    readOnly: true,
                    onTap: _pickPurchaseDate,
                    hint: 'Tap to select date',
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _warrantyExpiryController,
                    label: 'Warranty Expires',
                    icon: Icons.shield_outlined,
                    readOnly: true,
                    onTap: _pickWarrantyExpiry,
                    hint: 'Tap to select date',
                  ),

                  // ── More Details ───────────────────────────────────────
                  _sectionHeader('MORE DETAILS'),
                  _buildField(
                    controller: _manufacturerController,
                    label: 'Manufacturer',
                    icon: Icons.domain_outlined,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _colorController,
                    label: 'Color',
                    icon: Icons.palette_outlined,
                    hint: 'e.g., Black, Silver',
                  ),

                  // ── Save button ────────────────────────────────────────
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AssetDetailColors.primaryDark,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
    );
  }
}
