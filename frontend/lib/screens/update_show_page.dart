import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class UpdateShowPage extends StatefulWidget {
  final int showId;  // ID du show à mettre à jour

  const UpdateShowPage({super.key, required this.showId});

  @override
  _UpdateShowPageState createState() => _UpdateShowPageState();
}

class _UpdateShowPageState extends State<UpdateShowPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedCategory = 'movie';
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _fetchShowDetails();
  }

  // Récupérer les détails du show pour pré-remplir les champs
  Future<void> _fetchShowDetails() async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/shows/${widget.showId}'));

    if (response.statusCode == 200) {
      var show = jsonDecode(response.body);
      setState(() {
        _titleController.text = show['title'];
        _descriptionController.text = show['description'];
        _selectedCategory = show['category'];
        // Optionnellement, charge l'image existante si nécessaire
        // _imageFile = File(show['image']);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load show details")),
      );
    }
  }

  // Sélectionner une nouvelle image
  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  // Envoyer la mise à jour au backend
  Future<void> _updateShow() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields are required!")),
      );
      return;
    }

    setState(() => _isUploading = true);

    var request = http.MultipartRequest('PUT', Uri.parse('${ApiConfig.baseUrl}/shows/${widget.showId}'));
    request.fields['title'] = _titleController.text;
    request.fields['description'] = _descriptionController.text;
    request.fields['category'] = _selectedCategory;

    if (_imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath('image', _imageFile!.path));
    }

    var response = await request.send();
    setState(() => _isUploading = false);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Show updated successfully!")),
      );
      Navigator.pop(context, true); // Retourner à la page précédente avec succès
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update show")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Update Show"), backgroundColor: Colors.blueAccent),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Description"),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: const [
                DropdownMenuItem(value: "movie", child: Text("Movie")),
                DropdownMenuItem(value: "anime", child: Text("Anime")),
                DropdownMenuItem(value: "serie", child: Text("Series")),
              ],
              onChanged: (value) => setState(() => _selectedCategory = value!),
              decoration: const InputDecoration(labelText: "Category"),
            ),
            const SizedBox(height: 10),
            _imageFile == null
                ? const Center(child: Text("No Image Selected"))
                : Image.file(_imageFile!, height: 150, fit: BoxFit.cover),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.image),
                  label: const Text("Gallery"),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera),
                  label: const Text("Camera"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _isUploading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _updateShow,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                child: const Text("Update Show", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
