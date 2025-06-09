import 'package:app_viaja_mais/Travel-Mobile-App/pages/sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordOneController = TextEditingController();
  final TextEditingController _passwordTwoController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _passToggle = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordOneController.dispose();
    _passwordTwoController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      try {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordOneController.text.trim(),
        );

        // Salva informações adicionais do usuário no Firestore
        await _firestore.collection('users').doc(userCredential.user?.uid).set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'createdAt': Timestamp.now(),
        });

        if (!mounted) return;
        // Mostra um diálogo de sucesso e depois navega para o login
        _showSuccessDialog();

      } on FirebaseAuthException catch (e) {
        String errorMessage = "Ocorreu um erro desconhecido.";
        if (e.code == 'weak-password') {
          errorMessage = 'A senha é muito fraca. Tente uma mais forte.';
        } else if (e.code == 'email-already-in-use') {
          errorMessage = 'Este e-mail já está cadastrado. Tente fazer login.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'O formato do e-mail é inválido.';
        }
        _showErrorDialog(errorMessage);
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green),
            SizedBox(width: 10),
            Text("Sucesso!"),
          ],
        ),
        content: const Text("Sua conta foi criada. Agora você pode fazer o login."),
        actions: <Widget>[
          TextButton(
            child: const Text("Fazer Login"),
            onPressed: () {
              Navigator.of(ctx).pop(); // Fecha o diálogo
              Navigator.pushReplacement( // Navega para a tela de login
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen())
              );
            },
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 10),
            Text("Erro no Cadastro"),
          ],
        ),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFF263892),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset('assets/travel-app/logo.png', height: 100),
                    const SizedBox(height: 15),
                    const Text(
                      'Crie sua Conta',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Complete os campos para começar a aventura.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 30),

                    // --- Campo de Nome ---
                    TextFormField(
                      controller: _nameController,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(color: Colors.white),
                      validator: (value) => (value?.isEmpty ?? true) ? "Por favor, insira seu nome." : null,
                      decoration: _buildInputDecoration(
                        labelText: 'Nome completo',
                        prefixIcon: Icons.person_outline,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- Campo de E-mail ---
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Por favor, insira seu e-mail.";
                        if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) return "Por favor, insira um e-mail válido.";
                        return null;
                      },
                      decoration: _buildInputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: Icons.email_outlined,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- Campo de Senha ---
                    TextFormField(
                      controller: _passwordOneController,
                      obscureText: _passToggle,
                      style: const TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Por favor, insira uma senha.";
                        if (value.length < 6) return "A senha deve ter no mínimo 6 caracteres.";
                        return null;
                      },
                      decoration: _buildInputDecoration(
                        labelText: 'Senha',
                        prefixIcon: Icons.lock_outline,
                        suffixIcon: _buildTogglePassword(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- Campo de Confirmação de Senha ---
                    TextFormField(
                      controller: _passwordTwoController,
                      obscureText: _passToggle,
                      style: const TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Por favor, confirme sua senha.";
                        if (value != _passwordOneController.text) return "As senhas não coincidem.";
                        return null;
                      },
                      decoration: _buildInputDecoration(
                        labelText: 'Confirmar Senha',
                        prefixIcon: Icons.lock_outline,
                      ),
                    ),
                    const SizedBox(height: 30),

                    _buildSignUpButton(),
                    const SizedBox(height: 30),

                    _buildLoginSection(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Widgets Auxiliares ---

  Widget _buildSignUpButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _signUp,
      style: ElevatedButton.styleFrom(
        foregroundColor: const Color(0xFF263892),
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 5,
      ),
      child: _isLoading
          ? const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(color: Color(0xFF263892), strokeWidth: 3),
      )
          : const Text(
        'CRIAR CONTA',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildLoginSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Já tem uma conta?", style: TextStyle(color: Colors.white70)),
        TextButton(
          onPressed: () => Navigator.pop(context), // Volta para a tela anterior (Login)
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text("Faça o login", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildTogglePassword() {
    return IconButton(
      icon: Icon(
        _passToggle ? CupertinoIcons.eye_slash_fill : CupertinoIcons.eye_fill,
        color: Colors.white70,
      ),
      onPressed: () => setState(() => _passToggle = !_passToggle),
    );
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(prefixIcon, color: Colors.white70),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
    );
  }
}