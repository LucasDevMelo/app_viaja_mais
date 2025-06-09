import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:convert';
import 'package:app_viaja_mais/Travel-Mobile-App/models/travel_model.dart';
import 'package:app_viaja_mais/Travel-Mobile-App/const.dart';

// --- Model e Widgets de Avaliação (Sem alterações) ---

class Review {
  // ... (código do modelo Review permanece o mesmo)
  final String userId;
  final String userName;
  final double rating;
  final String comment;
  final Timestamp timestamp;

  Review({
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.timestamp,
  });

  factory Review.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Review(
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Usuário Anônimo',
      rating: (data['rating'] ?? 0.0).toDouble(),
      comment: data['comment'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
}

class AddReviewWidget extends StatefulWidget {
  // ... (código do widget AddReviewWidget permanece o mesmo)
  final String destinationId;
  const AddReviewWidget({super.key, required this.destinationId});

  @override
  State<AddReviewWidget> createState() => _AddReviewWidgetState();
}

class _AddReviewWidgetState extends State<AddReviewWidget> {
  final _commentController = TextEditingController();
  double _rating = 0.0;
  bool _isSubmitting = false;

  Future<void> _submitReview() async {
    if (_rating == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, selecione uma nota.')));
      return;
    }
    if (_commentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, escreva um comentário.')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Usuário não logado.");

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userName = userDoc.data()?['name'] ?? 'Usuário Anônimo';

      await FirebaseFirestore.instance
          .collection('destinations')
          .doc(widget.destinationId)
          .collection('reviews')
          .doc(user.uid)
          .set({
        'userId': user.uid,
        'userName': userName,
        'rating': _rating,
        'comment': _commentController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avaliação enviada com sucesso!')));

    } catch (e) {
      print("Erro ao enviar avaliação: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao enviar avaliação. Tente novamente.')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Deixe sua avaliação', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () => setState(() => _rating = index + 1.0),
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_outline,
                    color: Colors.amber,
                    size: 36,
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _commentController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Escreva seu comentário aqui...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitReview,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: kButtonColor,
              foregroundColor: Colors.white,
            ),
            child: _isSubmitting
                ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white))
                : const Text('Enviar Avaliação', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

// --- TELA PRINCIPAL (PlaceDetailScreen) ---

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
    // ... (código de fetchDestinationData permanece o mesmo)
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
          destination = TravelDestination.fromJson(data..['id'] = doc.id);
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
    // ... (código de _convertToQuillDelta permanece o mesmo)
    try {
      final parsedJson = jsonDecode(text);
      if (parsedJson is List) {
        return quill.Document.fromJson(parsedJson);
      }
    } catch (e) {}
    return quill.Document()..insert(0, text);
  }

  Future<void> _checkIfFavorited() async {
    // ... (código de _checkIfFavorited permanece o mesmo)
    if (!mounted) return;
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId!)
          .get();

      bool isCurrentlyFavorited = false;
      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        if (userData.containsKey('favorite_destination_ids') &&
            userData['favorite_destination_ids'] is List) {
          List<dynamic> favorites = userData['favorite_destination_ids'];
          isCurrentlyFavorited = favorites.contains(destination!.id);
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
    // ... (código de _toggleFavorite permanece o mesmo)
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
      } else {
        await userDocRef.set({
          'favorite_destination_ids': FieldValue.arrayUnion([currentDestinationId])
        }, SetOptions(merge: true));
      }
      if (!mounted) return;
      setState(() => _isFavorited = !_isFavorited);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isFavorited ? 'Adicionado aos favoritos!' : 'Removido dos favoritos.')),
      );
    } catch (e) {
      print("Erro ao atualizar favoritos: $e");
    }
  }

  void _showAddReviewSheet() {
    // ... (código de _showAddReviewSheet permanece o mesmo)
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: AddReviewWidget(destinationId: widget.destinationId),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color appBarColor = const Color(0xFF263892);

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(backgroundColor: appBarColor, foregroundColor: Colors.white),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (destination == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Erro"), backgroundColor: appBarColor, foregroundColor: Colors.white),
        body: const Center(child: Text("Destino não encontrado ou erro ao carregar.")),
      );
    }

    return Scaffold(
      // ⭐ ALTERAÇÃO AQUI ⭐
      backgroundColor: Colors.white,
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
                    setState(() => currentPage = index);
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
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12.0)),
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
                        width: 8.0, height: 8.0,
                        margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 3.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: currentPage == index ? appBarColor : Colors.grey.shade400,
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

            DefaultTabController(
              length: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    color: Colors.white,
                    child: TabBar(
                      labelColor: appBarColor,
                      unselectedLabelColor: Colors.black54,
                      indicatorColor: appBarColor,
                      indicatorWeight: 3.0,
                      labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      unselectedLabelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      tabs: const [
                        Tab(text: 'Visão Geral'),
                        Tab(text: 'Descrição'),
                        Tab(text: 'Avaliações'),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 800,
                    child: TabBarView(
                      children: [
                        ListView(
                          padding: const EdgeInsets.only(top: 16, left: 8, right: 8),
                          children: [
                            if (destination!.hours.isNotEmpty) _buildInfoTile(Icons.access_time_outlined, "Horários", destination!.hours, appBarColor),
                            if (destination!.duration.isNotEmpty) _buildInfoTile(Icons.timer_outlined, "Duração Estimada", destination!.duration, appBarColor),
                            if (destination!.age.isNotEmpty) _buildInfoTile(Icons.family_restroom_outlined, "Idade Recomendada", destination!.age, appBarColor),
                          ],
                        ),
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
                        _buildReviewsTab(),
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

  Widget _buildReviewsTab() {
    return Column(
      children: [
        if (_userId != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ElevatedButton.icon(
              onPressed: _showAddReviewSheet,
              icon: const Icon(Icons.rate_review_outlined),
              label: const Text('Deixar uma avaliação'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
                backgroundColor: kButtonColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        const Divider(height: 1),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('destinations')
              .doc(widget.destinationId)
              .collection('reviews')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              // ⭐ ALTERAÇÃO AQUI: Trocado Center por Align com Padding ⭐
              return const Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: 40.0), // Espaçamento do topo
                  child: Text(
                    "Ainda não há avaliações.\nSeja o primeiro a avaliar!",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              );
            }
            final reviews = snapshot.data!.docs.map((doc) => Review.fromFirestore(doc)).toList();
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                return _buildReviewCard(reviews[index]);
              },
            );
          },
        ),
      ],
    );
  }
  Widget _buildReviewCard(Review review) {
    // ... (código de _buildReviewCard permanece o mesmo)
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(backgroundColor: kButtonColor, foregroundColor: Colors.white, child: Icon(Icons.person)),
              const SizedBox(width: 12),
              Expanded(child: Text(review.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              _buildRatingStars(review.rating),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Text(review.comment, style: TextStyle(color: Colors.grey[800], fontSize: 15, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    // ... (código de _buildRatingStars permanece o mesmo)
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 20,
        );
      }),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle, Color iconColor) {
    // ... (código de _buildInfoTile permanece o mesmo)
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade200)
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor, size: 28),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
      ),
    );
  }
}