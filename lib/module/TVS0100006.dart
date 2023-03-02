import 'dart:io';
import 'package:adv_camera/adv_camera.dart';
import 'package:car_1/apis/fullscreendialog.dart';
import 'package:car_1/business/enums.dart';
import 'package:car_1/business/result.dart';
import 'package:car_1/module/CameraBoxAdv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import '../model/sysMenu.dart';
import 'package:path_provider/path_provider.dart';
import 'package:car_1/business/datagram.dart';
import 'package:car_1/business/responseresult.dart';
import 'package:car_1/business/business.dart';
import 'package:car_1/apis/messagebox.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'CarSelect.dart';
import 'GeneralFunction.dart';
import 'GeneralWidget.dart';
import 'CameraBox.dart';

class TVS0100006 extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _TVS0100006();
  }
}

class _TVS0100006 extends State<TVS0100006> with TickerProviderStateMixin {
  final String moduleId = 'TVS0100006';
  final String moduleName = '加油作業';
  String _imageCategory = 'TVS0100006';
  final _inputController = TextEditingController();
  final _numberController = TextEditingController();
  final _gasContainerNoController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final FocusNode _textFieldFocusNode = FocusNode();
  final FocusNode _numberFocusNode = FocusNode();
  final FocusNode _gasContainerNoFocusNode = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _onlineMode = true; //true: online false: offline
  bool _isLoading = false;
  int _inputMode = 1; //0: keybarod 1: scanner 2:camera
  List<String> _inputModeList = ['鍵盤', '掃描器', '照相機'];
  int _barcodeFixMode = 0; //0:一般 1:去頭 2:F/U
  List<String> _barcodeFixModeList = ['一般', '去頭', 'F/U'];
  String _message = '';
  ResultFlag _messageFlag = ResultFlag.ok;
  HardwareKeyboardListener _keyboardListen;
  //========================================================
  final Map<String, dynamic> _formData = {
    'scheduleDate': null, //排程日期
    'carLabel': null, //廠牌
    'vsaa1410': '2', //油品種類
    'vsaa1427': 'D', //加油來源
  };
  List<Map<String, dynamic>> _vinList;
  List<Map<String, dynamic>> _vinListPlanOut;
  List<DropdownMenuItem> dateItems; //排程日期
  List<DropdownMenuItem> _carLabelItems; //廠牌
  List<DropdownMenuItem> _vsaa1427Items; //加油來源
  List<DropdownMenuItem> _vsaa1410Items; //油品種類

  List<String> _offlineDataBuffer = List<String>();
  String _vinNo = ''; //車身號碼
  String _vsaa1405 = ''; //點交次數
  String _vsaa1406 = ''; //排程日期
  String _carLabel = ''; //廠牌
  String _carModel = ''; //車款
  String _layer = ''; //原儲位
  String _grid = ''; //原儲格
  String _isProduct = ''; //是否為商品車
  String _fuelCondition = ''; //加油條件
  //String _gasContainerNo = ''; //油槽編號
  int vinCountFuelAll = 0; //總車數
  int vinCountFuelN = 0; //未加油數
  bool _isPlan = true; //計畫性
  bool _isClick = false; //被點擊
  int clickCount = 0;
  String _inputName = '';
  Directory _appDocDir;
  List<Map<String, dynamic>> _files = List();
  int _checkImageCount = 0;
  AdvCameraController cameraController;
  // final AdvCamera advC = new AdvCamera(
  //     onCameraCreated: (and) async{
  //       _picture = await and.getPictureSizes();
  //       //_picture = __picture;
  //     },
  //     onImageCaptured: (path) {},
  //     cameraPreviewRatio: CameraPreviewRatio.r16_9);

