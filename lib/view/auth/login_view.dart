import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../model/auth_request.dart';
import '../../services/auth_service.dart';
import 'package:jwt_decode/jwt_decode.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final storage = GetStorage();

  String message = '';

  void _login() async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    if (username.isEmpty) {
      setState(() {
        message = 'Vui lòng nhập tên đăng nhập!';
      });
      return;
    } else if (password.isEmpty) {
      setState(() {
        message = 'Vui lòng nhập mật khẩu!';
      });
      return;
    }


    final request = AuthRequest(
      username: _usernameController.text.trim(),
      password: _passwordController.text.trim(),
    );

    final response = await _authService.login(request);

    // Sau khi login thành công và nhận được token:
    if (response.token != null) {
      await storage.write('token', response.token!);

      // Giải mã JWT để lấy thông tin người dùng
      Map<String, dynamic> decodedToken = Jwt.parseJwt(response.token!);

      // Lưu các thông tin từ token
      await storage.write('userId', decodedToken['sub']);  // Lưu 'sub' từ token
      await storage.write('role', decodedToken['role']);   // Lưu 'role' từ token

      print("👤 UserID đã lưu: ${storage.read('userId')}");
      print("👤 Role đã lưu: ${storage.read('role')}");

      Get.offAllNamed('/splash');
    } else {
      setState(() {
        message = response.message.isNotEmpty ? response.message : 'Sai thông tin đăng nhập. Vui lòng thử lại!';
      });
    }
  }

  void _goToRegister() {
    Get.toNamed('/register');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.blue[50],
        body: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/img/login.jpg',
                fit: BoxFit.cover,
              ),
              Container(color: Colors.black.withOpacity(0.3)), // phủ lớp đen mờ
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Đăng nhập",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _usernameController,
                          style: const TextStyle(
                            fontFamily: 'Arial', // hoặc 'Roboto'
                            color: Colors.black,
                          ),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.person),
                            hintText: 'Nhập tên đăng nhập',
                            labelText: 'Tên đăng nhập',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          obscuringCharacter: '*',
                          style: const TextStyle(
                            color: Colors.grey, // ✅ đặt màu chữ là đen (bao gồm dấu *)
                          ),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock),
                            hintText: 'Nhập mật khẩu',
                            labelText: 'Mật khẩu',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _login,
                            icon: const Icon(Icons.login),
                            label: const Text("Đăng nhập"),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (message.isNotEmpty)
                          Text(
                            message,
                            style: const TextStyle(color: Colors.red),
                          ),
                        TextButton(
                          onPressed: _goToRegister,
                          child: const Text("Chưa có tài khoản? Đăng ký ngay"),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ]
        )
    );
  }
}
