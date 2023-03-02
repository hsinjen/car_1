import 'dart:convert';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:car_1/business/business.dart';
import 'package:car_1/business/datagram.dart';
import 'package:car_1/business/responseresult.dart';
import 'package:car_1/model/sysMenu.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'Document.dart';
import 'GeneralFunction.dart';
import 'GeneralWidget.dart';

class TVS0100016 extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _TVS0100016();
  }
}

class _TVS0100016 extends State<TVS0100016> {
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

  @override
  void initState() {
    super.initState();

    // _inputController.text = 'JTMY43FV00D029924';
    // YV1LFBAADL1551450 volvo
    // T104007 T104118
    // _scheduleDate = '2020-05-25';
    _scheduleDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
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
        title: Text('存車維護作業'),
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
              onPressed: _saveFromOK,
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
      return Container();
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
                width: 450,
                child:
                    Text(data['站點名稱'] != null ? data['站點名稱'].toString() : ''),
              ),
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

    Datagram datagram = Datagram();
    datagram.addText("""if(1=1)
                         declare @_作業序號 varchar(5) = '',--作業序號
                                 @_站點序號 varchar(4) = '',--站點序號
                                 @_排程日期 varchar(10) = '$_scheduleDate',--排程日期
                                 @_車身號碼 varchar(20) = '$vin',--車身號碼
                                 @_點交次數 int,--點交次數
                                 @_作業人員 varchar(20) = '${Business.userId}',--作業人員
                                 @_資料集 nvarchar(max) = '',--JSON(第二槍才需要)
                                 @_作業方法 varchar(2) = '01';--作業方法 01:第一槍 02:第二槍
                         declare @oresult_flag varchar(2) = 'OK',
                                 @oresult nvarchar(4000) = '';
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
                         select row_number() over(order by vsab3200),
                                vsab3200,
                                vsab3201,
                                vsab3202,
                                vsab3204,
                                max(vsab3205)
                         from xvms_ab32
                         where vsab3202 = @_排程日期 and
                               vsab3204 = @_車身號碼 and
                               vsab3206 in ('0','1')
                         group by vsab3200,vsab3201,vsab3202,vsab3204
                         
                         set @_start_index = 1;
                         select @_end_index = max(rowindex) from @_temp_source
                         if @_end_index = 0
                             begin
                                 raiserror('該車身號碼尚未建立維護項目',16,1);
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

                                 exec spx_xvms_aa32_in @_作業序號,
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
      return false;
    }
  }

  Future<bool> _loadData(String vin) async {
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
                        if not exists(select 1 from xvms_ab32 where vsab3202 = '$_scheduleDate' and
                                                                    vsab3204 = '$vin')
                            begin
                                raiserror('尚未建立項目',16,1);
                            end
                        select vsab3200 as 作業序號,
                               t2.vsaa3003 as 作業名稱,
                               vsab3201 as 站點序號,
                               t3.vsab3002 as 站點名稱,
                               vsab3202 as 排程日期,
                               vsab3203 as 記錄項次,
                               vsab3204 as 車身號碼,
                               vsab3205 as 點交次數,
                               vsab3206 as 狀態,
                               vsab3225 as 作業部門,
                               case when vsab3206 in ('0','1') then 'Y' else 'N' end as 是否顯示,
                               isnull(t6.vs000101,'') as 進口商代碼,
                               isnull(t7.vs000101,'') as 廠牌代碼,
                               isnull(t8.vs000101,'') as 車款代碼,
                               isnull(t9.vs000101,'') as 車型代碼
                        from xvms_ab32 as t1
                        left join xvms_aa30 as t2 on t1.vsab3200 = t2.vsaa3001
                        left join xvms_ab30 as t3 on t1.vsab3200 = t3.vsab3000 and t1.vsab3201 = t3.vsab3001
                        left join (select distinct
                                          vsac3000 as 作業序號,
                                          vsac3001 as 站點序號
                                   from xvms_ac30) as t4 on t1.vsab3200 = t4.作業序號 and
                                                            t1.vsab3201 = t4.站點序號
                        left join xvms_aa32 as t5 on t1.vsab3204 = t5.vsaa3200 and
                                                     t1.vsab3205 = t5.vsaa3201
                        left join xvms_0001 as t6 on t5.vsaa3202 = t6.vs000100 and t6.vs000106 = '1'
                        left join xvms_0001 as t7 on t5.vsaa3203 = t7.vs000100 and t7.vs000106 = '2'
                        left join xvms_0001 as t8 on t5.vsaa3204 = t8.vs000100 and t8.vs000106 = '3'
                        left join xvms_0001 as t9 on t5.vsaa3205 = t9.vs000100 and t9.vs000106 = '4'
                        where t4.作業序號 is not null and
                              vsab3202 = '$_scheduleDate' and
                              vsab3204 = '$vin'
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
                        declare @_vsab3202 varchar(10) = '$_scheduleDate',
                                @_vsab3204 varchar(20) = '$vin';
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
                        select vsab3200 as 作業序號,
                               vsab3201 as 站點序號,
                               vsab3202 as 排程日期,
                               vsab3203 as 紀錄項次,
                               vsab3204 as 車身號碼,
                               vsab3205 as 點交次數,
                               t2.vsac3002 as 項目序號,
                               t2.vsac3003 as 項目,
                               '0' as [status],
                               '' as flag,
                               '' as [value],
                               '' as startTime,
                               '' as endTime
                        from xvms_ab32 as t1
                        left join xvms_ac30 as t2 on t1.vsab3200 = t2.vsac3000 and
                                                     t1.vsab3201 = t2.vsac3001
                        where t2.vsac3000 is not null and
                              vsab3202 = @_vsab3202 and
                              vsab3204 = @_vsab3204 and
                              vsab3222 = N''
                        insert into @_temp_source
                        select vsab3200 as 作業序號,
                               vsab3201 as 站點序號,
                               vsab3202 as 排程日期,
                               vsab3203 as 紀錄項次,
                               vsab3204 as 車身號碼,
                               vsab3205 as 點交次數,
                               t2.itemId as 項目序號,
                               t2.itemText as 項目,
                               t2.[status],
                               t2.flag,
                               t2.[value],
                               t2.startTime,
                               t2.endTime
                        from xvms_ab32 as t1
                        cross apply openjson(t1.vsab3222) with
                        (
                            itemId varchar(30),
                            itemText nvarchar(4000),
                            status nvarchar(30),
                            flag varchar(2),
                            value nvarchar(4000),
                            startTime varchar(19),
                            endTime varchar(19)
                        ) as t2
                        where vsab3202 = @_vsab3202 and
                              vsab3204 = @_vsab3204 and
                              vsab3222 != N''
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

  void _saveFromOK() async {
    for (Document station in _stationList) {
      if (station.items
              .where((element) => element.flag != DocumentFlag.none)
              .length >
          0) {
        if (station.items
                .where((element) => element.flag == DocumentFlag.none)
                .length >
            0) {
          String stationText = _data
              .firstWhere((element) =>
                  element['站點序號'].toString() == station.stationNo)['站點名稱']
              .toString();
          _showMessage(ResultFlag.ng, '項目尚未檢查完成,站點名稱:' + stationText);
          return;
        }
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
                        declare @svsab3200 varchar(5)
                        declare @svsab3201 varchar(4)
                        declare @svsab3202 varchar(10)
                        declare @svsab3204 varchar(20)
                        declare @svsab3205 int
                        declare @svsab3207 varchar(20)
                        declare @svsab3222 nvarchar(max)
                        declare @svsab3224 varchar(2)
                        declare @oresult_flag varchar(2) = 'OK';
                        declare @oresult nvarchar(max) = '';
                        
                        -- TODO: Set parameter values here.
                        set @svsab3200 = '${station.workNo}';--作業序號
                        set @svsab3201 = '${station.stationNo}';--站點序號
                        set @svsab3202 = '${station.scheduleDate}';--排程日期
                        set @svsab3204 = '${station.vin}';--車身號碼
                        set @svsab3205 = ${station.vinNo}--點交次數
                        set @svsab3207 = '${Business.userId}';--作業人員
                        set @svsab3222 = '${station.getItemsJson()}';--JSON(第二槍才需要)
                        set @svsab3224 = '02';--作業方法 01:第一槍 02:第二槍
                        
                        execute @rc = [dbo].[spx_xvms_aa32_in] 
                           @svsab3200
                          ,@svsab3201
                          ,@svsab3202
                          ,@svsab3204
                          ,@svsab3205
                          ,@svsab3207
                          ,@svsab3222
                          ,@svsab3224
                          ,@oresult_flag output
                          ,@oresult output
                          
                        if (@oresult_flag = 'NG')
                            begin
                                raiserror(@oresult,16,1);
                            end
                        select @oresult_flag as ORESULT_FLAG,@oresult as ORESULT;
    """, rowSize: 65535);
    }

    if (datagram.commandList.length == 0) {
      _showMessage(ResultFlag.ng, '車身號碼已檢查完成');
      return;
    }

    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      _showMessage(result.flag, '檢查完成');
    } else {
      _showMessage(result.flag, result.getNGMessage());
    }
  }

  void _showMessage(ResultFlag flag, String message) {
    setState(() {
      _messageFlag = flag;
      _message = message;
    });
    CommonMethod.playSound(flag);
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
            Divider(height: 2.0, color: Colors.black),
          ],
        ),
      ),
    );
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
