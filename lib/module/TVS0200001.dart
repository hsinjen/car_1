import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
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
import 'package:audioplayers/audio_cache.dart';

class TVS0200001 extends StatefulWidget {
  State<StatefulWidget> createState() {
    return _TVS0200001State();
  }
}

class _TVS0200001State extends State<TVS0200001> with TickerProviderStateMixin {
  final String moduleId = 'TVS0200001';
  final String moduleName = '車輛儲區作業';
  final GlobalKey<ScaffoldState> _this = new GlobalKey<ScaffoldState>();

  GlobalKey<KeyboardState> _keyboardSession;
  KeyboardAction _keyboardAction = KeyboardAction();
  ValueManager _values = ValueManager.create([
    KeyValue('BUFFER_VIN', ''),
    KeyValue('BUFFER_SCAN_VIN', ''),
    KeyValue('BUFFER_AREA', '00'),
    KeyValue('BUFFER_LOC', 'AA01'),
    KeyValue('BUFFER_DIRECTION', 'P'), //P:正向 R:逆向
    KeyValue('BUFFER_BARCODE_MODE', '0'), //0: 無 1:去頭 2: F/U
    KeyValue('BUFFER_MESSAGE', ''),
    KeyValue('BUFFER_MESSAGE_FLAG', 'OK'),
  ]);
  String _pageKey = 'pageMain';
  bool _isUploading = false;
  int _rowIndex = 0;
  List<Map<String, dynamic>> _dataBuffer;
  AudioPlayer fixedPlayer = new AudioPlayer();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    setPage('pageMain');
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
      //resizeToAvoidBottomPadding: false,
      //resizeToAvoidBottomInset: false,
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
      return '車輛儲區作業';
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
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: [
                  //======================================
                  labelTextBox('儲區', _values.getValue('BUFFER_AREA'),
                      emptyText: '儲區',
                      lableWidth: 45,
                      focus: _keyboardAction.actionName == 'BUFFER_AREA',
                      width: 100,
                      mainAxisAlignment: MainAxisAlignment.start,
                      margin: EdgeInsets.only(bottom: 5, top: 5), onClick: () {
                    setState(() {
                      _keyboardAction.showKeyboard('BUFFER_AREA',
                          defaultValue: _values.getValue('BUFFER_AREA'),
                          type: TextInputType.text);
                    });
                  }),
                  //======================================
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _values.setValue('BUFFER_DIRECTION', 'P');
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.only(left: 5),
                      decoration: BoxDecoration(
                        color: _values.getValue('BUFFER_DIRECTION') == 'P'
                            ? Colors.green
                            : Colors.white,
                        border: Border.all(width: 1, color: Colors.black),
                        borderRadius: BorderRadius.all(Radius.circular(4.0)),
                      ),
                      child: SizedBox(
                        height: 28,
                        width: 80,
                        child: Container(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            '正向',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                  //======================================
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _values.setValue('BUFFER_DIRECTION', 'R');
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.only(left: 5),
                      decoration: BoxDecoration(
                        color: _values.getValue('BUFFER_DIRECTION') == 'R'
                            ? Colors.green
                            : Colors.white,
                        border: Border.all(width: 1, color: Colors.black),
                        borderRadius: BorderRadius.all(Radius.circular(4.0)),
                      ),
                      child: SizedBox(
                        height: 28,
                        width: 80,
                        child: Container(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            '逆向',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              //================================================================
              Row(
                children: [
                  labelTextBox('儲條', _values.getValue('BUFFER_LOC'),
                      emptyText: '儲條',
                      lableWidth: 45,
                      focus: _keyboardAction.actionName == 'BUFFER_LOC',
                      width: 100,
                      mainAxisAlignment: MainAxisAlignment.start,
                      margin: EdgeInsets.only(bottom: 5, top: 5), onClick: () {
                    setState(() {
                      _keyboardAction.showKeyboard('BUFFER_LOC',
                          defaultValue: _values.getValue('BUFFER_LOC'),
                          type: TextInputType.text);
                    });
                  }),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        String originalLoc = _values.getValue('BUFFER_LOC');
                        if (originalLoc.length != 4) return;

                        int loc = int.tryParse(originalLoc.substring(2)) ?? -1;

                        if (loc == -1) return;

                        //正向
                        if (_values.getValue('BUFFER_DIRECTION') == 'P') {
                          if (loc < 99)
                            _values.setValue(
                                'BUFFER_LOC',
                                originalLoc.substring(0, 2) +
                                    (loc + 1).toString().padLeft(2, '0'));
                        }
                        //逆向
                        else {
                          if (loc > 1)
                            _values.setValue(
                                'BUFFER_LOC',
                                originalLoc.substring(0, 2) +
                                    (loc - 1).toString().padLeft(2, '0'));
                        }
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.only(left: 5),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        border: Border.all(width: 1, color: Colors.black),
                        borderRadius: BorderRadius.all(Radius.circular(4.0)),
                      ),
                      child: SizedBox(
                        height: 28,
                        width: 80,
                        child: Container(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            '跳過',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              //================================================================
              Row(
                children: [
                  SizedBox(
                    width: 50,
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_values.getValue('BUFFER_BARCODE_MODE') == '1')
                          _values.setValue('BUFFER_BARCODE_MODE', '0');
                        else
                          _values.setValue('BUFFER_BARCODE_MODE', '1');
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.only(left: 5),
                      decoration: BoxDecoration(
                        color: _values.getValue('BUFFER_BARCODE_MODE') == '1'
                            ? Colors.green
                            : Colors.white,
                        border: Border.all(width: 1, color: Colors.black),
                        borderRadius: BorderRadius.all(Radius.circular(4.0)),
                      ),
                      child: SizedBox(
                        height: 28,
                        width: 80,
                        child: Container(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            '去頭',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),

                  //====================================
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_values.getValue('BUFFER_BARCODE_MODE') == '2')
                          _values.setValue('BUFFER_BARCODE_MODE', '0');
                        else
                          _values.setValue('BUFFER_BARCODE_MODE', '2');
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.only(left: 5),
                      decoration: BoxDecoration(
                        color: _values.getValue('BUFFER_BARCODE_MODE') == '2'
                            ? Colors.green
                            : Colors.white,
                        border: Border.all(width: 1, color: Colors.black),
                        borderRadius: BorderRadius.all(Radius.circular(4.0)),
                      ),
                      child: SizedBox(
                        height: 28,
                        width: 80,
                        child: Container(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'F/U',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              //================================================================
              Row(
                children: [
                  labelTextBox('車身', _values.getValue('BUFFER_SCAN_VIN'),
                      emptyText: '掃描車身號碼',
                      lableWidth: 45,
                      focus: _keyboardAction.actionName == 'BUFFER_SCAN_VIN',
                      width: MediaQuery.of(context).size.width - 65,
                      mainAxisAlignment: MainAxisAlignment.start,
                      margin: EdgeInsets.only(bottom: 5, top: 5), onClick: () {
                    setState(() {
                      _keyboardAction.showScanner('BUFFER_SCAN_VIN');
                    });
                  }),
                ],
              ),
              //================================================================
              Container(
                child: Center(
                  child: Text(_values.getValue('BUFFER_VIN'),
                      style: TextStyle(color: Colors.blue, fontSize: 32)),
                ),
              ),
              //================================================================
              Container(
                child: Center(
                  child: Text(_values.getValue('BUFFER_MESSAGE'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: _values.getValue('BUFFER_MESSAGE_FLAG') == 'OK'
                              ? Colors.blue
                              : Colors.red,
                          fontSize: 29)),
                ),
              ),
            ],
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

  Future<List<Map<String, dynamic>>> _loadVin(String vin) async {
    Datagram datagram = Datagram();
    datagram.addText(
        """select tvsaf01 from [192.168.1.7,58586].db07.dbo.tvsaf_file where tvsaf01 like '%$vin'""");
    ResponseResult r = await Business.apiExecuteDatagram(datagram);
    return r.getMap();
  }

  //顯示多車身選擇
  void showVinActionSheet(List<Map<String, dynamic>> dataList) {
    if (dataList == null) return;
    List<Widget> _list = [];

    for (int i = 0; i < dataList.length; i++) {
      _list.add(CupertinoActionSheetAction(
        child: Text(dataList[i]['tvsaf01']),
        onPressed: () {
          keyboardValueChanged('ASSIGN_VIN', dataList[i]['tvsaf01']);
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

  //============================================================================ Event
  void keyboardValueChanged(String actionName, String value) async {
    print(
        'value changed: action: $actionName value: $value   ${DateTime.now()}');
    Map<String, String> barcodeResult;

    if (actionName == 'BUFFER_AREA') {
      if (value.length != 2) {
        playSound(ResultFlag.ng);

        setState(() {
          _values.setValue('BUFFER_MESSAGE', '儲區長度必須為 2');
        });

        return;
      }
    } else if (actionName == 'BUFFER_LOC') {
      if (value.length != 4) {
        playSound(ResultFlag.ng);
        setState(() {
          _values.setValue('BUFFER_MESSAGE', '儲條長度必須為 4');
        });
        return;
      } else if ((int.tryParse(value.substring(2)) ?? -1) == -1) {
        playSound(ResultFlag.ng);
        setState(() {
          _values.setValue('BUFFER_MESSAGE', '儲條後兩碼必須為數字');
        });
        return;
      }
    } else if (actionName == 'BUFFER_SCAN_VIN' || actionName == 'ASSIGN_VIN') {
      _values.setValue('BUFFER_MESSAGE', '');
      _values.setValue('BUFFER_MESSAGE_FLAG', 'OK');
      String area = _values.getValue('BUFFER_AREA');
      String loc = _values.getValue('BUFFER_LOC');
      String mode = _values.getValue('BUFFER_BARCODE_MODE'); //0: 無 1:去頭 2: F/U
      String direction = _values.getValue('BUFFER_DIRECTION'); //P:正向 R:逆向
      String vin = '';
      int iLoc = 0;

      if (area.length != 2) {
        playSound(ResultFlag.ng);
        setState(() {
          _values.setValue('BUFFER_MESSAGE_FLAG', 'NG');
          _values.setValue('BUFFER_MESSAGE', '儲區長度必須為 2');
        });
        return;
      }
      if (loc.length != 4) {
        playSound(ResultFlag.ng);
        setState(() {
          _values.setValue('BUFFER_MESSAGE_FLAG', 'NG');
          _values.setValue('BUFFER_MESSAGE', '儲條長度必須為 4');
        });
        return;
      } else if ((int.tryParse(loc.substring(2)) ?? -1) == -1) {
        playSound(ResultFlag.ng);
        setState(() {
          _values.setValue('BUFFER_MESSAGE_FLAG', 'NG');
          _values.setValue('BUFFER_MESSAGE', '儲條後兩碼必須為數字');
        });
        return;
      }
      iLoc = int.tryParse(loc.substring(2)) ?? 0;
      vin = CommonMethod.barcodeCheck(int.parse(mode), value);
      List<Map<String, dynamic>> vinList = await _loadVin(vin);
      if (vinList == null || vinList.length == 0) {
        playSound(ResultFlag.ng);
        setState(() {
          _values.setValue('BUFFER_MESSAGE_FLAG', 'NG');
          _values.setValue('BUFFER_MESSAGE', '不存在的車身號碼 $vin');
          _keyboardAction.showScanner('BUFFER_SCAN_VIN');
        });

        return;
      } else if (vinList.length > 1) {
        showVinActionSheet(vinList);
        return;
      } else {
        vin = vinList[0]['tvsaf01'].toString();
        _values.setValue('BUFFER_VIN', vin.toUpperCase());

        Datagram datagram =
            Datagram(transactionMode: TransactionMode.noTransaction);
        datagram.addProcedure('SPX_V2_UPDATE_LOCATION', parameters: [
          ParameterField('sTVSAF01', ParamType.strings, ParamDirection.input,
              value: vin),
          ParameterField('sTVSAF24', ParamType.strings, ParamDirection.input,
              value: area),
          ParameterField('sTVSAF25', ParamType.strings, ParamDirection.input,
              value: loc),
          ParameterField('sUSERID', ParamType.strings, ParamDirection.input,
              value: Business.userId),
          ParameterField(
              'oRESULT_FLAG', ParamType.strings, ParamDirection.output,
              value: '', size: 2),
          ParameterField('oRESULT', ParamType.strings, ParamDirection.output,
              value: '', size: 4000),
        ]);
        ResponseResult r = await Business.apiExecuteDatagram(datagram);
        String rMessage = r.items[0].message.toString();

        if (rMessage.startsWith('NG')) {
          playSound(ResultFlag.ng);
          _keyboardAction.showScanner('BUFFER_SCAN_VIN');
          setState(() {
            _values.setValue('BUFFER_MESSAGE_FLAG', 'NG');
            _values.setValue('BUFFER_MESSAGE', rMessage.split(':')[1]);
          });
          return;
        } else {
          if (direction == 'P') {
            if (iLoc >= 99) {
              playSound(ResultFlag.ng);
              _values.setValue('BUFFER_MESSAGE_FLAG', 'NG');
              _values.setValue('BUFFER_MESSAGE', '儲條位置已到盡頭，請切換儲區');
            }
            _values.setValue('BUFFER_LOC',
                loc.substring(0, 2) + (iLoc + 1).toString().padLeft(2, '0'));
          } else {
            if (iLoc <= 0) {
              playSound(ResultFlag.ng);
              _values.setValue('BUFFER_MESSAGE_FLAG', 'NG');
              _values.setValue('BUFFER_MESSAGE', '儲條位置已到盡頭，請切換儲區');
            }
            _values.setValue('BUFFER_LOC',
                loc.substring(0, 2) + (iLoc - 1).toString().padLeft(2, '0'));
          }
          playSound(ResultFlag.ok);
          _values.setValue(
              'BUFFER_MESSAGE', r.getMap()[0]['ORESULT'].split(':')[1]);
          _keyboardAction.showScanner('BUFFER_SCAN_VIN');
        }
      }
    }

    setState(() {
      _values.setValue(actionName, value.toUpperCase());
    });
  }

  void keyboardTextChanged(String actionName, String value) async {
    print('text changed: action: $actionName value: $value');

    // setState(() {
    //   _values.setValue(actionName, value.toUpperCase());
    // });
  }

  void keyboardNotify() {
    setState(() {
      _keyboardAction = _keyboardAction;
    });
  }

  Future<AudioPlayer> playSound(ResultFlag flag) {
    AudioCache _player =
        AudioCache(prefix: 'assets/sounds/', fixedPlayer: fixedPlayer);

    try {
      if (flag == ResultFlag.ok) {
        /*_audioPlayer = await */
        return _player.play('ok.mp3');
      } else {
        /*_audioPlayer = await */
        return _player.play('ng.mp3');
      }
    } catch (e) {
      print(e.toString());
    }
    return null;
  }
}
