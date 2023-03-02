import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:car_1/business/datagram.dart';
import 'package:car_1/business/responseresult.dart';
import 'package:car_1/apis/messagebox.dart';
import 'package:car_1/business/business.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/sysMenu.dart';
import 'CarInformation.dart';
import 'GeneralFunction.dart';
import 'GeneralWidget.dart';
import 'CarSelect.dart';
//123

class TVS0100002 extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _TVS0100002();
  }
}

class _TVS0100002 extends State<TVS0100002> with TickerProviderStateMixin {
  final String moduleId = 'TVS0100002';
  final String moduleName = '卸船作業';
  String _imageCategory = 'TVS0100002';
  final _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final FocusNode _textFieldFocusNode = FocusNode();
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
  List<Map<String, dynamic>> _fileList;
  //========================================================
  final Map<String, dynamic> _formData = {
    'vinCarrierName': null, //船名航次
  };
  List<Map<String, dynamic>> _vinList;
  List<String> _offlineDataBuffer = List<String>();
  int _vinCarrierTotalCount = 0; //
  int _vinCarrierStandbyCount = 0; //
  String _vinNo = ''; //車身號碼
  String _vinRemark = ''; //卸車註記
  String _vinShipDate = ''; //預計出車日
  List<DropdownMenuItem> _vinCarrierNameItems;
  List<Map<String, dynamic>> _xvms0033List;

