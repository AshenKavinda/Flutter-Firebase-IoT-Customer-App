# Type Casting Fix for Firebase Realtime Database

## Issue Resolved
**Error**: `type '_Map<Object?, Object?>' is not a subtype of type 'Map<String, dynamic>'`

This error occurred because Firebase Realtime Database returns data as `Map<Object?, Object?>` but we were trying to cast it directly to `Map<String, dynamic>`.

## Root Cause
When using Firebase Realtime Database, the `DataSnapshot.value` returns data with type `Object?`, which internally is `Map<Object?, Object?>` for JSON objects. Direct casting to `Map<String, dynamic>` fails because of Dart's strict type system.

## Solution Applied

### 1. Updated Database Service (`lib/sevices/database.dart`)
**Before**:
```dart
final data = child.value as Map<dynamic, dynamic>?;
final lockers = List<Map<dynamic, dynamic>>.from(data['lockers']);
```

**After**:
```dart
final data = child.value as Map<Object?, Object?>?;
final lockersData = data['lockers'] as List<dynamic>;
final lockers = lockersData.map((e) => Map<String, dynamic>.from(e as Map<Object?, Object?>)).toList();
```

### 2. Updated MakeReservation Page (`lib/pages/MakeReservation.dart`)
**Before**:
```dart
final data = Map<String, dynamic>.from(doc.value as Map);
final lockers = List<Map<String, dynamic>>.from(data['lockers']);
```

**After**:
```dart
final data = Map<String, dynamic>.from(doc.value as Map<Object?, Object?>);
final lockersData = data['lockers'] as List<dynamic>?;
if (lockersData != null) {
  final lockers = lockersData.map((e) => Map<String, dynamic>.from(e as Map<Object?, Object?>)).toList();
  // ... rest of the logic
}
```

### 3. Updated All Other Pages
Applied similar type casting fixes to:
- `ViewUnitsPage.dart`
- `unitDetailsPage.dart` 
- `MyReservationPage.dart`
- `BillingPage.dart`

## Key Changes Made

### Type Casting Pattern
```dart
// Step 1: Cast to Map<Object?, Object?>
final data = Map<String, dynamic>.from(snapshot.value as Map<Object?, Object?>);

// Step 2: Handle nested objects
final location = Map<String, dynamic>.from(data['location'] as Map<Object?, Object?>);

// Step 3: Handle arrays of objects
final lockersData = data['lockers'] as List<dynamic>;
final lockers = lockersData.map((e) => Map<String, dynamic>.from(e as Map<Object?, Object?>)).toList();
```

### Safe Handling
- Added null checks for nested data
- Used safe casting with proper type annotations
- Maintained data integrity while converting types

## Testing Data Structure Support
The app now correctly handles the provided Firebase Realtime Database structure:

```json
{
  "units": {
    "-OVf-SRrHoMazIbJ5qdy": {
      "deleted": false,
      "location": {
        "latitude": 6.065305,
        "longitude": 80.202617
      },
      "lockers": [
        {
          "confirmation": false,
          "id": "6gmuiwXb",
          "locked": false,
          "price": 100,
          "reserved": false,
          "status": "available",
          "timestamp": "2025-07-21T09:13:53.063073"
        }
      ]
    }
  }
}
```

## Result
✅ **Fixed**: Type casting errors resolved
✅ **Tested**: App compiles without errors
✅ **Compatible**: Works with your Firebase Realtime Database structure
✅ **Safe**: Proper null checking and type validation

The app should now work correctly with your Firebase Realtime Database without the type casting errors!
