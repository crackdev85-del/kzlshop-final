# KZL Shop App Blueprint

## Overview

This document outlines the architecture, features, and design of the KZL Shop mobile application. The app is a Flutter-based e-commerce platform that allows users to browse products, add them to a cart, and place orders. It also includes an admin panel for managing products and orders.

## Core Features

### User Features

- **Authentication**: Users can sign up and log in using their email and password.
- **Product Browsing**: Users can view a grid of available products on the home screen.
- **Product Details**: Tapping on a product reveals a details screen with a larger image, description, and price.
- **Shopping Cart**: Users can add products to a shopping cart and view the items in their cart.
- **Order Placement**: Users can place orders from the items in their cart.
- **Order History**: Users can view a list of their past orders.
- **Profile Management**: Users can view and update their profile information, including their username, address, and profile picture.
- **Dark Mode**: Users can toggle between light and dark themes.

### Admin Features

- **Admin Panel**: Admins have access to a separate dashboard to manage the application.
- **Product Management**: Admins can add, edit, and delete products.
- **Order Management**: Admins can view and manage user orders.
- **Category Management**: Admins can add, edit, and delete product categories.
- **Township Management**: Admins can add, edit, and delete townships for delivery.
- **Announcement Management**: Admins can create and manage announcements that are displayed to users.

## Design and Theming

- **Shop Name**: The official name of the shop is "KZL Shop", which is displayed in the app bar.
- **Color Scheme**: The application uses a consistent color scheme for both light and dark themes, derived from a primary seed color.
- **Typography**: The app uses a consistent set of text styles for headings, titles, and body text to ensure a readable and visually appealing interface.
- **Layout**: The layout is designed to be clean and intuitive, with a focus on user experience.

## Technical Architecture

- **Frontend**: The application is built with Flutter, a cross-platform UI toolkit.
- **Backend**: The backend is powered by Firebase, utilizing the following services:
    - **Firestore**: For storing data such as products, orders, users, and categories.
    - **Authentication**: For managing user authentication.
    - **Firebase Storage**: Although not currently used for storing images directly (they are stored as Base64 in Firestore), it can be integrated in the future for more efficient image handling.
- **State Management**: The application uses the `provider` package for state management, particularly for the shopping cart and theme.
- **Navigation**: The app uses a combination of `MaterialPageRoute` for basic navigation and a `PageController` for the main bottom navigation bar.
- **Dependencies**:
    - `cloud_firestore`: For interacting with Firestore.
    - `firebase_auth`: For user authentication.
    - `provider`: For state management.
    - `image_picker`: For picking images from the camera or gallery.
    - `url_launcher`: For opening external links, such as Google Maps.

## Current Task: Implement User Profile Picture

### Plan

1.  **Add `image_picker` dependency**: Add the `image_picker` package to `pubspec.yaml` to enable image selection from the camera.
2.  **Update Profile Screen UI**:
    - Add a `CircleAvatar` to display the user's profile picture.
    - Add an `IconButton` with a camera icon to allow the user to take a new photo.
    - Show a default person icon if no profile picture is available.
    - Display a loading indicator while the image is being uploaded.
3.  **Implement Image Picking and Uploading Logic**:
    - When the camera icon is tapped, use `ImagePicker` to open the device's camera.
    - After an image is captured, convert the image file to a Base64 encoded string.
    - Update the user's document in the `users` collection in Firestore, saving the Base64 string to the `profilePicture` field.
4.  **Display the Profile Picture**:
    - In the `ProfileScreen`, fetch the `profilePicture` field from the user's document.
    - If the field contains a Base64 string, decode it and display the image in the `CircleAvatar`.
