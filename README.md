# Smart Canteen Management System

A production-ready, real-time college canteen ordering application built using **Flutter (Riverpod)** and a local **Flask (Socket.IO)** backend server.

---

## ✨ Features

### 🧑‍🎓 Student Application
* **Real-time Menu Catalog**: Synced automatically with canteen stock. Unavailable or sold-out items are updated instantly using WebSockets.
* **Smart Cart System**: Add/remove items with quantity multipliers and GST calculations.
* **Order Tracking Pipeline**: Displays step progression (Placed → Accepted → Preparing → Ready → Completed) with real-time websocket sync.
* **Collection QR Code**: Cryptographically signed token (HMAC-SHA256) displaying unique collection tokens.
* **Profile Settings**: Easily configure host local IP address to run and test over college Wi-Fi.

### 🧑‍🍳 Canteen Staff / Admin Panel
* **Live Statistics**: Real-time revenue trackers, active order lists, active online users, and low-stock inventory alerts.
* **Order Management Dashboard**: Accept, prepare, ready, or reject incoming orders dynamically.
* **Menu CRUD Manager**: Create, read, update, or delete food items, edit price margins, update stock counts, and upload images.
* **QR Verification Scanner**: Read and decrypt student collection tokens via device camera, preventing double collections and counterfeits.
* **Raw Material Inventory**: Set low stock reorder thresholds with real-time alarms.
* **Sales Analytics**: fl_chart curves tracking peak traffic hours and sales trends.

---

## 🛠️ Tech Stack
* **Frontend Mobile App**: Flutter (with GoRouter, Material 3, Riverpod)
* **Backend API Server**: Python Flask (Flask-SocketIO, eventlet, python-dotenv)
* **Database Model**: SQLite (defaults) / PostgreSQL (production-ready) with SQLAlchemy ORM and Alembic Migrations

---

## 🚀 Quick Start Instructions
Please refer to the following documentation to set up and run:

1. 💻 **[Setup Guide](docs/SETUP_GUIDE.md)**: Steps to download packages, seed databases, and run servers/clients.
2. 🗺️ **[Database Relational Schema](docs/DATABASE_SCHEMA.md)**: Tables diagram (Mermaid) and definitions.
3. 🔐 **[API Endpoints Reference](docs/API_DOCUMENTATION.md)**: Authentication, menu, cart, checkout, and admin endpoints.
