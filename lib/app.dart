import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/library/library_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';
import 'presentation/screens/search/search_screen.dart';
import 'presentation/screens/admin/admin_dashboard.dart';
import 'presentation/screens/admin/book_management.dart';
import 'presentation/screens/admin/user_management.dart';
import 'presentation/screens/admin/category_management.dart';
import 'presentation/screens/book_detail/book_detail_screen.dart';
import 'presentation/screens/reader/reader_screen.dart';
import 'data/models/book_model.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'AI Book Reader',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          initialRoute: AppRoutes.splash,
          routes: {
            AppRoutes.splash: (context) => const SplashScreen(),
            AppRoutes.login: (context) => const LoginScreen(),
            AppRoutes.register: (context) => const RegisterScreen(),
            AppRoutes.home: (context) => const HomeScreen(),
            AppRoutes.library: (context) => const LibraryScreen(),
            AppRoutes.profile: (context) => const ProfileScreen(),
            AppRoutes.search: (context) => const SearchScreen(),
            AppRoutes.adminDashboard: (context) => const AdminDashboard(),
            AppRoutes.adminBooks: (context) => const BookManagementScreen(),
            AppRoutes.adminUsers: (context) => const UserManagementScreen(),
            AppRoutes.adminCategories: (context) => const CategoryManagement(),
          },
          onGenerateRoute: (settings) {
            // Handle routes with parameters
            if (settings.name == AppRoutes.bookDetail) {
              final bookId = settings.arguments as String;
              return MaterialPageRoute(
                builder: (context) => BookDetailScreen(bookId: bookId),
              );
            }
            if (settings.name == AppRoutes.reader) {
              final book = settings.arguments as BookModel;
              return MaterialPageRoute(
                builder: (context) => ReaderScreen(book: book),
              );
            }
            return null;
          },
        );
      },
    );
  }
}
