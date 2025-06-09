import 'package:app_viaja_mais/Travel-Mobile-App/pages/DestinationsByLocationScreen.dart';
import 'package:app_viaja_mais/Travel-Mobile-App/pages/search.dart';
import 'package:flutter/material.dart';
import 'package:app_viaja_mais/Travel-Mobile-App/const.dart'; // Assumindo que kButtonColor e blueTextColor estão aqui
import 'package:app_viaja_mais/Travel-Mobile-App/models/travel_model.dart' as model;
import 'package:app_viaja_mais/Travel-Mobile-App/pages/place_detail.dart';
import 'package:app_viaja_mais/Travel-Mobile-App/pages/add_destination_screen.dart';
import 'package:app_viaja_mais/Travel-Mobile-App/widgets/popular_place.dart';
import 'package:app_viaja_mais/Travel-Mobile-App/widgets/recomendate.dart'; // Assumindo que RecommendedDestination está aqui
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'FavoritesScreen.dart';
import 'ProfileScreen.dart'; // Corrigido para ProfileScreen.dart se for esse o nome do arquivo

// --- Telas Provisórias (Placeholder) ---
// Você pode mover estas para arquivos separados depois, se preferir


// --- Seu TravelHomeScreen Existente ---
class TravelHomeScreen extends StatefulWidget {
  const TravelHomeScreen({super.key});

  @override
  State<TravelHomeScreen> createState() => _TravelHomeScreenState();
}

class _TravelHomeScreenState extends State<TravelHomeScreen> {
  List<model.TravelDestination> popular = [];
  List<model.TravelDestination> recomendate = [];
  List<String> cities = ["Todas as cidades"];
  String selectedCity = "Todas as cidades";
  bool isLoading = true;
  bool hasError = false;

  int selectedIndex = 0;

  final List<IconData> icons = [
    Iconsax.home,
    Iconsax.heart,
    Iconsax.search_normal,
    Iconsax.user
  ];

  @override
  void initState() {
    super.initState();
    fetchCities();
    fetchDestinationsFromDB();
  }

  Future<void> fetchCities() async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      QuerySnapshot querySnapshot = await firestore.collection("destinations").get();

