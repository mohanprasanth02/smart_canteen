# Smart Canteen Management System - Setup Guide

This guide describes how to configure and run the backend server and connect the mobile devices.

---

## 💻 Backend Server Setup

### 1. Requirements
Ensure you have the following installed on your host laptop:
* **Python 3.9+**
* **pip** (Python package installer)
* **PostgreSQL** (Optional - defaults to SQLite for quick setup)

### 2. Installation
1. Open PowerShell / Command Prompt and navigate to the backend folder:
   ```bash
   cd backend
   ```
2. Install Python dependencies:
   ```bash
   pip install -r requirements.txt
   ```
3. Initialize the environment:
   Make a copy of `.env.example` named `.env` (it comes pre-configured with default values for SQLite database):
   ```bash
   cp .env.example .env
   ```

### 3. Seed Sample Canteen Menu
Populate the database tables with default categories, 28 food menu items, 13 inventory items, admin credentials, and test students:
```bash
python seed_data.py
```

### 4. Start Server
Run the local network server:
```bash
python run.py
```
This starts the backend on port `5000` binded to all interfaces (`0.0.0.0`). Take note of the **Network IP** displayed on start (e.g. `http://192.168.1.15:5000`).

---

## 📱 Mobile App Setup (Flutter)

### 1. Requirements
* **Flutter SDK 3.x**
* **Android Studio** (Android development) or **Xcode** (iOS development)

### 2. Configure Host Server IP
Open the app, go to **Profile**, and enter your host laptop's Local IP address (e.g., `192.168.1.15`). 
Alternatively, update the default fallback variable directly inside code at:
[api_constants.dart](file:///e:/mini%20pro/smart_canteen/lib/core/constants/api_constants.dart#L5):
```dart
static String baseIp = '192.168.x.x'; // Your laptop Wi-Fi IP
```

### 3. Run Application
Run dependencies and compile:
```bash
cd smart_canteen
flutter pub get
flutter run
```

---

## 🧪 Quick Test Credentials

Once the database seeder has run, use the following credentials to login:

### Canteen Staff / Admin Portal
* **Username:** `admin`
* **Password:** `admin123`

### Student Application
* **Email:** `student@test.com`
* **Password:** `student123`
