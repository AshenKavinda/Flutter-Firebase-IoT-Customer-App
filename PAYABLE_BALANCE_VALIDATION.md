# Payable Balance Validation for Reservations

## Overview
Added payable balance validation to prevent users from making new reservations when they have outstanding balances.

## Changes Made

### 1. Unit Details Page (`lib/pages/unitDetailsPage.dart`)

#### Added Methods:
- `_checkUserPayableBalance()` - Checks user's current payable balance
- `_showPayableBalanceDialog(int balance)` - Shows dialog when user has outstanding balance

#### Modified Methods:
- `_reserveLocker(String lockerId)` - Added payable balance validation

#### Validation Flow:
1. Check if user has PIN (existing)
2. **NEW:** Check if user has payable balance > 0
3. If balance exists, show payment dialog and prevent reservation
4. Otherwise, proceed with normal reservation flow

### 2. Make Reservation Page (`lib/pages/MakeReservation.dart`)

#### Added Methods:
- `_checkUserPayableBalance()` - Checks user's current payable balance  
- `_showPayableBalanceDialog(int balance)` - Shows dialog when user has outstanding balance

#### Modified Methods:
- `_onNextPressed()` - Added payable balance validation

#### Validation Flow:
1. Check if user has PIN (existing)
2. **NEW:** Check if user has payable balance > 0
3. If balance exists, show payment dialog and prevent reservation
4. Otherwise, proceed with locker ID validation and reservation

## UI Features

### Payable Balance Dialog
- **Icon:** Wallet icon with red color theme
- **Title:** "Outstanding Balance"
- **Content:** Shows exact balance amount and explains payment requirement
- **Actions:**
  - "Cancel" - Dismisses dialog
  - "Pay Now" - Navigates to Profile page for payment

### Visual Design
- Red color scheme to indicate urgency
- Clear messaging about payment requirement
- Consistent with existing PIN validation dialog design

## Technical Implementation

### Database Integration
- Uses existing `DatabaseService.getUserPayableBalance()` method
- Handles errors gracefully with fallback to 0 balance
- No additional database calls or structure changes

### Error Handling
- Try-catch blocks around database calls
- Prints errors to console for debugging
- Returns 0 balance on any error to prevent blocking

### State Management
- Sets loading state appropriately
- Resets loading state when showing dialogs
- Prevents multiple simultaneous operations

## Behavior

### When User Has Payable Balance:
1. User tries to make reservation
2. System checks PIN (existing validation)
3. System checks payable balance (new validation)
4. If balance > 0, shows payment dialog
5. User can either cancel or go to profile to pay
6. Reservation process is blocked until payment is made

### When User Has No Payable Balance:
1. System proceeds with normal validation flow
2. No additional delays or UI changes
3. Existing functionality remains unchanged

## Integration Points

### Works With:
- Existing PIN validation system
- Profile page payment functionality
- PaymentPage for balance payments
- DatabaseService payable balance methods

### Compatible With:
- Both unit-based and QR code-based reservation flows
- Existing error handling and loading states
- Current navigation patterns

## Testing

### Test Scenarios:
1. **User with payable balance tries to reserve:**
   - Should see payable balance dialog
   - Should be redirected to profile when clicking "Pay Now"
   - Should be able to cancel and return

2. **User without payable balance tries to reserve:**
   - Should proceed normally (no additional dialogs)
   - Existing PIN validation should still work
   - Reservation flow should be unchanged

3. **Error handling:**
   - Network errors should not block reservations
   - Database errors should fallback gracefully

### Setup Test Data:
```json
{
  "users": {
    "TEST_USER_ID": {
      "pin": "1234",
      "payable": 500
    }
  }
}
```

## Files Modified:
1. `lib/pages/unitDetailsPage.dart` - Added validation to `_reserveLocker` method
2. `lib/pages/MakeReservation.dart` - Added validation to `_onNextPressed` method

## Notes:
- Validation occurs early in the reservation process to prevent unnecessary operations
- Uses consistent UI patterns with existing PIN validation
- Maintains backward compatibility with existing code
- No breaking changes to existing functionality
