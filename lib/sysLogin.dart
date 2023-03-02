import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:package_info/package_info.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:car_1/business/business.dart';
import 'package:car_1/business/datagram.dart';
import 'package:car_1/business/responseresult.dart';
import 'package:car_1/apis/messagebox.dart';

var flutterLocalNotificationsPlugin;

class SysLogin extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    //flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
    return _SysLogin();
  }
}

class _SysLogin extends State<SysLogin> {
  final String grantCompany = '公司代碼'; //公司代碼
  final String grantHost = 'MISDB2017'; //主機名稱
  final String grantDate = '2099-12-31'; //授權日期
  final String grantSession = '9999'; //連線數
  final String grantDb = '資料庫'; //資料庫

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {
    'userId': null,
    'password': null,
    'new_password': null,
    'confirm_password': null
  };
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _netType = 'I'; //I: Internal   E: External
  int _loginFlag = 1; //1:Login 2:CreateOrModifyPwd
  PackageInfo _packageInfo;
  bool _isinternalTest = false;
  int _isinternalCount = 0; //0 in,1 Out

  @override
  void initState() {
    super.initState();

    Business.setUserId = '';
    Business.setUserName = '';
    Business.setDeptId = '';
    Business.setDeptName = '';
    Business.setJobId = '';
    Business.setJobName = '';
    Business.setEmail = '';
    Business.setAuthorityId = '';
    Business.setAuthorityName = '';
    //_isinternalTest = true; //公司測試,需要則不註解,release給客戶則註解
    _loadLogin();
    _loadPackageInfo();

    //推播初始化
    // var initializationSettingsAndroid =
    //     new AndroidInitializationSettings('app_icon');
    // var initializationSettingsIOS = new IOSInitializationSettings(
    //     onDidReceiveLocalNotification: onDidRecieveLocalNotification);
    // var initializationSettings = new InitializationSettings(
    //     initializationSettingsAndroid, initializationSettingsIOS);
    // flutterLocalNotificationsPlugin.initialize(initializationSettings,
    //     onSelectNotification: onSelectNotification);
    portraitInit();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () async {
          //Navigator.pushReplacementNamed(context, '/index');
        },
        child: Container(
          //decoration: BoxDecoration(image: _buildBackgroundImage()),
          child: Center(
            child: Form(
              key: _formKey,
              child: Container(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _isinternalTest == true
                        ? Container(
                            child: IconButton(
                              icon: Icon(
                                Icons.tag_faces,
                                color: _isinternalCount == 0
                                    ? Colors.redAccent
                                    : Colors.greenAccent,
                              ),
                              onPressed: () async {
                                _internalTest(_isinternalCount);
                              },
                            ),
                          )
                        : Text(
                            '車輛管理系統',
                            style: TextStyle(fontSize: 24),
                          ),
                    //
                    Container(
                      width: Business.deviceWidth(context) * 0.8,
                      child: TextFormField(
                        controller: _userIdController,
                        autovalidate: false,
                        maxLength: 20,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          labelText: '帳號',
                          filled: false,
                        ),
                        //initialValue: _formData['storeId']==null?'': _formData['storeId'].toString(),
                        validator: (String value) {
                          if (value.isEmpty) return '請輸入帳號';
                        },
                        onSaved: (String value) {
                          _formData['userId'] = value;
                        },
                      ),
                    ),
                    //
                    Container(
                      width: Business.deviceWidth(context) * 0.8,
                      child: TextFormField(
                        controller: _passwordController,
                        autovalidate: false,
                        obscureText: true,
                        maxLength: 20,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          labelText: '密碼',
                          filled: false,
                        ),
                        //initialValue: _formData['storeId']==null?'': _formData['storeId'].toString(),
                        validator: (String value) {
                          //if (value.isEmpty) return '請輸入密碼';
                        },
                        onSaved: (String value) {
                          _formData['password'] = value;
                        },
                      ),
                    ),
                    //
                    _loginFlag == 2
                        ? Container(
                            width: Business.deviceWidth(context) * 0.8,
                            child: TextFormField(
                              controller: _newPasswordController,
                              autovalidate: false,
                              obscureText: true,
                              maxLength: 20,
                              keyboardType: TextInputType.text,
                              decoration: InputDecoration(
                                labelText: '新密碼',
                                filled: false,
                              ),
                              //initialValue: _formData['storeId']==null?'': _formData['storeId'].toString(),
                              validator: (String value) {},
                              onSaved: (String value) {
                                _formData['new_password'] = value;
                              },
                            ),
                          )
                        : Container(),
                    //
                    //
                    _loginFlag == 2
                        ? Container(
                            width: Business.deviceWidth(context) * 0.8,
                            child: TextFormField(
                              controller: _confirmPasswordController,
                              autovalidate: false,
                              obscureText: true,
                              maxLength: 20,
                              keyboardType: TextInputType.text,
                              decoration: InputDecoration(
                                labelText: '確認密碼',
                                filled: false,
                              ),
                              //initialValue: _formData['storeId']==null?'': _formData['storeId'].toString(),
                              validator: (String value) {
                                if (_loginFlag == 2) {
                                  if (value.isEmpty) return '請輸入確認密碼';
                                  if (value != _newPasswordController.text)
                                    return '密碼不一致';
                                }
                              },
                              onSaved: (String value) {
                                _formData['new_password'] = value;
                              },
                            ),
                          )
                        : Container(),
                    //
                    Container(
                      width: Business.deviceWidth(context) * 0.8,
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            IconButton(
                              icon: Icon(_loginFlag == 1
                                  ? Icons.supervisor_account
                                  : Icons.supervised_user_circle),
                              onPressed: () async {
                                setState(() {
                                  _loginFlag = (_loginFlag == 1 ? 2 : 1);
                                });
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.bubble_chart),
                              onPressed: () async {
                                setState(() {
                                  _netType = (_netType == 'I' ? 'E' : 'I');
                                });

                                SharedPreferences prefs =
                                    await SharedPreferences.getInstance();
                                prefs.setString('netType', _netType);
                                if (_netType == 'I')
                                  Business.setAppRemoteAddress =
                                      '192.168.1.201';
                                else
                                  Business.setAppRemoteAddress =
                                      '192.168.1.201';
                              },
                            ),
                            Text(_netType == 'I' ? '內網' : '外網'),
                          ]),
                    ),
                    //
                    Container(
                      width: Business.deviceWidth(context) * 0.8,
                      child: RaisedButton(
                        child: Text(
                          _loginFlag == 1 ? '登入' : '變更密碼',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () async {
                          if (_formKey.currentState.validate() == false) return;
                          _formKey.currentState.save();
                          Navigator.pushReplacementNamed(context, '/main');

                          // if (_loginFlag == 2)
                          // //變更密碼
                          // {
                          //   bool success = await _modifyDeviceLoginPassword(
                          //       _formData['userId'].toString(),
                          //       _formData['password'].toString(),
                          //       _formData['new_password'].toString());
                          //   if (success == true) {
                          //     setState(() {
                          //       _loginFlag = 1;
                          //       _passwordController.text = '';
                          //       _newPasswordController.text = '';
                          //       _confirmPasswordController.text = '';
                          //       _formData['password'] = null;
                          //       _formData['new_password'] = null;
                          //       _formData['confirm_password'] = null;
                          //     });
                          //   } else {
                          //     MessageBox.showWarning(context, '', '變更密碼失敗');
                          //   }
                          // } else
                          // //一般登入
                          // {
                          //   Datagram datagram = Datagram();
                          //   CommandField p = CommandField(
                          //       cmdType: CmdType.procedure,
                          //       commandText: 'entirev4.dbo.sys_login');
                          //   p.addParamText('sIXA00400', grantCompany);
                          //   p.addParamText('sIXA00401', _formData['userId']);
                          //   p.addParamText(
                          //       'sIXA00405',
                          //       base64.encode(utf8
                          //           .encode(_formData['password'].toString())));
                          //   p.addParamText('sIX02201', '');
                          //   p.addParamText('sIX02202', '');
                          //   p.addParamText('sIX02203', '');
                          //   p.addParamText('sGRANT_HOST', grantHost);
                          //   p.addParamText('sGRANT_DATE', grantDate);
                          //   p.addParamText(
                          //       'sGRANT_SESSION_COUNT', grantSession);
                          //   p.addParamText('sGRANT_DB', grantDb);
                          //   p.addParam(ParameterField('oPWD_FLAG',
                          //       ParamType.strings, ParamDirection.output));
                          //   p.addParam(ParameterField('oRESULT_FLAG',
                          //       ParamType.strings, ParamDirection.output));
                          //   p.addParam(ParameterField('oRESULT',
                          //       ParamType.strings, ParamDirection.output));
                          //   datagram.addCommand(p);
                          //   ResponseResult result =
                          //       await Business.apiExecuteDatagram(datagram);
                          //   if (result.flag == ResultFlag.ok) {
                          //     bool success = await _setLogin();
                          //     if (success == true)
                          //       Navigator.pushReplacementNamed(
                          //           context, '/main');
                          //   } else {
                          //     MessageBox.showWarning(
                          //         context, '登入失敗', result.getNGMessage());
                          //   }
                          // }
                        },
                      ),
                    ),
                    //=======================================================================================================
                    _packageInfo != null
                        ? Container(
                            child: Text(
                              '公司名稱 ' +
                                  _packageInfo.version +
                                  '.' +
                                  _packageInfo.buildNumber,
                              style:
                                  TextStyle(fontSize: 12.0, color: Colors.grey),
                            ),
                          )
                        : Container()
                    // Container(
                    //     width: Business.deviceWidth(context) * 0.8,
                    //     child: RaisedButton(
                    //         child: Text('_showNotification',
                    //             style: TextStyle(fontWeight: FontWeight.bold)),
                    //         onPressed: () async {
                    //           await _showNotification();
                    //         })),
                    // Container(
                    //     width: Business.deviceWidth(context) * 0.8,
                    //     child: RaisedButton(
                    //         child: Text('_showNotificationWithNoSound',
                    //             style: TextStyle(fontWeight: FontWeight.bold)),
                    //         onPressed: () async {
                    //           await _showNotificationWithNoSound();
                    //         })),
                    // Container(
                    //     width: Business.deviceWidth(context) * 0.8,
                    //     child: RaisedButton(
                    //         child: Text('_showBigPictureNotification',
                    //             style: TextStyle(fontWeight: FontWeight.bold)),
                    //         onPressed: () async {
                    //           await _showBigPictureNotification();
                    //         })),
                    // Container(
                    //     width: Business.deviceWidth(context) * 0.8,
                    //     child: RaisedButton(
                    //         child: Text(
                    //             'BigPictureNotificationHideExpandedLargeIc',
                    //             style: TextStyle(fontWeight: FontWeight.bold)),
                    //         onPressed: () async {
                    //           await _showBigPictureNotificationHideExpandedLargeIcon();
                    //         })),
                    // Container(
                    //     width: Business.deviceWidth(context) * 0.8,
                    //     child: RaisedButton(
                    //         child: Text('_showBigTextNotification',
                    //             style: TextStyle(fontWeight: FontWeight.bold)),
                    //         onPressed: () async {
                    //           await _showBigTextNotification();
                    //         })),
                    // Container(
                    //     width: Business.deviceWidth(context) * 0.8,
                    //     child: RaisedButton(
                    //         child: Text('_showInboxNotification',
                    //             style: TextStyle(fontWeight: FontWeight.bold)),
                    //         onPressed: () async {
                    //           await _showInboxNotification();
                    //         })),
                    // Container(
                    // width: Business.deviceWidth(context) * 0.8,
                    // child: RaisedButton(
                    //     child: Text('_showIndeterminateProgressNotification',
                    //         style: TextStyle(fontWeight: FontWeight.bold)),
                    //     onPressed: () async {
                    //       //await _showGroupedNotifications();
                    //       //await _showOngoingNotification();
                    //       //await _showNotificationWithNoBadge();
                    //       //await _showProgressNotification();
                    //       await _showIndeterminateProgressNotification();
                    //     })),
                    //

                    //=====
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      resizeToAvoidBottomInset: false,
    );
  }

