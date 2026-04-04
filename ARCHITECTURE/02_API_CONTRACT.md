# HomeIQ — Complete API Contract

> **Version**: 1.0  
> **Base URL**: `https://api.homeiq.com/v1`  
> **Auth**: Bearer JWT token in `Authorization` header  
> **Content-Type**: `application/json`

---

## Standard Conventions

### Headers (All Requests)
```
Authorization: Bearer <access_token>       # Required for protected endpoints
Content-Type: application/json
X-Request-ID: <uuid>                        # Auto-generated, for tracing
X-App-Version: 1.0.0                        # Client app version
X-Platform: ios | android | web             # Client platform
```

### Success Response
```json
{
  "success": true,
  "data": { ... },
  "meta": {                    // Only for paginated endpoints
    "page": 1,
    "pageSize": 20,
    "totalItems": 150,
    "totalPages": 8
  }
}
```

### Error Response
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Human-readable error message",
    "details": [               // Only for validation errors
      { "field": "email", "message": "Must be a valid email" }
    ]
  }
}
```

### Error Codes
| Code | HTTP Status | Meaning |
|------|------------|---------|
| `VALIDATION_ERROR` | 400 | Invalid request body/params |
| `UNAUTHORIZED` | 401 | Missing or invalid token |
| `FORBIDDEN` | 403 | Insufficient permissions (RBAC) |
| `NOT_FOUND` | 404 | Resource not found |
| `CONFLICT` | 409 | Duplicate resource (email, phone) |
| `RATE_LIMITED` | 429 | Too many requests |
| `INTERNAL_ERROR` | 500 | Server error |
| `SERVICE_UNAVAILABLE` | 503 | Downstream service down |

### Pagination (Query Params)
```
?page=1&pageSize=20&sortBy=created_at&sortOrder=desc
```

### Filtering (Query Params)
```
?status=active&type=repair&from=2026-01-01&to=2026-12-31
```

---

## 1. Authentication (8 endpoints)

### `POST /v1/auth/signup`
Create a new user account.
```json
// Request
{
  "full_name": "John Doe",
  "email": "john@example.com",       // Optional if phone provided
  "phone": "+12125551234",           // Optional if email provided
  "password": "SecureP@ss123"        // Optional (OTP-based auth possible)
}

// Response 201
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "full_name": "John Doe",
      "email": "john@example.com",
      "phone": "+12125551234",
      "email_verified": false,
      "phone_verified": false,
      "created_at": "2026-02-23T10:00:00Z"
    },
    "otp_sent_to": "john@example.com",  // Or phone number
    "otp_type": "email"                  // Or "sms"
  }
}
```

### `POST /v1/auth/signin`
Sign in with email or phone.
```json
// Request
{
  "email_or_phone": "john@example.com",  // Email or phone
  "password": "SecureP@ss123"            // Optional if using OTP flow
}

// Response 200 (if password auth)
{
  "success": true,
  "data": {
    "access_token": "eyJhbG...",
    "refresh_token": "dGhpcyBpcyBhI...",
    "expires_in": 900,                    // 15 minutes in seconds
    "user": { ... }
  }
}

// Response 200 (if OTP auth — no password provided)
{
  "success": true,
  "data": {
    "otp_sent_to": "+12125551234",
    "otp_type": "sms",
    "message": "OTP sent successfully"
  }
}
```

### `POST /v1/auth/otp/send`
Send OTP code to email or phone.
```json
// Request
{
  "identifier": "+12125551234",          // Email or phone
  "type": "sms"                          // "sms" or "email"
}

// Response 200
{
  "success": true,
  "data": {
    "message": "OTP sent successfully",
    "expires_in": 300                     // 5 minutes
  }
}
```

### `POST /v1/auth/otp/verify`
Verify OTP and get tokens.
```json
// Request
{
  "identifier": "+12125551234",
  "code": "123456",
  "type": "sms"
}

