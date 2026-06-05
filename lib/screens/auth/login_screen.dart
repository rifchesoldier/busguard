import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/bg_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(text: 'parent@busguard.sn');
  final _password = TextEditingController(text: 'BusGuard2024!');
  bool _obscure = true;

  Future<void> _submit() async {
    final auth = context.read<AuthService>();
    final ok = await auth.login(_email.text.trim(), _password.text);
    if (!mounted) return;
    if (ok) {
      final route = auth.user!.isDriver ? '/driver' : '/parent';
      Navigator.pushReplacementNamed(context, route);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Erreur de connexion'), backgroundColor: BgColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.42,
            decoration: BgTheme.heroGradient,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BgLogo(size: 56, light: true),
                    const Spacer(),
                    Text('Bon retour !', style: GoogleFonts.outfit(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 8),
                    Text('Suivez le bus de votre enfant en direct', style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 15)),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            top: MediaQuery.of(context).size.height * 0.34,
            child: Container(
              decoration: const BoxDecoration(
                color: BgColors.cream,
                borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _password,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text('Chauffeur ? Utilisez vos identifiants admin', style: GoogleFonts.dmSans(fontSize: 12, color: BgColors.dusk.withValues(alpha: 0.6))),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: auth.isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(backgroundColor: BgColors.terracotta),
                      child: auth.isLoading
                          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Se connecter'),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Pas encore de compte ? ', style: GoogleFonts.dmSans(color: BgColors.dusk)),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/register'),
                          child: Text('S\'inscrire', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: BgColors.terracotta)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
