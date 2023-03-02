import 'dart:io';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:car_1/business/enums.dart';
import 'package:car_1/module/CameraBoxAdv.dart';
import 'package:car_1/module/GeneralFunction.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:car_1/business/datagram.dart';
import 'package:car_1/business/responseresult.dart';
import 'package:car_1/business/business.dart';
import 'package:car_1/apis/messagebox.dart';
import 'package:car_1/apis/imagebrowserlist.dart';
import 'package:car_1/business/classes.dart';
import 'CameraBox.dart';

Widget buildAutoUpMode(
    Color color, bool autoUpMode, void Function(bool) selectMode) {
  return Container(
    height: 50,
    color: color,
    child: ListTile(
        leading: Icon(Icons.apps),
        title: Text('上傳模式: ${autoUpMode == true ? '自動' : '手動'}'),
        onTap: () {
          autoUpMode = !autoUpMode;
          selectMode(autoUpMode);
        }),
  );
}

Widget buildConnectMode(
    Color color, bool onlineMode, void Function(bool) selectMode) {
  return Container(
    height: 50,
    color: color,
    child: ListTile(
        leading: Icon(Icons.apps),
        title: Text('連線模式: ${onlineMode == true ? '在線' : '離線'}'),
        onTap: () {
          onlineMode = !onlineMode;
          selectMode(onlineMode);
        }),
  );
}

Widget buildInputMode(
    Color color, int inputMode, void Function(int) selectMode) {
  List<String> _inputModeList = ['鍵盤', '掃描器', '照相機'];
  return Container(
    height: 50,
    color: color,
    child: ListTile(
        leading: Icon(Icons.apps),
        title: Text('輸入模式: ${_inputModeList[inputMode]}'),
        onTap: () {
          if (inputMode == 0) {
            inputMode = 1;
          } else if (inputMode == 1) {
            inputMode = 2;
          } else {
            inputMode = 0;
          }
          selectMode(inputMode);
        }),
  );
}

Widget buildBarcodeMode(
    Color color, int barcodeFixMode, void Function(int) selectMode) {
  List<String> _barcodeFixModeList = ['一般', '去頭', 'F/U'];
  return Container(
    height: 50,
    color: color,
    child: ListTile(
        leading: Icon(Icons.apps),
        title: Text('條碼模式: ${_barcodeFixModeList[barcodeFixMode]}'),
        onTap: () {
          if (barcodeFixMode == 0)
            barcodeFixMode = 1;
          else if (barcodeFixMode == 1)
            barcodeFixMode = 2;
          else
            barcodeFixMode = 0;
          selectMode(barcodeFixMode);
        }),
  );
}

Widget buildDataUpload(Color color, void Function() dataUpload) {
  return Container(
    height: 50,
    color: color,
    child: ListTile(
        leading: Icon(Icons.apps),
        title: Text('資料上傳'),
        onTap: () {
          dataUpload();
        }),
  );
}

Widget buildGallerybak(
    BuildContext context, Color color, String imageCategory) {
  return Container(
    height: 50,
    color: color,
    child: ListTile(
        leading: Icon(Icons.apps),
        title: Text('作業圖庫'),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => new ImageBrowserList(
                      FileSourceType.offline,
                      'compid/$imageCategory',
                      uploadProcess: (FileItem item, File f) async {
                        ResponseResult result = await Business.sendFile(
                            'compid/$imageCategory' + '/' + item.fileName, f,
                            userId: Business.userId,
                            deviceId: Business.deviceId,
                            ref1: path.basenameWithoutExtension(f.parent.path),
                            ref2: path.basenameWithoutExtension(
                                f.parent.parent.path));
                        if (result.flag == ResultFlag.ok) {
                          return true;
                        } else {
                          MessageBox.showError(
                              context, '', result.getNGMessage());
                          return false;
                        }
                      },
                    )),
          );
        }),
  );
}

