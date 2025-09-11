# Project Blueprint

## Overview

This document outlines the project's style, design, and features, from its initial version to the current one. It also details the plan for the latest requested changes.

## Style, Design, and Features

### Version 1.3 (Current)

- **Theme:**
  - A modern, responsive theme with both light and dark modes.
  - Custom color scheme with `babyPink`, `skyBlue`, and `pink`.
- **Authentication:**
  - Firebase authentication for secure user access.
- **Centralized Constants:**
  - A `lib/constants.dart` file holds all Firestore collection paths for easy management and consistency.
- **Admin - Product Management:**
  - Admin panel for managing products, orders, and users.
  - **Category Dropdown:** The add/edit product screen now features a dropdown menu to select and save a category for each product.
- **User - Product Display:**
  - **Category Display:** On the `ProductDetailScreen`, the product's category is now displayed as a chip, making it easy for users to see the category at a glance.
  - **Robust Image Handling:** The product detail and list screens can now correctly display images from both `base64` strings and network URLs (`http`).
- **Shopping Cart:**
  - A fully functional shopping cart with `CartProvider`.
- **Order Management:**
  - `OrderProvider` for managing customer orders.
- **Admin - Category Management:**
  - A "Category" feature allows adding categories with names and images.
  - `CategoryProvider` uses the centralized collection path from `constants.dart`.
  - Images are stored in the database in `base64` format with a `data:image/jpeg;base64,` prefix.

## Completed Plan

- **Display Category on Product Detail Page:**
  - Created a reusable `CategoryWidget` to fetch a category's name by its ID.
  - Integrated this widget into the `ProductDetailScreen` to display the category name prominently.
  - Corrected an issue where network images were not loading on the detail page.
