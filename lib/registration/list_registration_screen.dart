import 'package:flutter/material.dart';
import 'package:meeras_fest_app/profile/profileProvider.dart';
import 'package:meeras_fest_app/registration/register_provider.dart';
import 'package:provider/provider.dart';

class ListRegistrationScreen extends StatelessWidget {
  const ListRegistrationScreen({super.key});

  static Color _categoryColor(String category) {
    switch (category) {
      case 'Stage':
        return const Color(0xFFFFEDD5);
      case 'Non Stage':
        return const Color(0xFFDBEAFE);
      case 'General':
        return const Color(0xFFDCFCE7);
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  static Color _categoryTextColor(String category) {
    switch (category) {
      case 'Stage':
        return const Color(0xFFC2410C);
      case 'Non Stage':
        return const Color(0xFF1D4ED8);
      case 'General':
        return const Color(0xFF15803D);
      default:
        return Colors.black87;
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamId = context.watch<ProfileProvider>().teamId;
    if (teamId != null) {
      context.read<RegistrationProvider>().loadForTeam(teamId);
    }

    return Scaffold(
      body: Consumer<RegistrationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final registrations = provider.filteredTeamRegistrations;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              const Padding(
                padding: EdgeInsets.only(left: 12.0),
                child: Text("Registrations",
                    style: TextStyle(color: Color(0xff1F2937), fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 12.0),
                child: Text("View and manage your team's entries",
                    style: TextStyle(color: Color(0xff6B7280), fontWeight: FontWeight.w400, fontSize: 12)),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 41,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6),
                  child: ListView.separated(
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final label = provider.filterOptions[index];
                      final selected = provider.selectedFilter == label;
                      return InkWell(
                        onTap: () => provider.setFilter(label),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: selected ? const Color(0xFFFF8E53) : const Color(0xFFE5E7EB),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(9999),
                            gradient: LinearGradient(
                              begin: Alignment.centerRight,
                              end: Alignment.centerLeft,
                              colors: selected
                                  ? const [Color(0xFFFF6B6B), Color(0xFFFF8E53)]
                                  : const [Colors.white, Colors.white],
                            ),
                            boxShadow: selected
                                ? [
                              const BoxShadow(
                                color: Color(0x33FF6B6B),
                                blurRadius: 12,
                                offset: Offset(0, 6),
                              ),
                            ]
                                : [],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Center(
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: selected ? Colors.white : const Color(0xff4B5563),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (context, index) => const SizedBox(width: 6),
                    itemCount: provider.filterOptions.length,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: registrations.isEmpty
                    ? const Center(child: Text('No registrations yet', style: TextStyle(color: Colors.grey)))
                    : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: registrations.length,
                    itemBuilder: (context, index) {
                      final item = registrations[index];
                      final isExpanded = provider.isExpanded(index);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => provider.toggleExpand(index),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item.studentName,
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 4),
                                          Text(item.programName,
                                              style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: _categoryColor(item.programCategory),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(item.programCategory,
                                          style: TextStyle(fontSize: 12, color: _categoryTextColor(item.programCategory))),
                                    ),
                                    const SizedBox(width: 8),
                                    AnimatedRotation(
                                      turns: isExpanded ? .5 : 0,
                                      duration: const Duration(milliseconds: 250),
                                      child: const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 18),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            AnimatedCrossFade(
                              duration: const Duration(milliseconds: 250),
                              crossFadeState:
                              isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                              firstChild: const SizedBox.shrink(),
                              secondChild: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFAFAFA),
                                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text("Student Category",
                                              style: TextStyle(fontSize: 12, color: Colors.grey)),
                                          const SizedBox(height: 4),
                                          Text(item.studentCategory,
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text("Registration ID",
                                              style: TextStyle(fontSize: 12, color: Colors.grey)),
                                          const SizedBox(height: 4),
                                          Text(item.id, style: const TextStyle(fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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