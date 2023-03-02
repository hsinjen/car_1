import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:car_1/business/datagram.dart';
import 'package:car_1/business/responseresult.dart';
import 'package:car_1/apis/messagebox.dart';
import 'package:car_1/business/business.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/sysMenu.dart';
import 'CarInformation.dart';
import 'CarSelect.dart';
import 'GeneralFunction.dart';
import 'GeneralWidget.dart';

class TVS0100001 extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _TVS0100001();
  }
}

class _TVS0100001 extends State<TVS0100001> with TickerProviderStateMixin {
  final String moduleId = 'TVS0100001';
  final String moduleName = '卸船入儲作業';
  String _imageCategory = 'TVS0100001';
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
  List<Map<String, dynamic>> _fileList;
  //========================================================
  final Map<String, dynamic> _formData = {
    'layer': null, //儲區
    'grid': null, //儲格
    'vinCarrierName': null, //船名航次
  };
  final _gridController = TextEditingController();
  String _vinNo = ''; //車身號碼
  List<DropdownMenuItem> _vinCarrierNameItems;
  List<DropdownMenuItem> _layerItems;
  List<Map<String, dynamic>> _vinList;
  List<String> _offlineDataBuffer = List<String>();
  int _carCarrierCount_all = 0; //總車數
  int _carCarrierCount_N = 0; //未進倉數
  bool _gridDirection = true; //true: 正 false:逆

