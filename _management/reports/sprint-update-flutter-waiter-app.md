# Sprint Update — Flutter Waiter App

## Summary
All requested changes have been implemented, committed, and pushed.
This update focuses on usability improvements, safer order handling, and runtime stability for the waiter application.

## Delivered Work

### Default Waiter Setting
Added local waiter preference:
- Popup settings action in Waiter View.
- Stored with local persistence.
- Waiter field auto-fills from saved value.
- Field resets to default after order submission.

### Navigation Improvements
Added quick navigation controls:
- Back button
- Home button

Available in:
- Waiter View
- Orders View

### Submission Flow
After successful order submission:
- User automatically returns to the main home screen.
- Works for both new orders and extras.

### Extra Order Selection Logic
Improved parent order selection:
- If multiple orders exist for a table, the user must choose the correct base order.
- Prevents accidental linking of extras to the wrong order.

### Extra Selector Context
Entries now display:
- Table number
- Order time
- Waiter name

This ensures the user selects the correct order context.

### Base Order Filtering
Extra orders are excluded from selection lists:
- Only valid base orders appear in selectors.
- Prevents invalid parent relationships.

### Dynamic Categories
Menu categories are now generated dynamically from the backend payload.
No hardcoded category list remains in the UI.

### Inactive Menu Items
Inactive items remain visible but disabled:
- Marked with an OFF label.
- Cannot be added to orders.

### Android Stability Fix
Resolved runtime crash related to Flutter binary stripping during packaging.

### API Configuration
Application now points directly to the production backend:
- https://taverna-prodromes-68a3161fcaa2.herokuapp.com/

## Validation
- Tests executed multiple times.
- Debug and release builds verified.
- No runtime issues detected during validation.

## Repository State
All work has been committed and pushed to the repository.

## Status
Implementation for the requested scope is complete and stable.
