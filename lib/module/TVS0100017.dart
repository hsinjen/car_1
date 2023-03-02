import 'dart:convert';
import 'dart:io';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:car_1/apis/messagebox.dart';
import 'package:car_1/business/business.dart';
import 'package:car_1/business/datagram.dart';
import 'package:car_1/business/enums.dart';
import 'package:car_1/business/responseresult.dart';
import 'package:car_1/model/sysMenu.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import 'CameraBoxAdv.dart';
import 'CarSelect.dart';
import 'Document.dart';
import 'GeneralFunction.dart';
import 'GeneralWidget.dart';

class TVS0100017 extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _TVS0100017();
  }
}

class _TVS0100017 extends State<TVS0100017> {
  final _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final FocusNode _textFieldFocusNode = FocusNode();
  int _inputMode = 1; //0: keybarod 1: scanner 2:camera
  int _barcodeFixMode = 0; //0:一般 1:去頭 2:F/U
  bool _inSwitch = false;
  ReaderInputType _readerInputType = ReaderInputType.two;

  List<Map<String, dynamic>> _data = List<Map<String, dynamic>>();
  List<Document> _stationList = List<Document>();
  String _scheduleDate = ''; // 排程日期
  String _message = '';
  String _vin = ''; // 車身號碼
  String _importer = ''; // 進口商
  String _carlabel = ''; // 廠牌
  String _carmodels = ''; // 車款
  String _carmodel = ''; // 車型
  ResultFlag _messageFlag = ResultFlag.ok;
  bool isLargeScreen = false;
  bool _isSelectAll = false;
  Map<String, dynamic> _stationWork = {'station': null, 'stationName': null};
  List<Map<String, dynamic>> _stationHide = List<Map<String, dynamic>>();
  Directory _appDocDir;
  String _imageCategory = 'TVS0100017';
  List<Map<String, dynamic>> _files = new List<Map<String, dynamic>>();
  List<String> vinNos = new List<String>();
  int _checkImageCount = 0;
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();

