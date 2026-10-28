// Bienvenida, inicio de sesión y registro de usuarios reales (RF-01).
import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../state/app_scope.dart';
import '../theme/palette.dart';
import '../widgets/common.dart';

const _splashPhoto = 'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?auto=format&fit=crop&w=900&q=70';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const fp = farmerPalette;
    return PaletteOverride(
      palette: fp,
      child: Scaffold(
        backgroundColor: fp.primary,
        body: Stack(fit: StackFit.expand, children: [
          const NetImg(_splashPhoto),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x33000000), Color(0xCC1C1410), Color(0xF21C1410)],
                stops: [0, 0.55, 1],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: fp.warmSoft, borderRadius: BorderRadius.circular(20)),
                  child: const Text('☕', style: TextStyle(fontSize: 34)),
                ),
                const SizedBox(height: 18),
                Text('CaféDirecto', style: fp.display(size: 44, color: Colors.white)),
                const SizedBox(height: 10),
                Text('Del cafetal a la taza, sin intermediarios.', style: fp.text(size: 19, weight: FontWeight.w700, color: Colors.white)),
                Text('From farm to cup, direct.', style: fp.text(size: 16, color: Colors.white70)),
                const SizedBox(height: 28),
                Btn('Crear cuenta · Sign up',
                    kind: BtnKind.light, large: true, block: true, trailing: Icons.chevron_right_rounded,
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen()))),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen())),
                    child: Text('Ya tengo cuenta · Log in', style: fp.text(size: 16, weight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AppScope.of(context).login(_email.text.trim(), _pass.text);
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const p = farmerPalette;
    return PaletteOverride(
      palette: p,
      child: Scaffold(
        backgroundColor: p.bg,
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.arrow_back_rounded, color: p.ink)),
            ),
            Text('Iniciar sesión', style: p.display(size: 30)),
            Text('Log in', style: p.display(size: 20, color: p.ink2, weight: FontWeight.w500)),
            const SizedBox(height: 24),
            _Field(label: 'Correo · Email', icon: Icons.mail_outline_rounded, controller: _email, type: TextInputType.emailAddress),
            _Field(label: 'Contraseña · Password', icon: Icons.lock_outline_rounded, controller: _pass, obscure: true, onSubmit: (_) => _submit()),
            if (_error != null) _ErrorText(_error!),
            const SizedBox(height: 10),
            Btn('Entrar · Log in', large: true, block: true, onPressed: _busy ? null : _submit),
            if (_busy) const Padding(padding: EdgeInsets.only(top: 16), child: Center(child: CircularProgressIndicator())),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _busy
                    ? null
                    : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ForgotPasswordScreen(email: _email.text.trim()))),
                child: Text('¿Olvidaste tu contraseña? · Forgot password?', style: p.text(size: 15, weight: FontWeight.w800, color: p.accent)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Recuperar contraseña en dos pasos: 1) pedir el código por correo, 2) escribir el código y la clave nueva.
class ForgotPasswordScreen extends StatefulWidget {
  final String email;
  const ForgotPasswordScreen({super.key, this.email = ''});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final _email = TextEditingController(text: widget.email);
  final _code = TextEditingController();
  final _pass = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendCode() => _run(() async {
        final email = _email.text.trim();
        if (!email.contains('@')) throw 'Escribe tu correo · Enter your email';
        await AppScope.of(context).forgotPassword(email);
        if (mounted) setState(() => _codeSent = true);
      });

  Future<void> _reset() => _run(() async {
        if (_code.text.trim().length < 6) throw 'Escribe el código de 6 dígitos · Enter the 6-digit code';
        if (_pass.text.length < 6) throw 'La contraseña debe tener al menos 6 caracteres · At least 6 characters';
        final app = AppScope.of(context);
        await app.resetPassword(_email.text.trim(), _code.text.trim(), _pass.text);
        if (!mounted) return;
        Navigator.of(context).popUntil((r) => r.isFirst);
        app.showToast(app.tr('Contraseña actualizada', 'Password updated'));
      });

