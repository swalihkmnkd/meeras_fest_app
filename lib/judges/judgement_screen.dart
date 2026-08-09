import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'judge_provider.dart';

class JudgePanelPage extends StatelessWidget {
  const JudgePanelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => JudgeProvider(),
      child: Consumer<JudgeProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            backgroundColor: const Color(0xffF7F7F7),
            body: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Judge Panel",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "Evaluate assigned performances",
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),

                  // Progress card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Progress",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              "${provider.submittedCount} / ${provider.scores.length} Scored",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xff5667F6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xffE6E6E6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: provider.submittedCount / provider.scores.length,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF667EEA),
                                    Color(0xffFF6B6B),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Expanded(
                    child: ListView.builder(
                      itemCount: provider.scores.length,
                      itemBuilder: (context, index) {
                        final item = provider.scores[index];
                        final bool submitted =
                        item["submitted"];

                        return Container(
                          margin:
                          const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                            BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                    alpha: 0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                      children: [
                                        Text(
                                          item["title"],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight:
                                            FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item["participant"],
                                          style:
                                          const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding:
                                    const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: getCategoryColor(
                                          item["category"]),
                                      borderRadius:
                                      BorderRadius.circular(
                                          20),
                                    ),
                                    child: Text(
                                      item["category"],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                        getCategoryTextColor(
                                            item["category"]),
                                        fontWeight:
                                        FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              submitted
                                  ? Container(
                                padding:
                                const EdgeInsets.all(
                                    14),
                                decoration: BoxDecoration(
                                  color: const Color(
                                      0xffE8F5EC),
                                  borderRadius:
                                  BorderRadius
                                      .circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Color(
                                          0xff2E7D32),
                                      size: 20,
                                    ),
                                    const SizedBox(
                                        width: 8),
                                    const Expanded(
                                      child: Text(
                                        "Score Submitted",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(
                                              0xff2E7D32),
                                          fontWeight:
                                          FontWeight
                                              .w600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      "${item["score"]} / 100",
                                      style:
                                      const TextStyle(
                                        fontSize: 12,
                                        color: Color(
                                            0xff2E7D32),
                                        fontWeight:
                                        FontWeight
                                            .bold,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                                  : Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xffF3F3F3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        _scoreButton(
                                          icon: Icons.remove,
                                          onTap: () => provider.decreaseScore(index),
                                        ),

                                        const SizedBox(width: 10),

                                        Expanded(
                                          child: Column(
                                            children: [
                                              SizedBox(
                                                width: 70,
                                                child: TextField(
                                                  controller: item["controller"],
                                                  keyboardType: TextInputType.number,
                                                  textAlign: TextAlign.center,
                                                  decoration: const InputDecoration(
                                                    border: InputBorder.none,
                                                    isDense: true,
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xff6B7280),
                                                  ),
                                                  onChanged: (value) {
                                                    if (value.isEmpty) {
                                                      provider.updateScore(index, 0);
                                                      return;
                                                    }

                                                    int score = int.tryParse(value) ?? 0;

                                                    if (score > 100) score = 100;
                                                    if (score < 0) score = 0;

                                                    provider.updateScore(index, score);
                                                  },
                                                ),
                                              ),
                                              const Text(
                                                "Marks",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xff9CA3AF),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        const SizedBox(width: 10),

                                        _scoreButton(
                                          icon: Icons.add,
                                          onTap: () => provider.increaseScore(index),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(
                                      height: 12),
                                  SizedBox(
                                    width:
                                    double.infinity,
                                    child: ElevatedButton(
                                      onPressed: item[
                                      "score"] >=
                                          1
                                          ? () =>
                                          provider
                                              .submitScore(
                                              index)
                                          : null,
                                      style:
                                      ElevatedButton
                                          .styleFrom(
                                        backgroundColor:
                                        const Color(
                                            0xff0B132B),
                                        disabledBackgroundColor:
                                        const Color(
                                            0xffB0B7C3),
                                        foregroundColor:
                                        Colors.white,
                                        shape:
                                        RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius
                                              .circular(
                                              12),
                                        ),
                                        padding:
                                        const EdgeInsets
                                            .symmetric(
                                            vertical:
                                            14),
                                      ),
                                      child: const Text(
                                        "Submit Score",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight:
                                          FontWeight
                                              .w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

Widget _scoreButton({
  required IconData icon,
  required VoidCallback onTap,
}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: IconButton(
      onPressed: onTap,
      icon: Icon(
        size: 18,
        icon,
        color: const Color(0xff6B7280),
      ),
    ),
  );
}

Color getCategoryColor(String category) {
  switch (category.toLowerCase()) {
    case "music":
      return const Color(0xFFE3F2FD);
    case "dance":
      return const Color(0xFFFCE4EC);
    case "drama":
      return const Color(0xFFEDE7F6);
    case "literary":
      return const Color(0xFFE0F7F4);
    case "art":
      return const Color(0xFFFFF3E0);
    default:
      return const Color(0xFFF5F5F5);
  }
}

Color getCategoryTextColor(String category) {
  switch (category.toLowerCase()) {
    case "music":
      return const Color(0xFF1976D2);
    case "dance":
      return const Color(0xFFD81B60);
    case "drama":
      return const Color(0xFF8E24AA);
    case "literary":
      return const Color(0xFF00897B);
    case "art":
      return const Color(0xFFEF6C00);
    default:
      return Colors.black87;
  }
}