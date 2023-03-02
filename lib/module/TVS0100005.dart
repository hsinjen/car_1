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

class TVS0100005 extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _TVS0100005();
  }
}

class _TVS0100005 extends State<TVS0100005> with TickerProviderStateMixin {
  final String moduleId = 'TVS0100005';
  final String moduleName = '配件點檢';
  String _imageCategory = 'TVS0100005';
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
  HardwareKeyboardListener _keyboardListen;
  // List<Map<String, dynamic>> _fileList;
  // bool _isExistsFile = false;
  //========================================================
  bool _isExistsVin = false;
  List<Map<String, dynamic>> _vinList = new List<Map<String, dynamic>>();
  List<Map<String, dynamic>> _befList = new List<Map<String, dynamic>>();
  List<String> _offlineDataBuffer = List<String>();
  String _vinNo = ''; //車身號碼
  String _vsaa1302 = ''; //廠牌代碼
  String _vsaa1303 = ''; //車款代碼
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
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if ((_inputMode == 1 || _inputMode == 2) &&
        _inputFocusNode.hasFocus == true) {
      SystemChannels.textInput.invokeMethod('TextInput.hide');
      //FocusScope.of(context).requestFocus(_inputFocusNode);
    }
    //檢查車身號碼是否有照相
    // if (_isExistsFile == false) _getFiles();

    return Scaffold(
      resizeToAvoidBottomPadding: false,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(moduleName),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.find_in_page),
              onPressed: () async {
                String _vin = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            TVS0100005_Serch(imageCategory: _imageCategory)));
                if (_vin != null) _inputData(_vin);
              }),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //       builder: (context) => _buildFunctionMenu(context),
              //       fullscreenDialog: false),
              // );

              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => FunctionMenu(
                          //上傳模式
                          autoUpMode: _autoUpMode,
                          onAutoUpModeChange: (bool value) {
                            _autoUpMode = value;
                            debugPrint('上傳模式: ' + _autoUpMode.toString());
                          },
                          //連線模式
                          onlineMode: null,
                          onOnlineModeChange: null,
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
                          //dataUpload
                          offlineDataBuffer: null,
                          isLoading: null,
                          // xvms0033List: _xvms0033List,
                          dataUpload: null,
                          //拍照
                          imageCategory: null, //作業圖庫
                          // vinNo: _vinNo,
                          // vinList: _vinList,
                          onPhotograph: null,
                          //加入配件
                          vinNo: _vinNo, //車籍資料
                          vinList: _vinList,
                          showAddProduct: (ResultFlag value1, String value2,
                              List<Map<String, dynamic>> value3) {
                            if (value1 == ResultFlag.ng)
                              _showMessage(value1, value2);
                            if (value1 == ResultFlag.ok) {
                              setState(() {
                                _showMessage(value1, value2);
                                _vinList = value3;
                              });
                            }
                          },
                          //車籍資料
                          showCarInfo: (ResultFlag value1, String value2) {
                            if (value1 == ResultFlag.ng)
                              _showMessage(value1, value2);
                          },
                        ),
                    fullscreenDialog: false),
              );
            },
          )
        ],
      ),
      drawer: buildMenu(context),
      body:
          // SingleChildScrollView(
          //     reverse: true,
          //     child: Padding(
          //       padding: EdgeInsets.only(
          //           bottom: MediaQuery.of(context).viewInsets.bottom),
          //       child: Column(
          //         children: <Widget>[
          //           Container(
          //             width: 100,
          //             height: 200,
          //             padding: EdgeInsets.fromLTRB(0, 100, 0, 0),
          //             child: TextField(),
          //           ),
          //           Container(
          //             width: 100,
          //             height: 200,
          //             padding: EdgeInsets.fromLTRB(0, 100, 0, 0),
          //             child: TextField(),
          //           ),
          //         ],
          //       ),
          //     ))
