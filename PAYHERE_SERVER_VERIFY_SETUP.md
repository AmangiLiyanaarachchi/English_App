# PayHere Server Verification Setup

This project now verifies PayHere payments on the backend in `functions/index.js` using `payhereNotify`.

## 1. Set Cloud Function Secrets

Run these commands from the project root (`English_App`):

```powershell
firebase functions:secrets:set PAYHERE_MERCHANT_ID
firebase functions:secrets:set PAYHERE_MERCHANT_SECRET
```

Use these values when prompted:

- `PAYHERE_MERCHANT_ID`: `251015`
- `PAYHERE_MERCHANT_SECRET`: your live merchant secret

## 2. Deploy Functions

```powershell
cd functions
npm install
cd ..
firebase deploy --only functions
```

After deploy, your webhook URL is:

`https://us-central1-chatapp-40a85.cloudfunctions.net/payhereNotify`

## 3. Run App in Live Mode

From the `English_App` folder:

```powershell
flutter run -d R9YR8086S5T --dart-define-from-file=payhere.env.live.json
```

## 4. What is now verified server-side

- `merchant_id` must match secret config.
- `md5sig` hash must match expected PayHere signature.
- `status_code` must be `2`.
- Amount/currency are checked against the pending `payments/{orderId}` record if present.
- On success, user package/subscriptions are granted by server transaction.

## 5. Firestore Collections to monitor

- `payments` (status + verification + entitlement timestamps)
- `payhereNotifications` (raw notify payload + verification result)
