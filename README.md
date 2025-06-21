# Aplikasi BAKSO DJATIGIRI: Kasir dan Manajemen Stok

Aplikasi ini berbasis mobile untuk mempermudah pengguna terutama client sebagai pemilik brand BAKSO DJATIGIRI. Terdapat role owner dan kasir untuk mempermudahkan mengelola fitur dan manage user nya sebagai owner.

## Peran & Tanggung Jawab

| NIM            | Nama                    | Peran & Tanggung Jawab                                                                                                                                        |
| :------------- | :---------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **1122140093** | **Fachrio Raditya**     | **Lead Developer**. Bertanggung jawab atas perancangan arsitektur, implementasi, dan pengembangan keseluruhan fungsionalitas aplikasi dari awal hingga akhir. |
| **1122140109** | **M. Juan Adi Pratama** | **Developer Auth & UI**. Bertugas membuat Authentication memastikan semua system aman dan berfungsi dan menambahkan design tampilan sesuai dengan Figma       |
| **1122140090** | **Fandi Fadhillah**     | **System Analyst & Documenter**. Bertugas membuat dokumen _Software Requirements Specification_ (SRS) secara detail sebagai landasan utama pengembangan.      |

## Fitur Utama

- **Autentikasi**: Proses login untuk owner dan kasir.
- **Kasir**: Role owner dan kasir dapat menggunakan fitur kasir dan melakukan checkout
- **Manajemen Stok Bahan**: Role owner dapat CRUD bahan - bahan seperti bakso urat dll
- **Manajemen Menu**: Role owner untuk membuat menu berdasarkan stok bahan apakah tersedia atau tidak
- **Profile**: Role owner dan kasir dapat melihat profile nya sendiri
- **History**: Role owner dan kasir dapat dapat melihat history transaksi dari menu kasir tadi

---

## Teknologi & Arsitektur

Proyek ini dibangun menggunakan Flutter dengan _backend-as-a-service_ dari Firebase.

- **Framework**: Flutter
- **Bahasa**: Dart
- **Backend & Database**: Firebase (Authentication, Firestore, Storage Supabase)

## Prasyarat & Instalasi

Pastikan Flutter SDK versi 3.x.x atau yang lebih baru sudah terpasang di mesin Anda.

1.  **Clone Repositori**

    ```bash
    git clone -b team404 [https://github.com/ariebhewhe/globalSabtuGenap2425/](https://github.com/ariebhewhe/globalSabtuGenap2425/)
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

4.  **Jalankan Aplikasi**

    ```bash
    flutter run
    ```

---

## Struktur Proyek

Proyek ini mengikuti prinsip Clean Architecture dengan struktur folder sebagai berikut:

```
lib/
├── config/                     # Konfigurasi aplikasi
│   └── supabase_storage.dart   # Konfigurasi Supabase Storage
├── core/                       # Komponen inti yang digunakan di seluruh aplikasi
│   ├── animation/              # Animasi custom
│   ├── theme/                  # Tema aplikasi (warna, font, dll)
│   ├── utils/                  # Utility functions
│   └── widgets/                # Widget yang dapat digunakan kembali
└── features/                   # Fitur-fitur aplikasi
    ├── splash/                 # Fitur splash screen
    │   └── presentation/       # UI layer (splash screen)
    ├── auth/                   # Fitur autentikasi
    │   ├── bloc/               # State management untuk auth
    │   ├── data/               # Data layer (model, repository impl, data source)
    │   ├── domain/             # Domain layer (entity, repository interface, use case)
    │   └── presentation/       # UI layer (pages, widgets)
    ├── stock/                  # Fitur manajemen stock
    │   ├── bloc/               # State management untuk stock
    │   ├── data/               # Data layer
    │   ├── domain/             # Domain layer
    │   └── presentation/       # UI layer
    ├── menu/                   # Fitur manajemen menu
    │   ├── bloc/               # State management untuk menu
    │   ├── data/               # Data layer
    │   ├── domain/             # Domain layer
    │   └── presentation/       # UI layer
    └── cashier/                # Fitur kasir
        ├── bloc/               # State management untuk kasir
        ├── data/               # Data layer
        ├── domain/             # Domain layer
        └── presentation/       # UI layer
```