// Response 200
{
  "success": true,
  "data": {
    "access_token": "eyJhbG...",
    "refresh_token": "dGhpcyBpcyBhI...",
    "expires_in": 900,
    "is_new_user": false,
    "user": {
      "id": "uuid",
      "full_name": "John Doe",
      "email": "john@example.com",
      "phone": "+12125551234",
      "avatar_url": null,
      "email_verified": true,
      "phone_verified": true,
      "created_at": "2026-02-23T10:00:00Z"
    }
  }
}
```

### `POST /v1/auth/google`
Sign in with Google OAuth.
```json
// Request
{
  "id_token": "eyJhbGciOiJSUzI1..."     // Google ID token from client SDK
}

// Response 200
{
  "success": true,
  "data": {
    "access_token": "eyJhbG...",
    "refresh_token": "dGhpcyBpcyBhI...",
    "expires_in": 900,
    "is_new_user": true,                  // True if account just created
    "user": { ... }
  }
}
```

### `POST /v1/auth/apple`
Sign in with Apple.
```json
// Request
{
  "identity_token": "eyJraWQiOi...",
  "authorization_code": "c12abc...",
  "user_identifier": "001234.abc...",
  "full_name": "John Doe",              // Only provided on first login
  "email": "john@privaterelay.apple.com" // May be relay email
}

// Response 200 (same format as Google)
```

### `POST /v1/auth/refresh`
Refresh access token. **Auth: Refresh token in body (not JWT)**
```json
// Request
{
  "refresh_token": "dGhpcyBpcyBhI..."
}

// Response 200
{
  "success": true,
  "data": {
    "access_token": "eyJhbG...",          // New access token
    "refresh_token": "bmV3IHJlZnJl...",   // New refresh token (rotation)
    "expires_in": 900
  }
}
```

### `POST /v1/auth/logout`
Invalidate current session. **Auth: Required**
```json
// Request
{
  "refresh_token": "dGhpcyBpcyBhI..."    // Optional: invalidate specific session
}

// Response 200
{
  "success": true,
  "data": { "message": "Logged out successfully" }
}
```

---

## 2. Users (3 endpoints)

### `GET /v1/users/me`
Get current user profile. **Auth: Required**
```json
// Response 200
{
  "success": true,
  "data": {
    "id": "uuid",
    "full_name": "John Doe",
    "email": "john@example.com",
    "phone": "+12125551234",
    "avatar_url": "https://cdn.homeiq.com/avatars/uuid.jpg",
    "language": "en-US",
    "auth_provider": "email",
    "email_verified": true,
    "phone_verified": true,
    "last_login_at": "2026-02-23T10:00:00Z",
    "created_at": "2026-01-15T08:30:00Z",
    "settings": {
      "theme": "light",
      "date_format": "MM/DD/YYYY",
      "time_format": "12h",
      "default_home_id": "uuid"
    },
    "notification_preferences": {
      "email_enabled": true,
      "sms_enabled": true,
      "push_enabled": true,
      "maintenance_reminders": true,
      "service_bookings": true,
      "asset_alerts": true
    }
  }
}
```

### `PUT /v1/users/me`
Update user profile. **Auth: Required**
```json
// Request (partial update — only send changed fields)
{
  "full_name": "John Smith",
  "avatar_url": "https://cdn.homeiq.com/avatars/new.jpg",
  "language": "en-US",
  "settings": {
    "theme": "dark",
    "default_home_id": "uuid"
  },
  "notification_preferences": {
    "sms_enabled": false
  }
}

// Response 200
{
  "success": true,
  "data": { ... }    // Full updated user object
}
```

### `DELETE /v1/users/me`
Delete user account (soft delete). **Auth: Required**
```json
// Request
{
  "confirmation": "DELETE MY ACCOUNT"     // Require explicit confirmation
}

// Response 200
{
  "success": true,
  "data": { "message": "Account scheduled for deletion. You have 30 days to reactivate." }
}
```

---

## 3. Households (8 endpoints)

### `GET /v1/households`
List all households the current user belongs to. **Auth: Required**
```json
// Response 200
{
  "success": true,
  "data": [
    {
      "id": "uuid-1",
      "name": "Mom's House",
      "address_line1": "123 Main St",
      "city": "New York",
      "state": "NY",
      "zip_code": "10001",
      "property_type": "house",
      "my_role": "owner",
      "member_count": 3,
      "asset_count": 6,
      "created_at": "2026-01-15T08:30:00Z"
    },
    {
      "id": "uuid-2",
      "name": "My Apartment",
      "my_role": "member",
      "member_count": 1,
      "asset_count": 2,
      "created_at": "2026-02-01T12:00:00Z"
    }
  ]
}
```

### `POST /v1/households`
Create a new household. **Auth: Required**
```json
// Request
{
  "name": "Dad's House",
  "address_line1": "456 Oak Ave",
  "address_line2": "Apt 2B",
  "city": "Los Angeles",
  "state": "CA",
  "zip_code": "90001",
  "property_type": "house"
}

