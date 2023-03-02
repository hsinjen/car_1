import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audio_cache.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:adv_camera/adv_camera.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'sysImageViewGallery.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'package:audioplayers/audioplayers.dart';

enum ImageSourceType { offline, online }

class ImageItem {
  String imageId;
  String imageName;
  String imageExtName;
  int imageLength;

  final String filePath;
  final String groupKey;
  final String keyNo;
  final String keyDate;
  final String keyNumber;
  final String tag1;
  final String tag2;
  final ImageSourceType type;
  final String displayText;
  final String url;
  File file;
  bool upload = false;
  bool confirm = false;

  ImageItem(this.filePath,
      {this.groupKey,
      this.keyNo,
      this.keyDate,
      this.keyNumber,
      this.tag1,
      this.tag2,
      this.type = ImageSourceType.offline,
      this.url = '',
      this.displayText = ''}) {
    if (type == ImageSourceType.offline) {
      file = File(filePath);
      imageId = Uuid().v4();
      imageName = path.basename(filePath);
      imageExtName = path.extension(filePath).replaceAll('.', '');
      imageLength = file.lengthSync();
    } else {
      imageId = Uuid().v4();
      imageName = displayText;
    }
  }
}

enum CameraType { camera, cameraWithLamp }

class CameraWindow extends StatefulWidget {
  final CameraType cameraType;
  final List<CameraDescription> cameraList;
  final String imageDirPath;
  final String keyNo;
  final String keyDate;
  final String keyNumber;
  final String tag1;
  final String tag2;
  final String groupKey;
  final Function(List<ImageItem>) onConfirm;
  final Function onCancel;
  final List<ImageItem> imageList;

  CameraWindow(
      {Key key,
      this.cameraType,
      this.cameraList,
      this.imageDirPath,
      this.imageList,
      this.keyNo = '',
      this.keyDate = '',
      this.keyNumber = '',
      this.tag1 = '',
      this.tag2 = '',
      this.groupKey = '',
      this.onConfirm,
      this.onCancel})
      : super(key: key);

  @override
  _CameraWindowState createState() {
    return _CameraWindowState();
  }
}

