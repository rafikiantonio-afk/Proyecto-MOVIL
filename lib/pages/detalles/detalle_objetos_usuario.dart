import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/fs_service.dart';
import '../../utils/app_theme.dart';

// Vista de gestión para un objeto propio del usuario: marcar como Devuelto o eliminar
class DetalleObjetosUsuarioPage extends StatefulWidget {
  final String docId;
  final User user;

  const DetalleObjetosUsuarioPage({
    super.key,
    required this.docId,
    required this.user,
  });

  @override
  State<DetalleObjetosUsuarioPage> createState() =>
      _DetalleObjetosUsuarioPageState();
}

class _DetalleObjetosUsuarioPageState
    extends State<DetalleObjetosUsuarioPage> {
  final FsService _fsService = FsService();
  bool _procesando = false;

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

  Future<void> _confirmarAccion({
    required String tituloDialogo,
    required String mensaje,
    required String textoConfirmar,
    required Color colorBoton,
    required Future<void> Function() accion,
    String? mensajeExito,
    bool cerrarPantalla = false,
  }) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tituloDialogo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorBoton,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(textoConfirmar),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _procesando = true);
    try {
      await accion();
      if (!mounted) return;
      if (mensajeExito != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(mensajeExito)));
      }
      if (cerrarPantalla) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _procesando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String nombreAutor =
        (widget.user.displayName != null &&
                widget.user.displayName!.trim().isNotEmpty)
            ? widget.user.displayName!.trim()
            : (widget.user.email ?? widget.user.uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar mi objeto'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Objetos')
            .doc(widget.docId)
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
          final Uint8List? fotoBytes = _extraerBytesFoto(data['foto']);
          final bool estaDevuelto = estado == 'Devuelto';

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
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _DatoLinea(etiqueta: 'Estado', valor: estado),
                _DatoLinea(etiqueta: 'Tipo', valor: tipo),
                _DatoLinea(etiqueta: 'Categoría', valor: categoria),
                _DatoLinea(etiqueta: 'Lugar', valor: lugar),
                _DatoLinea(etiqueta: 'Fecha y hora', valor: fechaStr),
                _DatoLinea(etiqueta: 'Autor', valor: nombreAutor),
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
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Marcar como Devuelto'),
                  subtitle: Text(
                    estaDevuelto
                        ? 'Este objeto ya fue marcado como Devuelto'
                        : 'Al marcarlo, se actualiza el estado para todos',
                  ),
                  value: estaDevuelto,
                  activeColor: Colors.green,
                  onChanged: (_procesando || estaDevuelto)
                      ? null
                      : (_) => _confirmarAccion(
                            tituloDialogo: 'Marcar como Devuelto',
                            mensaje:
                                '¿Estás seguro de que deseas marcar "$titulo" como Devuelto?',
                            textoConfirmar: 'Confirmar',
                            colorBoton: AppTheme.primaryBlue,
                            accion: () => _fsService.marcarDevuelto(widget.docId),
                            mensajeExito: '"$titulo" marcado como Devuelto',
                          ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _procesando
                      ? null
                      : () => _confirmarAccion(
                            tituloDialogo: 'Eliminar objeto',
                            mensaje: '¿Seguro que deseas eliminar "$titulo"?',
                            textoConfirmar: 'Eliminar',
                            colorBoton: Colors.red,
                            accion: () => _fsService.borrarObjeto(widget.docId),
                            mensajeExito: 'Eliminado: $titulo',
                            cerrarPantalla: true,
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Eliminar publicación'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DatoLinea extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _DatoLinea({required this.etiqueta, required this.valor});

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