  @override
  void initState() {
    // _keyboardListen = new HardwareKeyboardListener(_hardwareInputCallback);
    super.initState();

    _loadCarCarrierNameData();
    _loadLayerData();
    // _setupCamera();
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
      if (prefs.containsKey('TVS0100001') == true)
        _offlineDataBuffer = prefs.getStringList('TVS0100001');
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
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => _buildFunctionMenu(context),
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
              //================ Input Start
              Container(
                child: Form(
                  key: _formKey,
                  child: Container(
                      child: Column(
                    children: <Widget>[
                      _buildInputContainer(),
                      //==== 來源船名
                      buildDropdownButton('來源船名', 'vinCarrierName', _formData,
                          _vinCarrierNameItems, (dynamic value) {
                        setState(() {
                          _formData['vinCarrierName'] = value;
                        });
                        _loadDataList(value);
                        if (_inputMode == 1)
                          FocusScope.of(context).requestFocus(_inputFocusNode);
                      }),
                      //==== 儲區 Layer
                      buildDropdownButton('儲區', 'layer', _formData, _layerItems,
                          (dynamic value) {
                        setState(() {
                          _formData['layer'] = value;
                        });
                        if (_inputMode == 1)
                          FocusScope.of(context).requestFocus(_inputFocusNode);
                      }),
                      //==== 儲格 Grid
                      _buildGrid(),
                      //==== Info
                      Container(
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: buildLabel(
                                  '總車身數', _carCarrierCount_all.toString()),
                            ),
                            Expanded(
                              child: buildLabel(
                                  '未進倉數', _carCarrierCount_N.toString()),
                            ),
                          ],
                        ),
                      ),
                      buildLabel('車身號碼', _vinNo),
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
                  String vin = s.split('|')[0];
                  String layer = s.split('|')[1];
                  String grid = s.split('|')[2];

                  List<ParameterField> paramList = List<ParameterField>();
                  paramList.add(ParameterField(
                      'sVSAA0200', ParamType.strings, ParamDirection.input,
                      value: vin));
                  paramList.add(ParameterField(
                      'sVSAA0223', ParamType.strings, ParamDirection.input,
                      value: 'Y'));
                  paramList.add(ParameterField(
                      'sVSAA0224', ParamType.strings, ParamDirection.input,
                      value: DateFormat('yyyy-MM-dd')
                          .format(DateTime.now()))); //點交日期
                  paramList.add(ParameterField(
                      'sVSAA0226', ParamType.strings, ParamDirection.input,
                      value: layer));
                  paramList.add(ParameterField(
                      'sVSAA0227', ParamType.strings, ParamDirection.input,
                      value: grid));
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
                  datagram.addProcedure('IMP_XVMS_AA02_02',
                      parameters: paramList);
                });
                ResponseResult result =
                    await Business.apiExecuteDatagram(datagram);
                if (result.flag == ResultFlag.ok) {
                  _offlineDataBuffer.clear();
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  if (prefs.containsKey('TVS0100003') == true)
                    prefs.remove('TVS0100003');
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

  Widget _buildGrid() {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Container(
              padding: EdgeInsets.only(left: 20.0, right: 20),
              child: TextFormField(
                controller: _gridController,
                autovalidate: false,
                maxLength: 4,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: '儲格',
                    filled: false,
                    contentPadding: EdgeInsets.only(top: 25, bottom: 0)),
                validator: (String value) {
                  if (value.isEmpty) return '請輸入儲格號碼';
                  if (value.isNotEmpty && value.length != 4) {
                    return '儲格必須等於 4 碼';
                  } else
                    return '';
                },
                onSaved: (String value) {
                  _formData['grid'] = value;
                  if (_inputMode == 1)
                    FocusScope.of(context).requestFocus(_inputFocusNode);
                },
              ),
            ),
          ),
          Container(
            height: 25,
            width: 50,
            padding: EdgeInsets.only(right: 10),
            child: RaisedButton(
              padding: EdgeInsets.all(1),
              color: Colors.purple,
              child: Text('跳過',
                  style: TextStyle(fontSize: 12.0, color: Colors.white)),
              onPressed: () {
                setState(() {
                  int gridNumber = int.tryParse(_gridController.text);
                  if (gridNumber == null) return;

                  if (_gridDirection == true) {
                    if (gridNumber >= 99999)
                      gridNumber = 99999;
                    else
                      gridNumber = gridNumber + 1;
                    _gridController.text =
                        gridNumber.toString().padLeft(4, '0');
                    _formData['grid'] = gridNumber.toString().padLeft(4, '0');
                  } else {
                    if (gridNumber <= 1)
                      gridNumber = 1;
                    else
                      gridNumber = gridNumber - 1;
                    _gridController.text =
                        gridNumber.toString().padLeft(4, '0');
                    _formData['grid'] = gridNumber.toString().padLeft(4, '0');
                  }
                });
              },
            ),
          ),
          Container(
            height: 25,
            width: 50,
            padding: EdgeInsets.only(right: 10),
            child: RaisedButton(
              padding: EdgeInsets.all(1),
              color:
                  _gridDirection == true ? Colors.green : Colors.orangeAccent,
              child: Text(_gridDirection == true ? '正向' : '逆向',
                  style: TextStyle(fontSize: 12.0, color: Colors.white)),
              onPressed: () {
                setState(() {
                  _gridDirection = !_gridDirection;
                });
              },
            ),
          ),
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
        });
      },
      onLongPress: () {
        CarInformation.show(context, data['車身號碼'].toString());
      },
      child: Container(
        height: 30,
        decoration: new BoxDecoration(
            color: data['已進倉'] == 'Y' ? Colors.lime : Colors.white,
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
    });

    if (_vinList == null || _vinList.length == 0) {
      _showMessage(ResultFlag.ng, '請選擇來源船名');
      return;
    }
    if (value == '') {
      _showMessage(ResultFlag.ng, '請輸入或掃描車身號碼');
      return;
    }
    if ((_formData['layer'] == null ? '' : _formData['layer']) == '') {
      _showMessage(ResultFlag.ng, '請輸入儲區');
      return;
    }
    if (_gridController.text == '') {
      _showMessage(ResultFlag.ng, '請輸入儲格');
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
      });
    } else if (startWithCount == 1) {
      setState(() {
        _vinNo = _vinList
            .firstWhere(
                (v) => v['車身號碼'].toString().startsWith(value) == true)['車身號碼']
            .toString();
      });
    } else if (endWithCount == 1) {
      setState(() {
        _vinNo = _vinList
            .firstWhere(
                (v) => v['車身號碼'].toString().endsWith(value) == true)['車身號碼']
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
        'N') {
      _showMessage(ResultFlag.ng, '車身號碼:' + _vinNo + ' 尚未卸車');
      return;
    }
    if (_vinList
            .firstWhere((v) => v['車身號碼'].toString() == _vinNo)['已進倉']
            .toString() ==
        'Y') {
      _showMessage(ResultFlag.ng, '車身號碼:' + _vinNo + ' 已完成進倉');
      return;
    }

    String layer = _formData['layer'];
    String grid = _gridController.text;
    String vin = _vinNo;

    if (_onlineMode == true)
    //====Online
    {
      Datagram datagram = Datagram();
      List<ParameterField> paramList = List<ParameterField>();
      paramList.add(ParameterField(
          'sVSAA0200', ParamType.strings, ParamDirection.input,
          value: vin));
      paramList.add(ParameterField(
          'sVSAA0223', ParamType.strings, ParamDirection.input,
          value: 'Y'));
      paramList.add(ParameterField(
          'sVSAA0224', ParamType.strings, ParamDirection.input,
          value: DateFormat('yyyy-MM-dd').format(DateTime.now()))); //點交日期
      paramList.add(ParameterField(
          'sVSAA0226', ParamType.strings, ParamDirection.input,
          value: layer));
      paramList.add(ParameterField(
          'sVSAA0227', ParamType.strings, ParamDirection.input,
          value: grid));
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
      datagram.addProcedure('IMP_XVMS_AA02_02', parameters: paramList);
      ResponseResult result = await Business.apiExecuteDatagram(datagram);
      if (result.flag == ResultFlag.ok) {
        _vinList.firstWhere((v) => v['車身號碼'].toString() == _vinNo)['已進倉'] = 'Y';
        _showMessage(ResultFlag.ok, '入儲成功');
        if (_carCarrierCount_N != 0) _carCarrierCount_N--;
      } else {
        _showMessage(ResultFlag.ng, result.getNGMessage());
      }
    }
    //Offline
    else {
      _vinList.firstWhere((v) => v['車身號碼'].toString() == _vinNo)['已進倉'] = 'Y';
      SharedPreferences prefs = await SharedPreferences.getInstance();

      if (prefs.containsKey('TVS0100001') == true)
        _offlineDataBuffer = prefs.getStringList('TVS0100001');
      setState(() {
        _offlineDataBuffer.add(vin + '|' + layer + '|' + grid);
      });

      prefs.setStringList('TVS0100001', _offlineDataBuffer);
      _showMessage(ResultFlag.ok, '入儲成功(離線)');
      if (_carCarrierCount_N != 0) _carCarrierCount_N--;
    }

    setState(() {
      int gridNumber = int.tryParse(grid);

      if (_gridDirection == true) {
        if (gridNumber >= 99999)
          gridNumber = 99999;
        else
          gridNumber = gridNumber + 1;
        _gridController.text = gridNumber.toString().padLeft(4, '0');
        _formData['grid'] = gridNumber.toString().padLeft(4, '0');
      } else {
        if (gridNumber <= 1)
          gridNumber = 1;
        else
          gridNumber = gridNumber - 1;
        _gridController.text = gridNumber.toString().padLeft(4, '0');
        _formData['grid'] = gridNumber.toString().padLeft(4, '0');
      }
    });
  }

  void _loadDataList(String carCarrierName) async {
    setState(() {
      _isLoading = true;
    });

    final ResponseResult result = await _loadData(carCarrierName);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      if (data.length == 0) {
        setState(() {
          _isLoading = false;
          _vinList = null;
          _carCarrierCount_all = 0;
          _carCarrierCount_N = 0;
        });
      } else {
        setState(() {
          _isLoading = false;
          _vinList = data;
          _carCarrierCount_all = data.length;
          _carCarrierCount_N =
              data.where((v) => v['已進倉'].toString() == 'N').length;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });

      _showMessage(ResultFlag.ng, result.getNGMessage());
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
                               from xvms_aa02 where status = 'Y' and
                                                    vsaa0222 = 'Y' and --已卸車
                                                    vsaa0223 = 'N'  --未進倉
                             ) as t1 left join entirev4.dbo.ifx_a007 as t2 on t1.vsaa0214 = t2.ixa00700 and t2.ixa00703 = '車輛來源類別'
                        order by t1.vsaa0216 desc
                     """, rowIndex: 0, rowSize: 999);
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

  void _loadLayerData() async {
    List<DropdownMenuItem> items = new List();
    Datagram datagram = Datagram();
    datagram.addText(
        """select vs003300,vs003301 from xvms_0033 where vs003303='3'""",
        rowIndex: 0, rowSize: 100);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);

    if (result.flag == ResultFlag.ng) {
    } else {
      List<Map<String, dynamic>> data = result.getMap();
      for (int i = 0; i < data.length; i++) {
        items.add(DropdownMenuItem(
            value: data[i]['vs003300'].toString(),
            child: Text(data[i]['vs003300'].toString() +
                ' : ' +
                data[i]['vs003301'].toString())));
      }
      setState(() {
        _layerItems = items;
      });
    }
  }

  Future<ResponseResult> _loadData(String carCarrierName) {
    Datagram datagram = Datagram();
    datagram.addText("""select t1.vsaa0200 as 車身號碼,
                               t2.vs000101 as 廠牌,
                               t3.vs000101 as 車款,
                               t1.vsaa0203 as 車型,
                               t1.vsaa0222 as 已卸車,
                               t1.vsaa0223 as 已進倉
                        from xvms_aa02 as t1  left join xvms_0001 as t2 on t1.vsaa0201 = t2.vs000100 and t2.vs000106 = '2'
                                              left join xvms_0001 as t3 on t1.vsaa0202 = t3.vs000100 and t3.vs000106 = '3'
                        where t1.status = 'Y' and vsaa0215 = N'$carCarrierName'
                        order by vsaa0216
                        """, rowIndex: 0, rowSize: 65535);
    Future<ResponseResult> result = Business.apiExecuteDatagram(datagram);
    return result;
  }
}
