# Checkout API Contract (Nizen Store)

Bu dokuman, frontend'in checkout oturumu olusturmak icin bekledigi API sozlesmesini tanimlar.

## Endpoint

- `POST /api/checkout/session`
- `Content-Type: application/json`
- Opsiyonel: `Authorization: Bearer <token>`

Frontend konfigurasyonu:

- `APP_CONFIG.checkoutApiUrl`: bu endpoint'in tam URL'i
- `APP_CONFIG.checkoutAuthToken`: opsiyonel sabit token

Provider modu backend tarafinda `PAYMENT_PROVIDER` ile secilir:

- `mock`
- `stripe`
- `iyzico`

## Request Body

```json
{
  "checkoutVersion": "2026-03",
  "createdAt": "2026-03-05T12:00:00.000Z",
  "idempotencyKey": "nizen_1741176000000_ab12cd34",
  "currency": "TRY",
  "language": "tr",
  "coupon": "NIZEN10",
  "totals": {
    "subtotal": 3290,
    "discount": 329,
    "discountedSubtotal": 2961,
    "shipping": 0,
    "tax": 592,
    "grandTotal": 3553
  },
  "items": [
    {
      "id": 12,
      "name": "Kisa Ceket - Bordo Modern Kesim",
      "size": "M",
      "qty": 1,
      "unitPrice": 1590,
      "lineTotal": 1590
    }
  ]
}
```

## Success Response

HTTP `200`:

```json
{
  "sessionId": "cs_test_123456",
  "redirectUrl": "https://pay.example.com/checkout/cs_test_123456",
  "expiresAt": "2026-03-05T12:20:00.000Z",
  "provider": "mock",
  "orderStatus": "pending_payment"
}
```

Gerekli alan:

- `redirectUrl` (string)
- `provider` (string)
- `orderStatus` (string)

## Error Responses

- `400` invalid payload
- `401` unauthorized
- `409` duplicate idempotency key (ayni sonucu donebilir)
- `422` stock/price mismatch
- `500` server error

Ornek:

```json
{
  "errorCode": "INVALID_PAYLOAD",
  "message": "items[0].qty must be >= 1"
}
```

## Backend Validasyon Beklentileri

- Her satir icin `qty >= 1`, `unitPrice >= 0`
- Urun ve beden kombinasyonu gecerli mi kontrolu
- Sunucu tarafi fiyat ve kampanya hesaplama (frontend tutarlarini dogrulama)
- Idempotency key ile tekrarli siparis olusumunu engelleme
- `redirectUrl` sadece guvenilir domainlerden uretilmeli

## Frontend Davranisi

- API basariliysa `redirectUrl`'e yonlenir.
- API kullanilmiyorsa `APP_CONFIG.checkoutUrl` fallback olarak kullanilir.
- Son checkout payload localde `nizen_checkout_payload` anahtarina yazilir.

## Order Status API

- `GET /api/orders/:idempotencyKey`
- `GET /api/orders/session/:sessionId`

Durum alanlari:

- `pending_payment`
- `paid`
- `payment_failed`
- `expired`

Not: `CHECKOUT_AUTH_TOKEN` tanimliysa bu endpoint'lerde `Authorization: Bearer <token>` beklenir.

## Provider Notlari

### Stripe

- `PAYMENT_PROVIDER=stripe`
- Gerekli env:
  - `STRIPE_SECRET_KEY`
  - `STRIPE_WEBHOOK_SECRET`
  - `STRIPE_SUCCESS_URL`
  - `STRIPE_CANCEL_URL`

Stripe webhook endpoint:

- `POST /webhooks/stripe`
- Onerilen eventler:
  - `checkout.session.completed`
  - `checkout.session.expired`
  - `checkout.session.async_payment_failed`

### iyzico

- `PAYMENT_PROVIDER=iyzico`
- Gerekli env:
  - `IYZICO_API_KEY`
  - `IYZICO_SECRET_KEY`
  - `IYZICO_BASE_URL`
  - `IYZICO_CALLBACK_URL`

iyzico webhook/callback endpointleri:

- `POST /webhooks/iyzico`
- `POST /iyzico/callback`

