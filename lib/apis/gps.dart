import 'dart:async';
//import 'package:location/location.dart';
import 'package:flutter/services.dart';

class Gps {
  bool _permission = false;
  String _permissionMessage = '尚未初始化';
  Map<String, double> _currentLocation;
  StreamSubscription<Map<String, double>> _locationListener;
  //Location _location = Location();

  String get message {
    return _permissionMessage;
  }

  Map<String, double> get location {
    return _currentLocation;
  }
  //緯度
  double get latitude {
    if (_currentLocation == null)
      return 0;
    else if (_currentLocation.containsKey('latitude') == false)
      return 0;
    else {
      return _currentLocation['latitude'];
    }
  }
  //經度
  double get longitude {
    if (_currentLocation == null)
      return 0;
    else if (_currentLocation.containsKey('longitude') == false)
      return 0;
    else {
      return _currentLocation['longitude'];
    }
  }
  //準確性
  double get accuracy {
    if (_currentLocation == null)
      return 0;
    else if (_currentLocation.containsKey('accuracy') == false)
      return 0;
    else {
      return _currentLocation['accuracy'];
    }
  }
  //高度
  double get altitude {
    if (_currentLocation == null)
      return 0;
    else if (_currentLocation.containsKey('altitude') == false)
      return 0;
    else {
      return _currentLocation['altitude'];
    }
  }
  //速度
  double get speed {
    if (_currentLocation == null)
      return 0;
    else if (_currentLocation.containsKey('speed') == false)
      return 0;
    else {
      return _currentLocation['speed'];
    }
  }
  //速度準確性
  double get speedAccuracy {
    if (_currentLocation == null)
      return 0;
    else if (_currentLocation.containsKey('speed_accuracy') == false)
      return 0;
    else {
      return _currentLocation['speed_accuracy'];
    }
  }

  Future<void> init(bool isListener) async {
    return false;
    // try {
    //   _permission = await _location.hasPermission();
    //   _currentLocation = await _location.getLocation();
    //   _permissionMessage = '';

    //   if (_permission == true && isListener == true) {
    //     _locationListener =
    //         _location.onLocationChanged().listen((Map<String, double> result) {
    //       _currentLocation = result;
    //     });
    //   }
    //   _permissionMessage = '完成';
    // } on PlatformException catch (e) {
    //   if (e.code == 'PERMISSION_DENIED') {
    //     _permissionMessage = '權限不足 PERMISSION_DENIED';
    //   } else if (e.code == 'PERMISSION_DENIED_NEVER_ASK') {
    //     _permissionMessage = '權限不足 - 請提供GPS定位權限 PERMISSION_DENIED_NEVER_ASK';
    //   } else {
    //     _permissionMessage = '權限不足 OTHER_DENIED';
    //   }
    //   _currentLocation = null;
    // } on Exception catch (_) {
    //   _permissionMessage = '權限不足';
    //   _currentLocation = null;
    // }
  }
}
