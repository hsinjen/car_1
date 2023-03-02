import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:car_1/business/datagram.dart';
import 'package:car_1/business/responseresult.dart';
import 'package:car_1/apis/imagebrowserlist.dart';
import 'package:car_1/business/classes.dart';
import 'package:car_1/business/business.dart';
import 'package:audioplayers/audio_cache.dart';
import '../model/sysMenu.dart';
import 'GeneralFunction.dart';
import 'GeneralWidget.dart';

class TVS0100004 extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _TVS0100004();
  }
}

class _TVS0100004 extends State<TVS0100004> with TickerProviderStateMixin {
  final String moduleId = 'TVS0100004';
  final String moduleName = '車輛查詢';
  String _imageCategory = 'TVS0100004';
  final _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final FocusNode _textFieldFocusNode = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  int _inputMode = 1; //0: keybarod 1: scanner 2:camera
  List<String> _inputModeList = ['鍵盤', '掃描器', '照相機'];
  int _barcodeFixMode = 0; //0:一般 1:去頭 2:F/U
  List<String> _barcodeFixModeList = ['一般', '去頭', 'F/U'];
  String _message = '';
  ResultFlag _messageFlag = ResultFlag.ok;
  HardwareKeyboardListener _keyboardListen;
  static AudioCache _player = AudioCache();
  //========================================================
  final _gridController = TextEditingController();
  final Map<String, dynamic> _formData = {
    'vin': null,
    'carLabel': null,
    'carModel': null,
    'carModelType': null,
    'layer': null,
    'grid': null
  };
  List<Map<String, dynamic>> _vinList;
  List<DropdownMenuItem> _carLabelItems;
  List<DropdownMenuItem> _carModelItems;
  List<DropdownMenuItem> _carModelTypeItems;
  List<DropdownMenuItem> _layerItems;

