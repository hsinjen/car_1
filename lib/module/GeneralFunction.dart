import 'dart:io';
import 'package:audioplayers/audio_cache.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission/permission.dart';
import 'package:car_1/apis/messagebox.dart';
import 'package:car_1/business/responseresult.dart';

class CommonMethod {
  static String barcodeCheck(int barcodeFixMode, String barcodeValue,
      {String Function(String) checkValue}) {
    String _value = '';
    if (checkValue != null) {
      _value = checkValue(barcodeValue);
    } else {
      //一般
      if (barcodeFixMode == 0) {
        if (barcodeValue.length > 17)
          _value = barcodeValue.substring(0, 17);
        else
          _value = barcodeValue;
      }
      //去頭
      else if (barcodeFixMode == 1) {
        if (barcodeValue.length >= 18)
          _value = barcodeValue.substring(1, 18);
        else
          _value = barcodeValue;
      } else
        _value = barcodeValue;
    }
    return _value;
  }

  static void removeFilesOfDir(
      BuildContext context, String initSubDir, String dirName) {
    MessageBox.showQuestion(context, '', '刪除所有檔案',
        yesButtonText: '刪除', noButtonText: '放棄', yesFunc: () {
      getApplicationDocumentsDirectory().then((Directory dir) {
        Directory _appDocDir = dir;
        if (Directory(_appDocDir.path + '/' + initSubDir + '/' + dirName)
                .existsSync() ==
            true) {
          //===刪除檔案不要用非同步，不然會有錯誤訊息，雖然實作正常，但錯誤訊息看起來不爽。
          Directory(_appDocDir.path + '/' + initSubDir + '/' + dirName)
              .deleteSync(recursive: true);
        }
      });
    });
  }

  static void removeFilesOfDirNoQuestion(
      BuildContext context, String initSubDir, String dirName) {
    getApplicationDocumentsDirectory().then((Directory dir) {
      Directory _appDocDir = dir;
      if (Directory(_appDocDir.path + '/' + initSubDir + '/' + dirName)
              .existsSync() ==
          true) {
        //===刪除檔案不要用非同步，不然會有錯誤訊息，雖然實作正常，但錯誤訊息看起來不爽。
        Directory(_appDocDir.path + '/' + initSubDir + '/' + dirName)
            .deleteSync(recursive: true);
      }
    });
  }

  static void playSound(ResultFlag flag) async {
    final _player = AudioCache(prefix: 'assets/sounds/');
    try {
      if (flag == ResultFlag.ok)
        await _player.play('ok.mp3');
      else
        await _player.play('ng.mp3');
    } catch (e) {
      print(e.toString());
    }
  }

  static Future<List<CameraDescription>> getAvailableCameras() async {
    try {
      List<CameraDescription> cameras;
      cameras = await availableCameras();
      return cameras;
    } on CameraException catch (e) {
      debugPrint('Error: ${e.code}\nError Message: ${e.description}');
      return [];
    }
  }

  static Future<CameraController> getSelectCameraController(
      List<CameraDescription> cameras,
      {CameraLensDirection cameraLensDirection =
          CameraLensDirection.back}) async {
    CameraDescription cameraDescription;
    CameraController controller;
    if (cameras == null || cameras.length == 0) return null;
    if (cameras.length > 0) {
      cameraDescription =
          cameras.firstWhere((v) => v.lensDirection == cameraLensDirection);
    }
    if (controller != null) {
      await controller.dispose();
    }
    controller = CameraController(
      cameraDescription,
      ResolutionPreset.veryHigh,
    );

    try {
      await controller.initialize();
      return controller;
    } on CameraException catch (e) {
      debugPrint('Error: ${e.code}\nError Message: ${e.description}');
      return null;
    }
  }

