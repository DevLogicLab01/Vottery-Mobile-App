import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../services/auth_service_new.dart';
import '../../widgets/error_boundary_wrapper.dart';

/// Authentication screen with email/password and Google sign-in
class BiometricAuthentication extends StatefulWidget {
  const BiometricAuthentication({super.key});

  @override
  State<BiometricAuthentication> createState() =>
      _BiometricAuthenticationState();
}

class _BiometricAuthenticationState extends State<BiometricAuthentication>
    with SingleTickerProviderStateMixin {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final AuthService _authService = AuthService.instance;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isAuthenticating = false;
  bool _canCheckBiometrics = false;
  List<BiometricType> _availableBiometrics = [];
  int _failedAttempts = 0;
  bool _isLockedOut = false;
  int _lockoutSeconds = 0;
  String _errorMessage = '';
  bool _isSignUpMode = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _initializePulseAnimation();
    _checkBiometricAvailability();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _initializePulseAnimation() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (mounted) {
        setState(() {
          _canCheckBiometrics = canCheck && isDeviceSupported;
        });
      }

      if (_canCheckBiometrics) {
        final availableBiometrics = await _localAuth.getAvailableBiometrics();
        if (mounted) {
          setState(() {
            _availableBiometrics = availableBiometrics;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _canCheckBiometrics = false;
          _errorMessage = 'Unable to check biometric availability';
        });
      }
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    if (_isLockedOut) {
      _showErrorMessage(
        'Too many failed attempts. Please wait $_lockoutSeconds seconds.',
      );
      return;
    }

    if (!_canCheckBiometrics) {
      _showBiometricNotEnrolledDialog();
      return;
    }

    setState(() {
      _isAuthenticating = true;
      _errorMessage = '';
    });

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your voting account',
      );

      if (authenticated) {
        _handleSuccessfulAuthentication();
      } else {
        _handleFailedAuthentication();
      }
    } on PlatformException catch (e) {
      _handleAuthenticationError(e);
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  Future<void> _handleEmailPasswordAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isAuthenticating = true;
      _errorMessage = '';
    });

    try {
      if (_isSignUpMode) {
        await AuthService.instance.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
        );
        if (mounted) {
          _showSuccessMessage(
            'Account created! Please check your email to verify.',
          );
        }
      } else {
        final authResponse = await AuthService.instance.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (authResponse.user != null && mounted) {
          _handleSuccessfulAuthentication();
        } else {
          throw Exception('Sign in failed');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
        _showErrorMessage(_errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isAuthenticating = true;
      _errorMessage = '';
    });

    try {
      final success = await AuthService.instance.signInWithGoogle();
      if (success && mounted) {
        _handleSuccessfulAuthentication();
      } else if (mounted) {
        _showErrorMessage('Google sign-in cancelled');
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Google sign-in failed: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  void _handleSuccessfulAuthentication() {
    HapticFeedback.mediumImpact();
    setState(() {
      _failedAttempts = 0;
      _errorMessage = '';
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushReplacementNamed(AppRoutes.voteDashboard);
      }
    });
  }

  void _handleFailedAuthentication() {
    setState(() {
      _failedAttempts++;
      _errorMessage = 'Authentication failed. Attempt $_failedAttempts of 3';
    });

    if (_failedAttempts >= 3) {
      _triggerLockout();
    }
  }

  void _handleAuthenticationError(PlatformException e) {
    String errorMsg = 'Authentication error occurred';

    if (e.code == 'NotAvailable') {
      errorMsg = 'Biometric authentication not available';
    } else if (e.code == 'NotEnrolled') {
      _showBiometricNotEnrolledDialog();
      return;
    } else if (e.code == 'LockedOut' || e.code == 'PermanentlyLockedOut') {
      _triggerLockout();
      return;
    }

    setState(() {
      _errorMessage = errorMsg;
    });
  }

  void _triggerLockout() {
    setState(() {
      _isLockedOut = true;
      _lockoutSeconds = 30;
      _errorMessage = 'Too many failed attempts. Locked for 30 seconds.';
    });

    _startLockoutTimer();
  }

  void _startLockoutTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _isLockedOut) {
        setState(() {
          _lockoutSeconds--;
          if (_lockoutSeconds <= 0) {
            _isLockedOut = false;
            _failedAttempts = 0;
            _errorMessage = '';
          } else {
            _errorMessage = 'Locked for $_lockoutSeconds seconds';
            _startLockoutTimer();
          }
        });
      }
    });
  }

  void _showBiometricNotEnrolledDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Biometric Not Enrolled',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          'Please enroll your fingerprint or face in device settings to use biometric authentication.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'BiometricAuthentication',
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 4.h),

                  // Logo and title
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 24.w,
                          height: 24.w,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: CustomIconWidget(
                              iconName: 'how_to_vote',
                              color: theme.colorScheme.primary,
                              size: 12.w,
                            ),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Welcome to Vottery',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          _isSignUpMode
                              ? 'Create your account'
                              : 'Sign in to continue',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 4.h),

                  // Demo credentials info
                  Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 5.w,
                              color: theme.colorScheme.primary,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              'Demo Login Credentials',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          'Email: sarah.johnson@email.com',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                        Text(
                          'Password: password123',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 3.h),

                  // Name field (only in sign-up mode)
                  if (_isSignUpMode) ...[
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      validator: (value) {
                        if (_isSignUpMode && (value == null || value.isEmpty)) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 2.h),
                  ],

                  // Email field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 2.h),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (_isSignUpMode && value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 1.h),

                  // Forgot password
                  if (!_isSignUpMode)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // Show forgot password dialog
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Reset Password'),
                              content: const Text(
                                'Password reset functionality will send a reset link to your email.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(color: theme.colorScheme.primary),
                        ),
                      ),
                    ),

                  SizedBox(height: 2.h),

                  // Error message
                  if (_errorMessage.isNotEmpty)
                    Container(
                      padding: EdgeInsets.all(3.w),
                      margin: EdgeInsets.only(bottom: 2.h),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        _errorMessage,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),

                  // Sign in/up button
                  ElevatedButton(
                    onPressed: _isAuthenticating
                        ? null
                        : _handleEmailPasswordAuth,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: _isAuthenticating
                        ? SizedBox(
                            height: 5.w,
                            width: 5.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _isSignUpMode ? 'Sign Up' : 'Sign In',
                            style: TextStyle(fontSize: 14.sp),
                          ),
                  ),

                  SizedBox(height: 2.h),

                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(color: theme.colorScheme.outline),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: Text(
                          'OR',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: theme.colorScheme.outline),
                      ),
                    ],
                  ),

                  SizedBox(height: 2.h),

                  // Google sign-in button
                  OutlinedButton.icon(
                    onPressed: _isAuthenticating ? null : _handleGoogleSignIn,
                    icon: Icon(Icons.g_mobiledata, size: 7.w),
                    label: Text(
                      'Continue with Google',
                      style: TextStyle(fontSize: 13.sp),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),

                  SizedBox(height: 2.h),

                  // Biometric authentication (if available)
                  if (_canCheckBiometrics) ...[
                    OutlinedButton.icon(
                      onPressed: _isAuthenticating
                          ? null
                          : _authenticateWithBiometrics,
                      icon: Icon(
                        _availableBiometrics.contains(BiometricType.face)
                            ? Icons.face
                            : Icons.fingerprint,
                        size: 6.w,
                      ),
                      label: Text(
                        _availableBiometrics.contains(BiometricType.face)
                            ? 'Use Face ID'
                            : 'Use Fingerprint',
                        style: TextStyle(fontSize: 13.sp),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),
                  ],

                  // Toggle sign-up/sign-in
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isSignUpMode
                            ? 'Already have an account?'
                            : "Don't have an account?",
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isSignUpMode = !_isSignUpMode;
                            _errorMessage = '';
                          });
                        },
                        child: Text(
                          _isSignUpMode ? 'Sign In' : 'Sign Up',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
