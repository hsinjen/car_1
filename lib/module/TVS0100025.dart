import 'dart:io';
import 'dart:convert';
import "package:collection/collection.dart";
import 'package:car_1/core/etextbox.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:car_1/business/datagram.dart';
import 'package:car_1/business/responseresult.dart';
import 'package:car_1/apis/messagebox.dart';
import 'package:car_1/business/business.dart';
import 'GeneralFunction.dart';
import '../model/sysMenu.dart';
import 'package:intl/intl.dart';
import '../core/keyvalue.dart';
import '../core/keyboard.dart';
import '../core/valuemanager.dart';
import '../core/ui.dart';
import '../core/utility.dart';

class TVS0100025 extends StatefulWidget {
  State<StatefulWidget> createState() {
    return _TVS0100025State();
  }
}

class _TVS0100025State extends State<TVS0100025> with TickerProviderStateMixin {
  final String moduleId = 'TVS0100025';
  final String moduleName = '底塗作業';
  final GlobalKey<ScaffoldState> _this = new GlobalKey<ScaffoldState>();
  GlobalKey<KeyboardState> _keyboardSession;
  KeyboardAction _keyboardAction = KeyboardAction();
  ValueManager _values = ValueManager.create([
    KeyValue('BUFFER_DATE1', ''),
    KeyValue('BUFFER_DATE2', ''),
    KeyValue('BUFFER_MAINTAIN_ITEM', ''),
    KeyValue('BUFFER_SCAN_VIN', ''),
    KeyValue('BUFFER_VIN', ''), //車身號碼
    KeyValue('BUFFER_VIN_BRAND', ''), //廠牌
    KeyValue('BUFFER_VIN_MODEL', ''), //車款
    KeyValue('BUFFER_VIN_TYPE', ''), //車型
    KeyValue('BUFFER_ARRIVAL_DATE', ''), //到港日
    KeyValue('BUFFER_MESSAGE', ''), //訊息
    KeyValue('BUFFER_GUN', '1'), //第一槍 、第二槍
  ]);
  String _pageKey = 'pageMain';
  bool _isUploading = false;
  List<Map<String, dynamic>> _currentVin = [];
  int _rowIndex = 0;
  //List<Map<String, dynamic>> _dataBuffer;
  List<VinMaintainItem> _vinItems = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getSampleData();

