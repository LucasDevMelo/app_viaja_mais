import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import 'dart:convert';
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
  final hoursController = TextEditingController();
  final durationController = TextEditingController();
  final ageController = TextEditingController();
  final imageUrlController = TextEditingController();
  final quill.QuillController _quillController = quill.QuillController.basic();

  void addDestination() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        DocumentReference docRef = FirebaseFirestore.instance.collection('destinations').doc();

        final destination = TravelDestination(
          id: docRef.id,
          name: nameController.text,
          description: jsonEncode(_quillController.document.toDelta().toJson()),
          location: locationController.text,
          imageUrls: imageUrlController.text.split(',').map((e) => e.trim()).toList(),
          hours: hoursController.text,
          duration: durationController.text,
          age: ageController.text,
          comments: [],
        );

        await docRef.set(destination.toJson());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Destino adicionado com sucesso!')),
        );

        _formKey.currentState?.reset();
        _clearFields();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar destino: $e')),
        );
      }
    }
  }

  void _clearFields() {
    nameController.clear();
    locationController.clear();
    hoursController.clear();
    durationController.clear();
    ageController.clear();
    imageUrlController.clear();
    setState(() {
      _quillController.document = quill.Document();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Destino'),
        backgroundColor: const Color(0xFF263892),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(nameController, 'Nome'),
              _buildTextField(locationController, 'Localização'),
              _buildDescriptionEditor(),
              _buildTextField(hoursController, 'Horário'),
              _buildTextField(durationController, 'Duração'),
              _buildTextField(ageController, 'Idade recomendada'),
              _buildTextField(imageUrlController, 'URLs das Imagens (separadas por vírgula)'),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: addDestination,
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF263892)),
                child: const Text('Adicionar Destino', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Descrição', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            children: [
              quill.QuillToolbar.simple(configurations: QuillSimpleToolbarConfigurations(controller: _quillController)),
              SizedBox(height: 10),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: quill.QuillEditor.basic(
                  configurations: QuillEditorConfigurations(
                    controller: _quillController,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF263892)),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF263892)),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor insira $label';
          }
          return null;
        },
      ),
    );
  }
}
