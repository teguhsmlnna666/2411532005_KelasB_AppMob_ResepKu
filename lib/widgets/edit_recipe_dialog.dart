
import 'package:flutter/material.dart';

class EditRecipeDialog extends StatefulWidget {
  const EditRecipeDialog({
    super.key,
    required this.initialName,
  });

  final String initialName;

  @override
  State<EditRecipeDialog> createState() =>
      _EditRecipeDialogState();
}

class _EditRecipeDialogState extends State<EditRecipeDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialName,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ubah Nama Resep'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Nama resep',
          hintText: 'Masukkan nama baru',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(
              context,
              _controller.text.trim(),
            );
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
