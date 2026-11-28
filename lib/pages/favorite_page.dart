import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resepku/models/favorite.dart';
import 'package:resepku/pages/detail_page.dart';
import 'package:resepku/providers/favorite_provider.dart';
import 'package:resepku/providers/settings_provider.dart';
import 'package:resepku/widgets/recipe_image.dart';

class FavoritePage extends StatelessWidget {
  const FavoritePage({super.key});

  Future<void> _editNote(BuildContext context, Favorite item) async {
    final note = await showDialog<String>(
      context: context,
      builder: (context) => _NoteDialog(initial: item.note),
    );

    if (note == null || !context.mounted) return;

    await context
        .read<FavoriteProvider>()
        .updateNote(item.recipe.id, note.trim());
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorit Saya'),
        actions: [
          PopupMenuButton<FavoriteSort>(
            tooltip: 'Urutkan favorit',
            initialValue: settings.favoriteSort,
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              settings.setFavoriteSort(value);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: FavoriteSort.newest,
                child: Text('Terbaru disimpan'),
              ),
              PopupMenuItem(
                value: FavoriteSort.name,
                child: Text('Nama A–Z'),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<FavoriteProvider>(
        builder: (context, favorite, child) {
          if (favorite.count == 0) {
            return const Center(
              child: Text(
                'Belum ada resep favorit.\nTekan ikon hati di daftar resep.',
                textAlign: TextAlign.center,
              ),
            );
          }

          // Mengurutkan salinan, bukan list asli provider.
          final items = [...favorite.items];

          if (settings.favoriteSort == FavoriteSort.newest) {
            items.sort(
              (a, b) => b.savedAt.compareTo(a.savedAt),
            );
          } else {
            items.sort(
              (a, b) => a.recipe.name
                  .toLowerCase()
                  .compareTo(b.recipe.name.toLowerCase()),
            );
          }

          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              final recipe = item.recipe;

              return Dismissible(
                key: ValueKey(recipe.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                onDismissed: (_) {
                  favorite.toggle(recipe);
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
                  subtitle: Text(
                    '${item.note.isEmpty ? 'Belum ada catatan' : item.note}\n'
                    'Dimasak ${item.cookedCount} kali',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  isThreeLine: true,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailPage(
                        recipe: recipe,
                      ),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Sudah dimasak',
                        icon: const Icon(Icons.restaurant),
                        onPressed: () async {
                          await favorite.incrementCooked(recipe.id);

                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${recipe.name} ditandai sudah dimasak',
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        tooltip: 'Catatan',
                        icon: const Icon(Icons.edit_note),
                        onPressed: () => _editNote(context, item),
                      ),
                      IconButton(
                        tooltip: 'Hapus dari favorit',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => favorite.toggle(recipe),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Dialog catatan pribadi.
class _NoteDialog extends StatefulWidget {
  const _NoteDialog({required this.initial});

  final String initial;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  late final _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Catatan pribadi'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'Contoh: kurangi garam',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _controller.text,
          ),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}