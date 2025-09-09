
# KZL Shop Blueprint

## Overview

KZL Shop is a modern e-commerce application built with Flutter and Firebase. It provides a seamless shopping experience for users, allowing them to browse products, add items to their cart, and place orders. The application also includes an admin panel for managing products and orders.

## Implemented Features

### Style and Design

*   **Theming:** The application features a custom theme with a light and dark mode.
    *   **Light Theme:** Uses a baby pink background, sky blue primary color, and pink secondary color.
    *   **Dark Theme:** Uses a dark grey background with the same sky blue and pink accent colors.
*   **Typography:** Utilizes Google Fonts for a modern and readable typography.
    *   **Oswald:** for headings.
    *   **Roboto:** for titles.
    *   **Open Sans:** for body text.
*   **UI Components:**
    *   Custom-styled buttons, app bars, and other UI elements to match the theme.
    *   Consistent use of icons and imagery to enhance user experience.

### User Features

*   **Authentication:**
    *   Users can sign up and log in using email and password.
    *   Authentication state is managed to provide a seamless experience.
*   **Product Browsing:**
    *   Users can view a list of products with their names, prices, and images.
*   **Shopping Cart:**
    *   Users can add products to their shopping cart.
    *   The cart provider manages the state of the shopping cart.
*   **Order Placement:**
    *   Users can place orders for the items in their cart.
    *   Order details are stored in Firestore.
*   **User Profile:**
    *   A dedicated profile screen for users to view their information.

### Admin Features

*   **Admin Panel:**
    *   A dedicated admin panel for managing the application.
*   **Product Management:**
    *   Admins can add, edit, and delete products.
    *   Product information is stored in Firestore.
*   **Order Management:**
    *   Admins can view and manage customer orders.
    *   Order details can be updated (e.g., changing the order status).

## Refactoring: Order Model

I have refactored the application to use a more consistent and robust data model for orders. The original `Order` model has been replaced with a new `OrderItem` model to better represent the structure of an order and its contents.

**Changes Made:**

*   **`order.dart`:** The original `Order` model has been removed and is no longer in use.
*   **`order_item.dart`:**
    *   A new `OrderItem` model has been introduced to represent an individual order.
    *   This model includes a list of `OrderProduct` objects, each representing a product within the order.
    *   A `fromFirestore` factory method has been added to facilitate the creation of `OrderItem` objects from Firestore documents.
*   **`order_provider.dart`:**
    *   The `OrderProvider` has been updated to use the new `OrderItem` model.
    *   The `addOrder` method now takes a list of `CartItem` objects and a total amount to create a new order.
    *   The `updateOrderStatus` method has been updated to work with the new `OrderItem` model.
*   **Screen Updates:**
    *   **`order_details_screen.dart` (Admin & User):** These screens have been updated to use the `OrderItem` model, ensuring that order details are displayed correctly.
    *   **`checkout_screen.dart`:** The checkout process has been updated to create orders using the new `OrderProvider` and `OrderItem` model.
    *   **`my_orders_screen.dart`:** This screen now fetches and displays a list of the user's orders using the `OrderItem` model.
*   **Widget Updates:**
    *   **`order_item_card.dart`:** This widget has been updated to display order information using the `OrderItem` model.

**Outcome:**

This refactoring has resulted in a more organized and maintainable codebase. The new `OrderItem` model provides a clearer representation of the data, and the application is now more robust and less prone to errors related to order management.

## Current Plan

All planned refactoring and bug fixes have been completed. The application is now in a stable state with no known issues. I am ready for the next set of instructions.
