# Analisis Database dan Token - Petugas Pintar

## 1. Token Admin mengandung data apa?

Berdasarkan analisis kode Flutter dan backend:

### JWT Token Contents:
- `user_id`: ID dari tabel admin (bukan tabel users)
- `username`: Username admin
- `is_admin`: Boolean flag (true untuk admin)
- `role`: Role string (misal: "admin", "officer")
- `iat`: Issued at timestamp
- `exp`: Expiration timestamp (jika ada)

### Proses Login Admin:
```dart
// Di ApiService.login()
final data = jsonDecode(response.body);
token = data['token'];  // JWT token
isAdmin = data['is_admin'] ?? false;  // Flag admin
role = data['role'];  // Role string
```

## 2. Query ke tabel mana yang dilakukan?

### Backend Query Pattern:

#### A. FCM Token Management:
```sql
-- Query untuk mendapatkan FCM tokens admin
SELECT id, fcm_token, session_id, session_start 
FROM admin 
WHERE fcm_token IS NOT NULL;

-- Update FCM token untuk admin
UPDATE admin 
SET fcm_token = ?, session_id = ?, session_start = ? 
WHERE id = ?;

-- Hapus invalid FCM token
UPDATE admin 
SET fcm_token = NULL, session_id = NULL 
WHERE id = ?;
```

#### B. Authentication:
```sql
-- Login verification (kemungkinan)
SELECT id, username, password_hash, is_admin, role 
FROM admin 
WHERE username = ?;

-- Get admin profile
SELECT id, username, name, address, phone, created_at, is_admin, role 
FROM admin 
WHERE id = ?;
```

#### C. Report Handling:
```sql
-- Insert new report
INSERT INTO reports (user_id, address, jenis_laporan, reporter_type, created_at) 
VALUES (?, ?, ?, ?, ?);

-- Get reports by admin
SELECT * FROM reports WHERE user_id = ?;
```

## 3. Konflik ID antara tabel users dan admin?

### YA, ADA POTENSI KONFLIK ID!

#### Masalah Yang Ditemukan:

1. **Dua Tabel Terpisah:**
   - `users` table: untuk warga biasa
   - `admin` table: untuk petugas/admin

2. **ID Collision Risk:**
   - User ID 1 di tabel `users` ≠ Admin ID 1 di tabel `admin`
   - Token JWT hanya menyimpan `user_id` tanpa context tabel
   - Backend mungkin salah menggunakan ID

#### Contoh Masalah:
```javascript
// Backend JWT decode
const userId = req.user.user_id; // ID dari token

// Ambil admin dengan ID ini
const [adminTokens] = await pool.query(
  'SELECT id, fcm_token FROM admin WHERE id = ?', 
  [userId]
);
```

#### Solusi Yang Diperlukan:

1. **Gunakan Prefix dalam JWT:**
```javascript
// JWT payload should include:
{
  user_id: adminId,
  user_type: "admin", // atau "user"
  table_source: "admin" // explicit table reference
}
```

2. **Query dengan Context:**
```sql
-- Pastikan query ke tabel yang benar
SELECT id, fcm_token FROM admin WHERE id = ? AND is_admin = true;
```

3. **Separate Token Types:**
```javascript
// Buat token berbeda untuk admin vs user
const adminToken = jwt.sign({
  admin_id: adminData.id,
  type: 'admin',
  username: adminData.username
});

const userToken = jwt.sign({
  user_id: userData.id,
  type: 'user', 
  username: userData.username
});
```

## Rekomendasi Perbaikan Immediate:

### 1. Fix Backend Authentication:
```javascript
// middleware/authenticate.js
function authenticate(req, res, next) {
  const token = req.header('Authorization')?.replace('Bearer ', '');
  
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    
    // Pastikan context table yang benar
    if (decoded.type === 'admin') {
      req.user = {
        user_id: decoded.admin_id,
        username: decoded.username,
        is_admin: true,
        table_source: 'admin'
      };
    } else {
      req.user = {
        user_id: decoded.user_id,
        username: decoded.username,
        is_admin: false,
        table_source: 'users'
      };
    }
    
    next();
  } catch (error) {
    res.status(401).json({ error: 'Invalid token' });
  }
}
```

### 2. Fix FCM Query:
```javascript
// Pastikan hanya query admin table untuk FCM
const [adminTokens] = await pool.query(`
  SELECT a.id, a.fcm_token, a.session_id, a.session_start 
  FROM admin a 
  WHERE a.fcm_token IS NOT NULL 
  AND a.is_admin = true
`);
```

### 3. Add Validation in Flutter:
```dart
// Validate user is actually admin before allowing admin features
if (!user.isAdmin || user.role != 'admin') {
  throw Exception('Unauthorized: Admin access required');
}
```

## Error Yang Terjadi Sekarang:

Log error menunjukkan:
```
[FCM] Sending to admin 2 (session: null)
[FCM] Failed to send notification to admin 2 in 3ms: apns.headers must only contain string values
```

Ini menunjukkan:
1. Admin ID 2 ada di database
2. Session ID null (tidak ter-set dengan benar)
3. Error APNS header (masalah backend)

## Next Steps:

1. **Immediate**: Fix backend APNS header issue
2. **Medium**: Implement proper table context in JWT
3. **Long-term**: Consider merging tables or using UUID for unique IDs across tables
