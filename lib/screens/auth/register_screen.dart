import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _consent = false;

  Future<void> _submit() async {
    if (!_consent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez accepter la politique de confidentialité.'), backgroundColor: BgColors.danger),
      );
      return;
    }

    final auth = context.read<AuthService>();
    final ok = await auth.register(
      name: _name.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      privacyConsent: _consent,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacementNamed(context, '/parent');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Erreur'), backgroundColor: BgColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.pop(context))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Créer un compte', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Inscrivez-vous pour suivre le transport de votre enfant', style: GoogleFonts.dmSans(color: BgColors.dusk.withValues(alpha: 0.7))),
            const SizedBox(height: 32),
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nom complet')),
            const SizedBox(height: 14),
            TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 14),
            TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Téléphone (optionnel)')),
            const SizedBox(height: 14),
            TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Mot de passe')),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(value: _consent, activeColor: BgColors.terracotta, onChanged: (v) => setState(() => _consent = v ?? false)),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.dmSans(fontSize: 13, color: BgColors.dusk),
                      children: [
                        const TextSpan(text: 'J\'accepte le traitement des données de mon enfant conformément à la '),
                        TextSpan(
                          text: 'politique de confidentialité',
                          style: const TextStyle(color: BgColors.terracotta, fontWeight: FontWeight.w600),
                          recognizer: TapGestureRecognizer()..onTap = () => launchUrl(Uri.parse(AppConstants.privacyPolicyUrl)),
                        ),
                        const TextSpan(text: ' (Loi n° 2008-12).'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: auth.isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: BgColors.terracotta),
                child: auth.isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Créer mon compte'),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: BgColors.gold.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: BgColors.gold),
                  const SizedBox(width: 12),
                  Expanded(child: Text('L\'affectation de votre enfant à un bus est faite par l\'administrateur scolaire.', style: GoogleFonts.dmSans(fontSize: 13))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
