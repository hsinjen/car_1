import 'dart:io';
import 'package:car_1/business/enums.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:car_1/business/datagram.dart';
import 'package:car_1/business/responseresult.dart';
import 'package:car_1/apis/imagebrowserlist.dart';
import 'package:car_1/business/classes.dart';
import 'package:car_1/business/business.dart';
import 'package:audioplayers/audio_cache.dart';
import '../model/sysMenu.dart';
import 'GeneralFunction.dart';
import 'GeneralFunction.dart';
import 'GeneralWidget.dart';
import 'package:car_1/module/CameraBoxAdv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class TVS0100019 extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _TVS0100019();
  }
}

class _TVS0100019 extends State<TVS0100019> with TickerProviderStateMixin {
  final String moduleId = 'TVS0100019';
  final String moduleName = '拍照上傳測試';
  String _imageCategory = 'TVS0100019';
  bool _isLoading = false;
  int _imageCount = 0;
  String _message = '';
  ResultFlag _messageFlag = ResultFlag.ok;
  Directory _appDocDir;
  List<Map<String, dynamic>> _files;
  String _startTime = '';
  String _endTime = '';
  int _imageFileSize = 0;
  var f = new NumberFormat("###.0#", "en_US");
  //========================================================

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(moduleName),
      ),
      drawer: buildMenu(context),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          //======== Query Button Start
          Opacity(
            opacity: 0.8,
            child: Container(
              child: RawMaterialButton(
                onPressed: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              CameraBoxAdv('compid', _imageCategory, 'TEST',
                                  (resultImageCount) {
                                print(resultImageCount);
                                _imageCount += resultImageCount;
                              })));
                },
                child: new Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 32.0,
                ),
                shape: new CircleBorder(),
                elevation: 2.0,
                fillColor: Colors.blueGrey,
                padding: const EdgeInsets.all(15.0),
              ),
              padding: EdgeInsets.only(bottom: 40),
            ),
          ),
          //======== Query Button End
        ],
      ),
      body: Container(
        child: Container(
          width: Business.deviceWidth(context),
          child: Column(
            children: <Widget>[
              //================ Input Start

              //================ Infomation Set Start
              _isLoading == false
                  ? Expanded(
                      child: Container(
                        child: Column(children: [
                          Text('本機圖片張數： ${_imageCount}'),
                          Text(
                              '本機圖片大小： ${f.format(_imageFileSize / 1024.0 / 1024.0)} MB'),
                          Text('開始時間： ${_startTime}'),
                          Text('結束時間： ${_endTime}'),
                          Divider(height: 40),
                          FlatButton(
                              //icon: Icon(Icons.ac_unit),
                              child: Text('讀取'),
                              onPressed: () {
                                setState(() {
                                  _loadPath();
                                  _loadFiles();
                                });
                              }),
                          FlatButton(
                              //icon: Icon(Icons.update),
                              child: Text('上傳'),
                              onPressed: () async {
                                DateFormat dateFormat =
                                    DateFormat("yyyy-MM-dd HH:mm:ss");

                                setState(() {
                                  _isLoading = true;
                                  _startTime =
                                      dateFormat.format(DateTime.now());
                                });
                                await uploadPicture();

                                setState(() {
                                  _isLoading = false;
                                  _endTime = dateFormat.format(DateTime.now());
                                });
                              }),
                          FlatButton(
                              //icon: Icon(Icons.ac_unit),
                              child: Text('刪除'),
                              onPressed: () {
                                setState(() {
                                  CommonMethod.removeFilesOfDirNoQuestion(
                                      context, 'compid/$_imageCategory', '');
                                  _loadFiles();
                                });
                              }),
                        ]),
                      ),
                    )
                  : CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.green)),
              //================
              _isLoading == false
                  ? buildMessage(context, _messageFlag, _message)
                  : Container(),
            ],
          ),
        ),
      ),
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

  Future<void> _loadPath() async {
    getApplicationDocumentsDirectory().then((Directory dir) {
      _appDocDir = dir;
    });
  }

  void _loadFiles() async {
    //------------------------------針對這模組下的全部車身上傳-----------------------------
    _imageFileSize = 0;
    List<FileSystemEntity> allList = List<FileSystemEntity>();
    List<Map<String, dynamic>> fileList = List<Map<String, dynamic>>();
    if (Directory(_appDocDir.path + '/compid/' + _imageCategory).existsSync() ==
        true) {
      allList = Directory(_appDocDir.path + '/compid/' + _imageCategory)
          .listSync(recursive: true, followLinks: false);

      allList.forEach((entity) {
        if (entity is File) {
          _imageFileSize += entity.lengthSync();
          fileList.add({
            '車身號碼': path.basename(path.dirname(entity.path)),
            '檔案路徑': entity.path,
          });
        }
      });
      _files = fileList;
      _imageCount = _files.length;
    } else {
      _files = fileList;
      _imageCount = _files.length;
    }
  }

  void _showMessage(ResultFlag flag, String message) {
    setState(() {
      _messageFlag = flag;
      _message =
          message.length < 29 ? message : message.substring(0, 30) + '...';
    });
    CommonMethod.playSound(flag);
  }

  Future<bool> uploadPicture() async {
    //------------------------------針對這模組下的全部車身上傳,未點檢車身略過-----------------------------

    bool resultF = false;
    List<File> files = List<File>();

    for (Map<String, dynamic> item
        in _files.where((v) => v['車身號碼'] == 'TEST')) {
      File f = File(item['檔案路徑'].toString());
      files.add(f);
    }

    Map<String, String> headers = {
      'ModuleId': _imageCategory,
      'SubPath': '\\' + _imageCategory + '\\TEST',
      'ReceiptType': '',
      'ReceiptSerial': '',
      'ReceiptNo': '',
      'Tag1': 'TEST',
      'Tag2': 'TEST',
      'Descryption': '',
      'UploadUser': Business.userId,
      'UploadDevice': '',
    };

    if (_files.length == 0) return false;

    ResponseResult result =
        await Business.apiUploadFile(FileCmdType.file, files, headers: headers);
    if (result.flag == ResultFlag.ok) {
      //上傳圖片成功
      _isLoading = false;
      //刪除本地照片
      //CommonMethod.removeFilesOfDirNoQuestion(
      //     context, 'compid/$_imageCategory',vin);

      resultF = true;
    } else {
      _showMessage(ResultFlag.ng, result.getNGMessage());
      _isLoading = false;
      resultF = false;
    }
    return resultF;
  }
}
