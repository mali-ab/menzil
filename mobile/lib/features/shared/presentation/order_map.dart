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
    final routePoints = [
      for (final order in orders) ...[
        LatLng(order.pickupLatitude, order.pickupLongitude),
        LatLng(order.deliveryLatitude, order.deliveryLongitude),
      ],
    ];
    final center = orders.isEmpty
        ? ashgabat
        : LatLng(orders.first.pickupLatitude, orders.first.pickupLongitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: height,
        child: Stack(children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: orders.isEmpty ? 12 : 13,
              initialCameraFit: routePoints.isEmpty
                  ? null
                  : CameraFit.coordinates(
                      coordinates: routePoints,
                      padding: const EdgeInsets.all(44),
                      maxZoom: 15,
                    ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                tileProvider: NetworkTileProvider(attemptDecodeOfHttpErrorResponses: false),
                userAgentPackageName: 'com.menzil.mobile',
              ),
              if (orders.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    for (var index = 0; index < orders.length; index++)
                      Polyline(
                        points: [
                          LatLng(orders[index].pickupLatitude, orders[index].pickupLongitude),
                          LatLng(orders[index].deliveryLatitude, orders[index].deliveryLongitude),
                        ],
                        strokeWidth: navigationMode ? 6 : 4,
                        color: _routeColor(index),
                        borderColor: Colors.white.withOpacity(0.8),
                        borderStrokeWidth: 2,
                      ),
                  ],
                ),
              MarkerLayer(markers: [
                if (navigationMode && orders.isNotEmpty) _courierMarker(_courierPoint(orders.first)),
                for (final order in orders) ...[
                  _marker(LatLng(order.pickupLatitude, order.pickupLongitude), const Color(0xFF0F766E), Icons.inventory_2_rounded),
                  _marker(LatLng(order.deliveryLatitude, order.deliveryLongitude), const Color(0xFFF59E0B), Icons.location_on_rounded),
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

  Color _routeColor(int index) => const [
        Color(0xFF0F766E),
        Color(0xFF4F46E5),
        Color(0xFFDB6B2F),
        Color(0xFF2563EB),
        Color(0xFF9333EA),
      ][index % 5];

  LatLng _courierPoint(OrderSummary order) => LatLng(order.pickupLatitude + (order.deliveryLatitude - order.pickupLatitude) * .32, order.pickupLongitude + (order.deliveryLongitude - order.pickupLongitude) * .32);

  Marker _courierMarker(LatLng point) => Marker(
    point: point, width: 64, height: 64,
    child: Stack(alignment: Alignment.center, children: [
      Container(width: 60, height: 60, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0x6614B8A6), width: 2))),
      DecoratedBox(decoration: const BoxDecoration(color: Color(0xFFE8F5F1), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0x220F766E), blurRadius: 12)]), child: const SizedBox(width: 42, height: 42, child: Icon(Icons.directions_car_filled_rounded, color: Color(0xFF0F766E), size: 23))),
    ]),
  );
}
