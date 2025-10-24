import 'book.dart';

class CartItem {
  final String id;
  final String userId;
  final int bookId;
  final int quantity;
  final Map<String, dynamic> personalizationData;
  final DateTime createdAt;
  final Book? book; // Populated via join

  CartItem({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.quantity,
    required this.personalizationData,
    required this.createdAt,
    this.book,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      userId: json['user_id'],
      bookId: json['book_id'] is int ? json['book_id'] : int.parse(json['book_id'].toString()),
      quantity: json['quantity'] ?? 1,
      personalizationData: json['personalization_data'] ?? {},
      createdAt: DateTime.parse(json['created_at']),
      book: json['book'] != null ? Book.fromJson(json['book']) : null,
    );
  }
}

class Order {
  final String id;
  final String userId;
  final String status;
  final double totalAmount;
  final String currency;
  final Map<String, dynamic> shippingAddress;
  final DateTime createdAt;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.userId,
    required this.status,
    required this.totalAmount,
    required this.currency,
    required this.shippingAddress,
    required this.createdAt,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      userId: json['user_id'],
      status: json['status'],
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'USD',
      shippingAddress: json['shipping_address'] ?? {},
      createdAt: DateTime.parse(json['created_at']),
      items: json['order_items'] != null
          ? (json['order_items'] as List)
              .map((item) => OrderItem.fromJson(item))
              .toList()
          : [],
    );
  }
}

class OrderItem {
  final String id;
  final String orderId;
  final int bookId;
  final int quantity;
  final double unitPrice;
  final Map<String, dynamic> personalizationData;
  final DateTime createdAt;
  final Book? book;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.bookId,
    required this.quantity,
    required this.unitPrice,
    required this.personalizationData,
    required this.createdAt,
    this.book,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      orderId: json['order_id'],
      bookId: json['book_id'] is int ? json['book_id'] : int.parse(json['book_id'].toString()),
      quantity: json['quantity'] ?? 1,
      unitPrice: (json['unit_price'] ?? 0.0).toDouble(),
      personalizationData: json['personalization_data'] ?? {},
      createdAt: DateTime.parse(json['created_at']),
      book: json['book'] != null ? Book.fromJson(json['book']) : null,
    );
  }

  double get totalPrice => unitPrice * quantity;
}
