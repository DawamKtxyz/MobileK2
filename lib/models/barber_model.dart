class Barber {
  final int id;
  final String nama;
  final String email;
  final String telepon;
  final String? spesialisasi;
  final double persentaseKomisi;
  final String sertifikat;
  final double harga; // Added harga field

  Barber({
    required this.id,
    required this.nama,
    required this.email,
    required this.telepon,
    this.spesialisasi,
    required this.persentaseKomisi,
    required this.sertifikat,
    required this.harga, // Added to constructor
  });

  factory Barber.fromJson(Map<String, dynamic> json) {
    return Barber(
      id: json['id'],
      nama: json['nama'],
      email: json['email'],
      telepon: json['telepon'],
      spesialisasi: json['spesialisasi'],
      persentaseKomisi: json['persentase_komisi'] != null
          ? double.tryParse(json['persentase_komisi'].toString()) ?? 0.0
          : 0.0,
      sertifikat: json['sertifikat'],
      harga: json['harga'] != null
          ? double.tryParse(json['harga'].toString()) ?? 20000.0
          : 20000.0, // Default to 20000 if null
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'email': email,
      'telepon': telepon,
      'spesialisasi': spesialisasi,
      'persentase_komisi': persentaseKomisi,
      'sertifikat': sertifikat,
      'harga': harga, // Added to JSON serialization
    };
  }
}