import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 站點資訊
class Document {
  /// 作業序號
  final String workNo;

  /// 站點序號
  final String stationNo;

  /// 排程日期
  final String scheduleDate;

  /// 紀錄項次
  final String recordNo;

  /// 車身號碼
  final String vin;

  /// 點交次數
  final String vinNo;

  /// 檢查項目
  List<DocumentItem> _items = [];

  Document({
    this.workNo,
    this.stationNo,
    this.scheduleDate,
    this.recordNo,
    this.vin,
    this.vinNo,
  });

  /// 檢查項目
  List<DocumentItem> get items {
    return _items;
  }

  /// 檢查項目
  set setDocumentItemList(List<DocumentItem> value) {
    _items = value;
  }

  /// Json to Class
  // factory Document.fromJson(Map<String, dynamic> jsonMap) {
  //   Document document = Document(
  //     jsonMap['documentId'],
  //     jsonMap['documentName'],
  //     jsonMap['documentType'],
  //     jsonMap['historyKey'],
  //     jsonMap['historyId'],
  //   );
  //   document.setCreateUser = jsonMap['createUser'];
  //   document.setCreateUser = jsonMap['createTime'];
  //   document.setCreateUser = jsonMap['modifyUser'];
  //   document.setCreateUser = jsonMap['modifyTime'];
  //   var itemsBuffer = json.decode(jsonMap['items']) as List;
  //   List<DocumentItem> documentItems =
  //       itemsBuffer.map((docitem) => DocumentItem.fromJson(docitem)).toList();
  //   document._items = documentItems;
  //   return document;
  // }

  /// Class to Json
  // Map<String, dynamic> toJson() => {
  //       'documentId': documentId,
  //       'documentName': documentName,
  //       'documentType': documentType,
  //       'historyKey': historyKey,
  //       'historyId': historyId,
  //       'createUser': createUser,
  //       'createTime': createTime,
  //       'modifyUser': modifyUser,
  //       'modifyTime': modifyTime,
  //       'items': json.encode(items),
  //     };

  /// Class to Json
  Map<String, dynamic> toJson() => {
        'items': json.encode(items),
      };

  /// 取得Json字串
  String toJsonStr() {
    Map<String, dynamic> map = toJson();
    return json.encode(map);
  }

  String getItemsJson() {
    return json.encode(items);
  }
}

/// 檢查項目
class DocumentItem {
  /// 站點序號
  final String stationNo;

  /// 項目序號
  final String itemId;

  /// 項目名稱
  final String itemText;

  /// 項目狀態
  DocumentStatus _status;

  /// 項目旗標
  DocumentFlag _flag;

  /// 備註
  String _value;

  /// 員工帳號
  String _userId;

  /// 開始時間
  String _startTime;

  /// 結束時間
  String _endTime;

  /// 檢查項目
  DocumentItem({
    @required this.stationNo,
    @required this.itemId,
    @required this.itemText,
  }) {
    _status = DocumentStatus.standby;
    _flag = DocumentFlag.none;
    _value = '';
    _userId = '';
    _startTime = '';
    _endTime = '';
  }

  /// 項目狀態
  DocumentStatus get status {
    return _status;
  }

  /// 項目狀態
  set setStatus(DocumentStatus value) {
    _status = value == null ? '' : value;
  }

  /// 項目旗標
  DocumentFlag get flag {
    return _flag;
  }

  /// 項目旗標
  set setFlag(DocumentFlag value) {
    _flag = value == null ? '' : value;
  }

  /// 備註
  String get value {
    return _value;
  }

  /// 備註
  set setValue(String value) {
    _value = value == null ? '' : value;
  }

  /// 員工帳號
  String get userId {
    return _userId;
  }

  /// 員工帳號
  set setUserId(String value) {
    _userId = value == null ? '' : value;
  }

  /// 開始時間
  String get startTime {
    return _startTime;
  }

  /// 開始時間
  set setStartTime(String value) {
    _startTime = value == null ? '' : value;
  }

  /// 結束時間
  String get endTime {
    return _endTime;
  }

  /// 結束時間
  set setEndTime(String value) {
    _endTime = value == null ? '' : value;
  }

  /// Json to Class
  factory DocumentItem.fromJson(Map<String, dynamic> jsonstr) {
    DocumentItem item = DocumentItem(
      stationNo: jsonstr['stationNo'],
      itemId: jsonstr['itemId'],
      itemText: jsonstr['itemText'],
    );
    item.setStatus = DocumentStatus.values.firstWhere(
        (e) => e.toString() == 'DocumentStatus.' + jsonstr['status']);
    item.setFlag = DocumentFlag.values
        .firstWhere((e) => e.toString() == 'DocumentFlag.' + jsonstr['flag']);
    item.setValue = jsonstr['value'];
    item.setUserId = jsonstr['userId'];
    item.setStartTime = jsonstr['startTime'];
    item.setEndTime = jsonstr['endTime'];
    return item;
  }

  /// Class to Json
  Map<String, dynamic> toJson() {
    String _status = '';
    String _flag = '';
    if (status == DocumentStatus.standby)
      _status = '0';
    else if (status == DocumentStatus.execute)
      _status = '1';
    else if (status == DocumentStatus.complete)
      _status = '2';
    else
      _status = 'X';

    if (flag == DocumentFlag.ok)
      _flag = 'OK';
    else if (flag == DocumentFlag.ng)
      _flag = 'NG';
    else
      _flag = '';

    return {
      'itemId': itemId,
      'itemText': itemText,
      'status': _status,
      'flag': _flag,
      'value': value,
      'userId': userId,
      'startTime': startTime,
      'endTime': endTime,
    };
  }

  DocumentStatus getDocumentStatusTypeFromString(String status) {
    if (status == '0')
      return DocumentStatus.standby;
    else if (status == '1')
      return DocumentStatus.execute;
    else if (status == '2')
      return DocumentStatus.complete;
    else
      return DocumentStatus.invalid;
  }

  String getDocumentStatusTypeFromType(DocumentStatus status) {
    if (status == DocumentStatus.standby)
      return '0';
    else if (status == DocumentStatus.execute)
      return '1';
    else if (status == DocumentStatus.complete)
      return '2';
    else
      return 'X';
  }

  DocumentFlag getDocumentFlagFromString(String flag) {
    if (flag == 'OK')
      return DocumentFlag.ok;
    else if (flag == 'NG')
      return DocumentFlag.ng;
    else
      return DocumentFlag.none;
  }

  String getDocumentFlagFromType(DocumentFlag flag) {
    if (flag == DocumentFlag.ok)
      return 'OK';
    else if (flag == DocumentFlag.ng)
      return 'NG';
    else
      return '';
  }
}

enum DocumentStatus {
  /// 待命
  standby,

  /// 執行
  execute,

  /// 完成
  complete,

  /// 作廢
  invalid,
}

enum DocumentFlag {
  ok,
  ng,
  none,
}
