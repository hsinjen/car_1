//import 'dart:html';
import 'dart:io';
import 'dart:convert';
import 'package:car_1/model/sysCamera.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:car_1/business/datagram.dart';
import 'package:car_1/business/responseresult.dart';
//import 'package:car_1/apis/messagebox.dart';
import 'package:car_1/business/business.dart';
import 'package:car_1/business/enums.dart';
import 'package:flutter/cupertino.dart';
//import 'package:car_1/module/CameraBoxAdv.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:string_validator/string_validator.dart';
//import 'package:car_1/apis/imagebrowserlist.dart';
//import 'package:car_1/business/classes.dart';

import 'GeneralFunction.dart';
import '../model/sysMenu.dart';
import '../model/sysInputToolBar.dart';
import '../model/sysUserListView.dart';
import '../model/sysUi.dart';
import '../model/sysImagePainter.dart';
import '../model/sysCamera.dart';
import 'package:camera/camera.dart';

class PdiWidgetItem {
  final String id;
  String text;
  String parameter = '';

  PdiWidgetItem(this.id, String text, String parameter) {
    this.text = text;
    this.parameter = parameter;
  }
}

class PdiItem {
  String vin;
  String vinNo;
  String pdiNo;
  String no;
  String station;
  String itemText;
  String originalItemText;
  String parameter;
  String status;
  String operationTeam;
  String remark;
  String bugStatus;
  String bugCategory;
  String bugRemark;
  String flag;
  List<PdiWidgetItem> widgetFormatList = [];
  List<ImageItem> imageList = [];

  //================================
  PdiItem(Map<String, dynamic> data) {
    if (data != null) {
      this.vin = data['車身號碼'];
      this.vinNo = data['點交次數'].toString();
      this.pdiNo = data['PDI次數'].toString();
      this.no = data['序號'].toString();
      this.station = data['站別'];
      this.itemText = data['作業項目'];
      this.originalItemText = data['原作業項目'];
      this.parameter = data['作業參數'];
      this.status = data['PDI狀態'];
      this.operationTeam = data['作業小組'];
      this.remark = data['備註'];
      this.bugStatus = data['異常狀態'];
      this.bugCategory = data['異常類別'];
      this.bugRemark = data['異常說明'];
      this.flag = data['資料旗標'];

      _analysisItemText(data['原作業項目'], data['作業參數']);
    }
  }
  void _analysisItemText(String value, String paramValue) {
    if (value.indexOf('{%') > 0) {
      List<int> _listIndex = [];
      List<String> _paramList = paramValue.split('|');

      int paramCount = 0;
      int startIndex = 0;
      while (value.indexOf('{%', startIndex + 1) > 0) {
        startIndex = value.indexOf('{%', startIndex + 1);
        _listIndex.add(startIndex);
      }

      startIndex = 0;
      for (int i = 0; i < _listIndex.length; i++) {
        widgetFormatList.add(PdiWidgetItem(
            Uuid().v4(), value.substring(startIndex, _listIndex[i]), ''));

        if (value.substring(_listIndex[i], _listIndex[i] + 4) == '{%d}') {
          widgetFormatList.add(PdiWidgetItem(Uuid().v4(), '{%d}',
              _paramList.length > paramCount ? _paramList[paramCount] : ''));
          paramCount++;
        } else if (value.substring(_listIndex[i], _listIndex[i] + 4) ==
            '{%s}') {
          widgetFormatList.add(PdiWidgetItem(Uuid().v4(), '{%s}',
              _paramList.length > paramCount ? _paramList[paramCount] : ''));
          paramCount++;
        } else if (value.substring(_listIndex[i], _listIndex[i] + 4) ==
            '{%t}') {
          widgetFormatList.add(PdiWidgetItem(Uuid().v4(), '{%t}',
              _paramList.length > paramCount ? _paramList[paramCount] : ''));
          paramCount++;
        } else if (value.substring(_listIndex[i], _listIndex[i] + 4) ==
            '{%u}') {
          widgetFormatList.add(PdiWidgetItem(Uuid().v4(), '{%u}',
              _paramList.length > paramCount ? _paramList[paramCount] : ''));
          paramCount++;
        }

        startIndex = _listIndex[i] + 4;

        if (i == _listIndex.length - 1) {
          if (startIndex < value.length)
            widgetFormatList.add(PdiWidgetItem(
                Uuid().v4(), value.substring(startIndex, value.length), ''));
        }
      }
    } else
      widgetFormatList.add(PdiWidgetItem(Uuid().v4(), value, ''));
  }

  void _analysisNewItemText() {
    String value = this.originalItemText;
    if (value.indexOf('{%') > 0) {
      List<int> _listIndex = [];
      List<String> _paramList = [];

      int paramCount = 0;
      int startIndex = 0;
      while (value.indexOf('{%', startIndex + 1) > 0) {
        startIndex = value.indexOf('{%', startIndex + 1);
        _listIndex.add(startIndex);
      }

      startIndex = 0;
      for (int i = 0; i < _listIndex.length; i++) {
        widgetFormatList.add(PdiWidgetItem(
            Uuid().v4(), value.substring(startIndex, _listIndex[i]), ''));

        if (value.substring(_listIndex[i], _listIndex[i] + 4) == '{%d}') {
          widgetFormatList.add(PdiWidgetItem(Uuid().v4(), '{%d}',
              _paramList.length > paramCount ? _paramList[paramCount] : ''));
          paramCount++;
        } else if (value.substring(_listIndex[i], _listIndex[i] + 4) ==
            '{%s}') {
          widgetFormatList.add(PdiWidgetItem(Uuid().v4(), '{%s}',
              _paramList.length > paramCount ? _paramList[paramCount] : ''));
          paramCount++;
        } else if (value.substring(_listIndex[i], _listIndex[i] + 4) ==
            '{%t}') {
          widgetFormatList.add(PdiWidgetItem(Uuid().v4(), '{%t}',
              _paramList.length > paramCount ? _paramList[paramCount] : ''));
          paramCount++;
        } else if (value.substring(_listIndex[i], _listIndex[i] + 4) ==
            '{%u}') {
          widgetFormatList.add(PdiWidgetItem(Uuid().v4(), '{%u}',
              _paramList.length > paramCount ? _paramList[paramCount] : ''));
          paramCount++;
        }

        startIndex = _listIndex[i] + 4;

        if (i == _listIndex.length - 1) {
          if (startIndex < value.length)
            widgetFormatList.add(PdiWidgetItem(
                Uuid().v4(), value.substring(startIndex, value.length), ''));
        }
      }
    } else
      widgetFormatList.add(PdiWidgetItem(Uuid().v4(), value, ''));
  }

  String displayText() {
    String _text = '';

    // int _parameterCount = 0;
    for (int i = 0; i < widgetFormatList.length; i++) {
      if (widgetFormatList[i].text == '{%s}' ||
          widgetFormatList[i].text == '{%d}' ||
          widgetFormatList[i].text == '{%t}' ||
          widgetFormatList[i].text == '{%u}') {
        _text += widgetFormatList[i].parameter;
        //_parameterCount++;
      } else {
        _text += widgetFormatList[i].text;
      }
    }
    return _text;
  }
}

