import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:car_1/apis/messagebox.dart';
import 'package:car_1/business/business.dart';
import 'package:car_1/business/datagram.dart';
import 'package:car_1/business/responseresult.dart';
import 'package:car_1/module/CameraBoxAdv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_picker/Picker.dart';
import 'package:flutter_picker/PickerLocalizations.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/sysMenu.dart';
import 'CameraBox.dart';
import 'CarInformation.dart';
import 'CarSelect.dart';
import 'GeneralFunction.dart';
import 'GeneralWidget.dart';
import 'package:car_1/business/enums.dart';

class TVS0100018 extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _TVS0100018();
  }
}

class _TVS0100018 extends State<TVS0100018> with TickerProviderStateMixin {
  final String moduleName = '估價拍照';
  String _imageCategory = 'TVS0100018';
  final _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final FocusNode _textFieldFocusNode = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _onlineMode = true; //true: online false: offline
  bool _isLoading = false;
  int _inputMode = 1; //0: keybarod 1: scanner 2:camera
  int _barcodeFixMode = 0; //0:一般 1:去頭 2:F/U
  String _message = '';
  ResultFlag _messageFlag = ResultFlag.ok;
  // List<Map<String, dynamic>> _fileList;
  // bool _isExistsFile = false;
  //========================================================
  bool _isExistsVin = false;
  List<Map<String, dynamic>> _vinList = new List<Map<String, dynamic>>();
  List<Map<String, dynamic>> _befList = new List<Map<String, dynamic>>();
  String _vinNo = ''; //車身號碼
  String _vsaa0103C = ''; //廠牌代碼
  String _vsaa0104C = ''; //車款代碼
  Directory _appDocDir;
  List<Map<String, dynamic>> _files;
  int _checkImageCount;
  bool _upLoadStatus = false;
  bool _autoUpMode = true;
  bool _inRedSec = false;
  List<String> vinNos = new List<String>();
  @override
  void initState() {
    super.initState();
    _loadPath();
    portraitUp();
  }

