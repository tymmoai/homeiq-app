import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../utils/responsive_utils.dart';
import 'payment_types.dart';

/// Digital wallet payment section: bank transfer or wallet app selection.
class PaymentWalletSection extends StatelessWidget {
  final WalletMode walletMode;
  final String bankAccountType;
  final String walletProvider;
  final String? bankRoutingError;
  final String? bankAccountError;
  final ValueChanged<WalletMode> onWalletModeChanged;
  final ValueChanged<String> onBankAccountTypeChanged;
  final ValueChanged<String> onBankRoutingChanged;
  final ValueChanged<String> onBankAccountChanged;
  final ValueChanged<String> onWalletProviderChanged;

  const PaymentWalletSection({
    super.key,
    required this.walletMode,
    required this.bankAccountType,
    required this.walletProvider,
    this.bankRoutingError,
    this.bankAccountError,
    required this.onWalletModeChanged,
    required this.onBankAccountTypeChanged,
    required this.onBankRoutingChanged,
    required this.onBankAccountChanged,
    required this.onWalletProviderChanged,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Container(
      width: double.infinity,
      padding: responsive.padding(all: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(responsive.borderRadius(12.0)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: responsive.spacing(10.0),
            offset: Offset(0, responsive.spacing(2.0)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => onWalletModeChanged(WalletMode.bank),
                child: Row(
                  children: [
                    Container(
                      width: responsive.spacing(20.0),
                      height: responsive.spacing(20.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: walletMode == WalletMode.bank
                              ? AppColors.primary
                              : AppColors.border,
                          width: 1.5,
                        ),
                        color: Colors.transparent,
                      ),
                      child: walletMode == WalletMode.bank
                          ? Center(
                              child: Container(
                                width: responsive.spacing(8.0),
                                height: responsive.spacing(8.0),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          : null,
                    ),
                    responsive.widthBox(8.0),
                    Text(
                      'Pay by Bank',
                      style: TextStyle(
                        fontSize: responsive.fontSize(14.0),
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              responsive.widthBox(24.0),
              GestureDetector(
                onTap: () => onWalletModeChanged(WalletMode.app),
                child: Row(
                  children: [
                    Container(
                      width: responsive.spacing(20.0),
                      height: responsive.spacing(20.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: walletMode == WalletMode.app
                              ? AppColors.primary
                              : AppColors.border,
                          width: 1.5,
                        ),
                        color: Colors.transparent,
                      ),
                      child: walletMode == WalletMode.app
                          ? Center(
                              child: Container(
                                width: responsive.spacing(8.0),
                                height: responsive.spacing(8.0),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          : null,
                    ),
                    responsive.widthBox(8.0),
                    Text(
                      'Select Wallet App',
                      style: TextStyle(
                        fontSize: responsive.fontSize(14.0),
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          responsive.heightBox(16.0),
          if (walletMode == WalletMode.bank) ...[
            // Account Type Toggle
            Row(
              children: [
                _buildAccountTypeChip(responsive, 'Checking', 'checking'),
                responsive.widthBox(12.0),
                _buildAccountTypeChip(responsive, 'Savings', 'savings'),
              ],
            ),
            responsive.heightBox(12.0),
            // Routing Number Field
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(
                  responsive.borderRadius(8.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowMedium,
                    blurRadius: responsive.spacing(8.0),
                    offset: Offset(0, responsive.spacing(2.0)),
                  ),
                ],
              ),
              child: TextField(
                onChanged: onBankRoutingChanged,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
                decoration: InputDecoration(
                  labelText: 'Routing Number',
                  hintText: '9-digit ABA routing number',
                  errorText: bankRoutingError,
                  prefixIcon: Icon(
                    Icons.account_balance,
                    color: AppColors.textSecondary,
                    size: responsive.iconSize(20.0),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      responsive.borderRadius(8.0),
                    ),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      responsive.borderRadius(8.0),
                    ),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      responsive.borderRadius(8.0),
                    ),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: responsive.padding(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            responsive.heightBox(12.0),
            // Account Number Field
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(
                  responsive.borderRadius(8.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowMedium,
                    blurRadius: responsive.spacing(8.0),
                    offset: Offset(0, responsive.spacing(2.0)),
                  ),
                ],
              ),
              child: TextField(
                onChanged: onBankAccountChanged,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(17),
                ],
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Account Number',
                  hintText: 'Enter your account number',
                  errorText: bankAccountError,
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: AppColors.textSecondary,
                    size: responsive.iconSize(20.0),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      responsive.borderRadius(8.0),
                    ),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      responsive.borderRadius(8.0),
                    ),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      responsive.borderRadius(8.0),
                    ),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: responsive.padding(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            responsive.heightBox(8.0),
            // Bank info notice
            Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: responsive.iconSize(14.0),
                  color: AppColors.success,
                ),
                responsive.widthBox(6.0),
                Expanded(
                  child: Text(
                    'Your bank details are encrypted and securely processed via ACH.',
                    style: TextStyle(
                      fontSize: responsive.fontSize(11.0),
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Column(
              children: [
                _buildWalletAppButton(responsive, 'Apple Pay', 'applePay'),
                responsive.heightBox(12.0),
                _buildWalletAppButton(responsive, 'Google Pay', 'googlePay'),
                responsive.heightBox(12.0),
                _buildWalletAppButton(responsive, 'PayPal', 'paypal'),
                responsive.heightBox(12.0),
                _buildWalletAppButton(responsive, 'Venmo', 'venmo'),
                responsive.heightBox(12.0),
                _buildWalletAppButton(responsive, 'Cash App', 'cashApp'),
                responsive.heightBox(12.0),
                _buildWalletAppButton(responsive, 'Zelle', 'zelle'),
              ],
            ),
          ],
          responsive.heightBox(12.0),
          Container(
            padding: responsive.padding(all: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(responsive.borderRadius(8.0)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowMedium,
                  blurRadius: responsive.spacing(8.0),
                  offset: Offset(0, responsive.spacing(2.0)),
                ),
              ],
            ),
            child: Text(
              'You will be redirected to your wallet app to complete payment. After approval, you will return here and your order will be placed.',
              style: TextStyle(
                fontSize: responsive.fontSize(11.0),
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletAppButton(
    ResponsiveUtils responsive,
    String label,
    String value,
  ) {
    final isSelected = walletProvider == value;
    final iconData = _getWalletAppIcon(value);

    return GestureDetector(
      onTap: () => onWalletProviderChanged(value),
      child: Container(
        padding: responsive.padding(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceVariant : AppColors.white,
          borderRadius: BorderRadius.circular(responsive.borderRadius(10.0)),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowMedium,
              blurRadius: responsive.spacing(8.0),
              offset: Offset(0, responsive.spacing(2.0)),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: responsive.spacing(20.0),
              height: responsive.spacing(20.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 1.5,
                ),
                color: Colors.transparent,
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: responsive.spacing(8.0),
                        height: responsive.spacing(8.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            responsive.widthBox(12.0),
            CircleAvatar(
              radius: responsive.spacing(16.0),
              backgroundColor: isSelected
                  ? AppColors.white
                  : AppColors.surfaceLight,
              child: Icon(
                iconData,
                size: responsive.iconSize(16.0),
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            responsive.widthBox(12.0),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: responsive.fontSize(14.0),
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                size: responsive.iconSize(18.0),
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }

  IconData _getWalletAppIcon(String value) {
    switch (value) {
      case 'applePay':
        return Icons.apple;
      case 'googlePay':
        return Icons.g_mobiledata;
      case 'paypal':
        return Icons.payments;
      case 'venmo':
        return Icons.account_balance_wallet;
      case 'cashApp':
        return Icons.attach_money;
      case 'zelle':
        return Icons.swap_horiz;
      default:
        return Icons.account_balance_wallet;
    }
  }

  Widget _buildAccountTypeChip(
    ResponsiveUtils responsive,
    String label,
    String value,
  ) {
    final isSelected = bankAccountType == value;
    return GestureDetector(
      onTap: () => onBankAccountTypeChanged(value),
      child: Container(
        padding: responsive.padding(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(responsive.borderRadius(20.0)),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: responsive.fontSize(13.0),
            fontWeight: FontWeight.w500,
            color: isSelected ? AppColors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
