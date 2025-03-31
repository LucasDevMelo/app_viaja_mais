import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:app_viaja_mais/Travel-Mobile-App/models/travel_model.dart';

class AddTravelDestinationScreen extends StatefulWidget {
  const AddTravelDestinationScreen({super.key});

  @override
  _AddTravelDestinationScreenState createState() => _AddTravelDestinationScreenState();
}

class _AddTravelDestinationScreenState extends State<AddTravelDestinationScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final locationController = TextEditingController();
  final descriptionController = TextEditingController();
  final hoursController = TextEditingController();
  final durationController = TextEditingController();
  final ageController = TextEditingController();
  final imageUrlController = TextEditingController();

  // Adicionar um destino ao Firestore
  void addDestination() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        DocumentReference docRef = FirebaseFirestore.instance.collection('destinations').doc();

        // Criar o objeto usando o modelo existente
        final destination = TravelDestination(
          id: docRef.id,
          name: nameController.text,
          description: descriptionController.text,
          location: locationController.text,
          imageUrls: imageUrlController.text.split(',').map((e) => e.trim()).toList(), // Remove espaços extras
          hours: hoursController.text,
          duration: durationController.text,
          age: int.tryParse(ageController.text) ?? 0, // Evita erro caso o usuário insira um valor inválido
          comments: [], // Inicialmente, sem comentários
        );

        // Salvar no Firestore
        await docRef.set(destination.toJson());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Destino adicionado com sucesso!')),
        );

        // Resetar o formulário
        _formKey.currentState?.reset();
        _clearFields();

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar destino: $e')),
        );
      }
    }
  }

  // Limpa os campos após adicionar um destino
  void _clearFields() {
    nameController.clear();
    locationController.clear();
    descriptionController.clear();
    hoursController.clear();
    durationController.clear();
    ageController.clear();
    imageUrlController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Adicionar Destino'),
        backgroundColor: Colors.amber,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(nameController, 'Nome'),
              _buildTextField(locationController, 'Localização'),
              _buildTextField(descriptionController, 'Descrição'),
              _buildTextField(hoursController, 'Horário'),
              _buildTextField(durationController, 'Duração'),
              _buildTextField(ageController, 'Idade recomendada', isNumber: true),
              _buildTextField(imageUrlController, 'URLs das Imagens (separadas por vírgula)'),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: addDestination,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                child: const Text('Adicionar Destino', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget para construir os campos de entrada de texto
  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.amber),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.yellow),
          ),
        ),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor insira $label';
          }
          if (isNumber && int.tryParse(value) == null) {
            return 'Insira um número válido';
          }
          return null;
        },
      ),
    );
  }
}
