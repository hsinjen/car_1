import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:adv_camera/adv_camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission/permission.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CameraBoxAdv extends StatefulWidget {
  final String imageCompany;
  final String imageCategory;
  final String imageItem;
  void Function(int imageCountString) imageResultCallback;
  CameraBoxAdv(this.imageCompany, this.imageCategory, this.imageItem,
      this.imageResultCallback);

  @override
  _CameraBoxAdv createState() {
    return _CameraBoxAdv();
  }
}

class _CameraBoxAdv extends State<CameraBoxAdv> {
  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();
  List<String> pictureSizes = [];
  String imagePath;
  AdvCameraController cameraController;
  Timer timer;
  int _durSec = 2; //拍照後,等待秒數
  int _start = 0;
  bool _isTimeButtonClick = false;

  int _imageCount = 0;
  List<String> _dataBufferPictureSize = new List<String>();
  List<String> _dataBufferFlashType = new List<String>();
  String _flashType = '';
  String _pictureSize = '';
  SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
      if (_prefs.containsKey(
              'adv_Camera' + widget.imageCategory + 'PictureSize') ==
          true) {
        _dataBufferPictureSize = _prefs
            .getStringList('adv_Camera' + widget.imageCategory + 'PictureSize');
      }
      if (_prefs
              .containsKey('adv_Camera' + widget.imageCategory + 'FlashType') ==
          true) {
        _dataBufferFlashType = _prefs
            .getStringList('adv_Camera' + widget.imageCategory + 'FlashType');
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                //閃光燈配置
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.only(right: 30),
                          child: Text('閃光燈'),
                        ),
                        Container(
                          padding: EdgeInsets.only(right: 1),
                          child: FlatButton(
                            color: _flashType == FlashType.auto.toString()
                                ? Colors.lightBlue[200]
                                : Colors.transparent,
                            child: Text("Auto"),
                            shape: new RoundedRectangleBorder(
                                borderRadius: new BorderRadius.circular(5.0),
                                side: BorderSide(width: 1)),
                            onPressed: () {
                              cameraController.setFlashType(FlashType.auto);
                              if (_dataBufferFlashType.length >= 1) {
                                _dataBufferFlashType.clear();
                              }

                              _dataBufferFlashType
                                  .add(FlashType.auto.toString());
                              _prefs.setStringList(
                                  'adv_Camera' +
                                      widget.imageCategory +
                                      'FlashType',
                                  _dataBufferFlashType);
                              setState(() {
                                _flashType = FlashType.auto.toString();
                              });
                            },
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.only(right: 1),
                          child: FlatButton(
                            color: _flashType == FlashType.on.toString()
                                ? Colors.lightBlue[200]
                                : Colors.transparent,
                            child: Text("On"),
                            padding: EdgeInsets.only(left: 1),
                            shape: new RoundedRectangleBorder(
                                borderRadius: new BorderRadius.circular(5.0),
                                side: BorderSide(width: 1)),
                            onPressed: () {
                              cameraController.setFlashType(FlashType.on);
                              if (_dataBufferFlashType.length >= 1) {
                                _dataBufferFlashType.clear();
                              }

                              _dataBufferFlashType.add(FlashType.on.toString());
                              _prefs.setStringList(
                                  'adv_Camera' +
                                      widget.imageCategory +
                                      'FlashType',
                                  _dataBufferFlashType);
                              setState(() {
                                _flashType = FlashType.on.toString();
                              });
                            },
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.only(right: 1),
                          child: FlatButton(
                            color: _flashType == FlashType.off.toString()
                                ? Colors.lightBlue[200]
                                : Colors.transparent,
                            child: Text("Off"),
                            padding: EdgeInsets.only(left: 1),
                            shape: new RoundedRectangleBorder(
                                borderRadius: new BorderRadius.circular(5.0),
                                side: BorderSide(width: 1)),
                            onPressed: () {
                              cameraController.setFlashType(FlashType.off);
                              if (_dataBufferFlashType.length >= 1) {
                                _dataBufferFlashType.clear();
                              }

                              _dataBufferFlashType
                                  .add(FlashType.off.toString());
                              _prefs.setStringList(
                                  'adv_Camera' +
                                      widget.imageCategory +
                                      'FlashType',
                                  _dataBufferFlashType);
                              setState(() {
                                _flashType = FlashType.off.toString();
                              });
                            },
                          ),
                        ),
                        // FlatButton(
                        //   child: Text("Torch"),
                        //   onPressed: () {
                        //     cameraController.setFlashType(FlashType.torch);
                        //   },
                        // ),
                      ],
                    ),
                  ),
                ),
                Divider(height: 2.0, color: Colors.black),
                Container(
                  // color: Colors.brown[100],
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                        children: this.pictureSizes.map(
                      (pictureSize) {
                        return Container(
                            color: Colors.transparent,
                            padding: EdgeInsets.only(left: 1),
                            child: FlatButton(
                              shape: new RoundedRectangleBorder(
                                  borderRadius: new BorderRadius.circular(5.0),
                                  side: BorderSide(width: 1)),
                              color: _pictureSize == pictureSize
                                  ? Colors.lightBlue[200]
                                  : Colors.transparent,
                              child: Text(pictureSize),
                              onPressed: () async {
                                cameraController.setPictureSize(
                                    int.tryParse(pictureSize.substring(
                                        0, pictureSize.indexOf(":"))),
                                    int.tryParse(pictureSize.substring(
                                        pictureSize.indexOf(":") + 1,
                                        pictureSize.length)));

                                if (_dataBufferPictureSize.length >= 1)
                                  _dataBufferPictureSize.clear();
                                _dataBufferPictureSize.add(pictureSize);
                                _prefs.setStringList(
                                    'adv_Camera' +
                                        widget.imageCategory +
                                        'PictureSize',
                                    _dataBufferPictureSize);
                                setState(() {
                                  _pictureSize = pictureSize;
                                });
                              },
                            ));
                      },
                    ).toList()),
                  ),
                ),
                Expanded(
                    child: Container(
                  child: AdvCamera(
                    onCameraCreated: _onCameraCreated,
                    onImageCaptured: _onImageCaptured,
                    cameraPreviewRatio: CameraPreviewRatio.r16_9,
                  ),
                )),
              ],
            ),
            //Show Small Picture
            Positioned(
              bottom: 16.0,
              left: 16.0,
              child: imagePath != null
                  ? Container(
                      width: 100.0,
                      height: 100.0,
                      child: Image.file(File(imagePath)))
                  : Icon(Icons.image),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 切換鏡頭
            // FloatingActionButton(
            //     child: Icon(Icons.switch_camera),
            //     onPressed: () {
            //       cameraController.switchCamera();
            //     }),
            // Container(height: 16.0),
            _isTimeButtonClick == false
                ? FloatingActionButton(
                    child: Icon(Icons.camera),
                    onPressed: () {
                      setState(() {
                        _isTimeButtonClick = true;
                      });
                      startTimer();
                      cameraController.captureImage();
                    })
                : SizedBox(
                    height: 48.0,
                    child: Container(
                      child: Text('儲存中...($_start)'),
                    )),
          ]),
    );
  }

  //拍照
  void _onImageCaptured(String path) async {
    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath =
        '${extDir.path}/${widget.imageCompany}/${widget.imageCategory}/${widget.imageItem}';
    bool dirExists = await Directory(dirPath).exists();
    if (dirExists == false) await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.jpg';

    File(path).copySync(filePath);

    File(path).deleteSync();

    _imageCount++;
    if (widget.imageResultCallback != null)
      widget.imageResultCallback(_imageCount);

    setState(() {
      imagePath = filePath;
    });
  }

  //相機開啟
  void _onCameraCreated(AdvCameraController controller) async {
    if (this.pictureSizes.length == 0) {
      this.cameraController = controller;
      List<String> _picture = new List<String>();
      await new Future.delayed(
          const Duration(milliseconds: 300)); //強制等他建立好所有的關聯類
      try {
        _picture = await this.cameraController.getPictureSizes();
      } catch (e) {
        debugPrint('該死相機有問題了! ' + e.toString());
      }

      //像素
      if (_dataBufferPictureSize.length < 1) {
        //如果是第一次,預設則為第一個設定值
        String p = _picture[0].toString();
        cameraController.setPictureSize(
            int.tryParse(p.substring(0, p.indexOf(":"))),
            int.tryParse(p.substring(p.indexOf(":") + 1, p.length)));
      } else {
        //取得像素設定值
        _pictureSize = _dataBufferPictureSize[0].toString();
        cameraController.setPictureSize(
            int.tryParse(_pictureSize.substring(0, _pictureSize.indexOf(":"))),
            int.tryParse(_pictureSize.substring(
                _pictureSize.indexOf(":") + 1, _pictureSize.length)));
      }
      //閃光燈
      if (_dataBufferFlashType.length < 1) {
        //如果是第一次,預設則為Auto
        cameraController.setFlashType(FlashType.auto);
      } else {
        //取得閃光燈設定值

        _flashType = _dataBufferFlashType[0].toString();
        if (_flashType == FlashType.auto.toString()) {
          cameraController.setFlashType(FlashType.auto);
        } else if (_flashType == FlashType.on.toString()) {
          cameraController.setFlashType(FlashType.on);
        } else {
          cameraController.setFlashType(FlashType.off);
        }
      }

      if (_picture != null) {
        setState(() {
          pictureSizes = _picture;
        });
      }
    }
  }

  void startTimer() {
    const oneSec = const Duration(seconds: 1);
    timer = Timer.periodic(
      oneSec,
      (Timer timer) => setState(() {
        if (_start < 1) {
          timer.cancel();
          _start = _durSec;
          _isTimeButtonClick = false;
        } else {
          _start = _start - 1;
        }
      }),
    );
  }

  Widget getPWidgetList() {
    this.pictureSizes.map(
      (pictureSize) {
        return Container(
            color: Colors.transparent,
            padding: EdgeInsets.only(left: 1),
            child: FlatButton(
              shape: new RoundedRectangleBorder(
                  borderRadius: new BorderRadius.circular(5.0),
                  side: BorderSide(width: 1)),
              color: _pictureSize == pictureSize
                  ? Colors.lightBlue[200]
                  : Colors.transparent,
              child: Text(pictureSize),
              onPressed: () async {
                cameraController.setPictureSize(
                    int.tryParse(
                        pictureSize.substring(0, pictureSize.indexOf(":"))),
                    int.tryParse(pictureSize.substring(
                        pictureSize.indexOf(":") + 1, pictureSize.length)));

                if (_dataBufferPictureSize.length >= 1)
                  _dataBufferPictureSize.clear();
                _dataBufferPictureSize.add(pictureSize);
                _prefs.setStringList(
                    'adv_Camera' + widget.imageCategory + 'PictureSize',
                    _dataBufferPictureSize);
                setState(() {
                  _pictureSize = pictureSize;
                });
              },
            ));
      },
    ).toList();
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
