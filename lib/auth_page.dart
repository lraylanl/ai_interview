import 'package:flutter/material.dart';
import 'services/user_service.dart';
import 'main.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLogin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      bool success;
      if (_isLogin) {
        success = await UserService.login(
          _usernameController.text.trim(),
          _passwordController.text,
        );

        if (success) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const MainScreen()),
            );
          }
        } else {
          _showMessage('아이디 또는 비밀번호가 올바르지 않습니다.');
        }
      } else {
        success = await UserService.register(
          _usernameController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );

        if (success) {
          _showMessage('회원가입이 완료되었습니다. 로그인해주세요.');
          setState(() {
            _isLogin = true;
            _passwordController.clear();
            _nameController.clear();
          });
        } else {
          _showMessage('이미 존재하는 아이디입니다.');
        }
      }
    } catch (e) {
      _showMessage('오류가 발생했습니다: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE3F2FD), Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 로고/제목
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.indigo.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.mic_external_on,
                              size: 48,
                              color: Colors.indigo,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isLogin ? '로그인' : '회원가입',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isLogin ? 'AI 면접에 오신 것을 환영합니다' : '새 계정을 만들어보세요',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // 아이디 입력
                          TextFormField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: '아이디',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value?.trim().isEmpty ?? true) {
                                return '아이디를 입력해주세요';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // 비밀번호 입력
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: '비밀번호',
                              prefixIcon: Icon(Icons.lock),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return '비밀번호를 입력해주세요';
                              }
                              if (!_isLogin && (value?.length ?? 0) < 4) {
                                return '비밀번호는 4자 이상이어야 합니다';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // 이름 입력 (회원가입시에만)
                          if (!_isLogin) ...[
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: '이름',
                                prefixIcon: Icon(Icons.badge),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value?.trim().isEmpty ?? true) {
                                  return '이름을 입력해주세요';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                          ] else
                            const SizedBox(height: 24),

                          // 로그인/회원가입 버튼
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleAuth,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : Text(
                                _isLogin ? '로그인' : '회원가입',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 로그인/회원가입 전환
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isLogin = !_isLogin;
                                _passwordController.clear();
                                _nameController.clear();
                              });
                            },
                            child: Text(
                              _isLogin
                                  ? '계정이 없으신가요? 회원가입'
                                  : '이미 계정이 있으신가요? 로그인',
                              style: const TextStyle(color: Colors.indigo),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}