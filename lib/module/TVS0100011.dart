import 'dart:io';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:car_1/module/GeneralFunction.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:xml/xml.dart';
import 'package:xml/xml.dart' as xml;
import '../model/sysMenu.dart';
import 'package:car_1/business/datagram.dart';
import 'package:car_1/business/responseresult.dart';
import 'package:car_1/apis/messagebox.dart';
import 'package:car_1/business/business.dart';
import 'GeneralWidget.dart';
import 'GeneralFunction.dart';

class TVS0100011 extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _TVS0100011();
  }
}

class _TVS0100011 extends State<TVS0100011> with TickerProviderStateMixin {
  final String moduleId = 'TVS0100002';
  final String moduleName = '生產刷讀作業';
  String _imageCategory = 'TVS0100002';
  final _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final FocusNode _textFieldFocusNode = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _onlineMode = true; //true: online false: offline
  bool _isLoading = false;
  int _inputMode = 0; //0: keybarod 1: scanner 2:camera
  int _barcodeFixMode = 0; //0:一般 1:去頭 2:F/U
  String _message = '';
  ResultFlag _messageFlag = ResultFlag.ok;
  HardwareKeyboardListener _keyboardListen;
  List<Map<String, dynamic>> _fileList;
  bool _isExistsFile = false;
  //========================================================
  List<String> _offlineDataBuffer = List<String>();
  final Map<String, dynamic> _formData = {
    'checkReport': null, //檢查表
    'okng': null, //okng
    'stationType': null, //站點類別
    'stationCode': null, //生產站點
  };
  ReaderInputType _readerInputType = ReaderInputType.one;
  final format = DateFormat("yyyy-MM-dd");
  List<DropdownMenuItem> _carModelTypeItems;
  List<DropdownMenuItem> _carCheckReportItems;
  List<DropdownMenuItem> _stationTypeItems;
  List<DropdownMenuItem> _stationCodeItems;
  CheckReport _checkReport;
  List<Map<String, dynamic>> _vinList;
  List<Map<String, dynamic>> _controlList;
  String _planDate = ''; //生產日期
  String _vinNo = ''; //車身號碼
  String _vinIndex = ''; //點交次數
  String _spacing = ''; //車身級別
  String _carModeType = ''; //廠牌
  List<Map<String, dynamic>> _xvms_0004;