      Set<String> loadedCities = {"Todas as cidades"};
      for (var doc in querySnapshot.docs) {
        String city = doc["location"];
        loadedCities.add(city);
      }
      if (!mounted) return;
      setState(() {
        cities = loadedCities.toList();
      });
    } catch (e) {
      print("Erro ao carregar cidades: $e");
      // Opcionalmente, defina um estado aqui para mostrar erro na UI, se necessário
    }
  }

  Future<void> fetchDestinationsFromDB() async {
    if (!mounted) return;
    try {
      setState(() {
        isLoading = true;
        hasError = false;
      });

      FirebaseFirestore firestore = FirebaseFirestore.instance;
      Query query = firestore.collection("destinations");

      if (selectedCity != "Todas as cidades") {
        query = query.where("location", isEqualTo: selectedCity);
      }

      QuerySnapshot querySnapshot = await query.get();
      if (!mounted) return;

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          popular = [];
          recomendate = [];
          isLoading = false;
        });
        return;
      }

      List<model.TravelDestination> allDestinations = querySnapshot.docs.map((doc) {
        return model.TravelDestination.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }).toList();
      if (!mounted) return;
      setState(() {
        popular = allDestinations;
        recomendate = allDestinations.isNotEmpty ? allDestinations.reversed.toList() : [];
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        hasError = true;
      });
      print("Erro ao carregar destinos: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: selectedIndex == 0 && selectedCity != "Todas as cidades",
      appBar: selectedIndex == 0 ? headerParts() : null,
      body: pages[selectedIndex],
      bottomNavigationBar: bottomNavBar(),
    );
  }

  List<Widget> get pages => [
    buildHomeContent(),
    const FavoritesScreen(), // Certifique-se que FavoritesScreen está importado e definido
    const SearchScreen(),    // Certifique-se que SearchScreen está importado e definido
    const ProfileScreen(),   // Certifique-se que ProfileScreen está importado e definido
  ];

  Widget buildHomeContent() {
    final bool isCitySelected = selectedCity != "Todas as cidades";
    final double screenHeight = MediaQuery.of(context).size.height;
    final double overlayTop = isCitySelected && popular.isNotEmpty && popular.first.imageUrls.isNotEmpty
        ? screenHeight * 0.30
        : 0;

    return Stack(
      children: [
        // Imagem/banner da cidade
        if (isCitySelected && popular.isNotEmpty && popular.first.imageUrls.isNotEmpty) cityHeroCard(),

        // Card branco sobreposto
        Positioned(
          top: overlayTop,
          left: 0,
          right: 0,
          bottom: 0, // ⭐ CORREÇÃO: Adicionado para limitar a parte inferior
          child: Container( // ⭐ CORREÇÃO: SizedBox removido, Container diretamente
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    // O padding inferior existente de 80 deve ser suficiente.
                    // Ele garante que o conteúdo rolável tenha espaço antes da borda inferior do Container.
                    padding: const EdgeInsets.only(top: 20, bottom: 80),
                    children: [
                      if (!isCitySelected) ...[
                        sectionHeader("Explore o Brasil"),
                        const SizedBox(height: 10),
                        if (!isLoading && !hasError)
                          imageCarousel(getCityImages()),
                        const SizedBox(height: 20),
                      ],
                      sectionHeader("Popular"),
                      const SizedBox(height: 20),
                      isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : hasError
                          ? const Center(child: Text("Erro ao carregar dados populares"))
                          : popular.isEmpty
                          ? Center(child: Text(selectedCity == "Todas as cidades" ? "Nenhum destino popular no momento." : "Nenhum destino popular para $selectedCity."))
                          : horizontalScrollList(popular),
                      sectionHeader("Recomendados para você"),
                      const SizedBox(height: 20),
                      isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : hasError
                          ? const Center(child: Text("Erro ao carregar recomendações"))
                          : recomendate.isEmpty
                          ? Center(child: Text(selectedCity == "Todas as cidades" ? "Nenhuma recomendação no momento." : "Nenhuma recomendação para $selectedCity."))
                          : verticalList(recomendate),
                      // Este SizedBox dá um espaço extra no final do conteúdo rolável,
                      // antes do padding inferior do ListView ser aplicado.
                      const SizedBox(height: 20),
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

  Widget sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black),
          ),
          Text(
            "Ver todos",
            style: TextStyle(fontSize: 14, color: blueTextColor), // Assumindo que blueTextColor está em const.dart
          )
        ],
      ),
    );
  }

  Widget horizontalScrollList(List<model.TravelDestination> list) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 40, left: 10, right:10), // Adicionado right padding
      child: Row(
        children: List.generate(
          list.length,
              (index) => GestureDetector(
            onTap: () => navigateToDetail(list[index]),
            child: PopularPlace(destination: list[index]), // Assumindo que PopularPlace está em widgets
          ),
        ),
      ),
    );
  }

  Widget verticalList(List<model.TravelDestination> list) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Column(
        children: List.generate(
          list.length,
              (index) => GestureDetector(
            onTap: () => navigateToDetail(list[index]),
            child: RecommendedDestination(destination: list[index]), // Assumindo que RecommendedDestination está em widgets
          ),
        ),
      ),
    );
  }

  void navigateToDetail(model.TravelDestination destination) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaceDetailScreen(destinationId: destination.id),
      ),
    ).then((_) {
      // Opcional: Atualizar dados se algo puder mudar na tela de detalhes, como favoritos
      // fetchDestinationsFromDB(); // Descomente se necessário
    });
  }

  Widget bottomNavBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      decoration: BoxDecoration(
        color: kButtonColor, // Assumindo que kButtonColor está em const.dart
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          icons.length,
              (index) => GestureDetector(
            onTap: () {
              if (!mounted) return;
              setState(() {
                selectedIndex = index;
              });
            },
            child: Icon(
              icons[index],
              size: 32,
              color: selectedIndex == index ? Colors.white : Colors.white.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }

  AppBar headerParts() {
    final bool isCitySelected = selectedCity != "Todas as cidades";
    return AppBar(
      elevation: 0,
      backgroundColor: isCitySelected ? Colors.transparent : const Color(0xFF263892),
      automaticallyImplyLeading: false,
      title: GestureDetector(
        onTap: showCityPicker,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                selectedCity,
                style: const TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 5),
            const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add, color: Colors.white, size: 30),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddTravelDestinationScreen()),
            ).then((_) {
              // Atualizar cidades e destinos se um novo destino for adicionado
              fetchCities();
              fetchDestinationsFromDB();
            });
          },
        ),
      ],
    );
  }

  void showCityPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Para permitir cantos arredondados no Container filho
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.4,
          minChildSize: 0.2,
          maxChildSize: 0.6,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: cities.length,
                      itemBuilder: (context, index) {
                        final bool isSelected = cities[index] == selectedCity;
                        return ListTile(
                          title: Text(
                            cities[index],
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? kButtonColor : Colors.black87, // Assumindo kButtonColor
                            ),
                          ),
                          trailing: isSelected ? Icon(Icons.check, color: kButtonColor) : null, // Assumindo kButtonColor
                          onTap: () {
                            if (!mounted) return;
                            setState(() {
                              selectedCity = cities[index];
                            });
                            fetchDestinationsFromDB();
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<Map<String, String>> getCityImages() {
    final Map<String, String> cityToImage = {};
    for (var dest in popular.where((d) => d.location != "Todas as cidades" && d.imageUrls.isNotEmpty)) {
      if (!cityToImage.containsKey(dest.location)) {
        cityToImage[dest.location] = dest.imageUrls.first;
      }
    }
    return cityToImage.entries
        .map((entry) => {'city': entry.key, 'imageUrl': entry.value})
        .toList();
  }

  // Em _TravelHomeScreenState

  Widget imageCarousel(List<Map<String, String>> cityImages) {
    if (cityImages.isEmpty) {
      return const SizedBox(
          height: 120,
          child: Center(child: Text("Nenhuma cidade para explorar no momento.")));
    }
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: cityImages.length,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemBuilder: (context, index) {
          final city = cityImages[index]['city']!;
          final imageUrl = cityImages[index]['imageUrl']!;
          return GestureDetector(
            onTap: () {
              // ⭐ CORREÇÃO AQUI ⭐
              // Passando a variável 'city' que contém o nome correto da localização.
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DestinationsByLocationScreen(locationName: city),
                ),
              );
            },
            child: Container(
              width: 200,
              margin: EdgeInsets.only(right: index == cityImages.length - 1 ? 0 : 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) {
                    print('Error loading image: $imageUrl, $exception');
                  },
                ),
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ),
                  Center(
                    child: Text(
                      city,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 4,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  Widget cityHeroCard() {
    if (popular.isEmpty || popular.first.imageUrls.isEmpty) return const SizedBox.shrink();
    final String imageUrl = popular.first.imageUrls.first;
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.4,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 50)),
              );
            },
          ),
          Container(color: Colors.black.withOpacity(0.3)),
        ],
      ),
    );
  }
}
