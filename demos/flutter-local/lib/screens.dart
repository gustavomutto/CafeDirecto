import 'package:flutter/material.dart';

import 'app_state.dart';
import 'coffee_data.dart';
import 'main.dart' show coffeeBrown, coffeeGreen;
import 'models.dart';

class FarmerHomeScreen extends StatelessWidget {
  const FarmerHomeScreen({required this.state, super.key});
  final CafeState state;

  @override
  Widget build(BuildContext context) {
    final farm = coffeeFarms.first;
    final myLots = state.lots.where((lot) => lot.farmId == farm.id).toList();
    return _Page(
      title: 'Hola, Luz Marina 👋',
      subtitle: '${farm.name} · ${farm.region}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RatingBanner(
            rating: farm.rating,
            location: '${farm.town}, ${farm.region}',
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  icon: Icons.add_circle_outline,
                  title: 'Publicar lote',
                  color: coffeeBrown,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PublishLotScreen(state: state),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionTile(
                  icon: Icons.chat_bubble_outline,
                  title: 'Mensajes',
                  badge: '${state.unreadCount}',
                  color: coffeeGreen,
                  onTap: () => state.selectTab(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  icon: Icons.handshake_outlined,
                  title: 'Mis acuerdos',
                  color: const Color(0xFFBC702E),
                  onTap: () => state.selectTab(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionTile(
                  icon: Icons.menu_book_outlined,
                  title: 'Aprende',
                  color: const Color(0xFF56728B),
                  onTap: () => state.selectTab(3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          _SectionHeader(
            title: 'Mis lotes publicados',
            trailing: '${myLots.length} lotes',
          ),
          const SizedBox(height: 12),
          ...myLots.map(
            (lot) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CoffeeLotCard(
                lot: lot,
                farm: farm,
                onTap: () => _openLot(context, state, lot),
              ),
            ),
          ),
          const SizedBox(height: 85),
        ],
      ),
    );
  }
}

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({required this.state, super.key});
  final CafeState state;

  @override
  Widget build(BuildContext context) {
    final query = state.search.toLowerCase().trim();
    final visibleLots = state.lots.where((lot) {
      final farm = _farmFor(lot);
      final matchesRegion =
          state.regionFilter == 'Todas' || farm.region == state.regionFilter;
      final matchesText =
          query.isEmpty ||
          '${lot.name} ${lot.variety} ${farm.name} ${farm.region} ${lot.notes.join(' ')}'
              .toLowerCase()
              .contains(query);
      return matchesRegion && matchesText && lot.sacks > 0;
    }).toList();
    return _Page(
      title: "Good morning, Lena ☀️",
      subtitle: 'Discover Colombian specialty origins',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            onChanged: state.setSearch,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search farm, variety, flavor…',
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children:
                  ['Todas', 'Huila', 'Nariño', 'Cauca', 'Quindío', 'Magdalena']
                      .map(
                        (region) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              region == 'Todas' ? 'All regions' : region,
                            ),
                            selected: state.regionFilter == region,
                            onSelected: (_) => state.setRegion(region),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
          const SizedBox(height: 14),
          _SectionHeader(
            title: '${visibleLots.length} lots',
            trailing: 'direct from farm',
          ),
          const SizedBox(height: 12),
          if (visibleLots.isEmpty)
            const _EmptyCard(
              icon: Icons.search,
              text: 'No lots match these filters',
            )
          else
            ...visibleLots.map(
              (lot) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CoffeeLotCard(
                  lot: lot,
                  farm: _farmFor(lot),
                  onTap: () => _openLot(context, state, lot),
                ),
              ),
            ),
          const SizedBox(height: 85),
        ],
      ),
    );
  }
}

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({required this.state, super.key});
  final CafeState state;

  @override
  Widget build(BuildContext context) {
    final chats = sampleConversations.where((chat) {
      final isOwnChat = state.isFarmer
          ? chat.farmId == 'f1'
          : chat.buyer.contains('Lena');
      return isOwnChat || chat.id == 'c1';
    }).toList();
    return _Page(
      title: state.isFarmer ? 'Mensajes' : 'Messages',
      subtitle: state.isFarmer
          ? 'Conversa directamente con compradores'
          : 'Your coffee conversations',
      child: Column(
        children: chats
            .map(
              (chat) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(14),
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor: const Color(0xFFEFE3D1),
                      child: Text(
                        chat.buyer.characters.first,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      chat.buyer,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        '${chat.company}\n${state.messages[chat.id]?.lastOrNull?.text ?? chat.preview}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    trailing: chat.unread > 0
                        ? CircleAvatar(
                            radius: 12,
                            backgroundColor: coffeeGreen,
                            child: Text(
                              '${chat.unread}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          )
                        : const Icon(Icons.chevron_right),
                    isThreeLine: true,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            ChatRoomScreen(state: state, conversation: chat),
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({required this.state, super.key});
  final CafeState state;

  @override
  Widget build(BuildContext context) => _Page(
    title: state.isFarmer ? 'Mis acuerdos' : 'Orders',
    subtitle: 'Acuerdos transparentes entre productor y comprador',
    child: Column(
      children: [
        ...state.agreements.map((agreement) {
          final lot = _lotFor(agreement.lotId);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        AgreementDetailScreen(agreement: agreement, lot: lot),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.handshake_outlined,
                            color: coffeeGreen,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              agreement.code,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          _StatusPill(label: agreement.status),
                        ],
                      ),
                      const Divider(height: 25),
                      Text(
                        lot.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('${agreement.buyer} · ${agreement.sacks} sacos'),
                      const SizedBox(height: 12),
                      Text(
                        '\$${agreement.price.toStringAsFixed(2)}/lb  ·  Total aprox. \$${(agreement.price * agreement.sacks * 154.32).toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'FOB Buenaventura',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    ),
  );
}

class LearnScreen extends StatelessWidget {
  const LearnScreen({required this.state, super.key});
  final CafeState state;

  @override
  Widget build(BuildContext context) => _Page(
    title: state.isFarmer ? 'Aprende' : 'Learn',
    subtitle: 'Herramientas para comerciar café con confianza',
    child: Column(
      children: [
        ...learnItems.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                leading: Text(item.icon, style: const TextStyle(fontSize: 30)),
                title: Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(item.subtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => LearnDetailScreen(
                      title: item.title,
                      subtitle: item.subtitle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const _InfoPanel(
          icon: Icons.lightbulb_outline,
          title: 'Consejo de hoy',
          message:
              'Una ficha completa y fotos claras ayudan a que más compradores encuentren tu café.',
        ),
      ],
    ),
  );
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({required this.state, super.key});
  final CafeState state;

  @override
  Widget build(BuildContext context) {
    final farm = coffeeFarms.first;
    return _Page(
      title: state.isFarmer ? 'Mi finca' : 'My profile',
      subtitle: state.isFarmer
          ? 'Tu perfil público de productor'
          : 'Buyer account',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: Color(0xFFEFE3D1),
                    child: Text('☕', style: TextStyle(fontSize: 30)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.isFarmer ? farm.producer : 'Lena Fischer',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          state.isFarmer
                              ? '${farm.name} · ${farm.region}'
                              : 'Nordlicht Kaffeerösterei · Berlin',
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          '⭐ 4.8 · Perfil verificado',
                          style: TextStyle(color: coffeeGreen),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            state.isFarmer
                ? farm.description
                : 'Independent specialty coffee roaster in Berlin.',
          ),
          const SizedBox(height: 22),
          const Text(
            'Panel de demostración',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.wifi_off),
              title: const Text('Simular sin conexión'),
              subtitle: const Text(
                'La app sigue funcionando en el dispositivo',
              ),
              value: state.offline,
              onChanged: (_) => state.toggleOffline(),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: Text(
                state.isFarmer ? 'Ver como comprador' : 'Ver como caficultor',
              ),
              subtitle: const Text('Cambiar el rol de demostración'),
              onTap: () => state.switchRole(!state.isFarmer),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.restart_alt, color: Colors.redAccent),
              title: const Text(
                'Reiniciar demo',
                style: TextStyle(color: Colors.redAccent),
              ),
              subtitle: const Text('Borra cambios locales y vuelve al inicio'),
              onTap: () async {
                final reset = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('¿Reiniciar la demo?'),
                    content: const Text(
                      'Se borrarán tus cambios guardados en este dispositivo.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Reiniciar'),
                      ),
                    ],
                  ),
                );
                if (reset == true) await state.resetDemo();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class PublishLotScreen extends StatefulWidget {
  const PublishLotScreen({required this.state, super.key});
  final CafeState state;

  @override
  State<PublishLotScreen> createState() => _PublishLotScreenState();
}

class _PublishLotScreenState extends State<PublishLotScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _sacks = TextEditingController(text: '20');
  final _price = TextEditingController(text: '5.50');
  String _variety = 'Caturra';
  String _process = 'Lavado';
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _sacks.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await widget.state.addLot(
      name: _name.text.trim(),
      variety: _variety,
      process: _process,
      sacks: int.parse(_sacks.text),
      price: double.parse(_price.text.replaceAll(',', '.')),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('¡Tu lote ya está publicado!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Publicar lote')),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: [
          const Text(
            'Cuéntale al mundo sobre tu café.',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'La información clara ayuda a encontrar el comprador adecuado.',
          ),
          const SizedBox(height: 24),
          _FieldLabel(label: 'Nombre del lote'),
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(hintText: 'Ej. Lote Primavera'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Escribe un nombre para el lote'
                : null,
          ),
          const SizedBox(height: 16),
          _FieldLabel(label: 'Variedad'),
          DropdownButtonFormField<String>(
            initialValue: _variety,
            items: ['Caturra', 'Pink Bourbon', 'Castillo', 'Geisha', 'Colombia']
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (value) => setState(() => _variety = value!),
          ),
          const SizedBox(height: 16),
          _FieldLabel(label: 'Proceso'),
          DropdownButtonFormField<String>(
            initialValue: _process,
            items: ['Lavado', 'Honey', 'Natural']
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (value) => setState(() => _process = value!),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel(label: 'Sacos (70 kg)'),
                    TextFormField(
                      controller: _sacks,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: '20'),
                      validator: (value) =>
                          int.tryParse(value ?? '') == null ||
                              int.parse(value!) < 1
                          ? 'Ingresa una cantidad válida'
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel(label: 'Precio (USD/lb)'),
                    TextFormField(
                      controller: _price,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(prefixText: '\$ '),
                      validator: (value) =>
                          double.tryParse((value ?? '').replaceAll(',', '.')) ==
                              null
                          ? 'Ingresa un precio válido'
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          FilledButton.icon(
            onPressed: _saving ? null : _publish,
            icon: const Icon(Icons.publish),
            label: Text(_saving ? 'Publicando…' : 'Publicar lote'),
          ),
        ],
      ),
    ),
  );
}

class LotDetailScreen extends StatelessWidget {
  const LotDetailScreen({required this.state, required this.lot, super.key});
  final CafeState state;
  final CoffeeLot lot;

  @override
  Widget build(BuildContext context) {
    final farm = _farmFor(lot);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                lot.name,
                style: const TextStyle(
                  shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                ),
              ),
              background: const _CoffeeArtwork(height: 260, expanded: true),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFC8782A)),
                      const SizedBox(width: 4),
                      Text(
                        '${lot.score} SCA',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      Text(
                        '\$${lot.price.toStringAsFixed(2)} / lb',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const _FieldLabel(label: 'PERFIL DEL CAFÉ'),
                  Text('${lot.variety} · ${lot.process} · ${lot.sacks} sacos'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: lot.notes
                        .map((note) => Chip(label: Text(note)))
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  const _FieldLabel(label: 'FINCA DE ORIGEN'),
                  Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFEFE3D1),
                        child: Icon(Icons.landscape, color: coffeeBrown),
                      ),
                      title: Text(
                        farm.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        '${farm.producer} · ${farm.town}, ${farm.region}\n${farm.altitude} m · ★ ${farm.rating}',
                      ),
                      isThreeLine: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(farm.description),
                  const SizedBox(height: 22),
                  const _InfoPanel(
                    icon: Icons.verified_outlined,
                    title: 'Origen trazable',
                    message: 'Conoce quién cultivó tu café y dónde creció.',
                  ),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: () {
                      final chat = sampleConversations.firstWhere(
                        (item) => item.lotId == lot.id,
                        orElse: () => sampleConversations.first,
                      );
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              ChatRoomScreen(state: state, conversation: chat),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: Text(
                      state.isFarmer
                          ? 'Ver conversación'
                          : 'Message the farmer',
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

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({
    required this.state,
    required this.conversation,
    super.key,
  });
  final CafeState state;
  final DemoConversation conversation;

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _message = TextEditingController();

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _message.text.trim();
    if (text.isEmpty) return;
    _message.clear();
    await widget.state.sendMessage(widget.conversation.id, text);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.conversation.buyer, style: const TextStyle(fontSize: 16)),
          Text(
            widget.conversation.company,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
          ),
        ],
      ),
    ),
    body: Column(
      children: [
        const _InfoPanel(
          icon: Icons.translate,
          title: 'Traducción automática',
          message: 'Puedes comunicarte en tu idioma.',
        ),
        Expanded(
          child: AnimatedBuilder(
            animation: widget.state,
            builder: (context, _) {
              final messages =
                  widget.state.messages[widget.conversation.id] ?? [];
              if (messages.isEmpty) {
                return const Center(
                  child: Text('Inicia la conversación con un mensaje.'),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final mine =
                      message.author ==
                      (widget.state.isFarmer ? 'farmer' : 'buyer');
                  return Align(
                    alignment: mine
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 310),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: mine ? coffeeBrown : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.text,
                            style: TextStyle(
                              color: mine
                                  ? Colors.white
                                  : const Color(0xFF2B1D14),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${mine ? 'Tú' : widget.conversation.buyer} · ${TimeOfDay.fromDateTime(message.time).format(context)}',
                            style: TextStyle(
                              color: mine ? Colors.white70 : Colors.black45,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _message,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      hintText: 'Escribe un mensaje…',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _send,
                  style: IconButton.styleFrom(
                    backgroundColor: coffeeBrown,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class AgreementDetailScreen extends StatelessWidget {
  const AgreementDetailScreen({
    required this.agreement,
    required this.lot,
    super.key,
  });
  final CoffeeAgreement agreement;
  final CoffeeLot lot;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detalle del acuerdo')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _InfoPanel(
          icon: Icons.verified,
          title: 'Acuerdo registrado',
          message:
              'Las condiciones de este intercambio están visibles para ambas partes.',
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agreement.code,
                  style: const TextStyle(
                    color: coffeeGreen,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  lot.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Divider(height: 28),
                _DataRow(label: 'Comprador', value: agreement.buyer),
                _DataRow(label: 'Cantidad', value: '${agreement.sacks} sacos'),
                _DataRow(
                  label: 'Precio',
                  value: '\$${agreement.price.toStringAsFixed(2)} / lb',
                ),
                _DataRow(label: 'Entrega', value: 'FOB Buenaventura'),
                _DataRow(label: 'Estado', value: agreement.status),
                _DataRow(
                  label: 'Total estimado',
                  value:
                      '\$${(agreement.price * agreement.sacks * 154.32).toStringAsFixed(0)} USD',
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class LearnDetailScreen extends StatelessWidget {
  const LearnDetailScreen({
    required this.title,
    required this.subtitle,
    super.key,
  });
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          subtitle,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 18),
        const _InfoPanel(
          icon: Icons.lightbulb_outline,
          title: 'Relaciones directas',
          message:
              'Un perfil completo, muestras representativas y comunicación clara ayudan a crear relaciones duraderas.',
        ),
        const SizedBox(height: 18),
        const _InfoPanel(
          icon: Icons.check_circle_outline,
          title: 'Acuerdos claros',
          message:
              'Antes de cerrar, confirma el lote, la cantidad, el precio por libra y el término de entrega.',
        ),
        const SizedBox(height: 18),
        const _InfoPanel(
          icon: Icons.handshake_outlined,
          title: 'Reputación mutua',
          message:
              'Después de la entrega, ambas partes pueden calificar la calidad, comunicación y cumplimiento.',
        ),
      ],
    ),
  );
}

class CoffeeLotCard extends StatelessWidget {
  const CoffeeLotCard({
    required this.lot,
    required this.farm,
    required this.onTap,
    super.key,
  });
  final CoffeeLot lot;
  final CoffeeFarm farm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CoffeeArtwork(height: 125),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        lot.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '\$${lot.price.toStringAsFixed(2)}/lb',
                      style: const TextStyle(
                        color: coffeeBrown,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${farm.name} · ${farm.region}',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 11),
                Wrap(
                  spacing: 7,
                  runSpacing: 5,
                  children: [
                    _Tag(text: lot.variety),
                    _Tag(text: lot.process),
                    _Tag(text: '${lot.score} SCA'),
                    _Tag(text: '${lot.sacks} sacos'),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  lot.notes.join(' · '),
                  style: const TextStyle(color: coffeeGreen),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _Page extends StatelessWidget {
  const _Page({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        sliver: SliverToBoxAdapter(child: child),
      ),
    ],
  );
}

class _CoffeeArtwork extends StatelessWidget {
  const _CoffeeArtwork({required this.height, this.expanded = false});
  final double height;
  final bool expanded;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    width: double.infinity,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [Color(0xFF315740), Color(0xFF78925C), Color(0xFFC69A5B)],
      ),
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          right: -10,
          top: -48,
          child: Icon(
            Icons.wb_sunny_rounded,
            size: expanded ? 175 : 105,
            color: Colors.white.withValues(alpha: .22),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Icon(
            Icons.landscape_rounded,
            size: expanded ? 185 : 135,
            color: const Color(0xFF254532),
          ),
        ),
        const Positioned(
          left: 18,
          bottom: 15,
          child: Icon(Icons.coffee_rounded, size: 39, color: Colors.white70),
        ),
      ],
    ),
  );
}

class _RatingBanner extends StatelessWidget {
  const _RatingBanner({required this.rating, required this.location});
  final double rating;
  final String location;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: const Color(0xFFE9F0E7),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        const CircleAvatar(
          radius: 25,
          backgroundColor: Colors.white,
          child: Text('🌱', style: TextStyle(fontSize: 25)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(location)),
        const Icon(Icons.star_rounded, color: Color(0xFFC8782A)),
        Text(' $rating', style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    this.badge,
  });
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: .12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (badge != null)
              CircleAvatar(
                radius: 11,
                backgroundColor: coffeeGreen,
                child: Text(
                  badge!,
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.trailing});
  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      Text(trailing, style: const TextStyle(color: Colors.black54)),
    ],
  );
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFF2EEE7),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFE9F0E7),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        color: coffeeGreen,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFE9F0E7),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: coffeeGreen),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(message),
            ],
          ),
        ),
      ],
    ),
  );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(30),
    child: Column(
      children: [Icon(icon, size: 38), const SizedBox(height: 8), Text(text)],
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
  );
}

class _DataRow extends StatelessWidget {
  const _DataRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: const TextStyle(color: Colors.black54)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

CoffeeFarm _farmFor(CoffeeLot lot) => coffeeFarms.firstWhere(
  (farm) => farm.id == lot.farmId,
  orElse: () => coffeeFarms.first,
);

CoffeeLot _lotFor(String id) => sampleLots.firstWhere(
  (lot) => lot.id == id,
  orElse: () => sampleLots.first,
);

void _openLot(BuildContext context, CafeState state, CoffeeLot lot) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => LotDetailScreen(state: state, lot: lot),
    ),
  );
}
