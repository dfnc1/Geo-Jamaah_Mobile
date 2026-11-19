# MOBILE_PLAN.md - Rencana Pengerjaan Aplikasi Mobile Geo-Jamaah

File ini adalah sumber kebenaran urutan kerja mobile. Agent membacanya
di awal setiap sesi, mengerjakan tahap berstatus ⬜ berurutan, lalu
memperbarui tabel status di bawah pada commit yang sama dengan kodenya.

## Status

| Tahap | Isi | Kode | Tes di perangkat |
|---|---|---|---|
| M1 | Setup, tema, API client | ✅ | ⬜ |
| M2 | Login dan routing per peran | ✅ | ⬜ |
| M3 | Beranda dan profil Mahasantri | ✅ | ⬜ |
| M4 | Presensi (lokasi, deteksi lokasi palsu) | ✅ | ⬜ |
| M5 | Izin Mahasantri | ✅ | ⬜ |
| M6 | Musyrif: verifikasi izin | ✅ | ⬜ |
| M7 | Musyrif: santri kritis, monitoring, grafik | ✅ | ⬜ |
| M8 | Perapian dan dokumentasi build | ✅ | ⬜ |
| M9 | Admin: rekap, tren, activity log, reset device, job | ✅ | ⬜ |

Kolom "Tes di perangkat" HANYA diubah oleh pemilik proyek (aku), bukan
agent.

## Aturan kerja (berlaku untuk semua tahap)

- Mode satu kali jalan: jangan berhenti meminta persetujuan rencana.
  Kerjakan semua tahap ⬜ berurutan tanpa menunggu tes. Pilih default
  paling sederhana yang konsisten dengan docs/ dan catat di bagian
  "Asumsi" pada laporan. Berhenti dan tanya HANYA jika: bertentangan
  dengan API_CONTRACT.md, butuh perubahan di backend, atau butuh paket
  yang membutuhkan keputusan besar.
- Sumber kebenaran: docs/API_CONTRACT.md, docs/FRONTEND_GUIDE.md,
  docs/Geo-Jamaah.png (desain login dan token visual), AGENTS.md.
  Jangan mengarang endpoint atau field.
- Aplikasi TIDAK menghitung apa pun yang menjadi tugas server (jarak,
  window waktu, status presensi, rasio, streak, kritis, status izin).
  Tampilkan apa adanya dari response.
- Status ditampilkan dengan ikon dan teks, bukan hanya warna. Kode error
  mentah tidak boleh tampil ke pengguna. 401 ditangani global (kembali
  ke login).
- Satu tahap = satu atau dua commit (Conventional Commits, subject
  Inggris, huruf kecil), selesai sebelum tahap berikutnya dimulai.
  Jangan push.
- Sebelum commit: flutter analyze dan flutter test harus bersih.
- JANGAN menjalankan flutter pub get, flutter clean, atau flutter run
  (IDE memakai Flutter Windows; menjalankannya dari WSL merusak
  .dart_tool). Cukup flutter analyze dan flutter test. Jika dependensi
  baru ditambahkan, tulis di laporan: "Jalankan flutter pub get dari
  Windows".
- Jangan menyimpan password. Token hanya di secure storage. Jangan
  mencatat password atau token di log.
- Struktur ringan, feature-first, tanpa lapisan domain/usecase dan tanpa
  code generation. Reuse widget di lib/core/widgets.
- Jawab dalam Bahasa Indonesia.

## M5: Izin Mahasantri

