# SIAP-D (Sistem Informasi Absensi PKL - DISKOMINFO)

**SIAP-D** adalah aplikasi presensi digital terpadu untuk peserta **Praktik Kerja Lapangan (PKL) / Magang** di lingkungan **Dinas Komunikasi dan Informatika (DISKOMINFO)**. Aplikasi ini dirancang untuk mendigitalisasi pencatatan kehadiran secara akurat, transparan, dan aman menggunakan verifikasi berlapis.

---

## Fitur Utama Aplikasi

- **Validasi Radius GPS (Geofencing)**: Presensi hanya bisa dilakukan jika peserta berada di area kantor DISKOMINFO (toleransi radius ≤ 100 meter).
- **Swafoto (Selfie)**: Wajib melampirkan foto wajah langsung saat presensi masuk dan pulang.
- **Tanda Tangan Digital**: Tanda tangan langsung di layar sebagai bukti validasi kehadiran.
- **Pengajuan Izin & Sakit**: Formulir pengajuan izin/sakit dengan rentang tanggal dan keterangan yang otomatis terkirim ke pembimbing.
- **Notifikasi Real-time**: Pembimbing lapangan langsung menerima notifikasi instan saat peserta mengajukan izin/sakit.
- **Rekapitulasi & Ekspor Excel**: Admin dapat memfilter kehadiran harian/periode tertentu dan mengunduh laporan dalam format Excel (`.xlsx`).

---

## Peran Pengguna (Roles)

1. **Peserta PKL**: Melakukan presensi masuk/pulang, mengajukan izin/sakit, dan melihat riwayat kehadiran pribadi.
2. **Pembimbing Lapangan**: Memantau kehadiran anak bimbingan secara harian, memverifikasi foto & tanda tangan presensi, serta menerima notifikasi izin/sakit.
3. **Administrator**: Mengelola data peserta, master data bidang & divisi, akun pembimbing, serta mengekspor rekap presensi.

---

## Panduan Penggunaan Aplikasi

### 1. Masuk ke Akun (Login)
1. Buka aplikasi **SIAP-D**.
2. Masukkan **Email** dan **Password** yang telah didaftarkan.
3. Tekan **Masuk Aplikasi**. Halaman dashboard akan otomatis menyesuaikan peran akun Anda.

---

### 2. Panduan Peserta PKL

#### A. Presensi Masuk (Check-in)
1. Pastikan **GPS aktif** dan Anda berada di area kantor DISKOMINFO.
2. Di halaman utama, tekan tombol **Presensi Masuk** (Status: **Hadir**).
3. Tunggu hingga lokasi terverifikasi (`✓ Anda berada di dalam radius kantor`).
4. Ambil **Foto Selfie** dan bubuhkan **Tanda Tangan Digital**.
5. Tekan **Kirim Presensi Masuk**. Status Anda otomatis tercatat **Hadir**.

#### B. Presensi Pulang (Check-out)
1. Di akhir jam kerja, buka kembali aplikasi SIAP-D.
2. Tekan tombol **Presensi Pulang** pada kartu presensi hari ini.
3. Ambil swafoto kepulangan dan buat tanda tangan konfirmasi.
4. Tekan **Kirim Presensi Pulang**.

#### C. Pengajuan Izin atau Sakit
1. Pada menu presensi, pilih status **Izin** atau **Sakit**.
2. Pilih rentang **Tanggal Mulai** dan **Tanggal Selesai**.
3. Tuliskan alasan/keterangan yang jelas.
4. Tekan **Kirim Pengajuan**. Notifikasi otomatis dikirim ke pembimbing Anda.

#### D. Cek Riwayat Presensi
- Buka tab **Riwayat** untuk melihat rekap kehadiran Anda per hari lengkap dengan jam dan statusnya.

---

### 3. Panduan Pembimbing Lapangan

#### A. Pantau Kehadiran Anak Bimbingan
- Di tab **Dashboard**, pantau ringkasan statistik kehadiran hari ini (*Hadir*, *Izin*, *Sakit*, *Belum Presensi*) khusus peserta yang Anda bimbing.

#### B. Cek Bukti Presensi
- Buka tab **Kehadiran**.
- Pilih tanggal untuk melihat daftar peserta.
- Ketuk nama peserta untuk memeriksa detail jam absen, foto selfie, dan tanda tangan digital.

#### C. Tangani Notifikasi Izin/Sakit
- Notifikasi akan meluncur di layar saat ada pengajuan izin/sakit baru.
- Buka tab **Notifikasi** untuk melihat seluruh daftar permohonan.

---

### 4. Panduan Administrator DISKOMINFO

#### A. Kelola Peserta PKL
- Buka tab **Kelola Peserta**.
- **Tambah Peserta**: Tekan tombol `+`, isi data diri, instansi, periode PKL, lalu tentukan Bidang, Divisi, dan Pembimbingnya.
- **Edit / Hapus**: Ketuk nama peserta untuk mengubah data, mengganti status (*Aktif/Selesai*), mereset kata sandi, atau menghapus akun.

#### B. Rekap Presensi & Ekspor Excel
- Buka tab **Rekap Log Presensi**.
- Gunakan filter: *Hari Ini*, *Pilih Tanggal*, atau *Berdasarkan Bidang/Divisi*.
- Tekan tombol **Ekspor Excel (`.xlsx`)** untuk mengunduh rekapitulasi kehadiran siap pakai.

#### C. Kelola Bidang & Pembimbing
- Buka tab **Kelola Bidang & Pembimbing** untuk menambah atau memperbarui data Bidang, Divisi, dan akun Pembimbing Lapangan.

---

## 🛠️ Teknologi yang Digunakan
- **Frontend**: Flutter & Dart (State Management: Provider)
- **Backend & Database**: Supabase (PostgreSQL, Supabase Auth, Storage, & Realtime)
- **Paket Utama**: `geolocator` (GPS), `signature` (Tanda Tangan), `image_picker` (Selfie), `excel` (Ekspor Rekap)

---

*SIAP-D • Dinas Komunikasi dan Informatika (DISKOMINFO)*

