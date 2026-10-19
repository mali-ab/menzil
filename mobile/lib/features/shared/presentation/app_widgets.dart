import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 38});

  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.24),
        child: Image.asset(
          'assets/launcher_icon.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          semanticLabel: 'Menzil',
        ),
      );
}

class AppGradientHeader extends StatelessWidget {
  const AppGradientHeader({super.key, required this.title, required this.subtitle, required this.icon});

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: const Color(0xFFE8F5F1), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFCBE5DC))),
        child: Row(
          children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(color: Color(0xFF134E4A), fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(subtitle, style: const TextStyle(color: Color(0xFF3F625D), fontSize: 14)),
              ]),
            ),
            CircleAvatar(radius: 28, backgroundColor: Colors.white, child: Icon(icon, color: const Color(0xFF0F766E), size: 29)),
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
          _point(const Color(0xFF047857), from),
          Container(margin: const EdgeInsets.only(left: 10), height: 18, width: 2, color: const Color(0xFFCBD5E1)),
          _point(const Color(0xFFF59E0B), to),
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
