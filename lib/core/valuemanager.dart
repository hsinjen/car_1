import 'keyvalue.dart';

class ValueManager {
  List<KeyValue> _items = [];

  ValueManager.create(List<KeyValue> items) {
    this._items = items;
  }

  bool exists(String key) {
    return _items.where((element) => element.key == key).length > 0;
  }

  bool isEmpty(String key) {
    if (exists(key) == true)
      return _items.firstWhere((element) => element.key == key).value == '';
    else
      return false;
  }

  bool isEmptys() {
    return _items.where((element) => element.value == '').length > 0;
  }

  void addValue(String key, String value) {
    if (exists(key) == false) _items.add(KeyValue(key, value));
  }

  String getValue(String key) {
    if (exists(key) == true)
      return _items.firstWhere((element) => element.key == key).value;
    else
      return '';
  }

  void setValue(String key, String value) {
    if (exists(key) == true)
      _items.firstWhere((element) => element.key == key).value = value;
  }

  void clearValue(String key) {
    if (exists(key) == true)
      _items.firstWhere((element) => element.key == key).value = '';
  }

  void clearItems() => _items.clear();
  void clearValues() => _items.forEach((element) {
        element.value = '';
      });
}
