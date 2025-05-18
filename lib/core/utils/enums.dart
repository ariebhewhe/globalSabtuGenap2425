// * Role Enum
enum Role { admin, user }

extension RoleExtension on Role {
  String toMap() {
    return this.toString().split('.').last;
  }

  static Role fromMap(String role) {
    return Role.values.firstWhere((e) => e.toString().split('.').last == role);
  }
}

// * Location Enum
enum Location { indoor, outdorr, vip }

extension LocationExtension on Location {
  String toMap() {
    return this.toString().split('.').last;
  }

  static Location fromMap(String location) {
    return Location.values.firstWhere(
      (e) => e.toString().split('.').last == location,
    );
  }
}

// * Order Type Enum
enum OrderType { dineIn, takeAway }

extension OrderTypeExtension on OrderType {
  String toMap() {
    return toString().split('.').last;
  }

  static OrderType fromMap(String orderType) {
    return OrderType.values.firstWhere(
      (e) => e.toString().split('.').last == orderType,
      orElse: () => OrderType.takeAway, // * Default value if not found
    );
  }
}

// * Order Status Enum
enum OrderStatus { pending, confirmed, preparing, ready, completed, cancelled }

extension OrderStatusExtension on OrderStatus {
  String toMap() {
    return toString().split('.').last;
  }

  static OrderStatus fromMap(String orderStatus) {
    return OrderStatus.values.firstWhere(
      (e) => e.toString().split('.').last == orderStatus,
      orElse: () => OrderStatus.pending, // * Default value if not found
    );
  }
}

// * Payment Method Enum
enum PaymentMethodType { cash, creditCard, debitCard, eWallet }

extension PaymentMethodTypeExtension on PaymentMethodType {
  String toMap() {
    return toString().split('.').last;
  }

  static PaymentMethodType fromMap(String paymentMethod) {
    return PaymentMethodType.values.firstWhere(
      (e) => e.toString().split('.').last == paymentMethod,
      orElse: () => PaymentMethodType.cash, // * Default value if not found
    );
  }
}

// * Payment Status Enum
enum PaymentStatus { unpaid, paid }

extension PaymentStatusExtension on PaymentStatus {
  String toMap() {
    return toString().split('.').last;
  }

  static PaymentStatus fromMap(String paymentStatus) {
    return PaymentStatus.values.firstWhere(
      (e) => e.toString().split('.').last == paymentStatus,
      orElse: () => PaymentStatus.unpaid, // * Default value if not found
    );
  }
}

// * Reservation Status Enum
enum ReservationStatus { reserved, occupied, completed, cancelled }

extension ReservationStatusExtension on ReservationStatus {
  String toMap() {
    return toString().split('.').last;
  }

  static ReservationStatus fromMap(String reservationStatus) {
    return ReservationStatus.values.firstWhere(
      (e) => e.toString().split('.').last == reservationStatus,
      orElse: () => ReservationStatus.reserved, // * Default value if not found
    );
  }
}

// * Transaction Status Enum
enum TransactionStatus { pending, completed, failed, refunded }

extension TransactionStatusExtension on TransactionStatus {
  String toMap() {
    return toString().split('.').last;
  }

  static TransactionStatus fromMap(String transactionStatus) {
    return TransactionStatus.values.firstWhere(
      (e) => e.toString().split('.').last == transactionStatus,
      orElse: () => TransactionStatus.pending, // * Default value if not found
    );
  }
}
