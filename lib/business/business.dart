import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_info/device_info.dart';
import 'enviroment.dart';
import 'transfer.dart';
import 'datagram.dart';
import 'responseresult.dart';
import 'user.dart';
import '../apis/gps.dart';
import 'enums.dart';

class Business {
  static Enviroment _systemEnv = Enviroment();
  static Transfer _transfer = Transfer();
  static User _user = User();
  static Gps _gps;
  //static SocketClient _socket;
  //static BehaviorSubject<String> systemEvent = BehaviorSubject();
  //==========================================================================
  static set setAppRemoteAddress(String value) =>
      _systemEnv.setAppRemoteAddress = value;
  static set setAppRemotePort(int value) => _systemEnv.setAppRemotePort = value;

  static set setRemoteMode(RemoteMethod value) =>
      _systemEnv.setRemoteMode = value;

  static set setAppToken(String value) => _systemEnv.setAppToken = value;

  static String get companyId => _systemEnv.companyId;

  static set setCompanyId(String value) => _systemEnv.setCompanyId = value;

  static String get factoryId => _systemEnv.factoryId;

  static set setFactoryId(String value) => _systemEnv.setFactoryId = value;

  static String get companyName => _systemEnv.companyName;

  static set setCompanyName(String value) => _systemEnv.setCompanyName = value;

  static String get appId => _systemEnv.appId;

  static set setAppId(String value) => _systemEnv.setAppId = value;

  static String get appToken => _systemEnv.appToken;

  static Map<String, String> get appTokenMap => _systemEnv.appTokenMap;

  static int get imageScale => _systemEnv.imageScale;
  static set setImageScale(int value) => _systemEnv.setImageScale = value;

  static String get remoteUrl => _systemEnv.remoteUrl;
  static String get remoteFileUrl => _systemEnv.remoteFileUrl;
  static String get sqlLiteVersion => _transfer.sqlLiteVersion;
  static int get httpConnectionTimeout => _systemEnv.httpConnectionTimeout;
  static set setHttpConnectionTimeout(int timeout) {
    _systemEnv.setHttpConnectionTimeout = timeout;
  }

  //============ Hardware Start
  static double deviceWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double deviceHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static Orientation deviceDirection(BuildContext context) =>
      MediaQuery.of(context).orientation;
  static String get deviceType => _systemEnv.deviceType;
  static String get deviceId => _systemEnv.deviceId;
  static String get deviceName => _systemEnv.deviceName;
  static String get deviceModel => _systemEnv.deviceModel;
  static String get deviceVersion => _systemEnv.deviceVersion;
  //============ Hardware End

  //============ Gps Start
  static String get gpsLatitude => _gps.latitude.toString();
  static String get gpsLongitude => _gps.longitude.toString();
  static String get gpsAccuracy => _gps.accuracy.toString();
  static String get gpsAltitude => _gps.altitude.toString();
  static String get gpsSpeed => _gps.speed.toString();
  static String get gpsSpeedAccuracy => _gps.speedAccuracy.toString();
  //============ Gps End

  //============ User Start
  static String get userId => _user.userId;
  static set setUserId(String value) => _user.setUserId = value;

  static String get userName => _user.userName;
  static set setUserName(String value) => _user.setUserName = value;

  static String get deptId => _user.deptId;
  static set setDeptId(String value) => _user.setDeptId = value;

  static String get deptName => _user.deptName;
  static set setDeptName(String value) => _user.setDeptName = value;

  static String get jobId => _user.jobId;
  static set setJobId(String value) => _user.setJobId = value;

  static String get jobName => _user.jobName;
  static set setJobName(String value) => _user.setJobName = value;

  static String get authorityId => _user.authorityId;
  static set setAuthorityId(String value) => _user.setAuthorityId = value;

  static String get authorityName => _user.authorityName;
  static set setAuthorityName(String value) => _user.setAuthorityName = value;

  static String get email => _user.email;
  static set setEmail(String value) => _user.setEmail = value;
  //============ User End