  @override
  Widget build(BuildContext context) {
    if ((_inputMode == 1 || _inputMode == 2) &&
        _inputFocusNode.hasFocus == true) {
      SystemChannels.textInput.invokeMethod('TextInput.hide');
      //FocusScope.of(context).requestFocus(_inputFocusNode);
    }

    return Scaffold(
      resizeToAvoidBottomPadding: false,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(moduleName),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => FunctionMenu(
                          //輸入模式
                          inputMode: _inputMode,
                          onInputModeChange: (int value) {
                            _inputMode = value;
                            debugPrint('輸入模式: ' + _inputMode.toString());
                          },
                          //條碼模式
                          barcodeMode: _barcodeFixMode,
                          onBarcodeChange: (int value) {
                            _barcodeFixMode = value;
                            debugPrint('條碼模式: ' + _barcodeFixMode.toString());
                          },
                          //拍照
                          imageCategory: _imageCategory, //作業圖庫
                        ),
                    fullscreenDialog: false),
              );
            },
          )
        ],
      ),
      drawer: buildMenu(context),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height - 80,
        child: Container(
          width: Business.deviceWidth(context),
          child: Column(
            children: <Widget>[
              //================ Input Start
              Container(
                child: Form(
                  key: _formKey,
                  child: Container(
                      child: Column(
                    children: <Widget>[
                      _buildInputContainer(),
                      buildLabel(
                          '車身號碼',
                          _vinList != null && _vinList.length > 0
                              ? _vinList[0]['車身號碼'].toString()
                              : ''),
                      buildLabel(
                          '廠牌',
                          _vinList != null && _vinList.length > 0
                              ? _vinList[0]['廠牌代碼'].toString()
                              : ''),
                      buildLabel(
                          '車款',
                          _vinList != null && _vinList.length > 0
                              ? _vinList[0]['車款代碼'].toString()
                              : ''),
                      buildLabel(
                          '車型',
                          _vinList != null && _vinList.length > 0
                              ? _vinList[0]['車型代碼'].toString()
                              : ''),
                    ],
                  )),
                ),
              ),
              //================
              // _isLoading == false
              //     ? _buildListView()
              //     : CircularProgressIndicator(
              //         valueColor: AlwaysStoppedAnimation(Colors.green)),
              //================
              _isLoading == false
                  ? Expanded(
                      child: Container(),
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
      // )
    );
  }

  void portraitUp() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  Widget _buildInputContainer() {
    return Container(
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
              padding: EdgeInsets.only(left: 20.0),
              child: RawKeyboardListener(
                focusNode: _inputFocusNode,
                onKey: (RawKeyEvent key) {
                  RawKeyEventDataAndroid data =
                      key.data as RawKeyEventDataAndroid;
                  String _keyCode;
                  _keyCode = data.keyCode.toString();
                  //back
                  if (_keyCode == '4') return;
                  if (key.runtimeType.toString() == 'RawKeyDownEvent') {
                  } else if (key.runtimeType.toString() == 'RawKeyUpEvent') {
                    if (_inputMode == 1) {
                      if (_inputController.text == '') return;
                      String value = '';
                      value = CommonMethod.barcodeCheck(
                          _barcodeFixMode, _inputController.text);
                      _inputData(value);
                    }
                  }
                },
                child: TextField(
                  controller: _inputController,
                  focusNode: _textFieldFocusNode,
                  keyboardType: TextInputType.number,
                  onEditingComplete: () {
                    if (_inputMode == 0) {
                      _inputData(_inputController.text);
                      FocusScope.of(context).requestFocus(new FocusNode());
                    }
                  },
                ),
              ),
            ),
          ),
          //上傳
          // _isExistsVin == false
          //     ? Container(
          //         width: 40,
          //         padding: EdgeInsets.only(right: 10),
          //         child: IconButton(
          //           icon: Icon(Icons.cloud_upload),
          //           onPressed: () {
          //             MessageBox.showQuestion(context, '點檢是否完成?', '',
          //                 yesFunc: () {
          //               if (_upLoadStatus == true) return;
          //               _upLoadStatus = true;
          //               if (_autoUpMode == true) {
          //                 _saveData(autoUpMode: true);
          //                 _upLoadStatus = false;
          //               } else {
          //                 _saveData();
          //                 _upLoadStatus = false;
          //                 return;
          //               }
          //             });
          //           },
          //         ),
          //       )
          //     : Container(),
          //拍照
          _isExistsVin == false
              ? Container(
                  //color: Colors.blue,
                  //width: 40,
                  padding: EdgeInsets.only(right: 10),
                  child: IconButton(
                    icon: Icon(Icons.camera_alt),
                    onPressed: () async {
                      Map<String, dynamic> map;
                      map = await CommonMethod.checkCameraPermission();
                      if (map['resultFlag'].toString() == 'ng') {
                        _showMessage(ResultFlag.ng, map['result'].toString());
                        return;
                      }
                      if (_vinList == null) {
                        _showMessage(ResultFlag.ng, '請輸入或掃描車身號碼');
                        return;
                      } else if (_vinList.length < 1) {
                        _showMessage(ResultFlag.ng, '請輸入或掃描車身號碼');
                        return;
                      }
                      await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => CameraBoxAdv(
                                      'compid',
                                      _imageCategory,
                                      _vinList[0]['車身號碼'], (resultImageCount) {
                                    _checkImageCount = resultImageCount;
                                  })));
                      // setState(() {
                      //   _isExistsFile = false;
                      // });
                    },
                  ),
                )
              : Container(),
          //==== 清除
          Container(
            height: 30,
            width: 60,
            padding: EdgeInsets.only(right: 10),
            child: RaisedButton(
              padding: EdgeInsets.all(1),
              color: Colors.black,
              child: Text('清除',
                  style: TextStyle(fontSize: 20.0, color: Colors.white)),
              onPressed: () {
                setState(() {
                  _inputController.text = '';
                  _vinList = null;
                });
                FocusScope.of(context).requestFocus(_textFieldFocusNode);
              },
            ),
          ),
          //=========== Input Mode
          _inputMode == 2
              ? IconButton(
                  icon: Icon(Icons.camera),
                  onPressed: () async {
                    try {
                      String barcode = await BarcodeScanner.scan();
                      if (barcode == null) return;
                      _inputData(barcode);
                      FocusScope.of(context).requestFocus(_inputFocusNode);
                    } catch (e) {
                      _showMessage(ResultFlag.ng, 'Scan Barcode Error 請檢查相機權限');
                    }
                  },
                )
              : _inputMode == 0
                  ? Container(
                      height: 30,
                      width: 60,
                      padding: EdgeInsets.only(right: 10),
                      child: RaisedButton(
                        padding: EdgeInsets.all(1),
                        color: Colors.black,
                        child: Text('查詢',
                            style:
                                TextStyle(fontSize: 20.0, color: Colors.white)),
                        onPressed: () {
                          if (_inputMode == 0) {
                            _inputData(_inputController.text);
                            FocusScope.of(context).requestFocus(FocusNode());
                          }
                          if (_inputMode == 1) {
                            _inputData(_inputController.text);
                            FocusScope.of(context).requestFocus(FocusNode());
                          }
                        },
                      ),
                    )
                  : Container(),
          //=========== Input Mode
        ],
      ),
    );
  }

  void _inputData(String value) async {
    value = value.replaceAll('/', '').toUpperCase();
    if (value == '') {
      _showMessage(ResultFlag.ng, '請輸入或掃描車身號碼');
      return;
    }

    if (_inputMode == 0 && value.length < 4) {
      _showMessage(ResultFlag.ng, '鍵盤模式下輸入長度最少4碼');
      return;
    }

    value = await CarSelect.showWithVin(context, value);
    if (value == null) {
      _showMessage(ResultFlag.ng, '找不到符合一筆以上的車身號碼');
      _inputController.text = '';
      _vinList = null;
      return;
    }

    // setState(() {
    //   _isLoading = true;
    // });
    _vinList = null;
    _loadData(value);
  }

  void _loadData(String vin) async {
    Datagram datagram = new Datagram();
    datagram.addText('''if(1=1)
                        with ect1 as (select    vsaa0100  as 車身號碼      ,
                        vsaa0102  as 廠牌系統碼    ,
                        vsaa0103  as 車款系統碼    ,
                        vsaa0104  as 車型系統碼    ,
                        vsaa0111  as 進口商系統碼  ,
                        vsaa0114  as 作業狀態      ,
                        vsaa0118  as 點交級別      ,
                        vsaa0119  as 點交次數      ,
                        vsaa0102c as 廠牌代碼      ,
                        vsaa0103c as 車款代碼      ,
                        vsaa0104c as 車型代碼      
                        from xvms_aa01
                                where 1 = 1 and  vsaa0100 ='$vin'  and vsaa0119 =  (select  max(vsaa0119) from xvms_aa01 where vsaa0100 ='$vin')
                                group by vsaa0100,
                                         vsaa0102,vsaa0103,
                                                  vsaa0104,
                                                  vsaa0111,
                                                  vsaa0114,
                                                  vsaa0118,
                                                  vsaa0119,
                                                  vsaa0102c,
                                                  vsaa0103c,
                                                  vsaa0104c)
                                                  select * from ect1 where 作業狀態 not in ('00','09','10','99')--只找最新並且不包含初始、出車、交車、離場''');
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      if (data.length < 1) {
        _showMessage(ResultFlag.ng, '該車未在港內');
        _vinList = null;
        return;
      } else if (data.length == 1) {
        _showMessage(ResultFlag.ok, '');
        setState(() {
          _vinList = data;
        });
      }
    } else {
      setState(() {
        _vinList = null;
      });
      _showMessage(
          ResultFlag.ng, result.getNGMessage().substring(0, 20) + '...');
      debugPrint('webapi異常' + result.getNGMessage());
      return;
    }
  }

  void _loadPath() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    _appDocDir = appDocDir;
  }

  bool errorMessageInThreeSec() {
    if (_inRedSec == false) {
      _inRedSec = true;
      int count = 2;
      Timer.periodic(Duration(seconds: 1), (timer) {
        if (count == 0) {
          timer.cancel();
          _showMessage(ResultFlag.ok, '');
          _inRedSec = false;
          return;
        }
        _showMessage(ResultFlag.ng, '點收數量異常,請填寫檢查說明');
        count--;
        print(count);
      });
    } else
      return false;
  }

  void _loadFiles() async {
    //------------------------------針對這模組下的全部車身上傳-----------------------------
    List<FileSystemEntity> allList = List<FileSystemEntity>();
    List<Map<String, dynamic>> fileList = List<Map<String, dynamic>>();
    vinNos.clear();
    if (Directory(_appDocDir.path + '/compid/' + _imageCategory).existsSync() ==
        true) {
      allList = Directory(_appDocDir.path + '/compid/' + _imageCategory)
          .listSync(recursive: true, followLinks: false);
      allList.forEach((entity) {
        if (entity is File) {
          fileList.add({
            '車身號碼': path.basename(path.dirname(entity.path)),
            '檔案路徑': entity.path,
          });
          if (vinNos.length == 0)
            vinNos.add(path.basename(path.dirname(entity.path)));
          else if (vinNos
                  .where((v) => v == path.basename(path.dirname(entity.path)))
                  .length ==
              0) vinNos.add(path.basename(path.dirname(entity.path)));
        }
      });
      _files = fileList;
    } else {
      _files = fileList;
    }
  }

  //============================================
  // Future<bool> uploadPicture() async {
  //   //---------------只針對屬於這車身的圖片去上傳--------------
  //   //檢查車身號碼是否有拍照
  //   int _filecount = 0;
  //   if (_files != null)
  //     _filecount = _files.where((v) => v['車身號碼'] == _vinNo).toList().length;
  //   if (_filecount < 3) {
  //     _showMessage(ResultFlag.ng, '請拍照,至少3張,車身:' + _vinNo);
  //     return false;
  //   }

  //   //點交次數
  //   String tag2 = '';
  //   Datagram datagram = Datagram();
  //   datagram.addText("""select isnull(vsaa0119,0) as vsaa0119
  //                                       from xvms_aa01
  //                                       where vsaa0100 = '$_vinNo' and
  //                                             vsaa0114 not in ('00','10','99')
  //                       """, rowSize: 65535);
  //   ResponseResult result2 = await Business.apiExecuteDatagram(datagram);
  //   if (result2.flag == ResultFlag.ok) {
  //     List<Map<String, dynamic>> data = result2.getMap();
  //     if (data.length > 0) tag2 = data[0]['vsaa0119'].toString();
  //   } else {}
  //   Map<String, String> headers = {
  //     'ModuleId': _imageCategory,
  //     'SubPath': '\\' + _imageCategory + '\\' + _vinNo,
  //     'ReceiptType': '',
  //     'ReceiptSerial': '',
  //     'ReceiptNo': '',
  //     'Tag1': _vinNo,
  //     'Tag2': tag2,
  //     'Descryption': '',
  //     'UploadUser': Business.userId,
  //     'UploadDevice': '',
  //   };

  //   List<File> files = List<File>();
  //   for (Map<String, dynamic> item in _files) {
  //     File f = File(item['檔案路徑'].toString());
  //     files.add(f);
  //   }
  //   if (files.length == 0) return false;

  //   ResponseResult result =
  //       await Business.apiUploadFile(FileCmdType.file, files, headers: headers);
  //   if (result.flag == ResultFlag.ok) {
  //     //上傳圖片成功
  //     _isLoading = false;
  //     return true;
  //   } else {
  //     _showMessage(ResultFlag.ng, result.getNGMessage());
  //     _isLoading = false;
  //     return false;
  //   }
  // }

  Future<bool> uploadPicture() async {
    //------------------------------針對這模組下的全部車身上傳,未點檢車身略過-----------------------------

    bool resultF = false;
    for (String vin in vinNos) {
      List<File> files = List<File>();
      //點交次數
      String tag2 = '';
      Datagram datagram = Datagram();
      // datagram.addText("""select max(isnull(vsaa0119,0)) as vsaa0119
      //                                     from xvms_aa01
      //                                     where vsaa0100 = '$vin' and
      //                                           vsaa0114 not in ('00','10','99')
      //                     """, rowSize: 65535);
      datagram.addText("""if(1=1)
                          declare @oResult_Fg varchar(2) ='OK',
                                  @tag1 varchar(100);
                              if exists (select 1 from XVMS_AA13 where VSAA1300 ='$vin')
                                  begin
                                      select @tag1 = max(isnull(vsaa1305,0)) 
                                            from xvms_aa13 where VSAA1300 ='$vin'
                                  end
                              else 
                                  begin
                                      set @oResult_Fg ='NG'
                                      set @tag1 ='該車上未點檢'
                                  end
                          select @oResult_Fg as oResult_Fg,@tag1 as vsaa1305
                          """, rowSize: 65535);
      ResponseResult result2 = await Business.apiExecuteDatagram(datagram);
      if (result2.flag == ResultFlag.ok) {
        List<Map<String, dynamic>> data = result2.getMap();
        if (data.length > 0 && data[0]['vsaa1305'].toString() != '該車上未點檢')
          tag2 = data[0]['vsaa1305'].toString();
        else
          //若該車未點檢則忽略
          continue;
      } else {
        //未知異常則忽略
        continue;
      }
      Map<String, String> headers = {
        'ModuleId': _imageCategory,
        'SubPath': '\\' + _imageCategory + '\\' + vin,
        'ReceiptType': '',
        'ReceiptSerial': '',
        'ReceiptNo': '',
        'Tag1': vin,
        'Tag2': tag2,
        'Descryption': '',
        'UploadUser': Business.userId,
        'UploadDevice': '',
      };

      for (Map<String, dynamic> item in _files.where((v) => v['車身號碼'] == vin)) {
        File f = File(item['檔案路徑'].toString());
        files.add(f);
      }
      if (files.length == 0) continue;

      ResponseResult result = await Business.apiUploadFile(
          FileCmdType.file, files,
          headers: headers);
      if (result.flag == ResultFlag.ok) {
        //上傳圖片成功
        _isLoading = false;
        //刪除本地照片
        CommonMethod.removeFilesOfDirNoQuestion(
            context, 'compid/$_imageCategory', vin);
        resultF = true;
      } else {
        _showMessage(ResultFlag.ng, result.getNGMessage());
        _isLoading = false;
        return resultF = false;
      }
    }
    return resultF;
  }

  bool checkPictureCount() {
    //檢查車身號碼是否有拍照
    int _filecount = 0;
    if (_vinList == null) return false;
    String vsab1300 = _vinList.first['車身號碼'].toString();
    if (_files != null) {
      _filecount = _files.where((v) => v['車身號碼'] == vsab1300).toList().length;

      if (_filecount < 3) {
        _showMessage(ResultFlag.ng, '車身號碼:' + vsab1300 + '請拍照,至少3張');
        return false;
      } else {
        return true;
      }
    } else {
      return false;
    }
  }

  void _saveData({bool autoUpMode = false}) async {
    // setState(() {
    //   _isExistsFile = false;
    // });
    _loadFiles();

    if (_vinList == null) {
      _showMessage(ResultFlag.ng, '請輸入車身號碼');
      return;
    }

    bool countResult = checkPictureCount();

    //如果是自動上傳...
    if (autoUpMode == true) {
      //照片檢查..上傳照片
      if (autoUpMode == true && countResult == true) {
        //如果該車身號碼照片3張以上
        if (await sendData()) {
          if (await uploadPicture()) {
            _isLoading = false;
          } else {
            _showMessage(ResultFlag.ok, '網路不穩或其他因素請重新上傳圖片');
            return;
          }
        } else
          return;
      } else {
        _showMessage(ResultFlag.ng, '請拍照,至少3張以上');
        FocusScope.of(context).requestFocus(FocusNode());
        return;
      }
      //如果是手動上傳...
    } else {
      if (countResult == false) //照片張數未滿3張
      {
        _showMessage(ResultFlag.ng, '請拍照,至少3張以上');
        return;
      } else
        await sendData();
    }
  }

  Future<bool> sendData() async {
    Datagram datagram = Datagram();
    String vsab1300 = _vinList.first['車身號碼'].toString();
    String vsab1305 = _vinList.first['點交次數'].toString();

    List<ParameterField> paramList = List<ParameterField>();
    paramList.add(ParameterField(
        'sSTATUS', ParamType.strings, ParamDirection.input,
        value: 'Y'));
    paramList.add(ParameterField(
        'sVSAA1300', ParamType.strings, ParamDirection.input,
        value: vsab1300));
    paramList.add(ParameterField(
        'sVSAA1305', ParamType.strings, ParamDirection.input,
        value: vsab1305));
    paramList.add(ParameterField(
        'sUSERID', ParamType.strings, ParamDirection.input,
        value: Business.userId));
    paramList.add(ParameterField(
        'sDEPTID', ParamType.strings, ParamDirection.input,
        value: Business.deptId));
    paramList.add(ParameterField(
        'oRESULT_FLAG', ParamType.strings, ParamDirection.output));
    paramList.add(
        ParameterField('oRESULT', ParamType.strings, ParamDirection.output));
    datagram.addProcedure('SPX_XVMS_AA13', parameters: paramList);
    for (Map<String, dynamic> item
        in _vinList.where((v) => v['點收狀態'].toString() == 'Y').toList()) {
      List<ParameterField> paramList = List<ParameterField>();
      paramList.add(ParameterField(
          'sVSAB1300', ParamType.strings, ParamDirection.input,
          value: item['車身號碼'].toString()));
      paramList.add(ParameterField(
          'sVSAB1301', ParamType.strings, ParamDirection.input,
          value: item['點交次數'].toString()));
      paramList.add(ParameterField(
          'sVSAB1303', ParamType.strings, ParamDirection.input,
          value: item['料號'].toString()));
      paramList.add(ParameterField(
          'sVSAB1308', ParamType.strings, ParamDirection.input,
          value: item['點收數量'].toString()));
      paramList.add(ParameterField(
          'sVSAB1313', ParamType.strings, ParamDirection.input,
          value: item['檢查說明'].toString()));
      paramList.add(ParameterField(
          'sUSERID', ParamType.strings, ParamDirection.input,
          value: Business.userId));
      paramList.add(ParameterField(
          'sDEPTID', ParamType.strings, ParamDirection.input,
          value: Business.deptId));
      paramList.add(ParameterField(
          'oRESULT_FLAG', ParamType.strings, ParamDirection.output));
      paramList.add(
          ParameterField('oRESULT', ParamType.strings, ParamDirection.output));
      datagram.addProcedure('SPX_XVMS_AB13', parameters: paramList);
    }
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      _inputData(vsab1300);
      _showMessage(ResultFlag.ok, '點收完成');
      return true;
    } else {
      _showMessage(ResultFlag.ng, result.getNGMessage());
      return false;
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
}

