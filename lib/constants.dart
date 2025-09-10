// COLLECTIONS
const String productsCollectionPath = 'artifacts/default-app-id/public/data/products';
const String categoriesCollectionPath = 'artifacts/default-app-id/public/data/categories';
const String townshipsCollectionPath = 'artifacts/default-app-id/public/data/townships';
const String announcementsCollectionPath = 'artifacts/default-app-id/public/data/announcements';
const String usersCollectionPath = 'artifacts/default-app-id/public/data/users';
const String ordersCollectionPath = 'artifacts/default-app-id/public/data/orders';

// SETTINGS: single doc to hold shop name, logo and splash
const String settingsCollectionPath = 'artifacts/default-app-id/public/data/settings';
const String settingsDocId = 'meta';

class Constants {
  // Product Fields
  static const String productName = 'name';
  static const String productPrice = 'price';
  static const String productQuantity = 'quantity';
  static const String productDescription = 'description';
  static const String productImageUrl = 'imageUrl';
  static const String productCategoryId = 'categoryId'; // Added this
}
