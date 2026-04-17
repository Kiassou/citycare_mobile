import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:citycare_mobile/config.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ManageNewsScreen extends StatefulWidget {
  const ManageNewsScreen({super.key});

  @override
  _ManageNewsScreenState createState() => _ManageNewsScreenState();
}

class _ManageNewsScreenState extends State<ManageNewsScreen> {
  List allNews = [];
  bool isLoading = false;
  XFile? _pickedFile;
  Uint8List? _webImage;

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  // --- LOGIQUE API ---

 Future<void> _fetchNews() async {
    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/news'),
      );


      print("CODE STATUT: ${response.statusCode}");

      if (response.statusCode == 200) {
        setState(() {
          allNews = jsonDecode(response.body);
        });
      }
    } catch (e) {
      print("ERREUR CONNEXION: $e");
    }

    setState(() => isLoading = false);
  }
  Future<void> _publishNews(String title, String content) async {
    if (title.isEmpty || content.isEmpty) return;

    setState(() => isLoading = true);
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.baseUrl}/api/news'),
      );
      request.fields['title'] = title;
      request.fields['content'] = content;

      if (_pickedFile != null) {
        var bytes = await _pickedFile!.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: _pickedFile!.name,
          ),
        );
      }

      var response = await http.Response.fromStream(await request.send());

      if (response.statusCode == 201) {
        if (mounted) Navigator.pop(context); // Ferme le modal d'ajout
        _showSuccessDialog("Votre actualité a été publiée et est maintenant visible par les citoyens.");
        setState(() {
          _pickedFile = null;
          _webImage = null;
        });
        _fetchNews();
      }
    } catch (e) {
      debugPrint("Erreur: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // --- DIALOGUES DE CONFIRMATION ---

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false, // L'utilisateur doit cliquer sur OK
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text("Succès"),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "OK",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI MODALS ---

  void _showAddModal() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Nouvelle Actualité",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final img = await picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (img != null) {
                    var bytes = await img.readAsBytes();
                    setModalState(() {
                      _webImage = bytes;
                      _pickedFile = img;
                    });
                  }
                },
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: _pickedFile == null
                      ? const Icon(
                          Icons.add_a_photo,
                          size: 40,
                          color: Colors.blue,
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: kIsWeb
                              ? Image.memory(_webImage!, fit: BoxFit.cover)
                              : Image.file(
                                  File(_pickedFile!.path),
                                  fit: BoxFit.cover,
                                ),
                        ),
                ),
              ),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: "Titre"),
              ),
              TextField(
                controller: contentCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Contenu"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () => _publishNews(titleCtrl.text, contentCtrl.text),
                child: const Text(
                  "Publier maintenant",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showListForEdit() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              "Modifier une actualité",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: allNews.length,
              itemBuilder: (context, i) => ListTile(
                leading: const Icon(Icons.article),
                title: Text(allNews[i]['title']),
                trailing: const Icon(Icons.edit, color:  Colors.orange),
                onTap: () =>
                    _showEditDialog(allNews[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _showEditDialog(Map news) {
    final titleCtrl = TextEditingController(text: news['title']);
    final contentCtrl = TextEditingController(text: news['content']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Modifier l'actualité"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: "Titre"),
            ),
            TextField(
              controller: contentCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Contenu"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              final response = await http.put(
                Uri.parse('${AppConfig.baseUrl}/api/news/${news['id']}'),
                headers: {"Content-Type": "application/json"},
                body: jsonEncode({
                  "title": titleCtrl.text,
                  "content": contentCtrl.text,
                }),
              );
              if (response.statusCode == 200) {
                Navigator.pop(context);
                _showSuccessDialog("Actualité mise à jour !");
                _fetchNews();
              }
            },
            child: const Text("Sauvegarder"),
          ),
        ],
      ),
    );
  }

  void _showListForDelete() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              "Supprimer une actualité",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: allNews.length,
              itemBuilder: (context, i) => ListTile(
                leading: const Icon(Icons.article),
                title: Text(allNews[i]['title']),
                trailing: const Icon(Icons.delete, color: Colors.red),
                onTap: () =>
                    _confirmDelete(allNews[i]['id'], allNews[i]['title']),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(int id, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmation"),
        content: Text("Supprimer '$title' ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Non"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final res = await http.delete(
                Uri.parse('${AppConfig.baseUrl}/api/news/$id'),
              );
              if (res.statusCode == 200) {
                Navigator.pop(context); // Ferme confirm
                Navigator.pop(context); // Ferme list modal
                _showSuccessDialog("Supprimé !");
                _fetchNews();
              }
            },
            child: const Text(
              "Oui, Supprimer",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // --- MAIN UI ---

  @override
   Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),

      appBar: AppBar(
        title: const Text(
          "Gestion des Actualités",

          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),

        backgroundColor: const Color(0xFF0F4C75),

        elevation: 0,

        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),

            Padding(
              padding: const EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          "Ajouter",

                          Icons.add_rounded,

                          Colors.green,

                          _showAddModal,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _buildActionCard(
                          "Modifier",

                          Icons.edit_rounded,

                          Colors.orange,

                          _showListForEdit,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _buildActionCard(
                          "Supprimer",

                          Icons.delete_rounded,

                          Colors.red,

                          _showListForDelete,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    "Activités Récentes",

                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 15),

                  _buildRecentList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),

      decoration: const BoxDecoration(
        color: Color(0xFF0F4C75),

        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),

      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            "Informer la Ville",

            style: TextStyle(
              color: Colors.white,

              fontSize: 24,

              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 10),

          Text(
            "Gérez ici les alertes, travaux et événements diffusés aux citoyens.",

            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String t, IconData i, Color c, VoidCallback o) {
    return InkWell(
      onTap: o,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: c.withOpacity(0.1), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Icon(i, color: c),
            const SizedBox(height: 5),
            Text(t, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentList() {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (allNews.isEmpty) {
      return const Center(child: Text("Aucune actualité trouvée"));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: allNews.length,
      itemBuilder: (context, i) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: const Icon(Icons.newspaper),
          title: Text(allNews[i]['title'] ?? ""),
          subtitle: Text(
            allNews[i]['created_at'] != null
                ? DateFormat(
                    'dd/MM HH:mm',
                  ).format(DateTime.parse(allNews[i]['created_at']))
                : "",
          ),
        ),
      ),
    );
  }
}
