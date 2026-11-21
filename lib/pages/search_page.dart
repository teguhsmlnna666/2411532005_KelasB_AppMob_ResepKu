import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resepku/models/recipe.dart';
import 'package:resepku/services/recipe_service.dart';
import 'package:resepku/widgets/error_view.dart';
import 'package:resepku/widgets/recipe_tile.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();

  Future<List<Recipe>>? _searchFuture;
  String _searchQuery = '';

  void _search(String query) {
    final keyword = query.trim();

    if (keyword.isEmpty) return;

    setState(() {
      _searchQuery = keyword;
      _searchFuture = context
          .read<RecipeService>()
          .searchRecipes(keyword);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Cari resep...',
            border: InputBorder.none,
          ),
          onSubmitted: _search,
        ),
      ),
      body: _searchFuture == null
          ? const Center(
              child: Text('Masukkan kata kunci untuk mencari resep.'),
            )
          : FutureBuilder<List<Recipe>>(
              future: _searchFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return ErrorView(
                    message: snapshot.error.toString(),
                    onRetry: () => _search(_searchQuery),
                  );
                }

                final recipes = snapshot.data ?? [];

                if (recipes.isEmpty) {
                  return const Center(
                    child: Text('Resep tidak ditemukan.'),
                  );
                }

                return ListView.builder(
                  itemCount: recipes.length,
                  itemBuilder: (context, index) {
                    return RecipeTile(
                      recipe: recipes[index],
                    );
                  },
                );
              },
            ),
    );
  }
}