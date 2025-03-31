import 'package:app_viaja_mais/Travel-Mobile-App/pages/onboard_travel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app_viaja_mais/Travel-Mobile-App/pages/travel_home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp( // ❌ Removido o "const" daqui
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasData) {
            return TravelHomeScreen(); // Adicionado "const" aqui pois TravelHomeScreen é um StatelessWidget
          } else if (snapshot.hasError) {
            return const Scaffold(
              body: Center(
                child: Text('Ocorreu um erro. Tente novamente.'),
              ),
            );
          } else {
            return const TravelOnBoardingScreen(); // Adicionado "const" aqui também
          }
        },
      ),
    );
  }
}
