
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resepku/providers/favorite_provider.dart';
import 'package:resepku/widgets/recipe_image.dart';

class FavoritePage extends StatelessWidget {
  const FavoritePage({super.key});

  Future<void> _confirmClear(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus semua favorit?'),
        content: const Text(
          'Apakah kamu yakin ingin menghapus semua resep dari favorit?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus semua'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      context.read<FavoriteProvider>().clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua resep favorit berhasil dihapus'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoriteProvider>(
      builder: (context, favorite, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Favorit Saya'),
            actions: [
              TextButton(
                onPressed: favorite.count == 0
                    ? null
                    : () => _confirmClear(context),
                child: const Text('Hapus semua'),
              ),
            ],
          ),
          body: favorite.items.isEmpty
              ? const Center(
                  child: Text('Belum ada resep favorit'),
                )
              : ListView.separated(
                  itemCount: favorite.items.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final recipe = favorite.items[index];

                    return Dismissible(
                      key: ValueKey(recipe.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      onDismissed: (direction) {
                        context.read<FavoriteProvider>().toggle(recipe);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${recipe.name} dihapus dari favorit',
                            ),
                          ),
                        );
                      },
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child: RecipeImage(
                              url: recipe.image,
                              cacheWidth: 168,
                            ),
                          ),
                        ),
                        title: Text(recipe.name),
                        subtitle: Text(recipe.cuisine),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            context
                                .read<FavoriteProvider>()
                                .toggle(recipe);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${recipe.name} dihapus dari favorit',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
