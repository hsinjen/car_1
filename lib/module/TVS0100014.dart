import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:car_1/business/business.dart';
import 'package:car_1/business/datagram.dart';
import 'package:car_1/business/responseresult.dart';
import 'package:car_1/model/sysMenu.dart';
import 'package:intl/intl.dart';
import 'GeneralFunction.dart';
import 'GeneralWidget.dart';

class TVS0100014 extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _TVS0100014();
  }
}

class _TVS0100014 extends State<TVS0100014> with TickerProviderStateMixin {
  final String moduleId = 'TVS0100014';
  final String moduleName = '其他加油作業';
  String _message = '';
  ResultFlag _messageFlag = ResultFlag.ok;
  bool _isLoading = false;
  //========================================================
  TextEditingController _vsaa1504controller = TextEditingController();
  TextEditingController _vsaa1540controller = TextEditingController();
  TextEditingController _vsaa1541controller = TextEditingController();
  final Map<String, dynamic> _formData = {
    'oilItem': null, //加油項目
    'wareHouse': null, // 倉庫
  };
  List<DropdownMenuItem> _oilItems;
  List<DropdownMenuItem> _warehouseItems;
  List<Map<String, dynamic>> _oilItemList;
  String _vs004702 = ''; //油品種類

  @override
  void initState() {
    super.initState();
    _loadXVMS0047();
    _loadWareHouse();
    portraitUp();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //===== 標題
      appBar: AppBar(
        title: Text(moduleName),
      ),
      floatingActionButton: _buildFloatingAction(),
      body: Container(
        width: Business.deviceWidth(context),
        child: Column(
          children: <Widget>[
            //==== 加油項目
            buildDropdownButton('加油項目', 'oilItem', _formData, _oilItems,
                (dynamic value) {
              setState(() {
                _formData['oilItem'] = value;
                _vs004702 = _oilItemList
                    .firstWhere(
                        (v) => v['vs004700'].toString() == value)['vs004702']
                    .toString();
                _vsaa1541controller.text = _oilItemList
                    .firstWhere(
                        (v) => v['vs004700'].toString() == value)['vs004703']
                    .toString();
              });
            }),
            // 油品種類
            buildLabel('油品種類', _vs004702),
            // 車身號碼
            Container(
              padding:
                  EdgeInsets.only(left: 20.0, right: 20.0, top: 10, bottom: 10),
              child: TextField(
                controller: _vsaa1541controller,
                decoration: InputDecoration(
                    labelText: '車身號碼', labelStyle: TextStyle(fontSize: 14.0)),
                onChanged: (String value) {
                  setState(() {
                    _vsaa1541controller.text = value;
                  });
                  _vsaa1541controller.selection =
                      TextSelection.collapsed(offset: value.length);
                },
              ),
            ),
            // 倉庫
            buildDropdownButton('倉庫', 'wareHouse', _formData, _warehouseItems,
                (dynamic value) {
              setState(() {
                _formData['wareHouse'] = value;
              });
            }),
            // 加油公升數
            Container(
              padding:
                  EdgeInsets.only(left: 20.0, right: 20.0, top: 10, bottom: 10),
              child: TextField(
                controller: _vsaa1504controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: '加油公升數', labelStyle: TextStyle(fontSize: 14.0)),
                onChanged: (String value) {
                  setState(() {
                    _vsaa1504controller.text = value;
                  });
                  _vsaa1504controller.selection =
                      TextSelection.collapsed(offset: value.length);
                },
              ),
            ),
            // 備註
            Container(
              padding:
                  EdgeInsets.only(left: 20.0, right: 20.0, top: 10, bottom: 10),
              child: TextField(
                controller: _vsaa1540controller,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                    labelText: '備註', labelStyle: TextStyle(fontSize: 14.0)),
                onChanged: (String value) {
                  setState(() {
                    _vsaa1540controller.text = value;
                  });
                  _vsaa1540controller.selection =
                      TextSelection.collapsed(offset: value.length);
                },
              ),
            ),
            //================
            Expanded(
              child: Container(),
            ),
            //================
            _isLoading == false
                ? buildMessage(context, _messageFlag, _message)
                : Container(),
          ],
        ),
      ),
      drawer: buildMenu(context),
      resizeToAvoidBottomInset: false,
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

  Widget _buildFloatingAction() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        //新增
        Opacity(
          opacity: 0.8,
          child: Container(
            child: RawMaterialButton(
              onPressed: () async {
                _saveData();
              },
              child: Icon(
                Icons.add,
                color: Colors.white,
                size: 32.0,
              ),
              shape: CircleBorder(),
              elevation: 2.0,
              fillColor: Colors.blueGrey,
              padding: const EdgeInsets.all(15.0),
            ),
            padding: EdgeInsets.only(bottom: 40),
          ),
        ),
      ],
    );
  }

  void _loadXVMS0047() async {
    List<DropdownMenuItem> items = List<DropdownMenuItem>();
    Datagram datagram = Datagram();
    datagram.addText("""select vs004700,
                               vs004701,
                               t2.ixa00701 as vs004702,
                               vs004703
                        from xvms_0047 as t1
                        left join entirev4.dbo.ifx_a007 as t2 on t1.vs004702 = t2.ixa00700 and t2.ixa00703 = '油品種類'
        """, rowIndex: 0, rowSize: 100);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);

    if (result.flag == ResultFlag.ng) {
    } else {
      List<Map<String, dynamic>> data = result.getMap();
      for (int i = 0; i < data.length; i++) {
        items.add(
          DropdownMenuItem(
            value: data[i]['vs004700'].toString(),
            child: Container(
              width: Business.deviceWidth(context) - 100,
              child: Text(
                data[i]['vs004701'].toString(),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      }
      setState(() {
        _oilItemList = data;
        _oilItems = items;
      });
    }
  }

  void _loadWareHouse() async {
    List<DropdownMenuItem> items = List<DropdownMenuItem>();
    Datagram datagram = Datagram();
    datagram.addText(
        """select vs002100,vs002101 from xvms_0021 where vs002100 in ('T99')
        """,
        rowIndex: 0, rowSize: 100);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);

    if (result.flag == ResultFlag.ng) {
    } else {
      List<Map<String, dynamic>> data = result.getMap();
      for (int i = 0; i < data.length; i++) {
        items.add(
          DropdownMenuItem(
            value: data[i]['vs002100'].toString(),
            child: Container(
              width: Business.deviceWidth(context) - 100,
              child: Text(
                data[i]['vs002101'].toString(),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      }
      setState(() {
        _warehouseItems = items;
      });
    }
  }

  void _saveData() async {
    String vsaa1502 = _formData['oilItem'] == null
        ? ''
        : _formData['oilItem'].toString(); //加油項目
    String vsaa1503 = _formData['wareHouse'] == null
        ? ''
        : _formData['wareHouse'].toString(); //倉庫
    String vsaa1504 = _vsaa1504controller.text; //加油公升數
    String vsaa1540 = _vsaa1540controller.text; //備註
    String vsaa1541 = _vsaa1541controller.text; //車身號碼

    if (vsaa1502 == '') {
      _showMessage(ResultFlag.ng, '加油項目不可空白');
      return;
    }
    if (vsaa1503 == '') {
      _showMessage(ResultFlag.ng, '倉庫不可空白');
      return;
    }
    if (vsaa1504 == '') {
      _showMessage(ResultFlag.ng, '加油公升數不可空白');
      return;
    }
    if (vsaa1541 == '') {
      _showMessage(ResultFlag.ng, '車身號碼不可空白');
      return;
    }
    if (vsaa1541.length > 17) {
      _showMessage(ResultFlag.ng, '車身號碼長度不可超過17碼');
      return;
    }

    DateFormat dateFormat = DateFormat('yyyy-MM-dd');
    Map<String, dynamic> data = await _getSeqNumber('compid', 'VMS02',
        seqDate: dateFormat.format(DateTime.now()));
    String vsaa1500 = data['seqNO'].toString();
    String vsaa1501 = data['seqNumber'].toString();

    Datagram datagram = Datagram();
    datagram.addText("""if(1=1)
                        if exists (select 1 from xvms_aa01 where vsaa0100 = '$vsaa1541')
                            begin
                                raiserror('車身主檔有該車身號碼,不可加油',16,1);
                            end
                        insert into xvms_aa15 values
                        (
                          '0',
                          entirev4.dbo.systemdate(),
                          entirev4.dbo.systemtime(),
                          '${Business.userId}',
                          '${Business.deptId}',
                          '','','','','',
                          '$vsaa1500',
                          '$vsaa1501',
                          '$vsaa1502',
                          '$vsaa1503',
                          '$vsaa1504',
                          '${Business.userId}',
                          entirev4.dbo.systemdate(),
                          entirev4.dbo.systemtime(),
                          '$vsaa1540',
                          '$vsaa1541'
                        );
    """, rowIndex: 0, rowSize: 100);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      _showMessage(ResultFlag.ok, '加油完成');
      _formData['oilItem'] = null; //加油項目
      _vs004702 = ''; //油品種類
      _vsaa1541controller.text = ''; //車身號碼
      _formData['wareHouse'] = null; //倉庫
      _vsaa1504controller.text = ''; //加油公升數
      _vsaa1540controller.text = ''; //備註
    } else {
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

  Future<Map<String, dynamic>> _getSeqNumber(String ixa00100, String ixa00101,
      {String seqDate = ''}) async {
    Datagram datagram = Datagram();
    List<ParameterField> paramList = List<ParameterField>();
    paramList.add(ParameterField(
        'sIXA00100', ParamType.strings, ParamDirection.input,
        value: ixa00100));
    paramList.add(ParameterField(
        'sIXA00101', ParamType.strings, ParamDirection.input,
        value: ixa00101));
    paramList.add(ParameterField(
        'sSEQ_DATE', ParamType.strings, ParamDirection.input,
        value: ixa00101));
    paramList.add(
        ParameterField('oSEQ_NO', ParamType.strings, ParamDirection.output));
    paramList.add(
        ParameterField('oSEQ_DATE', ParamType.strings, ParamDirection.output));
    paramList.add(ParameterField(
        'oSEQ_NUMBER', ParamType.strings, ParamDirection.output));
    paramList.add(ParameterField(
        'oRESULT_FLAG', ParamType.strings, ParamDirection.output));
    paramList.add(
        ParameterField('oRESULT', ParamType.strings, ParamDirection.output));
    datagram.addProcedure('entirev4.dbo.sys_get_sequence',
        parameters: paramList);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      return {
        'seqNO': data.first['OSEQ_NO'].toString(),
        'seqDate': data.first['OSEQ_DATE'].toString(),
        'seqNumber': data.first['OSEQ_NUMBER'].toString()
      };
    } else {
      _showMessage(ResultFlag.ng, result.getNGMessage());
      return null;
    }
  }
}
