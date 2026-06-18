import 'package:flutter/material.dart';
import 'package:meeras_fest_app/home_provider.dart';
import 'package:meeras_fest_app/profileProvider.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0x33FF6B6B), // 20%
              Color(0xFFFFF9F5), // 100%
              Color(0x33667EEA), // 20%
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
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🔒 Icon
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xffFF6B6B)],
                    ),
                  ),
                  child: const Icon(Icons.lock_outline, color: Colors.white),
                ),

                const SizedBox(height: 16),

                const Text(
                  "Welcome Back",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  "Sign in to access your account",
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 20),

                // 👤 Role Selector
                Wrap(
                  spacing: 10,
                  children: ["User", "Leader", "Judge", "Admin"]
                      .map(
                        (role) => Consumer<ProfileProvider>(
                          builder: (context, profilePro, child) {
                            return
                              InkWell(
                                onTap: (){
                                  profilePro.changeRole(role);
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10,vertical: 5),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(9999),
                                    color: profilePro.selectedRole==role?Colors.black:Colors.white,
                                    boxShadow:profilePro.selectedRole==role? [
                                      BoxShadow(
                                        color: Colors.grey,
                                        blurRadius: 3,
                                        offset: Offset(0, 1),
                                      ),
                                    ]:[],
                                  ),
                                  child: Text(
                                    role,
                                    style: TextStyle(
                                      color:profilePro.selectedRole==role? Colors.white:Color(0xff4B5563),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                              ChoiceChip(
                              label: Text(role),
                              selected: profilePro.selectedRole == role,
                              selectedColor: const Color(0xFF1F2937),
                              labelStyle: TextStyle(
                                color: profilePro.selectedRole == role
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                              onSelected: (_) {
                                profilePro.changeRole(role);
                              },
                            );
                          },
                        ),
                      )
                      .toList(),
                ),

                const SizedBox(height: 20),

                // 📧 Email
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email_outlined,color: Color(0xff9CA3AF),),
                    hintText: "Email Address",
                    hintStyle: TextStyle(color: Color(0xff9CA3AF)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB),width: 0.5),
                    ),
                    enabledBorder:OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB),width: 0.5),
                    ),focusedBorder:OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF667EEA),width: 1),
                  ),
                  ),
                ),

                const SizedBox(height: 12),

                // 🔒 Password
                TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline,color: Color(0xff9CA3AF)),
                    hintText: "Password",
                    hintStyle: TextStyle(color: Color(0xff9CA3AF)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB),width: 0.5),
                    ),
                    enabledBorder:OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB),width: 0.5),
                    ),focusedBorder:OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF667EEA),width: 1),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 🔥 Sign In Button
                Consumer2<ProfileProvider,HomeProvider>(
                  builder: (context,profPro,homePro,child) {
                    return Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xffFF6B6B)],
                        ),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                        onPressed: () {
                          profPro.changeLoginRole(profPro.selectedRole);
                          homePro.changeBottomIndex(0);
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Sign In",style: TextStyle(color: Colors.white),),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward,color: Colors.white,),
                          ],
                        ),
                      ),
                    );
                  }
                ),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: () {},
                  child: const Text(
                    "Continue as Guest",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
