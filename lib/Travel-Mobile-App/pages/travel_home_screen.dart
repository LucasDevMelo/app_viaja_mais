import 'package:flutter/material.dart';
import 'package:app_viaja_mais/Travel-Mobile-App/const.dart';
import 'package:app_viaja_mais/Travel-Mobile-App/models/travel_model.dart' as model;
import 'package:app_viaja_mais/Travel-Mobile-App/pages/place_detail.dart';
import 'package:app_viaja_mais/Travel-Mobile-App/widgets/popular_place.dart';
import 'package:app_viaja_mais/Travel-Mobile-App/widgets/recomendate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class TravelHomeScreen extends StatefulWidget {
  const TravelHomeScreen({super.key});

  @override
  State<TravelHomeScreen> createState() => _TravelHomeScreenState();
}

class _TravelHomeScreenState extends State<TravelHomeScreen> {
  List<model.TravelDestination> popular = [];
  List<model.TravelDestination> recomendate = [];
  int selectedPage = 0;
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
    DatabaseReference databaseRef = FirebaseDatabase.instance.ref("destinations");
    DatabaseEvent event = await databaseRef.once();
    DataSnapshot snapshot = event.snapshot;

    if (snapshot.value == null) return;

    Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
    List<model.TravelDestination> allDestinations = data.entries.map((entry) {
      return model.TravelDestination.fromJson({
        'id': entry.key,
        ...Map<String, dynamic>.from(entry.value),
      });
    }).toList();

    setState(() {
      popular = allDestinations;
      recomendate = allDestinations.reversed.toList();
    });
  }

  Future<void> showAddDestinationDialog() async {
    TextEditingController nameController = TextEditingController();
    TextEditingController locationController = TextEditingController();
    TextEditingController rateController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    TextEditingController hoursController = TextEditingController();
    TextEditingController durationController = TextEditingController();
    TextEditingController ageController = TextEditingController();

    List<XFile> selectedImages = [];
    final picker = ImagePicker();

    // Exibindo o formulário
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) { // Adicionando um State dentro do diálogo
            // Função para selecionar múltiplas imagens
            void pickImages() async {
              final pickedFiles = await picker.pickMultiImage();
              if (pickedFiles != null) {
                if (pickedFiles.length > 5) {
                  // Exibe um alerta se mais de 5 imagens forem selecionadas
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text("Limite de Imagens Excedido"),
                        content: const Text("Você pode selecionar no máximo 5 imagens."),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Fechar"),
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  setDialogState(() { // Atualiza o estado apenas do diálogo
                    selectedImages = pickedFiles;
                  });
                }
              }
            }

            return AlertDialog(
              title: const Text("Adicionar Novo Destino"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Nome"),
                    ),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(labelText: "Localização"),
                    ),
                    TextField(
                      controller: rateController,
                      decoration: const InputDecoration(labelText: "Nota (0-5)"),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: "Descrição"),
                    ),
                    TextField(
                      controller: hoursController,
                      decoration: const InputDecoration(labelText: "Horários de Funcionamento"),
                    ),
                    TextField(
                      controller: durationController,
                      decoration: const InputDecoration(labelText: "Duração"),
                    ),
                    TextField(
                      controller: ageController,
                      decoration: const InputDecoration(labelText: "Idade Mínima"),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: pickImages,
                      child: const Text("Selecionar Imagens (Máximo de 5)"),
                    ),
                  selectedImages.isNotEmpty
                      ? Wrap(
                    spacing: 8, // Espaço entre as imagens
                    children: selectedImages.map((image) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(10), // Borda arredondada nas imagens
                        child: Image.file(
                          File(image.path),
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      );
                    }).toList(),
                  )
                  : const SizedBox(), // Remove a mensagem "Nenhuma imagem selecionada"
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty ||
                        locationController.text.isEmpty ||
                        rateController.text.isEmpty ||
                        descriptionController.text.isEmpty ||
                        hoursController.text.isEmpty ||
                        durationController.text.isEmpty ||
                        ageController.text.isEmpty ||
                        selectedImages.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Por favor, preencha todos os campos e selecione ao menos uma imagem.")),
                      );
                      return;
                    }

                    List<String> imageUrls = [];
                    try {
                      for (var image in selectedImages) {
                        File imageFile = File(image.path);
                        String fileName = "destinations/${DateTime.now().millisecondsSinceEpoch}_${image.name}";
                        Reference ref = FirebaseStorage.instance.ref().child(fileName);
                        await ref.putFile(imageFile);
                        String imageUrl = await ref.getDownloadURL();
                        imageUrls.add(imageUrl);
                      }
                    } catch (e) {
                      print("Erro ao fazer upload das imagens: $e");
                      return;
                    }

                    DatabaseReference newDestinationRef =
                    FirebaseDatabase.instance.ref("destinations").push();
                    await newDestinationRef.set({
                      "name": nameController.text,
                      "location": locationController.text,
                      "description": descriptionController.text,
                      "hours": hoursController.text,
                      "duration": durationController.text,
                      "age": int.tryParse(ageController.text) ?? 0,
                      "images": imageUrls,
                      "rate": double.tryParse(rateController.text) ?? 0.0,
                    });
                    fetchDestinationsFromDB();
                    Navigator.pop(context);
                  },
                  child: const Text("Adicionar"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF263892), // Cor personalizada do botão
                  ),
                ),
              ],
            );
          },
        );
      },
    );
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
            horizontalScrollList(popular),
            sectionHeader("Recomendados para você"),
            verticalList(recomendate),
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
            child: Recomendate(destination: list[index]),
          ),
        ),
      ),
    );
  }

  void navigateToDetail(model.TravelDestination destination) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaceDetailScreen(destinationId: destination.id,),
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
      backgroundColor: Color(0xFF263892),
      title: Row(
        children: [
          const Icon(Iconsax.location, color: Colors.white),
          const SizedBox(width: 5),
          const Expanded(
            child: Text(
              "Todas as cidades",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.keyboard_arrow_down, size: 30, color: Colors.white),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add, color: Colors.white, size: 30),
          onPressed: showAddDestinationDialog,
        ),
        const SizedBox(width: 15),
      ],
    );
  }
}