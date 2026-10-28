import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'providers/app_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/peserta/peserta_main_screen.dart';
import 'screens/admin/admin_main_screen.dart';
import 'screens/pembimbing/pembimbing_main_screen.dart';
import 'services/supabase_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  
  // Initialize Supabase
  await SupabaseService.initialize();
  
  runApp(const SiPklApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class SiPklApp extends StatelessWidget {
  const SiPklApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'SIAP-D',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    if (!provider.isLoggedIn) {
      return const LoginScreen();
    }

    if (provider.isAdmin) {
      return const AdminMainScreen();
    }

    if (provider.isPembimbing) {
      return const PembimbingMainScreen();
    }

    return const PesertaMainScreen();
  }
}
