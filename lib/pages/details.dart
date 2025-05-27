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
    fetchRestaurantDetail();
    _loadFavoriteStatus();
  }

  Future<void> fetchRestaurantDetail() async {
    final response = await http.get(
      Uri.parse('https://restaurant-api.dicoding.dev/detail/${widget.id}'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        restaurant = data['restaurant'];
      });
    }
  }

  _loadFavoriteStatus() async {
  final prefs = await SharedPreferences.getInstance();
  final username = prefs.getString('username');
  if (username == null) {
    setState(() {
      isFavorited = false;
    });
    return;
  }

  var box = await Hive.openBox('favorites_$username');
  setState(() {
    isFavorited = box.containsKey(widget.id);
  });
}


  _toggleFavorite() async {
  final prefs = await SharedPreferences.getInstance();
  final username = prefs.getString('username');
  if (username == null) return;

  var box = await Hive.openBox('favorites_$username');

  if (isFavorited) {
    await box.delete(widget.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Berhasil menghapus dari favorit"),
        backgroundColor: Colors.red,
      ),
    );
  } else {
    // Simpan data lengkap restoran ke Hive
    await box.put(widget.id, restaurant);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Berhasil menyimpan ke favorit"),
        backgroundColor: Colors.green,
      ),
    );
  }

  setState(() {
    isFavorited = !isFavorited;
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Restaurant Detail",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF141E30),
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: restaurant == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      'https://restaurant-api.dicoding.dev/images/small/${restaurant!["pictureId"]}',
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return SizedBox(
                          height: 220,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: const Color(0xFF141E30),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 220,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.broken_image,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          restaurant!['name'],
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF141E30),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isFavorited ? Icons.favorite : Icons.favorite_border,
                          color: Colors.red,
                          size: 32,
                        ),
                        onPressed: _toggleFavorite,
                        tooltip: isFavorited
                            ? "Hapus dari favorit"
                            : "Tambah ke favorit",
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${restaurant!['city']} • Rating: ${restaurant!['rating']}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    restaurant!['description'],
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}
