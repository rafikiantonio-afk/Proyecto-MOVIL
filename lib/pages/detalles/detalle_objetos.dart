import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/app_theme.dart';

class DetalleObjetosPage extends StatelessWidget {
  final String docId;
  final User currentUser;

  const DetalleObjetosPage({
    super.key,
    required this.docId,
    required this.currentUser,
  });

  String _formatearFechaCompleta(dynamic fechaRaw) {
    if (fechaRaw is Timestamp) {
      final dt = fechaRaw.toDate();
      final dia = dt.day.toString().padLeft(2, '0');
      final mes = dt.month.toString().padLeft(2, '0');
      final anio = dt.year.toString();
      final hora = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$dia/$mes/$anio $hora:$min';
    }
    return 'Sin fecha';
  }

  Uint8List? _extraerBytesFoto(dynamic fotoRaw) {
    if (fotoRaw == null) return null;
    if (fotoRaw is Blob) return fotoRaw.bytes.isNotEmpty ? fotoRaw.bytes : null;
    if (fotoRaw is Uint8List) return fotoRaw.isNotEmpty ? fotoRaw : null;
    if (fotoRaw is List) {
      final bytes = Uint8List.fromList(fotoRaw.cast<int>());
      return bytes.isNotEmpty ? bytes : null;
    }
    return null;
  }

  String _obtenerNombreAutor(Map<String, dynamic> data) {
    final autorNombre = (data['autorNombre'] ?? '').toString().trim();
    if (autorNombre.isNotEmpty) return autorNombre;
    final autorId = (data['autorID'] ?? '').toString();
    if (autorId == currentUser.uid &&
        currentUser.displayName != null &&
        currentUser.displayName!.trim().isNotEmpty) {
      return currentUser.displayName!.trim();
    }
    return 'No disponible';
  }

  String _obtenerCorreoAutor(Map<String, dynamic> data) {
    final autorCorreo = (data['autorCorreo'] ?? '').toString().trim();
    if (autorCorreo.isNotEmpty) return autorCorreo;
    final autorId = (data['autorID'] ?? '').toString();
    if (autorId == currentUser.uid &&
        currentUser.email != null &&
        currentUser.email!.trim().isNotEmpty) {
      return currentUser.email!.trim();
    }
    return 'No disponible';
  }

  Future<void> _copiarCorreo(BuildContext context, String correo) async {
    if (correo == 'No disponible') return;
    await Clipboard.setData(ClipboardData(text: correo));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Correo copiado: $correo')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del objeto'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Objetos')
            .doc(docId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('La publicación ya no existe'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String titulo = (data['Titulo'] ?? 'Sin título').toString();
          final String descripcion =
              (data['Descripcion'] ?? 'Sin descripción').toString();
          final String tipo = (data['Tipo'] ?? 'Perdido').toString();
          final String categoria =
              (data['Categoria'] ?? 'Sin categoría').toString();
          final String lugar = (data['Lugar'] ?? 'Sin lugar').toString();
          final String estado = (data['Estado'] ?? 'Vigente').toString();
          final String fechaStr = _formatearFechaCompleta(data['Fecha']);
          final String autorNombre = _obtenerNombreAutor(data);
          final String autorCorreo = _obtenerCorreoAutor(data);
          final Uint8List? fotoBytes = _extraerBytesFoto(data['foto']);
          final bool estaDevuelto = estado == 'Devuelto';
          final bool tieneCorreo = autorCorreo != 'No disponible';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 280,
                    color: Colors.black12,
                    child: fotoBytes != null
                        ? Image.memory(
                            fotoBytes,
                            width: double.infinity,
                            height: 280,
                            fit: BoxFit.contain,
                          )
                        : const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 64,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Chip(
                      label: Text(estado),
                      backgroundColor: estaDevuelto
                          ? Colors.green.withValues(alpha: 0.18)
                          : AppTheme.primaryBlue.withValues(alpha: 0.15),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _FilaDato(etiqueta: 'Tipo', valor: tipo),
                _FilaDato(etiqueta: 'Categoría', valor: categoria),
                _FilaDato(etiqueta: 'Lugar', valor: lugar),
                _FilaDato(etiqueta: 'Fecha y hora', valor: fechaStr),
                _FilaDato(etiqueta: 'Publicado por', valor: autorNombre),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 125,
                        child: Text(
                          'Correo:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Expanded(child: Text(autorCorreo)),
                      if (tieneCorreo)
                        IconButton(
                          icon: const Icon(
                            Icons.copy,
                            size: 20,
                            color: AppTheme.primaryBlue,
                          ),
                          tooltip: 'Copiar correo',
                          onPressed: () => _copiarCorreo(context, autorCorreo),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Descripción',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  descripcion,
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FilaDato extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _FilaDato({required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              '$etiqueta:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(valor)),
        ],
      ),
    );
  }
}