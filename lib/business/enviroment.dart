//library engineu;
import 'enums.dart';

class Enviroment {
  String _companyId = 'ENGINEU';
  String _factoryId = 'ENGINEU';
  String _companyName = '擎宇科技有限公司';
  String _appId = 'EngineUEntire';
  String _appToken = '9198b026-e958-43d5-8370-06fd2cce0120';
  RemoteMethod _remoteMode = RemoteMethod.http;
  String _appRemoteAddress = 'www.engineu.com.tw';
  int _appRemotePort = 1111;
  String _socketAddress = '127.0.0.1';
  int _socketPort = 38001;
  int _imageScale = 100;
  //String _sqlLiteVersion = '1';
  int _httpConnectinoTimeout = 30; //by seconds
  String _deviceType = ''; //Android,IOS
  String _deviceId = '';
  String _deviceName = '';
  String _deviceModel = ''; //Android,iPhone,iPad
  String _deviceVersion = '';
  //===========================
  set setAppRemoteAddress(String value) => _appRemoteAddress = value;
  set setAppRemotePort(int value) => _appRemotePort = value;

  String get companyId => _companyId;
  set setCompanyId(String value) => _companyId = value;

  String get factoryId => _factoryId;
  set setFactoryId(String value) => _factoryId = value;

  String get companyName => _companyName;
  set setCompanyName(String value) => _companyName = value;

  String get appId => _appId;
  set setAppId(String value) => _appId = value;

  set setRemoteMode(RemoteMethod value) => _remoteMode = value;

  set setAppToken(String value) => _appToken = value;
  String get appToken => _appToken;
  // Map<String, String> get appTokenMap => {
  //       'ApplicationId': _appId,
  //       'ApiToken': _appToken,
  //       'CompanyId': _companyId,
  //       'FactoryId': _factoryId,
  //     };
  Map<String, String> get appTokenMap => {
        'ApplicationId': _appId,
        'ApiToken': _appToken,
        'CompanyId': _companyId,
        'FactoryId': _factoryId,
        'ImageScale': _imageScale.toString(),
      };

  String get remoteUrl {
    if (_remoteMode == RemoteMethod.https)
      return "https://" + _appRemoteAddress + ":" + _appRemotePort.toString();
    else
      return "http://" + _appRemoteAddress + ":" + _appRemotePort.toString();
  }

  String get remoteFileUrl {
    if (_remoteMode == RemoteMethod.https)
      return "https://" +
          _appRemoteAddress +
          ":" +
          _appRemotePort.toString() +
          '/common/' +
          _companyId +
          '/';
    else
      return "http://" +
          _appRemoteAddress +
          ":" +
          _appRemotePort.toString() +
          '/common/' +
          _companyId +
          '/';
  }

  int get imageScale => _imageScale;
  set setImageScale(int value) {
    if (value > 100)
      _imageScale = 100;
    else if (value < 1)
      _imageScale = 1;
    else
      _imageScale = value;
  }

  int get httpConnectionTimeout => _httpConnectinoTimeout;
  set setHttpConnectionTimeout(int timeout) {
    if (timeout < 0)
      _httpConnectinoTimeout = 0;
    else
      _httpConnectinoTimeout = timeout;
  }

  String get socketAddress => _socketAddress;
  int get socketPort => _socketPort;

  String get deviceType => _deviceType;
  set setDeviceType(String value) => _deviceType = value;

  String get deviceId => _deviceId;
  set setDeviceId(String value) => _deviceId = value;

  String get deviceName => _deviceName;
  set setDeviceName(String value) => _deviceName = value;

  String get deviceModel => _deviceModel;
  set setDeviceModel(String value) => _deviceModel = value;

  String get deviceVersion => _deviceVersion;
  set setDeviceVersion(String value) => _deviceVersion = value;
}
