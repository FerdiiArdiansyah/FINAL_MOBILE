param()

$API_KEY = "AIzaSyCEAwDlJ56tRiK_S6yNhR5LBNImXH0JrAA"
$PROJECT_ID = "edutech-smk-app-99a83"
$FIRESTORE_BASE = "https://firestore.googleapis.com/v1/projects/$PROJECT_ID/databases/(default)/documents"

# Login sebagai admin untuk mendapatkan token
function Get-AdminToken() {
    $signinUrl = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$API_KEY"
    $body = @{ email="admin@edutechsmk.sch.id"; password="Admin@EduTech2024!"; returnSecureToken=$true } | ConvertTo-Json
    $res = Invoke-RestMethod -Uri $signinUrl -Method POST -Body $body -ContentType "application/json"
    return $res.idToken
}

function Post-Firestore($collection, $body, $token) {
    $url = "$FIRESTORE_BASE/$collection"
    $headers = @{ Authorization = "Bearer $token" }
    try {
        Invoke-RestMethod -Uri $url -Method POST -Body ($body | ConvertTo-Json -Depth 10) -ContentType "application/json" -Headers $headers | Out-Null
        return $true
    } catch {
        Write-Host "  Error: $_" -ForegroundColor Red
        return $false
    }
}

Write-Host "`n=== EduTech SMK - Seed Data Demo ===" -ForegroundColor Cyan

$token = Get-AdminToken
Write-Host "Token admin berhasil didapat.`n" -ForegroundColor Green

# ==================== PENGUMUMAN ====================
Write-Host "Menambahkan Pengumuman..." -NoNewline

$announcements = @(
    @{
        fields = @{
            title      = @{ stringValue = "Selamat Datang di EduTech SMK!" }
            content    = @{ stringValue = "Aplikasi EduTech SMK resmi diluncurkan. Silahkan login sesuai role masing-masing." }
            authorId   = @{ stringValue = "admin" }
            authorName = @{ stringValue = "Administrator" }
            priority   = @{ stringValue = "normal" }
            createdAt  = @{ timestampValue = "2026-08-07T08:00:00Z" }
        }
    },
    @{
        fields = @{
            title      = @{ stringValue = "PENGUMUMAN: Ujian Tengah Semester" }
            content    = @{ stringValue = "UTS akan dilaksanakan pada tanggal 15-19 Agustus 2026. Harap mempersiapkan diri!" }
            authorId   = @{ stringValue = "admin" }
            authorName = @{ stringValue = "Administrator" }
            priority   = @{ stringValue = "urgent" }
            createdAt  = @{ timestampValue = "2026-08-07T09:00:00Z" }
        }
    },
    @{
        fields = @{
            title      = @{ stringValue = "Jadwal Piket Harian" }
            content    = @{ stringValue = "Jadwal piket siswa telah diperbarui. Silahkan cek di menu Jadwal." }
            authorId   = @{ stringValue = "admin" }
            authorName = @{ stringValue = "Administrator" }
            priority   = @{ stringValue = "normal" }
            createdAt  = @{ timestampValue = "2026-08-07T10:00:00Z" }
        }
    }
)

$ok = 0
foreach ($ann in $announcements) {
    if (Post-Firestore "announcements" $ann $token) { $ok++ }
}
Write-Host " $ok/3 OK" -ForegroundColor Green

# ==================== MATERI ====================
Write-Host "Menambahkan Materi Pembelajaran..." -NoNewline

$materials = @(
    @{
        fields = @{
            title       = @{ stringValue = "Pengenalan Pemrograman Web" }
            description = @{ stringValue = "Materi dasar HTML, CSS dan JavaScript untuk kelas X TKJ" }
            subject     = @{ stringValue = "Pemrograman Web" }
            classId     = @{ stringValue = "X-TKJ-1" }
            teacherId   = @{ stringValue = "guru_mapel_id" }
            teacherName = @{ stringValue = "Pak Hendra Wijaya" }
            type        = @{ stringValue = "pdf" }
            fileUrl     = @{ stringValue = "https://drive.google.com/sample-materi-web.pdf" }
            createdAt   = @{ timestampValue = "2026-08-07T08:00:00Z" }
        }
    },
    @{
        fields = @{
            title       = @{ stringValue = "Tutorial HTML5 Lengkap" }
            description = @{ stringValue = "Video tutorial membuat halaman web dengan HTML5 modern" }
            subject     = @{ stringValue = "Pemrograman Web" }
            classId     = @{ stringValue = "X-TKJ-1" }
            teacherId   = @{ stringValue = "guru_mapel_id" }
            teacherName = @{ stringValue = "Pak Hendra Wijaya" }
            type        = @{ stringValue = "video" }
            fileUrl     = @{ stringValue = "https://youtube.com/watch?v=sample" }
            createdAt   = @{ timestampValue = "2026-08-07T09:00:00Z" }
        }
    },
    @{
        fields = @{
            title       = @{ stringValue = "Dasar-Dasar Jaringan Komputer" }
            description = @{ stringValue = "Materi tentang topologi jaringan, IP Address, dan subnet mask" }
            subject     = @{ stringValue = "Jaringan Komputer" }
            classId     = @{ stringValue = "X-TKJ-1" }
            teacherId   = @{ stringValue = "guru_mapel_id" }
            teacherName = @{ stringValue = "Pak Hendra Wijaya" }
            type        = @{ stringValue = "pdf" }
            fileUrl     = @{ stringValue = "https://drive.google.com/sample-materi-jaringan.pdf" }
            createdAt   = @{ timestampValue = "2026-08-07T10:00:00Z" }
        }
    }
)