class FunctionMenu extends StatefulWidget {
  //==== ConnectMode
  // bool onlineMode;
  // final void Function(bool) onOnlineModeChange;

  //==== InputMode
  final int inputMode;
  final void Function(int) onInputModeChange;

  //==== BarcodeMode
  final int barcodeMode;
  final void Function(int) onBarcodeChange;
  //==== DataUpload
  // final void Function(ResultFlag, String) dataUpload;
  // List<String> offlineDataBuffer = List<String>();
  List<Map<String, dynamic>> xvms0033List;
  String moduleId;
  //==== 拍照buildPhotograph()
  final String imageCategory;
  final String vinNo; //車身號碼
  final List<Map<String, dynamic>> vinList;
  void Function(Map<String, dynamic>, ResultFlag, String) onPhotograph;
  //_showMessage()
  String message = '';
  ResultFlag messageFlag = ResultFlag.ok;

  FunctionMenu({
    //InputMode
    @required this.inputMode,
    @required this.onInputModeChange,
    //BarcodeMode
    @required this.barcodeMode,
    @required this.onBarcodeChange,
    //拍照
    @required this.imageCategory, //作業圖庫
    @required this.vinNo,
    @required this.vinList,
    @required this.onPhotograph,
  });

  @override
  State<StatefulWidget> createState() {
    return _FunctionMenu();
  }
}

