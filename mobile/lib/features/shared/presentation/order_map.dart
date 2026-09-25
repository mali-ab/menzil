import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/network/api_client.dart';

class OrderMap extends StatelessWidget {
  const OrderMap({super.key, required this.orders, this.height = 260, this.navigationMode = false});

  final List<OrderSummary> orders;
  final double height;
  final bool navigationMode;

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
                urlTemplate: navigationMode ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png' : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: navigationMode ? const ['a', 'b', 'c', 'd'] : const [],
                userAgentPackageName: 'com.menzil.mobile',
              ),
              if (navigationMode && orders.isNotEmpty) PolylineLayer(polylines: [Polyline(
                points: [LatLng(orders.first.pickupLatitude, orders.first.pickupLongitude), LatLng(orders.first.deliveryLatitude, orders.first.deliveryLongitude)],
                strokeWidth: 6,
                color: const Color(0xFF20E38A),
                borderColor: const Color(0xCC101B32),
                borderStrokeWidth: 2,
              )]),
              MarkerLayer(markers: [
                if (navigationMode && orders.isNotEmpty) _courierMarker(_courierPoint(orders.first)),
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
  LatLng _courierPoint(OrderSummary order) => LatLng(order.pickupLatitude + (order.deliveryLatitude - order.pickupLatitude) * .32, order.pickupLongitude + (order.deliveryLongitude - order.pickupLongitude) * .32);

  Marker _courierMarker(LatLng point) => Marker(
    point: point, width: 64, height: 64,
    child: Stack(alignment: Alignment.center, children: [
      Container(width: 60, height: 60, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0x8820E38A), width: 2))),
      DecoratedBox(decoration: const BoxDecoration(color: Color(0xFF20E38A), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0x99000000), blurRadius: 12)]), child: const SizedBox(width: 42, height: 42, child: Icon(Icons.directions_car_filled_rounded, color: Color(0xFF101B32), size: 23))),
    ]),
  );
}