// Response 201
{
  "success": true,
  "data": {
    "id": "uuid",
    "name": "Dad's House",
    "my_role": "owner",
    ...
  }
}
```

### `GET /v1/households/:id`
Get household details. **Auth: Required, Member of household**
```json
// Response 200
{
  "success": true,
  "data": {
    "id": "uuid",
    "name": "Mom's House",
    "address_line1": "123 Main St",
    "city": "New York",
    "state": "NY",
    "zip_code": "10001",
    "property_type": "house",
    "my_role": "owner",
    "members": [
      { "id": "uuid", "user_id": "uuid", "full_name": "John Doe", "role": "owner", "status": "active" },
      { "id": "uuid", "user_id": "uuid", "full_name": "Sarah Doe", "role": "admin", "status": "active" },
      { "id": "uuid", "user_id": null, "invited_email": "emma@example.com", "role": "member", "status": "pending" }
    ],
    "summary": {
      "total_assets": 6,
      "active_alerts": 2,
      "active_bookings": 1,
      "overdue_maintenance": 3
    }
  }
}
```

### `PUT /v1/households/:id`
Update household. **Auth: Required, Owner or Admin**
```json
// Request
{
  "name": "Mom's New House",
  "address_line1": "789 New St"
}
```

### `DELETE /v1/households/:id`
Delete household. **Auth: Required, Owner only**

### `POST /v1/households/:id/invite`
Invite a family member. **Auth: Required, Owner or Admin**
```json
// Request
{
  "email": "jane@example.com",
  "name": "Jane Doe",
  "role": "member",                       // "admin", "member", "viewer"
  "message": "Join our home on HomeIQ!"   // Optional
}

// Response 201
{
  "success": true,
  "data": {
    "invite_id": "uuid",
    "invited_email": "jane@example.com",
    "role": "member",
    "status": "pending",
    "expires_at": "2026-03-02T10:00:00Z"  // 7 days
  }
}
// Backend also sends invitation email with link
```

### `GET /v1/households/:id/members`
List members and pending invites. **Auth: Required, Member of household**

### `POST /v1/invites/:token/accept`
Accept a household invite. **Auth: Required (must be logged in)**
```json
// Response 200
{
  "success": true,
  "data": {
    "household_id": "uuid",
    "household_name": "Mom's House",
    "role": "member",
    "message": "You've joined Mom's House!"
  }
}
```

---

## 4. Assets (8 endpoints)

### `GET /v1/households/:hid/assets`
List all assets for a household. **Auth: Required, Member**
```
?status=active&category=appliances&search=samsung&sortBy=health_score&sortOrder=asc
```
```json
// Response 200
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "nickname": "Kitchen Fridge",
      "brand": "Samsung",
      "model_number": "RT-5000",
      "subcategory": { "id": "uuid", "name": "Refrigerator", "category": "Appliances" },
      "location_in_home": "Kitchen",
      "health_score": 85,
      "status": "active",
      "warranty_status": "active",              // Computed: "active", "expired", "none"
      "warranty_end_date": "2027-06-15",
      "has_protection_plan": true,
      "purchase_date": "2022-06-15",
      "image_url": "https://cdn.homeiq.com/assets/uuid.jpg",
      "overdue_maintenance_count": 1,
      "created_at": "2026-01-20T09:00:00Z"
    }
  ],
  "meta": { "page": 1, "pageSize": 20, "totalItems": 6, "totalPages": 1 }
}
```

### `POST /v1/households/:hid/assets`
Add a new asset. **Auth: Required, Owner/Admin/Member**
```json
// Request
{
  "subcategory_id": "uuid",
  "brand": "Samsung",
  "model_number": "RT-5000",
  "serial_number": "SN123456",
  "sub_category": "French Door",
  "nickname": "Kitchen Fridge",
  "identification_method": "manual",
  "location_in_home": "Kitchen",
  "purchase_date": "2022-06-15",
  "purchase_year": 2022,
  "purchase_month": 6,
  "purchase_price": 1299.99,
  "retailer": "Best Buy"
}

