import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/fs_service.dart';
import '../../utils/app_theme.dart';

class AgregarTab extends StatefulWidget {
  final User user;
  final VoidCallback? onGuardado;

  const AgregarTab({super.key, required this.user, this.onGuardado});

  @override
  State<AgregarTab> createState() => _AgregarTabState();
}

class _AgregarTabState extends State<AgregarTab> {
  final _formKey = GlobalKey<FormState>();
  final _fs = FsService();
  final _picker = ImagePicker();

  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _lugarCtrl = TextEditingController();

  late Future<QuerySnapshot> _categoriasFuture;
  String _tipo = 'Perdido';
  String? _categoria;
  Uint8List? _foto;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _categoriasFuture = _fs.categorias();
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _lugarCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirFoto(ImageSource origen) async {
    final archivo = await _picker.pickImage(
      source: origen,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 50,
    );
    if (archivo == null) return;
    final bytes = await archivo.readAsBytes();
    if (!mounted) return;
    setState(() => _foto = bytes);
  }

  void _aviso(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_categoria == null) {
      _aviso('Selecciona una categoría');
      return;
    }
    if (_foto == null) {
      _aviso('Debes seleccionar o tomar una foto');
      return;
    }
    if (_foto!.lengthInBytes > 800 * 1024) {
      _aviso('La foto supera el límite permitido para el documento');
      return;
    }

    setState(() => _guardando = true);
    try {
      await _fs.agregarObjeto(
        titulo: _tituloCtrl.text.trim(),
        descripcion: _descripcionCtrl.text.trim(),
        categoria: _categoria!,
        lugar: _lugarCtrl.text.trim(),
        tipo: _tipo,
        estado: 'Vigente',
        fecha: DateTime.now(),
        autorID: widget.user.uid,
        autorNombre: widget.user.displayName ?? 'Usuario',
        autorCorreo: widget.user.email ?? '',
        foto: _foto!,
      );

      _tituloCtrl.clear();
      _descripcionCtrl.clear();
      _lugarCtrl.clear();
      if (!mounted) return;
      setState(() {
        _tipo = 'Perdido';
        _foto = null;
        _guardando = false;
      });
      _aviso('Objeto publicado');
      widget.onGuardado?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      _aviso('Error al guardar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _tituloCtrl,
              decoration: const InputDecoration(labelText: 'Título'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ingresa un título' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descripcionCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Descripción'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Ingresa una descripción'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lugarCtrl,
              decoration: const InputDecoration(labelText: 'Lugar del campus'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ingresa el lugar' : null,
            ),
            const SizedBox(height: 12),
            const Text('Tipo:'),
            RadioGroup<String>(
              groupValue: _tipo,
              onChanged: (v) {
                if (v != null) setState(() => _tipo = v);
              },
              child: const Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text('Perdido'),
                      value: 'Perdido',
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text('Encontrado'),
                      value: 'Encontrado',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<QuerySnapshot>(
              future: _categoriasFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const LinearProgressIndicator();
                }
                final categorias = snapshot.data!.docs
                    .map((d) =>
                        (d.data() as Map<String, dynamic>)['nombre'].toString())
                    .toList();
                _categoria ??= categorias.isNotEmpty ? categorias.first : null;

                return DropdownButtonFormField<String>(
                  initialValue: _categoria,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: categorias
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _categoria = v),
                  validator: (v) =>
                      v == null ? 'Selecciona una categoría' : null,
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _elegirFoto(ImageSource.gallery),
                    icon: const Icon(Icons.photo),
                    label: const Text('Galería'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _elegirFoto(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Cámara'),
                  ),
                ),
              ],
            ),
            if (_foto != null) ...[
              const SizedBox(height: 12),
              Image.memory(_foto!, height: 180, fit: BoxFit.cover),
              Text(
                  'Peso: ${(_foto!.lengthInBytes / 1024).toStringAsFixed(1)} KB'),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _guardando ? null : _guardar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: Text(_guardando ? 'Guardando...' : 'Guardar objeto'),
            ),
          ],
        ),
      ),
    );
  }
}