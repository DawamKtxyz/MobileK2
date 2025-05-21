class Barber {
  final int id;
  final String nama;
  final String email;
  final String? telepon;
  final String? spesialisasi;
  final double harga;
  final String? sertifikat;
  final String? profilePhoto; // Add this field

  Barber({
    required this.id,
    required this.nama,
    required this.email,
    this.telepon,
    this.spesialisasi,
    required this.harga,
    this.sertifikat,
    this.profilePhoto, // Initialize it
  });

  factory Barber.fromJson(Map<String, dynamic> json) {
    return Barber(
      id: json['id'],
      nama: json['nama'],
      email: json['email'],
      telepon: json['telepon'],
      spesialisasi: json['spesialisasi'],
      harga: json['harga'] is String ? double.parse(json['harga']) : json['harga'].toDouble(),
      sertifikat: json['sertifikat'],
      profilePhoto: json['profile_photo'], // Parse from JSON
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'email': email,
      'telepon': telepon,
      'spesialisasi': spesialisasi,
      'harga': harga,
      'sertifikat': sertifikat,
      'profile_photo': profilePhoto, // Include in JSON
    };
  }
}