Endpoint: POST /v1/izin, GET /v1/izin/saya (lihat API_CONTRACT.md).
- Tab Izin (ganti placeholder di shell Mahasantri): daftar izin saya,
  urutan sesuai response. Tiap item: jenis (label "Sakit", "Pulang",
  "Tugas Kampus"), tanggal (10 karakter pertama dari tanggal_izin,
  format Indonesia), alasan ringkas (2 baris), StatusBadge (Pending,
  Disetujui, Ditolak). Pull-to-refresh, loading, kosong ("Belum ada
  pengajuan izin"), error dengan tombol coba lagi.
- Tombol "Ajukan Izin" membuka layar form di luar shell.
- Form: jenis (Sakit, Pulang, Tugas Kampus -> nilai Sakit, Pulang,
  Tugas_Kampus), tanggal (date picker, kirim YYYY-MM-DD dari tanggal
  lokal tanpa konversi zona; rentang 30 hari ke belakang sampai 90 hari
  ke depan), alasan (banyak baris, maksimal 500 karakter dengan
  penghitung, tidak boleh kosong atau hanya spasi).
- TANPA lampiran: jangan tampilkan tombol upload dan jangan kirim
  bukti_lampiran.
- Validasi lokal, tombol loading dan tidak bisa ditekan ganda. Sukses:
  kembali ke daftar, snackbar "Izin berhasil diajukan", muat ulang.
  Error: ERR_VALIDATION ("Data izin tidak valid"),
  ERR_MAHASANTRI_NOT_FOUND, jaringan, 429, kode lain pesan umum.
- Maksimal sekitar 6 file baru di lib/features/mahasantri/.
- Unit test: parsing JSON dari contoh kontrak (bukti_lampiran null),
  pemetaan jenis ke nilai kirim dan label, validasi form (kosong, spasi,
  501 karakter), format tanggal tanpa pergeseran zona, tekan ganda satu
  request.
- Commit: feat(mobile): add izin submission and list for mahasantri.

## M6: Musyrif, verifikasi izin

Endpoint: GET /v1/musyrif/izin?status=, PATCH
/v1/musyrif/izin/:id_izin/verify.
- Ganti placeholder beranda Musyrif dengan shell navigasi bawah (Izin,
  Santri, Profil), pola sama dengan shell Mahasantri
  (StatefulShellRoute). Tab Santri placeholder dulu.
- Tab Izin: daftar izin santri binaan. Filter chip: Pending (default),
  Disetujui, Ditolak, Semua (tanpa parameter status). Item: nama_mahasantri,
  NIM, jenis, tanggal, alasan ringkas, StatusBadge. Pull-to-refresh,
  loading, kosong per filter, error dengan coba lagi.
- Ketuk item: bottom sheet detail (alasan lengkap). Jika Pending: tombol
  "Setujui" dan "Tolak", masing-masing dengan dialog konfirmasi dan
  loading, tombol nonaktif selama request. PATCH body
  { status_persetujuan: "Disetujui" | "Ditolak" }.
- Error: 409 ERR_IZIN_ALREADY_DECIDED ("Izin sudah diputuskan. Daftar
  diperbarui.", muat ulang), 403 ERR_NOT_YOUR_STUDENT, 404
  ERR_IZIN_NOT_FOUND ("Izin tidak ditemukan", muat ulang), jaringan, 429,
  kode lain pesan umum. Sukses: tutup sheet, snackbar, muat ulang.
- Profil Musyrif: nama, nomor telepon (dari data user tersimpan),
  tombol Keluar dengan konfirmasi.
- Unit test: parsing daftar (nama_mahasantri), pemetaan filter ke query
  status, alur verifikasi sukses, 409 memuat ulang, tombol aksi hanya
  untuk Pending.
- Commit: feat(mobile): add musyrif leave verification.

## M7: Musyrif, santri kritis, monitoring, grafik

Endpoint: GET /v1/musyrif/dss/santri-kritis, GET
/v1/musyrif/presensi/monitoring?tanggal=, GET
/v1/musyrif/dashboard/tren-kehadiran?hari=.
- Tab Santri (ganti placeholder) dengan tiga bagian lewat segmented
  control atau tab atas: Kritis, Monitoring, Grafik.
- Kritis: kartu per santri (nama, NIM, rasio_kehadiran satu desimal,
  streak_alpha, jumlah hadir/tidak_hadir/izin, chip alasan, teks
  rekomendasi_tindakan). Petakan alasan "rasio" dan "streak" ke teks
  ("Kehadiran rendah", "Alpha berturut-turut"). Kosong: "Tidak ada santri
  kritis".
- Monitoring: pilih tanggal (default hari ini, tidak boleh masa depan).
  Tabel santri x jadwal yang bisa digulir horizontal dengan kolom nama
  tetap; sel berupa StatusBadge ringkas ("Belum" dibedakan). Ringkasan
  jumlah per status di atas tabel. Loading, kosong, error.
- Grafik: garis persen_hadir dengan fl_chart (tambahkan dependensi),
  pilihan 7, 14, 30 hari. Nilai null digambarkan terputus (bukan 0).
  Sumbu 0 sampai 100, label tanggal singkat, ringkasan teks nilai
  terakhir. Kosong dan error.
- Maksimal sekitar 8 file baru di lib/features/musyrif/.
- Unit test: parsing tiga respons dari contoh kontrak (nilai null,
  daftar kritis kosong), pemetaan alasan ke teks, tanggal masa depan
  ditolak.
- Commit: feat(mobile): add musyrif critical students, monitoring and
  chart.

## M8: Perapian dan dokumentasi

- Konsistensi: setiap layar punya loading, kosong, dan error; tidak ada
  kode error mentah ke pengguna; tidak ada perhitungan bisnis di aplikasi.
- Perbaikan dari tinjauan sebelumnya:
    - PresensiErrorMapper: jangan menampilkan error.message dari server;
      pakai teks tetap dari aplikasi.
    - Dialog ERR_DEVICE_MISMATCH: isi "Login ditolak: akun ini atau
      perangkat ini sudah terikat. Hubungi Admin untuk reset Device ID."
      (judul tetap "Perangkat tidak sesuai"). Perbarui test terkait.
- Hapus sisa TODO(M...) dan kode mati. Pastikan tidak ada print atau log
  yang memuat password atau token.
- Nama aplikasi "Geo-Jamaah", ikon peluncur dan splash sederhana dari
  warna #0F5132.
- README mobile: cara menjalankan (flutter run dengan
  --dart-define=API_BASE_URL=http://<IP-laptop>:3000/v1, tulis bahwa
  <IP-laptop> harus diganti angka asli), build APK (flutter build apk
  --release --dart-define=...), akun demo, catatan jaringan (emulator
  10.0.2.2, HP memakai IP LAN atau tunnel), JDK 17, dan batasan: tanpa
  refresh token, tanpa lampiran izin, tanpa layar Admin, tanpa
  notifikasi, token tidak terikat ke perangkat.
- Catat di README bahwa usesCleartextTraffic hanya untuk demo HTTP.
- flutter analyze tanpa peringatan, flutter test lulus.
- Commit terpisah: chore(mobile) lalu docs(mobile).

## M9: Admin Panel Mobile

Endpoint: GET /v1/admin/rekap, GET /v1/admin/dashboard/tren-kehadiran?hari=,
POST /v1/admin/mahasantri/:nim/reset-device, POST
/v1/admin/jobs/tandai-tidak-hadir, GET /v1/admin/activity-logs.
- Ganti placeholder Admin dengan AdminScreen fungsional lengkap (3 tab navigasi):
  - Tab 0 (Ringkasan): kartu metrik utama (Santri Aktif, Santri Kritis DSS),
    rekap presensi 30 hari (Hadir, Tidak Hadir, Izin, Manual, Total), rekap
    izin (Pending, Disetujui, Ditolak), dan grafik garis tren kehadiran global
    (7, 14, 30 hari). Pull-to-refresh.
  - Tab 1 (Log Aktivitas): audit trail aktivitas sistem, filter modul
    (Semua, Auth, Presensi, Izin, Masjid, Jadwal, Mahasantri, Jobs), waktu WIB,
    username & role, paginasi muat lebih banyak, pull-to-refresh.
  - Tab 2 (Kelola): aksi cepat Admin:
    - Form Reset Device ID Mahasantri (input NIM, validasi, dialog konfirmasi, feedback).
    - Pemicu Job Kehadiran Otomatis (eksekusi hari ini & backfill tanggal via date picker).
    - Profil Admin & tombol Keluar dengan konfirmasi.
- Domain & Data: `AdminRekap`, `PresensiRekap`, `IzinRekap`, `ResetDeviceResult`,
  `JobTandaiResult`, `ActivityLogItem`, `ActivityLogResponse`, `AdminRepository`,
  `AdminErrorMapper`, `AdminDashboardController`.
- Unit test: deserialisasi model JSON dari contoh kontrak, pemetaan kode error,
  uji form dan aksi.
- Commit: feat(mobile): implement admin dashboard, activity logs, and device reset.

## Checklist tes akhir (dijalankan pemilik proyek di HP)

Persiapan: backend menyala dengan seed dan pnpm seed:demo, koordinat
Masjid diatur ke lokasi uji (radius 100 m), satu jadwal sedang dalam
window, aplikasi dijalankan dengan alamat server yang benar, dan
jaringan terbukti (http://<IP>:3000/docs terbuka di browser HP).

1. Login: Mahasantri benar, password salah, akun nonaktif, Musyrif,
   Admin (dashboard Admin dengan rekap, tren, log, reset device), tutup-buka aplikasi tetap login.
2. Perangkat: akun yang sama dari perangkat lain ditolak, akun lain di
   perangkat yang sama ditolak, reset device lewat Swagger lalu berhasil.
3. Beranda: jadwal tampil, status berubah setelah presensi, muat ulang
   otomatis, server mati lalu coba lagi.
4. Presensi: di dalam radius berhasil, presensi kedua (pesan netral),
   di luar radius, di luar window, lokasi palsu ditolak, izin lokasi
   ditolak lalu diizinkan, GPS mati.
5. Izin Mahasantri: ajukan, tampil Pending, setujui dari Musyrif lalu
   berubah, validasi form.
6. Musyrif: daftar Pending, setujui, tolak, setujui dua kali (409),
   filter, profil.
7. Santri kritis (data demo: satu kritis, satu batas 75 persen tidak
   muncul), monitoring hari ini dan tanggal lampau, grafik 7 dan 30 hari.
8. Sesi kedaluwarsa kembali ke login.

## Alur setelah tes

- Jika semua lulus: pemilik proyek menulis "tes lulus", agent mengisi
  kolom "Tes di perangkat" menjadi ✅ untuk tahap yang disebut dan
  menutup pekerjaan (build APK release, ringkasan akhir).
- Jika ada temuan: pemilik proyek menulis daftar temuan (nomor
  checklist, perilaku yang terjadi, pesan error). Agent memperbaiki satu
  per satu sebagai commit fix(mobile) terpisah, mengulang analyze dan
  test, lalu melapor.