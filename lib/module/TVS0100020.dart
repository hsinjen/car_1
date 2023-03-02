import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
//import 'package:barcode_scan/barcode_scan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:car_1/business/datagram.dart';
import 'package:car_1/business/responseresult.dart';
import 'package:car_1/apis/messagebox.dart';
import 'package:car_1/business/business.dart';
import 'package:car_1/business/enums.dart';
import '../model/sysMenu.dart';
import 'GeneralWidget.dart';
import 'GeneralFunction.dart';
import 'package:flutter/cupertino.dart';
//import 'package:car_1/module/CameraBoxAdv.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:camera/camera.dart';
import '../model/sysInputToolBar.dart';
import '../model/sysCamera.dart';

class TVS0100020 extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _TVS0100020();
  }
}

class _TVS0100020 extends State<TVS0100020> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final String moduleId = 'TVS0100020';
  final String moduleName = 'RETROFIT 作業';
  final String imageCategory = 'TVS0100020';
  bool _isLoading = false;
  Directory _appDocDir;
  InputToolBarState _inputToolBarState;
  GlobalKey<InputToolBarContext> _inputToolBarKey;
  Map<String, dynamic> _currentVin;
  Map<String, dynamic> _currentHeader;
  List<Map<String, dynamic>> _currentContents;
  List<CameraDescription> cameras;
  List<ImageItem> _currentImageList = [];
  bool _currentVinLock = false; //車身作業中止
  List<KeyValueTri> _operationTeamState = [];

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
    if (action == 'date1') {
      _currentHeader['備註'] = value;
    }
    //vin
    if (action == "vin") {
      List<Map<String, dynamic>> data = await _loadVin(value);
      if (data == null || data.length == 0) {
        _inputToolBarKey.currentState
            .showMessage(_scaffoldKey, ResultFlag.ng, '無此車身號碼 $value');
      } else if (data.length > 1) {
        showVinActionSheet(data);
      } else if (data.length == 1) {
        setState(() {
          _currentVin = data[0];
        });
        // await _loadVinPicCount(data[0]['車身號碼'], data[0]['點交次數'].toString());
        await _loadHeader(data[0]['車身號碼'], data[0]['點交次數']);
        if (_currentHeader != null) {
          bool isCheckLock = await _checkVinLock(data[0]['車身號碼'], station: '');
          setState(() {
            _currentVinLock = isCheckLock;
          });
          if (isCheckLock == false)
            await _loadContent(_currentHeader['車身號碼'], _currentHeader['點交次數'],
                _currentHeader['裝配次數']);
        }
      }
    }
    //vinAction
    else if (action == "vinAction") {
      //  await _loadVinPicCount(
      //    _currentVin['車身號碼'], _currentVin['點交次數'].toString());
      await _loadHeader(_currentVin['車身號碼'], _currentVin['點交次數']);
      await _loadContent(_currentHeader['車身號碼'], _currentHeader['點交次數'],
          _currentHeader['裝配次數']);
    }
    //headerRemark
    else if (action == 'headerRemark') {
      _currentHeader['備註'] = value;
    }
    //addItem
    else if (action == 'addItem') {
      if (value.trim() != '') {
        if (_currentHeader != null && _currentHeader.length > 0) {
          setState(() {
            _currentContents.add({
              '車身號碼': _currentHeader['車身號碼'],
              '點交次數': _currentHeader['點交次數'],
              '裝配次數': _currentHeader['裝配次數'],
              '序號': 0,
              '作業項目': value,
              '裝配狀態': 'Y',
              '作業人員': '',
              '備註': '',
              '資料旗標': 'A',
            });
          });
        }
      }
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
              //_inputToolBarKey.currentState.setAction('vin');
              setState(() {
                _inputToolBarState.setDefault();
                _currentVin = null;
                _currentHeader = null;
                _currentVinLock = false;
                _currentContents = null;
                _currentImageList = [];
              });
            },
          ),
          //Save
          new IconButton(
            icon: new Icon(Icons.save),
            onPressed: () async {
              if (_currentVin == null) return;
              if (_currentHeader == null) return;
              if (_currentContents == null) return;
              if (_currentVinLock == true) {
                _inputToolBarKey.currentState
                    .showMessage(_scaffoldKey, ResultFlag.ng, '車身狀態作業中止');
                return;
              }
              setState(() {
                _isLoading = true;
              });
              await _save();
              await _saveFile();

              setState(() {
                _inputToolBarState.setDefault();
                _currentVin = null;
                _currentHeader = null;
                _currentContents = null;
                _currentVinLock = false;
                _isLoading = false;
              });
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
                        buildHeaderTwoRow(context, '廠牌', 30, '車身號碼', 70),
                        buildDataTwoRow(
                            context,
                            _currentVin == null ? '' : _currentVin['廠牌名稱'],
                            30,
                            _currentVin == null ? '' : _currentVin['車身號碼'],
                            70),
                        buildHeaderTwoRow(context, '車款', 30, '點交單', 70),
                        buildDataTwoRowWithContainer(
                            context,
                            _currentVin == null ? '' : _currentVin['車款名稱'],
                            30,
                            Container(
                              decoration: BoxDecoration(
                                border: Border(
                                    top: BorderSide(width: 1),
                                    right: BorderSide(width: 1)),
                              ),
                              alignment: Alignment.center,
                              width:
                                  MediaQuery.of(context).size.width / 100 * 70,
                              child: Row(children: [
                                //點交單人員
                                SizedBox(
                                  height: 24,
                                  width: MediaQuery.of(context).size.width /
                                          100 *
                                          70 -
                                      2,
                                  child: Column(children: [
                                    Expanded(
                                      child: RaisedButton(
                                        color: Colors.white,
                                        textColor: Colors.black,
                                        padding: EdgeInsets.all(0),
                                        child: Text(_currentHeader == null ||
                                                _currentHeader['點交單人員'] == ''
                                            ? '選擇人員'
                                            : _currentHeader['點交單人員']),
                                        onPressed: () {
                                          showHeaderUserActionSheet('點交單人員');
                                        },
                                      ),
                                    ),
                                  ]),
                                ),
                              ]),
                            )),
                        buildHeaderTwoRow(context, '車型', 30, '終檢', 70),
                        buildDataTwoRowWithContainer(
                          context,
                          _currentVin == null ? '' : _currentVin['車型名稱'],
                          30,
                          Container(
                            decoration: BoxDecoration(
                              border: Border(
                                  top: BorderSide(width: 1),
                                  right: BorderSide(width: 1)),
                            ),
                            alignment: Alignment.center,
                            width: MediaQuery.of(context).size.width / 100 * 70,
                            child: Row(children: [
                              //Camera
                              SizedBox(
                                height: 24,
                                child: Container(
                                  color: _currentImageList.length > 0
                                      ? Colors.blue
                                      : Colors.grey[300],
                                  child: IconButton(
                                    padding: EdgeInsets.all(0),
                                    icon: Icon(Icons.camera_alt),
                                    iconSize: 14,
                                    onPressed: () async {
                                      if (_currentVin == null ||
                                          _currentVin.length == 0) return;
                                      if (_currentVinLock == true) {
                                        _inputToolBarKey.currentState
                                            .showMessage(_scaffoldKey,
                                                ResultFlag.ng, '車身狀態作業中止');
                                        return;
                                      }
                                      if (cameras == null)
                                        cameras = await availableCameras();
                                      if (cameras != null) {
                                        await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  CameraWindow(
                                                cameraType: CameraType.camera,
                                                cameraList: cameras,
                                                imageDirPath:
                                                    _currentVin['車身號碼'] +
                                                        '\\' +
                                                        _currentVin['點交次數']
                                                            .toString(),
                                                imageList: _currentImageList,
                                                keyNo: 'RETROFIT',
                                                keyDate: '',
                                                keyNumber: _currentVin['車身號碼'],
                                                tag1: _currentVin['點交次數']
                                                    .toString(),
                                                onConfirm: (v) {
                                                  _currentImageList = v;
                                                },
                                              ),
                                            ));
                                      }
                                      // await Navigator.push(
                                      //   context,
                                      //   MaterialPageRoute(
                                      //       builder: (context) => CameraBoxAdv(
                                      //               'compid',
                                      //               imageCategory,
                                      //               _currentVin['車身號碼'] +
                                      //                   '-' +
                                      //                   _currentVin['點交次數']
                                      //                       .toString(),
                                      //               (resultImageCount) {
                                      //             _currentVin['照片數'] =
                                      //                 _currentVin['照片數'] + 1;
                                      //           })),
                                      // );
                                    },
                                  ),
                                ),
                              ),
                              //照片張數
                              // SizedBox(
                              //   height: 24,
                              //   width:
                              //       MediaQuery.of(context).size.width / 100 * 5,
                              //   child: Container(
                              //     alignment: Alignment.center,
                              //     child: Text(_currentVin == null
                              //         ? '0'
                              //         : _currentVin['照片數'].toString()),
                              //   ),
                              // ),
                              //終檢完成
                              SizedBox(
                                height: 24,
                                width: MediaQuery.of(context).size.width /
                                    100 *
                                    15,
                                child: RaisedButton(
                                  color: _currentHeader != null &&
                                          _currentHeader['終檢狀態'] == 'Y'
                                      ? Colors.lightBlue
                                      : Colors.grey[200],
                                  //splashColor: Colors.yellow,
                                  textColor: _currentHeader != null &&
                                          _currentHeader['終檢狀態'] == 'Y'
                                      ? Colors.white
                                      : Colors.black,
                                  padding: EdgeInsets.all(0),
                                  child: Text('完成'),
                                  onPressed: () {
                                    if (_currentHeader != null) {
                                      if (_currentContents
                                              .where((element) =>
                                                  (element['裝配狀態'] == 'N'))
                                              .length >
                                          0) {
                                        _inputToolBarKey.currentState
                                            .showMessage(_scaffoldKey,
                                                ResultFlag.ng, '尚有作業項目未完成');
                                      } else if (_currentContents
                                              .where((element) =>
                                                  (element['作業人員'] == ''))
                                              .length >
                                          0) {
                                        _inputToolBarKey.currentState
                                            .showMessage(_scaffoldKey,
                                                ResultFlag.ng, '作業項目尚有未指定作業人員');
                                      } else {
                                        setState(() {
                                          _currentHeader['終檢狀態'] = 'Y';
                                        });
                                      }
                                    }
                                  },
                                ),
                              ),
                              //終檢未完成
                              SizedBox(
                                height: 24,
                                width: MediaQuery.of(context).size.width /
                                    100 *
                                    15,
                                child: RaisedButton(
                                  color: _currentHeader == null ||
                                          _currentHeader['終檢狀態'] == 'N'
                                      ? Colors.lightBlue
                                      : Colors.grey[200],
                                  textColor: _currentHeader == null ||
                                          _currentHeader['終檢狀態'] == 'N'
                                      ? Colors.white
                                      : Colors.black,
                                  padding: EdgeInsets.all(0),
                                  child: Text('等待'),
                                  onPressed: () {
                                    if (_currentHeader != null) {
                                      setState(() {
                                        _currentHeader['終檢狀態'] = 'N';
                                      });
                                    }
                                  },
                                ),
                              ),
                              //終檢人員
                              SizedBox(
                                height: 24,
                                width: MediaQuery.of(context).size.width /
                                    100 *
                                    20,
                                child: Column(children: [
                                  Expanded(
                                    child: RaisedButton(
                                      color: Colors.white,
                                      textColor: Colors.black,
                                      padding: EdgeInsets.all(0),
                                      child: Text(_currentHeader == null ||
                                              _currentHeader['終檢人員'] == ''
                                          ? '選擇人員'
                                          : _currentHeader['終檢人員']),
                                      onPressed: () {
                                        showHeaderUserActionSheet('終檢人員');
                                      },
                                    ),
                                  ),
                                ]),
                              ),
                            ]),
                          ),
                        ),
                        buildHeaderOneRow(context, '備註', 100),
                        GestureDetector(
                          onTap: () {
                            if (_currentHeader == null ||
                                _currentHeader.length == 0) return;
                            setState(() {
                              _inputToolBarState.showKeyboard(
                                  'headerRemark', TextInputType.text);
                            });
                          },
                          child: buildDataOneRow(
                              context,
                              _currentHeader == null
                                  ? ''
                                  : _currentHeader['備註'],
                              100),
                        ),
                        Divider(height: 20),
                        //==============
                        Container(
                            child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(children: _buildOperationTeam()
                                    //[
                                    //Expanded(child: Container()),

                                    // SizedBox(
                                    //     height: 24,
                                    //     width: 80,
                                    //     child: RaisedButton(
                                    //       color: Colors.black,
                                    //       padding: EdgeInsets.all(0),
                                    //       child: Text('小組一',
                                    //           style: TextStyle(color: Colors.white)),
                                    //       onPressed: () {
                                    //         _loadTeamProfile('TEAM1');
                                    //       },
                                    //       onLongPress: () {
                                    //         _saveTeamProfile('TEAM1');
                                    //       },
                                    //     )),
                                    // SizedBox(
                                    //     height: 24,
                                    //     width: 80,
                                    //     child: RaisedButton(
                                    //       color: Colors.black,
                                    //       padding: EdgeInsets.all(0),
                                    //       child: Text('小組二',
                                    //           style: TextStyle(color: Colors.white)),
                                    //       onPressed: () {
                                    //         _loadTeamProfile('TEAM2');
                                    //       },
                                    //       onLongPress: () {
                                    //         _saveTeamProfile('TEAM2');
                                    //       },
                                    //     )),
                                    // SizedBox(
                                    //     height: 24,
                                    //     width: 80,
                                    //     child: RaisedButton(
                                    //       color: Colors.black,
                                    //       padding: EdgeInsets.all(0),
                                    //       child: Text('小組三',
                                    //           style: TextStyle(color: Colors.white)),
                                    //       onPressed: () {
                                    //         _loadTeamProfile('TEAM3');
                                    //       },
                                    //       onLongPress: () {
                                    //         _saveTeamProfile('TEAM3');
                                    //       },
                                    //     )),
                                    //]
                                    ))),
                        //==============
                        buildHeaderThreeRow(
                            context, '作業項目', 52, '動作', 20, '作業人員', 20),
                        _currentVinLock == false
                            ? Column(
                                children: buildGridView(context, 52, 20, 20))
                            : Container(),
                      ]),
                    ),
                  ),

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

  List<Widget> _buildOperationTeam() {
    List<Widget> _list = [];

    for (int i = 1; i <= 6; i++) {
      _list.add(
        SizedBox(
            height: 24,
            width: 80,
            child: RaisedButton(
              color: _operationTeamState
                          .where((element) =>
                              element.key == 'TEAM$i' &&
                              element.onPress == true)
                          .length >
                      0
                  ? Colors.green
                  : Colors.black,
              padding: EdgeInsets.all(0),
              child: Text('小組-$i', style: TextStyle(color: Colors.white)),
              onPressed: () {
                _loadTeamProfile('TEAM$i');

                _operationTeamState.forEach((element) {
                  element.onPress = false;
                });

                if (_operationTeamState
                        .where((element) => element.key == 'TEAM$i')
                        .length ==
                    0) {
                  KeyValueTri c = KeyValueTri();
                  c.key = 'TEAM$i';
                  c.onPress = true;
                  _operationTeamState.add(c);
                } else {
                  _operationTeamState
                      .firstWhere((element) => element.key == 'TEAM$i')
                      .onPress = true;
                }
                setState(() {});
              },
              onLongPress: () {
                _saveTeamProfile('TEAM$i');
              },
            )),
      );
    }
    return _list;
  }

  Future<void> _save() async {
    if (_currentVin == null) return;
    if (_currentHeader == null) return;

    Datagram datagram = Datagram();

    for (int i = _currentContents.length - 1; i >= 0; i--) {
      if (_currentContents[i]['資料旗標'] == 'D' && _currentContents[i]['序號'] == 0)
        continue;

      datagram.addProcedure('spx_xvms_ba02_in', parameters: [
        ParameterField('smode', ParamType.strings, ParamDirection.input,
            value: _currentContents[i]['資料旗標']),
        ParameterField('svsba2006', ParamType.strings, ParamDirection.input,
            value: _currentContents[i]['車身號碼']),
        ParameterField('svsba2007', ParamType.strings, ParamDirection.input,
            value: _currentContents[i]['點交次數'].toString()),
        ParameterField('svsba2008', ParamType.strings, ParamDirection.input,
            value: _currentHeader['終檢狀態']),
        ParameterField('svsba2013', ParamType.strings, ParamDirection.input,
            value: _currentHeader['終檢人員']),
        ParameterField('svsba2014', ParamType.strings, ParamDirection.input,
            value: _currentHeader['點交單人員']),
        ParameterField('svsba2017', ParamType.strings, ParamDirection.input,
            value: _currentHeader['備註']),
        ParameterField('svsbb2008', ParamType.strings, ParamDirection.input,
            value: _currentContents[i]['序號'].toString()),
        ParameterField('svsbb2009', ParamType.strings, ParamDirection.input,
            value: _currentContents[i]['作業項目']),
        ParameterField('svsbb2010', ParamType.strings, ParamDirection.input,
            value: _currentContents[i]['裝配狀態'] == ''
                ? 'Y'
                : _currentContents[i]['裝配狀態']),
        ParameterField('svsbb2011', ParamType.strings, ParamDirection.input,
            value: _currentContents[i]['作業人員']),
        ParameterField('svsbb2012', ParamType.strings, ParamDirection.input,
            value: ''),
        ParameterField('suserid', ParamType.strings, ParamDirection.input,
            value: Business.userId),
        ParameterField('sdeptid', ParamType.strings, ParamDirection.input,
            value: Business.deptId),
        ParameterField(
            'oresult_flag', ParamType.strings, ParamDirection.output),
        ParameterField('oresult', ParamType.strings, ParamDirection.output),
      ]);
    }
    datagram.addProcedure('spx_xvms_ba02_in', parameters: [
      ParameterField('smode', ParamType.strings, ParamDirection.input,
          value: 'H'),
      ParameterField('svsba2006', ParamType.strings, ParamDirection.input,
          value: _currentHeader['車身號碼']),
      ParameterField('svsba2007', ParamType.strings, ParamDirection.input,
          value: _currentHeader['點交次數'].toString()),
      ParameterField('svsba2008', ParamType.strings, ParamDirection.input,
          value: _currentHeader['終檢狀態']),
      ParameterField('svsba2013', ParamType.strings, ParamDirection.input,
          value: _currentHeader['終檢人員']),
      ParameterField('svsba2014', ParamType.strings, ParamDirection.input,
          value: _currentHeader['點交單人員']),
      ParameterField('svsba2017', ParamType.strings, ParamDirection.input,
          value: _currentHeader['備註']),
      ParameterField('svsbb2008', ParamType.strings, ParamDirection.input,
          value: '0'),
      ParameterField('svsbb2009', ParamType.strings, ParamDirection.input,
          value: ''),
      ParameterField('svsbb2010', ParamType.strings, ParamDirection.input,
          value: ''),
      ParameterField('svsbb2011', ParamType.strings, ParamDirection.input,
          value: ''),
      ParameterField('svsbb2012', ParamType.strings, ParamDirection.input,
          value: ''),
      ParameterField('suserid', ParamType.strings, ParamDirection.input,
          value: Business.userId),
      ParameterField('sdeptid', ParamType.strings, ParamDirection.input,
          value: Business.deptId),
      ParameterField('oresult_flag', ParamType.strings, ParamDirection.output),
      ParameterField('oresult', ParamType.strings, ParamDirection.output),
    ]);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
    } else {
      _inputToolBarKey.currentState
          .showMessage(_scaffoldKey, ResultFlag.ng, result.getNGMessage());
    }
  }

  Future<void> _saveFile() async {
    if (_currentVin == null) return;
    if (_currentHeader == null) return;
    if (_currentImageList.length == 0) return;

    for (int i = 0; i < _currentImageList.length; i++) {
      Map<String, String> headers = {
        'ModuleId': 'RETROFIT',
        'SubPath': 'RETROFIT\\' +
            _currentVin['車身號碼'] +
            '\\' +
            _currentVin['點交次數'].toString() +
            '\\' +
            _currentHeader['裝配次數'].toString(),
        'ReceiptType': 'RETROFIT',
        'ReceiptSerial': _currentVin['車身號碼'],
        'ReceiptNo': _currentVin['點交次數'].toString(),
        'Tag1': _currentHeader['裝配次數'].toString(),
        'Tag2': '',
        'Descryption': '',
        'UploadUser': Business.userId,
        'UploadDevice': '',
      };

      List<File> uploadFile = [];
      _currentImageList.forEach((element) {
        uploadFile.add(element.file);
      });
      ResponseResult result = await Business.apiUploadFile(
          FileCmdType.file, uploadFile,
          headers: headers);
      if (result.flag == ResultFlag.ok) {
        // for (int i = 0; i < uploadFile.length; i++)
        //      uploadFile[i].deleteSync();
        CommonMethod.removeFilesOfDirNoQuestion(context, 'RETROFIT', '');
      }
    }
  }

  Future<List<Map<String, dynamic>>> _loadVin(String value) async {
    Datagram datagram = Datagram();
    datagram.addText("""select x2.vsaa0100 as 車身號碼,
                               x2.vsaa0119 as 點交次數,
                               x2.vsaa0101 as 引擎號碼,
                               x2.vsaa0111 as 進口商系統碼,
                                  x3.進口商名稱,
                               x2.vsaa0102 as 廠牌系統碼,
                                  x3.廠牌名稱,
                               x2.vsaa0103 as 車款系統碼,
                                  x3.車款名稱,
                               x2.vsaa0104 as 車型系統碼,
                                  x3.車型名稱,
                               x2.vsaa0106 as 車色,
                               x2.vsaa0107 as 車身年份,
                               x2.vsaa0110 as 出廠年月日,
                               x2.vsaa0122 as 到港日期,
                               0 as 照片數
                        from (
                              select vsaa0100,max(vsaa0119) as vsaa0119 
                              from xvms_aa01 where vsaa0114 not in ('00','09','10','99') and vsaa0100 like '%$value'
                              group by vsaa0100
                        ) as x1 left join xvms_aa01 as x2 on x1.vsaa0100 = x2.vsaa0100 and x1.vsaa0119 = x2.vsaa0119
                        left join vi_xvms_0001_04 as x3 on x2.vsaa0111 = x3.進口商系統碼 and
                                                           x2.vsaa0102 = x3.廠牌系統碼 and
                                                           x2.vsaa0103 = x3.車款系統碼 and
                                                           x2.vsaa0104 = x3.系統碼
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

  Future<void> _loadVinPicCountBak(String vin, String vinNo) async {
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

  Future<void> _loadHeader(String vin, int vinNo) async {
    Datagram datagram = Datagram();
    datagram.addText("""select x2.vsba2006 as 車身號碼,
                               x2.vsba2007 as 點交次數,
                               x2.vsba2015 as 裝配次數,
                               x2.vsba2008 as 終檢狀態,
                               x2.vsba2013 as 終檢人員,
                               x2.vsba2014 as 點交單人員,
                               x2.vsba2017 as 備註
                        from (
                        select vsba2006,
                               vsba2007,
                               max(vsba2015) as vsba2015
                        from xvms_ba02 where vsba2006 = '$vin' and vsba2007  = $vinNo
                        group by vsba2006,vsba2007
                        ) as x1 left join xvms_ba02 as x2 on x1.vsba2006 = x2.vsba2006 and x1.vsba2007 = x2.vsba2007 and x1.vsba2015 = x2.vsba2015
                        where x2.vsba2000 is not null;
                        """, rowIndex: 0, rowSize: 65535);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      if (data.length > 0) {
        if (data[0]['終檢狀態'] == 'Y') {
          _inputToolBarKey.currentState
              .showMessage(_scaffoldKey, ResultFlag.ng, '$vin 已完成 RETROFIT');
          setState(() {
            _inputToolBarState.setDefault();
            _currentVin = null;
            _currentHeader = null;
            _currentContents = null;
          });
        } else {
          setState(() {
            _currentHeader = data[0];
          });
        }
      } else {
        setState(() {
          _currentHeader = {
            '車身號碼': vin,
            '點交次數': vinNo,
            '裝配次數': 0,
            '終檢狀態': 'N',
            '終檢人員': '',
            '點交單人員': '',
            '備註': '',
          };
        });
      }
    } else {
      setState(() {
        _currentHeader = {
          '車身號碼': vin,
          '點交次數': vinNo,
          '裝配次數': 0,
          '終檢狀態': 'N',
          '終檢人員': '',
          '點交單人員': '',
          '備註': '',
        };
      });
    }
  }

  Future<void> _loadContent(String vin, int vinNo, int operationNo) async {
    Datagram datagram = Datagram();

    datagram.addText("""select x1.vsbb2005 as 車身號碼,
                                 x1.vsbb2006 as 點交次數,
                                 x1.vsbb2007 as 裝配次數,
                                 x1.vsbb2008 as 序號,
                                 x1.vsbb2009 as 作業項目,
                                 x1.vsbb2010 as 裝配狀態,
                                 x1.vsbb2011 as 作業人員,
                                 x1.vsbb2012 as 備註,
                                 'U' as 資料旗標
                          from xvms_bb02 as x1
                          where x1.vsbb2005 = '$vin' and x1.vsbb2006 = $vinNo and x1.vsbb2007 = $operationNo;
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
        datagram.addText("""select x1.vsaa0100 as 車身號碼,
                                  x1.vsaa0119 as 點交次數,
                                  $operationNo as 裝配次數,
                                  0 as 序號,
                                  x2.vsba1005 as 作業項目,
                                  '' as 裝配狀態,
                                  '' as 作業人員,
                                  '' as 備註,
                                  'A' as 資料旗標
                           from xvms_aa01 as x1 left join xvms_ba01 as x2 on x1.vsaa0111 = x2.vsba1000 AND
                                                                             x1.vsaa0102 = x2.vsba1001 AND
                                                                             x1.vsaa0103 = x2.vsba1002 AND
                                                                             x1.vsaa0104 = x2.vsba1003
                           where x1.vsaa0100 = '$vin' and x1.vsaa0119 = $vinNo and x2.vsba1000 is not null;
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

  Future<bool> _checkVinLock(String vin, {String station = ''}) async {
    Datagram datagram = Datagram();
    if (station == '') {
      datagram.addText("""select 異常中止時間,中止說明 from vi_xvms_ba02_pause_history
                          where 類別 = '車身' and 車身號碼 = '$vin'
                       """, rowIndex: 0, rowSize: 65535);
    } else {
      datagram.addText("""select 異常中止時間,中止說明 from vi_xvms_ba02_pause_history
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

  Future<bool> _lockVin() async {
    if (_currentVin == null) return false;
    Datagram datagram = Datagram();
    datagram.addText(
        """update xvms_ba02 set vsba2019 = entirev4.dbo.systemdatetime(),
                                             vsba2020 = N'RETROFIT作業下達中止'
                        where vsba2006 = '${_currentHeader['車身號碼']}' and
                              vsba2007 = ${_currentHeader['點交次數']} and
                              vsba2015 = ${_currentHeader['裝配次數']} and
                              vsba2008 = 'N' and
                              vsba2019 = ''
                     """,
        rowIndex: 0, rowSize: 65535);

    datagram
        .addText("""update x1 set x1.vsbb2019 = entirev4.dbo.systemdatetime(),
                                  x1.vsbb2020 = N'RETROFIT作業下達中止'
                        from xvms_bb02 as x1 left join xvms_ba02 as x2 on x1.vsbb2005 = x2.vsba2006 and
                                                                          x1.vsbb2006 = x2.vsba2007 and
                                                                          x1.vsbb2007 = x2.vsba2015
                        where x1.vsbb2005 = '${_currentHeader['車身號碼']}' and
                              x1.vsbb2006 = ${_currentHeader['點交次數']} and
                              x1.vsbb2007 = ${_currentHeader['裝配次數']} and
                              x1.vsbb2019 = '' and
                              x2.vsba2008 = 'N'
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
    datagram.addText("""update xvms_ba02 set vsba2018 = iif(vsba2009 = '',
                                                            vsba2018,
                                                            vsba2018 + datediff(minute,vsba2019,entirev4.dbo.systemdatetime())),
                                             vsba2019 = '',
                                             vsba2020 = ''
                        where vsba2006 = '${_currentHeader['車身號碼']}' and
                              vsba2007 = ${_currentHeader['點交次數']} and
                              vsba2015 = ${_currentHeader['裝配次數']} and
                              vsba2019 != ''
                     """, rowIndex: 0, rowSize: 65535);

    datagram.addText("""update x1 set x1.vsbb2018 = iif(vsbb2013 = '',
                                                        vsbb2018,
                                                        vsbb2018 +  datediff(minute,vsbb2019,entirev4.dbo.systemdatetime())),
                                      x1.vsbb2019 = '',
                                      x1.vsbb2020 = ''
                    from xvms_bb02 as x1 left join xvms_ba02 as x2 on x1.vsbb2005 = x2.vsba2006 and
                                                                      x1.vsbb2006 = x2.vsba2007 and
                                                                      x1.vsbb2007 = x2.vsba2015
                    where x1.vsbb2005 = '${_currentHeader['車身號碼']}' and
                          x1.vsbb2006 = ${_currentHeader['點交次數']} and
                          x1.vsbb2007 = ${_currentHeader['裝配次數']} and
                          x1.vsbb2019 != ''
                 """, rowIndex: 0, rowSize: 65535);

    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok)
      return true;
    else
      return false;
  }

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

  void showHeaderUserActionSheet(String key) async {
    if (_currentHeader == null || _currentHeader.length == 0) return;
    List<Widget> _list = [];

    Datagram datagram = Datagram();
    //整三裝配
    datagram.addText("""select ixa00401,
                               ixa00403
                        from entirev4.dbo.ifx_a004 where ixa00400 = 'compid' and ixa00408 = '112301'
                        """, rowIndex: 0, rowSize: 65535);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      if (data.length > 0) {
        for (int i = 0; i < data.length; i++) {
          _list.add(CupertinoActionSheetAction(
            child: Text(data[i]['ixa00401'] + ' ' + data[i]['ixa00403']),
            onPressed: () {
              setState(() {
                _currentHeader[key] = data[i]['ixa00403'];
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

  void showContentUserActionSheet(int index) async {
    if (_currentHeader == null || _currentHeader.length == 0) return;
    List<Widget> _list = [];

    Datagram datagram = Datagram();
    //整三裝配
    datagram.addText("""select ixa00401,
                               ixa00403
                        from entirev4.dbo.ifx_a004 where ixa00400 = 'compid' and ixa00408 = '112301'
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
                _currentContents[index]['作業人員'] = data[i]['ixa00403'];
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

  Widget buildHeaderOneRow(
      BuildContext context, String header1, double width1) {
    return Row(children: [
      Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          border: Border(
              left: BorderSide(width: 1),
              top: BorderSide(width: 1),
              right: BorderSide(width: 1)),
        ),
        alignment: Alignment.center,
        width: MediaQuery.of(context).size.width / 100 * width1,
        child: Text(header1),
      ),
    ]);
  }

  Widget buildDataOneRow(BuildContext context, String value1, double width1,
      {bool endRow = false}) {
    return Row(children: [
      Container(
        decoration: BoxDecoration(
          border: Border(
              left: BorderSide(width: 1),
              top: BorderSide(width: 1),
              right: BorderSide(width: 1),
              bottom: BorderSide(width: 1)),
        ),
        alignment: Alignment.center,
        width: MediaQuery.of(context).size.width / 100 * width1,
        height: 24.0,
        child: Text(value1),
      ),
    ]);
  }

  Widget buildHeaderTwoRow(BuildContext context, String header1, double width1,
      String header2, double width2) {
    return Row(children: [
      Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          border: Border(
              left: BorderSide(width: 1),
              top: BorderSide(width: 1),
              right: BorderSide(width: 1)),
        ),
        alignment: Alignment.center,
        width: MediaQuery.of(context).size.width / 100 * width1,
        child: Text(header1),
      ),
      Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          border:
              Border(top: BorderSide(width: 1), right: BorderSide(width: 1)),
        ),
        alignment: Alignment.center,
        width: MediaQuery.of(context).size.width / 100 * width2,
        child: Text(header2),
      ),
    ]);
  }

  Widget buildDataTwoRow(BuildContext context, String value1, double width1,
      String value2, double width2) {
    return Row(children: [
      Container(
        decoration: BoxDecoration(
          border: Border(
              left: BorderSide(width: 1),
              top: BorderSide(width: 1),
              right: BorderSide(width: 1)),
        ),
        alignment: Alignment.center,
        width: MediaQuery.of(context).size.width / 100 * width1,
        height: 24.0,
        child: Text(value1),
      ),
      Container(
        decoration: BoxDecoration(
          border:
              Border(top: BorderSide(width: 1), right: BorderSide(width: 1)),
        ),
        alignment: Alignment.center,
        width: MediaQuery.of(context).size.width / 100 * width2,
        height: 24.0,
        child: Text(value2),
      ),
    ]);
  }

  Widget buildDataTwoRowWithContainer(BuildContext context, String value1,
      double width1, Container container2) {
    return Row(children: [
      Container(
        decoration: BoxDecoration(
          border: Border(
              left: BorderSide(width: 1),
              top: BorderSide(width: 1),
              right: BorderSide(width: 1)),
        ),
        alignment: Alignment.center,
        height: 24.0,
        width: MediaQuery.of(context).size.width / 100 * width1,
        child: Text(value1),
      ),
      container2
    ]);
  }

  Widget buildHeaderThreeRow(
      BuildContext context,
      String header1,
      double width1,
      String header2,
      double width2,
      String header3,
      double width3) {
    return Row(children: [
      SizedBox(
        height: 24,
        width: MediaQuery.of(context).size.width / 100 * 8,
        child: IconButton(
          padding: EdgeInsets.all(0),
          icon: Icon(Icons.add),
          onPressed: () {
            if (_currentHeader == null || _currentHeader.length == 0) return;
            if (_currentVinLock == true) {
              _inputToolBarKey.currentState
                  .showMessage(_scaffoldKey, ResultFlag.ng, '車身狀態作業中止');
              return;
            }
            MessageBox.showQuestion(context, '新增作業項目', '', yesFunc: () {
              setState(() {
                _inputToolBarState.showKeyboard('addItem', TextInputType.text);
              });
            });
          },
        ),
      ),
      Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          border: Border(
              left: BorderSide(width: 1),
              top: BorderSide(width: 1),
              right: BorderSide(width: 1)),
        ),
        alignment: Alignment.center,
        width: MediaQuery.of(context).size.width / 100 * width1,
        child: Text(header1),
      ),
      Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          border:
              Border(top: BorderSide(width: 1), right: BorderSide(width: 1)),
        ),
        alignment: Alignment.center,
        width: MediaQuery.of(context).size.width / 100 * width2,
        child: Text(header2),
      ),
      Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          border:
              Border(top: BorderSide(width: 1), right: BorderSide(width: 1)),
        ),
        alignment: Alignment.center,
        width: MediaQuery.of(context).size.width / 100 * width3,
        child: Text(header3),
      ),
    ]);
  }

  List<Widget> buildGridView(
      BuildContext context, double width1, double width2, double width3) {
    List<Widget> _list = [];

    if (_currentContents != null) {
      for (int i = 0; i < _currentContents.length; i++) {
        if (_currentContents[i]['資料旗標'] == 'D') continue;
        _list.add(buildGridViewItem(
            context,
            i,
            _currentContents[i]['作業項目'],
            width1,
            _currentContents[i]['裝配狀態'],
            width2,
            _currentContents[i]['作業人員'] == ''
                ? '選擇人員'
                : _currentContents[i]['作業人員'],
            width3));
      }
    }

    return _list;
  }

  Widget buildGridViewItem(
      BuildContext context,
      int index,
      String itemText,
      double width1,
      String status,
      double width2,
      String value3,
      double width3) {
    return Row(children: [
      SizedBox(
        height: 24,
        width: MediaQuery.of(context).size.width / 100 * 8,
        child: IconButton(
          padding: EdgeInsets.all(0),
          icon: Icon(Icons.delete),
          onPressed: () {
            MessageBox.showQuestion(context, '刪除作業項目  ($itemText)', '',
                yesFunc: () {
              setState(() {
                _currentContents[index]['資料旗標'] = 'D';
              });
            });
          },
        ),
      ),
      //作業項目
      Container(
        padding: EdgeInsets.all(0),
        decoration: BoxDecoration(
          //color: Colors.grey[300],
          border: Border(
            left: BorderSide(width: 1),
            top: BorderSide(width: 1),
            right: BorderSide(width: 1),
          ),
        ),
        alignment: Alignment.center,
        width: MediaQuery.of(context).size.width / 100 * width1,
        height: 24,
        child: Text(itemText),
      ),
      //動作
      Container(
        decoration: BoxDecoration(
          border:
              Border(top: BorderSide(width: 1), right: BorderSide(width: 1)),
        ),
        alignment: Alignment.center,
        width: MediaQuery.of(context).size.width / 100 * width2,
        height: 24,
        child: Row(children: [
          //OK
          SizedBox(
            height: 22,
            width: MediaQuery.of(context).size.width / 100 * width2 / 2 - 1,
            child: RaisedButton(
              color: status == '' || status == 'Y'
                  ? Colors.lightBlue
                  : Colors.grey[200],
              textColor:
                  status == '' || status == 'Y' ? Colors.white : Colors.black,
              padding: EdgeInsets.all(0),
              child: Text('完成', style: TextStyle(fontSize: 12.0)),
              onPressed: () {
                if (_currentContents != null) {
                  setState(() {
                    _currentContents[index]['裝配狀態'] = 'Y';
                  });
                }
              },
            ),
          ),
          //NG
          SizedBox(
            height: 22,
            width: MediaQuery.of(context).size.width / 100 * width2 / 2 - 1,
            child: RaisedButton(
              color: status == 'N' ? Colors.lightBlue : Colors.grey[200],
              textColor: status == 'N' ? Colors.white : Colors.black,
              padding: EdgeInsets.all(0),
              child: Text('等待', style: TextStyle(fontSize: 12.0)),
              onPressed: () {
                if (_currentContents != null) {
                  setState(() {
                    _currentContents[index]['裝配狀態'] = 'N';
                  });
                }
              },
            ),
          ),
        ]),
      ),
      Container(
        decoration: BoxDecoration(
          //color: Colors.grey[300],
          border:
              Border(top: BorderSide(width: 1), right: BorderSide(width: 1)),
        ),
        alignment: Alignment.center,
        width: MediaQuery.of(context).size.width / 100 * width3,
        height: 24,
        child: GestureDetector(
          onTap: () {
            showContentUserActionSheet(index);
          },
          child: Text(value3),
        ),
      ),
    ]);
  }
}

