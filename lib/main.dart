//import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission/permission.dart';
import 'package:car_1/business/business.dart';
import 'package:car_1/business/enums.dart';

import 'sysLogin.dart';
import 'sysMain.dart';
import 'module/TVS0100016.dart';
import 'module/TVS0100017.dart';
import 'module/TVS0100018.dart';
import 'module/TVS0100001.dart';
import 'module/TVS0100002.dart';
import 'module/TVS0100003.dart';
import 'module/TVS0100004.dart';
import 'module/TVS0100005.dart';
import 'module/TVS0100006.dart';
import 'module/TVS0100007.dart';
import 'module/TVS0100008.dart';
//import 'module/TVS0100009.dart';
import 'module/TVS0100010.dart';
//import 'module/TVS0100011.dart';
import 'module/TVS0100012.dart';
//import 'module/TVS0100013.dart';
import 'module/TVS0100014.dart';
//import 'module/TVS0100015.dart';
//import 'module/TVS0109999.dart';
import 'module/TVS0100019.dart';
import 'module/TVS0100020.dart';
import 'module/TVS0100021.dart';
import 'module/TVS0100022.dart';
import 'module/TVS0100023.dart';
import 'module/TVS0100024.dart';
import 'module/TVS0100025.dart';
import 'module/TVS0200001.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MyApp();
  }
}

class _MyApp extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    print(Business.deviceId);
    Business.setCompanyId = '公司代碼';
    Business.setFactoryId = '廠區代碼';
    Business.setCompanyName = '公司全名';
    Business.setAppId = 'EngineUEntire';
    Business.setAppToken = '6F261CDC-A742-4E05-B13F-61208CC7E69C'; //連公司
    Business.setAppRemoteAddress = '192.168.1.201'; //連公司
    Business.setAppRemotePort = 1114; //連公司
    Business.setRemoteMode = RemoteMethod.http;
    Business.setHttpConnectionTimeout = 600;
    Business.init();
    _requestPermission();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.blue,
        accentColor: Colors.blueAccent,
      ),
      home: null,
      /* 路由表 */
      routes: {
        '/': (BuildContext context) => SysLogin(),
        '/main': (BuildContext context) => SysMain(),
        '/TVS0100001': (BuildContext context) => TVS0100001(), //卸船入儲作業
        '/TVS0100002': (BuildContext context) => TVS0100002(), //卸船作業
        '/TVS0100003': (BuildContext context) => TVS0100003(), //盤點找車作業
        '/TVS0100004': (BuildContext context) => TVS0100004(), //車輛查詢
        '/TVS0100005': (BuildContext context) => TVS0100005(), //配件點檢作業
        '/TVS0100006': (BuildContext context) => TVS0100006(), //加油作業
        '/TVS0100007': (BuildContext context) => TVS0100007(), //車輛儲區作業
        '/TVS0100008': (BuildContext context) => TVS0100008(), //生產移車作業
        // '/TVS0100009': (BuildContext context) => TVS0100009(), //存車維護作業
        '/TVS0100010': (BuildContext context) => TVS0100010(), //車輛檢查作業
        // '/TVS0100011': (BuildContext context) => TVS0100011(), //生產刷讀作業
        '/TVS0100012': (BuildContext context) => TVS0100012(), //配件點檢稽核
        // '/TVS0100013': (BuildContext context) => TVS0100013(), //新車到港作業
        '/TVS0100014': (BuildContext context) => TVS0100014(), //其他加油作業
        // '/TVS0100015': (BuildContext context) => TVS0100015(), //存車維護查詢
        '/TVS0100016': (BuildContext context) => TVS0100016(), //存車維護作業
        '/TVS0100017': (BuildContext context) => TVS0100017(), //存車維護作業
        '/TVS0100018': (BuildContext context) => TVS0100018(), //估價拍照
        '/TVS0100019': (BuildContext context) => TVS0100019(), //拍照上傳測試
        '/TVS0100020': (BuildContext context) => TVS0100020(), //RETROFIT 作業
        '/TVS0100021': (BuildContext context) => TVS0100021(), //整二-PDI 作業
        '/TVS0100022': (BuildContext context) => TVS0100022(), //整二-PDI 終檢確認
        '/TVS0100023': (BuildContext context) => TVS0100023(), //整二-PDI 維修
        '/TVS0100024': (BuildContext context) => TVS0100024(), //存車維護
        '/TVS0100025': (BuildContext context) => TVS0100025(), //底塗作業
        // '/GeneralWidget_test':(BuildContext context) => FunctionMenu_TVS0100006(),
        '/TVS0200001': (BuildContext context) => TVS0200001(),
      },
      /* 路由表(帶參數) */
      onGenerateRoute: (RouteSettings settings) {
        return null;
      },
      /* 路由失敗時 */
      onUnknownRoute: (RouteSettings settings) {
        return null;
      },
    );
  }

  void _requestPermission() async {
    if (Platform.isAndroid == true) {
      await Permission.requestPermissions([
        PermissionName.Camera,
        PermissionName.Location,
        PermissionName.Microphone,
        PermissionName.Storage,
      ]);
    } else if (Platform.isIOS == true) {
      await Permission.requestPermissions([
        PermissionName.Camera,
        PermissionName.Location,
        PermissionName.Microphone,
      ]);
    }
  }
}
