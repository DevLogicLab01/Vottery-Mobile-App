import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';

class QuickRegistrationScreen extends StatefulWidget {
  final String? electionId;
  final String? referralSource;

  const QuickRegistrationScreen({
    super.key,
    this.electionId,
    this.referralSource,
  });

  @override
  State<QuickRegistrationScreen> createState() =>
      _QuickRegistrationScreenState();
}

class _QuickRegistrationScreenState extends State<QuickRegistrationScreen> {
  final AuthService _authService = AuthService.instance;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _termsAccepted = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleQuickSignup() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_termsAccepted) {
      setState(() {
        _errorMessage = 'Please accept the Terms & Privacy Policy';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Create quick account
      final response = await _authService.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _generateTemporaryPassword(),
        fullName: _nameController.text.trim(),
      );

      if (response.user != null) {
        // Record quick registration
        await _recordQuickRegistration(response.user!.id);

        // Navigate to election or show success
        if (widget.electionId != null) {
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.voteCasting,
            arguments: {'electionId': widget.electionId},
          );
        } else {
          // New users: topic preference onboarding (swipeable interest cards) then feed
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.topicPreferenceCollectionHub,
            arguments: {'fromOnboarding': true},
          );
        }

        // Show welcome tooltip
        _showWelcomeTooltip();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Registration failed: ${e.toString()}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _generateTemporaryPassword() {
    // Generate a secure temporary password
    return DateTime.now().millisecondsSinceEpoch.toString() +
        _emailController.text.hashCode.toString();
  }

  Future<void> _recordQuickRegistration(String userId) async {
    // Record in quick_registrations table
    try {
      await SupabaseService.instance.client.from('quick_registrations').insert({
        'user_id': userId,
        'election_id': widget.electionId,
        'registration_source': widget.referralSource ?? 'external_link',
      });
    } catch (e) {
      debugPrint('Failed to record quick registration: $e');
    }
  }

  void _showWelcomeTooltip() {
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Account created! Complete profile later for full features',
            ),
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Complete Now',
              onPressed: () {
                Navigator.pushNamed(context, '/user-profile');
              },
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Quick Sign Up',
        variant: CustomAppBarVariant.withBack,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Election Preview (if applicable)
              if (widget.electionId != null) ...[
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.how_to_vote, color: Colors.blue[700]),
                          SizedBox(width: 2.w),
                          Text(
                            'You\'re invited to vote!',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Quick sign up to participate in this election',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 3.h),
              ],

              // Header
              Text(
                'Create Your Account',
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 1.h),
              Text(
                'Get started in seconds',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
              ),
              SizedBox(height: 3.h),

              // Error Message
              if (_errorMessage != null)
                Container(
                  padding: EdgeInsets.all(2.w),
                  margin: EdgeInsets.only(bottom: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.red[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[900]),
                        ),
                      ),
                    ],
                  ),
                ),

              // Email Field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'your@email.com',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}\$',
                  ).hasMatch(value)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 2.h),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'John Doe',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 2.h),

              // Phone Field (Optional)
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone (Optional)',
                  hintText: '+1 234 567 8900',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              SizedBox(height: 2.h),

              // Terms Checkbox
              CheckboxListTile(
                value: _termsAccepted,
                onChanged: (value) {
                  setState(() => _termsAccepted = value ?? false);
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text.rich(
                  TextSpan(
                    text: 'I agree to the ',
                    style: TextStyle(fontSize: 11.sp),
                    children: [
                      TextSpan(
                        text: 'Terms & Privacy Policy',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                activeColor: AppTheme.primaryColor,
              ),
              SizedBox(height: 3.h),

              // Sign Up Button
              SizedBox(
                width: double.infinity,
                height: 6.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleQuickSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20.sp,
                          width: 20.sp,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Sign Up & Vote',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 2.h),

              // Alternative Auth
              Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2.w),
                    child: Text(
                      'OR',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              SizedBox(height: 2.h),

              // Google Sign In
              SizedBox(
                width: double.infinity,
                height: 6.h,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final success = await _authService.signInWithGoogle();
                    if (success && mounted) {
                      if (widget.electionId != null) {
                        Navigator.pushReplacementNamed(
                          context,
                          '/vote-casting',
                          arguments: {'electionId': widget.electionId},
                        );
                      } else {
                        Navigator.pushReplacementNamed(
                          context,
                          '/social-media-home-feed',
                        );
                      }
                    }
                  },
                  icon: Icon(Icons.g_mobiledata, size: 24.sp),
                  label: Text('Continue with Google'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