class KeyValueTri {
  String key;
  bool onPress = false;
}

// ignore: must_be_immutable
class FunctionMenu extends StatefulWidget {
  //==== ConnectMode
  // bool onlineMode;
  // final void Function(bool) onOnlineModeChange;

  //==== InputMode
  final int inputMode;
  final void Function(int) onInputModeChange;

  //==== BarcodeMode
  final int barcodeMode;
  final void Function(int) onBarcodeChange;
  //==== workMode
  final int workcodeMode;
  final void Function(int) onWorkcodeChange;

  //==== DataUpload
  // final void Function(ResultFlag, String) dataUpload;
  // List<String> offlineDataBuffer = List<String>();
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
    // @required this.onlineMode,
    // @required this.onOnlineModeChange,
    //InputMode
    @required this.inputMode,
    @required this.onInputModeChange,
    //BarcodeMode
    @required this.barcodeMode,
    @required this.onBarcodeChange,
    //workcodeMode
    @required this.workcodeMode,
    @required this.onWorkcodeChange,

    //==== DataUpload
    // @required this.dataUpload,
    // @required this.offlineDataBuffer,
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
  int _workcodeMode = 0;
  String _imageCategory = 'TVS0100020';
  bool _onlineMode = true; //在線模式
  String _vinNo = ''; //車身號碼
  List<Map<String, dynamic>> _vinList;

