class Noticia {
  final String id;
  final String titulo;
  final String fecha;
  final String hora;
  final String enlace;
  final String lugar;
  final String imagenUrl; // Changed from imagen_url
  final String resumen;
  final String contenido;
  final String tipo;
  final String nivel;

  Noticia({
    required this.id,
    required this.titulo,
    required this.fecha,
    required this.hora,
    required this.enlace,
    required this.lugar,
    required this.imagenUrl, // Changed from imagen_url
    required this.resumen,
    required this.contenido,
    required this.tipo,
    required this.nivel,
  });

  factory Noticia.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Noticia(
      id: doc.id,
      titulo: data['titulo'] ?? 'Sin título',
      fecha: data['fecha'] ?? 'Fecha no disponible',
      hora: data['hora'] ?? 'Hora no disponible',
      enlace: data['enlace'] ?? '',
      lugar: data['lugar'] ?? 'Ubicación no especificada',
      imagenUrl: data['imagen_url'] ?? '', // Changed from imagen_url
      resumen: data['resumen'] ?? 'Sin resumen.',
      contenido: data['contenido'] ?? 'Contenido no disponible.',
      tipo: data['tipo'] ?? 'General',
      nivel: data['nivel'] ?? 'Bajo',
    );
  }
}