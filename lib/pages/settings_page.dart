import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resepku/providers/favorite_provider.dart';
import 'package:resepku/providers/settings_provider.dart';
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _confirmDeleteAll(BuildContext context) async {
    final favorite = context.read<FavoriteProvider>();
    final count = favorite.count;

    if (count == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus semua favorit?'),
        content: Text(
          'Sebanyak $count resep favorit akan dihapus. '
          'Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Hapus semua'),
          ),
        ],
      ),
    );

    // Periksa apakah halaman masih aktif setelah dialog ditutup.
    if (!context.mounted || confirmed != true) return;

    // Hapus seluruh favorit dari provider dan database.
    await favorite.clear();

    // Periksa kembali sebelum menampilkan SnackBar.
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Semua favorit berhasil dihapus'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final favorite = context.watch<FavoriteProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Mode gelap'),
            value: settings.isDark,
            onChanged: settings.setDark,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.grid_view),
            title: const Text('Tampilan grid'),
            subtitle: const Text(
              'Daftar resep ditampilkan dalam dua kolom',
            ),
            value: settings.isGrid,
            onChanged: settings.setGrid,
          ),
          const Divider(),

          // Fitur hapus semua favorit.
          ListTile(
            leading: const Icon(
              Icons.delete_forever,
              color: Colors.red,
            ),
            title: const Text('Hapus semua favorit'),
            subtitle: Text(
              '${favorite.count} favorit tersimpan',
            ),
            onTap: favorite.count == 0
                ? null
                : () => _confirmDeleteAll(context),
          ),

          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Pengaturan tersimpan di HP'),
            subtitle: Text(
              'Pilihan tetap ada walaupun aplikasi ditutup.',
            ),
          ),
        ],
      ),
    );
  }
}