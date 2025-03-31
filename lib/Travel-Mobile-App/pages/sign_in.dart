import 'package:app_viaja_mais/Travel-Mobile-App/pages/sign_up.dart';
import 'package:app_viaja_mais/Travel-Mobile-App/pages/travel_home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _passToggle = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  String? _passwordError;
  bool _isLoading = false; // Variável para rastrear o estado de carregamento

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Ativa o estado de carregamento
      });

      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            );
          },
        );

        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        Navigator.of(context).pop(); // Fecha o diálogo de carregamento
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TravelHomeScreen(),
          ),
        );
      } catch (e) {
        setState(() {
          _isLoading = false; // Desativa o estado de carregamento em caso de erro
          if (e.toString().contains('wrong-password')) {
            _passwordError = "Senha incorreta";
          } else {
            _passwordError = null;
          }
        });

        // Fecha o diálogo de carregamento se houver um erro
        Navigator.of(context).pop();

        // Exibe o pop-up com a mensagem de erro
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text("Erro"),
              content: Text(
                _passwordError ?? "Erro ao fazer login. Verifique se seu e-mail e senha estão corretos.",
                style: TextStyle(fontSize: 20),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    "OK",
                    style: TextStyle(color: Colors.black, fontSize: 28),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );

        // Revalida o formulário para exibir a mensagem de erro no campo de senha
        _formKey.currentState!.validate();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SingleChildScrollView(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextFormField(
                    controller: _emailController,
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return "Digite seu E-mail";
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black, width: 2.0),
                      ),
                      labelStyle: TextStyle(
                        color: Colors.black,
                      ),
                      labelText: "E-mail",
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextFormField(
                    controller: _passwordController,
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return "Digite sua senha";
                      } else if (_passwordError != null) {
                        return _passwordError;
                      }
                      return null;
                    },
                    obscureText: _passToggle,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black, width: 2.0),
                      ),
                      labelStyle: TextStyle(
                        color: Colors.black,
                      ),
                      labelText: "Senha",
                      prefixIcon: Icon(Icons.lock),
                      suffixIcon: InkWell(
                        onTap: () {
                          setState(() {
                            _passToggle = !_passToggle;
                          });
                        },
                        child: _passToggle
                            ? Icon(CupertinoIcons.eye_slash_fill)
                            : Icon(CupertinoIcons.eye_fill),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: InkWell(
                    onTap: _isLoading ? null : _signIn, // Desabilita o botão durante o carregamento
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _isLoading ? Colors.grey : Color(0xFF000000), // Muda a cor do botão quando está carregando
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _isLoading ? "Carregando..." : "Login",
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Ainda não criou uma conta?",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SignUpScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "Criar conta",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF000000),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
