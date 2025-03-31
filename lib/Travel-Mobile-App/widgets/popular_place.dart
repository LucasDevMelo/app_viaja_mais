import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_viaja_mais/Travel-Mobile-App/models/travel_model.dart';

class PopularPlace extends StatefulWidget {
  final TravelDestination destination;

  const PopularPlace({super.key, required this.destination});
  @override
  State<PopularPlace> createState() => _PopularPlaceState();
}

class _PopularPlaceState extends State<PopularPlace> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<TravelDestination> destinations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDestinations();
  }

  Future<void> fetchDestinations() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('destinations').get();

      List<TravelDestination> fetchedDestinations = querySnapshot.docs.map((doc) {
        return TravelDestination.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }).toList();

      setState(() {
        destinations = fetchedDestinations;
        isLoading = false;
      });
    } catch (e) {
      print("Erro ao buscar destinos: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : destinations.isEmpty
        ? const Center(child: Text("Nenhum destino encontrado."))
        : ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: destinations.length,
      itemBuilder: (context, index) {
        return destinationCard(destinations[index]);
      },
    );
  }

  Widget destinationCard(TravelDestination destination) {
    String rate = _calculateAverageRating(destination.comments);

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Positioned(
          bottom: 10,
          right: 20,
          left: 20,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12.withOpacity(0.1),
                  spreadRadius: 5,
                  blurRadius: 5,
                ),
              ],
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Container(
            height: 210,
            width: MediaQuery.of(context).size.width * 0.75,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              image: DecorationImage(
                fit: BoxFit.cover,
                image: _getImage(destination.imageUrls),
              ),
            ),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  color: Colors.black.withOpacity(0.7),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            destination.name,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                destination.location,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 22,
                            color: Colors.amber[800],
                          ),
                          const SizedBox(width: 5),
                          Text(
                            rate,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Calcula a média das avaliações
  String _calculateAverageRating(List<Comment> comments) {
    if (comments.isEmpty) return "-";

    List<double> ratings = comments
        .where((comment) => comment.rating != null)
        .map((comment) => comment.rating!)
        .toList();

    if (ratings.isEmpty) return "-";

    double average = ratings.reduce((a, b) => a + b) / ratings.length;
    return average.toStringAsFixed(1);
  }

  // Obtém a imagem com fallback
  ImageProvider _getImage(List<String> imageUrls) {
    if (imageUrls.isNotEmpty && imageUrls[0].isNotEmpty) {
      return NetworkImage(imageUrls[0]);
    }
    return const AssetImage("assets/img/default.jpg");
  }
}
