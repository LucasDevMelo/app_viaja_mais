import 'package:flutter/material.dart';
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
      height: 105,
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

    double totalRating = comments.fold(0.0, (sum, comment) => sum + (comment.rating ?? 0.0));
    return totalRating / comments.length;
  }

  // Widget para exibir a imagem
  Widget _buildImageSection() {
    return Container(
      height: 95,
      width: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        image: destination.imageUrls.isNotEmpty
            ? DecorationImage(
          fit: BoxFit.cover,
          image: NetworkImage(destination.imageUrls[0]),
        )
            : const DecorationImage(
          fit: BoxFit.cover,
          image: AssetImage("assets/images/placeholder.jpg"), // Imagem padrão
        ),
      ),
    );
  }

  // Widget para exibir as informações
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
          Row(
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: averageRating > 0 ? averageRating.toStringAsFixed(1) : "N/A",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    TextSpan(
                      text: " ($totalReviews comentários)",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.black.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
