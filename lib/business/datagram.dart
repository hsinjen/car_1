//library engineu;

import 'dart:convert';

//============================= Datagram
class Datagram {
//===== Member
  List<CommandField> _commands = [];
  final TransactionMode transactionMode;
  final String databaseNameOrSid;

//===== Property
  List<CommandField> get commandList {
    return _commands;
  }

  set setCommandList(List<CommandField> value) {
    _commands = value;
  }

//===== Constructor
  Datagram(
      {this.transactionMode = TransactionMode.commitAndRollback,
      this.databaseNameOrSid = ''});

//===== Public Method
  void add(CmdType cmdType, String cmdText,
      {int batchId = 0,
      int syncId = 0,
      int rowIndex = 0,
      int rowSize = 65535}) {
    _commands.add(CommandField(
        cmdType: cmdType,
        commandText: cmdText,
        batchId: batchId,
        syncId: syncId,
        rowIndex: rowIndex,
        rowSize: rowSize));
  }

  void addText(String cmdText, {int rowIndex = 0, int rowSize = 65535}) {
    _commands.add(CommandField(
        cmdType: CmdType.text,
        commandText: cmdText,
        rowIndex: rowIndex,
        rowSize: rowSize));
  }

  bool addProcedure(String procedureName, {List<ParameterField> parameters}) {
    try {
      CommandField newCommand =
          CommandField(cmdType: CmdType.procedure, commandText: procedureName);
      if (parameters
              .where((v) => v.paramName.toLowerCase() == "oresult_flag")
              .length ==
          0)
        parameters.add(ParameterField(
            "oRESULT_FLAG", ParamType.strings, ParamDirection.output,
            size: 2));

      if (parameters
              .where((v) => v.paramName.toLowerCase() == "oresult")
              .length ==
          0)
        parameters.add(ParameterField(
            "oRESULT", ParamType.strings, ParamDirection.output));

      newCommand.setParameters = parameters;

      _commands.add(newCommand);
      return true;
    } catch (_) {
      return false;
    }
  }

  bool addCommand(CommandField command) {
    try {
      if (command.cmdType == CmdType.procedure ||
          command.cmdType == CmdType.fill_procedure) {
        if (command.parameters
                .where((v) => v.paramName.toLowerCase() == "oresult_flag")
                .length ==
            0)
          command.parameters.add(ParameterField(
              "oRESULT_FLAG", ParamType.strings, ParamDirection.output,
              size: 2));

        if (command.parameters
                .where((v) => v.paramName.toLowerCase() == "oresult")
                .length ==
            0)
          command.parameters.add(ParameterField(
              "oRESULT", ParamType.strings, ParamDirection.output));
      }
      _commands.add(command);
      return true;
    } catch (_) {
      return false;
    }
  }

  //停用
  // bool addWebFile(String companyId, String urlSubPath, File file ,{String userId = '',String deviceId = '',String ref1 = '',String ref2 = ''})  {
  //   if (companyId == '') return false;
  //   if (file == null) return false;

  //   try {

  //     List<int> _fileBytes = file.readAsBytesSync();
  //     int _fileLength = file.lengthSync();
  //     DateTime _fileLastAccessTime = file.lastAccessedSync();
  //     DateTime _fileLastModifiedTime = file.lastModifiedSync();
  //     // List<int> gzipBytes = new GZipEncoder().encode(_fileBytes);
  //     // int xxxx = gzipBytes.length;

  //     CommandField cmd = CommandField(
  //         cmdType: CmdType.web_file, commandText: "spx_upload_physical_file");
  //     cmd.addParamText(
  //         "file_name", path.basenameWithoutExtension(file.path)); //檔名不含副
  //     cmd.addParamText("file_ext_name", path.extension(file.path)); //副檔名

  //     cmd.addParamText("create_time",
  //         DateFormat('yyyy-MM-dd HH:mm:ss').format(_fileLastAccessTime)); //建立時間
  //     cmd.addParamText("modify_time",
  //         DateFormat('yyyy-MM-dd HH:mm:ss').format(_fileLastModifiedTime)); //
  //     cmd.addParamText("file_length", _fileLength.toString()); //長度
  //     cmd.addParamText("physical_path", '');
  //     cmd.addParamText("physical_sub_path", urlSubPath);
  //     cmd.addParamText("file_chksum", '');
  //     cmd.addParamText("osbit", 'All');
  //     cmd.addParamText("company_id", companyId);
  //     cmd.addParamText("upload_user", userId);
  //     cmd.addParamText("upload_device", deviceId);
  //     cmd.addParamText("file_ref1", ref1);
  //     cmd.addParamText("file_ref2", ref2);

  //    cmd.addParamText("filestream", base64Encode(_fileBytes));
  //     //cmd.addParam(ParameterField('filestream',ParamType.binary,ParamDirection.input, value: _fileBytes,size: _fileBytes.length));

