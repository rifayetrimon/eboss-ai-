import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eboss_ai/controllers/login_controller.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final LoginController controller = Get.put(LoginController());

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              if (constraints.maxWidth > 600)
                Expanded(
                  child: SafeArea(
                    // SafeArea ensures the background image and content are not under system UI
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/bg.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/logo/logo_white.png',
                            height: 120,
                          ),
                          const Text(
                            'Enhancing your safety through cutting-edge surveillance',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(
                              child: Text(
                                'Log In',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Center(
                              child: Text(
                                'Enter user ID and password to continue',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                            Form(
                              key: controller.formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // User ID Field
                                  const Text(
                                    'User ID',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: controller.userIdController,
                                    decoration: InputDecoration(
                                      hintText: 'Enter your user ID',
                                      prefixIcon: const Icon(
                                        Icons.person_outline,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.3),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter User ID';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  // Password Field
                                  const Text(
                                    'Password',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: controller.passwordController,
                                    obscureText: true,
                                    decoration: InputDecoration(
                                      hintText: 'Enter your password',
                                      prefixIcon: const Icon(
                                        Icons.lock_outline,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.3),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter Password';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  // Remember Me Checkbox
                                  Obx(
                                    () => Row(
                                      children: [
                                        Checkbox(
                                          value: controller.rememberMe.value,
                                          onChanged: (value) {
                                            if (value != null) {
                                              controller.toggleRememberMe(
                                                value,
                                              );
                                            }
                                          },
                                          activeColor:
                                              Colors
                                                  .black, // This makes the box black when checked
                                          checkColor: Colors.white,
                                        ),
                                        const Text('Remember Me'),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 30),

                                  // Login Button
                                  Center(
                                    child: SizedBox(
                                      width: 200.0,
                                      child: ElevatedButton(
                                        onPressed: controller.handleLogin,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color.fromARGB(
                                            255,
                                            0,
                                            0,
                                            0,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'LOGIN',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