// Container(
//    width: MediaQuery.of(context).size.width,
//                     height: MediaQuery.of(context).size.height-100,
//            child:
          //輩分,現在去掉padding
          // SingleChildScrollView(
          //     reverse: true,
          //     child: Padding(
          //       padding: EdgeInsets.only(
          //          bottom: MediaQuery.of(context).viewInsets.bottom,
          //       ),
          //       child: Container(
          //節取出來的padding
          // child: Padding(
          // padding: EdgeInsets.only(
          //    bottom: MediaQuery.of(context).viewInsets.bottom,
          // ),)
          // SingleChildScrollView(
          //     reverse: true,
          // child:
          Container(
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
                      // Container(
                      //   child: TextField(
                      //     // controller: _inputController,
                      //     // focusNode: _textFieldFocusNode,
                      //     keyboardType: TextInputType.number,
                      //     onEditingComplete: () {
                      //       if (_inputMode == 0) {
                      //         _inputData(_inputController.text);
                      //         FocusScope.of(context)
                      //             .requestFocus(new FocusNode());
                      //       }
                      //     },
                      //   ),
                      // ),
                      buildLabel('車身號碼', _vinNo),
                      buildLabel('廠牌', _vsaa1302),
                      buildLabel('車款', _vsaa1303),
                    ],
                  )),
                ),
              ),
              //================
              _isLoading == false
                  ? _buildListView()
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

  void portraitInit() async {
    await SystemChrome.setPreferredOrientations([]);
  }

  void portraitUp() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  // Widget _buildFunctionMenu(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: Text('功能清單'),
  //       backgroundColor: Colors.brown,
  //     ),
  //     body: SingleChildScrollView(
  //       child: Column(
  //         children: <Widget>[
  //           //==== ConnectMode
  //           // buildConnectMode(Colors.white, _onlineMode, (bool value) {
  //           //   setState(() {
  //           //     _onlineMode = value;
  //           //   });
  //           //   Navigator.pop(context);
  //           // }),
  //           //==== InputMode
  //           buildInputMode(Color(0xffe1e6ef), _inputMode, (int value) {
  //             setState(() {
  //               if (value == 0)
  //                 FocusScope.of(context).requestFocus(FocusNode());
  //               else if (value == 1)
  //                 FocusScope.of(context).requestFocus(FocusNode());
  //               else
  //                 FocusScope.of(context).requestFocus(FocusNode());
  //               _inputMode = value;
  //             });
  //             Navigator.pop(context);
  //           }),
  //           //==== BarcodeMode
  //           buildBarcodeMode(Colors.white, _barcodeFixMode, (int value) {
  //             setState(() {
  //               _barcodeFixMode = value;
  //             });
  //             Navigator.pop(context);
  //           }),
  //           //==== DataUpload
  //           // buildDataUpload(Color(0xffe1e6ef), () {
  //           //   if (_onlineMode == false) return;
  //           //   MessageBox.showQuestion(
  //           //       context,
  //           //       '共' + (_offlineDataBuffer.length).toString() + '筆資料',
  //           //       '確定上傳?', yesFunc: () async {
  //           //     setState(() {
  //           //       _isLoading = true;
  //           //     });
  //           //     Datagram datagram = Datagram();
  //           //     _offlineDataBuffer.forEach((s) {
  //           //       String vsab1300 = s.split('|')[0];
  //           //       String vsab1301 = s.split('|')[1];
  //           //       String vsab1303 = s.split('|')[2];
  //           //       String vsab1304 = s.split('|')[3];
  //           //       String vsab1305 = s.split('|')[4];
  //           //       String vsab1306 = s.split('|')[5];
  //           //       String vsab1307 = s.split('|')[6];
  //           //       String vsab1308 = s.split('|')[7];
  //           //       String vsab1309 = s.split('|')[8];
  //           //       String vsab1313 = s.split('|')[9];
  //           //       String vsab1314 = s.split('|')[10];
  //           //       String userId = s.split('|')[11];
  //           //       String deptId = s.split('|')[12];

  //           //       datagram.addText("""insert into xvms_ab13
  //           //                           select '0',
  //           //                                  entirev4.dbo.systemdate(),
  //           //                                  entirev4.dbo.systemtime(),
  //           //                                  '$userId',
  //           //                                  '$deptId',
  //           //                                  '','','','','',
  //           //                                  vsaa0100,
  //           //                                  vsaa0119,
  //           //                                  isnull((select max(vsab1302) from xvms_ab13 where vsab1300 = t1.vsaa0100 and vsab1301 = t1.vsaa0119),0) + 1,
  //           //                                  '$vsab1303',--料號
  //           //                                  '$vsab1304',--品名
  //           //                                  '$vsab1305',--規格
  //           //                                  '$vsab1306',--單位
  //           //                                  $vsab1307,--標準數量
  //           //                                  $vsab1308,--點收數量
  //           //                                  $vsab1309,--缺件數量
  //           //                                  entirev4.dbo.systemdate(),
  //           //                                  entirev4.dbo.systemtime(),
  //           //                                  '$userId',
  //           //                                  N'$vsab1313',--檢查說明
  //           //                                  '$vsab1314',--是否缺件
  //           //                                  'N',--缺件是否修正
  //           //                                  '','','',''
  //           //                           from xvms_aa01 as t1
  //           //                           where t1.vsaa0100 = '$vsab1300' and
  //           //                                 t1.vsaa0119 = '$vsab1301'
  //           //                        """, rowIndex: 0, rowSize: 100);
  //           //     });
  //           //     ResponseResult result = await Business.apiExecuteDatagram(datagram);
  //           //     if (result.flag == ResultFlag.ok) {
  //           //       _offlineDataBuffer.clear();
  //           //       SharedPreferences prefs =
  //           //           await SharedPreferences.getInstance();
  //           //       if (prefs.containsKey(moduleId) == true)
  //           //         prefs.remove(moduleId);
  //           //     } else
  //           //       _showMessage(ResultFlag.ng, result.getNGMessage());

  //           //     setState(() {
  //           //       _isLoading = false;
  //           //     });
  //           //   });
  //           // }),
  //           //==== 作業圖庫
  //           buildGallery(context, Color(0xffe1e6ef), _imageCategory),
  //           //==== 拍照
  //           // buildPhotograph(context, Color(0xffe1e6ef), _inputController.text,
  //           //     _vinList, _imageCategory, (Map<String, dynamic> map) {
  //           //   if (map['resultFlag'].toString() == 'ok') {
  //           //     setState(() {
  //           //       _inputController.text = map['result'].toString();
  //           //       _isExistsFile = false;
  //           //     });
  //           //   } else {
  //           //     _showMessage(ResultFlag.ng, map['result'].toString());
  //           //   }
  //           // }),
  //           Divider(height: 2.0, color: Colors.black),
  //           Container(
  //             height: 50,
  //             color: Colors.white,
  //             child: ListTile(
  //                 leading: Icon(Icons.apps),
  //                 title: Text('加入配件'),
  //                 onTap: () {
  //                   String value = _vinNo == null ? '' : _vinNo;
  //                   if (_vinList == null) {
  //                     _showMessage(ResultFlag.ng, '請選擇來源名稱');
  //                     return;
  //                   }
  //                   if (value == '' && _vinList == null ||
  //                       _vinList.length == 0) {
  //                     _showMessage(ResultFlag.ng, '請查詢車身號碼');
  //                     return;
  //                   }
  //                   String vinCarLabelsysNo =
  //                       _vinList.first['廠牌系統碼'].toString();

  //                   Navigator.pop(context);
  //                   Navigator.push(
  //                       context,
  //                       MaterialPageRoute(
  //                           builder: (context) => AddProduct(vinCarLabelsysNo,
  //                                   (Map<String, dynamic> data) {
  //                                 if (_vinList
  //                                         .where((v) =>
  //                                             v['車身號碼'].toString() == value &&
  //                                             v['料號'].toString() ==
  //                                                 data['料號'].toString())
  //                                         .length >
  //                                     0) {
  //                                   _showMessage(
  //                                       ResultFlag.ng,
  //                                       '料號:' +
  //                                           data['料號'].toString() +
  //                                           ' ' +
  //                                           data['品名'].toString() +
  //                                           ' 已存在');
  //                                   return;
  //                                 }
  //                                 setState(() {
  //                                   data['車身號碼'] = value;
  //                                   data['點交次數'] = _vinList.firstWhere((v) =>
  //                                       v['車身號碼'].toString() == value)['點交次數'];
  //                                   _vinList.add(data);
  //                                   //_inputController.text = value;
  //                                   _showMessage(
  //                                       ResultFlag.ok,
  //                                       '料號:' +
  //                                           data['料號'].toString() +
  //                                           ' ' +
  //                                           data['品名'].toString() +
  //                                           ' 已加入');
  //                                 });
  //                               })));
  //                 }),
  //           ),
  //           Container(
  //             height: 50,
  //             color: Color(0xffe1e6ef),
  //             child: ListTile(
  //               leading: Icon(Icons.apps),
  //               title: Text('車籍資料'),
  //               onTap: () {
  //                 if (_vinNo == '' || _vinNo == null) {
  //                   _showMessage(ResultFlag.ng, '請輸入或掃描車身號碼');
  //                   return;
  //                 }
  //                 CarInformation.show(context, _vinNo);
  //               },
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

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
          //此寫法刷讀時,會有問題,有時間再改良
          // Expanded(
          //   child: Container(
          //     padding: EdgeInsets.only(left: 20.0),
          //     child: TextField(
          //       inputFormatters: <TextInputFormatter>[_keyboardListen],
          //       focusNode: _inputFocusNode,
          //       controller: _inputController,
          //       enableInteractiveSelection: true,
          //       keyboardType: TextInputType.text,
          //       onChanged: (String value) {
          //         if (_inputMode == 1) {
          //           _inputData(value);
          //         }
          //       },
          //       onEditingComplete: () {
          //         if (_inputMode == 0) {
          //           _inputData(_inputController.text);
          //           FocusScope.of(context).requestFocus(new FocusNode());
          //         }
          //       },
          //     ),
          //   ),
          // ),
          //上傳
          _isExistsVin == false
              ? Container(
                  width: 40,
                  padding: EdgeInsets.only(right: 10),
                  child: IconButton(
                    icon: Icon(Icons.cloud_upload),
                    onPressed: () {
                      MessageBox.showQuestion(context, '點檢是否完成?', '',
                          yesFunc: () {
                        if (_upLoadStatus == true) return;
                        _upLoadStatus = true;
                        if (_autoUpMode == true) {
                          _saveData(autoUpMode: true);
                          _upLoadStatus = false;
                        } else {
                          _saveData();
                          _upLoadStatus = false;
                          return;
                        }
                      });
                    },
                  ),
                )
              : Container(),
          //拍照
          _isExistsVin == false
              ? Container(
                  width: 40,
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
                      if (_vinNo == '' || _vinList == null) {
                        _showMessage(ResultFlag.ng, '請輸入或掃描車身號碼');
                        return;
                      }
                      map = CommonMethod.checkVinList(_vinNo, _vinList);
                      if (map['resultFlag'].toString() == 'ng') {
                        _showMessage(ResultFlag.ng, map['result'].toString());
                        return;
                      } else {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CameraBoxAdv(
                                        'compid',
                                        _imageCategory,
                                        map['result'].toString(),
                                        (resultImageCount) {
                                      _checkImageCount = resultImageCount;
                                    })));
                        // setState(() {
                        //   _isExistsFile = false;
                        // });
                      }
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
                MessageBox.showQuestion(context, '畫面是否清空?', '',
                    yesFunc: () => {
                          setState(() {
                            _inputController.text = '';
                            _vinList = null;
                            _vinNo = '';
                            _vsaa1302 = '';
                            _vsaa1303 = '';
                          })
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

  Widget _buildListView() {
    return Expanded(
      child: Column(children: <Widget>[
        Divider(height: 10),
        Container(
            decoration: new BoxDecoration(
                border: new Border.all(color: Colors.grey, width: 0.5)),
            width: Business.deviceWidth(context) - 40,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                      padding: EdgeInsets.only(right: 0),
                      child: Text(
                        '配件項目',
                        textAlign: TextAlign.center,
                      ),
                      color: Colors.black12),
                ),
              ],
            )),
        Expanded(
          child: _buildVinList(_vinList),
        ),
      ]),
    );
  }

  Widget _buildVinList(List<Map<String, dynamic>> data) {
    if (data == null)
      return Container();
    else {
      return Container(
        width: Business.deviceWidth(context) - 40,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ListView.builder(
              itemCount: data == null ? 0 : data.length,
              itemBuilder: (BuildContext context, int index) {
                return _buildVinItem(context, data[index]);
              }),
        ),
      );
    }
  }

  Widget _buildVinItem(BuildContext context, Map<String, dynamic> data) {
    Color backColor = data['點收狀態'] == 'Y' ? Colors.lime : Colors.white;
    TextEditingController vsab1308Controller =
        TextEditingController(text: '0'); //點收數量
    TextEditingController vsab1313Controller = TextEditingController(); //檢查說明
    vsab1308Controller.text = data['點收數量'].toString();
    vsab1308Controller.selection =
        TextSelection.collapsed(offset: data['點收數量'].toString().length);
    vsab1313Controller.text = data['檢查說明'].toString();
    vsab1313Controller.selection =
        TextSelection.collapsed(offset: data['檢查說明'].toString().length);
    return _isExistsVin == false
        ? GestureDetector(
            onTap: () {},
            onLongPress: () {},
            child: Container(
              decoration: BoxDecoration(
                  color: backColor,
                  border: Border.all(color: Colors.grey, width: 0.5)),
              child: Column(
                children: <Widget>[
                  Container(
                    child: Row(
                      children: <Widget>[
                        SizedBox(
                          width: 20.0,
                        ),
                        Expanded(
                          child: Row(
                            children: <Widget>[
                              buildText('配件分類:', width: 65.0),
                              buildText(
                                  data['配件分類'] == null
                                      ? ''
                                      : data['配件分類'].toString(),
                                  color: Colors.blue,
                                  width: 75.0),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: <Widget>[
                              buildText('品名:', width: 40.0),
                              buildText(
                                  data['品名'] == null
                                      ? ''
                                      : data['品名'].toString(),
                                  color: Colors.blue,
                                  width: 100.0),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    child: Row(
                      children: <Widget>[
                        //Expanded(
                        //child:
                        Container(
                          width: 200,
                          padding:
                              EdgeInsets.only(left: 20, right: 20, bottom: 5.0),
                          // child: SingleChildScrollView(
                          child: TextField(
                            controller: vsab1308Controller,
                            maxLength: 7,
                            decoration: InputDecoration(
                              labelText: '點收數量',
                              filled: false,
                              contentPadding:
                                  EdgeInsets.only(top: 5, bottom: 10),
                              counterText: "",
                              hintText: "最多7位數",
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (String value) {
                              //vsab1308Controller.text = value;
                              vsab1308Controller.selection =
                                  TextSelection.collapsed(offset: value.length);
                              data['點收數量'] = value;
                              bool _isBefroer = beforeDataChk(data);
                              if (_isBefroer == false && data['檢查說明'] == '') {
                                setState(() {
                                  data['點收狀態'] = 'N';
                                });
                              }
                            },
                          )
                          // )
                          ,
                        ),
                        //),
                        IconButton(
                            icon: data['點收狀態'] == 'N'
                                ? Icon(Icons.check_box_outline_blank)
                                : Icon(Icons.check_box),
                            onPressed: () {
                              bool _isBefroer = beforeDataChk(data);
                              if (data['點收狀態'] == 'N' && _isBefroer == true) {
                                setState(() {
                                  data['點收狀態'] = 'Y';
                                });
                              } else if (data['點收狀態'] == 'N' &&
                                  _isBefroer == false &&
                                  data['檢查說明'] != '') {
                                setState(() {
                                  data['點收狀態'] = 'Y';
                                });
                              } else if (data['點收狀態'] == 'N' &&
                                  _isBefroer == false &&
                                  data['檢查說明'] == '') {
                                _showMessage(ResultFlag.ng, '點收數量異常,請填寫檢查說明');
                                errorMessageInThreeSec();
                              } else {
                                setState(() {
                                  data['點收狀態'] = 'N';
                                });
                              }
                            }),
                      ],
                    ),
                  ),
                  Container(
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.only(left: 20, right: 20),
                            child: TextField(
                              controller: vsab1313Controller,
                              decoration: InputDecoration(
                                labelText: '檢查說明',
                                filled: false,
                                contentPadding:
                                    EdgeInsets.only(top: 5, bottom: 10),
                              ),
                              keyboardType: TextInputType.text,
                              onChanged: (String value) {
                                //vsab1313Controller.text = value;
                                vsab1313Controller.selection =
                                    TextSelection.collapsed(
                                        offset: value.length);
                                data['檢查說明'] = value;
                                bool _isBefroer = beforeDataChk(data);

                                if (_isBefroer == false && data['檢查說明'] == '') {
                                  setState(() {
                                    data['點收狀態'] = 'N';
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        : GestureDetector(
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey, width: 0.5)),
              child: Column(
                children: <Widget>[
                  Container(
                    child: Row(
                      children: <Widget>[
                        buildLabel(
                            '配件分類',
                            data['配件分類'] == null
                                ? ''
                                : data['配件分類'].toString()),
                      ],
                    ),
                  ),
                  Container(
                    child: buildLabel(
                        '品名', data['品名'] == null ? '' : data['品名'].toString()),
                  ),
                  Container(
                    child: Row(
                      children: <Widget>[
                        buildLabel('點收數量',
                            data['點收數量'] == null ? '' : data['點收數量'].toString())
                      ],
                    ),
                  ),
                  Container(
                    child: Row(
                      children: <Widget>[
                        buildLabel(
                            '檢查說明',
                            data['檢查說明'] == null
                                ? ''
                                : data['檢查說明'].toString()),
                      ],
                    ),
                  ),
                  Container(
                    child: Row(
                      children: <Widget>[
                        data['檢查類別代碼'].toString() != '0'
                            ? buildLabel(
                                '檢查類別',
                                data['檢查類別'] == null
                                    ? ''
                                    : data['檢查類別'].toString(),
                                valueColor: Colors.red)
                            : buildLabel(
                                '檢查類別',
                                data['檢查類別'] == null
                                    ? ''
                                    : data['檢查類別'].toString()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
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

  bool beforeDataChk(Map<String, dynamic> data) {
    bool _isBefroer = false;
    for (Map<String, dynamic> d in _befList) {
      debugPrint(
          d['料號'].toString() + d['品名'].toString() + d['點收數量'].toString());
    }
    for (Map<String, dynamic> d in _vinList) {
      debugPrint(
          d['料號'].toString() + d['品名'].toString() + d['點收數量'].toString());
    }
    if (_befList
            .where((v) => v['料號'] == data['料號'] && v['品名'] == data['品名'])
            .length ==
        1) {
      String befroeCount = _befList
          .firstWhere(
              (v) => v['料號'] == data['料號'] && v['品名'] == data['品名'])['點收數量']
          .toString();
      String nowCount = data['點收數量'].toString();
      if (befroeCount == nowCount)
        _isBefroer = true;
      else
        _isBefroer = false;
    }
    return _isBefroer;
  }

  void _inputData(String value) async {
    value = value.replaceAll('/', '').toUpperCase();
    if (value == '') {
      _showMessage(ResultFlag.ng, '請輸入或掃描車身號碼');
      return;
    }

    // value = await CarSelect.showWithVin(context, value);
    value = await CarSelect.showWithVinNCheck_AB13(context, value);
    if (value == null) {
      _showMessage(ResultFlag.ng, '找不到符合一筆以上的車身號碼');
      _inputController.text = '';
      _vinList = null;
      return;
    }
    int abc = value.indexOf('|');
    if (abc > 0) {
      String val_Status = value.split('|').toList()[3].toString();
      if (val_Status == '已檢查') {
        _showMessage(ResultFlag.ok,
            '該車身號碼 :' + value.split('|').toList()[0].toString() + '已檢查過');
        _inputController.text = '';
        _vinList = null;
        // _vinNo =   value.split('|').toList()[0].toString();
        // _vsaa1302 = value.split('|').toList()[1].toString();
        // _vsaa1303 = value.split('|').toList()[2].toString();
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    bool isExistsVin = await _checkExistsVin(value);
    List<Map<String, dynamic>> data = new List<Map<String, dynamic>>();

    //車身主檔and配件BOM
    if (isExistsVin == false) {
      data = await _loadPrdBom(value);
    }
    //配件主檔
    else {
      data = await _loadXVMSAB13(value);
    }

    if (data != null) {
      setState(() {
        _inputController.text = '';
        _vinNo = data.first['車身號碼'].toString();
        _vsaa1302 = data.first['廠牌代碼'].toString();
        _vsaa1303 = data.first['車款代碼'].toString();
        _vinList = data;
        _befList = copyToList(data);
        //_befListAAAA = data;
        _isExistsVin = isExistsVin;
        _isLoading = false;
        _messageFlag = ResultFlag.ok;
        _message = '';
      });
    } else {
      setState(() {
        _inputController.text = '';
        _vinNo = '';
        _vsaa1302 = '';
        _vsaa1303 = '';
        _vinList = null;
        _befList = null;
        _isExistsVin = isExistsVin;
        _isLoading = false;
      });
      _showMessage(ResultFlag.ng, '請先建立配件BOM');
    }
  }

  List<Map<String, dynamic>> copyToList(List<Map<String, dynamic>> list) {
    List<Map<String, dynamic>> copyList = new List<Map<String, dynamic>>();
    Map<String, dynamic> map;
    for (Map<String, dynamic> item in list) {
      map = new Map<String, dynamic>();
      map = json.decode(json.encode(item));
      copyList.add(map);
    }
    return copyList;
  }

  void _loadPath() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    _appDocDir = appDocDir;
  }

  // void _loadFiles() async {
  //    //---------------只針對屬於這車身的圖片去上傳--------------
  //   List<FileSystemEntity> allList = List<FileSystemEntity>();
  //   List<Map<String, dynamic>> fileList = List<Map<String, dynamic>>();
  //   if (Directory(_appDocDir.path + '/compid/' + _imageCategory + '/' + _vinNo)
  //           .existsSync() ==
  //       true) {
  //     allList = Directory(_appDocDir.path + '/compid/' + _imageCategory + '/' + _vinNo)
  //         .listSync(recursive: true, followLinks: false);
  //     allList.forEach((entity) {
  //       if (entity is File)
  //         fileList.add({
  //           '車身號碼': path.basename(path.dirname(entity.path)),
  //           '檔案路徑': entity.path,
  //         });
  //     });
  //     _files = fileList;
  //   } else {
  //     _files = fileList;
  //   }
  // }

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
  // Future<void> _uploadFile() async {
  //   if (widget.fileSourceType == FileSourceType.online) return true;
  //   if (widget._fileSource != null && widget._fileSource.length > 0) {
  //     FileItem item = widget._fileSource[0];
  //     File f = File(item.fileUrl);

  //     bool success = await widget.uploadProcess(item, f);
  //     if (success == true) {
  //       f.delete(recursive: true);

  //       if (widget._fileSource.length <= 1)
  //       //如果資料來源 <= 1 筆
  //       {
  //         setState(() {
  //           widget._fileSource.clear();
  //           widget._fileSourceByKeyCategory.clear();
  //         });
  //       } else
  //       //如果資料來源 > 1 筆
  //       {
  //         setState(() {
  //           widget._fileSource.removeWhere((v) => v.fileUrl == item.fileUrl);
  //           //如果
  //           if (widget._fileSource
  //                   .where((v) => v.fileRef1 == item.fileRef1)
  //                   .length ==
  //               0)
  //           //如果 KeyDir 裡沒有任何檔案時
  //           {
  //             widget._fileSourceByKeyCategory
  //                 .removeWhere((v) => v.key == item.fileRef1);
  //           }
  //         });
  //       }
  //       if (widget._fileSource
  //               .where((v) => v.fileRef1 == item.fileRef1)
  //               .length ==
  //           0) {
  //         Directory(f.parent.path).deleteSync(recursive: true);
  //       }
  //       //如果資料來源 > 0 , 遞迴呼叫
  //       if (widget._fileSource.length > 0) {
  //         await _uploadFile();
  //       }
  //     }

  //     //   ResponseResult result = await Business.sendFile(
  //     //       widget.initSubDir + '/' + item.fileName, f,
  //     //       userId: Business.userId,
  //     //       deviceId: Business.deviceId,
  //     //       ref1: path.basenameWithoutExtension(f.parent.path),
  //     //       ref2: path.basenameWithoutExtension(f.parent.parent.path));

  //     //   //Upload Success
  //     //   if (result.flag == ResultFlag.ok) {
  //     //     f.delete(recursive: true);

  //     //     if (widget._fileSource.length <= 1)
  //     //     //如果資料來源 <= 1 筆
  //     //     {
  //     //       setState(() {
  //     //         widget._fileSource.clear();
  //     //         widget._fileSourceByKeyCategory.clear();
  //     //       });
  //     //     } else
  //     //     //如果資料來源 > 1 筆
  //     //     {
  //     //       setState(() {
  //     //         widget._fileSource.removeWhere((v) => v.fileUrl == item.fileUrl);
  //     //         //如果
  //     //         if (widget._fileSource
  //     //                 .where((v) => v.fileRef1 == item.fileRef1)
  //     //                 .length ==
  //     //             0)
  //     //         //如果 KeyDir 裡沒有任何檔案時
  //     //         {
  //     //           widget._fileSourceByKeyCategory
  //     //               .removeWhere((v) => v.key == item.fileRef1);
  //     //         }
  //     //       });
  //     //     }

  //     //     if (widget._fileSource
  //     //             .where((v) => v.fileRef1 == item.fileRef1)
  //     //             .length ==
  //     //         0) {
  //     //       Directory(f.parent.path).deleteSync(recursive: true);
  //     //     }
  //     //   }
  //     //   //Upload Failure
  //     //   else {
  //     //     //print(result.getNGMessage());
  //     //     return false;
  //     //   }

  //     //   //如果資料來源 > 0 , 遞迴呼叫
  //     //   if (widget._fileSource.length > 0) {
  //     //     bool flag = await _uploadFile();
  //     //     if (flag == false) return false;
  //     //   } else {
  //     //     return true;
  //     //   }
  //     //   return true;
  //     // }
  //     // //沒有任何資料來源
  //     // else
  //     //   return true;
  //   }
  // }
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

    if (_vinList.where((v) => v['點收狀態'].toString() == 'N').length > 0) {
      _showMessage(ResultFlag.ng, '尚有配件未點收');
      return;
    }

    if (_vinList.where((v) => v['點收狀態'].toString() == 'Y').length == 0) {
      _showMessage(ResultFlag.ng, '請點收配件');
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

  void _hardwareInputCallback(String value) {
    if (_inputMode == 1) {
      _inputController.text = CommonMethod.barcodeCheck(_barcodeFixMode, value);
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

  // void _getFiles() async {
  //   // _isExistsFile = true;
  //   List<Map<String, dynamic>> fileList = List<Map<String, dynamic>>();
  //   getApplicationDocumentsDirectory().then((Directory dir) {
  //     Directory _appDocDir = dir;
  //     if (Directory(_appDocDir.path + '/compid/' + _imageCategory)
  //             .existsSync() ==
  //         true) {
  //       Directory(_appDocDir.path + '/compid/' + _imageCategory)
  //           .list(recursive: true, followLinks: false)
  //           .listen((FileSystemEntity entity) {
  //         if (entity is Directory) {
  //         } else {
  //           fileList.add({
  //             "車身號碼": path.basename(path.dirname(entity.path)),
  //             "檔案路徑": entity.path,
  //           });
  //         }
  //       }).onDone(() {
  //         setState(() {
  //           _fileList = fileList;
  //         });
  //       });
  //     } else {
  //       setState(() {
  //         _fileList = fileList;
  //       });
  //     }
  //   });
  // }

  Future<bool> _checkExistsVin(String value) async {
    Datagram datagram = Datagram();
    datagram.addText(
        """select 1 from xvms_aa13 where status = 'Y' and vsaa1300 like '%$value%'""");
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      if (data.length > 0)
        return true;
      else
        return false;
    } else {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> _loadPrdBom(String value) async {
    Datagram datagram = Datagram();
    String sQL = """if(1=1)
                        with toponevin(車身號碼,點交次數,進口商系統碼,進口商代碼,進口商名稱,廠牌系統碼,廠牌代碼,車款系統碼,車款代碼,車型系統碼,車型代碼) as
                        (
                            select top 1
                                   vsaa0100,
                                   vsaa0119,
                                   vsaa0111,
                                   t2.vs000101 as 進口商代碼,
                                   t2.vs000102 as 進口商名稱,
                                   vsaa0102,
                                   t3.vs000101 as 廠牌代碼,
                                   vsaa0103,
                                   t4.vs000101 as 車款代碼,
                                   vsaa0104,
                                   t5.vs000101 as 車型代碼
                            from xvms_aa01 as t1
                            left join xvms_0001 as t2 on t1.vsaa0111 = t2.vs000100 and t2.vs000106 = '1'
                            left join xvms_0001 as t3 on t1.vsaa0102 = t3.vs000100 and t3.vs000106 = '2'
                            left join xvms_0001 as t4 on t1.vsaa0103 = t4.vs000100 and t4.vs000106 = '3'
                            left join xvms_0001 as t5 on t1.vsaa0104 = t5.vs000100 and t5.vs000106 = '4'
                            where vsaa0100 like '%$value%' and
                                  vsaa0114 not in ('00','10','99')
                        )
                        select distinct
                               iif(exists(select 1 from xvms_ab13 where vsab1300 = t1.車身號碼 and vsab1301 = t1.點交次數 and vsab1303 = t2.vs003205),'Y','N') as 點收狀態,
                               車身號碼,
                               點交次數,
                               廠牌系統碼,
                               廠牌代碼,
                               車款代碼,
                               t2.vs003205 as 料號,
                               t2.vs003206 as 品名,
                               t2.vs003207 as 規格,
                               t2.vs003208 as 單位,
                               t2.vs003210 as 標準數量,
                               t2.vs003210 as 點收數量,
                               '' as 檢查說明,
                               t4.vs004201 as 配件分類
                               ,車款系統碼,車型系統碼
                        from toponevin as t1
                        left join xvms_0032 as t2 on t1.廠牌系統碼 = t2.vs003201 and
                                                     t1.車款系統碼 = t2.vs003202
                                                     and t1.車型系統碼 = t2.VS003203
                        left join xvms_0031 as t3 on t2.vs003201 = t3.vs003106 and
                                                     t2.vs003205 = t3.vs003100
                        left join xvms_0042 as t4 on t3.vs003118 = t4.vs004200
                        where isnull(t2.vs003205, '') != ''
                        """;
    datagram.addText(sQL, rowIndex: 0, rowSize: 65535);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      if (data.length > 0)
        return data;
      else
        return null;
    } else {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _loadXVMSAB13(String value) async {
    Datagram datagram = Datagram();
    datagram.addText("""select 'Y' as 點收狀態,
                               vsab1300 as 車身號碼,
                               vsab1301 as 點交次數,
                               t2.vsaa0102 as 廠牌系統碼,
                               t8.vs000101 as 廠牌代碼,
                               t9.vs000101 as 車款代碼,
                               vsab1303 as 料號,
                               vsab1304 as 品名,
                               vsab1305 as 規格,
                               vsab1306 as 單位,
                               vsab1308 as 點收數量,
                               vsab1313 as 檢查說明,
                               vsab1314 as 檢查類別代碼,
                               t5.ixa00701 as 檢查類別,
                               isnull(t4.vs004201,'') as 配件分類
                        from xvms_ab13 as t1
                        left join xvms_aa01 as t2 on t1.vsab1300 = t2.vsaa0100 and
                                                     t1.vsab1301 = t2.vsaa0119
                        left join xvms_0031 as t3 on t2.vsaa0102 = t3.vs003106 and
                                                     t1.vsab1303 = t3.vs003100
                        left join xvms_0042 as t4 on t3.vs003118 = t4.vs004200
                        left join entirev4.dbo.ifx_a007 as t5 on t1.vsab1314 = t5.ixa00700 and t5.ixa00703 = '檢查類別'
                        left join xvms_aa13 as t6 on t1.vsab1300 = t6.vsaa1300 and
                                                     t1.vsab1301 = t6.vsaa1305
                        left join xvms_0001 as t7 on t6.vsaa1301 = t7.vs000100 and t7.vs000106 = '1'
                        left join xvms_0001 as t8 on t6.vsaa1302 = t8.vs000100 and t8.vs000106 = '2'
                        left join xvms_0001 as t9 on t6.vsaa1303 = t9.vs000100 and t9.vs000106 = '3'
                        left join xvms_0001 as t10 on t6.vsaa1304 = t10.vs000100 and t10.vs000106 = '4'
                        where vsab1300 like '%$value%' and
                              vsab1301 = (select max(vsab1301) from xvms_ab13 where vsab1300 like '%$value%')
                        """, rowIndex: 0, rowSize: 65535);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      if (data.length > 0)
        return data;
      else
        return null;
    } else {
      return null;
    }
  }
}

//加入配件
class AddProduct extends StatefulWidget {
  final String vinCarLabel; //廠牌系統碼
  String vinCarLabel2; //車款系統碼
  String vinCarLabel3; //車型系統碼
  final Function(Map<String, dynamic>) returnValue;

  AddProduct(this.vinCarLabel, this.returnValue,
      {this.vinCarLabel2 = '', this.vinCarLabel3 = ''});

  @override
  State<StatefulWidget> createState() {
    return _AddProduct();
  }
}

//加入配件
class _AddProduct extends State<AddProduct> {
  List<Map<String, dynamic>> _dataList;
  String _message = '';
  ResultFlag _messageFlag = ResultFlag.ok;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadXVMS0031();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('配件主檔'),
      ),
      body: Container(
        width: Business.deviceWidth(context),
        child: Column(
          children: <Widget>[
            //================
            _isLoading == false
                ? _buildListView()
                : CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Colors.green)),
            //================
            _isLoading == false
                ? buildMessage(context, _messageFlag, _message)
                : Container(),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    return Expanded(
      child: Column(children: <Widget>[
        Divider(height: 10),
        Container(
            decoration: new BoxDecoration(
                border: new Border.all(color: Colors.grey, width: 0.5)),
            width: Business.deviceWidth(context) - 40,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                      padding: EdgeInsets.only(right: 0),
                      child: Text(
                        '配件明細',
                        textAlign: TextAlign.center,
                      ),
                      color: Colors.black12),
                ),
              ],
            )),
        Expanded(
          child: _buildProductList(_dataList),
        ),
      ]),
    );
  }

  Widget _buildProductList(List<Map<String, dynamic>> data) {
    if (data == null)
      return Container();
    else {
      return Container(
        width: Business.deviceWidth(context) - 40,
        child: ListView.builder(
            itemCount: data == null ? 0 : data.length,
            itemBuilder: (BuildContext context, int index) {
              return _buildProductItem(context, data[index]);
            }),
      );
    }
  }

  Widget _buildProductItem(BuildContext context, Map<String, dynamic> data) {
    return GestureDetector(
      child: Container(
        // height: 30,
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey, width: 0.5)),
        child: Column(
          children: <Widget>[
            _buildCarInfoItem(
                '配件分類', data['配件分類'] == null ? '' : data['配件分類'].toString()),
            _buildCarInfoItem(
                '料號', data['料號'] == null ? '' : data['料號'].toString()),
            _buildCarInfoItem(
                '品名', data['品名'] == null ? '' : data['品名'].toString()),
            _buildCarInfoItem(
                '規格', data['規格'] == null ? '' : data['規格'].toString()),
            _buildCarInfoItem(
                '單位', data['單位'] == null ? '' : data['單位'].toString()),
            RaisedButton(
              child: Text('選擇料號'),
              onPressed: () {
                widget.returnValue(data);
                Navigator.pop(context);
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCarInfoItem(String labelText, String value,
      {bool bold = false,
      Color foreColor = Colors.black,
      Color backColor = Colors.white}) {
    return Container(
      padding: EdgeInsets.only(left: 20.0, bottom: 5),
      child: Row(
        children: <Widget>[
          Container(
            width: 80,
            child: Text(labelText,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
          Container(child: Text(':')),
          //==============
          Expanded(
            child: Container(
              padding: EdgeInsets.only(left: 5),
              decoration: BoxDecoration(
                  color: backColor,
                  border:
                      Border(bottom: BorderSide(width: 1, color: Colors.grey))),
              child: Text(value,
                  style: TextStyle(
                      color: foreColor,
                      fontSize: 14,
                      fontWeight:
                          bold == true ? FontWeight.bold : FontWeight.normal)),
            ),
          ),
          Container(width: 60),
          //================
        ],
      ),
    );
  }

  void _loadXVMS0031() async {
    setState(() {
      _isLoading = true;
    });

    Datagram datagram = Datagram();

    //這是找廠牌內所有相關配件
    // datagram.addText("""select 'N' as 點收狀態,
    //                            '' as 車身號碼,
    //                            0 as 點交次數,
    //                            vs003106 as 廠牌系統碼,
    //                            vs003100 as 料號,
    //                            vs003101 as 品名,
    //                            vs003102 as 規格,
    //                            vs003103 as 單位,
    //                            0 as 標準數量,
    //                            0 as 點收數量,
    //                            '' as 檢查說明,
    //                            t2.vs004201 as 配件分類
    //                     from xvms_0031 as t1
    //                     left join xvms_0042 as t2 on t1.vs003118 = t2.vs004200
    //                     where vs003106 = '${widget.vinCarLabel}'
    //                     """, rowSize: 5000);
    //這是找廠牌車款車型內所有相關配件
    datagram.addText("""select --distinct 
                              'N' as 點收狀態,
                                      '' as 車身號碼,
                                      0 as 點交次數,
                                      VS003205 as 料號,
                                      VS003206 as 品名,
                                      VS003207 as 規格,
                                      VS003208 as 單位,
                                      0 as 標準數量,
                                      0 as 點收數量,
                                      '' as 檢查說明,
                                      t3.vs004201 as 配件分類
                              from xvms_0032 as t1
                              left join xvms_0031 as t2 on t1.VS003205 = t2.VS003100
                              left join xvms_0042 as t3 on t2.vs003118 = t3.vs004200
                              where t1.VS003201 ='${widget.vinCarLabel}' 
                              and t1.VS003202 = '${widget.vinCarLabel2}' and t1.VS003203='${widget.vinCarLabel3}'
                        """, rowSize: 5000);

    final ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      setState(() {
        _dataList = data;
      });
    } else {
      _showMessage(ResultFlag.ng, result.getNGMessage());
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showMessage(ResultFlag flag, String message) {
    setState(() {
      _messageFlag = flag;
      _message = message;
    });
    CommonMethod.playSound(flag);
  }
}

class FunctionMenu extends StatefulWidget {
  //==== AutoUpMode
  bool autoUpMode;
  final void Function(bool) onAutoUpModeChange;

  //==== ConnectMode
  bool onlineMode;
  final void Function(bool) onOnlineModeChange;

  //==== InputMode
  final int inputMode;
  final void Function(int) onInputModeChange;

  //==== BarcodeMode
  final int barcodeMode;
  final void Function(int) onBarcodeChange;

  //==== DataUpload
  final void Function(ResultFlag, String) dataUpload;
  List<String> offlineDataBuffer = List<String>();
  // List<Map<String, dynamic>> xvms0033List;
  String moduleId;
  //==== 作業圖庫
  //String imageCategory;

  //==== 拍照buildPhotograph()
  final String imageCategory;
  final String vinNo; //車身號碼
  final List<Map<String, dynamic>> vinList;
  void Function(Map<String, dynamic>, ResultFlag, String) onPhotograph;
  //_showMessage()
  String message = '';
  ResultFlag messageFlag = ResultFlag.ok;
  //其他
  bool isLoading = false;

  void Function(ResultFlag, String) showCarInfo;
  void Function(ResultFlag, String, List<Map<String, dynamic>> vinList_Add)
      showAddProduct;

  FunctionMenu({
    //AutoUpMode
    @required this.autoUpMode,
    @required this.onAutoUpModeChange,
    //ConnectMode
    @required this.onlineMode,
    @required this.onOnlineModeChange,
    //InputMode
    @required this.inputMode,
    @required this.onInputModeChange,
    //BarcodeMode
    @required this.barcodeMode,
    @required this.onBarcodeChange,

    //==== DataUpload
    @required this.dataUpload,
    @required this.offlineDataBuffer,
    // @required this.xvms0033List,
    @required this.isLoading,

    //拍照
    @required this.imageCategory, //作業圖庫
    @required this.vinNo, //車籍資料
    @required this.vinList,
    @required this.onPhotograph,
    @required this.showAddProduct,

    //車籍資料
    @required this.showCarInfo,
  });

  @override
  State<StatefulWidget> createState() {
    return _FunctionMenu();
  }
}

class _FunctionMenu extends State<FunctionMenu> {
  int _inputMode = 1;
  int _barcodeFixMode = 0;
  String _imageCategory = 'TVS0100005';
  bool _onlineMode = true; //在線模式
  String _vinNo = ''; //車身號碼
  List<Map<String, dynamic>> _vinList;
  bool _autoUpMode = false; //上傳模式

  bool _isLoading;
  List<String> _offlineDataBuffer = List<String>();
  List<Map<String, dynamic>> _xvms0033List;
  @override
  void initState() {
    super.initState();
    _autoUpMode = widget.autoUpMode;
    _onlineMode = widget.onlineMode;
    _inputMode = widget.inputMode;
    _barcodeFixMode = widget.barcodeMode;
    //_imageCategory = widget.imageCategory;
    _isLoading = widget.isLoading;
    _offlineDataBuffer = widget.offlineDataBuffer;
    // _xvms0033List = widget.xvms0033List;
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
            //==== ConnectMode
            // buildConnectMode(Colors.white, _onlineMode, (bool value) {
            //   widget.onOnlineModeChange(value);
            //   setState(() {
            //     _onlineMode = value;
            //   });
            // }),
            //==== InputMode
            buildInputMode(Color(0xffe1e6ef), _inputMode, (int value) {
              widget.onInputModeChange(value);
              setState(() {
                _inputMode = value;
              });
            }),
            //==== BarcodeMode
            buildBarcodeMode(Colors.white, _barcodeFixMode, (int value) {
              widget.onBarcodeChange(value);
              setState(() {
                _barcodeFixMode = value;
              });
            }),
            //==== AutoUpMode
            buildAutoUpMode(Color(0xffe1e6ef), _autoUpMode, (bool value) {
              widget.onAutoUpModeChange(value);
              setState(() {
                _autoUpMode = value;
              });
            }),
            //==== DataUpload
            // buildDataUpload(Color(0xffe1e6ef), () {
            //   if (_onlineMode == false) {
            //     showDialog(
            //         ////新增一個對話框，用來顯示回傳的值
            //         context: context,
            //         child: AlertDialog(
            //           content: Text("連線模式:在線 才能上傳資料"),
            //         ));
            //     return;
            //   }
            //   if(_isLoading==true)return;
            //   ResultFlag _rf = ResultFlag.ok;
            //   String resultMs ='資料上傳成功';
            //   MessageBox.showQuestion(
            //       context,
            //       '共' + (_offlineDataBuffer.length).toString() + '筆資料',
            //       '確定上傳?', yesFunc: () async {
            //     setState(() {
            //       _isLoading = true;
            //     });
            //     Datagram datagram = Datagram();
            //     _offlineDataBuffer.forEach((s) {
            //       String vsaa1900 = s.split('|')[0];
            //       String vsab1901 = s.split('|')[1];
            //       String pickdate = s.split('|')[2];
            //       String pickuser = s.split('|')[3];

            //       datagram.addText("""update xvms_ab19 set status = status,
            //                                                  vsab1903 = '1',
            //                                                  vsab1904 = '$pickdate',
            //                                                  vsab1905 = '$pickuser'
            //                             where vsab1900 = '$vsaa1900' and
            //                                   vsab1901 = $vsab1901 and
            //                                   vsab1903 = '0'
            //                          """, rowIndex: 0, rowSize: 100);
            //     });
            //     ResponseResult result =
            //         await Business.apiExecuteDatagram(datagram);
            //     if (result.flag == ResultFlag.ok) {
            //       _offlineDataBuffer.clear();
            //       SharedPreferences prefs =
            //           await SharedPreferences.getInstance();
            //       if (prefs.containsKey(widget.moduleId) == true)
            //         prefs.remove(widget.moduleId);
            //     } else{
            //       _rf = ResultFlag.ng;
            //       resultMs = result.getNGMessage();
            //     }
            //       //_showMessage(ResultFlag.ng, result.getNGMessage());

            //     setState(() {
            //       _isLoading = false;
            //     });
            //     widget.dataUpload( _rf , resultMs);

            //   });
            // }),
            // //==== 作業圖庫
            buildGalleryWithSeqNo(context, Colors.white, _imageCategory),
            //==== 拍照
            // buildPhotograph(
            //     context, Color(0xffe1e6ef), _vinNo, _vinList, _imageCategory,
            //     (Map<String, dynamic> map) {
            //       ResultFlag _rf = ResultFlag.ok;
            //       String resultMs ='資料上傳成功';

            //   if (map['resultFlag'].toString() == 'ok') {

            //     _rf = ResultFlag.ok;
            //     resultMs = map['result'].toString();
            //     setState(() {
            //       _vinNo = map['result'].toString();
            //     });
            //   } else {

            //     _rf = ResultFlag.ng;
            //     resultMs = map['result'].toString();
            //     //_showMessage(ResultFlag.ng, map['result'].toString());
            //     //widget.onShowMessage(ResultFlag.ng , map['result'].toString());
            //   }
            //   widget.onPhotograph(map , _rf , resultMs);
            // }),

            Container(
              height: 50,
              color: Color(0xffe1e6ef),
              child: ListTile(
                  leading: Icon(Icons.apps),
                  title: Text('加入配件'),
                  onTap: () {
                    String value = _vinNo == null ? '' : _vinNo;
                    if (_vinList == null) {
                      widget.showAddProduct(ResultFlag.ng, '請選擇來源名稱', null);
                      //_showMessage(ResultFlag.ng, '請選擇來源名稱');
                      return;
                    }
                    if (value == '' && _vinList == null ||
                        _vinList.length == 0) {
                      widget.showAddProduct(ResultFlag.ng, '請查詢車身號碼', null);
                      //_showMessage(ResultFlag.ng, '請查詢車身號碼');
                      return;
                    }
                    String vinCarLabelsysNo =
                        _vinList.first['廠牌系統碼'].toString();
                    String vinCarLabelsysNo2 =
                        _vinList.first['車款系統碼'].toString();
                    String vinCarLabelsysNo3 =
                        _vinList.first['車型系統碼'].toString();

                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AddProduct(
                                  vinCarLabelsysNo,
                                  (Map<String, dynamic> data) {
                                    if (_vinList
                                            .where((v) =>
                                                v['車身號碼'].toString() == value &&
                                                v['料號'].toString() ==
                                                    data['料號'].toString())
                                            .length >
                                        0) {
                                      widget.showAddProduct(
                                          ResultFlag.ng,
                                          '料號:' +
                                              data['料號'].toString() +
                                              ' ' +
                                              data['品名'].toString() +
                                              ' 已存在',
                                          null);
                                      // _showMessage(
                                      //     ResultFlag.ng,
                                      //     '料號:' +
                                      //         data['料號'].toString() +
                                      //         ' ' +
                                      //         data['品名'].toString() +
                                      //         ' 已存在');
                                      return;
                                    }

                                    // setState(() {
                                    data['車身號碼'] = value;
                                    data['點交次數'] = _vinList.firstWhere((v) =>
                                        v['車身號碼'].toString() == value)['點交次數'];
                                    _vinList.add(data);
                                    //_inputController.text = value;
                                    // _showMessage(
                                    //     ResultFlag.ok,
                                    //     '料號:' +
                                    //         data['料號'].toString() +
                                    //         ' ' +
                                    //         data['品名'].toString() +
                                    //         ' 已加入');
                                    // });
                                    widget.showAddProduct(
                                        ResultFlag.ok,
                                        '料號:' +
                                            data['料號'].toString() +
                                            ' ' +
                                            data['品名'].toString() +
                                            ' 已加入',
                                        _vinList);
                                  },
                                  vinCarLabel2: vinCarLabelsysNo2,
                                  vinCarLabel3: vinCarLabelsysNo3,
                                )));
                  }),
            ),
            Container(
              height: 50,
              color: Colors.white,
              child: ListTile(
                leading: Icon(Icons.apps),
                title: Text('車籍資料'),
                onTap: () {
                  if (_vinNo == '' || _vinNo == null) {
                    widget.showCarInfo(ResultFlag.ng, '請輸入或掃描車身號碼');
                    //_showMessage(ResultFlag.ng, '請輸入或掃描車身號碼');
                    return;
                  }
                  CarInformation.show(context, _vinNo);
                },
              ),
            ),
            Divider(height: 2.0, color: Colors.black),
          ],
        ),
      ),
    );
  }
}

class TVS0100005_Serch extends StatefulWidget {
  // final String vin;
  // TVS0100005_Serch(this.vin);
  String imageCategory = '';

  TVS0100005_Serch({this.imageCategory});
  @override
  State<StatefulWidget> createState() {
    return _TVS0100005_Serch();
  }
}

class _TVS0100005_Serch extends State<TVS0100005_Serch>
    with TickerProviderStateMixin {
  Map<String, dynamic> _serchDropDown = {'船名航次': null, '廠牌': null};
  List<DateTime> _serchPicked = new List(2);
  List<DropdownMenuItem> _dataBoatItems = List<DropdownMenuItem>();
  List<DropdownMenuItem> _dataBrandItems = List<DropdownMenuItem>();
  List<Map<String, dynamic>> _dataCarInfo = List<Map<String, dynamic>>();
  int _groupValue = 0;

  List<String> _serch_Key1 = new List<String>();
  List<String> _serch_Key2 = new List<String>();
  List<String> _serch_Key3 = new List<String>();
  List<String> _serch_Key4 = new List<String>();
  SharedPreferences _prefs;
  bool _loadBoatStats = true;
  @override
  void initState() {
    super.initState();
    initkeyData();
    _loadDateBoat(context);
    _loadDateBrand(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('配件點檢查詢'), actions: <Widget>[
          IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                _clearCarInfo(context);
              }),
          IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                _loadDateCarInfo(context);
              })
        ]),
        body: Column(
          children: <Widget>[
            buildDropdownButton('船名航次', _dataBoatItems, (dynamic value) {
              setState(() {
                _serchDropDown['船名航次'] = value;
                _dataCarInfo.clear();
              });
            }, keyText: '船名航次', keyValue: _serchDropDown),
            //到港日
            buildDateRange(context, (dynamic value) {
              setState(() {
                _dataCarInfo.clear();
              });
            }),
            buildDropdownButton('廠牌', _dataBrandItems, (dynamic value) {
              setState(() {
                _serchDropDown['廠牌'] = value;
                _dataCarInfo.clear();
              });
            }, keyText: '廠牌', keyValue: _serchDropDown),
            Container(
              color: Colors.green,
              height: 5,
            ),
            Row(children: <Widget>[
              Container(
                  //margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
                  height: 40,
                  width: (Business.deviceWidth(context) - 80) / 2,
                  child: RadioListTile(
                    value: 0,
                    groupValue: _groupValue,
                    onChanged: (int value) {
                      setState(() {
                        _groupValue = value;
                      });
                    },
                    title: Text(
                      '未' +
                          (_dataCarInfo.length == 0
                              ? '0'
                              : _dataCarInfo
                                  .where((v) => v['已點檢'].toString() == '0')
                                  .length
                                  .toString()),
                      style: TextStyle(fontSize: 16),
                    ),
                  )),
              Container(
                  //margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
                  height: 40,
                  width: (Business.deviceWidth(context) - 80) / 2,
                  child: RadioListTile(
                    value: 1,
                    groupValue: _groupValue,
                    onChanged: (int value) {
                      setState(() {
                        _groupValue = value;
                      });
                    },
                    title: Text(
                      '已' +
                          _dataCarInfo
                              .where((v) => v['已點檢'].toString() == '1')
                              .length
                              .toString(),
                      style: TextStyle(fontSize: 16),
                    ),
                  )),
            ]),
            _buildCarList(_dataCarInfo
                .where((v) => v['已點檢'].toString() == _groupValue.toString())),
          ],
        ));
  }

  Future<Map<String, dynamic>> initkeyData() async {
    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
      if (_prefs.containsKey(widget.imageCategory + '_TVS0100005_Serch_key1') ==
          true) {
        _serch_Key1 = _prefs
            .getStringList(widget.imageCategory + '_TVS0100005_Serch_key1');
        setState(() {
          _serchDropDown['船名航次'] = _serch_Key1[0];
        });
      }
      if (_prefs.containsKey(widget.imageCategory + '_TVS0100005_Serch_key2') ==
          true) {
        _serch_Key2 = _prefs
            .getStringList(widget.imageCategory + '_TVS0100005_Serch_key2');
        _serchPicked[0] = DateTime.parse(_serch_Key2[0]);
      }
      if (_prefs.containsKey(widget.imageCategory + '_TVS0100005_Serch_key3') ==
          true) {
        _serch_Key3 = _prefs
            .getStringList(widget.imageCategory + '_TVS0100005_Serch_key3');
        _serchPicked[1] = DateTime.parse(_serch_Key3[0]);
      }
      if (_prefs.containsKey(widget.imageCategory + '_TVS0100005_Serch_key4') ==
          true) {
        _serch_Key4 = _prefs
            .getStringList(widget.imageCategory + '_TVS0100005_Serch_key4');
        setState(() {
          _serchDropDown['廠牌'] = _serch_Key4[0];
        });
      }
      return _serchDropDown;
    });
  }

  Widget _buildCarList(Iterable<Map<String, dynamic>> data) {
    if (data == null)
      return Container(child: Text('沒有資料'));
    else {
      return Container(
          width: Business.deviceWidth(context) - 80,
          height: 250,
          child: PageView.builder(
            itemCount: data == null ? 0 : data.length,
            itemBuilder: (BuildContext context, int index) {
              return _buildCarBox(context, data.elementAt(index), index);
            },
            onPageChanged: (int index) {
              // _selectVin = _dataCarInfo[index]['車身號碼'];
            },
          ));
    }
  }

  Widget _buildCarBox(
      BuildContext context, Map<String, dynamic> data, int index) {
    return Card(
      child: Container(
        padding: EdgeInsets.only(top: 20),
        child: Column(
          children: <Widget>[
            //Divider(height: 5),3333
            _buildCarInfoItem('廠牌', data['廠牌'] == null ? '' : data['廠牌'],
                bold: true),
            _buildCarInfoItem('車款', data['車款'] == null ? '' : data['車款']),
            _buildCarInfoButton(
                'VIN', data['車身號碼'] == null ? '' : data['車身號碼']),
            _buildCarInfoItem('儲區', data['儲區'] == null ? '' : data['儲區']),
            _buildCarInfoItem('儲格', data['儲格'] == null ? '' : data['儲格']),
          ],
        ),
      ),
    );
  }

  Widget _buildCarInfoButton(String labelText, String value,
      {bool bold = false,
      Color foreColor = Colors.black,
      Color backColor = Colors.white}) {
    return Container(
      //width: 260,
      //height: 30,
      padding: EdgeInsets.only(left: 0.0, right: 0.0, bottom: 5),
      child: Row(
        children: <Widget>[
          Container(
            width: 50,
            child: Text(labelText,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          Container(child: Text(':')),
          //==============
          //Expanded(

          //child:
          RaisedButton(
            padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
            // decoration: BoxDecoration(
            //     color: backColor,
            //     border:
            //         Border(bottom: BorderSide(width: 1, color: Colors.grey))),
            onPressed: () {
              //_selectVin = txt.text;
              // v['已點檢']  = 已點檢=1 else 0
              int noCheckCount = _dataCarInfo
                  .where((v) =>
                      v['已點檢'].toString() == '1' &&
                      v['車身號碼'].toString() == value)
                  .toList()
                  .length;
              if (noCheckCount == 1) return;
              Navigator.pop(context, value);
            },
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          //),
          //Container(width: 60),
          //================
        ],
      ),
    );
  }

  Widget _buildCarInfoItem(String labelText, String value,
      {bool bold = false,
      Color foreColor = Colors.black,
      Color backColor = Colors.white}) {
    return Container(
      //width: 260,
      //height: 30,
      padding: EdgeInsets.only(left: 0.0, right: 0.0, bottom: 5),
      child: Row(
        children: <Widget>[
          Container(
            width: 50,
            child: Text(labelText,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          Container(child: Text(':')),
          //==============
          Expanded(
            child: Container(
              padding: EdgeInsets.only(left: 5),
              decoration: BoxDecoration(
                  color: backColor,
                  border:
                      Border(bottom: BorderSide(width: 1, color: Colors.grey))),
              child: Text(value,
                  style: TextStyle(
                      color: foreColor,
                      fontSize: 16,
                      fontWeight:
                          bold == true ? FontWeight.bold : FontWeight.normal)),
            ),
          ),
          //Container(width: 60),
          //================
        ],
      ),
    );
  }

  Widget buildDateRange(
      BuildContext context, void Function(dynamic) onChanged) {
    return Container(
        width: Business.deviceWidth(context) - 50,
        child: Row(children: <Widget>[
          RaisedButton(
            child: Text('到港日▾'),
            onPressed: () {
              showPickerDateRange(context, onChanged);
            },
          ),
          //_serch_Key2.length == 0

          Text((_serchPicked[0] != null
                  ? DateFormat('yyyy-MM-dd').format(_serchPicked[0])
                  : '') +
              ' - ' +
              (_serchPicked[1] != null
                  ? DateFormat('yyyy-MM-dd').format(_serchPicked[1])
                  : '')),
        ]));
  }

  void showPickerDateRange(
      BuildContext context, void Function(dynamic) onChanged) {
    //print("canceltext: ${PickerLocalizations.of(context).cancelText}");

    Picker ps = new Picker(
        hideHeader: true,
        adapter: new DateTimePickerAdapter(
            type: PickerDateTimeType.kYMD, isNumberMonth: true),
        onConfirm: (Picker picker, List value) {
          print((picker.adapter as DateTimePickerAdapter).value);
          _serchPicked[0] = (picker.adapter as DateTimePickerAdapter).value;
          //onChanged(_serchPicked[0]);
        });

    Picker pe = new Picker(
        hideHeader: true,
        adapter: new DateTimePickerAdapter(
            type: PickerDateTimeType.kYMD, isNumberMonth: true),
        onConfirm: (Picker picker, List value) {
          print((picker.adapter as DateTimePickerAdapter).value);
          _serchPicked[1] = (picker.adapter as DateTimePickerAdapter).value;
        });

    List<Widget> actions = [
      FlatButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: new Text(PickerLocalizations.of(context).cancelText)),
      FlatButton(
          onPressed: () {
            Navigator.pop(context);
            setState(() {
              ps.onConfirm(ps, ps.selecteds);
              pe.onConfirm(pe, pe.selecteds);
            });
          },
          child: new Text(PickerLocalizations.of(context).confirmText))
    ];

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return new AlertDialog(
            //title: Text(""),
            actions: actions,
            content: Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text("Begin:"),
                  ps.makePicker(),
                  Text("End:"),
                  pe.makePicker()
                ],
              ),
            ),
          );
        });
  }

  Widget buildDropdownButton(
      String labelText,
      List<DropdownMenuItem<dynamic>> itemList,
      void Function(dynamic) onChanged,
      {String keyText = '',
      Map<String, dynamic> keyValue}) {
    return Container(
      padding: EdgeInsets.only(left: 10.0, right: 10.0, top: 0, bottom: 0),
      margin: EdgeInsets.only(top: 0, bottom: 0),
      //height: 70,
      width: Business.deviceWidth(context) - 30,
      child: DropdownButtonFormField(
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(fontSize: 16.0),
          contentPadding: EdgeInsets.only(top: 0, bottom: 0),
          filled: false,
        ),
        // selectedItemBuilder: (BuildContext context) {
        //   return _serchDropDown[labelText] == null ? [] : itemList;
        // },
        items: itemList == null ? [] : itemList,
        value: keyValue[keyText], //_serchDropDown[labelText],
        onChanged: (value) {
          onChanged(value);
        },
      ),
    );
  }

  void _loadDateBoat(BuildContext context) async {
    //if (_dataBoatItems.length == 0) {
    List<DropdownMenuItem> items = new List();
    Datagram datagram = Datagram();
    datagram.addText("""select  isnull(vs003708,vs003703) 到港日
                                 ,vs003701 船名航次
                          from xvms_0037
                          order by isnull(vs003708,vs003703) desc""",
        rowIndex: 0, rowSize: 100);
    debugPrint(datagram.commandList[0].commandText);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    _loadBoatStats = true;
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      _dataBoatItems.clear();
      for (int i = 0; i < data.length; i++) {
        items.add(DropdownMenuItem(
            value: data[i]['船名航次'].toString(),
            child: Container(
              width: Business.deviceWidth(context) - 80,
              child: Text(
                data[i]['到港日'].toString() + data[i]['船名航次'].toString(),
                overflow: TextOverflow.ellipsis,
              ),
            )));
      }
      setState(() {
        _dataBoatItems = items;
        _loadBoatStats = false;
      });

      //return true;
    } else {
      MessageBox.showInformation(context, "", result.getNGMessage());
    }
  }

  void _loadDateBrand(BuildContext context) async {
    //if (_dataBrandItems.length == 0) {
    List<DropdownMenuItem> items = new List();
    Datagram datagram = Datagram();
    datagram.addText("""select distinct 廠牌代碼 廠牌 from vi_xvms_0001_02""",
        rowIndex: 0, rowSize: 100);
    debugPrint(datagram.commandList[0].commandText);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);

    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      _dataBrandItems.clear();

      for (int i = 0; i < data.length; i++) {
        items.add(DropdownMenuItem(
            value: data[i]['廠牌'].toString(),
            child: Container(
              width: Business.deviceWidth(context) - 80,
              child: Text(
                data[i]['廠牌'].toString(),
                overflow: TextOverflow.ellipsis,
              ),
            )));
      }
      //_isLoadingBrand = true;
      setState(() {
        _dataBrandItems = items;
      });

      //return true;
    } else {
      MessageBox.showInformation(context, "", result.getNGMessage());
    }
  }

  Future<bool> _loadDateCarInfo(BuildContext context) async {
    if (_loadBoatStats == true && _serchDropDown['船名航次'] != null) {
      return false;
    }

    if (_serchDropDown['船名航次'] == null &&
        (_serchPicked[0] == null || _serchPicked[1] == null)) {
      MessageBox.showError(context, '查詢條件', '船名航次或到港日 至少選擇一項');
      return false;
    }

    if (_serchPicked[0] != null && _serchPicked[1] != null) {
      if (_serchPicked[1].difference(_serchPicked[0]).inDays > 30) {
        MessageBox.showError(context, '', '請縮小日期區間 最大為30天');
        return false;
      }
    }
    String pick0 = _serchPicked[0] != null
        ? DateFormat('yyyy-MM-dd').format(_serchPicked[0])
        : '';

    String pick1 = _serchPicked[1] != null
        ? DateFormat('yyyy-MM-dd').format(_serchPicked[1])
        : '';
    Datagram datagram = Datagram();
    String sQL = """if(1=1)
    declare @來源名稱 varchar(100)='${_serchDropDown['船名航次'] == null ? '' : _serchDropDown['船名航次']}'
            ,@到港日期1 varchar(10)='$pick0'
            ,@到港日期2 varchar(10)='$pick1'
            ,@廠牌 varchar(100)='${_serchDropDown['廠牌'] == null ? '' : _serchDropDown['廠牌']}'
    
    ;with cte as
    (
    --配件BOM
    select vs003201 廠牌
           ,vs003202 車款
           ,vs003203 車型
    from xvms_0032 
    where isnull(vs003205,'') !=''
    group by vs003201,vs003202,vs003203
    )
    
    select vsaa0102c  廠牌
           ,vsaa0103c 車款
           ,vsaa0100  車身號碼
           ,vsaa0115  儲區
           ,vsaa0116  儲格
           ,iif(t2.vsaa1300 is null,0,1) 已點檢
          ,vsaa0121
    from xvms_aa01 t1 
    left join xvms_aa13 t2 on t1.vsaa0100=t2.vsaa1300 and t1.vsaa0119=t2.vsaa1305
    left join cte t3 on t1.vsaa0102=t3.廠牌 and t1.vsaa0103=t3.車款 and t1.vsaa0104=t3.車型
    where 1=1
          and vsaa0114 not in ('00','10','99')  
          and t3.廠牌 is not null
          and (@來源名稱='' or vsaa0121=@來源名稱) --來源名稱
          and (@到港日期1='' or @到港日期2='' or vsaa0122 between @到港日期1 and @到港日期2) --到港日期
          and (@廠牌='' or vsaa0102c=@廠牌) --廠牌
    order by t2.create_date desc,t2.create_time desc""";
    datagram.addText(sQL, rowIndex: 0, rowSize: 100);
    debugPrint(datagram.commandList[0].commandText);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);

    // _dataBufferFlashType
    //     .add(FlashType.auto.toString());
    // _prefs.setStringList(
    //     'adv_Camera' +
    //         widget.imageCategory +
    //         'FlashType',
    //     _dataBufferFlashType);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      save_searchKey(true);
      setState(() {
        _dataCarInfo = data;
      });

      return true;
    } else {
      MessageBox.showInformation(context, "", result.getNGMessage());
      //_showMessage(ResultFlag.ng, result.getNGMessage());
      return false;
    }
  }

  void save_searchKey(bool saveOfOff) {
    if (saveOfOff == true) {
      if (_serchDropDown['船名航次'] != null) {
        _serch_Key1.clear();
        _serch_Key1.add(_serchDropDown['船名航次'].toString());
        _prefs.setStringList(
            widget.imageCategory + '_TVS0100005_Serch_key1', _serch_Key1);
      }

      if (_serchPicked[0] != '' && _serchPicked[0] != null) {
        _serch_Key2.clear();
        _serch_Key2.add(DateFormat('yyyy-MM-dd').format(_serchPicked[0]));
        _prefs.setStringList(
            widget.imageCategory + '_TVS0100005_Serch_key2', _serch_Key2);
      }
      if (_serchPicked[1] != '' && _serchPicked[1] != null) {
        _serch_Key3.clear();
        _serch_Key3.add(DateFormat('yyyy-MM-dd').format(_serchPicked[1]));
        _prefs.setStringList(
            widget.imageCategory + '_TVS0100005_Serch_key3', _serch_Key3);
      }
      if (_serchDropDown['廠牌'] != null) {
        _serch_Key4.clear();
        _serch_Key4.add(_serchDropDown['廠牌'].toString());
        _prefs.setStringList(
            widget.imageCategory + '_TVS0100005_Serch_key4', _serch_Key4);
      }
    } else if (saveOfOff == false) {
      _prefs.remove(widget.imageCategory + '_TVS0100005_Serch_key1');
      _prefs.remove(widget.imageCategory + '_TVS0100005_Serch_key2');
      _prefs.remove(widget.imageCategory + '_TVS0100005_Serch_key3');
      _prefs.remove(widget.imageCategory + '_TVS0100005_Serch_key4');
    }
  }

  Future<bool> _clearCarInfo(BuildContext context) async {
    setState(() {
      _serchDropDown['船名航次'] = null;
      _serchDropDown['廠牌'] = null;
      _serchPicked[0] = null;
      _serchPicked[1] = null;
      save_searchKey(false);
      _dataCarInfo.clear();
    });
  }
}