  //     cmd.addParam(ParameterField(
  //         "oUrl", ParamType.strings, ParamDirection.output,
  //         size: 512));
  //     cmd.addParam(ParameterField(
  //         "oFile_Id", ParamType.strings, ParamDirection.output,
  //         size: 32));
  //     cmd.addParam(ParameterField(
  //         "oRESULT_FLAG", ParamType.strings, ParamDirection.output,
  //         size: 2));
  //     cmd.addParam(
  //         ParameterField("oRESULT", ParamType.strings, ParamDirection.output));
  //     _commands.add(cmd);
  //     return true;
  //   } catch (ex) {
  //     return false;
  //   }
  // }

//===== Serialize ~ Deserialize
  factory Datagram.fromJson(Map<String, dynamic> jsonMap) {
    Datagram datagram = Datagram(
        transactionMode: TransactionMode.values.firstWhere((e) =>
            e.toString() == 'TransactionMode.' + jsonMap['transactionMode']),
        databaseNameOrSid: jsonMap['databaseNameOrSid']);

    var commandBuffer = json.decode(jsonMap['commands']) as List;
    List<CommandField> commandList =
        commandBuffer.map((i) => CommandField.fromJson(i)).toList();

    datagram.setCommandList = commandList;
    return datagram;
  }
  Map<String, dynamic> toJson() => {
        'transactionMode': transactionMode.toString().split('.')[1],
        'databaseNameOrSid': databaseNameOrSid,
        'commands':
            json.encode(commandList) //_removeChar(json.encode(commandList))
      };
  factory Datagram.fromJsonStr(String jsonStr) {
    return Datagram.fromJson(json.decode(jsonStr));
  }
  String toJsonStr() {
    Map<String, dynamic> buffer = toJson();
    return json.encode(buffer);
  }
}

//============================= CommandField
class CommandField {
//===== Member
  List<ParameterField> _parameters = [];
  final CmdType cmdType;
  final String commandText;
  final int rowIndex;
  final int rowSize;
  final int batchId;
  final int syncId;
  final int retryCount;

//===== Property
  List<ParameterField> get parameters {
    return _parameters;
  }

  set setParameters(List<ParameterField> value) {
    _parameters = value == null ? [] : value;
  }

//Constructor
  CommandField(
      {this.cmdType,
      this.commandText,
      this.rowIndex = 0,
      this.rowSize = 65535,
      this.batchId = 0,
      this.syncId = 0,
      this.retryCount = 3});

//===== Public Method
  bool addParamText(String parameterName, String value) {
    if (_parameters
            .where(
                (v) => v.paramName.toLowerCase() == parameterName.toLowerCase())
            .length ==
        0) {
      _parameters.add(ParameterField(
          parameterName, ParamType.strings, ParamDirection.input,
          value: value));
      return true;
    }
    return false;
  }

  bool addParam(ParameterField param) {
    _parameters.add(param);
    return true;
  }

//===== Serialize ~ Deserialize
  factory CommandField.fromJson(Map<String, dynamic> jsonstr) {
    CommandField cmd = CommandField(
      cmdType: CmdType.values
          .firstWhere((e) => e.toString() == 'CmdType.' + jsonstr['cmdType']),
      commandText: jsonstr['commandText'],
      rowIndex: jsonstr['rowIndex'],
      rowSize: jsonstr['rowSize'],
      batchId: jsonstr['batchId'],
      syncId: jsonstr['syncId'],
      retryCount: jsonstr['retryCount'],
    );
    var parameterBuffer = json.decode(jsonstr['parameters']) as List;
    List<ParameterField> parameterList =
        parameterBuffer.map((i) => ParameterField.fromJson(i)).toList();
    cmd.setParameters = parameterList;
    return cmd;
  }
  Map<String, dynamic> toJson() => {
        'cmdType': cmdType.toString().split('.')[1],
        'commandText': base64.encode(utf8.encode(commandText)),
        'rowIndex': rowIndex,
        'rowSize': rowSize,
        'batchId': batchId,
        'syncId': syncId,
        'retryCount': retryCount,
        'parameters':
            json.encode(parameters) // _removeChar(json.encode(parameters))
      };
}

//============================= ParameterField
class ParameterField {
//===== Member
  final String paramName;
  final ParamType dataType;
  final ParamDirection direction;
  final String value;
  final int size;

//Constructor
  ParameterField(this.paramName, this.dataType, this.direction,
      {this.value, this.size = 65535});

//===== Serialize ~ Deserialize
  factory ParameterField.fromJson(Map<String, dynamic> jsonstr) {
    return ParameterField(
        jsonstr['paramName'],
        ParamType.values.firstWhere(
            (e) => e.toString() == 'ParamType.' + jsonstr['dataType']),
        ParamDirection.values.firstWhere(
            (e) => e.toString() == 'ParamDirection.' + jsonstr['direction']),
        value: jsonstr['value'],
        size: jsonstr['size']);
  }
  Map<String, dynamic> toJson() => {
        'paramName': paramName,
        'dataType': dataType.toString().split('.')[1],
        'direction': direction.toString().split('.')[1],
        'value': value,
        'size': size
      };
}

//============================= Enums
enum ParamType { strings, int32, number, datetime, boolean, binary, table }
enum ParamDirection { input, output }
enum CmdType { text, procedure, schema, file, fill_procedure }
enum TransactionMode {
  commitAndRollback,
  commitAndRollbackIgnoreError,
  noTransaction
}