  bool _isLoading;
  List<String> _offlineDataBuffer = List<String>();
  List<Map<String, dynamic>> _xvms0033List;
  @override
  void initState() {
    super.initState();
    // _onlineMode = widget.onlineMode;
    _inputMode = widget.inputMode;
    _barcodeFixMode = widget.barcodeMode;
    _imageCategory = widget.imageCategory;
    _workcodeMode = widget.workcodeMode;
    _isLoading = widget.isLoading;
    // _offlineDataBuffer = widget.offlineDataBuffer;
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
            // buildConnectMode(Color(0xffe1e6ef), _onlineMode, (bool value) {
            //   widget.onOnlineModeChange(value);
            //   setState(() {
            //     _onlineMode = value;
            //   });
            // }),
            //==== InputMode
            buildInputMode(Colors.white, _inputMode, (int value) {
              widget.onInputModeChange(value);
              setState(() {
                _inputMode = value;
              });
            }),
            //==== BarcodeMode
            buildBarcodeMode(Color(0xffe1e6ef), _barcodeFixMode, (int value) {
              widget.onBarcodeChange(value);
              setState(() {
                _barcodeFixMode = value;
              });
            }),
            //==== workcodeMode
            buildWorkcodeMode(Colors.white, _workcodeMode, (int value) {
              widget.onWorkcodeChange(value);
              setState(() {
                _workcodeMode = value;
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
            //   if (_isLoading == true) return;
            //   ResultFlag _rf = ResultFlag.ok;
            //   String resultMs = '資料上傳成功';
            //   MessageBox.showQuestion(
            //       context,
            //       '共' + (_offlineDataBuffer.length).toString() + '筆資料',
            //       '確定上傳?', yesFunc: () async {
            //     setState(() {
            //       _isLoading = true;
            //     });
            //     Datagram datagram = Datagram();
            //     _offlineDataBuffer.forEach((s) {
            //       String workMode = s.split('|')[0];
            //       String vin = s.split('|')[1];
            //       String date = s.split('|')[2];
            //       String layer = s.split('|')[3];
            //       String grid = s.split('|')[4];
            //       String driver = s.split('|')[5];
            //       String vinNoVersion = s.split('|')[6];

            //       List<ParameterField> paramList = List<ParameterField>();
            //       paramList.add(ParameterField(
            //           'sSTATUS', ParamType.strings, ParamDirection.input,
            //           value: workMode.toString())); //狀態
            //       paramList.add(ParameterField(
            //           'sVSAA1100', ParamType.strings, ParamDirection.input,
            //           value: vin)); //車身號碼
            //       paramList.add(ParameterField(
            //           'sVSAA1107', ParamType.strings, ParamDirection.input,
            //           value: date)); //生產日期
            //       paramList.add(ParameterField(
            //           'sVSAA1114', ParamType.strings, ParamDirection.input,
            //           value: driver)); //移車人員
            //       paramList.add(ParameterField(
            //           'sVSAA1118', ParamType.strings, ParamDirection.input,
            //           value: layer)); //新儲區
            //       paramList.add(ParameterField(
            //           'sVSAA1119', ParamType.strings, ParamDirection.input,
            //           value: grid)); //新儲格
            //       paramList.add(ParameterField(
            //           'sVSAA1120', ParamType.strings, ParamDirection.input,
            //           value: vinNoVersion)); //版次
            //       paramList.add(ParameterField(
            //           'sUSERID', ParamType.strings, ParamDirection.input,
            //           value: driver));
            //       paramList.add(ParameterField('oRESULT_FLAG',
            //           ParamType.strings, ParamDirection.output));
            //       paramList.add(ParameterField(
            //           'oRESULT', ParamType.strings, ParamDirection.output));
            //       datagram.addProcedure('SPX_XVMS_AA11_LOCATION',
            //           parameters: paramList);
            //     });
            //     ResponseResult result =
            //         await Business.apiExecuteDatagram(datagram);
            //     if (result.flag == ResultFlag.ok) {
            //       _rf = ResultFlag.ok;
            //       resultMs = result.getNGMessage();
            //     } else {
            //       _rf = ResultFlag.ng;
            //       resultMs = result.getNGMessage();
            //     }
            //     //_showMessage(ResultFlag.ng, result.getNGMessage());

            //     setState(() {
            //       _isLoading = false;
            //     });
            //     widget.dataUpload(_rf, resultMs);
            //   });
            // }),
            // // //==== 作業圖庫
            // buildGalleryWithSeqNo(context, Colors.white, _imageCategory),
            // //==== 拍照
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
            Divider(height: 2.0, color: Colors.black),
          ],
        ),
      ),
    );
  }

  Widget buildWorkcodeMode(
      Color color, int workcodeMode, void Function(int) selectMode) {
    List<String> _workcodeModeList = ['撿車', '移車'];
    return Container(
      height: 50,
      color: color,
      child: ListTile(
          leading: Icon(Icons.apps),
          title: Text('作業模式: ${_workcodeModeList[workcodeMode]}'),
          onTap: () {
            if (workcodeMode == 0)
              workcodeMode = 1;
            else if (workcodeMode == 1) workcodeMode = 0;
            selectMode(workcodeMode);
          }),
    );
  }
}
