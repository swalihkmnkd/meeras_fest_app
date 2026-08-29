import 'package:flutter/material.dart';
import 'package:meeras_fest_app/registration/register_provider.dart';

/// Full-screen student detail view, opened by tapping a card in the
/// "Student wise" registrations list. Shows the student's photo, name,
/// team name, and chest (registration) number up top, then their
/// programs grouped the same way as the list card — Stage / Non Stage /
/// General — just with more room to breathe.
class StudentDetailScreen extends StatelessWidget {
  final StudentRegistrationGroup group;
  final String teamName;

  const StudentDetailScreen({
    super.key,
    required this.group,
    required this.teamName,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = group.photoUrl != null && group.photoUrl!.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xff1F2937),
            elevation: 0,
            title: Text(
              group.studentName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Column(
                children: [
                  // ---- Photo ----
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xffF3F4F6),
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      image: hasPhoto
                          ? DecorationImage(image: NetworkImage(group.photoUrl!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: !hasPhoto
                        ? Center(
                      child: Text(
                        group.studentName.isNotEmpty ? group.studentName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Color(0xff9CA3AF),
                          fontWeight: FontWeight.bold,
                          fontSize: 48,
                        ),
                      ),
                    )
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // ---- Name ----
                  Text(
                    group.studentName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xff1F2937)),
                  ),
                  const SizedBox(height: 4),

                  // ---- Team name ----
                  if (teamName.isNotEmpty)
                    Text(
                      teamName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Color(0xff6B7280), fontWeight: FontWeight.w500),
                    ),
                  const SizedBox(height: 14),

                  // ---- Chest number + total programs ----
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _InfoPill(
                        icon: Icons.badge_outlined,
                        label: 'Chest No: ${group.registrationNumber}',
                        bg: const Color(0xffEEF2FF),
                        fg: const Color(0xff4338CA),
                      ),
                      _InfoPill(
                        icon: Icons.event_note_outlined,
                        label: '${group.totalPrograms} programs',
                        bg: const Color(0xffF3F4F6),
                        fg: const Color(0xff374151),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (group.stagePrograms.isNotEmpty)
                    _DetailProgramSection(
                      label: 'Stage',
                      programNames: group.stagePrograms.map((r) => r.programName).toList(),
                      bg: const Color(0xFFFFEDD5),
                      fg: const Color(0xFFC2410C),
                    ),
                  if (group.nonStagePrograms.isNotEmpty)
                    _DetailProgramSection(
                      label: 'Non Stage',
                      programNames: group.nonStagePrograms.map((r) => r.programName).toList(),
                      bg: const Color(0xFFDBEAFE),
                      fg: const Color(0xFF1D4ED8),
                    ),
                  if (group.generalPrograms.isNotEmpty)
                    _DetailProgramSection(
                      label: 'General',
                      // ⬅️ General programs shown as tag pills too, but each
                      // one is tagged with the student's chest/registration
                      // id so it's clear which entry it belongs to (General
                      // registrations aren't unique per program otherwise).
                      programNames: group.generalPrograms
                          .map((r) => '${r.programName} · ID ${r.registrationNumber}')
                          .toList(),
                      bg: const Color(0xFFDCFCE7),
                      fg: const Color(0xFF15803D),
                    ),
                  if (group.totalPrograms == 0)
                    const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Center(
                        child: Text('No programs registered yet', style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;

  const _InfoPill({required this.icon, required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }
}

class _DetailProgramSection extends StatelessWidget {
  final String label;
  final List<String> programNames;
  final Color bg;
  final Color fg;

  const _DetailProgramSection({
    required this.label,
    required this.programNames,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: fg, letterSpacing: 0.4),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: programNames
                .map((name) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(name, style: TextStyle(fontSize: 12.5, color: fg, fontWeight: FontWeight.w600)),
            ))
                .toList(),
          ),
        ],
      ),
    );
  }
}