  static Future<Map<String, dynamic>> checkCameraPermission() async {
    Map<String, dynamic> map;
    if (Platform.isAndroid == true) {
      var permissions = await Permission.getPermissionsStatus([
        PermissionName.Camera,
        PermissionName.Microphone,
        PermissionName.Storage
      ]);
      Permissions permissionsCamera = permissions
          .firstWhere((v) => v.permissionName == PermissionName.Camera);
      if (permissionsCamera.permissionStatus == PermissionStatus.allow ||
          permissionsCamera.permissionStatus == PermissionStatus.always) {
        //允許
        map = {
          'resultFlag': 'ok',
          'result': '',
        };
      } else {
        //不允許
        map = {
          'resultFlag': 'ng',
          'result': '請開啟相機權限',
        };
        return map;
      }
      Permissions permissionsMicrophone = permissions
          .firstWhere((v) => v.permissionName == PermissionName.Microphone);
      if (permissionsMicrophone.permissionStatus == PermissionStatus.allow ||
          permissionsMicrophone.permissionStatus == PermissionStatus.always) {
        //允許
        map = {
          'resultFlag': 'ok',
          'result': '',
        };
      } else {
        //不允許
        map = {
          'resultFlag': 'ng',
          'result': '請開啟麥克風權限',
        };
        return map;
      }
      Permissions permissionsStorage = permissions
          .firstWhere((v) => v.permissionName == PermissionName.Storage);
      if (permissionsStorage.permissionStatus == PermissionStatus.allow ||
          permissionsStorage.permissionStatus == PermissionStatus.always) {
        //允許
        map = {
          'resultFlag': 'ok',
          'result': '',
        };
      } else {
        //不允許
        map = {
          'resultFlag': 'ng',
          'result': '請開啟儲存權限',
        };
        return map;
      }
    } else if (Platform.isIOS == true) {
      var permissionStatusCamera =
          await Permission.getSinglePermissionStatus(PermissionName.Camera);
      if (permissionStatusCamera == PermissionStatus.allow ||
          permissionStatusCamera == PermissionStatus.whenInUse) {
        //允許
        map = {
          'resultFlag': 'ok',
          'result': '',
        };
      } else {
        //不允許
        map = {
          'resultFlag': 'ng',
          'result': '請開啟相機權限',
        };
        return map;
      }
      var permissionStatusMicrophone =
          await Permission.getSinglePermissionStatus(PermissionName.Microphone);
      if (permissionStatusMicrophone == PermissionStatus.allow ||
          permissionStatusMicrophone == PermissionStatus.whenInUse) {
        //允許
        map = {
          'resultFlag': 'ok',
          'result': '',
        };
      } else {
        //不允許
        map = {
          'resultFlag': 'ng',
          'result': '請開啟麥克風權限',
        };
        return map;
      }
      var permissionStatusLocation =
          await Permission.getSinglePermissionStatus(PermissionName.Location);
      if (permissionStatusLocation == PermissionStatus.allow ||
          permissionStatusLocation == PermissionStatus.whenInUse) {
        //允許
        map = {
          'resultFlag': 'ok',
          'result': '',
        };
      } else {
        //不允許
        map = {
          'resultFlag': 'ng',
          'result': '請開啟位置權限',
        };
        return map;
      }
    }
    return map;
  }

  static Map<String, dynamic> checkVinList(
      String inputValue, List<Map<String, dynamic>> vinList) {
    Map<String, dynamic> map;
    String value = inputValue;
    value = value.replaceAll('/', '');

    int fullCount = 0;
    int startWithCount = 0;
    int endWithCount = 0;
    fullCount = vinList.where((v) => v['車身號碼'].toString() == value).length;
    startWithCount = vinList
        .where((v) => v['車身號碼'].toString().startsWith(value) == true)
        .length;
    endWithCount = vinList
        .where((v) => v['車身號碼'].toString().endsWith(value) == true)
        .length;
    if (fullCount == 0 && startWithCount == 0 && endWithCount == 0) {
      map = {
        'resultFlag': 'ng',
        'result': '沒有符合的車身號碼',
      };
    }
    if (fullCount >= 1) {
      value = vinList
          .firstWhere((v) => v['車身號碼'].toString() == value)['車身號碼']
          .toString();
      map = {
        'resultFlag': 'ok',
        'result': value,
      };
    } else if (startWithCount >= 1) {
      value = vinList
          .firstWhere(
              (v) => v['車身號碼'].toString().startsWith(value) == true)['車身號碼']
          .toString();
      map = {
        'resultFlag': 'ok',
        'result': value,
      };
    } else if (endWithCount >= 1) {
      value = vinList
          .firstWhere(
              (v) => v['車身號碼'].toString().endsWith(value) == true)['車身號碼']
          .toString();
      map = {
        'resultFlag': 'ok',
        'result': value,
      };
    } else {
      map = {
        'resultFlag': 'ng',
        'result': '找不到符合一筆以上的車身號碼:' + value + ' 請輸入完整或檢查資料來源',
      };
    }
    return map;
  }

