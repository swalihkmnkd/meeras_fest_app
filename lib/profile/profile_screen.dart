import 'package:flutter/material.dart';
import 'package:meeras_fest_app/home/home_provider.dart';
import 'package:meeras_fest_app/profile/profileProvider.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _signIn(BuildContext context) async {
    final profPro = context.read<ProfileProvider>();
    final homePro = context.read<HomeProvider>();

    final error = await profPro.login();
    if (error != null) return; // error shown inline via loginError

    homePro.changeBottomIndex(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0x33FF6B6B),
              Color(0xFFFFF9F5),
              Color(0x33667EEA),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [Color(0xFF667EEA), Color(0xffFF6B6B)]),
                  ),
                  child: const Icon(Icons.lock_outline, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Welcome Back",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                ),
                const SizedBox(height: 6),
                const Text("Sign in to access your account", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),

                // Role Selector
                Consumer<ProfileProvider>(
                  builder: (context, profilePro, child) {
                    return Wrap(
                      spacing: 10,
                      children: ["User", "Leader", "Judge", "Admin"].map((role) {
                        final selected = profilePro.selectedRole == role;
                        return InkWell(
                          onTap: () => profilePro.changeRole(role),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(9999),
                              color: selected ? Colors.black : Colors.white,
                              boxShadow: selected
                                  ? [const BoxShadow(color: Colors.grey, blurRadius: 3, offset: Offset(0, 1))]
                                  : [],
                            ),
                            child: Text(
                              role,
                              style: TextStyle(
                                color: selected ? Colors.white : const Color(0xff4B5563),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Email / Username
                Consumer<ProfileProvider>(
                  builder: (context, profPro, child) => TextField(
                    controller: profPro.emailCtrl,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.email_outlined, color: Color(0xff9CA3AF)),
                      hintText: "Username",
                      hintStyle: const TextStyle(color: Color(0xff9CA3AF)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF667EEA), width: 1),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Password
                Consumer<ProfileProvider>(
                  builder: (context, profPro, child) => TextField(
                    controller: profPro.passwordCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline, color: Color(0xff9CA3AF)),
                      hintText: "Password",
                      hintStyle: const TextStyle(color: Color(0xff9CA3AF)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF667EEA), width: 1),
                      ),
                    ),
                  ),
                ),

                // Inline error
                Consumer<ProfileProvider>(
                  builder: (context, profPro, child) {
                    if (profPro.loginError == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        profPro.loginError!,
                        style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Sign In Button
                Consumer<ProfileProvider>(
                  builder: (context, profPro, child) {
                    return Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xffFF6B6B)]),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                        onPressed: profPro.isLoggingIn ? null : () => _signIn(context),
                        child: profPro.isLoggingIn
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                            : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Sign In", style: TextStyle(color: Colors.white)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, color: Colors.white),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: () {},
                  child: const Text("Continue as Guest", style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}