  @override
  void initState() {
    // _keyboardListen = new HardwareKeyboardListener(_hardwareInputCallback);
    super.initState();
    _loadPath();
    _loadVSAA1427();
    _loadVSAA1410();
    portraitUp();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SharedPreferences.getInstance().then((prefs) {
      if (prefs.containsKey('TVS0100006') == true)
        _offlineDataBuffer = prefs.getStringList('TVS0100006');
    });

    if ((_inputMode == 1 || _inputMode == 2) &&
        _inputFocusNode.hasFocus == true) {
      SystemChannels.textInput.invokeMethod('TextInput.hide');
      FocusScope.of(context).requestFocus(_textFieldFocusNode);
    }

    if ((_inputMode == 1 || _inputMode == 2) &&
        _textFieldFocusNode.hasFocus == true) {
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(moduleName),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //       //builder: (context) => _buildFunctionMenu_A(context),
              //       builder: (context) => FunctionMenu(),
              //       //builder: (context) => _buildFunctionMenu(context),
              //       fullscreenDialog: false),
              // );
              // Navigator.of(context).pushNamed('/GeneralWidget_test',
              //     arguments: {'inputMode': '$_inputMode'}).then((value) {
              //   新增第二個變數arguments
              //   showDialog(
              //       新增一個對話框，用來顯示回傳的值
              //       context: context,
              //       child: AlertDialog(
              //         content: Text(value),
              //       ));
              //   setState(() {
              //      _inputMode =  int.parse(value);
              //   });

              // });
              //測試相機
              // Navigator.push(
              //     context,
              //     MaterialPageRoute(
              //         builder: (context) =>
              //         // AdvCamera(
              //         //     onCameraCreated: _onCameraCreated,
              //         //     onImageCaptured: (path) {},
              //         //     cameraPreviewRatio: CameraPreviewRatio.r16_9)
              //         CameraBoxAdv('compid', _imageCategory, _vinNo,
              //             (int resultImageCount) {
              //           _checkImageCount = resultImageCount;
              //         })

              //         ));
              //                   showDialog(
              // ////新增一個對話框，用來顯示回傳的值
              // context: context,
              // child: AlertDialog(
              //   content: Text("$_picture"),
              // ));

              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => FunctionMenu(
                        inputMode: _inputMode,
                        onInputModeChange: (int value) {
                          _inputMode = value;
                          debugPrint('輸入模式: ' + _inputMode.toString());
                        },
                        barcodeMode: _barcodeFixMode,
                        onBarcodeChange: (int value) {
                          _barcodeFixMode = value;
                          debugPrint('條碼模式: ' + _barcodeFixMode.toString());
                        },
                        imageCategory: _imageCategory),
                    fullscreenDialog: false),
              );
            },
          )
        ],
      ),
      drawer: buildMenu(context),
      body: WillPopScope(
        //Wrap out body with a `WillPopScope` widget that handles when a user is cosing current route
        onWillPop: () async {
          return false; //return a `Future` with false value so this route cant be popped or closed.
        },
        child: Container(
          child: Container(
            width: Business.deviceWidth(context),
            child: Column(
              children: <Widget>[
                Container(
                  child: Form(
                    key: _formKey,
                    child: Container(
                      child: Column(
                        children: <Widget>[
                          //==== 輸入
                          _buildInputContainer(),
                          //==== 排程日期 | 廠牌
                          // buildDropdownButton(
                          //     '排程日期', 'scheduleDate', _formData, dateItems,
                          //     (dynamic value) {
                          //   setState(() {
                          //     //下拉排程日期後，把焦點放在輸入方塊
                          //     FocusScope.of(context)
                          //         .requestFocus(_textFieldFocusNode);
                          //     _formData['scheduleDate'] = value;
                          //     _loadDataList(value);
                          //   });
                          // }),
                          //==== 廠牌
                          // _buildDropCarLabel(),

                          buildLabel('車身號碼', _vinNo),
                          buildLabel('廠牌', _carLabel),
                          buildLabel('車款', _carModel),
                          buildLabel('儲位', _layer == null ? '' : _layer),
                          buildLabel('儲格', _grid == null ? '' : _grid),
                          Container(
                              width: Business.deviceWidth(context),
                              child: Row(
                                children: [
                                  Container(
                                    width: 200,
                                    child: buildLabel(
                                        '加油條件',
                                        _fuelCondition == null
                                            ? ''
                                            : _fuelCondition,
                                        labelWidth: 70),
                                  ),
                                  _buildGasContainerNo()
                                ],
                              )),
                          buildLabel(
                            '是否為計畫商品車',
                            _isProduct == 'PY'
                                ? '計畫商品車'
                                : _isProduct == 'Y'
                                    ? '商品車'
                                    : _isProduct == 'N'
                                        ? '設備'
                                        : '',
                            labelWidth: 120,
                          ),
                          Container(
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                    child: GestureDetector(
                                  onTap: () {
                                    //查詢總車數
                                    if (_vinList == null || _vinNo == '')
                                      return;
                                    _loadOnevinCountFuelN(_vinNo,
                                        scheduleCars: true);

                                    // showDialog(
                                    //     ////新增一個對話框，用來顯示回傳的值
                                    //     context: context,
                                    //     child: AlertDialog(
                                    //       content: Text("hhh"),
                                    //     ));
                                  },
                                  child:
                                      buildLabel('總車數', '$vinCountFuelAll 台'),
                                )),
                                Expanded(
                                    child: GestureDetector(
                                  onTap: () {
                                    //查詢計畫中未加油數
                                    if (_vinList == null || _vinNo == '')
                                      return;
                                    _loadOnevinCountFuelN(_vinNo,
                                        scheduleCarsN: true);
                                    // showDialog(
                                    //     ////新增一個對話框，用來顯示回傳的值
                                    //     context: context,
                                    //     child: AlertDialog(
                                    //       content: Text("gggg"),
                                    //     ));
                                  },
                                  child: buildLabel(
                                    '計畫中未加油數',
                                    '$vinCountFuelN 台',
                                    labelWidth: 110,
                                  ),
                                ))
                              ],
                            ),
                          ),
                          //是否為計劃性
                          _buildCarInfo1(),
                          _isPlan == false
                              ? Container(
                                  child: Column(
                                    children: <Widget>[
                                      // buildDropdownButton(
                                      //     '油品種類',
                                      //     'vsaa1410',
                                      //     _formData,
                                      //     _vsaa1410Items, (dynamic value) {
                                      //   setState(() {
                                      //     _formData['vsaa1410'] = value;
                                      //   });
                                      // }),
                                      buildDropdownButton(
                                          '加油來源',
                                          'vsaa1427',
                                          _formData,
                                          _vsaa1427Items, (dynamic value) {
                                        setState(() {
                                          _formData['vsaa1427'] = value;
                                        });
                                      }),
                                    ],
                                  ),
                                )
                              : Container(),
                          // _buildCarInfo1(),
                        ],
                      ),
                    ),
                  ),
                ),
                //=================================== Information
                _isLoading == false
                    ? _buildListView()
                    : CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                //================
                _isLoading == false
                    ? buildMessage(context, _messageFlag, _message)
                    : Container(),
              ],
            ),
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

  Widget _buildFunctionMenu(BuildContext context) {
    int inputMode = 1; //0: keybarod 1: scanner 2:camera
    List<String> inputModeList = ['鍵盤', '掃描器', '照相機'];
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
            //   setState(() {
            //     _onlineMode = value;
            //   });
            //   Navigator.pop(context);
            // }),
            //==== InputMode
            // buildInputMode(Color(0xffe1e6ef), _inputMode, (int value) {
            //   setState(() {
            //     if (value == 0) {
            //       FocusScope.of(context).requestFocus(FocusNode());
            //     } else if (value == 1) {
            //       FocusScope.of(context).requestFocus(FocusNode());
            //     } else {
            //       FocusScope.of(context).requestFocus(FocusNode());
            //     }
            //     _inputMode = value;
            //   });
            //   Navigator.pop(context,true);
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(
            //       builder: (context) => _buildFunctionMenu(context),
            //       fullscreenDialog: false),
            // );
            // }),

            //=====測試客製失敗
            // Container(
            //     height: 50,
            //     color: Colors.white,
            //     child: ListTile(
            //         leading: Icon(Icons.apps),
            //         title: Text('輸入模式: ${inputModeList[inputMode]}'),
            //         onTap: () {
            //             if (inputMode == 0) {
            //               inputMode = 1;
            //             } else if (inputMode == 1) {
            //               inputMode = 2;
            //             } else {
            //               inputMode = 0;
            //             }
            //           setState(() {
            //             _inputMode = inputMode;
            //           // _inputName =  _inputModeList[_inputMode];
            //           });
            //         }),
            // ),
            //==== GeneraWidget_test BarcodeMode
            // buildInputMode_A(Color(0xffe1e6ef), _inputMode, (int value) {
            //   setState(() {
            //     if (value == 0){
            //       FocusScope.of(context).requestFocus(FocusNode());
            //     }else if (value == 1){
            //       FocusScope.of(context).requestFocus(FocusNode());
            //     }else{
            //       FocusScope.of(context).requestFocus(FocusNode());
            //     }
            //     _inputMode = value;
            //   });
            // }),
            //==== BarcodeMode
            buildBarcodeMode(Colors.white, _barcodeFixMode, (int value) {
              setState(() {
                _barcodeFixMode = value;
              });
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => _buildFunctionMenu(context),
                    fullscreenDialog: false),
              );
            }),

            //==== DataUpload
            // buildDataUpload(Color(0xffe1e6ef), () {
            //   if (_onlineMode == false) return;
            //   MessageBox.showQuestion(
            //       context,
            //       '共' + (_offlineDataBuffer.length).toString() + '筆資料',
            //       '確定上傳?', yesFunc: () async {
            //     setState(() {
            //       _isLoading = true;
            //     });
            //     List<Map<String, dynamic>> offlineList = [];
            //     Datagram datagram = Datagram();
            //     _offlineDataBuffer.forEach((s) {
            //       String vsaa1427 = s.split('|')[0];
            //       String vsaa1400 = s.split('|')[1];
            //       String vsaa1410 = s.split('|')[2];
            //       String vsaa1414 = s.split('|')[3];

            //       offlineList.add({
            //         'vsaa1427': vsaa1427,
            //         'vsaa1400': vsaa1400,
            //         'vsaa1410': vsaa1410,
            //         'vsaa1414': vsaa1414
            //       });
            //     });
            //     for (Map<String, dynamic> item in offlineList) {
            //       String vsaa1429 =
            //           await _getVSAA1429(item['vsaa1400'].toString());

            //       if (vsaa1429 == 'A') {
            //         CommandField cf = CommandField(
            //           cmdType: CmdType.procedure,
            //           commandText: 'SPX_VSAA14_IN',
            //         );
            //         cf.addParamText('sCMD', vsaa1429); //計劃性
            //         cf.addParamText(
            //             'sVSAA1400', item['vsaa1400'].toString()); //車身號碼
            //         cf.addParamText('sVSAA1410', ''); //油品種類
            //         cf.addParamText(
            //             'sVSAA1414', item['vsaa1414'].toString()); //實際加油公升數
            //         cf.addParamText('sVSAA1420', ''); //加油註記
            //         cf.addParamText('sVSAA1427', ''); //加油來源
            //         cf.addParamText('sUSERID', Business.userId); //加油人員
            //         cf.addParam(ParameterField('oRESULT_FLAG',
            //             ParamType.strings, ParamDirection.output));
            //         cf.addParam(ParameterField(
            //             'oRESULT', ParamType.strings, ParamDirection.output));
            //         datagram.addCommand(cf);
            //       } else {
            //         CommandField cf = CommandField(
            //           cmdType: CmdType.procedure,
            //           commandText: 'SPX_VSAA14_IN',
            //         );
            //         cf.addParamText('sCMD', vsaa1429); //計劃性
            //         cf.addParamText(
            //             'sVSAA1400', item['vsaa1400'].toString()); //車身號碼
            //         cf.addParamText(
            //             'sVSAA1410', item['vsaa1410'].toString()); //油品種類
            //         cf.addParamText(
            //             'sVSAA1414', item['vsaa1414'].toString()); //實際加油公升數
            //         cf.addParamText('sVSAA1420', ''); //加油註記
            //         cf.addParamText(
            //             'sVSAA1427', item['vsaa1427'].toString()); //加油來源
            //         cf.addParamText('sUSERID', Business.userId); //加油人員
            //         cf.addParam(ParameterField('oRESULT_FLAG',
            //             ParamType.strings, ParamDirection.output));
            //         cf.addParam(ParameterField(
            //             'oRESULT', ParamType.strings, ParamDirection.output));
            //         datagram.addCommand(cf);
            //       }
            //     }
            //     if (datagram.commandList.length == 0) {
            //       return;
            //     }
            //     ResponseResult result =
            //         await Business.apiExecuteDatagram(datagram);
            //     if (result.flag == ResultFlag.ok) {
            //       _offlineDataBuffer.clear();
            //       SharedPreferences prefs =
            //           await SharedPreferences.getInstance();
            //       if (prefs.containsKey(moduleId) == true)
            //         prefs.remove(moduleId);
            //     } else
            //       _showMessage(ResultFlag.ng, result.getNGMessage());

            //     setState(() {
            //       _isLoading = false;
            //     });
            //   });
            // }),
            //==== 作業圖庫
            buildGalleryWithSeqNo(context, Colors.white, _imageCategory),
            //==== 拍照
            // buildPhotograph(
            //     context, Color(0xffe1e6ef), _vinNo, _vinList, _imageCategory,
            //     (Map<String, dynamic> map) {
            //   if (map['resultFlag'].toString() == 'ok') {
            //     setState(() {
            //       _vinNo = map['result'].toString();
            //     });
            //   } else {
            //     _showMessage(ResultFlag.ng, map['result'].toString());
            //   }
            // }),
            Divider(height: 2.0, color: Colors.black),
          ],
        ),
      ),
    );
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
                      _loadOnevinCountFuelN(value);
                    }
                  }
                },
                child: TextField(
                  controller: _inputController,
                  focusNode: _textFieldFocusNode,
                  keyboardType: TextInputType.text,
                  onEditingComplete: () {
                    if (_inputMode == 0) {
                      if (_inputController.text.length < 6) return;
                      _loadkeyBoardvinCountFuelN(_inputController.text);
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
          //==== 確認
          Container(
            height: 30,
            width: 60,
            padding: EdgeInsets.only(right: 10),
            child: RaisedButton(
              padding: EdgeInsets.all(1),
              color: Colors.black,
              child: Text('確認',
                  style: TextStyle(fontSize: 20.0, color: Colors.white)),
              onPressed: () {
                if (_isClick == false) {
                  _isClick = true;
                  _saveData();
                }
              },
            ),
          ),
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
                  _gasContainerNoController.text = '';
                  _numberController.text = '';
                });
                if (_inputMode == 1)
                  FocusScope.of(context).requestFocus(_inputFocusNode);
                else
                  FocusScope.of(context).requestFocus(new FocusNode());
              },
            ),
          ),
          //=========== Input Mode
          _inputMode == 2
              ? IconButton(
                  icon: Icon(Icons.camera),
                  onPressed: () async {
                    String barcode;
                    try {
                      barcode = await BarcodeScanner.scan();
                      if (barcode == null) return;
                      _loadOnevinCountFuelN(barcode);
                      FocusScope.of(context).requestFocus(_inputFocusNode);
                    } catch (e) {
                      _showMessage(ResultFlag.ng, 'Scan Barcode Error 請檢查相機權限');
                    }
                  },
                )
              : Container(),
          //=========== Input Mode
        ],
      ),
    );
  }

  Widget _buildDropCarLabel() {
    return Container(
        child: Row(
      children: <Widget>[
        Expanded(
          child: Container(
            padding:
                EdgeInsets.only(left: 20.0, right: 20, top: 10, bottom: 10),
            child: DropdownButtonFormField(
              decoration: InputDecoration(
                labelText: '廠牌',
                labelStyle: TextStyle(fontSize: 14.0),
                contentPadding: EdgeInsets.only(top: 0, bottom: 0),
                filled: false,
              ),
              items: _carLabelItems,
              value: _formData['carLabel'],
              onChanged: (value) {
                setState(() {
                  _formData['carLabel'] = value;
                });
                List<Map<String, dynamic>> data = List<Map<String, dynamic>>();
                data = _vinList;
                data.where((v) => v['廠牌'].toString() == value);
              },
            ),
          ),
        ),
      ],
    ));
  }

  Widget _buildGasContainerNo() {
    return Container(
        //padding: EdgeInsets.only(left: 0.0, right: 0.0, bottom: 3.0),
        child: Row(children: [
      Container(
        width: 80,
        child: Text(
          '油槽編號:',
          style: TextStyle(fontSize: 14.0),
        ),
      ),
      Container(
          width: 50,
          child: TextField(
            readOnly: _isPlan,
            decoration: InputDecoration(
                //labelText: '油槽編號',
                filled: false,
                //contentPadding: EdgeInsets.only(top: 5, bottom: 10),
                counterText: ""),
            controller: _gasContainerNoController,
            focusNode: _gasContainerNoFocusNode,
            onSubmitted: (String value) {
              if (_vinNo == '') return;
              if (value == '') {
                FocusScope.of(context).requestFocus(_gasContainerNoFocusNode);
                return;
              }
              FocusScope.of(context).requestFocus(_numberFocusNode);
            },
            maxLength: 5,
          ))
    ]));
  }

  Widget _buildCarInfo1() {
    return Container(
      padding: EdgeInsets.only(left: 20.0, right: 20.0, bottom: 3.0),
      child: Row(
        children: <Widget>[
          Container(
            width: 80,
            child: Text(
              '公升數:',
              style: TextStyle(fontSize: 14.0),
            ),
          ),
          Expanded(
            child: Container(
                child: TextField(
              controller: _numberController,
              inputFormatters: [
                WhitelistingTextInputFormatter.digitsOnly,
              ],
              focusNode: _numberFocusNode,
              keyboardType: TextInputType.number,
              onSubmitted: (String value) async {
                if (_vinNo == '') return;
                if (value == '' || int.tryParse(value) == null) {
                  FocusScope.of(context).requestFocus(_numberFocusNode);
                  return;
                }
                _numberController.text = value;

                Map<String, dynamic> map;
                map = await CommonMethod.checkCameraPermission();
                if (map['resultFlag'].toString() == 'ng') {
                  FocusScope.of(context).requestFocus(_inputFocusNode);
                  return;
                }
                _checkImageCount = 0;
                showDialog<String>(
                  context: context,
                  builder: (ctx) => FullScreenDialog(
                      // top: 20.0,
                      // left: 1.0,
                      // right: 1.0,
                      // bottom: 20.0,
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      // width: 300,
                      // height: 300,
                      child:
                          // _isLoading == false?
                          Container(
                              color: Colors.white,
                              child: Column(
                                children: <Widget>[
                                  Container(
                                      padding:
                                          EdgeInsets.only(top: 0, bottom: 0),
                                      width: MediaQuery.of(context).size.width -
                                          2.0,
                                      color: Colors.black,
                                      child: Row(
                                        children: <Widget>[
                                          Expanded(
                                            child: Container(
                                              padding:
                                                  EdgeInsets.only(left: 35),
                                              child: Text(
                                                '拍照',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                              icon: Icon(
                                                Icons.exit_to_app,
                                                color: Colors.white,
                                              ),
                                              // onPressed: () async {
                                              //   clickCount++;
                                              //   if (clickCount > 1) return;
                                              //   if (_checkImageCount < 2) {
                                              //     _showMessage(
                                              //         ResultFlag.ng, '圖片總共需要2張');
                                              //     return;
                                              //   }

                                              //   //上傳圖片
                                              //   bool resultBool =
                                              //       await uploadPicture();
                                              //   if (resultBool == true) {
                                              //     //上傳加油資料
                                              //     _saveData();
                                              //     //返回
                                              //     Navigator.of(context).pop();
                                              //   } else {
                                              //     return;
                                              //   }
                                              // }
                                              onPressed: () async {
                                                //_isClick == false ?addGas():_isClick=true;
                                                if (_isClick == false) {
                                                  _isClick = true;
                                                  _isLoading = true;
                                                  addGas();
                                                } else {
                                                  return;
                                                }
                                              }),
                                        ],
                                      )),
                                  SizedBox(height: 1),
                                  Expanded(
                                    child: CameraBoxAdv(
                                        'compid', _imageCategory, _vinNo,
                                        (resultImageCount) {
                                      _checkImageCount = resultImageCount;
                                    }),
                                  ),
                                ],
                              ))
                      // : CircularProgressIndicator(
                      //     valueColor:
                      //         AlwaysStoppedAnimation<Color>(Colors.green),
                      //   )
                      ),
                );

                // showDialog<String>(
                //     context: context,
                //     builder: (ctx) => FullScreenDialog(
                //         top: 50.0,
                //         left: 10.0,
                //         right: 10.0,
                //         bottom: 50.0,
                //         child: CameraBox('compid', _imageCategory,
                //             map['result'].toString())));

                // Navigator.push(
                //     context,
                //     MaterialPageRoute(
                //         builder: (context) => CameraBox('compid',
                //             _imageCategory, map['result'].toString())));

                // FocusScope.of(context).requestFocus(_inputFocusNode);
              },
            )),
          ),
        ],
      ),
    );
  }

  void addGas() async {
    if (_checkImageCount < 2) {
      //檢查車身號碼是否有拍照
      int _filecount = 0;
      _loadFiles();
      if (_files != null)
        _filecount = _files.where((v) => v['車身號碼'] == _vinNo).toList().length;
      if (_filecount < 2) {
        _showMessage(ResultFlag.ng, '請拍照,至少2張,車身:' + _vinNo);
        _isClick = false;
        _isLoading = false;
        Navigator.of(context).pop();
        return;
      }
      // _isLoading = false;
      // _isClick = false;
      // _showMessage(ResultFlag.ng, '圖片總共需要2張');
      // Navigator.of(context).pop();
      // return;
    }
    // //上傳圖片
    // bool resultBool = await uploadPicture();
    // if (resultBool == true) {
    //   //上傳加油資料
    //   _saveData();
    //   //返回
    //   Navigator.of(context).pop();
    // } else {
    //   Navigator.of(context).pop();
    //   return;
    // }
    _saveData();
    Navigator.of(context).pop();
  }

  Widget _buildListView() {
    return Expanded(
      child: Column(children: <Widget>[
        Container(
            decoration: new BoxDecoration(
                border: new Border.all(color: Colors.grey, width: 0.5)),
            width: Business.deviceWidth(context) - 40,
            child: Row(
              children: <Widget>[
                Container(
                    padding: EdgeInsets.only(left: 0),
                    width: 90,
                    child: Text('廠牌'),
                    color: Colors.black12),
                Container(
                    padding: EdgeInsets.only(left: 0),
                    width: 90,
                    child: Text('車款'),
                    color: Colors.black12),
                Expanded(
                  child: Container(
                      padding: EdgeInsets.only(right: 0),
                      child: Text('車身號碼'),
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
      return Container(child: Text('沒有資料'));
    else {
      return Container(
        width: Business.deviceWidth(context) - 40,
        child: ListView.builder(
          itemCount: data == null ? 0 : data.length,
          itemBuilder: (BuildContext context, int index) {
            return _buildVinItem(context, data[index]);
          },
        ),
      );
    }
  }

  Widget _buildVinItem(BuildContext context, Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () {
        setState(() {
          //_inputController.text = data['車身號碼'].toString();
          _vinNo = data['車身號碼'] == null ? '' : data['車身號碼']; //車身號碼
          _carLabel = data['廠牌'] == null ? '' : data['廠牌']; //廠牌
          _carModel = data['車款'] == null ? '' : data['車款']; //車款
          _layer = data['原儲位'] == null ? '' : data['原儲位']; //原儲位
          _grid = data['原儲格'] == null ? '' : data['原儲格']; //原儲格
          _fuelCondition = data['加油條件'] == null ? '' : data['加油條件']; //加油條件
          _gasContainerNoController.text =
              data['油槽編號'] == null ? '' : data['油槽編號'];
          _numberController.text = '';
          _showMessage(ResultFlag.ok, '');
          if (data['旗標'] != null && data['旗標'] == 'PY' && data['加油狀態'] == 'N') {
            _isPlan = true;
            _isProduct = data['旗標'].toString();
            FocusScope.of(context).requestFocus(_numberFocusNode);
          } else {
            _isPlan = false;
            _isProduct = data['旗標'].toString();
            FocusScope.of(context).requestFocus(_gasContainerNoFocusNode);
          }
        });
      },
      child: Container(
        height: 36,
        decoration: new BoxDecoration(
            color: data['加油狀態'] == 'Y'
                ? Colors.lime
                : data['加油狀態'] == 'X'
                    ? Colors.lime[300]
                    : data['旗標'] == 'Y'
                        ? Colors.deepPurple[200]
                        : data['旗標'] == 'N'
                            ? Colors.cyan[200]
                            : Colors.white,
            border: new Border.all(color: Colors.grey, width: 0.5)),
        child: Row(
          children: <Widget>[
            //廠牌
            Container(
              padding: EdgeInsets.only(left: 2),
              width: 90,
              child: Text(
                data['廠牌'] == null
                    ? ''
                    : (data['廠牌'].toString().length > 10
                        ? '...' +
                            data['廠牌']
                                .toString()
                                .substring(data['廠牌'].toString().length - 10)
                                .trim()
                        : data['廠牌'].toString()),
                style: TextStyle(fontSize: 12),
              ),
              // color: Colors.white,
            ),
            //車款
            Container(
              width: 90,
              child: Text(
                data['車款'] == null
                    ? ''
                    : (data['車款'].toString().length > 10
                        ? '...' +
                            data['車款']
                                .toString()
                                .substring(data['車款'].toString().length - 10)
                                .trim()
                        : data['車款'].toString()),
                style: TextStyle(fontSize: 12),
              ),
              // color: Colors.white,
            ),
            //車身號碼
            Expanded(
              child: Container(
                child: Text(
                  data['車身號碼'] == null ? '' : data['車身號碼'].toString(),
                  style: TextStyle(fontSize: 12),
                ),
                // color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(ResultFlag flag, String message) {
    setState(() {
      _messageFlag = flag;
      _message = message;
    });
    CommonMethod.playSound(flag);
  }

  // void _inputData(String value) async {
  //   value = value.replaceAll('/', '');
  //   // if (_inputMode != 0) _vinListPlanOut = null;
  //   setState(() {
  //     _inputController.text = '';
  //     _vinNo = '';
  //     _carLabel = '';
  //     _carModel = '';
  //     _layer = '';
  //     _grid = '';
  //     _fuelCondition = '';
  //   });
  //   if (_vinList == null || _vinList.length == 0) {
  //     // _showMessage(ResultFlag.ng, '請選擇排程日期');
  //     FocusScope.of(context).requestFocus(_inputFocusNode);
  //     return;
  //   }
  //   if (value == '') {
  //     _showMessage(ResultFlag.ng, '請輸入或掃描車身號碼');
  //     FocusScope.of(context).requestFocus(_inputFocusNode);
  //     return;
  //   }
  //   int fullCount = 0;
  //   int startWithCount = 0;
  //   int endWithCount = 0;
  //   fullCount = _vinList.where((v) => v['車身號碼'].toString() == value).length;
  //   startWithCount = _vinList
  //       .where((v) => v['車身號碼'].toString().startsWith(value) == true)
  //       .length;
  //   endWithCount = _vinList
  //       .where((v) => v['車身號碼'].toString().endsWith(value) == true)
  //       .length;
  //   if (fullCount > 0 || startWithCount > 0 || endWithCount > 0) {
  //     if (fullCount == 1) {
  //       if (_vinList
  //               .firstWhere((v) => v['車身號碼'].toString() == value)['加油狀態']
  //               .toString() ==
  //           'Y') {
  //         _showMessage(ResultFlag.ng, '車身號碼:' + value + ' 已完成加油');
  //         FocusScope.of(context).requestFocus(_inputFocusNode);
  //         return;
  //       }
  //       setState(() {
  //         _vinNo = _vinList
  //             .firstWhere((v) => v['車身號碼'].toString() == value)['車身號碼']
  //             .toString();
  //         _carLabel = _vinList
  //             .firstWhere((v) => v['車身號碼'].toString() == value)['廠牌']
  //             .toString();
  //         _carModel = _vinList
  //             .firstWhere((v) => v['車身號碼'].toString() == value)['車款']
  //             .toString();
  //         _layer = _vinList
  //             .firstWhere((v) => v['車身號碼'].toString() == value)['原儲位']
  //             .toString();
  //         _grid = _vinList
  //             .firstWhere((v) => v['車身號碼'].toString() == value)['原儲格']
  //             .toString();
  //         _fuelCondition = _vinList
  //             .firstWhere((v) => v['車身號碼'].toString() == value)['加油條件']
  //             .toString();
  //         //點交次數
  //         _vsaa1405 = _vinList
  //             .firstWhere((v) => v['車身號碼'].toString() == value)['點交次數']
  //             .toString();
  //         //排程日期
  //         _vsaa1406 = _vinList
  //             .firstWhere((v) => v['車身號碼'].toString() == value)['排程日期']
  //             .toString();
  //         //是否為計畫商品車
  //         _isProduct = _vinList
  //             .firstWhere((v) => v['車身號碼'].toString() == value)['旗標']
  //             .toString();
  //       });
  //     } else if (startWithCount == 1) {
  //       if (_vinList
  //               .firstWhere((v) => v['車身號碼'].toString() == value)['加油狀態']
  //               .toString() ==
  //           'Y') {
  //         _showMessage(ResultFlag.ng, '車身號碼:' + value + ' 已完成加油');
  //         FocusScope.of(context).requestFocus(_inputFocusNode);
  //         return;
  //       }
  //       setState(() {
  //         _vinNo = _vinList
  //             .firstWhere(
  //                 (v) => v['車身號碼'].toString().startsWith(value) == true)['車身號碼']
  //             .toString();
  //         _carLabel = _vinList
  //             .firstWhere(
  //                 (v) => v['車身號碼'].toString().startsWith(value) == true)['廠牌']
  //             .toString();
  //         _carModel = _vinList
  //             .firstWhere(
  //                 (v) => v['車身號碼'].toString().startsWith(value) == true)['車款']
  //             .toString();
  //         _layer = _vinList
  //             .firstWhere(
  //                 (v) => v['車身號碼'].toString().startsWith(value) == true)['原儲位']
  //             .toString();
  //         _grid = _vinList
  //             .firstWhere(
  //                 (v) => v['車身號碼'].toString().startsWith(value) == true)['原儲格']
  //             .toString();
  //         _fuelCondition = _vinList
  //             .firstWhere(
  //                 (v) => v['車身號碼'].toString().startsWith(value) == true)['加油條件']
  //             .toString();
  //         //點交次數
  //         _vsaa1405 = _vinList
  //             .firstWhere(
  //                 (v) => v['車身號碼'].toString().startsWith(value) == true)['點交次數']
  //             .toString();
  //         //排程日期
  //         _vsaa1406 = _vinList
  //             .firstWhere(
  //                 (v) => v['車身號碼'].toString().startsWith(value) == true)['排程日期']
  //             .toString();
  //         //是否為計畫商品車
  //         _isProduct = _vinList
  //             .firstWhere((v) => v['車身號碼'].toString() == value)['旗標']
  //             .toString();
  //       });
  //     } else if (endWithCount == 1) {
  //       if (_vinList
  //               .firstWhere((v) => v['車身號碼'].toString() == value)['加油狀態']
  //               .toString() ==
  //           'Y') {
  //         _showMessage(ResultFlag.ng, '車身號碼:' + value + ' 已完成加油');
  //         FocusScope.of(context).requestFocus(_inputFocusNode);
  //         return;
  //       }
  //       setState(() {
  //         _vinNo = _vinList
  //             .firstWhere(
  //                 (v) => v['車身號碼'].toString().endsWith(value) == true)['車身號碼']
  //             .toString();
  //         _carLabel = _vinList
  //             .firstWhere(
  //                 (v) => v['車身號碼'].toString().endsWith(value) == true)['廠牌']
  //             .toString();
  //         _carModel = _vinList
  //             .firstWhere(
  //                 (v) => v['車身號碼'].toString().endsWith(value) == true)['車款']
  //             .toString();
  //         _layer = _vinList
  //             .firstWhere(
  //                 (v) => v['車身號碼'].toString().endsWith(value) == true)['原儲位']
  //             .toString();
  //         _grid = _vinList
  //             .firstWhere(
  //                 (v) => v['車身號碼'].toString().endsWith(value) == true)['原儲格']
  //             .toString();
  //         _fuelCondition = _vinList
  //             .firstWhere(
  //                 (v) => v['車身號碼'].toString().endsWith(value) == true)['加油條件']
  //             .toString();
  //         //點交次數
  //         _vsaa1405 = _vinList
  //             .firstWhere(
  //                 (v) => v['車身號碼'].toString().endsWith(value) == true)['點交次數']
  //             .toString();
  //         //排程日期
  //         _vsaa1406 = _vinList
  //             .firstWhere(
  //                 (v) => v['車身號碼'].toString().endsWith(value) == true)['排程日期']
  //             .toString();
  //         //是否為計畫商品車
  //         _isProduct = _vinList
  //             .firstWhere((v) => v['車身號碼'].toString() == value)['旗標']
  //             .toString();
  //       });
  //     } else if (fullCount > 1) {
  //       List<Map<String, dynamic>> list = List();

  //       _vinList
  //           .where((v) => v['車身號碼'].toString() == value)
  //           .toList()
  //           .forEach((f) {
  //         list.add({
  //           '車身號碼': f['車身號碼'].toString(),
  //         });
  //       });
  //       // value = await CarSelect.showWithList(context, list);
  //       // if (value == null) {
  //       //   _showMessage(ResultFlag.ng, '請選擇車身號碼');
  //       //   FocusScope.of(context).requestFocus(_inputFocusNode);
  //       //   return;
  //       // }
  //       if (_vinList
  //               .firstWhere((v) => v['車身號碼'].toString() == value)['加油狀態']
  //               .toString() ==
  //           'Y') {
  //         _showMessage(ResultFlag.ng, '車身號碼:' + value + ' 已完成加油');
  //         FocusScope.of(context).requestFocus(_inputFocusNode);
  //         return;
  //       }
  //       setState(() {
  //         _vinNo = _vinList
  //             .firstWhere((v) => v['車身號碼'].toString() == value)['車身號碼']
  //             .toString();
  //         _carLabel = _vinList
  //             .firstWhere((v) => v['車身號碼'].toString() == value)['廠牌']
  //             .toString();
  //         _carModel = _vinList
  //             .firstWhere((v) => v['車身號碼'].toString() == value)['車款']
  //             .toString();
  //         _layer = _vinList
  //             .firstWhere((v) => v['車身號碼'].toString() == value)['原儲位']
  //             .toString();
  //         _grid = _vinList
  //             .firstWhere((v) => v['車身號碼'].toString() == value)['原儲格']
  //             .toString();
  //         _fuelCondition = _vinList
  //             .firstWhere((v) => v['車身號碼'].toString() == value)['加油條件']
  //             .toString();
  //         //點交次數
  //         _vsaa1405 = _vinList
  //             .firstWhere((v) => v['車身號碼'].toString() == value)['點交次數']
  //             .toString();
  //         //排程日期
  //         _vsaa1406 = _vinList
  //             .firstWhere((v) => v['車身號碼'].toString() == value)['排程日期']
  //             .toString();
  //         //是否為計畫商品車
  //         _isProduct = _vinList
  //             .firstWhere((v) => v['車身號碼'].toString() == value)['旗標']
  //             .toString();
  //       });
  //     } else if (startWithCount > 1) {
  //       List<Map<String, dynamic>> list = List();
  //       _vinList
  //           .where((v) => v['車身號碼'].toString().startsWith(value) == true)
  //           .toList()
  //           .forEach((f) {
  //         list.add({
  //           '車身號碼': f['車身號碼'].toString(),
  //         });
  //       });
  //       // value = await CarSelect.showWithList(context, list);
  //       // if (value == null) {
  //       //   _showMessage(ResultFlag.ng, '請選擇車身號碼');
  //       //   FocusScope.of(context).requestFocus(_inputFocusNode);
  //       //   return;
  //       // }
  //       if (_vinList
  //               .firstWhere((v) => v['車身號碼'].toString() == value)['加油狀態']
  //               .toString() ==
  //           'Y') {
  //         _showMessage(ResultFlag.ng, '車身號碼:' + value + ' 已完成加油');
  //         FocusScope.of(context).requestFocus(_inputFocusNode);
  //         return;
  //       }
  //       setState(() {
  //         _vinNo = _vinList
  //             .firstWhere((v) => v['車身號碼'].toString() == value)['車身號碼']
  //             .toString();
  //         _carLabel = _vinList
  //             .firstWhere((v) => v['車身號碼'].toString() == value)['廠牌']
  //             .toString();
  //         _carModel = _vinList
  //             .firstWhere((v) => v['車身號碼'].toString() == value)['車款']
  //             .toString();
  //         _layer = _vinList
  //             .firstWhere((v) => v['車身號碼'].toString() == value)['原儲位']
  //             .toString();
  //         _grid = _vinList
  //             .firstWhere((v) => v['車身號碼'].toString() == value)['原儲格']
  //             .toString();
  //         _fuelCondition = _vinList
  //             .firstWhere((v) => v['車身號碼'].toString() == value)['加油條件']
  //             .toString();
  //         //點交次數
  //         _vsaa1405 = _vinList
  //             .firstWhere((v) => v['車身號碼'].toString() == value)['點交次數']
  //             .toString();
  //         //排程日期
  //         _vsaa1406 = _vinList
  //             .firstWhere((v) => v['車身號碼'].toString() == value)['排程日期']
  //             .toString();
  //         //是否為計畫商品車
  //         _isProduct = _vinList
  //             .firstWhere((v) => v['車身號碼'].toString() == value)['旗標']
  //             .toString();
  //       });
  //     } else if (endWithCount > 1) {
  //       List<Map<String, dynamic>> list = List();
  //       _vinList
  //           .where((v) => v['車身號碼'].toString().endsWith(value) == true)
  //           .toList()
  //           .forEach((f) {
  //         list.add({
  //           '車身號碼': f['車身號碼'].toString(),
  //         });
  //       });
  //       // value = await CarSelect.showWithList(context, list);
  //       // if (value == null) {
  //       //   _showMessage(ResultFlag.ng, '請選擇車身號碼');
  //       //   FocusScope.of(context).requestFocus(_inputFocusNode);
  //       //   return;
  //       // }
  //       if (_vinList
  //               .firstWhere((v) => v['車身號碼'].toString() == value)['加油狀態']
  //               .toString() ==
  //           'Y') {
  //         _showMessage(ResultFlag.ng, '車身號碼:' + value + ' 已完成加油');
  //         FocusScope.of(context).requestFocus(_inputFocusNode);
  //         return;
  //       }

  //       setState(() {
  //         _vinNo = _vinList
  //             .firstWhere((v) => v['車身號碼'].toString() == value)['車身號碼']
  //             .toString();
  //         _carLabel = _vinList
  //             .firstWhere((v) => v['車身號碼'].toString() == value)['廠牌']
  //             .toString();
  //         _carModel = _vinList
  //             .firstWhere((v) => v['車身號碼'].toString() == value)['車款']
  //             .toString();
  //         _layer = _vinList
  //             .firstWhere((v) => v['車身號碼'].toString() == value)['原儲位']
  //             .toString();
  //         _grid = _vinList
  //             .firstWhere((v) => v['車身號碼'].toString() == value)['原儲格']
  //             .toString();
  //         _fuelCondition = _vinList
  //             .firstWhere((v) => v['車身號碼'].toString() == value)['加油條件']
  //             .toString();
  //         //點交次數
  //         _vsaa1405 = _vinList
  //             .firstWhere((v) => v['車身號碼'].toString() == value)['點交次數']
  //             .toString();
  //         //排程日期
  //         _vsaa1406 = _vinList
  //             .firstWhere((v) => v['車身號碼'].toString() == value)['排程日期']
  //             .toString();
  //         //是否為計畫商品車
  //         _isProduct = _vinList
  //             .firstWhere((v) => v['車身號碼'].toString() == value)['旗標']
  //             .toString();
  //       });
  //     } else {
  //       _showMessage(
  //           ResultFlag.ng, '找不到符合一筆以上的車身號碼:' + value + ' 請輸入完整或檢查資料來源');
  //       FocusScope.of(context).requestFocus(_inputFocusNode);
  //       return;
  //     }
  //     setState(() {
  //       for (Map<String, dynamic> data in _vinList) {
  //         if (data['旗標'] != null && data['旗標'] == 'PY' && data['加油狀態'] == 'N' && data['車身號碼']== _vinNo) {
  //           _isPlan = true;
  //           _isProduct = data['旗標'].toString();
  //         } else {
  //           _isPlan = false;
  //           _isProduct = data['旗標'].toString();
  //         }
  //       }
  //     });
  //   } else {
  //     setState(() {
  //       _vinNo = value;
  //       _isPlan = true;
  //       FocusScope.of(context).requestFocus(_numberFocusNode);
  //     });
  //   }

  //   setState(() {
  //     _messageFlag = ResultFlag.ok;
  //     _message = '車身號碼OK';
  //     _numberController.text = '';
  //     FocusScope.of(context).requestFocus(_numberFocusNode);
  //   });
  // }

  void _inputData(String value) async {
    value = value.replaceAll('/', '');
    setState(() {
      _inputController.text = '';
      _vinNo = '';
      _carLabel = '';
      _carModel = '';
      _layer = '';
      _grid = '';
      _fuelCondition = '';
      _gasContainerNoController.text = ''; //油槽編號
    });

    if (_vinList == null || _vinList.length == 0) {
      // _showMessage(ResultFlag.ng, '請選擇排程日期');
      FocusScope.of(context).requestFocus(_inputFocusNode);
      return;
    }
    if (value == '') {
      _showMessage(ResultFlag.ng, '請輸入或掃描車身號碼');
      FocusScope.of(context).requestFocus(_inputFocusNode);
      return;
    }
    int fullCount = 0;
    fullCount = _vinList.where((v) => v['車身號碼'].toString() == value).length;
    if (fullCount > 0) {
      if (fullCount == 1) {
        if (_vinList
                    .firstWhere((v) => v['車身號碼'].toString() == value)['加油狀態']
                    .toString() ==
                'Y' ||
            _vinList
                    .firstWhere((v) => v['車身號碼'].toString() == value)['加油狀態']
                    .toString() ==
                '') {
          setState(() {
            _vinNo = _vinList
                .firstWhere((v) => v['車身號碼'].toString() == value)['車身號碼']
                .toString();
            _carLabel = _vinList
                .firstWhere((v) => v['車身號碼'].toString() == value)['廠牌']
                .toString();
            _carModel = _vinList
                .firstWhere((v) => v['車身號碼'].toString() == value)['車款']
                .toString();
            _layer = _vinList
                .firstWhere((v) => v['車身號碼'].toString() == value)['原儲位']
                .toString();
            _grid = _vinList
                .firstWhere((v) => v['車身號碼'].toString() == value)['原儲格']
                .toString();
            _fuelCondition = _vinList
                .firstWhere((v) => v['車身號碼'].toString() == value)['加油條件']
                .toString();
            //點交次數
            _vsaa1405 = _vinList
                .firstWhere((v) => v['車身號碼'].toString() == value)['點交次數']
                .toString();
            //排程日期
            _vsaa1406 = _vinList
                .firstWhere((v) => v['車身號碼'].toString() == value)['排程日期']
                .toString();
            //是否為計畫商品車
            _isProduct = _vinList
                .firstWhere((v) => v['車身號碼'].toString() == value)['旗標']
                .toString();
            _gasContainerNoController.text = _vinList
                .firstWhere((v) => v['車身號碼'].toString() == value)['油槽編號']
                .toString();
            _isPlan = false;
          });
          if (_isProduct == 'N') {
            _showMessage(ResultFlag.ng, '車身號碼:' + value + ' 屬於設備加油');
          } else {
            _showMessage(ResultFlag.ok, '車身號碼:' + value + ' 屬於計畫外加油');
          }

          FocusScope.of(context).requestFocus(_inputFocusNode);
          return;
        } else {
          setState(() {
            _vinNo = _vinList
                .firstWhere((v) => v['車身號碼'].toString() == value)['車身號碼']
                .toString();
            _carLabel = _vinList
                .firstWhere((v) => v['車身號碼'].toString() == value)['廠牌']
                .toString();
            _carModel = _vinList
                .firstWhere((v) => v['車身號碼'].toString() == value)['車款']
                .toString();
            _layer = _vinList
                .firstWhere((v) => v['車身號碼'].toString() == value)['原儲位']
                .toString();
            _grid = _vinList
                .firstWhere((v) => v['車身號碼'].toString() == value)['原儲格']
                .toString();
            _fuelCondition = _vinList
                .firstWhere((v) => v['車身號碼'].toString() == value)['加油條件']
                .toString();
            //點交次數
            _vsaa1405 = _vinList
                .firstWhere((v) => v['車身號碼'].toString() == value)['點交次數']
                .toString();
            //排程日期
            _vsaa1406 = _vinList
                .firstWhere((v) => v['車身號碼'].toString() == value)['排程日期']
                .toString();
            //是否為計畫商品車
            _isProduct = _vinList
                .firstWhere((v) => v['車身號碼'].toString() == value)['旗標']
                .toString();
            _gasContainerNoController.text = _vinList
                .firstWhere((v) => v['車身號碼'].toString() == value)['油槽編號']
                .toString();
            _isPlan = true;
          });
          setState(() {
            for (Map<String, dynamic> data in _vinList) {
              if (data['旗標'] != null &&
                  data['旗標'] == 'PY' &&
                  data['加油狀態'] == 'N' &&
                  data['車身號碼'] == _vinNo) {
                _isPlan = true;
                _isProduct = data['旗標'].toString();
              } else {
                _isPlan = false;
                _isProduct = data['旗標'].toString();
              }
            }
          });
          setState(() {
            _messageFlag = ResultFlag.ok;
            _message = '車身號碼OK';
            _numberController.text = '';
            FocusScope.of(context).requestFocus(_numberFocusNode);
          });
        }
      } else {}
    } else {
      //無論是barCode 拍照 都只能有一筆
      _showMessage(ResultFlag.ng, '找不到符合一筆以上的車身號碼:' + value + ' 請輸入完整或檢查資料來源');
      FocusScope.of(context).requestFocus(_inputFocusNode);
      return;
    }
  }

  // Widget createAdvCamera() {
  //   return Expanded(
  //     child: Container(
  //       child: AdvCamera(
  //           onCameraCreated: _onCameraCreated,
  //           onImageCaptured: (path) {},
  //           cameraPreviewRatio: CameraPreviewRatio.r16_9),
  //     ),
  //   );
  // }

  // //取得相機畫素
  // void _onCameraCreated(AdvCameraController controller) async {
  //   // if (_picture.length == 0) {

  //   List<String> __picture = await cameraController.getPictureSizes();
  //   setState(() {
  //     _picture = __picture;
  //   });

  //   debugPrint(_picture.length.toString() + '   ggggggggggggggggggggggggggggg');
  //   // }
  // }

  //確認完成加油
  void _saveData() async {
    if (_vinNo == '') {
      _showMessage(ResultFlag.ng, '請輸入或掃描車身號碼');
      return;
    }

    //檢查車身號碼是否有拍照
    int _filecount = 0;
    _loadFiles();
    if (_files != null)
      _filecount = _files.where((v) => v['車身號碼'] == _vinNo).toList().length;
    if (_filecount < 2) {
      _showMessage(ResultFlag.ng, '請拍照,至少2張,車身:' + _vinNo);
      _isClick = false;
      _isLoading = false;
      return;
    }

    if (_numberController.text == '') {
      _showMessage(ResultFlag.ng, '請輸入公升數');
      _isClick = false;
      _isLoading = false;
      return;
    }
    if (_gasContainerNoController.text == '') {
      _showMessage(ResultFlag.ng, '請輸入油槽編號');
      _isClick = false;
      _isLoading = false;
      return;
    }
    if (_gasContainerNoController.text.length < 5) {
      _showMessage(ResultFlag.ng, '油槽編號長度必須是5碼');
      _isClick = false;
      _isLoading = false;
      return;
    }
    String _qty = _numberController.text;
    String _gasContainerNo =
        _gasContainerNoController.text.trim().toUpperCase();
    String vsaa1410 = _gasContainerNo.substring(0, 2);

    //==== online
    if (_onlineMode == true) {
      String vsaa1429 = await _getVSAA1429(_vinNo);
      if (vsaa1429 == '') return;
      bool resultbool = false;
      //計劃性
      if (vsaa1429 == 'A') {
        if (_vinList
                .firstWhere((v) => v['車身號碼'].toString() == _vinNo)['加油狀態']
                .toString() ==
            'Y') {
          vsaa1429 = 'B'; //計畫中加過還要在加則為非計畫性
          // _showMessage(ResultFlag.ng, '車身號碼:' + _vinNo + ' 已完成加油');
          // FocusScope.of(context).requestFocus(_inputFocusNode);
        }

        resultbool = await xvmsaa14in(
            vsaa1429, //計劃性
            '', //加油來源
            _vinNo, //車身號碼
            '', //油品種類
            _qty, //實際加油公升數
            '', //加油註記
            _gasContainerNo //油槽編號
            );
        if (resultbool == true) {
          if (await uploadPicture() == true) {} //資料無誤再上傳圖片
          _vinList.firstWhere((v) => v['車身號碼'].toString() == _vinNo)['加油狀態'] =
              'Y';
          if (vinCountFuelN != 0) vinCountFuelN--;
          _showMessage(ResultFlag.ok, '加油完成');
          //刪除照片
          CommonMethod.removeFilesOfDirNoQuestion(
              context, 'compid/$_imageCategory', _vinNo);
          _isClick = false;
          _isLoading = false;
          FocusScope.of(context).requestFocus(_inputFocusNode);
        } else {
          _isClick = false;
          _isLoading = false;
          FocusScope.of(context).requestFocus(new FocusNode());
          return;
        }
      }
      //非計畫性
      else if (vsaa1429 == 'B') {
        //若有一筆屬於非計畫性但是 _isPaln卻是true/就是異常
        if (_vinList
                    .where((v) =>
                        v['加油狀態'].toString() == 'Y' ||
                        v['加油狀態'].toString() == '')
                    .length <
                1 &&
            _isPlan == true) {
          _showMessage(ResultFlag.ng, '車號 $_vinNo 加油失敗/發生異常');
          return;
        }

        resultbool = await xvmsaa14in(
            vsaa1429, //計劃性
            _formData['vsaa1427'].toString(), //加油來源
            _vinNo, //車身號碼
            (vsaa1410 == '92'
                ? '1'
                : vsaa1410 == '95'
                    ? '2'
                    : vsaa1410 == '98'
                        ? '3'
                        : vsaa1410 == 'DL'
                            ? 'Z'
                            : 'XX'), //油品種類 _formData['vsaa1410'].toString()
            _qty, //實際加油公升數
            '', //加油註記
            _gasContainerNo //油槽編號
            );
        if (resultbool == true) {
          if (await uploadPicture() == true) {} //資料無誤再上傳圖片
          _showMessage(ResultFlag.ok, '加油完成');
          //刪除照片
          CommonMethod.removeFilesOfDirNoQuestion(
              context, 'compid/$_imageCategory', _vinNo);
          _isClick = false;
          _isLoading = false;
          FocusScope.of(context).requestFocus(_inputFocusNode);
        } else {
          //刪除照片測試失敗則恢復
          // CommonMethod.removeFilesOfDirNoQuestion(
          //     context, 'compid/$_imageCategory', _vinNo);
          setState(() {
            _isClick = false;
            _isLoading = false;
          });
          FocusScope.of(context).requestFocus(new FocusNode());
          return;
        }
      }
    }
    //==== offline
    else {
      if (_vinList
              .firstWhere((v) => v['車身號碼'].toString() == _vinNo)['加油狀態']
              .toString() ==
          'Y') {
        _showMessage(ResultFlag.ng, '車身號碼:' + _vinNo + ' 已完成加油');
        FocusScope.of(context).requestFocus(_inputFocusNode);
        return;
      }

      _vinList.firstWhere((v) => v['車身號碼'].toString() == _vinNo)['加油狀態'] = 'Y';
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey('TVS0100006') == true)
        _offlineDataBuffer = prefs.getStringList('TVS0100006');

      setState(() {
        _offlineDataBuffer.add(_formData['vsaa1427'].toString() +
            '|' +
            _vinNo +
            '|' +
            _formData['vsaa1410'].toString() +
            '|' +
            _qty);
      });
      prefs.setStringList('TVS0100006', _offlineDataBuffer);
      _showMessage(ResultFlag.ok, '加油完成(離線)');
      FocusScope.of(context).requestFocus(_inputFocusNode);
      if (vinCountFuelN != 0) vinCountFuelN--;
    }
  }

  //排程日期 and 廠牌
  // void _loadScheduleDate() async {
  //   List<DropdownMenuItem> items = new List();
  //   Datagram datagram = Datagram();
  //   datagram.addText("""select *
  //                       from
  //                       (
  //                         select vsaa1406 as 排程日期,
  //                                t2.vs000101 as 廠牌
  //                         from xvms_aa14 as t1
  //                         left join xvms_0001 as t2 on t1.vsaa1402 = t2.vs000100 and t2.vs000106 = '2'
  //                         where vsaa1416 = 'N'
  //                         group by vsaa1406,t2.vs000101
  //                       ) as x
  //                       order by x.排程日期 desc""", rowIndex: 0, rowSize: 100);
  //   ResponseResult result = await Business.apiExecuteDatagram(datagram);
  //   if (result.flag == ResultFlag.ok) {
  //     List<Map<String, dynamic>> data = result.getMap();
  //     if (data != null && data.length > 0) {
  //       items.add(DropdownMenuItem(value: '', child: Text('')));
  //       for (int i = 0; i < data.length; i++) {
  //         items.add(DropdownMenuItem(
  //             value:
  //                 data[i]['排程日期'].toString() + '|' + data[i]['廠牌'].toString(),
  //             child: Text(data[i]['排程日期'].toString() +
  //                 ' ' +
  //                 data[i]['廠牌'].toString())));
  //       }
  //       setState(() {
  //         dateItems = items;
  //       });
  //     }
  //   } else {
  //     _showMessage(ResultFlag.ng, result.getNGMessage());
  //   }
  // }

  // void _loadDataList(String datetime) async {
  //   setState(() {
  //     _isLoading = true;
  //   });

  //   final ResponseResult result = await _loadData(datetime);
  //   if (result.flag == ResultFlag.ok) {
  //     List<Map<String, dynamic>> data = result.getMap();
  //     if (data.length == 0) {
  //       setState(() {
  //         _isLoading = false;
  //         _vinList = null;
  //         _vinCountFuel_All = 0;
  //         _vinCountFuel_N = 0;
  //       });
  //     } else {
  //       setState(() {
  //         _isLoading = false;
  //         _vinList = data;
  //         _vinCountFuel_All = data.length;
  //         _vinCountFuel_N =
  //             data.where((v) => v['加油狀態'].toString() == 'N').toList().length;
  //       });
  //     }
  //   } else {
  //     setState(() {
  //       _isLoading = false;
  //       _vinCountFuel_All = 0;
  //       _vinCountFuel_N = 0;
  //     });

  //     _showMessage(ResultFlag.ng, result.getNGMessage());
  //   }
  // }

  //取得是否為計劃性
  Future<String> _getVSAA1429(String value) async {
    Datagram datagram = Datagram();
    CommandField cf = CommandField(
      cmdType: CmdType.procedure,
      commandText: 'SPX_VSAA14_CHECK',
    );
    cf.addParamText('sVSAA1400', value);
    cf.addParam(ParameterField(
        'oRESULT_FLAG', ParamType.strings, ParamDirection.output));
    cf.addParam(
        ParameterField('oRESULT', ParamType.strings, ParamDirection.output));
    datagram.addCommand(cf);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      return data.first['ORESULT'].toString();
    } else {
      _showMessage(ResultFlag.ng, result.getNGMessage());
      return '';
    }
  }

  Future<bool> xvmsaa14in(String cmd, String vsaa1427, String vsaa1400,
      String vsaa1410, String vsaa1414, String vsaa1420, String stkb225) async {
    Datagram datagram = Datagram();
    CommandField cf = CommandField(
      cmdType: CmdType.procedure,
      commandText: 'SPX_VSAA14_IN',
    );
    cf.addParamText('sCMD', cmd); //計劃性
    cf.addParamText('sVSAA1400', vsaa1400); //車身號碼
    cf.addParamText('sVSAA1410', vsaa1410); //油品種類
    cf.addParamText('sVSAA1414', vsaa1414); //實際加油公升數
    cf.addParamText('sVSAA1420', vsaa1420); //加油註記
    cf.addParamText('sVSAA1427', vsaa1427); //加油來源
    cf.addParamText('sSTKB225', stkb225); //油槽編號
    cf.addParamText('sUSERID', Business.userId); //加油人員
    cf.addParam(ParameterField(
        'oRESULT_FLAG', ParamType.strings, ParamDirection.output));
    cf.addParam(
        ParameterField('oRESULT', ParamType.strings, ParamDirection.output));
    datagram.addCommand(cf);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      // List<Map<String, dynamic>> data = result.getMap();
      return true;
    } else {
      _showMessage(
          ResultFlag.ng,
          result.getNGMessage().length < 20
              ? result.getNGMessage()
              : result.getNGMessage().substring(0, 21) + '...');
      return false;
    }
  }

  void _loadVSAA1427() async {
    List<DropdownMenuItem> items = new List();
    Datagram datagram = Datagram();
    datagram.addText(
        """select ixa00700,ixa00701 from entirev4.dbo.ifx_a007 where ixa00703 = '加油來源'
    """);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      if (data != null && data.length > 0) {
        for (int i = 0; i < data.length; i++) {
          items.add(
            DropdownMenuItem(
              value: data[i]['ixa00700'].toString(),
              child: Text(data[i]['ixa00701'].toString()),
            ),
          );
        }
        setState(() {
          _vsaa1427Items = items;
        });
      } else {}
    } else {
      // _showMessage(ResultFlag.ng, result.getNGMessage());
    }
  }

  void _loadVSAA1410() async {
    List<DropdownMenuItem> items = new List();
    Datagram datagram = Datagram();
    datagram.addText(
        """select ixa00700,ixa00701 from entirev4.dbo.ifx_a007 where ixa00703 = '油品種類'
    """);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      if (data != null && data.length > 0) {
        for (int i = 0; i < data.length; i++) {
          items.add(
            DropdownMenuItem(
              value: data[i]['ixa00700'].toString(),
              child: Text(data[i]['ixa00701'].toString()),
            ),
          );
        }
        setState(() {
          _vsaa1410Items = items;
        });
      } else {}
    } else {
      // _showMessage(ResultFlag.ng, result.getNGMessage());
    }
  }

  //取得車身號碼列表
  // void _loadvinCountFuelN() async {
  //   setState(() {
  //     _isLoading = true;
  //   });

  //   Datagram datagram = Datagram();
  //   // datagram.addText("""if(1=1)
  //   //                     with notfinishDate (排程日期) as
  //   //                     (
  //   //                         select vsaa1406 as 排程日期
  //   //                         from xvms_aa14
  //   //                         where vsaa1416 = 'N'
  //   //                         group by vsaa1406
  //   //                     )
  //   //                     select vsaa1400 as 車身號碼,
  //   //                            vsaa1405 as 點交次數,
  //   //                            vsaa1406 as 排程日期,
  //   //                            isnull(t2.vs000101,'') as 廠牌,
  //   //                            isnull(t3.vs000101,'') as 車款,
  //   //                            vsaa1416 as 加油狀態,
  //   //                            vsaa1421 as 原儲位,
  //   //                            vsaa1422 as 原儲格,
  //   //                            case when vsaa1411 = '1' or vsaa1411 = '3' then t5.ixa00701 + '/' + cast(vsaa1412 as varchar) + ' L'
  //   //                                 when vsaa1411 = '2' then t5.ixa00701  + '/' + cast(vsaa1413 as varchar) + ' 元'
  //   //                                 else '' end as 加油條件
  //   //                     from xvms_aa14 as t1
  //   //                     left join xvms_0001 as t2 on t1.vsaa1402 = t2.vs000100 and t2.vs000106 = '2'
  //   //                     left join xvms_0001 as t3 on t1.vsaa1403 = t3.vs000100 and t3.vs000106 = '3'
  //   //                     left join xvms_0001 as t4 on t1.vsaa1404 = t4.vs000100 and t4.vs000106 = '4'
  //   //                     left join entirev4.dbo.ifx_a007 as t5 on t1.vsaa1410 = t5.ixa00700 and t5.ixa00703 = '油品種類'
  //   //                     where vsaa1406 in (select 排程日期 from notfinishDate)
  //   //                     order by vsaa1406 asc
  //   // """, rowIndex: 0, rowSize: 65535);
  //   datagram.addText("""select vsaa1400 as 車身號碼,
  //                              vsaa1405 as 點交次數,
  //                              vsaa1406 as 排程日期,
  //                              isnull(t2.vs000101,'') as 廠牌,
  //                              isnull(t3.vs000101,'') as 車款,
  //                              vsaa1416 as 加油狀態,
  //                              vsaa1421 as 原儲位,
  //                              vsaa1422 as 原儲格,
  //                              t5.ixa00701 + '/' + cast(vsaa1412 as varchar(30)) + ' L' as 加油條件
  //                       from xvms_aa14 as t1
  //                       left join xvms_0001 as t2 on t1.vsaa1402 = t2.vs000100 and t2.vs000106 = '2'
  //                       left join xvms_0001 as t3 on t1.vsaa1403 = t3.vs000100 and t3.vs000106 = '3'
  //                       left join entirev4.dbo.ifx_a007 as t5 on t1.vsaa1410 = t5.ixa00700 and t5.ixa00703 = '油品種類'
  //                       where vsaa1416 = 'N'
  //                       order by vsaa1406 asc
  //   """, rowSize: 65535);
  //   ResponseResult result = await Business.apiExecuteDatagram(datagram);
  //   if (result.flag == ResultFlag.ok) {
  //     List<Map<String, dynamic>> data = result.getMap();
  //     if (data.length > 0) {
  //       setState(() {
  //         _isLoading = false;
  //         _vinList = data;
  //         vinCountFuelAll = data.length;
  //         vinCountFuelN =
  //             data.where((v) => v['加油狀態'].toString() == 'N').toList().length;
  //       });
  //     } else {
  //       setState(() {
  //         _isLoading = false;
  //         _vinList = null;
  //         vinCountFuelN = 0;
  //       });
  //     }
  //   } else {
  //     // debugPrint(result.getNGMessage());
  //   }
  // }

  //取得一筆車身號碼來自XVMS_AA14
  void _loadOnevinCountFuelN(String _carNumber,
      {bool scheduleCars = false, bool scheduleCarsN = false}) async {
    if (_carNumber == "" || _carNumber == null) return;
    setState(() {
      _isLoading = true;
    });

    Datagram datagram = Datagram();
    // String sQL = """select
    //               vsaa1400 as 車身號碼,
    //               vsaa1405 as 點交次數,
    //               vsaa1406 as 排程日期,
    //               isnull(t2.vs000101,'') as 廠牌,
    //               isnull(t3.vs000101,'') as 車款,
    //               vsaa1416 as 加油狀態,
    //               vsaa1421 as 原儲位,
    //               vsaa1422 as 原儲格,
    //               t5.ixa00701 + '/' + cast(vsaa1412 as varchar(30)) + ' L' as 加油條件,
    //               vsaa1410 as 油品種類碼,
    //               vsaa1402 as 廠牌系統碼,
    //               vsaa1408 as 作業單位,
    //               vsaa1427 as 加油來源 ,
    //               'PY' as 旗標
    //               from xvms_aa14 as t1
    //               left join xvms_0001 as t2 on t1.vsaa1402 = t2.vs000100 and t2.vs000106 = '2'
    //               left join xvms_0001 as t3 on t1.vsaa1403 = t3.vs000100 and t3.vs000106 = '3'
    //               left join entirev4.dbo.ifx_a007 as t5 on t1.vsaa1410 = t5.ixa00700 and t5.ixa00703 = '油品種類'
    //               where 1=1 and VSAA1400 = '$_carNumber' """;

    String sQL = """if(1=1)
    if exists (select 1 from xvms_aa14 where VSAA1400 = '$_carNumber'and vsaa1416 ='N')--判斷此車有無在計畫中 && 加油狀態='N'
        begin
            select  vsaa1400 as 車身號碼,
                    vsaa1405 as 點交次數,
                    vsaa1406 as 排程日期,
                    isnull(t2.vs000101,'') as 廠牌,
                    isnull(t3.vs000101,'') as 車款,
                    vsaa1416 as 加油狀態,
                    vsaa1421 as 原儲位,
                    vsaa1422 as 原儲格,
                    t5.ixa00701 + '/' + cast(vsaa1412 as varchar(30)) + ' L' as 加油條件,
                    vsaa1410 as 油品種類碼,
                    vsaa1402 as 廠牌系統碼,
                    vsaa1408 as 作業單位,
                    vsaa1427 as 加油來源,
                    vsaa1415 as 油槽編號,
                    'PY' as 旗標
                    from xvms_aa14 as t1
                    left join xvms_0001 as t2 on t1.vsaa1402 = t2.vs000100 and t2.vs000106 = '2'
                    left join xvms_0001 as t3 on t1.vsaa1403 = t3.vs000100 and t3.vs000106 = '3'
                    left join entirev4.dbo.ifx_a007 as t5 on t1.vsaa1410 = t5.ixa00700 and t5.ixa00703 = '油品種類'
                    where 1=1 and VSAA1400 = '$_carNumber' and vsaa1416 ='N'
        end
    else --如果在 加油計畫中&& 加油狀態='N' 沒有任何相關車
        begin
                    with etc1 as (
                    select VSAA0100 as 車身號碼,
                            max(VSAA0119) as 點交次數,            
                            '' as 排程日期,
                            isnull(t3.vs000101,'') as 廠牌,
                            isnull(t4.vs000101,'') as 車款,
                            '' as 加油狀態,
                            VSAA0115 as 原儲位,
                            VSAA0116 as 原儲格,
                            '' as 加油條件,
                            '' as 油品種類碼,
                            VSAA0102 as 廠牌系統碼,
                            '' as 作業單位,
                            '' as 加油來源,
                            '' as 油槽編號,
                            'Y' as 旗標
                            from xvms_aa01 as t1 
                            left join xvms_0001 as t3 on t1.VSAA0102 = t3.vs000100 and t3.vs000106 = '2'
                            left join xvms_0001 as t4 on t1.VSAA0103 = t4.vs000100 and t4.vs000106 = '3'
                            where VSAA0100 = '$_carNumber'  group by  t1.VSAA0100 ,t3.vs000101,t4.vs000101,t1.VSAA0115,t1.VSAA0116,t1.VSAA0102  union all
                    select VS004700 as 車身號碼,
                            '' as 點交次數,          
                            '' as 排程日期,
                            '' as 廠牌,
                            '' as 車款,
                            '' as 加油狀態,
                            '' as 原儲位,
                            '' as 原儲格,
                            '' as 加油條件,
                            '' as 油品種類碼,
                            '' as 廠牌系統碼,
                            '' as 作業單位,
                            '' as 加油來源,
                            '' as 油槽編號,
                            'N' as 旗標
                    from XVMS_0047  where VS004700 = '$_carNumber'
                    )
                    select * from etc1  order by 旗標 asc,加油狀態 asc
        end""";

    String sQL2 = """if(1=1)
with etc1 as(select distinct vsaa1400 as 車身號碼,
                  vsaa1405 as 點交次數,
                  vsaa1406 as 排程日期,
                  isnull(t2.vs000101,'') as 廠牌,
                  isnull(t3.vs000101,'') as 車款,
                  vsaa1416 as 加油狀態,
                  vsaa1421 as 原儲位,
                  vsaa1422 as 原儲格,
                  t5.ixa00701 + '/' + cast(vsaa1412 as varchar(30)) + ' L' as 加油條件,
                  vsaa1410 as 油品種類碼,
                  vsaa1402 as 廠牌系統碼,
                  vsaa1408 as 作業單位,
                  vsaa1427 as 加油來源,
                  vsaa1415 as 油槽編號,
                  'PY' as 旗標
                  from xvms_aa14 as t1
                  left join xvms_0001 as t2 on t1.vsaa1402 = t2.vs000100 and t2.vs000106 = '2'
                  left join xvms_0001 as t3 on t1.vsaa1403 = t3.vs000100 and t3.vs000106 = '3'
                  left join entirev4.dbo.ifx_a007 as t5 on t1.vsaa1410 = t5.ixa00700 and t5.ixa00703 = '油品種類'
                  where 1=1 and VSAA1400 = '$_carNumber' 
            ), ect2 as(select vsaa1400 as 車身號碼,
                    vsaa1405 as 點交次數,            
                    vsaa1406 as 排程日期,
                    isnull(t3.vs000101,'') as 廠牌,
                    isnull(t4.vs000101,'') as 車款,
                    vsaa1416 as 加油狀態,
                    vsaa1421 as 原儲位,
                    vsaa1422 as 原儲格,
                    t5.ixa00701 + '/' + cast(vsaa1412 as varchar(30)) + ' L' as 加油條件,
                    vsaa1410 as 油品種類碼,
                    vsaa1402 as 廠牌系統碼,
                    vsaa1408 as 作業單位,
                    vsaa1427 as 加油來源,
                    vsaa1415 as 油槽編號,
                    'PY' as 旗標
                    from xvms_aa14 as t1
                    left join etc1 as t2 on t1.VSAA1406 = t2.排程日期  and t1.vsaa1408 = t2.作業單位  and t1.vsaa1402 = t2.廠牌系統碼 and t1.vsaa1410=t2.油品種類碼 and t1.vsaa1427 = t2.加油來源 
                    left join xvms_0001 as t3 on t1.vsaa1402 = t3.vs000100 and t3.vs000106 = '2'
                    left join xvms_0001 as t4 on t1.vsaa1403 = t4.vs000100 and t4.vs000106 = '3'
                    left join entirev4.dbo.ifx_a007 as t5 on t1.vsaa1410 = t5.ixa00700 and t5.ixa00703 = '油品種類'
                    where t1.VSAA1406 = t2.排程日期  and t1.vsaa1408 = t2.作業單位  and t1.vsaa1402 = t2.廠牌系統碼 and t1.vsaa1410=t2.油品種類碼 and t1.vsaa1427 = t2.加油來源 
                   )select distinct * from ect2 order by 旗標 asc,加油狀態 asc
  """;

    datagram.addText(sQL, rowSize: 65535);
    datagram.addText(sQL2, rowSize: 65535);
    debugPrint(sQL2);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);

    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      List<Map<String, dynamic>> data2;
      if (result.items.length > 1) {
        data2 = result.items[1].getMap();
      }

      if (data.length == 1) {
        setState(() {
          if (scheduleCars == true && scheduleCarsN == false) {
            _vinList = data2;
          } else if (scheduleCars == false && scheduleCarsN == true) {
            _vinList = data2.where((v) => v['加油狀態'].toString() == 'N').toList();
          } else {
            _vinList = data;
            vinCountFuelAll = data2.length;
            vinCountFuelN =
                data2.where((v) => v['加油狀態'].toString() == 'N').toList().length;
            // _isPlan = true;
            _isLoading = false;
            _inputData(_carNumber);
          }
          vinCountFuelAll = data2.length;
          vinCountFuelN =
              data2.where((v) => v['加油狀態'].toString() == 'N').toList().length;
          // _isPlan = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _vinList = null;
          _vinListPlanOut = null;
          vinCountFuelN = 0;
          _isLoading = false;
        });
      }
    } else {
      // debugPrint(result.getNGMessage());
    }
  }

  void _loadkeyBoardvinCountFuelN(String _carNumber) async {
    //限定keyBoard時使用
    if (_carNumber == "" || _carNumber == null || _inputMode != 0) return;
    setState(() {
      _isLoading = true;
    });

    Datagram datagram = Datagram();
    String sQL = """if(1=1)
declare @_numCount int = 0;
with etc1 as(select distinct vsaa1400 as 車身號碼,
                  vsaa1405 as 點交次數,
                  vsaa1406 as 排程日期,
                  isnull(t2.vs000101,'') as 廠牌,
                  isnull(t3.vs000101,'') as 車款,
                  vsaa1416 as 加油狀態,
                  vsaa1421 as 原儲位,
                  vsaa1422 as 原儲格,
                  t5.ixa00701 + '/' + cast(vsaa1412 as varchar(30)) + ' L' as 加油條件,
                  vsaa1410 as 油品種類碼,
                  vsaa1402 as 廠牌系統碼,
                  vsaa1408 as 作業單位,
                  vsaa1427 as 加油來源 ,
                  'PY' as 旗標
                  from xvms_aa14 as t1
                  left join xvms_0001 as t2 on t1.vsaa1402 = t2.vs000100 and t2.vs000106 = '2'
                  left join xvms_0001 as t3 on t1.vsaa1403 = t3.vs000100 and t3.vs000106 = '3'
                  left join entirev4.dbo.ifx_a007 as t5 on t1.vsaa1410 = t5.ixa00700 and t5.ixa00703 = '油品種類'
                  where 1=1 and VSAA1400 like '%$_carNumber%' 
            ), ect2 as(select  vsaa1400 as 車身號碼,
                    vsaa1405 as 點交次數,            
                    vsaa1406 as 排程日期,
                    isnull(t3.vs000101,'') as 廠牌,
                    isnull(t4.vs000101,'') as 車款,
                    vsaa1416 as 加油狀態,
                    vsaa1421 as 原儲位,
                    vsaa1422 as 原儲格,
                    t5.ixa00701 + '/' + cast(vsaa1412 as varchar(30)) + ' L' as 加油條件,
                    vsaa1410 as 油品種類碼,
                    vsaa1402 as 廠牌系統碼,
                    vsaa1408 as 作業單位,
                    vsaa1427 as 加油來源 ,
                    'PY' as 旗標
                    from xvms_aa14 as t1
                    left join etc1 as t2 on t1.VSAA1406 = t2.排程日期  and t1.vsaa1408 = t2.作業單位  and t1.vsaa1402 = t2.廠牌系統碼 and t1.vsaa1410=t2.油品種類碼 and t1.vsaa1427 = t2.加油來源 
                    left join xvms_0001 as t3 on t1.vsaa1402 = t3.vs000100 and t3.vs000106 = '2'
                    left join xvms_0001 as t4 on t1.vsaa1403 = t4.vs000100 and t4.vs000106 = '3'
                    left join entirev4.dbo.ifx_a007 as t5 on t1.vsaa1410 = t5.ixa00700 and t5.ixa00703 = '油品種類'
                    where t1.VSAA1406 = t2.排程日期  and t1.vsaa1408 = t2.作業單位  and t1.vsaa1402 = t2.廠牌系統碼 and t1.vsaa1410=t2.油品種類碼 and t1.vsaa1427 = t2.加油來源 
                   )select @_numCount = 1 from ect2 where 加油狀態='N'
                   if @_numCount >0 --判斷加油計畫中有無相關車
                       begin
                        
                        -----------------
                            with etc1 as(select distinct vsaa1400 as 車身號碼,
                                              vsaa1405 as 點交次數,
                                              vsaa1406 as 排程日期,
                                              isnull(t2.vs000101,'') as 廠牌,
                                              isnull(t3.vs000101,'') as 車款,
                                              vsaa1416 as 加油狀態,
                                              vsaa1421 as 原儲位,
                                              vsaa1422 as 原儲格,
                                              t5.ixa00701 + '/' + cast(vsaa1412 as varchar(30)) + ' L' as 加油條件,
                                              vsaa1410 as 油品種類碼,
                                              vsaa1402 as 廠牌系統碼,
                                              vsaa1408 as 作業單位,
                                              vsaa1427 as 加油來源,
                                              vsaa1415 as 油槽編號,
                                              'PY' as 旗標
                                              from xvms_aa14 as t1
                                              left join xvms_0001 as t2 on t1.vsaa1402 = t2.vs000100 and t2.vs000106 = '2'
                                              left join xvms_0001 as t3 on t1.vsaa1403 = t3.vs000100 and t3.vs000106 = '3'
                                              left join entirev4.dbo.ifx_a007 as t5 on t1.vsaa1410 = t5.ixa00700 and t5.ixa00703 = '油品種類'
                                              where 1=1 and VSAA1400 like '%$_carNumber%' 
                                        ),
                                        ect2 as
                                        (
                                        select  vsaa1400 as 車身號碼,
                                                vsaa1405 as 點交次數,            
                                                vsaa1406 as 排程日期,
                                                isnull(t3.vs000101,'') as 廠牌,
                                                isnull(t4.vs000101,'') as 車款,
                                                vsaa1416 as 加油狀態,
                                                vsaa1421 as 原儲位,
                                                vsaa1422 as 原儲格,
                                                t5.ixa00701 + '/' + cast(vsaa1412 as varchar(30)) + ' L' as 加油條件,
                                                vsaa1410 as 油品種類碼,
                                                vsaa1402 as 廠牌系統碼,
                                                vsaa1408 as 作業單位,
                                                vsaa1427 as 加油來源,
                                                vsaa1415 as 油槽編號,
                                                'PY' as 旗標
                                                from xvms_aa14 as t1
                                                left join etc1 as t2 on t1.VSAA1406 = t2.排程日期  and t1.vsaa1408 = t2.作業單位  and t1.vsaa1402 = t2.廠牌系統碼 and t1.vsaa1410=t2.油品種類碼 and t1.vsaa1427 = t2.加油來源 
                                                left join xvms_0001 as t3 on t1.vsaa1402 = t3.vs000100 and t3.vs000106 = '2'
                                                left join xvms_0001 as t4 on t1.vsaa1403 = t4.vs000100 and t4.vs000106 = '3'
                                                left join entirev4.dbo.ifx_a007 as t5 on t1.vsaa1410 = t5.ixa00700 and t5.ixa00703 = '油品種類'
                                                where t1.VSAA1406 = t2.排程日期  and t1.vsaa1408 = t2.作業單位  and t1.vsaa1402 = t2.廠牌系統碼 and t1.vsaa1410=t2.油品種類碼 and t1.vsaa1427 = t2.加油來源 
                                               ),
                                               ect3 as (
                                               select * from ect2
                                               union 
                                               select VSAA0100 as 車身號碼,
                                                      VSAA0119 as 點交次數,            
                                                      '' as 排程日期,
                                                      isnull(t3.vs000101,'') as 廠牌,
                                                      isnull(t4.vs000101,'') as 車款,
                                                      '' as 加油狀態,
                                                      VSAA0115 as 原儲位,
                                                      VSAA0116 as 原儲格,
                                                      '' as 加油條件,
                                                      '' as 油品種類碼,
                                                      VSAA0102 as 廠牌系統碼,
                                                      '' as 作業單位,
                                                      '' as 加油來源,
                                                      '' as 油槽編號,
                                                      'Y' as 旗標
                                                      from xvms_aa01 as t1 
                                                      left join xvms_0001 as t3 on t1.VSAA0102 = t3.vs000100 and t3.vs000106 = '2'
                                                      left join xvms_0001 as t4 on t1.VSAA0103 = t4.vs000100 and t4.vs000106 = '3'
                                                      where VSAA0100 like '%$_carNumber%'
                                               union all
                                               select VS004700 as 車身號碼,
                                                      '' as 點交次數,          
                                                      '' as 排程日期,
                                                      '' as 廠牌,
                                                      '' as 車款,
                                                      '' as 加油狀態,
                                                      '' as 原儲位,
                                                      '' as 原儲格,
                                                      '' as 加油條件,
                                                      '' as 油品種類碼,
                                                      '' as 廠牌系統碼,
                                                      '' as 作業單位,
                                                      '' as 加油來源,
                                                      '' as 油槽編號,
                                                      'N' as 旗標
                                               from XVMS_0047  where VS004700 like '%$_carNumber%'
                                               )
                                               select * from ect3 order by 旗標 asc,加油狀態 asc
                       end
                   else --如果加油計畫中沒有任何相關車
                       begin
                                               with etc1 as (
                                               select VSAA0100 as 車身號碼,
                                                      VSAA0119 as 點交次數,            
                                                      '' as 排程日期,
                                                      isnull(t3.vs000101,'') as 廠牌,
                                                      isnull(t4.vs000101,'') as 車款,
                                                      '' as 加油狀態,
                                                      VSAA0115 as 原儲位,
                                                      VSAA0116 as 原儲格,
                                                      '' as 加油條件,
                                                      '' as 油品種類碼,
                                                      VSAA0102 as 廠牌系統碼,
                                                      '' as 作業單位,
                                                      '' as 加油來源,
                                                      '' as 油槽編號,
                                                      'Y' as 旗標
                                                      from xvms_aa01 as t1 
                                                      left join xvms_0001 as t3 on t1.VSAA0102 = t3.vs000100 and t3.vs000106 = '2'
                                                      left join xvms_0001 as t4 on t1.VSAA0103 = t4.vs000100 and t4.vs000106 = '3'
                                                      where VSAA0100 like '%$_carNumber%' union all
                                               select VS004700 as 車身號碼,
                                                      '' as 點交次數,          
                                                      '' as 排程日期,
                                                      '' as 廠牌,
                                                      '' as 車款,
                                                      '' as 加油狀態,
                                                      '' as 原儲位,
                                                      '' as 原儲格,
                                                      '' as 加油條件,
                                                      '' as 油品種類碼,
                                                      '' as 廠牌系統碼,
                                                      '' as 作業單位,
                                                      '' as 加油來源,
                                                      '' as 油槽編號,
                                                      'N' as 旗標
                                               from XVMS_0047  where VS004700 like '%$_carNumber%'
                                               )
                                               select * from etc1  order by 旗標 asc,加油狀態 asc
                       end  """;
    datagram.addText(sQL);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      if (data.length > 0) {
        setState(() {
          _vinList = data;
          vinCountFuelAll = data.length;
          vinCountFuelN =
              data.where((v) => v['加油狀態'].toString() == 'N').toList().length;
          _vinNo = '';
          _carLabel = '';
          _carModel = '';
          _layer = '';
          _grid = '';
          _fuelCondition = '';
          _isPlan = true;
          _isLoading = false;
          _isProduct = '';
        });
      } else {
        setState(() {
          _vinList = null;
          _vinListPlanOut = null;
          vinCountFuelN = 0;
          vinCountFuelAll = 0;
          vinCountFuelN = 0;
          _vinNo = '';
          _carLabel = '';
          _carModel = '';
          _layer = '';
          _grid = '';
          _fuelCondition = '';
          _isLoading = false;
          _isProduct = '';
        });
      }
    } else {
      debugPrint(result.getNGMessage());
    }
    //清空公升數、油槽編號
    _numberController.text = '';
    _gasContainerNoController.text = '';
  }

  //檢查車身號碼是否存在
  Future<bool> _existsVin(String value) async {
    Datagram datagram = Datagram();
    datagram.addText("""select vsaa0100 as 車身號碼,
                               vsaa0119 as 點交次數,
                               t2.vs000101 as 進口商,
                               t3.vs000101 as 廠牌,
                               t4.vs000101 as 車款,
                               vsaa0115 as 原儲位,
                               
                               vsaa0116 as 原儲格
                        from xvms_aa01 as t1
                        left join xvms_0001 as t2 on t1.vsaa0111 = t2.vs000100 and t2.vs000106 = '1'
                        left join xvms_0001 as t3 on t1.vsaa0102 = t3.vs000100 and t3.vs000106 = '2'
                        left join xvms_0001 as t4 on t1.vsaa0103 = t4.vs000100 and t4.vs000106 = '3'
                        where vsaa0114 not in ('00','10','99') and
                              vsaa0100 like '%$value%'
    """, rowIndex: 0, rowSize: 65535);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      if (data.length > 0) {
        List<Map<String, dynamic>> list = List();
        data.forEach((f) {
          list.add({
            '車身號碼': f['車身號碼'].toString(),
          });
        });
        value = await CarSelect.showWithList(context, list);
        if (value == null) {
          _showMessage(ResultFlag.ng, '請選擇車身號碼');
          FocusScope.of(context).requestFocus(_inputFocusNode);
          return false;
        }
        setState(() {
          _vinNo = data
              .firstWhere((v) => v['車身號碼'].toString() == value)['車身號碼']
              .toString();
          _vsaa1405 = data
              .firstWhere((v) => v['車身號碼'].toString() == value)['點交次數']
              .toString();
          DateTime now = DateTime.now();
          String formattedDate = DateFormat('yyyy-MM-dd').format(now);
          _vsaa1406 = formattedDate;
          _carLabel = data
              .firstWhere((v) => v['車身號碼'].toString() == value)['廠牌']
              .toString();
          _carModel = data
              .firstWhere((v) => v['車身號碼'].toString() == value)['車款']
              .toString();
          _layer = data
              .firstWhere((v) => v['車身號碼'].toString() == value)['原儲位']
              .toString();
          _grid = data
              .firstWhere((v) => v['車身號碼'].toString() == value)['原儲格']
              .toString();
        });
      } else {
        setState(() {
          _vinNo = '';
          _carLabel = '';
          _carModel = '';
          _layer = '';
          _grid = '';
        });
        _showMessage(ResultFlag.ng, '找不到符合一筆以上的車身號碼');
      }
      return true;
    } else {
      _showMessage(ResultFlag.ng, result.getNGMessage());
      return false;
    }
  }

  void _loadPath() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    _appDocDir = appDocDir;
  }

  void _loadFiles() async {
    List<FileSystemEntity> allList = List<FileSystemEntity>();
    List<Map<String, dynamic>> fileList = List<Map<String, dynamic>>();

    if (Directory(_appDocDir.path + '/compid/' + _imageCategory + '/' + _vinNo)
            .existsSync() ==
        true) {
      Directory aa = Directory(
          _appDocDir.path + '/compid/' + _imageCategory + '/' + _vinNo);

      allList = Directory(
              _appDocDir.path + '/compid/' + _imageCategory + '/' + _vinNo)
          .listSync(recursive: true, followLinks: false);
      allList.forEach((entity) {
        if (entity is File)
          fileList.add({
            '車身號碼': path.basename(path.dirname(entity.path)),
            '檔案路徑': entity.path,
          });
      });
      _files = fileList;
    } else {
      _files = fileList;
    }
  }

  Future<bool> uploadPicture() async {
    //檢查車身號碼是否有拍照
    int _filecount = 0;
    _loadFiles();
    if (_files != null)
      _filecount = _files.where((v) => v['車身號碼'] == _vinNo).toList().length;
    if (_filecount < 2) {
      _showMessage(ResultFlag.ng, '請拍照,至少2張,車身:' + _vinNo);
      return false;
    }

    //點交次數
    String tag2 = '';
    Datagram datagram = Datagram();
    datagram.addText("""select isnull(vsaa0119,0) as vsaa0119
                                        from xvms_aa01
                                        where vsaa0100 = '$_vinNo' and
                                              vsaa0114 not in ('00','10','99')
                        """, rowSize: 65535);
    ResponseResult result2 = await Business.apiExecuteDatagram(datagram);
    if (result2.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result2.getMap();
      if (data.length > 0) tag2 = data[0]['vsaa0119'].toString();
    } else {}
    Map<String, String> headers = {
      'ModuleId': _imageCategory,
      'SubPath': '\\' + _imageCategory + '\\' + _vinNo,
      'ReceiptType': '',
      'ReceiptSerial': '',
      'ReceiptNo': '',
      'Tag1': _vinNo,
      'Tag2': tag2,
      'Descryption': '',
      'UploadUser': Business.userId,
      'UploadDevice': '',
    };

    List<File> files = List<File>();
    for (Map<String, dynamic> item in _files) {
      File f = File(item['檔案路徑'].toString());
      files.add(f);
    }
    if (files.length == 0) return false;

    ResponseResult result =
        await Business.apiUploadFile(FileCmdType.file, files, headers: headers);
    if (result.flag == ResultFlag.ok) {
      //上傳圖片成功
      _isLoading = false;
      return true;
    } else {
      _showMessage(ResultFlag.ng, result.getNGMessage());
      _isLoading = false;
      return false;
    }
  }

  //取得車身號碼列表
  // Future<ResponseResult> _loadData(String datetime) {
  //   Datagram datagram = Datagram();
  //   datagram.addText("""select vsaa1400 as 車身號碼,
  //                              vsaa1405 as 點交次數,
  //                              vsaa1406 as 排程日期,
  //                              t2.vs000101 as 廠牌,
  //                              t3.vs000101 as 車款,
  //                              vsaa1416 as 加油狀態,
  //                              vsaa1421 as 原儲位,
  //                              vsaa1422 as 原儲格,
  //                              case when vsaa1411 = '1' or vsaa1411 = '3' then t5.ixa00701 + '/' + cast(vsaa1412 as varchar) + ' L'
  //                                   when vsaa1411 = '2' then t5.ixa00701  + '/' + cast(vsaa1413 as varchar) + ' 元'
  //                                   else '' end as 加油條件
  //                       from xvms_aa14 as t1
  //                       left join xvms_0001 as t2 on t1.vsaa1402 = t2.vs000100 and t2.vs000106 = '2'
  //                       left join xvms_0001 as t3 on t1.vsaa1403 = t3.vs000100 and t3.vs000106 = '3'
  //                       left join xvms_0001 as t4 on t1.vsaa1404 = t4.vs000100 and t4.vs000106 = '4'
  //                       left join entirev4.dbo.ifx_a007 as t5 on t1.vsaa1410 = t5.ixa00700 and t5.ixa00703 = '油品種類'
  //                       where vsaa1406 + '|' + t2.vs000101 = '$datetime'
  //                    """, rowIndex: 0, rowSize: 5000);
  //   Future<ResponseResult> result = Business.apiExecuteDatagram(datagram);
  //   return result;
  // }
}

Widget _buildFunctionMenu_A(BuildContext context) {
  FuelDialogState fm = new FuelDialogState();
}

class FuelDialog extends StatefulWidget {
  const FuelDialog({this.onValueChange, this.initialValue});

  final String initialValue;
  final void Function(String) onValueChange;

  @override
  State createState() => new FuelDialogState();
}

class FuelDialogState extends State<FuelDialog> {
  String _selectedId;
  Map<String, dynamic> fuelType = {
    '1': '92無鉛',
    '2': '95無鉛',
    '3': '98無鉛',
    'Z': '柴油'
  };

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialValue;
  }

  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text('油品種類'),
      children: <Widget>[
        Container(
            padding: EdgeInsets.all(10.0),
            child: DropdownButton<String>(
              hint: Text('請選擇油品'),
              value: _selectedId,
              onChanged: (String value) {
                setState(() {
                  _selectedId = value;
                });
                widget.onValueChange(value);
              },
              items: fuelType.keys.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(fuelType[value].toString()),
                );
              }).toList(),
            )),
        Container(
          child: RaisedButton(
            child: Text('確認'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ],
    );
  }
}

class FunctionMenu extends StatefulWidget {
  List<String> offlineDataBuffer = List<String>();

  final int inputMode;
  final void Function(int) onInputModeChange;
  final int barcodeMode;
  final void Function(int) onBarcodeChange;
  final String imageCategory;
  FunctionMenu(
      {@required this.inputMode,
      @required this.onInputModeChange,
      @required this.barcodeMode,
      @required this.onBarcodeChange,
      @required this.imageCategory});

  @override
  State<StatefulWidget> createState() {
    return _FunctionMenu();
  }
}

class _FunctionMenu extends State<FunctionMenu> {
  int _inputMode = 1;
  int _barcodeFixMode = 0;
  String _imageCategory = 'TVS0100006';

  @override
  void initState() {
    super.initState();
    _inputMode = widget.inputMode;
    _barcodeFixMode = widget.barcodeMode;
    _imageCategory = widget.imageCategory;
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
            //   setState(() {
            //     _onlineMode = value;
            //   });
            //   Navigator.pop(context);
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
            // //==== DataUpload
            // buildDataUpload(Color(0xffe1e6ef), () {
            //   if (_onlineMode == false) return;
            //   MessageBox.showQuestion(
            //       context,
            //       '共' + (widget.offlineDataBuffer.length).toString() + '筆資料',
            //       '確定上傳?', yesFunc: () async {
            //     setState(() {
            //       _isLoading = true;
            //     });
            //     List<Map<String, dynamic>> offlineList = [];
            //     Datagram datagram = Datagram();
            //     widget.offlineDataBuffer.forEach((s) {
            //       String vsaa1427 = s.split('|')[0];
            //       String vsaa1400 = s.split('|')[1];
            //       String vsaa1410 = s.split('|')[2];
            //       String vsaa1414 = s.split('|')[3];

            //       offlineList.add({
            //         'vsaa1427': vsaa1427,
            //         'vsaa1400': vsaa1400,
            //         'vsaa1410': vsaa1410,
            //         'vsaa1414': vsaa1414
            //       });
            //     });
            //     for (Map<String, dynamic> item in offlineList) {
            //       String vsaa1429 =
            //           await _getVSAA1429(item['vsaa1400'].toString());

            //       if (vsaa1429 == 'A') {
            //         CommandField cf = CommandField(
            //           cmdType: CmdType.procedure,
            //           commandText: 'SPX_VSAA14_IN',
            //         );
            //         cf.addParamText('sCMD', vsaa1429); //計劃性
            //         cf.addParamText(
            //             'sVSAA1400', item['vsaa1400'].toString()); //車身號碼
            //         cf.addParamText('sVSAA1410', ''); //油品種類
            //         cf.addParamText(
            //             'sVSAA1414', item['vsaa1414'].toString()); //實際加油公升數
            //         cf.addParamText('sVSAA1420', ''); //加油註記
            //         cf.addParamText('sVSAA1427', ''); //加油來源
            //         cf.addParamText('sUSERID', Business.userId); //加油人員
            //         cf.addParam(ParameterField('oRESULT_FLAG',
            //             ParamType.strings, ParamDirection.output));
            //         cf.addParam(ParameterField(
            //             'oRESULT', ParamType.strings, ParamDirection.output));
            //         datagram.addCommand(cf);
            //       } else {
            //         CommandField cf = CommandField(
            //           cmdType: CmdType.procedure,
            //           commandText: 'SPX_VSAA14_IN',
            //         );
            //         cf.addParamText('sCMD', vsaa1429); //計劃性
            //         cf.addParamText(
            //             'sVSAA1400', item['vsaa1400'].toString()); //車身號碼
            //         cf.addParamText(
            //             'sVSAA1410', item['vsaa1410'].toString()); //油品種類
            //         cf.addParamText(
            //             'sVSAA1414', item['vsaa1414'].toString()); //實際加油公升數
            //         cf.addParamText('sVSAA1420', ''); //加油註記
            //         cf.addParamText(
            //             'sVSAA1427', item['vsaa1427'].toString()); //加油來源
            //         cf.addParamText('sUSERID', Business.userId); //加油人員
            //         cf.addParam(ParameterField('oRESULT_FLAG',
            //             ParamType.strings, ParamDirection.output));
            //         cf.addParam(ParameterField(
            //             'oRESULT', ParamType.strings, ParamDirection.output));
            //         datagram.addCommand(cf);
            //       }
            //     }
            //     if (datagram.commandList.length == 0) {
            //       return;
            //     }
            //     ResponseResult result =
            //         await Business.apiExecuteDatagram(datagram);
            //     if (result.flag == ResultFlag.ok) {
            //       widget.offlineDataBuffer.clear();
            //       SharedPreferences prefs =
            //           await SharedPreferences.getInstance();
            //       if (prefs.containsKey(moduleId) == true)
            //         prefs.remove(moduleId);
            //     } else
            //       _showMessage(ResultFlag.ng, result.getNGMessage());

            //     setState(() {
            //       _isLoading = false;
            //     });
            //   });
            // }),
            // //==== 作業圖庫
            buildGalleryWithSeqNo(context, Color(0xffe1e6ef), _imageCategory),
            //==== 拍照
            // buildPhotograph(
            //     context, Color(0xffe1e6ef), vinNo, vinList, _imageCategory,
            //     (Map<String, dynamic> map) {
            //   if (map['resultFlag'].toString() == 'ok') {
            //     setState(() {
            //       _vinNo = map['result'].toString();
            //     });
            //   } else {
            //     _showMessage(ResultFlag.ng, map['result'].toString());
            //   }
            // }),
            Divider(height: 2.0, color: Colors.black),
          ],
        ),
      ),
    );
  }
}
