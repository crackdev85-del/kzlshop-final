
# Project Blueprint

## Overview

This project is a Flutter application for a snack shop named "KZL Shop". The application allows users to browse products, add them to a cart, and place orders. The app uses Firebase for authentication and Firestore for data storage.

## Implemented Features

*   **User Authentication:**
    *   Users can sign up for a new account with their email and password.
    *   Users can log in with their existing account.
    *   The app persists the user's login state.
*   **Product Display:**
    *   Products are fetched from a Firestore collection.
    *   Products are displayed in a grid view on the home screen.
    *   Each product card shows the product image, name, and price.
*   **Styling and Theming:**
    *   The app uses the `google_fonts` package for custom fonts.
    *   The app has a custom theme with a primary color of amber.
    *   The app supports both light and dark modes.
*   **Code Structure:**
    *   The code is organized into separate files for different screens (login, signup, home).
    *   The `provider` package is used for state management.

## Current Request Plan

*   Modernize the `lib/main.dart` file to match the UI/UX of `App.jsx`.
*   Add an app bar with a logo and shop name.
*   Add a floating action button (FAB) with a cart icon.
*   Fetch products from Firestore and display them in a grid view.
*   Create a separate `home_screen.dart` file for the home screen UI.
*   Update the `signup_screen.dart` to collect additional user information (shop name, phone number, address).
*   Organize the code into separate files for better readability and maintenance.
*   Add assets to the project and declare them in `pubspec.yaml`.
