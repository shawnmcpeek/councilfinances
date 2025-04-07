enum PaymentMethod {
  cash('Cash'),
  check('Check'),
  debitCard('Debit Card'),
  square('Square');

  final String displayName;
  const PaymentMethod(this.displayName);

  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
      (method) => method.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PaymentMethod.cash,
    );
  }
} 