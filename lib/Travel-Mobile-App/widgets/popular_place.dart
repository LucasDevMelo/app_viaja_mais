import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:app_viaja_mais/Travel-Mobile-App/models/travel_model.dart';

class PopularPlace extends StatelessWidget {
  final TravelDestination destination;

  const PopularPlace({super.key, required this.destination});

  @override
  Widget build(BuildContext context) {
    double averageRating = _calculateAverageRating(destination.comments);
    int totalReviews = destination.comments.length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, // Permite rolagem horizontal
      child: Container(
        height: 200,
        width: MediaQuery.of(context).size.width * 0.75,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            _buildImageSection(context),
            _buildGradientOverlay(),
            _buildInfoOverlay(averageRating, totalReviews),
          ],
        ),
      ),
    );
  }

  // Cálculo da média das avaliações
  double _calculateAverageRating(List<Comment> comments) {
    if (comments.isEmpty) return 0.0;
    double totalRating = comments.fold(0.0, (sum, comment) => sum + (comment.rating ?? 0.0));
    return totalRating / comments.length;
  }

  // Busca a URL da imagem do Firebase Storage
  Future<String> _getImageUrl(String imagePath) async {
    try {
      return await FirebaseStorage.instance.ref(imagePath).getDownloadURL();
    } catch (e) {
      print("Erro ao obter URL da imagem: $e");
      return "";
    }
  }

  // Exibe a imagem com fallback
  Widget _buildImageSection(BuildContext context) {
    if (destination.imageUrls.isEmpty) {
      return _placeholderImage();
    }

    String imageUrl = destination.imageUrls[0];

    if (imageUrl.startsWith("gs://") || imageUrl.contains("/o/")) {
      return FutureBuilder<String>(
        future: _getImageUrl(imageUrl),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _loadingImage();
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return _placeholderImage();
          }
          return _networkImage(snapshot.data!, context);
        },
      );
    } else {
      return _networkImage(imageUrl, context);
    }
  }

  // Exibe a imagem da rede com tratamento de erro
  Widget _networkImage(String url, BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Image.network(
        url,
        height: 200,
        width: MediaQuery.of(context).size.width * 0.75,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _loadingImage();
        },
        errorBuilder: (context, error, stackTrace) {
          return _placeholderImage();
        },
      ),
    );
  }

  // Overlay de gradiente para melhorar a leitura do texto
  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.6),
            ],
          ),
        ),
      ),
    );
  }

  // Exibe as informações no card, agora com rolagem
// Substitua somente a função _buildInfoOverlay pelo código abaixo:

  Widget _buildInfoOverlay(double averageRating, int totalReviews) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(15),
          bottomRight: Radius.circular(15),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: Colors.black.withOpacity(0.7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                destination.name,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      destination.location,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, size: 16, color: Colors.amber[700]),
                      const SizedBox(width: 4),
                      Text(
                        averageRating > 0 ? averageRating.toStringAsFixed(1) : "N/A",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Placeholder para erro de imagem
  Widget _placeholderImage() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.grey[300],
      ),
      child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
    );
  }

  // Placeholder para carregamento
  Widget _loadingImage() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.grey[300],
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}
