Project Architecture Guide

This document explains the folder structure and architecture used in this Flutter project. The goal is to maintain a scalable, modular, and maintainable codebase.
Root Structure
lib/
│
├── config/
├── features/
├── services/
├── api_services/


Config Folder (lib/config)

This folder contains all application-level configurations and reusable constants.

config/
│
├── app_assets/        → Image paths, icons, etc.
├── app_colors/        → Color constants
├── app_constants/     → Static values used across app
├── app_endpoints/     → API endpoint URLs
├── app_layout/        → Responsive layout helpers
├── app_routes/        → Route management
├── app_sharedpref/    → SharedPreferences handling
├── app_style/         → Text styles, themes
├── app_widget/        → Common reusable widgets

Features Folder (lib/features)

This folder follows feature-based architecture.

features/
│
├── auth/
├── main/
├── utils/

Auth Module (features/auth)

Used for authentication-related screens.

Each feature MUST follow this structure:

auth/
│
├── splash/
│   ├── views/        → UI screens
│   ├── controller/   → GetX controllers
│   ├── binding/      → Dependency injection
│   ├── model/        → (Optional) Data models
│   ├── widget/       → (Optional) Local widgets

👉 Note:

views, controller, binding are mandatory
model, widget are optional (create only if needed)

Utils Module (features/utils)

Contains common reusable UI components

utils/
│
├── custom_button/
├── snackbar/
├── alertbox/
├── card/


API Services (lib/api_services)

Handles all API-related logic.

api_services/
│
├── network_service/     → Common API handling (GET, POST, headers, etc.)
├── auth_api/            → Auth-related APIs
├── home_api/            → Feature-specific API integrations

Services (lib/services)

Contains external or background services

services/
│
├── firebase_service/
├── notification_service/



