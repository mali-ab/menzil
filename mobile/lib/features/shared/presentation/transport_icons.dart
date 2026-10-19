import 'package:flutter/material.dart';

/// Transport type keys used by the API (`required_transport` / `transport`).
/// Returns the icon that represents the transport type, shown next to the
/// transport label everywhere in the app.
IconData transportIcon(String transport) => switch (transport) {
      'foot' => Icons.directions_walk_rounded,
      'bicycle' => Icons.pedal_bike_rounded,
      'scooter' => Icons.electric_scooter_rounded,
      'car' => Icons.directions_car_rounded,
      'truck' => Icons.local_shipping_rounded,
      _ => Icons.local_shipping_outlined,
    };

String transportLabel(String transport) => switch (transport) {
      'foot' => 'Pyýada',
      'bicycle' => 'Welosiped',
      'scooter' => 'Skuter',
      'car' => 'Awtoulag',
      'truck' => 'Ýük ulagy',
      _ => transport,
    };

/// A small rounded badge with the transport-type icon, used in order cards,
/// courier cards and anywhere the transport type is displayed.
class TransportBadge extends StatelessWidget {
  const TransportBadge({super.key, required this.transport, this.color = const Color(0xFF0F766E), this.bg = const Color(0xFFE8F5F1), this.size = 18});
  final String transport;
  final Color color;
  final Color bg;
  final double size;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: transport,
        child: Container(
          width: size + 16,
          height: size + 16,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular((size + 16) / 2)),
          child: Icon(transportIcon(transport), size: size, color: color),
        ),
      );
}
