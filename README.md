# GEO-JAMAAH — Sistem Informasi Presensi Shalat Berjamaah Berbasis Geofencing & DSS

> **Tugas Mata Kuliah:** Sistem Informasi Manajemen / Praktikum SIM  
> **Platform:** Flutter / Dart (Mobile Application)  
> **Metode Validasi:** Geofencing (Haversine Formula) & Window Time  
> **Backend:** Geo-Jamaah_Server (NestJS, PostgreSQL, Prisma) — berjalan di `http://<IP-laptop>:3000`

---

## 📌 Deskripsi Sistem

**GEO-JAMAAH** adalah sistem informasi manajemen presensi shalat berjamaah yang dirancang untuk lingkungan pesantren mahasiswa (mahasantri). Sistem ini memvalidasi kehadiran secara digital berdasarkan lokasi fisik perangkat (geofencing) dan rentang waktu shalat guna mengurangi potensi titip presensi, penggunaan *fake GPS*, serta mempermudah musyrif dalam melakukan evaluasi kedisiplinan.

---

## 👥 Peran Pengguna & Fitur Utama

### 1. Mahasantri (Mobile Role)
- **Login** dengan binding device ID (satu akun = satu perangkat).
- **Presensi Digital:** Melakukan presensi shalat 5 waktu dengan verifikasi jarak GPS ke masjid dan batas waktu shalat (server-side).
- **Pengajuan Izin:** Mengajukan izin (Sakit, Pulang, Tugas Kampus) dengan status Pending → Disetujui/Ditolak oleh Musyrif.
- **Riwayat & Profil:** Meninjau histori kehadiran dan data pembimbing musyrif.

### 2. Musyrif (Operational & DSS Role)
- **Dashboard Operasional:** Memantau kehadiran harian santri binaan secara *real-time*.
- **Early Warning System (EWS / DSS):** Mendeteksi mahasantri dengan status kehadiran kritis (< 75%) untuk intervensi dan pembinaan langsung.
- **Verifikasi Izin:** Menyetujui atau menolak pengajuan izin mahasantri binaan.
- **Rekapitulasi Kehadiran:** Meninjau rekapitulasi individu dan kelompok per kamar.

### 3. Admin / Pengasuh (Strategic Role)
- **Master Data Management:** Pengelolaan data Mahasantri, Musyrif, Jadwal Shalat, dan Koordinat Masjid (diakses via Web Dashboard Admin / Swagger).
- **Fitur Admin Mobile:** Panel monitoring rekapitulasi global, tren grafik kehadiran, peninjauan log aktivitas sistem (audit trail), eksekusi manual job presensi, dan reset ikatan device ID mahasantri.

---

## 🛠️ Teknologi

- **Framework:** Flutter (Material 3)
- **State/Storage:** Riverpod + `flutter_secure_storage` (token hanya di secure storage, tidak ada password)
- **HTTP Client:** Dio + `api_client` dengan interceptor token Bearer, unwrap respons, dan AppException
- **Kalkulasi Jarak:** Haversine Formula (di backend)
- **Lokasi:** `geolocator` + `safe_device` (deteksi fake GPS)
- **Navigasi:** `go_router` dengan routing per peran

---

## ▶️ Cara Menjalankan

Pastikan backend Geo-Jamaah_Server menyala dan bisa diakses dari HP/emulator.

```bash
# 1. Masuk ke folder project
cd geo-jamaah

# 2. Install dependensi (jalankan di Windows lewat IDE, atau WSL jika dipaksa)
flutter pub get

# 3. Jalankan aplikasi dengan alamat server laptop
#    Ganti <IP-laptop> dengan alamat IP asli laptop (mis. 192.168.1.10).
#    Untuk emulator Android, gunakan 10.0.2.2 (localhost di emulator merujuk ke emulator itu sendiri).
flutter run --dart-define=API_BASE_URL=http://<IP-laptop>:3000/v1
```

**Build APK release:**
```bash
flutter build apk --release --dart-define=API_BASE_URL=http://<IP-laptop>:3000/v1
```

### Catatan Jaringan
- **Emulator Android:** gunakan `http://10.0.2.2:3000/v1` (10.0.2.2 merujuk ke host laptop).
- **HP fisik:** gunakan alamat IP LAN laptop (mis. `http://192.168.1.10:3000/v1`) atau tunnel. Pastikan HP dan laptop dalam satu jaringan Wi-Fi, dan port 3000 tidak diblokir firewall.
- `usesCleartextTraffic` di AndroidManifest diaktifkan hanya untuk demo HTTP (tanpa HTTPS). Untuk produksi, gunakan HTTPS dan nonaktifkan cleartext.

### Batasan (menurut dokumen)
- Tanpa refresh token — token kedaluwarsa (default 7d) akan arahkan ke login ulang.
- Tanpa lampiran izin (upload bukti MinIO masih rencana).
- Tanpa layar Admin di aplikasi mobile (master data via Web Dashboard Admin / Swagger).
- Tanpa notifikasi push.
- Token tidak terikat ke perangkat selain binding device ID Mahasantri saat login pertama.

---

## 🗄️ Arsitektur Data (7 Entitas Utama)

1. `Pengguna` (Role, Authentication, Device ID)
2. `Mahasantri` (NIM, Kamar, Pembina)
3. `Musyrif` (ID Musyrif, Kontak)
4. `Jadwal_Sholat` (Waktu Azan, Iqamah, Window Presensi)
5. `Masjid` (Koordinat Latitude/Longitude, Radius Toleransi Meter)
6. `Presensi` (Koordinat User, Status Hadir/Izin/Alpha, Timestamp)
7. `Izin` (Jenis Izin, Bukti, Status Approval)

---

## 🧪 Akun Demo (Seed Backend)

Akun berikut tersedia setelah backend di-seed (sesuaikan dengan data seed sebenarnya):

| Role | Username | Password | Keterangan |
|------|----------|----------|------------|
| Admin | admin | rahasia123 | Akses master data via Swagger/Web |
| Musyrif | musyrif1 | rahasia123 | Pembina santri binaan |
| Mahasantri | mahasantri1 | 12345678 | Perlu device_id saat login |
| Mahasantri (nonaktif) | mahasantri2 | 12345678 | `status_aktif = false`, login ditolak |

---

## 🤖 Catatan Pengembangan

Sebagian besar kode dalam proyek ini dikembangkan dengan bantuan **AI (Artificial Intelligence)** sebagai asisten coding (pair programmer). Proyek ini berada dalam tahap pengembangan aktif (*work in progress*).

### Perintah pengembangan (WSL/Linux)
- `flutter analyze` — analisis statis kode (harus bersih sebelum commit)
- `flutter test` — jalankan semua unit test (harus lulus sebelum commit)
- *Jangan* menjalankan `flutter pub get`, `flutter clean`, atau `flutter run` dari WSL (IDE memakai Flutter Windows; menjalankannya dari WSL merusak `.dart_tool`). Jika dependensi berubah, jalankan `flutter pub get` dari Windows.

---

## 📄 Dokumen Terkait

- `docs/API_CONTRACT.md` — kontrak lengkap endpoint backend
- `docs/FRONTEND_GUIDE.md` — panduan frontend dan status endpoint
- `docs/BUSINESS_RULES.md` — aturan bisnis sistem
- `docs/DATABASE_SCHEMA.md` — skema database
- `docs/MOBILE_PLAN.md` — rencana pengerjaan tahap mobile (M1–M9)
- `AGENTS.md` — konteks dan aturan pengembangan agent

---

> Aplikasi ini dikembangkan sebagai bagian dari tugas akhir Sistem Informasi Manajemen.
