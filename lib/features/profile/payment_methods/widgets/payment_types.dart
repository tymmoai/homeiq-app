/// Payment type selection options.
enum PaymentType { card, wallet, installment }

/// Digital wallet sub-mode: pay by bank or via wallet app.
enum WalletMode { bank, app }

/// Line item for order summary (label, amount, optional discount styling).
class OrderSummaryItem {
  final String label;
  final double amount;
  final bool isDiscount;

  const OrderSummaryItem({
    required this.label,
    required this.amount,
    this.isDiscount = false,
  });
}
