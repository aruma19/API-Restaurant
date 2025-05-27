import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DetailPage extends StatefulWidget {
  final String id;
  const DetailPage({super.key, required this.id});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  Map? restaurant;
  bool isFavorited = false;

  @override
  void initState() {
    super.initState();
    _initDetail();
  }

  Future<void> _initDetail() async {
    await fetchRestaurantDetail();
    await _loadFavoriteStatus();
  }

  Future<void> fetchRestaurantDetail() async {
    final response = await http.get(Uri.parse('https://restaurant-api.dicoding.dev/detail/${widget.id}'));
    if (response.statusCode == 200) {
      setState(() {
        restaurant = json.decode(response.body)['restaurant'];
      });
    }
  }

  Future<void> _loadFavoriteStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    if (username == null) return;

    final box = await Hive.openBox('favorites_$username');
    setState(() => isFavorited = box.containsKey(widget.id));
  }

  Future<void> _toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    if (username == null) return;

    final box = await Hive.openBox('favorites_$username');

    setState(() => isFavorited = !isFavorited);
    if (isFavorited) {
      await box.put(widget.id, restaurant);
      _showSnackBar("Berhasil menyimpan ke favorit", Colors.green);
    } else {
      await box.delete(widget.id);
      _showSnackBar("Berhasil menghapus dari favorit", Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Restaurant Detail", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF141E30),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: restaurant == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildImage(),
                  const SizedBox(height: 20),
                  _buildHeader(),
                  const SizedBox(height: 8),
                  Text(
                    '${restaurant!['city']} • Rating: ${restaurant!['rating']}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    restaurant!['description'],
                    style: const TextStyle(fontSize: 16, height: 1.5),
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildImage() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        'https://restaurant-api.dicoding.dev/images/small/${restaurant!["pictureId"]}',
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                  : null,
              color: const Color(0xFF141E30),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          height: 220,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image, size: 80, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            restaurant!['name'],
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF141E30)),
          ),
        ),
        IconButton(
          icon: Icon(isFavorited ? Icons.favorite : Icons.favorite_border, color: Colors.red, size: 32),
          onPressed: _toggleFavorite,
          tooltip: isFavorited ? "Hapus dari favorit" : "Tambah ke favorit",
        ),
      ],
    );
  }
}
