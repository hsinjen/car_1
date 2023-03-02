import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:car_1/business/datagram.dart';
import 'package:car_1/business/responseresult.dart';
import 'package:car_1/apis/messagebox.dart';
import 'package:car_1/business/business.dart';
import '../model/sysMenu.dart';
import 'CarInformation.dart';
import 'CarSelect.dart';
import 'GeneralFunction.dart';
import 'GeneralWidget.dart';

class TVS0100003 extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _TVS0100003();
  }
}

class _TVS0100003 extends State<TVS0100003> with TickerProviderStateMixin {
  final String moduleId = 'TVS0100003';
  final String moduleName = '盤點找車作業';
  String _imageCategory = 'TVS0100003';
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
  //========================================================
  final Map<String, dynamic> _formData = {
    'vsab1900': null, //盤點單號
    'vsab1901': null, //盤點項次
  };
  String _vinNo = ''; //車身號碼
  String _vsab1906 = ''; //備註
  List<Map<String, dynamic>> _vinList;
  int _invTotalCount = 0; //盤點總量
  int _invPickCount = 0; //已盤量

  List<String> _offlineDataBuffer = List<String>();
  final format = DateFormat("yyyy-MM-dd");
  List<DropdownMenuItem> _seqnumberItems;

  @override
  void initState() {
    // _keyboardListen = new HardwareKeyboardListener(_hardwareInputCallback);
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      if (prefs.containsKey('TVS0100003') == true)
        _offlineDataBuffer = prefs.getStringList('TVS0100003');
    });
    _loadSeqNumber();
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
                      buildDropdownButton(
                          '盤點單號', 'vsab1900', _formData, _seqnumberItems,
                          (dynamic value) {
                        setState(() {
                          _formData['vsab1900'] = value;
                        });
                        _loadDataList(value);
                      }),
                      Container(
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child:
                                  buildLabel('總車身數', _invTotalCount.toString()),
                            ),
                            Expanded(
                              child:
                                  buildLabel('已盤數', _invPickCount.toString()),
                            ),
                          ],
                        ),
                      ),
                      buildLabel('車身號碼', _vinNo),
                      buildRichText('備註:', _vsab1906,
                          valueColor: Colors.blue, valuefontSize: 18.0),
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
                  String vsaa1900 = s.split('|')[0];
                  String vsab1901 = s.split('|')[1];
                  String pickdate = s.split('|')[2];
                  String pickuser = s.split('|')[3];

                  datagram.addText("""update xvms_ab19 set status = status,
                                                             vsab1903 = '1',
                                                             vsab1904 = '$pickdate',
                                                             vsab1905 = '$pickuser'
                                        where vsab1900 = '$vsaa1900' and
                                              vsab1901 = $vsab1901 and
                                              vsab1903 = '0'
                                     """, rowIndex: 0, rowSize: 100);
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
                  if (_keyCode == '4' || _keyCode == '66') return;
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

  //此寫法刷讀時,會有問題,有時間再改良
  Widget _buildInputContainerbak() {
    return Container(
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
              padding: EdgeInsets.only(left: 20.0),
              child: TextField(
                inputFormatters: <TextInputFormatter>[_keyboardListen],
                focusNode: _inputFocusNode,
                controller: _inputController,
                enableInteractiveSelection: true,
                keyboardType: TextInputType.text,
                onChanged: (String value) {
                  if (_inputMode == 1) {
                    _inputData(value);
                  }
                },
                onEditingComplete: () {
                  if (_inputMode == 0) {
                    _inputData(_inputController.text);
                    FocusScope.of(context).requestFocus(new FocusNode());
                  }
                },
              ),
            ),
          ),
          //==== 清除
          Container(
            height: 20,
            width: 40,
            padding: EdgeInsets.only(right: 10),
            child: RaisedButton(
              padding: EdgeInsets.all(1),
              color: Colors.black,
              child: Text('清除',
                  style: TextStyle(fontSize: 12.0, color: Colors.white)),
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
                      setState(() {
                        _inputController.text = barcode == null ? '' : barcode;
                        _inputData(barcode == null ? '' : barcode);
                      });
                      FocusScope.of(context).requestFocus(_inputFocusNode);
                    } catch (e) {
                      _showMessage(ResultFlag.ng, 'Scan Barcode Error 請檢查相機權限');
                    }
                  },
                )
              : _inputMode == 0
                  ? Container(
                      height: 20,
                      width: 40,
                      padding: EdgeInsets.only(right: 10),
                      child: RaisedButton(
                        padding: EdgeInsets.all(1),
                        color: Colors.black,
                        child: Text('確認',
                            style:
                                TextStyle(fontSize: 12.0, color: Colors.white)),
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
          child: _buildCarList(_vinList),
        ),
      ]),
    );
  }

  Widget _buildCarList(List<Map<String, dynamic>> data) {
    if (data == null)
      return Container(child: Text('沒有資料'));
    else {
      List<Map<String, dynamic>> _data;
      String vin = _formData['vin'] == null ? '' : _formData['vin'];
      _data = data
          .where((v) => v['車身號碼'].toString().endsWith(vin) == true)
          .toList();
      if (_data.length > 0) {
        return Container(
          width: Business.deviceWidth(context) - 40,
          child: ListView.builder(
              itemCount: _data == null ? 0 : _data.length,
              itemBuilder: (BuildContext context, int index) {
                return _buildCarItem(context, _data[index]);
              }),
        );
      } else {
        return Container(child: Text('沒有資料'));
      }
    }
  }

  Widget _buildCarItem(BuildContext context, Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _vinNo = data['車身號碼'].toString();
          _inputController.text = data['車身號碼'].toString();
          _formData['vsab1900'] = data['盤點單號'].toString();
          _formData['vsab1901'] = data['盤點項次'].toString();
          _vsab1906 = data['備註'].toString();
        });
      },
      child: Container(
        height: 30,
        decoration: new BoxDecoration(
            color: data['車輛盤點狀態'] == '1' ? Colors.lime : Colors.white,
            border: new Border.all(color: Colors.grey, width: 0.5)),
        child: Row(
          children: <Widget>[
            Container(
              padding: EdgeInsets.only(left: 2),
              width: 60,
              child: Text(
                data['儲區'] == null ? '' : data['儲區'].toString(),
                style: TextStyle(fontSize: 12),
              ),
            ),
            Container(
              padding: EdgeInsets.only(left: 2),
              width: 70,
              child: Text(
                data['儲格'] == null ? '' : data['儲格'].toString(),
                style: TextStyle(fontSize: 12),
              ),
            ),
            Expanded(
              child: Container(
                child: GestureDetector(
                  onLongPress: () {
                    CarInformation.show(context, data['車身號碼'].toString());
                  },
                  child: Text(
                    data['車身號碼'] == null ? '' : data['車身號碼'].toString(),
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _inputData(String value) async {
    value = value.replaceAll('/', '');
    setState(() {
      _inputController.text = '';
      _vinNo = '';
      _vsab1906 = '';
    });
    if (_vinList == null || _vinList.length == 0) {
      _showMessage(ResultFlag.ng, '請選擇盤點單號');
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
        _vsab1906 = _vinList
            .firstWhere((v) => v['車身號碼'].toString() == value)['備註']
            .toString();
      });
    } else if (startWithCount == 1) {
      setState(() {
        _vinNo = _vinList
            .firstWhere(
                (v) => v['車身號碼'].toString().startsWith(value) == true)['車身號碼']
            .toString();
        _vsab1906 = _vinList
            .firstWhere(
                (v) => v['車身號碼'].toString().startsWith(value) == true)['備註']
            .toString();
      });
    } else if (endWithCount == 1) {
      setState(() {
        _vinNo = _vinList
            .firstWhere(
                (v) => v['車身號碼'].toString().endsWith(value) == true)['車身號碼']
            .toString();
        _vsab1906 = _vinList
            .firstWhere(
                (v) => v['車身號碼'].toString().endsWith(value) == true)['備註']
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
        _vsab1906 = _vinList
            .firstWhere((v) => v['車身號碼'].toString() == value)['備註']
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
        _vsab1906 = _vinList
            .firstWhere((v) => v['車身號碼'].toString() == value)['備註']
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
        _vsab1906 = _vinList
            .firstWhere((v) => v['車身號碼'].toString() == value)['備註']
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
            .firstWhere((v) => v['車身號碼'].toString() == _vinNo)['車輛盤點狀態']
            .toString() ==
        '1') {
      _showMessage(ResultFlag.ng, '車身號碼:' + _vinNo + ' 已完成盤點');
      return;
    }

    String pickdate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String pickuser = Business.userId;
    String vsab1900 = _formData['vsab1900'];
    int vsab1901 =
        _vinList.firstWhere((v) => v['車身號碼'].toString() == _vinNo)['盤點項次'];

    if (_onlineMode == true)
    //====Online
    {
      Datagram datagram = Datagram();
      datagram.addText("""update xvms_ab19 set status = status,
                                               vsab1903 = '1',
                                               vsab1904 = '$pickdate',
                                               vsab1905 = '$pickuser'
                          where vsab1900 = '$vsab1900' and
                                vsab1901 = $vsab1901 and
                                vsab1903 = '0'
        """, rowIndex: 0, rowSize: 100);
      ResponseResult result = await Business.apiExecuteDatagram(datagram);
      if (result.flag == ResultFlag.ok) {
        _vinList.firstWhere((v) => v['車身號碼'].toString() == _vinNo)['車輛盤點狀態'] =
            '1';
        _showMessage(ResultFlag.ok, '盤點完成');
        if (_invTotalCount > _invPickCount) _invPickCount++;
      } else {
        _showMessage(ResultFlag.ng, result.getNGMessage());
      }
    }
    //Offline
    else {
      _vinList.firstWhere((v) => v['車身號碼'].toString() == _vinNo)['車輛盤點狀態'] =
          '1';
      SharedPreferences prefs = await SharedPreferences.getInstance();

      if (prefs.containsKey('TVS0100003') == true)
        _offlineDataBuffer = prefs.getStringList('TVS0100003');
      setState(() {
        _offlineDataBuffer.add(vsab1900 +
            '|' +
            vsab1901.toString() +
            '|' +
            pickdate +
            '|' +
            pickuser);
      });
      prefs.setStringList('TVS0100003', _offlineDataBuffer);
      _showMessage(ResultFlag.ok, '盤點完成(離線)');
      if (_invTotalCount > _invPickCount) _invPickCount++;
    }
  }

  void _loadDataList(String seqnumber) async {
    setState(() {
      _isLoading = true;
    });

    final ResponseResult result = await _loadData(seqnumber);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      if (data.length == 0) {
        setState(() {
          _isLoading = false;
          _vinList = null;
          _invTotalCount = 0;
          _invPickCount = 0;
        });
      } else {
        setState(() {
          _isLoading = false;
          _vinList = data;
          _invTotalCount = data.length;
          _invPickCount = data.where((v) => v['車輛盤點狀態'] == '1').toList().length;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });

      MessageBox.showInformation(context, "", result.getNGMessage());
    }
  }

  void _showMessage(ResultFlag flag, String message) {
    setState(() {
      _messageFlag = flag;
      _message = message;
    });
    CommonMethod.playSound(flag);
  }

  void _loadSeqNumber() async {
    List<DropdownMenuItem> items = new List();
    Datagram datagram = Datagram();
    datagram.addText("""select t1.vsaa1900 as 盤點單號,
                               t1.vsaa1901 as 盤點日期
                        from (
                            select distinct vsaa1900,vsaa1901
                            from xvms_aa19 as t1
                            left join xvms_ab19 as t2 on t1.vsaa1900 = t2.vsab1900
                            where t1.status = 'Y' and
                                  t2.vsab1903 = '0'
                        ) as t1
                        """, rowIndex: 0, rowSize: 65535);
    final ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      for (int i = 0; i < data.length; i++) {
        items.add(DropdownMenuItem(
            value: data[i]['盤點單號'].toString(),
            child: Text(data[i]['盤點單號'].toString() +
                ' ' +
                data[i]['盤點日期'].toString())));
      }
      _seqnumberItems = items;
      setState(() {});
    } else {
      MessageBox.showInformation(context, "", result.getNGMessage());
    }
  }

  void _hardwareInputCallback(String value) {
    if (_inputMode == 1) {
      _inputController.text = CommonMethod.barcodeCheck(_barcodeFixMode, value);
    }
  }

  Future<ResponseResult> _loadData(String seqnumber) {
    Datagram datagram = Datagram();
    datagram.addText("""select vsab1900 as 盤點單號,
                               vsab1901 as 盤點項次,
                               vsab1902 as 車身號碼,
                               vsab1903 as 車輛盤點狀態,
                               vsab1906 as 備註,
                               t2.vsaa0119 as 點交次數,
                               t2.vsaa0115 as 儲區,
                               t2.vsaa0116 as 儲格
                        from xvms_ab19 as t1
                        left join (select vsaa0100,
                                          max(vsaa0119) as vsaa0119,
                                          vsaa0115,
                                          vsaa0116
                                   from xvms_aa01
                                   group by vsaa0100,vsaa0115,vsaa0116
                                  ) as t2 on t1.vsab1902 = t2.vsaa0100
                        where vsab1900 = '$seqnumber'
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
  });

  @override
  State<StatefulWidget> createState() {
    return _FunctionMenu();
  }
}

class _FunctionMenu extends State<FunctionMenu> {
  int _inputMode = 1;
  int _barcodeFixMode = 0;
  String _imageCategory = 'TVS0100003';
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
                  String vsaa1900 = s.split('|')[0];
                  String vsab1901 = s.split('|')[1];
                  String pickdate = s.split('|')[2];
                  String pickuser = s.split('|')[3];

                  datagram.addText("""update xvms_ab19 set status = status,
                                                             vsab1903 = '1',
                                                             vsab1904 = '$pickdate',
                                                             vsab1905 = '$pickuser'
                                        where vsab1900 = '$vsaa1900' and
                                              vsab1901 = $vsab1901 and
                                              vsab1903 = '0'
                                     """, rowIndex: 0, rowSize: 100);
                });
                ResponseResult result =
                    await Business.apiExecuteDatagram(datagram);
                if (result.flag == ResultFlag.ok) {
                  _offlineDataBuffer.clear();
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  if (prefs.containsKey(widget.moduleId) == true)
                    prefs.remove(widget.moduleId);
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
            //buildGalleryWithSeqNo(context, Colors.white, _imageCategory),
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
            Divider(height: 2.0, color: Colors.black),
          ],
        ),
      ),
    );
  }
}
