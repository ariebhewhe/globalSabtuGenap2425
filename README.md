# Perpus Glo : Aplikasi perpustakaan Global dan Manajemen peminjaman


**PerpusGlo** adalah aplikasi mobile berbasis Flutter yang dirancang untuk mempermudah proses **peminjaman, pengembalian, dan pembayaran denda** buku perpustakaan secara digital. Aplikasi ini ditujukan untuk mahasiswa, petugas perpustakaan, dan admin kampus agar dapat mengelola aktivitas perpustakaan tanpa harus hadir secara fisik.


## Peran & Tanggung Jawab

| NIM            | Nama                    | Peran & Tanggung Jawab                                                                                                                                        |
| :------------- | :---------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **1122140079** | **Miftahudin Aldi Saputra**     | **Lead Developer**. Bertanggung jawab atas perancangan arsitektur, implementasi, dan pengembangan keseluruhan fungsionalitas aplikasi dari awal hingga akhir. |
| **1122140068** | **Dwi Bayu Nugraha** | **Frontend & Documenter SRS**. Bertugas membuat tampilan frontend pada login dan register dan Membuat dokumen _Software Requirements Specification_ (SRS) secara detail sebagai landasan utama pengembangan. |
| **1122140029** | **Wahyu Nayoga**     | **Frontend & UI**. Bertugas membuat tampilan frontend category dan berfungsi dan Membuat design UI menggunakan Figma. |

## Fitur Utama

### Mahasiswa
- **Login & Registrasi**
- **Lihat katalog buku** berdasarkan kategori, judul, penulis
- **Ajukan peminjaman buku** secara online
- **Ajukan perpanjangan masa pinjam**
- **Bayar denda keterlambatan** via QRIS, e-wallet, transfer
- **Lihat riwayat peminjaman & pembayaran**
- **Terima notifikasi** pengingat & status peminjaman
- **Lihat history** history aktivitas
- 
### Petugas Perpustakaan
- **Konfirmasi peminjaman & pengembalian**
- **Tolak permintaan jika tidak valid**
- **Notifikasi ke mahasiswa**

### Admin
- **Kelola data buku & kategori**
- **Tambah dan update stok buku**
- **Kelola user & role**

---

## Teknologi & Arsitektur

Proyek ini dibangun menggunakan Flutter dengan _backend-as-a-service_ dari Firebase.

- **Flutter 3.29.3**
- **Dart 3.7.2**
- **Firebase**:
  - Firebase Authentication
  - Firestore
  - Firebase Cloud Messaging
- **State Management**: Riverpod
- **Push Notification**: Awesome Notifications
- **Routing**: GoRouter
- **Form Validation**: Formz


## Prasyarat & Instalasi

Pastikan Flutter SDK versi 3.x.x atau yang lebih baru sudah terpasang di mesin Anda.

1.  **Clone Repositori**

    ```bash
    git clone -b tim-dmw [https://github.com/ariebhewhe/globalSabtuGenap2425/](https://github.com/ariebhewhe/globalSabtuGenap2425/)
    cd globalSabtuGenap2425
    ```

2.  **Konfigurasi Firebase**
    Proyek ini memerlukan koneksi ke proyek Firebase.

    - Buat proyek baru di [Firebase Console](https://console.firebase.google.com/).
    - Tambahkan aplikasi Android dan/atau iOS ke proyek Firebase Anda.
    - Unduh file konfigurasi `google-services.json` (untuk Android) dan letakkan di direktori `android/app/`.
    - Unduh file `GoogleService-Info.plist` (untuk iOS) dan konfigurasikan di Xcode.
    - Aktifkan layanan **Authentication**, **Firestore Database**, dan **Storage**.

3.  **Instal Dependencies**
    Jalankan perintah berikut dari direktori root proyek:

    ```bash
    flutter pub get
    ```
4. **Setup Firebase**

   * Tambahkan file `firebase_options.dart` via:

     ```bash
     flutterfire configure
     ```
     
5.  **Jalankan Aplikasi**

    ```bash
    flutter run
    ```

---

## Struktur Proyek

Proyek ini mengikuti prinsip Clean Architecture dengan struktur folder sebagai berikut:

```
lib/
├── main.dart
├── core/                  # 🔧 Konfigurasi global & utilitas
│   ├── constants/         # Konstanta global (warna, teks, dll)
│   ├── services/          # Service global (Firebase, Notification, Storage)
│   ├── theme/             # Custom ThemeData
│   └── router.dart        # GoRouter config 
│
├── common/                # Reusable widgets/components
│   ├── widgets/
│   ├── utils/
│   └── providers/         # Global provider 
│
├── features/              # Modular per fitur
│   ├── admin/             # Admin 
│   │   ├── view/          # Dashboard admin dll.

│   ├── auth/              # Login, Register, Profile
│   │   ├── data/          # AuthRepository (Firebase Auth)
│   │   ├── providers/     # authProvider, userProvider
│   │   ├── view/          # UI screens: login_page.dart, register_page.dart
│   │   └── model/         # User model
│
│   ├── books/             # Katalog & Peminjaman Buku
│   │   ├── data/          # BookRepository (Firestore CRUD)
│   │   ├── providers/     # bookListProvider, borrowProvider
│   │   ├── view/          # books_page.dart, book_detail_page.dart
│   │   └── model/         # Book model

│   ├── categories/        # Category
│   │   ├── data/          # CategoryRepository (Firestore CRUD)
│   │   ├── providers/     # CategoryProvider
│   │   ├── view/          # category_detail_page.dart
│   │   └── model/         # Category model

│   ├── profile/           # Profilee
│   │   ├── data/          # ProfileRepository (Firestore CRUD)
│   │   ├── providers/     # ProfileProvider
│   │   ├── view/          # profile.dart, settings.dart, edit.dart
│   │   └── model/         # User Profile model
│
│   ├── borrow/            # Pinjam, Perpanjang, Kembali
    |   ├── data/          #  (Firestore CRUD)
│   │   ├── providers/
│   │   ├── view/
│   │   └── model/
│
│   ├── payment/           # Pembayaran Denda
│   │   ├── providers/
│   │   ├── view/
│   │   └── model/
│
│   ├── notification/      # Reminder & Notifikasi
│   │   ├── providers/
│   │   └── service/       # awesome_notifications wrapper
│
│   └── history/           # Riwayat 
│       ├── providers/
│       └── view/

│   └── home/           # Home page
│       ├── providers/
│       └── view/

```
