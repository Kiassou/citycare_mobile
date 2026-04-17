import 'dart:io';
import 'package:citycare_mobile/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:citycare_mobile/models/user_model.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class NewSignalementScreen extends StatefulWidget {
  final UserModel user;
  const NewSignalementScreen({super.key, required this.user});

  @override
  State<NewSignalementScreen> createState() => _NewSignalementScreenState();
}

class _NewSignalementScreenState extends State<NewSignalementScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _autreDescController = TextEditingController();
  final MapController _mapController = MapController();

  // GPS
  String _currentAddress = "Recherche de la position...";
  Position? _currentPosition;
  bool _isLocationLoading = true;

  String _currentMapStyle = 'explore'; // Style par défaut

  final Map<String, String> _mapStyles = {
    'explore': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    'satellite':
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    'transit': 'https://tile.memomaps.de/tilegen/{z}/{x}/{y}.png',
    'driving': 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
  };

  String? _webImagePath;
  String? _selectedType;
  File? _image;
  final ImagePicker _picker = ImagePicker();

  /// Liste des catégories avec chemins locaux (assets)
  final List<Map<String, dynamic>> _categories = [
    {'title': 'Eau', 'image': 'assets/images/eau.png', 'color': Colors.blue},
    {
      'title': 'Éclairage',
      'image': 'assets/images/eclairage.png',
      'color': Colors.amber,
    },
    {
      'title': 'Voirie',
      'image': 'assets/images/voirie.png',
      'color': Colors.grey,
    },
    {
      'title': 'Accident',
      'image': 'assets/images/accident.png',
      'color': Colors.redAccent,
    },
    {
      'title': 'Sécurité',
      'image': 'assets/images/securite.png',
      'color': Colors.deepOrange,
    },
    {
      'title': 'Déchets',
      'image': 'assets/images/dechets.png',
      'color': Colors.green,
    },
    {
      'title': 'Météo',
      'image': 'assets/images/meteo.png',
      'color': Colors.lightBlueAccent,
    },
    {
      'title': 'Autre',
      'image': 'assets/images/autre.png',
      'color': Colors.blueGrey,
    },
  ];

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

