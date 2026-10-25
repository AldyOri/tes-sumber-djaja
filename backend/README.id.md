# API Mutasi Stok Antar Gudang

[English](README.md) | **Bahasa Indonesia**

Backend untuk **Studi Kasus 2: Mutasi Stok Antar Gudang**, berdasarkan [dokumen kebutuhan produk](../prd.md). Teknologi yang digunakan: Node.js/JavaScript ES modules, Express 5, MySQL/InnoDB, Drizzle ORM, dan Drizzle Kit. Dependensi dikelola melalui npm dengan `package-lock.json` yang disertakan dalam repositori; skrip aplikasi dijalankan menggunakan Node.js.

## Prasyarat dan Menjalankan Aplikasi

- Node.js 22+ (dikembangkan menggunakan Node.js 24).
- npm (disertakan bersama Node.js).
- MySQL 8.4 (disarankan) atau MariaDB 10.4+ dengan InnoDB. Gunakan Laragon, instalasi basis data lokal yang sudah ada, atau Docker Compose (layanan yang disertakan menggunakan MySQL 8.4).

Jalankan dari direktori utama repositori. Perintah `cp` tersedia di PowerShell dan shell Unix pada umumnya. Pertahankan `.env` yang sudah ada jika telah dikonfigurasi.

```sh
cd backend
npm ci
cp .env.example .env
```

Pilih **satu** opsi basis data berikut, lalu lanjutkan ke langkah migrasi dan menjalankan aplikasi.

### Opsi A: Docker Compose

Konfigurasi contoh `.env` sudah sesuai dengan nama basis data, akun, kata sandi, dan port dalam `compose.yaml`:

```sh
docker compose up -d --wait
```

### Opsi B: Laragon (Tanpa Docker)

Laragon mengelola layanan basis data lokal; API Express dijalankan secara terpisah melalui npm. Repositori dapat tetap berada di folder saat ini, dan API diakses melalui `http://localhost:3000/api`.

