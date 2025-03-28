import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class TravelDestination {
  final String id, name, description, location;
  final List<String> images;
  final int review;
  final double rate;

  TravelDestination({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.images,
    required this.review,
    required this.rate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'location': location,
      'images': images,
      'review': review,
      'rate': rate,
    };
  }

  factory TravelDestination.fromJson(Map<String, dynamic> json) {
    return TravelDestination(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      location: json['location'],
      images: List<String>.from(json['images']),
      review: json['review'],
      rate: json['rate'].toDouble(),
    );
  }
}

final DatabaseReference databaseRef = FirebaseDatabase.instance.ref("destinations");

Future<void> saveDestination(TravelDestination destination) async {
  await databaseRef.child(destination.id).set(destination.toJson());
}

Future<List<TravelDestination>> fetchDestinations() async {
  DatabaseEvent event = await databaseRef.once();
  DataSnapshot snapshot = event.snapshot;

  if (snapshot.value == null) return [];

  Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
  return data.entries.map((entry) {
    return TravelDestination.fromJson(Map<String, dynamic>.from(entry.value));
  }).toList();
}

class PlaceDetailScreen extends StatefulWidget {
  final String destinationId;
  const PlaceDetailScreen({super.key, required this.destinationId});

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  TravelDestination? destination;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDestination();
  }

  Future<void> fetchDestination() async {
    DatabaseEvent event = await databaseRef.child(widget.destinationId).once();
    DataSnapshot snapshot = event.snapshot;
    if (snapshot.value != null) {
      setState(() {
        destination = TravelDestination.fromJson(Map<String, dynamic>.from(snapshot.value as Map));
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalhes"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : destination == null
          ? const Center(child: Text("Destino não encontrado"))
          : Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(destination!.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(destination!.location, style: const TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 10),
            Text(destination!.description),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: destination!.images.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Image.network(destination!.images[index], width: 200, height: 200, fit: BoxFit.cover),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
