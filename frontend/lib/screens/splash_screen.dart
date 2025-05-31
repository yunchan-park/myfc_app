import 'package:flutter/material.dart';
import 'package:myfc_app/config/routes.dart';
import 'package:myfc_app/config/theme.dart';
import 'package:myfc_app/services/api_service.dart';
import 'package:myfc_app/services/auth_service.dart';
import 'package:myfc_app/utils/validators.dart';
import 'package:myfc_app/utils/helpers.dart';
import 'package:myfc_app/widgets/common/app_button.dart';
import 'package:myfc_app/widgets/common/app_input.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _apiService = ApiService();
  bool _isLoading = false;
  bool _checkingAuth = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final isLoggedIn = await _authService.isLoggedIn();
    if (isLoggedIn) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } else {
      setState(() {
        _checkingAuth = false;
      });
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final loginResponse = await _apiService.loginTeam(
        _nameController.text.trim(),
        _passwordController.text.trim(),
      );

      final accessToken = loginResponse['access_token'] as String;
      var teamIdStr = '';
      
      if (loginResponse.containsKey('team_id')) {
        final teamId = loginResponse['team_id'];
        teamIdStr = teamId.toString();
      }

      await _authService.saveAuthData(accessToken, teamIdStr);

      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          '로그인에 실패했습니다. 구단 이름과 비밀번호를 확인해주세요.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAuth) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  Row(
                    children: [
                      Icon(
                        Icons.sports_soccer,
                        size: 40,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'MY FC',
                        style: AppTextStyles.displayLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 80),
                  AppInput(
                    controller: _nameController,
                    hint: '구단 이름을 입력해주세요',
                    validator: Validators.validateTeamName,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  AppInput(
                    controller: _passwordController,
                    hint: '구단의 비밀번호를 입력해주세요',
                    obscureText: true,
                    validator: Validators.validatePassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _login(),
                  ),
                  const SizedBox(height: 32),
                  AppButton(
                    text: '우리 구단 페이지로 가기',
                    onPressed: _isLoading ? null : _login,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: AppButton(
                      text: '우리 구단 입력하기',
                      variant: AppButtonVariant.text,
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.registerTeam,
                      ),
                    ),
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