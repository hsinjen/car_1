import 'package:flutter/material.dart';
import 'package:car_1/apis/fullscreendialog.dart';
import 'package:car_1/business/business.dart';
import 'package:car_1/business/datagram.dart';
import 'package:car_1/business/responseresult.dart';

class CarSelect {
  static Future<String> showWithVin(BuildContext context, String vin) async {
    List<Map<String, dynamic>> _vinList = List();
    Datagram datagram = Datagram();
    // datagram.addText("""select vsaa0100 as 車身號碼,
    //                            isnull(t3.vs000101,'') as 廠牌,
    //                            isnull(t4.vs000101,'') as 車款

    //                     from xvms_aa01 as t1
    //                     left join xvms_0001 as t3 on t1.vsaa0102 = t3.vs000100 and t3.vs000106 = '2'
    //                     left join xvms_0001 as t4 on t1.vsaa0103 = t4.vs000100 and t4.vs000106 = '3'
    //                     where vsaa0100 like '%$vin%' and
    //                           vsaa0114 not in ('00','10','99')
    // """, rowSize: 9999);
    datagram.addText("""select vsaa0100 as 車身號碼,
                               isnull(t3.vs000101,'') as 廠牌,
                               isnull(t4.vs000101,'') as 車款
                               ,max(t1.VSAA0119) as 點交次數
                        from xvms_aa01 as t1
                        left join xvms_0001 as t3 on t1.vsaa0102 = t3.vs000100 and t3.vs000106 = '2'
                        left join xvms_0001 as t4 on t1.vsaa0103 = t4.vs000100 and t4.vs000106 = '3'
                        where vsaa0100 like '%$vin%' and
                              vsaa0114 not in ('00','10','99')
                              group by vsaa0100,t3.vs000101,t4.vs000101
    """, rowSize: 9999);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      _vinList = data;
    } else {
      _vinList = null;
    }
    if (_vinList == null || _vinList.length == 0) {
      return null;
    } else if (_vinList.length > 1) {
      return showDialog<String>(
          context: context,
          builder: (ctx) => FullScreenDialog(
                top: 100.0,
                left: 10.0,
                right: 10.0,
                bottom: 100.0,
                child: Container(
                  child: Column(
                    children: <Widget>[
                      _buildListView(context, _vinList),
                    ],
                  ),
                ),
              ));
    } else {
      return _vinList.first['車身號碼'].toString();
    }
  }

  static Future<String> showWithVinNCheck_AB13(
      BuildContext context, String vin) async {
    List<Map<String, dynamic>> _vinList = List();
    Datagram datagram = Datagram();
    datagram.addText("""select vsaa0100 as 車身號碼,
                               isnull(t3.vs000101,'') as 廠牌,
                               isnull(t4.vs000101,'') as 車款
                               ,iif(t5.VSAA1300 is not null ,'已檢查','未檢查') as 檢查狀態
                        from xvms_aa01 as t1
                        left join xvms_0001 as t3 on t1.vsaa0102 = t3.vs000100 and t3.vs000106 = '2'
                        left join xvms_0001 as t4 on t1.vsaa0103 = t4.vs000100 and t4.vs000106 = '3'
                        left join xvms_aa13 as t5 on t1.VSAA0100 = t5.VSAA1300 and t1.VSAA0119 = t5.VSAA1305
                        where vsaa0100 like '%$vin%' and
                              vsaa0114 not in ('00','10','99')
                              --and t5.VSAA1300 is null
    """, rowSize: 9999);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      _vinList = data;
    } else {
      _vinList = null;
    }
    if (_vinList == null || _vinList.length == 0) {
      return null;
    } else if (_vinList.length > 1) {
      return showDialog<String>(
          context: context,
          builder: (ctx) => FullScreenDialog(
                top: 100.0,
                left: 10.0,
                right: 10.0,
                bottom: 100.0,
                child: Container(
                  child: Column(
                    children: <Widget>[
                      _buildListView(context, _vinList),
                    ],
                  ),
                ),
              ));
    } else if (_vinList
        .where((v) => v['檢查狀態'].toString() == '已檢查')
        .isNotEmpty) {
      String vinDetail = _vinList.first['車身號碼'].toString() +
          '|' +
          _vinList.first['廠牌'].toString() +
          '|' +
          _vinList.first['車款'].toString() +
          '|已檢查';
      return vinDetail;
    } else {
      return _vinList.first['車身號碼'].toString();
    }
  }

  static Future<String> showWithList(
      BuildContext context, List<Map<String, dynamic>> list) async {
    return showDialog<String>(
        context: context,
        builder: (ctx) => FullScreenDialog(
              top: 100.0,
              left: 10.0,
              right: 10.0,
              bottom: 100.0,
              child: Container(
                child: Column(
                  children: <Widget>[
                    _buildListView(context, list),
                  ],
                ),
              ),
            ));
  }

  static Widget _buildListView(
      BuildContext context, List<Map<String, dynamic>> data) {
    return Expanded(
      child: Column(children: <Widget>[
        Divider(height: 10),
        Container(
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 0.5)),
            width: Business.deviceWidth(context) - 40,
            child: Row(
              children: <Widget>[
                // Container(
                //     padding: EdgeInsets.only(left: 0),
                //     width: 90,
                //     child: Text('廠牌'),
                //     color: Colors.grey),
                // Container(
                //     padding: EdgeInsets.only(left: 0),
                //     width: 90,
                //     child: Text('車款'),
                //     color: Colors.grey),
                Expanded(
                  child: Container(
                      padding: EdgeInsets.only(right: 0),
                      child: Text('車身號碼'),
                      color: Colors.grey),
                ),
              ],
            )),
        Expanded(
          child: _buildVinList(context, data),
        ),
      ]),
    );
  }

  static Widget _buildVinList(
      BuildContext context, List<Map<String, dynamic>> data) {
    if (data == null || data.length == 0)
      return Container(
        width: Business.deviceWidth(context) - 40,
        child: Column(
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey, width: 0.5)),
              child: Row(
                children: <Widget>[
                  Container(
                    color: Colors.white,
                    child: Text('沒有資料'),
                  ),
                ],
              ),
            ),
            RaisedButton(
              child: Text('返回'),
              onPressed: () {
                Navigator.of(context).pop(null);
              },
            ),
          ],
        ),
      );
    else {
      return Container(
        width: Business.deviceWidth(context) - 40,
        child: ListView.builder(
            itemCount: data == null ? 0 : data.length,
            itemBuilder: (BuildContext context, int index) {
              return _buildVinItem(context, data[index]);
            }),
      );
    }
  }

  static Widget _buildVinItem(BuildContext context, Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop(data['車身號碼'].toString());
      },
      child: Container(
        height: 30,
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey, width: 0.5)),
        child: Row(
          children: <Widget>[
            // Container(
            //   padding: EdgeInsets.only(left: 2),
            //   width: 90,
            //   child: Text(
            //     data['廠牌'] == null
            //         ? ''
            //         : (data['廠牌'].toString().length > 10
            //             ? '...' +
            //                 data['廠牌']
            //                     .toString()
            //                     .substring(data['廠牌'].toString().length - 10)
            //                     .trim()
            //             : data['廠牌'].toString()),
            //     style: TextStyle(fontSize: 12),
            //   ),
            //   // color: Colors.white,
            // ),
            // Container(
            //   width: 90,
            //   child: Text(
            //     data['車款'] == null
            //         ? ''
            //         : (data['車款'].toString().length > 10
            //             ? '...' +
            //                 data['車款']
            //                     .toString()
            //                     .substring(data['車款'].toString().length - 10)
            //                     .trim()
            //             : data['車款'].toString()),
            //     style: TextStyle(fontSize: 12),
            //   ),
            //   // color: Colors.white
            // ),
            Expanded(
              child: Container(
                child: Text(
                  data['車身號碼'] == null ? '' : data['車身號碼'].toString(),
                  style: TextStyle(fontSize: 21),
                ),
                // color: Colors.white
              ),
            ),
          ],
        ),
      ),
    );
  }
}