// Response 201
{
  "success": true,
  "data": {
    "id": "uuid",
    "brand": "Samsung",
    "model_number": "RT-5000",
    "health_score": 75,                   // Initial computed score
    ...
  }
}
// Backend also: creates maintenance reminders from templates
```

### `GET /v1/assets/:id`
Get full asset details. **Auth: Required, Member of asset's household**
```json
// Response 200
{
  "success": true,
  "data": {
    "id": "uuid",
    "household_id": "uuid",
    "brand": "Samsung",
    "model_number": "RT-5000",
    "serial_number": "SN123456",
    "nickname": "Kitchen Fridge",
    "subcategory": { "id": "uuid", "name": "Refrigerator", "category": "Appliances" },
    "location_in_home": "Kitchen",
    "purchase_date": "2022-06-15",
    "purchase_price": 1299.99,
    "retailer": "Best Buy",
    "status": "active",
    "image_url": "...",
    
    // Health
    "health": {
      "score": 85,
      "risk_score": 15,
      "factors": {
        "age": 80,
        "maintenance_rate": 90,
        "issue_history": 95,
        "brand_reliability": 75
      },
      "recommendation": "maintain",
      "recommendation_confidence": 85,
      "replacement_urgency": "low",
      "last_computed": "2026-02-23T06:00:00Z"
    },
    
    // Warranties
    "warranties": [
      {
        "id": "uuid",
        "type": "manufacturer",
        "provider_name": "Samsung",
        "start_date": "2022-06-15",
        "end_date": "2023-06-15",
        "status": "expired"
      },
      {
        "id": "uuid",
        "type": "protection_plan",
        "provider_name": "SquareTrade",
        "start_date": "2023-06-15",
        "end_date": "2027-06-15",
        "status": "active"
      }
    ],
    
    // Protection plan
    "protection_plan": {
      "id": "uuid",
      "plan_name": "Premium",
      "billing_type": "monthly",
      "price": 14.99,
      "deductible": 50,
      "coverage_start": "2023-06-15",
      "coverage_end": "2027-06-15",
      "is_active": true
    },
    
    // Documents
    "documents": [
      { "id": "uuid", "type": "receipt", "file_name": "receipt.pdf", "file_url": "...", "created_at": "..." }
    ],
    
    // Recent maintenance
    "upcoming_maintenance": [
      { "id": "uuid", "task_name": "Clean Condenser Coils", "due_date": "2026-03-15", "priority": "medium", "status": "upcoming" }
    ],
    "overdue_maintenance_count": 1,
    
    // Recent claims
    "recent_claims": [
      { "id": "uuid", "claim_number": "CLM-2026-0001", "type": "repair", "status": "resolved", "submitted_at": "..." }
    ],
    
    "created_at": "2026-01-20T09:00:00Z",
    "updated_at": "2026-02-23T10:00:00Z"
  }
}
```

### `PUT /v1/assets/:id`
Update asset. **Auth: Required, Owner/Admin/Member**

### `DELETE /v1/assets/:id`
Soft-delete asset. **Auth: Required, Owner/Admin**

### `POST /v1/assets/:id/documents`
Upload document for asset (multipart/form-data). **Auth: Required**
```
Content-Type: multipart/form-data
Fields: file (binary), document_type (receipt|manual|warranty_card|photo|invoice|other)
```

### `GET /v1/assets/:id/warranties`
Get all warranties for an asset. **Auth: Required**

### `GET /v1/assets/:id/maintenance`
Get maintenance history and upcoming reminders for an asset. **Auth: Required**

---

## 5. Maintenance (8 endpoints)

### `GET /v1/households/:hid/maintenance/reminders`
Get all maintenance reminders for a household. **Auth: Required**
```
?status=overdue,upcoming&asset_id=uuid&priority=high
```

### `GET /v1/households/:hid/maintenance/summary`
Get maintenance dashboard summary. **Auth: Required**
```json
// Response 200
{
  "success": true,
  "data": {
    "overdue_count": 3,
    "upcoming_count": 8,
    "completed_count": 15,
    "snoozed_count": 2,
    "home_health_score": 78,
    "category_scores": {
      "appliances": { "health": 82, "risk": 18, "asset_count": 3 },
      "electronics": { "health": 75, "risk": 25, "asset_count": 2 },
      "home_systems": { "health": 70, "risk": 30, "asset_count": 1 }
    }
  }
}
```

### `PUT /v1/maintenance/reminders/:id/complete`
Mark a reminder as completed. **Auth: Required**
```json
// Request
{
  "notes": "Cleaned coils thoroughly",
  "evidence_url": "https://cdn.homeiq.com/evidence/uuid.jpg"  // Optional photo
}

