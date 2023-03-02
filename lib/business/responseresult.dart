//library engineu;
import 'dart:convert';
//part of engineu;

//============================= ResponseResult
class ResponseResult {
//member
  List<ResponseResultItem> _items = [];
  ResultFlag _flag = ResultFlag.ok;

//Constructor
  ResponseResult({Map<String, dynamic> map, ResponseResultItem item}) {
    if (map != null) {
      setflag = ResultFlag.values.firstWhere((e) =>
          e.toString() == 'ResultFlag.' + map['flag'].toString().toLowerCase());
      if (map['count'].toString() != "0") {
        for (int i = int.parse(map['count'].toString()) - 1; i >= 0; i--) {
          Map<String, dynamic> _itemBuffer = map['items'][i];

          if (_itemBuffer['type'].toString().toLowerCase() == 'datatable' ||
              _itemBuffer['type'].toString().toLowerCase() == 'map') {
            List<dynamic> _dataBuffer = _itemBuffer['data'];
            List<Map<String, dynamic>> _dataBufferList = _dataBuffer
                .cast<Map<String, dynamic>>()
                //.map((v) => v.cast<String, dynamic>())
                .toList();
            if (_dataBufferList.length > 0) _dataBufferList.removeAt(0);

            _items.add(ResponseResultItem(
                batchId: int.parse(_itemBuffer['batchId'].toString()),
                syncId: int.parse(_itemBuffer['syncId'].toString()),
                flag: ResultFlag.values.firstWhere((e) =>
                    e.toString() ==
                    'ResultFlag.' +
                        _itemBuffer['flag'].toString().toLowerCase()),
                messageCode: _itemBuffer["messageCode"].toString(),
                message: _itemBuffer['message'].toString(),
                type: ResultType.values.firstWhere((e) =>
                    e.toString() ==
                    'ResultType.' +
                        _itemBuffer['type'].toString().toLowerCase()),
                data: _dataBufferList));
          } else {
            _items.add(ResponseResultItem(
                batchId: int.parse(_itemBuffer['batchId'].toString()),
                syncId: int.parse(_itemBuffer['syncId'].toString()),
                flag: ResultFlag.values.firstWhere((e) =>
                    e.toString() ==
                    'ResultFlag.' +
                        _itemBuffer['flag'].toString().toLowerCase()),
                messageCode: _itemBuffer["messageCode"].toString(),
                message: _itemBuffer['message'].toString(),
                type: ResultType.values.firstWhere((e) =>
                    e.toString() ==
                    'ResultType.' +
                        _itemBuffer['type'].toString().toLowerCase()),
                data: _itemBuffer['data'].toString()));
          }
        }
      }
    } else if (item != null) {
      _items.add(item);
      if (item.flag == ResultFlag.ng) _flag = ResultFlag.ng;
    }
  }

//Property
  ResultFlag get flag {
    return _flag;
  }

  set setflag(ResultFlag value) => _flag = value;

  int get count {
    return _items.length;
  }

  int get countOfString {
    return _items.where((v) => v.type == ResultType.strings).length;
  }

  int get countOfMap {
    return _items.where((v) => v.type == ResultType.map).length;
  }

  bool get hasErrorItem {
    return _items.where((v) => v.flag == ResultFlag.ng).length > 0;
  }

  List<ResponseResultItem> get items {
    return _items;
  }

//===== Public Method
  String getOKMessage() {
    if (_items
            .where(
                (v) => v.flag == ResultFlag.ok && v.type == ResultType.strings)
            .length >
        0) {
      return _items
          .firstWhere(
              (v) => v.flag == ResultFlag.ok && v.type == ResultType.strings)
          .message;
    } else
      return null;
  }

  String getNGMessage() {
    if (_items
            .where(
                (v) => v.flag == ResultFlag.ng && v.type == ResultType.strings)
            .length >
        0) {
      return _items
          .firstWhere(
              (v) => v.flag == ResultFlag.ng && v.type == ResultType.strings)
          .message;
    } else
      return null;
  }

  Object getData() {
    if (_items.length == 0)
      return null;
    else
      return _items[0];
  }

  Object getDataOfIndex(int index) {
    if (index < 0 || index > this.count - 1)
      return null;
    else
      return _items[index];
  }

  String getString() {
    if (_items.where((v) => v.type == ResultType.strings).length > 0) {
      return _items.firstWhere((v) => v.type == ResultType.strings).getString();
    } else
      return null;
  }

  String getStringOfIndex(int index) {
    if (index < 0 || index > this.count - 1)
      return null;
    else
      return _items[index].getString();
  }

  List<Map<String, dynamic>> getMap() {
    if (_items
            .where((v) =>
                v.type == ResultType.map || v.type == ResultType.datatable)
            .length >
        0) {
      return _items
          .firstWhere(
              (v) => v.type == ResultType.map || v.type == ResultType.datatable)
          .getMap();
    } else
      return null;
  }

  List<Map<String, dynamic>> getMapOfIndex(int index) {
    if (index < 0 || index > this.count - 1)
      return null;
    else
      return _items[index].getMap();
  }

//===== Serialize ~ Deserialize
  factory ResponseResult.fromJson(Map<String, dynamic> jsonMap) {
    try {
      return ResponseResult(map: jsonMap);
    } catch (_) {
      return ResponseResult(
          item: ResponseResultItem(
              batchId: 0,
              syncId: 0,
              type: ResultType.strings,
              flag: ResultFlag.ng,
              message: "無法解析的訊息",
              messageCode: "000000",
              data: "無法解析的訊息"));
    }
  }
  factory ResponseResult.fromJsonStr(String jsonStr) {
    return ResponseResult.fromJson(json.decode(jsonStr));
  }
}

//============================= ResponseResultItem
class ResponseResultItem {
  final int batchId;
  final int syncId;
  final ResultFlag flag;
  final String messageCode;
  final String message;
  final ResultType type;
  final Object data;

  ResponseResultItem(
      {this.batchId = 0,
      this.syncId = 0,
      this.flag,
      this.messageCode,
      this.message,
      this.type,
      this.data});

  T getData<T>() {
    if (data == null) return null;
    return data as T;
  }

  String getString() {
    if (type == ResultType.strings) {
      return getData<String>();
    } else
      return '';
  }

  List<Map<String, dynamic>> getMap() {
    if (type == ResultType.map || type == ResultType.datatable) {
      return getData<List<Map<String, dynamic>>>();
    } else
      return null;
  }
}

//============================= ResponseResultItem
enum ResultFlag {
  none,
  ok,
  ng,
}
enum ResultType {
  none,
  strings,
  datatable,
  map,
}
