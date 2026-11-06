import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';

/// First-launch screen that prompts the user for their Gemini API key.
/// Once saved, it navigates directly to the Dashboard on subsequent launches.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _storage = FlutterSecureStorage();
  static const _apiKeyStorageKey = 'gemini_api_key';

  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _obscureText = true;
  String? _errorMessage;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _checkExistingKey();
  }

  Future<void> _checkExistingKey() async {
    await Future.delayed(const Duration(milliseconds: 400));
    final existingKey = await _storage.read(key: _apiKeyStorageKey);
    if (!mounted) return;

    if (existingKey != null && existingKey.isNotEmpty) {
      _navigateToDashboard(existingKey);
    } else {
      setState(() => _isLoading = false);
      _fadeController.forward();
    }
  }

  Future<void> _saveApiKey() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final key = _apiKeyController.text.trim();
    try {
      await _storage.write(key: _apiKeyStorageKey, value: key);
      if (!mounted) return;
      _navigateToDashboard(key);
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = 'Failed to save API key securely. Please try again.';
      });
    }
  }

  void _navigateToDashboard(String apiKey) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DashboardScreen(apiKey: apiKey),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ParkSnapLogo(),
              SizedBox(height: 32),
              CircularProgressIndicator(color: AppTheme.primary),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  const _ParkSnapLogo(),
                  const SizedBox(height: 20),
                  Text(
                    'PARKSNAP',
                    style: AppTheme.headlineLg.copyWith(
                      color: AppTheme.primary,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gate Vehicle Intelligence',
                    style: AppTheme.bodyMd.copyWith(
                      color: AppTheme.onSurfaceVariant,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // API Key setup card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.outlineVariant,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.vpn_key_rounded,
                              color: AppTheme.secondary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'API KEY SETUP',
                              style: AppTheme.labelLg.copyWith(
                                color: AppTheme.secondary,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Enter your Gemini API key to enable AI-powered license plate recognition. '
                          'Your key is stored securely on this device only.',
                          style: AppTheme.bodyMd,
                        ),
                        const SizedBox(height: 20),

                        // API Key field
                        TextFormField(
                          controller: _apiKeyController,
                          obscureText: _obscureText,
                          style: AppTheme.labelLg.copyWith(
                            color: AppTheme.onSurface,
                            letterSpacing: 0.5,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Gemini API Key',
                            hintText: 'AIzaSy...',
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              color: AppTheme.outline,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppTheme.outline,
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _obscureText = !_obscureText),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'API key is required';
                            }
                            if (val.trim().length < 20) {
                              return 'Key appears too short — check for typos';
                            }
                            return null;
                          },
                        ),

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            _errorMessage!,
                            style: AppTheme.labelMd.copyWith(
                                color: AppTheme.error),
                          ),
                        ],

                        const SizedBox(height: 24),

                        ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveApiKey,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: AppTheme.onPrimary,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check_circle_outline_rounded,
                                  size: 20),
                          label: Text(
                              _isSaving ? 'SAVING...' : 'ACTIVATE PARKSNAP'),
                        ),

                        const SizedBox(height: 16),
                        // Link to get API key
                        Center(
                          child: GestureDetector(
                            child: Text(
                              'Get a free API key at aistudio.google.com',
                              style: AppTheme.labelSm.copyWith(
                                color: AppTheme.primary.withValues(alpha: 0.7),
                                decoration: TextDecoration.underline,
                                decorationColor:
                                    AppTheme.primary.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  // Feature bullets
                  ..._features.map((f) => _FeatureBullet(icon: f.$1, label: f.$2)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const _features = [
  (Icons.camera_alt_rounded, 'Camera-based license plate capture'),
  (Icons.psychology_rounded, 'Gemini 2.5 Flash AI extraction'),
  (Icons.storage_rounded, 'Offline SQLite local storage'),
  (Icons.speed_rounded, 'Instant gate entry/exit logging'),
];

class _FeatureBullet extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureBullet({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 12),
          Text(label, style: AppTheme.bodyMd),
        ],
      ),
    );
  }
}

class _ParkSnapLogo extends StatelessWidget {
  const _ParkSnapLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D2B1F), Color(0xFF0A1F33)],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.primaryContainer, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryContainer.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.local_parking_rounded,
        color: AppTheme.primary,
        size: 42,
      ),
    );
  }
}
