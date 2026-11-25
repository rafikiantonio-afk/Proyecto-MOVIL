import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/fs_service.dart';
import '../../utils/app_theme.dart';
import '../detalles/detalle_objetos_usuario.dart';

// Pestaña "Mis objetos": muestra en tiempo real solo los objetos del usuario actual
class UsuarioTab extends StatelessWidget {
  final User user;

  UsuarioTab({super.key, required this.user});

  final FsService _fsService = FsService();

  String _formatearFecha(dynamic fechaRaw) {
    if (fechaRaw is Timestamp) {
      final dt = fechaRaw.toDate();
      final dia = dt.day.toString().padLeft(2, '0');
      final mes = dt.month.toString().padLeft(2, '0');
      final hora = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$dia/$mes $hora:$min';
    }
    return '';
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _fsService.objetos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final todosDocs = snapshot.data?.docs ?? [];
        final misDocs = todosDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return (data['autorID'] ?? '').toString() == user.uid;
        }).toList();

        if (misDocs.isEmpty) {
          return const Center(
            child: Text('Aún no has creado objetos con esta cuenta'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          itemCount: misDocs.length,
          separatorBuilder: (_, _) => const Divider(height: 1, indent: 76),
          itemBuilder: (context, index) {
            final doc = misDocs[index];
            final data = doc.data() as Map<String, dynamic>;

            final String titulo = (data['Titulo'] ?? 'Sin título').toString();
            final String lugar = (data['Lugar'] ?? '').toString();
            final String estado = (data['Estado'] ?? 'Vigente').toString();
            final String fechaStr = _formatearFecha(data['Fecha']);
            final Uint8List? fotoBytes = _extraerBytesFoto(data['foto']);
            final bool estaDevuelto = estado == 'Devuelto';

            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetalleObjetosUsuarioPage(
                      docId: doc.id,
                      user: user,
                    ),
                  ),
                );
              },
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 48,
                  height: 48,
                  color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                  child: fotoBytes != null
                      ? Image.memory(
                          fotoBytes,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.inventory_2_outlined,
                            color: AppTheme.primaryBlue,
                          ),
                        )
                      : const Icon(
                          Icons.inventory_2_outlined,
                          color: AppTheme.primaryBlue,
                        ),
                ),
              ),
              title: Text(
                titulo,
                style: const TextStyle(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '$estado${lugar.isNotEmpty ? ' • $lugar' : ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: estaDevuelto ? Colors.green.shade700 : null,
                ),
              ),
              trailing: Text(
                fechaStr,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            );
          },
        );
      },
    );
  }
}