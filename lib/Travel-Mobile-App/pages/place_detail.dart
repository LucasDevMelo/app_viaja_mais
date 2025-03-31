import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:app_viaja_mais/Travel-Mobile-App/const.dart';
import 'package:app_viaja_mais/Travel-Mobile-App/models/travel_model.dart';

class PlaceDetailScreen extends StatefulWidget {
  final String destinationId;
  const PlaceDetailScreen({super.key, required this.destinationId});

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  TravelDestination? destination;
  bool isLoading = true;
  PageController pageController = PageController();
  int currentPage = 0;

  @override
  void initState() {
    super.initState();
    fetchDestinationData();
  }

  Future<void> fetchDestinationData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('destinations')
          .doc(widget.destinationId)
          .get();

      if (doc.exists) {
        setState(() {
          destination = TravelDestination.fromJson(doc.data() as Map<String, dynamic>);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (error) {
      print("Erro ao buscar destino: $error");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (destination == null) {
      return const Scaffold(
        body: Center(child: Text("Destino não encontrado")),
      );
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leadingWidth: 64,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Container(
              margin: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: const Icon(Icons.arrow_back_ios_new),
            ),
          ),
        ),
        centerTitle: true,
        title: const Text(
          "Detalhes",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black12),
            ),
            child: const Icon(Icons.bookmark_outline, size: 30),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 400,
                child: PageView.builder(
                  controller: pageController,
                  itemCount: destination!.imageUrls.length,
                  onPageChanged: (index) {
                    setState(() {
                      currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.network(
                        destination!.imageUrls[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              DefaultTabController(
                length: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TabBar(
                      labelColor: blueTextColor,
                      labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      unselectedLabelColor: Colors.black,
                      indicatorColor: blueTextColor,
                      tabs: [
                        Tab(text: 'Visão geral'),
                        Tab(text: 'Detalhes'),
                        Tab(text: 'Avaliações'),
                      ],
                    ),
                    SizedBox(
                      height: 400,
                      child: TabBarView(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.access_time),
                                title: Text("Horários: ${destination!.hours}"),
                              ),
                              ListTile(
                                leading: const Icon(Icons.timer),
                                title: Text("Duração: ${destination!.duration}"),
                              ),
                              ListTile(
                                leading: const Icon(Icons.group),
                                title: Text("Idades: ${destination!.age}"),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text(
                              destination!.description,
                              style: const TextStyle(color: Colors.black54, fontSize: 14, height: 1.5),
                            ),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: destination!.comments.length,
                            itemBuilder: (context, index) {
                              final comment = destination!.comments[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(comment.userImage),
                                ),
                                title: Text(comment.userName),
                                subtitle: Text(comment.comment),
                                trailing: Text('${comment.rating} ★'),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
