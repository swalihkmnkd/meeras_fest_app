import 'package:flutter/material.dart';


class AnimatedBarGraph extends StatefulWidget {
  final List<double> values;
  final double maxValue;
  final double barWidth;

  const AnimatedBarGraph({
    super.key,
    required this.values,
    this.maxValue = 100,
    this.barWidth = 40,
  });

  @override
  State<AnimatedBarGraph> createState() => _AnimatedBarGraphState();
}

class _AnimatedBarGraphState extends State<AnimatedBarGraph> {
  final List<Color> colors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.amber,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(widget.values.length, (index) {
          final value = widget.values[index];

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text("${value.toInt()}"),
              const SizedBox(height: 8),

              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                tween: Tween(begin: 0, end: value),
                builder: (context, animatedValue, child) {
                  return Container(
                    width: widget.barWidth,
                    height:
                    (animatedValue / widget.maxValue) * 150,
                    decoration: BoxDecoration(
                      color: colors[index % colors.length],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                },
              ),

              const SizedBox(height: 8),
              Text("Phonix",style: TextStyle(fontSize: 10,color: Colors.black87),),
            ],
          );
        }),
      ),
    );
  }
}