Widget buildGallery(BuildContext context, Color color, String imageCategory) {
  return Container(
    height: 50,
    color: color,
    child: ListTile(
        leading: Icon(Icons.apps),
        title: Text('作業圖庫'),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => new ImageBrowserList(
                      FileSourceType.offline,
                      'compid/$imageCategory',
                      uploadProcess: (FileItem item, File f) async {
                        Map<String, String> headers = {
                          'ModuleId': imageCategory,
                          'SubPath':
                              '\\' + imageCategory + '\\' + item.fileName,
                          'ReceiptType': '',
                          'ReceiptSerial': '',
                          'ReceiptNo': '',
                          'Tag1': item.fileName,
                          'Tag2': '',
                          'Descryption': '',
                          'UploadUser': Business.userId,
                          'UploadDevice': '',
                        };
                        List<File> _files = [];
                        _files.add(f);

                        ResponseResult result = await Business.apiUploadFile(
                            FileCmdType.file, _files,
                            headers: headers);
                        if (result.flag == ResultFlag.ok) {
                          return true;
                        } else {
                          MessageBox.showError(
                              context, '', result.getNGMessage());
                          return false;
                        }

                        // ResponseResult result = await Business.sendFile(
                        //     'compid/$imageCategory' + '/' + item.fileName, f,
                        //     userId: Business.userId,
                        //     deviceId: Business.deviceId,
                        //     ref1: path.basenameWithoutExtension(f.parent.path),
                        //     ref2: path.basenameWithoutExtension(
                        //         f.parent.parent.path));
                        // if (result.flag == ResultFlag.ok) {
                        //   return true;
                        // } else {
                        //   MessageBox.showError(
                        //       context, '', result.getNGMessage());
                        //   return false;
                        // }
                      },
                    )),
          );
        }),
  );
}

Widget buildGalleryWithSeqNo(
    BuildContext context, Color color, String imageCategory) {
  return Container(
    height: 50,
    color: color,
    child: ListTile(
        leading: Icon(Icons.apps),
        title: Text('作業圖庫'),
        onTap: () {
          //Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => new ImageBrowserList(
                      FileSourceType.offline,
                      'compid/$imageCategory',
                      uploadProcess: (FileItem item, File f) async {
                        String tag2 = '';
                        //點交次數
                        Datagram datagram = Datagram();
                        datagram.addText(
                            """select max(isnull(vsaa0119,0)) as vsaa0119
                                        from xvms_aa01
                                        where vsaa0100 = '${item.fileName}' and
                                              vsaa0114 not in ('00','10','99')
                        """,
                            rowSize: 65535);
                        ResponseResult result2 =
                            await Business.apiExecuteDatagram(datagram);
                        if (result2.flag == ResultFlag.ok) {
                          List<Map<String, dynamic>> data = result2.getMap();
                          if (data.length > 0)
                            tag2 = data[0]['vsaa0119'].toString();
                        } else {}
                        Map<String, String> headers = {
                          'ModuleId': imageCategory,
                          'SubPath':
                              '\\' + imageCategory + '\\' + item.fileName,
                          'ReceiptType': '',
                          'ReceiptSerial': '',
                          'ReceiptNo': '',
                          'Tag1': item.fileName,
                          'Tag2': tag2,
                          'Descryption': '',
                          'UploadUser': Business.userId,
                          'UploadDevice': '',
                        };
                        List<File> _files = [];
                        _files.add(f);

                        ResponseResult result = await Business.apiUploadFile(
                            FileCmdType.file, _files,
                            headers: headers);
                        if (result.flag == ResultFlag.ok) {
                          return true;
                        } else {
                          MessageBox.showError(
                              context, '', result.getNGMessage());
                          return false;
                        }

                        // ResponseResult result = await Business.sendFile(
                        //     'compid/$imageCategory' + '/' + item.fileName, f,
                        //     userId: Business.userId,
                        //     deviceId: Business.deviceId,
                        //     ref1: path.basenameWithoutExtension(f.parent.path),
                        //     ref2: path.basenameWithoutExtension(
                        //         f.parent.parent.path));
                        // if (result.flag == ResultFlag.ok) {
                        //   return true;
                        // } else {
                        //   MessageBox.showError(
                        //       context, '', result.getNGMessage());
                        //   return false;
                        // }
                      },
                    )),
          );
        }),
  );
}

