import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:car_1/business/datagram.dart';
import 'package:car_1/business/responseresult.dart';
import 'package:car_1/apis/messagebox.dart';
import 'package:car_1/business/business.dart';
import '../model/sysMenu.dart';
import 'CarInformation.dart';
import 'CarSelect.dart';
import 'GeneralWidget.dart';
import 'GeneralFunction.dart';

class TVS0100008 extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _TVS0100008();
  }
}

class _TVS0100008 extends State<TVS0100008> with TickerProviderStateMixin {
  final String moduleId = 'TVS0100008';
  final String moduleName = '生產移車作業';
  String _imageCategory = 'TVS0100008';
  final _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final FocusNode _textFieldFocusNode = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _onlineMode = true; //true: online false: offline
  bool _isLoading = false;
  int _inputMode = 1; //0: keybarod 1: scanner 2:camera
  int _barcodeFixMode = 0; //0:一般 1:去頭 2:F/U
  int _workMode = 1; //0: 撿車 2: 移車
  String _message = '';
  ResultFlag _messageFlag = ResultFlag.ok;
  HardwareKeyboardListener _keyboardListen;
  List<Map<String, dynamic>> _fileList;
  bool _isExistsFile = false;
  //========================================================
  //AnimationController _animationController;
  final FocusNode _dirverFocusNode = FocusNode();
  final FocusNode _dirverTextFocusNode = FocusNode();
  final _driverController = TextEditingController();
  final _vinController = TextEditingController();
  final _gridController = TextEditingController();
  final Map<String, dynamic> _formData = {
    'layer': null,
    'date': null,
  };
  List<Map<String, dynamic>> _vinList;
  bool _hardwareInputMode = false;
  bool _gridDirection = true; //true: 正 false:逆
  List<DropdownMenuItem> _dateItems;
  List<DropdownMenuItem> _layerItems;
  List<String> _offlineDataBuffer = List<String>();
  String _vinNo = '';
  String _vinNoVersion = '';
  String _driverId = '';
  String _driverName = '';
  ScrollController _scrollController = new ScrollController(
    initialScrollOffset: 0.0,
    keepScrollOffset: true,
  );

  @override
  void initState() {
    // _keyboardListen = new HardwareKeyboardListener(_hardwareInputCallback);
    super.initState();
    _loadDate();
    _loadLayerData();
    portraitUp();
  }

