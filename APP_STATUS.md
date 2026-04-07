# Flutter App — Module Status Report

> **Package:** `packages/app`
> **Stack:** Flutter / Dart / Riverpod / GoRouter
> **Legend:** ✅ Done & Connected to Server | 🟡 Partial | 🔵 Mock Data (UI Done — Replace with Real Data) | ❌ Not Built / No Connection

---

## QUICK SUMMARY

| Module | Status |
|--------|--------|
| Authentication | ✅ Done |
| Home Dashboard | 🟡 Partial |
| Asset Management | ✅ Done |
| Protection Plans | ✅ Done |
| Maintenance Records + AI Fix | 🟡 Partial |
| Claims | ✅ Done |
| Orders | ✅ Done |
| Family Members | ✅ Done |
| Profile & Settings | 🟡 Partial |
| Service Booking Flows (all 9) | 🔵 Mock Data |
| Shopping / Buy New Asset | 🔵 Mock Data |
| Payments / Stripe | 🔵 / ❌ Mixed |

---

## AUTHENTICATION ✅ DONE

| Screen | Status | Notes |
|--------|--------|-------|
| Splash Screen | ✅ | Checks login state, redirects |
| Sign In Screen | ✅ | OTP login via real server API |
| Sign Up Screen | ✅ | Registration via real server API |
| OTP Verification | ✅ | Verifies code via real server API |

---

## HOME DASHBOARD 🟡 PARTIAL

| Feature | Status | Notes |
|---------|--------|-------|
| Asset list | ✅ | Real data from server (`AssetApiService`) |
| Notifications bell | ✅ | Real data from server |
| Maintenance reminders preview | 🔵 | UI shows seeded sample data — replace with real server data |
| Quick action buttons | ✅ | Navigation UI |

---

## ASSET MANAGEMENT ✅ DONE

| Feature | Status | Notes |
|---------|--------|-------|
| View all assets | ✅ | Real server data |
| Asset detail screen | ✅ | Full detail — service history, docs, issues — all from server |
| Add new asset (5-step flow) | ✅ | All 5 steps save to server |
| Edit asset | ✅ | Updates server record |
| Upload document | ✅ | Sends to server |
| View documents | ✅ | From server |
| View issues on asset | ✅ | From server |
| View service history | ✅ | From server |

---

## PROTECTION PLANS ✅ DONE

| Feature | Status | Notes |
|---------|--------|-------|
| View all plans | ✅ | Real server data via `ProtectionPlanService` |
| Plan detail | ✅ | Real data |
| Purchase plan (5-step flow) | ✅ | Saves to server |
| Active plan check on assets | ✅ | Server auto-attaches this to each asset |

---

## MAINTENANCE 🟡 PARTIAL

| Feature | Status | Notes |
|---------|--------|-------|
| Maintenance dashboard | ✅ | Reads records from server |
| View maintenance records | ✅ | From server API |
| AI Fix Problem screen | ✅ | Calls `/ai/diagnose`, `/ai/diy-steps`, `/ai/search-parts` on server |
| Issue detail screen | ✅ | Real server data |
| DIY guide screen | 🟡 | Screen exists, content is static |
| Maintenance reminders | 🔵 | UI shows seeded sample data — replace with real server data |
| Parts Order: Order screen | 🔵 | UI complete (4 screens), shows placeholder data — needs server connection |
| Parts Order: Address screen | 🔵 | Shows dummy address — replace with real saved addresses |
| Parts Order: Payment screen | 🔵 | UI built — replace with real payment processing |
| Parts Order: Confirmation | 🔵 | UI built — replace with real order creation |

---

## CLAIMS ✅ DONE

| Feature | Status | Notes |
|---------|--------|-------|
| My Claims screen | ✅ | Real data via `ClaimsService` |
| File a new claim | ✅ | Submits to server |
| View claim status | ✅ | Real-time from server |

---

## ORDERS ✅ DONE

| Feature | Status | Notes |
|---------|--------|-------|
| My Orders screen | ✅ | Real data via `OrderService` |
| Create new order | ✅ | Saves to server |
| View order detail | ✅ | From server |

---

## FAMILY MEMBERS ✅ DONE

| Feature | Status | Notes |
|---------|--------|-------|
| Family members screen | ✅ | Real data via `FamilyApiService` |
| Invite member | ✅ | Server sends email invite |
| Accept invitation | ✅ | Real API call |
| Member detail screen | ✅ | Real data |
| Manage asset access | ✅ | Saves to server |
| My Family Access screen | ✅ | Real server data |

