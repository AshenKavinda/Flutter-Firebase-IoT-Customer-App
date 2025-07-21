# Firebase Realtime Database Setup Guide

## Prerequisites
1. Firebase project with Authentication enabled
2. Firebase Realtime Database enabled in your Firebase project

## Setup Steps

### 1. Enable Firebase Realtime Database
1. Go to your Firebase Console
2. Navigate to "Realtime Database"
3. Click "Create Database"
4. Choose "Start in test mode" (you can update rules later)

### 2. Update Database Rules
Replace the default rules with:
```json
{
  "rules": {
    ".read": "auth != null",
    ".write": "auth != null",
    "units": {
      ".indexOn": ["deleted", "status"]
    },
    "reservations": {
      ".indexOn": ["userID", "active"]
    }
  }
}
```

### 3. Sample Data Structure
Import this sample data to test the app:

```json
{
  "units": {
    "unit001": {
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
          "timestamp": "2025-01-21T10:30:00.000Z"
        },
        {
          "id": "6115476Y", 
          "status": "available",
          "locked": false,
          "confirmation": false,
          "price": 150,
          "reserved": false,
          "timestamp": "2025-01-21T10:35:00.000Z"
        }
      ],
      "status": "available",
      "deleted": false,
      "timestamp": "2025-01-21T09:00:00.000Z"
    },
    "unit002": {
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
          "timestamp": "2025-01-21T10:45:00.000Z"
        }
      ],
      "status": "available",
      "deleted": false,
      "timestamp": "2025-01-21T09:15:00.000Z"
    }
  },
  "reservations": {},
  "payment": {}
}
```

### 4. Running the App
1. Ensure all dependencies are installed: `flutter pub get`
2. Run the app: `flutter run`

### 5. Testing Checklist
- [ ] User can see units on the map
- [ ] User can view unit details
- [ ] User can make a reservation with a locker ID
- [ ] User can view active reservations
- [ ] User can process payments
- [ ] Database updates correctly

## Migration from Firestore
If you have existing Firestore data, you'll need to:
1. Export your Firestore data
2. Transform the data structure to match the new format
3. Import to Realtime Database
4. Update timestamps to ISO 8601 format
5. Test all functionality

## Key Differences
- **Collections** → **References**: Firestore collections become Realtime Database references
- **Documents** → **Objects**: Firestore documents become JSON objects with keys
- **Timestamps**: Stored as ISO 8601 strings instead of Firestore Timestamp objects
- **Queries**: Limited server-side filtering; most filtering done client-side
- **Updates**: Use `update()` with specific paths instead of document updates
