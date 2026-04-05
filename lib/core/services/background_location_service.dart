import 'dart:async';
import 'dart:convert';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const int _sendIntervalSeconds = 30;
const int _eventIntervalMs = 30000;
const int _serviceId = 512;

/// Entry point for the foreground task isolate
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
}

/// Handles periodic location sending in the background isolate.
class LocationTaskHandler extends TaskHandler {
  Timer? _timer;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _timer = Timer.periodic(
      const Duration(seconds: _sendIntervalSeconds),
      (_) => _sendLocation(),
    );
    // Send immediately on start
    await _sendLocation();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    _sendLocation();
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isDestroyed) async {
    _timer?.cancel();
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'stop') {
      FlutterForegroundTask.stopService();
    }
  }

  Future<void> _sendLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tokenStr = prefs.getString('auth_token');
    final int? personalId = prefs.getInt('employee_id');
    final String serverUrl =
        prefs.getString('server_url') ?? 'http://192.168.1.100:8000';

    if (tokenStr == null || personalId == null) return;

    // Read selected vehicle info
    final int? vehiculoId = prefs.getInt('selected_vehicle_id');

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $tokenStr',
    };
    final url =
        Uri.parse('$serverUrl/api/seguridad-ciudadana/personal-ubicacion');

    // --- Sync offline pending locations ---
    final offlineStr = prefs.getString('sc_offline_locations');
    List<dynamic> offlineLocations = [];
    if (offlineStr != null) {
      offlineLocations = jsonDecode(offlineStr);
    }

    for (int i = 0; i < offlineLocations.length; i++) {
      try {
        final res = await http
            .post(url,
                headers: headers, body: jsonEncode(offlineLocations[i]))
            .timeout(const Duration(seconds: 10));
        if (res.statusCode == 200 || res.statusCode == 201) {
          offlineLocations.removeAt(i);
          i--;
        }
      } catch (_) {}
    }
    await prefs.setString(
        'sc_offline_locations', jsonEncode(offlineLocations));

    // --- Send current location ---
    Map<String, dynamic>? currentBody;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      // Determine tipo_ubicacion based on vehicle context
      String tipoUbicacion = 'personal';
      if (vehiculoId != null) {
        tipoUbicacion = 'vehiculo';
      }

      currentBody = {
        'id_personal': personalId,
        'latitud': position.latitude,
        'longitud': position.longitude,
        'tipo_ubicacion': tipoUbicacion,
        'vehiculo_id': vehiculoId,
      };

      final response = await http
          .post(url, headers: headers, body: jsonEncode(currentBody))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        FlutterForegroundTask.updateService(
          notificationTitle: 'Rastreo activo',
          notificationText:
              'Última ubicación: ${DateTime.now().toString().split('.')[0].split(' ')[1]}',
        );
        // Notify UI that location was sent
        FlutterForegroundTask.sendDataToMain({'event': 'location_sent', 'time': DateTime.now().toIso8601String()});
      } else {
        FlutterForegroundTask.updateService(
          notificationTitle: 'Rastreo: error',
          notificationText: 'Error del servidor: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (currentBody != null) {
        offlineLocations.add(currentBody);
        await prefs.setString(
            'sc_offline_locations', jsonEncode(offlineLocations));
      }

      FlutterForegroundTask.updateService(
        notificationTitle: 'Rastreo: sin conexión',
        notificationText:
            'Sin conexión. En cola: ${offlineLocations.length}',
      );
    }
  }
}

/// Background Location Service management
class BackgroundLocationService {
  static Future<void> initializeService() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'sc_location_tracking',
        channelName: 'Rastreo de ubicación',
        channelDescription:
            'Notificaciones del servicio de rastreo de ubicación',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(_eventIntervalMs),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<bool> startService() async {
    try {
      final isRunning = await FlutterForegroundTask.isRunningService;
      if (isRunning) {
        await FlutterForegroundTask.restartService();
      } else {
        await FlutterForegroundTask.startService(
          serviceId: _serviceId,
          notificationTitle: 'Rastreo activo',
          notificationText: 'Enviando ubicación en segundo plano...',
          notificationIcon: null,
          notificationButtons: [
            const NotificationButton(id: 'stop', text: 'Detener'),
          ],
          callback: startCallback,
        );
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> stopService() async {
    try {
      await FlutterForegroundTask.stopService();
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> get isRunning async {
    return await FlutterForegroundTask.isRunningService;
  }
}
