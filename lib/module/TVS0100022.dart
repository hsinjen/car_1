//import 'dart:html';
import 'dart:io';
import 'dart:convert';
import 'package:car_1/model/sysCamera.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
//import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:car_1/business/datagram.dart';
import 'package:car_1/business/responseresult.dart';
//import 'package:car_1/apis/messagebox.dart';
import 'package:car_1/business/business.dart';
import 'package:car_1/business/enums.dart';
import 'package:flutter/cupertino.dart';
//import 'package:car_1/module/CameraBoxAdv.dart';
//import 'package:path/path.dart' as path;
//import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
//import 'package:string_validator/string_validator.dart';
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
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:async';
import '../model/sysImageViewGallery.dart';

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
  String status; //PDI狀態
  String operationTeam;
  String remark;
  String bugStatus; //異常狀態
  String bugCategory;
  String bugRemark;
  String fixStatus; //修正狀態
  String fixCategory; //修正類別
  String fixRemark; //修正說明
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
      this.fixStatus = data['修正狀態'];
      this.fixCategory = data['修正類別'];
      this.fixRemark = data['修正說明'];
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

class TVS0100022 extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _TVS0100022();
  }
}

class _TVS0100022 extends State<TVS0100022> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final String moduleId = 'TVS0100022';
  final String moduleName = 'PDI 終檢確認';
  final String imageCategory = 'TVS0100022';
  String _vinFinalState = 'N'; //終檢完工狀態
  bool _isLoading = false;
  InputToolBarState _inputToolBarState;
  GlobalKey<InputToolBarContext> _inputToolBarKey;
  bool _isImageloaded = false;
  Map<String, dynamic> _currentVin;
  List<Map<String, dynamic>> _currentContents;
  String _currentStation = '終檢';
  List<PdiItem> _currentItem = [];
  List<User> _currentTeam = [];
  List<PointItem> _currentVinPoint = [];
  List<ImageItem> _currentFinalVisionImages = [];
  bool _currentVinLock = false; //車身作業中止
  List<CameraDescription> cameras;
  ui.Image _currentVisionImage;

  @override
  void initState() {
    super.initState();

    _inputToolBarKey = GlobalKey();
    _inputToolBarState = InputToolBarState();
    initVisionImage();

    SharedPreferences.getInstance().then((prefs) {
      if (prefs.containsKey(moduleId + '_teams_' + _currentStation) == true) {
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
    });
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
    // else if (action.startsWith('itemTextWithParameter') == true) {
    //   String key1 = action.split('#')[1];
    //   String key2 = action.split('#')[2];

    //   PdiItem item = _currentItem.firstWhere((element) =>
    //       element.station == _currentStation && element.no == key1);

    //   if (item != null) {
    //     PdiWidgetItem widgetItem =
    //         item.widgetFormatList.firstWhere((element) => element.id == key2);
    //     widgetItem.parameter = value;
    //   }
    // }
    //vin
    else if (action == "vin") {
      //_currentStation = '';
      _currentVin = null;
      _currentContents = null;
      _currentItem = [];
      _currentVinPoint = [];
      List<Map<String, dynamic>> data = await _loadVin(value);
      if (data == null || data.length == 0) {
        _inputToolBarKey.currentState
            .showMessage(_scaffoldKey, ResultFlag.ng, '計劃無此車身號碼或已終檢完工 $value');
      } else if (data.length > 1) {
        showVinActionSheet(data);
      } else if (data.length == 1) {
        bool isCheckLock = await _checkVinLock(data[0]['車身號碼'], station: '');
        bool b1 = await _checkOperation(data[0]['車身號碼'],
            data[0]['點交次數'].toString(), data[0]['PDI次數'].toString());
        if (b1 == false) return;

        if (data[0]['外觀圖'] != '') {
          _currentVinPoint = (json.decode(data[0]['外觀圖'].toString()) as List)
              .map((i) => PointItem.fromJson(i))
              .toList();
        }

        setState(() {
          _currentVinLock = isCheckLock;
          _currentVin = data[0];
        });
        if (_currentVin != null && _currentVinLock == false) {
          await _loadContent(
              _currentVin['車身號碼'], _currentVin['點交次數'], _currentVin['PDI次數']);
          _currentItem = [];
          if (_currentContents != null) {
            for (final item in _currentContents) {
              _currentItem.add(PdiItem(item));
            }
          } else {
            _inputToolBarState.setDefault();
            _currentVin = null;
            _currentContents = null;
            _currentItem = [];
            _currentVinPoint = [];
          }
        }
      }
    }
    //vinAction
    else if (action == "vinAction") {
      _currentContents = null;
      _currentItem = [];
      _currentVinPoint = [];
      if (_currentVin != null) {
        bool b1 = await _checkOperation(_currentVin['車身號碼'],
            _currentVin['點交次數'].toString(), _currentVin['PDI次數'].toString());
        if (b1 == false) return;

        if (_currentVin['外觀圖'] != '') {
          _currentVinPoint =
              (json.decode(_currentVin['外觀圖'].toString()) as List)
                  .map((i) => PointItem.fromJson(i))
                  .toList();
        }
        await _loadContent(
            _currentVin['車身號碼'], _currentVin['點交次數'], _currentVin['PDI次數']);
        _currentItem = [];
        if (_currentContents != null) {
          for (final item in _currentContents) {
            _currentItem.add(PdiItem(item));
          }
        } else {
          _inputToolBarState.setDefault();
          _currentVin = null;
          _currentContents = null;
          _currentItem = [];
          _currentVinPoint = [];
        }
      }
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
                // _currentStation = '';
                _currentVin = null;
                _currentVinLock = false;
                _currentContents = null;
                _currentItem = [];
                _currentVinPoint = [];
                _currentFinalVisionImages = [];
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
              if (_currentVinLock == true) {
                _inputToolBarKey.currentState
                    .showMessage(_scaffoldKey, ResultFlag.ng, '車身狀態作業中止');
                return;
              }
              if (_vinFinalState == 'Y' &&
                  (_currentVin['維修狀態'] == 'W' || _currentVin['維修狀態'] == 'S')) {
                _inputToolBarKey.currentState
                    .showMessage(_scaffoldKey, ResultFlag.ng, '維修站未完成處置');
                return;
              }

              if (_vinFinalState == 'Y' &&
                  _currentItem
                          .where(
                              (v) => v.bugStatus == 'Y' && v.fixStatus == 'N')
                          .length >
                      0) {
                _inputToolBarKey.currentState
                    .showMessage(_scaffoldKey, ResultFlag.ng, '尚有異常未修正');
                return;
              }

              if (_currentTeam == null || _currentTeam.length == 0) {
                _inputToolBarKey.currentState
                    .showMessage(_scaffoldKey, ResultFlag.ng, '未指派作業人員');
                return;
              }

              setState(() {
                _isLoading = true;
              });
              bool r1 = await _save();
              bool r2 = await _saveFile();
              if (r1 == true && r2 == true) {
                setState(() {
                  _isLoading = false;
                  _inputToolBarState.setDefault();
                  _currentVin = null;
                  _currentVinLock = false;
                  _currentContents = null;
                  _currentItem = [];
                  _currentVinPoint = [];
                  _currentFinalVisionImages = [];
                  _vinFinalState = 'N';
                });
              } else {
                if (_inputToolBarKey.currentState != null && r1 == false)
                  _inputToolBarKey.currentState
                      .showMessage(_scaffoldKey, ResultFlag.ng, '儲存失敗');
                else if (_inputToolBarKey.currentState != null && r2 == false)
                  _inputToolBarKey.currentState
                      .showMessage(_scaffoldKey, ResultFlag.ng, '上傳檔案失敗');
                setState(() {
                  _isLoading = false;
                });
              }
            },
          ),
        ],
      ),
      drawer: buildMenu(context),
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
                            decoration: BoxDecoration(
                              border: Border(
                                  top: BorderSide(width: 1),
                                  right: BorderSide(width: 1),
                                  bottom: BorderSide(width: 1)),
                            ),
                            alignment: Alignment.center,
                            width: MediaQuery.of(context).size.width / 100 * 70,
                            height: 24.0,
                            child: Text(
                                _currentVin == null ? '' : _currentVin['備註'],
                                style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        //Function ToolBar
                        Divider(height: 2.0),
                        buildStationToolBar(),
                        //
                        Divider(height: 2.0),
                        _isImageloaded == false
                            ? Container()
                            : buildHeaderOneRow(context, '外觀檢查', 100),

                        _isImageloaded == false
                            ? Container()
                            : GestureDetector(
                                onLongPress: () async {
                                  List<ImageItem> list =
                                      await _loadOnlinePdiVisionImage(
                                          _currentVin['車身號碼'],
                                          _currentVin['點交次數'].toString(),
                                          _currentVin['PDI次數'].toString());
                                  if (list != null && list.length > 0) {
                                    await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ImageIndicator(
                                            hasDelete: false,
                                            images: list,
                                            onValueChanged: () {
                                              setState(() {});
                                            },
                                          ),
                                        ));
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                      border: Border.all(width: 1)),
                                  child: CustomPaint(
                                    size: Size(
                                        _currentVisionImage.width *
                                            (MediaQuery.of(context).size.width /
                                                _currentVisionImage.width),
                                        _currentVisionImage.height *
                                            (MediaQuery.of(context).size.width /
                                                _currentVisionImage.width)),
                                    painter: ImagePainter(context,
                                        type: '全部',
                                        image: _currentVisionImage,
                                        points: _currentVinPoint,
                                        scale:
                                            MediaQuery.of(context).size.width /
                                                _currentVisionImage.width),
                                  ),
                                ),
                              ),

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
    return Container(
      alignment: Alignment.centerRight,
      width: MediaQuery.of(context).size.width,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          height: 28,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                child: Text('終檢旗標：',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
              ),
              Container(
                color: _vinFinalState == 'N' ? Colors.blue : Colors.white,
                child: FlatButton(
                  child: Text('未完工',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    setState(() {
                      _vinFinalState = 'N';
                    });
                  },
                ),
              ),
              Container(
                color: _vinFinalState == 'N' ? Colors.white : Colors.blue,
                child: FlatButton(
                  child: Text('完工',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    setState(() {
                      _vinFinalState = 'Y';
                    });
                  },
                ),
              ),
              Container(
                color: Colors.black,
                child: RaisedButton.icon(
                    color: Colors.black,
                    onPressed: () async {
                      if (_currentVin == null) {
                        _inputToolBarKey.currentState.showMessage(
                            _scaffoldKey, ResultFlag.ng, '請輸入車身號碼');
                      } else {
                        if (_currentVinLock == true) {
                          _inputToolBarKey.currentState.showMessage(
                              _scaffoldKey, ResultFlag.ng, '車身狀態作業中止');
                          return;
                        }
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
                    icon: Icon(
                      Icons.people,
                      color: Colors.white,
                    ),
                    label: Text(
                        _currentTeam.length == 0
                            ? '請指派作業人員'
                            : _currentTeam[0].userName +
                                '(' +
                                _currentTeam.length.toString() +
                                ')',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold))),
              ),
              Container(width: 3),
              Container(
                color: Colors.black,
                child: RaisedButton.icon(
                    color: _currentFinalVisionImages.length == 0
                        ? Colors.black
                        : Colors.blue,
                    onPressed: () async {
                      if (_currentVin == null || _currentVin.length == 0)
                        return;
                      if (_currentVinLock == true) {
                        _inputToolBarKey.currentState.showMessage(
                            _scaffoldKey, ResultFlag.ng, '車身狀態作業中止');
                        return;
                      }
                      if (cameras == null) cameras = await availableCameras();
                      if (cameras != null) {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CameraWindow(
                                cameraType: CameraType.camera,
                                cameraList: cameras,
                                imageDirPath: _currentVin['車身號碼'] +
                                    '\\' +
                                    _currentVin['點交次數'].toString() +
                                    '\\' +
                                    _currentVin['PDI次數'].toString(),
                                imageList: _currentFinalVisionImages,
                                keyNo: 'PDIFinalVision',
                                keyDate: '',
                                keyNumber: _currentVin['車身號碼'],
                                tag1: _currentVin['點交次數'].toString(),
                                groupKey: _currentVin['PDI次數'].toString(),
                                onConfirm: (v) {
                                  setState(() {
                                    _currentFinalVisionImages = v;
                                  });
                                },
                              ),
                            ));
                      }
                    },
                    icon: Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                    ),
                    label: Text('終檢拍照',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> buildGridView(
      BuildContext context, double width1, double width2) {
    List<Widget> _list = [];

    if (_currentItem == null || _currentItem.length == 0) return _list;

    String _initStation = '';
    for (final item in _currentItem.where((v) => v.bugStatus == 'Y')) {
      if (_initStation != item.station) {
        _list.add(buildHeaderOneRow(context, item.station, 100.0));

        _list.add(buildHeaderFourRow(
            context, '作業項目', 70, '原因', 16, '對策', 7, '動作', 7));

        _initStation = item.station;
      }
      _list.add(buildGridViewItem(context, 70, 16, 7, 7, item));
    }

    return _list;
  }

  Widget buildGridViewItem(BuildContext context, double width1, double width2,
      double width3, double width4, PdiItem data) {
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
        child: Column(children: [
          Text(data.displayText(), style: TextStyle(fontSize: 12))
        ]),
        //Column(children: [Wrap(children: itemWidget)]),
      ),
      //原因
      Container(
        padding: EdgeInsets.only(top: 3, bottom: 3, left: 4, right: 0),
        decoration: BoxDecoration(
          //color: Colors.grey[300],
          border: Border(
            //left: BorderSide(width: 0),
            top: BorderSide(width: 1),
            right: BorderSide(width: 1),
            //bottom: BorderSide(width: 1),
          ),
        ),
        alignment: Alignment.centerLeft,
        width: MediaQuery.of(context).size.width / 100 * width2,
        child: Column(
            children: [Text(data.bugCategory, style: TextStyle(fontSize: 12))]),
        //Column(children: [Wrap(children: itemWidget)]),
      ),
      //對策
      Container(
        decoration: BoxDecoration(
          //color: Colors.yellow,
          border: Border(
            top: BorderSide(width: 1),
            // right: BorderSide(width: 1),
            //bottom: BorderSide(width: 1),
          ),
        ),
        alignment: Alignment.topCenter,
        width: MediaQuery.of(context).size.width / 100 * width3,
        child: Column(
            //color: Colors.red, //Colors.grey[300],
            children: [
              SizedBox(
                height: 24,
                child: IconButton(
                  padding:
                      EdgeInsets.only(top: 0, bottom: 0, left: 0, right: 0),
                  icon: Icon(
                    Icons.bug_report,
                    color: data.fixStatus == 'N' ? Colors.red : Colors.green,
                  ),
                  iconSize: 22,
                  onPressed: () async {
                    //showContentFixCategoryActionSheet(data);
                  },
                ),
              ),
            ]),
      ),
      //動作
      Container(
        //color: Colors.red,
        child: Container(
          decoration: BoxDecoration(
            //color: Colors.yellow,
            border: Border(
              top: BorderSide(width: 1),
              right: BorderSide(width: 1),
              //bottom: BorderSide(width: 1),
            ),
          ),
          alignment: Alignment.topCenter,
          width: MediaQuery.of(context).size.width / 100 * width3,
          child: Column(
              //color: Colors.red, //Colors.grey[300],
              children: [
                SizedBox(
                  height: 24,
                  child: IconButton(
                    padding:
                        EdgeInsets.only(top: 0, bottom: 0, left: 0, right: 0),
                    icon: Icon(
                      Icons.image,
                    ),
                    iconSize: 22,
                    onPressed: () async {
                      List<ImageItem> list = await _loadOnlinePdiImage(
                          data.vin, data.vinNo, data.pdiNo, data.no);
                      if (list.length == 0) {
                        list = await _loadOnlinePdiVisionImage(
                            data.vin, data.vinNo, data.pdiNo,
                            itemText: data.itemText);
                      }

                      if (list != null && list.length > 0) {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ImageIndicator(
                                hasDelete: false,
                                images: list,
                                onValueChanged: () {
                                  setState(() {});
                                },
                              ),
                            ));
                      }
                    },
                  ),
                ),
              ]),
        ),
      ),
    ]);
  }

  Future<bool> _save() async {
    if (_currentVin == null) return false;
    if (_currentItem == null) return false;

    Datagram datagram = Datagram();

    List<PdiItem> dataList =
        _currentItem.where((element) => element.bugStatus == 'Y').toList();

    for (int i = dataList.length - 1; i >= 0; i--) {
      if (dataList[i].flag == 'D' && dataList[i].no.toString() == '0') continue;

      datagram.addText("""update xvms_bb04 set vsbb4023 = '$_vinFinalState',
                                               vsbb4024 = '${dataList[i].fixStatus}',
                                               vsbb4025 = '${dataList[i].fixCategory}',
                                               vsbb4026 = '',
                                               vsbb4027 = iif(vsbb4027 = '',entirev4.dbo.systemdate(),vsbb4027),
                                               vsbb4028 = iif(vsbb4028 = '',entirev4.dbo.systemtime(),vsbb4028),
                                               vsbb4029 = ${_vinFinalState == 'Y' ? 'entirev4.dbo.systemdate()' : "''"},
                                               vsbb4030 = ${_vinFinalState == 'Y' ? 'entirev4.dbo.systemtime()' : "''"},"
                                               vsbb4031 = ''
                          where vsbb4005 = '${dataList[i].vin}' and vsbb4006 = ${dataList[i].vinNo} and vsbb4007 = ${dataList[i].pdiNo} and vsbb4008 = ${dataList[i].no};
                       
    """, rowSize: 65535);
    }

    datagram
        .addText("""update xvms_ba04 set mod_date = entirev4.dbo.systemdate(),
                                               mod_time = entirev4.dbo.systemtime(),
                                               mod_user = '${Business.userId}',
                                               mod_dept = '${Business.deptId}',
                                               vsba4008 = '$_vinFinalState',
                                               vsba4009 = iif(vsba4009 = '',entirev4.dbo.systemdate(),vsba4009),
                                               vsba4010 = iif(vsba4010 = '',entirev4.dbo.systemtime(),vsba4010),
                                               vsba4011 = ${_vinFinalState == 'Y' ? 'entirev4.dbo.systemdate()' : "''"} ,
                                               vsba4012 = ${_vinFinalState == 'Y' ? 'entirev4.dbo.systemtime()' : "''"} ,
                                               vsba4013 = '${_currentTeam.length == 0 ? '' : jsonEncode(_currentTeam)}'
                        where vsba4006 = '${_currentVin['車身號碼']}' and vsba4007 = ${_currentVin['點交次數']} and vsba4015 = ${_currentVin['PDI次數']}
    """, rowSize: 65535);

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

    Map<String, String> headers = {
      'ModuleId': 'PDIFinalVision',
      'SubPath': 'PDIFinalVision\\' +
          _currentVin['車身號碼'] +
          '\\' +
          _currentVin['點交次數'].toString() +
          '\\' +
          _currentVin['PDI次數'].toString(),
      'ReceiptType': 'PDIFinalVision',
      'ReceiptSerial': _currentVin['車身號碼'],
      'ReceiptNo': _currentVin['點交次數'].toString(),
      'Tag1': _currentVin['PDI次數'].toString(),
      'Tag2': '',
      'Descryption': '',
      'UploadUser': Business.userId,
      'UploadDevice': '',
    };
    List<File> uploadFile = [];
    _currentFinalVisionImages.forEach((element) {
      uploadFile.add(element.file);
    });
    ResponseResult result = await Business.apiUploadFile(
        FileCmdType.file, uploadFile,
        headers: headers);
    if (result.flag == ResultFlag.ok) {
      CommonMethod.removeFilesOfDirNoQuestion(context, 'PDIFinalVision', '');
      return true;
    } else {
      return false;
    }
  }

  Future<List<ImageItem>> _loadOnlinePdiImage(
      String vin, String vinNo, String pdiNo, String no) async {
    List<ImageItem> list = [];
    Datagram datagram = Datagram();

    datagram.addText("""select file_id,
                               file_name + '.' + ext_name as [filename],
                               url  
                        from sys_file where module_id = 'PDI' and receipt_serial = '$vin' and tag1 = '$pdiNo' and tag2 = '$no' and receipt_no = '$vinNo'
    """, rowSize: 65535);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      for (int i = 0; i < data.length; i++) {
        list.add(ImageItem('',
            type: ImageSourceType.online,
            displayText: data[i]['filename'],
            url: data[i]['url']));
      }
    } else {
      if (_inputToolBarKey.currentState != null)
        _inputToolBarKey.currentState
            .showMessage(_scaffoldKey, ResultFlag.ng, result.getNGMessage());
    }
    return list;
  }

  Future<List<ImageItem>> _loadOnlinePdiVisionImage(
      String vin, String vinNo, String pdiNo,
      {String itemText = ''}) async {
    List<ImageItem> list = [];
    Datagram datagram = Datagram();

    if (itemText == '') {
      datagram.addText("""select file_id,
                               file_name + '.' + ext_name as [filename],
                               url,
                               tag2
                        from sys_file where module_id = 'PDIVision' and receipt_serial = '$vin' and tag1 = '$pdiNo' and receipt_no = '$vinNo'
    """, rowSize: 65535);
    } else {
      datagram.addText("""select file_id,
                               file_name + '.' + ext_name as [filename],
                               url,
                               tag2
                        from sys_file where module_id = 'PDIVision' and receipt_serial = '$vin' and tag1 = '$pdiNo' and receipt_no = '$vinNo' and tag2 = '$itemText'
    """, rowSize: 65535);
    }
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      for (int i = 0; i < data.length; i++) {
        list.add(ImageItem('',
            type: ImageSourceType.online,
            displayText: data[i]['tag2'],
            url: data[i]['url']));
      }
    } else {
      if (_inputToolBarKey.currentState != null)
        _inputToolBarKey.currentState
            .showMessage(_scaffoldKey, ResultFlag.ng, result.getNGMessage());
    }
    return list;
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
                               x1.vsba4008 as 終檢狀態,
                               x1.vsba4017 as 備註,
                               x3.vsaa0106 as 車色,
                               x3.vsaa0107 as 車身年份,
                               x3.vsaa0110 as 出廠年月日,
                               x3.vsaa0122 as 到港日期,
                               x1.vsba4014 as 外觀圖,
                               x1.vsba4018 as 維修狀態,
                               0 as 照片數
                        from xvms_ba04 as x1 left join vi_xvms_0001_04 as x2 on x1.vsba4002 = x2.進口商系統碼 and
                                                                                x1.vsba4003 = x2.廠牌系統碼 and
                                                                                x1.vsba4004 = x2.車款系統碼 and
                                                                                x1.vsba4005 = x2.系統碼
                                             left join xvms_aa01 as x3 on x1.vsba4006 = x3.vsaa0100 and x1.vsba4007 = x3.vsaa0119
                        where x1.vsba4008 = 'N' and x1.vsba4006 like '%$value'
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

  Future<bool> _checkOperation(String vin, String vinNo, String pdiNo) async {
    Datagram datagram = Datagram();
    datagram.addText("""select distinct x2.vsba3006
                        from xvms_ba04 as x1 left join xvms_ba03 as x2 on x1.vsba4002 = x2.vsba3000 AND
                                                  x1.vsba4003 = x2.vsba3001 AND
                                                  x1.vsba4004 = x2.vsba3002 AND
                                                  x1.vsba4005 = x2.vsba3003
                        where vsba4006 = '$vin' and vsba4007 = $vinNo and vsba4015 = $pdiNo and vsba3006 != '終檢'
                        """, rowIndex: 0, rowSize: 65535);
    datagram.addText("""select distinct vsbb4009
                        from xvms_bb04 
                        where vsbb4005 = '$vin' and vsbb4006 = $vinNo and vsbb4007 = $pdiNo
                        """, rowIndex: 0, rowSize: 65535);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMapOfIndex(0); //Source BOM
      List<Map<String, dynamic>> data2 = result.getMapOfIndex(1); //History
      if (data.length > data2.length) {
        String notDoStation = '';
        for (int i = 0; i < data.length; i++) {
          if (data2
                  .where(
                      (element) => element['vsbb4009'] == data[i]['vsba3006'])
                  .length ==
              0) {
            if (data.length - 1 == i)
              notDoStation = notDoStation + data[i]['vsba3006'];
            else
              notDoStation = notDoStation + data[i]['vsba3006'] + ',';
          }
        }
        _inputToolBarKey.currentState.showMessage(
            _scaffoldKey, ResultFlag.ng, 'PDI前製程(' + notDoStation + ')尚未完成');
        return false;
      } else
        return true;
    } else {
      _inputToolBarKey.currentState
          .showMessage(_scaffoldKey, ResultFlag.ng, result.getString());
      return false;
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
                                x1.vsbb4024 as 修正狀態,
                                x1.vsbb4025 as 修正類別,
                                x1.vsbb4026 as 修正說明,
                                'U' as 資料旗標
                        from xvms_bb04 as x1
                        where x1.vsbb4005 = '$vin' and x1.vsbb4006 = $vinNo and x1.vsbb4007 = $operationNo
                        order by iif(charindex('檢查圖',x1.vsbb4009) > 0 , -1, vsbb4008)
                        """, rowIndex: 0, rowSize: 65535);

    ResponseResult result = await Business.apiExecuteDatagram(datagram);
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
            .showMessage(_scaffoldKey, ResultFlag.ng, '車身號碼 $vin 尚未開工');
      }
    }
  }

  Future<bool> _lockVin() async {
    if (_currentVin == null) return false;
    Datagram datagram = Datagram();
    datagram.addText(
        """update xvms_ba04 set vsba4026 = entirev4.dbo.systemdatetime(),
                                             vsba4027 = N'PDI終檢確認下達中止'
                        where vsba4006 = '${_currentVin['車身號碼']}' and
                              vsba4007 = ${_currentVin['點交次數']} and
                              vsba4015 = ${_currentVin['PDI次數']} and
                              vsba4008 = 'N' and
                              vsba4026 = ''
                     """,
        rowIndex: 0, rowSize: 65535);

    datagram
        .addText("""update x1 set x1.vsbb4039 = entirev4.dbo.systemdatetime(),
                                  x1.vsbb4040 = N'PDI終檢確認下達中止'
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

  //顯示判定
  void showContentFixCategoryActionSheet(PdiItem item) async {
    if (_currentVin == null || _currentVin.length == 0) return;
    List<Widget> _list = [];

    Datagram datagram = Datagram();
    datagram.addText("""select vs005101 from xvms_0051
                        """, rowIndex: 0, rowSize: 65535);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      if (data.length > 0) {
        for (int i = 0; i < data.length; i++) {
          _list.add(CupertinoActionSheetAction(
            child: Text(data[i]['vs005101']),
            //isDefaultAction: true,
            onPressed: () {
              setState(() {
                PdiItem p1 = _currentItem.firstWhere(
                    (v) => v.station == item.station && v.no == item.no);
                p1.fixStatus = (data[i]['vs005101'] == '無' ? 'N' : 'Y');
                p1.fixCategory = data[i]['vs005101'];
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

  //=======================
  Future<Null> initVisionImage() async {
    final ByteData data = await rootBundle.load('assets/images/vin.jpg');
    _currentVisionImage = await loadImage(new Uint8List.view(data.buffer));
  }

  Future<ui.Image> loadImage(List<int> img) async {
    final Completer<ui.Image> completer = new Completer();
    ui.decodeImageFromList(img, (ui.Image img) {
      setState(() {
        _isImageloaded = true;
      });
      return completer.complete(img);
    });
    return completer.future;
  }
}
