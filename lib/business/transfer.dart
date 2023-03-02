//library engineu;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:connectivity/connectivity.dart';
import 'MessageCode.dart';
import 'datagram.dart';
import 'business.dart';
import 'responseresult.dart';
import 'enums.dart';

class Transfer {
  bool _sqlLiteInitialized = false;
  String _sqlLiteVersion;
  String _sqlLiteFilename;
  int _file_max_size = 1024 * 1024 * 100;

  String get sqlLiteVersion {
    return _sqlLiteVersion;
  }

  void _fromDioError(DioError e) {
    if (e.type == DioErrorType.CANCEL) {
      debugPrint('請求取消');
    } else if (e.type == DioErrorType.CONNECT_TIMEOUT) {
      debugPrint('連線超時');
    } else if (e.type == DioErrorType.RECEIVE_TIMEOUT) {
      debugPrint('接收超時');
    } else if (e.type == DioErrorType.RESPONSE) {
      debugPrint('出現異常');
    } else if (e.type == DioErrorType.SEND_TIMEOUT) {
      debugPrint('請求超時');
    } else {
      debugPrint(e.message);
    }
  }

  ResponseResult _checkFileSize(List<File> fileList) {
    int sizes = 0;
    fileList.forEach((File f) {
      sizes += f.lengthSync();
    });
    if (sizes < _file_max_size) {
      return ResponseResult(
          item: ResponseResultItem(
              batchId: 0,
              syncId: 0,
              type: ResultType.strings,
              flag: ResultFlag.ok,
              message: '處理完成',
              messageCode: '000001',
              data: '處理完成'));
    } else {
      return ResponseResult(
          item: ResponseResultItem(
              batchId: 0,
              syncId: 0,
              type: ResultType.strings,
              flag: ResultFlag.ng,
              message: '檔案大小不可超過100M',
              messageCode: '000002',
              data: '檔案大小不可超過100M'));
    }
  }

  ResponseResult _getResponseResult(String code, {List<String> messageList}) {
    MessageCode messageCode = SystemMessage.getMessageCode(code);
    if (messageCode.flag == ResultFlag.ok) {
      return ResponseResult(
          item: ResponseResultItem(
              batchId: 0,
              syncId: 0,
              type: ResultType.strings,
              flag: messageCode.flag,
              message: messageCode.message,
              messageCode: messageCode.code,
              data: messageCode.message));
    } else {
      StringBuffer strBuffer = StringBuffer();
      String message = '';

      if (messageList.length > 0) {
        messageList.forEach((String str) {
          strBuffer.write(str);
          strBuffer.write('|');
        });
        message = messageCode.message.replaceAll('{0}',
            strBuffer.toString().substring(0, strBuffer.toString().length - 1));
      } else {
        message = messageCode.message;
      }

      return ResponseResult(
          item: ResponseResultItem(
              batchId: 0,
              syncId: 0,
              type: ResultType.strings,
              flag: messageCode.flag,
              message: message,
              messageCode: messageCode.code,
              data: message));
    }
  }

