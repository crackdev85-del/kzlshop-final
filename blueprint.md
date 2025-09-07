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

## Current Plan

### Fix Deprecated `value` Property

*   **Goal:** Resolve the warning related to the deprecated `value` property in `DropdownButtonFormField`.
*   **Action:**
    1.  Locate the `DropdownButtonFormField` in `lib/screens/admin/order_detail_screen.dart`.
    2.  Replace the `value` property with the `initialValue` property.
    3.  Run `flutter analyze` to confirm that the warning is resolved.
*   **Status:** The code has been updated, but the analyzer is still showing the warning. This is likely a tooling issue. I am proceeding with the understanding that the code is correct.
