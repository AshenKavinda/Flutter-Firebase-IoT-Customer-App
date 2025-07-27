# Payable Balance Feature Test

## Overview
This document outlines the new payable balance feature that has been implemented in the Customer App.

## Changes Made

### 1. Database Service Updates (`lib/sevices/database.dart`)
Added new methods to handle payable balance:
- `getUserPayableBalance(String userId)` - Gets the current payable balance for a user
- `setUserPayableBalance(String userId, int amount)` - Sets the payable balance
- `resetUserPayableBalance(String userId)` - Resets balance to 0

### 2. Profile Page Updates (`lib/pages/Profile.dart`)
- Added `_payableBalance` state variable
- Updated `_loadUserData()` to load both PIN and payable balance
- Added payable balance display section with:
  - Outstanding balance amount
  - Red-themed warning UI
  - "Pay Now" button that navigates to payment page
- Added `_navigateToPayment()` method

### 3. Payment Page Updates (`lib/pages/PaymentPage.dart`)
- Modified `_handlePayment()` to detect payable balance payments
- Added different logic for payable balance vs regular reservation payments
- Updated UI to show different icons and text for payable balance payments
- For payable balance payments:
  - Resets balance to 0 after successful payment
  - Shows appropriate success message
  - Returns to previous page instead of navigating to home

## How to Test

### Setup Test Data
1. Add payable balance to a user in Firebase Realtime Database:
```json
{
  "users": {
    "YOUR_USER_ID": {
      "payable": 300,
      "pin": "1234"
    }
  }
}
```

### Test Steps
1. **View Payable Balance:**
   - Open the app and navigate to Profile page
   - You should see a red "Outstanding Balance" section showing Rs. 300
   - The section includes a "Pay Now" button

2. **Process Payment:**
   - Click "Pay Now" button
   - You'll be redirected to the Payment page
   - The payment page shows:
     - Red-themed card (instead of teal)
     - "Outstanding Balance" title
     - Wallet icon instead of payment icon
     - "Payment ID" instead of "Reservation ID"

3. **Complete Payment:**
   - Click "Pay Now" on the payment page
   - After 2-second simulation, success dialog appears
   - After dismissing dialog, you're returned to Profile page
   - The payable balance section should no longer appear (balance reset to 0)

### Database Structure
The feature expects the following structure in Firebase Realtime Database:
```json
{
  "users": {
    "USER_ID": {
      "pin": "1234",
      "payable": 300
    }
  }
}
```

## Features
- **Conditional Display:** Payable balance section only shows when balance > 0
- **Visual Indicators:** Red color scheme to indicate urgency
- **Payment Integration:** Reuses existing PaymentPage with modifications
- **Balance Reset:** Automatically resets balance to 0 after successful payment
- **Data Persistence:** Balance is stored in Firebase Realtime Database

## Notes
- The payable balance feature integrates seamlessly with existing payment infrastructure
- Payment records are still created for payable balance payments
- The feature maintains the existing payment simulation (2-second delay)
- UI is responsive and follows the app's design patterns