1. Instal/buka Laragon dan jalankan layanan MySQL melalui menu layanan. Gunakan MySQL 8.4 (disarankan) atau MariaDB 10.4+ dengan InnoDB. Periksa versi server yang digunakan karena setiap instalasi Laragon dapat memiliki versi berbeda. Lihat [menu layanan Laragon](https://laragon.app/docs/context-menu) dan [cara menambahkan versi MySQL](https://laragon.org/docs/operations).
2. Buka **Terminal** Laragon, yang menyediakan alat-alatnya melalui `PATH`. Hubungkan sebagai `root` atau administrator basis data lain dengan port yang dikonfigurasi di Laragon (3306 pada contoh ini):

```sh
mysql -h 127.0.0.1 -P 3306 -u root -p
```

Masukkan kata sandi akun administrator saat diminta. Jika akun tersebut dikonfigurasi tanpa kata sandi, tekan Enter. SQL berikut juga dapat dijalankan melalui jendela kueri pada aplikasi klien basis data yang terhubung sebagai administrator. Lihat [lingkungan terminal Laragon](https://laragon.org/docs/isolated).

3. Periksa versi server, lalu buat basis data kosong dan akun aplikasi satu kali untuk instalasi baru:

```sql
SELECT VERSION();

CREATE DATABASE warehouse_transfer
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'warehouse'@'127.0.0.1' IDENTIFIED BY 'warehouse_dev';
GRANT ALL PRIVILEGES ON warehouse_transfer.* TO 'warehouse'@'127.0.0.1';
```

Jika menggunakan klien `mysql`, jalankan `EXIT;` setelahnya untuk kembali ke terminal. Akun aplikasi memiliki izin migrasi serta baca/tulis pada basis datanya. Jika basis data/akun sudah ada, gunakan kembali kredensial dan izin yang telah dikonfigurasi. Pengaturan akun mengikuti [alur CREATE USER dan GRANT MySQL](https://dev.mysql.com/doc/refman/8.4/en/creating-accounts.html).

4. Ubah `backend/.env` agar sesuai dengan koneksi basis data:

```dotenv
DATABASE_URL=mysql://warehouse:warehouse_dev@127.0.0.1:3306/warehouse_transfer
```

URL ini sesuai dengan contoh SQL dan `.env.example`. Sesuaikan port, nama pengguna, kata sandi, atau nama basis data dengan instalasi Anda. Gunakan percent-encoding untuk karakter khusus pada kredensial URL, misalnya `@` menjadi `%40` dan `#` menjadi `%23`. MariaDB juga menggunakan skema URL `mysql://`. Variabel `MYSQL_*` hanya digunakan oleh Docker Compose; mengubahnya tidak mengatur Laragon atau koneksi API.

5. Jika diperlukan, periksa login akun aplikasi melalui Terminal Laragon. Masukkan `warehouse_dev` saat diminta kata sandi, lalu jalankan `SELECT DATABASE(), VERSION();` dan `EXIT;`:

```sh
mysql -h 127.0.0.1 -P 3306 -u warehouse -p warehouse_transfer
```

Lanjutkan dengan perintah npm berikut melalui PowerShell atau terminal lain yang menyediakan Node.js 22+ dan npm.

### Migrasi, Seed, dan Menjalankan API

Untuk kedua opsi basis data, jalankan dari direktori `backend/`:

```sh
npm run db:migrate
npm run db:seed
npm run dev
```

Jalankan seed hanya pada basis data aplikasi yang sudah dimigrasi dan masih kosong. Untuk instalasi yang sudah berisi data, terapkan migrasi yang belum dijalankan dan mulai API tanpa mengulangi `db:seed`. Skema menggunakan `utf8mb4_unicode_ci`, yang tersedia pada kedua basis data, dan pembacaan bersama menggunakan `LOCK IN SHARE MODE` untuk kompatibilitas.

Kredensial contoh ditujukan untuk demo lokal. Berkas `.env` diabaikan oleh Git. Docker membatasi akses basis data ke localhost; untuk instalasi lokal, gunakan koneksi loopback di atas. API menerima koneksi pada seluruh antarmuka jaringan agar dapat diakses dari Android. Gunakan `npm start` untuk menjalankan tanpa mode pemantauan perubahan. Saat menambahkan dependensi, gunakan `npm install <package>` (atau `npm install --save-dev <package>`) dan sertakan perubahan `package.json` serta `package-lock.json` dalam commit.

- API: <http://localhost:3000/api>
- Kesiapan layanan: <http://localhost:3000/api/health>
- Swagger UI: <http://localhost:3000/api/docs>
- OpenAPI JSON: <http://localhost:3000/api/openapi.json>

API tetap berjalan meskipun MySQL tidak tersedia agar dokumentasi dapat diakses. Endpoint kesiapan mengembalikan 503 sampai koneksi dan tabel aplikasi hasil migrasi siap digunakan.

### Penanganan Masalah Basis Data Lokal

- **Port sudah digunakan:** Laragon, XAMPP, layanan MySQL Windows, dan Docker dapat menggunakan port 3306 secara bersamaan. Jalankan satu layanan basis data pada port tersebut, atau gunakan port berbeda dan sesuaikan `DATABASE_URL` agar mengarah ke server yang dimaksud.
- **`ECONNREFUSED` / koneksi ditolak:** jalankan layanan basis data dan pastikan host/port sesuai dengan `DATABASE_URL`.
- **`ER_ACCESS_DENIED_ERROR` / akses ditolak:** periksa akun, kata sandi, dan host. Akun contoh adalah `'warehouse'@'127.0.0.1'`, sesuai dengan host TCP pada URL. Periksa kembali izinnya sebagai administrator.
- **`ER_BAD_DB_ERROR` / basis data tidak ditemukan:** buat basis data pada server yang ditunjuk oleh `DATABASE_URL` sebelum menjalankan migrasi.
- **Seed menolak dijalankan:** data aplikasi sudah ada. Gunakan data tersebut, atau ikuti [petunjuk reset](#migrasi-seed-dan-reset) untuk mengembalikan data contoh.

## Konfigurasi

| Variabel | Bawaan/contoh | Kegunaan |
| --- | --- | --- |
| `NODE_ENV` | `development` | `development` atau `production`; mode produksi menonaktifkan reset. |
| `HOST` | `0.0.0.0` | Alamat tempat API menerima koneksi HTTP. |
| `PORT` | `3000` | Port HTTP. |
| `DATABASE_URL` | Lihat `.env.example` | URL koneksi MySQL yang wajib diisi. |
| `DB_POOL_SIZE` | `10` | Ukuran pool, 1–100 koneksi. |
| `DB_LOCK_TIMEOUT_SECONDS` | `5` | Batas waktu tunggu penguncian InnoDB, 1–60 detik. |
| `CORS_ORIGINS` | `http://localhost:5173,http://127.0.0.1:5173` | Daftar origin browser dipisahkan koma; sertakan skema/port, tanpa garis miring di akhir dan tanpa wildcard. |
| `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_ROOT_PASSWORD`, `MYSQL_PORT` | Lihat `.env.example` | Hanya untuk Docker Compose; sesuaikan `DATABASE_URL` saat menggunakan Docker. Laragon menggunakan `DATABASE_URL` secara langsung. |

Jalankan ulang API setelah mengubah konfigurasi. Variabel inisialisasi Docker diterapkan saat volume pertama kali dibuat; mengubah `.env` tidak memperbarui kata sandi MySQL yang sudah ada. Permintaan Swagger dari origin yang sama dan klien tanpa header Origin diterima. CORS merupakan kebijakan browser; MVP ini tidak memiliki autentikasi.

## Struktur Basis Data

Sumber skema: [`src/db/schema.js`](src/db/schema.js). SQL berversi dan metadata: [`drizzle/`](drizzle/). Migrasi awal secara eksplisit menggunakan InnoDB, UTF-8, dan `utf8mb4_unicode_ci`.

| Tabel | Hubungan dan Batasan |
| --- | --- |
| `items` | ID utama, SKU unik, nama, satuan, serta waktu pembuatan/pembaruan dalam UTC. |
| `warehouses` | ID utama, kode unik, nama, alamat opsional, serta waktu dalam UTC. |
| `warehouse_stocks` | PK gabungan `(warehouse_id, item_id)`, FK dengan RESTRICT ke kedua master, batas jumlah 0–2,147,483,647. |
| `stock_transfers` | ID utama, referensi unik, FK sumber/tujuan dengan RESTRICT, batasan gudang harus berbeda, catatan, waktu dalam UTC. |
| `stock_transfer_items` | ID utama, FK mutasi/barang dengan RESTRICT, keunikan `(transfer_id, item_id)`, batas jumlah 1–2,147,483,647. |

FK dan waktu riwayat memiliki indeks. Saldo stok menjadi acuan operasional. Saldo dari seed merupakan stok awal, sehingga riwayat mutasi bukan buku besar persediaan yang lengkap.

## Migrasi, Seed, dan Reset

```sh
# Setelah mengubah skema Drizzle, buat dan tinjau migrasi baru.
npm run db:generate -- --name=describe_change

# Periksa riwayat migrasi, lalu terapkan migrasi yang belum dijalankan.
npm run db:check
npm run db:migrate

# Isi data contoh secara eksplisit pada basis data yang sudah dimigrasi dan kosong.
npm run db:seed
```

Penerapan migrasi menggunakan migrator MySQL Drizzle pada koneksi khusus dan tidak pernah menjalankan seed secara otomatis. DDL MySQL/MariaDB tidak sepenuhnya transaksional: periksa basis data jika migrasi gagal di tengah proses sebelum menjalankannya kembali. Gunakan InnoDB dan `utf8mb4_unicode_ci` untuk tabel aplikasi yang ditambahkan berikutnya.

Jika revisi sebelumnya gagal pada perintah `CREATE TABLE` pertama dengan pesan `Unknown collation: utf8mb4_0900_ai_ci`, perbarui kode dan jalankan kembali `npm run db:migrate`. Perintah yang gagal tersebut belum membuat tabel, sehingga kasus ini tidak memerlukan reset atau penghapusan data. Pesan kegagalan migrasi kini menyertakan kode kesalahan basis data tanpa mencetak SQL atau kredensial.

Jika XAMPP kemudian berhenti pada `Creating table` dan `mysql_error.log` melaporkan kesalahan tablespace InnoDB (misalnya pada `mysql.gtid_slave_pos.ibd`), selesaikan masalah server basis data sebelum mencoba kembali. Masalah ini terpisah dari collation yang tidak didukung. Perubahan kompatibilitas telah diverifikasi secara manual pada MariaDB 10.4.28 yang bersih, termasuk migrasi berulang, seed, mutasi, rollback, dan permintaan stok bersamaan.

Seed menolak dijalankan jika **salah satu tabel aplikasi sudah berisi data**. Data demo yang sedang digunakan tidak akan ditimpa. Perintah seed/reset menggunakan advisory lock yang sama untuk mencegah skrip pemeliharaan berjalan bersamaan. Hentikan API sebelum menjalankan salah satu perintah agar penulisan data aplikasi tidak berlangsung bersamaan dengan pemeliharaan.

| SKU (ID) | Barang | Satuan | Gudang A (ID 1) | Gudang B (ID 2) |
| --- | --- | --- | --- | --- |
| BRG-001 (1) | Baut | pcs | 100 | 20 |
| BRG-002 (2) | Mur | pcs | 50 | 0 |
| BRG-003 (3) | Ring | pcs | 0 | 30 |

Saldo nol sengaja tidak memiliki baris stok fisik. Kueri stok menampilkan nol; mutasi membuat baris stok tujuan jika diperlukan. Pembuatan data master tidak pernah menambahkan stok awal.

Untuk menghapus data aplikasi dan mengembalikan data contoh, hentikan API dan konfirmasikan nama basis data dari `DATABASE_URL` secara eksplisit:

```sh
npm run db:reset -- --confirm=warehouse_transfer
```

Reset menghapus baris aplikasi sesuai urutan FK dan menjalankan seed dalam satu transaksi. Jika gagal, perubahan dibatalkan sehingga data sebelumnya dipertahankan. Metadata migrasi tetap disimpan; penghitung auto-increment tidak direset. Tidak ada reset saat aplikasi dimulai. `NODE_ENV=production` menonaktifkan perintah ini. Untuk menghentikan layanan Docker dengan tetap menyimpan data, gunakan `docker compose down`.

## Kontrak API

Semua path berikut diawali `/api`. POST/PUT memerlukan `Content-Type: application/json`; batas ukuran body adalah 64 KiB. Spesifikasi Swagger mencakup seluruh skema permintaan/respons dan contohnya.

| Metode | Path | Perilaku |
| --- | --- | --- |
| GET | `/health` | Kesiapan basis data/aplikasi. |
| GET | `/items?search=&page=&limit=` | Pencarian SKU/nama dengan paginasi. |
| POST | `/items` | Membuat barang dengan stok nol. |
| PUT | `/items/:id` | Mengganti metadata barang. |
| GET | `/warehouses?search=&page=&limit=` | Pencarian kode/nama dengan paginasi. |
| POST | `/warehouses` | Membuat gudang dengan stok nol. |
| PUT | `/warehouses/:id` | Mengganti metadata gudang. |
| GET | `/warehouses/:id/stocks?search=&page=&limit=` | Seluruh barang dan jumlahnya, termasuk stok nol. |
| POST | `/transfers` | Menyelesaikan mutasi beberapa barang secara atomik. |
| GET | `/transfers?sourceWarehouseId=&destinationWarehouseId=&page=&limit=` | Menyaring riwayat, diurutkan dari yang terbaru. |
| GET | `/transfers/:id` | Data utama mutasi dan rincian barang. |
| GET | `/docs` | Swagger UI. |
| GET | `/openapi.json` | Spesifikasi OpenAPI. |

Paginasi secara bawaan menggunakan halaman 1 dan limit 20; limit maksimum adalah 100. Pemilih data master harus mengambil halaman berikutnya. Hilangkan filter gudang yang tidak digunakan alih-alih mengirim string kosong. Kunci yang tidak dikenal dan parameter kueri berulang ditolak. Pencarian memperlakukan `%` dan `_` sebagai karakter literal. Daftar menggunakan urutan yang stabil dengan ID sebagai penentu jika nilai pengurutan sama.

Respons berhasil menggunakan `{ "data": ... }`; respons daftar juga menyertakan `{ "meta": { "page": 1, "limit": 20, "total": 3 } }`. Respons kesalahan menggunakan:

```json
{
  "error": {
    "code": "INSUFFICIENT_STOCK",
    "message": "Stok BRG-001 tidak mencukupi.",
    "fields": { "items.0.quantity": "Stok tersedia 100." }
  }
}
```

Status: 400 untuk JSON rusak atau sintaks kueri/path tidak valid; 403 untuk Origin yang tidak diizinkan; 404 untuk sumber daya yang tidak ditemukan; 409 untuk kode duplikat, stok tidak mencukupi, atau satuan terkunci; 413 untuk body terlalu besar; 415 untuk tipe konten/encoding yang tidak didukung; 422 untuk payload/referensi tidak valid atau stok tujuan melampaui batas; 503 untuk basis data tidak tersedia atau konflik penguncian; 500 untuk kegagalan tak terduga. `fields` bersifat opsional. Respons menyertakan `X-Request-Id`; log server menggunakan metadata aman tanpa SQL, payload, kredensial, atau stack trace dalam respons.

## Aturan Mutasi

[`transfers.service.js`](src/modules/transfers/transfers.service.js) mengelola transaksi perubahan stok:

1. Mengambil shared lock pada master berdasarkan urutan ID gudang/barang dari kecil ke besar. Perubahan barang mengambil exclusive lock pada barang, sehingga perubahan satuan tidak berlangsung bersamaan dengan mutasi.
2. Membuat atau mengunci baris saldo berdasarkan urutan `(warehouse_id, item_id)` dari kecil ke besar. PK gabungan menserialisasi pembuatan saldo tujuan yang berlangsung bersamaan. Penguncian tanpa perubahan mempertahankan saldo dan waktu pembaruan yang sudah ada.
3. Memeriksa setiap saldo sumber dan batas maksimum stok tujuan sebelum menulis data. Baris sumber yang tidak ada dianggap nol. Semua jumlah berada dalam rentang signed INT.
4. Memperbarui kedua gudang, menyimpan data utama/rincian, dan membaca hasil mutasi dalam satu transaksi Drizzle.
5. Melakukan commit bersama, atau membatalkan seluruh perubahan, termasuk baris saldo yang baru dibuat, jika salah satu operasi gagal.

Transaksi menggunakan READ COMMITTED dan tidak pernah mengulang secara otomatis. `503 DATABASE_BUSY` berarti terjadi deadlock atau batas waktu penguncian setelah rollback. Kegagalan koneksi atau respons yang tidak dapat dipastikan dapat membuat hasil commit tidak diketahui: muat ulang riwayat dan stok sebelum mengirim kembali. POST berulang yang terpisah dapat menghasilkan mutasi berulang karena idempotensi berada di luar cakupan.

Mutasi langsung selesai, tanpa tahap draf/status/persetujuan atau endpoint untuk mengubah/menghapusnya. Penghapusan master tidak disediakan. Perubahan metadata tidak pernah mengubah stok. Perubahan satuan ditolak setelah ada baris stok atau riwayat, termasuk baris dengan saldo nol. Riwayat menampilkan nama/kode/SKU master terkini, bukan salinan data pada saat transaksi.

Waktu disimpan sebagai UTC `DATETIME(3)` dan dikembalikan dalam format ISO 8601 UTC. Frontend menampilkan Asia/Jakarta (WIB, UTC+07:00). Pesan validasi untuk pengguna menggunakan Bahasa Indonesia; identifier menggunakan Bahasa Inggris.

## Pemeriksaan Manual

Sesuai permintaan, proyek tidak menyertakan berkas pengujian, layanan basis data pengujian, atau framework pengujian. `npm run check` memeriksa sintaks JavaScript dan penguraian YAML; `npm run db:check` memvalidasi riwayat migrasi. Pemeriksaan ini tidak membuktikan perilaku transaksi atau akses bersamaan.

Setelah migrasi dan seed pada basis data kosong:

1. Buka Swagger UI dan ambil stok kedua gudang. Cocokkan dengan tabel data contoh, termasuk saldo nol.
2. Kirim POST `/transfers` dengan body berikut:

   ```json
   {
     "sourceWarehouseId": 1,
     "destinationWarehouseId": 2,
     "notes": "Demo AC-03",
     "items": [{ "itemId": 1, "quantity": 10 }]
   }
   ```

3. Respons yang diharapkan adalah 201 dengan referensi yang dihasilkan. A kini memiliki 90 BRG-001; B memiliki 30. Total tetap 120. Buka ID mutasi yang dikembalikan dan riwayat menggunakan filter.
4. Pindahkan 5 BRG-002 dari A ke B. Stok A menjadi 45 dan B menjadi 5, dengan baris saldo B yang sebelumnya belum ada dibuat satu kali.
5. Kirim dua baris barang dengan salah satunya melebihi stok. Respons yang diharapkan adalah 409 tanpa perubahan stok/riwayat. Barang duplikat, gudang yang sama, desimal, string angka, nol, angka negatif, dan referensi tidak valid juga harus ditolak.
6. Buat/ubah data master; periksa penghapusan spasi di awal/akhir kode, normalisasi huruf kapital, kesalahan duplikat, stok awal nol, serta penolakan perubahan satuan untuk barang dari seed.
7. Untuk akses bersamaan, reset data contoh, jalankan API, lalu kirim dua mutasi terpisah secara bersamaan, masing-masing 80 BRG-001 dari A ke B. Tepat satu permintaan harus berhasil. Stok akhir A adalah 20, B adalah 100, dengan satu entri riwayat. Periksa hasilnya tanpa mengulang secara otomatis.

Pengujian batas maksimum stok dan rollback akibat kegagalan basis data memerlukan persiapan khusus pada basis data lokal yang dapat dibuang. Pulihkan data contoh setelahnya; jangan menyimpulkan kasus ini berhasil hanya dari pemeriksaan sintaks.

## Koneksi Flutter

Pada penyerahan backend ini, direktori `frontend/` disiapkan untuk implementasi Flutter pada tahap berikutnya; layar Flutter tidak termasuk dalam penyerahan backend tersebut.

| Target | URL Dasar API |
| --- | --- |
| Emulator Android | `http://10.0.2.2:3000/api` |
| Perangkat Android fisik | `http://<computer-LAN-IP>:3000/api` |
| Web pada komputer pengembangan | `http://localhost:3000/api` |

Android menjadi target utama. Instal Flutter dan Android SDK, lalu jalankan emulator atau hubungkan perangkat. Perangkat fisik harus berada pada jaringan yang sama dengan komputer; izinkan koneksi TCP masuk ke port 3000 melalui firewall pengembangan. HTTP lokal pada Android memerlukan izin Internet dan konfigurasi cleartext khusus debug. Gunakan HTTPS untuk deployment berikutnya.

Setelah Flutter diinisialisasi dan kliennya membaca `String.fromEnvironment('API_BASE_URL')`, perintah yang digunakan adalah:

```sh
flutter run -d <android-device-id> --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
flutter run -d chrome --web-port=5173 --dart-define=API_BASE_URL=http://localhost:3000/api
```

Tetapkan port web agar sesuai dengan `CORS_ORIGINS`. Frontend perlu mempertahankan isian formulir yang ditolak, mengosongkan baris saat sumber berubah, memuat ulang stok/riwayat terkait setelah berhasil, dan tidak pernah mengulangi POST mutasi secara otomatis.

## Struktur dan Cakupan

```text
compose.yaml          Layanan MySQL lokal
drizzle.config.js     Konfigurasi Drizzle Kit
drizzle/              Migrasi SQL, snapshot, jurnal
docs/openapi.yaml     Kontrak API
scripts/check.js      Pemeriksaan sintaks/YAML
src/
  app.js              Middleware, perutean, Swagger
  server.js           Menjalankan dan menghentikan server secara tertib
  config/env.js       Validasi konfigurasi lingkungan
  db/                 Klien, skema, pelaksana migrasi, seed/reset
  shared/             Kesalahan, validasi, paginasi
  middleware/         Validasi permintaan dan penanganan kesalahan
  modules/
    health/           Kesiapan layanan
    items/            Rute, validasi, service, repository
    warehouses/       Rute, validasi, service, repository
    stocks/           Rute, validasi, service, repository
    transfers/        Rute, validasi, service, repository
```

Autentikasi, peran pengguna, penerimaan barang, penyesuaian manual, pembatalan, penghapusan, deployment, dan implementasi Flutter berada di luar cakupan penyerahan backend ini.
