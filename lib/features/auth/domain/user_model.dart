/// Model data pengguna yang dikembalikan dari backend pada saat login.
class UserModel {
  final String idPengguna;
  final String username;
  final String role; // "Mahasantri" | "Musyrif" | "Admin"
  final Map<String, dynamic>? profil;

  const UserModel({
    required this.idPengguna,
    required this.username,
    required this.role,
    this.profil,
  });

  /// Nama tampilan pengguna (mengutamakan profil.nama jika ada)
  String get displayName {
    if (profil != null && profil!['nama'] != null) {
      final name = profil!['nama'].toString().trim();
      if (name.isNotEmpty) return name;
    }
    return username;
  }

  /// NIM mahasantri (jika profil Mahasantri)
  String get nim {
    return profil?['nim']?.toString() ?? '-';
  }

  /// Nama lengkap mahasantri / pengguna
  String get namaLengkap {
    final nama = profil?['nama']?.toString().trim();
    if (nama != null && nama.isNotEmpty) return nama;
    return displayName;
  }

  /// Kamar mahasantri
  String get kamar {
    return profil?['kamar']?.toString() ?? '-';
  }

  /// Nama musyrif pembina
  String get namaMusyrif {
    final musyrif = profil?['musyrif'];
    if (musyrif is Map<String, dynamic> && musyrif['nama'] != null) {
      return musyrif['nama'].toString();
    }
    return '-';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      idPengguna: json['id_pengguna']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      profil: json['profil'] is Map<String, dynamic>
          ? json['profil'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_pengguna': idPengguna,
      'username': username,
      'role': role,
      'profil': profil,
    };
  }
}