  @override
  Widget build(BuildContext context) {
    const p = farmerPalette;
    return PaletteOverride(
      palette: p,
      child: Scaffold(
        backgroundColor: p.bg,
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.arrow_back_rounded, color: p.ink)),
            ),
            Text('Recuperar contraseña', style: p.display(size: 30)),
            Text('Reset password', style: p.display(size: 20, color: p.ink2, weight: FontWeight.w500)),
            const SizedBox(height: 12),
            Text(
              _codeSent
                  ? 'Si el correo está registrado, te enviamos un código de 6 dígitos. Vence en 15 minutos.\n'
                      'If the email is registered, we sent you a 6-digit code. It expires in 15 minutes.'
                  : 'Te enviaremos un código a tu correo para crear una contraseña nueva.\n'
                      "We'll email you a code to set a new password.",
              style: p.muted(size: 15),
            ),
            const SizedBox(height: 20),
            _Field(label: 'Correo · Email', icon: Icons.mail_outline_rounded, controller: _email, type: TextInputType.emailAddress),
            if (_codeSent) ...[
              _Field(label: 'Código · Code', icon: Icons.pin_outlined, controller: _code, type: TextInputType.number),
              _Field(
                  label: 'Contraseña nueva · New password',
                  icon: Icons.lock_outline_rounded,
                  controller: _pass,
                  obscure: true,
                  onSubmit: (_) => _reset()),
            ],
            if (_error != null) _ErrorText(_error!),
            const SizedBox(height: 10),
            Btn(_codeSent ? 'Guardar · Save' : 'Enviar código · Send code',
                large: true, block: true, onPressed: _busy ? null : (_codeSent ? _reset : _sendCode)),
            if (_busy) const Padding(padding: EdgeInsets.only(top: 16), child: Center(child: CircularProgressIndicator())),
            if (_codeSent && !_busy)
              Center(
                child: TextButton(
                  onPressed: _sendCode,
                  child: Text('Enviar otro código · Resend code', style: p.text(size: 15, weight: FontWeight.w800, color: p.accent)),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String? role;
  String lang = 'es';
  final c = <String, TextEditingController>{
    for (final k in ['name', 'email', 'password', 'phone', 'farmName', 'municipality', 'company', 'city', 'country', 'type'])
      k: TextEditingController(),
  };
  String region = regions.first;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final x in c.values) {
      x.dispose();
    }
    super.dispose();
  }

  bool get es => lang == 'es';
  String t(String a, String b) => es ? a : b;

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final data = <String, dynamic>{
      'role': role,
      'lang': lang,
      'name': c['name']!.text.trim(),
      'email': c['email']!.text.trim(),
      'password': c['password']!.text,
      'phone': c['phone']!.text.trim(),
      if (role == 'farmer') ...{
        'farmName': c['farmName']!.text.trim(),
        'region': region,
        'municipality': c['municipality']!.text.trim(),
      } else ...{
        'company': c['company']!.text.trim(),
        'city': c['city']!.text.trim(),
        'country': c['country']!.text.trim(),
        'type': c['type']!.text.trim(),
      },
    };
    try {
      await AppScope.of(context).register(data);
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = paletteFor(role ?? 'farmer');
    return PaletteOverride(
      palette: p,
      child: Scaffold(
        backgroundColor: p.bg,
        body: SafeArea(child: role == null ? _rolePick(p) : _form(p)),
      ),
    );
  }

