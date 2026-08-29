import 'package:flutter/material.dart';
import 'package:meeras_fest_app/stage_manager/stageManagerProvider.dart';
import 'package:provider/provider.dart';

/// Shows every registration entered for one program (program name +
/// team name for each row) and lets the Stage Manager assign a unique
/// code letter (A, B, C, ...) to each one. The letter pool is sized to
/// the number of registrations in this program.
class ProgramRegistrationsScreen extends StatelessWidget {
  final String programId;
  final String programName;

  const ProgramRegistrationsScreen({
    super.key,
    required this.programId,
    required this.programName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFFF9F5),
      appBar: AppBar(
        title: Text(programName),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<StageManagerProvider>(
        builder: (context, pro, child) {
          final regs = pro.registrationsForProgram(programId);
          final letters = StageManagerProvider.letterOptions(regs.length);
          final assigned = regs.where((r) => r.isAssigned).length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$assigned / ${regs.length} assigned',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              Expanded(
                child: regs.isEmpty
                    ? const Center(child: Text('No registrations for this program'))
                    : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: regs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final r = regs[i];
                    final taken =
                    pro.takenLetters(programId, exceptRegistrationId: r.id);
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      title: Text('${r.programName} — ${pro.teamName(r.teamId)}'),
                      subtitle: Text('${r.studentName} • ${r.studentCategory}'),
                      trailing: DropdownButton<String>(
                        hint: const Text('Assign'),
                        value: r.codeLetter.isEmpty ? null : r.codeLetter,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Unassigned')),
                          ...letters.map(
                                (l) => DropdownMenuItem(
                              value: l,
                              enabled: !taken.contains(l),
                              child: Text(
                                l,
                                style: TextStyle(
                                  color: taken.contains(l) ? Colors.grey : null,
                                ),
                              ),
                            ),
                          ),
                        ],
                        onChanged: (v) => pro.assignCodeLetter(r, v),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}