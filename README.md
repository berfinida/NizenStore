# Nizen Store

Tek sayfa (single-file) butik e-ticaret demo arayuzu. Proje yalnizca `index.html` dosyasi ile calisir; urun listesi, sepet, favoriler, kombinler, dil degisimi (TR/EN) ve modal/panel akislarini istemci tarafinda yonetir.

## Ozellikler

- Kadin/erkek koleksiyonlari ve kategori filtreleri
- Arama + filtre kombinasyonu
- Urun karti, hizli beden secimi ve detay modal'i
- Sepet paneli (adet, toplam, silme)
- Favoriler paneli ve favoriden sepete ekleme akisi
- Hazir kombinler (look) ve tek tikla coklu urun ekleme
- Kampanya slider'i (ok/dot/otomatik gecis)
- TR/EN i18n metinleri ve fiyat gosterimi
- `localStorage` ile sepet/favori/dil kaliciligi
- Erisilebilirlik odakli iyilestirmeler:
  - `aria-live` bildirimleri
  - klavye ile kart acma (Enter/Space)
  - ESC/overlay/back ile katman kapatma
  - modal/panel focus trap

## Hizli Baslangic

1. Depoyu/acik dosyalari ayni klasorde tutun.
2. `index.html` dosyasini tarayicida acin.
3. Gelistirme icin Live Server gibi bir aracla klasoru serve edebilirsiniz (opsiyonel).

Not: Ayrica bir paket yoneticisi, build adimi veya backend gerektirmez.

## Checkout API (Opsiyonel ama onerilir)

Gercek odeme akisina yakin test icin minimal Node/Express checkout API dahil edildi.

1. `npm install`
2. `.env.example` dosyasini `.env` olarak kopyalayin ve gerekirse degerleri guncelleyin.
3. `npm start`
4. Frontend icinde `APP_CONFIG.checkoutApiUrl` alanini `http://localhost:8787/api/checkout/session` yapin.

Provider secenekleri:

- `PAYMENT_PROVIDER=mock` (varsayilan)
- `PAYMENT_PROVIDER=stripe`
- `PAYMENT_PROVIDER=iyzico`

Stripe icin:

- `STRIPE_SECRET_KEY`
- `STRIPE_WEBHOOK_SECRET`
- `STRIPE_SUCCESS_URL`
- `STRIPE_CANCEL_URL`

iyzico icin:

- `IYZICO_API_KEY`
- `IYZICO_SECRET_KEY`
- `IYZICO_BASE_URL`
- `IYZICO_CALLBACK_URL`

Order durum endpointleri:

- `GET /api/orders/:idempotencyKey`
- `GET /api/orders/session/:sessionId`

Webhook endpointleri:

- Stripe: `POST /webhooks/stripe`
- iyzico: `POST /webhooks/iyzico`
- iyzico callback: `POST /iyzico/callback`

## Webhook Test Scripti (PowerShell)

Tek komutla checkout + order status polling + (opsiyonel) Stripe trigger:

```bash
npm run test:webhooks
```

Ornekler:

```bash
powershell -ExecutionPolicy Bypass -File scripts/test-webhooks.ps1 -Mode stripe -AuthToken "<TOKEN>"
powershell -ExecutionPolicy Bypass -File scripts/test-webhooks.ps1 -Mode iyzico -AuthToken "<TOKEN>"
powershell -ExecutionPolicy Bypass -File scripts/test-webhooks.ps1 -Mode checkout-only -AuthToken "<TOKEN>"
```

API sozlesmesi:

- `CHECKOUT_API_CONTRACT.md`

## Proje Yapisi

- `index.html`: Tum HTML + CSS + JavaScript kodu
- `CHECKOUT_API_CONTRACT.md`: Checkout API istek/yanit sozlesmesi
- `server.js`: Minimal checkout session API sunucusu
- `.env.example`: Checkout API ortam degiskenleri ornegi

## Veri Kaliciligi

Uygulama asagidaki anahtarlarla `localStorage` kullanir:

- `nizen_cart`
- `nizen_wishlist`
- `nizen_lang`
- `nizen_checkout_payload`

Okuma/yazma islemleri `safeLoadJSON`, `safeSetJSON`, `safeGetValue`, `safeSetValue` yardimcilariyla korumali yapilir.

## Sonraki Iyilestirmeler

Planlanan baslica sonraki adimlar:

- CDN varliklari icin SRI sabitleme
- i18n kapsami icin otomatik test
- DOM smoke testleri
- kapsamli erisilebilirlik denetimi (axe)

