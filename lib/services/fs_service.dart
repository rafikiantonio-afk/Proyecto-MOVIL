import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';

class FsService {
  // Lista de categorías desde Firestore
  Future<QuerySnapshot> categorias() {
    return FirebaseFirestore.instance
        .collection('Categorias')
        .orderBy('nombre')
        .get();
  }

  // Stream en tiempo real de todos los objetos
  Stream<QuerySnapshot> objetos() {
    return FirebaseFirestore.instance.collection('Objetos').snapshots();
  }

  // Guarda un nuevo objeto con la foto como Blob en Firestore
  Future<void> agregarObjeto({
    required String titulo,
    required String descripcion,
    required String categoria,
    required String lugar,
    required String tipo,
    required String estado,
    required DateTime fecha,
    required String autorID,
    required String autorNombre,
    required String autorCorreo,
    required Uint8List foto,
  }) {
    return FirebaseFirestore.instance.collection('Objetos').doc().set({
      'Titulo': titulo,
      'Descripcion': descripcion,
      'Categoria': categoria,
      'Lugar': lugar,
      'Tipo': tipo,
      'Estado': estado,
      'Fecha': Timestamp.fromDate(fecha),
      'autorID': autorID,
      'autorNombre': autorNombre,
      'autorCorreo': autorCorreo,
      'foto': Blob(foto),
    });
  }

  // Marca un objeto como Devuelto
  Future<void> marcarDevuelto(String id) {
    return FirebaseFirestore.instance
        .collection('Objetos')
        .doc(id)
        .update({'Estado': 'Devuelto'});
  }

  // Borra un objeto por su id
  Future<void> borrarObjeto(String id) {
    return FirebaseFirestore.instance.collection('Objetos').doc(id).delete();
  }
}