    // _inputController.text = '3PCAJ5M10KF144086';
    // 2020-06-18
    // 9300158    楊錦樹
    // 9800012    張志明
    // _stationWork['station'] = '0039';
    // _stationWork['stationName'] = '外觀';
    _scheduleDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _loadStationHideSetting();
    _loadPath();
    portraitInit();
  }

  @override
  void dispose() {
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
        title: Text('生產刷讀作業'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
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
                          },
                          //條碼模式
                          barcodeMode: _barcodeFixMode,
                          onBarcodeChange: (int value) {
                            _barcodeFixMode = value;
                          },
                          //dataUpload
                          offlineDataBuffer: null,
                          isLoading: null,
                          xvms0033List: null,
                          dataUpload: null,
                          //拍照
                          imageCategory: null, //作業圖庫
                          vinNo: null,
                          vinList: null,
                          onPhotograph: null,
                          //排程日期
                          datetimeinit: _scheduleDate,
                          onDateTimeChange: (String value) {
                            _scheduleDate = value;
                          },
                          //作業站點
                          stationWork: _stationWork,
                          onStationWorkChange: (Map<String, dynamic> value) {
                            _stationWork = value;
                            // debugPrint(_stationWork['station'].toString());
                            // debugPrint(_stationWork['stationName'].toString());
                          },
                          stationHide: _stationHide,
                          onStationHideChange:
                              (List<Map<String, dynamic>> data) {
                            _stationHide = data;
                            _saveStationHideSetting();
                            // for (Map<String, dynamic> item in data) {
                            //   debugPrint(item['station'].toString());
                            //   debugPrint(item['stationName'].toString());
                            // }
                          },
                        ),
                    fullscreenDialog: false),
              );
            },
          )
        ],
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        child: Column(
          children: [
            //=================== Station Selector
            Container(
              height: 50,
              color: Colors.blue[50],
              child: ListTile(
                  leading: Container(
                    child: Text('作業站點：'),
                    margin: EdgeInsets.only(top: 3.5),
                  ),
                  title: Text((_stationWork['stationName'] != null
                      ? _stationWork['stationName'].toString()
                      : '')),
                  onTap: () async {
                    Map<String, dynamic> data = {
                      'station': null,
                      'stationName': null
                    };

                    data = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => StationWork(
                                  station: _stationWork,
                                  scheduleDate: _scheduleDate,
                                )));
                    if (data == null) return;
                    setState(() {
                      _stationWork = data;
                    });
                  }),
            ),
            //====================
            _buildInputContainer(),
            Row(
              children: [
                Container(
                  alignment: Alignment.centerRight,
                  width: 90.0,
                  child: Text('車身號碼'),
                ),
                Text(':'),
                Text(_vin),
              ],
            ),
            Row(
              children: [
                Container(
                  alignment: Alignment.centerRight,
                  width: 90.0,
                  child: Text('廠牌'),
                ),
                Text(':'),
                Text(_carlabel),
              ],
            ),
            Row(
              children: [
                Container(
                  alignment: Alignment.centerRight,
                  width: 90.0,
                  child: Text('車款'),
                ),
                Text(':'),
                Text(_carmodels),
              ],
            ),
            Row(
              children: [
                Container(
                  alignment: Alignment.centerRight,
                  width: 90.0,
                  child: Text('車型'),
                ),
                Text(':'),
                Text(_carmodel),
              ],
            ),
            Row(
              children: [
                Container(
                  alignment: Alignment.centerRight,
                  width: 120.0,
                  child: Text('全選OK/全選NG:'),
                ),
                IconButton(
                  icon: _isSelectAll
                      ? Icon(
                          Icons.check_box,
                          size: 25.0,
                        )
                      : Icon(Icons.check_box_outline_blank, size: 25.0),
                  onPressed: () {
                    selectAll();
                  },
                ),
                // RaisedButton(
                //     child: Text('這是測試照片路徑上傳'),
                //     onPressed: () {
                //       _loadFiles(_stationList[0]);
                //       //刪除本地照片
                //       if (_files != null && _files.length > 0) {
                //         uploadPicture();
                //         // CommonMethod.removeFilesOfDirNoQuestion(
                //         //     context, 'compid/$_imageCategory', '');
                //       }
                //     })
              ],
            ),
            Expanded(
              child: _buildStationList(_data),
            ),
            buildMessage(context, _messageFlag, _message),
          ],
        ),
      ),
      drawer: buildMenu(context),
    );
  }

  void portraitInit() async {
    await SystemChrome.setPreferredOrientations([]);
  }

  Widget _buildInputContainer() {
    return Container(
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
              // padding: EdgeInsets.only(left: 20.0),
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
                      _inputData(_inputController.text);
                      FocusScope.of(context).requestFocus(FocusNode());
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
          Container(
            height: 30,
            width: 60,
            padding: EdgeInsets.only(right: 10),
            child: RaisedButton(
              padding: EdgeInsets.all(1),
              color: Colors.black,
              child: Text('OK',
                  style: TextStyle(fontSize: 20.0, color: Colors.white)),
              onPressed: () {
                if (_isLoading == false) _saveFromOK();
              },
            ),
          ),
          //=========== Input Mode 相機掃描
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
                      // _showMessage(ResultFlag.ng, 'Scan Barcode Error 請檢查相機權限');
                    }
                  },
                )
              : Container(),
          //=========== Input Mode
        ],
      ),
    );
  }

  Widget _buildStationList(List<Map<String, dynamic>> data) {
    if (data == null)
      return Container(
        child: Text('沒有資料'),
      );
    else
      return ListView.builder(
        itemBuilder: (BuildContext context, int index) {
          return _buildStationListSub(context, data[index]);
        },
        itemCount: data == null ? 0 : data.length,
      );
  }

  Widget _buildStationListSub(BuildContext context, Map<String, dynamic> data) {
    bool _visable = false;
    if (data['是否顯示'].toString() == 'Y')
      _visable = true;
    else
      _visable = false;
    return Column(
      children: [
        Container(
          //width: Business.deviceWidth(context),
          color: Colors.grey,
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child:
                      Text(data['作業名稱'] != null ? data['作業名稱'].toString() : ''),
                ),
              ),
              SizedBox(
                width: 15,
              ),
              SizedBox(
                width: 250, //before : 450
                child:
                    Text(data['站點名稱'] != null ? data['站點名稱'].toString() : ''),
              ),
              SizedBox(
                  width: 200,
                  child: IconButton(
                    icon: Icon(
                      Icons.camera_alt,
                      //size: 30,
                    ),
                    onPressed: () async {
                      if (data['是否顯示'].toString() == 'N') return;

                      //判斷該員工部門有無作業權限、沒有則無法拍照
                      if (data['作業部門'].toString() != '') {
                        dynamic vsab3225map =
                            jsonDecode(data['作業部門'].toString());
                        List vsab3225List = vsab3225map['items'];
                        if (vsab3225List
                                .where((element) =>
                                    element['deptId'] == Business.deptId)
                                .length ==
                            0) return;
                      }
                      //判斷是否完成了
                      int completeCount = _stationList
                          .firstWhere(
                            (element) =>
                                element.stationNo == data['站點序號'].toString(),
                          )
                          .items
                          .where((v) => v.status == DocumentStatus.complete)
                          .length;
                      if (completeCount > 0) return;

                      Map<String, dynamic> map =
                          await CommonMethod.checkCameraPermission();
                      if (map['resultFlag'].toString() == 'ng') {
                        MessageBox.showError(context, ResultFlag.ng.toString(),
                            map['result'].toString());
                        return;
                      }
                      if (_vin == '' || _data == null || _data.length == 0) {
                        _showMessage(ResultFlag.ng, '請輸入或掃描計畫中內車身號碼');
                        return;
                      }
                      String planKey = data['作業序號'].toString() +
                          '/' +
                          data['站點序號'].toString() +
                          '/' +
                          data['排程日期'].toString();
                      await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => CameraBoxAdv(
                                      'compid',
                                      _imageCategory,
                                      planKey + '/' + _vin, (resultImageCount) {
                                    _checkImageCount = resultImageCount;
                                  })));
                    },
                  )),
              SizedBox(
                width: 100,
                child: Text('OK'),
              ),
              SizedBox(
                width: 84,
                child: Text('NG'),
              ),
              SizedBox(
                width: 75.0,
                child: Text('備註'),
              ),
              Container(
                height: 24.0,
                child: Switch(
                  value: _visable,
                  onChanged: (bool value) {
                    if (data['是否顯示'].toString() == 'Y')
                      data['是否顯示'] = 'N';
                    else
                      data['是否顯示'] = 'Y';
                    setState(() {
                      _visable = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        _visable == true
            ? _buildCheckItemList(
                data['站點序號'] != null ? data['站點序號'].toString() : '')
            : Container(),
      ],
    );
  }

  Widget _buildCheckItemList(String station) {
    List<DocumentItem> data = List<DocumentItem>();
    if (_stationList.length == 0) return Container();
    data = _stationList.firstWhere((element) => element.stationNo == station,
        orElse: () {
      return null;
    }).items;

    if (data == null)
      return Container();
    else
      return Container(
        padding: EdgeInsets.only(right: 20.0),
        height: 24.0 * data.length,
        child: ListView.builder(
          itemBuilder: (BuildContext context, int index) {
            return _buildCheckItemListSub(context, data[index]);
          },
          itemCount: data == null ? 0 : data.length,
        ),
      );
  }

  Widget _buildCheckItemListSub(
      BuildContext context, DocumentItem documentItem) {
    int groupValue = 0;
    if (documentItem.flag == DocumentFlag.ok)
      groupValue = 1;
    else if (documentItem.flag == DocumentFlag.ng)
      groupValue = 2;
    else
      groupValue = 0;
    TextEditingController controller = TextEditingController();
    controller.text = documentItem.value;

    bool isComplete = false;
    if (documentItem.status == DocumentStatus.complete) isComplete = true;
    bool isReadonly = false;

    // 檢查項目是否有屬於該部門
    bool isNotExistsDept = true;
    String isEmpty = _data
        .firstWhere(
            (element) => element['站點序號'] == documentItem.stationNo)['作業部門']
        .toString();
    if (isEmpty != '') {
      dynamic vsab3225map = jsonDecode(_data
          .firstWhere(
              (element) => element['站點序號'] == documentItem.stationNo)['作業部門']
          .toString());
      List vsab3225List = vsab3225map['items'];
      if (vsab3225List
              .where((element) => element['deptId'] == Business.deptId)
              .length ==
          0)
        isNotExistsDept = true;
      else
        isNotExistsDept = false;
    } else
      isNotExistsDept = false;

    if (isComplete == true) {
      isReadonly = true;
    } else {
      isReadonly = false;
      if (isNotExistsDept == true)
        isReadonly = true;
      else
        isReadonly = false;
    }

    Color color = Colors.white;
    if (isComplete == true)
      color = Colors.green[50];
    else if (isNotExistsDept == true) color = Colors.red[50];

    // 備註
    String _value;
    if (documentItem.value != '') {
      if (documentItem.value.length >= 3)
        _value = documentItem.value.substring(0, 3);
      else
        _value = documentItem.value;
    } else
      _value = '......';

    return Container(
      color: color,
      child: AbsorbPointer(
        absorbing: isReadonly,
        child: Column(
          children: [
            Row(
              children: [
                // 項目名稱
                SizedBox(
                  width: 550.0,
                  height: 24.0,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(documentItem.itemText),
                  ),
                ),
                // OK
                SizedBox(
                  width: 100.0,
                  height: 24.0,
                  child: Container(
                    alignment: Alignment.centerLeft,
                    child: Radio(
                      value: 1,
                      groupValue: groupValue,
                      onChanged: (int value) {
                        documentItem.setFlag = DocumentFlag.ok;
                        groupValue = value;
                        setState(() {});
                      },
                    ),
                  ),
                ),
                // NG
                SizedBox(
                  width: 100.0,
                  height: 24.0,
                  child: Container(
                    alignment: Alignment.centerLeft,
                    child: Radio(
                      value: 2,
                      groupValue: groupValue,
                      onChanged: (int value) {
                        documentItem.setFlag = DocumentFlag.ng;
                        groupValue = value;
                        setState(() {});
                      },
                    ),
                  ),
                ),
                // 備註
                SizedBox(
                  width: 39.0,
                  height: 24.0,
                  child: Text(_value),
                ),
                SizedBox(
                  width: 30.0,
                  height: 24.0,
                  child: IconButton(
                    iconSize: 18.0,
                    icon: Icon(Icons.more),
                    onPressed: () async {
                      var result = await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return TextFieldDialog(
                                itemText: documentItem.itemText,
                                initValue: documentItem.value);
                          });
                      if (result != null)
                        documentItem.setValue = result.toString();
                    },
                  ),
                ),
                // SizedBox(
                //   width: 120.0,
                //   height: 24.0,
                //   child: TextField(
                //     controller: controller,
                //     onChanged: (String value) {
                //       documentItem.setValue = value;
                //     },
                //   ),
                // ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _inputData(String value) async {
    bool result = false;
    _isSelectAll = false; //初始化
    //正式要改為6碼
    if (value.length < 6) {
      _showMessage(ResultFlag.ng, '車身號碼長度不能小於6碼');
      return;
    }
    String selectVin = await isMultipleOptionVin(value);
    if (selectVin == null || selectVin == '')
      return;
    else
      value = selectVin;
    result = await _checkData(value);
    if (result == false) return;

    result = await _loadData(value);
    if (result == false) return;

    result = await _loadCheckItemData(value);
    if (result == false) return;
  }

  Future<bool> _checkData(String vin) async {
    if (vin == '') {
      _showMessage(ResultFlag.ng, '車身號碼不可空白');
      return false;
    }

    if (_scheduleDate == '') {
      _showMessage(ResultFlag.ng, '排程日期不可空白');
      return false;
    }

    if (_stationWork['station'] == null ||
        _stationWork['station'].toString() == '') {
      _showMessage(ResultFlag.ng, '作業站點不可空白');
      return false;
    }

    Datagram datagram = Datagram();
    datagram.addText("""if(1=1)
                         declare @_作業序號 varchar(5) = '',--作業序號
                                 @_站點序號 varchar(4) = '${_stationWork['station'].toString()}',--站點序號
                                 @_排程日期 varchar(10) = '$_scheduleDate',--排程日期
                                 @_車身號碼 varchar(20) = '$vin',--車身號碼
                                 @_點交次數 int,--點交次數
                                 @_作業人員 varchar(20) = '${Business.userId}',--作業人員
                                 @_資料集 nvarchar(max) = '',--JSON(第二槍才需要)
                                 @_作業方法 varchar(2) = '01';--作業方法 01:第一槍 02:第二槍
                         declare @oresult_flag varchar(2) = 'OK',
                                 @oresult nvarchar(4000) = '';

                         if not exists(select 1 from xvms_ab31 where vsab3101 = @_站點序號 and
                                                                     vsab3102 = @_排程日期 and
                                                                     vsab3104 = @_車身號碼)
                            begin
                                raiserror('該車身號碼尚未建立計劃',16,1);
                            end

                         declare @_temp_source table
                         (
                             rowindex bigint,
                             作業序號 varchar(5),
                             站點序號 varchar(4),
                             排程日期 varchar(10),
                             車身號碼 varchar(20),
                             點交次數 int
                         );
                         declare @_start_index bigint = 0,
                                 @_end_index bigint = 0;
                         insert into @_temp_source
                         select row_number() over(order by vsab3100),
                                vsab3100,--作業序號
                                vsab3101,--站點序號
                                vsab3102,--排程日期
                                vsab3104,--車身號碼
                                max(vsab3105)--點交次數
                         from xvms_ab31
                         where vsab3101 = @_站點序號 and
                               vsab3102 = @_排程日期 and
                               vsab3104 = @_車身號碼 and
                               vsab3110 in ('0','1')--狀態
                         group by vsab3100,vsab3101,vsab3102,vsab3104
                         
                         set @_start_index = 1;
                         select @_end_index = max(rowindex) from @_temp_source
                         if isnull(@_end_index,0) = 0
                             begin
                                 goto end_proc;
                             end
                         while @_start_index <= @_end_index
                             begin
                                 select @_作業序號 = 作業序號,
                                        @_站點序號 = 站點序號,
                                        @_排程日期 = 排程日期,
                                        @_車身號碼 = 車身號碼,
                                        @_點交次數 = 點交次數
                                 from @_temp_source
                                 where rowindex = @_start_index 

                                 exec spx_xvms_aa31_in @_作業序號,
                                                       @_站點序號,
                                                       @_排程日期,
                                                       @_車身號碼,
                                                       @_點交次數,
                                                       @_作業人員,
                                                       @_資料集,
                                                       @_作業方法,
                                                       @oresult_flag output,
                                                       @oresult output;
                                 if @oresult_flag = 'NG'
                                     begin
                                         raiserror(@oresult,16,1);
                                      end
                                 set @_start_index = @_start_index + 1;
                             end
                         delete @_temp_source
                         end_proc:
                         select @oresult_flag as ORESULT_FLAG,@oresult as ORESULT;
    """, rowSize: 65535);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      _showMessage(result.flag, data[0]['ORESULT'].toString());
      _data = null;
      _stationList.clear();
      return true;
    } else {
      _showMessage(ResultFlag.ng, result.getNGMessage());
      _data = null;
      _stationList.clear();
      return false;
    }
  }

  // 載入站點
  Future<bool> _loadData(String vin) async {
    if (vin == '') {
      _showMessage(ResultFlag.ng, '車身號碼不可空白');
      return false;
    }

    if (_scheduleDate == '') {
      _showMessage(ResultFlag.ng, '排程日期不可空白');
      return false;
    }

    if (_stationWork['station'] == null ||
        _stationWork['station'].toString() == '') {
      _showMessage(ResultFlag.ng, '作業站點不可空白');
      return false;
    }

    //隱藏站點
    StringBuffer _strBuf = StringBuffer();
    String _where = '';
    for (Map<String, dynamic> item in _stationHide) {
      _strBuf.write("'");
      _strBuf.write(item['station'].toString());
      _strBuf.write("',");
    }

    if (_strBuf.length > 0) {
      _where +=
          """ and vsab3101 not in (${_strBuf.toString().substring(0, _strBuf.length - 1)}) """;
    }

    Datagram datagram = Datagram();
    datagram.addText("""if(1=1)
                        select vsab3100 as 作業序號,
                               t2.vsaa3003 as 作業名稱,
                               vsab3101 as 站點序號,
                               t3.vsab3002 as 站點名稱,
                               vsab3102 as 排程日期,
                               vsab3103 as 記錄項次,
                               vsab3104 as 車身號碼,
                               vsab3105 as 點交次數,
                               vsab3106 as 狀態,
                               vsab3129 as 作業部門,
                               case when vsab3110 in ('0','1') then 'Y' else 'N' end as 是否顯示,
                               isnull(t6.vs000101,'') as 進口商代碼,
                               isnull(t7.vs000101,'') as 廠牌代碼,
                               isnull(t8.vs000101,'') as 車款代碼,
                               isnull(t9.vs000101,'') as 車型代碼
                        from xvms_ab31 as t1
                        left join xvms_aa30 as t2 on t1.vsab3100 = t2.vsaa3001
                        left join xvms_ab30 as t3 on t1.vsab3100 = t3.vsab3000 and t1.vsab3101 = t3.vsab3001
                        left join (select distinct
                                          vsac3000 as 作業序號,
                                          vsac3001 as 站點序號
                                   from xvms_ac30) as t4 on t1.vsab3100 = t4.作業序號 and
                                                            t1.vsab3101 = t4.站點序號
                        left join xvms_0001 as t6 on t1.vsab3106 = t6.vs000100 and t6.vs000106 = '1'
                        left join xvms_0001 as t7 on t1.vsab3107 = t7.vs000100 and t7.vs000106 = '2'
                        left join xvms_0001 as t8 on t1.vsab3108 = t8.vs000100 and t8.vs000106 = '3'
                        left join xvms_0001 as t9 on t1.vsab3109 = t9.vs000100 and t9.vs000106 = '4'
                        where t4.作業序號 is not null and
                              vsab3101 = '${_stationWork['station'].toString()}' and
                              vsab3102 = '$_scheduleDate' and
                              vsab3104 = '$vin'
                        union
                        select vsab3100 as 作業序號,
                               t2.vsaa3003 as 作業名稱,
                               vsab3101 as 站點序號,
                               t3.vsab3002 as 站點名稱,
                               vsab3102 as 排程日期,
                               vsab3103 as 記錄項次,
                               vsab3104 as 車身號碼,
                               vsab3105 as 點交次數,
                               vsab3106 as 狀態,
                               vsab3129 as 作業部門,
                               case when vsab3110 in ('0','1') then 'Y' else 'N' end as 是否顯示,
                               isnull(t6.vs000101,'') as 進口商代碼,
                               isnull(t7.vs000101,'') as 廠牌代碼,
                               isnull(t8.vs000101,'') as 車款代碼,
                               isnull(t9.vs000101,'') as 車型代碼
                        from xvms_ab31 as t1
                        left join xvms_aa30 as t2 on t1.vsab3100 = t2.vsaa3001
                        left join xvms_ab30 as t3 on t1.vsab3100 = t3.vsab3000 and t1.vsab3101 = t3.vsab3001
                        left join (select distinct
                                          vsac3000 as 作業序號,
                                          vsac3001 as 站點序號
                                   from xvms_ac30) as t4 on t1.vsab3100 = t4.作業序號 and
                                                            t1.vsab3101 = t4.站點序號
                        left join xvms_0001 as t6 on t1.vsab3106 = t6.vs000100 and t6.vs000106 = '1'
                        left join xvms_0001 as t7 on t1.vsab3107 = t7.vs000100 and t7.vs000106 = '2'
                        left join xvms_0001 as t8 on t1.vsab3108 = t8.vs000100 and t8.vs000106 = '3'
                        left join xvms_0001 as t9 on t1.vsab3109 = t9.vs000100 and t9.vs000106 = '4'
                        where t4.作業序號 is not null and
                              vsab3102 = '$_scheduleDate' and
                              vsab3104 = '$vin' and
                              vsab3110 = '2' --狀態 2:完成
                              $_where
    """, rowSize: 65535);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      if (data.length > 0) {
        _vin = data.first['車身號碼'];
        _carlabel = data.first['廠牌代碼'];
        _carmodels = data.first['車款代碼'];
        _carmodel = data.first['車型代碼'];
        setState(() {
          _data = data;
        });
        return true;
      } else
        return false;
    } else {
      _showMessage(result.flag, result.getNGMessage());
      return false;
    }
  }

  // 載入檢查項目
  Future<bool> _loadCheckItemData(String vin) async {
    if (vin == '') {
      _showMessage(ResultFlag.ng, '車身號碼不可空白');
      return false;
    }

    if (_scheduleDate == '') {
      _showMessage(ResultFlag.ng, '排程日期不可空白');
      return false;
    }

    Datagram datagram = Datagram();
    datagram.addText("""if(1=1)
                        declare @_vsab3102 varchar(10) = '$_scheduleDate',
                                @_vsab3104 varchar(20) = '$vin';
                        declare @_temp_source table
                        (
                            作業序號 varchar(5),
                            站點序號 varchar(4),
                            排程日期 varchar(10),
                            紀錄項次 int,
                            車身號碼 varchar(20),
                            點交次數 int,
                            項目序號 nvarchar(50),
                            項目 nvarchar(256),
                            [status] nvarchar(30),
                            flag varchar(2),
                            [value] nvarchar(4000),
                            startTime varchar(19),
                            endTime varchar(19)
                        )
                        insert into @_temp_source
                        select vsab3100 as 作業序號,
                               vsab3101 as 站點序號,
                               vsab3102 as 排程日期,
                               vsab3103 as 紀錄項次,
                               vsab3104 as 車身號碼,
                               vsab3105 as 點交次數,
                               t2.vsac3002 as 項目序號,
                               t2.vsac3003 as 項目,
                               '0' as [status],
                               '' as flag,
                               '' as [value],
                               '' as startTime,
                               '' as endTime
                        from xvms_ab31 as t1
                        left join xvms_ac30 as t2 on t1.vsab3100 = t2.vsac3000 and
                                                     t1.vsab3101 = t2.vsac3001
                        where t2.vsac3000 is not null and
                              vsab3102 = @_vsab3102 and
                              vsab3104 = @_vsab3104 and
                              vsab3126 = N''
                        insert into @_temp_source
                        select vsab3100 as 作業序號,
                               vsab3101 as 站點序號,
                               vsab3102 as 排程日期,
                               vsab3103 as 紀錄項次,
                               vsab3104 as 車身號碼,
                               vsab3105 as 點交次數,
                               t2.itemId as 項目序號,
                               t2.itemText as 項目,
                               t2.[status],
                               t2.flag,
                               t2.[value],
                               t2.startTime,
                               t2.endTime
                        from xvms_ab31 as t1
                        cross apply openjson(t1.vsab3126) with
                        (
                            itemId varchar(30),
                            itemText nvarchar(4000),
                            status nvarchar(30),
                            flag varchar(2),
                            value nvarchar(4000),
                            startTime varchar(19),
                            endTime varchar(19)
                        ) as t2
                        where vsab3102 = @_vsab3102 and
                              vsab3104 = @_vsab3104 and
                              vsab3126 != N''
                        select * from @_temp_source
                        order by 站點序號
                        delete @_temp_source;
    """);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      if (data.length > 0) {
        List<Document> stationList = List<Document>();
        for (Map<String, dynamic> station in _data) {
          Document document = Document(
              workNo: station['作業序號'].toString(),
              stationNo: station['站點序號'].toString(),
              scheduleDate: station['排程日期'].toString(),
              recordNo: station['紀錄項次'].toString(),
              vin: station['車身號碼'].toString(),
              vinNo: station['點交次數'].toString());

          for (Map<String, dynamic> item in data) {
            if (station['站點序號'] == item['站點序號']) {
              DocumentItem documentItem = DocumentItem(
                  stationNo: item['站點序號'],
                  itemId: item['項目序號'],
                  itemText: item['項目']);

              documentItem.setStatus =
                  documentItem.getDocumentStatusTypeFromString(item['status']);
              documentItem.setFlag =
                  documentItem.getDocumentFlagFromString(item['flag']);
              documentItem.setValue = item['value'];
              documentItem.setStartTime = item['startTime'];
              documentItem.setEndTime = item['endTime'];
              documentItem.setUserId = Business.userId;
              documentItem.setStartTime =
                  DateFormat('yyyy-MM-dd hh:mm:ss').format(DateTime.now());
              document.items.add(documentItem);
            }
          }
          stationList.add(document);
        }
        setState(() {
          _stationList = stationList;
        });
      }
      return true;
    } else {
      _showMessage(result.flag, result.getNGMessage());
      return false;
    }
  }

  Future<String> isMultipleOptionVin(String vin) async {
    Datagram datagram = new Datagram();
    datagram.addText("""select 
           VSAB3101,
           VSAB3102,
           VSAB3104 as 車身號碼 from XVMS_AB31 
     where VSAB3101 = '${_stationWork['station'].toString()}' and 
           VSAB3102 = '$_scheduleDate' and 
           VSAB3104 like '%$vin%' """);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();

      //若只判斷後6碼
      // List<Map<String, dynamic>> list = List();
      // int fullCount = data.where((v) => v['車身號碼'].toString() == vin).length;
      // int startCount = data.where((v) => v['車身號碼'].toString().startsWith(vin) == true).length;
      // int endCount =  data.where((v) => v['車身號碼'].toString().endsWith(vin) == true).length;
      // if(endCount > 1)
      // {
      //   data.where((v) => v['車身號碼'].toString().endsWith(vin) == true)
      //       .toList()
      //       .forEach((f) {
      //     list.add({
      //       '車身號碼': f['車身號碼'].toString(),
      //     });
      //   });

      // }..未完成

      //全判斷
      if (data.length == 1)
        return data[0]['車身號碼'].toString();
      else if (data.length > 1) {
        vin = await CarSelect.showWithList(context, data);
        if (vin == null || vin == '') {
          _showMessage(ResultFlag.ng, '找不到符合一筆以上的車身號碼:' + ' 請輸入完整或選擇一筆車身號碼');
          FocusScope.of(context).requestFocus(_inputFocusNode);
          return null;
        } else
          return vin;
      } else if (data.length <= 0) {
        _showMessage(
            ResultFlag.ng, '找不到符合一筆以上的車身號碼:' + vin + '   ,請輸入完整或檢查資料來源');
        return null;
      }
    } else {
      _showMessage(ResultFlag.ng, result.getNGMessage());
      return null;
    }
  }

  void selectAll() {
    if (_stationList.length <= 0) return;
    if (!_isSelectAll) {
      for (Document station in _stationList) {
        if (station.items
                .where((element) => element.status == DocumentStatus.complete)
                .length >
            0) continue;
        //-----判斷該員工是否為此部門
        String isEmpty = _data
            .firstWhere(
                (element) => element['站點序號'] == station.stationNo)['作業部門']
            .toString();
        if (isEmpty != '') {
          dynamic vsab3225map = jsonDecode(_data.firstWhere(
              (element) => element['站點序號'] == station.stationNo, orElse: () {
            return null;
          })['作業部門'].toString());
          List vsab3225List = vsab3225map['items'];
          if (vsab3225List
                  .where((element) => element['deptId'] == Business.deptId)
                  .length ==
              0) continue;
        }
        //-----
        if (station.items
                .where((element) => element.flag != (DocumentFlag.ok))
                .length >
            0) {
          for (DocumentItem item in station.items) {
            item.setFlag = DocumentFlag.ok;
          }
          setState(() {
            _isSelectAll = true;
          });
        }
      }
    } else {
      for (Document station in _stationList) {
        if (station.items
                .where((element) => element.status == DocumentStatus.complete)
                .length >
            0) continue;

        //-----判斷該員工是否為此部門
        String isEmpty = _data
            .firstWhere(
                (element) => element['站點序號'] == station.stationNo)['作業部門']
            .toString();
        if (isEmpty != '') {
          dynamic vsab3225map = jsonDecode(_data.firstWhere(
              (element) => element['站點序號'] == station.stationNo, orElse: () {
            return null;
          })['作業部門'].toString());
          List vsab3225List = vsab3225map['items'];
          if (vsab3225List
                  .where((element) => element['deptId'] == Business.deptId)
                  .length ==
              0) continue;
        }
        //-----

        if (station.items
                .where((element) => element.flag != DocumentFlag.ng)
                .length >
            0) {
          for (DocumentItem item in station.items) {
            item.setFlag = DocumentFlag.ng;
          }
          setState(() {
            _isSelectAll = false;
          });
        }
      }
    }
  }

  void _loadPath() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    _appDocDir = appDocDir;
  }

  void _loadFiles(Document station) async {
    if (station == null) return;
    List<FileSystemEntity> allList = List<FileSystemEntity>();
    List<Map<String, dynamic>> fileList = List<Map<String, dynamic>>();
    if (Directory(_appDocDir.path + '/compid/' + _imageCategory).existsSync() ==
        true) {
      allList = Directory(_appDocDir.path + '/compid/' + _imageCategory)
          .listSync(recursive: true, followLinks: false);
      allList.forEach((entity) {
        if (entity is File) {
          fileList.add({
            '車身號碼': path.basename(path.dirname(entity.path)),
            '檔案路徑': entity.path,
          });
          if (vinNos.length == 0)
            vinNos.add(path.basename(path.dirname(entity.path)));
          else if (vinNos
                  .where((v) => v == path.basename(path.dirname(entity.path)))
                  .length ==
              0) vinNos.add(path.basename(path.dirname(entity.path)));
        }
      });
      _files = fileList;
    } else {
      _files = fileList;
    }
  }

  Future<bool> uploadPicture() async {
    //------------------------------針對這模組下的全部車身上傳,未點檢車身略過-----------------------------
    bool resultF = false;
    for (String vin in vinNos) {
      List<File> files = List<File>();
      //點交次數
      String tag2 = '';
      Datagram datagram = Datagram();
      datagram.addText("""if(1=1)
                          declare @oResult_Fg varchar(2) ='OK',
                                  @tag2 varchar(100);
                              if exists (select 1 from XVMS_AB31 where VSAB3104 ='$vin')
                                  begin
                                      select @tag2 = max(isnull(VSAB3105,0)) 
                                            from XVMS_AB31 where VSAB3104 ='$vin'
                                  end
                              else 
                                  begin
                                      set @oResult_Fg ='NG'
                                      set @tag2 ='點交次數異常'
                                  end
                          select @oResult_Fg as oResult_Fg,@tag2 as VSAB3105
                          """, rowSize: 65535);
      ResponseResult result2 = await Business.apiExecuteDatagram(datagram);
      if (result2.flag == ResultFlag.ok) {
        List<Map<String, dynamic>> data = result2.getMap();
        if (data.length > 0 && data[0]['VSAB3105'].toString() != '點交次數異常')
          tag2 = data[0]['VSAB3105'].toString();
        else
          //若該車未有點交次數則忽略
          continue;
      } else {
        //未知異常則忽略
        continue;
      }

      for (Map<String, dynamic> item in _files.where((v) => v['車身號碼'] == vin)) {
        File f = File(item['檔案路徑'].toString());
        files.add(f);
      }
      if (files.length == 0) continue;

      String plankey = path.dirname(path.dirname(files[0].path)); //車號以前
      String scheduleDate = path.basename(plankey);
      String stationNo = path.basename(path.dirname(plankey));
      String workNo = path.basename(path.dirname(path.dirname(plankey)));
      plankey = workNo + '\\' + stationNo + '\\' + scheduleDate;
      Map<String, String> headers = {
        'ModuleId': _imageCategory,
        'SubPath': '\\' + _imageCategory + '\\' + plankey + '\\' + vin,
        'ReceiptType': workNo,
        'ReceiptSerial': stationNo,
        'ReceiptNo': scheduleDate,
        'Tag1': vin,
        'Tag2': tag2,
        'Descryption': '',
        'UploadUser': Business.userId,
        'UploadDevice': '',
      };
      // int fileSize = 0;
      // files.forEach((fsize) {
      //   List<FileSystemEntity> allList =
      //       Directory(_appDocDir.path + '/compid/' + _imageCategory)
      //           .listSync(recursive: true, followLinks: false);
      //   allList = Directory(path.dirname(fsize.path.toString())).listSync(recursive: true, followLinks: false);
      //   bool fisExists = File(fsize.path).existsSync();
      //   fileSize = fsize.lengthSync();
      // });

      ResponseResult result = await Business.apiUploadFile(
          FileCmdType.file, files,
          headers: headers);
      if (result.flag == ResultFlag.ok) {
        //上傳圖片成功
        _isLoading = false;
        //刪除本地照片...會留下資料夾00006/0001/2020-07-11
        CommonMethod.removeFilesOfDirNoQuestion(
            context,
            'compid/$_imageCategory',
            plankey.replaceAll('\\', '/') + '/' + vin);
        // //全刪00006含自己全刪除..但這是迴圈無法拿第二章上傳
        // CommonMethod.removeFilesOfDirNoQuestion(context,
        //     'compid/$_imageCategory', workNo);
        resultF = true;
      } else {
        _showMessage(ResultFlag.ng, result.getNGMessage());
        _isLoading = false;
        return resultF = false;
      }
    }
    return resultF;
  }

  void _saveFromOK() async {
    if (_stationList.length == 0) return;
    _isLoading = true; //上傳
    for (Document station in _stationList) {
      if (station.items
              .where((element) => element.flag == DocumentFlag.none)
              .length >
          0) {
        String stationText = _data
            .firstWhere((element) =>
                element['站點序號'].toString() == station.stationNo)['站點名稱']
            .toString();
        _showMessage(ResultFlag.ng, '項目尚未檢查完成,站點名稱:' + stationText);
        _isLoading = false; //上傳
        return;
      }
      //判斷該員工部門有無權限操作
      dynamic vsab3225map = jsonDecode(_data
          .firstWhere((element) => element['站點序號'] == station.stationNo)['作業部門']
          .toString());
      List vsab3225List = vsab3225map['items'];
      if (vsab3225List
              .where((element) => element['deptId'] == Business.deptId)
              .length ==
          0) {
        _showMessage(ResultFlag.ng, '您所屬部門尚無權限進行操作');
        _isLoading = false; //上傳
        return;
      }
    }
    Datagram datagram = Datagram();

    for (Document station in _stationList) {
      if (station.items
              .where((element) => element.status == DocumentStatus.complete)
              .length >
          0) {
        continue;
      }
      // 當有項目未完成時
      if (station.items
              .where((element) => element.flag == DocumentFlag.none)
              .length >
          0) {
        continue;
      }
      for (DocumentItem item in station.items) {
        item.setStatus = DocumentStatus.complete;
        item.setEndTime =
            DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      }
      datagram.addText("""if(1=1)
                        declare @rc int
                        declare @svsab3100 varchar(5)
                        declare @svsab3101 varchar(4)
                        declare @svsab3102 varchar(10)
                        declare @svsab3104 varchar(20)
                        declare @svsab3105 int
                        declare @svsab3111 varchar(20)
                        declare @svsab3126 nvarchar(max)
                        declare @svsab3128 varchar(2)
                        declare @oresult_flag varchar(2) = 'OK';
                        declare @oresult nvarchar(max) = '';
                        
                        -- TODO: Set parameter values here.
                        set @svsab3100 = '${station.workNo}';--作業序號
                        set @svsab3101 = '${station.stationNo}';--站點序號
                        set @svsab3102 = '${station.scheduleDate}';--排程日期
                        set @svsab3104 = '${station.vin}';--車身號碼
                        set @svsab3105 =  ${station.vinNo}--點交次數
                        set @svsab3111 = '${Business.userId}';--作業人員
                        set @svsab3126 = '${station.getItemsJson()}';--JSON(第二槍才需要)
                        set @svsab3128 = '02';--作業方法 01:第一槍 02:第二槍
                        
                        execute @rc = [dbo].[spx_xvms_aa31_in] 
                           @svsab3100
                          ,@svsab3101
                          ,@svsab3102
                          ,@svsab3104
                          ,@svsab3105
                          ,@svsab3111
                          ,@svsab3126
                          ,@svsab3128
                          ,@oresult_flag output
                          ,@oresult output
                          
                        if (@oresult_flag = 'NG')
                            begin
                                raiserror(@oresult,16,1);
                            end
                        select @oresult_flag as ORESULT_FLAG,@oresult as ORESULT;
    """, rowSize: 65535);
      _loadFiles(station);
    }

    if (datagram.commandList.length == 0) {
      _showMessage(ResultFlag.ng, '車身號碼已檢查完成');
      _isLoading = false; //上傳資料、圖片結束
      return;
    }
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      _showMessage(result.flag, '檢查完成');
      if (await uploadPicture() == false) {
        //TODO
        //資料ok接者上傳圖片
        //若有一台車上傳失敗...之後做別台在上傳的話,之前失敗的車會一起上傳
        //所以暫時不作獨立重新上傳的功能,因為可能要改寫作業圖庫,先這樣之後再說
      }
    } else {
      for (Document station in _stationList) {
        for (DocumentItem item in station.items) {
          item.setStatus = DocumentStatus.standby;
          item.setEndTime = '';
        }
      }
      _showMessage(result.flag, result.getNGMessage());
    }
    _isLoading = false; //上傳資料、圖片結束
  }

  void _showMessage(ResultFlag flag, String message) {
    setState(() {
      _messageFlag = flag;
      _message = message;
    });
    CommonMethod.playSound(flag);
  }

  void _saveStationHideSetting() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> _station_hide = List<String>();

    if (prefs.containsKey('TVS0100017_STATION_HIDE') == true) {
      prefs.remove('TVS0100017_STATION_HIDE');
    }
    for (Map<String, dynamic> item in _stationHide) {
      _station_hide.add(
          item['station'].toString() + '|' + item['stationName'].toString());
    }
    prefs.setStringList('TVS0100017_STATION_HIDE', _station_hide);
  }

  void _loadStationHideSetting() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> _station_hide = List<String>();

    if (prefs.containsKey('TVS0100017_STATION_HIDE') == true) {
      _station_hide = prefs.getStringList('TVS0100017_STATION_HIDE');
      _stationHide.clear();

      for (String item in _station_hide) {
        _stationHide.add(
            {'station': item.split('|')[0], 'stationName': item.split('|')[1]});
      }
    }
  }
}