Widget buildPhotograph(
    BuildContext context,
    Color color,
    String inputValue,
    List<Map<String, dynamic>> vinList,
    String imageCategory,
    void Function(Map<String, dynamic> value) onPhotograph) {
  return Container(
    height: 50,
    color: color,
    child: ListTile(
      leading: Icon(Icons.apps),
      title: Text('拍照'),
      onTap: () async {
        Map<String, dynamic> map;
        map = await CommonMethod.checkCameraPermission();
        if (map['resultFlag'].toString() == 'ng') {
          onPhotograph(map);
          return;
        }
        if (inputValue == '' || vinList == null) {
          map = {
            'resultFlag': 'ng',
            'result': '請輸入或掃描車身號碼',
          };
          onPhotograph(map);
          return;
        }
        map = CommonMethod.checkVinList(inputValue, vinList);
        if (map['resultFlag'].toString() == 'ng') {
          onPhotograph(map);
          return;
        } else {
          // Navigator.push(
          //     context,
          //     MaterialPageRoute(
          //         builder: (context) => CameraBox('compid', imageCategory,
          //             map['result'].toString(), null)));
          //TODO: 2020/8/26 Hank Change
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => CameraBoxAdv('compid', imageCategory,
                      map['result'].toString(), null)));

          map = {
            'resultFlag': 'ok',
            'result': map['result'].toString(),
          };
          onPhotograph(map);
        }
      },
    ),
  );
}

Widget buildPhotographAdv(
    BuildContext context,
    Color color,
    String inputValue,
    List<Map<String, dynamic>> vinList,
    String imageCategory,
    void Function(Map<String, dynamic> value) onPhotograph) {
  return Container(
    height: 50,
    color: color,
    child: ListTile(
      leading: Icon(Icons.apps),
      title: Text('拍照'),
      onTap: () async {
        Map<String, dynamic> map;
        map = await CommonMethod.checkCameraPermission();
        if (map['resultFlag'].toString() == 'ng') {
          onPhotograph(map);
          return;
        }
        if (inputValue == '' || vinList == null) {
          map = {
            'resultFlag': 'ng',
            'result': '請輸入或掃描車身號碼',
          };
          onPhotograph(map);
          return;
        }
        map = CommonMethod.checkVinList(inputValue, vinList);
        if (map['resultFlag'].toString() == 'ng') {
          onPhotograph(map);
          return;
        } else {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => CameraBoxAdv('compid', imageCategory,
                      map['result'].toString(), null)));
          map = {
            'resultFlag': 'ok',
            'result': map['result'].toString(),
          };
          onPhotograph(map);
        }
      },
    ),
  );
}

Widget buildLabel(String title, String value,
    {double fontSize = 14.0,
    double labelWidth = 80.0,
    Color valueColor = Colors.blue}) {
  return Container(
    padding: EdgeInsets.only(left: 20.0),
    child: Row(
      children: <Widget>[
        Container(
          width: labelWidth,
          child: Text(
            title + ':',
            style: TextStyle(fontSize: fontSize),
          ),
        ),
        Text(
          value,
          textAlign: TextAlign.start,
          style: TextStyle(color: valueColor, fontSize: fontSize),
        ),
      ],
    ),
  );
}

Widget buildText(String value,
    {Color color = Colors.black, double fontSize = 14.0, double width = 60.0}) {
  return Container(
    width: width,
    child: Text(
      value,
      textAlign: TextAlign.start,
      style: TextStyle(color: color, fontSize: fontSize),
      overflow: TextOverflow.ellipsis,
      softWrap: false,
    ),
  );
}

