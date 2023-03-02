import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

class CameraBox extends StatefulWidget {
  final String imageCompany;
  final String imageCategory;
  final String imageItem;
  final Function imageResultCallback;

  CameraBox(this.imageCompany, this.imageCategory, this.imageItem,
      this.imageResultCallback);

  @override
  _CameraBox createState() {
    return _CameraBox();
  }
}

class _CameraBox extends State<CameraBox> with WidgetsBindingObserver {
  List<CameraDescription> cameras;
  CameraController cameraController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();
  Timer _timer;
  int _durSec = 2; //拍照後,等待秒數
  int _start = 0;
  bool _isTimeButtonClick = false;

  int _imageCount = 0;

  @override
  void initState() {
    super.initState();
    _start = _durSec;
    _setupCameras();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_timer != null) _timer.cancel();
    if (cameraController != null) cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Column(
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
                  color: cameraController != null &&
                          cameraController.value.isRecordingVideo
                      ? Colors.redAccent
                      : Colors.grey,
                  width: 3.0,
                ),
              ),
            ),
          ),
          _captureControlRowWidget(),
        ],
      ),
    );
  }

  /// Display the preview from the camera (or a message if the preview is not available).
  Widget _cameraPreviewWidget() {
    if (cameraController == null ||
        cameraController.value.isInitialized == false) {
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
        aspectRatio: cameraController.value.aspectRatio,
        child: CameraPreview(cameraController),
      );
    }
  }

  /// Display the control bar with buttons to take pictures and record videos.
  Widget _captureControlRowWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        _isTimeButtonClick == false
            ? IconButton(
                icon: Icon(Icons.camera_alt),
                color: Colors.blue,
                onPressed: cameraController != null &&
                        cameraController.value.isInitialized &&
                        !cameraController.value.isRecordingVideo
                    ? onTakePictureButtonPressed
                    : null,
              )
            : SizedBox(
                height: 48.0,
                child: Center(
                  child: Text('儲存中...($_start)'),
                )),
      ],
    );
  }

  void onTakePictureButtonPressed() {
    setState(() {
      _isTimeButtonClick = true;
    });
    startTimer();
    takePicture();
  }

  // 拍照
  void takePicture() async {
    if (cameraController.value.isInitialized == false) {
      showInSnackBar('Error: select a camera first.');
      return;
    }
    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath =
        '${extDir.path}/${widget.imageCompany}/${widget.imageCategory}/${widget.imageItem}';
    bool dirExists = await Directory(dirPath).exists();
    if (dirExists == false) await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.jpg';

    if (cameraController.value.isTakingPicture == true) {
      // A capture is already pending, do nothing.
      return;
    }

    try {
      await cameraController.takePicture(filePath);
      _imageCount++;
      if (widget.imageResultCallback != null)
        widget.imageResultCallback(_imageCount);
    } on CameraException catch (e) {
      _showCameraException(e);
      return;
    }
  }

  void _setupCameras(
      {CameraLensDirection cameraLensDirection =
          CameraLensDirection.back}) async {
    try {
      cameras = await availableCameras();

      if (cameras.length > 0) {
        CameraDescription cameraDescription =
            cameras.firstWhere((v) => v.lensDirection == cameraLensDirection);
        onNewCameraSelected(cameraDescription);
      }
    } on CameraException catch (e) {
      logError(e.code, e.description);
    }
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    if (cameraController != null) {
      await cameraController.dispose();
    }
    cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.veryHigh,
    );

    // If the controller is updated then update the UI.
    cameraController.addListener(() {
      if (mounted) setState(() {});
      if (cameraController.value.hasError) {
        showInSnackBar(
            'Camera error ${cameraController.value.errorDescription}');
      }
    });

    try {
      await cameraController.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  void startTimer() {
    const oneSec = const Duration(seconds: 1);
    _timer = Timer.periodic(
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

  void showInSnackBar(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(message)));
  }

  void _showCameraException(CameraException e) {
    logError(e.code, e.description);
    showInSnackBar('Error: ${e.code}\n${e.description}');
  }
}

/// Returns a suitable camera icon for [direction].
IconData getCameraLensIcon(CameraLensDirection direction) {
  switch (direction) {
    case CameraLensDirection.back:
      return Icons.camera_rear;
    case CameraLensDirection.front:
      return Icons.camera_front;
    case CameraLensDirection.external:
      return Icons.camera;
  }
  throw ArgumentError('Unknown lens direction');
}

void logError(String code, String message) =>
    debugPrint('Error: $code\nError Message: $message');