/// 作業方法 01:第一槍 02:第二槍
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

  /// 排程日期初始值
  final String datetimeinit;

  /// 排程日期
  final void Function(String datetime) onDateTimeChange;

  /// 作業站點
  final Map<String, dynamic> stationWork;
  final void Function(Map<String, dynamic> stationWork) onStationWorkChange;

  /// 隱藏站點
  final List<Map<String, dynamic>> stationHide;
  final void Function(List<Map<String, dynamic>> stationHide)
      onStationHideChange;

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

    //排程日期
    @required this.datetimeinit,
    @required this.onDateTimeChange,

    //作業站點
    @required this.stationWork,
    @required this.onStationWorkChange,

    //隱藏站點
    @required this.stationHide,
    @required this.onStationHideChange,
  });

  @override
  State<StatefulWidget> createState() {
    return _FunctionMenu();
  }
}

class _FunctionMenu extends State<FunctionMenu> {
  int _inputMode = 1;
  int _barcodeFixMode = 0;
  String _imageCategory = 'TVS0100016';
  bool _onlineMode = true; //在線模式
  String _vinNo = ''; //車身號碼
  String _datetimeinit = ''; // 排程日期
  List<Map<String, dynamic>> _vinList;

  bool _isLoading;
  List<String> _offlineDataBuffer = List<String>();
  List<Map<String, dynamic>> _xvms0033List;
  Map<String, dynamic> _stationWork = {
    'station': null,
    'stationName': null,
  };
  List<Map<String, dynamic>> _stationhide;
  List<MultiSelectDialogItem<int>> _stationMutlti;

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
    _datetimeinit = widget.datetimeinit;
    _stationWork = widget.stationWork;
    _stationhide = widget.stationHide;
    _loadStationData();
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
                  title: Text('排程日期:' + _datetimeinit),
                  onTap: () async {
                    DateTime dateTime = await showDatePicker(
                        context: context,
                        firstDate: DateTime(1900),
                        initialDate: widget.datetimeinit != null
                            ? DateTime.tryParse(widget.datetimeinit)
                            : DateTime.now(),
                        lastDate: DateTime(2100));
                    String value = DateFormat('yyyy-MM-dd')
                        .format(dateTime != null ? dateTime : DateTime.now());
                    widget.onDateTimeChange(value);
                    setState(() {
                      _datetimeinit = value;
                    });
                  }),
            ),
            /*Container(
              height: 50,
              color: Colors.white,
              child: ListTile(
                  leading: Icon(Icons.apps),
                  title: Text('作業站點:' +
                      (_stationWork['stationName'] != null
                          ? _stationWork['stationName'].toString()
                          : '')),
                  onTap: () async {
                    Map<String, dynamic> data = {
                      'station': null,
                      'stationName': null
                    };
                    if (_datetimeinit != '' && _datetimeinit != null) {
                      data = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => StationWork(
                                    station: _stationWork,
                                    scheduleDate: _datetimeinit,
                                  )));
                      if (data == null) return;
                      widget.onStationWorkChange(data);
                      setState(() {
                        _stationWork = data;
                      });
                    }
                  }),
            ),*/
            Container(
              height: 50,
              color: Colors.white,
              child: ListTile(
                  leading: Icon(Icons.apps),
                  title: Text('隱藏站點'),
                  onTap: () async {
                    List<int> _initvalue = List<int>();
                    if (_stationhide.length > 0) {
                      _stationhide.forEach((element) {
                        element['station'].toString();
                        _initvalue.add(_stationMutlti
                            .firstWhere((mutlti) =>
                                mutlti.keyText == element['station'].toString())
                            .value);
                      });
                    }

                    final selectedValues = await showDialog<Set<int>>(
                      context: context,
                      builder: (BuildContext context) {
                        return MultiSelectDialog(
                          items: _stationMutlti,
                          initialSelectedValues: _initvalue.length != 0
                              ? _initvalue.toSet()
                              : null,
                        );
                      },
                    );

                    if (selectedValues == null) return;
                    List<Map<String, dynamic>> data =
                        List<Map<String, dynamic>>();
                    selectedValues.forEach((element) {
                      data.add({
                        'station': _stationMutlti
                            .firstWhere((v) => v.value == element)
                            .keyText,
                        'stationName': _stationMutlti
                            .firstWhere((v) => v.value == element)
                            .labelText
                      });
                    });
                    _stationhide = data;
                    widget.onStationHideChange(data);
                  }),
            ),
            Divider(height: 2.0, color: Colors.black),
          ],
        ),
      ),
    );
  }

  void _loadStationData() async {
    Datagram datagram = Datagram();
    datagram.addText("""select vsab3001 as 站點序號,
                               vsab3002 as 站點名稱,
                               t2.vsaa3003 as 作業名稱
                        from xvms_ab30 as t1
                        left join xvms_aa30 as t2 on t1.vsab3000 = t2.vsaa3001
                        where vsab3010 = 'P'
        """, rowIndex: 0, rowSize: 100);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);

    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      if (data.length > 0) {
        List<MultiSelectDialogItem> stationMulti =
            List<MultiSelectDialogItem<int>>();
        int index = 1;
        for (Map<String, dynamic> item in data) {
          stationMulti.add(MultiSelectDialogItem<int>(
              index++,
              item['站點序號'].toString(),
              item['站點名稱'].toString() + '-' + item['作業名稱'].toString()));
        }
        setState(() {
          _stationMutlti = stationMulti;
        });
      }
    } else {}
  }
}

