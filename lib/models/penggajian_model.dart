class Penggajian {
  final int idGaji;
  final int idPesanan;
  final int idBarber;
  final String namaBarber;
  final String rekeningBarber;
  final int idPelanggan;
  final String namaPelanggan;
  final DateTime tanggalPesanan;
  final int? jadwalId;
  final DateTime? tanggalJadwal;
  final String? jamJadwal;
  final double totalBayar;
  final double potongan;
  final double totalGaji;
  final String status; // 'lunas' atau 'belum lunas'
  final String? buktiTransfer;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Penggajian({
    required this.idGaji,
    required this.idPesanan,
    required this.idBarber,
    required this.namaBarber,
    required this.rekeningBarber,
    required this.idPelanggan,
    required this.namaPelanggan,
    required this.tanggalPesanan,
    this.jadwalId,
    this.tanggalJadwal,
    this.jamJadwal,
    required this.totalBayar,
    required this.potongan,
    required this.totalGaji,
    required this.status,
    this.buktiTransfer,
    this.createdAt,
    this.updatedAt,
  });

  factory Penggajian.fromJson(Map<String, dynamic> json) {
    return Penggajian(
      idGaji: json['id_gaji'] ?? 0,
      idPesanan: json['id_pesanan'] ?? 0,
      idBarber: json['id_barber'] ?? 0,
      namaBarber: json['nama_barber'] ?? '',
      rekeningBarber: json['rekening_barber'] ?? '',
      idPelanggan: json['id_pelanggan'] ?? 0,
      namaPelanggan: json['nama_pelanggan'] ?? '',
      tanggalPesanan: json['tanggal_pesanan'] != null 
          ? DateTime.parse(json['tanggal_pesanan'])
          : DateTime.now(),
      jadwalId: json['jadwal_id'],
      tanggalJadwal: json['tanggal_jadwal'] != null 
          ? DateTime.parse(json['tanggal_jadwal'])
          : null,
      jamJadwal: json['jam_jadwal'],
      totalBayar: _parseDouble(json['total_bayar']),
      potongan: _parseDouble(json['potongan']),
      totalGaji: _parseDouble(json['total_gaji']),
      status: json['status'] ?? 'belum lunas',
      buktiTransfer: json['bukti_transfer'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_gaji': idGaji,
      'id_pesanan': idPesanan,
      'id_barber': idBarber,
      'nama_barber': namaBarber,
      'rekening_barber': rekeningBarber,
      'id_pelanggan': idPelanggan,
      'nama_pelanggan': namaPelanggan,
      'tanggal_pesanan': tanggalPesanan.toIso8601String(),
      'jadwal_id': jadwalId,
      'tanggal_jadwal': tanggalJadwal?.toIso8601String(),
      'jam_jadwal': jamJadwal,
      'total_bayar': totalBayar,
      'potongan': potongan,
      'total_gaji': totalGaji,
      'status': status,
      'bukti_transfer': buktiTransfer,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // Helper getters
  bool get isLunas => status == 'lunas';
  bool get isBelumLunas => status == 'belum lunas';
  
  String get formattedTotalBayar => 'Rp ${totalBayar.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]}.',
  )}';
  
  String get formattedTotalGaji => 'Rp ${totalGaji.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]}.',
  )}';
  
  String get formattedPotongan => 'Rp ${potongan.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]}.',
  )}';

  String get formattedTanggalPesanan {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${tanggalPesanan.day} ${months[tanggalPesanan.month - 1]} ${tanggalPesanan.year}';
  }

  String get formattedJadwalLengkap {
    if (tanggalJadwal != null && jamJadwal != null) {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${tanggalJadwal!.day} ${months[tanggalJadwal!.month - 1]} ${tanggalJadwal!.year} • $jamJadwal';
    }
    return 'Tidak tersedia';
  }
}

// Model untuk statistik penggajian
class PenggajianStats {
  final double totalGajiMenanti;
  final double totalGajiDiterima;
  final int jumlahTransaksiMenanti;
  final int jumlahTransaksiSelesai;
  final double pendapatanBulanIni;
  final String periode;

  PenggajianStats({
    required this.totalGajiMenanti,
    required this.totalGajiDiterima,
    required this.jumlahTransaksiMenanti,
    required this.jumlahTransaksiSelesai,
    required this.pendapatanBulanIni,
    required this.periode,
  });

  factory PenggajianStats.fromJson(Map<String, dynamic> json) {
    return PenggajianStats(
      totalGajiMenanti: _parseDouble(json['total_gaji_menanti']),
      totalGajiDiterima: _parseDouble(json['total_gaji_diterima']),
      jumlahTransaksiMenanti: json['jumlah_transaksi_menanti'] ?? 0,
      jumlahTransaksiSelesai: json['jumlah_transaksi_selesai'] ?? 0,
      pendapatanBulanIni: _parseDouble(json['pendapatan_bulan_ini']),
      periode: json['periode'] ?? '',
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  String get formattedTotalGajiMenanti => 'Rp ${totalGajiMenanti.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]}.',
  )}';
  
  String get formattedTotalGajiDiterima => 'Rp ${totalGajiDiterima.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]}.',
  )}';
  
  String get formattedPendapatanBulanIni => 'Rp ${pendapatanBulanIni.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]}.',
  )}';
}