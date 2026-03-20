# PaluwaganPro

A modern Flutter application for managing digital paluwagan (rotating savings and credit associations) groups. Bring the traditional Filipino savings system into the digital age with transparent tracking, secure payments, and community management.

## Features
- **User Authentication**: Secure sign-up and login with password validation
- **Group Management**: Create and join paluwagan groups with unique join codes
- **Payment System**: GCash integration with payment proof uploads and verification
- **Real-time Tracking**: Monitor contributions, payouts, and rotation schedules
- **Group Chat**: Communicate with members within each group
- **Notifications**: Get alerts for payments, verifications, and group updates
- **Profile Management**: Update personal info and GCash details

## Tech Stack
- **Flutter** (Frontend)
- **SQLite** (Local database with sqflite)
- **Supabase** (Cloud database & Authentication)
- **Provider** (State management)
- **Image Picker** (Photo uploads)

## Getting Started

### Prerequisites
- Flutter SDK (latest stable)
- Dart SDK

### Installation
1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to start the application

## Database Schema
The app uses a hybrid database approach (SQLite + Supabase) with tables for users, groups, members, contributions, transactions, chat messages, notifications, payment proofs, and round rotations. Database migrations are handled automatically.
