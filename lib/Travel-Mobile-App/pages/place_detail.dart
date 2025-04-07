import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:convert';
import 'package:app_viaja_mais/Travel-Mobile-App/models/travel_model.dart';
import 'package:flutter_quill/flutter_quill.dart';

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
  quill.QuillController _quillController = quill.QuillController.basic();

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
          _quillController = quill.QuillController(
            document: _convertToQuillDelta(destination!.description),
            selection: const TextSelection.collapsed(offset: 0),
          );
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

  quill.Document _convertToQuillDelta(String text) {
    try {
      final parsed = jsonDecode(text);
      if (parsed is List) {
        return quill.Document.fromJson(parsed);
      }
    } catch (e) {
      print("Erro ao converter JSON para Quill Delta: $e");
    }
    // Se falhar, retorna um documento Delta básico com o texto
    return quill.Document()..insert(0, text + "\n");
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
      appBar: AppBar(
        title: const Text("Detalhes"),
        backgroundColor: const Color(0xFF263892),
        foregroundColor: Colors.white, // ← isso muda o texto e os ícones para branco
        iconTheme: const IconThemeData(color: Colors.white), // ← reforça os ícones em branco
      ),
      body: SingleChildScrollView(
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
                    labelColor: Colors.blue,
                    labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    unselectedLabelColor: Colors.black,
                    indicatorColor: Colors.blue,
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
                          child: quill.QuillEditor.basic(
                            configurations: QuillEditorConfigurations(
                              enableInteractiveSelection: false,
                              showCursor: false,
                              controller: _quillController,
                            ),
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
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
    );
  }
}
