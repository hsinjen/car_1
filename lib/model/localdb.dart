import 'package:car_1/business/datagram.dart';
import 'package:car_1/business/responseresult.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';

class LocalDb {
  String dbName;
  int dbVersion;
  List<String> schemas;

  LocalDb();

  Future<Database> getDatabase() async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, dbName);

    final instance = openDatabase(path, version: dbVersion,
        onCreate: (Database db, int version) {
      if (this.schemas != null && this.schemas.length > 0) {
        for (String sch in this.schemas) {
          db.execute(sch);
        }
      }
    });

    return instance;
  }

  Future<void> showSchema() async {
    final database = await getDatabase();
    var datatable = await database
        .rawQuery("""SELECT * FROM sqlite_master WHERE type='table';""");
    for (int i = 0; i < datatable.length; i++)
      print('Schema: ' + datatable[i]['name'].toString());
  }

  Future<void> delDatabase(String dbName) async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, dbName);

    bool exist = await databaseExists(path);
    if (exist) await deleteDatabase(path);
  }

  Future<bool> existsDatabase(String dbName) async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, dbName);

    bool exist = await databaseExists(path);
    return exist;
  }

  Future<ResponseResult> execute(Datagram datagram) async {
    final database = await getDatabase();
    ResponseResult r = ResponseResult();

    try {
      for (CommandField cmd
          in datagram.commandList.where((v) => v.cmdType == CmdType.text)) {
        //==================================================
        //insert
        if (cmd.commandText.startsWith('insert') == true) {
          int insertCount = await database.rawInsert(cmd.commandText);
          r.items.add(ResponseResultItem(
              batchId: 0,
              syncId: 0,
              flag: ResultFlag.ok,
              messageCode: '000001',
              message: '',
              type: ResultType.strings,
              data: insertCount));
        }
        //update
        else if (cmd.commandText.startsWith('update') == true) {
          int updateCount = await database.rawUpdate(cmd.commandText);
          r.items.add(ResponseResultItem(
              batchId: 0,
              syncId: 0,
              flag: ResultFlag.ok,
              messageCode: '000001',
              message: '',
              type: ResultType.strings,
              data: updateCount));
        }
        //delete
        else if (cmd.commandText.startsWith('delete') == true) {
          int deleteCount = await database.rawDelete(cmd.commandText);
          r.items.add(ResponseResultItem(
              batchId: 0,
              syncId: 0,
              flag: ResultFlag.ok,
              messageCode: '000001',
              message: '',
              type: ResultType.strings,
              data: deleteCount));
        }
        //query
        else {
          var datatable = await database.rawQuery(cmd.commandText);
          r.items.add(ResponseResultItem(
              batchId: 0,
              syncId: 0,
              flag: ResultFlag.ok,
              messageCode: '000001',
              message: '',
              type: ResultType.datatable,
              data: datatable.toList()));
        }
        //==================================================
      }
    } catch (e) {
      r.items.add(ResponseResultItem(
          batchId: 0,
          syncId: 0,
          flag: ResultFlag.ng,
          messageCode: '000004',
          message: '',
          type: ResultType.strings,
          data: e.toString()));
    } finally {
      if (database != null && database.isOpen == true) database.close();
    }
    return r;
  }
}