Future<void> _determinePosition() async {
    if (!mounted) return;
    setState(() => _isLocationLoading = true);

    try {
      // 1. Permissions et Services
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _currentAddress = "Veuillez activer le GPS";
            _isLocationLoading = false;
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _currentAddress = "Permission refusée";
              _isLocationLoading = false;
            });
          }
          return;
        }
      }

      // 2. Récupération des coordonnées (On ne change rien ici, c'est bon)
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 25),
      );

      // 3. Récupération de l'adresse (ZONE CRITIQUE)
      String adresseAffichee = "Adresse introuvable";

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(const Duration(seconds: 5));

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          // On sécurise chaque champ avec ?? pour éviter le "null"
          String rue = place.street ?? "";
          String quartier = place.subLocality ?? place.locality ?? "";
          adresseAffichee = "$rue, $quartier".trim();
          if (adresseAffichee.startsWith(','))
            adresseAffichee = adresseAffichee.substring(1).trim();
        }
      } catch (e) {
        // Si l'adresse échoue, on met les coordonnées comme adresse de secours
        adresseAffichee =
            "${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
      }

      // 4. Mise à jour de l'interface
      if (mounted) {
        setState(() {
          _currentPosition = position; // LA CARTE VA S'AFFICHER ICI
          _currentAddress = adresseAffichee;
          _isLocationLoading = false;
        });
      }
    } catch (e) {
      print("Erreur GPS majeure: $e");
      if (mounted) {
        setState(() {
          _currentAddress = "Erreur de localisation";
          _isLocationLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGPSCard(),
                    const SizedBox(height: 25),
                    _buildSectionTitle(
                      "Veuillez sélectionner un type de problème.",
                    ),
                    const SizedBox(height: 15),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        bool isSelected = _selectedType == cat['title'];
                        return _buildImageCategoryCard(cat, isSelected);
                      },
                    ),
                    if (_selectedType == 'Autre') ...[
                      const SizedBox(height: 15),
                      _buildTextField(
                        controller: _autreDescController,
                        label: "Décrivez le problème",
                        hint: "Saisissez ici...",
                        icon: Icons.edit_note_rounded,
                      ),
                    ],
                    const SizedBox(height: 30),
                    _buildSectionTitle("Preuve visuelle"),
                    const SizedBox(height: 15),
                    _buildPhotoSelector(),
                    const SizedBox(height: 40),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGPSCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: _currentPosition == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_searching,
                            color: Colors.blue[300],
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Recherche de votre position...",
                            style: TextStyle(
                              color: Colors.blueGrey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Stack(
                      // On utilise un Stack pour mettre les boutons par-dessus la carte
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            ),
                            initialZoom: 15,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  _mapStyles[_currentMapStyle]!, // Utilise le style choisi
                              userAgentPackageName: 'com.citycare.app',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(
                                    _currentPosition!.latitude,
                                    _currentPosition!.longitude,
                                  ),
                                  width: 80,
                                  height: 80,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // --- LES BOUTONS DE STYLE ALIGNÉS À DROITE ---
                        Positioned(
                          right: 10,
                          top: 10,
                          bottom: 10,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // --- BOUTON RECENTRER (Nouveau) ---
                              _buildActionButton(
                                icon: Icons.my_location,
                                onTap: () {
                                  if (_currentPosition != null) {
                                    _mapController.move(
                                      LatLng(
                                        _currentPosition!.latitude,
                                        _currentPosition!.longitude,
                                      ),
                                      18.0, // On recentre avec un zoom un peu plus proche (16)
                                    );
                                  }
                                },
                              ),
                              const SizedBox(
                                height: 8,
                              ), // Un plus grand espace pour séparer
                              // --- TES BOUTONS DE STYLE EXISTANTS ---
                              _buildMapStyleButton(
                                'explore',
                                Icons.map_outlined,
                              ),
                              const SizedBox(height: 8),
                              _buildMapStyleButton(
                                'satellite',
                                Icons.satellite_alt_rounded,
                              ),
                              /*_buildMapStyleButton(
                                'transit',
                                Icons.directions_transit_outlined,
                              ),
                              const SizedBox(height: 10),
                              _buildMapStyleButton(
                                'driving',
                                Icons.directions_car_outlined,
                              ),*/
                            ],
                          ),
                        )
                      ],
                    ),
            ),
          ),
          ListTile(
            onTap: _determinePosition,
            leading: const Icon(Icons.my_location, color: Color(0xFF1A73B8)),
            title: const Text(
              "Position Actuelle",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            subtitle: _isLocationLoading
                ? const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: LinearProgressIndicator(),
                  )
                : Text(
                    _currentAddress,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
            trailing: const Icon(Icons.refresh, size: 18, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required VoidCallback onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A73B8), // Bleu CityCare
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A73B8).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: 18,
        color: Colors.white,
      ),
    ),
  );
}

  Widget _buildMapStyleButton(String style, IconData icon) {
    bool isSelected = _currentMapStyle == style;
    return GestureDetector(
      onTap: () => setState(() => _currentMapStyle = style),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1A73B8)
              : Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected ? Colors.white : Colors.blueGrey,
        ),
      ),
    );
  }

  Widget _buildImageCategoryCard(Map<String, dynamic> cat, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedType = cat['title']),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF1A73B8)
                      : Colors.transparent,
                  width: 3,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(cat['image'], fit: BoxFit.cover),
                    if (isSelected)
                      Container(
                        color: Colors.black26,
                        child: const Center(
                          child: Icon(Icons.check_circle, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            cat['title'],
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? const Color(0xFF1A73B8) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

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
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F4C75),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSelector() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 180,
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
                      ? Image.network(_webImagePath!)
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
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_rounded,
                    color: Color(0xFF1A73B8),
                    size: 40,
                  ),
                  SizedBox(height: 10),
                  Text(
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF1A73B8)),
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _submitForm,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1A73B8),
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: const Text(
        "ENVOYER LE SIGNALEMENT",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_currentPosition == null) {
      _showErrorSnackBar("Position GPS manquante.");
      return;
    }
    if (_selectedType == null) {
      _showErrorSnackBar("Sélectionnez un type.");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    try {
      var uri = Uri.parse("${AppConfig.baseUrl}/api/signalements");
      var request = http.MultipartRequest("POST", uri);

      request.fields['user_id'] = widget.user.id.toString();
      request.fields['type_signalement'] = _selectedType!;
      request.fields['description'] = _selectedType == 'Autre'
          ? _autreDescController.text
          : "Signalement $_selectedType";
      request.fields['lieu'] = _currentAddress;
      request.fields['titre'] = _selectedType!;
      request.fields['latitude'] = _currentPosition!.latitude.toString();
      request.fields['longitude'] = _currentPosition!.longitude.toString();

      // 1. On prépare l'envoi de l'image de manière sécurisée
      if (kIsWeb && _webImagePath != null) {
        // CORRECTIF WEB : On ne touche pas à la variable "_image" qui est pour le mobile
        // On utilise XFile pour lire les bytes directement
        final bytes = await XFile(_webImagePath!).readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'photo',
            bytes,
            filename: 'upload.jpg',
            contentType: MediaType(
              'image',
              'jpeg',
            ), // Optionnel mais plus propre
          ),
        );
      } else if (!kIsWeb && _image != null) {
        // MOBILE : Ici _image existe et fonctionne
        request.files.add(
          await http.MultipartFile.fromPath('photo', _image!.path),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (mounted) Navigator.pop(context);

      if (response.statusCode == 201 || response.statusCode == 200) {
        _showSuccessDialog();
      } else {
        _showErrorSnackBar("Erreur serveur : ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showErrorSnackBar("Erreur réseau");
    }
  }

  void _showSuccessDialog() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône stylisée
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 60,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Merci !",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F4C75),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Votre signalement a été transmis avec succès. Ensemble, rendons la ville meilleure.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 30),
            // Bouton Chic
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Ferme le modal
                  Navigator.pop(context); // Retourne à l'accueil
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A73B8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "CONTINUER",
                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFC72C41),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFC72C41).withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
