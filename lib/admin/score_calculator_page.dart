import 'package:flutter/material.dart';
import 'package:meeras_fest_app/admin/providers/score_calculator_provider.dart';
import 'package:provider/provider.dart';

import 'adminWidgets.dart';
import 'providers/programProvider.dart';

class ScoreCalculatorPage extends StatelessWidget {
  const ScoreCalculatorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ScoreCalculatorProvider(),
      child: Consumer2<ProgramProvider, ScoreCalculatorProvider>(
        builder: (context, programProvider, calc, child) {
          return Scaffold(
            backgroundColor: const Color(0xFFF3F4F6),
            appBar: AppBar(
              title: const Text('Score Calculator'),
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: calc.reset,
                  tooltip: 'Reset',
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'INPUTS',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField(
                          value: calc.selectedProgram,
                          decoration: InputDecoration(
                            labelText: 'Select Program',
                            prefixIcon: const Icon(Icons.event_note_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: programProvider.programs
                              .map((p) => DropdownMenuItem(value: p, child: Text(p.programName)))
                              .toList(),
                          onChanged: calc.selectProgram,
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: calc.markCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Mark (out of 100)',
                            prefixIcon: const Icon(Icons.edit_note_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<int>(
                          value: calc.position,
                          decoration: InputDecoration(
                            labelText: 'Position',
                            prefixIcon: const Icon(Icons.emoji_events_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('1st')),
                            DropdownMenuItem(value: 2, child: Text('2nd')),
                            DropdownMenuItem(value: 3, child: Text('3rd')),
                            DropdownMenuItem(value: 0, child: Text('No position')),
                          ],
                          onChanged: calc.selectPosition,
                        ),
                        const SizedBox(height: 20),
                        AdminSubmitButton(
                          label: 'Calculate',
                          loading: false,
                          onPressed: calc.selectedProgram == null ? () {} : calc.calculate,
                          color: const Color(0xFF10B981),
                        ),
                      ],
                    ),
                  ),
                  if (calc.hasResult) ...[
                    const SizedBox(height: 16),
                    _ResultCard(calc: calc),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final ScoreCalculatorProvider calc;
  const _ResultCard({required this.calc});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RESULT',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Grade',
                  value: calc.grade ?? '—',
                  icon: Icons.star_rounded,
                  color: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  label: 'Grade Pts',
                  value: '${calc.gradePoints?.toInt() ?? 0}',
                  icon: Icons.workspace_premium_rounded,
                  color: const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  label: 'Position Pts',
                  value: '${calc.positionPoints?.toInt() ?? 0}',
                  icon: Icons.emoji_events_rounded,
                  color: const Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'TOTAL SCORE',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 4),
                Text(
                  '${calc.totalScore.toInt()}',
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }
}