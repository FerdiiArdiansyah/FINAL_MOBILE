param()

$API_KEY = "AIzaSyCEAwDlJ56tRiK_S6yNhR5LBNImXH0JrAA"
$PROJECT_ID = "edutech-smk-app-99a83"

$AUTH_URL = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$API_KEY"
$FIRESTORE_BASE = "https://firestore.googleapis.com/v1/projects/$PROJECT_ID/databases/(default)/documents"

# Demo accounts
$users = @(
    @{ email="admin@edutechsmk.sch.id";      password="Admin@EduTech2024!";   name="Administrator";        role="ADMIN";        nisn=$null; classId=$null; className=$null },
    @{ email="siswa1@edutechsmk.sch.id";      password="Siswa@EduTech2024!";   name="Ahmad Fauzi";          role="SISWA";        nisn="0012345678"; classId="X-TKJ-1"; className="X TKJ 1" },
    @{ email="siswa2@edutechsmk.sch.id";      password="Siswa@EduTech2024!";   name="Budi Santoso";         role="SISWA";        nisn="0012345679"; classId="X-TKJ-1"; className="X TKJ 1" },
    @{ email="guru.mapel@edutechsmk.sch.id";  password="Guru@EduTech2024!";    name="Pak Hendra Wijaya";    role="GURU_MAPEL";   nisn=$null; classId=$null; className=$null },
    @{ email="wali.kelas@edutechsmk.sch.id";  password="Wali@EduTech2024!";    name="Bu Siti Rahayu";       role="WALI_KELAS";   nisn=$null; classId="X-TKJ-1"; className="X TKJ 1" },
    @{ email="guru.bk@edutechsmk.sch.id";     password="GuruBK@EduTech2024!";  name="Pak Darmawan";         role="GURU_BK";      nisn=$null; classId=$null; className=$null },
    @{ email="guru.piket@edutechsmk.sch.id";  password="Piket@EduTech2024!";   name="Bu Ningsih";           role="GURU_PIKET";   nisn=$null; classId=$null; className=$null }
)

function Create-FirebaseUser($email, $password) {
    $body = @{ email=$email; password=$password; returnSecureToken=$true } | ConvertTo-Json
    try {
        $res = Invoke-RestMethod -Uri $AUTH_URL -Method POST -Body $body -ContentType "application/json"
        return $res
    } catch {
        $errBody = $_.ErrorDetails.Message | ConvertFrom-Json
        if ($errBody.error.message -eq "EMAIL_EXISTS") {
            # Sign in instead
            $signinUrl = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$API_KEY"
            $res = Invoke-RestMethod -Uri $signinUrl -Method POST -Body $body -ContentType "application/json"
            return $res
        }
        throw $_
    }
}

function Create-FirestoreDoc($uid, $idToken, $email, $name, $role, $nisn, $classId, $className) {
    $url = "$FIRESTORE_BASE/users?documentId=$uid"
    
    $fields = @{
        email     = @{ stringValue = $email }
        name      = @{ stringValue = $name }
        role      = @{ stringValue = $role }
        createdAt = @{ timestampValue = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ") }
    }

    if ($nisn)      { $fields["nisn"]      = @{ stringValue = $nisn } }
    if ($classId)   { $fields["classId"]   = @{ stringValue = $classId } }
    if ($className) { $fields["className"] = @{ stringValue = $className } }

    $body = @{ fields = $fields } | ConvertTo-Json -Depth 5
    $headers = @{ Authorization = "Bearer $idToken" }

    try {
        Invoke-RestMethod -Uri $url -Method POST -Body $body -ContentType "application/json" -Headers $headers | Out-Null
        return $true
    } catch {
        # Document might already exist - try PATCH
        $patchUrl = "$FIRESTORE_BASE/users/$uid"
        try {
            Invoke-RestMethod -Uri $patchUrl -Method PATCH -Body $body -ContentType "application/json" -Headers $headers | Out-Null
            return $true
        } catch {
            return $false
        }
    }
}

Write-Host "`n=== EduTech SMK - Seed Akun Demo ===" -ForegroundColor Cyan
Write-Host "Project: $PROJECT_ID`n" -ForegroundColor Gray

$results = @()

foreach ($u in $users) {
    Write-Host "[$($u.role)] Membuat akun: $($u.email)..." -NoNewline

    try {
        $authResult = Create-FirebaseUser -email $u.email -password $u.password
        $uid = $authResult.localId
        $idToken = $authResult.idToken

        $firestoreOk = Create-FirestoreDoc `
            -uid $uid -idToken $idToken `
            -email $u.email -name $u.name -role $u.role `
            -nisn $u.nisn -classId $u.classId -className $u.className

        if ($firestoreOk) {
            Write-Host " OK" -ForegroundColor Green
        } else {
            Write-Host " Auth OK, Firestore GAGAL" -ForegroundColor Yellow
        }

        $results += [PSCustomObject]@{
            Role     = $u.role
            Email    = $u.email
            Password = $u.password
            Nama     = $u.name
            UID      = $uid
        }
    } catch {
        Write-Host " GAGAL: $_" -ForegroundColor Red
    }
}

Write-Host "`n=== Daftar Akun Yang Berhasil Dibuat ===" -ForegroundColor Cyan
$results | Format-Table -AutoSize

Write-Host "`nNote: Simpan password di atas untuk login testing!" -ForegroundColor Yellow
Write-Host "Selesai!" -ForegroundColor Green
