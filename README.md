# EduTech SMK

**Aplikasi Mobile Learning Management System (LMS) untuk SMK**
berbasis Flutter + Firebase dengan 6 role pengguna.

---

## Link Penting

| | |
|---|---|
| 🌐 **Aplikasi Web** | [https://edutech-smk-43b56.web.app](https://edutech-smk-43b56.web.app) |
| 🎬 **Demo Video** | [https://youtu.be/mirlTMEl-d0](https://youtu.be/mirlTMEl-d0) |

---

## Akun Demo (Siap Pakai)

| Role | Email | Password |
|------|-------|----------|
| Admin | `admin@edutechsmk.sch.id` | `Admin@EduTech2024!` |
| Guru Mapel | `guru.mapel@edutechsmk.sch.id` | `Guru@EduTech2024!` |
| Wali Kelas | `wali.kelas@edutechsmk.sch.id` | `Wali@EduTech2024!` |
| Guru BK | `guru.bk@edutechsmk.sch.id` | `GuruBK@EduTech2024!` |
| Guru Piket | `guru.piket@edutechsmk.sch.id` | `Piket@EduTech2024!` |
| Siswa 1 | `siswa1@edutechsmk.sch.id` | `Siswa@EduTech2024!` |
| Siswa 2 | `siswa2@edutechsmk.sch.id` | `Siswa@EduTech2024!` |

---

## Cara Menjalankan untuk Demo

### Prasyarat
- Windows dengan nama user **tanpa spasi** → gunakan perintah di bawah
- Node.js (untuk serve) — sudah terinstall
- Flutter SDK di `C:\Users\ACER ID\Downloads\flutter`

### Langkah 1 — Build Web (sekali, atau setiap ada perubahan kode)

```powershell
subst X: "C:\Users\ACER ID\Downloads\flutter"
$env:PUB_CACHE = "C:\PubCache"
cd "c:\Project Mandiri\FINAL_MOBILE"
& "X:\bin\flutter.bat" build web --release --no-tree-shake-icons
```

### Langkah 2 — Serve & Buka Browser

```powershell
cd "c:\Project Mandiri\FINAL_MOBILE"
npx serve build/web --listen 8080 --single
```

Buka browser → **http://localhost:8080**

### Alternatif — Klik dua kali `run.bat`

File `run.bat` di root project menjalankan `flutter run -d edge` (debug mode
dengan hot reload). Gunakan ini saat development, bukan demo.

---

## Fitur per Role

### Siswa
- Lihat materi (PDF / Video / Link)
- Kerjakan & kumpulkan tugas dan kuis
- Lihat nilai dan rekap absensi
- Jadwal pelajaran & piket
- Chat dengan guru, forum diskusi
- Booking konseling BK
- Lihat catatan pelanggaran pribadi

### Guru Mapel
- Upload materi, buat tugas & kuis
- Input absensi per jam pelajaran
- Nilai & beri feedback pengumpulan tugas
- Lihat statistik kelas
- Lapor pelanggaran siswa

### Wali Kelas
- Monitoring perkembangan akademik & absensi kelas
- Alert otomatis: poin pelanggaran > 60 (warning) / > 80 (kritis)
- Kelola pengumuman kelas

### Guru BK
- Terima & jadwalkan sesi konseling dari siswa
- Tracking kasus (pending → scheduled → ongoing → resolved)
- Chat confidential dengan siswa
- Catat catatan & resolusi kasus

### Guru Piket
- Input absensi gerbang via NISN manual
- Buku piket digital (terlambat, izin pulang, kejadian)
- Catat pelanggaran siswa
- Broadcast pengumuman darurat ke seluruh sekolah

### Admin
- Manajemen seluruh pengguna (tambah, lihat, hapus)
- Monitor semua materi & tugas
- Verifikasi & hapus catatan pelanggaran
- Statistik pengguna per role

---

## Struktur Proyek

```
lib/
├── main.dart
├── firebase_options.dart          # Konfigurasi Firebase (auto-generated)
├── core/
│   ├── constants/
│   │   ├── roles.dart             # Konstanta 6 role
│   │   └── firebase_constants.dart
│   ├── models/                    # UserModel, AssignmentModel, dll
│   ├── providers/                 # AuthProvider (state login)
│   ├── router/                    # GoRouter dengan redirect berbasis role
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── firestore_service.dart # 50+ metode CRUD
│   │   ├── fcm_service.dart       # Push notification
│   │   └── storage_service.dart   # Upload file
│   └── theme/                     # Material 3 theme
└── features/
    ├── auth/                      # Login & Splash
    ├── student/                   # Dashboard, materi, tugas, nilai, absensi
    ├── teacher/                   # Dashboard, upload, penilaian, absensi
    ├── wali_kelas/                # Dashboard, monitoring, alert
    ├── bk/                        # Dashboard, tracking kasus, jadwal
    ├── piket/                     # Dashboard, absensi gerbang, buku piket
    ├── admin/                     # Panel admin 4 tab
    └── shared/                    # Chat, notifikasi, pengumuman, forum, pelanggaran
```

## Firebase Services

| Service | Fungsi |
|---------|--------|
| Authentication | Login email/password + Custom Claims role |
| Cloud Firestore | Database realtime (14 koleksi) |
| Firebase Storage | Upload file materi & tugas |
| Cloud Messaging | Push notification otomatis |
| Firebase Hosting | Deploy web admin portal |

---

## Setup dari Awal (Project Baru)

### 1. Buat Firebase Project
1. Buka [Firebase Console](https://console.firebase.google.com)
2. Buat project: `edutech-smk-app`
3. Aktifkan: Authentication (Email/Password), Firestore, Storage, Messaging, Hosting

### 2. Konfigurasi Flutter
```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
firebase login
flutterfire configure --project=edutech-smk-app
flutter pub get
```

### 3. Deploy Rules
```bash
firebase deploy --only firestore:rules
firebase deploy --only storage
```

### 4. Buat Akun Demo
```powershell
cd scripts
.\seed_users.ps1
.\seed_data.ps1
```

### 5. Deploy ke Firebase Hosting (Web)
```powershell
subst X: "C:\Users\ACER ID\Downloads\flutter"
$env:PUB_CACHE = "C:\PubCache"
& "X:\bin\flutter.bat" build web --release
firebase deploy --only hosting
```

---

## Catatan Teknis

> **Windows — Spasi di Nama User**: Flutter SDK di path dengan spasi (`ACER ID`)
> menyebabkan native assets build gagal. Gunakan `subst X:` sebagai alias dan
> `$env:PUB_CACHE = "C:\PubCache"` setiap sesi terminal, atau jalankan `run.bat`.

> **QR Scanner**: Fitur scan QR (`mobile_scanner`) tidak tersedia di web build.
> Absensi gerbang menggunakan input NISN manual yang berfungsi di semua platform.
