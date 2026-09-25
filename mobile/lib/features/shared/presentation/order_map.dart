import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/network/api_client.dart';

class OrderMap extends StatelessWidget {
  const OrderMap({super.key, required this.orders, this.height = 260});

  final List<OrderSummary> orders;
  final double height;

  @override
  Widget build(BuildContext context) {
    const ashgabat = LatLng(37.9601, 58.3261);
    final center = orders.isEmpty
        ? ashgabat
        : LatLng(orders.first.pickupLatitude, orders.first.pickupLongitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: height,
        child: Stack(children: [
          FlutterMap(
            options: MapOptions(initialCenter: center, initialZoom: orders.isEmpty ? 12 : 13),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.menzil.mobile',
              ),
              MarkerLayer(markers: [
                for (final order in orders) ...[
                  _marker(LatLng(order.pickupLatitude, order.pickupLongitude), const Color(0xFF11B981), Icons.inventory_2_rounded),
                  _marker(LatLng(order.deliveryLatitude, order.deliveryLongitude), const Color(0xFF4F46E5), Icons.location_on_rounded),
                ],
              ]),
            ],
          ),
          Positioned(
            top: 12,
            left: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.94), borderRadius: BorderRadius.circular(12)),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                child: Text('Alyş  •  Eltiş', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ),
          ),
          const Positioned(
            bottom: 5,
            right: 7,
            child: Text('© OpenStreetMap contributors', style: TextStyle(fontSize: 9, color: Color(0xFF334155), backgroundColor: Color(0xDFFFFFFF))),
          ),
        ]),
      ),
    );
  }

  Marker _marker(LatLng point, Color color, IconData icon) => Marker(
        point: point,
        width: 46,
        height: 46,
        child: DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 8)]),
          child: Icon(icon, color: Colors.white, size: 21),
        ),
      );
}