  Future<ResponseResult> send(Datagram datagram) async {
    try {
      // var connectivityResult = await (Connectivity().checkConnectivity());
      // if (connectivityResult == ConnectivityResult.mobile) {
      //   // I am connected to a mobile network.
      // } else if (connectivityResult == ConnectivityResult.wifi) {
      //   // I am connected to a wifi network.
      // } else {
      //   return ResponseResult(
      //       item: ResponseResultItem(
      //           batchId: 0,
      //           syncId: 0,
      //           type: ResultType.strings,
      //           flag: ResultFlag.ng,
      //           message: '未啟用網路連線',
      //           messageCode: "000002",
      //           data: '未啟用網路連線'));
      // }
      bool heartbeat = await checkHeartbeat();
      if (heartbeat == false) {
        return ResponseResult(
            item: ResponseResultItem(
                batchId: 0,
                syncId: 0,
                type: ResultType.strings,
                flag: ResultFlag.ng,
                message: '無法連接伺服器',
                messageCode: "000002",
                data: '無法連接伺服器'));
      }

      var dio = Dio();
      Response response = await dio.post(
        '${Business.remoteUrl}/datagram/method=send',
        data: datagram.toJsonStr(),
        options: Options(
            headers: Business.appTokenMap,
            sendTimeout: 10000,
            receiveTimeout: Business.httpConnectionTimeout * 1000),
      );
      //.timeout(Duration(seconds: Business.httpConnectionTimeout));

      // final http.Response response = await http.post(
      //     '${Business.remoteUrl}/datagram/method=send',
      //     body: datagram.toJsonStr(),
      //     headers: Business.appTokenMap);

      if (response.statusCode != 200 && response.statusCode != 201) {
        return ResponseResult(
            item: ResponseResultItem(
                batchId: 0,
                syncId: 0,
                type: ResultType.strings,
                flag: ResultFlag.ng,
                message: "網路通訊失敗",
                messageCode: "024008",
                data: "網路通訊失敗"));
      } else {
        return ResponseResult.fromJson(response.data);
        //return ResponseResult.fromJsonStr(response.body);
      }
    } catch (ex) {
      return ResponseResult(
          item: ResponseResultItem(
              batchId: 0,
              syncId: 0,
              type: ResultType.strings,
              flag: ResultFlag.ng,
              message: ex.toString(),
              messageCode: "000002",
              data: ex.toString()));
    }
  }

  Future<ResponseResult> sendfile(String physicalSubPath, File file,
      {String userId = '',
      String deviceId = '',
      String ref1 = '',
      String ref2 = ''}) async {
    try {
      // var connectivityResult = await (Connectivity().checkConnectivity());
      // if (connectivityResult == ConnectivityResult.mobile) {
      //   // I am connected to a mobile network.
      // } else if (connectivityResult == ConnectivityResult.wifi) {
      //   // I am connected to a wifi network.
      // } else {
      //   return ResponseResult(
      //       item: ResponseResultItem(
      //           batchId: 0,
      //           syncId: 0,
      //           type: ResultType.strings,
      //           flag: ResultFlag.ng,
      //           message: '未啟用網路連線',
      //           messageCode: "000002",
      //           data: '未啟用網路連線'));
      // }
      bool heartbeat = await checkHeartbeat();
      if (heartbeat == false) {
        return ResponseResult(
            item: ResponseResultItem(
                batchId: 0,
                syncId: 0,
                type: ResultType.strings,
                flag: ResultFlag.ng,
                message: '無法連接伺服器',
                messageCode: "000002",
                data: '無法連接伺服器'));
      }

      List<int> _fileBytes = file.readAsBytesSync();
      DateTime _fileLastAccessTime = file.lastAccessedSync();
      DateTime _fileLastModifiedTime = file.lastModifiedSync();

      final http.Response response = await http.post(
        '${Business.remoteUrl}/datagram/method=sendfile',
        headers: {
          'ApplicationId': Business.appId,
          'ApiToken': Business.appToken,
          'CompanyId': Business.companyId,
          'file_name': path.basenameWithoutExtension(file.path),
          'file_ext_name': path.extension(file.path).replaceAll('.', ''), //副檔名
          'create_time': DateFormat('yyyy-MM-dd HH:mm:ss')
              .format(_fileLastAccessTime)
              .toString(), //建立時間
          'modify_time': DateFormat('yyyy-MM-dd HH:mm:ss')
              .format(_fileLastModifiedTime), //修改時間
          'physical_sub_path': physicalSubPath,
          'upload_user': userId,
          'upload_device': deviceId,
          'file_ref1': ref1,
          'file_ref2': ref2,
        },
        body: _fileBytes,
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        return ResponseResult(
            item: ResponseResultItem(
                batchId: 0,
                syncId: 0,
                type: ResultType.strings,
                flag: ResultFlag.ng,
                message: "網路通訊失敗",
                messageCode: "024008",
                data: "網路通訊失敗"));
      } else {
        return ResponseResult.fromJsonStr(response.body);
      }
    } catch (ex) {
      return ResponseResult(
          item: ResponseResultItem(
              batchId: 0,
              syncId: 0,
              type: ResultType.strings,
              flag: ResultFlag.ng,
              message: ex.toString(),
              messageCode: "000002",
              data: ex.toString()));
    }
  }

