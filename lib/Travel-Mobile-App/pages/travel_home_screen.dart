import 'package:flutter/material.dart';
import 'package:app_viaja_mais/Travel-Mobile-App/const.dart';
import 'package:app_viaja_mais/Travel-Mobile-App/pages/place_detail.dart';
import 'package:app_viaja_mais/Travel-Mobile-App/widgets/popular_place.dart';
import 'package:app_viaja_mais/Travel-Mobile-App/widgets/recomendate.dart';
import 'package:iconsax/iconsax.dart';

import '../models/travel_model.dart';

class TravelHomeScreen extends StatefulWidget {
  const TravelHomeScreen({super.key});

  @override
  State<TravelHomeScreen> createState() => _TravelHomeScreenState();
}

class _TravelHomeScreenState extends State<TravelHomeScreen> {
  int selectedPage = 0;
  List<IconData> icons = [
    Iconsax.home1,
    Iconsax.search_normal,
    Icons.confirmation_number_outlined,
    Icons.bookmark_outline,
    Icons.person_outline,
  ];

  List<TravelDestination> popular =
  myDestination.where((element) => element.category == "popular").toList();
  List<TravelDestination> recomendate =
  myDestination.where((element) => element.category == "recomend").toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: headerParts(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Popular",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    "Ver todos",
                    style: TextStyle(
                      fontSize: 14,
                      color: blueTextColor,
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 15),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 40),
              child: Row(
                children: List.generate(
                  popular.length,
                      (index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlaceDetailScreen(
                              destination: popular[index],
                            ),
                          ),
                        );
                      },
                      child: PopularPlace(
                        destination: popular[index],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Recomendados para você",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    "Ver todos",
                    style: TextStyle(
                      fontSize: 14,
                      color: blueTextColor,
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            Column(
              children: List.generate(
                recomendate.length,
                    (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlaceDetailScreen(
                            destination: recomendate[index],
                          ),
                        ),
                      );
                    },
                    child: Recomendate(
                      destination: recomendate[index],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: Container(
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
      ),
    );
  }

  AppBar headerParts() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      title: Row(
        children: [
          const Icon(Iconsax.location, color: Colors.black),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              "Rio de Janeiro",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.keyboard_arrow_down, size: 30, color: Colors.black26),
        ],
      ),
      actions: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.black12),
          ),
          padding: const EdgeInsets.all(7),
          child: const Stack(
            children: [
              Icon(Iconsax.notification, color: Colors.black, size: 30),
              Positioned(
                top: 5,
                right: 5,
                child: CircleAvatar(radius: 5, backgroundColor: Colors.red),
              ),
            ],
          ),
        ),
        const SizedBox(width: 15),
      ],
    );
  }
}
