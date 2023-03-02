import 'package:barcode_scan/barcode_scan.dart';
import 'package:car_1/business/business.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/sysMenu.dart';
import 'package:car_1/business/datagram.dart';
import 'package:car_1/business/responseresult.dart';
import 'CameraBox.dart';
import 'CarSelect.dart';
import 'GeneralFunction.dart';
import 'GeneralWidget.dart';

class TVS0100009 extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _TVS0100009();
  }
}

class _TVS0100009 extends State<TVS0100009> with TickerProviderStateMixin {
  final String moduleId = 'TVS0100009';
  final String moduleName = '存車維護作業';
  String _imageCategory = 'TVS0100009';
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
  bool _isExistsFile = false;
  //========================================================
  bool _isExistsVin = false;
  List<Map<String, dynamic>> _vinList;
  List<Map<String, dynamic>> _maintainItems;
  List<Map<String, dynamic>> _signMaintainItems;
  List<String> _signMaintainDataBuffer = List<String>();
  Map<String, dynamic> _formData = {
    'scheduleDate': null, //排程日期
  };
  Map<String, dynamic> _formData2 = {
    'scheduleDate': null, //排程日期
  };
  List<DropdownMenuItem> _scheduleDateItems = new List<DropdownMenuItem>();
  List<DropdownMenuItem<String>> _scheduleDateItems2 =
      new List<DropdownMenuItem<String>>();
  String _vinNo = ''; //車身號碼
  String _vsaa0902 = ''; //廠牌代碼
  String _vsaa0903 = ''; //車款代碼
  List<Map<String, dynamic>> _pubDate;

