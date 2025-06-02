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
import 'ProfileScreen.dart';

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

      setState(() {
        cities = loadedCities.toList();
      });
    } catch (e) {
      print("Erro ao carregar cidades: $e");
      // Opcionalmente, defina um estado aqui para mostrar erro na UI, se necessário
    }
  }

  Future<void> fetchDestinationsFromDB() async {
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

      setState(() {
        popular = allDestinations;
        // Considere se você realmente precisa inverter para 'recomendate'
        // ou se há uma lógica/fonte diferente para recomendações
        recomendate = allDestinations.reversed.toList();
        isLoading = false;
      });
    } catch (e) {
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
      // ⭐ MODIFICADO: extendBodyBehindAppBar agora também verifica selectedIndex
      extendBodyBehindAppBar: selectedIndex == 0 && selectedCity != "Todas as cidades",
      appBar: selectedIndex == 0 ? headerParts() : null,
      body: pages[selectedIndex],
      bottomNavigationBar: bottomNavBar(),
    );
  }

  // ⭐ MODIFICADO: Lista de 'pages' atualizada com as novas telas
  List<Widget> get pages => [
    buildHomeContent(),
    const FavoritesScreen(),
    const SearchScreen(),
    const ProfileScreen(),
  ];

  Widget buildHomeContent() {
    final bool isCitySelected = selectedCity != "Todas as cidades";
    final double screenHeight = MediaQuery.of(context).size.height;
    // Ajuste a lógica de overlayTop se cityHeroCard nem sempre estiver presente
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
          child: SizedBox(
            height: screenHeight - overlayTop,
            child: Container(
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
                      padding: const EdgeInsets.only(top: 20, bottom: 80), // Adicionado preenchimento inferior para a NavBar
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
                            ? const Center(child: Text("Erro ao carregar dados"))
                            : popular.isEmpty
                            ? Center(child: Text(selectedCity == "Todas as cidades" ? "Nenhum destino popular no momento." : "Nenhum destino popular para $selectedCity."))
                            : horizontalScrollList(popular),
                        sectionHeader("Recomendados para você"),
                        const SizedBox(height: 20),
                        isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : hasError
                            ? const Center(child: Text("Erro ao carregar dados"))
                            : recomendate.isEmpty
                            ? Center(child: Text(selectedCity == "Todas as cidades" ? "Nenhuma recomendação no momento." : "Nenhuma recomendação para $selectedCity."))
                            : verticalList(recomendate),
                        const SizedBox(height: 20), // Space for content above bottom nav bar
                      ],
                    ),
                  ),
                ],
              ),
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
          // Você pode querer ocultar "Ver todos" ou fazê-lo funcionar de forma diferente
          // quando uma cidade específica é selecionada ou para diferentes seções.
          Text(
            "Ver todos", // Isso poderia navegar para uma tela mostrando todos os itens daquela seção
            style: TextStyle(fontSize: 14, color: blueTextColor),
          )
        ],
      ),
    );
  }

  Widget horizontalScrollList(List<model.TravelDestination> list) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 40, left: 10),
      child: Row(
        children: List.generate(
          list.length,
              (index) => GestureDetector(
            onTap: () => navigateToDetail(list[index]),
            child: PopularPlace(destination: list[index]),
          ),
        ),
      ),
    );
  }

  Widget verticalList(List<model.TravelDestination> list) {
    // Adicionado preenchimento para evitar sobreposição com a barra de navegação inferior
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Column(
        children: List.generate(
          list.length,
              (index) => GestureDetector(
            onTap: () => navigateToDetail(list[index]),
            child: RecommendedDestination(destination: list[index]),
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
    );
  }

  Widget bottomNavBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      decoration: BoxDecoration(
        color: kButtonColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [ // Opcional: adicionada uma sombra sutil
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
              setState(() {
                selectedIndex = index;
              });
            },
            child: Icon(
              icons[index],
              size: 32,
              color: selectedIndex == index ? Colors.white : Colors.white.withOpacity(0.6), // Opacidade ajustada para não selecionado
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
      backgroundColor: isCitySelected ? Colors.transparent : const Color(0xFF263892), // Certifique-se de que esta cor é a desejada ou use kButtonColor
      automaticallyImplyLeading: false, // Bom para a tela inicial
      title: GestureDetector(
        onTap: showCityPicker,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible( // Adicionado Flexible para evitar estouro se o nome da cidade for longo
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
            );
          },
        ),
      ],
    );
  }

  void showCityPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite que a planilha ocupe mais altura, se necessário
      builder: (context) {
        return DraggableScrollableSheet( // Torna mais flexível em altura
          expand: false,
          initialChildSize: 0.4, // Começa com 40% da altura da tela
          minChildSize: 0.2,   // Mínimo 20%
          maxChildSize: 0.6,   // Máximo 60%
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
                  // Opcional: Adicionar uma alça (grabber)
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
                      controller: scrollController, // Use o controller do DraggableScrollableSheet
                      shrinkWrap: true,
                      itemCount: cities.length,
                      itemBuilder: (context, index) {
                        final bool isSelected = cities[index] == selectedCity;
                        return ListTile(
                          title: Text(
                            cities[index],
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? kButtonColor : Colors.black87,
                            ),
                          ),
                          trailing: isSelected ? Icon(Icons.check, color: kButtonColor) : null,
                          onTap: () {
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

    // Filtra destinos populares para incluir apenas aqueles que têm URLs de imagem
    // e não são "Todas as cidades" (se "Todas as cidades" puder ser uma localização)
    for (var dest in popular.where((d) => d.location != "Todas as cidades" && d.imageUrls.isNotEmpty)) {
      if (!cityToImage.containsKey(dest.location)) {
        cityToImage[dest.location] = dest.imageUrls.first;
      }
    }
    if (cityToImage.isEmpty && popular.isNotEmpty && popular.first.imageUrls.isNotEmpty) {
      // Lógica de fallback ou imagem padrão, se necessário, embora este carrossel seja para explorar cidades
    }


    return cityToImage.entries
        .map((entry) => {'city': entry.key, 'imageUrl': entry.value})
        .toList();
  }

  Widget imageCarousel(List<Map<String, String>> cityImages) {
    if (cityImages.isEmpty) {
      return const SizedBox(
          height: 120,
          child: Center(child: Text("Nenhuma cidade para explorar no momento."))
      );
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
          // Removida a lógica isFirst e isLast para o raio da borda, pois estava causando problemas com a margem
          // Aplique um raio de borda consistente a todos os itens ou lide com as margens de forma diferente

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedCity = city;
              });
              fetchDestinationsFromDB();
            },
            child: Container(
              width: 200,
              margin: EdgeInsets.only(right: index == cityImages.length - 1 ? 0 : 10), // Adiciona margem, exceto para o último item
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15), // Raio de borda consistente
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) { // Lidar com erros de carregamento de imagem
                    print('Error loading image: $imageUrl, $exception');
                    // Você poderia exibir uma imagem provisória aqui
                  },
                ),
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15), // Raio de borda consistente
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
    // Garanta que a lista popular não esteja vazia e que o primeiro item tenha imagens
    if (popular.isEmpty || popular.first.imageUrls.isEmpty) return const SizedBox.shrink();

    final String imageUrl = popular.first.imageUrls.first;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.4, // Altura reduzida para melhor equilíbrio
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            alignment: Alignment.center, // Alterado para centralizar para um enquadramento potencialmente melhor
            errorBuilder: (context, error, stackTrace) { // Lidar com erros de carregamento de imagem
              return Container(
                color: Colors.grey[300],
                child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 50)),
              );
            },
          ),
          Container(color: Colors.black.withOpacity(0.3)), // Sobreposição de gradiente ou sólida
        ],
      ),
    );
  }
}