import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:convert';
import 'package:app_viaja_mais/Travel-Mobile-App/models/travel_model.dart'; // Ajuste o caminho se necessário
import 'package:app_viaja_mais/Travel-Mobile-App/const.dart'; // Para kButtonColor

class PlaceDetailScreen extends StatefulWidget {
  final String destinationId;
  const PlaceDetailScreen({super.key, required this.destinationId});

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  TravelDestination? destination;
  bool isLoading = true;
  bool _isFavorited = false;
  String? _userId;

  PageController pageController = PageController();
  int currentPage = 0;
  quill.QuillController _quillController = quill.QuillController.basic();

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    fetchDestinationData();
  }

  @override
  void dispose() {
    _quillController.dispose();
    pageController.dispose();
    super.dispose();
  }

  Future<void> fetchDestinationData() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('destinations')
          .doc(widget.destinationId)
          .get();

      if (doc.exists && doc.data() != null) {
        if (!mounted) return;
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          destination = TravelDestination.fromJson(data);
          _quillController = quill.QuillController(
            document: _convertToQuillDelta(destination!.description),
            selection: const TextSelection.collapsed(offset: 0),
          );
        });

        if (_userId != null && destination != null) {
          await _checkIfFavorited();
        } else {
          if (!mounted) return;
          setState(() => isLoading = false);
        }
      } else {
        if (!mounted) return;
        setState(() => isLoading = false);
      }
    } catch (error) {
      print("Erro ao buscar destino: $error");
      if (!mounted) return;
      setState(() => isLoading = false);
    }
    if (isLoading && mounted && _userId == null && destination != null) {
      setState(() => isLoading = false);
    }
  }

  quill.Document _convertToQuillDelta(String text) {
    try {
      final parsedJson = jsonDecode(text);
      if (parsedJson is List) {
        return quill.Document.fromJson(parsedJson);
      }
      print("Descrição não é um Delta JSON em formato de lista, tratando como texto simples.");
    } catch (e) {
      // print("Descrição não é JSON ('$text'), tratando como texto simples: $e");
    }
    return quill.Document()..insert(0, text);
  }

  Future<void> _checkIfFavorited() async {
    if (!mounted) return;
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId!) // _userId já foi verificado como não nulo antes de chamar
          .get();

      bool isCurrentlyFavorited = false;
      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        if (userData.containsKey('favorite_destination_ids') &&
            userData['favorite_destination_ids'] is List) {
          List<dynamic> favorites = userData['favorite_destination_ids'];
          isCurrentlyFavorited = favorites.contains(destination!.id); // destination já foi verificado
        }
      }
      if (!mounted) return;
      setState(() {
        _isFavorited = isCurrentlyFavorited;
      });
    } catch (e) {
      print("Erro ao verificar favoritos: $e");
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _toggleFavorite() async {
    if (_userId == null || destination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faça login para favoritar destinos.')),
      );
      return;
    }

    final userDocRef = FirebaseFirestore.instance.collection('users').doc(_userId);
    final currentDestinationId = destination!.id;

    try {
      if (_isFavorited) {
        await userDocRef.update({
          'favorite_destination_ids': FieldValue.arrayRemove([currentDestinationId])
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Destino removido dos favoritos!')),
          );
        }
      } else {
        await userDocRef.set({
          'favorite_destination_ids': FieldValue.arrayUnion([currentDestinationId])
        }, SetOptions(merge: true));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Destino adicionado aos favoritos! ❤️')),
          );
        }
      }
      if (!mounted) return;
      setState(() {
        _isFavorited = !_isFavorited;
      });
    } catch (e) {
      print("Erro ao atualizar favoritos: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao atualizar favoritos.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color appBarColor = const Color(0xFF263892); // kButtonColor

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Carregando Detalhes..."),
          backgroundColor: appBarColor,
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (destination == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Erro"),
          backgroundColor: appBarColor,
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: Text("Destino não encontrado ou erro ao carregar.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(destination!.name.isNotEmpty ? destination!.name : "Detalhes do Destino"),
        backgroundColor: appBarColor,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_userId != null)
            IconButton(
              icon: Icon(
                _isFavorited ? Icons.star : Icons.star_border,
                color: _isFavorited ? Colors.yellowAccent : Colors.white,
              ),
              tooltip: _isFavorited ? 'Remover dos Favoritos' : 'Adicionar aos Favoritos',
              onPressed: _toggleFavorite,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (destination!.imageUrls.isNotEmpty)
              SizedBox(
                height: 250,
                child: PageView.builder(
                  controller: pageController,
                  itemCount: destination!.imageUrls.length,
                  onPageChanged: (index) {
                    if (!mounted) return;
                    setState(() {
                      currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: Image.network(
                          destination!.imageUrls[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey[300],
                            child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                          ),
                          loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                height: 200,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Center(child: Icon(Icons.image_not_supported, size: 60, color: Colors.grey[400])),
              ),

            if (destination!.imageUrls.length > 1)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(destination!.imageUrls.length, (index) {
                      return Container(
                        width: 8.0,
                        height: 8.0,
                        margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 3.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: currentPage == index
                              ? appBarColor
                              : Colors.grey.shade400,
                        ),
                      );
                    }),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                destination!.name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),

            // ⭐ TabBar REVERTIDA PARA O ESTILO ANTERIOR ⭐
            DefaultTabController(
              length: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Para alinhar a TabBar à esquerda se o Column for mais largo
                children: [
                  Material( // Envolve a TabBar com Material para ter um fundo (opcional)
                    color: Colors.white, // Ou a cor de fundo que você preferir para a TabBar
                    child: TabBar(
                      labelColor: appBarColor, // Cor do texto da aba selecionada (azul escuro)
                      unselectedLabelColor: Colors.black54, // Cor do texto das abas não selecionadas
                      indicatorColor: appBarColor, // Cor da linha indicadora
                      indicatorWeight: 3.0, // Espessura da linha indicadora
                      labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600), // Estilo do texto da aba
                      unselectedLabelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      tabs: const [
                        Tab(text: 'Visão Geral'),
                        Tab(text: 'Descrição'),
                        Tab(text: 'Avaliações'),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 400, // Altura para o conteúdo das abas (revertido para 400)
                    child: TabBarView(
                      children: [
                        // Conteúdo da Aba "Visão Geral"
                        ListView(
                          padding: const EdgeInsets.only(top: 16, left: 8, right: 8),
                          children: [
                            if(destination!.hours.isNotEmpty) _buildInfoTile(Icons.access_time_outlined, "Horários", destination!.hours, appBarColor),
                            if(destination!.duration.isNotEmpty) _buildInfoTile(Icons.timer_outlined, "Duração Estimada", destination!.duration, appBarColor),
                            if(destination!.age.isNotEmpty) _buildInfoTile(Icons.family_restroom_outlined, "Idade Recomendada", destination!.age, appBarColor),
                          ],
                        ),
                        // Conteúdo da Aba "Descrição" (Quill)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0, left: 8, right: 8),
                          child: quill.QuillEditor.basic(
                            configurations: quill.QuillEditorConfigurations(
                              controller: _quillController,
                              showCursor: false,
                              customStyles: quill.DefaultStyles(
                                  paragraph: quill.DefaultTextBlockStyle(
                                    const TextStyle(fontSize: 15, color: Colors.black87, height: 1.6),
                                    const quill.VerticalSpacing(0, 0),
                                    const quill.VerticalSpacing(10, 0),
                                    null,
                                  )
                              ),
                            ),
                          ),
                        ),
                        // Conteúdo da Aba "Avaliações"
                        destination!.comments.isEmpty
                            ? const Center(child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text("Ainda não há avaliações.", style: TextStyle(fontSize: 16, color: Colors.grey)),
                        ))
                            : ListView.builder(
                          padding: const EdgeInsets.only(top: 16, left: 8, right: 8),
                          itemCount: destination!.comments.length,
                          itemBuilder: (context, index) {
                            final comment = destination!.comments[index];
                            return Card(
                              elevation: 1,
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(comment.userImage),
                                  onBackgroundImageError: (exception, stackTrace) => const Icon(Icons.person_outline, color: Colors.grey),
                                  backgroundColor: Colors.grey[200],
                                ),
                                title: Text(comment.userName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(comment.comment, style: TextStyle(color: Colors.grey[700])),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('${comment.rating}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[700])),
                                    const SizedBox(width: 2),
                                    Icon(Icons.star, color: Colors.orange[600], size: 18),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle, Color iconColor) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade200)
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor, size: 28), // Usando a cor do ícone passada
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
      ),
    );
  }
}