  static Future<ResponseResult> checkCameraPermissionWithResult() async {
    if (Platform.isAndroid == true) {
      bool isUseCamera = true;
      bool isUseMicrophone = true;
      bool isUseStorage = true;
      var permissions = await Permission.getPermissionsStatus([
        PermissionName.Camera,
        PermissionName.Microphone,
        PermissionName.Storage
      ]);

      if (permissions
                  .firstWhere((v) => v.permissionName == PermissionName.Camera)
                  .permissionStatus ==
              PermissionStatus.allow ||
          permissions
                  .firstWhere((v) => v.permissionName == PermissionName.Camera)
                  .permissionStatus ==
              PermissionStatus.always) {
        isUseCamera = true;
      } else {
        isUseCamera = false;
      }
      if (permissions
                  .firstWhere(
                      (v) => v.permissionName == PermissionName.Microphone)
                  .permissionStatus ==
              PermissionStatus.allow ||
          permissions
                  .firstWhere(
                      (v) => v.permissionName == PermissionName.Microphone)
                  .permissionStatus ==
              PermissionStatus.always) {
        isUseMicrophone = true;
      } else {
        isUseMicrophone = false;
      }
      if (permissions
                  .firstWhere((v) => v.permissionName == PermissionName.Storage)
                  .permissionStatus ==
              PermissionStatus.allow ||
          permissions
                  .firstWhere((v) => v.permissionName == PermissionName.Storage)
                  .permissionStatus ==
              PermissionStatus.always) {
        isUseStorage = true;
      } else {
        isUseStorage = false;
      }
      if (isUseCamera == false) {
        //不允許
        return ResponseResult(
            item: ResponseResultItem(
                batchId: 0,
                syncId: 0,
                type: ResultType.strings,
                flag: ResultFlag.ng,
                message: '請開啟相機權限',
                messageCode: "",
                data: '請開啟相機權限'));
      } else if (isUseMicrophone == false) {
        //不允許
        return ResponseResult(
            item: ResponseResultItem(
                batchId: 0,
                syncId: 0,
                type: ResultType.strings,
                flag: ResultFlag.ng,
                message: '請開啟麥克風權限',
                messageCode: "",
                data: '請開啟麥克風權限'));
      } else if (isUseStorage == false) {
        //不允許
        return ResponseResult(
            item: ResponseResultItem(
                batchId: 0,
                syncId: 0,
                type: ResultType.strings,
                flag: ResultFlag.ng,
                message: '請開啟儲存權限',
                messageCode: "",
                data: '請開啟儲存權限'));
      } else {
        //允許
        return ResponseResult(
            item: ResponseResultItem(
                batchId: 0,
                syncId: 0,
                type: ResultType.strings,
                flag: ResultFlag.ok,
                message: '',
                messageCode: "",
                data: ''));
      }
    } else if (Platform.isIOS == true) {
      bool isUseCamera = true;
      bool isUseMicrophone = true;
      bool isUseLocation = true;
      var permissionStatusCamera =
          await Permission.getSinglePermissionStatus(PermissionName.Camera);
      if (permissionStatusCamera == PermissionStatus.allow ||
          permissionStatusCamera == PermissionStatus.whenInUse) {
        isUseCamera = true;
      } else {
        isUseCamera = false;
      }
      var permissionStatusMicrophone =
          await Permission.getSinglePermissionStatus(PermissionName.Microphone);
      if (permissionStatusMicrophone == PermissionStatus.allow ||
          permissionStatusMicrophone == PermissionStatus.whenInUse) {
        isUseMicrophone = true;
      } else {
        isUseMicrophone = false;
      }
      var permissionStatusLocation =
          await Permission.getSinglePermissionStatus(PermissionName.Location);
      if (permissionStatusLocation == PermissionStatus.allow ||
          permissionStatusLocation == PermissionStatus.whenInUse) {
        isUseLocation = true;
      } else {
        isUseLocation = false;
      }

      if (isUseCamera == false) {
        //不允許
        return ResponseResult(
            item: ResponseResultItem(
                batchId: 0,
                syncId: 0,
                type: ResultType.strings,
                flag: ResultFlag.ng,
                message: '請開啟相機權限',
                messageCode: "",
                data: '請開啟相機權限'));
      } else if (isUseMicrophone == false) {
        //不允許
        return ResponseResult(
            item: ResponseResultItem(
                batchId: 0,
                syncId: 0,
                type: ResultType.strings,
                flag: ResultFlag.ng,
                message: '請開啟麥克風權限',
                messageCode: "",
                data: '請開啟麥克風權限'));
      } else if (isUseLocation == false) {
        //不允許
        return ResponseResult(
            item: ResponseResultItem(
                batchId: 0,
                syncId: 0,
                type: ResultType.strings,
                flag: ResultFlag.ng,
                message: '請開啟位置權限',
                messageCode: "",
                data: '請開啟位置權限'));
      } else {
        //允許
        return ResponseResult(
            item: ResponseResultItem(
                batchId: 0,
                syncId: 0,
                type: ResultType.strings,
                flag: ResultFlag.ok,
                message: '',
                messageCode: "",
                data: ''));
      }
    } else {
      return ResponseResult(
          item: ResponseResultItem(
              batchId: 0,
              syncId: 0,
              type: ResultType.strings,
              flag: ResultFlag.ng,
              message: '未知權限',
              messageCode: "",
              data: '未知權限'));
    }
  }

