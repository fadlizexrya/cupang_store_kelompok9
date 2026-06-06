class Produk {
  final int id;
  final String nama;
  final String deskripsi;
  final int harga;
  final int stok;
  final String? fotoUrl;    
  final String kategori;   
  final String namaToko;   
  final String noWa;       

  Produk({
    required this.id, 
    required this.nama, 
    required this.deskripsi, 
    required this.harga, 
    required this.stok,
    this.fotoUrl,
    required this.kategori,
    required this.namaToko,
    required this.noWa,
  });

  factory Produk.fromJson(Map<String, dynamic> json) {
    final userData = json['user'] as Map<String, dynamic>?;

    String? rawFoto = json['foto_cupang'] ?? json['foto_url'];
    String? fixedFotoUrl;

    if (rawFoto != null && rawFoto.isNotEmpty) {
      if (rawFoto.startsWith('http')) {
        fixedFotoUrl = rawFoto;
      } else {
        fixedFotoUrl = 'https://bettaverse.my.id/storage/$rawFoto';
      }
    }

    // REVISI LOGIKA NAMA TOKO:
    // Jika userData ada, cek apakah dia penjual (punya shop_name). 
    // Kalau shop_name null/kosong (berarti dia Admin/User biasa), pakai userData['name'] (Nama Admin itu sendiri).
    String ditentukanNamaToko = 'Toko Cupang';
    if (userData != null) {
      if (userData['shop_name'] != null && userData['shop_name'].toString().trim().isNotEmpty) {
        ditentukanNamaToko = userData['shop_name']; // Nama Toko Penjual pas registrasi
      } else {
        ditentukanNamaToko = userData['name'] ?? 'Admin BettaVerse'; // Nama Akun Admin
      }
    }

    return Produk(
      id: json['id'],
      nama: json['nama_cupang'] ?? 'Tanpa Nama',
      deskripsi: json['deskripsi'] ?? '',
      kategori: json['jenis_cupang'] ?? 'Halfmoon',
      fotoUrl: fixedFotoUrl, 
      noWa: json['no_wa'] ?? '',
      harga: json['harga'] is int ? json['harga'] : int.parse((json['harga'] ?? 0).toString()),
      stok: json['stok'] is int ? json['stok'] : int.parse((json['stok'] ?? 1).toString()), 
      namaToko: ditentukanNamaToko,
    );
  }
}