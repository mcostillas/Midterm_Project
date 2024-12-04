# Expense Tracker App

A modern and intuitive expense tracking application built with Flutter. This app helps users manage their personal finances by tracking income, expenses, and providing detailed statistics.

## Features

- **Balance Management**
  - Track current balance
  - Add/modify balance with transaction history
  - Color-coded transactions (green for income, red for expenses)

- **Transaction Management**
  - Add income and expenses
  - Categorize transactions
  - Add transaction descriptions
  - View detailed transaction history

- **Category System**
  - Default categories (Income, Food, Transportation, etc.)
  - Add custom categories
  - Category-based filtering
  - Color-coded category icons

- **Statistics and Analytics**
  - Visual expense breakdown with pie charts
  - Category-wise expense distribution
  - Toggle between income and expense views
  - Comprehensive date filtering options
    - Today
    - This Week
    - This Month
    - This Year
    - All Time

- **Modern UI/UX**
  - Clean, minimalist design
  - Intuitive navigation
  - Responsive layout
  - Pull-to-refresh functionality
  - Empty state handling
  - Error state management

## Getting Started

### Prerequisites

- Flutter (latest stable version)
- Dart SDK >=3.0.0 <4.0.0

### Installation

1. Clone the repository
   ```bash
   git clone https://github.com/mcostillas/Midterm_Project.git
   ```

2. Navigate to the project directory
   ```bash
   cd Midterm_Project
   ```

3. Install dependencies
   ```bash
   flutter pub get
   ```

4. Run the app
   ```bash
   flutter run
   ```

## Dependencies

- `shared_preferences: ^2.2.2` - Local data storage
- `uuid: ^4.2.1` - Unique ID generation
- `fl_chart: ^0.66.2` - Chart visualization
- `google_fonts: ^5.1.0` - Custom fonts
- `intl: ^0.19.0` - Internationalization and formatting
- `flutter_svg: ^2.0.9` - SVG support
- `collection: ^1.17.0` - Collection utilities

## Project Structure

```
lib/
├── constants/
│   └── categories.dart
├── models/
│   └── transaction.dart
├── screens/
│   ├── home_screen.dart
│   ├── add_expense_screen.dart
│   ├── statistics_screen.dart
│   ├── settings_screen.dart
│   └── history_screen.dart
├── services/
│   ├── storage_service.dart
│   └── category_service.dart
├── theme/
│   └── app_theme.dart
└── widgets/
    └── app_logo.dart
```

## Author

**Costillas, Celeste T.**
- Section: BSCS 3-3
- Created: October 2023

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
