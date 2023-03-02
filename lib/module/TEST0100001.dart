import 'dart:async';
import 'dart:isolate';
import 'dart:io';
import 'dart:ui';
import 'dart:convert' as convert;

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:car_1/business/enums.dart';
import 'package:car_1/business/datagram.dart';
import 'package:car_1/business/responseresult.dart';
import 'package:car_1/business/business.dart';
import 'package:car_1/business/result.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:uuid/uuid_util.dart';

import 'CameraBox.dart';
import 'GeneralFunction.dart';

class TEST0100001 extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _TEST0100001();
  }
}

class _TEST0100001 extends State<TEST0100001> {
  List<File> _files = List();

  final _images = [
    {
      'name': 'Arches National Park',
      'link':
          'https://upload.wikimedia.org/wikipedia/commons/6/60/The_Organ_at_Arches_National_Park_Utah_Corrected.jpg'
    },
    {
      'name': 'Canyonlands National Park',
      'link':
          'https://upload.wikimedia.org/wikipedia/commons/7/78/Canyonlands_National_Park%E2%80%A6Needles_area_%286294480744%29.jpg'
    },
    {
      'name': 'Death Valley National Park',
      'link':
          'https://upload.wikimedia.org/wikipedia/commons/b/b2/Sand_Dunes_in_Death_Valley_National_Park.jpg'
    },
    {
      'name': 'Gates of the Arctic National Park and Preserve',
      'link':
          'https://upload.wikimedia.org/wikipedia/commons/e/e4/GatesofArctic.jpg'
    }
  ];

  bool _isLoading;
  bool _permissionReady;
  String _localPath;
  ReceivePort _port = ReceivePort();
  String _message = '';
  Timer _timer;
  int _start = 0;
  String _messageHeartBeat = '';
  String _messageHeartSelect = '';
  String _messageUpload = '';
  String _messageDownload = '';
  String _messageSelect1 = '';
  String _messageSelect2 = '';
  Map<String, String> urlHeaders = Map();
  int _upCount = 0;
  int _upCountOK = 0;
  int _upCountNG = 0;
  int _doCount = 0;
  int _doCountOK = 0;
  int _doCountNG = 0;
  int _sendCount1 = 0;
  int _receiveCount1OK = 0;
  int _receiveCount1NG = 0;
  int _sendCount2 = 0;
  int _receiveCount2OK = 0;
  int _receiveCount2NG = 0;
  Uuid uuid = Uuid();

  @override
  void initState() {
    super.initState();
    Business.setAppId = 'EngineUEntire';
    Business.setCompanyId = '公司代碼';
    Business.setFactoryId = '廠區代碼';
    Business.setCompanyName = '公司全名';
    Business.setAppToken = 'B5DD8D4B-B2B0-4614-97A3-0B7474E9B242';
    Business.setRemoteMode = RemoteMethod.http;
    Business.setAppRemoteAddress = '192.168.1.201';
    Business.setAppRemotePort = 1111;

    // _bindBackgroundIsolate();

    // FlutterDownloader.registerCallback(downloadCallback);

    // _prepare();
    urlHeaders.addAll(Business.appTokenMap);
    urlHeaders.addAll({
      'CmdType': 'getimage',
      'ScalePercent': '0',
      'ScaleHeight': '0',
      'ScaleWidth': '0',
    });
  }

