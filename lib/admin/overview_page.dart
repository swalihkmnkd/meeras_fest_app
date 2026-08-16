import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'adminWidgets.dart';
import 'addStudentPage.dart';
import 'categoryListPage.dart';
import 'providers/dashBordProvider.dart';
import 'judgesListPage.dart';
import 'programListPage.dart';
import 'teamsListPage.dart';

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DashboardProvider()..fetchCounts(),
      child: const _OverviewView(),
    );
  }
}

class _OverviewView extends StatelessWidget {
  const _OverviewView();

  List<Map<String, dynamic>> _status() => [
    {
      "title": 'Approved',
      'name': "John Doe",
      "program": "Water Color",
      'textColor': const Color(0xff22C55E),
      'backColor': const Color(0xffDCFCE7),
    },
    {
      "title": 'Pending',
      'name': "John Doe",
      "program": "Water Color",
      'textColor': const Color(0xffF97316),
      'backColor': const Color(0xffFFEDD5),
    },
    {
      "title": 'Approved',
      'name': "John Doe",
      "program": "Water Color",
      'textColor': const Color(0xff22C55E),
      'backColor': const Color(0xffDCFCE7),
    },
    {
      "title": 'Approved',
      'name': "John Doe",
      "program": "Water Color",
      'textColor': const Color(0xff22C55E),
      'backColor': const Color(0xffDCFCE7),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final status = _status();

    return Consumer<DashboardProvider>(
      builder: (context, dashboard, child) {

        return SizedBox(
          child: Column(
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.25,
                children: [
                  AdminActionCard(
                    count: dashboard.studentCount.toString()??'-',
                    title: "Add Students",
                    subtitle: "Upload via Excel",
                    icon: Icons.school_rounded,
                    color: const Color(0xFF6366F1),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddStudentsPage()),
                    ),
                  ),
                  AdminActionCard(
                    count: dashboard.programCount.toString()??'-',
                    title: "Programs",
                    subtitle: "View & manage",
                    icon: Icons.event_note_rounded,
                    color: const Color(0xFF10B981),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProgramsListPage()),
                    ),
                  ),
                  AdminActionCard(
                    count: dashboard.categoryCount.toString()??'-',
                    title: "Categories",
                    subtitle: "View & manage",
                    icon: Icons.category_rounded,
                    color: const Color(0xFFF59E0B),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CategoryListPage()),
                    ),
                  ),
                  AdminActionCard(
                    count: dashboard.judgeCount.toString()??'-',
                    title: "Judges",
                    subtitle: "View & manage",
                    icon: Icons.gavel_rounded,
                    color: const Color(0xFFEF4444),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const JudgesListPage()),
                    ),
                  ),
                  AdminActionCard(
                    count: dashboard.teamCount.toString()??'-',
                    title: "Teams",
                    subtitle: "View & manage",
                    icon: Icons.groups_rounded,
                    color: const Color(0xFF3B82F6),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TeamsListPage()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Recent Registrations",
                      style: TextStyle(color: Color(0xff1F2937), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 15),
                    ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: status.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(status[index]['name'],
                                      style: const TextStyle(
                                          color: Color(0xff1F2937), fontWeight: FontWeight.w400, fontSize: 12)),
                                  Text(status[index]['program'],
                                      style: const TextStyle(color: Color(0xff6B7280), fontSize: 12)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: status[index]['backColor'],
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: Text(status[index]['title'],
                                    style: TextStyle(
                                        color: status[index]['textColor'], fontWeight: FontWeight.w400, fontSize: 12)),
                              )
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}