Widget buildRichText(String labelText, String valueText,
    {Color labelColor = Colors.black,
    double labelfontSize = 14.0,
    double labelWidth = 80.0,
    Color valueColor = Colors.black,
    double valuefontSize = 14.0}) {
  return Container(
    alignment: Alignment.centerLeft,
    padding: EdgeInsets.only(left: 20.0),
    child: RichText(
      text: TextSpan(
        style: TextStyle(color: Colors.black, fontSize: 14.0),
        children: <TextSpan>[
          TextSpan(
              text: labelText,
              style: TextStyle(color: labelColor, fontSize: labelfontSize)),
          TextSpan(
              text: valueText,
              style: TextStyle(color: valueColor, fontSize: valuefontSize)),
        ],
      ),
      textAlign: TextAlign.start,
    ),
  );
}

Widget buildDropdownButton(
    String labelText,
    String keyText,
    Map<String, dynamic> keyValue,
    List<DropdownMenuItem<dynamic>> itemList,
    void Function(dynamic) onChanged) {
  return Container(
    padding: EdgeInsets.only(left: 20.0, right: 20.0, top: 10, bottom: 10),
    child: DropdownButtonFormField(
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(fontSize: 16.0),
        contentPadding: EdgeInsets.only(top: 0, bottom: 0),
        filled: false,
      ),
      items: itemList == null ? [] : itemList,
      value: keyValue[keyText],
      onChanged: (value) {
        onChanged(value);
      },
    ),
  );
}

Widget buildMessage(
    BuildContext context, ResultFlag resultFlag, String message) {
  return Container(
    width: Business.deviceWidth(context) + 50,
    height: 25,
    color: resultFlag == ResultFlag.ok ? Colors.green : Colors.red,
    child: Text(
      message,
      style: TextStyle(fontSize: 16.0),
    ),
  );
}

Widget buildTab(BuildContext context, TabController tabController,
    List<Widget> tabBar, List<Widget> tabBarView,
    {double tabBarViewHeight = 120.0}) {
  return Container(
    child: Column(
      children: <Widget>[
        PreferredSize(
          child: Container(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: TabBar(
              tabs: tabBar,
              controller: tabController,
            ),
          ),
          preferredSize: Size(30.0, MediaQuery.of(context).size.width),
        ),
        Container(
          height: tabBarViewHeight,
          child: TabBarView(
            children: tabBarView,
            controller: tabController,
          ),
        ),
      ],
    ),
  );
}

Widget buildDatetime(String labelText,
    {void Function(String) onChanged, String dateformat = 'yyyy-MM-dd'}) {
  DateFormat format = DateFormat(dateformat);
  return Container(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Container(
            padding: EdgeInsets.only(left: 20.0, right: 20.0, bottom: 5.0),
            child: DateTimeField(
              decoration: InputDecoration(labelText: labelText),
              format: format,
              onShowPicker: (context, currentValue) {
                return showDatePicker(
                    context: context,
                    firstDate: DateTime(1900),
                    initialDate: currentValue ?? DateTime.now(),
                    lastDate: DateTime(2100));
              },
              onChanged: (DateTime date) {
                String controlText = '';
                if (date != null) {
                  String formattedDate = format.format(date);
                  controlText = formattedDate;
                } else {
                  controlText = '';
                }
                onChanged(controlText);
              },
            ),
          ),
        ),
      ],
    ),
  );
}

DecorationImage buildBackgroundImage() {
  return DecorationImage(
    fit: BoxFit.cover,
    colorFilter: ColorFilter.mode(
      Colors.black.withOpacity(1),
      BlendMode.dstATop,
    ),
    image: AssetImage('assets/images/shop_index_background.jpg'),
  );
}
