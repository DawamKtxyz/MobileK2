class Barber {
  final int id;
  final String nama;
  final String email;
  final String? telepon;
  final String? alamat; // Tambahan field alamat
  final String? spesialisasi;
  final double harga;
  final String? sertifikat;
  final String? profilePhoto;
  final double? persentaseKomisi;
  final String? namaBank;
  final String? rekeningBarber;
  final String? createdAt;
  final String? updatedAt;

  Barber({
    required this.id,
    required this.nama,
    required this.email,
    this.telepon,
    this.alamat, // Tambahan field alamat
    this.spesialisasi,
    required this.harga,
    this.sertifikat,
    this.profilePhoto,
    this.persentaseKomisi,
    this.namaBank,
    this.rekeningBarber,
    this.createdAt,
    this.updatedAt,
  });

  factory Barber.fromJson(Map<String, dynamic> json) {
    return Barber(
      id: json['id'],
      nama: json['nama'],
      email: json['email'],
      telepon: json['telepon'],
      alamat: json['alamat'], // Tambahan field alamat
      spesialisasi: json['spesialisasi'],
      harga: json['harga'] is String ? double.parse(json['harga']) : json['harga'].toDouble(),
      sertifikat: json['sertifikat'],
      profilePhoto: json['profile_photo'],
      persentaseKomisi: json['persentase_komisi'] != null
          ? (json['persentase_komisi'] is String
          ? double.parse(json['persentase_komisi'])
          : json['persentase_komisi'].toDouble())
          : null,
      namaBank: json['nama_bank'],
      rekeningBarber: json['rekening_barber'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'email': email,
      'telepon': telepon,
      'alamat': alamat, // Tambahan field alamat
      'spesialisasi': spesialisasi,
      'harga': harga,
      'sertifikat': sertifikat,
      'profile_photo': profilePhoto,
      'persentase_komisi': persentaseKomisi,
      'nama_bank': namaBank,
      'rekening_barber': rekeningBarber,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

// BarberSearch class untuk search results
class BarberCari {
  final int id;
  final String nama;
  final String email;
  final String? telepon;
  final String? alamat; // Tambahan field alamat
  final String? spesialisasi;
  final double harga;
  final String? profilePhoto;
  final double rating;
  final int totalReviews;
  final String formattedHarga;

  BarberCari({
    required this.id,
    required this.nama,
    required this.email,
    this.telepon,
    this.alamat, // Tambahan field alamat
    this.spesialisasi,
    required this.harga,
    this.profilePhoto,
    required this.rating,
    required this.totalReviews,
    required this.formattedHarga,
  });

  factory BarberCari.fromJson(Map<String, dynamic> json) {
    return BarberCari(
      id: json['id'],
      nama: json['nama'],
      email: json['email'],
      telepon: json['telepon'],
      alamat: json['alamat'], // Tambahan field alamat
      spesialisasi: json['spesialisasi'],
      harga: json['harga'] is String ? double.parse(json['harga']) : json['harga'].toDouble(),
      profilePhoto: json['profile_photo'],
      rating: json['rating'] != null
          ? (json['rating'] is String
          ? double.parse(json['rating'])
          : json['rating'].toDouble())
          : 0.0,
      totalReviews: json['total_reviews'] ?? 0,
      formattedHarga: json['formatted_harga'] ?? 'Rp ${json['harga'] ?? 0}',
    );
  }
}