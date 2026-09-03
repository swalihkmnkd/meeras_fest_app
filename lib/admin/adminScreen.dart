import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'addStudentPage.dart';
import 'providers/adminProvider.dart';
import 'adminWidgets.dart';
import 'categoryListPage.dart';
import 'judgesListPage.dart';
import 'overview_page.dart';
import 'programListPage.dart';
import 'teamsListPage.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Admin Panel",
                style: TextStyle(
                  color: Color(0xff1F2937),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "Manage festival operations",
                style: TextStyle(color: Color(0xff6B7280), fontSize: 13),
              ),

              // ---------- Quick actions (3D cards) ----------
              const Text(
                "Quick Actions",
                style: TextStyle(
                  color: Color(0xff1F2937),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Consumer<AdminProvider>(
                builder: (context, adminPro, child) {

                  return const OverviewPage();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}