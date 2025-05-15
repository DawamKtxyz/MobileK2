class Barber {
  final int id;
  final String nama;
  final String email;
  final String telepon;
  final String? spesialisasi;
  final double persentaseKomisi;
  final String sertifikat;

  Barber({
    required this.id,
    required this.nama,
    required this.email,
    required this.telepon,
    this.spesialisasi,
    required this.persentaseKomisi,
    required this.sertifikat,
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
    };
  }
}