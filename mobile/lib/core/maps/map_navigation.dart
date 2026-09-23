import 'package:url_launcher/url_launcher.dart';

abstract final class MapNavigation {
  // OpenStreetMap/OSRM hiç bir gizlin API açarysyz işleýär. Önümçilikde
  // provider sazlamasy arkaly Google ýa-da Ýandex deep-link-i hem saýlanyp bilner.
  static Future<void> openOpenStreetMap({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(
      'https://www.openstreetmap.org/?mlat=$latitude&mlon=$longitude#map=18/$latitude/$longitude',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Kartany açyp bolmady');
    }
  }
}
