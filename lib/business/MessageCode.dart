import 'responseresult.dart';

class SystemMessage {
  static List<MessageCode> _mMessage = List<MessageCode>();

  static bool get initialized => _mMessage.length == 0 ? false : true;

  static bool initOSCutlture(String langCode) {
    switch (langCode) {
      case 'zh-tw':
      default:
        _initLanguageXml('zh-TW.lang');
    }
  }

  static MessageCode getMessageCode(String code) {
    if (_mMessage == null || _mMessage.length == 0)
      _initLanguageXml('zh-TW.lang');
    MessageCode messageCode =
        _mMessage.firstWhere((m) => m.code == code, orElse: () {
      return unknow();
    });
    return messageCode;
  }

  static String getMessageWithMessageCode(String code, List<String> args) {
    StringBuffer strBuffer = StringBuffer();
    if (_mMessage.where((m) => m.code == code).length == 0) {
      if (args.length == 0) {
        return _mMessage.firstWhere((m) => m.code == code).message;
      } else {
        for (String item in args) {
          strBuffer.write(item);
          strBuffer.write('|');
        }
        String message = _mMessage.firstWhere((m) => m.code == code).message;
        return message.replaceAll('{0}', strBuffer.toString());
      }
    } else
      return unknow().message;
  }

  static MessageCode unknow() {
    return MessageCode(
        ResultFlag.ng, '000000', '無法解析的訊息', '無法於訊息定義內取得訊息代碼', '');
  }

  static MessageCode exception() {
    return MessageCode(ResultFlag.ng, '00EEEE', '', 'flutter拋出的異常訊息', '');
  }

  static MessageCode userDefine() {
    return MessageCode(ResultFlag.ng, '00FFFF', '', '使用者自訂的訊息', '');
  }

  static bool _initLanguageXml(String filename) {
    if (filename == 'zh-TW.lang') {
      _mMessage.add(MessageCode(
          ResultFlag.ng, '000000', '無法解析的訊息', '無法於訊息定義內取得的資訊代碼', ''));
      _mMessage
          .add(MessageCode(ResultFlag.ok, '000001', '處理完成', '通用型處理完成訊息', ''));
      _mMessage
          .add(MessageCode(ResultFlag.ng, '000002', '處理失敗', '通用型處失敗成訊息', ''));
      _mMessage
          .add(MessageCode(ResultFlag.ng, '030001', '通訊位置 Url 格式異常', '', ''));
      _mMessage
          .add(MessageCode(ResultFlag.ng, '030002', '通訊異常，錯誤碼:{0}', '', ''));
      _mMessage.add(MessageCode(ResultFlag.ng, '030003', '通訊逾時', '', ''));
      _mMessage.add(MessageCode(ResultFlag.ng, '030004', '通訊異常', '', ''));
      _mMessage.add(MessageCode(ResultFlag.ng, '030005', '認證無效', '', ''));
      _mMessage.add(MessageCode(ResultFlag.ng, '030006', '無效的資料', '', ''));
      _mMessage.add(MessageCode(ResultFlag.ng, '030007', '通訊格式異常', '', ''));
      _mMessage.add(MessageCode(ResultFlag.ng, '030008', '獲取資源失敗', '', ''));
      _mMessage.add(MessageCode(ResultFlag.ng, '030009', '遺失參數', '', ''));
      _mMessage.add(MessageCode(ResultFlag.ng, '030010', '尚未支援', '', ''));
    }
    return true;
  }
}

class MessageCode {
  ResultFlag _flag;
  String _code;
  String _message;
  String _descript;
  String _category;

  ResultFlag get flag => _flag;
  String get code => _code;
  String get message => _message;
  String get descript => _descript;
  String get category => _category;

  MessageCode(ResultFlag flag, String code, String message, String descript,
      String category) {
    _flag = flag;
    _code = code;
    _message = message;
    _descript = descript;
    _category = category;
  }
}
