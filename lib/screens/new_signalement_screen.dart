import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import 'package:citycare_mobile/config.dart';
import 'package:citycare_mobile/models/user_model.dart';

class NewSignalementScreen extends StatefulWidget {
  final UserModel user;
  const NewSignalementScreen({super.key, required this.user});

  @override
  State<NewSignalementScreen> createState() => _NewSignalementScreenState();
}

class _NewSignalementScreenState extends State<NewSignalementScreen> {
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs
  final TextEditingController _titreController = TextEditingController();
  final TextEditingController _lieuController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  String? _webImagePath;
  String? _selectedType;
  File? _image;
  final ImagePicker _picker = ImagePicker();

  final List<String> _types = [
    'Eau & Assainissement',
    'Éclairage public',
    'Voirie / Routes',
    'Déchets',
    'Autre',
  ];

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
    );

    if (pickedFile != null) {
      setState(() {
        if (kIsWeb) {
          _webImagePath = pickedFile.path;
        } else {
          _image = File(pickedFile.path);
        }
      });
    }
  }

  @override
 @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fond légèrement grisé pour faire ressortir les champs blancs
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A73B8),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Nouveau Signalement",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Petit bandeau de description sous le header fixe
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: const Color(0xFF1A73B8),
              child: const Text(
                "Aidez-nous à améliorer votre ville en décrivant précisément le problème rencontré.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("Informations générales"),
                    const SizedBox(height: 15),

                    _buildTextField(
                      controller: _titreController,
                      label: "Titre du problème",
                      hint: "Ex: Fuite d'eau importante",
                      icon: Icons.edit_note_rounded,
                    ),
                    const SizedBox(height: 15),

                    _buildDropdown(),
                    const SizedBox(height: 15),

                    _buildTextField(
                      controller: _lieuController,
                      label: "Lieu / Adresse",
                      hint: "Ex: Rue 14, en face de la mosquée",
                      icon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 30),

                    _buildSectionTitle("Détails & Photo"),
                    const SizedBox(height: 15),

                    _buildTextField(
                      controller: _descController,
                      label: "Description",
                      hint: "Donnez plus de détails...",
                      icon: Icons.description_outlined,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 20),

                    _buildPhotoSelector(),

                    const SizedBox(height: 40),

                    // Bouton avec ombre pour le relief
                    Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1A73B8).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A73B8),
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Envoyer le signalement",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Modifier également le _buildTextField pour qu'il soit bien blanc sur le fond gris
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // Toujours blanc ici
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: (value) => value == null || value.isEmpty ? "Requis" : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF0F4C75)),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
          prefixIcon: Icon(icon, color: const Color(0xFF1A73B8), size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  // --- Widgets Utilitaires ---

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFF1A73B8),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(15),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedType,
        validator: (value) => value == null ? "Veuillez choisir un type" : null,
        decoration: const InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.category_outlined,
            color: Color(0xFF1A73B8),
            size: 22,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        ),
        hint: const Text("Type de signalement", style: TextStyle(fontSize: 14)),
        items: _types.map((String type) {
          return DropdownMenuItem(
            value: type,
            child: Text(type, style: const TextStyle(fontSize: 14)),
          );
        }).toList(),
        onChanged: (value) => setState(() => _selectedType = value),
      ),
    );
  }

  Widget _buildPhotoSelector() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 180,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: (_image != null || (kIsWeb && _webImagePath != null))
            ? Stack(
                fit: StackFit.expand,
                children: [
                  kIsWeb
                      ? Image.network(_webImagePath!, fit: BoxFit.cover)
                      : Image.file(_image!, fit: BoxFit.cover),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _image = null;
                        _webImagePath = null;
                      }),
                      child: const CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 15,
                        child: Icon(Icons.close, color: Colors.red, size: 18),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.blue[300],
                    size: 40,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Prendre une photo du problème",
                    style: TextStyle(
                      color: Color(0xFF1A73B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF1A73B8)),
        ),
      );

      try {
        var uri = Uri.parse("${AppConfig.baseUrl}/api/signalements");
        http.Response response;

        if (_image == null && _webImagePath == null) {
          response = await http
              .post(
                uri,
                headers: {"Content-Type": "application/json"},
                body: jsonEncode({
                  'user_id': widget.user.id.toString(),
                  'titre': _titreController.text,
                  'type_signalement': _selectedType,
                  'description': _descController.text,
                  'lieu': _lieuController.text,
                }),
              )
              .timeout(const Duration(seconds: 10));
        } else {
          var request = http.MultipartRequest("POST", uri);
          request.fields['user_id'] = widget.user.id.toString();
          request.fields['titre'] = _titreController.text;
          request.fields['type_signalement'] = _selectedType!;
          request.fields['description'] = _descController.text;
          request.fields['lieu'] = _lieuController.text;

          if (kIsWeb && _webImagePath != null) {
            // Logique Web pour Multipart si nécessaire
          } else if (_image != null) {
            request.files.add(
              await http.MultipartFile.fromPath('photo', _image!.path),
            );
          }

          var streamedResponse = await request.send();
          response = await http.Response.fromStream(streamedResponse);
        }

        if (mounted) Navigator.pop(context); // Ferme le spinner

        if (response.statusCode == 201 || response.statusCode == 200) {
          _showSuccessDialog();
        } else {
          _showErrorSnackBar("Erreur lors de l'envoi (${response.statusCode})");
        }
      } catch (e) {
        if (mounted) Navigator.pop(context);
        _showErrorSnackBar("Erreur réseau : $e");
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 20),
            const Text(
              "Merci !",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Signalement envoyé avec succès. Nos équipes vont le traiter rapidement.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73B8),
              ),
              child: const Text(
                "Retour à l'accueil",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
