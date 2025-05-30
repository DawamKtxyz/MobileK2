class Pelanggan {
  final int id;
  final String nama;
  final String email;
  final String? telepon;
  final String? alamat;
  final String? tanggalLahir;
  final String? apiToken;
  final String? profilePhoto;
  final String? createdAt;
  final String? updatedAt;

  Pelanggan({
    required this.id,
    required this.nama,
    required this.email,
    this.telepon,
    this.alamat,
    this.tanggalLahir,
    this.apiToken,
    this.profilePhoto,
    this.createdAt,
    this.updatedAt,
  });

  factory Pelanggan.fromJson(Map<String, dynamic> json) {
    return Pelanggan(
      id: json['id'],
      nama: json['nama'],
      email: json['email'],
      telepon: json['telepon'],
      alamat: json['alamat'],
      tanggalLahir: json['tanggal_lahir'],
      apiToken: json['api_token'],
      profilePhoto: json['profile_photo'],
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
      'alamat': alamat,
      'tanggal_lahir': tanggalLahir,
      'api_token': apiToken,
      'profile_photo': profilePhoto,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}