class _CameraWindowState extends State<CameraWindow>
    with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  CameraController controller;
  AdvCameraController cameraController;
  int _currentResolutionPreset = 3;
  final List<String> _currentResolutionPresetText = [
    '低畫質(240p)',
    '中畫質(480p)',
    '高畫質(720p)',
    '超高畫質(1080p)',
    '極高畫質(2160p)',
    '裝置最高畫質'
  ];
  bool loading = false;
  List<String> pixleList = [];
  List<String> torchList = ['關', '開', '自動'];

  String getFileId() => DateTime.now().millisecondsSinceEpoch.toString();

  int _currentPixle = 0;
  int _currentTorch = 0; //0: Off 1:On 2:Auto
  SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([]);
    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
      if (_prefs.containsKey('camera_resolution_preset') == true) {
        _currentResolutionPreset = _prefs.getInt('camera_resolution_preset');
      }
      if (_prefs.containsKey('camera_pixle') == true) {
        _currentPixle = _prefs.getInt('camera_pixle');
      }
      if (_prefs.containsKey('camera_torch') == true) {
        _currentTorch = _prefs.getInt('camera_torch');
      }
    });
    //======
    controller =
        CameraController(widget.cameraList[0], ResolutionPreset.veryHigh);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    cameraController = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (controller != null) {
        onNewCameraSelected(controller.description);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.cameraType == CameraType.camera
        ? WillPopScope(
            onWillPop: () async => false,
            child: Scaffold(
              backgroundColor: Colors.black,
              body: NativeDeviceOrientationReader(builder: (context) {
                NativeDeviceOrientation orientation =
                    NativeDeviceOrientationReader.orientation(context);

                int turns;
                switch (orientation) {
                  case NativeDeviceOrientation.landscapeLeft:
                    turns = -1;
                    break;
                  case NativeDeviceOrientation.landscapeRight:
                    turns = 1;
                    break;
                  case NativeDeviceOrientation.portraitDown:
                    turns = 2;
                    break;
                  default:
                    turns = 0;
                    break;
                }

                return Column(children: [
                  Expanded(
                    child: Container(
                      color: Colors.red,
                      child: RotatedBox(
                        quarterTurns: turns,
                        child: Transform.scale(
                          scale: (orientation ==
                                      NativeDeviceOrientation.portraitUp ||
                                  orientation ==
                                      NativeDeviceOrientation.portraitDown)
                              ? 1
                              : 1, // /
                          // (controller.value.previewSize == null
                          //     ? 1
                          //     : controller.value.aspectRatio),
                          child: AspectRatio(
                            aspectRatio: (orientation ==
                                        NativeDeviceOrientation.portraitUp ||
                                    orientation ==
                                        NativeDeviceOrientation.portraitDown)
                                ? 1
                                : controller.value.previewSize == null
                                    ? 1
                                    : controller.value.aspectRatio,
                            child: _cameraPreviewWidget(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    color: Colors.white,
                    child: _cameraToolBarWidget(),
                  ),
                ]);
              }),
              floatingActionButton: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    loading == true
                        ? Container()
                        : FloatingActionButton(
                            backgroundColor:
                                loading == true ? Colors.grey : Colors.blue,
                            heroTag: "T2",
                            child: Icon(
                              Icons.camera,
                              color: Colors.white,
                            ),
                            onPressed: onTakePictureButtonPressed,
                          ),
                    Container(height: 36.0),
                  ]),
            ),
          )
        : WillPopScope(
            onWillPop: () async => false,
            child: Scaffold(
              key: _scaffoldKey,
              body: _cameraWidget(),
              floatingActionButton: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    loading == true
                        ? Container()
                        : FloatingActionButton(
                            backgroundColor:
                                loading == true ? Colors.grey : Colors.blue,
                            heroTag: "T2",
                            child: Icon(
                              Icons.camera,
                              color: Colors.white,
                            ),
                            onPressed: onTakePictureButtonPressed,
                          ),
                    Container(height: 36.0),
                  ]),
              //====
            ),
          );
  }

  Widget _cameraWidget() {
    if (widget.cameraType == CameraType.camera) {
      return Column(
        children: <Widget>[
          Expanded(
            child: Container(
              child: Padding(
                padding: const EdgeInsets.all(1.0),
                child: Center(
                  child: _cameraPreviewWidget(),
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(
                  color: controller != null && controller.value.isRecordingVideo
                      ? Colors.redAccent
                      : Colors.grey,
                  width: 3.0,
                ),
              ),
            ),
          ),
          _cameraToolBarWidget(),
        ],
      );
    } else {
      return Column(
        children: <Widget>[
          Expanded(
            child: Container(
              child: Padding(
                padding: const EdgeInsets.all(1.0),
                child: Center(
                  child: AdvCamera(
                    onCameraCreated: _onCameraCreated,
                    onImageCaptured: _onImageCaptured,
                    cameraPreviewRatio: CameraPreviewRatio.r16_9,
                  ),
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(
                  color: controller != null && controller.value.isRecordingVideo
                      ? Colors.redAccent
                      : Colors.grey,
                  width: 3.0,
                ),
              ),
            ),
          ),
          _cameraToolBarWidget(),
        ],
      );
    }
  }

  // 顯示照像機畫面
  Widget _cameraPreviewWidget() {
    if (controller == null || !controller.value.isInitialized) {
      return const Text(
        'Tap a camera',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {
      return AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: CameraPreview(controller),
      );
    }
  }

  // 顯示工具列
  Widget _cameraToolBarWidget() {
    if (widget.cameraType == CameraType.camera) {
      return Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Expanded(
              //width: MediaQuery.of(context).size.width / 2,
              child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    Container(
                      padding: EdgeInsets.only(left: 4, top: 5, bottom: 5),
                      child: Text('照片:'),
                    ),
                    SizedBox(
                      width: 80,
                      child: FlatButton(
                        child: Text(widget.imageList.length.toString() + ' 張',
                            style: TextStyle(color: Colors.blue)),
                        onPressed: () async {
                          if (widget.imageList.length > 0) {
                            await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ImageIndicator(
                                    images: widget.imageList,
                                    onValueChanged: () {
                                      setState(() {});
                                    },
                                  ),
                                ));
                          }
                        },
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.only(left: 2.0),
                      child: Text('品質:'),
                    ),
                    Container(
                      padding: EdgeInsets.only(left: 2.0),
                      child: FlatButton(
                          child: Text(
                              _currentResolutionPresetText[
                                  _currentResolutionPreset],
                              style: TextStyle(color: Colors.blue)),
                          onPressed: () async {
                            setState(() {
                              if (_currentResolutionPreset == 0)
                                _currentResolutionPreset = 1;
                              else if (_currentResolutionPreset == 1)
                                _currentResolutionPreset = 2;
                              else if (_currentResolutionPreset == 2)
                                _currentResolutionPreset = 3;
                              else if (_currentResolutionPreset == 3)
                                _currentResolutionPreset = 4;
                              else if (_currentResolutionPreset == 4)
                                _currentResolutionPreset = 5;
                              else if (_currentResolutionPreset == 5)
                                _currentResolutionPreset = 0;
                              _prefs.setInt('camera_resolution_preset',
                                  _currentResolutionPreset);

                              onNewCameraSelected(widget.cameraList[0]);
                            });
                          }),
                    ),
                  ]))),
          FlatButton(
            color: Colors.black,
            child: Text('取消', style: TextStyle(color: Colors.white)),
            onPressed: () {
              widget.imageList
                  .where((element) => element.confirm == false)
                  .forEach((f) {
                f.file.delete();
              });
              widget.imageList
                  .removeWhere((element) => element.confirm == false);

              if (widget.onCancel != null) widget.onCancel();
              Navigator.of(context).pop();
            },
          ),
          SizedBox(width: 2),
          FlatButton(
            color: Colors.black,
            child: Text('確定', style: TextStyle(color: Colors.white)),
            onPressed: () {
              widget.imageList.forEach((element) {
                element.confirm = true;
              });
              if (widget.onConfirm != null) widget.onConfirm(widget.imageList);
              Navigator.of(context).pop();
            },
          ),
          SizedBox(width: 2),
        ],
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  Container(
                    padding: EdgeInsets.only(left: 4, top: 5, bottom: 5),
                    child: Text('照片:'),
                  ),
                  SizedBox(
                    width: 80,
                    child: FlatButton(
                      child: Text(widget.imageList.length.toString() + ' 張',
                          style: TextStyle(color: Colors.blue)),
                      onPressed: () async {
                        if (widget.imageList.length > 0) {
                          await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ImageIndicator(
                                  images: widget.imageList,
                                  onValueChanged: () {
                                    setState(() {});
                                  },
                                ),
                              ));
                        }
                      },
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.only(left: 2.0),
                    child: Text('品質:'),
                  ),
                  Container(
                    padding: EdgeInsets.only(left: 2.0),
                    child: FlatButton(
                      //color: Colors.red,
                      child: Text(
                          pixleList.length == 0
                              ? '-'
                              : pixleList[_currentPixle] + ' 像素',
                          style: TextStyle(color: Colors.blue)),
                      onPressed: () {
                        setState(() {
                          if (pixleList.length > 0) {
                            if (_currentPixle < pixleList.length - 1)
                              _currentPixle = _currentPixle + 1;
                            else
                              _currentPixle = 0;
                            _prefs.setInt('camera_pixle', _currentPixle);

                            int dx = int.parse(
                                pixleList[_currentPixle].split(':')[0]);
                            int dy = int.parse(
                                pixleList[_currentPixle].split(':')[1]);

                            cameraController.setPictureSize(dx, dy);
                          }
                        });
                      },
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.only(left: 2.0),
                    child: Text('閃光燈:'),
                  ),
                  Container(
                    child: SizedBox(
                      width: 65,
                      child: FlatButton(
                        //color: Colors.red,
                        child: Text(torchList[_currentTorch],
                            style: TextStyle(color: Colors.blue)),
                        onPressed: () {
                          setState(() {
                            if (torchList.length > 0) {
                              if (_currentTorch < torchList.length - 1)
                                _currentTorch = _currentTorch + 1;
                              else
                                _currentTorch = 0;
                            }
                          });

                          if (_currentTorch == 0)
                            cameraController.setFlashType(FlashType.off);
                          else if (_currentTorch == 1)
                            cameraController.setFlashType(FlashType.torch);
                          else
                            cameraController.setFlashType(FlashType.auto);

                          _prefs.setInt('camera_torch', _currentTorch);
                        },
                      ),
                    ),
                  ),
                ])),
          ),
          FlatButton(
            color: Colors.black,
            child: Text('取消', style: TextStyle(color: Colors.white)),
            onPressed: () {
              if (widget.onCancel != null) widget.onCancel();
              Navigator.of(context).pop();
            },
          ),
          SizedBox(width: 2),
          FlatButton(
            color: Colors.black,
            child: Text('確定', style: TextStyle(color: Colors.white)),
            onPressed: () {
              if (widget.onConfirm != null) widget.onConfirm(widget.imageList);
              Navigator.of(context).pop();
            },
          ),
          SizedBox(width: 2),
        ],
      );
    }
  }

  void playSound() async {
    AudioCache audioPlayer = AudioCache();
    audioPlayer.play('sounds/camera_shut.mp3');
  }

  // 拍照事件
  void onTakePictureButtonPressed() {
    if (widget.cameraType == CameraType.camera) {
      if (controller == null || controller.value.isInitialized == false) return;
      playSound();
      _camera1TakePicture().then((String filePath) {
        if (mounted) {
          if (filePath != null) {
            setState(() {
              widget.imageList.add(ImageItem(filePath,
                  keyNo: widget.keyNo,
                  keyDate: widget.keyDate,
                  keyNumber: widget.keyNumber,
                  tag1: widget.tag1,
                  tag2: widget.tag2,
                  groupKey: widget.groupKey));
            });
          }
          //if (filePath != null) showInSnackBar('message');
          //showInSnackBar('Picture saved to $filePath');
        }
      });
    } else {
      if (cameraController == null) return;
      playSound();
      try {
        if (loading == true) return;
        setState(() {
          loading = true;
        });

        cameraController.captureImage();
      } catch (e) {}
    }
  }

  //Camera Save Image
  Future<String> _camera1TakePicture() async {
    if (!controller.value.isInitialized) {
      showInSnackBar('異常: 請先選擇相機控制器');
      return null;
    }
    final Directory rootDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${rootDir.path}/${widget.imageDirPath}}';
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${getFileId()}.jpg';

    if (controller.value.isTakingPicture) {
      return null;
    }

    try {
      await controller.takePicture(filePath);
    } on CameraException catch (_) {
      return null;
    }
    return filePath;
  }

  //Camera Controller Changed
  void onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller.dispose();
    }
    ResolutionPreset nowResolutionPreset = ResolutionPreset.ultraHigh;
    if (_currentResolutionPreset == 0)
      nowResolutionPreset = ResolutionPreset.low;
    else if (_currentResolutionPreset == 1)
      nowResolutionPreset = ResolutionPreset.medium;
    else if (_currentResolutionPreset == 2)
      nowResolutionPreset = ResolutionPreset.high;
    else if (_currentResolutionPreset == 3)
      nowResolutionPreset = ResolutionPreset.veryHigh;
    else if (_currentResolutionPreset == 4)
      nowResolutionPreset = ResolutionPreset.ultraHigh;
    else if (_currentResolutionPreset == 5)
      nowResolutionPreset = ResolutionPreset.max;

    controller = CameraController(
      cameraDescription,
      nowResolutionPreset,
      enableAudio: false,
    );

    // If the controller is updated then update the UI.
    controller.addListener(() {
      if (mounted) setState(() {});
      if (controller.value.hasError) {
        showInSnackBar('Camera error ${controller.value.errorDescription}');
      }
    });

    try {
      await controller.initialize();
    } on CameraException catch (e) {}

    if (mounted) {
      setState(() {});
    }
  }

  //AdvCamera Create Controller
  void _onCameraCreated(AdvCameraController controller) {
    this.cameraController = controller;
    this.cameraController.getPictureSizes().then((pictureSizes) {
      setState(() {
        this.pixleList = pictureSizes;
      });
    });
  }

  //AdvCamera Save Image
  void _onImageCaptured(String imagePath) async {
    if (this.mounted) {
      final Directory rootDir = await getApplicationDocumentsDirectory();
      final String dirPath = '${rootDir.path}/${widget.imageDirPath}}';
      await Directory(dirPath).create(recursive: true);
      final String filePath = '$dirPath/${getFileId()}.jpg';
      File(imagePath).copySync(filePath);
      File(imagePath).deleteSync();

      setState(() {
        widget.imageList.add(ImageItem(filePath,
            keyNo: widget.keyNo,
            keyDate: widget.keyDate,
            keyNumber: widget.keyNumber,
            tag1: widget.tag1,
            tag2: widget.tag2,
            groupKey: widget.groupKey));
        loading = false;
      });
    }
  }

  //=========
  void showInSnackBar(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(message)));
  }
}
