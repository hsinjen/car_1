import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../model/sysMenu.dart';
import 'package:car_1/business/business.dart';
import 'package:car_1/business/datagram.dart';
import 'package:car_1/business/responseresult.dart';
import 'CarInformation.dart';
import 'CarSelect.dart';
import 'GeneralFunction.dart';
import 'GeneralWidget.dart';

class TVS0100012 extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _TVS0100012();
  }
}

class _TVS0100012 extends State<TVS0100012> with TickerProviderStateMixin {
  final String moduleId = 'TVS0100012';
  final String moduleName = '配件點檢稽核';
  String _imageCategory = 'TVS0100012';
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
  List<Map<String, dynamic>> _vinList;
  TextEditingController _vsaa1311Controller = TextEditingController(); //稽核備註
  String _vinNo = ''; //車身號碼
  String _vsaa1302 = ''; //廠牌代碼
  String _vsaa1303 = ''; //車款代碼

  @override
  void initState() {
    super.initState();
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
                          //車籍資料
                          vinNo: _vinNo,
                          showCarInfo: (ResultFlag value1, String value2) {
                            if (value1 == ResultFlag.ng)
                              _showMessage(value1, value2);
                          },
                          imageCategory: null,
                          dataUpload: null,
                          onPhotograph: null,
                          showAddProduct: null,
                          isLoading: null,
                          offlineDataBuffer: null,
                          vinList: null,
                        ),
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
                      _buildInfo1(),
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
            Divider(height: 2.0, color: Colors.black),
            Container(
              height: 50,
              color: Colors.white,
              child: ListTile(
                leading: Icon(Icons.apps),
                title: Text('車籍資料'),
                onTap: () {
                  if (_inputController.text == '') {
                    _showMessage(ResultFlag.ng, '請輸入或掃描車身號碼');
                    return;
                  }
                  CarInformation.show(context, _inputController.text);
                },
              ),
            ),
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
          //稽核
          Container(
            height: 30,
            width: 60,
            padding: EdgeInsets.only(right: 10),
            child: RaisedButton(
              padding: EdgeInsets.all(1),
              color: Colors.black,
              child: Text('稽核',
                  style: TextStyle(fontSize: 20.0, color: Colors.white)),
              onPressed: () {
                _saveData();
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
                _inputController.text = '';
                _vsaa1311Controller.text = '';
                setState(() {
                  _vinList = null;
                  _vinNo = '';
                  _vsaa1302 = '';
                  _vsaa1303 = '';
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

  Widget _buildInfo1() {
    return Container(
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
              padding: EdgeInsets.only(left: 20, right: 20),
              child: TextField(
                controller: _vsaa1311Controller,
                decoration: InputDecoration(
                  labelText: '稽核備註',
                  filled: false,
                  contentPadding: EdgeInsets.only(top: 5, bottom: 10),
                ),
                keyboardType: TextInputType.text,
                onChanged: (String value) {
                  // _vsaa1311Controller.text = value;
                  // _vsaa1311Controller.selection =
                  //     TextSelection.collapsed(
                  //         offset: value.length);
                },
              ),
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
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey, width: 0.5)),
        child: Column(
          children: <Widget>[
            // Container(
            //   child: Row(
            //     children: <Widget>[
            buildLabel(
                '配件分類', data['配件分類'] == null ? '' : data['配件分類'].toString()),
            buildLabel('品名', data['品名'] == null ? '' : data['品名'].toString(),
                labelWidth: 40.0),
            //],
            //),
            //),
            Container(
              child: Row(
                children: <Widget>[
                  buildLabel('點收數量',
                      data['已收數量'] == null ? '' : data['已收數量'].toString())
                ],
              ),
            ),
            Container(
              child: Row(
                children: <Widget>[
                  buildLabel('檢查說明',
                      data['檢查說明'] == null ? '' : data['檢查說明'].toString()),
                ],
              ),
            ),
            Container(
              child: Row(
                children: <Widget>[
                  data['檢查類別代碼'].toString() != '0'
                      ? buildLabel('檢查類別',
                          data['檢查類別'] == null ? '' : data['檢查類別'].toString(),
                          valueColor: Colors.red)
                      : buildLabel('檢查類別',
                          data['檢查類別'] == null ? '' : data['檢查類別'].toString()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _inputData(String value) async {
    value = value.replaceAll('/', '').toUpperCase();
    if (value == '') {
      _showMessage(ResultFlag.ng, '請輸入或掃描車身號碼');
      return;
    }

    value = await CarSelect.showWithVin(context, value);
    if (value == null) {
      _showMessage(ResultFlag.ng, '找不到符合一筆以上的車身號碼');
      return;
    }

    bool existsVin = false;
    existsVin = await _checkExistsVin(value);
    if (existsVin == false) {
      setState(() {
        _inputController.text = '';
        _vinNo = '';
        _vsaa1302 = '';
        _vsaa1303 = '';
        _vinList = null;
        _isLoading = false;
      });
      _showMessage(ResultFlag.ng, '配件尚未點收:' + value);
      return;
    }

    setState(() {
      _isLoading = true;
    });
    List<Map<String, dynamic>> data = await _loadXVMSAB13(value);
    if (data != null) {
      setState(() {
        _inputController.text = data.first['車身號碼'].toString();
        _vinNo = data.first['車身號碼'].toString();
        _vsaa1302 = data.first['廠牌代碼'].toString();
        _vsaa1303 = data.first['車款代碼'].toString();
        _vinList = data;
        _isLoading = false;
        _messageFlag = ResultFlag.ok;
        _message = '';
      });
    } else {
      setState(() {
        _inputController.text = '';
        _vinList = null;
        _isLoading = false;
      });
      _showMessage(ResultFlag.ng, '沒有符合的車身號碼:' + value);
    }
  }

  void _saveData() async {
    if (_vinList == null) {
      _showMessage(ResultFlag.ng, '請輸入車身號碼');
      return;
    }
    Datagram datagram = Datagram();
    String vsaa1300 = _vinList.first['車身號碼'].toString();
    String vsaa1305 = _vinList.first['點交次數'].toString();
    String vsaa1311 = _vsaa1311Controller.text;
    datagram.addText("""update xvms_aa13
                          set status = status,
                          vsaa1307 = 'Y',
                          vsaa1308 = '${Business.userId}',--稽核人員
                          vsaa1309 = entirev4.dbo.systemdate(),
                          vsaa1310 = entirev4.dbo.systemtime(),
                          vsaa1311 = N'$vsaa1311'--稽核備註
                        where vsaa1300 = '$vsaa1300' and
                              vsaa1305 = $vsaa1305
                                """, rowIndex: 0, rowSize: 100);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      _showMessage(ResultFlag.ok, '稽核完成');
    } else {
      _showMessage(ResultFlag.ng, result.getNGMessage());
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
      _message = message;
    });
    CommonMethod.playSound(flag);
  }

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
                               vsab1308 as 已收數量,
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

  void Function(ResultFlag, String) showCarInfo;
  void Function(ResultFlag, String, List<Map<String, dynamic>> vinList_Add)
      showAddProduct;

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
  String _imageCategory = 'TVS0100012';
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
            Container(
              height: 50,
              color: Color(0xffe1e6ef),
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
