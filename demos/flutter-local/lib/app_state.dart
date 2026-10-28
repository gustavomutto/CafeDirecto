import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'coffee_data.dart';
import 'models.dart';

class CafeState extends ChangeNotifier {
  CafeState() {
    lots = List.of(sampleLots);
  }

  static const _storageKey = 'cafedirecto-flutter-v1';

  bool ready = false;
  bool onboarded = false;
  bool offline = false;
  bool isFarmer = true;
  int tabIndex = 0;
  String regionFilter = 'Todas';
  String search = '';
  late List<CoffeeLot> lots;
  final List<CoffeeAgreement> agreements = List.of(sampleAgreements);
  final Map<String, List<ChatMessage>> messages = {
    'c1': [
      ChatMessage(
        author: 'buyer',
        text: 'Hi Luz Marina! Is the Pink Bourbon lot still available?',
        time: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      ChatMessage(
        author: 'farmer',
        text: '¡Hola! Sí, todavía tengo veintiocho sacos disponibles.',
        time: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      ChatMessage(
        author: 'buyer',
        text: 'We can commit to 20 bags if we meet at 5.45.',
        time: DateTime.now().subtract(const Duration(minutes: 40)),
      ),
    ],
    'c2': [
      ChatMessage(
        author: 'buyer',
        text: 'The coffee arrived perfectly. Arigato!',
        time: DateTime.now().subtract(const Duration(days: 9)),
      ),
    ],
    'c3': [
      ChatMessage(
        author: 'buyer',
        text: 'Hi! I love your coffee profile.',
        time: DateTime.now().subtract(const Duration(hours: 4)),
      ),
    ],
  };

  int get unreadCount => isFarmer ? 2 : 1;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      try {
        final saved = jsonDecode(raw) as Map<String, dynamic>;
        onboarded = saved['onboarded'] as bool? ?? false;
        isFarmer = saved['isFarmer'] as bool? ?? true;
        offline = saved['offline'] as bool? ?? false;
        tabIndex = saved['tabIndex'] as int? ?? 0;
        final savedLots = saved['lots'] as List<dynamic>?;
        if (savedLots != null) {
          lots = [
            ...savedLots.map(
              (lot) => CoffeeLot.fromJson(lot as Map<String, dynamic>),
            ),
            ...sampleLots,
          ];
        }
        final savedMessages = saved['messages'] as Map<String, dynamic>?;
        if (savedMessages != null) {
          for (final entry in savedMessages.entries) {
            messages[entry.key] = (entry.value as List<dynamic>)
                .map(
                  (message) =>
                      ChatMessage.fromJson(message as Map<String, dynamic>),
                )
                .toList();
          }
        }
      } on FormatException {
        await prefs.remove(_storageKey);
      } on TypeError {
        await prefs.remove(_storageKey);
      }
    }
    ready = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode({
        'onboarded': onboarded,
        'isFarmer': isFarmer,
        'offline': offline,
        'tabIndex': tabIndex,
        'lots': lots
            .where((lot) => !sampleLots.any((sample) => sample.id == lot.id))
            .map((lot) => lot.toJson())
            .toList(),
        'messages': messages.map(
          (key, value) =>
              MapEntry(key, value.map((message) => message.toJson()).toList()),
        ),
      }),
    );
  }

  Future<void> completeOnboarding(bool farmer) async {
    isFarmer = farmer;
    onboarded = true;
    tabIndex = 0;
    notifyListeners();
    await _save();
  }

  Future<void> switchRole(bool farmer) async {
    isFarmer = farmer;
    tabIndex = 0;
    notifyListeners();
    await _save();
  }

  Future<void> selectTab(int index) async {
    tabIndex = index;
    notifyListeners();
    await _save();
  }

  void setSearch(String value) {
    search = value;
    notifyListeners();
  }

  void setRegion(String value) {
    regionFilter = value;
    notifyListeners();
  }

  Future<void> addLot({
    required String name,
    required String variety,
    required String process,
    required int sacks,
    required double price,
  }) async {
    lots.insert(
      0,
      CoffeeLot(
        id: 'local-${DateTime.now().millisecondsSinceEpoch}',
        farmId: 'f1',
        name: name,
        variety: variety,
        process: process,
        sacks: sacks,
        score: 86,
        price: price,
        notes: const ['Cacao', 'Frutos dulces'],
      ),
    );
    notifyListeners();
    await _save();
  }

  Future<void> sendMessage(String conversationId, String text) async {
    messages.putIfAbsent(conversationId, () => []);
    messages[conversationId]!.add(
      ChatMessage(
        author: isFarmer ? 'farmer' : 'buyer',
        text: text,
        time: DateTime.now(),
      ),
    );
    notifyListeners();
    await _save();
  }

  Future<void> toggleOffline() async {
    offline = !offline;
    notifyListeners();
    await _save();
  }

  Future<void> resetDemo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    onboarded = false;
    isFarmer = true;
    offline = false;
    tabIndex = 0;
    regionFilter = 'Todas';
    search = '';
    lots = List.of(sampleLots);
    messages
      ..clear()
      ..addAll({
        'c1': [
          ChatMessage(
            author: 'buyer',
            text: 'Hi Luz Marina! Is the Pink Bourbon lot still available?',
            time: DateTime.now().subtract(const Duration(hours: 3)),
          ),
        ],
        'c2': [],
        'c3': [],
      });
    notifyListeners();
  }
}
