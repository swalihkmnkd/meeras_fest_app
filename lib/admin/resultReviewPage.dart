import 'package:flutter/material.dart';
import 'package:meeras_fest_app/admin/providers/resultProvider.dart';
import 'package:provider/provider.dart';

class ResultsReviewPage extends StatelessWidget {
  const ResultsReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ResultsPublishProvider()..fetchPending(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: AppBar(
          title: const Text('Publish Results'),
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            Consumer<ResultsPublishProvider>(
              builder: (context, provider, _) => TextButton(
                onPressed: provider.pendingResults.isEmpty
                    ? null
                    : () async {
                  final error = await provider.publishAll();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error ?? 'All results published')),
                    );
                  }
                },
                child: const Text('Publish All', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
        body: Consumer<ResultsPublishProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.errorMessage != null) {
              return Center(child: Text(provider.errorMessage!));
            }
            final groups = provider.pendingByProgram;
            if (groups.isEmpty) {
              return const Center(
                child: Text('No results waiting to be published.',
                    style: TextStyle(color: Colors.grey)),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                return _ProgramResultsCard(group: groups[index], provider: provider);
              },
            );
          },
        ),
      ),
    );
  }
}

/// One program's card: name once at top, every judged student listed below
/// with an inline score editor, and a single "Publish Program" button that
/// publishes all of them together — never just one row.
class _ProgramResultsCard extends StatelessWidget {
  final ProgramResultsGroup group;
  final ResultsPublishProvider provider;
  const _ProgramResultsCard({required this.group, required this.provider});

  @override
  Widget build(BuildContext context) {
    final publishing = provider.isPublishingProgram(group.programId);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(group.programName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('${group.results.length} student(s)',
                    style: const TextStyle(fontSize: 11, color: Color(0xff6B7280))),
              ),
            ],
          ),
          const Divider(height: 20),
          ...group.results.map((result) => _StudentResultRow(result: result, provider: provider)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: publishing
                  ? null
                  : () async {
                final error = await provider.publishProgram(group.programId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error ?? '${group.programName} results published')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: publishing
                  ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Publish ${group.programName} (${group.results.length})',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentResultRow extends StatelessWidget {
  final PendingResult result;
  final ResultsPublishProvider provider;
  const _StudentResultRow({required this.result, required this.provider});

  @override
  Widget build(BuildContext context) {
    final saving = provider.isSavingEdit(result.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(result.studentName,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (result.isGeneral)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('General',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
                Text('Reg #${result.registerNumber}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text(
                  'Grade ${result.grade}'
                      '${result.rank != null ? ' · Rank ${result.rank}' : ''}'
                      ' · ${result.totalPoint} pts',
                  style: const TextStyle(fontSize: 11, color: Color(0xff6B7280)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 64,
            child: TextField(
              controller: result.scoreController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                isDense: true,
                labelText: 'Score',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => provider.updateScore(result, v),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            height: 38,
            child: OutlinedButton(
              onPressed: saving
                  ? null
                  : () async {
                final error = await provider.saveEdit(result);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error ?? 'Saved')),
                  );
                }
              },
              style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
              child: saving
                  ? const SizedBox(
                  height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save', style: TextStyle(fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }
}