class DateTimeFieldEx extends StatelessWidget {
  final String labelText;
  final String dateformat;
  final void Function(String) onChanged;
  final String initialValue;

  DateTimeFieldEx({
    @required this.labelText,
    @required this.dateformat,
    @required this.onChanged,
    this.initialValue = '',
  });

  @override
  Widget build(BuildContext context) {
    DateFormat format = DateFormat(dateformat);
    return DateTimeField(
      format: format,
      onShowPicker: (BuildContext context, DateTime currentValue) {
        return showDatePicker(
            context: context,
            firstDate: DateTime(1900),
            initialDate: currentValue ?? DateTime.now(),
            lastDate: DateTime(2100));
      },
      initialValue:
          initialValue != null ? DateTime.now() : DateTime.parse(initialValue),
      onChanged: (DateTime datetime) {
        String controlText = '';
        if (datetime != null) {
          String formattedDate = format.format(datetime);
          controlText = formattedDate;
        } else {
          controlText = '';
        }
        onChanged(controlText);
      },
      decoration: InputDecoration(
        labelText: labelText,
      ),
    );
  }
}

class TextFieldDialog extends StatefulWidget {
  final String itemText;
  final String initValue;

  TextFieldDialog({@required this.itemText, @required this.initValue});

  @override
  State<StatefulWidget> createState() {
    return _TextFieldDialog();
  }
}

