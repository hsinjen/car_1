import 'package:flutter/material.dart';
import 'package:car_1/business/business.dart';
import 'package:car_1/business/datagram.dart';
import 'package:car_1/business/responseresult.dart';
import 'package:car_1/model/sysMenu.dart';
import 'package:flutter/services.dart';
import 'GeneralFunction.dart';
import 'GeneralWidget.dart';

class TVS0100015 extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _TVS0100015();
  }
}

class _TVS0100015 extends State<TVS0100015> {
  final String moduleId = 'TVS0100015';
  final String moduleName = '存車維護查詢';
  String _message = '';
  ResultFlag _messageFlag = ResultFlag.ok;
  bool _isLoading = false;
  //========================================================
  final Map<String, dynamic> _formData = {
    'carLabel': null,
    'maintain': null,
    'date_start': null,
    'date_end': null,
  };
  List<Map<String, dynamic>> _vinList;
  List<DropdownMenuItem> _carLabelItems;
  List<DropdownMenuItem> _maintainItems;
  int _carCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCarLabelData();
    _loadmaintainData();
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
      appBar: AppBar(
        title: Text(moduleName),
      ),
      body: Container(
        width: Business.deviceWidth(context),
        child: Column(
          children: <Widget>[
            Container(
              child: Form(
                child: Container(
                  child: Column(
                    children: <Widget>[
                      _buildInput1(),
                      _buildInput2(),
                      _buildInput3(),
                      _buildInput4(),
                    ],
                  ),
                ),
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

  Widget _buildInput1() {
    return Container(
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
              padding: EdgeInsets.only(left: 20.0, right: 20, top: 10),
              child: Text('台數:' + _carCount.toString()),
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(9.0),
              child: RaisedButton(
                child: Text('查詢'),
                onPressed: () {
                  _loadData();
                },
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(9.0),
              child: RaisedButton(
                child: Text('清除'),
                onPressed: () {
                  setState(() {
                    _formData['carLabel'] = null;
                    _formData['maintain'] = null;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput2() {
    return Container(
      child: Row(
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
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput3() {
    return Container(
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
              padding: EdgeInsets.only(left: 20.0, right: 20, top: 10),
              child: DropdownButtonFormField(
                decoration: InputDecoration(
                    labelText: '維護項目',
                    filled: false,
                    contentPadding: EdgeInsets.only(top: 0, bottom: 0)),
                items: _maintainItems,
                value: _formData['maintain'],
                onChanged: (value) {
                  setState(() {
                    _formData['maintain'] = value;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput4() {
    return Container(
      child: Row(
        children: <Widget>[
          Container(
            width: 170.0,
            child: buildDatetime('作業日期', onChanged: (String date) {
              setState(() {
                _formData['date_start'] = date;
              });
            }),
          ),
          Container(
            child: Text('~'),
          ),
          Container(
            width: 170.0,
            child: buildDatetime('作業日期', onChanged: (String date) {
              setState(() {
                _formData['date_end'] = date;
              });
            }),
          ),
        ],
      ),
    );
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
    return Card(
      child: Container(
        child: Column(
          children: <Widget>[
            Divider(height: 5),
            _buildCarInfoItem('車身號碼', data['車身號碼'] == null ? '' : data['車身號碼'],
                bold: true),
            _buildCarInfoItem('計畫日期', data['計畫日期'] == null ? '' : data['計畫日期']),
            _buildCarInfoItem(
                '維護項目', data['維護項目名稱'] == null ? '' : data['維護項目名稱']),
            _buildCarInfoItem('廠牌', data['廠牌代碼'] == null ? '' : data['廠牌代碼']),
            _buildCarInfoItem('車款', data['車款代碼'] == null ? '' : data['車款代碼']),
            _buildCarInfoItem('車色', data['車色'] == null ? '' : data['車色']),
            _buildCarInfoItem('儲區', data['儲區'] == null ? '' : data['儲區']),
            _buildCarInfoItem('儲格', data['儲格'] == null ? '' : data['儲格']),
            _buildCarInfoItem('到港日期', data['到港日期'] == null ? '' : data['到港日期']),
            _buildCarInfoItem(
                '存車天數', data['存車天數'] == null ? '' : data['存車天數'].toString()),
          ],
        ),
      ),
    );
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

  void _loadCarLabelData() async {
    List<DropdownMenuItem> items = List();
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
              width: Business.deviceWidth(context) - 80,
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

  void _loadmaintainData() async {
    List<DropdownMenuItem> items = List();
    Datagram datagram = Datagram();
    datagram.addText("""select vs001201,vs001202 from xvms_0012
        """, rowIndex: 0, rowSize: 65535);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);

    if (result.flag == ResultFlag.ng) {
    } else {
      List<Map<String, dynamic>> data = result.getMap();
      for (int i = 0; i < data.length; i++) {
        items.add(
          DropdownMenuItem(
            value: data[i]['vs001201'].toString(),
            child: Container(
              width: Business.deviceWidth(context) - 80,
              child: Text(
                data[i]['vs001202'].toString(),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      }
      setState(() {
        _maintainItems = items;
      });
    }
  }

  void _loadData() async {
    String vsab0902 =
        _formData['carLabel'] == null ? '' : _formData['carLabel'].toString();
    String vsab0908 =
        _formData['maintain'] == null ? '' : _formData['maintain'].toString();
    String date_start = _formData['date_start'] == null
        ? ''
        : _formData['date_start'].toString();
    String date_end =
        _formData['date_end'] == null ? '' : _formData['date_end'].toString();
    StringBuffer whereBuffer = StringBuffer();
    if (vsab0902 != '') whereBuffer.write("vsab0902 = '$vsab0902' and ");
    if (vsab0908 != '') whereBuffer.write("vsab0908 = '$vsab0908' and ");
    if (date_start != '' && date_end == '')
      whereBuffer.write("vsab0906 = '$date_start' and ");
    else if (date_start != '' && date_end != '')
      whereBuffer.write("vsab0906 between '$date_start' and '$date_end' and ");
    if (whereBuffer.length == 0) {
      _showMessage(ResultFlag.ng, '請至少選擇一個條件');
      return;
    }
    String _where = '';
    if (whereBuffer.length > 0) {
      _where = """where vsab0913 = 'N' and """ +
          whereBuffer.toString().substring(0, whereBuffer.length - 4);
    }

    setState(() {
      _isLoading = true;
    });

    Datagram datagram = Datagram();
    datagram.addText("""select vsab0911 as 車身號碼,
                               vsab0906 as 計畫日期,
                               vsab0909 as 維護項目名稱,
                               t2.vs000101 as 進口商代碼,
                               t3.vs000101 as 廠牌代碼,
                               t4.vs000101 as 車款代碼,
                               t5.vsaa0106 as 車色,
                               t5.vsaa0115 as 儲區,
                               t5.vsaa0116 as 儲格,
                               t5.vsaa0122 as 到港日期,
                               t5.vsaa0124 as 存車天數
                        from xvms_ab09 as t1
                        left join xvms_0001 as t2 on t1.vsab0901 = t2.vs000100 and t2.vs000106 = '1'
                        left join xvms_0001 as t3 on t1.vsab0902 = t3.vs000100 and t3.vs000106 = '2'
                        left join xvms_0001 as t4 on t1.vsab0903 = t4.vs000100 and t4.vs000106 = '3'
                        left join xvms_aa01 as t5 on t1.vsab0911 = t5.vsaa0100 and t1.vsab0912 = t5.vsaa0119
                        $_where
    """);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      _showMessage(ResultFlag.ok, '');
      List<Map<String, dynamic>> data = result.getMap();
      if (data.length > 0) {
        setState(() {
          _vinList = data;
          _carCount = data.length;
        });
      } else {
        setState(() {
          _vinList = null;
          _carCount = 0;
        });
      }
    } else {
      _showMessage(ResultFlag.ng, result.getNGMessage());
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _showMessage(ResultFlag flag, String message) {
    setState(() {
      _messageFlag = flag;
      _message = message;
    });
    CommonMethod.playSound(flag);
  }
}
