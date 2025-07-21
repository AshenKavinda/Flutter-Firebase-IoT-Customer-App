# Firebase Realtime Database Structure for Customer App

This document outlines the data structure for the converted customer app using Firebase Realtime Database.

## Database Structure

### Units Collection
```json
{
  "units": {
    "unit1_key": {
      "location": {
        "latitude": 6.927079,
        "longitude": 79.861243
      },
      "lockers": [
        {
          "id": "6115475X",
          "status": "available",
          "locked": false,
          "confirmation": false,
          "price": 100,
          "reserved": false,
          "timestamp": "2025-01-15T10:30:00.000Z"
        },
        {
          "id": "6115476Y",
          "status": "reserved",
          "locked": true,
          "confirmation": true,
          "price": 150,
          "reserved": true,
          "timestamp": "2025-01-15T11:15:00.000Z"
        }
      ],
      "status": "available",
      "deleted": false,
      "timestamp": "2025-01-15T09:00:00.000Z"
    },
    "unit2_key": {
      "location": {
        "latitude": 6.928079,
        "longitude": 79.862243
      },
      "lockers": [
        {
          "id": "7225577A",
          "status": "available",
          "locked": false,
          "confirmation": false,
          "price": 120,
          "reserved": false,
          "timestamp": "2025-01-15T10:45:00.000Z"
        }
      ],
      "status": "available",
      "deleted": false,
      "timestamp": "2025-01-15T09:15:00.000Z"
    }
  }
}
```

### Reservations Collection
```json
{
  "reservations": {
    "reservation1_key": {
      "timestamp": "2025-01-15T10:30:00.000Z",
      "userID": "user123",
      "lockerID": "6115475X",
      "active": true
    },
    "reservation2_key": {
      "timestamp": "2025-01-15T11:15:00.000Z",
      "userID": "user456",
      "lockerID": "6115476Y",
      "active": false
    }
  }
}
```

### Payment Collection
```json
{
  "payment": {
    "payment1_key": {
      "reservationDocId": "reservation1_key",
      "total": 200,
      "userId": "user123",
      "lokerId": "6115475X",
      "timestamp": "2025-01-15T12:30:00.000Z"
    }
  }
}
```

## Key Changes Made

### 1. Dependencies Updated
- Removed `cloud_firestore` dependency
- Added `firebase_database` dependency

### 2. Database Service (`lib/sevices/database.dart`)
- Changed from Firestore collections to Realtime Database references
- Updated all query methods to work with DataSnapshot instead of DocumentSnapshot
- Modified timestamp handling to use ISO string format
- Updated array/list operations for Realtime Database structure

### 3. Payment Service (`lib/sevices/payment_service.dart`)
- Updated to use Firebase Realtime Database references
- Changed timestamp format to ISO string

### 4. UI Pages Updated
- `ViewUnitsPage.dart`: Updated data parsing for DataSnapshot
- `unitDetailsPage.dart`: Updated FutureBuilder type and data access
- `MakeReservation.dart`: Updated data parsing for unit documents
- `MyReservationPage.dart`: Updated reservation data parsing
- `BillingPage.dart`: Updated reservation lookup and timestamp handling
- `PaymentPage.dart`: Updated database reference calls

### 5. Data Structure Changes
- **Timestamps**: All timestamps are now stored as ISO 8601 strings instead of Firestore Timestamp objects
- **Document IDs**: Using Firebase Realtime Database push keys instead of Firestore document IDs
- **Queries**: All filtering is now done client-side since Realtime Database has limited query capabilities
- **Updates**: Using `update()` method with specific paths instead of Firestore document updates

## Setup Instructions

1. **Install Dependencies**: Run `flutter pub get` (already done)

2. **Firebase Realtime Database Rules**: Update your Firebase project to include Realtime Database with appropriate security rules:
```json
{
  "rules": {
    ".read": "auth != null",
    ".write": "auth != null"
  }
}
```

3. **Data Migration**: If you have existing Firestore data, you'll need to migrate it to the new Realtime Database structure

4. **Testing**: Test all functionalities:
   - View units on map
   - Make reservations
   - View active reservations
   - Process payments
   - Unlock lockers

## Important Notes

- All timestamp operations now use DateTime.toIso8601String() and DateTime.tryParse()
- Document references are now handled using DataSnapshot.key instead of DocumentSnapshot.id
- Query filtering is done in Dart code since Realtime Database has limited query capabilities
- The data structure maintains the same logical organization but uses Realtime Database's key-value format
