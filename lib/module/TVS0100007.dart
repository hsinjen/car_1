import 'dart:io';
import 'package:audioplayers/audio_cache.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:car_1/business/datagram.dart';
import 'package:car_1/business/responseresult.dart';
import 'package:car_1/apis/messagebox.dart';
import 'package:car_1/business/business.dart';
import '../model/sysMenu.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../module/CarInformation.dart';
import 'CarSelect.dart';
import 'GeneralFunction.dart';
import 'GeneralWidget.dart';

class TVS0100007 extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _TVS0100007();
  }
}

class _TVS0100007 extends State<TVS0100007> with TickerProviderStateMixin {
  final String moduleId = 'TVS0100007';
  final String moduleName = '車輛儲區作業';
  String _imageCategory = 'TVS0100007';
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
  static AudioCache _player = new AudioCache();
  List<Map<String, dynamic>> _fileList;
  //========================================================
  final _gridController = TextEditingController();
  final Map<String, dynamic> _formData = {'layer': null, 'grid': null};
  List<Map<String, dynamic>> _vinList;
  bool _gridDirection = true; //true: 正 false:逆
  bool _isOpenAlarm = true; //警示音
  List<DropdownMenuItem> _layerItems;
  List<String> _offlineDataBuffer = List<String>();
  String _vinNo = ''; //車身號碼
  String _layer = '';
  String _grid = '';
  int _rawKeyUpEventCount = 0;
  bool _inSwitch = false;