  static void init(
      {Function socketAccept,
      Function socketClose,
      Function socketError,
      Function socketReceive,
      bool isGpsListener = false}) async {
    // _systemEnv.setDeviceHeight = context;
    // _systemEnv.setDeviceWidth = context;
    //設定畫面可翻轉的方向
    // await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    //==============================================================
    // _gps = Gps();
    // await _gps.init(isGpsListener);
    //==============================================================
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    bool isAndroid = true;
    bool isIos = true;

    // if (Platform.isAndroid == true) {
    //   AndroidDeviceInfo androidInfo =
    //       await deviceInfo.androidInfo.catchError((e) {
    //     isAndroid = false;
    //   });
    //   if (isAndroid == true) {
    //     _systemEnv.setDeviceId = androidInfo.androidId;
    //     _systemEnv.setDeviceModel = 'Android';
    //     _systemEnv.setDeviceName = androidInfo.model;
    //     _systemEnv.setDeviceType = 'Android';
    //     _systemEnv.setDeviceVersion = androidInfo.version.release;
    //     print('Android Infomation ==========');
    //     print('androidId:' +
    //         androidInfo.androidId); //5774016fee93cf62,1ece210e07975a53
    //     print('board:' + androidInfo.board); //unknown,sdm845
    //     print('bootloader:' + androidInfo.bootloader); //unknown,xboot
    //     print('brand:' + androidInfo.brand); //google,Sony
    //     print('device:' + androidInfo.device); //generic_x86,H8296
    //     print('display:' +
    //         androidInfo
    //             .display); //sdk_gphone_x86-userdebug 8.1.0 OSM1.180201.026 5056746 dev-keys,52.0.A.3.202
    //     print('fingerprint:' +
    //         androidInfo
    //             .fingerprint); //google/sdk_gphone_x86/generic_x86:8.1.0/OSM1.180201.026/5056746:userdebug/dev-keys,Sony/H8296/H8296:9/52.0.A.3.202/770997973:user/release-keys
    //     print('hardware:' + androidInfo.hardware); //ranchu,qcom
    //     print('host:' + androidInfo.host); //abfarm324,BuildHost
    //     print('id:' + androidInfo.id); //OSM1.180201.026,52.0.A.3.202
    //     print('isPhysicalDevice:' +
    //         androidInfo.isPhysicalDevice.toString()); //false
    //     print('manufacturer:' + androidInfo.manufacturer); //Google,Sony
    //     print('model:' + androidInfo.model); //Android SDK built for x86,H8296
    //     print('product:' + androidInfo.product); //sdk_gphone_x86,H8296
    //     print('supported32BitAbis:' +
    //         androidInfo.supported32BitAbis
    //             .toString()); //[x86],[armeabi-v7a, armeabi]
    //     print('supported64BitAbis:' +
    //         androidInfo.supported64BitAbis.toString()); //[],[arm64-v8a]
    //     print('supportedAbis:' +
    //         androidInfo.supportedAbis
    //             .toString()); //[x86],[arm64-v8a, armeabi-v7a, armeabi]
    //     print('tags:' + androidInfo.tags); //dev-keys,release-keys
    //     print('type:' + androidInfo.type); //userdebug
    //     print('version.baseOS:' + androidInfo.version.baseOS); //
    //     print('version.codename:' + androidInfo.version.codename); //REL
    //     print(
    //         'version.incremental:' + androidInfo.version.incremental); //5056746
    //     print('version.previewSdkInt:' +
    //         androidInfo.version.previewSdkInt.toString()); //0
    //     print('version.release:' + androidInfo.version.release); //8.1.0,9
    //     print(
    //         'version.sdkInt:' + androidInfo.version.sdkInt.toString()); //27,28
    //     print('version.securityPatch:' +
    //         androidInfo.version.securityPatch); //2018-01-05
    //   }
    // } else if (Platform.isIOS == true) {
    //   IosDeviceInfo iosInfo = await deviceInfo.iosInfo.catchError((e) {
    //     isIos = false;
    //   });
    //   if (isIos == true) {
    //     _systemEnv.setDeviceId = iosInfo.identifierForVendor;
    //     _systemEnv.setDeviceModel = iosInfo.model;
    //     _systemEnv.setDeviceName = iosInfo.name;
    //     _systemEnv.setDeviceType = 'iOS';
    //     _systemEnv.setDeviceVersion = iosInfo.utsname.release;
    //     print('IOS Infomation ==========');
    //     print('identifierForVendor:' +
    //         iosInfo
    //             .identifierForVendor); //EB8A7280-EC38-4DDA-A1F9-C2923D43F7FB,A63D37D8-078B-48C9-80DD-ED3E0F228615
    //     print(
    //         'isPhysicalDevice:' + iosInfo.isPhysicalDevice.toString()); //false
    //     print('localizedModel:' + iosInfo.localizedModel); //iPhone,iPad
    //     print('model:' + iosInfo.model); //iPhone,iPad
    //     print('name:' + iosInfo.name); //iPhone XS Max,iPad Pro (11-inch)
    //     print('systemName:' + iosInfo.systemName); //iOS
    //     print('systemVersion:' + iosInfo.systemVersion); //12.1
    //     print('utsname.machine:' + iosInfo.utsname.machine); //x86_64
    //     print('utsname.nodename:' + iosInfo.utsname.nodename); //MORGE-IMAC
    //     print('utsname.release:' + iosInfo.utsname.release); //18.2.0
    //     print('iosInfo.utsname.sysname:' + iosInfo.utsname.sysname); //Darwin
    //     print('iosInfo.utsname.version:' +
    //         iosInfo.utsname
    //             .version); //Darwin Kernel Version 18.2.0: Thu Dec 20 20:46:53 PST 2018; root:xnu-4903.241.1~1/RELEASE_X86_64
    //   }
    // }

    //==============================================================
    // _socket = SocketClient(
    //     _systemEnv.socketAddress, _systemEnv.socketPort, _systemEnv.appToken,
    //     onAccept: socketAccept,
    //     onClose: socketClose,
    //     onError: socketError,
    //     onReceive: socketReceive);
    // _socket.connect();
  }