// Response 200 — also triggers: create next reminder, recompute health score
```

### `PUT /v1/maintenance/reminders/:id/snooze`
Snooze a reminder. **Auth: Required**
```json
// Request
{
  "snooze_days": 7
}
```

### `PUT /v1/maintenance/reminders/:id/skip`
Skip a reminder. **Auth: Required**
```json
// Request
{
  "reason": "not_needed"                  // "dont_know_how", "not_needed", "will_do_later"
}
```

### `GET /v1/assets/:id/maintenance/records`
Get maintenance history for an asset. **Auth: Required**

### `GET /v1/assets/:id/health`
Get current health score and recommendation. **Auth: Required**

### `POST /v1/assets/:id/health/recompute`
Force recompute health score. **Auth: Required, Owner/Admin**

---

## 6. Claims (5 endpoints)

### `GET /v1/claims`
List user's claims. **Auth: Required**
```
?status=active&type=repair&household_id=uuid&page=1&pageSize=20
```
- `status=active` → submitted, under_review, approved, in_progress
- `status=resolved` → resolved, closed
- `status=denied` → denied

### `POST /v1/claims`
File a new claim. **Auth: Required**
```json
// Request
{
  "asset_id": "uuid",
  "claim_type": "repair",                // "repair", "replacement", "maintenance"
  "title": "Refrigerator not cooling",
  "description": "The fridge stopped cooling yesterday. Food is getting warm.",
  "issue_category": "Cooling Issue",
  "linked_booking_id": "HQ2026-0223-0001"  // Optional: if claim is from a booking
}

// Response 201
{
  "success": true,
  "data": {
    "id": "uuid",
    "claim_number": "CLM-2026-0001",
    "status": "submitted",
    "is_covered": true,                    // Auto-checked against warranty/plan
    "plan_name": "Premium",
    "deductible": 50.00,
    "submitted_at": "2026-02-23T10:00:00Z"
  }
}
// Backend also: creates claim_status_history entry, sends notification
```

### `GET /v1/claims/:id`
Get claim details with full status history. **Auth: Required**

### `GET /v1/claims/:id/history`
Get claim status transition history. **Auth: Required**

### `POST /v1/claims/:id/documents`
Upload claim supporting documents. **Auth: Required**

---

## 7. Service Bookings (7 endpoints)

### `GET /v1/bookings`
List user's bookings. **Auth: Required**
```
?status=pending,confirmed,in_progress&household_id=uuid&category=assembly
```

### `POST /v1/bookings`
Create a service booking. **Auth: Required**
```json
// Request (Assembly example)
{
  "household_id": "uuid",
  "category_slug": "assembly",
  "service_type": "assembly",
  "service_name": "Furniture Assembly",
  "service_details": {
    "items": { "Bookshelf": 2, "Desk": 1 },
    "addons": ["Wall Anchoring", "Packaging Disposal"],
    "property_type": "house"
  },
  "scheduled_date": "2026-03-01",
  "scheduled_time_slot": "9 AM - 12 PM",
  "date_selection_type": "custom",
  "contact_name": "John Doe",
  "contact_email": "john@example.com",
  "contact_phone": "+12125551234",
  "service_address": {
    "line1": "123 Main St",
    "city": "New York",
    "state": "NY",
    "zip": "10001",
    "apartment": "2B"
  },
  "payment_mode": "pay_now",
  "special_requirements": "Please ring doorbell",
  "terms_accepted": true
}

