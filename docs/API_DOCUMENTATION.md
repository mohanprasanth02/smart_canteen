# Smart Canteen Management System - API Documentation

All request and response objects are formatted as JSON. Bearer tokens must be attached inside requests under the `Authorization` header.

---

## 🔐 Authentication APIs

### 1. Student Registration
* **Endpoint**: `POST /api/auth/register`
* **Body**:
  ```json
  {
    "full_name": "Test Student",
    "register_number": "REG001",
    "department": "Computer Science",
    "year": 3,
    "mobile_number": "9876543210",
    "email": "student@test.com",
    "password": "student123"
  }
  ```
* **Response (201 Created)**:
  ```json
  {
    "message": "Registration successful",
    "user": { "id": 1, "email": "student@test.com", "full_name": "Test Student" },
    "access_token": "ey...",
    "refresh_token": "ey..."
  }
  ```

### 2. Login
* **Endpoint**: `POST /api/auth/login` (Admin: `POST /api/auth/admin/login`)
* **Body**:
  ```json
  {
    "email": "student@test.com",
    "password": "student123"
  }
  ```

---

## 🍔 Menu APIs

### 1. Retrieve Categories
* **Endpoint**: `GET /api/menu/categories`
* **Response (200 OK)**:
  ```json
  {
    "categories": [
      { "id": 1, "name": "Breakfast", "display_order": 1 }
    ]
  }
  ```

### 2. Retrieve Food Catalog
* **Endpoint**: `GET /api/menu/food-items`
* **Query Params**: `category_id` (int), `is_veg` (bool)
* **Response (200 OK)**:
  ```json
  {
    "items": [
      { "id": 1, "name": "Dosa", "price": 40.0, "quantity": 30, "is_available": true }
    ]
  }
  ```

---

## 🛒 Cart & Order APIs

### 1. Add Item to Cart
* **Endpoint**: `POST /api/cart/items`
* **Body**: `{"food_item_id": 1, "quantity": 2}`

### 2. Place Order
* **Endpoint**: `POST /api/orders`
* **Body**:
  ```json
  {
    "pickup_time": "Immediate (10-15 mins)",
    "notes": "Make it spicy",
    "payment_method": "cash"
  }
  ```
* **Response (201 Created)**:
  ```json
  {
    "message": "Order placed successfully",
    "order": {
      "order_id": "ORD-2026-000001",
      "status": "placed",
      "total_amount": 135.0,
      "token": { "token_number": "TKN-451", "qr_data": "..." }
    }
  }
  ```

---

## 🛠️ Canteen Staff Admin APIs

### 1. Verify Collection QR
* **Endpoint**: `POST /api/admin/verify-qr`
* **Body**: `{"qr_data": "..."}`
* **Response (200 OK)**:
  ```json
  {
    "message": "Order verified and marked as collected",
    "order": { "order_id": "ORD-2026-000001", "status": "completed" }
  }
  ```
