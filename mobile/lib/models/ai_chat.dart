/// One dish within a suggested restaurant set, as returned by AI_Id's
/// `/api/chat` endpoint.
class AiDish {
  const AiDish({
    required this.name,
    required this.price,
    required this.quantity,
    required this.unitPrice,
  });

  factory AiDish.fromJson(Map<String, dynamic> json) {
    return AiDish(
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: (json['quantity'] as num).toInt(),
      unitPrice: (json['unit_price'] as num).toDouble(),
    );
  }

  final String name;
  final double price;
  final int quantity;
  final double unitPrice;
}

/// A full restaurant suggestion (restaurant + dish combo that fits the
/// requested budget) within an AI_Id chat reply.
class AiRestaurantSet {
  const AiRestaurantSet({
    required this.restaurant,
    required this.location,
    required this.rating,
    required this.dishes,
    required this.total,
    required this.peopleCount,
  });

  factory AiRestaurantSet.fromJson(Map<String, dynamic> json) {
    return AiRestaurantSet(
      restaurant: json['restaurant'] as String,
      location: json['location'] as String,
      rating: (json['rating'] as num).toDouble(),
      dishes: (json['dishes'] as List<dynamic>)
          .map((e) => AiDish.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toDouble(),
      peopleCount: (json['people_count'] as num).toInt(),
    );
  }

  final String restaurant;
  final String location;
  final double rating;
  final List<AiDish> dishes;
  final double total;
  final int peopleCount;
}

/// The full response from a single `/api/chat` turn: the assistant's text
/// reply plus zero or more matching restaurant sets.
class AiChatResult {
  const AiChatResult({required this.reply, required this.sets});

  factory AiChatResult.fromJson(Map<String, dynamic> json) {
    return AiChatResult(
      reply: json['reply'] as String? ?? '',
      sets: (json['sets'] as List<dynamic>? ?? const [])
          .map((e) => AiRestaurantSet.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String reply;
  final List<AiRestaurantSet> sets;
}