// Request (Lifestyle — Cab example)
{
  "household_id": "uuid",
  "category_slug": "lifestyle",
  "service_type": "lifestyle",
  "service_name": "Cab Booking",
  "service_details": {
    "selected_service": "Cab",
    "pickup_location": "123 Main St, New York",
    "drop_location": "JFK Airport",
    "vehicle_type": "SUV",
    "estimated_fare": 65.00,
    "estimated_distance": 18.5
  },
  "scheduled_date": "2026-03-01",
  "scheduled_time_slot": "6:00 AM",
  ...
}

// Response 201
{
  "success": true,
  "data": {
    "id": "uuid",
    "booking_number": "HQ2026-0301-0001",
    "status": "pending",
    "items_total": 125.00,
    "service_fee": 55.00,
    "tax_amount": 14.40,
    "total_amount": 194.40,
    "scheduled_date": "2026-03-01",
    "scheduled_time_slot": "9 AM - 12 PM"
  }
}
```

### `GET /v1/bookings/:id`
Get booking details with provider info and status history. **Auth: Required**

### `PUT /v1/bookings/:id/cancel`
Cancel a booking. **Auth: Required**
```json
// Request
{
  "reason": "Schedule conflict"
}
```

### `PUT /v1/bookings/:id/reschedule`
Reschedule a booking. **Auth: Required**
```json
// Request
{
  "new_date": "2026-03-05",
  "new_time_slot": "2 PM - 5 PM"
}
```

### `GET /v1/bookings/active`
Get active/upcoming bookings. **Auth: Required**
```
?household_id=uuid
```

### `GET /v1/bookings/history`
Get completed/past bookings. **Auth: Required**

---

## 8. Orders (4 endpoints)

### `GET /v1/orders`
List user's orders. **Auth: Required**
```
?type=purchase,upgrade_trade_in&status=placed,shipped&household_id=uuid
```

### `POST /v1/orders`
Place an order. **Auth: Required**
```json
// Request (Upgrade with trade-in)
{
  "household_id": "uuid",
  "order_type": "upgrade_trade_in",
  "items": [
    {
      "product_id": "uuid",
      "quantity": 1,
      "price": 1499.99
    }
  ],
  "trade_in": {
    "old_asset_id": "uuid",
    "estimated_value": 200.00,
    "condition": "good"
  },
  "shipping_address": {
    "line1": "123 Main St",
    "city": "New York",
    "state": "NY",
    "zip": "10001"
  },
  "payment_method_id": "uuid",
  "requires_installation": true,
  "installment_plan": {                    // Optional
    "num_installments": 12,
    "interest_rate": 0
  }
}

// Response 201
{
  "success": true,
  "data": {
    "id": "uuid",
    "order_number": "HQ-ORD-2026-0001",
    "status": "placed",
    "subtotal": 1499.99,
    "trade_in_credit": -200.00,
    "tax_amount": 103.99,
    "shipping_cost": 0.00,
    "total_amount": 1403.98,
    "estimated_delivery": "2026-03-10",
    "payment_status": "succeeded"
  }
}
```

### `GET /v1/orders/:id`
Get order details with tracking and timeline. **Auth: Required**

### `PUT /v1/orders/:id/cancel`
Cancel an order (if status allows). **Auth: Required**

---

## 9. Products (4 endpoints)

### `GET /v1/products`
Search/browse products. **Auth: Optional (for personalization)**
```
?subcategory_id=uuid&brand=Samsung&min_price=500&max_price=2000&energy_star=true&smart=true&search=french+door&sortBy=rating&sortOrder=desc&page=1&pageSize=20
```

### `GET /v1/products/:id`
Get product details. **Auth: Optional**

### `GET /v1/products/categories`
Get product categories and subcategories. **Auth: Not required**

### `GET /v1/products/featured`
Get featured/popular products. **Auth: Not required**

---

## 10. Protection Plans (5 endpoints)

### `GET /v1/plans`
Get available protection plan templates. **Auth: Not required**

### `GET /v1/plans/:id`
Get plan template details (coverage, pricing, deductibles). **Auth: Not required**

### `POST /v1/assets/:id/plans`
Purchase a protection plan for an asset. **Auth: Required**
```json
// Request
{
  "plan_template_id": "uuid",
  "billing_type": "monthly",             // "monthly", "yearly", "one_time"
  "deductible_amount": 50.00,
  "payment_method_id": "uuid"
}

