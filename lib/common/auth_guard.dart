import 'package:ado_dad_user/common/shared_pref.dart';

/// Authentication guard utility for route protection
class AuthGuard {
  /// Check if user is authenticated
  /// Returns true if user has a valid token, false otherwise
  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// List of routes that require authentication
  static const List<String> protectedRoutes = [
    '/notifications',
    '/profile',
    '/wishlist',
    '/my-ads',
    '/seller',
    '/chat-rooms',
    '/chat',
    '/add-two-wheeler-form',
    '/add-commercial-vehicle-form',
    '/add-private-vehicle-form',
    '/add-property-form',
    '/edit-two-wheeler',
    '/edit-private-vehicle',
    '/edit-commercial-vehicle',
    '/edit-property',
  ];

  /// List of routes that are accessible without authentication
  static const List<String> publicRoutes = [
    '/',
    '/login',
    '/login-otp',
    '/otp-verification',
    '/signup',
    '/home',
    '/search',
    '/category-list-page',
    '/add-detail-page',
    '/seller-profile',
    '/car-filter',
    '/property-filter',
    '/item-category',
    '/help',
    '/showroom-users',
    '/showroom-user-ads',
    '/splash-1',
    '/splash-2',
    '/splash-3',
    '/splash-4',
  ];

  /// Check if a route requires authentication
  /// Returns true if the route is in the protected routes list
  static bool isProtectedRoute(String location) {
    // Remove query parameters for checking
    final path = location.split('?').first;

    // Check exact matches
    if (protectedRoutes.contains(path)) {
      return true;
    }

    // Check if route starts with any protected route pattern
    for (final protectedRoute in protectedRoutes) {
      if (path.startsWith(protectedRoute)) {
        return true;
      }
    }

    // Check for chat routes with roomId parameter
    if (path.startsWith('/chat/')) {
      return true;
    }

    // Check for edit routes
    if (path.startsWith('/edit-')) {
      return true;
    }

    // Check for add form routes
    if (path.startsWith('/add-') &&
        (path.contains('-form') ||
            path.contains('-wheeler') ||
            path.contains('-vehicle') ||
            path.contains('-property'))) {
      return true;
    }

    return false;
  }

  /// Check if a route is public (accessible without authentication)
  static bool isPublicRoute(String location) {
    // Remove query parameters for checking
    final path = location.split('?').first;

    // Check exact matches
    if (publicRoutes.contains(path)) {
      return true;
    }

    // Check if route starts with any public route pattern
    for (final publicRoute in publicRoutes) {
      if (path.startsWith(publicRoute)) {
        return true;
      }
    }

    // Check for seller profile routes (public)
    if (path.startsWith('/seller-profile/')) {
      return true;
    }

    // Check for category list page (public)
    if (path.startsWith('/category-list-page')) {
      return true;
    }

    // Check for add detail page (public)
    if (path.startsWith('/add-detail-page')) {
      return true;
    }

    // Check for filter pages (public)
    if (path.startsWith('/car-filter') || path.startsWith('/property-filter')) {
      return true;
    }

    return false;
  }

  /// Handle route redirection based on authentication status
  /// Returns the route to redirect to, or null if access is allowed
  static Future<String?> checkRouteAccess(String location) async {
    // If it's a public route, allow access
    if (isPublicRoute(location)) {
      return null; // Allow access
    }

    // If it's a protected route, check authentication
    if (isProtectedRoute(location)) {
      final isAuth = await isAuthenticated();
      if (!isAuth) {
        // Redirect to login with a return path
        return '/login?redirect=${Uri.encodeComponent(location)}';
      }
    }

    // Allow access
    return null;
  }
}