    _values.setValue(
        'BUFFER_DATE1', DateFormat('yyyy/MM/dd').format(DateTime.now()));
    _values.setValue(
        'BUFFER_DATE2', DateFormat('yyyy/MM/dd').format(DateTime.now()));
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    setPage('pageMain');
  }

  void getSampleData() {
    // _dataBuffer = [
    //   {
    //     "VIN": "1HGCR2630DA550011",
    //     "VINNO": "1",
    //     "OPERATION_DATE": "2021-01-01",
    //     "OPEN_DATE": "2020-01-02",
    //     "DAY": 30,
    //     "CONTENT":
    //         '[{"itemId":"01","itemText":"充電","flag":"N","value":"","notnull":"N","updateTime":""},{"itemId":"02","itemText":"鍍鉻作業","flag":"N","value":"","notnull":"Y","updateTime":""}]'
    //   },
    //   {
    //     "VIN": "1HGCR2650DA550138",
    //     "VINNO": "2",
    //     "OPERATION_DATE": "2021-01-30",
    //     "OPEN_DATE": "",
    //     "DAY": 60,
    //     "CONTENT":
    //         '[{"itemId":"01","itemText":"充電","flag":"N","value":"","notnull":"N","updateTime":""},{"itemId":"02","itemText":"鍍鉻作業","flag":"N","value":"","notnull":"Y","updateTime":""}]'
    //   },
    // ];
  }

  Widget getBackButton() {
    if (_pageKey == 'pageMain')
      return Container();
    else
      return Container();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _this,
      resizeToAvoidBottomPadding: false,
      resizeToAvoidBottomInset: false,
      drawer: buildMenu(context),
      appBar: AppBar(
        title: Text(getPageTitle(_pageKey)),
        actions: [],
      ),
      body: _isUploading == true
          ? Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  SizedBox(
                      height: 25,
                      width: MediaQuery.of(context).size.width - 20,
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation(Colors.blue),
                      )),
                  Divider(height: 4),
                  Text(_pageKey == 'pageUpload' ? 'Uploading' : 'Loading')
                ]))
          : getPage(_pageKey),
    );
  }

  //============================================================================ Method
  String getPageTitle(String key) {
    if (key == 'pageMain')
      return '存車維護作業';
    else
      return 'Unknow';
  }

  void setPage(String key) {
    _rowIndex = 0;
    setState(() {
      _isUploading = true;
    });
    setState(() {
      _pageKey = key;
      _isUploading = false;
    });
  }

  Widget getPage(String key) {
    if (key == 'pageMain') {
      return pageMain();
    } else
      return Container();
  }

  //============================================================================ Pages

  //主頁
  Widget pageMain() {
    return Column(
      children: [
        Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                child: Row(
                  // mainAxisAlignment: mainAxisAlignment,
                  children: [
                    Container(
                      width: 60,
                      padding: EdgeInsets.only(left: 3),
                      margin: EdgeInsets.only(right: 10),
                      child: Text('作業日期'),
                    ),
                    ETextBox(
                      text: _values.getValue('BUFFER_DATE1'),
                      emptyText: '作業日期(起)',
                      focus: _keyboardAction.actionName == 'BUFFER_DATE1',
                      width: 110,
                      margin: EdgeInsets.only(right: 3),
                      onClick: () {
                        showDatePickerEx(
                          context,
                          'BUFFER_DATE1',
                          keyboardValueChanged,
                          defaultDate: _values.getValue('BUFFER_DATE1') == ''
                              ? null
                              : new DateFormat('yyyy/MM/dd').parse(
                                  _values.getValue('BUFFER_DATE1'),
                                ),
                        );
                      },
                    ),
                    ETextBox(
                      text: _values.getValue('BUFFER_DATE2'),
                      emptyText: '作業日期(訖)',
                      focus: _keyboardAction.actionName == 'BUFFER_DATE2',
                      width: 110,
                      onClick: () {
                        showDatePickerEx(
                          context,
                          'BUFFER_DATE2',
                          keyboardValueChanged,
                          defaultDate: _values.getValue('BUFFER_DATE2') == ''
                              ? null
                              : new DateFormat('yyyy/MM/dd').parse(
                                  _values.getValue('BUFFER_DATE2'),
                                ),
                        );
                      },
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_values.isEmpty('BUFFER_DATE1') == true ||
                              _values.isEmpty('BUFFER_DATE2') == true) return;
                          Utility.showFullScreenDialog(
                              this.context,
                              TVS0100024Dialog(
                                this.context,
                                '存車維護明細',
                                _values
                                    .getValue('BUFFER_DATE1')
                                    .replaceAll('/', '-'),
                                _values
                                    .getValue('BUFFER_DATE2')
                                    .replaceAll('/', '-'),
                                onConfirm: null,
                                onCancel: null,
                              ));
                        },
                        child: Container(
                          margin: EdgeInsets.only(left: 5),
                          decoration: BoxDecoration(
                            color: Colors.lightBlue[100],
                            border: Border.all(width: 1, color: Colors.black),
                            borderRadius:
                                BorderRadius.all(Radius.circular(4.0)),
                          ),
                          child: SizedBox(
                            height: 28,
                            width: 80,
                            child: Container(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                '明細',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              //================================================================
              Row(
                children: [
                  labelTextBox('維護項目', _values.getValue('BUFFER_MAINTAIN_ITEM'),
                      emptyText: '請選擇維護項目',
                      lableWidth: 60,
                      focus:
                          _keyboardAction.actionName == 'BUFFER_MAINTAIN_ITEM',
                      width: MediaQuery.of(context).size.width - 75,
                      mainAxisAlignment: MainAxisAlignment.start,
                      margin: EdgeInsets.only(bottom: 5, top: 5), onClick: () {
                    setState(() {
                      _loadMaintainItem();
                    });
                  }),
                ],
              ),

              //================================================================
              Row(
                children: [
                  labelTextBox('車身號碼', _values.getValue('BUFFER_SCAN_VIN'),
                      emptyText: '掃描車身號碼',
                      lableWidth: 60,
                      focus: _keyboardAction.actionName == 'BUFFER_SCAN_VIN',
                      width: MediaQuery.of(context).size.width - 75,
                      mainAxisAlignment: MainAxisAlignment.start,
                      margin: EdgeInsets.only(bottom: 5, top: 5), onClick: () {
                    // if (_values.isEmpty('BUFFER_DATE1') == true ||
                    //     _values.isEmpty('BUFFER_DATE2') == true) {
                    //   _showMessage(ResultFlag.ng, '請輸入作業日期');
                    //   return;
                    // } else
                    if (_values.isEmpty('BUFFER_MAINTAIN_ITEM') == true) {
                      _showMessage(ResultFlag.ng, '請選擇維護項目');
                      return;
                    }

                    setState(() {
                      _keyboardAction.showScanner('BUFFER_SCAN_VIN');
                    });
                  }),
                ],
              ),
              //================================================================
              Container(
                margin: EdgeInsets.only(bottom: 5),
                child: Row(
                  // mainAxisAlignment: mainAxisAlignment,
                  children: [
                    Container(
                      width: 60,
                      padding: EdgeInsets.only(left: 3),
                      margin: EdgeInsets.only(right: 10),
                      child: Text(
                        '廠牌',
                        textAlign: TextAlign.right,
                      ),
                    ),
                    ETextBox(
                      text: _values.getValue('BUFFER_VIN_BRAND'),
                      emptyText: '廠牌',
                      width: 120,
                      margin: EdgeInsets.only(right: 3),
                    ),
                    Container(
                      width: 45,
                      padding: EdgeInsets.only(left: 3),
                      margin: EdgeInsets.only(right: 10),
                      child: Text(
                        '車款',
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      child: ETextBox(
                        text: _values.getValue('BUFFER_VIN_MODEL'),
                        emptyText: '車款',
                        width: 120,
                        margin: EdgeInsets.only(right: 3),
                      ),
                    ),
                  ],
                ),
              ),
              //================================================================
              Container(
                child: Row(
                  // mainAxisAlignment: mainAxisAlignment,
                  children: [
                    Container(
                      width: 60,
                      padding: EdgeInsets.only(left: 3),
                      margin: EdgeInsets.only(right: 10),
                      child: Text(
                        '車型',
                        textAlign: TextAlign.right,
                      ),
                    ),
                    ETextBox(
                      text: _values.getValue('BUFFER_VIN_TYPE'),
                      emptyText: '車型',
                      width: 120,
                      margin: EdgeInsets.only(right: 3),
                    ),
                    Container(
                      width: 45,
                      padding: EdgeInsets.only(left: 3),
                      margin: EdgeInsets.only(right: 10),
                      child: Text(
                        '到港日',
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      child: ETextBox(
                        text: _values.getValue('BUFFER_ARRIVAL_DATE'),
                        emptyText: '到港日',
                        width: 120,
                        margin: EdgeInsets.only(right: 3),
                      ),
                    ),
                  ],
                ),
              ),
              //================================================================
              Container(
                child: Center(
                  child: Text(_values.getValue('BUFFER_VIN'),
                      style: TextStyle(color: Colors.blue, fontSize: 32)),
                ),
              ),
              //================================================================
            ],
          ),
        ),
        _currentVin.length == 0
            ? Expanded(child: Text('沒有任何資料'))
            : Expanded(
                child: ListView.builder(
                    itemCount: _currentVin.length,
                    //itemExtent: 35.0,
                    itemBuilder: (BuildContext context, int index) {
                      return vinItem(_currentVin[index]);
                    }),
              ),
        _keyboardAction.actionName == ''
            ? Container()
            : Keyboard(
                key: _keyboardSession,
                config: _keyboardAction,
                onValueChanged: keyboardValueChanged,
                onTextChanged: keyboardTextChanged,
                onNotify: keyboardNotify,
              ),
      ],
    );
  }

  Widget vinItem(Map<String, dynamic> data) {
    print(data['作業內容']);
    if (data['作業內容'] == '') return Container();

    List<VinMaintainItem> buffer = (json.decode(data['作業內容']) as List)
        .map((i) => VinMaintainItem.fromJson(
            data['車身號碼'], data['點交次數'].toString(), data['作業日期'], i))
        .toList();
    _vinItems.removeWhere((element) =>
        element.vin == data['車身號碼'] &&
        element.vinNo == data['點交次數'].toString() &&
        element.operationDate == data['作業日期'].toString());
    _vinItems.addAll(buffer);

    List<Widget> bufferWidget = [];
    bufferWidget.add(Container(
      child: Row(
        children: [
          SizedBox(
            height: 40,
            child: Container(
                // color: Colors.red,
                child: IconButton(
              padding: EdgeInsets.all(0),
              icon: Icon(
                buffer.where((element) => element.flag == 'Y').length == 0
                    ? Icons.check_circle_outline
                    : Icons.check_circle,
                color:
                    buffer.where((element) => element.flag == 'Y').length == 0
                        ? Colors.grey
                        : Colors.green,
              ),
              onPressed: () async {
                if (buffer.where((element) => element.flag == 'Y').length > 0) {
                  buffer.forEach((element) {
                    element.flag = 'N';
                    element.updateTime = DateFormat('yyyy-MM-dd HH:mm:ss')
                        .format(DateTime.now());
                  });
                } else {
                  buffer.forEach((element) {
                    element.flag = 'Y';
                    element.updateTime = DateFormat('yyyy-MM-dd HH:mm:ss')
                        .format(DateTime.now());
                  });
                }
                List<VinMaintainItem> rResult = _vinItems
                    .where((v) =>
                        v.vin == data['車身號碼'] &&
                        v.vinNo == data['點交次數'].toString() &&
                        v.operationDate == data['作業日期'])
                    .toList();
                String jsonResult = json.encode(rResult);
                bool y1 = await _closeVin(
                    data['車身號碼'],
                    data['點交次數'].toString(),
                    _values.getValue('BUFFER_MAINTAIN_ITEM'),
                    data['作業日期'],
                    jsonResult);
                if (y1 == true) {
                  setState(() {
                    _currentVin.firstWhere((v) =>
                        v['車身號碼'] == data['車身號碼'] &&
                        v['點交次數'].toString() == data['點交次數'].toString() &&
                        v['作業日期'] == data['作業日期'])['作業內容'] = jsonResult;
                  });
                }
              },
            )),
          ),
          labelTextBox(
            '作業日',
            data['作業日期'],
            emptyText: '作業日期',
            lableWidth: 45,
            width: 90,
            mainAxisAlignment: MainAxisAlignment.start,
            margin: EdgeInsets.only(bottom: 5, top: 5),
          ),
          Expanded(
            child: labelTextBox('開工日', data['開工日期'],
                emptyText: '未開工',
                lableWidth: 50,
                width: 90,
                mainAxisAlignment: MainAxisAlignment.start,
                margin: EdgeInsets.only(bottom: 5, top: 5), onClick: () async {
              if (data['開工旗標'] == 'N') {
                DialogResult r1 = await DialogBox.showQuestion(
                    context, '\n確定開工\n',
                    title: data['車身號碼'], button1Text: '是', button2Text: '否');
                if (r1 == DialogResult.yes) {
                  bool y1 = await _openVin(
                      data['車身號碼'],
                      data['點交次數'].toString(),
                      _values.getValue('BUFFER_MAINTAIN_ITEM'),
                      data['作業日期']);
                  if (y1 == true) {
                    setState(() {
                      data['開工旗標'] = 'Y';
                      data['開工日期'] =
                          DateFormat('yyyy-MM-dd').format(DateTime.now());
                    });
                  }
                }
              }
            }),
          ),
        ],
      ),
    ));

    for (int i = 0; i < buffer.length; i++) {
      bufferWidget.add(Row(children: [
        SizedBox(
          height: 40,
          child: Container(
              child: IconButton(
            padding: EdgeInsets.all(0),
            icon: Icon(
              buffer[i].flag == 'N'
                  ? Icons.check_circle_outline
                  : Icons.check_circle,
              color: buffer[i].flag == 'N' ? Colors.grey : Colors.green,
            ),
            onPressed: () async {
              VinMaintainItem item = _vinItems.firstWhere((v) =>
                  v.vin == buffer[i].vin &&
                  v.vinNo == buffer[i].vinNo &&
                  v.operationDate == buffer[i].operationDate &&
                  v.itemId == buffer[i].itemId);
              item.flag = (item.flag == 'Y' ? 'N' : 'Y');
              item.updateTime =
                  DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
              List<VinMaintainItem> rResult = _vinItems
                  .where((v) =>
                      v.vin == buffer[i].vin &&
                      v.vinNo == buffer[i].vinNo &&
                      v.operationDate == buffer[i].operationDate)
                  .toList();

              String jsonResult = json.encode(rResult);
              bool y1 = await _closeVin(
                  buffer[i].vin,
                  buffer[i].vinNo,
                  _values.getValue('BUFFER_MAINTAIN_ITEM'),
                  buffer[i].operationDate,
                  jsonResult);
              if (y1 == true) {
                setState(() {
                  _currentVin.firstWhere((v) =>
                          v['車身號碼'] == buffer[i].vin &&
                          v['點交次數'].toString() == buffer[i].vinNo &&
                          v['作業日期'] == buffer[i].operationDate)['作業內容'] =
                      jsonResult;
                });
              }
            },
          )),
        ),
        Container(
          padding: EdgeInsets.only(left: 3),
          margin: EdgeInsets.only(right: 10),
          width: 20,
          child: Text(
            buffer[i].itemId,
            softWrap: false,
          ),
        ),
        Container(
          padding: EdgeInsets.only(left: 3),
          margin: EdgeInsets.only(right: 10),
          width: 120,
          child: Text(
            buffer[i].itemText,
            softWrap: false,
          ),
        ),
        Expanded(
            child: ETextBox(
          text: buffer[i].value,
          emptyText: '作業內容',
          width: 120,
          margin: EdgeInsets.only(right: 3),
          onClick: () async {
            var r = await DialogBox.showText(
              context,
              buffer[i].itemText,
              content: buffer[i].value,
              button1Text: "確定",
              button2Text: "取消",
            );
            VinMaintainItem item = _vinItems.firstWhere((v) =>
                v.vin == buffer[i].vin &&
                v.vinNo == buffer[i].vinNo &&
                v.operationDate == buffer[i].operationDate &&
                v.itemId == buffer[i].itemId);

            item.value = r;
            item.flag = 'Y';
            item.updateTime =
                DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

            List<VinMaintainItem> rResult = _vinItems
                .where((v) =>
                    v.vin == buffer[i].vin &&
                    v.vinNo == buffer[i].vinNo &&
                    v.operationDate == buffer[i].operationDate)
                .toList();

            String jsonResult = json.encode(rResult);
            bool y1 = await _closeVin(
                buffer[i].vin,
                buffer[i].vinNo,
                _values.getValue('BUFFER_MAINTAIN_ITEM'),
                buffer[i].operationDate,
                jsonResult);
            if (y1 == true) {
              setState(() {
                _currentVin.firstWhere((v) =>
                    v['車身號碼'] == buffer[i].vin &&
                    v['點交次數'].toString() == buffer[i].vinNo &&
                    v['作業日期'] == buffer[i].operationDate)['作業內容'] = jsonResult;
              });
            }
          },
        ))
      ]));
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8, left: 3, right: 3),
      decoration: BoxDecoration(
        //color: Colors.lightBlue[100],
        border: Border.all(width: 2, color: Colors.black),
        borderRadius: BorderRadius.all(Radius.circular(4.0)),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        child: Column(children: bufferWidget),
      ),
      //=====================================================
    );
  }

  Future<void> _loadMaintainItem() async {
    Datagram datagram = Datagram();
    datagram.addText("""select distinct vsac3210 from xvms_ac32""");
    ResponseResult r = await Business.apiExecuteDatagram(datagram);
    if (r.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> _dataList = r.getMap();
      List<Widget> _list = [];

      for (int i = 0; i < _dataList.length; i++) {
        _list.add(
          CupertinoActionSheetAction(
            child: Text(_dataList[i]['vsac3210']),
            onPressed: () {
              keyboardValueChanged(
                  'BUFFER_MAINTAIN_ITEM', _dataList[i]['vsac3210']);
              Navigator.pop(context);
            },
          ),
        );
      }
      //for end
      final action = CupertinoActionSheet(
        title: Text(
          "維護項目",
          style: TextStyle(fontSize: 18),
        ),
        // message: Text(
        //   "選擇其中一台車身",
        //   style: TextStyle(fontSize: 15.0),
        // ),
        actions: _list,
        cancelButton: CupertinoActionSheetAction(
          child: Text("取消"),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      );
      showCupertinoModalPopup(context: context, builder: (context) => action);
    }
  }

  Future<List<Map<String, dynamic>>> _loadVin(String vin) async {
    Datagram datagram = Datagram();
    datagram.addText("""select x1.vsac3200 as 車身號碼,
                               x1.vsac3201 as 點交次數,
                               x2.進口商名稱,
                               x2.廠牌名稱,
                               x2.車款名稱,
                               x2.車型名稱,
                               x1.vsac3206 as 到港日期,
                               x1.vsac3207 as 覆進日期,
                               x1.vsac3208 as 點交日期,
                               x1.vsac3209 as 出廠日期,
                               x1.vsac3211 as 天數,
                               x1.vsac3212 as 作業日期,
                               x1.vsac3216 as 備註,
                               x1.vsac3217 as 開工日期,
                               x1.vsac3222 as 作業內容,
                               iif(x1.vsac3217 = '','N','Y') as 開工旗標
                        from xvms_ac32 as x1 left join vi_xvms_0001_04 as x2 on x1.vsac3202 = x2.進口商系統碼 and
                                                                                x1.vsac3203 = x2.廠牌系統碼 and
                                                                                x1.vsac3204 = x2.車款系統碼 and
                                                                                x1.vsac3205 = x2.系統碼
                        where --(x1.vsac3212 between '${_values.getValue('BUFFER_DATE1')}' and '${_values.getValue('BUFFER_DATE2')}') and
                              --x1.vsac3219 = '' and
                              x1.vsac3210 = '${_values.getValue('BUFFER_MAINTAIN_ITEM')}' and
                              x1.vsac3200 like '%$vin'
                              order by x1.vsac3212 desc""");
    ResponseResult r = await Business.apiExecuteDatagram(datagram);
    if (r.flag == ResultFlag.ng)
      return null;
    else
      return r.getMap();
  }

  Future<bool> _openVin(
      String vin, String vinNo, String mainItem, String operationDate) async {
    Datagram datagram = Datagram();
    datagram
        .addText("""update xvms_ac32 set vsac3214 = entirev4.dbo.systemdate(),
                                         vsac3217 = entirev4.dbo.systemdate(),
                                         vsac3218 = entirev4.dbo.systemtime(),
                                         vsac3219 = entirev4.dbo.systemdate(),
                                         vsac3220 = entirev4.dbo.systemtime(),
                                         vsac3221 = '${Business.userId}'
                    where vsac3200 = '$vin' and vsac3201 = $vinNo and vsac3210 = '$mainItem' and vsac3212 = '$operationDate' and
                          vsac3217 = ''""");
    ResponseResult r = await Business.apiExecuteDatagram(datagram);
    if (r.flag == ResultFlag.ng)
      return false;
    else
      return true;
  }

  Future<bool> _closeVin(String vin, String vinNo, String mainItem,
      String operationDate, String items) async {
    Datagram datagram = Datagram();
    datagram
        .addText("""update xvms_ac32 set vsac3214 = entirev4.dbo.systemdate(),
                                         vsac3219 = entirev4.dbo.systemdate(),
                                         vsac3220 = entirev4.dbo.systemtime(),
                                         vsac3221 = '${Business.userId}',
                                         vsac3222 = '$items'
                    where vsac3200 = '$vin' and vsac3201 = $vinNo and vsac3210 = '$mainItem' and vsac3212 = '$operationDate'""");
    ResponseResult r = await Business.apiExecuteDatagram(datagram);
    if (r.flag == ResultFlag.ng)
      return false;
    else
      return true;
  }

  //顯示多車身選擇
  void showVinActionSheet(List<Map<String, dynamic>> dataList) {
    if (dataList == null) return;
    List<Widget> _list = [];

    for (int i = 0; i < dataList.length; i++) {
      _list.add(CupertinoActionSheetAction(
        child: Text(dataList[i]['車身號碼']),
        onPressed: () {
          keyboardValueChanged('BUFFER_SCAN_VIN', dataList[i]['車身號碼']);
          Navigator.pop(context);
        },
      ));
    }

    final action = CupertinoActionSheet(
      title: Text(
        "車身號碼",
        style: TextStyle(fontSize: 18),
      ),
      message: Text(
        "選擇車身",
        style: TextStyle(fontSize: 15.0),
      ),
      actions: _list,
      cancelButton: CupertinoActionSheetAction(
        child: Text("取消"),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
    showCupertinoModalPopup(context: context, builder: (context) => action);
  }

  void _showMessage(ResultFlag flag, String message) {
    _this.currentState.showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: flag == ResultFlag.ok ? Colors.green : Colors.red,
    ));
  }

  //============================================================================ Event
  void keyboardValueChanged(String actionName, String value) async {
    print('value changed: action: $actionName value: $value');
    value = value.toUpperCase();
    Map<String, String> barcodeResult;

//  KeyValue('BUFFER_MAINTAIN_ITEM', ''),
//     KeyValue('BUFFER_SCAN_VIN', ''),
//     KeyValue('BUFFER_VIN', ''),//車身號碼
//     KeyValue('BUFFER_VIN_BRAND', ''), //廠牌
//     KeyValue('BUFFER_VIN_MODEL', ''), //車款
//     KeyValue('BUFFER_VIN_TYPE', ''),  //車型
//     KeyValue('BUFFER_ARRIVAL_DATE',''),//到港日
//     KeyValue('BUFFER_MESSAGE', ''),
    if (actionName == 'BUFFER_DATE1' || actionName == 'BUFFER_DATE2') {
      _values.clearValue('BUFFER_MAINTAIN_ITEM');
      _values.clearValue('BUFFER_SCAN_VIN');
      _values.clearValue('BUFFER_VIN');
      _values.clearValue('BUFFER_VIN_BRAND');
      _values.clearValue('BUFFER_VIN_MODEL');
      _values.clearValue('BUFFER_VIN_TYPE');
      _values.clearValue('BUFFER_ARRIVAL_DATE');
      _values.clearValue('BUFFER_MESSAGE');
      _values.setValue('BUFFER_GUN', '1');
    } else if (actionName == 'BUFFER_MAINTAIN_ITEM') {
      _values.clearValue('BUFFER_SCAN_VIN');
      _values.clearValue('BUFFER_VIN');
      _values.clearValue('BUFFER_VIN_BRAND');
      _values.clearValue('BUFFER_VIN_MODEL');
      _values.clearValue('BUFFER_VIN_TYPE');
      _values.clearValue('BUFFER_ARRIVAL_DATE');
      _values.clearValue('BUFFER_MESSAGE');
      _values.setValue('BUFFER_GUN', '1');
      _keyboardAction.showScanner('BUFFER_SCAN_VIN');
    } else if (actionName == 'BUFFER_SCAN_VIN') {
      List<Map<String, dynamic>> _data1 = await _loadVin(value);
      bool multiVin =
          groupBy(_data1, (obj) => obj['車身號碼']).length > 1 ? true : false;

      if (_data1 == null || _data1.length == 0) {
        _values.setValue('BUFFER_GUN', '1');
        _values.clearValue('BUFFER_VIN');
        _values.clearValue('BUFFER_VIN_BRAND');
        _values.clearValue('BUFFER_VIN_MODEL');
        _values.clearValue('BUFFER_VIN_TYPE');
        _values.clearValue('BUFFER_ARRIVAL_DATE');
        _values.clearValue('BUFFER_MESSAGE');
        _showMessage(ResultFlag.ng, '無效的車身號碼 $value');
        _currentVin = [];
        _vinItems = [];
        _keyboardAction.showScanner('BUFFER_SCAN_VIN');
      } else {
        if (multiVin == true) {
          _values.setValue('BUFFER_GUN', '1');
          _values.clearValue('BUFFER_VIN');
          _values.clearValue('BUFFER_VIN_BRAND');
          _values.clearValue('BUFFER_VIN_MODEL');
          _values.clearValue('BUFFER_VIN_TYPE');
          _values.clearValue('BUFFER_ARRIVAL_DATE');
          _values.clearValue('BUFFER_MESSAGE');
          _currentVin = [];
          _vinItems = [];
          showVinActionSheet(_data1);
          return;
        } else {
          _currentVin = _data1;
          _values.setValue('BUFFER_GUN',
              _values.getValue('BUFFER_VIN') != _data1[0]['車身號碼'] ? '1' : '2');
          _values.setValue('BUFFER_VIN', _data1[0]['車身號碼']);
          _values.setValue('BUFFER_VIN_BRAND', _data1[0]['廠牌名稱']);
          _values.setValue('BUFFER_VIN_MODEL', _data1[0]['車款名稱']);
          _values.setValue('BUFFER_VIN_TYPE', _data1[0]['車型名稱']);
          _values.setValue('BUFFER_ARRIVAL_DATE', _data1[0]['到港日期']);
        }
      }
    }

    setState(() {
      _values.setValue(actionName, value.toUpperCase());
    });
  }

  void keyboardTextChanged(String actionName, String value) async {
    print('text changed: action: $actionName value: $value');

    setState(() {
      _values.setValue(actionName, value.toUpperCase());
    });
  }

  void keyboardNotify() {
    setState(() {
      _keyboardAction = _keyboardAction;
    });
  }
}

//=============================================================================
class VinMaintainItem {
  final String vin;
  final String vinNo;
  final String operationDate;
  final String itemId;
  final String itemText;
  final String notNull;
  String flag;
  String value;
  String updateTime;

  VinMaintainItem(this.vin, this.vinNo, this.operationDate, this.itemId,
      this.itemText, this.notNull,
      {String flag = 'N', String value = '', String updateTime = ''}) {
    this.flag = flag;
    this.value = value;
    this.updateTime = updateTime;
  }

  Map<String, dynamic> toJson() => {
        'itemId': this.itemId,
        'itemText': this.itemText,
        'flag': this.flag,
        'value': this.value,
        'notnull': this.notNull,
        'updateTime': this.updateTime
      };

  factory VinMaintainItem.fromJson(String vin, String vinNo,
      String operationDate, Map<String, dynamic> parsedJson) {
    return VinMaintainItem(vin, vinNo, operationDate, parsedJson['itemId'],
        parsedJson['itemText'], parsedJson['notnull'],
        flag: parsedJson['flag'],
        value: parsedJson['value'],
        updateTime: parsedJson['updateTime']);
  }
}

//=============================================================================
class TVS0100024Dialog extends StatelessWidget {
  final BuildContext parentContext;
  final String title;
  final String beginDate; //作業日期起
  final String endDate; //作業日期訖
  final Function(dynamic v) onConfirm;
  final Function(dynamic v) onCancel;

  TVS0100024Dialog(
    this.parentContext,
    this.title,
    this.beginDate,
    this.endDate, {
    this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: this.title,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: TVS0100024DialogPage(
        parentContext: this.parentContext,
        title: this.title,
        beginDate: this.beginDate,
        endDate: this.endDate,
        onConfirm: this.onConfirm,
        onCancel: this.onCancel,
      ),
    );
  }
}

// ignore: must_be_immutable
class TVS0100024DialogPage extends StatefulWidget {
  TVS0100024DialogPage(
      {Key key,
      this.parentContext,
      this.title,
      this.beginDate,
      this.endDate,
      this.onConfirm,
      this.onCancel})
      : super(key: key);
  final BuildContext parentContext;
  final String title;
  final String beginDate; //作業日期起
  final String endDate; //作業日期訖
  final Function(dynamic v) onConfirm;
  final Function(dynamic v) onCancel;

  @override
  _TVS0100024DialogPageState createState() => _TVS0100024DialogPageState();
}

class _TVS0100024DialogPageState extends State<TVS0100024DialogPage> {
  final GlobalKey<ScaffoldState> _this = new GlobalKey<ScaffoldState>();
  //鍵盤變更數
  GlobalKey<KeyboardState> _keyboardSession;
  //鍵盤動作配置設定
  KeyboardAction _keyboardAction = KeyboardAction();
  //該頁面參數值管理
  ValueManager _values = ValueManager.create([
    KeyValue('BUFFER_FLOW', '1'),
    KeyValue('BUFFER_MAINTAIN_ITEM', ''),
    KeyValue('BUFFER_OPERATION_DATE', ''),
    KeyValue('BUFFER_VIN_BRAND', ''), //廠牌
    KeyValue('BUFFER_VIN_MODEL', ''), //車款
    KeyValue('BUFFER_VIN_TYPE', ''), //車型
    KeyValue('MESSAGE', ''),
  ]);
  List<Map<String, dynamic>> _dataBuffer = [];
  bool _isTransfer = true;

  @override
  void initState() {
    super.initState();
    _keyboardSession = GlobalKey();
    _loadPage1();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _this,
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          //
          int.parse(_values.getValue('BUFFER_FLOW')) > 1
              ? IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    int currFlow = int.parse(_values.getValue('BUFFER_FLOW'));
                    setState(() {
                      _values.setValue(
                          'BUFFER_FLOW', (currFlow - 1).toString());
                      _isTransfer = true;
                    });
                    if (currFlow == 2)
                      _loadPage1();
                    else if (currFlow == 3) _loadPage2();
                  })
              : Container(),
          //
          widget.onConfirm != null
              ? IconButton(
                  icon: Icon(Icons.save),
                  onPressed: () {
                    if (widget.onConfirm != null) widget.onConfirm(null);
                    Navigator.of(widget.parentContext).pop();
                  })
              : Container(),
          //
          widget.onCancel != null ||
                  (widget.onConfirm == null && widget.onCancel == null)
              ? IconButton(
                  icon: Icon(Icons.cancel),
                  onPressed: () {
                    if (widget.onCancel != null) widget.onCancel(null);
                    Navigator.of(widget.parentContext).pop();
                  })
              : Container(),
        ],
      ),
      body: MediaQuery.of(context).orientation == Orientation.portrait
          ? portraitPage()
          : landscapePage(),
    );
  }

  //直版
  Widget portraitPage() {
    return _isTransfer == true
        ? Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(
                height: 25,
                width: MediaQuery.of(context).size.width - 20,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(Colors.blue),
                )),
            Divider(height: 4),
            Text('Loading')
          ]))
        : Column(
            children: [
              _dataBuffer.length == 0
                  ? Center(child: Text('沒有任何資料'))
                  : getPage()
            ],
          );
  }

  //橫版
  Widget landscapePage() {
    return Container();
  }

  Widget getPage() {
    if (_values.getValue('BUFFER_FLOW') == '1') {
      return Expanded(
        child: Column(children: <Widget>[
          Container(
              decoration: new BoxDecoration(
                  border: new Border.all(color: Colors.grey, width: 0.5)),
              width: Business.deviceWidth(context),
              child: Row(
                children: <Widget>[
                  Container(
                      padding: EdgeInsets.only(left: 0),
                      width: 80,
                      child: Text(
                        '作業日期',
                        style: TextStyle(color: Colors.white),
                      ),
                      color: Colors.black),
                  Expanded(
                    child: Container(
                        padding: EdgeInsets.only(left: 0),
                        child: Text(
                          '維護項目',
                          style: TextStyle(color: Colors.white),
                        ),
                        color: Colors.black),
                  ),
                  Container(
                      padding: EdgeInsets.only(right: 0),
                      width: 40,
                      child: Text(
                        '台',
                        style: TextStyle(color: Colors.white),
                      ),
                      color: Colors.black),
                ],
              )),
          Expanded(
            child: ListView.builder(
                itemCount: _dataBuffer.length,
                itemExtent: 35.0,
                itemBuilder: (BuildContext context, int index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _values.setValue('BUFFER_FLOW', '2');
                        _values.setValue('BUFFER_OPERATION_DATE',
                            _dataBuffer[index]['作業日期']);
                        _values.setValue(
                            'BUFFER_MAINTAIN_ITEM', _dataBuffer[index]['維護項目']);
                        _isTransfer = true;
                      });
                      _loadPage2();
                    },
                    child: Container(
                      decoration: new BoxDecoration(
                          border:
                              new Border.all(color: Colors.grey, width: 0.5)),
                      width: Business.deviceWidth(context),
                      child: Row(
                        children: <Widget>[
                          Container(
                            padding: EdgeInsets.only(left: 0),
                            width: 80,
                            child: Text(_dataBuffer[index]['作業日期']),
                          ),
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.only(left: 0),
                              child: Text(_dataBuffer[index]['維護項目']),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(right: 0),
                            width: 40,
                            child: Text(_dataBuffer[index]['台'].toString()),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
          ),
        ]),
      );
    } else if (_values.getValue('BUFFER_FLOW') == '2') {
      return Expanded(
        child: Column(children: <Widget>[
          Container(
              decoration: new BoxDecoration(
                  border: new Border.all(color: Colors.grey, width: 0.5)),
              width: Business.deviceWidth(context),
              child: Row(
                children: <Widget>[
                  Container(
                      padding: EdgeInsets.only(left: 0),
                      width: 80,
                      child: Text(
                        '廠牌',
                        style: TextStyle(color: Colors.white),
                      ),
                      color: Colors.black),
                  Container(
                      padding: EdgeInsets.only(left: 0),
                      width: 140,
                      child: Text(
                        '車款',
                        style: TextStyle(color: Colors.white),
                      ),
                      color: Colors.black),
                  Expanded(
                    child: Container(
                        padding: EdgeInsets.only(left: 0),
                        child: Text(
                          '車型',
                          style: TextStyle(color: Colors.white),
                        ),
                        color: Colors.black),
                  ),
                  Container(
                      padding: EdgeInsets.only(right: 0),
                      width: 40,
                      child: Text(
                        '台',
                        style: TextStyle(color: Colors.white),
                      ),
                      color: Colors.black),
                ],
              )),
          Expanded(
            child: ListView.builder(
                itemCount: _dataBuffer.length,
                itemExtent: 35.0,
                itemBuilder: (BuildContext context, int index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _values.setValue('BUFFER_FLOW', '3');
                        _values.setValue(
                            'BUFFER_VIN_BRAND', _dataBuffer[index]['廠牌名稱']);
                        _values.setValue(
                            'BUFFER_VIN_MODEL', _dataBuffer[index]['車款名稱']);
                        _values.setValue(
                            'BUFFER_VIN_TYPE', _dataBuffer[index]['車型名稱']);
                        _isTransfer = true;
                      });
                      _loadPage3();
                    },
                    child: Container(
                      decoration: new BoxDecoration(
                          border:
                              new Border.all(color: Colors.grey, width: 0.5)),
                      width: Business.deviceWidth(context),
                      child: Row(
                        children: <Widget>[
                          Container(
                            padding: EdgeInsets.only(left: 0),
                            width: 80,
                            child: Text(_dataBuffer[index]['廠牌名稱']),
                          ),
                          Container(
                            padding: EdgeInsets.only(left: 0),
                            width: 140,
                            child: Text(_dataBuffer[index]['車款名稱']),
                          ),
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.only(left: 0),
                              child: Text(_dataBuffer[index]['車型名稱']),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(right: 0),
                            width: 40,
                            child: Text(_dataBuffer[index]['台'].toString()),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
          ),
        ]),
      );
    } else if (_values.getValue('BUFFER_FLOW') == '3') {
      return Expanded(
        child: Column(children: <Widget>[
          Container(
              decoration: new BoxDecoration(
                  border: new Border.all(color: Colors.grey, width: 0.5)),
              width: Business.deviceWidth(context),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Container(
                        padding: EdgeInsets.only(left: 0),
                        child: Text(
                          '車身號碼',
                          style: TextStyle(color: Colors.white),
                        ),
                        color: Colors.black),
                  ),
                  Container(
                      padding: EdgeInsets.only(left: 0),
                      width: 80,
                      child: Text(
                        '到港日期',
                        style: TextStyle(color: Colors.white),
                      ),
                      color: Colors.black),
                  Container(
                      padding: EdgeInsets.only(right: 0),
                      width: 80,
                      child: Text(
                        '開工日期',
                        style: TextStyle(color: Colors.white),
                      ),
                      color: Colors.black),
                ],
              )),
          Expanded(
            child: ListView.builder(
                itemCount: _dataBuffer.length,
                itemExtent: 35.0,
                itemBuilder: (BuildContext context, int index) {
                  return GestureDetector(
                    onTap: () {
                      //
                    },
                    child: Container(
                      decoration: new BoxDecoration(
                          border:
                              new Border.all(color: Colors.grey, width: 0.5)),
                      width: Business.deviceWidth(context),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.only(left: 0),
                              child: Text(_dataBuffer[index]['車身號碼']),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(left: 0),
                            width: 80,
                            child: Text(_dataBuffer[index]['到港日期']),
                          ),
                          Container(
                            padding: EdgeInsets.only(left: 0),
                            width: 80,
                            child: Text(_dataBuffer[index]['開工日期']),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
          ),
        ]),
      );
    } else
      return Container(child: Text('Page not found'));
  }

  //============================================================================
  Future<void> _loadPage1() async {
    Datagram datagram = Datagram();
    datagram.addText("""select x1.vsac3212 as 作業日期,
                                x1.vsac3210 as 維護項目,
                                count(*) as 台
                         from xvms_ac32 as x1
                         where (x1.vsac3212 between '${widget.beginDate}' and '${widget.endDate}') and
                                x1.vsac3219 = ''
                         group by x1.vsac3212,x1.vsac3210
                         order by x1.vsac3212""");
    ResponseResult r = await Business.apiExecuteDatagram(datagram);
    if (r.flag == ResultFlag.ok) _dataBuffer = r.getMap();
    setState(() {
      _isTransfer = false;
    });
  }

  Future<void> _loadPage2() async {
    Datagram datagram = Datagram();
    datagram.addText("""select x2.廠牌名稱,
                               x2.車款名稱,
                               x2.車型名稱,
                               count(*) as 台
                        from xvms_ac32 as x1 left join vi_xvms_0001_04 as x2 on x1.vsac3202 = x2.進口商系統碼 and
                                                                                x1.vsac3203 = x2.廠牌系統碼 and
                                                                                x1.vsac3204 = x2.車款系統碼 and
                                                                                x1.vsac3205 = x2.系統碼
                        where (x1.vsac3212 between '${widget.beginDate}' and '${widget.endDate}') and
                               x1.vsac3219 = '' and
                               x1.vsac3212 = '${_values.getValue('BUFFER_OPERATION_DATE')}' and
                               x1.vsac3210 = '${_values.getValue('BUFFER_MAINTAIN_ITEM')}'
                        group by x2.廠牌名稱,
                                 x2.車款名稱,
                                 x2.車型名稱
                        order by x2.廠牌名稱""");
    ResponseResult r = await Business.apiExecuteDatagram(datagram);
    if (r.flag == ResultFlag.ok) _dataBuffer = r.getMap();
    setState(() {
      _isTransfer = false;
    });
  }

  Future<void> _loadPage3() async {
    Datagram datagram = Datagram();
    datagram.addText("""select x1.vsac3200 as 車身號碼,
                               x1.vsac3201 as 點交次數,
                               x1.vsac3206 as 到港日期,
                               x1.vsac3207 as 覆進日期,
                               x1.vsac3208 as 點交日期,
                               x1.vsac3209 as 出廠日期,
                               x1.vsac3217 as 開工日期
                        from xvms_ac32 as x1 left join vi_xvms_0001_04 as x2 on x1.vsac3202 = x2.進口商系統碼 and
                                                                                x1.vsac3203 = x2.廠牌系統碼 and
                                                                                x1.vsac3204 = x2.車款系統碼 and
                                                                                x1.vsac3205 = x2.系統碼
                        where (x1.vsac3212 between '${widget.beginDate}' and '${widget.endDate}') and
                               x1.vsac3219 = '' and
                               x1.vsac3212 = '${_values.getValue('BUFFER_OPERATION_DATE')}' and
                               x1.vsac3210 = '${_values.getValue('BUFFER_MAINTAIN_ITEM')}' and
                               x2.廠牌名稱 = '${_values.getValue('BUFFER_VIN_BRAND')}' and
                               x2.車款名稱 = '${_values.getValue('BUFFER_VIN_MODEL')}' and
                               x2.車型名稱 = '${_values.getValue('BUFFER_VIN_TYPE')}'""");
    ResponseResult r = await Business.apiExecuteDatagram(datagram);
    if (r.flag == ResultFlag.ok) _dataBuffer = r.getMap();
    setState(() {
      _isTransfer = false;
    });
  }

  //============================================================================ Keyboard Event
  void keyboardValueChanged(String actionName, String value) async {
    print('value changed: action: $actionName value: $value');

    setState(() {
      _values.setValue(actionName, value);
    });
  }

  void keyboardTextChanged(String actionName, String value) async {
    print('text changed: action: $actionName value: $value');

    setState(() {
      _values.setValue(actionName, value);
    });
  }

  void keyboardNotify() {
    setState(() {
      _keyboardAction = _keyboardAction;
    });
  }
}

//=============================================================================
class TVS0100024InputDialog extends StatelessWidget {
  final BuildContext parentContext;
  final String title;
  final Function(dynamic v) onConfirm;
  final Function(dynamic v) onCancel;

  TVS0100024InputDialog(
    this.parentContext,
    this.title, {
    this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: this.title,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: TVS0100024InputDialogPage(
        parentContext: this.parentContext,
        title: this.title,
        onConfirm: this.onConfirm,
        onCancel: this.onCancel,
      ),
    );
  }
}

// ignore: must_be_immutable
class TVS0100024InputDialogPage extends StatefulWidget {
  TVS0100024InputDialogPage(
      {Key key, this.parentContext, this.title, this.onConfirm, this.onCancel})
      : super(key: key);
  final BuildContext parentContext;
  final String title;
  final Function(dynamic v) onConfirm;
  final Function(dynamic v) onCancel;

  @override
  _TVS0100024InputDialogPageState createState() =>
      _TVS0100024InputDialogPageState();
}

class _TVS0100024InputDialogPageState extends State<TVS0100024InputDialogPage> {
  final GlobalKey<ScaffoldState> _this = new GlobalKey<ScaffoldState>();
  //鍵盤變更數
  GlobalKey<KeyboardState> _keyboardSession;
  //鍵盤動作配置設定
  KeyboardAction _keyboardAction = KeyboardAction();
  //該頁面參數值管理
  ValueManager _values = ValueManager.create([
    KeyValue('PARAM1', ''),
    KeyValue('MESSAGE', ''),
  ]);

  @override
  void initState() {
    super.initState();
    _keyboardSession = GlobalKey();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _this,
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          //
          widget.onConfirm != null
              ? IconButton(
                  icon: Icon(Icons.save),
                  onPressed: () {
                    if (widget.onConfirm != null) widget.onConfirm(null);
                    Navigator.of(widget.parentContext).pop();
                  })
              : Container(),
          //
          widget.onCancel != null ||
                  (widget.onConfirm == null && widget.onCancel == null)
              ? IconButton(
                  icon: Icon(Icons.cancel),
                  onPressed: () {
                    if (widget.onCancel != null) widget.onCancel(null);
                    Navigator.of(widget.parentContext).pop();
                  })
              : Container(),
        ],
      ),
      body: MediaQuery.of(context).orientation == Orientation.portrait
          ? portraitPage()
          : landscapePage(),
    );
  }

  //直版
  Widget portraitPage() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                labelTextBox(
                  '名稱',
                  '',
                  emptyText: '請輸入名稱',
                  lableWidth: 50,
                  width: 150,
                  mainAxisAlignment: MainAxisAlignment.start,
                  margin: EdgeInsets.only(bottom: 5, top: 5),
                ),
              ],
            ),
          ),
        ),
        _keyboardAction.actionName == ''
            ? Container()
            : Keyboard(
                key: _keyboardSession,
                config: _keyboardAction,
                onValueChanged: keyboardValueChanged,
                onTextChanged: keyboardTextChanged,
                onNotify: keyboardNotify,
              ),
      ],
    );
  }

  //橫版
  Widget landscapePage() {
    return Container();
  }

  //============================================================================ Keyboard Event
  void keyboardValueChanged(String actionName, String value) async {
    print('value changed: action: $actionName value: $value');

    setState(() {
      _values.setValue(actionName, value);
    });
  }

  void keyboardTextChanged(String actionName, String value) async {
    print('text changed: action: $actionName value: $value');

    setState(() {
      _values.setValue(actionName, value);
    });
  }

  void keyboardNotify() {
    setState(() {
      _keyboardAction = _keyboardAction;
    });
  }
}