// Response 201
{
  "success": true,
  "data": {
    "id": "uuid",
    "plan_name": "Premium",
    "billing_type": "monthly",
    "price": 14.99,
    "deductible": 50.00,
    "coverage_start": "2026-02-23",
    "coverage_end": "2027-02-23",
    "is_active": true,
    "stripe_subscription_id": "sub_xxx"
  }
}
```

### `GET /v1/users/me/plans`
Get all active protection plans for current user. **Auth: Required**

### `DELETE /v1/plans/:id/cancel`
Cancel a protection plan. **Auth: Required**

---

## 11. Payments (6 endpoints)

### `GET /v1/payment-methods`
List saved payment methods. **Auth: Required**

### `POST /v1/payment-methods`
Add a new payment method (via Stripe). **Auth: Required**
```json
// Request
{
  "stripe_payment_method_id": "pm_xxx",   // Created by Stripe.js on client
  "is_default": true
}
```

### `DELETE /v1/payment-methods/:id`
Remove a payment method. **Auth: Required**

### `PUT /v1/payment-methods/:id/default`
Set as default payment method. **Auth: Required**

### `POST /v1/payments/create-intent`
Create a Stripe payment intent. **Auth: Required**
```json
// Request
{
  "amount": 194.40,
  "currency": "USD",
  "payment_method_id": "uuid",
  "metadata": {
    "type": "booking",
    "booking_id": "uuid"
  }
}

// Response 200
{
  "success": true,
  "data": {
    "client_secret": "pi_xxx_secret_xxx",  // For Stripe.js confirmation
    "payment_intent_id": "pi_xxx"
  }
}
```

### `POST /v1/webhooks/stripe`
Stripe webhook handler. **Auth: Stripe signature verification**
Handles: `payment_intent.succeeded`, `payment_intent.failed`, `invoice.paid`, `customer.subscription.updated`, `customer.subscription.deleted`

---

## 12. Notifications (4 endpoints)

### `GET /v1/notifications`
List notifications. **Auth: Required**
```
?type=maintenance_due,booking_confirmed&unread_only=true&page=1&pageSize=20
```

### `PUT /v1/notifications/:id/read`
Mark notification as read. **Auth: Required**

### `PUT /v1/notifications/read-all`
Mark all notifications as read. **Auth: Required**

### `GET /v1/notifications/unread-count`
Get unread notification count. **Auth: Required**
```json
// Response 200
{
  "success": true,
  "data": { "count": 5 }
}
```

---

## 13. Alerts (3 endpoints)

### `GET /v1/households/:hid/alerts`
Get critical alerts for a household. **Auth: Required**
```
?severity=critical,warning&category=warranty,maintenance&dismissed=false
```

### `PUT /v1/alerts/:id/dismiss`
Dismiss an alert. **Auth: Required**

### `GET /v1/alerts/summary`
Get alert counts across all user's households. **Auth: Required**

---

## 14. AI Services (5 endpoints)

### `POST /v1/ai/brand-lookup`
Get brand list for an asset type. **Auth: Required**
```json
// Request
{
  "asset_type": "Refrigerator"
}

// Response 200 (cached in Redis 24h)
{
  "success": true,
  "data": {
    "brands": ["Samsung", "LG", "Whirlpool", "GE", "Frigidaire", "Bosch", "KitchenAid", "Maytag", "Kenmore", "Sub-Zero"],
    "cached": true
  }
}
```

### `POST /v1/ai/subcategory-lookup`
Get subcategories for an asset type. **Auth: Required**
```json
// Request
{
  "asset_type": "Refrigerator"
}