  Widget _rolePick(Palette p) {
    Widget card(String r, String emoji, String title, String sub, Color bg, Color fg) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Material(
            color: bg,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => setState(() {
                role = r;
                lang = r == 'farmer' ? 'es' : 'en';
              }),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(children: [
                  Text(emoji, style: const TextStyle(fontSize: 40)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title, style: p.text(size: 20, weight: FontWeight.w800, color: fg)),
                      Text(sub, style: p.text(size: 15, color: fg.withValues(alpha: 0.75))),
                    ]),
                  ),
                  Icon(Icons.chevron_right_rounded, color: fg),
                ]),
              ),
            ),
          ),
        );
    return ListView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 24), children: [
      Align(
        alignment: Alignment.centerLeft,
        child: IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.arrow_back_rounded, color: p.ink)),
      ),
      Text('¿Quién eres?', style: p.display(size: 34)),
      Text('Who are you?', style: p.display(size: 24, color: p.ink2, weight: FontWeight.w500)),
      const SizedBox(height: 28),
      card('farmer', '👩🏽‍🌾', 'Soy caficultor', 'Quiero vender mi café', p.primary, p.primaryInk),
      card('buyer', '☕', "I'm a coffee buyer", 'Roaster, café or importer', Colors.white, buyerPalette.ink),
    ]);
  }

  Widget _form(Palette p) {
    final farmer = role == 'farmer';
    return ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 32), children: [
      Align(
        alignment: Alignment.centerLeft,
        child: IconButton(onPressed: () => setState(() => role = null), icon: Icon(Icons.arrow_back_rounded, color: p.ink)),
      ),
      Text(t('Crea tu cuenta', 'Create your account'), style: p.display(size: 30)),
      const SizedBox(height: 4),
      Text(
        farmer ? t('Cuenta de caficultor', 'Farmer account') : t('Cuenta de comprador', 'Buyer account'),
        style: p.muted(),
      ),
      const SizedBox(height: 18),
      Text(t('Idioma de la app', 'App language'), style: p.text(size: p.fs - 2, weight: FontWeight.w700)),
      const SizedBox(height: 6),
      Segmented(options: const {'es': 'Español', 'en': 'English'}, value: lang, onChanged: (v) => setState(() => lang = v)),
      const SizedBox(height: 6),
      Text(t('Los mensajes que recibas se traducen a este idioma.', 'Messages you receive are translated into this language.'),
          style: p.muted(size: 13)),
      const SizedBox(height: 16),
      _Field(label: t('Tu nombre', 'Full name'), icon: Icons.person_outline_rounded, controller: c['name']!),
      _Field(label: t('Correo', 'Email'), icon: Icons.mail_outline_rounded, controller: c['email']!, type: TextInputType.emailAddress),
      _Field(label: t('Contraseña (mínimo 6)', 'Password (min. 6)'), icon: Icons.lock_outline_rounded, controller: c['password']!, obscure: true),
      _Field(label: t('Celular (opcional)', 'Phone (optional)'), icon: Icons.phone_android_rounded, controller: c['phone']!, type: TextInputType.phone),
      if (farmer) ...[
        _Field(label: t('Nombre de la finca', 'Farm name'), icon: Icons.cottage_outlined, controller: c['farmName']!),
        Text(t('Departamento', 'Region'), style: p.text(size: p.fs - 2, weight: FontWeight.w700)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: region,
          items: [for (final r in regions) DropdownMenuItem(value: r, child: Text(r, style: p.text()))],
          onChanged: (v) => setState(() => region = v ?? region),
        ),
        const SizedBox(height: 14),
        _Field(label: t('Municipio', 'Town'), icon: Icons.place_outlined, controller: c['municipality']!),
      ] else ...[
        _Field(label: t('Empresa', 'Company'), controller: c['company']!),
        Row(children: [
          Expanded(child: _Field(label: t('Ciudad', 'City'), controller: c['city']!)),
          const SizedBox(width: 12),
          Expanded(child: _Field(label: t('País', 'Country'), controller: c['country']!)),
        ]),
        _Field(label: t('Tipo (tostador, cafetería…)', 'Type (roaster, café…)'), controller: c['type']!),
      ],
      if (_error != null) _ErrorText(_error!),
      const SizedBox(height: 10),
      Btn(t('Crear cuenta', 'Create account'), large: true, block: true, trailing: Icons.chevron_right_rounded, onPressed: _busy ? null : _submit),
      if (_busy) const Padding(padding: EdgeInsets.only(top: 16), child: Center(child: CircularProgressIndicator())),
    ]);
  }
}

class _Field extends StatelessWidget {
  final String label;
  final IconData? icon;
  final TextEditingController controller;
  final TextInputType? type;
  final bool obscure;
  final ValueChanged<String>? onSubmit;
  const _Field({required this.label, required this.controller, this.icon, this.type, this.obscure = false, this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: p.text(size: p.fs - 2, weight: FontWeight.w700)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: type,
          obscureText: obscure,
          autocorrect: !obscure && type != TextInputType.emailAddress,
          onSubmitted: onSubmit,
          style: p.text(),
          decoration: icon == null ? null : InputDecoration(prefixIcon: Icon(icon, color: p.ink2)),
        ),
      ]),
    );
  }
}

class _ErrorText extends StatelessWidget {
  final String text;
  const _ErrorText(this.text);

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: p.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(p.radiusSm)),
      child: Row(children: [
        Icon(Icons.error_outline_rounded, color: p.danger, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: p.text(size: 14, weight: FontWeight.w700, color: p.danger))),
      ]),
    );
  }
}