  @override
  void initState() {
    // _keyboardListen = new HardwareKeyboardListener(_hardwareInputCallback);
    super.initState();
    _loadCarCarrierNameData();
    _loadXVMW_0033();
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
      if (prefs.containsKey(moduleId) == true)
        _offlineDataBuffer = prefs.getStringList(moduleId);
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
              //       builder: (context) => _buildFunctionMenu(context),
              //       fullscreenDialog: false),
              // );
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => FunctionMenu(
                        //連線模式
                        onlineMode: _onlineMode,
                        onOnlineModeChange: (bool value) {
                          _onlineMode = value;
                          debugPrint('連線模式: ' + _onlineMode.toString());
                        },
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
                        offlineDataBuffer: _offlineDataBuffer,
                        isLoading: _isLoading,
                        xvms0033List: _xvms0033List,
                        dataUpload: (ResultFlag value3, String value4) async {
                          _isLoading = true;
                          if (value3 == ResultFlag.ok) {
                            _offlineDataBuffer.clear();
                            SharedPreferences prefs =
                                await SharedPreferences.getInstance();
                            if (prefs.containsKey(moduleId) == true)
                              prefs.remove(moduleId);
                            _showMessage(value3, value4);
                          } else {
                            _showMessage(value3, value4);
                          }
                          _isLoading = false;
                        },
                        //拍照
                        imageCategory: _imageCategory, //作業圖庫
                        vinNo: _vinNo,
                        vinList: _vinList,
                        onPhotograph: (Map<String, dynamic> value1,
                            ResultFlag value2, String value3) {
                          if (value2 == ResultFlag.ng)
                            _showMessage(value2, value3);
                        }),
                    fullscreenDialog: false),
              );
            },
          )
        ],
      ),
      drawer: buildMenu(context),
      body: Container(
        child: Container(
          width: Business.deviceWidth(context),
          child: Column(
            children: <Widget>[
              //================
              Container(
                child: Form(
                  key: _formKey,
                  child: Container(
                      child: Column(
                    children: <Widget>[
                      _buildInputContainer(),
                      buildDropdownButton('來源船名', 'vinCarrierName', _formData,
                          _vinCarrierNameItems, (dynamic value) {
                        setState(() {
                          _formData['vinCarrierName'] = value;
                        });
                        _loadDataList(value);
                        if (_inputMode == 1)
                          FocusScope.of(context).requestFocus(_inputFocusNode);
                      }),
                      // _buildCarInfo1(),
                      Container(
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: buildLabel(
                                  '總車身數', _vinCarrierTotalCount.toString()),
                            ),
                            Expanded(
                              child: buildLabel(
                                  '未卸車數', _vinCarrierStandbyCount.toString()),
                            ),
                          ],
                        ),
                      ),
                      buildLabel('預計出車日', _vinShipDate),
                      buildLabel('車身號碼', _vinNo),
                      buildRichText('卸車註記:', _vinRemark,
                          valueColor: Colors.blue, valuefontSize: 18.0),
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
    );
  }

//================================================================

  void portraitInit() async {
    await SystemChrome.setPreferredOrientations([]);
  }

  void portraitUp() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  Widget _buildFunctionMenu(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('功能清單'),
        backgroundColor: Colors.brown,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            //==== ConnectMode
            buildConnectMode(Colors.white, _onlineMode, (bool value) {
              setState(() {
                _onlineMode = value;
              });
              Navigator.pop(context);
            }),
            //==== InputMode
            buildInputMode(Color(0xffe1e6ef), _inputMode, (int value) {
              setState(() {
                if (value == 0)
                  FocusScope.of(context).requestFocus(FocusNode());
                else if (value == 1)
                  FocusScope.of(context).requestFocus(FocusNode());
                else
                  FocusScope.of(context).requestFocus(FocusNode());
                _inputMode = value;
              });
              Navigator.pop(context);
            }),
            //==== BarcodeMode
            buildBarcodeMode(Colors.white, _barcodeFixMode, (int value) {
              setState(() {
                _barcodeFixMode = value;
              });
              Navigator.pop(context);
            }),
            //==== DataUpload
            buildDataUpload(Color(0xffe1e6ef), () {
              if (_onlineMode == false) return;
              MessageBox.showQuestion(
                  context,
                  '共' + (_offlineDataBuffer.length).toString() + '筆資料',
                  '確定上傳?', yesFunc: () async {
                setState(() {
                  _isLoading = true;
                });
                Datagram datagram = Datagram();
                _offlineDataBuffer.forEach((s) {
                  List<ParameterField> paramList = List();
                  paramList.add(ParameterField(
                      'sVSAA0200', ParamType.strings, ParamDirection.input,
                      value: s));
                  paramList.add(ParameterField(
                      'sVSAA0226', ParamType.strings, ParamDirection.input,
                      value: _xvms0033List.first['儲區代碼'].toString()));
                  paramList.add(ParameterField(
                      'sUSERID', ParamType.strings, ParamDirection.input,
                      value: Business.userId));
                  paramList.add(ParameterField(
                      'sDEPTID', ParamType.strings, ParamDirection.input,
                      value: Business.deptId));
                  paramList.add(ParameterField(
                      'sROWINDEX', ParamType.strings, ParamDirection.input,
                      value: '1'));
                  paramList.add(ParameterField('oRESULT_FLAG',
                      ParamType.strings, ParamDirection.output));
                  paramList.add(ParameterField(
                      'oRESULT', ParamType.strings, ParamDirection.output));
                  datagram.addProcedure('IMP_XVMS_AA02_01',
                      parameters: paramList);
                });
                ResponseResult result =
                    await Business.apiExecuteDatagram(datagram);
                if (result.flag == ResultFlag.ok) {
                  _offlineDataBuffer.clear();
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  if (prefs.containsKey(moduleId) == true)
                    prefs.remove(moduleId);
                } else
                  _showMessage(ResultFlag.ng, result.getNGMessage());

                setState(() {
                  _isLoading = false;
                });
              });
            }),
            //==== 作業圖庫
            buildGallery(context, Colors.white, _imageCategory),
            //==== 拍照
            buildPhotograph(
                context, Color(0xffe1e6ef), _vinNo, _vinList, _imageCategory,
                (Map<String, dynamic> map) {
              if (map['resultFlag'].toString() == 'ok') {
                setState(() {
                  _vinNo = map['result'].toString();
                });
              } else {
                _showMessage(ResultFlag.ng, map['result'].toString());
              }
            }),
            Divider(height: 2.0, color: Colors.black),
          ],
        ),
      ),
    );
  }

  //刷讀後不需按確認
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
                  debugPrint('keycode: ' + _keyCode);
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
                  keyboardType: TextInputType.text,
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
                setState(() => _inputController.text = '');
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
                        child: Text('確認',
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
      return Container();
    else {
      return Container(
        width: Business.deviceWidth(context) - 40,
        child: ListView.builder(
            itemCount: data == null ? 0 : data.length,
            itemBuilder: (BuildContext context, int index) {
              return _buildVinItem(context, data[index]);
            }),
      );
    }
  }

  Widget _buildVinItem(BuildContext context, Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _inputController.text = data['車身號碼'].toString();
          _vinNo = data['車身號碼'].toString();
          _vinRemark = data['卸車備註'] == null ? '' : data['卸車備註'].toString();
          _vinShipDate = data['預計出車日'] == null ? '' : data['預計出車日'].toString();
        });
      },
      onLongPress: () {
        CarInformation.show(context, data['車身號碼'].toString());
      },
      child: Container(
        height: 30,
        decoration: new BoxDecoration(
            color: data['已卸車'] == 'Y' ? Colors.lime : Colors.white,
            border: new Border.all(color: Colors.grey, width: 0.5)),
        child: Row(
          children: <Widget>[
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
              // color: Colors.white
            ),
            Expanded(
              child: Container(
                child: Text(
                  data['車身號碼'] == null ? '' : data['車身號碼'].toString(),
                  style: TextStyle(fontSize: 12),
                ),
                // color: Colors.white
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

  void _inputData(String value) async {
    value = value.replaceAll('/', '');
    setState(() {
      _inputController.text = '';
      _vinNo = '';
      _vinRemark = '';
      _vinShipDate = '';
    });

    if (_vinList == null || _vinList.length == 0) {
      _showMessage(ResultFlag.ng, '請選擇來源船名');
      return;
    }
    if (value == '') {
      _showMessage(ResultFlag.ng, '請輸入或掃描車身號碼');
      return;
    }
    //
    int fullCount = 0;
    int startWithCount = 0;
    int endWithCount = 0;
    fullCount = _vinList.where((v) => v['車身號碼'].toString() == value).length;
    startWithCount = _vinList
        .where((v) => v['車身號碼'].toString().startsWith(value) == true)
        .length;
    endWithCount = _vinList
        .where((v) => v['車身號碼'].toString().endsWith(value) == true)
        .length;
    if (fullCount == 1) {
      setState(() {
        _vinNo = _vinList
            .firstWhere((v) => v['車身號碼'].toString() == value)['車身號碼']
            .toString();
        _vinRemark = _vinList
            .firstWhere((v) => v['車身號碼'].toString() == value)['卸車備註']
            .toString();
        _vinShipDate = _vinList
            .firstWhere((v) => v['車身號碼'].toString() == value)['預計出車日']
            .toString();
      });
    } else if (startWithCount == 1) {
      setState(() {
        _vinNo = _vinList
            .firstWhere(
                (v) => v['車身號碼'].toString().startsWith(value) == true)['車身號碼']
            .toString();
        _vinRemark = _vinList
            .firstWhere(
                (v) => v['車身號碼'].toString().startsWith(value) == true)['卸車備註']
            .toString();
        _vinShipDate = _vinList
            .firstWhere(
                (v) => v['車身號碼'].toString().startsWith(value) == true)['預計出車日']
            .toString();
      });
    } else if (endWithCount == 1) {
      setState(() {
        _vinNo = _vinList
            .firstWhere(
                (v) => v['車身號碼'].toString().endsWith(value) == true)['車身號碼']
            .toString();
        _vinRemark = _vinList
            .firstWhere(
                (v) => v['車身號碼'].toString().endsWith(value) == true)['卸車備註']
            .toString();
        _vinShipDate = _vinList
            .firstWhere(
                (v) => v['車身號碼'].toString().endsWith(value) == true)['預計出車日']
            .toString();
      });
    } else if (fullCount > 1) {
      List<Map<String, dynamic>> list = List();
      _vinList
          .where((v) => v['車身號碼'].toString() == value)
          .toList()
          .forEach((f) {
        list.add({
          '車身號碼': f['車身號碼'].toString(),
        });
      });
      value = await CarSelect.showWithList(context, list);
      if (value == null) {
        _showMessage(ResultFlag.ng, '請選擇車身號碼');
        return;
      }
      setState(() {
        _vinNo = _vinList
            .firstWhere((v) => v['車身號碼'].toString() == value)['車身號碼']
            .toString();
        _vinRemark = _vinList
            .firstWhere((v) => v['車身號碼'].toString() == value)['卸車備註']
            .toString();
        _vinShipDate = _vinList
            .firstWhere((v) => v['車身號碼'].toString() == value)['預計出車日']
            .toString();
      });
    } else if (startWithCount > 1) {
      List<Map<String, dynamic>> list = List();
      _vinList
          .where((v) => v['車身號碼'].toString().startsWith(value) == true)
          .toList()
          .forEach((f) {
        list.add({
          '車身號碼': f['車身號碼'].toString(),
        });
      });
      value = await CarSelect.showWithList(context, list);
      if (value == null) {
        _showMessage(ResultFlag.ng, '請選擇車身號碼');
        return;
      }
      setState(() {
        _vinNo = _vinList
            .firstWhere((v) => v['車身號碼'].toString() == value)['車身號碼']
            .toString();
        _vinRemark = _vinList
            .firstWhere((v) => v['車身號碼'].toString() == value)['卸車備註']
            .toString();
        _vinShipDate = _vinList
            .firstWhere((v) => v['車身號碼'].toString() == value)['預計出車日']
            .toString();
      });
    } else if (endWithCount > 1) {
      List<Map<String, dynamic>> list = List();
      _vinList
          .where((v) => v['車身號碼'].toString().endsWith(value) == true)
          .toList()
          .forEach((f) {
        list.add({
          '車身號碼': f['車身號碼'].toString(),
        });
      });
      value = await CarSelect.showWithList(context, list);
      if (value == null) {
        _showMessage(ResultFlag.ng, '請選擇車身號碼');
        return;
      }
      setState(() {
        _vinNo = _vinList
            .firstWhere((v) => v['車身號碼'].toString() == value)['車身號碼']
            .toString();
        _vinRemark = _vinList
            .firstWhere((v) => v['車身號碼'].toString() == value)['卸車備註']
            .toString();
        _vinShipDate = _vinList
            .firstWhere((v) => v['車身號碼'].toString() == value)['預計出車日']
            .toString();
      });
    } else {
      _showMessage(ResultFlag.ng, '找不到符合一筆以上的車身號碼:' + value + ' 請輸入完整或檢查資料來源');
      return;
    }

    _saveData();
  }

  void _saveData() async {
    if (_vinList
            .firstWhere((v) => v['車身號碼'].toString() == _vinNo)['已卸車']
            .toString() ==
        'Y') {
      _showMessage(ResultFlag.ng, '車身號碼:' + _vinNo + ' 已完成卸車');
      return;
    }
    if (_vinNo == '') return;

    if (_onlineMode == true)
    //====Online
    {
      Datagram datagram = Datagram();
      List<ParameterField> paramList = List();
      paramList.add(ParameterField(
          'sVSAA0200', ParamType.strings, ParamDirection.input,
          value: _vinNo));
      paramList.add(ParameterField(
          'sVSAA0226', ParamType.strings, ParamDirection.input,
          value: _xvms0033List.first['儲區代碼'].toString()));
      paramList.add(ParameterField(
          'sUSERID', ParamType.strings, ParamDirection.input,
          value: Business.userId));
      paramList.add(ParameterField(
          'sDEPTID', ParamType.strings, ParamDirection.input,
          value: Business.deptId));
      paramList.add(ParameterField(
          'sROWINDEX', ParamType.strings, ParamDirection.input,
          value: '1'));
      paramList.add(ParameterField(
          'oRESULT_FLAG', ParamType.strings, ParamDirection.output));
      paramList.add(
          ParameterField('oRESULT', ParamType.strings, ParamDirection.output));
      datagram.addProcedure('IMP_XVMS_AA02_01', parameters: paramList);
      ResponseResult result = await Business.apiExecuteDatagram(datagram);
      if (result.flag == ResultFlag.ok) {
        _vinList.firstWhere((v) => v['車身號碼'].toString() == _vinNo)['已卸車'] = 'Y';
        _showMessage(ResultFlag.ok, '卸車完成');
        if (_vinCarrierStandbyCount != 0) _vinCarrierStandbyCount--;
      } else {
        _showMessage(ResultFlag.ng, result.getNGMessage());
      }
    }
    //Offline
    else {
      _vinList.firstWhere((v) => v['車身號碼'].toString() == _vinNo)['已卸車'] = 'Y';
      SharedPreferences prefs = await SharedPreferences.getInstance();

      if (prefs.containsKey(moduleId) == true)
        _offlineDataBuffer = prefs.getStringList(moduleId);
      setState(() {
        _offlineDataBuffer.add(_vinNo);
      });
      prefs.setStringList(moduleId, _offlineDataBuffer);
      _showMessage(ResultFlag.ok, '卸車完成(離線)');
      if (_vinCarrierStandbyCount != 0) _vinCarrierStandbyCount--;
    }
  }

  void _loadDataList(String vinCarrierName) async {
    setState(() {
      _isLoading = true;
    });

    final ResponseResult result = await _loadData(vinCarrierName);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      if (data.length == 0) {
        setState(() {
          _isLoading = false;
          _vinList = null;
          _vinCarrierTotalCount = 0;
          _vinCarrierStandbyCount = 0;
        });
      } else {
        setState(() {
          _isLoading = false;
          _vinList = data;
          _vinCarrierTotalCount = data.length;
          _vinCarrierStandbyCount =
              data.where((v) => v['已卸車'].toString() == 'N').length;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });

      _showMessage(ResultFlag.ng, result.getNGMessage());
    }
  }

  void _loadXVMW_0033() async {
    Datagram datagram = Datagram();
    datagram.addText("""select vs003300 as 儲區代碼,
                               vs003301 as 儲區名稱
                        from xvms_0033
                        where vs003303 = '3'
           """, rowIndex: 0, rowSize: 65535);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      setState(() {
        _xvms0033List = data;
      });
    }
  }

  void _loadCarCarrierNameData() async {
    List<DropdownMenuItem> items = new List();
    Datagram datagram = Datagram();
    datagram.addText("""select t2.ixa00701 as 車輛來源類別,
                               t1.vsaa0216 as 預計到港日,
                               t1.vsaa0215 as 車輛來源名稱
                        from (
                               select distinct
                                      vsaa0214,
                                      vsaa0216,
                                      vsaa0215
                               from xvms_aa02 where status = 'Y' and vsaa0222 = 'N'
                              ) as t1 left join entirev4.dbo.ifx_a007 as t2 on t1.vsaa0214 = t2.ixa00700 and t2.ixa00703 = '車輛來源類別'
                        order by vsaa0216 desc
      """, rowIndex: 0, rowSize: 100);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);

    if (result.flag == ResultFlag.ng) {
    } else {
      List<Map<String, dynamic>> data = result.getMap();
      for (int i = 0; i < data.length; i++) {
        items.add(
          DropdownMenuItem(
            value: data[i]['車輛來源名稱'].toString(),
            child: Container(
              width: Business.deviceWidth(context) - 100,
              child: Text(
                data[i]['預計到港日'].toString() +
                    ' ' +
                    data[i]['車輛來源名稱'].toString(),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      }
      setState(() {
        _vinCarrierNameItems = items;
      });
    }
  }

  Future<ResponseResult> _loadData(String vinCarrierName) {
    Datagram datagram = Datagram();
    datagram.addText("""select t1.vsaa0222 as 已卸車,
                               t1.vsaa0223 as 已進倉,
                               t1.vsaa0200 as 車身號碼,
                               t2.vs000101 as 廠牌,
                               t3.vs000101 as 車款,
                               t1.vsaa0203 as 車型,
                               t1.vsaa0220 as 卸車備註,
                               t1.vsaa0232 as 預計出車日
                        from xvms_aa02 as t1  left join xvms_0001 as t2 on t1.vsaa0201 = t2.vs000100 and t2.vs000106 = '2'
                                              left join xvms_0001 as t3 on t1.vsaa0202 = t3.vs000100 and t3.vs000106 = '3'
                        where t1.status = 'Y' and vsaa0215 = '$vinCarrierName'
                        order by vsaa0216
                        """, rowIndex: 0, rowSize: 65535);
    Future<ResponseResult> result = Business.apiExecuteDatagram(datagram);
    return result;
  }
}

class FunctionMenu extends StatefulWidget {
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
  List<Map<String, dynamic>> xvms0033List;
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

  FunctionMenu({
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
    @required this.xvms0033List,
    @required this.isLoading,

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
  String _imageCategory = 'TVS0100002';
  bool _onlineMode = true; //在線模式
  String _vinNo = ''; //車身號碼
  List<Map<String, dynamic>> _vinList;

  bool _isLoading;
  List<String> _offlineDataBuffer = List<String>();
  List<Map<String, dynamic>> _xvms0033List;
  @override
  void initState() {
    super.initState();
    _onlineMode = widget.onlineMode;
    _inputMode = widget.inputMode;
    _barcodeFixMode = widget.barcodeMode;
    _imageCategory = widget.imageCategory;
    _isLoading = widget.isLoading;
    _offlineDataBuffer = widget.offlineDataBuffer;
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
            //==== ConnectMode
            buildConnectMode(Colors.white, _onlineMode, (bool value) {
              widget.onOnlineModeChange(value);
              setState(() {
                _onlineMode = value;
              });
            }),
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
            //==== DataUpload
            buildDataUpload(Color(0xffe1e6ef), () {
              if (_onlineMode == false) {
                showDialog(
                    ////新增一個對話框，用來顯示回傳的值
                    context: context,
                    child: AlertDialog(
                      content: Text("連線模式:在線 才能上傳資料"),
                    ));
                return;
              }
              if (_isLoading == true) return;
              ResultFlag _rf = ResultFlag.ok;
              String resultMs = '資料上傳成功';
              MessageBox.showQuestion(
                  context,
                  '共' + (_offlineDataBuffer.length).toString() + '筆資料',
                  '確定上傳?', yesFunc: () async {
                setState(() {
                  _isLoading = true;
                });
                Datagram datagram = Datagram();
                _offlineDataBuffer.forEach((s) {
                  List<ParameterField> paramList = List();
                  paramList.add(ParameterField(
                      'sVSAA0200', ParamType.strings, ParamDirection.input,
                      value: s));
                  paramList.add(ParameterField(
                      'sVSAA0226', ParamType.strings, ParamDirection.input,
                      value: _xvms0033List.first['儲區代碼'].toString()));
                  paramList.add(ParameterField(
                      'sUSERID', ParamType.strings, ParamDirection.input,
                      value: Business.userId));
                  paramList.add(ParameterField(
                      'sDEPTID', ParamType.strings, ParamDirection.input,
                      value: Business.deptId));
                  paramList.add(ParameterField(
                      'sROWINDEX', ParamType.strings, ParamDirection.input,
                      value: '1'));
                  paramList.add(ParameterField('oRESULT_FLAG',
                      ParamType.strings, ParamDirection.output));
                  paramList.add(ParameterField(
                      'oRESULT', ParamType.strings, ParamDirection.output));
                  datagram.addProcedure('IMP_XVMS_AA02_01',
                      parameters: paramList);
                });
                ResponseResult result =
                    await Business.apiExecuteDatagram(datagram);
                if (result.flag == ResultFlag.ok) {
                  _offlineDataBuffer.clear();
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  if (prefs.containsKey(widget.moduleId) == true)
                    prefs.remove(widget.moduleId);

                  _rf = ResultFlag.ok;
                  resultMs = result.getNGMessage();
                } else {
                  _rf = ResultFlag.ng;
                  resultMs = result.getNGMessage();
                }
                //_showMessage(ResultFlag.ng, result.getNGMessage());

                setState(() {
                  _isLoading = false;
                });
                widget.dataUpload(_rf, resultMs);
              });
            }),
            // //==== 作業圖庫
            buildGalleryWithSeqNo(context, Colors.white, _imageCategory),
            //==== 拍照
            buildPhotograph(
                context, Color(0xffe1e6ef), _vinNo, _vinList, _imageCategory,
                (Map<String, dynamic> map) {
              ResultFlag _rf = ResultFlag.ok;
              String resultMs = '拍照完成';

              if (map['resultFlag'].toString() == 'ok') {
                _rf = ResultFlag.ok;
                resultMs = map['result'].toString();
                setState(() {
                  _vinNo = map['result'].toString();
                });
              } else {
                _rf = ResultFlag.ng;
                resultMs = map['result'].toString();
                //_showMessage(ResultFlag.ng, map['result'].toString());
                //widget.onShowMessage(ResultFlag.ng , map['result'].toString());
              }
              widget.onPhotograph(map, _rf, resultMs);
            }),
            Divider(height: 2.0, color: Colors.black),
          ],
        ),
      ),
    );
  }
}