class _FunctionMenu extends State<FunctionMenu> {
  int _inputMode = 1;
  int _barcodeFixMode = 0;
  int _workcodeMode = 0;
  String _imageCategory = 'TVS0100018';
  String _vinNo = ''; //車身號碼
  List<Map<String, dynamic>> _vinList;

  bool _isLoading;
  List<String> _offlineDataBuffer = List<String>();
  List<Map<String, dynamic>> _xvms0033List;
  @override
  void initState() {
    super.initState();
    // _onlineMode = widget.onlineMode;
    _inputMode = widget.inputMode;
    _barcodeFixMode = widget.barcodeMode;
    _imageCategory = widget.imageCategory;
    _xvms0033List = widget.xvms0033List;
    _vinNo = widget.vinNo;
    _vinList = widget.vinList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('功能清單'),
        backgroundColor: Colors.brown,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            //==== InputMode
            buildInputMode(Colors.white, _inputMode, (int value) {
              widget.onInputModeChange(value);
              setState(() {
                _inputMode = value;
              });
            }),
            //==== BarcodeMode
            buildBarcodeMode(Color(0xffe1e6ef), _barcodeFixMode, (int value) {
              widget.onBarcodeChange(value);
              setState(() {
                _barcodeFixMode = value;
              });
            }),
            // //==== 作業圖庫
            buildGalleryWithSeqNo(context, Colors.white, _imageCategory),
            Divider(height: 2.0, color: Colors.black),
          ],
        ),
      ),
    );
  }
}
