import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'addStudentPage.dart';
import 'providers/adminProvider.dart';
import 'adminWidgets.dart';
import 'analytic_page.dart';
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
              const SizedBox(height: 10),
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
              const SizedBox(height: 20),

              // ---------- Quick actions (3D cards) ----------
              const Text(
                "Quick Actions",
                style: TextStyle(
                  color: Color(0xff1F2937),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 26),

              // ---------- Overview / Analytics tab switch ----------
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Consumer<AdminProvider>(
                    builder: (context, adminPro, child) {
                      return Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => adminPro.changeAnalyticTab(false),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(9),
                                  color: !adminPro.isAnalyticTab
                                      ? const Color(0xff6366F1)
                                      : Colors.transparent,
                                  boxShadow: !adminPro.isAnalyticTab
                                      ? [
                                    BoxShadow(
                                      color: const Color(0xff6366F1).withOpacity(0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                      : [],
                                ),
                                child: Center(
                                  child: Text(
                                    "Overview",
                                    style: TextStyle(
                                      color: !adminPro.isAnalyticTab ? Colors.white : const Color(0xff6B7280),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => adminPro.changeAnalyticTab(true),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(9),
                                  color: adminPro.isAnalyticTab
                                      ? const Color(0xff6366F1)
                                      : Colors.transparent,
                                  boxShadow: adminPro.isAnalyticTab
                                      ? [
                                    BoxShadow(
                                      color: const Color(0xff6366F1).withOpacity(0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                      : [],
                                ),
                                child: Center(
                                  child: Text(
                                    "Analytics",
                                    style: TextStyle(
                                      color: adminPro.isAnalyticTab ? Colors.white : const Color(0xff6B7280),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
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
                ),
              ),
              const SizedBox(height: 16),
              Consumer<AdminProvider>(
                builder: (context, adminPro, child) {
                  if (adminPro.isAnalyticTab) {
                    return const AnalyticPage();
                  }
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