  static ResponseResult checkVinListWithResult(
      String inputValue, List<Map<String, dynamic>> vinList) {
    String value = inputValue;
    value = value.replaceAll('/', '');

    int fullCount = 0;
    int startWithCount = 0;
    int endWithCount = 0;
    fullCount = vinList.where((v) => v['車身號碼'].toString() == value).length;
    startWithCount = vinList
        .where((v) => v['車身號碼'].toString().startsWith(value) == true)
        .length;
    endWithCount = vinList
        .where((v) => v['車身號碼'].toString().endsWith(value) == true)
        .length;
    if (fullCount == 0 && startWithCount == 0 && endWithCount == 0) {
      return ResponseResult(
          item: ResponseResultItem(
              batchId: 0,
              syncId: 0,
              type: ResultType.strings,
              flag: ResultFlag.ng,
              message: '沒有符合的車身號碼',
              messageCode: "",
              data: '沒有符合的車身號碼'));
    }
    if (fullCount >= 1) {
      value = vinList
          .firstWhere((v) => v['車身號碼'].toString() == value)['車身號碼']
          .toString();
      return ResponseResult(
          item: ResponseResultItem(
              batchId: 0,
              syncId: 0,
              type: ResultType.strings,
              flag: ResultFlag.ok,
              message: "",
              messageCode: "",
              data: value));
    } else if (startWithCount >= 1) {
      value = vinList
          .firstWhere(
              (v) => v['車身號碼'].toString().startsWith(value) == true)['車身號碼']
          .toString();
      return ResponseResult(
          item: ResponseResultItem(
              batchId: 0,
              syncId: 0,
              type: ResultType.strings,
              flag: ResultFlag.ok,
              message: "",
              messageCode: "",
              data: value));
    } else if (endWithCount >= 1) {
      value = vinList
          .firstWhere(
              (v) => v['車身號碼'].toString().endsWith(value) == true)['車身號碼']
          .toString();
      return ResponseResult(
          item: ResponseResultItem(
              batchId: 0,
              syncId: 0,
              type: ResultType.strings,
              flag: ResultFlag.ok,
              message: "",
              messageCode: "",
              data: value));
    } else {
      return ResponseResult(
          item: ResponseResultItem(
              batchId: 0,
              syncId: 0,
              type: ResultType.strings,
              flag: ResultFlag.ng,
              message: '找不到符合一筆以上的車身號碼:' + value + ' 請輸入完整或檢查資料來源',
              messageCode: "",
              data: '找不到符合一筆以上的車身號碼:' + value + ' 請輸入完整或檢查資料來源'));
    }
  }
}

class HardwareKeyboardListener extends TextInputFormatter {
  final Function inputCallback;
  bool barcodeMode = false;

  HardwareKeyboardListener(this.inputCallback, {this.barcodeMode = false});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    debugPrint('oldValue:' + oldValue.text);
    debugPrint('newValue:' + newValue.text);
    if (barcodeMode == true && inputCallback != null) {
      if (oldValue.text.length == 0) {
        inputCallback(newValue.text);
        return newValue;
      }
      //
      else if (oldValue.text == newValue.text) {
        return newValue;
      }
      //
      else {
        String _newValue = '';
        _newValue = newValue.text
            .substring(0, newValue.text.length - oldValue.text.length);
        inputCallback(_newValue);
        return TextEditingValue(text: _newValue);
      }
    } else
      return newValue;
  }
}