  @override
  void dispose() {
    //为了避免内存泄露，需要调用_controller.dispose
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SharedPreferences.getInstance().then((prefs) {
      if (prefs.containsKey('TVS0100008') == true)
        _offlineDataBuffer = prefs.getStringList('TVS0100008');
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

    if ((_inputMode == 1 || _inputMode == 2) &&
        _dirverFocusNode.hasFocus == true) {
      SystemChannels.textInput.invokeMethod('TextInput.hide');
      // FocusScope.of(context).requestFocus(_dirverFocusNode);
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
                        // onlineMode: _onlineMode,
                        // onOnlineModeChange: (bool value) {
                        //   _onlineMode = value;
                        //   debugPrint('連線模式: ' + _onlineMode.toString());
                        // },
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
                        //作業模式
                        workcodeMode: _workMode,
                        onWorkcodeChange: (int value) {
                          _workMode = value;
                          debugPrint('作業模式: ' + _workMode.toString());
                        },
                        //dataUpload
                        // offlineDataBuffer: _offlineDataBuffer,
                        isLoading: _isLoading,
                        // xvms0033List: _xvms0033List,
                        // dataUpload: (ResultFlag value3, String value4) async {
                        //   _isLoading = true;
                        //   if (value3 == ResultFlag.ok) {
                        //     _offlineDataBuffer.clear();
                        //     SharedPreferences prefs =
                        //         await SharedPreferences.getInstance();
                        //     if (prefs.containsKey(moduleId) == true)
                        //       prefs.remove(moduleId);
                        //     _showMessage(value3, value4);
                        //   } else {
                        //     _showMessage(value3, value4);
                        //   }
                        //   _isLoading = false;
                        // },
                        //拍照
                        imageCategory: null, //作業圖庫
                        vinNo: null,
                        vinList: null,
                        onPhotograph: null),
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
                      buildDropdownButton('排程日期', 'date', _formData, _dateItems,
                          (dynamic value) {
                        setState(() {
                          _formData['date'] = value;
                        });
                        _loadDataList(value);
                      }),
                      _buildDriver(),
                      buildDropdownButton('儲區', 'layer', _formData, _layerItems,
                          (dynamic value) {
                        setState(() {
                          _formData['layer'] = value;
                        });
                      }),
                      _buildGrid(),
                      Row(
                        children: <Widget>[
                          buildLabel('車身號碼', _vinNo),
                          // buildLabel('版次', _vinNoVersion),
                        ],
                      ),
                      buildLabel('作業人員', _driverId + ' ' + _driverName),
                    ],
                  )),
                ),
              ),
              //================ Infomation Set Start
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

  Widget buildWorkcodeMode(
      Color color, int workcodeMode, void Function(int) selectMode) {
    List<String> _workcodeModeList = ['撿車', '移車'];
    return Container(
      height: 50,
      color: color,
      child: ListTile(
          leading: Icon(Icons.apps),
          title: Text('作業模式: ${_workcodeModeList[workcodeMode]}'),
          onTap: () {
            if (workcodeMode == 0)
              workcodeMode = 1;
            else if (workcodeMode == 1) workcodeMode = 0;
            selectMode(workcodeMode);
          }),
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
                          //檢查車身號碼是否有照相
                          setState(() {
                            _isExistsFile = false;
                          });
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

  Widget _buildDriver() {
    return Container(
      padding: EdgeInsets.only(left: 20.0, right: 20.0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
              child: RawKeyboardListener(
                focusNode: _dirverFocusNode,
                onKey: (RawKeyEvent key) {
                  if (key.runtimeType.toString() == 'RawKeyUpEvent') {
                    if (_inputMode == 1) {
                      _loadDriverData();
                    }
                  }
                },
                child: TextField(
                  focusNode: _dirverTextFocusNode,
                  autofocus: true,
                  decoration: InputDecoration(labelText: '作業人員'),
                  controller: _driverController,
                  keyboardType: TextInputType.text,
                  onEditingComplete: () {
                    // if (_inputMode == 0) {
                    //   _loadDriverData();
                    // }
                    _loadDriverData();
                    FocusScope.of(context).requestFocus(_textFieldFocusNode);
                  },
                ),
              ),
            ),
          ),
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
                  } else {
                    if (gridNumber <= 1)
                      gridNumber = 1;
                    else
                      gridNumber = gridNumber - 1;
                    _gridController.text =
                        gridNumber.toString().padLeft(4, '0');
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
        // Container(
        //     decoration: new BoxDecoration(
        //         border: new Border.all(color: Colors.grey, width: 0.5)),
        //     width: Business.deviceWidth(context) - 40,
        //     child: Row(
        //       children: <Widget>[
        //         Container(
        //             padding: EdgeInsets.only(left: 0),
        //             width: 90,
        //             child: Text('廠牌'),
        //             color: Colors.black12),
        //         Expanded(
        //             child: Container(
        //                 padding: EdgeInsets.only(left: 0),
        //                 width: 90,
        //                 child: Text('車款'),
        //                 color: Colors.black12)),
        //       ],
        //     )),
        Container(
            decoration: new BoxDecoration(
                border: new Border.all(color: Colors.grey, width: 0.5)),
            width: Business.deviceWidth(context) - 40,
            child: new NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  _scrollController.jumpTo(scrollInfo.metrics.pixels);
                  return false;
                },
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: <Widget>[
                      Container(
                          padding: EdgeInsets.only(left: 0),
                          width: 150,
                          child: Text('廠牌'),
                          color: Colors.black12),
                      Container(
                          padding: EdgeInsets.only(left: 0),
                          width: 300,
                          child: Text('車款'),
                          color: Colors.black12),
                      Container(
                          width: 160,
                          padding: EdgeInsets.only(right: 0),
                          child: Text('車身號碼'),
                          color: Colors.black12),
                      // Container(
                      //     width: 50,
                      //     padding: EdgeInsets.only(right: 0),
                      //     child: Text('版次'),
                      //     color: Colors.black12),
                      Container(
                          padding: EdgeInsets.only(left: 0),
                          width: 80,
                          child: Text('原_儲區'),
                          color: Colors.black12),
                      Container(
                          padding: EdgeInsets.only(left: 0),
                          width: 80,
                          child: Text('原_儲格'),
                          color: Colors.black12),
                      Container(
                          padding: EdgeInsets.only(left: 0),
                          width: 80,
                          child: Text('計畫說明'),
                          color: Colors.black12),
                    ],
                  ),
                ))),
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
    return SingleChildScrollView(
      physics: new NeverScrollableScrollPhysics(),
      scrollDirection: Axis.horizontal,
      controller: _scrollController,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _inputController.text = data['車身號碼'].toString();
            _vinNo = data['車身號碼'].toString();
            _vinNoVersion = data['版次'].toString();
          });
        },
        onLongPress: () {
          CarInformation.show(context, data['車身號碼'].toString());
        },
        child: Container(
            height: 25,
            decoration: new BoxDecoration(
                color: data['移車狀態'] == '已移車'
                    ? Colors.lightGreen
                    : data['移車狀態'] == '已撿車'
                        ? Colors.orange
                        : Colors.white,
                border: new Border.all(color: Colors.grey, width: 0.5)),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.only(left: 2),
                      width: 150,
                      child: Text(
                        data['廠牌'] == null
                            ? ''
                            : (data['廠牌'].toString().length > 7
                                ? '...' +
                                    data['廠牌']
                                        .toString()
                                        .substring(
                                            data['廠牌'].toString().length - 7)
                                        .trim()
                                : data['廠牌'].toString()),
                        style: TextStyle(fontSize: 14),
                      ),
                      // color: Colors.white,
                    ),
                    Container(
                      width: 300,
                      child: Text(
                        data['車款'] == null
                            ? ''
                            : (data['車款'].toString().length > 20
                                ? '...' +
                                    data['車款']
                                        .toString()
                                        .substring(
                                            data['車款'].toString().length - 20)
                                        .trim()
                                : data['車款'].toString()),
                        style: TextStyle(fontSize: 14),
                      ),
                      // color: Colors.white
                    ),
                    Container(
                      width: 160,
                      child: Text(
                        data['車身號碼'] == null ? '' : data['車身號碼'].toString(),
                        style: TextStyle(fontSize: 14),
                      ),
                      // color: Colors.white
                    ),
                    // Container(
                    //   width: 50,
                    //   child: Text(
                    //     data['版次'] == null ? '' : data['版次'].toString(),
                    //     style: TextStyle(fontSize: 14),
                    //   ), // color: Colors.white
                    // ),
                    Container(
                      width: 80,
                      child: Text(
                        data['儲區'] == null ? '' : data['儲區'].toString(),
                        style: TextStyle(fontSize: 14),
                      ), // color: Colors.white
                    ),
                    Container(
                      width: 80,
                      child: Text(
                        data['儲格'] == null ? '' : data['儲格'].toString(),
                        style: TextStyle(fontSize: 14),
                      ), // color: Colors.white
                    ),
                    Container(
                      width: 80,
                      child: Text(
                        data['計劃說明'] == null ? '' : data['計劃說明'].toString(),
                        style: TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ), // color: Colors.white
                    ),
                  ],
                ),
              ],
            )),
      ),
    );
  }

  Widget _buildTextListener() {
    return Container(
      padding: EdgeInsets.only(left: 20.0),
      child: RawKeyboardListener(
        focusNode: _inputFocusNode,
        onKey: _handKey,
        child: TextField(
          controller: _inputController,
          keyboardType: TextInputType.text,
          onEditingComplete: () {
            if (_inputMode == 0) {
              _inputData(_inputController.text);
              FocusScope.of(context).requestFocus(new FocusNode());
            }
          },
        ),
      ),
    );
  }

  void _handKey(RawKeyEvent key) {
    RawKeyEventDataAndroid data = key.data as RawKeyEventDataAndroid;
    String _keyCode;
    _keyCode = data.keyCode.toString();
    if (key.runtimeType.toString() == 'RawKeyDownEvent') {
    } else if (key.runtimeType.toString() == 'RawKeyUpEvent') {
      _hardwareInputCallback(_inputController.text);
      _inputData(_inputController.text);
    }
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
    if (value == '') {
      _showMessage(ResultFlag.ng, '請輸入或掃描車身號碼');
      return;
    }

    if (_vinList == null || _vinList.length == 0) {
      _showMessage(ResultFlag.ng, '請選擇排程日期');
      return;
    }
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
    if (fullCount == 0 && startWithCount == 0 && endWithCount == 0) {
      _showMessage(ResultFlag.ng, '沒有符合的車身號碼:' + value);
      return;
    }
    if (_driverController.text == '') {
      _showMessage(ResultFlag.ng, '請刷入員工工號');
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
        _vinNo = _vinList
            .firstWhere((v) => v['車身號碼'].toString() == value)['車身號碼']
            .toString();
        _vinNoVersion = _vinList
            .firstWhere((v) => v['車身號碼'].toString() == value)['版次']
            .toString();
      });
      _saveData();
    } else if (startWithCount == 1) {
      setState(() {
        _vinNo = _vinList
            .firstWhere(
                (v) => v['車身號碼'].toString().startsWith(value) == true)['車身號碼']
            .toString();
        _vinNoVersion = _vinList
            .firstWhere(
                (v) => v['車身號碼'].toString().startsWith(value) == true)['版次']
            .toString();
      });
      _saveData();
    } else if (endWithCount > 1) {
      List<Map<String, dynamic>> list = List();

      _vinList
          .where((v) => v['車身號碼'].toString().endsWith(value) == true)
          .toList()
          .forEach((f) {
        list.add({
          '車身號碼': f['車身號碼'].toString() + '_' + f['版次'].toString(),
        });
      });
      String vin = await CarSelect.showWithList(context, list);
      if (vin == null) {
        _showMessage(
            ResultFlag.ng, '找不到符合一筆以上的車身號碼:' + value + ' 請輸入完整或檢查資料來源');
        return;
      }
      if (_vinList
              .where((v) => v['車身號碼'].toString() == vin.split('_')[0])
              .length ==
          0) {
        _showMessage(
            ResultFlag.ng, '找不到符合一筆以上的車身號碼:' + value + ' 請輸入完整或檢查資料來源');
        return;
      }

      setState(() {
        // List vinvalue = _vinList
        //     .firstWhere((v) => v['車身號碼'].toString().split('_')[0] == vin)['車身號碼']
        //     .toString()
        //     .split('_');
        _vinNo = vin.split('_')[0];
        _vinNoVersion = vin.split('_')[1];
      });
      _saveData();
    } else if (endWithCount == 1) {
      setState(() {
        _vinNo = _vinList
            .firstWhere(
                (v) => v['車身號碼'].toString().endsWith(value) == true)['車身號碼']
            .toString();
        _vinNoVersion = _vinList
            .firstWhere(
                (v) => v['車身號碼'].toString().endsWith(value) == true)['版次']
            .toString();
      });
      _saveData();
    } else {
      _showMessage(ResultFlag.ng, '找不到符合一筆以上的車身號碼:' + value + ' 請輸入完整或檢查資料來源');
    }
    setState(() {
      _inputController.text = '';
      _vinNo = '';
      _vinNoVersion = '';
    });
  }

  void _saveData() async {
    String status = _vinList
        .firstWhere((v) =>
            v['車身號碼'].toString() == _vinNo &&
            v['版次'].toString() == _vinNoVersion)['移車狀態']
        .toString();
    //撿車
    if (_workMode == 0 && status != '未執行') {
      _showMessage(ResultFlag.ng, _vinNo + ' 目前狀態 ' + status + ' 不可撿車');
      return;
    }
    //移車
    else if (_workMode == 1 && status != '已撿車') {
      _showMessage(ResultFlag.ng, _vinNo + ' 目前狀態 ' + status + ' 不可移車');
      return;
    }
    if (_driverId == "") {
      _showMessage(ResultFlag.ng, '請輸入員工工號');
      return;
    }

    String vin = _vinNo;
    // String date = _formData['date'];
    String date = _formData['date'].split('/')[0].toString();
    String layer = _formData['layer'];
    String grid = _gridController.text;
    String driver = _driverId;

    if (_onlineMode == true)
    //====Online
    {
      Datagram datagram = Datagram();
      List<ParameterField> paramList = List<ParameterField>();
      paramList.add(ParameterField(
          'sSTATUS', ParamType.strings, ParamDirection.input,
          value: _workMode.toString())); //狀態
      paramList.add(ParameterField(
          'sVSAA1100', ParamType.strings, ParamDirection.input,
          value: vin)); //車身號碼
      paramList.add(ParameterField(
          'sVSAA1107', ParamType.strings, ParamDirection.input,
          value: date)); //生產日期
      paramList.add(ParameterField(
          'sVSAA1114', ParamType.strings, ParamDirection.input,
          value: driver)); //移車人員
      paramList.add(ParameterField(
          'sVSAA1118', ParamType.strings, ParamDirection.input,
          value: layer)); //新儲區
      paramList.add(ParameterField(
          'sVSAA1119', ParamType.strings, ParamDirection.input,
          value: grid)); //新儲格
      paramList.add(ParameterField(
          'sVSAA1120', ParamType.strings, ParamDirection.input,
          value: _vinNoVersion)); //版次
      paramList.add(ParameterField(
          'sUSERID', ParamType.strings, ParamDirection.input,
          value: driver));
      paramList.add(ParameterField(
          'oRESULT_FLAG', ParamType.strings, ParamDirection.output));
      paramList.add(
          ParameterField('oRESULT', ParamType.strings, ParamDirection.output));
      datagram.addProcedure('SPX_XVMS_AA11_LOCATION', parameters: paramList);
      ResponseResult result = await Business.apiExecuteDatagram(datagram);
      if (result.flag == ResultFlag.ok) {
        //  _vinList.firstWhere((v) => v['車身號碼'].toString() == _vinNo)['移車狀態'] =
        //      '已檢車';
        _showMessage(ResultFlag.ok, '作業成功');
        setState(() {
          _vinNo = '';
          _vinNoVersion = '';
          _driverController.text = '';
          _inputController.text = '';
          _driverId = '';
          _driverName = '';
          _loadDataList(_formData['date']);
        });
        FocusScope.of(context).requestFocus(_dirverTextFocusNode);
      } else {
        _showMessage(ResultFlag.ng, result.getNGMessage());
      }
    }
    //Offline
    else {
      // 離線模式不使用,在更新上傳時,會有更新錯誤,檢車與移車誰先更新的機率

      // _vinList.firstWhere((v) => v['車身號碼'].toString() == _vinNo)['移車狀態'] = 'Y';
      // SharedPreferences prefs = await SharedPreferences.getInstance();

      // if (prefs.containsKey('TVS0100008') == true)
      //   _offlineDataBuffer = prefs.getStringList('TVS0100008');
      // setState(() {
      //   _vinNo = '';
      //   _vinNoVersion = '';
      //   _driverController.text = '';
      //   _driverId = '';
      //   _driverName = '';
      //   _offlineDataBuffer.add(_workMode.toString() +
      //       '|' +
      //       vin +
      //       '|' +
      //       date +
      //       '|' +
      //       layer +
      //       '|' +
      //       grid +
      //       '|' +
      //       driver +
      //       '|' +
      //       _vinNoVersion);
      // });
      // prefs.setStringList('TVS0100008', _offlineDataBuffer);
      // _showMessage(ResultFlag.ok, '移車成功(離線)');
      // FocusScope.of(context).requestFocus(_dirverTextFocusNode);
    }

    setState(() {
      int gridNumber = int.tryParse(grid);

      if (_gridDirection == true) {
        if (gridNumber >= 99999)
          gridNumber = 99999;
        else
          gridNumber = gridNumber + 1;
        _gridController.text = gridNumber.toString().padLeft(4, '0');
      } else {
        if (gridNumber <= 1)
          gridNumber = 1;
        else
          gridNumber = gridNumber - 1;
        _gridController.text = gridNumber.toString().padLeft(4, '0');
      }
    });
  }

  void _loadDataList(String date) async {
    setState(() {
      _isLoading = true;
    });

    if (_onlineMode == true) {
      final ResponseResult result = await _loadData(date);
      if (result.flag == ResultFlag.ok) {
        List<Map<String, dynamic>> data = result.getMap();
        if (data.length == 0) {
          setState(() {
            _isLoading = false;
            _vinList = null;
          });
        } else {
          setState(() {
            _isLoading = false;
            _vinList = data;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });

        MessageBox.showInformation(context, "", result.getNGMessage());
      }
    } else {
      setState(() {
        _isLoading = false;
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

  void _loadDriverData() async {
    Datagram datagram = Datagram();
    datagram.addText(
        """select ixa00401,ixa00403 from entirev4.dbo.ifx_a004 where ixa00400 = 'compid' and ixa00401 = '${_driverController.text}'""",
        rowIndex: 0, rowSize: 100);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      if (data.length > 0) {
        setState(() {
          _driverController.text = data[0]['ixa00401'].toString();
          _driverId = data[0]['ixa00401'].toString();
          _driverName = data[0]['ixa00403'].toString();
        });
      } else {
        setState(() {
          _driverController.text = '';
          _driverId = '';
          _driverName = '';
        });
        _showMessage(ResultFlag.ng, '員工主檔找不到此移車人員');
      }
    } else {
      _showMessage(ResultFlag.ng, result.getNGMessage());
    }
  }

  //排程日期
  void _loadDate() async {
    List<DropdownMenuItem> items = new List();
    Datagram datagram = Datagram();
    datagram.addText("""select  vsaa1107 as 排程日期,
                                vsaa1109 作業單位代碼,
                                (select ixa01002 from entirev4.dbo.ifx_a010 where ixa01000='compid' and ixa01001=vsaa1109) as 作業單位,
                                vsaa1120 as 移車版本
                        from xvms_aa11 as t1
                        where vsaa1113 = 'N' 
                        group by vsaa1107,vsaa1109,vsaa1120
                        order by vsaa1107 desc""", rowIndex: 0, rowSize: 100);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);

    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      for (int i = 0; i < data.length; i++) {
        items.add(DropdownMenuItem(
            value: data[i]['排程日期'].toString() +
                '/' +
                data[i]['作業單位代碼'].toString() +
                '/' +
                data[i]['移車版本'].toString(),
            child: Text(data[i]['排程日期'].toString() +
                ' ' +
                data[i]['作業單位'].toString() +
                ' ' +
                data[i]['移車版本'].toString())));
      }
      setState(() {
        _dateItems = items;
      });
    } else {
      _showMessage(ResultFlag.ng, result.getNGMessage());
    }
  }

  void _hardwareInputCallback(String value) {
    if (_inputMode == 1) {
      _inputController.text = CommonMethod.barcodeCheck(_barcodeFixMode, value);
    }
  }

  Future<ResponseResult> _loadData(String data) {
    Datagram datagram = Datagram();
    datagram.addText("""select t1.vsaa1100 as 車身號碼,
                               t1.vsaa1120 as 版次,
                               t2.vs000101 as 廠牌,
                               t3.vs000101 as 車款,
                               t1.vsaa1104 as 車型,
                               vsaa1110 as 計劃說明,
                               vsaa1111 儲區,
                               vsaa1112 儲格,
                               case when vsaa1113='Y' then '已移車'
                                    when vsaa1121='Y' then '已撿車'
                               else '未執行' end 移車狀態
                        from xvms_aa11 as t1  left join xvms_0001 as t2 on t1.vsaa1102 = t2.vs000100 and t2.vs000106 = '2'
                                              left join xvms_0001 as t3 on t1.vsaa1103 = t3.vs000100 and t3.vs000106 = '3'
                                              left join entirev4.dbo.ifx_a010 t4 on t1.vsaa1109=t4.ixa01001
                        where vsaa1107 + '/' + vsaa1109 + '/' + cast(vsaa1120 as varchar) = '$data'
                        order by vsaa1107 desc""", rowIndex: 0, rowSize: 65535);
    debugPrint(datagram.commandList[0].commandText);
    Future<ResponseResult> result = Business.apiExecuteDatagram(datagram);

    return result;
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
  //==== workMode
  final int workcodeMode;
  final void Function(int) onWorkcodeChange;

  //==== DataUpload
  // final void Function(ResultFlag, String) dataUpload;
  // List<String> offlineDataBuffer = List<String>();
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
    // @required this.onlineMode,
    // @required this.onOnlineModeChange,
    //InputMode
    @required this.inputMode,
    @required this.onInputModeChange,
    //BarcodeMode
    @required this.barcodeMode,
    @required this.onBarcodeChange,
    //workcodeMode
    @required this.workcodeMode,
    @required this.onWorkcodeChange,

    //==== DataUpload
    // @required this.dataUpload,
    // @required this.offlineDataBuffer,
    // @required this.xvms0033List,
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
  int _workcodeMode = 0;
  String _imageCategory = 'TVS0100008';
  bool _onlineMode = true; //在線模式
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
    _workcodeMode = widget.workcodeMode;
    _isLoading = widget.isLoading;
    // _offlineDataBuffer = widget.offlineDataBuffer;
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
            // buildConnectMode(Color(0xffe1e6ef), _onlineMode, (bool value) {
            //   widget.onOnlineModeChange(value);
            //   setState(() {
            //     _onlineMode = value;
            //   });
            // }),
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
            //==== workcodeMode
            buildWorkcodeMode(Colors.white, _workcodeMode, (int value) {
              widget.onWorkcodeChange(value);
              setState(() {
                _workcodeMode = value;
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
            //   if (_isLoading == true) return;
            //   ResultFlag _rf = ResultFlag.ok;
            //   String resultMs = '資料上傳成功';
            //   MessageBox.showQuestion(
            //       context,
            //       '共' + (_offlineDataBuffer.length).toString() + '筆資料',
            //       '確定上傳?', yesFunc: () async {
            //     setState(() {
            //       _isLoading = true;
            //     });
            //     Datagram datagram = Datagram();
            //     _offlineDataBuffer.forEach((s) {
            //       String workMode = s.split('|')[0];
            //       String vin = s.split('|')[1];
            //       String date = s.split('|')[2];
            //       String layer = s.split('|')[3];
            //       String grid = s.split('|')[4];
            //       String driver = s.split('|')[5];
            //       String vinNoVersion = s.split('|')[6];

            //       List<ParameterField> paramList = List<ParameterField>();
            //       paramList.add(ParameterField(
            //           'sSTATUS', ParamType.strings, ParamDirection.input,
            //           value: workMode.toString())); //狀態
            //       paramList.add(ParameterField(
            //           'sVSAA1100', ParamType.strings, ParamDirection.input,
            //           value: vin)); //車身號碼
            //       paramList.add(ParameterField(
            //           'sVSAA1107', ParamType.strings, ParamDirection.input,
            //           value: date)); //生產日期
            //       paramList.add(ParameterField(
            //           'sVSAA1114', ParamType.strings, ParamDirection.input,
            //           value: driver)); //移車人員
            //       paramList.add(ParameterField(
            //           'sVSAA1118', ParamType.strings, ParamDirection.input,
            //           value: layer)); //新儲區
            //       paramList.add(ParameterField(
            //           'sVSAA1119', ParamType.strings, ParamDirection.input,
            //           value: grid)); //新儲格
            //       paramList.add(ParameterField(
            //           'sVSAA1120', ParamType.strings, ParamDirection.input,
            //           value: vinNoVersion)); //版次
            //       paramList.add(ParameterField(
            //           'sUSERID', ParamType.strings, ParamDirection.input,
            //           value: driver));
            //       paramList.add(ParameterField('oRESULT_FLAG',
            //           ParamType.strings, ParamDirection.output));
            //       paramList.add(ParameterField(
            //           'oRESULT', ParamType.strings, ParamDirection.output));
            //       datagram.addProcedure('SPX_XVMS_AA11_LOCATION',
            //           parameters: paramList);
            //     });
            //     ResponseResult result =
            //         await Business.apiExecuteDatagram(datagram);
            //     if (result.flag == ResultFlag.ok) {
            //       _rf = ResultFlag.ok;
            //       resultMs = result.getNGMessage();
            //     } else {
            //       _rf = ResultFlag.ng;
            //       resultMs = result.getNGMessage();
            //     }
            //     //_showMessage(ResultFlag.ng, result.getNGMessage());

            //     setState(() {
            //       _isLoading = false;
            //     });
            //     widget.dataUpload(_rf, resultMs);
            //   });
            // }),
            // // //==== 作業圖庫
            // buildGalleryWithSeqNo(context, Colors.white, _imageCategory),
            // //==== 拍照
            // buildPhotograph(
            //     context, Color(0xffe1e6ef), _vinNo, _vinList, _imageCategory,
            //     (Map<String, dynamic> map) {
            //       ResultFlag _rf = ResultFlag.ok;
            //       String resultMs ='拍照完成';

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
            Divider(height: 2.0, color: Colors.black),
          ],
        ),
      ),
    );
  }

  Widget buildWorkcodeMode(
      Color color, int workcodeMode, void Function(int) selectMode) {
    List<String> _workcodeModeList = ['撿車', '移車'];
    return Container(
      height: 50,
      color: color,
      child: ListTile(
          leading: Icon(Icons.apps),
          title: Text('作業模式: ${_workcodeModeList[workcodeMode]}'),
          onTap: () {
            if (workcodeMode == 0)
              workcodeMode = 1;
            else if (workcodeMode == 1) workcodeMode = 0;
            selectMode(workcodeMode);
          }),
    );
  }
}
