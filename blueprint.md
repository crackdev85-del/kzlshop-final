# Project Blueprint

## 1. Overview

This document outlines the project's style, design, and features, from its initial version to the current one. It also details the plan for the latest requested changes.

## 2. Style, Design, and Features

### 2.1. Version 1.5 (Current)

1.  **Admin - Revamped Order Management:**
    *   **Refined UI Flow:** The order management process for admins has been streamlined. The `OrdersTab` now serves as a clean, high-level list of all incoming orders.
    *   **Real-time Detail View:** The `AdminOrdersScreen` has been refactored to be the primary detail screen. It now uses the `orderId` and a `StreamBuilder` to listen for real-time updates from Firestore, ensuring the displayed data is always current.
    *   **Comprehensive Customer Info:** The customer information card on the `AdminOrdersScreen` now displays the user's `username`, `shopName`, `phoneNumber`, and a tappable link that opens the customer's location directly in Google Maps.
    *   **Product Editing Capability:** A new `EditOrderProductsScreen` has been introduced, allowing admins to modify an existing order.
        *   Admins can adjust the `quantity` of each product or remove a product from the order entirely.
        *   When changes are saved, the `totalAmount` is automatically recalculated, and the order document in Firestore is updated.
        *   This screen is accessible via a new "Edit" button on the `AdminOrdersScreen`.

### 2.2. Version 1.4

1.  **Theme:**
    *   A modern, responsive theme with both light and dark modes.
    *   Custom color scheme with `babyPink`, `skyBlue`, and `pink`.
2.  **Authentication:**
    *   Firebase authentication for secure user access.
3.  **Centralized Constants:**
    *   A `lib/constants.dart` file holds all Firestore collection paths for easy management and consistency.
4.  **Admin - Product Management:**
    *   Admin panel for managing products, orders, and users.
    *   **Category Dropdown:** The add/edit product screen now features a dropdown menu to select and save a category for each product.
5.  **User - Product Discovery & Display:**
    *   **Category Carousel:** The home screen now features a horizontal carousel of categories below the app bar, allowing users to browse categories easily.
    *   **Product Filtering:** Tapping a category filters the product grid to show only items belonging to that category. An "All" button is available to reset the filter.
    *   **Category Chip:** On the `ProductDetailScreen`, the product's category is displayed as a chip for clear identification.
    *   **Robust Image Handling:** All screens that display images can now correctly render them from both `base64` strings (used for categories) and network URLs.
6.  **Shopping Cart:**
    *   A fully functional shopping cart with `CartProvider`.
7.  **Order Management:**
    *   `OrderProvider` for managing customer orders.
8.  **Admin - Category Management:**
    *   A "Category" feature allows adding categories with names and images.
    *   `CategoryProvider` uses the centralized collection path from `constants.dart`.
    *   Images are stored in the database in `base64` format with a `data:image/jpeg;base64,` prefix.

## 3. Completed Plan

1.  **Implement Admin Order Editing:**
    *   Refactored the admin order view to use `StreamBuilder` for real-time data on `AdminOrdersScreen`.
    *   Added a new `EditOrderProductsScreen` allowing admins to change quantities or remove items from an order.
    *   Implemented the logic to automatically recalculate the total price and update the order in Firestore.
    *   Enhanced the customer info section to include `username` and a Google Maps link for the `location`.
2.  **Implement Category Carousel and Filtering on Home Screen:**
    *   Added a horizontal, scrollable list of categories with their images and names below the app bar on the `HomeScreen`.
    *   Implemented functionality to filter the product grid based on the selected category.
    *   Included an "All" category option to view all products.
3.  **Display Category on Product Detail Page:**
    *   Created a reusable `CategoryWidget` to fetch a category's name by its ID.
    *   Integrated this widget into the `ProductDetailScreen` to display the category name prominently.
    *   Corrected an issue where network images were not loading on the detail page.