// Response 200
{
  "success": true,
  "data": {
    "subcategories": ["French Door", "Side-by-Side", "Top Freezer", "Bottom Freezer", "Mini Fridge", "Wine Cooler"],
    "cached": true
  }
}
```

### `POST /v1/ai/nameplate-guide`
Generate nameplate location wireframe. **Auth: Required**
```json
// Request
{
  "asset_type": "Refrigerator",
  "brand": "Samsung",
  "model": "RT-5000"
}

// Response 200
{
  "success": true,
  "data": {
    "image_url": "https://cdn.homeiq.com/ai/wireframes/uuid.png",
    "label_locations": [
      { "location": "Inside the door, on the left wall", "confidence": "high" },
      { "location": "Back panel, lower left corner", "confidence": "medium" }
    ]
  }
}
```

### `POST /v1/ai/analyze-issue`
AI issue analysis. **Auth: Required**
```json
// Request
{
  "asset_type": "Refrigerator",
  "brand": "Samsung",
  "model": "RT-5000",
  "selected_issue": "Not cooling properly"
}

// Response 200
{
  "success": true,
  "data": {
    "diagnosis": "The most likely cause is a dirty condenser coil or a failing compressor.",
    "severity": "medium",
    "requires_professional": false,
    "possible_causes": [
      "Dirty condenser coils",
      "Faulty thermostat",
      "Failing compressor",
      "Blocked air vents"
    ],
    "quick_checks": [
      "Check if the condenser coils are dusty",
      "Verify the thermostat setting",
      "Listen for unusual compressor sounds"
    ],
    "estimated_cost": {
      "diy": "$20-$50",
      "professional": "$150-$400"
    }
  }
}
```

### `POST /v1/ai/diy-steps`
Generate DIY troubleshooting/maintenance steps. **Auth: Required**
```json
// Request
{
  "asset_type": "Refrigerator",
  "brand": "Samsung",
  "model": "RT-5000",
  "task_name": "Clean Condenser Coils"
}

// Response 200
{
  "success": true,
  "data": {
    "steps": [
      {
        "step_number": 1,
        "title": "Unplug the Refrigerator",
        "description": "Pull the refrigerator away from the wall and unplug it.",
        "instructions": "Ensure the fridge is completely disconnected from power before proceeding.",
        "safety_note": "Always unplug before working on any appliance.",
        "tools_needed": ["None"],
        "duration": "2 minutes",
        "risk_level": "low"
      },
      ...
    ],
    "all_tools_needed": ["Vacuum with brush attachment", "Coil cleaning brush", "Flashlight"],
    "estimated_time": "30 minutes",
    "difficulty_level": "Easy",
    "safety_warnings": ["Always unplug before cleaning", "Wear gloves when handling sharp fins"]
  }
}
```

---

## 15. File Uploads

### `POST /v1/uploads`
Upload a file to S3. **Auth: Required**
```
Content-Type: multipart/form-data
Fields:
  - file: (binary, max 10MB)
  - type: "asset_photo" | "document" | "evidence" | "avatar" | "claim_photo"
  - related_id: "uuid" (optional — asset_id, claim_id, etc.)
```
```json
// Response 201
{
  "success": true,
  "data": {
    "url": "https://cdn.homeiq.com/uploads/uuid/filename.jpg",
    "file_name": "filename.jpg",
    "file_size": 1234567,
    "mime_type": "image/jpeg"
  }
}
```

### `GET /v1/uploads/presigned-url`
Get a presigned upload URL (for large files or direct-to-S3). **Auth: Required**
```
?file_name=receipt.pdf&content_type=application/pdf&type=document
```

---

## Rate Limits

| Endpoint Group | Limit | Window |
|---------------|-------|--------|
| Auth (signup, signin, OTP) | 5 requests | 1 minute |
| AI endpoints | 10 requests | 1 hour |
| File uploads | 20 requests | 1 hour |
| General API (authenticated) | 200 requests | 1 minute |
| General API (unauthenticated) | 30 requests | 1 minute |

Rate limit headers returned on every response:
```
X-RateLimit-Limit: 200
X-RateLimit-Remaining: 195
X-RateLimit-Reset: 1708732860
```
