import 'dart:async'; // Importe para usar o Timer (debounce)
import 'package:app_viaja_mais/Travel-Mobile-App/pages/DestinationsByLocationScreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:app_viaja_mais/Travel-Mobile-App/models/travel_model.dart' as model;
import 'package:app_viaja_mais/Travel-Mobile-App/pages/place_detail.dart';
import 'package:app_viaja_mais/Travel-Mobile-App/const.dart';
// Importe a tela de destinos por localização que você criou:

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<model.TravelDestination> _searchResults = [];
  List<String> _uniqueLocations = [];
  bool _isLoading = false;
  bool _isLoadingLocations = true;
  String _lastSearchedTerm = "";
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchUniqueLocations();
  }

  Future<void> _fetchUniqueLocations() async {
    if (!mounted) return;
    setState(() {
      _isLoadingLocations = true;
    });
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      QuerySnapshot snapshot = await firestore.collection("destinations").get();
      Set<String> locationsSet = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey("location") && data["location"] is String && (data["location"] as String).isNotEmpty) {
          locationsSet.add(data["location"] as String);
        }
      }
      if (!mounted) return;
      setState(() {
        _uniqueLocations = locationsSet.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        _isLoadingLocations = false;
      });
    } catch (e) {
      if (!mounted) return;
      print("Erro ao buscar localizações únicas: $e");
      setState(() {
        _isLoadingLocations = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro ao carregar lista de localizações.")),
      );
    }
  }

  Future<void> _performSearch(String query) async {
    final String trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      if (!mounted) return;
      setState(() {
        _searchResults = [];
        _isLoading = false;
        _lastSearchedTerm = "";
      });
      return;
    }

    // A busca agora usará o trimmedQuery diretamente, sem converter para minúsculas.
    final String searchQuery = trimmedQuery;

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _searchResults = [];
      _lastSearchedTerm = trimmedQuery;
    });

    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Query para nome (busca por prefixo, CASE-SENSITIVE)
      QuerySnapshot nameSnapshot = await firestore
          .collection("destinations")
          .where("name", isGreaterThanOrEqualTo: searchQuery) // Busca no campo original 'name'
          .where("name", isLessThanOrEqualTo: '$searchQuery\uf8ff')
          .get();

      // Query para localização (busca por prefixo, CASE-SENSITIVE)
      QuerySnapshot locationSnapshot = await firestore
          .collection("destinations")
          .where("location", isGreaterThanOrEqualTo: searchQuery) // Busca no campo original 'location'
          .where("location", isLessThanOrEqualTo: '$searchQuery\uf8ff')
          .get();

      Set<String> uniqueIds = {};
      List<model.TravelDestination> combinedResults = [];

      for (var doc in nameSnapshot.docs) {
        if (uniqueIds.add(doc.id)) {
          combinedResults.add(model.TravelDestination.fromJson({
            'id': doc.id, ...doc.data() as Map<String, dynamic>,
          }));
        }
      }
      for (var doc in locationSnapshot.docs) {
        if (uniqueIds.add(doc.id)) {
          combinedResults.add(model.TravelDestination.fromJson({
            'id': doc.id, ...doc.data() as Map<String, dynamic>,
          }));
        }
      }
      // A ordenação dos resultados ainda pode ser case-insensitive para melhor UX visual.
      combinedResults.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      if (!mounted) return;
      setState(() {
        _searchResults = combinedResults;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      print("Erro ao buscar destinos (case-sensitive): $e"); // Comentário atualizado
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao realizar a busca: ${e.toString()}")),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Widget _buildSearchResults() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_searchResults.isEmpty && _lastSearchedTerm.isNotEmpty) {
      return Center(child: Text("Nenhum resultado encontrado para '$_lastSearchedTerm'."));
    }
    if (_searchResults.isEmpty) return const SizedBox.shrink();

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final destination = _searchResults[index];
        String? displayImageUrl;
        for (String url in destination.imageUrls) {
          if (url.startsWith("http")) {
            displayImageUrl = url;
            break;
          }
        }
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 0),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(10),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: displayImageUrl != null
                  ? Image.network(
                displayImageUrl, width: 60, height: 60, fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(width:60, height: 60, color: Colors.grey[200], child: const Icon(Icons.broken_image, size:30, color: Colors.grey)),
              )
                  : Container(width:60, height: 60, color: Colors.grey[200], child: const Icon(Icons.image_not_supported, size:30, color: Colors.grey)),
            ),
            title: Text(destination.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(destination.location),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlaceDetailScreen(destinationId: destination.id))),
          ),
        );
      },
    );
  }

  Widget _buildUniqueLocationsList() {
    if (_isLoadingLocations) return const Center(child: CircularProgressIndicator());
    if (_uniqueLocations.isEmpty) return const Center(child: Text("Nenhuma localização para explorar."));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 0, right: 0, top: 8, bottom: 12),
          child: Text(
            "Explorar por Localização",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _uniqueLocations.length,
            itemBuilder: (context, index) {
              final locationName = _uniqueLocations[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0),
                elevation: 1.5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: ListTile(
                  title: Text(locationName, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500)),
                  trailing: Icon(Iconsax.arrow_right_3, color: kButtonColor, size: 20),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DestinationsByLocationScreen(locationName: locationName)),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Buscar Destinos"),
        backgroundColor:  const Color(0xFF263892), // Certifique-se de que esta cor é a desejada ou use kButtonColor
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Pesquisar nome ou local...",
                  prefixIcon: const Icon(Iconsax.search_normal),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal:10),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _performSearch("");
                      setState(() {});
                    },
                  )
                      : null,
                ),
                onChanged: (value) {
                  if (_debounce?.isActive ?? false) _debounce!.cancel();
                  _debounce = Timer(const Duration(milliseconds: 600), () {
                    _performSearch(value);
                  });
                  setState(() {});
                },
              ),
            ),
            Expanded(
              child: _searchController.text.trim().isNotEmpty
                  ? _buildSearchResults()
                  : _buildUniqueLocationsList(),
            ),
          ],
        ),
      ),
    );
  }
}