  @override
  void dispose() {
    // _unbindBackgroundIsolate();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('測試中'),
      ),
      body: Container(
        child: Column(
          children: <Widget>[
            // Container(
            //   child: Row(
            //     children: <Widget>[
            //       RaisedButton(
            //         child: Text('TakePicture'),
            //         onPressed: () async {
            //           Navigator.push(
            //               context,
            //               MaterialPageRoute(
            //                   builder: (context) => CameraBox(
            //                       'compid', 'TEST0100001', 'winni')));
            //         },
            //       ),
            //       RaisedButton(
            //         child: Text('deletePicture'),
            //         onPressed: () {
            //           CommonMethod.removeFilesOfDir(
            //               context, 'compid/TEST0100001', 'winni');
            //         },
            //       ),
            //       RaisedButton(
            //         child: Text('GetFiles'),
            //         onPressed: () async {
            //           List<File> files = List();
            //           // Directory(dir.path + 'compid' + 'TEST0100001' + 'winni')
            //           //     .list(recursive: true, followLinks: false);
            //           getApplicationDocumentsDirectory().then((Directory dir) {
            //             Directory _appDocDir = dir;
            //             if (Directory(_appDocDir.path +
            //                         '/compid/' +
            //                         'TEST0100001/winni')
            //                     .existsSync() ==
            //                 true) {
            //               Directory(_appDocDir.path +
            //                       '/compid/' +
            //                       'TEST0100001/winni')
            //                   .list(recursive: true, followLinks: false)
            //                   .listen((FileSystemEntity entity) {
            //                 if (entity is Directory) {
            //                 } else {
            //                   File f = File(entity.path);
            //                   files.add(f);
            //                   // fileList.add({
            //                   //   "車身號碼":
            //                   //       path.basename(path.dirname(entity.path)),
            //                   //   "檔案路徑": entity.path,
            //                   // });
            //                 }
            //               }).onDone(() {
            //                 debugPrint('files: ' + files.length.toString());
            //                 for (File item in files) {
            //                   debugPrint(item.path);
            //                 }
            //                 setState(() {
            //                   _files = files;
            //                 });
            //               });
            //             } else {
            //               debugPrint('files: ' + files.length.toString());
            //               setState(() {
            //                 _files = files;
            //               });
            //             }
            //           });
            //         },
            //       ),
            //     ],
            //   ),
            // ),
            Container(
              child: Row(
                children: <Widget>[
                  RaisedButton(
                    child: Text('Clear'),
                    onPressed: () {
                      setState(() {
                        _sendCount1 = 0;
                        _receiveCount1OK = 0;
                        _receiveCount1NG = 0;
                        _sendCount2 = 0;
                        _receiveCount2OK = 0;
                        _receiveCount2NG = 0;
                      });
                    },
                  ),
                  RaisedButton(
                    child: Text('HeartBeat'),
                    onPressed: () async {
                      ResponseResult result =
                          await Business.apiHeartbeatAsync();
                      if (result.flag == ResultFlag.ok) {
                        setState(() {
                          _messageHeartBeat = 'HeartBeat OK';
                        });
                      } else {
                        setState(() {
                          _messageHeartBeat = result.getNGMessage();
                        });
                      }
                    },
                  ),
                  Text('mesHeartBeat: '),
                  SizedBox(
                    width: 5.0,
                  ),
                  Text(_messageHeartBeat),
                ],
              ),
            ),
            Container(
              child: Row(
                children: <Widget>[
                  RaisedButton(
                    child: Text('Select'),
                    onPressed: () async {
                      Datagram datagram = Datagram();
                      datagram.addText(
                          """select top 65535 * from entirev4.dbo.ifx_a002""",
                          rowIndex: 0, rowSize: 65535);
                      String josn = datagram.toJsonStr();
                      debugPrint(josn);
                      ResponseResult result =
                          await Business.apiExecuteDatagram(datagram);
                      if (result.flag == ResultFlag.ok) {
                        // debugPrint('Select OK');
                        // List<Map<String, dynamic>> data = result.getMap();
                        // debugPrint('1:' + data.length.toString());
                        // data.fillRange(1, 10);
                        // for (Map<String, dynamic> item in data) {
                        //   debugPrint(item['IXA00200'].toString() +
                        //       '|' +
                        //       item['IXA00201'].toString() +
                        //       '|' +
                        //       item['IXA00202'].toString() +
                        //       '|' +
                        //       item['IXA00203'].toString() +
                        //       '|' +
                        //       item['IXA00204'].toString());
                        // }
                        setState(() {
                          _messageHeartSelect = 'Select OK';
                        });
                      } else {
                        setState(() {
                          _messageHeartSelect = result.getNGMessage();
                        });
                      }
                    },
                  ),
                  Text('mesSelect: '),
                  Text(_messageHeartSelect),
                ],
              ),
            ),
            Container(
              child: Row(
                children: <Widget>[
                  RaisedButton(
                    child: Text('Procedure'),
                    onPressed: () async {
                      Datagram datagram = Datagram();
                      CommandField p = CommandField(
                          cmdType: CmdType.procedure,
                          commandText: 'entirev4.dbo.sys_login');
                      p.addParamText('sIXA00400', 'test');
                      p.addParamText('sIXA00401', 'test');
                      p.addParamText('sIXA00405', 'test');
                      p.addParamText('sIX02201', '');
                      p.addParamText('sIX02202', '');
                      p.addParamText('sIX02203', '');
                      p.addParamText('sGRANT_HOST', 'test');
                      p.addParamText('sGRANT_DATE', 'test');
                      p.addParamText('sGRANT_SESSION_COUNT', '999');
                      p.addParamText('sGRANT_DB', 'test');
                      p.addParam(ParameterField('oPWD_FLAG', ParamType.strings,
                          ParamDirection.output));
                      p.addParam(ParameterField('oRESULT_FLAG',
                          ParamType.strings, ParamDirection.output));
                      p.addParam(ParameterField(
                          'oRESULT', ParamType.strings, ParamDirection.output));
                      datagram.addCommand(p);
                      // ResponseResult result =
                      //     await Business.apiExecuteDatagram(datagram);
                      ResponseResult result =
                          await Business.apiExecuteCommandField(p);
                      if (result.flag == ResultFlag.ok) {
                        List<Map<String, dynamic>> data = result.getMap();
                      } else {
                        debugPrint(result.getNGMessage());
                      }
                    },
                  ),
                ],
              ),
            ),
            Container(
              child: Row(
                children: <Widget>[
                  RaisedButton(
                    child: Text('ListFile'),
                    onPressed: () async {
                      ResponseResult result = await Business.apiListFile(
                          FileCmdType.file,
                          headers: {'SubPath': '\JM7BN327001248206'});
                      if (result.flag == ResultFlag.ok) {
                        List<Map<String, dynamic>> data = result.getMap();
                        for (Map<String, dynamic> item in data) {
                          debugPrint(item['filename'].toString());
                        }
                      } else {
                        debugPrint(result.getNGMessage());
                      }
                    },
                  ),
                ],
              ),
            ),
            Container(
              child: Row(
                children: <Widget>[
                  RaisedButton(
                    child: Text('DownloadFile'),
                    onPressed: () async {
                      // startTimer();
                      setState(() {
                        _doCount++;
                      });
                      String _extName = '.zip';
                      String _fileName = uuid.v1() + _extName;

                      // String uri = Business.remoteUrl +
                      //     '/OBJECT/XWARE/TAOYUAN' +
                      //     '/JM7BN327001248206' +
                      //     '/' +
                      //     _fileName;
                      String uri = Business.remoteUrl +
                          '/OBJECT/XWARE/TAOYUAN/JM7BN327001248206/D4AA164E81E745578E3D36EFBE415B2E.zip';
                      String _local = '/storage/emulated/0';
                      String savePath = _local + '/Download' + '/' + _fileName;

                      Map<String, dynamic> headers = {
                        'CmdType': 'getfile',
                        'ScalePercent': '0',
                        'ScaleHeight': '0',
                        'ScaleWidth': '0',
                      };

                      ResponseResult result = await Business.downloadFile(
                          uri, savePath,
                          headers: headers);

                      if (result.flag == ResultFlag.ok) {
                        setState(() {
                          _doCountOK++;
                          _messageDownload = 'download OK';
                        });
                      } else {
                        setState(() {
                          _doCountNG++;
                          _messageDownload = result.getNGMessage();
                        });
                      }
                      // _timer.cancel();
                      // setState(() {
                      //   _message = _start.toString() + ' s';
                      //   _start = 0;
                      // });
                    },
                  ),
                  Text('total: '),
                  Text(_doCount.toString()),
                  Text(' OK: '),
                  Text(_doCountOK.toString()),
                  Text(' NG: '),
                  Text(_doCountNG.toString()),
                ],
              ),
            ),
            Container(
              child: Row(
                children: <Widget>[
                  Text(_messageDownload),
                ],
              ),
            ),
            Container(
              child: Row(
                children: <Widget>[
                  RaisedButton(
                    child: Text('UploadFile'),
                    onPressed: () async {
                      setState(() {
                        _upCount++;
                      });
                      List<File> files = List();
                      File bigFile =
                          File('/storage/emulated/0/Download/test.zip');
                      files.add(bigFile);
                      Map<String, String> headersScript = {
                        'ModuleId': 'TEST0100001',
                        'SubPath': 'JM7BN327001248206',
                        'ReceiptType': '',
                        'ReceiptSerial': 'JM7BN327001248206',
                        'ReceiptNo': '',
                        'Tag1': '測試100M',
                        'Tag2': '',
                        'Descryption': '',
                        'UploadUser': 'RUM',
                        'UploadDevice': 'Android',
                      };
                      ResponseResult result = await Business.apiUploadFile(
                          FileCmdType.file, files,
                          headers: headersScript, commandTimeout: 6000000);
                      if (result.flag == ResultFlag.ok) {
                        setState(() {
                          _upCountOK++;
                          _messageUpload = 'upload OK';
                        });
                      } else {
                        setState(() {
                          _upCountNG++;
                          _messageUpload = result.getNGMessage();
                        });
                      }

                      // _timer.cancel();

                      // setState(() {
                      //   _message = _message + _start.toString() + ' s';
                      //   _start = 0;
                      // });
                    },
                  ),
                  Text('total: '),
                  Text(_upCount.toString()),
                  Text(' OK: '),
                  Text(_upCountOK.toString()),
                  Text(' NG: '),
                  Text(_upCountNG.toString()),
                ],
              ),
            ),
            Container(
              child: Row(
                children: <Widget>[
                  Text('mesUpload: ' + _messageUpload),
                ],
              ),
            ),
            Container(
              child: Row(
                children: <Widget>[
                  RaisedButton(
                    child: Text('DeleteFile'),
                    onPressed: () async {
                      Map<String, String> headers = {
                        'SubPath': 'JM7BN327001248206',
                      };

                      ResponseResult result = await Business.apiDeleteFile(
                          FileCmdType.file,
                          '09587FEDFB9D40C7A58DBB5967D775EB.jpg',
                          headers: headers);

                      if (result.flag == ResultFlag.ok) {
                        debugPrint(result.getString());
                        setState(() {
                          _message = result.getString();
                        });
                      } else {
                        debugPrint(result.getString());
                        setState(() {
                          _message = result.getString();
                        });
                      }
                    },
                  ),
                  RaisedButton(
                    child: Text('UploadBuffer50'),
                    onPressed: () async {
                      // if (_files.length == 0) return;
                      // for (File item in _files) {
                      //   debugPrint(item.path);
                      // }
                      debugPrint('startTime');
                      startTimer();
                      // File bigFile = File(
                      //     '/storage/emulated/0/Download/learning_android_studio.pdf');
                      List<File> files = List();
                      File bigFile =
                          File('/storage/emulated/0/Download/Buffer50.zip');
                      // File bigFile = File(
                      //     '/storage/emulated/0/Download/IMG_20191029_184924.jpg');
                      // File bigFile =
                      //     File('/storage/emulated/0/Download/BigBuckBunny.mp4');
                      files.add(bigFile);

                      // Map<String, String> headersFile = {
                      //   'ModuleId': 'TEST0100001',
                      //   'SubPath': 'JM7BN327001248206',
                      //   'ReceiptType': '',
                      //   'ReceiptSerial': 'JM7BN327001248206',
                      //   'ReceiptNo': '',
                      //   'Tag1': '測試100M',
                      //   'Tag2': '',
                      //   'Descryption': '',
                      //   'UploadUser': 'RUM',
                      //   'UploadDevice': 'Android',
                      // };
                      Map<String, String> headersScript = {
                        'ModuleId': 'TEST0100001',
                        'SubPath': '',
                        'ReceiptType': '',
                        'ReceiptSerial': 'JM7BN327001248206',
                        'ReceiptNo': '',
                        'Tag1': '測試100M',
                        'Tag2': '',
                        'Descryption': '',
                        'UploadUser': 'RUM',
                        'UploadDevice': 'Android',
                      };
                      ResponseResult result = await Business.apiUploadFile(
                          FileCmdType.script, files,
                          headers: headersScript, commandTimeout: 6000000);
                      if (result.flag == ResultFlag.ok) {
                        debugPrint(result.getOKMessage());
                        setState(() {
                          _message = result.getOKMessage();
                        });
                      } else {
                        debugPrint(result.getNGMessage());
                        setState(() {
                          _message = result.getNGMessage();
                        });
                      }

                      _timer.cancel();

                      setState(() {
                        _message = _message + _start.toString() + ' s';
                        _start = 0;
                      });
                    },
                  ),
                  Text('Time: ' + '$_start'),
                ],
              ),
            ),
            Container(
              child: Row(
                children: <Widget>[
                  RaisedButton(
                    child: Text('Select1'),
                    onPressed: () async {
                      setState(() {
                        _sendCount1++;
                      });
                      debugPrint('Select1 start');
                      Datagram datagram = Datagram();
                      datagram.addText(
                          """select top 65535 * from entirev4.dbo.ifx_a002""",
                          rowIndex: 0, rowSize: 65535);
                      // String josn = datagram.toJsonStr();
                      // debugPrint(josn);
                      ResponseResult result = await Business.apiExecuteDatagram(
                          datagram,
                          commandTimeout: 600000);
                      if (result.flag == ResultFlag.ok) {
                        // List<Map<String, dynamic>> data = result.getMap();
                        // debugPrint(data.length.toString());
                        setState(() {
                          _receiveCount1OK++;
                          // _messageSelect1 = result.getOKMessage();
                        });
                      } else {
                        setState(() {
                          _receiveCount1NG++;
                          _messageSelect1 = result.getNGMessage();
                        });
                      }
                      debugPrint('Select1 end');

                      // String url =
                      //     Business.remoteUrl + '/command/method=heartbeat';
                      // Map<String, String> headers = Map();
                      // headers.addAll(Business.appTokenMap);

                      // try {
                      //   var response = await http.get(url);
                      //   if (response.statusCode == 200) {
                      //     debugPrint("Number of books about http: OK");
                      //   } else {
                      //     debugPrint(
                      //         "Request failed with status: ${response.statusCode}.");
                      //   }
                      // } catch (e) {
                      //   debugPrint(e.toString());
                      // }
                    },
                  ),
                  SizedBox(
                    width: 10.0,
                  ),
                  Text('send1: ' + _sendCount1.toString()),
                  SizedBox(
                    width: 10.0,
                  ),
                  Text('receive1OK: ' + _receiveCount1OK.toString()),
                  SizedBox(
                    width: 10.0,
                  ),
                  Text('receive1NG: ' + _receiveCount1NG.toString()),
                ],
              ),
            ),
            Container(
              child: Text(_messageSelect1),
            ),
            Container(
              child: Row(
                children: <Widget>[
                  RaisedButton(
                    child: Text('Select2'),
                    onPressed: () async {
                      setState(() {
                        _sendCount2++;
                      });
                      debugPrint('Select2 start');
                      Datagram datagram = Datagram();
                      datagram.addText(
                          """select top 65535 * from uprov4.dbo.xprd_aa01""",
                          rowIndex: 0, rowSize: 65535);
                      // String josn = datagram.toJsonStr();
                      // debugPrint(josn);
                      ResponseResult result = await Business.apiExecuteDatagram(
                          datagram,
                          commandTimeout: 600000);
                      if (result.flag == ResultFlag.ok) {
                        // List<Map<String, dynamic>> data = result.getMap();
                        // debugPrint(data.length.toString());
                        setState(() {
                          _receiveCount2OK++;
                          // _messageSelect2 = result.getOKMessage();
                        });
                      } else {
                        setState(() {
                          _receiveCount2NG++;
                          _messageSelect2 = result.getNGMessage();
                        });
                        debugPrint(result.getNGMessage());
                      }
                      debugPrint('Select2 end');
                    },
                  ),
                  SizedBox(
                    width: 10.0,
                  ),
                  Text('send2: ' + _sendCount2.toString()),
                  SizedBox(
                    width: 10.0,
                  ),
                  Text('receive2OK: ' + _receiveCount2OK.toString()),
                  SizedBox(
                    width: 10.0,
                  ),
                  Text('receive2NG: ' + _receiveCount2NG.toString()),
                ],
              ),
            ),
            Container(
              child: Text(_messageSelect2),
            ),
            //Url Show Image
            // Container(
            //   child: Row(
            //     children: <Widget>[
            //       Container(
            //         width: (MediaQuery.of(context).size.width - 15) / 2,
            //         height: 200.0,
            //         child: CachedNetworkImage(
            //           imageUrl: Business.remoteUrl +
            //               '/OBJECT/XWARE/TAOYUAN' +
            //               '/JM7BN327001248206' +
            //               '/24F3AEA937A74CE58A1641AB266D86AC.jpg',
            //           placeholder: (context, url) => CircularProgressIndicator(
            //               valueColor: AlwaysStoppedAnimation(Colors.green)),
            //           errorWidget: (context, url, error) => Icon(Icons.error),
            //           httpHeaders: urlHeaders,
            //         ),
            //       ),
            //       Container(
            //         width: (MediaQuery.of(context).size.width - 15) / 2,
            //         height: 200.0,
            //         child: CachedNetworkImage(
            //           imageUrl: Business.remoteUrl +
            //               '/OBJECT/XWARE/TAOYUAN' +
            //               '/JM7BN327001248206' +
            //               '/2F1F1700C9324C878DBE275887650B85.jpg',
            //           placeholder: (context, url) => CircularProgressIndicator(
            //               valueColor: AlwaysStoppedAnimation(Colors.green)),
            //           errorWidget: (context, url, error) => Icon(Icons.error),
            //           httpHeaders: urlHeaders,
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            //message
            Container(
              child: Text(_message),
            ),
          ],
        ),
      ),
      resizeToAvoidBottomInset: true,
    );
  }

  // void _bindBackgroundIsolate() {
  //   bool isSuccess = IsolateNameServer.registerPortWithName(
  //       _port.sendPort, 'downloader_send_port');
  //   if (!isSuccess) {
  //     _unbindBackgroundIsolate();
  //     _bindBackgroundIsolate();
  //     return;
  //   }
  //   _port.listen((dynamic data) {
  //     print('UI Isolate Callback: $data');
  //     String id = data[0];
  //     DownloadTaskStatus status = data[1];
  //     int progress = data[2];

  //     final task = _tasks?.firstWhere((task) => task.taskId == id);
  //     if (task != null) {
  //       setState(() {
  //         task.status = status;
  //         task.progress = progress;
  //       });
  //     }
  //   });
  // }

  // void _unbindBackgroundIsolate() {
  //   IsolateNameServer.removePortNameMapping('downloader_send_port');
  // }

  // static void downloadCallback(
  //     String id, DownloadTaskStatus status, int progress) {
  //   print(
  //       'Background Isolate Callback: task ($id) is in status ($status) and process ($progress)');
  //   final SendPort send =
  //       IsolateNameServer.lookupPortByName('downloader_send_port');
  //   send.send([id, status, progress]);
  // }

  // Future<Null> _prepare() async {
  //   final tasks = await FlutterDownloader.loadTasks();

  //   int count = 0;
  //   _tasks = [];
  //   _items = [];

  //   // _tasks.addAll(_documents.map((document) =>
  //   //     _TaskInfo(name: document['name'], link: document['link'])));

  //   // _items.add(_ItemHolder(name: 'Documents'));
  //   // for (int i = count; i < _tasks.length; i++) {
  //   //   _items.add(_ItemHolder(name: _tasks[i].name, task: _tasks[i]));
  //   //   count++;
  //   // }

  //   _tasks.addAll(_images
  //       .map((image) => _TaskInfo(name: image['name'], link: image['link'])));

  //   _items.add(_ItemHolder(name: 'Images'));
  //   for (int i = count; i < _tasks.length; i++) {
  //     _items.add(_ItemHolder(name: _tasks[i].name, task: _tasks[i]));
  //     count++;
  //   }

  //   // _tasks.addAll(_videos
  //   //     .map((video) => _TaskInfo(name: video['name'], link: video['link'])));

  //   // _items.add(_ItemHolder(name: 'Videos'));
  //   // for (int i = count; i < _tasks.length; i++) {
  //   //   _items.add(_ItemHolder(name: _tasks[i].name, task: _tasks[i]));
  //   //   count++;
  //   // }

  //   tasks?.forEach((task) {
  //     for (_TaskInfo info in _tasks) {
  //       if (info.link == task.url) {
  //         info.taskId = task.taskId;
  //         info.status = task.status;
  //         info.progress = task.progress;
  //       }
  //     }
  //   });

  //   // _permissionReady = await _checkPermission();

  //   // _localPath = (await _findLocalPath()) + '/Download';
  //   _localPath = (await _findLocalPath());
  //   debugPrint('localPath: ' + _localPath);

  //   final savedDir = Directory(_localPath);
  //   bool hasExisted = await savedDir.exists();
  //   if (!hasExisted) {
  //     savedDir.create();
  //   }

  //   setState(() {
  //     _isLoading = false;
  //   });
  // }

  // Future<bool> _checkPermission() async {
  //   if (Theme.of(context).platform == TargetPlatform.android) {
  //     PermissionStatus permission = await PermissionHandler()
  //         .checkPermissionStatus(PermissionGroup.storage);
  //     if (permission != PermissionStatus.granted) {
  //       Map<PermissionGroup, PermissionStatus> permissions =
  //           await PermissionHandler()
  //               .requestPermissions([PermissionGroup.storage]);
  //       if (permissions[PermissionGroup.storage] == PermissionStatus.granted) {
  //         return true;
  //       }
  //     } else {
  //       return true;
  //     }
  //   } else {
  //     return true;
  //   }
  //   return false;
  // }

  Future<String> _findLocalPath() async {
    final directory = Theme.of(context).platform == TargetPlatform.android
        ? await getExternalStorageDirectory()
        : await getApplicationDocumentsDirectory();
    return directory.path;
  }

  void startTimer() {
    const oneSec = const Duration(seconds: 1);
    _timer = new Timer.periodic(
      oneSec,
      (Timer timer) => setState(
        () {
          _start = _start + 1;
          // if (_start < 1) {
          //   timer.cancel();
          // } else {
          //   _start = _start + 1;
          // }
        },
      ),
    );
  }
}

// class _TaskInfo {
//   final String name;
//   final String link;

//   String taskId;
//   int progress = 0;
//   DownloadTaskStatus status = DownloadTaskStatus.undefined;

//   _TaskInfo({this.name, this.link});
// }

// class _ItemHolder {
//   final String name;
//   final _TaskInfo task;

//   _ItemHolder({this.name, this.task});
// }