  static Future<ResponseResult> send(Datagram datagram) {
    return _transfer.send(datagram);
  }

  static Future<ResponseResult> sendFile(String physicalSubPath, File file,
      {String userId = '',
      String deviceId = '',
      String ref1 = '',
      String ref2 = ''}) {
    return _transfer.sendfile(physicalSubPath, file,
        userId: userId, deviceId: deviceId, ref1: ref1, ref2: ref2);
  }

  static Future<ResponseResult> apiHeartbeatAsync() {
    return _transfer.apiHeartbeatAsync();
  }

  static Future<ResponseResult> apiExecuteDatagram(Datagram datagram,
      {int commandTimeout = 30000}) {
    return _transfer.apiExecuteDatagram(datagram,
        commandTimeout: commandTimeout);
  }

  static Future<ResponseResult> apiExecuteCommandField(
      CommandField commandField,
      {int commandTimeout = 30000,
      TransactionMode transactionMode = TransactionMode.commitAndRollback}) {
    return _transfer.apiExecuteCommandField(commandField,
        commandTimeout: commandTimeout, transactionMode: transactionMode);
  }

  static Future<ResponseResult> apiListFile(FileCmdType fileCmdType,
      {Map<String, String> headers, int commandTimeout = 30000}) {
    return _transfer.apiListFile(fileCmdType,
        headers: headers, commandTimeout: commandTimeout);
  }

  static Future<ResponseResult> apiUploadFile(
      FileCmdType fileCmdType, List<File> files,
      {Map<String, String> headers, int commandTimeout = 30000}) {
    return _transfer.apiUploadFile(fileCmdType, files,
        headers: headers, commandTimeout: commandTimeout);
  }

  static Future<ResponseResult> apiDownloadFile(
      FileCmdType fileCmdType, String filename, String savePath,
      {Map<String, String> headers, int commandTimeout = 30000}) async {
    return ResponseResult(
        item: ResponseResultItem(
            batchId: 0,
            syncId: 0,
            type: ResultType.strings,
            flag: ResultFlag.ng,
            message: '未支援',
            messageCode: "000002",
            data: '未支援'));
    ResponseResult result = await _transfer.apiDownloadFile(
        fileCmdType, filename,
        headers: headers, commandTimeout: commandTimeout);
    if (result.flag == ResultFlag.ok) {
      try {
        File file = File(savePath + '/' + filename);
        file.writeAsBytes(result.getData(), mode: FileMode.write);
        // var raf = file.openSync(mode: FileMode.write);
        // raf.writeFromSync(result.object);
        // await raf.close();
        return ResponseResult(
            item: ResponseResultItem(
                batchId: 0,
                syncId: 0,
                type: ResultType.strings,
                flag: ResultFlag.ok,
                message: '下載完成',
                messageCode: "000001",
                data: '下載完成'));
      } catch (ex) {
        return ResponseResult(
            item: ResponseResultItem(
                batchId: 0,
                syncId: 0,
                type: ResultType.strings,
                flag: ResultFlag.ng,
                message: ex.toString(),
                messageCode: "000002",
                data: ex.toString()));
      }
    } else {
      return ResponseResult(
          item: ResponseResultItem(
              batchId: 0,
              syncId: 0,
              type: ResultType.strings,
              flag: ResultFlag.ng,
              message: '處理失敗',
              messageCode: "000002",
              data: '處理失敗'));
    }
  }

  static Future<ResponseResult> apiDeleteFile(
      FileCmdType fileCmdType, String filename,
      {Map<String, String> headers, int commandTimeout = 30000}) {
    return _transfer.apiDeleteFile(fileCmdType, filename,
        headers: headers, commandTimeout: commandTimeout);
  }

  static Future<ResponseResult> downloadFile(String uri, String savePath,
      {Map<String, dynamic> headers, int commandTimeout = 30000}) {
    return _transfer.downloadFile(uri, savePath,
        headers: headers, commandTimeout: commandTimeout);
  }

  static Future<ResponseResult> downloadFileWithChunks(
      String uri, String savePath,
      {Map<String, dynamic> headers,
      int commandTimeout = 30000,
      ProgressCallback onReceiveProgress}) {
    return _transfer.downloadFileWithChunks(uri, savePath,
        headers: headers,
        commandTimeout: commandTimeout,
        onReceiveProgress: onReceiveProgress);
  }

  static Future<bool> sqlLiteInsert(String command, [List<dynamic> arguments]) {
    return _transfer.sqlLiteInsert(command, arguments);
  }

  static Future<bool> sqlLiteUpdate(String command, [List<dynamic> arguments]) {
    return _transfer.sqlLiteUpdate(command, arguments);
  }

  static Future<bool> sqlLiteDelete(String command, [List<dynamic> arguments]) {
    return _transfer.sqlLiteDelete(command, arguments);
  }

  static Future<ResponseResult> sqlLiteQuery(String command,
      [List<dynamic> arguments]) {
    return _transfer.sqlLiteQuery(command, arguments);
  }

  // static bool sendSocket(SocketPacket packet) {
  //   return _socket.sendPacket(packet);
  // }
}
