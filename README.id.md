# Sumber Djaja — Aplikasi Mutasi Stok Antar Gudang

[English](README.md) | **Bahasa Indonesia**

Implementasi full-stack untuk **Studi Kasus 2: Mutasi Stok Antar Gudang** dalam [tes praktik full-stack developer](Practical_Test_Fullstack_Developer.md). Aplikasi ini mengelola barang, gudang, saldo stok, dan mutasi melalui aplikasi Flutter dan REST API. Android menjadi platform utama; versi web mendukung alur kerja inti yang sama.

Lihat [dokumen kebutuhan produk](prd.md), [panduan backend](backend/README.id.md), dan [panduan frontend](frontend/README.id.md) untuk rincian kontrak API, konfigurasi, dan catatan implementasi.

## Fitur

- Membuat dan mengubah master barang serta gudang, dengan pencarian, paginasi, dan validasi kode duplikat.
- Melihat stok per gudang, termasuk barang dengan saldo nol.
- Memindahkan beberapa barang berbeda antar gudang dengan jumlah berupa bilangan bulat positif.
- Memperbarui stok sumber, stok tujuan, dan riwayat mutasi dalam satu transaksi basis data. Stok yang tidak mencukupi atau kegagalan operasi lain membatalkan seluruh perubahan dalam mutasi tersebut.
- Menelusuri riwayat mutasi, menyaring berdasarkan gudang sumber/tujuan, dan membuka rincian mutasi yang tidak dapat diubah.
- Menggunakan tata letak responsif, label dan validasi berbahasa Indonesia, serta waktu yang ditampilkan dalam WIB (UTC+7).
- Menjelajahi API melalui Swagger UI dan spesifikasi OpenAPI.

## Teknologi dan Struktur

| Lapisan | Teknologi |
| --- | --- |
| Frontend | Flutter / Dart, Android dan web |
| Backend | Node.js / JavaScript ES modules, Express 5 |
| Basis data | MySQL / InnoDB, kompatibel dengan MariaDB |
| Akses data | Drizzle ORM, Drizzle Kit, migrasi SQL berversi |
| Dokumentasi API | OpenAPI dan Swagger UI |

```text
backend/
  src/                 Rute API, validasi, layanan, repositori, basis data
  drizzle/             Migrasi SQL dan metadata
  docs/openapi.yaml    Spesifikasi API
  compose.yaml         Layanan MySQL lokal
frontend/
  lib/app/             Pengaturan aplikasi, dependensi, tema, navigasi
  lib/core/            Konfigurasi API, jaringan, utilitas
  lib/shared/          Controller dan widget bersama
  lib/features/        Barang, gudang, stok, mutasi
prd.md                 Cakupan, aturan bisnis, kriteria penerimaan
```

