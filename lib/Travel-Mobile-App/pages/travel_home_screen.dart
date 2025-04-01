import 'package:flutter/material.dart';
import 'package:app_viaja_mais/Travel-Mobile-App/const.dart';
import 'package:app_viaja_mais/Travel-Mobile-App/models/travel_model.dart' as model;
import 'package:app_viaja_mais/Travel-Mobile-App/pages/place_detail.dart';
import 'package:app_viaja_mais/Travel-Mobile-App/pages/add_destination_screen.dart';
import 'package:app_viaja_mais/Travel-Mobile-App/widgets/popular_place.dart';
import 'package:app_viaja_mais/Travel-Mobile-App/widgets/recomendate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  /// 🔹 Busca todas as cidades disponíveis no Firebase
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
    }
  }

  /// 🔹 Busca destinos do Firebase, filtrando pela cidade selecionada
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
      appBar: headerParts(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            sectionHeader("Popular"),
            const SizedBox(height: 20),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : hasError
                ? const Center(child: Text("Erro ao carregar dados"))
                : horizontalScrollList(popular),
            sectionHeader("Recomendados para você"),
            const SizedBox(height: 20),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : hasError
                ? const Center(child: Text("Erro ao carregar dados"))
                : verticalList(recomendate),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: bottomNavBar(),
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
          const Text(
            "Ver todos",
            style: TextStyle(fontSize: 14, color: blueTextColor),
          )
        ],
      ),
    );
  }

  Widget horizontalScrollList(List<model.TravelDestination> list) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 40),
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
    return Column(
      children: List.generate(
        list.length,
            (index) => GestureDetector(
          onTap: () => navigateToDetail(list[index]),
          child: RecommendedDestination(destination: list[index]),
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
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: kButtonColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          icons.length,
              (index) => GestureDetector(
            onTap: () {
              setState(() {
                // Trocar a página ao clicar (se necessário no futuro)
              });
            },
            child: Icon(
              icons[index],
              size: 32,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
        ),
      ),
    );
  }

  /// 🔹 AppBar com seletor de cidades
  AppBar headerParts() {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF263892),
      title: GestureDetector(
        onTap: showCityPicker,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedCity,
              style: const TextStyle(color: Colors.white),
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
              MaterialPageRoute(builder: (context) => AddTravelDestinationScreen()),
            );
          },
        ),
      ],
    );
  }

  void showCityPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          shrinkWrap: true,
          itemCount: cities.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(cities[index]),
              onTap: () {
                setState(() {
                  selectedCity = cities[index];
                });
                fetchDestinationsFromDB();
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }
}