---

## PROFILE & SETTINGS 🟡 PARTIAL

| Feature | Status | Notes |
|---------|--------|-------|
| View profile | ✅ | Real user data |
| Edit profile | ✅ | Saves to server via `UserService` |
| Settings screen | ✅ | Preferences UI |
| Push notifications toggle | 🟡 | UI exists; Firebase credentials not configured |
| Pending deliveries screen | 🟡 | Screen exists; no server data wired |

---

## SERVICE BOOKING FLOWS 🔵 ALL MOCK DATA

> All 9 service types have complete multi-step booking screens. They look fully finished — UI works and shows data — but bookings are saved to **phone storage only**, not the server. The backend booking API is ready and waiting. Replace phone storage with real server calls.
>
> **Known issue to fix:** Code uses hardcoded `homeId: 'home-1'` and `userId: 'user-1'` — must use real logged-in user/home IDs.

| Service | Screens Built | Server Connection |
|---------|--------------|-------------------|
| Assembly | ✅ 5-step flow | 🔵 Saves to phone — replace with server save |
| Cleaning | ✅ Multi-step | 🔵 Saves to phone — replace with server save |
| Home Repairs | ✅ Multi-step | 🔵 Saves to phone — replace with server save |
| Mounting | ✅ Multi-step | 🔵 Saves to phone — replace with server save |
| Moving | ✅ Multi-step | 🔵 Saves to phone — replace with server save |
| Outdoor Services | ✅ Multi-step | 🔵 Saves to phone — replace with server save |
| Painting | ✅ Multi-step | 🔵 Saves to phone — replace with server save |
| Security | ✅ Multi-step | 🔵 Saves to phone — replace with server save |
| Lifestyle | ✅ Multi-step | 🔵 Saves to phone — replace with server save |
| Active Services screen | ✅ UI | 🔵 Shows phone storage data — replace with server data |
| Booking Detail screen | ✅ UI | 🔵 Shows phone storage data — replace with server data |
| Service History screen | ✅ UI | 🔵 Shows phone storage data — replace with server data |

---

## SHOPPING / BUY NEW ASSET 🔵 ALL MOCK DATA

| Feature | Status | Notes |
|---------|--------|-------|
| Browse products | 🔵 | `_getMockProducts()` — UI shows hardcoded catalog — replace with real product API |
| Product detail | 🔵 | Shows static data — replace with real product lookup |
| Upgrade / replace asset flow | 🔵 | `buildUpgradeMockProducts()` — UI works — replace with real catalog |
| Shopping cart | 🔵 | UI exists and works — replace with real cart/order save |
| Checkout: Address | 🔵 | Shows dummy addresses — replace with real saved addresses |
| Checkout: Payment | 🔵 | Shows fake Apple Pay / Google Pay dialog — replace with real Stripe charge |
| Checkout: Confirmation | 🔵 | UI shows success screen — replace with real order confirmation |

---

## PAYMENTS / STRIPE 🔵 / ❌ MIXED

| Feature | Status | Notes |
|---------|--------|-------|
| Add payment card | ❌ | Stripe key is `pk_test_YOUR_STRIPE_KEY` — literal placeholder, must integrate Stripe |
| Saved payment methods | 🔵 | UI shows mock cards `pm_mock_1` (Visa), `pm_mock_2` (Mastercard) — replace with real Stripe saved methods |
| Process payment | ❌ | All methods have `// TODO: Implement with Stripe` — not built |
| Apple Pay | 🔵 | UI shows a fake success dialog — replace with real Apple Pay flow |
| Google Pay | 🔵 | UI shows a fake success dialog — replace with real Google Pay flow |
| `flutter_stripe` package | ❌ | **Not listed in `pubspec.yaml`** — library must be installed before any Stripe work |

---

## COMPLETION ESTIMATE

```
✅  Done:    Auth, Assets, Protection Plans, Claims, Orders, Family, AI Fix, Maintenance Records
🟡  Partial: Home Dashboard, Profile, DIY Guide
🔵  Mock:    All 9 Service Flows, Shopping, Checkout, Parts Order,
             Maintenance Reminders, Saved Payment Methods, Apple/Google Pay dialogs
❌  Pending: Stripe integration (library not installed), Real payment processing

Overall: ~55% connected to server | Mock data screens that need real data wiring: ~35%
```
