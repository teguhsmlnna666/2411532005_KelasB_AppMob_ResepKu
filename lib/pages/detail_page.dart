import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resepku/models/recipe.dart';
import 'package:resepku/services/recipe_service.dart';
import 'package:resepku/widgets/edit_recipe_dialog.dart';

class DetailPage extends StatefulWidget {
  const DetailPage({super.key, required this.recipe});

  final Recipe recipe;

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late int _servings;

  @override
  void initState() {
    super.initState();
    _servings = widget.recipe.servings;
  }

  void _addServing() {
    setState(() {
      _servings++;
    });
  }

  void _removeServing() {
    if (_servings > 1) {
      setState(() {
        _servings--;
      });
    }
  }

  
  Future<void> _showEditDialog() async {
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return EditRecipeDialog(
          initialName: widget.recipe.name,
        );
      },
    );

    if (!mounted) return;
    if (newName == null || newName.isEmpty) return;

    try {
      final updated = await context.read<RecipeService>().updateRecipe(
        id: widget.recipe.id,
        name: newName,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nama resep berhasil diubah menjadi "${updated.name}".',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengubah resep: $e'),
        ),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Resep'),
          content: const Text('Apakah Anda yakin ingin menghapus resep ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    if (confirm != true) return;

    try {
      final result = await context.read<RecipeService>().deleteRecipe(
        widget.recipe.id,
      );

      if (!mounted) return;

      if (result['isDeleted'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resep berhasil dihapus.')),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Resep gagal dihapus.')));
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal menghapus resep: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final totalCalories = recipe.caloriesPerServing * _servings;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header gambar resep
          SliverAppBar(
            pinned: true,
            expandedHeight: 260,
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditDialog();
                  } else if (value == 'delete') {
                    _confirmDelete();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Ubah nama')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Hapus resep'),
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                recipe.name,
                style: const TextStyle(
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                ),
              ),
              background: CachedNetworkImage(
                imageUrl: recipe.image,
                fit: BoxFit.cover,
                placeholder: (context, url) {
                  return const Center(child: CircularProgressIndicator());
                },
                errorWidget: (context, url, error) {
                  return const Center(
                    child: Icon(Icons.broken_image, size: 50),
                  );
                },
              ),
            ),
          ),

          // Informasi resep dan pengaturan porsi
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cuisine: ${recipe.cuisine}'),
                  Text('Kesulitan: ${recipe.difficulty}'),
                  Text('Waktu: ${recipe.totalTimeMinutes} menit'),
                  const SizedBox(height: 16),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text('Jumlah Porsi'),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: _servings > 1
                                    ? _removeServing
                                    : null,
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text(
                                '$_servings',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              IconButton(
                                onPressed: _addServing,
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ],
                          ),
                          Text('Total Kalori: $totalCalories kkal'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Judul daftar bahan
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Bahan',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),

          // Daftar bahan resep
          SliverList.builder(
            itemCount: recipe.ingredients.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: Text(recipe.ingredients[index]),
              );
            },
          ),

          // Judul "Langkah": widget biasa dibungkus SliverToBoxAdapter
          if (recipe.instructions.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                child: Text(
                  'Langkah',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
          // Daftar langkah: lazy, sama seperti daftar bahan
          SliverList.builder(
            itemCount: recipe.instructions.length,
            itemBuilder: (context, index) => ListTile(
              dense: true,
              leading: CircleAvatar(radius: 12, child: Text('${index + 1}')),
              title: Text(recipe.instructions[index]),
            ),
          ),
          // Ruang di bawah langkah terakhir
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
