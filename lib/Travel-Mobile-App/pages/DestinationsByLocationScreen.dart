// destinations_by_location_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_viaja_mais/Travel-Mobile-App/models/travel_model.dart' as model;
import 'package:app_viaja_mais/Travel-Mobile-App/pages/place_detail.dart';
import 'package:app_viaja_mais/Travel-Mobile-App/const.dart'; // Para kButtonColor, se necessário

class DestinationsByLocationScreen extends StatefulWidget {
  final String locationName;
  const DestinationsByLocationScreen({super.key, required this.locationName});

  @override
  State<DestinationsByLocationScreen> createState() => _DestinationsByLocationScreenState();
}

class _DestinationsByLocationScreenState extends State<DestinationsByLocationScreen> {
  List<model.TravelDestination> _destinationsInLocation = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDestinations();
  }

  Future<void> _fetchDestinations() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      QuerySnapshot snapshot = await firestore
          .collection("destinations")
          .where("location", isEqualTo: widget.locationName) // Busca pelo nome exato da localização
          .get();

      if (!mounted) return;
      setState(() {
        _destinationsInLocation = snapshot.docs.map((doc) {
          return model.TravelDestination.fromJson({
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          });
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      print("Erro ao buscar destinos por localização (${widget.locationName}): $e");
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao carregar destinos para ${widget.locationName}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.locationName),
        backgroundColor:  const Color(0xFF263892), // Certifique-se de que esta cor é a desejada ou use kButtonColor
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        iconTheme: const IconThemeData(color: Colors.white), // Para o botão de voltar
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _destinationsInLocation.isEmpty
          ? Center(child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text("Nenhum ponto turístico encontrado para ${widget.locationName}.", textAlign: TextAlign.center),
      ))
          : ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _destinationsInLocation.length,
        itemBuilder: (context, index) {
          final destination = _destinationsInLocation[index];
          String? displayImageUrl;
          for (String url in destination.imageUrls) {
            if (url.startsWith("http")) {
              displayImageUrl = url;
              break;
            }
          }
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(10),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: displayImageUrl != null
                    ? Image.network(
                  displayImageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(width:60, height: 60, color: Colors.grey[200], child: const Icon(Icons.broken_image, size:30, color: Colors.grey)),
                )
                    : Container(width:60, height: 60, color: Colors.grey[200], child: const Icon(Icons.image_not_supported, size:30, color: Colors.grey)),
              ),
              title: Text(destination.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                destination.description.isNotEmpty
                    ? (destination.description.length > 60 ? '${destination.description.substring(0, 60)}...' : destination.description)
                    : "Sem descrição disponível.",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlaceDetailScreen(destinationId: destination.id),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}