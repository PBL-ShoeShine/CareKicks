# API Contract - Pemindai (Admin)

Modul ini digunakan untuk memvalidasi QR Code dari label sepatu guna mendapatkan detail pesanan.

## 1. Verify QR Code

- **URL**: `/api/v1/admin/pemindai/verify`
- **Method**: `POST`
- **Auth**: Required (Bearer Token)

### Request Body
```json
{
  "qr_code": "[https://qris.id/1](https://qris.id/1)"
}