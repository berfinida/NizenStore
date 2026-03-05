param(
    [ValidateSet("stripe", "iyzico", "checkout-only")]
    [string]$Mode = "stripe",
    [string]$ApiBaseUrl = "http://localhost:8787",
    [string]$AuthToken = "",
    [string]$IdempotencyKey = "",
    [int]$PollCount = 6,
    [int]$PollIntervalSec = 2,
    [switch]$SkipStripeTrigger
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step($msg) {
    Write-Host "`n==> $msg" -ForegroundColor Cyan
}

function Build-Headers {
    param([string]$Token)
    $h = @{ "Content-Type" = "application/json" }
    if ($Token) { $h["Authorization"] = "Bearer $Token" }
    return $h
}

function New-CheckoutPayload {
    param([string]$Key)

    $subtotal = 1000
    $discount = 0
    $discountedSubtotal = 1000
    $shipping = 0
    $tax = 200
    $grandTotal = 1200

    return @{
        checkoutVersion = "2026-03"
        createdAt = (Get-Date).ToUniversalTime().ToString("o")
        idempotencyKey = $Key
        currency = "TRY"
        language = "tr"
        coupon = $null
        totals = @{
            subtotal = $subtotal
            discount = $discount
            discountedSubtotal = $discountedSubtotal
            shipping = $shipping
            tax = $tax
            grandTotal = $grandTotal
        }
        items = @(
            @{
                id = 1
                name = "Test Urun"
                size = "M"
                qty = 1
                unitPrice = $subtotal
                lineTotal = $subtotal
            }
        )
    }
}

function Invoke-CheckoutSession {
    param(
        [string]$BaseUrl,
        [string]$Token,
        [hashtable]$Payload
    )
    $headers = Build-Headers -Token $Token
    $uri = "$BaseUrl/api/checkout/session"
    $body = $Payload | ConvertTo-Json -Depth 10
    return Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
}

function Get-OrderByIdempotency {
    param(
        [string]$BaseUrl,
        [string]$Token,
        [string]$Key
    )
    $headers = Build-Headers -Token $Token
    $uri = "$BaseUrl/api/orders/$Key"
    return Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
}

function Try-RunStripeTriggers {
    if ($SkipStripeTrigger) {
        Write-Host "Stripe trigger adimi atlandi (-SkipStripeTrigger)." -ForegroundColor Yellow
        return
    }
    $stripeCmd = Get-Command stripe -ErrorAction SilentlyContinue
    if (-not $stripeCmd) {
        Write-Host "Stripe CLI bulunamadi. Tetikleme atlandi." -ForegroundColor Yellow
        Write-Host "Kurulum: https://stripe.com/docs/stripe-cli" -ForegroundColor Yellow
        return
    }
    Write-Step "Stripe test eventleri tetikleniyor"
    & stripe trigger checkout.session.completed | Out-Null
    & stripe trigger checkout.session.expired | Out-Null
    & stripe trigger checkout.session.async_payment_failed | Out-Null
    Write-Host "Stripe trigger komutlari gonderildi."
}

if (-not $IdempotencyKey) {
    $IdempotencyKey = "nizen_test_{0}" -f ([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())
}

Write-Step "Checkout session olusturuluyor"
$payload = New-CheckoutPayload -Key $IdempotencyKey
$session = Invoke-CheckoutSession -BaseUrl $ApiBaseUrl -Token $AuthToken -Payload $payload
$session | ConvertTo-Json -Depth 10

if ($Mode -eq "stripe") {
    Try-RunStripeTriggers
} elseif ($Mode -eq "iyzico") {
    Write-Host "iyzico icin odemeyi sandbox payment page uzerinden tamamlayin." -ForegroundColor Yellow
}

Write-Step "Order status polling basliyor"
for ($i = 1; $i -le $PollCount; $i++) {
    try {
        $order = Get-OrderByIdempotency -BaseUrl $ApiBaseUrl -Token $AuthToken -Key $IdempotencyKey
        $status = $order.status
        Write-Host ("[{0}/{1}] status: {2}" -f $i, $PollCount, $status)
        if ($status -in @("paid", "payment_failed", "expired")) {
            Write-Host "Terminal duruma ulasildi: $status" -ForegroundColor Green
            break
        }
    } catch {
        Write-Host ("[{0}/{1}] status sorgusu basarisiz: {2}" -f $i, $PollCount, $_.Exception.Message) -ForegroundColor Yellow
    }
    Start-Sleep -Seconds $PollIntervalSec
}

Write-Step "Tamamlandi"
Write-Host "idempotencyKey: $IdempotencyKey"
