# Setup Google Maps API Key

## Masalah
Peta Google Maps tidak tampil (layar kosong) karena API key belum dikonfigurasi.

## Solusi

### Langkah 1: Dapatkan Google Maps API Key

1. Buka [Google Cloud Console](https://console.cloud.google.com/)
2. Buat project baru atau pilih project yang sudah ada
3. Enable **Maps SDK for Android** API:
   - Pergi ke "APIs & Services" → "Library"
   - Cari "Maps SDK for Android"
   - Klik "Enable"
4. Buat API Key:
   - Pergi ke "APIs & Services" → "Credentials"
   - Klik "Create Credentials" → "API Key"
   - Copy API key yang dibuat

### Langkah 2: Konfigurasi API Key (RECOMMENDED - Gunakan Restrictions)

Untuk keamanan, tambahkan restrictions ke API key Anda:

1. Di halaman Credentials, klik API key yang baru dibuat
2. Pilih "Application restrictions":
   - Pilih "Android apps"
   - Klik "Add an item"
3. Masukkan package name dan SHA-1 certificate fingerprint:
   - **Package name**: `com.example.anigmaa`
   - **SHA-1**: Dapatkan dengan menjalankan:
     ```bash
     # Debug certificate (untuk development)
     keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

     # Release certificate (untuk production)
     keytool -list -v -keystore /path/to/your/release.keystore -alias your_alias_name
     ```
   - Copy nilai SHA-1 certificate fingerprint dan paste
4. Klik "Save"

### Langkah 3: Update AndroidManifest.xml

Edit file `/home/user/anigmaa/android/app/src/main/AndroidManifest.xml` dan ganti `YOUR_API_KEY_HERE` dengan API key yang Anda dapatkan:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSy..." />  <!-- Ganti dengan API key Anda -->
```

### Langkah 4: Rebuild Aplikasi

```bash
# Bersihkan build
flutter clean

# Get dependencies
flutter pub get

# Build ulang
flutter build apk
# atau
flutter run
```

## Troubleshooting

### Peta masih tidak tampil setelah menambahkan API key

1. **Periksa API key sudah benar**: Pastikan tidak ada spasi atau karakter tambahan
2. **Enable APIs yang diperlukan di Google Cloud Console**:
   - Maps SDK for Android
   - Places API (jika menggunakan search)
   - Geocoding API (untuk reverse geocoding)
3. **Periksa restrictions**: Pastikan package name (`com.example.anigmaa`) dan SHA-1 fingerprint sudah benar
4. **Tunggu beberapa menit**: Setelah membuat API key, mungkin butuh waktu 5-10 menit untuk aktif
5. **Periksa billing**: Pastikan billing sudah diaktifkan di Google Cloud Console
6. **Lihat logcat** untuk error messages:
   ```bash
   adb logcat | grep -i "maps\|google"
   ```

### Common Error Messages

- **"AUTHORIZATION_FAILURE"**: API key tidak valid atau restrictions tidak sesuai
- **"API_KEY_EXPIRED"**: API key sudah expired (check di console)
- **"OVER_QUERY_LIMIT"**: Quota sudah habis (check billing)

## Catatan Penting

- **JANGAN commit API key ke Git**: Tambahkan ke `.gitignore`
- Gunakan environment variables atau secrets management untuk production
- Monitor usage di Google Cloud Console untuk menghindari biaya tak terduga
- Free tier: $200 kredit gratis per bulan (28,500 map loads)

## Referensi

- [Get API Key - Google Maps Platform](https://developers.google.com/maps/documentation/android-sdk/get-api-key)
- [Using API Keys - Google Maps Platform](https://developers.google.com/maps/documentation/android-sdk/signup)
- [Restrict API Keys - Best Practices](https://developers.google.com/maps/api-security-best-practices)
