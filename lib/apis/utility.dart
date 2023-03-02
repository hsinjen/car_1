//import 'dart:async';
//import 'dart:io';
import 'dart:convert';
//import 'package:convert/convert.dart';
//import 'package:path/path.dart' as path;

class Utility {
  static List<int> encodeInt(int value, int length) =>
      ascii.encode(value.toString().padLeft(length, '0'));
  static int decodeInt(List<int> bytes) => int.parse(ascii.decode(bytes));

  static List<int> encodeUtf8(String text, {int padLeftLength = 0}) =>
      padLeftLength == 0
          ? utf8.encode(text)
          : utf8.encode(text.padLeft(padLeftLength));
  static String decodeUtf8(List<int> bytes) => utf8.decode(bytes).trim();

  static List<int> encodeAscii(String text, {int padLeftLength = 0}) =>
      padLeftLength == 0
          ? ascii.encode(text)
          : ascii.encode(text.padLeft(padLeftLength));
  static String decodeAscii(List<int> bytes) => ascii.decode(bytes).trim();

  static List<int> encodeBase64(List<int> bytes) => ascii.encode(base64Encode(bytes));
  static List<int> decodeBase64(List<int> bytes) => base64Decode(ascii.decode(bytes));
}
