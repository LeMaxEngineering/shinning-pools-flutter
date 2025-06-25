import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'welcome': 'Welcome',
      'signIn': 'Sign In',
      'signInWithGoogle': 'Sign In with Google',
      'email': 'Email',
      'password': 'Password',
      'noAccount': 'Don\'t have an account? Register',
      'pleaseEnterEmail': 'Please enter your email',
      'pleaseEnterValidEmail': 'Please enter a valid email',
      'pleaseEnterPassword': 'Please enter your password',
      'controlPanel': 'Control Panel',
      'comingSoon': 'Coming Soon: Pool and Services Management',
    },
    'es': {
      'welcome': 'Bienvenido',
      'signIn': 'Iniciar sesión',
      'signInWithGoogle': 'Iniciar sesión con Google',
      'email': 'Correo',
      'password': 'Contraseña',
      'noAccount': '¿No tienes cuenta? Regístrate',
      'pleaseEnterEmail': 'Por favor ingresa tu email',
      'pleaseEnterValidEmail': 'Ingresa un email válido',
      'pleaseEnterPassword': 'Por favor ingresa tu contraseña',
      'controlPanel': 'Panel de Control',
      'comingSoon': 'Próximamente: Gestión de piscinas y servicios',
    },
  };

  String? _getValue(String key) => _localizedValues[locale.languageCode]?[key];

  String get welcome => _getValue('welcome') ?? 'Welcome';
  String get signIn => _getValue('signIn') ?? 'Sign In';
  String get signInWithGoogle => _getValue('signInWithGoogle') ?? 'Sign In with Google';
  String get email => _getValue('email') ?? 'Email';
  String get password => _getValue('password') ?? 'Password';
  String get noAccount => _getValue('noAccount') ?? 'Don\'t have an account? Register';
  String get pleaseEnterEmail => _getValue('pleaseEnterEmail') ?? 'Please enter your email';
  String get pleaseEnterValidEmail => _getValue('pleaseEnterValidEmail') ?? 'Please enter a valid email';
  String get pleaseEnterPassword => _getValue('pleaseEnterPassword') ?? 'Please enter your password';
  String get controlPanel => _getValue('controlPanel') ?? 'Control Panel';
  String get comingSoon => _getValue('comingSoon') ?? 'Coming Soon: Pool and Services Management';
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'es'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
} 