# MyTrade - Advanced Trading Journal App 📈

**MyTrade** adalah aplikasi Jurnal Trading modern dan komprehensif yang dibangun menggunakan **Flutter** dan **Supabase**. Aplikasi ini dirancang khusus untuk membantu para *trader* (Forex, Crypto, Saham, dll) dalam mencatat, melacak, dan menganalisis setiap transaksi perdagangan mereka guna meningkatkan performa dan disiplin *trading*.

![MyTrade App Screenshot](https://via.placeholder.com/800x400.png?text=MyTrade+Dashboard+Preview) *(Tambahkan screenshot dashboard di sini)*

---

## ✨ Fitur Utama (Key Features)

### 🏦 Sistem Multi-Akun (Multi-Account Management)
Kelola portofolio Anda tanpa batas. Anda dapat membuat banyak akun trading sekaligus (misal: *Real Account*, *Cent Account*, *Challenge FTMO*, dll).
- Tentukan **Modal Awal** (Initial Balance) untuk setiap akun.
- Dukungan berbagai **Mata Uang** (USD, USC, IDR).
- Setiap akun memiliki statistik dan analitiknya masing-masing secara terpisah.

### 📊 Dashboard Analitik Tingkat Lanjut
Pantau kesehatan akun *trading* Anda dalam satu layar dengan metrik profesional:
- **Total PnL** (Profit & Loss).
- **Win Rate %** (Rasio Kemenangan).
- **Profit Factor** (Rasio Keuntungan berbanding Kerugian).
- **Average Win & Loss** (Rata-rata profit dan loss per transaksi).
- **Max Drawdown** (Penurunan saldo maksimal, dalam nominal maupun persentase).

### 📈 Kurva Ekuitas (Equity Curve)
Visualisasikan pertumbuhan saldo akun Anda melalui grafik garis (*Line Chart*) yang interaktif. Grafik ini mendukung penggeseran horizontal (scrollable) yang mulus, lengkap dengan tooltips detail dan sumbu Y presisi tinggi.

### 📝 Pencatatan Jurnal Interaktif
Catat setiap detail posisi *trading* Anda dengan mudah:
- Arah posisi (Buy / Sell).
- Instrumen/Pair (XAUUSD, BTCUSDT, EURUSD, dll).
- Tanggal & Waktu Eksekusi (*Entry Time*).
- Kategori Setup / Strategi yang digunakan (SMC, SnD, Breakout, dll).
- Hasil akhir (Nominal Profit/Loss & Persentase).

### 🗓️ Tampilan Kalender (Calendar View)
Lacak aktivitas *trading* Anda berdasarkan hari dan tanggal. Fitur kalender memudahkan Anda melihat riwayat *trade* secara kronologis.

### 🔍 Analisis Setup (Strategy Analyzer)
Cari tahu strategi mana yang paling menguntungkan. Aplikasi secara otomatis menghitung performa (Win Rate, Profit, dll) berdasarkan setup/strategi yang Anda catat pada tiap *trade*.

---

## 🛠️ Teknologi yang Digunakan (Tech Stack)

- **Frontend:** [Flutter](https://flutter.dev/) (Dart)
- **Backend & Database:** [Supabase](https://supabase.com/) (PostgreSQL)
- **State Management:** Riverpod
- **Routing:** GoRouter
- **Charts:** fl_chart

---

## 🚀 Cara Menjalankan Proyek (Getting Started)

### Prasyarat
- Flutter SDK (Versi terbaru disarankan)
- Akun Supabase (Untuk konfigurasi Backend)

### Instalasi
1. Kloning repositori ini:
   ```bash
   git clone https://github.com/username-anda/mytrade.git
   ```
2. Masuk ke direktori proyek:
   ```bash
   cd mytrade
   ```
3. Unduh semua *dependencies*:
   ```bash
   flutter pub get
   ```
4. Siapkan konfigurasi Supabase Anda (Ganti kredensial API Key & URL pada file `.env` atau konfigurasi proyek Anda).
5. Jalankan aplikasi:
   ```bash
   flutter run
   ```

---

## 🤝 Kontribusi (Contributing)
Kontribusi selalu terbuka! Jika Anda memiliki ide fitur baru, perbaikan *bug*, atau optimisasi, silakan buat *Pull Request* atau laporkan pada tab *Issues*.

---

## 📄 Lisensi (License)
Proyek ini dilisensikan di bawah [MIT License](LICENSE).

---
*Dibuat dengan ❤️ untuk para Trader yang ingin berkembang.*