  @override
  void initState() {
    super.initState();
    _loadXVMS0012();
    portraitUp();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //如果 RawKeyboardListener有focus and 模式:掃描器或相機,則1.隱藏鍵盤 2.Focus在TextField
    if ((_inputMode == 1 || _inputMode == 2) &&
        _inputFocusNode.hasFocus == true) {
      SystemChannels.textInput.invokeMethod('TextInput.hide');
      FocusScope.of(context).requestFocus(_textFieldFocusNode);
    }
    //如果 TextField有focus and 模式:掃描器或相機,則隱藏鍵盤
    if ((_inputMode == 1 || _inputMode == 2) &&
        _textFieldFocusNode.hasFocus == true) {
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    }
    _mappingMaintain();
    return Scaffold(
      resizeToAvoidBottomInset: false,
      //===== 標題
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
                          xvms0033List: null,
                          dataUpload: null,
                          //拍照
                          imageCategory: _imageCategory, //作業圖庫
                          vinNo: null,
                          vinList: null,
                          onPhotograph: null,
                          signMaintainItems: _signMaintainItems,
                          onResultChange:
                              (List<Map<String, dynamic>> value1) async {
                            if (value1 != null) {
                              SharedPreferences prefs =
                                  await SharedPreferences.getInstance();
                              _signMaintainDataBuffer.clear();
                              for (Map<String, dynamic> item in value1) {
                                if (item['旗標'] == 'Y') {
                                  _signMaintainDataBuffer.add(
                                      item['旗標'].toString() +
                                          '|' +
                                          item['vs001201'].toString() +
                                          '|' +
                                          item['vs001202'].toString());
                                }
                              }
                              prefs.setStringList(
                                  'TVS0100009_SIGN', _signMaintainDataBuffer);
                              setState(() {
                                _signMaintainItems = value1;
                              });
                              _loadCheckItems();
                            }
                          },
                        ),
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
          child: Column(
            children: <Widget>[
              //================
              Container(
                child: Form(
                  child: Container(
                    child: Column(
                      children: <Widget>[
                        _buildInputContainer(),

                        // buildDropdownButton('計劃日期', 'scheduleDate', _formData,
                        //     _scheduleDateItems, (dynamic value) {
                        //   setState(() {
                        //     _formData['scheduleDate'] = value;
                        //     _loadCheckItems();
                        //   });
                        // }),
                        buildDropdownButton(
                            '計畫日期', _scheduleDateItems, _formData,
                            (dynamic newValue) {
                          setState(() {
                            // dropdownValue = newValue;
                            _formData['scheduleDate'] = newValue;
                            _loadCheckItems();
                          });
                        }),
                        // buildDropdownButton('計劃日期', _scheduleDateItems,
                        //     keyValue: _formData),

                        buildLabel('車身號碼', _vinNo),
                        buildLabel('廠牌', _vsaa0902),
                        buildLabel('車款', _vsaa0903),
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
                  //if (_keyCode == '4') return;
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
          //上傳
          _isExistsVin == false
              ? Container(
                  width: 40,
                  padding: EdgeInsets.only(right: 10),
                  child: IconButton(
                    icon: Icon(Icons.cloud_upload),
                    onPressed: () {
                      _saveData(_vinNo);
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
                      if (_inputController.text == '' || _vinList == null) {
                        _showMessage(ResultFlag.ng, '請輸入或掃描車身號碼');
                        return;
                      }
                      map = CommonMethod.checkVinList(
                          _inputController.text, _vinList);
                      if (map['resultFlag'].toString() == 'ng') {
                        _showMessage(ResultFlag.ng, map['result'].toString());
                        return;
                      } else {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CameraBox(
                                    'compid',
                                    _imageCategory,
                                    map['result'].toString(),
                                    null)));
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
            // buildConnectMode(Colors.white, _onlineMode, (bool value) {
            //   setState(() {
            //     _onlineMode = value;
            //   });
            //   Navigator.pop(context);
            // }),
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
            // buildDataUpload(Color(0xffe1e6ef), () {
            //   if (_onlineMode == false) return;
            //   MessageBox.showQuestion(
            //       context,
            //       '共' + (_offlineDataBuffer.length).toString() + '筆資料',
            //       '確定上傳?', yesFunc: () async {
            //     setState(() {
            //       _isLoading = true;
            //     });
            //     Datagram datagram = Datagram();
            //     _offlineDataBuffer.forEach((s) {
            //       String vsab1300 = s.split('|')[0];
            //       String vsab1301 = s.split('|')[1];
            //       String vsab1303 = s.split('|')[2];
            //       String vsab1304 = s.split('|')[3];
            //       String vsab1305 = s.split('|')[4];
            //       String vsab1306 = s.split('|')[5];
            //       String vsab1307 = s.split('|')[6];
            //       String vsab1308 = s.split('|')[7];
            //       String vsab1309 = s.split('|')[8];
            //       String vsab1313 = s.split('|')[9];
            //       String vsab1314 = s.split('|')[10];
            //       String userId = s.split('|')[11];
            //       String deptId = s.split('|')[12];

            //       datagram.addText("""insert into xvms_ab13
            //                           select '0',
            //                                  entirev4.dbo.systemdate(),
            //                                  entirev4.dbo.systemtime(),
            //                                  '$userId',
            //                                  '$deptId',
            //                                  '','','','','',
            //                                  vsaa0100,
            //                                  vsaa0119,
            //                                  isnull((select max(vsab1302) from xvms_ab13 where vsab1300 = t1.vsaa0100 and vsab1301 = t1.vsaa0119),0) + 1,
            //                                  '$vsab1303',--料號
            //                                  '$vsab1304',--品名
            //                                  '$vsab1305',--規格
            //                                  '$vsab1306',--單位
            //                                  $vsab1307,--點收數量
            //                                  $vsab1308,--已收數量
            //                                  $vsab1309,--缺件數量
            //                                  entirev4.dbo.systemdate(),
            //                                  entirev4.dbo.systemtime(),
            //                                  '$userId',
            //                                  N'$vsab1313',--檢查說明
            //                                  '$vsab1314',--是否缺件
            //                                  'N',--缺件是否修正
            //                                  '','','',''
            //                           from xvms_aa01 as t1
            //                           where t1.vsaa0100 = '$vsab1300' and
            //                                 t1.vsaa0119 = '$vsab1301'
            //                        """, rowIndex: 0, rowSize: 100);
            //     });
            //     ResponseResult result = await Business.apiExecuteDatagram(datagram);
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
            buildGallery(context, Color(0xffe1e6ef), _imageCategory),
            //==== 拍照
            // buildPhotograph(context, Color(0xffe1e6ef), _inputController.text,
            //     _vinList, _imageCategory, (Map<String, dynamic> map) {
            //   if (map['resultFlag'].toString() == 'ok') {
            //     setState(() {
            //       _inputController.text = map['result'].toString();
            //       _isExistsFile = false;
            //     });
            //   } else {
            //     _showMessage(ResultFlag.ng, map['result'].toString());
            //   }
            // }),
            Divider(height: 2.0, color: Colors.black),
            Container(
              height: 50,
              color: Colors.white,
              child: ListTile(
                  leading: Icon(Icons.apps),
                  title: Text('指定維護項目'),
                  onTap: () async {
                    Navigator.pop(context);
                    List<Map<String, dynamic>> result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              AddMaintainItem(_signMaintainItems)),
                    );

                    if (result != null) {
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      _signMaintainDataBuffer.clear();
                      for (Map<String, dynamic> item in result) {
                        if (item['旗標'] == 'Y') {
                          _signMaintainDataBuffer.add(item['旗標'].toString() +
                              '|' +
                              item['vs001201'].toString() +
                              '|' +
                              item['vs001202'].toString());
                        }
                      }
                      prefs.setStringList(
                          'TVS0100009_SIGN', _signMaintainDataBuffer);
                      setState(() {
                        _signMaintainItems = result;
                      });
                      _loadCheckItems();
                    }
                  }),
            ),
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
                        '維護項目',
                        textAlign: TextAlign.center,
                      ),
                      color: Colors.black12),
                ),
              ],
            )),
        Expanded(
          child: _buildVinList(_maintainItems),
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
    bool checked = true;
    TextEditingController vsab0991controller = TextEditingController();
    TextEditingController vsab0992controller = TextEditingController();
    if (data['維護狀態'].toString() == 'Y')
      checked = true;
    else
      checked = false;
    vsab0991controller.text =
        data['維護備註01'] == null ? '' : data['維護備註01'].toString();
    vsab0991controller.selection =
        TextSelection.collapsed(offset: data['維護備註01'].toString().length);
    vsab0992controller.text =
        data['維護備註02'] == null ? '' : data['維護備註02'].toString();
    vsab0992controller.selection =
        TextSelection.collapsed(offset: data['維護備註02'].toString().length);
    return GestureDetector(
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey, width: 0.5)),
        child: Column(
          children: <Widget>[
            Container(
                child: Row(
              children: <Widget>[
                IconButton(
                    icon: checked == true
                        ? Icon(Icons.check_box)
                        : Icon(Icons.check_box_outline_blank),
                    onPressed: () {
                      setState(() {
                        if (data['維護狀態'].toString() == 'Y')
                          data['維護狀態'] = 'N';
                        else
                          data['維護狀態'] = 'Y';
                      });
                    }),
                Text(
                  data['維護項目名稱'] == null ? '' : data['維護項目名稱'].toString(),
                  style: TextStyle(fontSize: 14.0),
                  softWrap: true,
                )
              ],
            )),
            Container(
              padding: EdgeInsets.only(left: 20.0, right: 20.0),
              child: TextField(
                controller: vsab0991controller,
                decoration: InputDecoration(
                    labelText: '維護備註01', labelStyle: TextStyle(fontSize: 14.0)),
                onChanged: (String value) {
                  data['維護備註01'] = value;
                },
              ),
            ),
            Container(
              padding: EdgeInsets.only(left: 20.0, right: 20.0),
              child: TextField(
                controller: vsab0992controller,
                decoration: InputDecoration(
                    labelText: '維護備註02', labelStyle: TextStyle(fontSize: 14.0)),
                onChanged: (String value) {
                  data['維護備註02'] = value;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _inputData(String value) async {
    value = value.replaceAll('/', '').toUpperCase();
    _inputController.text = '';
    _showMessage(ResultFlag.ok, '');
    if (value == '') {
      _showMessage(ResultFlag.ng, '請輸入或掃描車身號碼');
      return;
    }

    value = await CarSelect.showWithVin(context, value);
    if (value == null) {
      _showMessage(ResultFlag.ng, '找不到符合一筆以上的車身號碼');
      return;
    }

    await _loadScheduleDate(value);
    List<Map<String, dynamic>> data = await _loadData(value);
    if (data != null) {
      setState(() {
        _inputController.text = data.first['車身號碼'].toString();
        _vinList = data;
        _vinNo = data.first['車身號碼'].toString(); //車身號碼
        _vsaa0902 = data.first['廠牌代碼'].toString(); //廠牌代碼
        _vsaa0903 = data.first['車款代碼'].toString(); //車款代碼
      });
      _loadCheckItems();
    } else {
      _showMessage(ResultFlag.ng, '沒有符合的車身號碼:' + value);
      setState(() {
        _vinNo = '';
        _vsaa0902 = '';
        _vsaa0903 = '';
        _maintainItems = null;
      });
    }
  }

  Widget buildDropdownButton(String labelText, List<DropdownMenuItem> itemList,
      Map<String, dynamic> value, void Function(dynamic) onChanged) {
    return Container(
        padding: EdgeInsets.only(left: 10.0, right: 10.0, top: 0, bottom: 0),
        margin: EdgeInsets.only(top: 0, bottom: 0),
        //height: 70,
        width: Business.deviceWidth(context) - 30,
        child: DropdownButton(
          // value: dropdownValue,
          value: value['scheduleDate'],
          hint: Text(labelText),
          //icon: Icon(Icons.arrow_downward),
          // iconSize: 24,
          // elevation: 16,
          // style: TextStyle(color: Colors.black26),
          underline: Container(
            height: 1,
            color: Colors.black38,
          ),
          // items: <String>['One', 'Two', 'Free', 'Four']
          //     .map<DropdownMenuItem<String>>((String value) {
          //   return DropdownMenuItem<String>(
          //     value: value,
          //     child: Text(value),
          //   );
          // }).toList(),
          items: itemList == null ? [] : itemList,
          onChanged: (value) {
            onChanged(value);
          },
        ));
  }

  // Widget buildDropdownButton(
  //     String labelText, List<DropdownMenuItem<dynamic>> itemList,
  //     {String keyText, Map<String, dynamic> value}) {
  //   return Container(
  //     padding: EdgeInsets.only(left: 10.0, right: 10.0, top: 0, bottom: 0),
  //     margin: EdgeInsets.only(top: 0, bottom: 0),
  //     //height: 70,
  //     width: Business.deviceWidth(context) - 30,
  //     child: DropdownButtonFormField(
  //       // decoration: InputDecoration(
  //       //   labelText: labelText,
  //       //   labelStyle: TextStyle(fontSize: 16.0),
  //       //   contentPadding: EdgeInsets.only(top: 0, bottom: 0),
  //       //   filled: false,
  //       // ),
  //       // selectedItemBuilder: (BuildContext context) {
  //       //   return _serchDropDown[labelText] == null ? [] : itemList;
  //       // },
  //       items: itemList == null ? [] : itemList,
  //       // value: _pubDate.first['計劃日期'].toString() != _formData['scheduleDate']
  //       //     ? _pubDate.first['計劃日期'].toString()
  //       //     : _formData['scheduleDate'], //_serchDropDown[labelText],
  //       value: value['scheduleDate'],
  //       onChanged: (value) {
  //         setState(() {
  //           _formData['scheduleDate'] = value;
  //           _loadCheckItems();
  //         });
  //       },
  //     ),
  //   );
  // }

  void _saveData(String value) async {
    //計劃日期
    String vsab0906 = _formData['scheduleDate'] == null
        ? ''
        : _formData['scheduleDate'].toString();
    //車身號碼
    // String vsab0911 = _inputController.text;
    String vsab0911 = value;
    if (vsab0911 == '') {
      _showMessage(ResultFlag.ng, '請輸入車身號碼');
      return;
    }
    if (vsab0906 == '') {
      _showMessage(ResultFlag.ng, '請選擇計劃日期');
      return;
    }
    //點交次數
    String vsab0912 = _vinList
        .firstWhere((v) => v['車身號碼'].toString() == vsab0911)['點交次數']
        .toString();
    //維護需求
    String vsab0907 = _vinList
        .firstWhere((v) => v['車身號碼'].toString() == vsab0911)['維護需求']
        .toString();
    Datagram datagram = Datagram();
    for (Map<String, dynamic> item in _maintainItems) {
      if (item['維護狀態'].toString() == 'Y') {
        List<ParameterField> paramList = List<ParameterField>();
        paramList.add(ParameterField(
            'sVSAB0900', ParamType.strings, ParamDirection.input,
            value: '2'));
        paramList.add(ParameterField(
            'sVSAB0906', ParamType.strings, ParamDirection.input,
            value: vsab0906));
        paramList.add(ParameterField(
            'sVSAB0907', ParamType.strings, ParamDirection.input,
            value: vsab0907));
        paramList.add(ParameterField(
            'sVSAB0908', ParamType.strings, ParamDirection.input,
            value: item['維護項目代碼'].toString()));
        paramList.add(ParameterField(
            'sVSAB0911', ParamType.strings, ParamDirection.input,
            value: vsab0911));
        paramList.add(ParameterField(
            'sVSAB0912', ParamType.strings, ParamDirection.input,
            value: vsab0912));
        paramList.add(ParameterField(
            'sVSAB0991', ParamType.strings, ParamDirection.input,
            value: item['維護備註01'].toString()));
        paramList.add(ParameterField(
            'sVSAB0992', ParamType.strings, ParamDirection.input,
            value: item['維護備註02'].toString()));
        paramList.add(ParameterField(
            'sUSERID', ParamType.strings, ParamDirection.input,
            value: Business.userId));
        paramList.add(ParameterField(
            'sDEPTID', ParamType.strings, ParamDirection.input,
            value: Business.deptId));
        paramList.add(ParameterField(
            'oRESULT_FLAG', ParamType.strings, ParamDirection.output));
        paramList.add(ParameterField(
            'oRESULT', ParamType.strings, ParamDirection.output));
        datagram.addProcedure('SPX_XVMS_AB09_INPUT', parameters: paramList);
      }
    }
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      for (Map<String, dynamic> item in _maintainItems) {
        if (item['維護狀態'].toString() == 'Y') {
          _vinList.removeWhere((v) =>
              v['計劃日期'].toString() == vsab0906 &&
              v['維護需求'].toString() == vsab0907 &&
              v['維護項目代碼'].toString() == item['維護項目代碼'].toString() &&
              v['車身號碼'].toString() == vsab0911 &&
              v['點交次數'] == int.parse(vsab0912));
        }
      }
      setState(() {
        _maintainItems = null;
      });
      _showMessage(ResultFlag.ok, '完成,請繼續下一台車');
    } else {
      _showMessage(ResultFlag.ng, result.getNGMessage());
    }
  }

  void _loadCheckItems() {
    if (_vinList == null) return;
    String scheduleDate = _formData['scheduleDate'] == null
        ? ''
        : _formData['scheduleDate'].toString();
    if (scheduleDate == '') return;

    List<Map<String, dynamic>> maintainItems = List<Map<String, dynamic>>();

    if (_signMaintainItems != null) {
      if (_signMaintainItems
              .where((v) => v['旗標'].toString() == 'Y')
              .toList()
              .length >
          0) {
        for (Map<String, dynamic> item in _signMaintainItems) {
          if (item['旗標'].toString() == 'Y') {
            Map<String, dynamic> firstItem = _vinList.firstWhere(
                (v) =>
                    v['計劃日期'].toString() == scheduleDate &&
                    v['維護項目代碼'].toString() == item['vs001201'].toString(),
                orElse: () {
              return {};
            });
            if (firstItem.isEmpty == false) {
              firstItem['維護狀態'] = 'Y';
              maintainItems.add(firstItem);
            }
          }
        }
      } else {
        maintainItems = _vinList
            .where((v) => v['計劃日期'].toString() == scheduleDate)
            .toList();
        for (Map<String, dynamic> item in maintainItems) {
          item['維護狀態'] = 'Y';
        }
      }
    } else {
      maintainItems =
          _vinList.where((v) => v['計劃日期'].toString() == scheduleDate).toList();
      for (Map<String, dynamic> item in maintainItems) {
        item['維護狀態'] = 'Y';
      }
    }
    setState(() {
      _maintainItems = maintainItems;
    });
  }

  void _mappingMaintain() {
    if (_signMaintainItems == null) return;
    SharedPreferences.getInstance().then((prefs) {
      if (prefs.containsKey('TVS0100009_SIGN') == true)
        _signMaintainDataBuffer = prefs.getStringList('TVS0100009_SIGN');
    }).whenComplete(() {
      String vs001201 = '';
      for (Map<String, dynamic> item in _signMaintainItems) {
        _signMaintainDataBuffer.forEach((s) {
          vs001201 = s.split('|')[1];
          if (item['vs001201'].toString() == vs001201) {
            item['旗標'] = 'Y';
          }
        });
      }
    });
  }

  void _hardwareInputCallback(String value) {
    if (_inputMode == 1) {
      _inputController.text = CommonMethod.barcodeCheck(_barcodeFixMode, value);
    }
  }

  void _showMessage(ResultFlag flag, String message) {
    setState(() {
      _messageFlag = flag;
      _message = message;
    });
    CommonMethod.playSound(flag);
  }

  Future<bool> _loadScheduleDate(String value) async {
    setState(() {
      _scheduleDateItems.clear();
      _formData['scheduleDate'] = null;
    });
    // if (_inputController.text == '') return;

    List<DropdownMenuItem> items = List<DropdownMenuItem>();
    List<DropdownMenuItem<String>> items2 = List<DropdownMenuItem<String>>();
    Datagram datagram = Datagram();
    datagram.addText("""select distinct vsab0906 as 計劃日期
                        from xvms_ab09 as t1
                        left join xvms_aa01 as t2 on t1.vsab0911 = t2.vsaa0100 and
                                                     t1.vsab0912 = t2.vsaa0119
                        where vsab0911 like '%$value%' and
                              vsab0900 = '2' and
                              vsab0913 = 'N' 
                              and vsab0906 >= t2.vsaa0122 
                              and --計劃日期 > 到港日期
                              vsab0906 <= convert(varchar(10), getdate() + 30, 120) --計劃日期 <= 今天+30天
                        order by vsab0906 asc
        """, rowIndex: 0, rowSize: 100);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);

    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      if (data.length > 0) {
        for (int i = 0; i < data.length; i++) {
          items.add(
            DropdownMenuItem(
              value: data[i]['計劃日期'].toString(),
              child: Container(
                width: Business.deviceWidth(context) - 100,
                child: Text(
                  data[i]['計劃日期'].toString(),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          );
        }

        setState(() {
          _scheduleDateItems = items;
          _pubDate = data;
          debugPrint(data.first['計劃日期'].toString());
          _formData['scheduleDate'] = data.first['計劃日期'].toString();
        });
        return true;
      } else {
        return true;
      }
    } else {
      return false;
    }
  }

  void _loadXVMS0012() async {
    Datagram datagram = Datagram();
    datagram.addText(
        """select 'N' as 旗標,vs001201,vs001202 from xvms_0012 where vs001200 = '2'
        """,
        rowSize: 5000);

    final ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      setState(() {
        _signMaintainItems = data;
      });
    } else {
      _showMessage(ResultFlag.ng, result.getNGMessage());
    }
  }

  Future<List<Map<String, dynamic>>> _loadData(String value) async {
    Datagram datagram = Datagram();
    datagram.addText("""select vsab0900 as 作業類別,
                               vsab0901 as 進口商系統碼,
                               t2.vs000102 as 進口商名稱,
                               vsab0902 as 廠牌系統碼,
                               t3.vs000101 as 廠牌代碼,
                               vsab0903 as 車款系統碼,
                               t4.vs000101 as 車款代碼,
                               vsab0904 as 車型系統碼,
                               vsab0905 as 車輛類型,
                               vsab0906 as 計劃日期,
                               vsab0907 as 維護需求,
                               vsab0908 as 維護項目代碼,
                               vsab0909 as 維護項目名稱,
                               vsab0911 as 車身號碼,
                               vsab0912 as 點交次數,
                               vsab0913 as 維護狀態,
                               vsab0991 as 維護備註01,
                               vsab0992 as 維護備註02
                        from xvms_ab09 as t1
                        left join xvms_0001 as t2 on t1.vsab0901 = t2.vs000100 and t2.vs000106 = '1'
                        left join xvms_0001 as t3 on t1.vsab0902 = t3.vs000100 and t3.vs000106 = '2'
                        left join xvms_0001 as t4 on t1.vsab0903 = t4.vs000100 and t4.vs000106 = '3'
                        left join xvms_0001 as t5 on t1.vsab0904 = t5.vs000100 and t5.vs000106 = '4'
                        where vsab0911 like '%$value%' and vsab0900 = '2'
                         and vsab0913 = 'N'
                        order by vsab0906 asc
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

//指定維護項目
class AddMaintainItem extends StatefulWidget {
  final List<Map<String, dynamic>> dataList;

  AddMaintainItem(this.dataList);

  @override
  State<StatefulWidget> createState() {
    return _AddMaintainItem();
  }
}

class _AddMaintainItem extends State<AddMaintainItem> {
  String _message = '';
  ResultFlag _messageFlag = ResultFlag.ok;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, widget.dataList);
          },
        ),
        title: Text('維護項目'),
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
                        '項目明細',
                        textAlign: TextAlign.center,
                      ),
                      color: Colors.black12),
                ),
              ],
            )),
        Expanded(
          child: _buildMaintainList(widget.dataList),
        ),
      ]),
    );
  }

  Widget _buildMaintainList(List<Map<String, dynamic>> data) {
    if (data == null)
      return Container();
    else {
      return Container(
        width: Business.deviceWidth(context) - 40,
        child: ListView.builder(
            itemCount: data == null ? 0 : data.length,
            itemBuilder: (BuildContext context, int index) {
              return _buildMaintainItem(context, data[index]);
            }),
      );
    }
  }

  Widget _buildMaintainItem(BuildContext context, Map<String, dynamic> data) {
    bool isSelected = false;
    if (data['旗標'].toString() == 'Y')
      isSelected = true;
    else
      isSelected = false;
    return Container(
      // height: 30,
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey, width: 0.5)),

      child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                IconButton(
                    icon: isSelected == true
                        ? Icon(Icons.check_box)
                        : Icon(Icons.check_box_outline_blank),
                    onPressed: () {
                      setState(() {
                        if (data['旗標'].toString() == 'Y')
                          data['旗標'] = 'N';
                        else
                          data['旗標'] = 'Y';
                      });
                    }),
                Text(
                  data['vs001202'] == null ? '' : data['vs001202'].toString(),
                  style: TextStyle(fontSize: 14.0),
                  softWrap: true,
                ),
              ],
            ),
          )),
    );
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

  //維護項目
  List<Map<String, dynamic>> signMaintainItems;
  void Function(List<Map<String, dynamic>>) onResultChange;
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
    //維護項目
    @required this.signMaintainItems,
    @required this.onResultChange,
  });

  @override
  State<StatefulWidget> createState() {
    return _FunctionMenu();
  }
}

class _FunctionMenu extends State<FunctionMenu> {
  int _inputMode = 1;
  int _barcodeFixMode = 0;
  String _imageCategory = 'TVS0100009';
  bool _onlineMode = true; //在線模式
  String _vinNo = ''; //車身號碼
  List<Map<String, dynamic>> _vinList;

  bool _isLoading;
  List<String> _offlineDataBuffer = List<String>();
  List<Map<String, dynamic>> _xvms0033List;
  List<Map<String, dynamic>> _signMaintainItems;

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
    _signMaintainItems = widget.signMaintainItems;
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
            //       List<ParameterField> paramList = List();
            //       paramList.add(ParameterField(
            //           'sVSAA0200', ParamType.strings, ParamDirection.input,
            //           value: s));
            //       paramList.add(ParameterField(
            //           'sVSAA0226', ParamType.strings, ParamDirection.input,
            //           value: _xvms0033List.first['儲區代碼'].toString()));
            //       paramList.add(ParameterField(
            //           'sUSERID', ParamType.strings, ParamDirection.input,
            //           value: Business.userId));
            //       paramList.add(ParameterField(
            //           'sDEPTID', ParamType.strings, ParamDirection.input,
            //           value: Business.deptId));
            //       paramList.add(ParameterField(
            //           'sROWINDEX', ParamType.strings, ParamDirection.input,
            //           value: '1'));
            //       paramList.add(ParameterField('oRESULT_FLAG',
            //           ParamType.strings, ParamDirection.output));
            //       paramList.add(ParameterField(
            //           'oRESULT', ParamType.strings, ParamDirection.output));
            //       datagram.addProcedure('IMP_XVMS_AA02_01',
            //           parameters: paramList);
            //     });
            //     ResponseResult result =
            //         await Business.apiExecuteDatagram(datagram);
            //     if (result.flag == ResultFlag.ok) {

            //       _offlineDataBuffer.clear();
            //       SharedPreferences prefs =
            //           await SharedPreferences.getInstance();
            //       if (prefs.containsKey(widget.moduleId) == true)
            //         prefs.remove(widget.moduleId);

            //       _rf = ResultFlag.ok;
            //       resultMs = result.getNGMessage();
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

            buildGalleryWithSeqNo(context, Color(0xffe1e6ef), _imageCategory),

            //==== 拍照
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

            Container(
              height: 50,
              color: Colors.white,
              child: ListTile(
                  leading: Icon(Icons.apps),
                  title: Text('指定維護項目'),
                  onTap: () async {
                    Navigator.pop(context);
                    List<Map<String, dynamic>> result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              AddMaintainItem(_signMaintainItems)),
                    );
                    if (result != null) {
                      widget.onResultChange(result);
                    }
                  }),
            ),
            Divider(height: 2.0, color: Colors.black),
          ],
        ),
      ),
    );
  }
}
