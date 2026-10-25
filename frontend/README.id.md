# Sumber Djaja — Frontend Flutter

[English](README.md) | **Bahasa Indonesia**

Aplikasi mutasi stok antar gudang untuk Studi Kasus 2. Android menjadi platform utama; versi web mendukung alur kerja yang sama. Label dan pesan validasi untuk operator menggunakan Bahasa Indonesia.

## Prasyarat

- Flutter dengan Dart 3.11+. Dikembangkan menggunakan Flutter 3.47.8 / Dart 3.13.7.
- Android Studio, Android SDK, lisensi SDK yang sudah diterima, serta emulator atau perangkat dengan USB debugging aktif.
- Android SDK Platform 36, Build-Tools 36, dan NDK `27.1.12297006`. Gradle menetapkan versi NDK agar hasil build konsisten. Instal komponen yang belum tersedia melalui SDK Manager di Android Studio.
- Chrome untuk web.
- Backend yang sudah berjalan dengan basis data yang telah dimigrasi dan diisi data awal: [panduan backend](../backend/README.id.md).

Dari direktori ini:

```sh
flutter doctor
flutter pub get
```

## Android

Jalankan emulator melalui Device Manager di Android Studio, atau gunakan:

```sh
flutter emulators
flutter emulators --launch <emulator-id>
flutter devices
flutter run -d <android-device-id>
```

Android secara bawaan menggunakan `http://10.0.2.2:3000/api` untuk mengakses backend pada komputer host dari emulator standar. Backend harus menerima koneksi pada `0.0.0.0:3000`, sesuai konfigurasi contoh.

Untuk perangkat fisik, gunakan alamat IP LAN komputer. Pastikan kedua perangkat berada pada jaringan yang sama dan izinkan koneksi ke port backend melalui firewall:

```sh
flutter run -d <android-device-id> --dart-define=API_BASE_URL=http://192.168.1.10:3000/api
```

Sebagai alternatif, teruskan port melalui USB:

```sh
adb reverse tcp:3000 tcp:3000
flutter run -d <android-device-id> --dart-define=API_BASE_URL=http://127.0.0.1:3000/api
```

Manifest Android mengizinkan akses internet dan HTTP untuk demo lokal. Formulir dapat digulir dan menyesuaikan ukuran saat keyboard terbuka.

```sh
flutter build apk --debug
```

APK: `build/app/outputs/flutter-apk/app-debug.apk`. Penandatanganan aplikasi rilis dan deployment berada di luar cakupan.

## Web

```sh
flutter run -d chrome --web-port=5173
```

Web secara bawaan menggunakan `http://localhost:3000/api`. Konfigurasi contoh backend mengizinkan `http://localhost:5173` dan `http://127.0.0.1:5173` melalui `CORS_ORIGINS`. Jalankan ulang backend setelah mengubah CORS.

```sh
flutter run -d chrome --web-hostname=127.0.0.1 --web-port=5173 --dart-define=API_BASE_URL=http://127.0.0.1:3000/api
flutter build web --dart-define=API_BASE_URL=http://localhost:3000/api
```

`API_BASE_URL` menyertakan `/api` dan ditetapkan saat kompilasi. Jalankan ulang atau build ulang setelah mengubahnya. HTTP digunakan untuk pengembangan lokal; aplikasi web dengan origin HTTPS memerlukan API HTTPS.

## Struktur dan Panduan Membaca Kode

```text
lib/
  main.dart
  app/                         Pengaturan, dependensi, tema, navigasi
  core/
    config/                    Konfigurasi API sesuai platform
    network/                   Klien HTTP, kesalahan API, paginasi
    utils/                     Validasi dan format waktu WIB
  shared/
    controllers/               Paginasi dan penyimpanan master yang digunakan bersama
    widgets/                   Pencarian, pemilih, formulir, umpan balik, tata letak
  features/
    items/                     Master barang dan formulir
    warehouses/                Master gudang dan formulir
    stocks/                    Pemilihan gudang dan saldo stok
    transfers/                 Formulir, riwayat, rincian yang tidak dapat diubah
```

Ikuti alur kerja dari layar ke controller, repository, dan model data. Repository menangani endpoint dan konversi JSON; controller menangani state dan validasi; berkas presentasi menangani widget dan navigasi. Controller bersama menangani perilaku yang digunakan berulang kali. Dependensi dibuat satu kali dalam `app/app_dependencies.dart` dan diteruskan secara eksplisit.

Kode menggunakan identifier Bahasa Inggris yang deskriptif, named parameter, format Dart, dan baris kosong di antara langkah logis. Komentar menjelaskan batasan bisnis dan perilaku asinkron. Widget khusus fitur ditempatkan bersama fitur terkait.

## Perilaku Aplikasi

