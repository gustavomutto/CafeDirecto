class CoffeeFarm {
  const CoffeeFarm({
    required this.id,
    required this.name,
    required this.producer,
    required this.region,
    required this.town,
    required this.altitude,
    required this.rating,
    required this.description,
  });

  final String id;
  final String name;
  final String producer;
  final String region;
  final String town;
  final int altitude;
  final double rating;
  final String description;
}

class CoffeeLot {
  const CoffeeLot({
    required this.id,
    required this.farmId,
    required this.name,
    required this.variety,
    required this.process,
    required this.sacks,
    required this.score,
    required this.price,
    required this.notes,
  });

  final String id;
  final String farmId;
  final String name;
  final String variety;
  final String process;
  final int sacks;
  final double score;
  final double price;
  final List<String> notes;

  Map<String, Object> toJson() => {
    'id': id,
    'farmId': farmId,
    'name': name,
    'variety': variety,
    'process': process,
    'sacks': sacks,
    'score': score,
    'price': price,
    'notes': notes,
  };

  factory CoffeeLot.fromJson(Map<String, dynamic> json) => CoffeeLot(
    id: json['id'] as String,
    farmId: json['farmId'] as String,
    name: json['name'] as String,
    variety: json['variety'] as String,
    process: json['process'] as String,
    sacks: json['sacks'] as int,
    score: (json['score'] as num).toDouble(),
    price: (json['price'] as num).toDouble(),
    notes: List<String>.from(json['notes'] as List),
  );
}

class DemoConversation {
  const DemoConversation({
    required this.id,
    required this.farmId,
    required this.buyer,
    required this.company,
    required this.preview,
    required this.unread,
    required this.lotId,
  });

  final String id;
  final String farmId;
  final String buyer;
  final String company;
  final String preview;
  final int unread;
  final String lotId;
}

class ChatMessage {
  const ChatMessage({
    required this.author,
    required this.text,
    required this.time,
  });

  final String author;
  final String text;
  final DateTime time;

  Map<String, Object> toJson() => {
    'author': author,
    'text': text,
    'time': time.toIso8601String(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    author: json['author'] as String,
    text: json['text'] as String,
    time: DateTime.parse(json['time'] as String),
  );
}

class CoffeeAgreement {
  const CoffeeAgreement({
    required this.code,
    required this.lotId,
    required this.buyer,
    required this.sacks,
    required this.price,
    required this.status,
  });

  final String code;
  final String lotId;
  final String buyer;
  final int sacks;
  final double price;
  final String status;
}
