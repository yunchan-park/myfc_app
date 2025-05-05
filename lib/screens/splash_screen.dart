import 'package:flutter/material.dart';
import 'package:myfc_app/config/routes.dart';
import 'package:myfc_app/services/api_service.dart';
import 'package:myfc_app/services/auth_service.dart';
import 'package:myfc_app/utils/validators.dart';
import 'package:myfc_app/utils/helpers.dart';

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

      final token = loginResponse['access_token'] as String;
      int teamId;
      
      // API가 직접 team_id를 반환하는지 확인
      if (loginResponse.containsKey('team_id')) {
        teamId = loginResponse['team_id'] as int;
      } 
      // JWT 토큰에서 추출한 데이터에서 확인
      else if (loginResponse.containsKey('token_data') && 
              loginResponse['token_data'] is Map &&
              (loginResponse['token_data'] as Map).containsKey('team_id')) {
        final tokenTeamId = loginResponse['token_data']['team_id'];
        if (tokenTeamId is int) {
          teamId = tokenTeamId;
        } else if (tokenTeamId is String) {
          teamId = int.tryParse(tokenTeamId) ?? 0;
        } else {
          // 팀 ID를 찾을 수 없는 경우
          throw Exception("Failed to extract team ID from token");
        }
      } else {
        // 위 방법으로도 팀 ID를 찾을 수 없는 경우
        throw Exception("Failed to extract team ID from response");
      }

      await _authService.saveAuthData(token, teamId);

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
        print('Login error: $e');
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
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
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
                  // Logo
                  Row(
                    children: [
                      const Icon(
                        Icons.sports_soccer,
                        size: 40,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'MY FC',
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 80),
                  // Team name input
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: '구단 이름을 입력해주세요',
                    ),
                    validator: Validators.validateTeamName,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  // Password input
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      hintText: '구단의 비밀번호를 입력해주세요',
                    ),
                    obscureText: true,
                    validator: Validators.validatePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _login(),
                  ),
                  const SizedBox(height: 32),
                  // Login button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading 
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('우리 구단 페이지로 가기'),
                  ),
                  const SizedBox(height: 16),
                  // Register link
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.registerTeam,
                      ),
                      child: const Text(
                        '우리 구단 입력하기',
                        style: TextStyle(
                          color: Colors.black,
                          decoration: TextDecoration.underline,
                        ),
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