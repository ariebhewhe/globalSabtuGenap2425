class ProductModel {
  final String id;
  final String nama;
  final String jenis;
  final String deskripsi;
  final double harga;
  final double berat;
  final String gambar;

  ProductModel({
    required this.id,
    required this.nama,
    required this.jenis,
    required this.deskripsi,
    required this.harga,
    required this.berat,
    required this.gambar,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      nama: json['nama'] as String,
      jenis: json['jenis'] as String,
      deskripsi: json['deskripsi'] as String,
      harga: (json['harga'] as num).toDouble(),
      berat: (json['berat'] as num).toDouble(),
      gambar: json['gambar'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'jenis': jenis,
      'deskripsi': deskripsi,
      'harga': harga,
      'berat': berat,
      'gambar': gambar,
    };
  }
}
