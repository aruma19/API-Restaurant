import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:latres_tpm/models/Restaurant.dart';
import 'details.dart';
import 'package:shared_preferences/shared_preferences.dart';


class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<Restaurants> favorites = [];
  bool isLoading = true;
  String? username;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    username = prefs.getString('username');
    if (username == null) {
      setState(() {
        favorites = [];
        isLoading = false;
      });
      return;
    }

    var box = await Hive.openBox('favorites_$username');
    setState(() {
      favorites = box.values
          .map((e) => Restaurants.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      isLoading = false;
    });
  }

  Future<void> _removeFavorite(Restaurants restaurant) async {
    if (username == null) return;
    var box = await Hive.openBox('favorites_$username');
    await box.delete(restaurant.id);
    setState(() {
      favorites.removeWhere((r) => r.id == restaurant.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Favorites",
        style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF141E30),
        centerTitle: true,
        iconTheme: const IconThemeData(
        color: Colors.white,
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : favorites.isEmpty
              ? const Center(child: Text("Tidak ada favorit"))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: favorites.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final restaurant = favorites[index];
                    return Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DetailPage(id: restaurant.id),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  'https://restaurant-api.dicoding.dev/images/small/${restaurant.pictureId}',
                                  width: 120,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    width: 120,
                                    height: 90,
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.broken_image,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      restaurant.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          restaurant.city,
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.favorite,
                                            color: Colors.redAccent,
                                          ),
                                          onPressed: () {
                                            _removeFavorite(restaurant);
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