Basis data terdiri dari tabel `items`, `warehouses`, `warehouse_stocks`, `stock_transfers`, dan `stock_transfer_items`. Foreign key menjaga hubungan antartabel; penguncian baris dengan urutan yang konsisten menjaga stok saat beberapa mutasi berlangsung bersamaan. Lihat [struktur basis data](backend/README.id.md#struktur-basis-data) untuk batasan data dan [struktur frontend](frontend/README.id.md#struktur-dan-panduan-membaca-kode) untuk pembagian tanggung jawab layar, controller, dan repository.

## Prasyarat

- Node.js 22+ dan npm.
- MySQL 8.4 (disarankan) atau MariaDB 10.4+ dengan InnoDB, yang dijalankan secara lokal melalui Laragon atau instalasi lainnya. Sebagai alternatif, gunakan Docker Compose untuk layanan MySQL 8.4 yang disertakan.
- Flutter dengan Dart 3.11+.
- Untuk Android: Android Studio, lisensi SDK yang sudah diterima, emulator atau perangkat dengan USB debugging aktif, Android SDK Platform 36, Build-Tools 36, dan NDK `27.1.12297006`.
- Untuk web: Chrome.

## Menjalankan Aplikasi Secara Lokal

### 1. Jalankan Backend

Dari direktori utama repositori, instal dependensi dan buat berkas konfigurasi lokal. Jika `.env` sudah ada dan telah dikonfigurasi, pertahankan berkas tersebut dan lewati perintah penyalinan:

```sh
cd backend
npm ci
cp .env.example .env
```

Pilih salah satu opsi basis data berikut, lalu lanjutkan ke langkah migrasi dan menjalankan API.

#### Opsi A: Docker Compose

Konfigurasi contoh `.env` sudah sesuai dengan layanan MySQL yang disertakan:

```sh
docker compose up -d --wait
```

#### Opsi B: Laragon (Tanpa Docker)

1. Buka Laragon dan jalankan layanan MySQL. Gunakan MySQL 8.4 atau instalasi MariaDB 10.4+ yang kompatibel dengan InnoDB.
2. Hubungkan aplikasi klien basis data ke server tersebut sebagai `root` atau administrator lain, lalu jalankan SQL berikut satu kali untuk instalasi baru:

```sql
CREATE DATABASE warehouse_transfer
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'warehouse'@'127.0.0.1' IDENTIFIED BY 'warehouse_dev';
GRANT ALL PRIVILEGES ON warehouse_transfer.* TO 'warehouse'@'127.0.0.1';
```

3. Atur URL koneksi dalam `backend/.env`. Contoh ini menggunakan port 3306 untuk basis data Laragon:

```dotenv
DATABASE_URL=mysql://warehouse:warehouse_dev@127.0.0.1:3306/warehouse_transfer
```

Sesuaikan URL jika port, nama pengguna, atau kata sandi basis data berbeda. Variabel `MYSQL_*` hanya digunakan untuk konfigurasi Docker; pengaturan Laragon menggunakan `DATABASE_URL`. Laragon mengelola basis data, sedangkan API dijalankan melalui npm pada port 3000. Repositori dapat tetap berada di folder saat ini.

Lihat [panduan lengkap Laragon](backend/README.id.md#opsi-b-laragon-tanpa-docker) untuk perintah login melalui terminal, pemeriksaan koneksi, dan penanganan masalah. Gunakan satu layanan basis data per port saat berganti antara Laragon dan Docker.

#### Migrasi, Pengisian Data Awal, dan Menjalankan API

Untuk kedua opsi basis data, jalankan dari direktori `backend/`:

```sh
npm run db:migrate
npm run db:seed
npm run dev
```

Pengisian data awal (seed) hanya dapat dijalankan ketika seluruh tabel aplikasi kosong. Untuk instalasi yang sudah berisi data, terapkan migrasi yang belum dijalankan dan mulai API tanpa mengulangi seed. Hentikan API sebelum menjalankan seed atau reset secara manual pada instalasi yang sudah ada. Menjalankan API tidak akan mereset atau mengisi ulang data secara otomatis.

Konfigurasi contoh menerima koneksi pada `0.0.0.0:3000` agar dapat diakses dari Android. Jika menggunakan Docker, sesuaikan `DATABASE_URL` setiap kali pengaturan basis datanya berubah. Lihat [panduan konfigurasi backend](backend/README.id.md#konfigurasi) untuk seluruh variabel.

| Layanan | URL Lokal |
| --- | --- |
| URL dasar API | <http://localhost:3000/api> |
| Kesiapan basis data | <http://localhost:3000/api/health> |
| Swagger UI | <http://localhost:3000/api/docs> |
| OpenAPI JSON | <http://localhost:3000/api/openapi.json> |

Dokumentasi tetap dapat diakses saat basis data tidak tersedia. Endpoint kesiapan mengembalikan HTTP 503 sampai koneksi dan tabel hasil migrasi siap digunakan.

### 2. Jalankan Frontend

Buka terminal kedua pada direktori utama repositori:

```sh
cd frontend
flutter doctor
flutter pub get
flutter devices
```

Jalankan emulator Android atau hubungkan perangkat, lalu ganti `<android-device-id>` dengan ID perangkat tersebut:

```sh
flutter run -d <android-device-id>
```

Sebagai alternatif, jalankan aplikasi web:

```sh
flutter run -d chrome --web-port=5173
```

### Koneksi ke API

| Klien | URL Dasar API |
| --- | --- |
| Emulator Android standar | `http://10.0.2.2:3000/api` (bawaan untuk Android) |
| Web pada komputer pengembangan | `http://localhost:3000/api` (bawaan untuk web) |
| Perangkat Android fisik pada jaringan yang sama | `http://<computer-LAN-IP>:3000/api` |

Untuk perangkat fisik, izinkan koneksi masuk ke port 3000 dan gunakan alamat IP LAN komputer:

```sh
flutter run -d <android-device-id> --dart-define=API_BASE_URL=http://192.168.1.10:3000/api
```

`API_BASE_URL` harus menyertakan `/api` dan ditetapkan saat kompilasi. Jalankan ulang atau build ulang aplikasi setelah mengubahnya. Konfigurasi contoh backend mengizinkan origin browser `http://localhost:5173` dan `http://127.0.0.1:5173`. Perbarui `CORS_ORIGINS` dan jalankan ulang backend jika origin web berubah. Lihat [panduan frontend](frontend/README.id.md#android) untuk penerusan port melalui USB dan pengaturan perangkat lainnya.

## Alur Demo

Seed pada basis data kosong menghasilkan saldo awal berikut:

| SKU | Barang | Satuan | Gudang A | Gudang B |
| --- | --- | --- | --- | --- |
| BRG-001 | Baut | pcs | 100 | 20 |
| BRG-002 | Mur | pcs | 50 | 0 |
| BRG-003 | Ring | pcs | 0 | 30 |

1. Buka **Stok Gudang** dan periksa saldo kedua gudang.
2. Buka **Mutasi**, pilih Gudang A sebagai sumber dan Gudang B sebagai tujuan, lalu pindahkan 10 BRG-001. Jika diinginkan, tambahkan 5 BRG-002.
3. Periksa nomor referensi yang muncul setelah berhasil, rincian mutasi, dan riwayat menggunakan filter.
4. Pastikan stok BRG-001 menjadi 90 di A dan 30 di B. Jika BRG-002 disertakan, stoknya menjadi 45 di A dan 5 di B.
5. Coba jumlah yang tidak valid atau melebihi stok. Pastikan isian formulir tetap tersimpan dan stok maupun riwayat tidak berubah.
6. Buat/ubah data **Barang** dan **Gudang**. Data baru memiliki stok awal nol; perubahan metadata tidak mengubah saldo.

Untuk mengembalikan data contoh setelah demo, ikuti [petunjuk seed/reset](backend/README.id.md#migrasi-seed-dan-reset). Langkah pemeriksaan manual lengkap tersedia dalam [panduan backend](backend/README.id.md#pemeriksaan-manual) dan [panduan frontend](frontend/README.id.md#verifikasi-dan-demo).

## Verifikasi dan Build

Dari direktori `backend/`:

```sh
npm run check
npm run db:check
```

Perintah tersebut memeriksa sintaks JavaScript, penguraian YAML, dan riwayat migrasi. Pemeriksaan ini tidak memverifikasi perilaku transaksi atau akses bersamaan; gunakan langkah pemeriksaan manual backend untuk kasus tersebut.

Dari direktori `frontend/`:

```sh
dart format --output=none --set-exit-if-changed lib
flutter analyze
flutter build apk --debug
flutter build web
```

Hasil build tersedia di `frontend/build/app/outputs/flutter-apk/app-debug.apk` dan `frontend/build/web/`. Tambahkan `--dart-define=API_BASE_URL=...` saat melakukan build untuk alamat API yang berbeda. Proyek ini tidak menyertakan rangkaian pengujian otomatis; lihat [catatan verifikasi frontend](frontend/README.id.md#hasil-verifikasi-lokal) untuk hasil pemeriksaan lokal yang telah dicatat.

## Cakupan dan Perilaku Aplikasi

Stok awal berasal dari seed; penerimaan barang dan penyesuaian stok manual berada di luar cakupan. Mutasi langsung selesai tanpa tahap persetujuan dan tidak dapat diubah, dibatalkan, atau dihapus. Satuan barang tidak dapat diubah setelah terdapat baris stok atau riwayat mutasi. Riwayat menampilkan nama/kode master terkini, bukan salinan data pada saat transaksi.

Backend belum menyediakan idempotensi di sisi server, sehingga pengiriman permintaan yang sama berulang kali dapat menghasilkan mutasi berulang. Frontend menonaktifkan pengiriman ulang selama permintaan masih diproses dan tidak pernah mengulangi POST mutasi secara otomatis. Jika hasil pengiriman tidak dapat dipastikan, pengguna harus meninjau riwayat serta stok yang telah dimuat ulang sebelum secara eksplisit mengizinkan percobaan berikutnya.

Autentikasi, peran pengguna, penandatanganan aplikasi rilis, dan deployment berada di luar cakupan. Konfigurasi HTTP ditujukan untuk pengembangan lokal; aplikasi web dengan origin HTTPS memerlukan API HTTPS.
