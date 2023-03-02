import 'package:flutter/material.dart';
import 'package:car_1/apis/fullscreendialog.dart';
import 'package:car_1/business/datagram.dart';
import 'package:car_1/business/responseresult.dart';
import 'package:car_1/business/business.dart';

class CarInformation {
  static void show(BuildContext context, String vin) async {
    Datagram datagram = Datagram();
    datagram.addText("""select t1.vsaa0100 as 車身號碼,
                               t1.vsaa0101 as 引擎號碼,
                               t2.vs000101 as 廠牌,
                               t3.vs000101 as 車款,
                               t4.vs000101 as 車型,
                               t1.vsaa0106 as 車色,
                               t1.vsaa0115 as 儲位,
                               t1.vsaa0116 as 儲格,
                               t1.vsaa0122 as 到港日,
                               isnull(t5.vsaa0607,'') as 出車日,
                               '' as 排程日,
                               isnull(t5.vsaa0609,'') as 交車日,
                               isnull(t6.油品種類,'') as 油品種類,
                               isnull(t6.加油公升,0) as 加油公升,
                               isnull(t6.加油來源,'') as 加油來源,
                               iif(t6.車身號碼 is null,'已完成','未完成') as 加油狀態
                        from xvms_aa01 as t1 left join xvms_0001 as t2 on t1.vsaa0102 = t2.vs000100 and t2.vs000106 = '2'
                                             left join xvms_0001 as t3 on t1.vsaa0103 = t3.vs000100 and t3.vs000106 = '3'
                                             left join xvms_0001 as t4 on t1.vsaa0104 = t4.vs000100 and t4.vs000106 = '4'
                                             left join xvms_aa06 as t5 on t1.vsaa0100 = t5.vsaa0600 and t1.vsaa0119 = t5.vsaa0605
                                             left join (
                                                         select x1.vsaa1400 as 車身號碼,
                                                                x2.ixa00701 as 油品種類,
                                                                x1.vsaa1412 as 加油公升,
                                                                x3.ixa00701 as 加油來源
                                                         from xvms_aa14 as x1 left join entirev4.dbo.ifx_a007 as x2 on x1.vsaa1410 = x2.ixa00700 and x2.ixa00703='油品種類'
                                                                              left join entirev4.dbo.ifx_a007 as x3 on x1.vsaa1427 = x3.ixa00700 and x3.ixa00703='加油來源'
                                                         where vsaa1416 = 'N'
                                                       ) as t6 on t1.vsaa0100 = t6.車身號碼
                        where vsaa0100 like '%$vin%'""",
        rowIndex: 0, rowSize: 100);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);

    if (result.flag == ResultFlag.ng) {
    } else {
      List<Map<String, dynamic>> data = result.getMap();
      if (data.length == 0) {
      } else {
        showDialog(
          context: context,
          builder: (ctx) => new FullScreenDialog(
            top: 100.0,
            left: 10.0,
            right: 10.0,
            bottom: 100.0,
            //height:50,
            //width:200,
            child: Container(
                color: Colors.white,
                child: Column(
                  children: <Widget>[
                    Container(
                        padding: EdgeInsets.only(top: 2, bottom: 2),
                        width: MediaQuery.of(context).size.width - 20.0,
                        color: Colors.blueGrey,
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.only(left: 35),
                                child: Text(
                                  '車籍資料',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                                icon: Icon(
                                  Icons.exit_to_app,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                }),
                          ],
                        )),
                    SizedBox(height: 5),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Container(
                          margin: EdgeInsets.all(0.0),
                          color: Colors.white,
                          child: Column(
                            children: <Widget>[
                              _buildCarInfoItem(
                                  '車身號碼',
                                  data[0]['車身號碼'] == null
                                      ? ''
                                      : data[0]['車身號碼'],
                                  bold: true),
                              _buildCarInfoItem(
                                  '引擎號碼',
                                  data[0]['引擎號碼'] == null
                                      ? ''
                                      : data[0]['引擎號碼']),
                              _buildCarInfoItem('廠牌',
                                  data[0]['廠牌'] == null ? '' : data[0]['廠牌']),
                              _buildCarInfoItem('車款',
                                  data[0]['車款'] == null ? '' : data[0]['車款']),
                              _buildCarInfoItem('車型',
                                  data[0]['車型'] == null ? '' : data[0]['車型']),
                              _buildCarInfoItem('車色',
                                  data[0]['車色'] == null ? '' : data[0]['車色']),
                              _buildCarInfoItem('儲位',
                                  data[0]['儲位'] == null ? '' : data[0]['儲位']),
                              _buildCarInfoItem('儲格',
                                  data[0]['儲格'] == null ? '' : data[0]['儲格']),
                              _buildCarInfoItem('到港日',
                                  data[0]['到港日'] == null ? '' : data[0]['到港日']),
                              _buildCarInfoItem('出車日',
                                  data[0]['出車日'] == null ? '' : data[0]['出車日']),
                              _buildCarInfoItem('排程日',
                                  data[0]['排程日'] == null ? '' : data[0]['排程日']),
                              _buildCarInfoItem('交車日',
                                  data[0]['交車日'] == null ? '' : data[0]['交車日']),
                              _buildCarInfoItem(
                                  '油品種類',
                                  data[0]['油品種類'] == null
                                      ? ''
                                      : data[0]['油品種類']),
                              _buildCarInfoItem(
                                  '加油公升',
                                  data[0]['加油公升'] == null
                                      ? '0'
                                      : data[0]['加油公升'].toString()),
                              _buildCarInfoItem(
                                  '加油來源',
                                  data[0]['加油來源'] == null
                                      ? ''
                                      : data[0]['加油來源']),
                              _buildCarInfoItem(
                                  '加油狀態',
                                  (data[0]['加油狀態'] == null
                                      ? ''
                                      : data[0]['加油狀態']),
                                  foreColor: (data[0]['加油狀態'] == null
                                              ? ''
                                              : data[0]['加油狀態']) ==
                                          '未完成'
                                      ? Colors.white
                                      : Colors.black,
                                  backColor: (data[0]['加油狀態'] == null
                                              ? ''
                                              : data[0]['加油狀態']) ==
                                          '未完成'
                                      ? Colors.red
                                      : Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                )),
          ),
        );
      }
    }
  }

  static Widget _buildCarInfoItem(String labelText, String value,
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
}