  Future<bool> checkHeartbeat() async {
    try {
      //
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.mobile) {
        // I am connected to a mobile network.
      } else if (connectivityResult == ConnectivityResult.wifi) {
        // I am connected to a wifi network.
      } else {
        return false;
      }
      var dio = Dio();
      Response response = await dio.get(
        '${Business.remoteUrl}/datagram/method=heartbeat',
        options: Options(
            headers: Business.appTokenMap,
            sendTimeout: 10000,
            receiveTimeout: 10000),
      );
      //.timeout(Duration(seconds: 5));

      if (response.statusCode != 200 && response.statusCode != 201) {
        return false;
      } else {
        return true;
      }
    } catch (ex) {
      return false;
    }
  }

  Future<ResponseResult> apiHeartbeatAsync() async {
    try {
      //
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.mobile) {
        // I am connected to a mobile network.
      } else if (connectivityResult == ConnectivityResult.wifi) {
        // I am connected to a wifi network.
      } else {
        List<String> messageList = List<String>();
        messageList.add('未啟用網路連線');
        return _getResponseResult('030002', messageList: messageList);
      }

      Dio dio = Dio();
      Response response = await dio.get(
        '${Business.remoteUrl}/command/method=heartbeat',
        options: Options(sendTimeout: 10000, receiveTimeout: 10000),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return _getResponseResult('000001');
      } else {
        return _getResponseResult('030007');
      }
    } on DioError catch (e) {
      _fromDioError(e);
      List<String> messageList = List<String>();
      messageList.add('網路中斷,請確認網路連線');
      return _getResponseResult('030002', messageList: messageList);
    } catch (ex) {
      List<String> messageList = List<String>();
      messageList.add('網路中斷,請確認網路連線');
      return _getResponseResult('030002', messageList: messageList);
    }
  }

  Future<ResponseResult> apiExecuteDatagram(Datagram datagram,
      {int commandTimeout = 30000}) async {
    try {
      ResponseResult result = await apiHeartbeatAsync();
      if (result.flag == ResultFlag.ng) {
        return _getResponseResult('030007');
      }

      Dio dio = Dio();
      // dio.interceptors.add(InterceptorsWrapper(onResponse: (Response response) {
      //   debugPrint('響應之前');
      //   return response;
      // }, onError: (DioError e) {
      //   print('錯誤之前');
      //   return e;
      // }));

      Response response = await dio.post(
        '${Business.remoteUrl}/command/method=send',
        data: datagram.toJsonStr(),
        options: Options(
            headers: Business.appTokenMap,
            sendTimeout: commandTimeout,
            receiveTimeout: Business.httpConnectionTimeout * 1000),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ResponseResult.fromJson(response.data);
      } else {
        return _getResponseResult('030007');
      }
    } on DioError catch (e) {
      _fromDioError(e);
      List<String> messageList = List<String>();
      messageList.add('網路中斷,請確認網路連線');
      return _getResponseResult('030002', messageList: messageList);
    } catch (ex) {
      List<String> messageList = List<String>();
      messageList.add('網路中斷,請確認網路連線');
      return _getResponseResult('030002', messageList: messageList);
    }
  }

  Future<ResponseResult> apiExecuteCommandField(CommandField commandField,
      {int commandTimeout = 30000,
      TransactionMode transactionMode =
          TransactionMode.commitAndRollback}) async {
    try {
      ResponseResult result = await apiHeartbeatAsync();
      if (result.flag == ResultFlag.ng) {
        return _getResponseResult('030007');
      }

      Datagram datagram = Datagram(transactionMode: transactionMode);
      datagram.addCommand(commandField);

      Dio dio = Dio();
      Response response = await dio.post(
        '${Business.remoteUrl}/command/method=send',
        data: datagram.toJsonStr(),
        options: Options(
            headers: Business.appTokenMap,
            sendTimeout: commandTimeout,
            receiveTimeout: Business.httpConnectionTimeout * 1000),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ResponseResult.fromJson(response.data);
      } else {
        return _getResponseResult('030007');
      }
    } catch (ex) {
      List<String> messageList = List<String>();
      messageList.add('網路中斷,請確認網路連線');
      return _getResponseResult('030002', messageList: messageList);
    }
  }

  Future<ResponseResult> apiListFile(FileCmdType fileCmdType,
      {Map<String, String> headers, int commandTimeout = 30000}) async {
    try {
      ResponseResult result = await apiHeartbeatAsync();
      if (result.flag == ResultFlag.ng) {
        return _getResponseResult('030007');
      }

      if (fileCmdType == FileCmdType.file) {
        if (headers != null && headers.keys.contains('SubPath') == false) {
          return _getResponseResult('030009');
        }
      }

      Map<String, String> map = Map();
      map.addAll(Business.appTokenMap);
      map.addAll({'FileCmdType': fileCmdType.toString().split('.')[1]});
      if (headers != null) {
        headers.forEach((String key, String value) {
          headers[key] = base64.encode(utf8.encode(value));
        });
        map.addAll(headers);
      }

      Dio dio = Dio();
      Response response = await dio.get(
        '${Business.remoteUrl}/command/method=listfile',
        options: Options(
          sendTimeout: commandTimeout,
          receiveTimeout: Business.httpConnectionTimeout * 1000,
          headers: map,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ResponseResult.fromJson(response.data);
      } else {
        return _getResponseResult('030007');
      }
    } catch (ex) {
      List<String> messageList = List<String>();
      messageList.add('網路中斷,請確認網路連線');
      return _getResponseResult('030002', messageList: messageList);
    }
  }

  Future<ResponseResult> apiUploadFile(
      FileCmdType fileCmdType, List<File> files,
      {Map<String, String> headers, int commandTimeout = 30000}) async {
    if (fileCmdType == FileCmdType.assembly ||
            fileCmdType == FileCmdType.component //||
        //fileCmdType == FileCmdType.script
        ) {
      return _getResponseResult('030010');
    }

    //檢查檔案是否有超過100M
    ResponseResult fileResult = _checkFileSize(files);
    if (fileResult.flag == ResultFlag.ng) {
      return fileResult;
    }

    try {
      ResponseResult result = await apiHeartbeatAsync();
      if (result.flag == ResultFlag.ng) {
        return _getResponseResult('030007');
      }

      if (fileCmdType == FileCmdType.file) {
        if (headers != null && headers.keys.contains('ModuleId') == false ||
            headers.keys.contains('SubPath') == false ||
            headers.keys.contains('ReceiptType') == false ||
            headers.keys.contains('ReceiptSerial') == false ||
            headers.keys.contains('ReceiptNo') == false ||
            headers.keys.contains('Tag1') == false ||
            headers.keys.contains('Tag2') == false ||
            headers.keys.contains('Descryption') == false ||
            headers.keys.contains('UploadUser') == false ||
            headers.keys.contains('UploadDevice') == false) {
          return _getResponseResult('030009');
        }
      }

      List<MultipartFile> multFile = List<MultipartFile>();
      for (File file in files) {
        multFile.add(await MultipartFile.fromFile(file.path,
            filename: base64.encode(utf8.encode(path.basename(file.path)))));
      }

      Map<String, String> headersMap = Map();
      headersMap.addAll(Business.appTokenMap);
      headersMap.addAll({'FileCmdType': fileCmdType.toString().split('.')[1]});
      if (headers != null) {
        headers.forEach((String key, String value) {
          headers[key] = base64.encode(utf8.encode(value));
        });
        headersMap.addAll(headers);
      }
      Map<String, dynamic> filesMap = Map();
      filesMap.addAll({'attachment': multFile.asMap().values.toList()});

      FormData formData = FormData.fromMap(filesMap);

      Dio dio = Dio();
      CancelToken cancelToken = CancelToken();
      Response response = await dio.post(
        '${Business.remoteUrl}/command/method=uploadfile',
        data: formData,
        options: Options(
          sendTimeout: commandTimeout,
          receiveTimeout: Business.httpConnectionTimeout * 1000,
          headers: headersMap,
        ),
        cancelToken: cancelToken,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ResponseResult.fromJson(response.data);
      } else {
        return _getResponseResult('030007');
      }
    } catch (ex) {
      List<String> messageList = List<String>();
      messageList.add('網路中斷,請確認網路連線');
      return _getResponseResult('030002', messageList: messageList);
    }
  }

  Future<ResponseResult> apiDownloadFile(
      FileCmdType fileCmdType, String filename,
      {Map<String, String> headers, int commandTimeout = 30000}) async {
    if (fileCmdType == FileCmdType.assembly ||
        fileCmdType == FileCmdType.component ||
        fileCmdType == FileCmdType.script) {
      return _getResponseResult('030010');
    }
    try {
      ResponseResult result = await apiHeartbeatAsync();
      if (result.flag == ResultFlag.ng) {
        return _getResponseResult('030007');
      }
      if (fileCmdType == FileCmdType.file) {
        if (headers != null && headers.keys.contains('SubPath') == false) {
          return _getResponseResult('030009');
        }
      }

      Map<String, dynamic> map = Map();
      map.addAll(Business.appTokenMap);
      map.addAll({
        'FileCmdType': fileCmdType.toString().split('.')[1],
        'Filename': base64.encode(utf8.encode(filename))
      });
      if (headers != null) {
        headers.forEach((String key, String value) {
          headers[key] = base64.encode(utf8.encode(value));
        });
        map.addAll(headers);
      }

      Dio dio = Dio();
      Response response = await dio.get(
        '${Business.remoteUrl}/command/method=downloadfile',
        options: Options(
          sendTimeout: commandTimeout,
          receiveTimeout: Business.httpConnectionTimeout * 1000,
          headers: map,
          responseType: ResponseType.bytes,
          followRedirects: false,
        ),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        List<int> bytesResult = response.data;
        if (bytesResult != null)
          return _getResponseResult('000001');
        else
          return _getResponseResult('030008');
      } else {
        return _getResponseResult('030007');
      }
    } catch (ex) {
      List<String> messageList = List<String>();
      messageList.add('網路中斷,請確認網路連線');
      return _getResponseResult('030002', messageList: messageList);
    }
  }

  Future<ResponseResult> apiDeleteFile(FileCmdType fileCmdType, String filename,
      {Map<String, String> headers, int commandTimeout = 30000}) async {
    if (fileCmdType == FileCmdType.assembly ||
        fileCmdType == FileCmdType.component ||
        fileCmdType == FileCmdType.script) {
      return _getResponseResult('030010');
    }
    try {
      ResponseResult result = await apiHeartbeatAsync();
      if (result.flag == ResultFlag.ng) {
        return _getResponseResult('030007');
      }

      if (fileCmdType == FileCmdType.file) {
        if (headers != null && headers.keys.contains('SubPath') == false) {
          return _getResponseResult('030009');
        }
      }

      Map<String, dynamic> map = Map();
      map.addAll(Business.appTokenMap);
      map.addAll({
        'FileCmdType': fileCmdType.toString().split('.')[1],
        'Filename': base64.encode(utf8.encode(filename))
      });
      if (headers != null) {
        headers.forEach((String key, String value) {
          headers[key] = base64.encode(utf8.encode(value));
        });
        map.addAll(headers);
      }

      Dio dio = Dio();
      Response response =
          await dio.delete('${Business.remoteUrl}/command/method=deletefile',
              options: Options(
                sendTimeout: commandTimeout,
                receiveTimeout: Business.httpConnectionTimeout * 1000,
                headers: map,
              ));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ResponseResult.fromJson(response.data);
      } else {
        return _getResponseResult('030007');
      }
    } catch (ex) {
      List<String> messageList = List<String>();
      messageList.add('網路中斷,請確認網路連線');
      return _getResponseResult('030002', messageList: messageList);
    }
  }

  Future<ResponseResult> downloadFile(String uri, String savePath,
      {Map<String, dynamic> headers, int commandTimeout = 30000}) async {
    try {
      Map<String, dynamic> headersMap = Map();
      headersMap.addAll(Business.appTokenMap);
      if (headers != null) {
        headersMap.addAll(headers);
      }

      Dio dio = Dio();
      CancelToken cancelToken = CancelToken();
      Response response = await dio
          .download(uri, savePath, cancelToken: cancelToken,
              onReceiveProgress: (int received, int total) {
        if (total != -1) {
          debugPrint((received / total * 100).toStringAsFixed(0) + "%");
        }
      },
              options: Options(
                sendTimeout: commandTimeout,
                receiveTimeout: Business.httpConnectionTimeout * 1000,
                headers: headersMap,
              ));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return _getResponseResult('000001');
      } else {
        return _getResponseResult('030007');
      }
    } catch (ex) {
      List<String> messageList = List<String>();
      messageList.add('網路中斷,請確認網路連線');
      return _getResponseResult('030002', messageList: messageList);
    }
  }

  Future<ResponseResult> downloadFileWithChunks(String uri, String savePath,
      {Map<String, dynamic> headers,
      int commandTimeout = 30000,
      ProgressCallback onReceiveProgress}) async {
    try {
      Map<String, dynamic> headersMap = Map();
      headersMap.addAll(Business.appTokenMap);
      if (headers != null) {
        headersMap.addAll(headers);
      }

      const firstChunkSize = 102;
      const maxChunk = 3;

      int total = 0;
      Dio dio = Dio();
      List<int> progress = <int>[];

      createCallback(no) {
        return (int received, _) {
          progress[no] = received;
          if (onReceiveProgress != null && total != 0) {
            onReceiveProgress(progress.reduce((a, b) => a + b), total);
          }
        };
      }

      Future<Response> downloadChunk(url, start, end, no) async {
        progress.add(0);
        --end;
        headersMap.addAll({'range': 'bytes=$start-$end'});
        return dio.download(
          url,
          savePath + "temp$no",
          onReceiveProgress: createCallback(no),
          options: Options(
            headers: headersMap,
          ),
        );
      }

      Future mergeTempFiles(chunk) async {
        File f = File(savePath + "temp0");
        IOSink ioSink = f.openWrite(mode: FileMode.writeOnlyAppend);
        for (int i = 1; i < chunk; ++i) {
          File _f = File(savePath + "temp$i");
          await ioSink.addStream(_f.openRead());
          await _f.delete();
        }
        await ioSink.close();
        await f.rename(savePath);
      }

      Response response = await downloadChunk(uri, 0, firstChunkSize, 0);
      if (response.statusCode == 206) {
        total = int.parse(response.headers
            .value(HttpHeaders.contentRangeHeader)
            .split("/")
            .last);
        int reserved = total -
            int.parse(response.headers.value(Headers.contentLengthHeader));
        int chunk = (reserved / firstChunkSize).ceil() + 1;
        if (chunk > 1) {
          int chunkSize = firstChunkSize;
          if (chunk > maxChunk + 1) {
            chunk = maxChunk + 1;
            chunkSize = (reserved / maxChunk).ceil();
          }
          var futures = <Future>[];
          for (int i = 0; i < maxChunk; ++i) {
            int start = firstChunkSize + i * chunkSize;
            futures.add(downloadChunk(uri, start, start + chunkSize, i + 1));
          }
          await Future.wait(futures);
        }
        await mergeTempFiles(chunk);

        return _getResponseResult('000001');
      } else {
        return _getResponseResult('030007');
      }
    } catch (ex) {
      List<String> messageList = List<String>();
      messageList.add('網路中斷,請確認網路連線');
      return _getResponseResult('030002', messageList: messageList);
    }
  }

  //=========================================================
  Future<void> _initSqllite() async {
    _sqlLiteVersion = '1.0.0';

    String localDbPath = await getDatabasesPath();
    _sqlLiteFilename = path.join(localDbPath, 'engineu.db');

    File f = File(_sqlLiteFilename);
    bool fileExist = await f.exists();
    // if (fileExist == true) {
    //   await deleteDatabase(_sqlLiteFilename);
    //   fileExist = false;
    // }
    if (fileExist == false) {
      Database database = await openDatabase(_sqlLiteFilename, version: 1,
          onCreate: (Database db, int version) async {
        await db.execute(
            'create table login (id integer primary key, userId text, lastLoginTime text)');
      });
      if (database.isOpen) {
        await database.transaction((txn) async {
          await txn.rawInsert(
              'insert into login(id, userId, lastLoginTime) values(0, "", "")');
        });
        await database.close();
      }
    }
    _sqlLiteInitialized = true;
  }

  Future<bool> sqlLiteInsert(String command, [List<dynamic> arguments]) async {
    try {
      if (_sqlLiteInitialized == false) await _initSqllite();

      bool _success = false;
      Database database = await openDatabase(_sqlLiteFilename, version: 1);
      if (database.isOpen == true) {
        await database.transaction((txn) async {
          await txn.rawInsert(command, arguments);
          _success = true;
        });
        await database.close();
      } else {
        _success = false;
      }
      return _success;
    } catch (_) {
      //on DatabaseException catch (e) {
      return false;
    }
  }

  Future<bool> sqlLiteUpdate(String command, [List<dynamic> arguments]) async {
    try {
      if (_sqlLiteInitialized == false) await _initSqllite();

      bool _success = false;
      Database database = await openDatabase(_sqlLiteFilename, version: 1);
      if (database.isOpen == true) {
        await database.transaction((txn) async {
          await txn.rawUpdate(command, arguments);
          _success = true;
        });
        await database.close();
      } else {
        _success = false;
      }
      return _success;
    } catch (_) {
      //on DatabaseException catch (e) {
      return false;
    }
  }

  Future<bool> sqlLiteDelete(String command, [List<dynamic> arguments]) async {
    try {
      if (_sqlLiteInitialized == false) await _initSqllite();

      bool _success = false;
      Database database = await openDatabase(_sqlLiteFilename, version: 1);
      if (database.isOpen == true) {
        await database.transaction((txn) async {
          await txn.rawDelete(command, arguments);
          _success = true;
        });
        await database.close();
      } else {
        _success = false;
      }
      return _success;
    } catch (_) {
      //on DatabaseException catch (e) {
      return false;
    }
  }

  Future<ResponseResult> sqlLiteQuery(String command,
      [List<dynamic> arguments]) async {
    try {
      if (_sqlLiteInitialized == false) await _initSqllite();

      Database database = await openDatabase(_sqlLiteFilename, version: 1);
      if (database.isOpen == true) {
        List<Map<String, dynamic>> ret =
            await database.rawQuery(command, arguments);
        ResponseResult result = ResponseResult();
        result.setflag = ResultFlag.ok;
        result.items.add(ResponseResultItem(
            batchId: 0,
            syncId: 0,
            flag: ResultFlag.ok,
            type: ResultType.map,
            message: '處理完成',
            messageCode: "000001",
            data: ret));

        // for(int i=0;i< ret.length;i++)
        // {
        //   Map<String, dynamic> mapItem = ret[i];
        //   result.items.add(ResponseResultItem(
        //       batchId: 0,
        //       syncId: 0,
        //       flag: ResultFlag.ok,
        //       type: ResultType.map,
        //       message: '處理完成',
        //       messageCode: "000001",
        //       data: mapItem));
        // }
        // ret.map((v) {
        //   result.items.add(ResponseResultItem(
        //       batchId: 0,
        //       syncId: 0,
        //       flag: ResultFlag.ok,
        //       type: ResultType.map,
        //       message: '處理完成',
        //       messageCode: "000001",
        //       data: v));
        // });
        return result;
      } else {
        return ResponseResult(
            item: ResponseResultItem(
                batchId: 0,
                syncId: 0,
                flag: ResultFlag.ng,
                message: '讀取系統組態失敗',
                messageCode: "026003",
                data: '讀取系統組態失敗'));
      }
    } catch (_) {
      //on DatabaseException catch (e) {
      return ResponseResult(
          item: ResponseResultItem(
              batchId: 0,
              syncId: 0,
              flag: ResultFlag.ng,
              message: '讀取系統組態失敗',
              messageCode: "026003",
              data: '讀取系統組態失敗'));
    }
  }
}
