import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_viaja_mais/Travel-Mobile-App/models/travel_model.dart' as model;
import 'package:app_viaja_mais/Travel-Mobile-App/pages/place_detail.dart';
import 'package:app_viaja_mais/Travel-Mobile-App/const.dart';

// ▼▼▼ ADICIONE O IMPORT PARA SUA TELA DE LOGIN AQUI ▼▼▼
// Exemplo: import 'caminho/para/sua/login_screen.dart';
// class LoginScreen extends StatelessWidget { const LoginScreen({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text("Login (Placeholder)")), body: Center(child: Text("Esta é a tela de Login")));} // Placeholder
// ▲▲▲ ADICIONE O IMPORT PARA SUA TELA DE LOGIN AQUI ▲▲▲

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  String? _userId;
  List<model.TravelDestination> _favoriteDestinations = [];
  bool _isLoading = true;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _checkUserAndLoadFavorites();
  }

  void _checkUserAndLoadFavorites() {
    if (!mounted) return;
    setState(() {
      _userId = FirebaseAuth.instance.currentUser?.uid;
    });
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = "";
      _favoriteDestinations = [];
    });

    if (_userId == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        // A UI para "não logado" será construída no _buildBody
      });
      return;
    }

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .get();

      List<String> favoriteIds = [];
      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        if (userData.containsKey('favorite_destination_ids') &&
            userData['favorite_destination_ids'] is List) {
          favoriteIds = List<String>.from(userData['favorite_destination_ids']);
        }
      }

      if (favoriteIds.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          // A mensagem "Nenhum local favoritado" será tratada no _buildBody
        });
        return;
      }

      List<model.TravelDestination> fetchedDestinations = [];
      List<List<String>> chunks = [];
      for (var i = 0; i < favoriteIds.length; i += 30) {
        chunks.add(favoriteIds.sublist(i, i + 30 > favoriteIds.length ? favoriteIds.length : i + 30));
      }

      for (List<String> chunk in chunks) {
        if (chunk.isEmpty) continue;
        QuerySnapshot destinationsSnapshot = await FirebaseFirestore.instance
            .collection('destinations')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (var doc in destinationsSnapshot.docs) {
          if (doc.exists && doc.data() != null) {
            fetchedDestinations.add(model.TravelDestination.fromJson(doc.data() as Map<String, dynamic>));
          }
        }
      }

      if (favoriteIds.isNotEmpty && fetchedDestinations.isNotEmpty) {
        fetchedDestinations.sort((a, b) => favoriteIds.indexOf(a.id).compareTo(favoriteIds.indexOf(b.id)));
      }

      if (!mounted) return;
      setState(() {
        _favoriteDestinations = fetchedDestinations;
        _isLoading = false;
        if (_favoriteDestinations.isEmpty && favoriteIds.isNotEmpty) {
          _errorMessage = "Alguns locais favoritados não foram encontrados.";
        }
      });

    } catch (e) {
      print("Erro ao carregar favoritos: $e");
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Erro ao carregar seus favoritos. Tente novamente.";
      });
    }
  }

  void _navigateToDetail(String destinationId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaceDetailScreen(destinationId: destinationId),
      ),
    ).then((_) {
      if (mounted) {
        _checkUserAndLoadFavorites(); // Recarrega ao voltar
      }
    });
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      // ▼▼▼ SUBSTITUA 'LoginScreen()' PELO CONSTRUTOR DA SUA TELA DE LOGIN ▼▼▼
      MaterialPageRoute(builder: (context) => const PlaceholderLoginScreen()), // Ex: LoginScreen()
      // ▲▲▲ SUBSTITUA 'LoginScreen()' PELO CONSTRUTOR DA SUA TELA DE LOGIN ▲▲▲
    ).then((_) {
      if (mounted) {
        _checkUserAndLoadFavorites(); // Verifica o usuário e recarrega favoritos após tentar login
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Meus Favoritos"),
        backgroundColor:  const Color(0xFF263892), // Certifique-se de que esta cor é a desejada ou use kButtonColor
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        automaticallyImplyLeading: false,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_userId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0), // Aumentado padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.favorite_border, size: 70, color: Colors.grey[400]), // Ícone
              const SizedBox(height: 20),
              Text(
                "Faça o login e acesse seus lugares favoritos",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 19, color: Colors.grey[800], fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: kButtonColor,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)
                    )
                ),
                onPressed: _navigateToLogin,
                child: const Text(
                  "Fazer Login",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty && _errorMessage != "Alguns locais favoritados não foram encontrados.") {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red[400], size: 50),
              const SizedBox(height:10),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, color: Colors.red[700]),
              ),
              const SizedBox(height:20),
              ElevatedButton(onPressed: _loadFavorites, child: Text("Tentar Novamente"))
            ],
          ),
        ),
      );
    }

    if (_favoriteDestinations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0), // Aumentado padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.maps_ugc_outlined, size: 70, color: Colors.grey[400]),
              const SizedBox(height: 20),
              Text(
                _errorMessage.isNotEmpty ? _errorMessage : "Nenhum local favoritado ainda", // Mostra erro específico se houver
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: ListView.builder(
        padding: const EdgeInsets.all(10.0),
        itemCount: _favoriteDestinations.length,
        itemBuilder: (context, index) {
          final destination = _favoriteDestinations[index];
          String? displayImageUrl;
          if (destination.imageUrls.isNotEmpty) {
            displayImageUrl = destination.imageUrls.firstWhere((url) => url.startsWith("http"), orElse: () => destination.imageUrls.first);
          }

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _navigateToDetail(destination.id),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: displayImageUrl != null
                          ? Image.network(
                        displayImageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(width: 80, height: 80, color: Colors.grey[200], child: const Icon(Icons.broken_image, size: 40, color: Colors.grey)),
                      )
                          : Container(width: 80, height: 80, color: Colors.grey[200], child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey)),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            destination.name,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            destination.location,
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ▼▼▼ REMOVA ESTE WIDGET PLACEHOLDER E IMPORTE SUA TELA DE LOGIN REAL ▼▼▼
class PlaceholderLoginScreen extends StatelessWidget {
  const PlaceholderLoginScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tela de Login (Exemplo)")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Esta é a sua tela de login."),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Simular login e voltar
                // No seu app real, o Firebase Auth cuidaria do login.
                // Após o login, o .then() na FavoritesScreen chamaria _checkUserAndLoadFavorites()
                Navigator.pop(context);
              },
              child: const Text("Simular Login e Voltar"),
            )
          ],
        ),
      ),
    );
  }
}
// ▲▲▲ REMOVA ESTE WIDGET PLACEHOLDER E IMPORTE SUA TELA DE LOGIN REAL ▲▲▲