  @override
  void initState() {
    // _keyboardListen = new HardwareKeyboardListener(_hardwareInputCallback);
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
                          // // xvms0033List: _xvms0033List,
                          dataUpload: null,
                          //拍照
                          imageCategory: null, //作業圖庫
                          vinNo: null,
                          vinList: null,
                          onPhotograph: null,
                        ),
                    fullscreenDialog: false),
              );
            },
          )
        ],
      ),
      drawer: buildMenu(context),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          //======== Query Button Start
          Opacity(
            opacity: 0.8,
            child: Container(
              child: RawMaterialButton(
                onPressed: () async {
                  _loadVinData();
                },
                child: new Icon(
                  Icons.search,
                  color: Colors.white,
                  size: 32.0,
                ),
                shape: new CircleBorder(),
                elevation: 2.0,
                fillColor: Colors.blueGrey,
                padding: const EdgeInsets.all(15.0),
              ),
              padding: EdgeInsets.only(bottom: 40),
            ),
          ),
          //======== Query Button End
        ],
      ),
      body: Container(
        child: Container(
          width: Business.deviceWidth(context),
          child: Column(
            children: <Widget>[
              //================ Input Start
              Container(
                //height: 80,
                child: Form(
                  key: _formKey,
                  child: Container(
                      child: Column(
                    children: <Widget>[
                      _buildInputContainer(),
                      //==== 儲區 Layer
                      _buildLayer(),
                      //==== 儲格 Grid
                      _buildGrid(),
                    ],
                  )),
                ),
              ),
              //================ Infomation Set Start
              _isLoading == false
                  ? Expanded(
                      child: Container(
                        child: _buildCarList(_vinList),
                      ),
                    )
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
            // _buildConnectMode(),
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
            // _buildDataUpload(),
            //==== 作業圖庫
            //_buildGallery(),
            //==== 拍照
            //_buildPhotograph(),
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
                    _hardwareInputCallback(_inputController.text);
                    _inputController.selection =
                        TextSelection.collapsed(offset: 0); //游標
                    setState(() {
                      _formData['vin'] = _inputController.text;
                    });
                  }
                },
                child: TextField(
                  controller: _inputController,
                  focusNode: _textFieldFocusNode,
                  keyboardType: TextInputType.text,
                  onEditingComplete: () {
                    if (_inputMode == 0) {
                      FocusScope.of(context).requestFocus(new FocusNode());
                      _loadVinData();
                    }
                  },
                ),
              ),
            ),
          ),
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
          //         _formData['vin'] = value;
          //         setState(() {});
          //       },
          //       onEditingComplete: () {
          //         _formData['vin'] = _inputController.text;
          //         setState(() {});
          //         if (_inputMode == 0) {
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
                setState(() {
                  _inputController.text = '';
                  _formData['vin'] = '';
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
                      setState(() {
                        _inputController.text = barcode == null ? '' : barcode;
                        _formData['vin'] = barcode;
                      });
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
                            FocusScope.of(context).requestFocus(FocusNode());
                          }
                          if (_inputMode == 1) {
                            FocusScope.of(context).requestFocus(FocusNode());
                          }
                          _loadVinData();
                        },
                      ),
                    )
                  : Container(),
          //=========== Input Mode
        ],
      ),
    );
  }

  Widget _buildLayer() {
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
                    labelText: '儲區',
                    filled: false,
                    contentPadding: EdgeInsets.only(top: 0, bottom: 0)),
                selectedItemBuilder: (BuildContext context) {
                  return _formData['layer'] == null ? [] : _layerItems;
                },
                items: _layerItems == null ? [] : _layerItems,
                value: _formData['layer'],
                onChanged: (value) {
                  setState(() {
                    _formData['layer'] = value;
                  });
                  if (_inputMode == 1)
                    FocusScope.of(context).requestFocus(_inputFocusNode);
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
              child: Text('清除',
                  style: TextStyle(fontSize: 20.0, color: Colors.white)),
              onPressed: () {
                _formData['layer'] = null;
                setState(() {});
              },
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
                onSaved: (String value) {
                  _formData['grid'] = value;
                  if (_inputMode == 1)
                    FocusScope.of(context).requestFocus(_inputFocusNode);
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
              child: Text('清除',
                  style: TextStyle(fontSize: 20.0, color: Colors.white)),
              onPressed: () {
                _gridController.text = '';
                _formData['grid'] = null;
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }

  //==== 廠牌 CarLabel
  Widget _buildCarLabel() {
    return Container(
        child: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Container(
            padding: EdgeInsets.only(left: 20.0, right: 20, top: 10),
            child: DropdownButtonFormField(
              decoration: InputDecoration(
                  labelText: '廠牌',
                  filled: false,
                  contentPadding: EdgeInsets.only(top: 0, bottom: 0)),
              items: _carLabelItems,
              value: _formData['carLabel'],
              onChanged: (value) {
                setState(() {
                  _formData['carLabel'] = value;
                });
                _loadCarModelData(value);
                _loadCarModelTypeData(value, '');
              },
              // validator: (value) {
              //   if (value == null || value.isEmpty)
              //     return '請選擇廠牌';
              // },
              // onSaved: (value) {
              //   _formData['carLabel'] = value;
              // },
            ),
          ),
        ),
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
              setState(() => _formData['carLabel'] = null);
            },
          ),
        ),
      ],
    ));
  }

  //==== 車款 CarModel
  Widget _buildCarModel() {
    return Container(
        child: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Container(
            padding: EdgeInsets.only(left: 20.0, right: 20, top: 10),
            child: DropdownButtonFormField(
              decoration: InputDecoration(
                  labelText: '車款',
                  filled: false,
                  contentPadding: EdgeInsets.only(top: 0, bottom: 0)),
              items: _carModelItems,
              value: _formData['carModel'],
              onChanged: (value) {
                setState(() {
                  _formData['carModel'] = value;
                });
                //  _loadCarModelData(value);
                _loadCarModelTypeData(_formData['carLabel'], value);
              },
              // validator: (value) {
              //   if (value == null || value.isEmpty)
              //     return '請選擇廠牌';
              // },
              // onSaved: (value) {
              //   _formData['carModel'] = value;
              // },
            ),
          ),
        ),
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
              setState(() => _formData['carModel'] = null);
            },
          ),
        ),
      ],
    ));
  }

  //==== 車型 CarModelType
  Widget _buildCarModelType() {
    return Container(
        child: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Container(
            padding: EdgeInsets.only(left: 20.0, right: 20, top: 10),
            child: DropdownButtonFormField(
              decoration: InputDecoration(
                  labelText: '車型',
                  filled: false,
                  contentPadding: EdgeInsets.only(top: 0, bottom: 0)),
              items: _carModelTypeItems,
              value: _formData['carModelType'],
              onChanged: (value) {
                setState(() {
                  _formData['carModelType'] = value;
                });
              },
              // validator: (value) {
              //   if (value == null || value.isEmpty)
              //     return '請選擇廠牌';
              // },
              // onSaved: (value) {
              //   _formData['carModelType'] = value;
              // },
            ),
          ),
        ),
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
              setState(() => _formData['carModelType'] = null);
            },
          ),
        ),
      ],
    ));
  }

  Widget _buildCarList(List<Map<String, dynamic>> data) {
    if (data == null)
      return Container(child: Text('沒有資料'));
    else {
      return ListView.builder(
          itemCount: data == null ? 0 : data.length,
          itemBuilder: (BuildContext context, int index) {
            return _buildCarBox(context, data[index]);
          });
    }
  }

  Widget _buildCarBox(BuildContext context, Map<String, dynamic> data) {
    if (data == null) {
      return Card(
        child: Container(
          child: Column(
            children: <Widget>[
              _buildCarInfoItem('車身號碼', ''),
              // _buildCarInfoItem('引擎號碼', ''),
              _buildCarInfoItem('廠牌', ''),
              _buildCarInfoItem('車款', ''),
              _buildCarInfoItem('車型', ''),
              _buildCarInfoItem('車色', ''),
              _buildCarInfoItem('儲區', ''),
              _buildCarInfoItem('儲格', ''),
              _buildCarInfoItem('到港日', ''),
              _buildCarInfoItem('出車日', ''),
              _buildCarInfoItem('交車日', ''),
              _buildCarInfoItem('油品種類', ''),
              _buildCarInfoItem('加油公升', ''),
              _buildCarInfoItem('加油來源', ''),
              _buildCarInfoItem('加油狀態', ''),
            ],
          ),
        ),
      );
    } else {
      return Card(
        child: Container(
          child: Column(
            children: <Widget>[
              Divider(height: 5),
              _buildCarInfoItem(
                  '車身號碼', data['車身號碼'] == null ? '' : data['車身號碼'],
                  bold: true),
              // _buildCarInfoItem(
              //     '引擎號碼', data['引擎號碼'] == null ? '' : data['引擎號碼']),
              _buildCarInfoItem('廠牌', data['廠牌'] == null ? '' : data['廠牌']),
              _buildCarInfoItem('車款', data['車款'] == null ? '' : data['車款']),
              _buildCarInfoItem('車型', data['車型'] == null ? '' : data['車型']),
              _buildCarInfoItem('車色', data['車色'] == null ? '' : data['車色']),
              _buildCarInfoItem('儲區', data['儲區'] == null ? '' : data['儲區']),
              _buildCarInfoItem('儲格', data['儲格'] == null ? '' : data['儲格']),
              _buildCarInfoItem('到港日', data['到港日'] == null ? '' : data['到港日']),
              _buildCarInfoItem('出車日', data['出車日'] == null ? '' : data['出車日']),
              _buildCarInfoItem('交車日', data['交車日'] == null ? '' : data['交車日']),
              _buildCarInfoItem(
                  '油品種類', data['油品種類'] == null ? '' : data['油品種類']),
              _buildCarInfoItem(
                  '加油公升', data['加油公升'] == null ? '0' : data['加油公升'].toString()),
              _buildCarInfoItem(
                  '加油來源', data['加油來源'] == null ? '' : data['加油來源']),
              _buildCarInfoItem(
                  '加油狀態', (data['加油狀態'] == null ? '' : data['加油狀態']),
                  foreColor: (data['加油狀態'] == null ? '' : data['加油狀態']) == '未完成'
                      ? Colors.white
                      : Colors.black,
                  backColor: (data['加油狀態'] == null ? '' : data['加油狀態']) == '未完成'
                      ? Colors.red
                      : Colors.white),
              _buildCarImageItem(
                  context, data['車身號碼'] == null ? '' : data['車身號碼']),
            ],
          ),
        ),
      );
    }
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                      fontSize: 18,
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

  Widget _buildCarImageItem(BuildContext context, String vin) {
    return Container(
      padding: EdgeInsets.only(left: 105.0, bottom: 10),
      child: Row(
        children: <Widget>[
          //============= Vin Browser Start
          Container(
            padding: EdgeInsets.only(right: 30),
            child: SizedBox(
                height: 30.0,
                width: 30.0,
                child: new IconButton(
                  padding: new EdgeInsets.all(0.0),
                  icon: new Icon(Icons.image, size: 30.0),
                  onPressed: () async {
                    Navigator.push(
                      context,
                      new MaterialPageRoute(
                          builder: (context) => new ImageBrowserList(
                              FileSourceType.online, '$vin')),
                    );
                  },
                )),
          ),
        ],
      ),
    );
  }

  void _loadCarLabelData() async {
    List<DropdownMenuItem> items = new List();
    Datagram datagram = Datagram();
    datagram.addText("""select t1.vs000100 as 廠牌系統碼,
                  t1.vs000101 as 廠牌代碼,
                  t2.vs000102 as 進口商名稱
           from xvms_0001 as t1 left join xvms_0001 as t2 on t1.vs000107 = t2.vs000100 and t2.vs000106 = '1' 
           where t1.vs000106='2'
           order by t1.vs000101
        """, rowIndex: 0, rowSize: 100);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);

    if (result.flag == ResultFlag.ng) {
    } else {
      List<Map<String, dynamic>> data = result.getMap();
      for (int i = 0; i < data.length; i++) {
        items.add(
          DropdownMenuItem(
            value: data[i]['廠牌系統碼'].toString(),
            child: Container(
              width: Business.deviceWidth(context) - 120,
              child: Text(
                data[i]['廠牌代碼'].toString() + ' ' + data[i]['進口商名稱'].toString(),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      }
      setState(() {
        _carLabelItems = items;
      });
    }
  }

  void _loadCarModelData(String carLabel) async {
    List<DropdownMenuItem> items = new List();
    Datagram datagram = Datagram();
    datagram.addText(
        """select vs000100,vs000101 from xvms_0001 where vs000106='3' and vs000107 = '$carLabel' """,
        rowIndex: 0, rowSize: 100);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);

    if (result.flag == ResultFlag.ng) {
    } else {
      List<Map<String, dynamic>> data = result.getMap();
      for (int i = 0; i < data.length; i++) {
        items.add(
          DropdownMenuItem(
            value: data[i]['vs000100'].toString(),
            child: Container(
              width: Business.deviceWidth(context) - 120,
              child: Text(
                data[i]['vs000100'].toString() +
                    ' ' +
                    data[i]['vs000101'].toString(),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      }
      setState(() {
        _carModelItems = items;
      });
    }
  }

  void _loadCarModelTypeData(String carLabel, String carModel) async {
    List<DropdownMenuItem> items = new List();
    Datagram datagram = Datagram();
    datagram.addText("""select t1.vs000100,t1.vs000101 
           from xvms_0001 as t1 left join xvms_0001 as t2 on t1.vs000107 = t2.vs000100 and t2.vs000106 = '3'
           where t1.vs000106='4' and t1.vs000107 = '$carModel' and t2.vs000107 = '$carLabel'
        """, rowIndex: 0, rowSize: 100);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);

    if (result.flag == ResultFlag.ng) {
    } else {
      List<Map<String, dynamic>> data = result.getMap();
      for (int i = 0; i < data.length; i++) {
        items.add(
          DropdownMenuItem(
            value: data[i]['vs000100'].toString(),
            child: Container(
              width: Business.deviceWidth(context) - 120,
              child: Text(
                data[i]['vs000100'].toString() +
                    ' ' +
                    data[i]['vs000101'].toString(),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      }
      setState(() {
        _carModelTypeItems = items;
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

  void _loadVinData() async {
    _formData['vin'] = _inputController.text;
    if (_formKey.currentState.validate() == false) return;
    _formKey.currentState.save();

    bool whereCondition = false;

    if (_formData['vin'] != null && _formData['vin'].toString().length > 0)
      whereCondition = true;
    if (_formData['carLabel'] != null &&
        _formData['carLabel'].toString().length > 0) whereCondition = true;
    if (_formData['carModel'] != null &&
        _formData['carModel'].toString().length > 0) whereCondition = true;
    if (_formData['carModelType'] != null &&
        _formData['carModelType'].toString().length > 0) whereCondition = true;
    if (_formData['layer'] != null && _formData['layer'].toString().length > 0)
      whereCondition = true;
    if (_formData['grid'] != null && _formData['grid'].toString().length > 0)
      whereCondition = true;

    if (whereCondition == false) return;

    setState(() {
      _isLoading = true;
    });

    final ResponseResult result = await _loadData(
        _formData['vin'],
        _formData['carLabel'],
        _formData['carModel'],
        _formData['carModelType'],
        _formData['layer'],
        _formData['grid']);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      if (data.length == 0) {
        setState(() {
          _isLoading = false;
          _vinList = null;
        });
      } else {
        if (data.where((v) => v['加油狀態'] == '未完成').length > 0) {
          _player.play('sounds/alarm.mp3');
        }

        setState(() {
          _isLoading = false;
          _vinList = data;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });

      _showMessage(ResultFlag.ng, result.getNGMessage());
    }
  }

  void _showMessage(ResultFlag flag, String message) {
    setState(() {
      _messageFlag = flag;
      _message = message;
    });
    CommonMethod.playSound(flag);
  }

  void _hardwareInputCallback(String value) {
    if (_inputMode == 1) {
      _inputController.text = CommonMethod.barcodeCheck(_barcodeFixMode, value);
    }
  }

  Future<ResponseResult> _loadData(String vin, String carLabel, String carModel,
      String carModelType, String layer, String grid) {
    String where = 'where ';
    if (vin != null && vin.length > 0)
      where += """vsaa0100 like '%$vin' and """;
    if (carLabel != null && carLabel.length > 0)
      where += """vsaa0102 = '$carLabel' and """;
    if (carModel != null && carModel.length > 0)
      where += """vsaa0103 = '$carModel' and """;
    if (carModelType != null && carModelType.length > 0)
      where += """vsaa0104 = '$carModelType' and """;
    if (layer != null && layer.length > 0)
      where += """vsaa0115 = '$layer' and """;
    if (grid != null && grid.length > 0) where += """vsaa0116 = '$grid' and """;

    where = where.substring(0, where.length - 4);

    Datagram datagram = Datagram();
    datagram.addText("""select t1.vsaa0100 as 車身號碼,
                               t1.vsaa0101 as 引擎號碼,
                               t2.vs000101 as 廠牌,
                               t3.vs000101 as 車款,
                               t4.vs000101 as 車型,
                               t1.vsaa0106 as 車色,
                               t1.vsaa0115 as 儲區,
                               t1.vsaa0116 as 儲格,
                               t1.vsaa0122 as 到港日,
                               isnull(t5.vsaa0607,'') as 出車日,
                               isnull(t5.vsaa0609,'') as 交車日,
                               isnull(t6.油品種類,'') as 油品種類,
                               isnull(t6.加油公升,0) as 加油公升,
                               isnull(t6.加油來源,'') as 加油來源,
                               iif(t6.車身號碼 is null,'已完成','未完成') as 加油狀態
                        from xvms_aa01 as t1 left join xvms_0001 as t2 on t1.vsaa0102 = t2.vs000100 and t2.vs000106 = '2'
                                             left join xvms_0001 as t3 on t1.vsaa0103 = t3.vs000100 and t3.vs000106 = '3'
                                             left join xvms_0001 as t4 on t1.vsaa0104 = t4.vs000100 and t4.vs000106 = '4'
                                             left join xvms_aa06 as t5 on t1.vsaa0100 = t5.vsaa0600 and t1.vsaa0119 = t5.vsaa0605
                                             left join (
                                                         select x1.vsaa1400 as 車身號碼,
                                                                x2.ixa00701 as 油品種類,
                                                                x1.vsaa1412 as 加油公升,
                                                                x3.ixa00701 as 加油來源
                                                         from xvms_aa14 as x1 left join entirev4.dbo.ifx_a007 as x2 on x1.vsaa1410 = x2.ixa00700 and x2.ixa00703='油品種類'
                                                                              left join entirev4.dbo.ifx_a007 as x3 on x1.vsaa1427 = x3.ixa00700 and x3.ixa00703='加油來源'
                                                         where vsaa1416 = 'N'
                                                       ) as t6 on t1.vsaa0100 = t6.車身號碼
                        $where
                        """, rowIndex: 0, rowSize: 100);
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
  String _imageCategory = 'TVS0100004';
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
