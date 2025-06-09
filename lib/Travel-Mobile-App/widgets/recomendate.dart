import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:app_viaja_mais/Travel-Mobile-App/models/travel_model.dart';

class RecommendedDestination extends StatelessWidget {
  final TravelDestination destination;

  const RecommendedDestination({super.key, required this.destination});

  @override
  Widget build(BuildContext context) {
    // Cálculo da média de avaliações e total de comentários
    double averageRating = _calculateAverageRating(destination.comments);
    int totalReviews = destination.comments.length;

    return Container(
      height: 90,
      margin: const EdgeInsets.only(bottom: 16,left: 15,right: 15), // <-- margem entre os cards
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      child: Row(
        children: [
          _buildImageSection(),
          const SizedBox(width: 10),
          _buildInfoSection(averageRating, totalReviews),
        ],
      ),
    );
  }

  // Função para calcular a média das avaliações
  double _calculateAverageRating(List<Comment> comments) {
    if (comments.isEmpty) return 0.0;
    double totalRating = comments.fold(0.0, (sum, comment) => sum + (comment.rating));
    return totalRating / comments.length;
  }

  // Função para buscar a URL da imagem do Firebase Storage
  Future<String> _getImageUrl(String imagePath) async {
    try {
      return await FirebaseStorage.instance.ref(imagePath).getDownloadURL();
    } catch (e) {
      print("Erro ao obter URL da imagem: $e");
      return ""; // Retorna string vazia se falhar
    }
  }

  // Widget para exibir a imagem com tratamento de erro e loading
  Widget _buildImageSection() {
    if (destination.imageUrls.isEmpty) {
      return _placeholderImage();
    }

    String imageUrl = destination.imageUrls[0];

    // Se a URL parecer ser do Firebase Storage, buscar URL real
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
          return _networkImage(snapshot.data!);
        },
      );
    } else {
      return _networkImage(imageUrl);
    }
  }

  // Função para exibir uma imagem da rede com tratamento de erro
  Widget _networkImage(String url) {
    return Container(
      height: 95,
      width: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _loadingImage();
          },
          errorBuilder: (context, error, stackTrace) {
            return _placeholderImage();
          },
        ),
      ),
    );
  }

  // Placeholder para erro de imagem
  Widget _placeholderImage() {
    return Container(
      height: 95,
      width: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey[300],
      ),
      child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
    );
  }

  // Placeholder para carregamento
  Widget _loadingImage() {
    return Container(
      height: 95,
      width: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey[300],
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  // Widget para exibir as informações do destino
  Widget _buildInfoSection(double averageRating, int totalReviews) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            destination.name,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: Colors.black,
                size: 16,
              ),
              Expanded(
                child: Text(
                  destination.location,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),

        ],
      ),
    );
  }
}