class TVS0100021 extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _TVS0100021();
  }
}

class _TVS0100021 extends State<TVS0100021> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final String moduleId = 'TVS0100021';
  final String moduleName = 'PDI 作業';
  final String imageCategory = 'TVS0100021';
  bool _isLoading = false;
  Directory _appDocDir;
  InputToolBarState _inputToolBarState;
  GlobalKey<InputToolBarContext> _inputToolBarKey;

  Map<String, dynamic> _currentVin;
  List<Map<String, dynamic>> _currentContents;
  String _currentStation = '';
  List<PdiItem> _currentItem = [];
  List<User> _currentTeam = [];
  List<PointItem> _currentVinPoint = []; //外觀內裝圖座標
  bool _currentVinLock = false; //車身作業中止
  List<CameraDescription> cameras;

  @override
  void initState() {
    super.initState();

    _inputToolBarKey = GlobalKey();
    _inputToolBarState = InputToolBarState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void inputToolBarValueChanged(String action, String value) async {
    if (action == 'operationTeam') {
      _currentItem
          .where((element) => element.station == _currentStation)
          .forEach((v) {
        v.operationTeam = value;
      });

      if (value == '') {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        if (prefs.containsKey(moduleId + '_teams_' + _currentStation) == true)
          prefs.remove(moduleId + '_teams_' + _currentStation);
        _currentTeam = [];
      }
      //
      else {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        if (prefs.containsKey(moduleId + '_teams_' + _currentStation) == true)
          prefs.remove(moduleId + '_teams_' + _currentStation);
        prefs.setString(moduleId + '_teams_' + _currentStation, value);

        _currentTeam =
            (json.decode(value) as List).map((i) => User.fromJson(i)).toList();
      }
    }
    //
    else if (action.startsWith('itemTextWithParameter') == true) {
      String key1 = action.split('#')[1];
      String key2 = action.split('#')[2];

      PdiItem item = _currentItem.firstWhere((element) =>
          element.station == _currentStation && element.no == key1);

      if (item != null) {
        PdiWidgetItem widgetItem =
            item.widgetFormatList.firstWhere((element) => element.id == key2);
        widgetItem.parameter = value;

        String param = '';
        for (int i = 0; i < item.widgetFormatList.length; i++)
          if (item.widgetFormatList[i].text.indexOf('{%') > -1)
            param += item.widgetFormatList[i].parameter + '|';

        if (param != '') item.parameter = param.substring(0, param.length - 1);
      }
    }
    //vin
    else if (action == "vin") {
      _currentStation = '';
      _currentVin = null;
      _currentContents = null;
      _currentItem = [];
      _currentTeam = [];
      _currentVinPoint = [];
      List<Map<String, dynamic>> data = await _loadVin(value);
      if (data == null || data.length == 0) {
        _inputToolBarKey.currentState
            .showMessage(_scaffoldKey, ResultFlag.ng, '無此車身號碼 $value');
      } else if (data.length > 1) {
        showVinActionSheet(data);
      } else if (data.length == 1) {
        bool isCheckLock = await _checkVinLock(data[0]['車身號碼'], station: '');
        if (data[0]['外觀圖'] != '') {
          _currentVinPoint = (json.decode(data[0]['外觀圖'].toString()) as List)
              .map((i) => PointItem.fromJson(i))
              .toList();
        }

        setState(() {
          _currentVinLock = isCheckLock;
          _currentVin = data[0];
        });
        if (_currentVin != null) {
          await _loadContent(
              _currentVin['車身號碼'], _currentVin['點交次數'], _currentVin['PDI次數']);
          _currentItem = [];
          if (_currentContents != null)
            for (final item in _currentContents) {
              _currentItem.add(PdiItem(item));
            }
        }
      }
    }
    //vinAction
    else if (action == "vinAction") {
      _currentStation = '';
      _currentContents = null;
      _currentItem = [];
      _currentTeam = [];
      _currentVinPoint = [];
      //await _loadVinPicCount(
      //    _currentVin['車身號碼'], _currentVin['點交次數'].toString());
      if (_currentVin != null) {
        if (_currentVin['外觀圖'] != '') {
          _currentVinPoint =
              (json.decode(_currentVin['外觀圖'].toString()) as List)
                  .map((i) => PointItem.fromJson(i))
                  .toList();
        }
        await _loadContent(
            _currentVin['車身號碼'], _currentVin['點交次數'], _currentVin['PDI次數']);
        _currentItem = [];
        if (_currentContents != null)
          for (final item in _currentContents) {
            _currentItem.add(PdiItem(item));
          }
      }
    }
    //headerRemark
    else if (action == 'headerRemark') {
      _currentVin['備註'] = value;
    }
    //addOther
    else if (action == 'addItem') {
      PdiItem newItem = PdiItem(null);
      newItem.vin = _currentVin['車身號碼'];
      newItem.vinNo = _currentVin['點交次數'].toString();
      newItem.pdiNo = _currentVin['PDI次數'].toString();
      newItem.no =
          (_currentItem.where((element) => element.station == '其它').length + 1)
              .toString();
      newItem.station = '其它';
      newItem.itemText = value;
      newItem.originalItemText = value;
      newItem.parameter = '';
      newItem.status = 'Y';
      newItem.operationTeam = '';
      newItem.remark = '';
      newItem.bugStatus = 'N';
      newItem.bugCategory = '';
      newItem.bugRemark = '';
      newItem._analysisNewItemText();
      setState(() {
        _currentItem.add(newItem);
      });
    }
  }

  void inputToolBarRefresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        toolbarHeight: 50,
        title: Text(moduleName),
        automaticallyImplyLeading: true,
        actions: <Widget>[
          //Lock
          new IconButton(
            icon: new Icon(
              _currentVinLock == false ? Icons.lock_open : Icons.lock,
              color: _currentVinLock == false ? Colors.white : Colors.red,
            ),
            onPressed: () async {
              bool isLockState = false;
              if (_currentVinLock == false)
                isLockState = await _lockVin();
              else
                isLockState = await _unlockVin();

              if (isLockState == true)
                inputToolBarValueChanged('vin', _currentVin['車身號碼']);
            },
          ),
          //Clear
          new IconButton(
            icon: new Icon(Icons.clear_all),
            onPressed: () {
              setState(() {
                _inputToolBarState.setDefault();
                _currentVinLock = false;
                _currentStation = '';
                _currentVin = null;
                _currentContents = null;
                _currentItem = [];
                _currentTeam = [];
                _currentVinPoint = [];
              });
            },
          ),
          //Save
          new IconButton(
            icon: new Icon(Icons.save),
            onPressed: () async {
              if (_currentVin == null) return;
              if (_currentContents == null) return;
              if (_currentItem == null) return;
              if (_currentStation == '') {
                _inputToolBarKey.currentState
                    .showMessage(_scaffoldKey, ResultFlag.ng, '請選擇站別');
                return;
              }
              if (_currentVinLock == true) {
                _inputToolBarKey.currentState
                    .showMessage(_scaffoldKey, ResultFlag.ng, '車身狀態作業中止');
                return;
              }
              if (_currentItem
                      .where((v) =>
                          v.station == _currentStation && v.status == 'N')
                      .length >
                  0) {
                _inputToolBarKey.currentState.showMessage(_scaffoldKey,
                    ResultFlag.ng, _currentStation + ' 尚有作業項目未完成');
                return;
              }
              if (_currentItem
                      .where((v) =>
                          v.station == _currentStation && v.operationTeam == '')
                      .length >
                  0) {
                _inputToolBarKey.currentState.showMessage(
                    _scaffoldKey, ResultFlag.ng, _currentStation + ' 未指派作業人員');
                return;
              }

              setState(() {
                _isLoading = true;
              });
              bool r1 = await _save();
              bool r2 = await _saveFile();

              if (r1 == true && r2 == true) {
                setState(() {
                  _inputToolBarState.setDefault();
                  _currentVinLock = false;
                  _currentStation = '';
                  _currentVin = null;
                  _currentContents = null;
                  _currentItem = [];
                  _currentTeam = [];
                  _currentVinPoint = [];
                  _isLoading = false;
                });
              } else {
                setState(() {
                  _isLoading = false;
                });
                if (_inputToolBarKey.currentState != null && r1 == false)
                  _inputToolBarKey.currentState
                      .showMessage(_scaffoldKey, ResultFlag.ng, '儲存失敗');
                else if (_inputToolBarKey.currentState != null && r2 == false)
                  _inputToolBarKey.currentState
                      .showMessage(_scaffoldKey, ResultFlag.ng, '上傳檔案失敗');
              }
            },
          ),
        ],
      ),
      drawer: buildMenu(context),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniStartDocked,
      floatingActionButton: _currentStation.indexOf('其它') != -1 ||
              _inputToolBarState.inputEnabled == true
          ? Container()
          : FloatingActionButton.extended(
              onPressed: () {
                if (_currentVin == null) return;
                if (_currentVinLock == true) {
                  _inputToolBarKey.currentState
                      .showMessage(_scaffoldKey, ResultFlag.ng, '車身狀態作業中止');
                  return;
                }
                if (_currentStation.indexOf('其它') != -1) {
                  setState(() {
                    _inputToolBarState.showKeyboard(
                        'addItem', TextInputType.text);
                  });
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ImageEditor(
                            type: _currentStation, points: _currentVinPoint),
                        fullscreenDialog: false),
                  );
                }
              },
              label: Text(_currentStation == '其它' ? '新增項目' : '車身檢查'),
              icon:
                  Icon(_currentStation == '其它' ? Icons.add : Icons.view_agenda),
              backgroundColor: Colors.blueGrey,
            ),
      body: Container(
        width: Business.deviceWidth(context),
        child: _isLoading == false
            ? Column(
                children: <Widget>[
                  //================ Body
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(children: [
                        buildHeaderThreeRow(
                            context, '廠牌', 30, '引擎號碼', 30, '車身號碼', 40),
                        buildDataThreeRow(
                            context,
                            _currentVin == null ? '' : _currentVin['廠牌名稱'],
                            30,
                            _currentVin == null ? '' : _currentVin['引擎號碼'],
                            30,
                            _currentVin == null ? '' : _currentVin['車身號碼'],
                            40),
                        buildHeaderThreeRow(
                            context, '車款', 30, '到港日', 30, '出廠日', 40),
                        buildDataThreeRow(
                            context,
                            _currentVin == null ? '' : _currentVin['車款名稱'],
                            30,
                            _currentVin == null ? '' : _currentVin['到港日期'],
                            30,
                            _currentVin == null ? '' : _currentVin['出廠年月日'],
                            40),
                        buildHeaderTwoRow(context, '車型', 30, '備註', 70),
                        buildDataTwoRowWithContainer(
                          context,
                          _currentVin == null ? '' : _currentVin['車型名稱'],
                          30,
                          Container(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _inputToolBarState.showKeyboard(
                                      'headerRemark', TextInputType.text);
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                      top: BorderSide(width: 1),
                                      right: BorderSide(width: 1),
                                      bottom: BorderSide(width: 1)),
                                ),
                                alignment: Alignment.center,
                                width: MediaQuery.of(context).size.width /
                                    100 *
                                    70,
                                height: 24.0,
                                child: Text(
                                    _currentVin == null
                                        ? ''
                                        : _currentVin['備註'],
                                    style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          ),
                        ),
                        //Function ToolBar
                        Divider(height: 2.0),
                        buildStationToolBar(),
                        //
                        Divider(height: 2.0),
                        MediaQuery.of(context).orientation ==
                                Orientation.portrait
                            ? buildHeaderTwoRow(context, '作業項目', 75, '動作', 25)
                            : buildHeaderTwoRow(context, '作業項目', 85, '動作', 15),
                        MediaQuery.of(context).orientation ==
                                Orientation.portrait
                            ? Column(
                                children: buildGridView(context, 75, 25)) //直
                            : Column(
                                children: buildGridView(context, 85, 15)), //橫
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: Colors.black,
                        ),
                      ]),
                    ),
                  ),

                  //InputToolBar
                  Container(
                      height: 40.0,
                      child: InputToolBar(
                        key: _inputToolBarKey,
                        state: _inputToolBarState,
                        onValueChanged: inputToolBarValueChanged,
                        onNotifyParent: inputToolBarRefresh,
                      ))
                ],
              )
            : Container(
                alignment: Alignment.center,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(Colors.green)),
                      SizedBox(height: 10.0),
                      Text('儲存中'),
                    ]),
              ),
      ),
    );
  }

  //建立站別工具列
  Widget buildStationToolBar() {
    List<String> _station = [];
    List<Widget> _list = [];

    if (_currentItem != null) {
      _list.add(RaisedButton(
        child: Text(
            _currentTeam.length == 0
                ? '請指派作業人員'
                : _currentTeam[0].userName +
                    '(' +
                    _currentTeam.length.toString() +
                    ')',
            style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
        color: Colors.black,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5.0),
            side: BorderSide(color: Colors.black)),
        onPressed: () async {
          if (_currentVinLock == true) {
            _inputToolBarKey.currentState
                .showMessage(_scaffoldKey, ResultFlag.ng, '車身狀態作業中止');
            return;
          }
          if (_currentStation == '') {
            _inputToolBarKey.currentState
                .showMessage(_scaffoldKey, ResultFlag.ng, '請選擇作業站別');
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => UserListView(
                        'operationTeam',
                        '作業小組: $_currentStation',
                        _currentTeam.length == 0
                            ? ''
                            : jsonEncode(_currentTeam),
                        inputToolBarValueChanged,
                        deptId: '112200',
                      ),
                  fullscreenDialog: false),
            );
          }
        },
      ));

      for (int i = 0; i < _currentItem.length; i++) {
        if (_currentItem[i].station.indexOf('檢查圖') > -1) continue;
        if (_currentItem[i].station.startsWith('維修') == true) continue;
        if (_currentItem[i].station.startsWith('其它') == true) continue;
        if (_station.contains(_currentItem[i].station) == false) {
          _station.add(_currentItem[i].station);
          _list.add(RaisedButton(
            child: Text(
                _currentItem
                            .where((v) =>
                                v.station == _currentItem[i].station &&
                                v.flag == 'A')
                            .length >
                        0
                    ? _currentItem[i].station
                    : _currentItem[i].station + ' (V)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            color: _currentStation == _currentItem[i].station
                ? Colors.green[200]
                : Colors.blue[200],
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0),
                side: BorderSide(color: Colors.black)),
            onPressed: () async {
              if (_currentVinLock == true) {
                _inputToolBarKey.currentState
                    .showMessage(_scaffoldKey, ResultFlag.ng, '車身狀態作業中止');
                return;
              }
              setState(() {
                _currentStation = _currentItem[i].station;
              });
              SharedPreferences prefs = await SharedPreferences.getInstance();
              if (prefs.containsKey(moduleId + '_teams_' + _currentStation) ==
                  true) {
                String usrJson =
                    prefs.getString(moduleId + '_teams_' + _currentStation);

                _currentTeam = (json.decode(usrJson) as List)
                    .map((i) => User.fromJson(i))
                    .toList();

                _currentItem
                    .where((element) => element.station == _currentStation)
                    .forEach((v) {
                  v.operationTeam = usrJson;
                });
              } else
                _currentTeam = [];
              setState(() {});
            },
          ));
        }
      }
    }

    // _list.add(RaisedButton(
    //   child: Text('其它',
    //       style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    //   color: _currentStation == '其它' ? Colors.green[200] : Colors.blue[200],
    //   shape: RoundedRectangleBorder(
    //       borderRadius: BorderRadius.circular(5.0),
    //       side: BorderSide(color: Colors.black)),
    //   onPressed: () {
    //     setState(() {
    //       _currentStation = '其它';
    //     });
    //   },
    // ));

    return Container(
      width: MediaQuery.of(context).size.width,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          height: 28,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _list,
          ),
        ),
      ),
    );
  }

  List<Widget> buildGridView(
      BuildContext context, double width1, double width2) {
    List<Widget> _list = [];

    if (_currentItem == null) return _list;
    if (_currentStation == '') return _list;

    for (final item
        in _currentItem.where((v) => v.station == _currentStation)) {
      List<Widget> _itemWidget = [];

      // int patternCount = 0;
      for (int i = 0; i < item.widgetFormatList.length; i++) {
        //String
        if (item.widgetFormatList[i].text == '{%s}') {
          _itemWidget.add(GestureDetector(
              onTap: () {
                setState(() {
                  _inputToolBarState.showKeyboard(
                      'itemTextWithParameter#' +
                          item.no +
                          '#' +
                          item.widgetFormatList[i].id,
                      TextInputType.text);
                });
              },
              child: Container(
                  height: 23,
                  //color: Colors.green,
                  padding: EdgeInsets.only(
                      left: 0,
                      right: 0,
                      top: item.widgetFormatList[i].parameter == '' ||
                              isAscii(item.widgetFormatList[i].parameter) ==
                                  true
                          ? 5
                          : 0,
                      bottom: 0),
                  child: Text(
                      item.widgetFormatList[i].parameter == ''
                          ? '          '
                          : item.widgetFormatList[i].parameter,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          decoration: TextDecoration.underline)))));
          //patternCount++;
        }
        //Number
        else if (item.widgetFormatList[i].text == '{%d}') {
          _itemWidget.add(GestureDetector(
              onTap: () {
                setState(() {
                  _inputToolBarState.showKeyboard(
                      'itemTextWithParameter#' +
                          item.no +
                          '#' +
                          item.widgetFormatList[i].id,
                      TextInputType.number);
                });
              },
              child: Container(
                  height: 23,
                  //color: Colors.red,
                  padding: EdgeInsets.only(
                      left: 0,
                      right: 0,
                      top: item.widgetFormatList[i].parameter == '' ||
                              isAscii(item.widgetFormatList[i].parameter) ==
                                  true
                          ? 5
                          : 0,
                      bottom: 0),
                  child: Text(
                      item.widgetFormatList[i].parameter == ''
                          ? ' 0 '
                          : item.widgetFormatList[i].parameter,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          decoration: TextDecoration.underline)))));
          //patternCount++;
        }
        //Date
        else if (item.widgetFormatList[i].text == '{%t}') {
          _itemWidget.add(GestureDetector(
              onTap: () async {
                var rdresult = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2099));
                if (rdresult == null)
                  setState(() {
                    inputToolBarValueChanged(
                        'itemTextWithParameter#' +
                            item.no +
                            '#' +
                            item.widgetFormatList[i].id,
                        '');
                  });
                else
                  setState(() {
                    inputToolBarValueChanged(
                        'itemTextWithParameter#' +
                            item.no +
                            '#' +
                            item.widgetFormatList[i].id,
                        DateFormat('yyyy-MM-dd').format(rdresult));
                  });
              },
              child: Container(
                  height: 23,
                  //color: Colors.pink,
                  padding: EdgeInsets.only(
                      left: 0,
                      right: 0,
                      top: item.widgetFormatList[i].parameter == '' ||
                              isAscii(item.widgetFormatList[i].parameter) ==
                                  true
                          ? 5
                          : 0,
                      bottom: 0),
                  child: Text(
                      item.widgetFormatList[i].parameter == ''
                          ? '          '
                          : item.widgetFormatList[i].parameter,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          decoration: TextDecoration.underline)))));
          //patternCount++;
        }
        //User
        else if (item.widgetFormatList[i].text == '{%u}') {
          _itemWidget.add(GestureDetector(
              onTap: () {
                showGridViewUserActionSheet('itemTextWithParameter#' +
                    item.no +
                    '#' +
                    item.widgetFormatList[i].id);
              },
              child: Container(
                  height: 23,
                  //color: Colors.lightGreen,
                  padding: EdgeInsets.only(
                      left: 0,
                      right: 0,
                      top: item.widgetFormatList[i].parameter == '' ||
                              isAscii(item.widgetFormatList[i].parameter) ==
                                  true
                          ? 5
                          : 0,
                      bottom: 0),
                  child: Text(
                      item.widgetFormatList[i].parameter == ''
                          ? '          '
                          : item.widgetFormatList[i].parameter,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          decoration: TextDecoration.underline)))));
          // patternCount++;
        }
        //Text
        else
          _itemWidget.add(Container(
              //color: Colors.yellow,
              child: Text(item.widgetFormatList[i].text,
                  style: TextStyle(fontSize: 16))));
      }
      _list.add(buildGridViewItem(context, width1, width2, item, _itemWidget));
    }

    return _list;
  }

  Widget buildGridViewItem(BuildContext context, double width1, double width2,
      PdiItem data, List<Widget> itemWidget) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      //作業項目
      Container(
        padding: EdgeInsets.only(top: 3, bottom: 3, left: 4, right: 0),
        decoration: BoxDecoration(
          //color: Colors.grey[300],
          border: Border(
            left: BorderSide(width: 1),
            top: BorderSide(width: 1),
            right: BorderSide(width: 1),
            //bottom: BorderSide(width: 1),
          ),
        ),
        alignment: Alignment.centerLeft,
        width: MediaQuery.of(context).size.width / 100 * width1,
        child:
            //Column(children: [Text(data['原作業項目'], style: TextStyle(fontSize: 10))]),
            Column(children: [Wrap(children: itemWidget)]),
      ),
      //動作
      Container(
        decoration: BoxDecoration(
          // color: Colors.red,
          border: Border(
            top: BorderSide(width: 1),
            right: BorderSide(width: 1),
            //bottom: BorderSide(width: 1),
          ),
        ),
        alignment: Alignment.topCenter,
        width: MediaQuery.of(context).size.width / 100 * width2,
        //height: 24,
        child: Row(children: [
          //檢查狀態
          SizedBox(
            height: 28,
            width: MediaQuery.of(context).size.width / 100 * width2 / 3 - 1,
            child: Container(
              //color: Colors.red, //Colors.grey[300],
              child: IconButton(
                padding: EdgeInsets.only(top: 3, bottom: 0, left: 0, right: 0),
                icon: Icon(data.status == 'Y'
                    ? Icons.check_box
                    : Icons.check_box_outline_blank),
                iconSize: 22,
                onPressed: () async {
                  setState(() {
                    _currentItem
                        .firstWhere((v) =>
                            v.station == _currentStation && v.no == data.no)
                        .status = (data.status == 'Y' ? 'N' : 'Y');
                  });
                },
              ),
            ),
          ),
          //異常狀態
          SizedBox(
            height: 28,
            width: MediaQuery.of(context).size.width / 100 * width2 / 3 - 1,
            child: Container(
              //color: Colors.grey[300],
              child: IconButton(
                color: data.bugStatus == 'Y' ? Colors.red : Colors.black,
                padding: EdgeInsets.only(top: 3, bottom: 0, left: 0, right: 0),
                icon: Icon(Icons.bug_report),
                iconSize: 22,
                onPressed: () async {
                  showContentBugCategoryActionSheet(data.no);
                },
              ),
            ),
          ),
          //相機
          SizedBox(
            height: 28,
            width: MediaQuery.of(context).size.width / 100 * width2 / 3 - 1,
            child: GestureDetector(
              onLongPress: () async {
                if (_currentVin == null || _currentVin.length == 0) return;

                if (cameras == null) cameras = await availableCameras();
                if (cameras != null) {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CameraWindow(
                          cameraType: CameraType.cameraWithLamp,
                          cameraList: cameras,
                          imageDirPath: data.vin +
                              '\\' +
                              data.vinNo +
                              '\\' +
                              data.pdiNo +
                              '\\' +
                              data.no,
                          imageList: data.imageList,
                          keyNo: 'PDI',
                          keyDate: '',
                          keyNumber: data.vin,
                          tag1: data.vinNo,
                          tag2: data.no,
                          groupKey: data.pdiNo,
                          onConfirm: (v) {
                            data.imageList = v;
                          },
                        ),
                      ));
                }
              },
              child: Container(
                child: IconButton(
                  color: data.imageList.length > 0 ? Colors.blue : Colors.black,
                  padding:
                      EdgeInsets.only(top: 3, bottom: 0, left: 0, right: 0),
                  icon: Icon(Icons.camera_alt),
                  iconSize: 22,
                  onPressed: () async {
                    if (_currentVin == null || _currentVin.length == 0) return;

                    if (cameras == null) cameras = await availableCameras();
                    if (cameras != null) {
                      await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CameraWindow(
                              cameraType: CameraType.camera,
                              cameraList: cameras,
                              imageDirPath: data.vin +
                                  '\\' +
                                  data.vinNo +
                                  '\\' +
                                  data.pdiNo +
                                  '\\' +
                                  data.no,
                              imageList: data.imageList,
                              keyNo: 'PDI',
                              keyDate: '',
                              keyNumber: data.vin,
                              tag1: data.vinNo,
                              tag2: data.no,
                              groupKey: data.pdiNo,
                              onConfirm: (v) {
                                data.imageList = v;
                              },
                            ),
                          ));
                    }
                  },
                ),
              ),
            ),
          ),
        ]),
      ),
    ]);
  }

  Future<bool> _save() async {
    if (_currentVin == null) return false;
    if (_currentItem == null) return false;

    Datagram datagram = Datagram();

    List<PdiItem> dataList = _currentItem
        .where((element) => element.station == _currentStation)
        .toList();

    for (int i = dataList.length - 1; i >= 0; i--) {
      if (dataList[i].flag == 'D' && dataList[i].no.toString() == '0') continue;

      datagram.addText("""if(1=1)
                       declare @sMODE varchar(1) = '${dataList[i].flag}',       --H: A: U: D:
                               @sVSBA4006 varchar(20) = '${dataList[i].vin}',  --車身號碼
                               @sVSBA4007 int = ${dataList[i].vinNo},          --點交次數
                               @sVSBA4014 nvarchar(max) = '-', --外觀圖座標 Json
                               @sVSBA4017 nvarchar(200) = '',--備註
                               @sVSBB4008 int = ${dataList[i].no},          --序號(0:表示新增項目)
                               @sVSBB4009 nvarchar(20) = '${dataList[i].station}', --站別
                               @sVSBB4010 nvarchar(512) = '${dataList[i].displayText()}',--作業項目
                               @sVSBB4011 nvarchar(512) = '${dataList[i].originalItemText}',--原作業項目
                               @sVSBB4012 nvarchar(512) = '${dataList[i].parameter}',--作業參數
                               @sVSBB4013 varchar(1) = '${dataList[i].status}',   --PDI狀態
                               @sVSBB4014 varchar(max) = '${dataList[i].operationTeam}', --作業小組 Json
                               @sVSBB4015 nvarchar(200) = '${dataList[i].remark}',--備註
                               @sVSBB4020 varchar(1) = '${dataList[i].bugStatus}',   --異常狀態
                               @sVSBB4021 nvarchar(20) = '${dataList[i].bugCategory}', --異常原因
                               @sVSBB4022 nvarchar(512) = '${dataList[i].bugStatus == 'Y' ? dataList[i].station : ''}',--異常部位
                               @sUSERID varchar(30) = '${Business.userId}',
                               @sDEPTID varchar(30) = '${Business.deptId}',
                               @oRESULT_FLAG varchar(2), --處理旗標(OK / NG)
                               @oRESULT nvarchar(4000);   --返回訊息
                        declare @rc int;
                        execute @rc = [dbo].[spx_xvms_ba04_in] 
                          @smode,
                          @svsba4006,
                          @svsba4007,
                          @svsba4014,
                          @svsba4017,
                          @svsbb4008,
                          @svsbb4009,
                          @svsbb4010,
                          @svsbb4011,
                          @svsbb4012,
                          @svsbb4013,
                          @svsbb4014,
                          @svsbb4015,
                          @svsbb4020,
                          @svsbb4021,
                          @svsbb4022,
                          @suserid,
                          @sdeptid,
                          @oresult_flag output,
                          @oresult output
                          
                        if (@oresult_flag = 'NG')
                            begin
                                raiserror(@oresult,16,1);
                            end
                        select @oresult_flag as ORESULT_FLAG,@oresult as ORESULT;
    """, rowSize: 65535);
    }

    datagram.addText("""if(1=1)
                       declare @sMODE varchar(1) = 'H',       --H: A: U: D:
                               @sVSBA4006 varchar(20) = '${_currentVin['車身號碼']}',  --車身號碼
                               @sVSBA4007 int = ${_currentVin['點交次數']},          --點交次數
                               @sVSBA4014 nvarchar(max) = '${(_currentVinPoint.length > 0 ? jsonEncode(_currentVinPoint) : '-')}', --外觀圖座標 Json
                               @sVSBA4017 nvarchar(200) = '${_currentVin['備註']}',--備註
                               @sVSBB4008 int = '0',          --序號(0:表示新增項目)
                               @sVSBB4009 nvarchar(20) = '$_currentStation', --站別
                               @sVSBB4010 nvarchar(512) = '',--作業項目
                               @sVSBB4011 nvarchar(512) = '',--原作業項目
                               @sVSBB4012 nvarchar(512) = '',--作業參數
                               @sVSBB4013 varchar(1) = '',   --PDI狀態
                               @sVSBB4014 varchar(max) = '${dataList[0].operationTeam}', --作業小組 Json
                               @sVSBB4015 nvarchar(200) = '',--備註
                               @sVSBB4020 varchar(1) = '',   --異常狀態
                               @sVSBB4021 nvarchar(20) = '', --異常類別
                               @sVSBB4022 nvarchar(512) = '',--異常說明
                               @sUSERID varchar(30) = '${Business.userId}',
                               @sDEPTID varchar(30) = '${Business.deptId}',
                               @oRESULT_FLAG varchar(2), --處理旗標(OK / NG)
                               @oRESULT nvarchar(4000);   --返回訊息
                        declare @rc int;
                        execute @rc = [dbo].[spx_xvms_ba04_in] 
                          @smode,
                          @svsba4006,
                          @svsba4007,
                          @svsba4014,
                          @svsba4017,
                          @svsbb4008,
                          @svsbb4009,
                          @svsbb4010,
                          @svsbb4011,
                          @svsbb4012,
                          @svsbb4013,
                          @svsbb4014,
                          @svsbb4015,
                          @svsbb4020,
                          @svsbb4021,
                          @svsbb4022,
                          @suserid,
                          @sdeptid,
                          @oresult_flag output,
                          @oresult output
                          
                        if (@oresult_flag = 'NG')
                            begin
                                raiserror(@oresult,16,1);
                            end
                        select @oresult_flag as ORESULT_FLAG,@oresult as ORESULT;
    """, rowSize: 65535);

    // datagram.addText(
    //     """delete from xvms_bb04 where vsbb4005 = '${_currentVin['車身號碼']}' and
    //                                    vsbb4006 = ${_currentVin['點交次數']} and
    //                                    vsbb4007 = ${_currentVin['PDI次數']} and
    //                                    vsbb4009 = '外觀檢查'
    //                  """);

    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> _saveFile() async {
    if (_currentVin == null) return false;
    if (_currentItem == null) return false;

    List<PdiItem> dataList = _currentItem
        .where((element) => element.station == _currentStation)
        .toList();

    for (int i = 0; i < dataList.length; i++) {
      if (dataList[i].flag == 'D' && dataList[i].no.toString() == '0') continue;
      if (dataList[i].imageList.length == 0) continue;

      Map<String, String> headers = {
        'ModuleId': dataList[i].imageList[0].keyNo,
        'SubPath': '\\PDI\\' +
            dataList[i].imageList[0].keyNumber +
            '\\' +
            dataList[i].imageList[0].tag1 +
            '\\' +
            dataList[i].imageList[0].groupKey,
        'ReceiptType': 'PDI',
        'ReceiptSerial': dataList[i].imageList[0].keyNumber,
        'ReceiptNo': dataList[i].imageList[0].tag1,
        'Tag1': dataList[i].imageList[0].groupKey,
        'Tag2': dataList[i].imageList[0].tag2,
        'Descryption': '',
        'UploadUser': Business.userId,
        'UploadDevice': '',
      };
      List<File> uploadFile = [];
      dataList[i].imageList.forEach((element) {
        uploadFile.add(element.file);
      });
      ResponseResult result = await Business.apiUploadFile(
          FileCmdType.file, uploadFile,
          headers: headers);
      if (result.flag == ResultFlag.ok) {
        CommonMethod.removeFilesOfDirNoQuestion(context, 'PDI', '');
      } else {
        return false;
      }
    }

    for (int i = 0; i < _currentVinPoint.length; i++) {
      if (_currentVinPoint[i].imageList == null) continue;
      if (_currentVinPoint[i].imageList.length == 0) continue;

      Map<String, String> headers = {
        'ModuleId': _currentVinPoint[i].imageList[0].keyNo,
        'SubPath': 'PDIVision\\' +
            _currentVin['車身號碼'] +
            '\\' +
            _currentVin['點交次數'].toString() +
            '\\' +
            _currentVin['PDI次數'].toString(),
        'ReceiptType': _currentVinPoint[i].imageList[0].keyNo,
        'ReceiptSerial': _currentVin['車身號碼'],
        'ReceiptNo': _currentVin['點交次數'].toString(),
        'Tag1': _currentVin['PDI次數'].toString(),
        'Tag2': _currentVinPoint[i].imageList[0].tag2,
        'Descryption': '',
        'UploadUser': Business.userId,
        'UploadDevice': '',
      };
      List<File> uploadFile = [];
      _currentVinPoint[i].imageList.forEach((element) {
        uploadFile.add(element.file);
      });
      ResponseResult result = await Business.apiUploadFile(
          FileCmdType.file, uploadFile,
          headers: headers);
      if (result.flag == ResultFlag.ok) {
        CommonMethod.removeFilesOfDirNoQuestion(context, 'PDIVision', '');
      } else {
        return false;
      }
    }

    return true;
  }

  Future<List<Map<String, dynamic>>> _loadVin(String value) async {
    Datagram datagram = Datagram();
    datagram.addText("""select x1.vsba4006 as 車身號碼,
                               x3.vsaa0101 as 引擎號碼,
                               x1.vsba4007 as 點交次數,
                               x1.vsba4002 as 進口商系統碼,
                                 x2.進口商名稱,
                               x1.vsba4003 as 廠牌系統碼,
                                 x2.廠牌名稱,
                               x1.vsba4004 as 車款系統碼,
                                 x2.車款名稱,
                               x1.vsba4005 as 車型系統碼,
                                 x2.車型名稱,
                               x1.vsba4015 as PDI次數,
                               x1.vsba4017 as 備註,
                               x3.vsaa0106 as 車色,
                               x3.vsaa0107 as 車身年份,
                               x3.vsaa0110 as 出廠年月日,
                               x3.vsaa0122 as 到港日期,
                               x1.vsba4014 as 外觀圖,
                               0 as 照片數
                        from xvms_ba04 as x1 left join vi_xvms_0001_04 as x2 on x1.vsba4002 = x2.進口商系統碼 and
                                                                                x1.vsba4003 = x2.廠牌系統碼 and
                                                                                x1.vsba4004 = x2.車款系統碼 and
                                                                                x1.vsba4005 = x2.系統碼
                                             left join xvms_aa01 as x3 on x1.vsba4006 = x3.vsaa0100 and x1.vsba4007 = x3.vsaa0119
                        where x1.vsba4008 = 'N' and x1.vsba4006 like '%$value' and x2.廠牌名稱 not in ('MASERATI','PORSCHE','AUDI','VOLKSWAGEN','SKODA','V.W.(LCV)')
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

  Future<bool> _checkVinLock(String vin, {String station = ''}) async {
    Datagram datagram = Datagram();
    if (station == '') {
      datagram.addText("""select 異常中止時間,中止說明 from vi_xvms_ba04_pause_history
                          where 類別 = '車身' and 車身號碼 = '$vin'
                       """, rowIndex: 0, rowSize: 65535);
    } else {
      datagram.addText("""select 異常中止時間,中止說明 from vi_xvms_ba04_pause_history
                          where 類別 = '$station' and 車身號碼 = '$vin'
                       """, rowIndex: 0, rowSize: 65535);
    }
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ng) {
      _inputToolBarKey.currentState
          .showMessage(_scaffoldKey, ResultFlag.ng, result.getString());
      return false;
    } else {
      List<Map<String, dynamic>> data = result.getMap();
      if (data.length == 0)
        return false;
      else {
        _inputToolBarKey.currentState.showMessage(
            _scaffoldKey,
            ResultFlag.ng,
            station +
                ' 作業中止: ' +
                data[0]['中止說明'] +
                '  (' +
                data[0]['異常中止時間'] +
                ')');
        return true;
      }
    }
  }

  Future<void> _loadContent(String vin, int vinNo, int operationNo) async {
    Datagram datagram = Datagram();

    datagram.addText("""select x1.vsbb4005 as 車身號碼,
                                x1.vsbb4006 as 點交次數,
                                x1.vsbb4007 as PDI次數,
                                x1.vsbb4008 as 序號,
                                x1.vsbb4009 as 站別,
                                x1.vsbb4010 as 作業項目,
                                x1.vsbb4011 as 原作業項目,
                                x1.vsbb4012 as 作業參數,
                                x1.vsbb4013 as PDI狀態,
                                x1.vsbb4014 as 作業小組,
                                x1.vsbb4015 as 備註,
                                x1.vsbb4020 as 異常狀態,
                                x1.vsbb4021 as 異常類別,
                                x1.vsbb4022 as 異常說明,
                                'U' as 資料旗標
                         from xvms_bb04 as x1
                         where x1.vsbb4005 = '$vin' and x1.vsbb4006 = $vinNo and x1.vsbb4007 = $operationNo and vsbb4009 not in ('外觀檢查圖','內裝檢查圖')
                         union all
                         select x1.vsba4006 as 車身號碼,
                                   x1.vsba4007 as 點交次數,
                                   $operationNo as PDI次數,
                                   (select isnull(max(vsbb4008),0) from xvms_bb04 where vsbb4005 = '$vin' and vsbb4006 = $vinNo and vsbb4007 = $operationNo) + 
                                      row_number() over(order by getdate()) as 序號,
                                   x2.vsba3006 as 站別,
                                   x2.vsba3005 as 作業項目,
                                   x2.vsba3005 as 原作業項目,
                                   '' as 作業參數,
                                   'Y' as PDI狀態,
                                   '' as 作業小組,
                                   '' as 備註,
                                   'N' as 異常狀態,
                                   '' as 異常類別,
                                   '' as 異常說明,
                                   'A' as 資料旗標
                            from xvms_ba04 as x1 left join xvms_ba03 as x2 on x1.vsba4002 = x2.vsba3000 AND
                                                                              x1.vsba4003 = x2.vsba3001 AND
                                                                              x1.vsba4004 = x2.vsba3002 AND
                                                                              x1.vsba4005 = x2.vsba3003
                            where x1.vsba4006 = '$vin' and x1.vsba4007 = $vinNo and x2.vsba3000 is not null and 
                            x2.vsba3006 not in (select distinct vsbb4009 from xvms_bb04 
                                                where vsbb4005 = '$vin' and vsbb4006 = $vinNo and vsbb4007 = $operationNo)
                        """, rowIndex: 0, rowSize: 65535);

    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      if (data.length > 0) {
        setState(() {
          _currentContents = data;
        });
      } else {
        //====================================
        datagram = new Datagram();
        datagram.addText("""select x1.vsba4006 as 車身號碼,
                                   x1.vsba4007 as 點交次數,
                                   $operationNo as PDI次數,
                                   row_number() over(order by getdate()) as 序號,
                                   x2.vsba3006 as 站別,
                                   x2.vsba3005 as 作業項目,
                                   x2.vsba3005 as 原作業項目,
                                   '' as 作業參數,
                                   'Y' as PDI狀態,
                                   '' as 作業小組,
                                   '' as 備註,
                                   'N' as 異常狀態,
                                   '' as 異常類別,
                                   '' as 異常說明,
                                   'A' as 資料旗標
                            from xvms_ba04 as x1 left join xvms_ba03 as x2 on x1.vsba4002 = x2.vsba3000 AND
                                                                              x1.vsba4003 = x2.vsba3001 AND
                                                                              x1.vsba4004 = x2.vsba3002 AND
                                                                              x1.vsba4005 = x2.vsba3003
                            where x1.vsba4006 = '$vin' and x1.vsba4007 = $vinNo and x2.vsba3000 is not null;
                        """, rowIndex: 0, rowSize: 65535);
        result = await Business.apiExecuteDatagram(datagram);
        if (result.flag == ResultFlag.ok) {
          List<Map<String, dynamic>> data = result.getMap();
          if (data.length > 0) {
            setState(() {
              _currentContents = data;
            });
          } else {
            setState(() {
              _currentContents = null;
            });
            _inputToolBarKey.currentState
                .showMessage(_scaffoldKey, ResultFlag.ng, '未配置作業項目');
          }
        } else {
          setState(() {
            _currentContents = null;
          });
          _inputToolBarKey.currentState
              .showMessage(_scaffoldKey, ResultFlag.ng, '未配置作業項目');
        }
        //====================================
      }
    } else {
      setState(() {
        _currentContents = null;
      });
      _inputToolBarKey.currentState
          .showMessage(_scaffoldKey, ResultFlag.ng, '未配置作業項目');
    }
  }

  Future<bool> _lockVin() async {
    if (_currentVin == null) return false;
    Datagram datagram = Datagram();
    datagram.addText(
        """update xvms_ba04 set vsba4026 = entirev4.dbo.systemdatetime(),
                                             vsba4027 = N'PDI作業下達中止'
                        where vsba4006 = '${_currentVin['車身號碼']}' and
                              vsba4007 = ${_currentVin['點交次數']} and
                              vsba4015 = ${_currentVin['PDI次數']} and
                              vsba4008 = 'N' and
                              vsba4026 = ''
                     """,
        rowIndex: 0, rowSize: 65535);

    datagram
        .addText("""update x1 set x1.vsbb4039 = entirev4.dbo.systemdatetime(),
                                  x1.vsbb4040 = N'PDI作業下達中止'
                        from xvms_bb04 as x1 left join xvms_ba04 as x2 on x1.vsbb4005 = x2.vsba4006 and
                                                                          x1.vsbb4006 = x2.vsba4007 and
                                                                          x1.vsbb4007 = x2.vsba4015
                        where x1.vsbb4005 = '${_currentVin['車身號碼']}' and
                              x1.vsbb4006 = ${_currentVin['點交次數']} and
                              x1.vsbb4007 = ${_currentVin['PDI次數']} and
                              x1.vsbb4039 = '' and
                              x2.vsba4008 = 'N'
                     """, rowIndex: 0, rowSize: 65535);

    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok)
      return true;
    else
      return false;
  }

  Future<bool> _unlockVin() async {
    if (_currentVin == null) return false;
    Datagram datagram = Datagram();
    datagram.addText("""update xvms_ba04 set vsba4025 = iif(vsba4009 = '',
                                                            vsba4025,
                                                            vsba4025 + datediff(minute,vsba4026,entirev4.dbo.systemdatetime())),
                                             vsba4026 = '',
                                             vsba4027 = ''
                        where vsba4006 = '${_currentVin['車身號碼']}' and
                              vsba4007 = ${_currentVin['點交次數']} and
                              vsba4015 = ${_currentVin['PDI次數']} and
                              vsba4026 != ''
                     """, rowIndex: 0, rowSize: 65535);

    datagram.addText("""update x1 set x1.vsbb4038 = iif(vsbb4016 = '',
                                                    vsbb4038,
                                                    vsbb4038 +  datediff(minute,vsbb4039,entirev4.dbo.systemdatetime())),
                                  x1.vsbb4039 = '',
                                  x1.vsbb4040 = ''
                    from xvms_bb04 as x1 left join xvms_ba04 as x2 on x1.vsbb4005 = x2.vsba4006 and
                                                                      x1.vsbb4006 = x2.vsba4007 and
                                                                      x1.vsbb4007 = x2.vsba4015
                    where x1.vsbb4005 = '${_currentVin['車身號碼']}' and
                          x1.vsbb4006 = ${_currentVin['點交次數']} and
                          x1.vsbb4007 = ${_currentVin['PDI次數']} and
                          x1.vsbb4039 != ''
                 """, rowIndex: 0, rowSize: 65535);

    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok)
      return true;
    else
      return false;
  }

  //顯示多車身選擇
  void showVinActionSheet(List<Map<String, dynamic>> dataList) {
    if (dataList == null) return;
    List<Widget> _list = [];

    for (int i = 0; i < dataList.length; i++) {
      _list.add(CupertinoActionSheetAction(
        child: Text(dataList[i]['車身號碼']),
        onPressed: () {
          setState(() {
            _currentVin = dataList[i];
          });
          inputToolBarValueChanged("vinAction", '');
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
        "選擇其中一台車身",
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

  //顯示部位異常分類
  void showContentBugCategoryActionSheet(String no) async {
    if (_currentVin == null || _currentVin.length == 0) return;
    List<Widget> _list = [];

    Datagram datagram = Datagram();
    datagram.addText("""select vs005001 from xvms_0050
                        """, rowIndex: 0, rowSize: 65535);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      if (data.length > 0) {
        for (int i = 0; i < data.length; i++) {
          _list.add(CupertinoActionSheetAction(
            child: Text(data[i]['vs005001']),
            //isDefaultAction: true,
            onPressed: () {
              setState(() {
                PdiItem p1 = _currentItem.firstWhere(
                    (v) => v.station == _currentStation && v.no == no);
                p1.bugStatus = (data[i]['vs005001'] == '無' ? 'N' : 'Y');
                p1.status = (data[i]['vs005001'] == '無' ? p1.status : 'Y');
                p1.bugCategory = data[i]['vs005001'];
              });

              Navigator.pop(context);
            },
          ));
        }
      }
    }

    final action = CupertinoActionSheet(
      title: Text(
        "異常原因",
        style: TextStyle(fontSize: 18),
      ),
      // message: Text(
      //   "整三裝配",
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

  void showGridViewUserActionSheet(String key) async {
    List<Widget> _list = [];

    Datagram datagram = Datagram();

    datagram.addText("""select ixa00401,
                               ixa00403
                        from entirev4.dbo.ifx_a004 where ixa00400 = 'compid' and ixa00408 = '112200'
                        """, rowIndex: 0, rowSize: 65535);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      if (data.length > 0) {
        for (int i = 0; i < data.length; i++) {
          _list.add(CupertinoActionSheetAction(
            child: Text(data[i]['ixa00401'] + ' ' + data[i]['ixa00403']),
            //isDefaultAction: true,
            onPressed: () {
              setState(() {
                inputToolBarValueChanged(key, data[i]['ixa00403']);
              });

              Navigator.pop(context);
            },
          ));
        }
      }
    }

    final action = CupertinoActionSheet(
      title: Text(
        "作業人員",
        style: TextStyle(fontSize: 18),
      ),
      message: Text(
        "整三裝配",
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

  //=======================
  Future<void> _saveTeamProfile(String key) async {
    if (_currentContents == null) return;

    List<String> list = [];
    for (int i = 0; i < _currentContents.length; i++) {
      list.add(_currentContents[i]['作業項目'] + ',' + _currentContents[i]['作業人員']);
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(moduleId + '_' + key) == true)
      prefs.remove(moduleId + '_' + key);
    prefs.setStringList(moduleId + '_' + key, list);

    _inputToolBarKey.currentState
        .showMessage(_scaffoldKey, ResultFlag.ok, '儲存完成');
  }

  Future<void> _loadTeamProfile(String key) async {
    if (_currentContents == null) return;

    SharedPreferences.getInstance().then((prefs) {
      if (prefs.containsKey(moduleId + '_' + key) == true) {
        List<String> list = prefs.getStringList(moduleId + '_' + key);

        for (int i = 0; i < list.length; i++) {
          String itemText = list[i].split(',')[0];
          String user = list[i].split(',')[1];

          if (_currentContents
                  .where((element) => (element['作業項目'] == itemText))
                  .length >
              0) {
            _currentContents.firstWhere(
                (element) => (element['作業項目'] == itemText))['作業人員'] = user;
          }
        }
        _inputToolBarKey.currentState
            .showMessage(_scaffoldKey, ResultFlag.ok, '載入完成');
        setState(() {});
      }
    });
  }

  Future<void> _loadVinPicCount(String vin, String vinNo) async {
    if (_appDocDir == null) {
      _appDocDir = await getApplicationDocumentsDirectory();
    }
    //------------------------------針對這模組下的全部車身上傳-----------------------------
    List<FileSystemEntity> allList = List<FileSystemEntity>();
    List<Map<String, dynamic>> fileList = List<Map<String, dynamic>>();
    if (Directory(_appDocDir.path +
                '/compid/' +
                imageCategory +
                '/' +
                vin +
                '-' +
                vinNo)
            .existsSync() ==
        true) {
      allList = Directory(_appDocDir.path +
              '/compid/' +
              imageCategory +
              '/' +
              vin +
              '-' +
              vinNo)
          .listSync(recursive: true, followLinks: false);

      allList.forEach((entity) {
        if (entity is File) {
          fileList.add({
            '車身號碼': path.basename(path.dirname(entity.path)),
            '檔案路徑': entity.path,
          });
        }
      });
      _currentVin['照片數'] = fileList.length;
    } else {
      _currentVin['照片數'] = 0;
    }
  }
}