$ok = 0
foreach ($mat in $materials) {
    if (Post-Firestore "materials" $mat $token) { $ok++ }
}
Write-Host " $ok/3 OK" -ForegroundColor Green

# ==================== TUGAS ====================
Write-Host "Menambahkan Tugas & Kuis..." -NoNewline

$assignments = @(
    @{
        fields = @{
            title       = @{ stringValue = "Tugas 1: Buat Halaman HTML Profil Diri" }
            description = @{ stringValue = "Buat halaman HTML yang menampilkan profil diri kamu. Meliputi: nama, kelas, hobi, dan foto." }
            subject     = @{ stringValue = "Pemrograman Web" }
            classId     = @{ stringValue = "X-TKJ-1" }
            teacherId   = @{ stringValue = "guru_mapel_id" }
            teacherName = @{ stringValue = "Pak Hendra Wijaya" }
            type        = @{ stringValue = "tugas" }
            deadline    = @{ timestampValue = "2026-08-20T23:59:00Z" }
            maxScore    = @{ integerValue = 100 }
            createdAt   = @{ timestampValue = "2026-08-07T08:00:00Z" }
        }
    },
    @{
        fields = @{
            title       = @{ stringValue = "Kuis: Pengenalan Jaringan Komputer" }
            description = @{ stringValue = "Kuis tentang topologi jaringan dan pengalamatan IP." }
            subject     = @{ stringValue = "Jaringan Komputer" }
            classId     = @{ stringValue = "X-TKJ-1" }
            teacherId   = @{ stringValue = "guru_mapel_id" }
            teacherName = @{ stringValue = "Pak Hendra Wijaya" }
            type        = @{ stringValue = "kuis" }
            deadline    = @{ timestampValue = "2026-08-15T23:59:00Z" }
            maxScore    = @{ integerValue = 100 }
            createdAt   = @{ timestampValue = "2026-08-07T09:00:00Z" }
        }
    }
)

$ok = 0
foreach ($asgn in $assignments) {
    if (Post-Firestore "assignments" $asgn $token) { $ok++ }
}
Write-Host " $ok/2 OK" -ForegroundColor Green

# ==================== JADWAL ====================
Write-Host "Menambahkan Jadwal Pelajaran..." -NoNewline

$schedules = @(
    @{
        fields = @{
            classId   = @{ stringValue = "X-TKJ-1" }
            className = @{ stringValue = "X TKJ 1" }
            day       = @{ stringValue = "Senin" }
            sessions  = @{ arrayValue = @{
                values = @(
                    @{ mapValue = @{ fields = @{
                        jam = @{ stringValue = "07:00-08:30" }
                        subject = @{ stringValue = "Matematika" }
                        teacher = @{ stringValue = "Bu Rini" }
                        room = @{ stringValue = "R.101" }
                    }}}
                    @{ mapValue = @{ fields = @{
                        jam = @{ stringValue = "08:30-10:00" }
                        subject = @{ stringValue = "Bahasa Indonesia" }
                        teacher = @{ stringValue = "Pak Budi" }
                        room = @{ stringValue = "R.101" }
                    }}}
                    @{ mapValue = @{ fields = @{
                        jam = @{ stringValue = "10:15-11:45" }
                        subject = @{ stringValue = "Pemrograman Web" }
                        teacher = @{ stringValue = "Pak Hendra Wijaya" }
                        room = @{ stringValue = "Lab Komputer" }
                    }}}
                    @{ mapValue = @{ fields = @{
                        jam = @{ stringValue = "12:30-14:00" }
                        subject = @{ stringValue = "Jaringan Komputer" }
                        teacher = @{ stringValue = "Pak Hendra Wijaya" }
                        room = @{ stringValue = "Lab Jaringan" }
                    }}}
                )
            }}
            createdAt = @{ timestampValue = "2026-08-07T08:00:00Z" }
        }
    }
)

$ok = 0
foreach ($sched in $schedules) {
    if (Post-Firestore "schedules" $sched $token) { $ok++ }
}
Write-Host " $ok/1 OK" -ForegroundColor Green

# ==================== PIKET LOG ====================
Write-Host "Menambahkan Log Piket Sample..." -NoNewline

$piketLogs = @(
    @{
        fields = @{
            studentName    = @{ stringValue = "Ahmad Fauzi" }
            type           = @{ stringValue = "terlambat" }
            note           = @{ stringValue = "Terlambat 15 menit, alasan macet" }
            recordedBy     = @{ stringValue = "piket_id" }
            recordedByName = @{ stringValue = "Bu Ningsih" }
            date           = @{ timestampValue = "2026-08-07T07:15:00Z" }
        }
    }
)

$ok = 0
foreach ($log in $piketLogs) {
    if (Post-Firestore "piketLog" $log $token) { $ok++ }
}
Write-Host " $ok/1 OK" -ForegroundColor Green

Write-Host "`n=== Seed Data Selesai! ===" -ForegroundColor Cyan
Write-Host "Database sudah diisi dengan data demo untuk testing.`n" -ForegroundColor Green