class _TextFieldDialog extends State<TextFieldDialog> {
  TextEditingController controller = TextEditingController();
  @override
  void initState() {
    super.initState();
    controller.text = widget.initValue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(15.0),
        child: Column(
          children: [
            Text(
              widget.itemText,
              style: TextStyle(fontSize: 30.0, decoration: TextDecoration.none),
            ),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: '備註',
              ),
              keyboardType: TextInputType.multiline,
              maxLines: null,
              maxLength: 256,
            ),
            RaisedButton(
              onPressed: () {
                Navigator.pop(context, controller.text);
              },
              child: Text('確認'),
            ),
          ],
        ),
      ),
      resizeToAvoidBottomInset: false,
    );
  }
}

class StationWork extends StatefulWidget {
  final Map<String, dynamic> station;
  String scheduleDate;

  StationWork({
    @required this.station,
    @required this.scheduleDate,
  });

  @override
  State<StatefulWidget> createState() {
    return _StationWork();
  }
}

class _StationWork extends State<StationWork> {
  List<Map<String, dynamic>> _data;
  List<DropdownMenuItem> _items;

  @override
  void initState() {
    super.initState();
    _loadStationData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('作業站點'),
      ),
      body: Container(
        child: Column(
          children: [
            Container(
              padding:
                  EdgeInsets.only(left: 20.0, right: 20, top: 10, bottom: 10),
              child: DropdownButtonFormField(
                items: _items == null ? [] : _items,
                value: widget.station['station'],
                onChanged: (dynamic value) {
                  widget.station['station'] = value.toString();
                  widget.station['stationName'] = _data
                      .firstWhere((element) =>
                          element['站點序號'] == value.toString())['站點名稱']
                      .toString();
                },
                decoration: InputDecoration(
                  labelText: '站點序號',
                  labelStyle: TextStyle(fontSize: 16.0),
                  contentPadding: EdgeInsets.only(top: 0, bottom: 0),
                  filled: false,
                ),
              ),
            ),
            RaisedButton(
              onPressed: () {
                Navigator.pop(context, widget.station);
              },
              child: Text('確認'),
            ),
          ],
        ),
      ),
    );
  }

  void checkStationValue() {
    if (_data != null) {
      if (_data
              .where((e) =>
                  e['站點序號'] == widget.station['station'] &&
                  e['站點名稱'] == widget.station['stationName'])
              .length <=
          0) {
        widget.station['station'] = null;
        widget.station['stationName'] = null;
      }
    }
  }

  void _loadStationData() async {
    List<DropdownMenuItem> items = new List();
    Datagram datagram = Datagram();
    // datagram.addText("""select vsab3001 as 站點序號,
    //                            vsab3002 as 站點名稱,
    //                            t2.vsaa3003 as 作業名稱
    //                     from xvms_ab30 as t1
    //                     left join xvms_aa30 as t2 on t1.vsab3000 = t2.vsaa3001
    //                     where vsab3010 = 'P'
    //     """, rowIndex: 0, rowSize: 100);
    // datagram.addText("""select  t1.VSAA3101 as 站點序號,
    //                             t2.VSAB3002 as 站點名稱,
    //                             t3.VSAA3003 as 作業名稱
    //                         from XVMS_AA31 as t1
    //                         left join xvms_ab30 as t2 on t1.VSAA3100 = t2.VSAB3000 and t1.VSAA3101 = t2.VSAB3001
    //                         left join xvms_aa30 as t3 on t1.VSAA3100 = t3.vsaa3001
    //                                                where t2.VSAB3010 ='P' and t1.VSAA3102 = '${widget.scheduleDate}'
    //     """, rowIndex: 0, rowSize: 100);
    datagram.addText("""select  t1.VSCA0100 as 排班日期,
                                t1.VSCA0101 as 作業單位,
                                t1.VSCA0102 as 作業站點,
                                t1.VSCA0103 as 作業人員,
                                t1.VSCA0104 as 作業內容,
                                t1.VSCA0105 as 備註,
                                t2.VSAB3001 as 站點序號,
                                t2.VSAB3002 as 站點名稱,
                                t3.VSAA3003 as 作業名稱
                             from XVMS_CA01 as t1
                          left join XVMS_AB30 as t2 on t1.VSCA0102 = t2.VSAB3002
                          left join XVMS_AA30 as t3 on t2.VSAB3000 = t3.VSAA3001 
                                                 where t1.VSCA0100 = '${widget.scheduleDate}'
                                                   and t1.VSCA0103 = '${Business.userId}'
                                """, rowIndex: 0, rowSize: 100);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      for (int i = 0; i < data.length; i++) {
        items.add(
          DropdownMenuItem(
            value: data[i]['站點序號'].toString(),
            child: Container(
              width: Business.deviceWidth(context) - 100,
              child: Text(
                data[i]['站點名稱'].toString() + '-' + data[i]['作業名稱'].toString(),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      }
      if (data.length <= 0)
        MessageBox.showError(context, '注意', '查無站點,請至主管確認生產排班表');
      setState(() {
        _data = data;
        _items = items;
      });
      checkStationValue();
    } else {}
  }
}

//隱藏站點
class MultiSelectDialogItem<V> {
  const MultiSelectDialogItem(this.value, this.keyText, this.labelText);

  final V value;
  final String keyText;
  final String labelText;
}

class MultiSelectDialog<V> extends StatefulWidget {
  MultiSelectDialog({Key key, this.items, this.initialSelectedValues})
      : super(key: key);

  final List<MultiSelectDialogItem<V>> items;
  final Set<V> initialSelectedValues;

  @override
  State<StatefulWidget> createState() => _MultiSelectDialogState<V>();
}

class _MultiSelectDialogState<V> extends State<MultiSelectDialog<V>> {
  final _selectedValues = Set<V>();

  void initState() {
    super.initState();
    if (widget.initialSelectedValues != null) {
      _selectedValues.addAll(widget.initialSelectedValues);
    }
  }

  void _onItemCheckedChange(V itemValue, bool checked) {
    setState(() {
      if (checked) {
        _selectedValues.add(itemValue);
      } else {
        _selectedValues.remove(itemValue);
      }
    });
  }

  void _onCancelTap() {
    Navigator.pop(context);
  }

  void _onSubmitTap() {
    Navigator.pop(context, _selectedValues);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('選擇站點'),
      contentPadding: EdgeInsets.only(top: 12.0),
      content: SingleChildScrollView(
        child: ListTileTheme(
          contentPadding: EdgeInsets.fromLTRB(14.0, 0.0, 24.0, 0.0),
          child: ListBody(
            children: widget.items.map(_buildItem).toList(),
          ),
        ),
      ),
      actions: <Widget>[
        FlatButton(
          child: Text('CANCEL'),
          onPressed: _onCancelTap,
        ),
        FlatButton(
          child: Text('OK'),
          onPressed: _onSubmitTap,
        )
      ],
    );
  }

  Widget _buildItem(MultiSelectDialogItem<V> item) {
    final checked = _selectedValues.contains(item.value);
    return CheckboxListTile(
      value: checked,
      title: Text(item.labelText),
      controlAffinity: ListTileControlAffinity.leading,
      onChanged: (checked) => _onItemCheckedChange(item.value, checked),
    );
  }
}
