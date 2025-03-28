import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class TravelDestination {
  final String id, name, description, location, hours, duration;
  final List<String> images;
  final int review, age;
  final double rate;

  TravelDestination({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.images,
    required this.review,
    required this.rate,
    required this.hours,
    required this.duration,
    required this.age,
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
      'hours': hours,
      'duration': duration,
      'age': age,
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
      hours: json['hours'],
      duration: json['duration'],
      age: json['age'],
    );
  }
}

final DatabaseReference databaseRef = FirebaseDatabase.instance.ref("destinations");

Future<void> saveDestination(TravelDestination destination) async {
  DatabaseReference newDestinationRef = databaseRef.push(); // Gera um ID único
  String newId = newDestinationRef.key!;

  // Criamos um novo objeto com o ID gerado
  TravelDestination newDestination = TravelDestination(
    id: newId,
    name: destination.name,
    description: destination.description,
    location: destination.location,
    images: destination.images,
    review: destination.review,
    rate: destination.rate,
    hours: destination.hours, // Novo campo
    duration: destination.duration, // Novo campo
    age: destination.age, // Novo campo
  );

  await newDestinationRef.set(newDestination.toJson());
}

Future<List<TravelDestination>> fetchDestinations() async {
  DatabaseEvent event = await databaseRef.once();
  DataSnapshot snapshot = event.snapshot;

  if (snapshot.value == null) return [];

  Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
  return data.entries.map((entry) {
    return TravelDestination.fromJson({
      'id': entry.key, // Pegamos o ID gerado pelo Firebase
      ...Map<String, dynamic>.from(entry.value),
    });
  }).toList();
}