  @override
  void initState() {
    // _keyboardListen = new HardwareKeyboardListener(_hardwareInputCallback);
    super.initState();
    _loadStationType();
    _loadCheckReport('HONDA');
    // _loadListHONDA_0001();
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
      //===== 標題
      appBar: AppBar(
        title: Text('生產刷讀作業'),
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
                        }),
                    fullscreenDialog: false),
              );
            },
          )
        ],
      ),
      //==== 選單
      drawer: buildMenu(context),
      //==== 內容
      body: Container(
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
                        _buildInputContainer(),
                        _buildStationType(),
                        _buildStationCode(),
                        _buildCheckReport(),
                        buildLabel('車身號碼', _vinNo),
                        Container(
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: buildLabel('點交次數', _vinIndex),
                              ),
                              Expanded(
                                child: buildLabel('車身級別', _spacing),
                              ),
                            ],
                          ),
                        ),
                        buildLabel('廠牌', _carModeType),
                      ],
                    ),
                  ),
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
                // _offlineDataBuffer.forEach((s) {
                //   datagram.addText("""
                //                    """, rowIndex: 0, rowSize: 100);
                // });
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
                  _isExistsFile = false;
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
                  if (_keyCode == '4' || _keyCode == '66') return;
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

  Widget _buildStationType() {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Container(
              padding:
                  EdgeInsets.only(left: 20.0, right: 20, top: 10, bottom: 10),
              child: DropdownButtonFormField(
                decoration: InputDecoration(
                    labelText: '站點類別',
                    filled: false,
                    contentPadding: EdgeInsets.only(top: 0, bottom: 0)),
                items: _stationTypeItems == null ? [] : _stationTypeItems,
                value: _formData['stationType'],
                onChanged: (value) {
                  _loadStationCode(value);
                  setState(() {
                    _formData['stationType'] = value;
                    _formData['stationCode'] = null;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStationCode() {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Container(
              padding:
                  EdgeInsets.only(left: 20.0, right: 20, top: 10, bottom: 10),
              child: DropdownButtonFormField(
                decoration: InputDecoration(
                    labelText: '生產站點',
                    filled: false,
                    contentPadding: EdgeInsets.only(top: 0, bottom: 0)),
                items: _stationCodeItems == null ? [] : _stationCodeItems,
                value: _formData['stationCode'],
                onChanged: (value) {
                  setState(() {
                    _formData['stationCode'] = value;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckReport() {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Container(
              padding:
                  EdgeInsets.only(left: 20.0, right: 20, top: 10, bottom: 10),
              child: DropdownButtonFormField(
                decoration: InputDecoration(
                    labelText: '檢查表',
                    filled: false,
                    contentPadding: EdgeInsets.only(top: 0, bottom: 0)),
                items: _carCheckReportItems == null ? [] : _carCheckReportItems,
                value: _formData['checkReport'],
                onChanged: (value) async {
                  if (value != null) {
                    await _loadCheckReportData(
                        _vinNo,
                        _vinIndex,
                        value.toString().split('|')[0],
                        value.toString().split('|')[1]);
                  }
                  if (value == 'HONDA_PDI檢查表|0001') {
                    _loadListHONDA_0001();
                  } else
                    _checkReport = null;
                  setState(() {
                    _formData['checkReport'] = value;
                  });
                },
              ),
            ),
          ),
          Container(
            height: 30,
            width: 60,
            padding: EdgeInsets.only(right: 10),
            child: RaisedButton(
              padding: EdgeInsets.all(1),
              color: Colors.black,
              child: Text('儲存',
                  style: TextStyle(fontSize: 20.0, color: Colors.white)),
              onPressed: () {
                // _loadCheckReportData('', '', '', '');
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
                Expanded(
                  child: Container(
                      padding: EdgeInsets.only(left: 0),
                      width: 90,
                      child: Text('檢查項目'),
                      color: Colors.black12),
                ),
              ],
            )),
        Expanded(
          child: _buildCheckItemList(_checkReport),
        ),
      ]),
    );
  }

  Widget _buildCheckItemList(CheckReport checkReport) {
    if (checkReport == null)
      return Container();
    else {
      return Container(
        width: Business.deviceWidth(context) - 40,
        child: ListView.builder(
            itemCount: checkReport == null ? 0 : checkReport.columnItems.length,
            itemBuilder: (BuildContext context, int index) {
              if (checkReport.reportName == 'HONDA_PDI檢查表|0001')
                return _buildHONDA_0001(
                    context, checkReport.columnItems[index]);
              else
                return Container();
            }),
      );
    }
  }

  Widget _buildHONDA_0001(BuildContext context, ColumnItem data) {
    switch (data.typeName) {
      case '內外觀':
      case '引擎室':
      case '駕駛室':
      case '完檢':
        return Card(
          child: Container(
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    _buildLabel('檢查項目', data.rowItem[0].controlName),
                  ],
                ),
                Row(
                  children: <Widget>[
                    _buildLabel('檢查方式', data.rowItem[1].controlName),
                  ],
                ),
                Row(
                  children: <Widget>[
                    _buildLabel('檢查基準', data.rowItem[2].controlName),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _buildRaisedButton('結果1', data.rowItem[3]),
                    ),
                    Expanded(
                      child: _buildRaisedButton('結果2', data.rowItem[4]),
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _buildTextField('不良1', data.rowItem[5]),
                    ),
                    SizedBox(
                      width: 10.0,
                    ),
                    Expanded(
                      child: _buildTextField('不良2', data.rowItem[6]),
                    ),
                  ],
                ),
                SizedBox(
                  height: 3.0,
                ),
              ],
            ),
          ),
        );
        break;
      case 'IMA':
        return Card(
          child: Container(
            child: Column(
              children: <Widget>[
                //==== IMA系統電瓶效能檢查紀錄表
                Row(
                  children: <Widget>[
                    _buildLabel('累計天日', data.rowItem[0].controlName),
                    Expanded(
                      child: _buildDateTimeField('檢查日期', data.rowItem[1]),
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _buildTextField('檢查結果', data.rowItem[2]),
                    ),
                    SizedBox(
                      width: 10.0,
                    ),
                    Expanded(
                      child: _buildTextField('充電前', data.rowItem[3]),
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _buildTextField('充電前', data.rowItem[4]),
                    ),
                    SizedBox(
                      width: 10.0,
                    ),
                    Expanded(
                      child: _buildTextField('充電結果', data.rowItem[5]),
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _buildTextField('確認者', data.rowItem[6]),
                    ),
                    SizedBox(
                      width: 10.0,
                    ),
                    Expanded(
                      child: _buildTextField('備註', data.rowItem[7]),
                    ),
                  ],
                ),
                SizedBox(
                  height: 3.0,
                ),
              ],
            ),
          ),
        );
        break;
      default:
        return Container();
    }
  }

  void _loadListHONDA_0001() {
    setState(() {
      _isLoading = true;
    });

    CheckReport checkReport = CheckReport();
    checkReport.reportName = 'HONDA_PDI檢查表|0001';
    checkReport.columnItems = [
      ColumnItem('內外觀', [
        RowItem('檢查項目', '1. 車身及外表烤漆是否瑕疪或損傷', ValueType.label),
        RowItem('檢查方式', '目視', ValueType.label),
        RowItem('檢查基準', '1.在有燈光照明下檢查。2.小美容，包含細刮痕處理', ValueType.label),
        RowItem('結果1', 'comboBox1', ValueType.combobox),
        RowItem('結果2', 'comboBox2', ValueType.combobox),
        RowItem('不良1', 'textBox9', ValueType.textbox),
        RowItem('不良2', 'textBox10', ValueType.textbox),
      ]),
      ColumnItem('內外觀', [
        RowItem('檢查項目', '2. 內裝及座(皮)椅', ValueType.label),
        RowItem('檢查方式', '目視', ValueType.label),
        RowItem('檢查基準', '外觀檢查', ValueType.label),
        RowItem('結果1', 'comboBox4', ValueType.combobox),
        RowItem('結果2', 'comboBox3', ValueType.combobox),
        RowItem('不良1', 'textBox12', ValueType.textbox),
        RowItem('不良2', 'textBox11', ValueType.textbox),
      ]),
      ColumnItem('內外觀', [
        RowItem('檢查項目', '3. 儀表板、門飾板、A.B.C柱飾板', ValueType.label),
        RowItem('檢查方式', '目視', ValueType.label),
        RowItem('檢查基準', '外觀檢查', ValueType.label),
        RowItem('結果1', 'comboBox6', ValueType.combobox),
        RowItem('結果2', 'comboBox5', ValueType.combobox),
        RowItem('不良1', 'textBox14', ValueType.textbox),
        RowItem('不良2', 'textBox13', ValueType.textbox),
      ]),
      ColumnItem('內外觀', [
        RowItem('檢查項目', '4. 檢查IMA系統進汽口', ValueType.label),
        RowItem('檢查方式', '確認', ValueType.label),
        RowItem('檢查基準', '確認進氣口無阻礙(位於後椅左側)', ValueType.label),
        RowItem('結果1', 'comboBox12', ValueType.combobox),
        RowItem('結果2', 'comboBox11', ValueType.combobox),
        RowItem('不良1', 'textBox16', ValueType.textbox),
        RowItem('不良2', 'textBox15', ValueType.textbox),
      ]),
      ColumnItem('內外觀', [
        RowItem('檢查項目', '5. 全車鍍鉻飾件', ValueType.label),
        RowItem('檢查方式', '目視', ValueType.label),
        RowItem('檢查基準', '外觀檢查', ValueType.label),
        RowItem('結果1', 'comboBox10', ValueType.combobox),
        RowItem('結果2', 'comboBox9', ValueType.combobox),
        RowItem('不良1', 'textBox18', ValueType.textbox),
        RowItem('不良2', 'textBox17', ValueType.textbox),
      ]),
      ColumnItem('引擎室', [
        RowItem('檢查項目', '6. 引擎蓋鉸鏈與鎖扣', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '外觀檢查及操作', ValueType.label),
        RowItem('結果1', 'comboBox8', ValueType.combobox),
        RowItem('結果2', 'comboBox7', ValueType.combobox),
        RowItem('不良1', 'textBox20', ValueType.textbox),
        RowItem('不良2', 'textBox19', ValueType.textbox),
      ]),
      ColumnItem('引擎室', [
        RowItem('檢查項目', '7. 電瓶樁頭(塗上黃油)', ValueType.label),
        RowItem('檢查方式', '潤滑', ValueType.label),
        RowItem('檢查基準', '外觀檢查', ValueType.label),
        RowItem('結果1', 'comboBox18', ValueType.combobox),
        RowItem('結果2', 'comboBox17', ValueType.combobox),
        RowItem('不良1', 'textBox30', ValueType.textbox),
        RowItem('不良2', 'textBox29', ValueType.textbox),
      ]),
      ColumnItem('引擎室', [
        RowItem('檢查項目', '8. 電瓶及電壓狀況', ValueType.label),
        RowItem('檢查方式', '測量', ValueType.label),
        RowItem('檢查基準', '外觀檢查及電壓量測', ValueType.label),
        RowItem('結果1', 'comboBox16', ValueType.combobox),
        RowItem('結果2', 'comboBox15', ValueType.combobox),
        RowItem('不良1', 'textBox28', ValueType.textbox),
        RowItem('不良2', 'textBox27', ValueType.textbox),
      ]),
      ColumnItem('引擎室', [
        RowItem('檢查項目', '9. 主接地線', ValueType.label),
        RowItem('檢查方式', '目視', ValueType.label),
        RowItem('檢查基準', '外觀檢查', ValueType.label),
        RowItem('結果1', 'comboBox14', ValueType.combobox),
        RowItem('結果2', 'comboBox13', ValueType.combobox),
        RowItem('不良1', 'textBox26', ValueType.textbox),
        RowItem('不良2', 'textBox25', ValueType.textbox),
      ]),
      ColumnItem('引擎室', [
        RowItem('檢查項目', '10. 保險絲/繼電器狀況', ValueType.label),
        RowItem('檢查方式', '目視', ValueType.label),
        RowItem('檢查基準', '外觀檢查', ValueType.label),
        RowItem('結果1', 'comboBox24', ValueType.combobox),
        RowItem('結果2', 'comboBox23', ValueType.combobox),
        RowItem('不良1', 'textBox24', ValueType.textbox),
        RowItem('不良2', 'textBox23', ValueType.textbox),
      ]),
      ColumnItem('引擎室', [
        RowItem('檢查項目', '11. 煞車油液面高度', ValueType.label),
        RowItem('檢查方式', '檢查', ValueType.label),
        RowItem('檢查基準', '液面MAX-MIN標準高度', ValueType.label),
        RowItem('結果1', 'comboBox22', ValueType.combobox),
        RowItem('結果2', 'comboBox21', ValueType.combobox),
        RowItem('不良1', 'textBox22', ValueType.textbox),
        RowItem('不良2', 'textBox21', ValueType.textbox),
      ]),
      ColumnItem('引擎室', [
        RowItem('檢查項目', '12. 引擎機油液面高度', ValueType.label),
        RowItem('檢查方式', '檢查', ValueType.label),
        RowItem('檢查基準', '液面MAX-MIN標準高度', ValueType.label),
        RowItem('結果1', 'comboBox20', ValueType.combobox),
        RowItem('結果2', 'comboBox19', ValueType.combobox),
        RowItem('不良1', 'textBox40', ValueType.textbox),
        RowItem('不良2', 'textBox39', ValueType.textbox),
      ]),
      ColumnItem('引擎室', [
        RowItem('檢查項目', '13. 冷卻水液面高度及防凍劑', ValueType.label),
        RowItem('檢查方式', '檢查', ValueType.label),
        RowItem('檢查基準', '液面MAX-MIN標準高度', ValueType.label),
        RowItem('結果1', 'comboBox34', ValueType.combobox),
        RowItem('結果2', 'comboBox33', ValueType.combobox),
        RowItem('不良1', 'textBox38', ValueType.textbox),
        RowItem('不良2', 'textBox37', ValueType.textbox),
      ]),
      ColumnItem('引擎室', [
        RowItem('檢查項目', '14. 動力方向盤油壺液面高度', ValueType.label),
        RowItem('檢查方式', '檢查', ValueType.label),
        RowItem('檢查基準', '液面MAX-MIN標準高度', ValueType.label),
        RowItem('結果1', 'comboBox32', ValueType.combobox),
        RowItem('結果2', 'comboBox31', ValueType.combobox),
        RowItem('不良1', 'textBox36', ValueType.textbox),
        RowItem('不良2', 'textBox35', ValueType.textbox),
      ]),
      ColumnItem('引擎室', [
        RowItem('檢查項目', '15. 自動變速箱油液面高度', ValueType.label),
        RowItem('檢查方式', '檢查', ValueType.label),
        RowItem('檢查基準', '液面MAX-MIN標準高度', ValueType.label),
        RowItem('結果1', 'comboBox30', ValueType.combobox),
        RowItem('結果2', 'comboBox29', ValueType.combobox),
        RowItem('不良1', 'textBox34', ValueType.textbox),
        RowItem('不良2', 'textBox33', ValueType.textbox),
      ]),
      ColumnItem('引擎室', [
        RowItem('檢查項目', '16. 擋風玻璃及頭燈清潔液面高度', ValueType.label),
        RowItem('檢查方式', '檢查', ValueType.label),
        RowItem('檢查基準', '液面MAX-MIN標準高度', ValueType.label),
        RowItem('結果1', 'comboBox28', ValueType.combobox),
        RowItem('結果2', 'comboBox27', ValueType.combobox),
        RowItem('不良1', 'textBox32', ValueType.textbox),
        RowItem('不良2', 'textBox31', ValueType.textbox),
      ]),
      ColumnItem('引擎室', [
        RowItem('檢查項目', '17. 所有驅動皮帶', ValueType.label),
        RowItem('檢查方式', '檢查', ValueType.label),
        RowItem('檢查基準', '手壓皮帶確認有無破損、龜裂', ValueType.label),
        RowItem('結果1', 'comboBox26', ValueType.combobox),
        RowItem('結果2', 'comboBox25', ValueType.combobox),
        RowItem('不良1', 'textBox50', ValueType.textbox),
        RowItem('不良2', 'textBox49', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '18. 駐車手煞車', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '操作是否正常', ValueType.label),
        RowItem('結果1', 'comboBox44', ValueType.combobox),
        RowItem('結果2', 'comboBox43', ValueType.combobox),
        RowItem('不良1', 'textBox48', ValueType.textbox),
        RowItem('不良2', 'textBox47', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '19. 煞車踏板高度及自由行程', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '操作是否正常', ValueType.label),
        RowItem('結果1', 'comboBox42', ValueType.combobox),
        RowItem('結果2', 'comboBox41', ValueType.combobox),
        RowItem('不良1', 'textBox46', ValueType.textbox),
        RowItem('不良2', 'textBox45', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '20. 油門踏板', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '操作是否正常', ValueType.label),
        RowItem('結果1', 'comboBox40', ValueType.combobox),
        RowItem('結果2', 'comboBox39', ValueType.combobox),
        RowItem('不良1', 'textBox44', ValueType.textbox),
        RowItem('不良2', 'textBox43', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '21. 設定收音機頻道 (唯一 96.3 頻道)', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '操作及設定', ValueType.label),
        RowItem('結果1', 'comboBox38', ValueType.combobox),
        RowItem('結果2', 'comboBox37', ValueType.combobox),
        RowItem('不良1', 'textBox42', ValueType.textbox),
        RowItem('不良2', 'textBox41', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '22. 收音機/CD/DVD功能', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '操作及功能測試', ValueType.label),
        RowItem('結果1', 'comboBox36', ValueType.combobox),
        RowItem('結果2', 'comboBox35', ValueType.combobox),
        RowItem('不良1', 'textBox60', ValueType.textbox),
        RowItem('不良2', 'textBox59', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '23. GMT時間設定', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', 'GMT時間設定完成', ValueType.label),
        RowItem('結果1', 'comboBox54', ValueType.combobox),
        RowItem('結果2', 'comboBox53', ValueType.combobox),
        RowItem('不良1', 'textBox58', ValueType.textbox),
        RowItem('不良2', 'textBox57', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '24. 所有儀錶板警示燈', ValueType.label),
        RowItem('檢查方式', '目視', ValueType.label),
        RowItem('檢查基準', 'KEY ON儀錶板警示燈需亮起', ValueType.label),
        RowItem('結果1', 'comboBox52', ValueType.combobox),
        RowItem('結果2', 'comboBox51', ValueType.combobox),
        RowItem('不良1', 'textBox56', ValueType.textbox),
        RowItem('不良2', 'textBox55', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '25. ASL防止啟動裝置', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', 'KEY ON 踩煞車排檔桿可排出；不踩煞車不可排出', ValueType.label),
        RowItem('結果1', 'comboBox58', ValueType.combobox),
        RowItem('結果2', 'comboBox57', ValueType.combobox),
        RowItem('不良1', 'textBox54', ValueType.textbox),
        RowItem('不良2', 'textBox53', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '26. 啟動操作(各儀錶警示燈需熄滅)', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '啟動後各儀錶警示燈需熄滅', ValueType.label),
        RowItem('結果1', 'comboBox56', ValueType.combobox),
        RowItem('結果2', 'comboBox55', ValueType.combobox),
        RowItem('不良1', 'textBox52', ValueType.textbox),
        RowItem('不良2', 'textBox51', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '27. 執行怠速學習程', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '維持轉速在3,000 rpm無負荷狀態，直到水箱風扇運轉。', ValueType.label),
        RowItem('結果1', 'comboBox50', ValueType.combobox),
        RowItem('結果2', 'comboBox49', ValueType.combobox),
        RowItem('不良1', 'textBox70', ValueType.textbox),
        RowItem('不良2', 'textBox69', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '28. 怠速及快怠速檢查', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '怠速數秒後需回覆基本怠速', ValueType.label),
        RowItem('結果1', 'comboBox48', ValueType.combobox),
        RowItem('結果2', 'comboBox47', ValueType.combobox),
        RowItem('不良1', 'textBox68', ValueType.textbox),
        RowItem('不良2', 'textBox67', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '29. 檢查IMA系統電瓶效能與紀錄', ValueType.label),
        RowItem('檢查方式', '檢查', ValueType.label),
        RowItem('檢查基準', '紀錄IMA系統充電前後效能', ValueType.label),
        RowItem('結果1', 'comboBox46', ValueType.combobox),
        RowItem('結果2', 'comboBox45', ValueType.combobox),
        RowItem('不良1', 'textBox66', ValueType.textbox),
        RowItem('不良2', 'textBox65', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '30. 檢查自動怠速熄火', ValueType.label),
        RowItem('檢查方式', '檢查', ValueType.label),
        RowItem('檢查基準', 'IMA系統顯示充電超過50%, 踩住煞車踏板,引擎必須熄火', ValueType.label),
        RowItem('結果1', 'comboBox68', ValueType.combobox),
        RowItem('結果2', 'comboBox67', ValueType.combobox),
        RowItem('不良1', 'textBox64', ValueType.textbox),
        RowItem('不良2', 'textBox63', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '31. 雨刷各段作動功能', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '間歇、低速、高速功能', ValueType.label),
        RowItem('結果1', 'comboBox66', ValueType.combobox),
        RowItem('結果2', 'comboBox65', ValueType.combobox),
        RowItem('不良1', 'textBox62', ValueType.textbox),
        RowItem('不良2', 'textBox61', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '32. 雨刷清洗器及噴灑模式', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '噴水及噴灑模式', ValueType.label),
        RowItem('結果1', 'comboBox64', ValueType.combobox),
        RowItem('結果2', 'comboBox63', ValueType.combobox),
        RowItem('不良1', 'textBox80', ValueType.textbox),
        RowItem('不良2', 'textBox79', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '33. 方向燈及回覆裝置', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '方向燈需亮起及回覆功能', ValueType.label),
        RowItem('結果1', 'comboBox62', ValueType.combobox),
        RowItem('結果2', 'comboBox61', ValueType.combobox),
        RowItem('不良1', 'textBox78', ValueType.textbox),
        RowItem('不良2', 'textBox77', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '34. 雨滴感知作動功能', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '噴水至前檔雨刷需作動', ValueType.label),
        RowItem('結果1', 'comboBox60', ValueType.combobox),
        RowItem('結果2', 'comboBox59', ValueType.combobox),
        RowItem('不良1', 'textBox76', ValueType.textbox),
        RowItem('不良2', 'textBox75', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '35. 危險警告燈', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '燈光需亮起', ValueType.label),
        RowItem('結果1', 'comboBox78', ValueType.combobox),
        RowItem('結果2', 'comboBox77', ValueType.combobox),
        RowItem('不良1', 'textBox74', ValueType.textbox),
        RowItem('不良2', 'textBox73', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '36. 小燈及牌照燈', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '燈光需亮起', ValueType.label),
        RowItem('結果1', 'comboBox76', ValueType.combobox),
        RowItem('結果2', 'comboBox75', ValueType.combobox),
        RowItem('不良1', 'textBox72', ValueType.textbox),
        RowItem('不良2', 'textBox71', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '37. 自動頭燈功能及近/遠切換模式', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', 'AUTO功能', ValueType.label),
        RowItem('結果1', 'comboBox74', ValueType.combobox),
        RowItem('結果2', 'comboBox73', ValueType.combobox),
        RowItem('不良1', 'textBox90', ValueType.textbox),
        RowItem('不良2', 'textBox89', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '38. 煞車燈及倒車燈', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '踩煞車，煞車燈需亮起，R檔倒車燈需亮起', ValueType.label),
        RowItem('結果1', 'comboBox72', ValueType.combobox),
        RowItem('結果2', 'comboBox71', ValueType.combobox),
        RowItem('不良1', 'textBox88', ValueType.textbox),
        RowItem('不良2', 'textBox87', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '39. 前霧燈及後霧燈', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '燈光需亮起', ValueType.label),
        RowItem('結果1', 'comboBox70', ValueType.combobox),
        RowItem('結果2', 'comboBox69', ValueType.combobox),
        RowItem('不良1', 'textBox86', ValueType.textbox),
        RowItem('不良2', 'textBox85', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '40. 儀表亮度調整', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '調整後儀表亮度是否變化', ValueType.label),
        RowItem('結果1', 'comboBox88', ValueType.combobox),
        RowItem('結果2', 'comboBox87', ValueType.combobox),
        RowItem('不良1', 'textBox84', ValueType.textbox),
        RowItem('不良2', 'textBox83', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '41. VSA OFF功能', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '按下VSA OFF,指示燈需亮起', ValueType.label),
        RowItem('結果1', 'comboBox86', ValueType.combobox),
        RowItem('結果2', 'comboBox85', ValueType.combobox),
        RowItem('不良1', 'textBox82', ValueType.textbox),
        RowItem('不良2', 'textBox81', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '42. 煙灰缸及手套箱燈光', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '燈光需亮起', ValueType.label),
        RowItem('結果1', 'comboBox84', ValueType.combobox),
        RowItem('結果2', 'comboBox83', ValueType.combobox),
        RowItem('不良1', 'textBox100', ValueType.textbox),
        RowItem('不良2', 'textBox99', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '43. 喇叭', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '喇叭需鳴叫', ValueType.label),
        RowItem('結果1', 'comboBox82', ValueType.combobox),
        RowItem('結果2', 'comboBox81', ValueType.combobox),
        RowItem('不良1', 'textBox98', ValueType.textbox),
        RowItem('不良2', 'textBox97', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '44. 點煙器及配件電源', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '功能正常，電源正常', ValueType.label),
        RowItem('結果1', 'comboBox80', ValueType.combobox),
        RowItem('結果2', 'comboBox79', ValueType.combobox),
        RowItem('不良1', 'textBox96', ValueType.textbox),
        RowItem('不良2', 'textBox95', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '45. 前後空調系統操作及各段風速及功能', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '前後空調系統操作及各段風速及功能正常', ValueType.label),
        RowItem('結果1', 'comboBox98', ValueType.combobox),
        RowItem('結果2', 'comboBox97', ValueType.combobox),
        RowItem('不良1', 'textBox94', ValueType.textbox),
        RowItem('不良2', 'textBox93', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '46. 電動窗主開關、副開關及中控鎖', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '操作正常', ValueType.label),
        RowItem('結果1', 'comboBox96', ValueType.combobox),
        RowItem('結果2', 'comboBox95', ValueType.combobox),
        RowItem('不良1', 'textBox92', ValueType.textbox),
        RowItem('不良2', 'textBox91', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '47. 四門電動防夾功能', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '功能正常', ValueType.label),
        RowItem('結果1', 'comboBox94', ValueType.combobox),
        RowItem('結果2', 'comboBox93', ValueType.combobox),
        RowItem('不良1', 'textBox110', ValueType.textbox),
        RowItem('不良2', 'textBox109', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '48. 後視鏡收納功能', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '功能正常', ValueType.label),
        RowItem('結果1', 'comboBox92', ValueType.combobox),
        RowItem('結果2', 'comboBox91', ValueType.combobox),
        RowItem('不良1', 'textBox108', ValueType.textbox),
        RowItem('不良2', 'textBox107', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '49. 倒車雷達功能', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '功能正常', ValueType.label),
        RowItem('結果1', 'comboBox90', ValueType.combobox),
        RowItem('結果2', 'comboBox89', ValueType.combobox),
        RowItem('不良1', 'textBox106', ValueType.textbox),
        RowItem('不良2', 'textBox105', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '50. 方向盤音響/定速/快撥鍵功能', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '功能及操作正常', ValueType.label),
        RowItem('結果1', 'comboBox108', ValueType.combobox),
        RowItem('結果2', 'comboBox107', ValueType.combobox),
        RowItem('不良1', 'textBox104', ValueType.textbox),
        RowItem('不良2', 'textBox103', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '51. 儀錶板警示燈需熄滅', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', 'KEY OFF儀錶板警示燈需熄滅', ValueType.label),
        RowItem('結果1', 'comboBox106', ValueType.combobox),
        RowItem('結果2', 'comboBox105', ValueType.combobox),
        RowItem('不良1', 'textBox102', ValueType.textbox),
        RowItem('不良2', 'textBox101', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '52. 方向盤機柱鎖功能', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '功能及操作正常', ValueType.label),
        RowItem('結果1', 'comboBox104', ValueType.combobox),
        RowItem('結果2', 'comboBox103', ValueType.combobox),
        RowItem('不良1', 'textBox120', ValueType.textbox),
        RowItem('不良2', 'textBox119', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '53. 遮陽板/化妝鏡/燈', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '功能及操作正常', ValueType.label),
        RowItem('結果1', 'comboBox102', ValueType.combobox),
        RowItem('結果2', 'comboBox101', ValueType.combobox),
        RowItem('不良1', 'textBox118', ValueType.textbox),
        RowItem('不良2', 'textBox117', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '54. 室內防眩後視鏡', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '功能及操作正常', ValueType.label),
        RowItem('結果1', 'comboBox100', ValueType.combobox),
        RowItem('結果2', 'comboBox99', ValueType.combobox),
        RowItem('不良1', 'textBox116', ValueType.textbox),
        RowItem('不良2', 'textBox115', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '55. 中控鎖', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '功能及操作正常', ValueType.label),
        RowItem('結果1', 'comboBox118', ValueType.combobox),
        RowItem('結果2', 'comboBox117', ValueType.combobox),
        RowItem('不良1', 'textBox114', ValueType.textbox),
        RowItem('不良2', 'textBox113', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '56. 前座室內燈(三段位置)', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '功能及操作正常', ValueType.label),
        RowItem('結果1', 'comboBox116', ValueType.combobox),
        RowItem('結果2', 'comboBox115', ValueType.combobox),
        RowItem('不良1', 'textBox112', ValueType.textbox),
        RowItem('不良2', 'textBox111', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '57. 前/後安全帶功能', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '功能及操作正常', ValueType.label),
        RowItem('結果1', 'comboBox114', ValueType.combobox),
        RowItem('結果2', 'comboBox113', ValueType.combobox),
        RowItem('不良1', 'textBox130', ValueType.textbox),
        RowItem('不良2', 'textBox129', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '58. 扶手/置杯架/置物盒', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '功能及操作正常', ValueType.label),
        RowItem('結果1', 'comboBox112', ValueType.combobox),
        RowItem('結果2', 'comboBox111', ValueType.combobox),
        RowItem('不良1', 'textBox128', ValueType.textbox),
        RowItem('不良2', 'textBox127', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '59. 手套箱', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '功能及操作正常', ValueType.label),
        RowItem('結果1', 'comboBox110', ValueType.combobox),
        RowItem('結果2', 'comboBox109', ValueType.combobox),
        RowItem('不良1', 'textBox126', ValueType.textbox),
        RowItem('不良2', 'textBox125', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '60. 後行李箱安全釋放開關', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '功能及操作正常', ValueType.label),
        RowItem('結果1', 'comboBox128', ValueType.combobox),
        RowItem('結果2', 'comboBox127', ValueType.combobox),
        RowItem('不良1', 'textBox124', ValueType.textbox),
        RowItem('不良2', 'textBox123', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '61. 後行李箱把手開啟功能', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '功能及操作正常', ValueType.label),
        RowItem('結果1', 'comboBox126', ValueType.combobox),
        RowItem('結果2', 'comboBox125', ValueType.combobox),
        RowItem('不良1', 'textBox122', ValueType.textbox),
        RowItem('不良2', 'textBox121', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '62. 後行李箱燈', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '功能及操作正常', ValueType.label),
        RowItem('結果1', 'comboBox124', ValueType.combobox),
        RowItem('結果2', 'comboBox123', ValueType.combobox),
        RowItem('不良1', 'textBox140', ValueType.textbox),
        RowItem('不良2', 'textBox139', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '63. 雨刷位置變更調整', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '功能及操作正常', ValueType.label),
        RowItem('結果1', 'comboBox122', ValueType.combobox),
        RowItem('結果2', 'comboBox121', ValueType.combobox),
        RowItem('不良1', 'textBox138', ValueType.textbox),
        RowItem('不良2', 'textBox137', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '64. 油箱蓋功能及燃油警語標籤', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '功能及操作正常', ValueType.label),
        RowItem('結果1', 'comboBox120', ValueType.combobox),
        RowItem('結果2', 'comboBox119', ValueType.combobox),
        RowItem('不良1', 'textBox136', ValueType.textbox),
        RowItem('不良2', 'textBox135', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '65. 前座頭枕操作', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '功能及操作正常', ValueType.label),
        RowItem('結果1', 'comboBox138', ValueType.combobox),
        RowItem('結果2', 'comboBox137', ValueType.combobox),
        RowItem('不良1', 'textBox134', ValueType.textbox),
        RowItem('不良2', 'textBox133', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '66. 後座頭枕操作', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '功能及操作正常', ValueType.label),
        RowItem('結果1', 'comboBox136', ValueType.combobox),
        RowItem('結果2', 'comboBox135', ValueType.combobox),
        RowItem('不良1', 'textBox132', ValueType.textbox),
        RowItem('不良2', 'textBox131', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '67. 後座扶手操作/置杯架', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '功能及操作正常', ValueType.label),
        RowItem('結果1', 'comboBox134', ValueType.combobox),
        RowItem('結果2', 'comboBox133', ValueType.combobox),
        RowItem('不良1', 'textBox150', ValueType.textbox),
        RowItem('不良2', 'textBox149', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '68. 後座閱讀燈', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '功能及操作正常', ValueType.label),
        RowItem('結果1', 'comboBox132', ValueType.combobox),
        RowItem('結果2', 'comboBox131', ValueType.combobox),
        RowItem('不良1', 'textBox148', ValueType.textbox),
        RowItem('不良2', 'textBox147', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '69. 後行李箱開關開啟操作', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '功能及操作正常', ValueType.label),
        RowItem('結果1', 'comboBox130', ValueType.combobox),
        RowItem('結果2', 'comboBox129', ValueType.combobox),
        RowItem('不良1', 'textBox146', ValueType.textbox),
        RowItem('不良2', 'textBox145', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '70. 兒童安全鎖', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '功能及操作正常', ValueType.label),
        RowItem('結果1', 'comboBox148', ValueType.combobox),
        RowItem('結果2', 'comboBox147', ValueType.combobox),
        RowItem('不良1', 'textBox144', ValueType.textbox),
        RowItem('不良2', 'textBox143', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '71. 潤滑鎖組及鉸鍊', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '功能及操作正常', ValueType.label),
        RowItem('結果1', 'comboBox146', ValueType.combobox),
        RowItem('結果2', 'comboBox145', ValueType.combobox),
        RowItem('不良1', 'textBox142', ValueType.textbox),
        RowItem('不良2', 'textBox141', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '72. 各車門開啟安全指示燈功能', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '功能及操作正常', ValueType.label),
        RowItem('結果1', 'comboBox144', ValueType.combobox),
        RowItem('結果2', 'comboBox143', ValueType.combobox),
        RowItem('不良1', 'textBox160', ValueType.textbox),
        RowItem('不良2', 'textBox159', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '73. 車門間段差及間隙', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '功能及操作正常', ValueType.label),
        RowItem('結果1', 'comboBox142', ValueType.combobox),
        RowItem('結果2', 'comboBox141', ValueType.combobox),
        RowItem('不良1', 'textBox158', ValueType.textbox),
        RowItem('不良2', 'textBox157', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '74. 底盤、引擎、煞車及油管(是否損壞及洩漏)', ValueType.label),
        RowItem('檢查方式', '目視', ValueType.label),
        RowItem('檢查基準', '是否損壞及洩漏', ValueType.label),
        RowItem('結果1', 'comboBox140', ValueType.combobox),
        RowItem('結果2', 'comboBox139', ValueType.combobox),
        RowItem('不良1', 'textBox156', ValueType.textbox),
        RowItem('不良2', 'textBox155', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '75. 懸吊固定螺絲及螺帽', ValueType.label),
        RowItem('檢查方式', '目視', ValueType.label),
        RowItem('檢查基準', '是否損壞及洩漏', ValueType.label),
        RowItem('結果1', 'comboBox158', ValueType.combobox),
        RowItem('結果2', 'comboBox157', ValueType.combobox),
        RowItem('不良1', 'textBox154', ValueType.textbox),
        RowItem('不良2', 'textBox153', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '76. 胎壓標籤', ValueType.label),
        RowItem('檢查方式', '目視', ValueType.label),
        RowItem('檢查基準', '標籤貼附', ValueType.label),
        RowItem('結果1', 'comboBox156', ValueType.combobox),
        RowItem('結果2', 'comboBox155', ValueType.combobox),
        RowItem('不良1', 'textBox152', ValueType.textbox),
        RowItem('不良2', 'textBox151', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '77. 輪(備)胎胎壓', ValueType.label),
        RowItem('檢查方式', '目視', ValueType.label),
        RowItem('檢查基準', '胎壓正常', ValueType.label),
        RowItem('結果1', 'comboBox154', ValueType.combobox),
        RowItem('結果2', 'comboBox153', ValueType.combobox),
        RowItem('不良1', 'textBox170', ValueType.textbox),
        RowItem('不良2', 'textBox169', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '78. 輪胎螺帽扭矩', ValueType.label),
        RowItem('檢查方式', '操作', ValueType.label),
        RowItem('檢查基準', '扭力正常', ValueType.label),
        RowItem('結果1', 'comboBox152', ValueType.combobox),
        RowItem('結果2', 'comboBox151', ValueType.combobox),
        RowItem('不良1', 'textBox168', ValueType.textbox),
        RowItem('不良2', 'textBox167', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '79. 備胎、工具包、千斤頂、拖車勾', ValueType.label),
        RowItem('檢查方式', '目視', ValueType.label),
        RowItem('檢查基準', '部品確認', ValueType.label),
        RowItem('結果1', 'comboBox150', ValueType.combobox),
        RowItem('結果2', 'comboBox149', ValueType.combobox),
        RowItem('不良1', 'textBox166', ValueType.textbox),
        RowItem('不良2', 'textBox165', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '80. 冷卻風扇作動檢查', ValueType.label),
        RowItem('檢查方式', '目視', ValueType.label),
        RowItem('檢查基準', '功能及操作正常', ValueType.label),
        RowItem('結果1', 'comboBox168', ValueType.combobox),
        RowItem('結果2', 'comboBox167', ValueType.combobox),
        RowItem('不良1', 'textBox164', ValueType.textbox),
        RowItem('不良2', 'textBox163', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '81. 檢查怠速、CO、HC', ValueType.label),
        RowItem('檢查方式', '檢查', ValueType.label),
        RowItem('檢查基準', '符合法規值', ValueType.label),
        RowItem('結果1', 'comboBox166', ValueType.combobox),
        RowItem('結果2', 'comboBox165', ValueType.combobox),
        RowItem('不良1', 'textBox162', ValueType.textbox),
        RowItem('不良2', 'textBox161', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '82. 汽油、機油、冷卻液、排氣管是否洩漏', ValueType.label),
        RowItem('檢查方式', '目視', ValueType.label),
        RowItem('檢查基準', '外觀檢查', ValueType.label),
        RowItem('結果1', 'comboBox164', ValueType.combobox),
        RowItem('結果2', 'comboBox163', ValueType.combobox),
        RowItem('不良1', 'textBox180', ValueType.textbox),
        RowItem('不良2', 'textBox179', ValueType.textbox),
      ]),
      ColumnItem('駕駛室', [
        RowItem('檢查項目', '83. 空調冷度/冷媒量檢查', ValueType.label),
        RowItem('檢查方式', '目視', ValueType.label),
        RowItem('檢查基準', '功能及操作正常', ValueType.label),
        RowItem('結果1', 'comboBox162', ValueType.combobox),
        RowItem('結果2', 'comboBox161', ValueType.combobox),
        RowItem('不良1', 'textBox178', ValueType.textbox),
        RowItem('不良2', 'textBox177', ValueType.textbox),
      ]),
      ColumnItem('完檢', [
        RowItem('檢查項目', '84. 清洗車輛外表及內裝清潔', ValueType.label),
        RowItem('檢查方式', '目視', ValueType.label),
        RowItem('檢查基準', '外觀檢查', ValueType.label),
        RowItem('結果1', 'comboBox160', ValueType.combobox),
        RowItem('結果2', 'comboBox159', ValueType.combobox),
        RowItem('不良1', 'textBox176', ValueType.textbox),
        RowItem('不良2', 'textBox175', ValueType.textbox),
      ]),
      ColumnItem('完檢', [
        RowItem('檢查項目', '85. 檢查車內是否漏水', ValueType.label),
        RowItem('檢查方式', '目視', ValueType.label),
        RowItem('檢查基準', '外觀檢查', ValueType.label),
        RowItem('結果1', 'comboBox172', ValueType.combobox),
        RowItem('結果2', 'comboBox171', ValueType.combobox),
        RowItem('不良1', 'textBox174', ValueType.textbox),
        RowItem('不良2', 'textBox173', ValueType.textbox),
      ]),
      ColumnItem('完檢', [
        RowItem('檢查項目', '86. 全車檢查箭頭貼紙已去除', ValueType.label),
        RowItem('檢查方式', '目視', ValueType.label),
        RowItem('檢查基準', '檢查', ValueType.label),
        RowItem('結果1', 'comboBox170', ValueType.combobox),
        RowItem('結果2', 'comboBox169', ValueType.combobox),
        RowItem('不良1', 'textBox172', ValueType.textbox),
        RowItem('不良2', 'textBox171', ValueType.textbox),
      ]),
      ColumnItem('IMA', [
        RowItem('累計天日', '首次', ValueType.label),
        RowItem('檢查日期', 'maskedTextBox1', ValueType.datetime),
        RowItem('檢查結果', 'textBox187', ValueType.textbox),
        RowItem('充電前', 'textBox188', ValueType.textbox),
        RowItem('充電後', 'textBox189', ValueType.textbox),
        RowItem('充電結果', 'textBox190', ValueType.textbox),
        RowItem('確認者', 'textBox191', ValueType.textbox),
        RowItem('備註', 'textBox192', ValueType.textbox),
      ]),
      ColumnItem('IMA', [
        RowItem('累計天日', '90', ValueType.label),
        RowItem('檢查日期', 'maskedTextBox2', ValueType.datetime),
        RowItem('檢查結果', 'textBox198', ValueType.textbox),
        RowItem('充電前', 'textBox197', ValueType.textbox),
        RowItem('充電後', 'textBox196', ValueType.textbox),
        RowItem('充電結果', 'textBox195', ValueType.textbox),
        RowItem('確認者', 'textBox194', ValueType.textbox),
        RowItem('備註', 'textBox193', ValueType.textbox),
      ]),
      ColumnItem('IMA', [
        RowItem('累計天日', '180', ValueType.label),
        RowItem('檢查日期', 'maskedTextBox4', ValueType.datetime),
        RowItem('檢查結果', 'textBox204', ValueType.textbox),
        RowItem('充電前', 'textBox203', ValueType.textbox),
        RowItem('充電後', 'textBox202', ValueType.textbox),
        RowItem('充電結果', 'textBox201', ValueType.textbox),
        RowItem('確認者', 'textBox200', ValueType.textbox),
        RowItem('備註', 'textBox199', ValueType.textbox),
      ]),
      ColumnItem('IMA', [
        RowItem('累計天日', '270', ValueType.label),
        RowItem('檢查日期', 'maskedTextBox3', ValueType.datetime),
        RowItem('檢查結果', 'textBox210', ValueType.textbox),
        RowItem('充電前', 'textBox209', ValueType.textbox),
        RowItem('充電後', 'textBox208', ValueType.textbox),
        RowItem('充電結果', 'textBox207', ValueType.textbox),
        RowItem('確認者', 'textBox206', ValueType.textbox),
        RowItem('備註', 'textBox205', ValueType.textbox),
      ]),
      ColumnItem('IMA', [
        RowItem('累計天日', '360', ValueType.label),
        RowItem('檢查日期', 'maskedTextBox6', ValueType.datetime),
        RowItem('檢查結果', 'textBox216', ValueType.textbox),
        RowItem('充電前', 'textBox215', ValueType.textbox),
        RowItem('充電後', 'textBox214', ValueType.textbox),
        RowItem('充電結果', 'textBox213', ValueType.textbox),
        RowItem('確認者', 'textBox212', ValueType.textbox),
        RowItem('備註', 'textBox211', ValueType.textbox),
      ]),
      ColumnItem('IMA', [
        RowItem('累計天日', '450', ValueType.label),
        RowItem('檢查日期', 'maskedTextBox5', ValueType.datetime),
        RowItem('檢查結果', 'textBox222', ValueType.textbox),
        RowItem('充電前', 'textBox221', ValueType.textbox),
        RowItem('充電後', 'textBox220', ValueType.textbox),
        RowItem('充電結果', 'textBox219', ValueType.textbox),
        RowItem('確認者', 'textBox218', ValueType.textbox),
        RowItem('備註', 'textBox217', ValueType.textbox),
      ]),
    ];

    _mappingControlValue(checkReport);

    setState(() {
      _checkReport = checkReport;
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

  void _mappingControlValue(CheckReport checkReport) {
    List<RowItem> rowItems = checkReport.getAllRowItems();
    for (RowItem item in rowItems) {
      if (_controlList
              .where((v) => v['controlName'].toString() == item.controlName)
              .length ==
          1) {
        //
        item.setControlValue = _controlList
            .firstWhere((v) => v['controlName'].toString() == item.controlName)[
                'controlValue']
            .toString();
      }
    }
  }

  //讀取站點類別
  void _loadStationType() async {
    List<DropdownMenuItem> items = List<DropdownMenuItem>();
    Datagram datagram = Datagram();
    datagram.addText("""select ixa00700,ixa00701 from entirev4.dbo.ifx_a007
                        where ixa00703 = '站點類別' and ixa00700 not in ('S','B')
    """, rowIndex: 0, rowSize: 100);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      for (Map<String, dynamic> item in data) {
        items.add(DropdownMenuItem(
          value: item['ixa00700'],
          child: Container(
            width: Business.deviceWidth(context) - 100,
            child: Text(
              item['ixa00701'],
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ));
      }
      setState(() {
        _stationTypeItems = items;
      });
    } else {
      // _showMessage(ResultFlag.ng, result.getNGMessage());
    }
  }

  //讀取生產站點
  void _loadStationCode(String stationType) async {
    List<DropdownMenuItem> items = List<DropdownMenuItem>();
    Datagram datagram = Datagram();
    datagram.addText("""select * from xvms_0004
                        where vs000403 = '$stationType' and vs000405 = 'N'
    """, rowIndex: 0, rowSize: 100);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      for (Map<String, dynamic> item in data) {
        items.add(DropdownMenuItem(
          value: item['VS000400'],
          child: Container(
            width: Business.deviceWidth(context) - 100,
            child: Text(
              item['VS000403'] + item['VS000400'] + ' ' + item['VS000401'],
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ));
      }
      setState(() {
        _stationCodeItems = items;
        _xvms_0004 = data;
      });
    } else {
      // _showMessage(ResultFlag.ng, result.getNGMessage());
    }
  }

  void _loadCheckReport(String carModelType) async {
    List<DropdownMenuItem> items = List<DropdownMenuItem>();
    Datagram datagram = Datagram();
    datagram.addText("""select vs002200,vs002202
                        from (select distinct vs002200,vs002202 from xvms_0022
                              where vs002200 like '$carModelType%'
                              union
                              select distinct vs002200,vs002202 from xvms_0022
                              where vs002200 like '共用%') as t1""",
        rowIndex: 0, rowSize: 100);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      if (data.length > 0) {
        for (Map<String, dynamic> item in data) {
          items.add(DropdownMenuItem(
            value: item['vs002200'] + '|' + item['vs002202'],
            child: Container(
              width: Business.deviceWidth(context) - 120,
              child: Text(
                item['vs002200'] + ' ' + item['vs002202'],
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ));
        }
      }
      setState(() {
        _carCheckReportItems = items;
      });
    } else {
      _showMessage(ResultFlag.ng, result.getNGMessage());
    }
  }

  void _loadDataList(String planDate, String carModelType) async {
    final ResponseResult result = await _loadData(planDate, carModelType);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      if (data.length > 0) {
        setState(() {
          _vinList = data;
        });
        _showMessage(ResultFlag.ok, '有資料');
      } else {
        _showMessage(ResultFlag.ok, '沒資料');
      }
    } else {
      _showMessage(ResultFlag.ng, result.getNGMessage());
    }
  }

  void _inputData(String value) async {
    value = value.replaceAll('/', '');
    if (value == '') {
      _showMessage(ResultFlag.ng, '請輸入或掃描車身號碼');
      return;
    }

    String stationType = _formData['stationType'] == null
        ? ''
        : _formData['stationType'].toString();
    String stationCode = _formData['stationCode'] == null
        ? ''
        : _formData['stationCode'].toString();
    String stationName = _xvms_0004
        .firstWhere((v) => v['VS000400'].toString() == stationCode)['VS000401']
        .toString();

    if (stationType == '') {
      _showMessage(ResultFlag.ng, '請選擇站點類別');
      return;
    }
    if (stationCode == '') {
      _showMessage(ResultFlag.ng, '請選擇生產站底');
      return;
    }
    bool resultStatus;
    //讀取車身資料
    resultStatus = await _loadDataVin(value, stationCode);
    if (resultStatus == false) {
      return;
    }

    //檢查生產狀態
    resultStatus = await _checkVINStatus(_vinNo, _vinIndex, stationCode);
    if (resultStatus == false) {
      return;
    }

    //讀取檢查表
    _loadCheckReport(_carModeType);

    Datagram datagram = Datagram();
    //刷第一槍
    if (_readerInputType == ReaderInputType.one) {
      List<ParameterField> paramList = List<ParameterField>();
      paramList.add(ParameterField(
          'sSTATION_TYPE', ParamType.strings, ParamDirection.input,
          value: stationType));
      paramList.add(ParameterField(
          'sSTATION_CODE', ParamType.strings, ParamDirection.input,
          value: stationCode));
      paramList.add(ParameterField(
          'sSTATION_NAME', ParamType.strings, ParamDirection.input,
          value: stationName));
      paramList.add(ParameterField(
          'sOPERATION_USERS', ParamType.strings, ParamDirection.input,
          value: Business.userId));
      paramList.add(ParameterField(
          'sVSAA0500', ParamType.strings, ParamDirection.input,
          value: _vinNo)); //車身號碼
      paramList.add(ParameterField(
          'sVSAA0504', ParamType.strings, ParamDirection.input,
          value: _vinIndex)); //點交次數
      paramList.add(ParameterField(
          'sVSAA0580', ParamType.strings, ParamDirection.input,
          value: '')); //作業註記一
      paramList.add(ParameterField(
          'sVSAA0581', ParamType.strings, ParamDirection.input,
          value: '')); //作業註記二
      paramList.add(ParameterField(
          'sVSAA0582', ParamType.strings, ParamDirection.input,
          value: '')); //作業註記三
      paramList.add(ParameterField(
          'sUSERID', ParamType.strings, ParamDirection.input,
          value: Business.userId)); //員工編號
      paramList.add(ParameterField(
          'sDEPTID', ParamType.strings, ParamDirection.input,
          value: Business.deptId)); //部門編號
      paramList.add(ParameterField(
          'oRESULT_CONTROL', ParamType.strings, ParamDirection.output));
      paramList.add(ParameterField(
          'oRESULT_FLAG', ParamType.strings, ParamDirection.output));
      paramList.add(
          ParameterField('oRESULT', ParamType.strings, ParamDirection.output));
      datagram.addProcedure('SPX_XVMS_AA05', parameters: paramList);
      ResponseResult result = await Business.apiExecuteDatagram(datagram);
      if (result.flag == ResultFlag.ok) {
        List<Map<String, dynamic>> data = result.getMap();
        if (data.length > 0) {
          switch (data[0]['oRESULT_CONTROL'].toString()) {
            case '':
              break;
            //表示必須第二槍
            case 'END_READER':
              break;
            //表示作業完成
            case 'COMPLETED':
              setState(() {
                _readerInputType = ReaderInputType.one;
                _vinNo = '';
                _vinIndex = '';
                _carModeType = '';
                _spacing = '';
              });
              break;
            default:
          }
        }
      } else {
        _showMessage(ResultFlag.ng, result.getNGMessage());
      }
    }
    //刷第二槍
    else {
      MessageBox.showQuestion(context, '', '確定完成結束槍?', yesButtonText: '確定',
          yesFunc: () async {
        List<ParameterField> paramList = List<ParameterField>();
        paramList.add(ParameterField(
            'sSTATION_TYPE', ParamType.strings, ParamDirection.input,
            value: stationType));
        paramList.add(ParameterField(
            'sSTATION_CODE', ParamType.strings, ParamDirection.input,
            value: stationCode));
        paramList.add(ParameterField(
            'sSTATION_NAME', ParamType.strings, ParamDirection.input,
            value: stationName));
        paramList.add(ParameterField(
            'sOPERATION_USERS', ParamType.strings, ParamDirection.input,
            value: Business.userId));
        paramList.add(ParameterField(
            'sVSAA0500', ParamType.strings, ParamDirection.input,
            value: _vinNo)); //車身號碼
        paramList.add(ParameterField(
            'sVSAA0504', ParamType.strings, ParamDirection.input,
            value: _vinIndex)); //點交次數
        paramList.add(ParameterField(
            'sVSAA0580', ParamType.strings, ParamDirection.input,
            value: '')); //作業註記一
        paramList.add(ParameterField(
            'sVSAA0581', ParamType.strings, ParamDirection.input,
            value: '')); //作業註記二
        paramList.add(ParameterField(
            'sVSAA0582', ParamType.strings, ParamDirection.input,
            value: '')); //作業註記三
        paramList.add(ParameterField(
            'sUSERID', ParamType.strings, ParamDirection.input,
            value: Business.userId)); //員工編號
        paramList.add(ParameterField(
            'sDEPTID', ParamType.strings, ParamDirection.input,
            value: Business.deptId)); //部門編號
        paramList.add(ParameterField(
            'oRESULT_CONTROL', ParamType.strings, ParamDirection.output));
        paramList.add(ParameterField(
            'oRESULT_FLAG', ParamType.strings, ParamDirection.output));
        paramList.add(ParameterField(
            'oRESULT', ParamType.strings, ParamDirection.output));
        datagram.addProcedure('SPX_XVMS_AA05', parameters: paramList);
        ResponseResult result = await Business.apiExecuteDatagram(datagram);
        if (result.flag == ResultFlag.ok) {
          List<Map<String, dynamic>> data = result.getMap();
          if (data.length > 0) {
            switch (data[0]['oRESULT_CONTROL'].toString()) {
              case '':
                break;
              //表示必須第二槍
              case 'END_READER':
                break;
              //表示作業完成
              case 'COMPLETED':
                setState(() {
                  _readerInputType = ReaderInputType.one;
                  _vinNo = '';
                  _vinIndex = '';
                  _carModeType = '';
                  _spacing = '';
                });
                break;
              default:
            }
          }
        } else {
          _showMessage(ResultFlag.ng, result.getNGMessage());
        }
      }, noButtonText: '放棄');
    }
  }

  void _hardwareInputCallback(String value) {
    if (_inputMode == 1) {
      _inputController.text = CommonMethod.barcodeCheck(_barcodeFixMode, value);
    }
  }

  String _existsVinInList(List<Map<String, dynamic>> vinList, String value) {
    String vinNo = '';
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
      vinNo = '';
    }
    if (fullCount >= 1) {
      setState(() {
        vinNo = _vinList
            .firstWhere((v) => v['車身號碼'].toString() == value)['車身號碼']
            .toString();
      });
    } else if (startWithCount >= 1) {
      setState(() {
        vinNo = _vinList
            .firstWhere(
                (v) => v['車身號碼'].toString().startsWith(value) == true)['車身號碼']
            .toString();
      });
    } else if (endWithCount >= 1) {
      setState(() {
        vinNo = _vinList
            .firstWhere(
                (v) => v['車身號碼'].toString().endsWith(value) == true)['車身號碼']
            .toString();
      });
    } else {
      vinNo = '';
    }
    return vinNo;
  }

  Future<bool> _checkVINStatus(
      String vinNo, String vinIndex, String stationCode) async {
    Datagram datagram = Datagram();
    datagram.addText("""if(1=1)
                        if exists(select 1 from xvms_ab05 where vsab0500 = '$vinNo' and vsab0504 = '$vinIndex' and vsab0506 = '$stationCode' and vsab0509 = '' and vsab0511 = '')
                           begin
                               select 'ONE' as 動作
                           end
                        else if exists(select 1 from xvms_ab05 where vsab0500 = '$vinNo' and vsab0504 = '$vinIndex' and vsab0506 = '$stationCode' and vsab0509 != '' and vsab0511 = '')
                           begin
                               select 'TWO' as 動作
                           end
                        else if exists(select 1 from xvms_ab05 where vsab0500 = '$vinNo' and vsab0504 = '$vinIndex' and vsab0506 = '$stationCode' and vsab0509 != '' and vsab0511 != '')
                           begin
                               select 'COMPLETED' as 動作
                           end
                        else
                           begin
                               select 'NOT_FOUND' as 動作
                           end
    """, rowIndex: 0, rowSize: 100);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      switch (data[0]['動作'].toString()) {
        case 'ONE':
          _readerInputType = ReaderInputType.one;
          return true;
          break;
        case 'TWO':
          _readerInputType = ReaderInputType.two;
          return true;
          break;
        case 'COMPLETED':
          _readerInputType = ReaderInputType.one;
          _showMessage(ResultFlag.ng, '車身號碼已作業完成');
          return false;
          break;
        case 'NOT_FOUND':
          _readerInputType = ReaderInputType.one;
          return true;
          break;
        default:
          return false;
      }
    } else {
      return false;
    }
  }

  Future<bool> _loadDataVin(String vinNo, String stationCode) async {
    Datagram datagram = Datagram();
    datagram.addText("""select vsaa0500 as 車身號碼,
                               vsaa0504 as 點交次數,
                               t2.vs000101 as 廠牌,
                               isnull(t4.ixa00701,'') as 車身級別,
                               iif(t5.vsab0500 is null, '未執行',
                                   iif(t5.vsab0511 != '', '結束', '開始')) as 作業狀態
                        from xvms_aa05 as t1
                        left join xvms_0001 as t2 on t1.vsaa0501 = t2.vs000100 and t2.vs000106 = '2'
                        left join xvms_aa01 as t3 on t1.vsaa0500 = t3.vsaa0100 and t1.vsaa0504 = t3.vsaa0119
                        left join entirev4.dbo.ifx_a007 as t4 on t3.vsaa0117 = t4.ixa00700 and t4.ixa00703 = '車身級別'
                        left join xvms_ab05 as t5 on t1.vsaa0500 = t5.vsab0500 and t1.vsaa0504 = t5.vsab0504 and t5.vsab0506 = '$stationCode'
                        where vsaa0500 like '%$vinNo%'
    """, rowIndex: 0, rowSize: 100);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      if (data.length > 0) {
        setState(() {
          _inputController.text = data[0]['車身號碼'].toString();
          _vinNo = data[0]['車身號碼'].toString();
          _vinIndex = data[0]['點交次數'].toString();
          _spacing = data[0]['車身級別'].toString();
          _carModeType = data[0]['廠牌'].toString();
        });
        return true;
      } else {
        setState(() {
          _vinNo = '';
          _vinIndex = '';
          _spacing = '';
          _carModeType = '';
        });
        _showMessage(ResultFlag.ng, '車身號碼不在生產計畫中');
        return false;
      }
    } else {
      _showMessage(ResultFlag.ng, result.getNGMessage());
      return false;
    }
  }

  Future<void> _loadCheckReportData(
      String vin, String vinNO, String reportName, String reportVer) async {
    Datagram datagram = Datagram();
    // datagram.addText("""select * from xvms_ah05
    //                     where vsah0500 = '$vin' and
    //                           vsah0501 = $vinNO and
    //                           vsah0502 = N'$reportName' and
    //                           vsah0503 = '$reportVer'
    // """, rowIndex: 0, rowSize: 500);
    datagram.addText("""select * from xvms_ah05
                        where vsah0500 = 'JHMRC1830JC206202' and
                              vsah0501 = 1 and
                              vsah0502 = N'HONDA_PDI檢查表' and
                              vsah0503 = '0001'
    """, rowIndex: 0, rowSize: 500);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      if (data.length > 0) {
        String xmlText = data[0]['VSAH0504'].toString();
        XmlDocument xmlDocument = XmlDocument();
        xmlDocument = xml.parse(xmlText);
        Iterable<XmlElement> root = xmlDocument.findElements('root');
        if (root.isEmpty == true) {
          return;
        }
        List<Map<String, dynamic>> xmlElementList =
            List<Map<String, dynamic>>();
        for (XmlElement item in xmlDocument.findAllElements('item')) {
          for (XmlNode node in item.children) {
            if ((node is XmlElement) == false) {
              continue;
            }
            XmlElement xmlElement = node;
            if (xmlElement.name.toString() == 'controlName') {
              String controlValue = item.children
                  .firstWhere((node) =>
                      (node as XmlElement).name.toString() == 'controlValue')
                  .text;
              xmlElementList.add({
                'controlName': xmlElement.text,
                'controlValue': controlValue
              });
            }
          }
        }
        setState(() {
          _controlList = xmlElementList;
        });
      }
    } else {
      _showMessage(ResultFlag.ng, result.getNGMessage());
    }
  }

  Future<ResponseResult> _loadData(String planDate, String carModelType) {
    Datagram datagram = Datagram();
    datagram.addText("""select vsaa0500 as 車身號碼,
                               vsaa0504 as 點交次數,
                               vsaa0505 as 生產日期,
                               t2.vs000101 as 廠牌
                        from xvms_aa05 as t1
                        left join xvms_0001 as t2 on t1.vsaa0501 = t2.vs000100 and t2.vs000106 = '2'
                        where vsaa0507 not in ('Z') and
                              vsaa0505 = '$planDate' and
                              t2.vs000101 = '$carModelType'
    """, rowIndex: 0, rowSize: 65535);
    Future<ResponseResult> result = Business.apiExecuteDatagram(datagram);
    return result;
  }

  Widget _buildLabel(String title, String data) {
    return Expanded(
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: Colors.black,
          ),
          children: <TextSpan>[
            TextSpan(
                text: title + ': ',
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: data),
          ],
        ),
      ),
    );
  }

  Widget _buildRaisedButton(String title, RowItem rowItem) {
    int okng = 0;
    List<String> okngItem = ['', 'OK', 'NG'];
    if (rowItem.controlValue == null || rowItem.controlValue == '')
      okng = 0;
    else if (rowItem.controlValue == 'OK')
      okng = 1;
    else
      okng = 2;
    return Container(
      child: Row(
        children: <Widget>[
          title != ''
              ? Text(
                  title + ': ',
                  style: TextStyle(fontSize: 14.0),
                )
              : Container(),
          Container(
            height: 20,
            width: 40,
            padding: EdgeInsets.only(right: 10),
            child: RaisedButton(
              padding: EdgeInsets.all(1),
              color: Colors.black,
              child: Text(okngItem[okng],
                  style: TextStyle(fontSize: 12.0, color: Colors.white)),
              onPressed: () {
                if (okng == 0)
                  okng = 1;
                else if (okng == 1)
                  okng = 2;
                else
                  okng = 0;

                setState(() {
                  rowItem.setControlValue = okngItem[okng];
                });
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTextField(String title, RowItem rowItem) {
    TextEditingController controller = TextEditingController();
    controller.text = rowItem.controlValue;
    return Container(
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
            labelText: title, labelStyle: TextStyle(fontSize: 14.0)),
        onChanged: (String value) {
          setState(() {
            controller.text = value;
            rowItem.setControlValue = value;
          });
        },
      ),
    );
  }

  Widget _buildDateTimeField(String title, RowItem rowItem) {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Container(
              padding: EdgeInsets.only(left: 20.0, right: 20.0, bottom: 5.0),
              child: DateTimeField(
                decoration: InputDecoration(labelText: title),
                format: DateFormat("yy-MM-dd"),
                onShowPicker: (context, currentValue) {
                  Future<DateTime> date;
                  date = showDatePicker(
                      context: context,
                      firstDate: DateTime(1900),
                      initialDate: currentValue ?? DateTime.now(),
                      lastDate: DateTime(2100));
                  rowItem.setControlValue = date.toString();
                  return date;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckBox(String title, RowItem rowItem) {
    bool checked = false;
    if (rowItem.controlValue == 'True')
      checked = true;
    else
      checked = false;
    return Container(
        child: Row(
      children: <Widget>[
        IconButton(
            icon: checked == true
                ? Icon(Icons.check_box_outline_blank)
                : Icon(Icons.check_box),
            onPressed: () {
              setState(() {
                checked = !checked;
                rowItem.setControlValue = (checked == true ? 'True' : 'False');
              });
            }),
        Text(
          title,
          style: TextStyle(fontSize: 14.0),
          softWrap: true,
        )
      ],
    ));
  }
}

class CheckReport {
  String reportName;
  List<ColumnItem> columnItems = [];

  List<RowItem> getAllRowItems() {
    List<RowItem> rowItems = List<RowItem>();
    if (columnItems.length > 0) {
      for (ColumnItem colItem in columnItems) {
        rowItems.addAll(colItem.rowItems);
      }
    }
    return rowItems;
  }
}

class ColumnItem {
  final String typeName;
  final List<RowItem> rowItem;

  ColumnItem(this.typeName, this.rowItem);

  List<RowItem> get rowItems {
    return rowItem;
  }
}

class RowItem {
  String _controlValue = '';
  final String keyName;
  final String controlName;
  final ValueType valueType;

  RowItem(this.keyName, this.controlName, this.valueType);

  String get controlValue {
    return _controlValue;
  }

  set setControlValue(String value) {
    _controlValue = value;
  }
}

enum ValueType { label, combobox, textbox, checkbox, number, datetime }
enum ReaderInputType { one, two }

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
  String _imageCategory = 'TVS0100011';
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
                // _offlineDataBuffer.forEach((s) {
                //   datagram.addText("""
                //                    """, rowIndex: 0, rowSize: 100);
                // });
                ResponseResult result =
                    await Business.apiExecuteDatagram(datagram);
                if (result.flag == ResultFlag.ok) {
                  _offlineDataBuffer.clear();
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  if (prefs.containsKey(widget.moduleId) == true)
                    prefs.remove(widget.moduleId);

                  _rf = ResultFlag.ok;
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