  void portraitInit() async {
    await SystemChrome.setPreferredOrientations([]);
  }

  void portraitUp() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  Future<bool> _modifyDeviceLoginPassword(
      String userId, String oldPassword, String newPassword) async {
    String oldPwd64 = oldPassword == null || oldPassword == ''
        ? ''
        : base64.encode(utf8.encode(oldPassword));
    String newPwd64 = newPassword == null || newPassword == ''
        ? ''
        : base64.encode(utf8.encode(newPassword));

    Datagram datagram = Datagram();
    String sQL = """if(2=2)
                        if exists(select 1 from entirev4.dbo.ifx_a004 where ixa00400 = '$grantCompany' and ixa00401 = '$userId' and isnull(ixa00405_2,'') = '$oldPwd64')
                           begin
                               update entirev4.dbo.ifx_a004 set ixa00405_2 = '$newPwd64'
                               where ixa00400 = '$grantCompany' and ixa00401 = '$userId' and isnull(ixa00405_2,'') = '$oldPwd64'
                           end
                     """;
    datagram.addText(sQL);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      if (result.getString() == '1')
        return true;
      else
        return false;
    } else {
      MessageBox.showWarning(context, '', result.getNGMessage());
      return false;
    }
  }

  void _internalTest(int count) {
    if (_isinternalTest == true) {
      if (_isinternalCount == 0) {
        _userIdController.text = 'user';
        _passwordController.text = 'pass';

        Business.setAppRemoteAddress = '192.168.1.201'; //連公司
        Business.setAppRemotePort = 1114; //連公司

        setState(() {
          _isinternalCount = 1;
        });
      } else {
        SharedPreferences.getInstance().then((prefs) {
          if (prefs.containsKey('userId') == true) {
            String userId = prefs.getString('userId');
            setState(() {
              _userIdController.text = userId;
              _formData['userId'] = userId;
              _formData['password'] = "";
            });
          }
        });
        Business.setAppRemoteAddress = '192.168.1.201'; //連公司
        Business.setAppRemotePort = 1111; //連公司
        setState(() {
          _isinternalCount = 0;
        });
      }
    }
  }

  void _loadLogin() {
    SharedPreferences.getInstance().then((prefs) {
      if (prefs.containsKey('netType') == true)
        _netType = prefs.getString('netType');

      if (_netType == 'I')
        Business.setAppRemoteAddress = '192.168.1.201';
      else
        Business.setAppRemoteAddress = '192.168.1.201';

      if (prefs.containsKey('userId') == true) {
        String userId = prefs.getString('userId');
        setState(() {
          _userIdController.text = userId;
          _formData['userId'] = userId;
          _formData['password'] = "";
        });
      }
    }).whenComplete(() {
      _internalTest(_isinternalCount);
    });
    // Business.sqlLiteQuery("select * from login where id = 0")
    //     .then((ResponseResult result) {
    //   if (result.flag == ResultFlag.ok) {
    //     List<Map<String, dynamic>> data = result.getMap();
    //     if (data.length > 0) {
    //       String userId =
    //           data[0]['userId'] == null ? '' : data[0]['userId'].toString();
    //       print(data[0]['userId'].toString());
    //       setState(() {
    //         _userIdController.text = userId;
    //         _formData['userId'] = userId;
    //         _formData['password'] = "";
    //       });
    //     } else {
    //       _userIdController.text = "";
    //       _formData['userId'] = '';
    //       _formData['password'] = '';
    //     }
    //   }
    // });
  }

  void _loadPackageInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = packageInfo;
    });
  }

  Future<bool> _setLogin() async {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('userId', _formData['userId']);
    });

    Business.setUserId = _formData['userId'];
    Datagram datagram = Datagram();
    datagram.addText("""select ixa00401,
                               ixa00403,
                               ixa00406,
                               ixa00408,
                               ixa00409,
                               ixa00410
                        from entirev4.dbo.ifx_a004 where ixa00400 = '$grantCompany' and ixa00401 = '${_formData['userId']}'
                     """);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      Business.setUserId = data[0]['ixa00401'];
      Business.setUserName = data[0]['ixa00403'];
      Business.setDeptId = data[0]['ixa00408'];
      Business.setDeptName = '';
      Business.setJobId = data[0]['ixa00409'];
      Business.setJobName = '';
      Business.setEmail = data[0]['ixa00410'];
      Business.setAuthorityId = data[0]['ixa00406'];
      Business.setAuthorityName = '';
      return true;
    } else {
      Business.setUserId = '';
      Business.setUserName = '';
      Business.setDeptId = '';
      Business.setDeptName = '';
      Business.setJobId = '';
      Business.setJobName = '';
      Business.setEmail = '';
      Business.setAuthorityId = '';
      Business.setAuthorityName = '';
      MessageBox.showWarning(context, '', result.getNGMessage());
      return false;
    }
    // Business.sqlLiteUpdate(
    //     "update login set userId = ?,lastLoginTime = ? where id = 0", [
    //   _formData['userId'],
    //   DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())
    // ]).then((bool result) {
    //   if (result == true) {
    //     print('set login ok');
    //   } else
    //     print('set login ng');
    // });
  }

  //=========
  Future _showNotification() async {
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        'your channel id',
        'your other channel name',
        'your channel description',
        importance: Importance.Max,
        priority: Priority.High);
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    var platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0, '訂單通知', '我已經收到訂單了。', platformChannelSpecifics,
        payload: '訂單通知');
  }

  Future _cancelNotification() async {
    await flutterLocalNotificationsPlugin.cancel(0);
  }

  /// Schedules a notification that specifies a different icon, sound and vibration pattern
  Future _scheduleNotification() async {
    var scheduledNotificationDateTime =
        new DateTime.now().add(new Duration(seconds: 5));
    var vibrationPattern = new Int64List(4);
    vibrationPattern[0] = 0;
    vibrationPattern[1] = 1000;
    vibrationPattern[2] = 5000;
    vibrationPattern[3] = 2000;

    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        'your other channel id',
        'your other channel name',
        'your other channel description',
        icon: 'secondary_icon',
        sound: 'slow_spring_board',
        largeIcon: 'sample_large_icon',
        largeIconBitmapSource: BitmapSource.Drawable,
        vibrationPattern: vibrationPattern,
        color: const Color.fromARGB(255, 255, 0, 0));
    var iOSPlatformChannelSpecifics =
        new IOSNotificationDetails(sound: "slow_spring_board.aiff");
    var platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.schedule(0, '訂單通知排程', '我已經收到訂單了程排程。',
        scheduledNotificationDateTime, platformChannelSpecifics);
  }

  Future _showNotificationWithNoSound() async {
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        'silent channel id',
        'silent channel name',
        'silent channel description',
        playSound: false,
        styleInformation: new DefaultStyleInformation(true, true));
    var iOSPlatformChannelSpecifics =
        new IOSNotificationDetails(presentSound: false);
    var platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0, '訂單通知靜音', '我已經收到訂單了靜音。', platformChannelSpecifics,
        payload: '訂單通知靜音');
  }

  Future _showBigPictureNotification() async {
    var directory = await getApplicationDocumentsDirectory();
    var largeIconResponse = await http.get('http://via.placeholder.com/48x48');
    var largeIconPath = '${directory.path}/largeIcon';
    var file = new File(largeIconPath);
    await file.writeAsBytes(largeIconResponse.bodyBytes);
    var bigPictureResponse = await http.get(
        'https://www.engineu.com.tw/engineu_shop_client/shop/images/food-2.jpg');
    var bigPicturePath = '${directory.path}/bigPicture';
    file = new File(bigPicturePath);
    await file.writeAsBytes(bigPictureResponse.bodyBytes);
    var bigPictureStyleInformation = new BigPictureStyleInformation(
        bigPicturePath, BitmapSource.FilePath,
        largeIcon: largeIconPath,
        largeIconBitmapSource: BitmapSource.FilePath,
        contentTitle: '美食通知',
        htmlFormatContentTitle: true,
        summaryText: '蚵仔煎特賣',
        htmlFormatSummaryText: true);
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        'big text channel id',
        'big text channel name',
        'big text channel description',
        style: AndroidNotificationStyle.BigPicture,
        styleInformation: bigPictureStyleInformation);
    var platformChannelSpecifics =
        new NotificationDetails(androidPlatformChannelSpecifics, null);
    await flutterLocalNotificationsPlugin.show(
        0, 'big text title', 'silent body', platformChannelSpecifics,
        payload: '美食通知');
  }

  Future _showBigPictureNotificationHideExpandedLargeIcon() async {
    var directory = await getApplicationDocumentsDirectory();
    var largeIconResponse = await http.get('http://via.placeholder.com/48x48');
    var largeIconPath = '${directory.path}/largeIcon';
    var file = new File(largeIconPath);
    await file.writeAsBytes(largeIconResponse.bodyBytes);
    var bigPictureResponse = await http.get(
        'https://www.engineu.com.tw/engineu_shop_client/shop/images/food-2.jpg');
    var bigPicturePath = '${directory.path}/bigPicture';
    file = new File(bigPicturePath);
    await file.writeAsBytes(bigPictureResponse.bodyBytes);
    var bigPictureStyleInformation = new BigPictureStyleInformation(
        bigPicturePath, BitmapSource.FilePath,
        hideExpandedLargeIcon: true,
        contentTitle: '美食通知2',
        htmlFormatContentTitle: true,
        summaryText: '蚵仔煎特賣2',
        htmlFormatSummaryText: true);
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        'big text channel id',
        'big text channel name',
        'big text channel description',
        largeIcon: largeIconPath,
        largeIconBitmapSource: BitmapSource.FilePath,
        style: AndroidNotificationStyle.BigPicture,
        styleInformation: bigPictureStyleInformation);
    var platformChannelSpecifics =
        new NotificationDetails(androidPlatformChannelSpecifics, null);
    await flutterLocalNotificationsPlugin.show(
        0, 'big text title', 'silent body', platformChannelSpecifics,
        payload: '美食通知');
  }

  Future _showBigTextNotification() async {
    var bigTextStyleInformation = new BigTextStyleInformation(
        '這裡面是一堆內容，這裡面是一堆內容，這裡面是一堆內容，這裡面是一堆內容，這裡面是一堆內容，這裡面是一堆內容，這裡面是一堆內容，這裡面是一堆內容，這裡面是一堆內容，這裡面是一堆內容，這裡面是一堆內容，這裡面是一堆內容，這裡面是一堆內容，這裡面是一堆內容，',
        htmlFormatBigText: true,
        contentTitle: '這是標題',
        htmlFormatContentTitle: true,
        summaryText: '什麼鬼',
        htmlFormatSummaryText: true);
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        'big text channel id',
        'big text channel name',
        'big text channel description',
        style: AndroidNotificationStyle.BigText,
        styleInformation: bigTextStyleInformation);
    var platformChannelSpecifics =
        new NotificationDetails(androidPlatformChannelSpecifics, null);
    await flutterLocalNotificationsPlugin.show(
        0, 'big text title', 'silent body', platformChannelSpecifics);
  }

  Future _showInboxNotification() async {
    var lines = new List<String>();
    lines.add('第一列訊息');
    lines.add('第二列訊息');
    var inboxStyleInformation = new InboxStyleInformation(lines,
        htmlFormatLines: true,
        contentTitle: '這是標題',
        htmlFormatContentTitle: true,
        summaryText: '支援 html tag',
        htmlFormatSummaryText: true);
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        'inbox channel id', 'inboxchannel name', 'inbox channel description',
        style: AndroidNotificationStyle.Inbox,
        styleInformation: inboxStyleInformation);
    var platformChannelSpecifics =
        new NotificationDetails(androidPlatformChannelSpecifics, null);
    await flutterLocalNotificationsPlugin.show(
        0, 'inbox title', 'inbox body', platformChannelSpecifics);
  }

  Future _showGroupedNotifications() async {
    var groupKey = 'com.android.example.WORK_EMAIL';
    var groupChannelId = 'grouped channel id';
    var groupChannelName = 'grouped channel name';
    var groupChannelDescription = 'grouped channel description';
    // example based on https://developer.android.com/training/notify-user/group.html
    var firstNotificationAndroidSpecifics = new AndroidNotificationDetails(
        groupChannelId, groupChannelName, groupChannelDescription,
        importance: Importance.Max,
        priority: Priority.High,
        groupKey: groupKey);
    var firstNotificationPlatformSpecifics =
        new NotificationDetails(firstNotificationAndroidSpecifics, null);
    await flutterLocalNotificationsPlugin.show(1, 'Alex Faarborg',
        'You will not believe...', firstNotificationPlatformSpecifics);
    var secondNotificationAndroidSpecifics = new AndroidNotificationDetails(
        groupChannelId, groupChannelName, groupChannelDescription,
        importance: Importance.Max,
        priority: Priority.High,
        groupKey: groupKey);
    var secondNotificationPlatformSpecifics =
        new NotificationDetails(secondNotificationAndroidSpecifics, null);
    await flutterLocalNotificationsPlugin.show(
        2,
        'Jeff Chang',
        'Please join us to celebrate the...',
        secondNotificationPlatformSpecifics);

    // create the summary notification required for older devices that pre-date Android 7.0 (API level 24)
    var lines = new List<String>();
    lines.add('Alex Faarborg  Check this out');
    lines.add('Jeff Chang    Launch Party');
    var inboxStyleInformation = new InboxStyleInformation(lines,
        contentTitle: '2 new messages', summaryText: 'janedoe@example.com');
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        groupChannelId, groupChannelName, groupChannelDescription,
        style: AndroidNotificationStyle.Inbox,
        styleInformation: inboxStyleInformation,
        groupKey: groupKey,
        setAsGroupSummary: true);
    var platformChannelSpecifics =
        new NotificationDetails(androidPlatformChannelSpecifics, null);
    await flutterLocalNotificationsPlugin.show(
        3, 'Attention', 'Two new messages', platformChannelSpecifics);
  }

  Future _cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future onSelectNotification(String payload) async {
    if (payload != null) {
      debugPrint('notification payload: ' + payload);
    }

    await Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => new SecondScreen(payload)),
    );
  }

  Future _showOngoingNotification() async {
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        'your channel id', 'your channel name', 'your channel description',
        importance: Importance.Max,
        priority: Priority.High,
        ongoing: true,
        autoCancel: false);
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    var platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(0, 'ongoing notification title',
        'ongoing notification body', platformChannelSpecifics);
  }

  Future _repeatNotification() async {
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        'repeating channel id',
        'repeating channel name',
        'repeating description');
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    var platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.periodicallyShow(0, 'repeating title',
        'repeating body', RepeatInterval.EveryMinute, platformChannelSpecifics);
  }

  Future _showDailyAtTime() async {
    var time = new Time(10, 0, 0);
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        'repeatDailyAtTime channel id',
        'repeatDailyAtTime channel name',
        'repeatDailyAtTime description');
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    var platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.showDailyAtTime(
        0,
        'show daily title',
        'Daily notification shown at approximately ${_toTwoDigitString(time.hour)}:${_toTwoDigitString(time.minute)}:${_toTwoDigitString(time.second)}',
        time,
        platformChannelSpecifics);
  }

  Future _showWeeklyAtDayAndTime() async {
    var time = new Time(10, 0, 0);
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        'show weekly channel id',
        'show weekly channel name',
        'show weekly description');
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    var platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.showWeeklyAtDayAndTime(
        0,
        'show weekly title',
        'Weekly notification shown on Monday at approximately ${_toTwoDigitString(time.hour)}:${_toTwoDigitString(time.minute)}:${_toTwoDigitString(time.second)}',
        Day.Monday,
        time,
        platformChannelSpecifics);
  }

  Future _showNotificationWithNoBadge() async {
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        'no badge channel', 'no badge name', 'no badge description',
        channelShowBadge: false,
        importance: Importance.Max,
        priority: Priority.High,
        onlyAlertOnce: true);
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    var platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0, 'no badge title', 'no badge body', platformChannelSpecifics,
        payload: 'item x');
  }

  Future _showProgressNotification() async {
    var maxProgress = 5;
    for (var i = 0; i <= maxProgress; i++) {
      await Future.delayed(Duration(seconds: 1), () async {
        var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
            'progress channel',
            'progress channel',
            'progress channel description',
            channelShowBadge: false,
            importance: Importance.Max,
            priority: Priority.High,
            onlyAlertOnce: true,
            showProgress: true,
            maxProgress: maxProgress,
            progress: i);
        var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
        var platformChannelSpecifics = new NotificationDetails(
            androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
        await flutterLocalNotificationsPlugin.show(
            0,
            'progress notification title',
            'progress notification body',
            platformChannelSpecifics,
            payload: 'item x');
      });
    }
  }

  Future _showIndeterminateProgressNotification() async {
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        'indeterminate progress channel',
        'indeterminate progress channel',
        'indeterminate progress channel description',
        channelShowBadge: false,
        importance: Importance.Max,
        priority: Priority.High,
        onlyAlertOnce: true,
        showProgress: true,
        indeterminate: true);
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    var platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0,
        'indeterminate progress notification title',
        'indeterminate progress notification body',
        platformChannelSpecifics,
        payload: 'item x');
  }

  String _toTwoDigitString(int value) {
    return value.toString().padLeft(2, '0');
  }

  Future onDidRecieveLocalNotification(
      int id, String title, String body, String payload) async {
    // display a dialog with the notification details, tap ok to go to another page
    showDialog(
      context: context,
      builder: (BuildContext context) => new CupertinoAlertDialog(
        title: new Text(title),
        content: new Text(body),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: new Text('Ok'),
            onPressed: () async {
              Navigator.of(context, rootNavigator: true).pop();
              await Navigator.push(
                context,
                new MaterialPageRoute(
                  builder: (context) => new SecondScreen(payload),
                ),
              );
            },
          )
        ],
      ),
    );
  }
}

DecorationImage _buildBackgroundImage() {
  return DecorationImage(
    fit: BoxFit.cover,
    colorFilter: ColorFilter.mode(
      Colors.black.withOpacity(1),
      BlendMode.dstATop,
    ),
    image: AssetImage('assets/images/shop_index_background.jpg'),
  );
}

class SecondScreen extends StatefulWidget {
  final String payload;
  SecondScreen(this.payload);
  @override
  State<StatefulWidget> createState() => new SecondScreenState();
}

class SecondScreenState extends State<SecondScreen> {
  String _payload;
  @override
  void initState() {
    super.initState();
    _payload = widget.payload;
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(_payload),
      ),
      body: new Center(
        child: new RaisedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: new Text('返回'),
        ),
      ),
    );
  }
}
