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
  int selectedPage = 0;
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
    fetchDestinationsFromDB();
  }

  Future<void> fetchDestinationsFromDB() async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Consultando a coleção de destinos
      QuerySnapshot querySnapshot = await firestore.collection("destinations").get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Convertendo os documentos para objetos TravelDestination
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
            isLoading
                ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
                : hasError
                ? const Center(child: Text("Erro ao carregar dados"))
                : horizontalScrollList(popular),
            sectionHeader("Recomendados para você"),
            isLoading
                ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
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
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const Text(
            "Ver todos",
            style: TextStyle(
              fontSize: 14,
              color: blueTextColor,
            ),
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
              (index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: GestureDetector(
              onTap: () => navigateToDetail(list[index]),
              child: PopularPlace(destination: list[index]),
            ),
          ),
        ),
      ),
    );
  }

  Widget verticalList(List<model.TravelDestination> list) {
    return Column(
      children: List.generate(
        list.length,
            (index) => Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: GestureDetector(
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
                selectedPage = index;
              });
            },
            child: Icon(
              icons[index],
              size: 32,
              color: selectedPage == index
                  ? Colors.white
                  : Colors.white.withOpacity(0.4),
            ),
          ),
        ),
      ),
    );
  }

  AppBar headerParts() {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF263892),
      title: const Text(
        "Todas as cidades",
        style: TextStyle(color: Colors.white),
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
        const SizedBox(width: 15),
      ],
    );
  }
}
