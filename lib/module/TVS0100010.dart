import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:car_1/apis/messagebox.dart';
import 'package:car_1/business/business.dart';
import 'package:car_1/business/datagram.dart';
import 'package:car_1/business/enums.dart';
import 'package:car_1/business/responseresult.dart';
import 'package:car_1/model/localdb.dart';
import 'package:car_1/model/sysCamera.dart';
import 'package:car_1/model/sysInputToolBar.dart';
import 'package:car_1/model/sysMenu.dart';
import 'package:car_1/module/GeneralFunction.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class TVS0100010 extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _TVS0100010();
  }
}

class _TVS0100010 extends State<TVS0100010> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final String moduleId = 'TVS0100010';
  final String moduleName = '車輛檢查作業';
  final String imageCategory = 'TVS0100010';
  bool _onlineMode = true; //true: online false: offline
  InputToolBarState _inputToolBarState;
  GlobalKey<InputToolBarContext> _inputToolBarKey;

  int pages = 1;
  int selectPage = 0; // 2: 檢查作業 3:記錄作業
  bool isButtonTapped = false;
  LocalDb localDb = LocalDb();
  Map<String, dynamic> _currentData = {
    '檢查分類': null,
    '來源名稱': '',
    '實際到港日': '',
    '台數': '',
    '檢查作業檢查項次': 0,
    '檢查作業總數': '',
    '檢查作業未完成數': '',
    '檢查作業已完成數': '',
    '檢查作業車身號碼': '',
    '檢查作業廠牌': '',
    '檢查作業車款': '',
    '檢查作業車型': '',
    '記錄作業車身號碼': '',
    '記錄作業點交次數': 0,
    '記錄作業檢查項次': 0,
    '記錄作業公證': 'N',
    '記錄作業方位': null,
    '記錄作業異常位置': null,
    '記錄作業異常原因': null,
    '記錄作業檢查說明': '',
    '記錄作業判定': null,
    '檢查作業離線資料': 'N',
    '記錄作業離線資料': 'N',
    '里程數': 0,
  };
  List<CameraDescription> cameras;
  List<ImageItem> imageItemList = [];
  List<Map<String, dynamic>> _boatList = [];
  List<XVMSAA03> _xvmsaa03List = [];
  List<XVMSAA21> _xvmsaa21List = [];
  List<XVMSAB03> _xvmsab03List = [];
  List<Map<String, dynamic>> _vsaa0307List = [];
  List<Map<String, dynamic>> _vsab0311List = [];
  List<Map<String, dynamic>> _vsab0312List = [];
  List<Map<String, dynamic>> _vsab0313List = [];
  List<Map<String, dynamic>> _vsab0315List = [];

  @override
  void initState() {
    super.initState();

    _inputToolBarKey = GlobalKey();
    _inputToolBarState = InputToolBarState();

    initDatabase();
    loadBoat();
    loadVSAA0307();
    loadVSAB0311();
    loadVSAB0312();
    loadVSAB0313();
    loadVSAB0315();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
          toolbarHeight: 50,
          title: Text(moduleName),
          automaticallyImplyLeading: true,
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.home),
              onPressed: () {
                checkLocalAA03();
                checkLocalAB03();
                setState(() {
                  pages = 1;
                });
              },
            ),
          ]),
      body: controlPage(),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniStartDocked,
      drawer: buildMenu(context),
      resizeToAvoidBottomInset: true,
    );
  }

  void inputToolBarValueChanged(String action, String value) async {
    if (action == 'vin') {
      controlFlowWithVin(value);
    }
    //headerRemark 檢查說明
    else if (action == 'headerRemark') {
      _currentData['記錄作業檢查說明'] = value;
    }
    //milage 里程數
    else if (action == 'milage') {
      _currentData['里程數'] = value;
    }
    //vsaa0308 檢查項次
    else if (action == 'vsaa0308') {
      int vsaa0308 = int.tryParse(value);
      if (vsaa0308 == null) {
        _inputToolBarKey.currentState
            .showMessage(_scaffoldKey, ResultFlag.ng, '次數輸入錯誤');
        return;
      }
      _currentData['檢查作業檢查項次'] = vsaa0308;
    }
    //vsab0308 檢查項次
    else if (action == 'vsab0308') {
      int vsaa0308 = int.tryParse(value);
      if (vsaa0308 == null) {
        _inputToolBarKey.currentState
            .showMessage(_scaffoldKey, ResultFlag.ng, '次數輸入錯誤');
        return;
      }
      _currentData['記錄作業檢查項次'] = vsaa0308;
    }
  }

  void inputToolBarRefresh() {
    setState(() {});
  }

  Future<void> clearAllData() async {
    CommonMethod.removeFilesOfDirNoQuestion(context, moduleId, '');

    Datagram datagram = Datagram(databaseNameOrSid: localDb.dbName);
    datagram.addText('''delete from xvmsaa03''', rowIndex: 0, rowSize: 65535);
    datagram.addText('''delete from xvmsaa21''', rowIndex: 0, rowSize: 65535);
    datagram.addText('''delete from xvmsab03''', rowIndex: 0, rowSize: 65535);
    datagram.addText('''delete from imageitem''', rowIndex: 0, rowSize: 65535);
    await localDb.execute(datagram);

    setState(() {
      _xvmsaa03List = [];
      _xvmsaa21List = [];
      _xvmsab03List = [];

      _currentData['檢查作業車身號碼'] = '';
      _currentData['檢查作業廠牌'] = '';
      _currentData['檢查作業車款'] = '';
      _currentData['檢查作業車型'] = '';
      _currentData['記錄作業車身號碼'] = '';
      _currentData['記錄作業點交次數'] = 0;
    });
  }

  void controlFlow() async {
    //在線
    if (_onlineMode == true) {
      //檢查作業
      if (selectPage == 2) {
        //到港檢驗
        if ((_currentData['檢查分類'] as ActionSheet).contentkey == '1') {
          onlinedownloadData();
        }
        //倉儲檢驗
        else if ((_currentData['檢查分類'] as ActionSheet).contentkey == '2') {}
      }
      //記錄作業
      else if (selectPage == 3) {
        //到港檢驗
        if ((_currentData['檢查分類'] as ActionSheet).contentkey == '1') {
          onlinedownloadData();
        }
        //倉儲檢驗
        else if ((_currentData['檢查分類'] as ActionSheet).contentkey == '2') {}
      }
    }
    //離線
    else {
      //檢查作業
      if (selectPage == 2) {
        //到港檢驗
        if ((_currentData['檢查分類'] as ActionSheet).contentkey == '1') {
          offlinedownloadData();
        }
        //倉儲檢驗
        else if ((_currentData['檢查分類'] as ActionSheet).contentkey == '2') {}
      }
      //記錄作業
      else if (selectPage == 3) {
        //到港檢驗
        if ((_currentData['檢查分類'] as ActionSheet).contentkey == '1') {
          List<Map<String, dynamic>> data = await getListFromAA02();
          if (data == null) return;
          if (data.length > 0) {
            List<XVMSAA03> _xvmsaa03 = [];
            for (Map<String, dynamic> item in data) {
              XVMSAA03 xvmsaa03 = XVMSAA03();
              xvmsaa03.vsaa0300 = item['車身號碼'];
              xvmsaa03.vsaa0301 = item['進口商'];
              xvmsaa03.vsaa0302 = item['廠牌'];
              xvmsaa03.vsaa0303 = item['車款'];
              xvmsaa03.vsaa0304 = item['車型'];
              xvmsaa03.vsaa0305 = item['點交次數'];
              xvmsaa03.vsaa0306 = item['來源名稱'];
              xvmsaa03.vsaa0307 =
                  (_currentData['檢查分類'] as ActionSheet).contentkey;
              xvmsaa03.vsaa0308 = 0; //檢查項次
              xvmsaa03.vsaa0309 = 'N'; //是否檢查
              xvmsaa03.timestamp = 0; //時間標記
              _xvmsaa03.add(xvmsaa03);
            }
            setState(() {
              _xvmsaa03List = _xvmsaa03;
            });
          }
        }
        //倉儲檢驗
        else if ((_currentData['檢查分類'] as ActionSheet).contentkey == '2') {}
      }
    }
  }

  void controlFlowWithVin(String value) async {
    //在線
    if (_onlineMode == true) {
      //檢查作業
      if (selectPage == 2) {
        //到港檢驗
        if ((_currentData['檢查分類'] as ActionSheet).contentkey == '1') {
          if (_currentData['檢查作業檢查項次'] == 0) {
            _inputToolBarKey.currentState
                .showMessage(_scaffoldKey, ResultFlag.ng, '請選擇檢查次數');
            return;
          }

          if (value.length < 6) {
            _inputToolBarKey.currentState
                .showMessage(_scaffoldKey, ResultFlag.ng, '車身號碼6碼');
            return;
          }

          _currentData['檢查作業車身號碼'] = '';
          _currentData['檢查作業廠牌'] = '';
          _currentData['檢查作業車款'] = '';
          _currentData['檢查作業車型'] = '';

          List<Map<String, dynamic>> vinList = checkExistsVin(value);
          if (vinList.length == 0) {
            _inputToolBarKey.currentState
                .showMessage(_scaffoldKey, ResultFlag.ng, '無此車身號碼 $value');
            return;
          } else if (vinList.length > 1) {
            vinList.sort(
                (a, b) => a['車身號碼'].toString().compareTo(b['車身號碼'].toString()));
            String vin = await showVinActionSheet(vinList);
            if (vin == null) {
              return;
            }
            XVMSAA03 item =
                _xvmsaa03List.where((element) => element.vsaa0300 == vin).first;
            setState(() {
              _currentData['檢查作業車身號碼'] = item.vsaa0300;
              _currentData['檢查作業廠牌'] = item.vsaa0302;
              _currentData['檢查作業車款'] = item.vsaa0303;
              _currentData['檢查作業車型'] = item.vsaa0304;
              item.vsaa0309 = 'Y'; //是否檢查
              DateTime now = DateTime.now();
              item.vsaa0308 = _currentData['檢查作業檢查項次']; //檢查項次
              item.vsaa0310 = DateFormat('yyyy-MM-dd').format(now); //檢查日期
              item.vsaa0311 = DateFormat('HH:mm:ss').format(now); //檢查時間
              item.vsaa0312 = Business.userId; //檢查人員
              item.timestamp = now.millisecondsSinceEpoch; // 時間標記
            });
          } else if (vinList.length == 1) {
            XVMSAA03 item = _xvmsaa03List
                .where((element) => element.vsaa0300 == vinList.first['車身號碼'])
                .first;
            if (item.vsaa0309 == 'Y' &&
                _currentData['檢查作業檢查項次'] <= item.vsaa0308) {
              _inputToolBarKey.currentState
                  .showMessage(_scaffoldKey, ResultFlag.ng, '車身號碼已檢查 $value');
              return;
            }
            setState(() {
              _currentData['檢查作業車身號碼'] = item.vsaa0300;
              _currentData['檢查作業廠牌'] = item.vsaa0302;
              _currentData['檢查作業車款'] = item.vsaa0303;
              _currentData['檢查作業車型'] = item.vsaa0304;
              item.vsaa0309 = 'Y'; //是否檢查
              DateTime now = DateTime.now();
              item.vsaa0308 = _currentData['檢查作業檢查項次']; //檢查項次
              item.vsaa0310 = DateFormat('yyyy-MM-dd').format(now); //檢查日期
              item.vsaa0311 = DateFormat('HH:mm:ss').format(now); //檢查時間
              item.vsaa0312 = Business.userId; //檢查人員
              item.timestamp = now.millisecondsSinceEpoch; // 時間標記
            });
          }
        }

        //倉儲檢驗
        else if ((_currentData['檢查分類'] as ActionSheet).contentkey == '2') {
          if (_currentData['檢查作業檢查項次'] == 0) {
            _inputToolBarKey.currentState
                .showMessage(_scaffoldKey, ResultFlag.ng, '請選擇檢查次數');
            return;
          }

          if (value.length < 6) {
            _inputToolBarKey.currentState
                .showMessage(_scaffoldKey, ResultFlag.ng, '車身號碼6碼');
            return;
          }

          _currentData['來源名稱'] = '';
          _currentData['檢查作業車身號碼'] = '';
          _currentData['檢查作業廠牌'] = '';
          _currentData['檢查作業車款'] = '';
          _currentData['檢查作業車型'] = '';

          Map<String, dynamic> map = await checkExistsVinWithDB(value);
          if (map == null) {
            _inputToolBarKey.currentState
                .showMessage(_scaffoldKey, ResultFlag.ng, '無此車身號碼 $value');
            return;
          }
          if (map['車身號碼'] == '') {
            return;
          }

          if (_xvmsaa03List
                  .where(
                      (element) => element.vsaa0300 == map['車身號碼'].toString())
                  .length >
              0) {
            XVMSAA03 temp = _xvmsaa03List.firstWhere(
                (element) => element.vsaa0300 == map['車身號碼'].toString()); //時間標記
            setState(() {
              _currentData['來源名稱'] = temp.vsaa0306;
              _currentData['檢查作業車身號碼'] = temp.vsaa0300;
              _currentData['檢查作業廠牌'] = temp.vsaa0302;
              _currentData['檢查作業車款'] = temp.vsaa0303;
              _currentData['檢查作業車型'] = temp.vsaa0304;
              temp.timestamp = DateTime.now().millisecondsSinceEpoch;
            });
            return;
          }
          XVMSAA03 xvmsaa03 = XVMSAA03();
          xvmsaa03.vsaa0300 = map['車身號碼'];
          xvmsaa03.vsaa0301 = map['進口商'];
          xvmsaa03.vsaa0302 = map['廠牌'];
          xvmsaa03.vsaa0303 = map['車款'];
          xvmsaa03.vsaa0304 = map['車型'];
          xvmsaa03.vsaa0305 = map['點交次數'];
          xvmsaa03.vsaa0306 = map['來源名稱'];
          xvmsaa03.vsaa0307 = (_currentData['檢查分類'] as ActionSheet).contentkey;
          xvmsaa03.vsaa0308 = _currentData['檢查作業檢查項次']; //檢查項次
          xvmsaa03.vsaa0309 = 'Y'; //是否檢查
          DateTime now = DateTime.now();
          xvmsaa03.vsaa0310 = DateFormat('yyyy-MM-dd').format(now); //檢查日期
          xvmsaa03.vsaa0311 = DateFormat('HH:mm:ss').format(now); //檢查時間
          xvmsaa03.vsaa0312 = Business.userId; //檢查人員
          xvmsaa03.timestamp = now.millisecondsSinceEpoch; //時間標記
          _xvmsaa03List.add(xvmsaa03);
          setState(() {
            _currentData['來源名稱'] = xvmsaa03.vsaa0306;
            _currentData['檢查作業車身號碼'] = xvmsaa03.vsaa0300;
            _currentData['檢查作業廠牌'] = xvmsaa03.vsaa0302;
            _currentData['檢查作業車款'] = xvmsaa03.vsaa0303;
            _currentData['檢查作業車型'] = xvmsaa03.vsaa0304;
          });
        }
      }
      //記錄作業
      else if (selectPage == 3) {
        //到港檢驗
        if ((_currentData['檢查分類'] as ActionSheet).contentkey == '1') {
          if (value.length < 6) {
            _inputToolBarKey.currentState
                .showMessage(_scaffoldKey, ResultFlag.ng, '車身號碼6碼');
            return;
          }

          //刪除圖片
          for (ImageItem item in imageItemList) {
            CommonMethod.removeFilesOfDirNoQuestion(
                context, moduleId, item.tag1);
          }
          //清除資料
          setState(() {
            _xvmsab03List = [];
            imageItemList = [];
          });

          _currentData['來源名稱'] = '';
          _currentData['記錄作業車身號碼'] = '';
          _currentData['記錄作業點交次數'] = 0;

          List<Map<String, dynamic>> vinList = checkExistsVin(value);
          if (vinList.length == 0) {
            _inputToolBarKey.currentState
                .showMessage(_scaffoldKey, ResultFlag.ng, '無此車身號碼 $value');
            return;
          } else if (vinList.length > 1) {
            vinList.sort(
                (a, b) => a['車身號碼'].toString().compareTo(b['車身號碼'].toString()));
            String vin = await showVinActionSheet(vinList);
            if (vin == null) {
              return;
            }
            XVMSAA03 item =
                _xvmsaa03List.where((element) => element.vsaa0300 == vin).first;
            setState(() {
              _currentData['來源名稱'] = item.vsaa0306;
              _currentData['記錄作業車身號碼'] = item.vsaa0300;
              _currentData['記錄作業點交次數'] = item.vsaa0305;
            });
          } else if (vinList.length == 1) {
            XVMSAA03 item = _xvmsaa03List
                .where((element) => element.vsaa0300 == vinList.first['車身號碼'])
                .first;
            setState(() {
              _currentData['來源名稱'] = item.vsaa0306;
              _currentData['記錄作業車身號碼'] = item.vsaa0300;
              _currentData['記錄作業點交次數'] = item.vsaa0305;
            });
          }
        }
        //倉儲檢驗
        else if ((_currentData['檢查分類'] as ActionSheet).contentkey == '2') {
          if (value.length < 6) {
            _inputToolBarKey.currentState
                .showMessage(_scaffoldKey, ResultFlag.ng, '車身號碼6碼');
            return;
          }

          Map<String, dynamic> map = await checkExistsVinWithDB(value);
          if (map == null) {
            _inputToolBarKey.currentState
                .showMessage(_scaffoldKey, ResultFlag.ng, '無此車身號碼 $value');
            return;
          }
          if (map['車身號碼'] == '') {
            return;
          }

          //刪除圖片
          for (ImageItem item in imageItemList) {
            CommonMethod.removeFilesOfDirNoQuestion(
                context, moduleId, item.tag1);
          }
          //清除資料
          setState(() {
            _xvmsab03List = [];
            imageItemList = [];
            _currentData['來源名稱'] = map['來源名稱'];
            _currentData['記錄作業車身號碼'] = map['車身號碼'];
            _currentData['記錄作業點交次數'] = map['點交次數'];
          });
        }
      }
    }
    //離線
    else {
      //檢查作業
      if (selectPage == 2) {
        //到港檢驗
        if ((_currentData['檢查分類'] as ActionSheet).contentkey == '1') {
          if (_currentData['檢查作業檢查項次'] == 0) {
            _inputToolBarKey.currentState
                .showMessage(_scaffoldKey, ResultFlag.ng, '請選擇檢查次數');
            return;
          }

          if (value.length < 6) {
            _inputToolBarKey.currentState
                .showMessage(_scaffoldKey, ResultFlag.ng, '車身號碼6碼');
            return;
          }

          _currentData['檢查作業車身號碼'] = '';
          _currentData['檢查作業廠牌'] = '';
          _currentData['檢查作業車款'] = '';
          _currentData['檢查作業車型'] = '';

          List<Map<String, dynamic>> vinList = checkExistsVin(value);
          if (vinList.length == 0) {
            _inputToolBarKey.currentState
                .showMessage(_scaffoldKey, ResultFlag.ng, '無此車身號碼 $value');
            return;
          } else if (vinList.length > 1) {
            vinList.sort(
                (a, b) => a['車身號碼'].toString().compareTo(b['車身號碼'].toString()));
            String vin = await showVinActionSheet(vinList);
            if (vin == null) {
              return;
            }
            XVMSAA03 item =
                _xvmsaa03List.where((element) => element.vsaa0300 == vin).first;
            setState(() {
              _currentData['檢查作業車身號碼'] = item.vsaa0300;
              _currentData['檢查作業廠牌'] = item.vsaa0302;
              _currentData['檢查作業車款'] = item.vsaa0303;
              _currentData['檢查作業車型'] = item.vsaa0304;
              item.vsaa0309 = 'Y'; //是否檢查
              DateTime now = DateTime.now();
              item.vsaa0308 = _currentData['檢查作業檢查項次']; //檢查項次
              item.vsaa0310 = DateFormat('yyyy-MM-dd').format(now); //檢查日期
              item.vsaa0311 = DateFormat('HH:mm:ss').format(now); //檢查時間
              item.vsaa0312 = Business.userId; //檢查人員
              item.timestamp = now.millisecondsSinceEpoch; // 時間標記
            });
          } else if (vinList.length == 1) {
            XVMSAA03 item = _xvmsaa03List
                .where((element) => element.vsaa0300 == vinList.first['車身號碼'])
                .first;
            setState(() {
              _currentData['檢查作業車身號碼'] = item.vsaa0300;
              _currentData['檢查作業廠牌'] = item.vsaa0302;
              _currentData['檢查作業車款'] = item.vsaa0303;
              _currentData['檢查作業車型'] = item.vsaa0304;
              item.vsaa0309 = 'Y'; //是否檢查
              DateTime now = DateTime.now();
              item.vsaa0308 = _currentData['檢查作業檢查項次']; //檢查項次
              item.vsaa0310 = DateFormat('yyyy-MM-dd').format(now); //檢查日期
              item.vsaa0311 = DateFormat('HH:mm:ss').format(now); //檢查時間
              item.vsaa0312 = Business.userId; //檢查人員
              item.timestamp = now.millisecondsSinceEpoch; // 時間標記
            });
          }
        }
        //倉儲檢驗
        else if ((_currentData['檢查分類'] as ActionSheet).contentkey == '2') {
          if (_currentData['檢查作業檢查項次'] == 0) {
            _inputToolBarKey.currentState
                .showMessage(_scaffoldKey, ResultFlag.ng, '請選擇檢查次數');
            return;
          }

          if (value.length < 17) {
            _inputToolBarKey.currentState
                .showMessage(_scaffoldKey, ResultFlag.ng, '車身號碼17碼');
            return;
          }

          XVMSAA03 xvmsaa03 = XVMSAA03();
          xvmsaa03.vsaa0300 = value; //車身號碼
          xvmsaa03.vsaa0301 = ''; //進口商
          xvmsaa03.vsaa0302 = ''; //廠牌
          xvmsaa03.vsaa0303 = ''; //車款
          xvmsaa03.vsaa0304 = ''; //車型
          xvmsaa03.vsaa0305 = 0; //點交次數
          xvmsaa03.vsaa0306 = '';
          xvmsaa03.vsaa0307 = (_currentData['檢查分類'] as ActionSheet).contentkey;
          xvmsaa03.vsaa0308 = _currentData['檢查作業檢查項次']; //檢查項次
          xvmsaa03.vsaa0309 = 'Y'; //是否檢查
          DateTime now = DateTime.now();
          xvmsaa03.vsaa0310 = DateFormat('yyyy-MM-dd').format(now); //檢查日期
          xvmsaa03.vsaa0311 = DateFormat('HH:mm:ss').format(now); //檢查時間
          xvmsaa03.vsaa0312 = Business.userId; //檢查人員
          xvmsaa03.timestamp = now.millisecondsSinceEpoch; //時間標記
          _xvmsaa03List.add(xvmsaa03);

          setState(() {
            _currentData['檢查作業車身號碼'] = value;
          });
        }
      }
      //記錄作業
      else if (selectPage == 3) {
        //到港檢驗
        if ((_currentData['檢查分類'] as ActionSheet).contentkey == '1') {
          if (value.length < 6) {
            _inputToolBarKey.currentState
                .showMessage(_scaffoldKey, ResultFlag.ng, '車身號碼6碼');
            return;
          }

          //刪除圖片
          for (ImageItem item in imageItemList) {
            CommonMethod.removeFilesOfDirNoQuestion(
                context, moduleId, item.tag1);
          }
          //清除資料
          setState(() {
            _xvmsab03List = [];
            imageItemList = [];
          });

          _currentData['來源名稱'] = '';
          _currentData['記錄作業車身號碼'] = '';
          _currentData['記錄作業點交次數'] = 0;

          List<Map<String, dynamic>> vinList = checkExistsVin(value);
          if (vinList.length == 0) {
            _inputToolBarKey.currentState
                .showMessage(_scaffoldKey, ResultFlag.ng, '無此車身號碼 $value');
            return;
          } else if (vinList.length > 1) {
            vinList.sort(
                (a, b) => a['車身號碼'].toString().compareTo(b['車身號碼'].toString()));
            String vin = await showVinActionSheet(vinList);
            if (vin == null) {
              return;
            }
            XVMSAA03 item =
                _xvmsaa03List.where((element) => element.vsaa0300 == vin).first;
            setState(() {
              _currentData['來源名稱'] = item.vsaa0306;
              _currentData['記錄作業車身號碼'] = item.vsaa0300;
              _currentData['記錄作業點交次數'] = item.vsaa0305;
            });
          } else if (vinList.length == 1) {
            XVMSAA03 item = _xvmsaa03List
                .where((element) => element.vsaa0300 == vinList.first['車身號碼'])
                .first;
            setState(() {
              _currentData['來源名稱'] = item.vsaa0306;
              _currentData['記錄作業車身號碼'] = item.vsaa0300;
              _currentData['記錄作業點交次數'] = item.vsaa0305;
            });
          }
        }
        //倉儲檢驗
        else if ((_currentData['檢查分類'] as ActionSheet).contentkey == '2') {
          if (_currentData['記錄作業檢查項次'] == 0) {
            _inputToolBarKey.currentState
                .showMessage(_scaffoldKey, ResultFlag.ng, '請選擇檢查次數');
            return;
          }

          if (value.length < 17) {
            _inputToolBarKey.currentState
                .showMessage(_scaffoldKey, ResultFlag.ng, '車身號碼17碼');
            return;
          }

          setState(() {
            _currentData['來源名稱'] = '';
            _currentData['記錄作業車身號碼'] = value;
            _currentData['記錄作業點交次數'] = 0;
          });
        }
      }
    }
  }

  Widget controlPage() {
    if (pages == 1) {
      return page1();
    } else if (pages == 2) {
      return page2();
    } else if (pages == 3) {
      return page3();
    } else {
      return Container();
    }
  }

  //下載作業
  Widget page1() {
    return Container(
      child: Column(
        children: [
          Row(
            children: [
              buildOne('選擇模式', 25),
              Container(
                color: Colors.grey[300],
                child: GestureDetector(
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(width: 1),
                        right: BorderSide(width: 1),
                        left: BorderSide(width: 1),
                        bottom: BorderSide(width: 1),
                      ),
                    ),
                    width: MediaQuery.of(context).size.width / 100 * 25,
                    height: 29.0,
                    child: Text((_onlineMode == true ? '在線' : '離線')),
                  ),
                  onTap: () {
                    setState(() {
                      if (_onlineMode == true)
                        _onlineMode = false;
                      else
                        _onlineMode = true;
                    });
                  },
                ),
              ),
            ],
          ),
          Row(
            children: [
              buildOne('選擇作業', 25),
              Container(
                color: selectPage == 2 ? Colors.orange : Colors.grey[300],
                child: GestureDetector(
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(width: 1),
                        right: BorderSide(width: 1),
                        left: BorderSide(width: 1),
                        bottom: BorderSide(width: 1),
                      ),
                    ),
                    width: MediaQuery.of(context).size.width / 100 * 25,
                    height: 29.0,
                    child: Text('檢查作業'),
                  ),
                  onTap: () {
                    setState(() {
                      selectPage = 2;
                    });
                  },
                ),
              ),
              Container(
                color: selectPage == 3 ? Colors.orange : Colors.grey[300],
                child: GestureDetector(
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(width: 1),
                        right: BorderSide(width: 1),
                        left: BorderSide(width: 1),
                        bottom: BorderSide(width: 1),
                      ),
                    ),
                    width: MediaQuery.of(context).size.width / 100 * 25,
                    height: 29.0,
                    child: Text('記錄作業'),
                  ),
                  onTap: () {
                    setState(() {
                      selectPage = 3;
                    });
                  },
                ),
              ),
            ],
          ),
          Row(
            children: [
              buildOne('檢查分類', 25),
              //檢查分類
              Container(
                color: Colors.grey[300],
                child: GestureDetector(
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(width: 1),
                        right: BorderSide(width: 1),
                        left: BorderSide(width: 1),
                        bottom: BorderSide(width: 1),
                      ),
                    ),
                    width: MediaQuery.of(context).size.width / 100 * 25,
                    height: 29.0,
                    child: Text(_currentData['檢查分類'] != null
                        ? (_currentData['檢查分類'] as ActionSheet).contentvalue
                        : ''),
                  ),
                  onTap: () async {
                    setState(() {
                      _currentData['來源名稱'] = '';
                      _currentData['實際到港日'] = '';
                      _currentData['台數'] = '';
                    });
                    showActionSheet(
                        ActionSheet('檢查分類', '檢查分類', 'ixa00700', 'ixa00701'),
                        _vsaa0307List);
                  },
                ),
              ),
            ],
          ),
          _currentData['檢查分類'] != null &&
                  (_currentData['檢查分類'] as ActionSheet).contentkey == '1'
              ? Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          color: Colors.grey[300],
                          child: GestureDetector(
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(width: 1),
                                  right: BorderSide(width: 1),
                                  left: BorderSide(width: 1),
                                  bottom: BorderSide(width: 1),
                                ),
                              ),
                              width:
                                  MediaQuery.of(context).size.width / 100 * 25,
                              height: 36.0,
                              child: Text('來源名稱'),
                            ),
                            onTap: () {
                              showBoatActionSheet();
                            },
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        buildOne('來源名稱', 25),
                        buildOne(_currentData['來源名稱'].toString(), 75),
                      ],
                    ),
                    Row(
                      children: [
                        buildOne('實際到港日', 25),
                        buildOne(_currentData['實際到港日'].toString(), 75),
                      ],
                    ),
                    Row(
                      children: [
                        buildOne('台數', 25),
                        buildOne(_currentData['台數'].toString(), 75),
                      ],
                    ),
                  ],
                )
              : Container(
                  height: 88.0,
                ),
          Row(
            children: [
              Container(
                color: Colors.grey[300],
                child: GestureDetector(
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(width: 1),
                        right: BorderSide(width: 1),
                        left: BorderSide(width: 1),
                        bottom: BorderSide(width: 1),
                      ),
                    ),
                    width: MediaQuery.of(context).size.width / 100 * 25,
                    height: 29.0,
                    child: Text('前往作業'),
                  ),
                  onTap: () async {
                    if (selectPage == 0) {
                      MessageBox.showWarning(context, '', '請選擇作業');
                      return;
                    }
                    if (_currentData['檢查分類'] == null) {
                      MessageBox.showWarning(context, '', '請選擇檢查分類');
                      return;
                    }
                    //當為到港檢驗必須選擇來源名稱
                    if ((_currentData['檢查分類'] as ActionSheet).contentkey ==
                            '1' &&
                        _currentData['來源名稱'] == '') {
                      MessageBox.showWarning(context, '', '請選擇來源名稱');
                      return;
                    }

                    if (_currentData['檢查作業離線資料'] == 'Y' ||
                        _currentData['記錄作業離線資料'] == 'Y') {
                      MessageBox.showQuestion(
                          context, '', '離線資料尚未上傳,將會清空資料,重製作業,是否繼續?',
                          yesFunc: () async {
                        await clearAllData();

                        controlFlow();

                        setState(() {
                          pages = selectPage;
                        });
                      });
                    } else {
                      await clearAllData();

                      controlFlow();

                      setState(() {
                        pages = selectPage;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          Container(
            alignment: Alignment.center,
            color: Colors.grey,
            width: MediaQuery.of(context).size.width,
            child: Text('離線'),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    child: Row(
                      children: [
                        buildOne('檢查作業', 25),
                        buildOne('離線資料:' + _currentData['檢查作業離線資料'], 35),
                        _currentData['檢查作業離線資料'] == 'Y'
                            ? Container(
                                color: Colors.grey[300],
                                child: GestureDetector(
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(width: 1),
                                        right: BorderSide(width: 1),
                                        left: BorderSide(width: 1),
                                        bottom: BorderSide(width: 1),
                                      ),
                                    ),
                                    width: MediaQuery.of(context).size.width /
                                        100 *
                                        25,
                                    height: 29.0,
                                    child: Text('上傳'),
                                  ),
                                  onTap: () async {
                                    await uploadaa03();
                                    await uploadaa21();
                                    await uploadImageItem();
                                    await uploadUpdateSerNoFromAA21();
                                  },
                                ),
                              )
                            : Container(),
                      ],
                    ),
                  ),
                  Container(
                    child: Row(
                      children: [
                        buildOne('記錄作業', 25),
                        buildOne('離線資料:' + _currentData['記錄作業離線資料'], 35),
                        _currentData['記錄作業離線資料'] == 'Y'
                            ? Container(
                                color: Colors.grey[300],
                                child: GestureDetector(
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(width: 1),
                                        right: BorderSide(width: 1),
                                        left: BorderSide(width: 1),
                                        bottom: BorderSide(width: 1),
                                      ),
                                    ),
                                    width: MediaQuery.of(context).size.width /
                                        100 *
                                        25,
                                    height: 29.0,
                                    child: Text('上傳'),
                                  ),
                                  onTap: () async {
                                    bool boo = await uploadab03();
                                    if (boo == true) {
                                      await uploadImageItem();
                                      await uploadUpdateSerNoFromAB03();
                                    }
                                  },
                                ),
                              )
                            : Container(),
                      ],
                    ),
                  ),
                  Container(
                    child: Row(
                      children: [
                        buildOne('離線資料', 25),
                        Container(
                          color: Colors.grey[300],
                          child: GestureDetector(
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(width: 1),
                                  right: BorderSide(width: 1),
                                  left: BorderSide(width: 1),
                                  bottom: BorderSide(width: 1),
                                ),
                              ),
                              width:
                                  MediaQuery.of(context).size.width / 100 * 25,
                              height: 29.0,
                              child: Text('清空'),
                            ),
                            onTap: () async {
                              await clearAllData();
                              checkLocalAA03();
                              checkLocalAB03();
                            },
                          ),
                        ),
                        buildOne('是否有離線資料', 30),
                        Container(
                          color: Colors.grey[300],
                          child: GestureDetector(
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(width: 1),
                                  right: BorderSide(width: 1),
                                  left: BorderSide(width: 1),
                                  bottom: BorderSide(width: 1),
                                ),
                              ),
                              width:
                                  MediaQuery.of(context).size.width / 100 * 20,
                              height: 29.0,
                              child: Text('刷新'),
                            ),
                            onTap: () async {
                              checkLocalAA03();
                              checkLocalAB03();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  //檢查作業
  Widget page2() {
    int iscompleteN = 0;
    int iscompleteY = 0;
    iscompleteN =
        _xvmsaa03List.where((element) => element.vsaa0309 == 'N').length;
    iscompleteY =
        _xvmsaa03List.where((element) => element.vsaa0309 == 'Y').length;
    //_xvmsaa03List.sort((a, b) => a.vsaa0300.compareTo(b.vsaa0300));
    _xvmsaa03List.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return Container(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    children: [
                      //檢查作業檢查項次
                      buildOne('檢查次數', 25),
                      Container(
                        color: Colors.grey[300],
                        child: GestureDetector(
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(width: 1),
                                right: BorderSide(width: 1),
                                left: BorderSide(width: 1),
                                bottom: BorderSide(width: 1),
                              ),
                            ),
                            width: MediaQuery.of(context).size.width / 100 * 25,
                            height: 29.0,
                            child: Text(_currentData['檢查作業檢查項次'].toString()),
                          ),
                          onTap: () {
                            setState(() {
                              _inputToolBarState.showKeyboard(
                                  'vsaa0308', TextInputType.number);
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 100 * 30,
                        height: 29.0,
                      ),
                      //儲存
                      Container(
                        color: Colors.grey[300],
                        child: GestureDetector(
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(width: 1),
                                right: BorderSide(width: 1),
                                left: BorderSide(width: 1),
                                bottom: BorderSide(width: 1),
                              ),
                            ),
                            width: MediaQuery.of(context).size.width / 100 * 20,
                            height: 29.0,
                            child: Text('儲存'),
                          ),
                          onTap: () async {
                            if (isButtonTapped == false) {
                              isButtonTapped = true;
                              if (_onlineMode == true) {
                                bool boo = await onlineSavexvmsaa03();
                                if (boo == true) {
                                  onlineSavexvmsaa21();
                                  await onlineSaveFile();
                                }
                              } else {
                                await offlineSavexvmsaa03();
                                await offlineSavexvmsaa21();
                                await offlineSaveFile();
                              }
                              isButtonTapped = false;
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  //總數
                  Row(
                    children: [
                      buildOne('總數', 16),
                      buildOne(_currentData['台數'].toString(), 16),
                      buildOne('未完成數', 16),
                      buildOne(iscompleteN.toString(), 16),
                      buildOne('已完成數', 16),
                      buildOne(iscompleteY.toString(), 20),
                    ],
                  ),
                  //船名
                  Row(
                    children: [
                      buildOne('船名', 25),
                      buildOne(_currentData['來源名稱'], 75),
                    ],
                  ),
                  //車身號碼
                  Row(
                    children: [
                      buildOne('車身號碼', 25),
                      buildOne(_currentData['檢查作業車身號碼'], 75),
                    ],
                  ),
                  Row(
                    children: [
                      buildOne('廠牌', 25),
                      buildOne(_currentData['檢查作業廠牌'], 75),
                    ],
                  ),
                  Row(
                    children: [
                      buildOne('車款', 25),
                      buildOne(_currentData['檢查作業車款'], 75),
                    ],
                  ),
                  Row(
                    children: [
                      buildOne('車型', 25),
                      buildOne(_currentData['檢查作業車型'], 75),
                    ],
                  ),
                  Row(
                    children: [
                      buildOne('檢查分類', 25),
                      buildOne(
                          _currentData['檢查分類'] != null
                              ? (_currentData['檢查分類'] as ActionSheet)
                                  .contentvalue
                              : '',
                          25),
                    ],
                  ),
                  Row(
                    children: [
                      buildOne('里程數', 25),
                      Container(
                        color: Colors.grey[300],
                        child: GestureDetector(
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(width: 1),
                                right: BorderSide(width: 1),
                                left: BorderSide(width: 1),
                                bottom: BorderSide(width: 1),
                              ),
                            ),
                            width: MediaQuery.of(context).size.width / 100 * 25,
                            height: 29.0,
                            child: Text(_currentData['里程數'].toString()),
                          ),
                          onTap: () async {
                            setState(() {
                              _inputToolBarState.showKeyboard(
                                  'milage', TextInputType.number);
                            });
                          },
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width / 100 * 25,
                        height: 29.0,
                        child: GestureDetector(
                          onLongPress: () async {
                            if (_currentData['檢查作業車身號碼'] == '') {
                              return;
                            }
                            XVMSAA03 item = _xvmsaa03List.firstWhere(
                                (element) =>
                                    element.vsaa0300 ==
                                    _currentData['檢查作業車身號碼']);
                            XVMSAA21 xvmsaa21 = XVMSAA21();
                            xvmsaa21.vsaa2100 = item.vsaa0300;
                            xvmsaa21.vsaa2105 = item.vsaa0305;
                            int milage = int.tryParse(_currentData['里程數']);
                            xvmsaa21.vsaa2107 = milage;
                            xvmsaa21.companyId = Business.companyId;
                            xvmsaa21.deptId = Business.deptId;
                            xvmsaa21.userId = Business.userId;
                            xvmsaa21.uuid = Uuid().v4();
                            setState(() {
                              _xvmsaa21List.add(xvmsaa21);
                            });
                            if (cameras == null)
                              cameras = await availableCameras();
                            if (cameras != null) {
                              await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CameraWindow(
                                      cameraType: CameraType.cameraWithLamp,
                                      cameraList: cameras,
                                      imageDirPath:
                                          moduleId + '/' + xvmsaa21.uuid,
                                      imageList: imageItemList
                                          .where((element) =>
                                              element.tag1 == xvmsaa21.uuid)
                                          .toList(),
                                      keyNo: xvmsaa21.vsaa2100,
                                      keyDate: xvmsaa21.vsaa2105.toString(),
                                      keyNumber: '里程數', //里程數
                                      tag1: xvmsaa21.uuid,
                                      tag2: '',
                                      groupKey: moduleId,
                                      onConfirm: (v) {
                                        imageItemList.removeWhere((element) =>
                                            element.tag1 == xvmsaa21.uuid);
                                        for (var item in v) {
                                          imageItemList.add(item);
                                        }
                                      },
                                    ),
                                  ));
                            }
                          },
                          child: IconButton(
                            padding: EdgeInsets.only(top: 0.0),
                            icon: Icon(Icons.camera),
                            onPressed: () async {
                              if (_currentData['檢查作業車身號碼'] == '') {
                                return;
                              }
                              XVMSAA03 item = _xvmsaa03List.firstWhere(
                                  (element) =>
                                      element.vsaa0300 ==
                                      _currentData['檢查作業車身號碼']);
                              XVMSAA21 xvmsaa21 = XVMSAA21();
                              xvmsaa21.vsaa2100 = item.vsaa0300;
                              xvmsaa21.vsaa2105 = item.vsaa0305;
                              int milage = int.tryParse(_currentData['里程數']);
                              xvmsaa21.vsaa2107 = milage;
                              xvmsaa21.companyId = Business.companyId;
                              xvmsaa21.deptId = Business.deptId;
                              xvmsaa21.userId = Business.userId;
                              xvmsaa21.uuid = Uuid().v4();
                              debugPrint(xvmsaa21.uuid);
                              setState(() {
                                _xvmsaa21List.add(xvmsaa21);
                              });
                              if (cameras == null)
                                cameras = await availableCameras();
                              if (cameras != null) {
                                await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CameraWindow(
                                        cameraType: CameraType.camera,
                                        cameraList: cameras,
                                        imageDirPath:
                                            moduleId + '/' + xvmsaa21.uuid,
                                        imageList: imageItemList
                                            .where((element) =>
                                                element.tag1 == xvmsaa21.uuid)
                                            .toList(),
                                        keyNo: xvmsaa21.vsaa2100,
                                        keyDate: xvmsaa21.vsaa2105.toString(),
                                        keyNumber: '里程數',
                                        tag1: xvmsaa21.uuid,
                                        tag2: '',
                                        groupKey: moduleId,
                                        onConfirm: (v) {
                                          imageItemList.removeWhere((element) =>
                                              element.tag1 == xvmsaa21.uuid);
                                          for (var item in v) {
                                            imageItemList.add(item);
                                          }
                                        },
                                      ),
                                    ));
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        color: Colors.grey,
                        width: MediaQuery.of(context).size.width / 100 * 20,
                        height: 29.0,
                        child: Text('廠牌'),
                      ),
                      Container(
                        color: Colors.grey,
                        width: MediaQuery.of(context).size.width / 100 * 25,
                        height: 29.0,
                        child: Text('車款'),
                      ),
                      Container(
                        color: Colors.grey,
                        width: MediaQuery.of(context).size.width / 100 * 55,
                        height: 29.0,
                        child: Text('車身號碼'),
                      ),
                    ],
                  ),
                  buildXVMSAA03ist(_xvmsaa03List),
                ],
              ),
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
              )),
        ],
      ),
    );
  }

  //記錄作業
  Widget page3() {
    return Container(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    children: [
                      buildOne('船名', 25),
                      buildOne(_currentData['來源名稱'], 50),
                      //儲存
                      Container(
                        color: Colors.grey[300],
                        child: GestureDetector(
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(width: 1),
                                right: BorderSide(width: 1),
                                left: BorderSide(width: 1),
                                bottom: BorderSide(width: 1),
                              ),
                            ),
                            width: MediaQuery.of(context).size.width / 100 * 25,
                            height: 29.0,
                            child: Text('儲存'),
                          ),
                          onTap: () async {
                            if (isButtonTapped == false) {
                              isButtonTapped = true;
                              if (_onlineMode == true) {
                                bool boo = await onlineSavexvmsab03();
                                if (boo == true) await onlineSaveFile();
                              } else {
                                await offlineSavexvmsab03();
                                await offlineSaveFile();
                              }
                              isButtonTapped = false;
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      buildOne('車身號碼', 25),
                      buildOne(_currentData['記錄作業車身號碼'], 75),
                    ],
                  ),
                  Row(
                    children: [
                      buildOne('檢查分類', 25),
                      buildOne(
                          _currentData['檢查分類'] != null
                              ? (_currentData['檢查分類'] as ActionSheet)
                                  .contentvalue
                              : '',
                          25),
                    ],
                  ),
                  Row(
                    children: [
                      buildOne('檢查次數', 25),
                      Container(
                        color: Colors.grey[300],
                        child: GestureDetector(
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(width: 1),
                                right: BorderSide(width: 1),
                                left: BorderSide(width: 1),
                                bottom: BorderSide(width: 1),
                              ),
                            ),
                            width: MediaQuery.of(context).size.width / 100 * 25,
                            height: 29.0,
                            child: Text(_currentData['記錄作業檢查項次'].toString()),
                          ),
                          onTap: () {
                            setState(() {
                              _inputToolBarState.showKeyboard(
                                  'vsab0308', TextInputType.number);
                            });
                          },
                        ),
                      ),
                      buildOne('公證', 25),
                      Container(
                        color: Colors.grey[300],
                        child: GestureDetector(
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(width: 1),
                                right: BorderSide(width: 1),
                                left: BorderSide(width: 1),
                                bottom: BorderSide(width: 1),
                              ),
                            ),
                            width: MediaQuery.of(context).size.width / 100 * 25,
                            height: 29.0,
                            child: Text(_currentData['記錄作業公證']),
                          ),
                          onTap: () async {
                            setState(() {
                              if (_currentData['記錄作業公證'] == 'Y')
                                _currentData['記錄作業公證'] = 'N';
                              else
                                _currentData['記錄作業公證'] = 'Y';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      buildOne('方位', 25),
                      Container(
                        color: Colors.grey[300],
                        child: GestureDetector(
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(width: 1),
                                right: BorderSide(width: 1),
                                left: BorderSide(width: 1),
                                bottom: BorderSide(width: 1),
                              ),
                            ),
                            width: MediaQuery.of(context).size.width / 100 * 25,
                            height: 29.0,
                            child: Text(_currentData['記錄作業方位'] != null
                                ? (_currentData['記錄作業方位'] as ActionSheet)
                                    .contentvalue
                                : ''),
                          ),
                          onTap: () async {
                            showActionSheet(
                                ActionSheet(
                                    '方位', '記錄作業方位', 'vs004800', 'vs004801'),
                                _vsab0311List);
                          },
                        ),
                      ),
                      buildOne('異常位置', 25),
                      Container(
                        color: Colors.grey[300],
                        child: GestureDetector(
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(width: 1),
                                right: BorderSide(width: 1),
                                left: BorderSide(width: 1),
                                bottom: BorderSide(width: 1),
                              ),
                            ),
                            width: MediaQuery.of(context).size.width / 100 * 25,
                            height: 29.0,
                            child: Text(_currentData['記錄作業異常位置'] != null
                                ? (_currentData['記錄作業異常位置'] as ActionSheet)
                                    .contentvalue
                                : ''),
                          ),
                          onTap: () async {
                            showActionSheet(
                                ActionSheet(
                                    '異常位置', '記錄作業異常位置', 'vs004900', 'vs004901'),
                                _vsab0312List);
                          },
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      buildOne('異常原因', 25),
                      Container(
                        color: Colors.grey[300],
                        child: GestureDetector(
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(width: 1),
                                right: BorderSide(width: 1),
                                left: BorderSide(width: 1),
                                bottom: BorderSide(width: 1),
                              ),
                            ),
                            width: MediaQuery.of(context).size.width / 100 * 25,
                            height: 29.0,
                            child: Text(_currentData['記錄作業異常原因'] != null
                                ? (_currentData['記錄作業異常原因'] as ActionSheet)
                                    .contentvalue
                                : ''),
                          ),
                          onTap: () async {
                            showActionSheet(
                                ActionSheet(
                                    '異常原因', '記錄作業異常原因', 'vs005000', 'vs005001'),
                                _vsab0313List);
                          },
                        ),
                      ),
                      buildOne('判定', 25),
                      Container(
                        color: Colors.grey[300],
                        child: GestureDetector(
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(width: 1),
                                right: BorderSide(width: 1),
                                left: BorderSide(width: 1),
                                bottom: BorderSide(width: 1),
                              ),
                            ),
                            width: MediaQuery.of(context).size.width / 100 * 25,
                            height: 29.0,
                            child: Text(_currentData['記錄作業判定'] != null
                                ? (_currentData['記錄作業判定'] as ActionSheet)
                                    .contentvalue
                                : ''),
                          ),
                          onTap: () async {
                            showActionSheet(
                                ActionSheet(
                                    '判定', '記錄作業判定', 'vs005100', 'vs005101'),
                                _vsab0315List);
                          },
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      buildOne('檢查說明', 25),
                      Container(
                        color: Colors.grey[300],
                        child: GestureDetector(
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(width: 1),
                                right: BorderSide(width: 1),
                                left: BorderSide(width: 1),
                                bottom: BorderSide(width: 1),
                              ),
                            ),
                            width: MediaQuery.of(context).size.width / 100 * 50,
                            height: 29.0,
                            child: Text(_currentData['記錄作業檢查說明']),
                          ),
                          onTap: () async {
                            setState(() {
                              _inputToolBarState.showKeyboard(
                                  'headerRemark', TextInputType.text);
                            });
                          },
                        ),
                      ),
                      Container(
                        color: Colors.grey[300],
                        child: GestureDetector(
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(width: 1),
                                right: BorderSide(width: 1),
                                left: BorderSide(width: 1),
                                bottom: BorderSide(width: 1),
                              ),
                            ),
                            width: MediaQuery.of(context).size.width / 100 * 25,
                            height: 29.0,
                            child: Text('加入'),
                          ),
                          onTap: () async {
                            addXvmsab03();
                          },
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        alignment: Alignment.center,
                        color: Colors.grey,
                        width: MediaQuery.of(context).size.width,
                        child: Text('異常明細'),
                      ),
                    ],
                  ),
                  buildXVMSAB03ist(_xvmsab03List),
                ],
              ),
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
              )),
        ],
      ),
    );
  }

  Widget buildOne(String value, double width) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(width: 1),
          right: BorderSide(width: 1),
          left: BorderSide(width: 1),
          bottom: BorderSide(width: 1),
        ),
      ),
      width: MediaQuery.of(context).size.width / 100 * width,
      height: 29.0,
      child: Text(value),
    );
  }

  Widget buildXVMSAA03ist(List<XVMSAA03> data) {
    if (data == null || data.length == 0)
      return Container();
    else {
      return Container(
        height: MediaQuery.of(context).size.height / 100 * 50,
        child: ListView.builder(
            itemCount: data == null ? 0 : data.length,
            itemBuilder: (BuildContext context, int index) {
              return buildXVMSAA03Item(context, data[index]);
            }),
      );
    }
  }

  Widget buildXVMSAA03Item(BuildContext context, XVMSAA03 item) {
    return Container(
      color: item.vsaa0309 == 'Y' ? Colors.lime : Colors.white,
      child: Row(children: [
        Container(
          decoration: BoxDecoration(
            border: Border(
                left: BorderSide(width: 1),
                top: BorderSide(width: 1),
                right: BorderSide(width: 1)),
          ),
          alignment: Alignment.center,
          width: MediaQuery.of(context).size.width / 100 * 20,
          height: 24.0,
          child: Text(item.vsaa0302, style: TextStyle(fontSize: 12)),
        ),
        Container(
          decoration: BoxDecoration(
            border:
                Border(top: BorderSide(width: 1), right: BorderSide(width: 1)),
          ),
          alignment: Alignment.center,
          width: MediaQuery.of(context).size.width / 100 * 25,
          height: 24.0,
          child: Text(item.vsaa0303, style: TextStyle(fontSize: 12)),
        ),
        Container(
          decoration: BoxDecoration(
            border:
                Border(top: BorderSide(width: 1), right: BorderSide(width: 1)),
          ),
          alignment: Alignment.center,
          width: MediaQuery.of(context).size.width / 100 * 55,
          height: 24.0,
          child: Text(item.vsaa0300, style: TextStyle(fontSize: 12)),
        ),
      ]),
    );
  }

  //異常記錄
  Widget buildXVMSAB03ist(List<XVMSAB03> data) {
    if (data == null || data.length == 0)
      return Container();
    else {
      return Container(
        height: MediaQuery.of(context).size.height / 100 * 50,
        child: ListView.builder(
            itemCount: data == null ? 0 : data.length,
            itemBuilder: (BuildContext context, int index) {
              return buildXVMSAB03Item(context, data[index]);
            }),
      );
    }
  }

  //異常記錄
  Widget buildXVMSAB03Item(BuildContext context, XVMSAB03 item) {
    return Container(
      child: Row(
        children: [
          Container(
            width: MediaQuery.of(context).size.width / 100 * 20,
            height: 30.0,
            child: IconButton(
              padding: EdgeInsets.only(top: 0.0),
              icon: Icon(Icons.remove_circle),
              onPressed: () {
                setState(() {
                  _xvmsab03List.remove(item);
                  imageItemList
                      .removeWhere((element) => element.tag1 == item.vsab0324);
                  CommonMethod.removeFilesOfDirNoQuestion(
                      context, moduleId, item.vsab0324);
                });
              },
            ),
          ),
          //方位
          Container(
              width: MediaQuery.of(context).size.width / 100 * 20,
              child: Text(item.vsab0311.contentvalue)),
          //異常位置
          Container(
              width: MediaQuery.of(context).size.width / 100 * 20,
              child: Text(item.vsab0312.contentvalue)),
          //異常原因
          Container(
              width: MediaQuery.of(context).size.width / 100 * 20,
              child: Text(item.vsab0313.contentvalue)),
          //相機
          Container(
            width: MediaQuery.of(context).size.width / 100 * 20,
            height: 30.0,
            child: GestureDetector(
              onLongPress: () async {
                if (cameras == null) cameras = await availableCameras();
                if (cameras != null) {
                  //檔案序號 vsab0324 = uuid = b67bae25-3f08-4068-8795-91cbb161edab
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CameraWindow(
                          cameraType: CameraType.cameraWithLamp,
                          cameraList: cameras,
                          imageDirPath: moduleId + '/' + item.vsab0324,
                          imageList: imageItemList
                              .where((element) => element.tag1 == item.vsab0324)
                              .toList(),
                          keyNo: item.vsab0300,
                          keyDate: item.vsab0305.toString(),
                          keyNumber: item.vsab0307.contentkey,
                          tag1: item.vsab0324,
                          tag2: '',
                          groupKey: moduleId,
                          onConfirm: (v) {
                            imageItemList.removeWhere(
                                (element) => element.tag1 == item.vsab0324);
                            for (var item in v) {
                              imageItemList.add(item);
                            }
                          },
                        ),
                      ));
                }
              },
              child: IconButton(
                padding: EdgeInsets.only(top: 0.0),
                icon: Icon(Icons.camera),
                onPressed: () async {
                  if (cameras == null) cameras = await availableCameras();
                  if (cameras != null) {
                    //檔案序號 vsab0324 = uuid = b67bae25-3f08-4068-8795-91cbb161edab
                    await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CameraWindow(
                            cameraType: CameraType.camera,
                            cameraList: cameras,
                            imageDirPath: moduleId + '/' + item.vsab0324,
                            imageList: imageItemList
                                .where(
                                    (element) => element.tag1 == item.vsab0324)
                                .toList(),
                            keyNo: item.vsab0300,
                            keyDate: item.vsab0305.toString(),
                            keyNumber: item.vsab0307.contentkey,
                            tag1: item.vsab0324,
                            tag2: '',
                            groupKey: moduleId,
                            onConfirm: (v) {
                              imageItemList.removeWhere(
                                  (element) => element.tag1 == item.vsab0324);
                              for (var item in v) {
                                imageItemList.add(item);
                              }
                            },
                          ),
                        ));
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  //加入異常
  void addXvmsab03() async {
    if (_currentData['記錄作業車身號碼'] == '') {
      _inputToolBarKey.currentState
          .showMessage(_scaffoldKey, ResultFlag.ng, '請輸入車身號碼');
      return;
    }

    if (_currentData['記錄作業檢查項次'] == 0) {
      _inputToolBarKey.currentState
          .showMessage(_scaffoldKey, ResultFlag.ng, '請選擇檢查次數');
      return;
    }

    if (_currentData['記錄作業方位'] == null) {
      _inputToolBarKey.currentState
          .showMessage(_scaffoldKey, ResultFlag.ng, '請選擇方位');
      return;
    }

    if (_currentData['記錄作業異常位置'] == null) {
      _inputToolBarKey.currentState
          .showMessage(_scaffoldKey, ResultFlag.ng, '請選擇異常位置');
      return;
    }

    if (_currentData['記錄作業異常原因'] == null) {
      _inputToolBarKey.currentState
          .showMessage(_scaffoldKey, ResultFlag.ng, '請選擇異常原因');
      return;
    }

    if (_currentData['記錄作業判定'] == null) {
      _inputToolBarKey.currentState
          .showMessage(_scaffoldKey, ResultFlag.ng, '請選擇判定');
      return;
    }

    XVMSAB03 xvmsab03 = XVMSAB03();
    xvmsab03.vsab0300 = _currentData['記錄作業車身號碼']; //車身號碼
    xvmsab03.vsab0305 = _currentData['記錄作業點交次數']; //點交次數
    xvmsab03.vsab0306 = _currentData['來源名稱']; //來源名稱
    xvmsab03.vsab0307 = _currentData['檢查分類']; //檢查分類
    xvmsab03.vsab0308 = _currentData['記錄作業檢查項次']; //檢查項次
    xvmsab03.vsab0309 = 'Y';
    xvmsab03.vsab0310 = _currentData['記錄作業公證']; //公證
    xvmsab03.vsab0311 = _currentData['記錄作業方位']; //方位
    xvmsab03.vsab0312 = _currentData['記錄作業異常位置']; //異常位置
    xvmsab03.vsab0313 = _currentData['記錄作業異常原因']; //異常原因
    xvmsab03.vsab0314 = _currentData['記錄作業檢查說明']; //檢查說明
    xvmsab03.vsab0315 = _currentData['記錄作業判定']; //判定
    DateTime now = DateTime.now();
    xvmsab03.vsab0316 = DateFormat('yyyy-MM-dd').format(now); //檢查日期
    xvmsab03.vsab0317 = DateFormat('HH:mm:ss').format(now); //檢查時間
    xvmsab03.vsab0318 = Business.userId; //檢查人員
    xvmsab03.vsab0324 = Uuid().v4();

    setState(() {
      _xvmsab03List.add(xvmsab03);
    });
  }

  //List檢查車身號碼
  List<Map<String, dynamic>> checkExistsVin(String value) {
    List<Map<String, dynamic>> vinList = [];
    int startWithCount = 0;
    int endWithCount = 0;
    int fullCount = 0;
    List<Map<String, dynamic>> data = [];
    _xvmsaa03List.forEach((element) {
      data.add({'車身號碼': element.vsaa0300});
    });
    startWithCount =
        data.where((element) => element['車身號碼'].startsWith(value)).length;
    endWithCount =
        data.where((element) => element['車身號碼'].endsWith(value)).length;
    fullCount = data.where((element) => element['車身號碼'] == value).length;
    if (startWithCount == 0 && endWithCount == 0 && fullCount == 0) {
      vinList = [];
    } else if (startWithCount > 1) {
      vinList =
          data.where((element) => element['車身號碼'].startsWith(value)).toList();
    } else if (endWithCount > 1) {
      vinList =
          data.where((element) => element['車身號碼'].endsWith(value)).toList();
    } else if (fullCount > 1) {
      vinList = data.where((element) => element['車身號碼'] == value).toList();
    } else if (startWithCount == 1) {
      XVMSAA03 item = _xvmsaa03List
          .where((element) => element.vsaa0300.startsWith(value))
          .first;
      vinList.add({'車身號碼': item.vsaa0300});
    } else if (endWithCount == 1) {
      XVMSAA03 item = _xvmsaa03List
          .where((element) => element.vsaa0300.endsWith(value))
          .first;
      vinList.add({'車身號碼': item.vsaa0300});
    } else if (fullCount == 1) {
      XVMSAA03 item =
          _xvmsaa03List.where((element) => element.vsaa0300 == value).first;
      vinList.add({'車身號碼': item.vsaa0300});
    }
    return vinList;
  }

  Future<Map<String, dynamic>> checkExistsVinWithDB(String value) async {
    Datagram datagram = Datagram();
    datagram.addText('''select vsaa0200 as 車身號碼,
                               isnull(t2.進口商代碼,'') as 進口商,
                               isnull(t2.廠牌代碼,'') as 廠牌,
                               isnull(t2.車款代碼,'') as 車款,
                               isnull(t2.車型代碼,'') as 車型,
                               vsaa0213 as 點交次數,
                               vsaa0215 as 來源名稱
                        from xvms_aa02 as t1 left join vi_xvms_0001_04 as t2 on t1.vsaa0208 = t2.進口商系統碼 and
                                                                                t1.vsaa0201 = t2.廠牌系統碼 and
                                                                                t1.vsaa0202 = t2.車款系統碼 and
                                                                                t1.vsaa0203 = t2.系統碼
                        where vsaa0200 like '%$value';''');
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      if (data.length == 0) {
        return null;
      } else if (data.length == 1) {
        return data.first;
      } else {
        String vin = await showVinActionSheet(data);
        if (vin == null) {
          return {'車身號碼': ''};
        }
        Map<String, dynamic> item =
            data.firstWhere((element) => element['車身號碼'].toString() == vin);
        return item;
      }
    } else {
      _inputToolBarKey.currentState
          .showMessage(_scaffoldKey, ResultFlag.ng, result.getNGMessage());
      return null;
    }
  }

  void checkLocalAA03() async {
    Datagram datagram = Datagram(databaseNameOrSid: localDb.dbName);
    datagram.addText('''select vsaa0300 from xvmsaa03 limit 1''');
    ResponseResult result = await localDb.execute(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();

      setState(() {
        if (data != null && data.length > 0) {
          _currentData['檢查作業離線資料'] = 'Y';
        } else {
          _currentData['檢查作業離線資料'] = 'N';
        }
      });
    } else {}
  }

  void checkLocalAB03() async {
    Datagram datagram = Datagram(databaseNameOrSid: localDb.dbName);
    datagram.addText('''select vsab0300 from xvmsab03 limit 1''');
    ResponseResult result = await localDb.execute(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();

      setState(() {
        if (data != null && data.length > 0) {
          _currentData['記錄作業離線資料'] = 'Y';
        } else {
          _currentData['記錄作業離線資料'] = 'N';
        }
      });
    } else {}
  }

  Future<List<Map<String, dynamic>>> getListFromAA02() async {
    if (_currentData['來源名稱'].toString() == '') return null;
    if (_currentData['實際到港日'].toString() == '') return null;

    Datagram datagram = Datagram();
    datagram.addText('''select vsaa0200 as 車身號碼,
                               t2.vs000101 as 進口商,
                               t3.vs000101 as 廠牌,
                               t4.vs000101 as 車款,
                               t5.vs000101 as 車型,
                               vsaa0213 as 點交次數,
                               vsaa0215 as 來源名稱
                        from xvms_aa02 as t1
                        left join xvms_0001 as t2 on t1.vsaa0208 = t2.vs000100 and t2.vs000106 = '1'
                        left join xvms_0001 as t3 on t1.vsaa0201 = t3.vs000100 and t3.vs000106 = '2'
                        left join xvms_0001 as t4 on t1.vsaa0202 = t4.vs000100 and t4.vs000106 = '3'
                        left join xvms_0001 as t5 on t1.vsaa0203 = t5.vs000100 and t5.vs000106 = '4'
                        where vsaa0215 = '${_currentData['來源名稱']}' and
                              vsaa0217 = '${_currentData['實際到港日']}';''');
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      return data;
    } else {
      return null;
    }
  }

  void initDatabase() async {
    bool exist = await localDb.existsDatabase('TVS0100010.db');

    localDb.dbName = 'TVS0100010.db';
    localDb.dbVersion = 1;
    localDb.schemas = [
      '''create table if not exists xvmsaa03
           (
             vsaa0300 text,
             vsaa0301 text,
             vsaa0302 text,
             vsaa0303 text,
             vsaa0304 text,
             vsaa0305 integer,
             vsaa0306 text,
             vsaa0307 text,
             vsaa0308 integer,
             vsaa0309 text,
             vsaa0310 text,
             vsaa0311 text,
             vsaa0312 text
           )''',
      '''create table if not exists xvmsab03
           (
             vsab0300 text,
             vsab0305 integer,
             vsab0306 text,
             vsab0307 text,
             vsab0308 integer,
             vsab0309 text,
             vsab0310 text,
             vsab0311 text,
             vsab0312 text,
             vsab0313 text,
             vsab0314 text,
             vsab0315 text,
             vsab0316 text,
             vsab0317 text,
             vsab0318 text,
             vsab0324 text
           )''',
      '''create table if not exists imageitem
         (
           ReceiptType text,
           ReceiptSerial text,
           ReceiptNo text,
           Tag1 text,
           Tag2 text,
           FilePath text
         )
      ''',
      '''create table if not exists xvmsaa21
         (
           vsaa2100 text,
           vsaa2105 integer,
           vsaa2107 integer,
           companyId text,
           deptId text,
           userId text,
           uuid text
         )
      ''',
    ];
    if (exist == true) {
      Datagram datagram = Datagram(databaseNameOrSid: localDb.dbName);
      datagram.addText('select vsaa0300 from xvmsaa03 limit 1;');
      datagram.addText('select vsab0300 from xvmsab03 limit 1;');
      ResponseResult result = await localDb.execute(datagram);
      if (result.flag == ResultFlag.ok) {
        List<Map<String, dynamic>> data1 = result.items[0].getMap();
        List<Map<String, dynamic>> data2 = result.items[1].getMap();
        if (data1.length == 0 && data2.length == 0)
          await localDb.delDatabase('TVS0100010.db');
        else {
          checkLocalAA03();
          checkLocalAB03();
        }
      }
    }

    localDb.getDatabase();
  }

  //來源名稱
  void loadBoat() async {
    Datagram datagram = Datagram();
    datagram.addText('''select vsaa0217 as 實際到港日,
                               vsaa0215 as 來源名稱,
                               count(*) as 台數
                        from xvms_aa02
                        where vsaa0217 > convert(varchar(10), dateadd(month, -2, getdate()), 120)
                        group by vsaa0217,vsaa0215
                        order by vsaa0217 desc;''');
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      if (data.length > 0) {
        setState(() {
          _boatList = data;
        });
      }
    }
  }

  //車輛檢查分類
  void loadVSAA0307() async {
    Datagram datagram = Datagram();
    datagram.addText(
        '''select ixa00700,ixa00701 from entirev4.dbo.ifx_a007 where ixa00703 = '車輛檢查分類';''');
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      if (data.length > 0) {
        setState(() {
          _vsaa0307List = data;
        });
      }
    } else {}
  }

  //方位
  void loadVSAB0311() async {
    Datagram datagram = Datagram();
    datagram.addText('''select vs004800,vs004801 from xvms_0048;''');
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      if (data.length > 0) {
        setState(() {
          _vsab0311List = data;
        });
      }
    } else {}
  }

  //異常位置
  void loadVSAB0312() async {
    Datagram datagram = Datagram();
    datagram.addText('''select vs004900,vs004901 from xvms_0049;''');
    ResponseResult result = await Business.apiExecuteDatagram(datagram);

    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      setState(() {
        _vsab0312List = data;
      });
    } else {}
  }

  //異常原因
  void loadVSAB0313() async {
    Datagram datagram = Datagram();
    datagram.addText('''select vs005000,vs005001 from xvms_0050''',
        rowIndex: 0, rowSize: 65535);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);

    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      setState(() {
        _vsab0313List = data;
      });
    } else {}
  }

  //判定
  void loadVSAB0315() async {
    Datagram datagram = Datagram();
    datagram.addText('''select vs005100,vs005101 from xvms_0051''',
        rowIndex: 0, rowSize: 65535);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);

    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      setState(() {
        _vsab0315List = data;
      });
    } else {}
  }

  //離線下載資料
  void offlinedownloadData() async {
    List<Map<String, dynamic>> data = await getListFromAA02();
    if (data == null) return;
    if (data.length > 0) {
      //class
      List<XVMSAA03> _xvmsaa03 = [];
      for (Map<String, dynamic> item in data) {
        XVMSAA03 xvmsaa03 = XVMSAA03();
        xvmsaa03.vsaa0300 = item['車身號碼'];
        xvmsaa03.vsaa0301 = item['進口商'];
        xvmsaa03.vsaa0302 = item['廠牌'];
        xvmsaa03.vsaa0303 = item['車款'];
        xvmsaa03.vsaa0304 = item['車型'];
        xvmsaa03.vsaa0305 = item['點交次數'];
        xvmsaa03.vsaa0306 = item['來源名稱'];
        xvmsaa03.vsaa0307 = (_currentData['檢查分類'] as ActionSheet).contentkey;
        xvmsaa03.vsaa0308 = 0; //檢查項次
        xvmsaa03.vsaa0309 = 'N'; //是否檢查
        xvmsaa03.timestamp = 0; //時間標記
        _xvmsaa03.add(xvmsaa03);
      }
      setState(() {
        _xvmsaa03List = _xvmsaa03;
      });

      //localDB
      Datagram datagram2 = Datagram(databaseNameOrSid: localDb.dbName);
      for (Map<String, dynamic> item in data) {
        datagram2.addText('''insert into xvmsaa03
                               (
                                 vsaa0300,
                                 vsaa0301,
                                 vsaa0302,
                                 vsaa0303,
                                 vsaa0304,
                                 vsaa0305,
                                 vsaa0306,
                                 vsaa0307,
                                 vsaa0308,
                                 vsaa0309,
                                 vsaa0310,
                                 vsaa0311,
                                 vsaa0312
                               )
                               values
                               (
                                 '${item['車身號碼']}',
                                 '${item['進口商']}',
                                 '${item['廠牌']}',
                                 '${item['車款']}',
                                 '${item['車型']}',
                                 ${item['點交次數']},
                                 '${item['來源名稱']}',
                                 '',
                                 0,
                                 'N',
                                 '',
                                 '',
                                 ''
                               )''');
      }
      ResponseResult result2 = await localDb.execute(datagram2);
      if (result2.flag == ResultFlag.ok) {
        debugPrint('insert xvmsaa03 ok');
      } else {
        debugPrint('insert xvmsaa03 ng' + result2.getNGMessage());
      }
    }
  }

  //離線記錄作業檔案儲存
  Future<void> offlineSaveFile() async {
    if (imageItemList.length == 0) return;

    Datagram datagram = Datagram(databaseNameOrSid: localDb.dbName);
    for (ImageItem item in imageItemList) {
      datagram.addText('''insert into imageitem
                          (
                            ReceiptType,
                            ReceiptSerial,
                            ReceiptNo,
                            Tag1,
                            Tag2,
                            FilePath
                          )
                          values
                          (
                            '${item.keyNo}',
                            '${item.keyDate}',
                            '${item.keyNumber}',
                            '${item.tag1}',
                            '',
                            '${item.filePath}'
                          )''');
    }
    ResponseResult result = await localDb.execute(datagram);
    if (result.flag == ResultFlag.ok) {
      setState(() {
        imageItemList = [];
      });
      debugPrint('offlineSaveFile ok');
    } else {
      debugPrint('offlineSaveFile ng');
    }
  }

  //離線儲存檢查作業
  Future<void> offlineSavexvmsaa03() async {
    if (_xvmsaa03List.length == 0) return false;
    if (_xvmsaa03List.where((element) => element.vsaa0309 == 'Y').length == 0)
      return false;

    Datagram datagram = Datagram(databaseNameOrSid: localDb.dbName);
    //到港檢驗
    if ((_currentData['檢查分類'] as ActionSheet).contentkey == '1') {
      for (XVMSAA03 item in _xvmsaa03List
          .where((element) => element.vsaa0309 == 'Y')
          .toList()) {
        datagram.addText('''update xvmsaa03
                            set vsaa0307 = '${item.vsaa0307}',
                                vsaa0308 = ${item.vsaa0308},
                                vsaa0309 = '${item.vsaa0309}',
                                vsaa0310 = '${item.vsaa0310}',
                                vsaa0311 = '${item.vsaa0311}',
                                vsaa0312 = '${item.vsaa0312}'
                            where vsaa0300 = '${item.vsaa0300}' and
                                  vsaa0305 = ${item.vsaa0305}''');
      }
    }
    //倉儲檢驗
    else {
      for (XVMSAA03 item in _xvmsaa03List
          .where((element) => element.vsaa0309 == 'Y')
          .toList()) {
        datagram.addText('''insert into xvmsaa03
                               (
                                 vsaa0300,
                                 vsaa0301,
                                 vsaa0302,
                                 vsaa0303,
                                 vsaa0304,
                                 vsaa0305,
                                 vsaa0306,
                                 vsaa0307,
                                 vsaa0308,
                                 vsaa0309,
                                 vsaa0310,
                                 vsaa0311,
                                 vsaa0312
                               )
                               values
                               (
                                 '${item.vsaa0300}',
                                 '',
                                 '',
                                 '',
                                 '',
                                 0,
                                 '',
                                 '${item.vsaa0307}',
                                 ${item.vsaa0308},
                                 '${item.vsaa0309}',
                                 '${item.vsaa0310}',
                                 '${item.vsaa0311}',
                                 '${item.vsaa0312}'
                               )''');
      }
    }

    ResponseResult result = await localDb.execute(datagram);
    if (result.flag == ResultFlag.ok) {
      setState(() {
        _xvmsaa03List = [];
        _currentData['來源名稱'] = '';
        _currentData['實際到港日'] = '';
        _currentData['台數'] = '';
        _currentData['檢查作業車身號碼'] = '';
        _currentData['檢查作業廠牌'] = '';
        _currentData['檢查作業車款'] = '';
        _currentData['檢查作業車型'] = '';
      });
      _inputToolBarKey.currentState
          .showMessage(_scaffoldKey, ResultFlag.ok, '離線檢查記錄完成');
    } else {
      debugPrint('ng offlineSavexvmsaa03');
    }
  }

  //離線儲存里程數
  Future<void> offlineSavexvmsaa21() async {
    if (_xvmsaa21List.length == 0) return;

    Datagram datagram = Datagram(databaseNameOrSid: localDb.dbName);
    for (XVMSAA21 item in _xvmsaa21List) {
      datagram.addText('''insert into xvmsaa21
                          (
                            vsaa2100,
                            vsaa2105,
                            vsaa2107,
                            companyId,
                            deptId,
                            userId,
                            uuid
                          )
                          values
                          (
                            '${item.vsaa2100}',
                            ${item.vsaa2105},
                            ${item.vsaa2107},
                            '${item.companyId}',
                            '${item.deptId}',
                            '${item.userId}',
                            '${item.uuid}'
                          )''');
    }
    ResponseResult result = await localDb.execute(datagram);
    if (result.flag == ResultFlag.ok) {
      setState(() {
        _xvmsaa21List = [];
      });
      debugPrint('ok 離線儲存里程數');
    } else {
      debugPrint('ng 離線儲存里程數');
    }
  }

  //離線儲存記錄作業
  Future<void> offlineSavexvmsab03() async {
    if (_xvmsab03List.length == 0) return;

    Datagram datagram = Datagram(databaseNameOrSid: localDb.dbName);
    for (XVMSAB03 item in _xvmsab03List) {
      datagram.addText('''insert into xvmsab03
                          (
                            vsab0300,
                            vsab0305,
                            vsab0306,
                            vsab0307,
                            vsab0308,
                            vsab0309,
                            vsab0310,
                            vsab0311,
                            vsab0312,
                            vsab0313,
                            vsab0314,
                            vsab0315,
                            vsab0316,
                            vsab0317,
                            vsab0318,
                            vsab0324
                          )
                          values
                          (
                            '${item.vsab0300}',
                            ${item.vsab0305},
                            '${item.vsab0306}',
                            '${item.vsab0307.contentkey}',
                            ${item.vsab0308},
                            '${item.vsab0309}',
                            '${item.vsab0310}',
                            '${item.vsab0311.contentkey}',
                            '${item.vsab0312.contentkey}',
                            '${item.vsab0313.contentkey}',
                            '${item.vsab0314}',
                            '${item.vsab0315.contentkey}',
                            '${item.vsab0316}',
                            '${item.vsab0317}',
                            '${item.vsab0318}',
                            '${item.vsab0324}'
                          )''');
    }

    ResponseResult result = await localDb.execute(datagram);
    if (result.flag == ResultFlag.ok) {
      _inputToolBarKey.currentState
          .showMessage(_scaffoldKey, ResultFlag.ok, '離線記錄作業完成');
      setState(() {
        _xvmsab03List = [];
        _currentData['記錄作業車身號碼'] = '';
        _currentData['記錄作業點交次數'] = 0;
      });
    } else {
      debugPrint('ng offlineSavexvmsab03');
    }
  }

  //在線下載資料
  void onlinedownloadData() async {
    if (_currentData['來源名稱'].toString() == '') return;
    if (_currentData['實際到港日'].toString() == '') return;

    Datagram datagram = Datagram();
    datagram.addText('''select vsaa0200 as 車身號碼,
                               t2.進口商代碼 as 進口商,
                               t2.廠牌代碼 as 廠牌,
                               t2.車款代碼 as 車款,
                               t2.車型代碼 as 車型,
                               vsaa0213 as 點交次數,
                               vsaa0215 as 來源名稱,
                               isnull(t3.vsaa0308,0) as 檢查項次,
                               isnull(t3.vsaa0309,'N') as 是否檢查
                        from xvms_aa02 as t1 left join vi_xvms_0001_04 as t2 on t1.vsaa0208 = t2.進口商系統碼 and
                                                                                t1.vsaa0201 = t2.廠牌系統碼 and
                                                                                t1.vsaa0202 = t2.車款系統碼 and
                                                                                t1.vsaa0203 = t2.系統碼
                                             left join (
                                                         select h2.vsaa0300,
                                                                h2.vsaa0305,
                                                                h2.vsaa0309,
                                                                h2.vsaa0308
                                                         from (
                                                               select vsaa0300,
                                                                      vsaa0305,
                                                                      max(vsaa0308) as vsaa0308
                                                               from xvms_aa03 where vsaa0306 = '${_currentData['來源名稱']}'
                                                               group by vsaa0300,vsaa0305
                                                              ) as h1 left join xvms_aa03 as h2 on h1.vsaa0300 = h2.vsaa0300 and h1.vsaa0305 = h2.vsaa0305 and h1.vsaa0308 = h2.vsaa0308
                                                         where h2.vsaa0300 is not null
                                                       ) as t3 on t1.vsaa0200 = t3.vsaa0300 and
                                                                  t1.vsaa0213 = t3.vsaa0305
                        where vsaa0215 = '${_currentData['來源名稱']}' and
                              vsaa0217 = '${_currentData['實際到港日']}' order by isnull(t3.vsaa0309,'N');''');
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      if (data.length > 0) {
        List<XVMSAA03> _xvmsaa03 = [];
        for (Map<String, dynamic> item in data) {
          XVMSAA03 xvmsaa03 = XVMSAA03();
          xvmsaa03.vsaa0300 = item['車身號碼'];
          xvmsaa03.vsaa0301 = item['進口商'];
          xvmsaa03.vsaa0302 = item['廠牌'];
          xvmsaa03.vsaa0303 = item['車款'];
          xvmsaa03.vsaa0304 = item['車型'];
          xvmsaa03.vsaa0305 = item['點交次數'];
          xvmsaa03.vsaa0306 = item['來源名稱'];
          xvmsaa03.vsaa0307 = (_currentData['檢查分類'] as ActionSheet).contentkey;
          xvmsaa03.vsaa0308 = item['檢查項次']; //檢查項次
          xvmsaa03.vsaa0309 = item['是否檢查'];
          ; //是否檢查
          xvmsaa03.timestamp = 0; //時間標記
          _xvmsaa03.add(xvmsaa03);
        }
        setState(() {
          _xvmsaa03List = _xvmsaa03;
        });
        // MessageBox.showInformation(context, '', '下載完成');
      } else {}
    } else {}
  }

  //在線記錄作業檔案
  Future<void> onlineSaveFile() async {
    if (imageItemList.length == 0) return;

    for (ImageItem item in imageItemList) {
      Map<String, String> headers = {
        'ModuleId': moduleId,
        'SubPath': moduleId + '\\' + item.tag1,
        'ReceiptType': item.keyNo,
        'ReceiptSerial': item.keyDate,
        'ReceiptNo': item.keyNumber,
        'Tag1': item.tag1,
        'Tag2': '',
        'Descryption': '',
        'UploadUser': Business.userId,
        'UploadDevice': '',
      };

      List<File> uploadFile = [];
      uploadFile.add(item.file);

      ResponseResult result = await Business.apiUploadFile(
          FileCmdType.file, uploadFile,
          headers: headers);
      if (result.flag == ResultFlag.ok) {
        uploadFile.first.deleteSync();
      }
    }

    setState(() {
      imageItemList = [];
    });
  }

  Future<bool> onlineSavexvmsaa03() async {
    if (_xvmsaa03List.length == 0) return false;
    if (_xvmsaa03List.where((element) => element.vsaa0309 == 'Y').length == 0)
      return false;

    String json = jsonEncode(
        _xvmsaa03List.where((element) => element.vsaa0309 == 'Y').toList());
    json = '{"items":' + json + '}';

    Datagram datagram = Datagram();
    datagram.addText('''if(1=1)
                        declare @rc int
                        declare @sjson nvarchar(max) = '$json';
                        declare @suserid varchar(30) = '${Business.userId}';
                        declare @sdeptid varchar(30) = '${Business.deptId}';
                        declare @oresult_flag varchar(2)
                        declare @oresult nvarchar(4000)
                        
                        execute @rc = [dbo].[spx_xvms_aa03_insert] 
                            @sjson,
                            @suserid,
                            @sdeptid,
                            @oresult_flag output,
                            @oresult output

                        if (@oresult_flag = 'NG')
                            begin
                                raiserror(@oresult,16,1);
                            end
                        select @oresult_flag as ORESULT_FLAG,@oresult as ORESULT;''');

    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      setState(() {
        _xvmsaa03List = [];
        _currentData['來源名稱'] = '';
        _currentData['實際到港日'] = '';
        _currentData['台數'] = '';
        _currentData['檢查作業車身號碼'] = '';
        _currentData['檢查作業廠牌'] = '';
        _currentData['檢查作業車款'] = '';
        _currentData['檢查作業車型'] = '';
      });
      return true;
    } else {
      _inputToolBarKey.currentState
          .showMessage(_scaffoldKey, ResultFlag.ng, result.getNGMessage());
      return false;
    }
  }

  //在線儲存里程數
  void onlineSavexvmsaa21() async {
    if (_xvmsaa21List.length == 0) return;

    Datagram datagram = Datagram();
    for (XVMSAA21 item in _xvmsaa21List) {
      List<ParameterField> paramList = List<ParameterField>();
      paramList.add(ParameterField(
          'sVSAA2100', ParamType.strings, ParamDirection.input,
          value: item.vsaa2100));
      paramList.add(ParameterField(
          'sVSAA2105', ParamType.strings, ParamDirection.input,
          value: item.vsaa2105.toString()));
      paramList.add(ParameterField(
          'sVSAA2107', ParamType.strings, ParamDirection.input,
          value: item.vsaa2107.toString()));
      paramList.add(ParameterField(
          'sVSAA2112', ParamType.strings, ParamDirection.input,
          value: item.uuid));
      paramList.add(ParameterField(
          'sCOMPID', ParamType.strings, ParamDirection.input,
          value: item.companyId));
      paramList.add(ParameterField(
          'sDEPTID', ParamType.strings, ParamDirection.input,
          value: item.deptId));
      paramList.add(ParameterField(
          'sUSERID', ParamType.strings, ParamDirection.input,
          value: item.userId));
      paramList.add(ParameterField(
          'oRESULT_FLAG', ParamType.strings, ParamDirection.output));
      paramList.add(
          ParameterField('oRESULT', ParamType.strings, ParamDirection.output));
      datagram.addProcedure('SPX_XVMS_AA21', parameters: paramList);
    }

    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      setState(() {
        _xvmsaa21List = [];
      });
    } else {}
  }

  Future<bool> onlineSavexvmsab03() async {
    if (_currentData['來源名稱'].toString() == '') {
      _inputToolBarKey.currentState
          .showMessage(_scaffoldKey, ResultFlag.ng, '來源名稱為空白');
      return false;
    }
    if (_xvmsab03List.length == 0) return false;

    StringBuffer strbuf = StringBuffer();
    for (XVMSAB03 item in _xvmsab03List) {
      strbuf.write(jsonEncode(item.toMap()));
      strbuf.write(',');
    }
    String json =
        '{"items":[' + strbuf.toString().substring(0, strbuf.length - 1) + ']}';

    Datagram datagram = Datagram();
    datagram.addText('''if(1=1)
                        declare @rc int
                        declare @sjson nvarchar(max) = '$json';
                        declare @suserid varchar(30) = '${Business.userId}';
                        declare @sdeptid varchar(30) = '${Business.deptId}';
                        declare @oresult_flag varchar(2)
                        declare @oresult nvarchar(4000)
                        
                        execute @rc = [dbo].[spx_xvms_ab03_insert] 
                            @sjson,
                            @suserid,
                            @sdeptid,
                            @oresult_flag output,
                            @oresult output

                        if (@oresult_flag = 'NG')
                            begin
                                raiserror(@oresult,16,1);
                            end
                        select @oresult_flag as ORESULT_FLAG,@oresult as ORESULT;''');

    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      setState(() {
        _xvmsab03List = [];
        _currentData['來源名稱'] = '';
        _currentData['記錄作業車身號碼'] = '';
        _currentData['記錄作業點交次數'] = 0;
      });
      return true;
    } else {
      _inputToolBarKey.currentState
          .showMessage(_scaffoldKey, ResultFlag.ng, result.getNGMessage());
      return false;
    }
  }

  //ActionSheet 選擇
  void showActionSheet(
      ActionSheet actionSheet, List<Map<String, dynamic>> dataList) {
    if (dataList == null) return;
    List<Widget> _list = [];

    for (int i = 0; i < dataList.length; i++) {
      _list.add(CupertinoActionSheetAction(
        child: Text(dataList[i][actionSheet.columnNamevalue]),
        onPressed: () {
          actionSheet.contentkey = dataList[i][actionSheet.columnNamekey];
          actionSheet.contentvalue = dataList[i][actionSheet.columnNamevalue];
          setState(() {
            _currentData[actionSheet.label] = actionSheet;
          });
          Navigator.pop(context);
        },
      ));
    }

    final action = CupertinoActionSheet(
      title: Text(
        actionSheet.title,
        style: TextStyle(fontSize: 18),
      ),
      message: Text(
        '請選擇',
        style: TextStyle(fontSize: 15.0),
      ),
      actions: _list,
      cancelButton: CupertinoActionSheetAction(
        child: Text('取消'),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
    showCupertinoModalPopup(context: context, builder: (context) => action);
  }

  //來源名稱
  void showBoatActionSheet() {
    if (_currentData == null || _currentData.length == 0) return;
    List<Widget> _list = [];

    if (_boatList.length > 0) {
      for (int i = 0; i < _boatList.length; i++) {
        _list.add(CupertinoActionSheetAction(
          child: Text(_boatList[i]['實際到港日'] + ' ' + _boatList[i]['來源名稱']),
          onPressed: () {
            setState(() {
              _currentData['來源名稱'] = _boatList[i]['來源名稱'];
              _currentData['實際到港日'] = _boatList[i]['實際到港日'];
              _currentData['台數'] = _boatList[i]['台數'];
              _currentData['檢查作業車身號碼'] = '';
              _currentData['檢查作業廠牌'] = '';
              _currentData['檢查作業車款'] = '';
              _currentData['檢查作業車型'] = '';
            });
            Navigator.pop(context);
          },
        ));
      }
    }

    final action = CupertinoActionSheet(
      title: Text(
        '來源名稱',
        style: TextStyle(fontSize: 18),
      ),
      message: Text(
        '請選擇',
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

  //顯示多車身選擇
  Future<String> showVinActionSheet(List<Map<String, dynamic>> dataList) {
    List<Widget> _list = [];

    for (int i = 0; i < dataList.length; i++) {
      _list.add(CupertinoActionSheetAction(
        child: Text(dataList[i]['車身號碼']),
        onPressed: () {
          Navigator.pop(context, dataList[i]['車身號碼'].toString());
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
          Navigator.pop(context, null);
        },
      ),
    );
    return showCupertinoModalPopup(
        context: context, builder: (context) => action);
  }

  Future<void> uploadaa03() async {
    Datagram datagram = Datagram(databaseNameOrSid: localDb.dbName);
    datagram.addText('''select * from xvmsaa03''');
    ResponseResult result = await localDb.execute(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      if (data.length > 0) {
        data.removeWhere((element) => element['vsaa0309'] == 'N');

        String json = '{"items":' + jsonEncode(data) + '}';

        Datagram datagram2 = Datagram();
        datagram2.addText('''if(1=1)
                        declare @rc int
                        declare @sjson nvarchar(max) = '$json';
                        declare @suserid varchar(30) = '${Business.userId}';
                        declare @sdeptid varchar(30) = '${Business.deptId}';
                        declare @oresult_flag varchar(2)
                        declare @oresult nvarchar(4000)
                        
                        execute @rc = [dbo].[spx_xvms_aa03_insert] 
                            @sjson,
                            @suserid,
                            @sdeptid,
                            @oresult_flag output,
                            @oresult output

                        if (@oresult_flag = 'NG')
                            begin
                                raiserror(@oresult,16,1);
                            end
                        select @oresult_flag as ORESULT_FLAG,@oresult as ORESULT;''');
        ResponseResult result2 = await Business.apiExecuteDatagram(datagram2);
        if (result2.flag == ResultFlag.ok) {
          datagram.setCommandList = [];
          datagram.addText('''delete from xvmsaa03''');
          result = await localDb.execute(datagram);
          checkLocalAA03();
          MessageBox.showInformation(context, '', '檢查離線上傳完成');
        } else {
          MessageBox.showWarning(context, '', result2.getNGMessage());
        }
      }
    } else {
      debugPrint('uploadaa03' + result.getNGMessage());
    }
  }

  Future<void> uploadaa21() async {
    Datagram datagram = Datagram(databaseNameOrSid: localDb.dbName);
    datagram.addText('''select * from xvmsaa21''');
    ResponseResult result = await localDb.execute(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      if (data.length > 0) {
        Datagram datagram2 = Datagram();
        for (Map<String, dynamic> item in data) {
          List<ParameterField> paramList = List<ParameterField>();
          paramList.add(ParameterField(
              'sVSAA2100', ParamType.strings, ParamDirection.input,
              value: item['vsaa2100']));
          paramList.add(ParameterField(
              'sVSAA2105', ParamType.strings, ParamDirection.input,
              value: item['vsaa2105'].toString()));
          paramList.add(ParameterField(
              'sVSAA2107', ParamType.strings, ParamDirection.input,
              value: item['vsaa2107'].toString()));
          paramList.add(ParameterField(
              'sVSAA2112', ParamType.strings, ParamDirection.input,
              value: item['uuid']));
          paramList.add(ParameterField(
              'sCOMPID', ParamType.strings, ParamDirection.input,
              value: item['companyId']));
          paramList.add(ParameterField(
              'sDEPTID', ParamType.strings, ParamDirection.input,
              value: item['deptId']));
          paramList.add(ParameterField(
              'sUSERID', ParamType.strings, ParamDirection.input,
              value: item['userId']));
          paramList.add(ParameterField(
              'oRESULT_FLAG', ParamType.strings, ParamDirection.output));
          paramList.add(ParameterField(
              'oRESULT', ParamType.strings, ParamDirection.output));
          datagram2.addProcedure('SPX_XVMS_AA21', parameters: paramList);
        }
        ResponseResult result2 = await Business.apiExecuteDatagram(datagram2);
        if (result2.flag == ResultFlag.ok) {
          datagram.setCommandList = [];
          datagram.addText('''delete from xvmsaa21''');
          result = await localDb.execute(datagram);
          debugPrint('SPX_XVMS_AA21 ok');
        } else {
          debugPrint('SPX_XVMS_AA21 ng' + result2.getNGMessage());
        }
      }
    } else {
      debugPrint('error uploadaa21' + result.getNGMessage());
    }
  }

  Future<bool> uploadab03() async {
    Datagram datagram = Datagram(databaseNameOrSid: localDb.dbName);
    datagram.addText('''select * from xvmsab03''');
    ResponseResult result = await localDb.execute(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      if (data.length > 0) {
        String json = '{"items":' + jsonEncode(data) + '}';

        Datagram datagram2 = Datagram();
        datagram2.addText('''if(1=1)
                        declare @rc int
                        declare @sjson nvarchar(max) = '$json';
                        declare @suserid varchar(30) = '${Business.userId}';
                        declare @sdeptid varchar(30) = '${Business.deptId}';
                        declare @oresult_flag varchar(2)
                        declare @oresult nvarchar(4000)
                        
                        execute @rc = [dbo].[spx_xvms_ab03_insert] 
                            @sjson,
                            @suserid,
                            @sdeptid,
                            @oresult_flag output,
                            @oresult output

                        if (@oresult_flag = 'NG')
                            begin
                                raiserror(@oresult,16,1);
                            end
                        select @oresult_flag as ORESULT_FLAG,@oresult as ORESULT;''');
        ResponseResult result2 = await Business.apiExecuteDatagram(datagram2);
        if (result2.flag == ResultFlag.ok) {
          datagram.setCommandList = [];
          datagram.addText('''delete from xvmsab03''');
          result = await localDb.execute(datagram);
          checkLocalAB03();
          MessageBox.showInformation(context, '', '記錄離線上傳完成');
          return true;
        } else {
          MessageBox.showWarning(context, '', result2.getNGMessage());
          return false;
        }
      } else
        return false;
    } else {
      debugPrint('uploadab03' + result.getNGMessage());
      return false;
    }
  }

  Future<void> uploadImageItem() async {
    Datagram datagram = Datagram(databaseNameOrSid: localDb.dbName);
    datagram.addText('''select * from imageitem''');
    ResponseResult result = await localDb.execute(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      for (Map<String, dynamic> item in data) {
        Map<String, String> headers = {
          'ModuleId': moduleId,
          'SubPath': moduleId + '\\' + item['Tag1'],
          'ReceiptType': item['ReceiptType'],
          'ReceiptSerial': item['ReceiptSerial'],
          'ReceiptNo': item['ReceiptNo'],
          'Tag1': item['Tag1'],
          'Tag2': '',
          'Descryption': '',
          'UploadUser': Business.userId,
          'UploadDevice': '',
        };

        File file = File(item['FilePath'].toString());

        List<File> uploadFile = [];
        uploadFile.add(file);

        ResponseResult result2 = await Business.apiUploadFile(
            FileCmdType.file, uploadFile,
            headers: headers);
        if (result2.flag == ResultFlag.ok) {
          uploadFile.first.deleteSync();
        }
      }
    } else {
      debugPrint(result.getNGMessage());
    }
  }

  Future<void> uploadUpdateSerNoFromAA21() async {
    Datagram datagram = Datagram(databaseNameOrSid: localDb.dbName);
    datagram.addText('''select * from imageitem''');
    ResponseResult result = await localDb.execute(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();

      Datagram datagram2 = Datagram();
      //因離線作業只知道車身號碼，點交次數不知道，在此回寫點交次數
      for (Map<String, dynamic> item in data) {
        if (item['ReceiptSerial'] == '0') {
          datagram2.addText('''update t2
                               set t2.receipt_serial = cast(t1.vsaa2105 as varchar)
                               from xvms_aa21 as t1
                               left join sys_file as t2 on t1.vsaa2112 = t2.tag1
                               where vsaa2112 = '${item['Tag1']}';''');
        }
      }
      ResponseResult result2 = await Business.apiExecuteDatagram(datagram2);
      if (result2.flag == ResultFlag.ok) {}

      datagram.setCommandList = [];
      datagram.addText('''delete from imageitem''');
      result = await localDb.execute(datagram);
    }
  }

  Future<void> uploadUpdateSerNoFromAB03() async {
    Datagram datagram = Datagram(databaseNameOrSid: localDb.dbName);
    datagram.addText('''select * from imageitem''');
    ResponseResult result = await localDb.execute(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();

      Datagram datagram2 = Datagram();
      //因離線作業只知道車身號碼，點交次數不知道，在此回寫點交次數
      for (Map<String, dynamic> item in data) {
        if (item['ReceiptSerial'] == '0') {
          datagram2.addText('''update t2
                               set t2.receipt_serial = cast(t1.vsab0305 as varchar)
                               from xvms_ab03 as t1
                               left join sys_file as t2 on t1.vsab0324 = t2.tag1
                               where vsab0324 = '${item['Tag1']}';''');
        }
      }
      ResponseResult result2 = await Business.apiExecuteDatagram(datagram2);
      if (result2.flag == ResultFlag.ok) {}

      datagram.setCommandList = [];
      datagram.addText('''delete from imageitem''');
      result = await localDb.execute(datagram);
    }
  }
}

class XVMSAA03 {
  /// 車身號碼
  String vsaa0300;

  /// 進口商系統碼
  String vsaa0301;

  /// 廠牌系統碼
  String vsaa0302;

  /// 車款系統碼
  String vsaa0303;

  /// 車型系統碼
  String vsaa0304;

  /// 點交次數
  int vsaa0305;

  /// 來源名稱
  String vsaa0306;

  /// 檢查分類
  String vsaa0307;

  /// 檢查項次
  int vsaa0308;

  /// 是否檢查
  String vsaa0309;

  /// 檢查日期
  String vsaa0310;

  /// 檢查時間
  String vsaa0311;

  /// 檢查人員
  String vsaa0312;

  /// 時間標記
  int timestamp;

  XVMSAA03();

  Map toJson() => {
        'vsaa0300': vsaa0300,
        'vsaa0301': vsaa0301,
        'vsaa0302': vsaa0302,
        'vsaa0303': vsaa0303,
        'vsaa0304': vsaa0304,
        'vsaa0305': vsaa0305,
        'vsaa0306': vsaa0306,
        'vsaa0307': vsaa0307,
        'vsaa0308': vsaa0308,
        'vsaa0309': vsaa0309,
        'vsaa0310': vsaa0310,
        'vsaa0311': vsaa0311,
        'vsaa0312': vsaa0312,
      };

  factory XVMSAA03.fromJson(Map<String, dynamic> parsedJson) {
    XVMSAA03 xvmsaa03 = XVMSAA03();
    xvmsaa03.vsaa0300 = parsedJson['vsaa0300'];
    xvmsaa03.vsaa0301 = parsedJson['vsaa0301'];
    xvmsaa03.vsaa0302 = parsedJson['vsaa0302'];
    xvmsaa03.vsaa0303 = parsedJson['vsaa0303'];
    xvmsaa03.vsaa0304 = parsedJson['vsaa0304'];
    xvmsaa03.vsaa0305 = parsedJson['vsaa0305'];
    xvmsaa03.vsaa0306 = parsedJson['vsaa0306'];
    xvmsaa03.vsaa0307 = parsedJson['vsaa0307'];
    xvmsaa03.vsaa0308 = parsedJson['vsaa0308'];
    xvmsaa03.vsaa0309 = parsedJson['vsaa0309'];
    xvmsaa03.vsaa0310 = parsedJson['vsaa0310'];
    xvmsaa03.vsaa0311 = parsedJson['vsaa0311'];
    xvmsaa03.vsaa0312 = parsedJson['vsaa0312'];
    return xvmsaa03;
  }
}

class XVMSAB03 {
  ///車身號碼
  String vsab0300;

  ///點交次數
  int vsab0305;

  ///來源名稱
  String vsab0306;

  ///檢查分類
  ActionSheet vsab0307;

  ///檢查項次
  int vsab0308;

  ///是否缺失
  String vsab0309;

  ///公證
  String vsab0310;

  ///方位
  ActionSheet vsab0311;

  ///異常位置
  ActionSheet vsab0312;

  ///異常原因
  ActionSheet vsab0313;

  ///檢查說明
  String vsab0314;

  ///判定
  ActionSheet vsab0315;

  ///檢查日期
  String vsab0316;

  ///檢查時間
  String vsab0317;

  ///檢查人員
  String vsab0318;

  ///檔案序號
  String vsab0324;

  XVMSAB03();

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'vsab0300': vsab0300,
      'vsab0305': vsab0305,
      'vsab0306': vsab0306,
      'vsab0307': vsab0307.contentkey,
      'vsab0308': vsab0308,
      'vsab0309': vsab0309,
      'vsab0310': vsab0310,
      'vsab0311': vsab0311.contentkey,
      'vsab0312': vsab0312.contentkey,
      'vsab0313': vsab0313.contentkey,
      'vsab0314': vsab0314,
      'vsab0315': vsab0315.contentkey,
      'vsab0316': vsab0316,
      'vsab0317': vsab0317,
      'vsab0318': vsab0318,
      'vsab0324': vsab0324,
    };

    return map;
  }

  XVMSAB03.fromMap(Map<String, dynamic> map) {
    vsab0300 = map['vsab0300'];
    vsab0305 = map['vsab0305'];
    vsab0306 = map['vsab0306'];
    vsab0307 = map['vsab0307'];
    vsab0308 = map['vsab0308'];
    vsab0309 = map['vsab0309'];
    vsab0310 = map['vsab0310'];
    vsab0311 = map['vsab0311'];
    vsab0312 = map['vsab0312'];
    vsab0313 = map['vsab0313'];
    vsab0314 = map['vsab0314'];
    vsab0315 = map['vsab0315'];
    vsab0316 = map['vsab0316'];
    vsab0317 = map['vsab0317'];
    vsab0318 = map['vsab0318'];
    vsab0324 = map['vsab0324'];
  }
}

class ActionSheet {
  final String title;
  final String label;
  final String columnNamekey;
  final String columnNamevalue;
  String contentkey;
  String contentvalue;

  ActionSheet(this.title, this.label, this.columnNamekey, this.columnNamevalue);

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'title': title,
      'label': label,
      'columnNamekey': columnNamekey,
      'columnNamevalue': columnNamevalue,
      'contentkey': contentkey,
      'contentvalue': contentvalue,
    };

    return map;
  }
}

class XVMSAA21 {
  /// 車身號碼
  String vsaa2100;

  ///點交次數
  int vsaa2105;

  ///里程數
  int vsaa2107;

  ///公司代碼
  String companyId;

  ///部門代碼
  String deptId;

  ///使用者代碼
  String userId;

  ///檔案序號
  String uuid;

  XVMSAA21();

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'vsaa2100': vsaa2100,
      'vsaa2105': vsaa2105,
      'vsaa2107': vsaa2107.toString(),
      'companyId': companyId,
      'deptId': deptId,
      'userId': userId,
      'uuid': uuid,
    };

    return map;
  }

  XVMSAA21.fromMap(Map<String, dynamic> map) {
    vsaa2100 = map['vsaa2100'];
    vsaa2105 = map['vsaa2105'];
    vsaa2107 = map['vsaa2107'];
    companyId = map['companyId'];
    deptId = map['deptId'];
    userId = map['userId'];
    uuid = map['uuid'];
  }
}
