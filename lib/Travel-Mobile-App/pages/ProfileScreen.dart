// profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';

import 'package:app_viaja_mais/Travel-Mobile-App/models/travel_model.dart' as model;
import 'package:app_viaja_mais/Travel-Mobile-App/pages/place_detail.dart';
// Importe suas outras telas aqui
// Exemplo: import 'package:app_viaja_mais/Travel-Mobile-App/const.dart';

// ▼▼▼ SUBSTITUA ESTES PLACEHOLDERS PELAS SUAS TELAS REAIS E IMPORTE-AS CORRETAMENTE ▼▼▼
class PlaceholderLoginScreen extends StatelessWidget {
  const PlaceholderLoginScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login (Substitua)")),
      body: const Center(child: Text("Esta é a sua Tela de Login (Substitua)")),
    );
  }
}

class PlaceholderEditProfileScreen extends StatelessWidget {
  const PlaceholderEditProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Editar Perfil (Substitua)")),
      body: const Center(child: Text("Esta é a sua Tela de Editar Perfil (Substitua)")),
    );
  }
}
// ▲▲▲ SUBSTITUA ESTES PLACEHOLDERS PELAS SUAS TELAS REAIS E IMPORTE-AS CORRETAMENTE ▲▲▲

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _userId;
  String _userName = "Carregando...";
  String? _userEmail;
  String? _profileImageUrl;
  int _favoriteCount = 0;
  final int _commentCount = 0;
  bool _isLoading = true;

  // Estados para a lista de favoritos integrada
  bool _showFavoritesSection = false;
  List<String> _favoriteDestinationIds = [];
  List<model.TravelDestination> _favoriteDestinations = [];
  bool _isLoadingFavorites = false;

  final Color _primaryAppColor = const Color(0xFF263892);

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _userId = currentUser.uid;
      _userEmail = currentUser.email;
      await _loadUserDataFromFirestore(); // Isso agora também carrega _favoriteDestinationIds
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _userName = "Visitante";
        });
      }
    }
  }

  Future<void> _loadUserDataFromFirestore() async {
    if (!mounted) return;
    // Não seta _isLoading = true aqui para não piscar a tela toda ao recarregar favoritos
    // setState(() => _isLoading = true); // Removido para refresh mais suave

    if (_userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        if (!mounted) return;
        setState(() {
          _userName = data['name'] ?? FirebaseAuth.instance.currentUser?.displayName ?? "Usuário";
          _profileImageUrl = data['profile_image_url'];
          if (data.containsKey('favorite_destination_ids') && data['favorite_destination_ids'] is List) {
            _favoriteDestinationIds = List<String>.from(data['favorite_destination_ids']);
            _favoriteCount = _favoriteDestinationIds.length;
          } else {
            _favoriteDestinationIds = [];
            _favoriteCount = 0;
          }
        });
      } else {
        if (!mounted) return;
        setState(() {
          _userName = FirebaseAuth.instance.currentUser?.displayName ?? "Usuário";
          _favoriteDestinationIds = [];
          _favoriteCount = 0;
        });
      }
    } catch (e) {
      print("Erro ao carregar dados do usuário do Firestore: $e");
      // Tratar erro
    } finally {
      if (mounted && _isLoading) { // Só seta isLoading para false se era o carregamento inicial
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadFavoriteDestinationsDetails() async {
    if (!_showFavoritesSection || _favoriteDestinationIds.isEmpty) {
      if (mounted && _favoriteDestinationIds.isEmpty) {
        setState(() {
          _favoriteDestinations = [];
          _isLoadingFavorites = false;
        });
      }
      return;
    }

    if (!mounted) return;
    setState(() => _isLoadingFavorites = true);

    List<model.TravelDestination> fetchedDestinations = [];
    try {
      List<List<String>> chunks = [];
      for (var i = 0; i < _favoriteDestinationIds.length; i += 30) {
        chunks.add(_favoriteDestinationIds.sublist(i, i + 30 > _favoriteDestinationIds.length ? _favoriteDestinationIds.length : i + 30));
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

      if (_favoriteDestinationIds.isNotEmpty && fetchedDestinations.isNotEmpty) {
        fetchedDestinations.sort((a, b) => _favoriteDestinationIds.indexOf(a.id).compareTo(_favoriteDestinationIds.indexOf(b.id)));
      }

      if (!mounted) return;
      setState(() {
        _favoriteDestinations = fetchedDestinations;
      });
    } catch (e) {
      print("Erro ao carregar detalhes dos favoritos: $e");
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao carregar detalhes dos favoritos: ${e.toString()}")));
    } finally {
      if (!mounted) return;
      setState(() => _isLoadingFavorites = false);
    }
  }

  Future<void> _refreshAllProfileData() async {
    await _loadUserDataFromFirestore(); // Recarrega dados do usuário (incluindo IDs de favoritos)
    if (_showFavoritesSection && mounted) { // Se a seção de favoritos estiver visível, recarrega os detalhes
      await _loadFavoriteDestinationsDetails();
    } else if (mounted) { // Se não estiver visível, mas os IDs podem ter mudado, limpa os detalhes
      setState(() {
        _favoriteDestinations = [];
      });
    }
  }


  Future<void> _pickImage() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade de adicionar/editar imagem será implementada.')),
    );
  }

  Future<void> _logout() async {
    // ... (código de logout existente)
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const PlaceholderLoginScreen()),
              (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      print("Erro ao fazer logout: $e");
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao fazer logout: ${e.toString()}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Meu Perfil"),
        backgroundColor: _primaryAppColor,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userId == null
          ? _buildLoginPrompt()
          : _buildProfileView(),
    );
  }

  Widget _buildLoginPrompt() {
    // ... (código _buildLoginPrompt existente)
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined, size: 70, color: Colors.grey[400]),
            const SizedBox(height: 20),
            const Text(
              "Você não está logado.",
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              "Faça login para acessar seu perfil e favoritos.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryAppColor,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
              ),
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const PlaceholderLoginScreen()),
                      (Route<dynamic> route) => false,
                ).then((_) => _loadInitialData()); // Tenta recarregar após "login"
              },
              child: const Text("Fazer Login", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildProfileView() {
    return RefreshIndicator(
      onRefresh: _refreshAllProfileData, // Atualiza todos os dados do perfil
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 24),
          _buildStatsRow(),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "Opções",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700]),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              elevation: 1,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  _buildMenuOption(
                    icon: Icons.account_circle_outlined,
                    title: "Informações Pessoais",
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const PlaceholderEditProfileScreen()));
                    },
                  ),
                  _buildMenuOption(
                    icon: Icons.favorite_outline,
                    title: "Seus Favoritos",
                    trailingIcon: _showFavoritesSection ? Icons.expand_less : Icons.expand_more,
                    onTap: () {
                      setState(() {
                        _showFavoritesSection = !_showFavoritesSection;
                        if (_showFavoritesSection && _favoriteDestinations.isEmpty && _favoriteDestinationIds.isNotEmpty) {
                          _loadFavoriteDestinationsDetails();
                        }
                      });
                    },
                  ),
                  // Seção de Favoritos (condicional)
                  if (_showFavoritesSection) _buildFavoritesSection(),

                  _buildMenuOption(
                    icon: Icons.logout_outlined,
                    title: "Logout",
                    isLogout: true,
                    onTap: _logout,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildFavoritesSection() {
    if (_isLoadingFavorites) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_favoriteDestinationIds.isEmpty) { // Verifica pelos IDs primeiro
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Text("Nenhum local favoritado ainda.", style: TextStyle(color: Colors.grey[600], fontSize: 15), textAlign: TextAlign.center),
      );
    }
    if (_favoriteDestinations.isEmpty && !_isLoadingFavorites) { // Se IDs existem mas detalhes não carregaram (ou foram removidos)
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Text("Não foi possível carregar os detalhes dos favoritos ou não há favoritos.", style: TextStyle(color: Colors.grey[600], fontSize: 15), textAlign: TextAlign.center),
      );
    }

    // Usar um Column para o título e depois o ListView
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: Text(
            "Meus Locais Favoritos (${_favoriteDestinations.length})",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[700]),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _favoriteDestinations.length,
          itemBuilder: (context, index) {
            final destination = _favoriteDestinations[index];
            String? displayImageUrl;
            if (destination.imageUrls.isNotEmpty) {
              displayImageUrl = destination.imageUrls.firstWhere((url) => url.startsWith("http"), orElse: () => destination.imageUrls.first);
            }
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: displayImageUrl != null
                    ? CachedNetworkImage(
                  imageUrl: displayImageUrl,
                  width: 60, height: 60, fit: BoxFit.cover,
                  placeholder: (context, url) => Container(width: 60, height: 60, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator(strokeWidth: 2.0))),
                  errorWidget: (context, url, error) => Container(width: 60, height: 60, color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey)),
                )
                    : Container(width: 60, height: 60, color: Colors.grey[200], child: const Icon(Icons.image_not_supported, color: Colors.grey)),
              ),
              title: Text(destination.name, style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text(destination.location, style: TextStyle(color: Colors.grey[600])),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PlaceDetailScreen(destinationId: destination.id)),
                ).then((_) => _refreshAllProfileData()); // Atualiza tudo ao voltar
              },
            );
          },
        ),
        const SizedBox(height: 10), // Um pouco de espaço após a lista
      ],
    );
  }


  Widget _buildProfileHeader() {
    // ... (código _buildProfileHeader existente, sem alterações)
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
      decoration: BoxDecoration(
        color: _primaryAppColor,
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white.withOpacity(0.8),
                child: CircleAvatar(
                  radius: 57,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(_profileImageUrl!)
                      : null,
                  child: _profileImageUrl == null || _profileImageUrl!.isEmpty
                      ? Icon(Icons.person, size: 70, color: Colors.grey[500])
                      : null,
                ),
              ),
              Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 3,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: Icon(Icons.camera_alt_outlined, size: 22, color: _primaryAppColor),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 18),
          Text(
            _userName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          if (_userEmail != null && _userEmail!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _userEmail!,
              style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.85)),
              textAlign: TextAlign.center,
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    // ... (código _buildStatsRow existente, sem alterações)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(child: _buildStatItem("Comentários", _commentCount.toString(), Icons.comment_outlined)),
          Container(height: 40, width: 1, color: Colors.grey[300], margin: const EdgeInsets.symmetric(horizontal: 8)),
          Expanded(child: _buildStatItem("Favoritos", _favoriteCount.toString(), Icons.favorite_outline)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    // ... (código _buildStatItem existente, sem alterações)
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: _primaryAppColor, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildMenuOption({required IconData icon, required String title, required VoidCallback onTap, bool isLogout = false, IconData? trailingIcon}) {
    Color iconColor = isLogout ? Colors.red.shade600 : _primaryAppColor.withOpacity(0.9);
    Color textColor = isLogout ? Colors.red.shade700 : Colors.black87;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Icon(icon, color: iconColor, size: 26),
      title: Text(
        title,
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: textColor),
      ),
      trailing: trailingIcon != null
          ? Icon(trailingIcon, size: 22, color: Colors.grey[500])
          : (isLogout ? null : Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400])),
      onTap: onTap,
    );
  }
}