import 'package:flutter/material.dart';

class AppGradientHeader extends StatelessWidget {
  const AppGradientHeader({super.key, required this.title, required this.subtitle, required this.icon});

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xFF101B32), Color(0xFF243C68)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(subtitle, style: const TextStyle(color: Color(0xFFE0E7FF), fontSize: 14)),
              ]),
            ),
            CircleAvatar(radius: 28, backgroundColor: const Color(0xFF20E38A), child: Icon(icon, color: const Color(0xFF101B32), size: 29)),
          ],
        ),
      );
}

class LocationLine extends StatelessWidget {
  const LocationLine({super.key, required this.from, required this.to});
  final String from;
  final String to;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          _point(const Color(0xFF11B981), from),
          Container(margin: const EdgeInsets.only(left: 10), height: 18, width: 2, color: const Color(0xFFCBD5E1)),
          _point(const Color(0xFF4F46E5), to),
        ],
      );

  Widget _point(Color color, String text) => Row(children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Expanded(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis)),
      ]);
}

void showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()), backgroundColor: Colors.red.shade700));
}