  @override
  void initState() {
    //_keyboardListen = new HardwareKeyboardListener(_hardwareInputCallback);
    super.initState();
    _loadLayerData();
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
      if (prefs.containsKey('TVS0100007') == true)
        _offlineDataBuffer = prefs.getStringList('TVS0100007');
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
                          // xvms0033List: _xvms0033List,
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
                          },
                          //警示音
                          isOpenAlarm: _isOpenAlarm,
                          isOpenAlarmChange: (bool value) {
                            _isOpenAlarm = value;
                          },
                        ),
                    fullscreenDialog: false),
              );
            },
          )
        ],
      ),
      drawer: buildMenu(context),
      body: Container(
        //decoration: BoxDecoration(image: _buildBackgroundImage()),
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
                      buildDropdownButton('儲區', 'layer', _formData, _layerItems,
                          (dynamic value) {
                        setState(() {
                          _formData['layer'] = value;
                        });
                        if (_inputMode == 1)
                          FocusScope.of(context).requestFocus(_inputFocusNode);
                      }),
                      _buildGrid(),
                      buildLabel('車身號碼', _vinNo),
                      buildLabel('儲區', _layer),
                      buildLabel('儲格', _grid),
                    ],
                  )),
                ),
              ),
              //================ 查詢清單 Start
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
                  '共' + _offlineDataBuffer.length.toString() + '筆資料',
                  '確定上傳更新儲位?', yesFunc: () async {
                setState(() {
                  _isLoading = true;
                });
                Datagram datagram = Datagram();
                //==== 更新到港
                if (_offlineDataBuffer.length > 0) {
                  _offlineDataBuffer.forEach((s) {
                    String vin = s.split('|')[0];
                    String layer = s.split('|')[1];
                    String grid = s.split('|')[2];

                    List<ParameterField> paramList = List<ParameterField>();
                    paramList.add(ParameterField(
                        'sMODE', ParamType.strings, ParamDirection.input,
                        value: '2'));
                    paramList.add(ParameterField(
                        'sVSAA0200', ParamType.strings, ParamDirection.input,
                        value: vin)); //車身號碼
                    paramList.add(ParameterField(
                        'sVSAA0226', ParamType.strings, ParamDirection.input,
                        value: layer)); //點交位置一(儲區)
                    paramList.add(ParameterField(
                        'sVSAA0227', ParamType.strings, ParamDirection.input,
                        value: grid)); //點交位置二(儲格)
                    paramList.add(ParameterField(
                        'sUSERID', ParamType.strings, ParamDirection.input,
                        value: Business.userId)); //員工編號
                    paramList.add(ParameterField('oRESULT_FLAG',
                        ParamType.strings, ParamDirection.output));
                    paramList.add(ParameterField(
                        'oRESULT', ParamType.strings, ParamDirection.output));
                    datagram.addProcedure('SPX_XVMS_AA02_LOCATION',
                        parameters: paramList);
                  });
                }

                ResponseResult result =
                    await Business.apiExecuteDatagram(datagram);
                if (result.flag == ResultFlag.ok) {
                  _offlineDataBuffer.clear();
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  if (prefs.containsKey('TVS0100007') == true)
                    prefs.remove('TVS0100007');
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
            //=== 警示音開關
            Container(
              height: 50,
              color: Colors.white,
              child: ListTile(
                  leading: Icon(Icons.apps),
                  title: Text('警示音: ${_isOpenAlarm == true ? '開' : '關'}'),
                  onTap: () {
                    setState(() {
                      _isOpenAlarm = !_isOpenAlarm;
                    });
                  }),
            ),
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
                  //if (_keyCode == '66' || _keyCode =='4') return;
                  //print("Event runtimeType is ${key.runtimeType}--keyCode:${_keyCode}");
                  if (key.runtimeType.toString() == 'RawKeyDownEvent') {
                  } else if (key.runtimeType.toString() == 'RawKeyUpEvent') {
                    if (_inputMode == 1) {
                      if (_inputController.text == '') return;
                      String value = '';
                      if (_inputMode == 1 &&
                          _inputController.text != '' &&
                          _inSwitch == false) {
                        _inSwitch = true;
                        value = CommonMethod.barcodeCheck(
                            _barcodeFixMode, _inputController.text);
                        _inputData(value);
                      }
                    }
                  }
                },
                child: TextField(
                  controller: _inputController,
                  focusNode: _textFieldFocusNode,
                  keyboardType: TextInputType.text,
                  onEditingComplete: () {
                    if (_inputMode == 0) {
                      _inputData(_inputController.text, isSaveData: false);
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
          //==== 清除
          Container(
            height: 25,
            width: 50,
            padding: EdgeInsets.only(right: 10),
            child: RaisedButton(
              padding: EdgeInsets.all(1),
              color: Colors.black,
              child: Text('清除',
                  style: TextStyle(fontSize: 12.0, color: Colors.white)),
              onPressed: () {
                setState(() => _gridController.text = '');
              },
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
                    if (gridNumber >= 9999)
                      gridNumber = 9999;
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
        Container(
          child: Container(
            child: Text(
              '查詢清單',
              textAlign: TextAlign.left,
            ),
            color: Colors.black26,
          ),
          width: Business.deviceWidth(context) - 40,
          decoration: new BoxDecoration(
              border: new Border.all(color: Colors.grey, width: 0.5)),
        ),
        Container(
            decoration: new BoxDecoration(
                border: new Border.all(color: Colors.grey, width: 0.5)),
            width: Business.deviceWidth(context) - 40,
            child: Row(
              children: <Widget>[
                Container(
                    padding: EdgeInsets.only(left: 0),
                    width: 60,
                    child: Text('儲區'),
                    color: Colors.black12),
                Container(
                    padding: EdgeInsets.only(left: 0),
                    width: 70,
                    child: Text('儲格'),
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
            }),
      );
    }
  }

  Widget _buildVinItem(BuildContext context, Map<String, dynamic> data) {
    int isPlayer = 0;
    if ((data['加油狀態'] == null ? '' : data['加油狀態']) == '未完成') {
      isPlayer++;
    }
    if ((data['存車狀態'] == null ? '' : data['存車狀態']) == '已加入存車') {
      isPlayer++;
    }
    if ((data['配件狀態'] == null ? '' : data['配件狀態']) == '已加入配件') {
      isPlayer++;
    }
    if ((data['新車狀態'] == null ? '' : data['新車狀態']) == '已加入新車') {
      isPlayer++;
    }
    return GestureDetector(
      onTap: () {
        setState(() {
          _inputController.text = data['車身號碼'].toString();
          _vinNo = data['車身號碼'].toString();
          // _formData['layer'] = data['儲區'];
          _layer = data['儲區'].toString();
          _grid = data['儲格'].toString();
        });
      },
      onLongPress: () {
        CarInformation.show(context, data['車身號碼'].toString());
      },
      child: Container(
        height: 30,
        decoration: new BoxDecoration(
            color: isPlayer > 0 ? Colors.red : Colors.white,
            border: new Border.all(color: Colors.grey, width: 0.5)),
        child: Row(
          children: <Widget>[
            Container(
              padding: EdgeInsets.only(left: 2),
              width: 60,
              child: Text(
                data['儲區'] == null
                    ? ''
                    : (data['儲區'].toString().length > 10
                        ? '...' +
                            data['儲區']
                                .toString()
                                .substring(data['儲區'].toString().length - 10)
                                .trim()
                        : data['儲區'].toString()),
                style: TextStyle(fontSize: 12),
              ),
              // color: Colors.white,
            ),
            Container(
              width: 70,
              child: Text(
                data['儲格'] == null
                    ? ''
                    : (data['儲格'].toString().length > 10
                        ? '...' +
                            data['儲格']
                                .toString()
                                .substring(data['儲格'].toString().length - 10)
                                .trim()
                        : data['儲格'].toString()),
                style: TextStyle(fontSize: 12),
              ),
              // color: Colors.white,
            ),
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

  void _inputData(String value, {bool isSaveData = true}) async {
    value = value.replaceAll('/', '');
    if (value == '') {
      _showMessage(ResultFlag.ng, '請輸入或掃描車身號碼');
      return;
    }
    setState(() {
      _isLoading = true;
    });
    List<Map<String, dynamic>> data;
    ResponseResult result = await _loadData(value);
    if (result.flag == ResultFlag.ok) {
      data = result.getMap();
      if (data.length > 0) {
        _vinList = data;

        int isPlayer = 0;
        if (data.where((v) => v['加油狀態'] == '未完成').length > 0) {
          isPlayer++;
        }
        if (data.where((v) => v['存車狀態'] == '已加入存車').length > 0) {
          isPlayer++;
        }
        if (data.where((v) => v['配件狀態'] == '已加入配件').length > 0) {
          isPlayer++;
        }
        if (data.where((v) => v['新車狀態'] == '已加入新車').length > 0) {
          isPlayer++;
        }
        if (isPlayer > 0) {
          if (_isOpenAlarm == true) {
            _player.play('sounds/alarm.mp3');
          }
        }
      } else
        _vinList = null;

      _inSwitch = false;
    } else {
      _vinList = null;
      _isLoading = false;
      _showMessage(ResultFlag.ng, result.getNGMessage());
      _inSwitch = false;
      return;
    }

    if (isSaveData == true) {
      setState(() {
        _inputController.text = '';
        _vinNo = '';
        _isLoading = false;
      });
      int fullCount = 0;
      int startWithCount = 0;
      int endWithCount = 0;
      fullCount = data.where((v) => v['車身號碼'].toString() == value).length;
      startWithCount = data
          .where((v) => v['車身號碼'].toString().startsWith(value) == true)
          .length;
      endWithCount = data
          .where((v) => v['車身號碼'].toString().endsWith(value) == true)
          .length;
      if (fullCount == 0 && startWithCount == 0 && endWithCount == 0) {
        _showMessage(ResultFlag.ng, '沒有符合的車身號碼:' + value);
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
      if (_gridController.text.length != 4) {
        _showMessage(ResultFlag.ng, '儲格必須等於 4 碼');
        return;
      }
      if (fullCount == 1) {
        setState(() {
          _vinNo = data
              .firstWhere((v) => v['車身號碼'].toString() == value)['車身號碼']
              .toString();
          _layer = data
              .firstWhere((v) => v['車身號碼'].toString() == value)['儲區']
              .toString();
          _grid = data
              .firstWhere((v) => v['車身號碼'].toString() == value)['儲格']
              .toString();
        });
        _saveData();
      } else if (startWithCount == 1) {
        setState(() {
          _vinNo = data
              .firstWhere(
                  (v) => v['車身號碼'].toString().startsWith(value) == true)['車身號碼']
              .toString();
          _layer = data
              .firstWhere(
                  (v) => v['車身號碼'].toString().startsWith(value) == true)['儲區']
              .toString();
          _grid = _vinList
              .firstWhere(
                  (v) => v['車身號碼'].toString().startsWith(value) == true)['儲格']
              .toString();
        });
        _saveData();
      } else if (endWithCount == 1) {
        setState(() {
          _vinNo = data
              .firstWhere(
                  (v) => v['車身號碼'].toString().endsWith(value) == true)['車身號碼']
              .toString();
          _layer = data
              .firstWhere(
                  (v) => v['車身號碼'].toString().endsWith(value) == true)['儲區']
              .toString();
          _grid = data
              .firstWhere(
                  (v) => v['車身號碼'].toString().endsWith(value) == true)['儲格']
              .toString();
        });
        _saveData();
      } else if (fullCount > 1) {
        List<Map<String, dynamic>> list = List();
        data.where((v) => v['車身號碼'].toString() == value).toList().forEach((f) {
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
          _vinNo = data
              .firstWhere((v) => v['車身號碼'].toString() == value)['車身號碼']
              .toString();
          _layer = data
              .firstWhere((v) => v['車身號碼'].toString() == value)['儲區']
              .toString();
          _grid = data
              .firstWhere((v) => v['車身號碼'].toString() == value)['儲格']
              .toString();
        });
        _saveData();
      } else if (startWithCount > 1) {
        List<Map<String, dynamic>> list = List();
        data
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
          _vinNo = data
              .firstWhere((v) => v['車身號碼'].toString() == value)['車身號碼']
              .toString();
          _layer = data
              .firstWhere((v) => v['車身號碼'].toString() == value)['儲區']
              .toString();
          _grid = data
              .firstWhere((v) => v['車身號碼'].toString() == value)['儲格']
              .toString();
        });
        _saveData();
      } else if (endWithCount > 1) {
        List<Map<String, dynamic>> list = List();
        data
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
          _vinNo = data
              .firstWhere((v) => v['車身號碼'].toString() == value)['車身號碼']
              .toString();
          _layer = data
              .firstWhere((v) => v['車身號碼'].toString() == value)['儲區']
              .toString();
          _grid = data
              .firstWhere((v) => v['車身號碼'].toString() == value)['儲格']
              .toString();
        });
        _saveData();
      } else {
        _showMessage(
            ResultFlag.ng, '找不到符合一筆以上的車身號碼:' + value + ' 請輸入完整或檢查資料來源');
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _saveData() async {
    String vin = _vinNo;
    String layer = _formData['layer'];
    String grid = _gridController.text;

    //====Online
    if (_onlineMode == true) {
      Datagram datagram = Datagram();
      List<ParameterField> paramList = List<ParameterField>();
      paramList.add(ParameterField(
          'sMODE', ParamType.strings, ParamDirection.input,
          value: '2'));
      paramList.add(ParameterField(
          'sVSAA0200', ParamType.strings, ParamDirection.input,
          value: vin)); //車身號碼
      paramList.add(ParameterField(
          'sVSAA0226', ParamType.strings, ParamDirection.input,
          value: layer)); //點交位置一(儲區)
      paramList.add(ParameterField(
          'sVSAA0227', ParamType.strings, ParamDirection.input,
          value: grid)); //點交位置二(儲格)
      paramList.add(ParameterField(
          'sUSERID', ParamType.strings, ParamDirection.input,
          value: Business.userId)); //員工編號
      paramList.add(ParameterField(
          'oRESULT_FLAG', ParamType.strings, ParamDirection.output));
      paramList.add(
          ParameterField('oRESULT', ParamType.strings, ParamDirection.output));
      datagram.addProcedure('SPX_XVMS_AA02_LOCATION', parameters: paramList);
      ResponseResult result = await Business.apiExecuteDatagram(datagram);
      if (result.flag == ResultFlag.ok) {
        _vinList.firstWhere((v) => v['車身號碼'].toString() == _vinNo)['儲區'] =
            layer;
        _vinList.firstWhere((v) => v['車身號碼'].toString() == _vinNo)['儲格'] = grid;
        setState(() {
          _layer = layer;
          _grid = grid;
        });
        _showMessage(ResultFlag.ok, '更新成功');
      } else {
        _showMessage(ResultFlag.ng, result.getNGMessage());
      }
    }
    //====Offline
    else {
      _vinList.firstWhere((v) => v['車身號碼'].toString() == _vinNo)['儲區'] = layer;
      _vinList.firstWhere((v) => v['車身號碼'].toString() == _vinNo)['儲格'] = grid;
      setState(() {
        _layer = layer;
        _grid = grid;
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey('TVS0100007') == true)
        _offlineDataBuffer = prefs.getStringList('TVS0100007');
      setState(() {
        _offlineDataBuffer.add(vin + '|' + layer + '|' + grid);
      });
      prefs.setStringList('TVS0100007', _offlineDataBuffer);
      _showMessage(ResultFlag.ok, '更新成功(離線)');
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

  void _showMessage(ResultFlag flag, String message) {
    setState(() {
      _messageFlag = flag;
      if (message == null) message = '';
      _message = message;
    });
    CommonMethod.playSound(flag);
  }

  // void _loadDataList(String vin) async {
  //   setState(() {
  //     _isLoading = true;
  //   });

  //   final ResponseResult result = await _loadData(vin);
  //   if (result.flag == ResultFlag.ok) {
  //     List<Map<String, dynamic>> data = result.getMap();
  //     if (data.length == 0) {
  //       setState(() {
  //         _isLoading = false;
  //         _vinList = null;
  //       });
  //     } else {
  //       setState(() {
  //         _isLoading = false;
  //         _vinList = data;
  //       });
  //     }
  //   } else {
  //     setState(() {
  //       _isLoading = false;
  //     });

  //     MessageBox.showInformation(context, "", result.getNGMessage());
  //   }
  // }

  Future<ResponseResult> _loadData(String vin) async {
    Datagram datagram = Datagram();
    datagram.addText("""select vsaa0100 as 車身號碼,
                               vsaa0115 as 儲區,
                               vsaa0116 as 儲格,
                               case when (select top 1 1 from xvms_aa14 where vsaa1400 = t2.vsaa0100 and vsaa1416 = 'N') = 1 then '未完成' else '已完成' end as 加油狀態,
                               case when (select top 1 1 from xvms_aa09 where vsaa0900 = t2.vsaa0100) = 1 then '已加入存車' else '未加入存車' end as 存車狀態,
                               case when (select top 1 1 from xvms_aa13 where vsaa1300 = t2.vsaa0100) = 1 then '已加入配件' else '未加入配件' end as 配件狀態,
                               case when (select top 1 1 from xvms_aa20 where vsaa2000 = t2.vsaa0100) = 1 then '已加入新車' else '未加入新車' end as 新車狀態
                        from
                        (
                            select vsaa0100 as 車身號碼,
                                   max(vsaa0119) as 點交次數
                            from xvms_aa01
                            group by vsaa0100
                        ) as t1
                        left join xvms_aa01 as t2 on t1.車身號碼 = t2.vsaa0100 and
                                                     t1.點交次數 = t2.vsaa0119
                        where vsaa0100 like '%$vin%'
                        """, rowIndex: 0, rowSize: 65535);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
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
  // List<Map<String, dynamic>> xvms0033List;
  String moduleId = 'TVS0100007';
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
  bool isOpenAlarm = true;
  void Function(bool) isOpenAlarmChange;

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
    // @required this.xvms0033List,
    @required this.isLoading,

    //拍照
    @required this.imageCategory, //作業圖庫
    @required this.vinNo,
    @required this.vinList,
    @required this.onPhotograph,
    //警示音
    @required this.isOpenAlarm,
    @required this.isOpenAlarmChange,
  });

  @override
  State<StatefulWidget> createState() {
    return _FunctionMenu();
  }
}

class _FunctionMenu extends State<FunctionMenu> {
  int _inputMode = 1;
  int _barcodeFixMode = 0;
  String _imageCategory = 'TVS0100007';
  bool _onlineMode = true; //在線模式
  String _vinNo = ''; //車身號碼
  List<Map<String, dynamic>> _vinList;

  bool _isLoading;
  List<String> _offlineDataBuffer = List<String>();
  // List<Map<String, dynamic>> _xvms0033List;
  bool _isOpenAlarm = true;
  @override
  void initState() {
    super.initState();
    _onlineMode = widget.onlineMode;
    _inputMode = widget.inputMode;
    _barcodeFixMode = widget.barcodeMode;
    _imageCategory = widget.imageCategory;
    _isLoading = widget.isLoading;
    _offlineDataBuffer = widget.offlineDataBuffer;
    // _xvms0033List = widget.xvms0033List;
    _vinNo = widget.vinNo;
    _vinList = widget.vinList;
    _isOpenAlarm = widget.isOpenAlarm;
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
              String resultMs;
              MessageBox.showQuestion(
                  context,
                  '共' + (_offlineDataBuffer.length).toString() + '筆資料',
                  '確定上傳?', yesFunc: () async {
                setState(() {
                  _isLoading = true;
                });
                Datagram datagram = Datagram();
                //==== 更新到港
                if (_offlineDataBuffer.length > 0) {
                  _offlineDataBuffer.forEach((s) {
                    String vin = s.split('|')[0];
                    String layer = s.split('|')[1];
                    String grid = s.split('|')[2];

                    List<ParameterField> paramList = List<ParameterField>();
                    paramList.add(ParameterField(
                        'sMODE', ParamType.strings, ParamDirection.input,
                        value: '2'));
                    paramList.add(ParameterField(
                        'sVSAA0200', ParamType.strings, ParamDirection.input,
                        value: vin)); //車身號碼
                    paramList.add(ParameterField(
                        'sVSAA0226', ParamType.strings, ParamDirection.input,
                        value: layer)); //點交位置一(儲區)
                    paramList.add(ParameterField(
                        'sVSAA0227', ParamType.strings, ParamDirection.input,
                        value: grid)); //點交位置二(儲格)
                    paramList.add(ParameterField(
                        'sUSERID', ParamType.strings, ParamDirection.input,
                        value: Business.userId)); //員工編號
                    paramList.add(ParameterField('oRESULT_FLAG',
                        ParamType.strings, ParamDirection.output));
                    paramList.add(ParameterField(
                        'oRESULT', ParamType.strings, ParamDirection.output));
                    datagram.addProcedure('SPX_XVMS_AA02_LOCATION',
                        parameters: paramList);
                  });
                }

                ResponseResult result =
                    await Business.apiExecuteDatagram(datagram);
                if (result.flag == ResultFlag.ok) {
                  _offlineDataBuffer.clear();
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  if (prefs.containsKey('TVS0100007') == true) {
                    prefs.remove('TVS0100007');
                  }

                  _rf = ResultFlag.ok;
                  resultMs = '資料上傳成功';
                } else {
                  _rf = ResultFlag.ng;
                  resultMs = result.getNGMessage();
                }

                // ResponseResult result =
                //     await Business.apiExecuteDatagram(datagram);
                // if (result.flag == ResultFlag.ok) {
                //   _rf = ResultFlag.ok;
                //   resultMs = result.getNGMessage();
                // } else{
                //   _rf = ResultFlag.ng;
                //   resultMs = result.getNGMessage();
                // }
                //_showMessage(ResultFlag.ng, result.getNGMessage());

                _isLoading = false;

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
            //=== 警示音開關
            Container(
              height: 50,
              color: Colors.white,
              child: ListTile(
                  leading: Icon(Icons.apps),
                  title: Text('警示音: ${_isOpenAlarm == true ? '開' : '關'}'),
                  onTap: () {
                    setState(() {
                      _isOpenAlarm = !_isOpenAlarm;
                    });
                    widget.isOpenAlarmChange(_isOpenAlarm);
                  }),
            ),
            Divider(height: 2.0, color: Colors.black),
          ],
        ),
      ),
    );
  }
}
