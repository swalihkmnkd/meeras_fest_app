import 'package:flutter/material.dart';
import 'package:meeras_fest_app/admin/providers/curosel_provider.dart';
import 'package:meeras_fest_app/admin/providers/resultProvider.dart';
import 'package:meeras_fest_app/admin/registration_setting_page.dart';
import 'package:meeras_fest_app/admin/resultReviewPage.dart';
import 'package:meeras_fest_app/stage_manager/stageManagerAdminProvider.dart';
import 'package:meeras_fest_app/stage_manager/stageManagerListPage.dart';
import 'package:provider/provider.dart';

import 'adminWidgets.dart';
import 'addStudentPage.dart';
import 'categoryListPage.dart';
import 'curosel_section.dart';
import 'providers/dashBordProvider.dart';
import 'judgesListPage.dart';
import 'programListPage.dart';
import 'teamsListPage.dart';

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DashboardProvider()..fetchCounts()),
        ChangeNotifierProvider(create: (_) => CarouselProvider()),
        ChangeNotifierProvider(create: (_) => ResultsPublishProvider()..fetchPending()),
        // ⬅️ NEW: kept self-contained (own fetch, own count) rather than
        // wired into DashboardProvider, so this card doesn't require
        // touching that file too.
        ChangeNotifierProvider(create: (_) => StageManagerAdminProvider()..fetchAll()),
        // ⬅️ NEW: same pattern — Stage Manager card gets its own provider
        // instance here just to show a live count; StageManagersListPage
        // fetches its own separate copy when opened.
      ],
      child: const _OverviewView(),
    );
  }
}

class _OverviewView extends StatelessWidget {
  const _OverviewView();

  @override
  Widget build(BuildContext context) {
    return Consumer3<DashboardProvider, ResultsPublishProvider, StageManagerAdminProvider>(
      builder: (context, dashboard, results, stageManagers, child) {
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
                    count: dashboard.studentCount.toString(),
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
                    count: dashboard.programCount.toString(),
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
                    count: dashboard.categoryCount.toString(),
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
                    count: dashboard.judgeCount.toString(),
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
                    count: dashboard.teamCount.toString(),
                    title: "Teams",
                    subtitle: "View & manage",
                    icon: Icons.groups_rounded,
                    color: const Color(0xFF3B82F6),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TeamsListPage()),
                    ),
                  ),
                  AdminActionCard(
                    count: results.pendingResults.length.toString(),
                    title: "Publish Results",
                    subtitle: "Review before publishing",
                    icon: Icons.publish_rounded,
                    color: const Color(0xFF8B5CF6),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ResultsReviewPage()),
                    ),
                  ),
                  // ⬅️ NEW: admin-editable Stage / Non Stage registration caps
                  AdminActionCard(
                    count: '${dashboard.stageRegistrationCount + dashboard.nonStageRegistrationCount}',
                    title: "Registration Limits",
                    subtitle: "Set Stage :${dashboard.stageRegistrationCount} / Non Stage :${dashboard.nonStageRegistrationCount}",
                    icon: Icons.rule_rounded,
                    color: const Color(0xFF0EA5E9),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegistrationSettingsPage()),
                    ),
                  ),
                  // ⬅️ NEW: manage Stage Manager logins (name, username,
                  // password) — add/edit/delete lives on StageManagersListPage.
                  AdminActionCard(
                    count: stageManagers.stageManagers.length.toString(),
                    title: "Stage Manager",
                    subtitle: "Add & manage logins",
                    icon: Icons.record_voice_over_rounded,
                    color: const Color(0xFFDB2777),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StageManagersListPage()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // ---------- Home page carousel manager ----------
              const CarouselSection(),
              const SizedBox(height: 15),

              // Real pending results replacing the old dummy list
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Results Awaiting Publish",
                          style: TextStyle(color: Color(0xff1F2937), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        if (results.pendingResults.isNotEmpty)
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ResultsReviewPage()),
                            ),
                            child: const Text('View All', style: TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (results.isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (results.pendingResults.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          "Nothing waiting to be published.",
                          style: TextStyle(color: Color(0xff9CA3AF), fontSize: 12),
                        ),
                      )
                    else
                      ListView.builder(
                        padding: EdgeInsets.zero,
                        // Preview only the first 5 here; full list lives on
                        // ResultsReviewPage via "View All".
                        itemCount: results.pendingResults.length > 5 ? 5 : results.pendingResults.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final r = results.pendingResults[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(r.studentName,
                                          style: const TextStyle(
                                              color: Color(0xff1F2937), fontWeight: FontWeight.w400, fontSize: 12)),
                                      Text(r.programName,
                                          style: const TextStyle(color: Color(0xff6B7280), fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xffFFEDD5),
                                    borderRadius: BorderRadius.circular(9999),
                                  ),
                                  child: const Text('Resulted',
                                      style: TextStyle(
                                          color: Color(0xffF97316), fontWeight: FontWeight.w400, fontSize: 12)),
                                ),
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

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xff6B7280))),
        ],
      ),
    );
  }
}