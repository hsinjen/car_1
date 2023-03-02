import 'responseresult.dart';
import 'MessageCode.dart';

class Result {
  ResultFlag _flag = ResultFlag.ok;
  MessageCode _messageCode;
  String _message = '';
  Object _object;

  ResultFlag get flag => _flag;
  // set _setFlag(ResultFlag value) => _flag = value;

  MessageCode get messageCode => _messageCode;
  // set _setMessageCode(MessageCode value) => _messageCode = value;

  String get message => _message;
  // set _setMessage(String value) => _message = value;

  Object get object => _object;
  set setValue(Object value) => _object = value;

  Result(ResultFlag flag, MessageCode messageCode, String message,
      {Object object}) {
    _flag = flag;
    _messageCode = messageCode;
    _message = message;
    _object = object;
  }

  static Result createWithMessageCodeString(String messageCodeString,
      {List<String> messageList, Object object}) {
    MessageCode messageCode = SystemMessage.getMessageCode(messageCodeString);

    if (messageList == null) {
      Result r = Result(messageCode.flag, messageCode, messageCode.message,
          object: object);
      return r;
    } else {
      StringBuffer strBuffer = StringBuffer();

      for (String item in messageList) {
        strBuffer.write(item);
        strBuffer.write('|');
      }

      String message =
          messageCode.message.replaceAll('{0}', strBuffer.toString());

      Result r = Result(messageCode.flag, messageCode, message, object: object);
      return r;
    }
  }

  static Result createWithUserDefine(
      ResultFlag flag, String message, Object object) {
    Result r =
        Result(flag, SystemMessage.userDefine(), message, object: object);
    return r;
  }

  static Result createWithMessageCodeObject(
      MessageCode messageCode, String message, Object object) {
    Result r = Result(messageCode.flag, messageCode, message, object: object);
    return r;
  }

  static Result ok({Object object}) {
    return createWithMessageCodeString('000001',
        messageList: null, object: object);
  }

  static Result ng({Object object}) {
    return createWithMessageCodeString('000002',
        messageList: null, object: object);
  }

  static Result ngWithMessageCode(String messageCode, List<String> messageList,
      {Object object}) {
    return createWithMessageCodeString(messageCode,
        messageList: messageList, object: object);
  }

  static Result exception(String message) {
    return createWithMessageCodeObject(
        SystemMessage.exception(), message, null);
  }

  static Result userDefine(String message) {
    return createWithMessageCodeObject(
        SystemMessage.userDefine(), message, null);
  }
}