- Empat tujuan navigasi: Barang, Gudang, Stok Gudang, dan Mutasi. Ponsel menggunakan navigasi bawah; jendela lebar menggunakan panel navigasi samping.
- Pencarian dan paginasi diproses oleh server. Pemilih gudang mendukung halaman berikutnya. Data ketersediaan untuk mutasi diambil dari seluruh halaman stok agar barang di luar halaman pertama tetap dapat dipilih.
- Spasi di awal/akhir nilai master dihapus; SKU/kode diubah menjadi huruf kapital. Kesalahan duplikat atau satuan terkunci dari backend ditampilkan langsung pada kolom terkait. Pembuatan/perubahan master tidak pernah menambahkan stok.
- Mutasi berisi 1–50 barang berbeda dengan jumlah bilangan bulat positif hingga 2,147,483,647. Gudang sumber dan tujuan harus berbeda. Mengubah sumber akan mengosongkan baris barang dan memuat stok sumber baru.
- Informasi ketersediaan hanya menjadi acuan; backend memeriksa saldo dalam transaksinya. Respons konflik stok mempertahankan formulir dan memperbarui informasi ketersediaan.
- Selama pengiriman diproses, perubahan formulir, navigasi kembali, dan pengiriman ulang dinonaktifkan. Permintaan POST mutasi tidak pernah diulang secara otomatis.
- Jika hasil pengiriman tidak dapat dipastikan, percobaan berikutnya dikunci. Draf tetap terbuka saat operator memeriksa riwayat; saat kembali, stok sumber juga dimuat ulang. Hanya setelah kedua permintaan berhasil, konfirmasi pengguna bahwa tidak ada mutasi yang sesuai dapat mengizinkan pengiriman berikutnya. Mekanisme ini tidak menyediakan idempotensi di sisi server.
- Setelah berhasil, aplikasi membuka referensi/rincian mutasi dan memuat ulang riwayat. Saat kembali ke halaman stok, saldo terbaru diambil. Mutasi yang sudah selesai tidak dapat diubah atau dihapus.
- Waktu menggunakan Asia/Jakarta (UTC+7) dengan label WIB, terlepas dari zona waktu perangkat.

## Verifikasi dan Demo

```sh
dart format --output=none --set-exit-if-changed lib
flutter analyze
flutter build apk --debug
flutter build web
```

Tidak ada framework pengujian yang ditambahkan. Periksa secara manual pada Android, lalu ulangi alur kerja inti pada web:

1. Dengan data contoh awal, Gudang A menampilkan BRG-001 = 100, BRG-002 = 50, BRG-003 = 0. Gudang B menampilkan 20, 0, 30.
2. Buat/ubah barang dan gudang. Coba kolom wajib yang kosong dan kode duplikat. Master baru memiliki stok nol; perubahan mempertahankan saldo.
3. Pindahkan 10 BRG-001 dari A ke B, dengan tambahan 5 BRG-002 jika diinginkan. Periksa referensi keberhasilan, kedua baris rincian, filter riwayat, dan pembukaan kembali rincian.
4. Pastikan BRG-001 berjumlah 90 di A dan 30 di B. Jika disertakan, BRG-002 berjumlah 45 di A dan 5 di B.
5. Coba jumlah desimal, nol, atau berlebihan. Tambah/hapus baris dan ubah sumber untuk memeriksa pengosongan baris. Coba pencarian tanpa hasil dan buka halaman berikutnya pada daftar/pemilih.
6. Simulasikan kegagalan koneksi. Daftar menyediakan pilihan coba lagi; pengiriman yang gagal mempertahankan isian dan memerlukan peninjauan hasil. Pulihkan koneksi dan gunakan kontrol peninjauan/coba lagi yang tersedia.
7. Periksa tampilan pada lebar layar ponsel dan formulir saat keyboard terbuka.

Gunakan petunjuk seed/reset yang eksplisit dalam panduan backend untuk mengembalikan data contoh. Menjalankan aplikasi tidak pernah mereset atau mengisi ulang stok secara otomatis.

### Hasil Verifikasi Lokal

Pada 25 Oktober 2026, analisis Flutter serta build APK debug Android dan build rilis web berhasil. Pemeriksaan Chrome mencakup pembuatan/perubahan master, validasi kolom wajib/duplikat, stok nol, pengiriman beberapa barang, filter riwayat, pencarian tanpa hasil, kesalahan koneksi daftar/coba lagi, serta peninjauan pengiriman yang hasilnya tidak pasti dengan isian tetap tersimpan. Simulasi respons stok yang sudah kedaluwarsa juga memverifikasi penolakan konflik stok oleh backend: formulir mempertahankan jumlah 29, memperbarui ketersediaan aktual menjadi 28, dan tidak membuat mutasi. Build web produksi dimuat tanpa kesalahan konsol.

Pada emulator Pixel 3a dengan Android API 34, aplikasi memuat stok/riwayat dari backend, menerima isian jumlah saat keyboard terbuka, dan menyelesaikan mutasi 2 BRG-003 dari Gudang B ke Gudang C yang baru dibuat. Referensi/rincian yang dikembalikan ditampilkan dan API melaporkan jumlah 2 di C. Perubahan satuan barang yang sudah ada juga menampilkan kesalahan satuan terkunci dari backend langsung pada kolom terkait. Verifikasi lokal sengaja membuat master dan mutasi demo; gunakan alur reset yang didokumentasikan saat membutuhkan data contoh semula.
