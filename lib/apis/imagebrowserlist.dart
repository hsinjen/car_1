import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'messagebox.dart';
import 'package:path_provider/path_provider.dart';
import '../business/classes.dart';
import 'imagebrowser.dart';
import '../business/datagram.dart';
import '../business/responseresult.dart';
import '../business/business.dart';
import 'dart:async';

class ImageBrowserList extends StatefulWidget {
  final FileSourceType fileSourceType;
  final String initSubDir;
  //目錄結構定義:
  //Root + CategoryDir(initSubDir) + KeyDir + FileName.file
  final Future<bool> Function(FileItem item, File f) uploadProcess;
  //==========================================================================
  List<FileItem> _fileSource;
  List<KeyValueItem<String, String>> _fileSourceByKeyCategory; //Key, Category
  bool _isUploadLoading = false;
  bool _initData = false;

  //==================================================
  ImageBrowserList(this.fileSourceType, this.initSubDir, {this.uploadProcess});

  @override
  State<StatefulWidget> createState() {
    return _ImageBrowserList();
  }
}

class _ImageBrowserList extends State<ImageBrowserList> {
  @override
  void initState() {
    super.initState();
    if (widget._initData == false) _getFiles();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        //======================= App Bar Start
        appBar: new AppBar(
          title: new Text(
              (widget.fileSourceType == FileSourceType.offline ? '本機' : '線上') +
                  "圖片瀏覽列表"),
          actions: <Widget>[
            widget.fileSourceType == FileSourceType.offline
                ? IconButton(
                    icon: Icon(Icons.file_upload),
                    onPressed: () async {
                      MessageBox.showQuestion(context, '請保持您的網路與電力', '是否上傳檔案',
                          yesFunc: () {
                        setState(() {
                          widget._isUploadLoading = true;
                        });
                        _uploadFile().then((_) {
                          _getFiles();
                          setState(() {
                            widget._isUploadLoading = false;
                            widget._initData = false;
                          });
                        });
                      });
                    },
                  )
                : Container(),
          ],
        ),
        //======================= App Bar End
        body: (widget._fileSourceByKeyCategory == null ||
                widget._fileSourceByKeyCategory.length == 0)
            ? Center(child: Container(child: Text('沒有圖片')))
            : (widget._isUploadLoading == false
                ? Container(
                    width: MediaQuery.of(context).size.width,
                    height: 300,
                    child: ListView.builder(
                        itemCount: widget._fileSourceByKeyCategory == null
                            ? 0
                            : widget._fileSourceByKeyCategory.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Container(
                              child: Column(
                            children: <Widget>[
                              ListTile(
                                leading: RawMaterialButton(
                                  onPressed: () {
                                    //====== Jump to ImageBrowser
                                    Navigator.push(
                                      context,
                                      new MaterialPageRoute(
                                        builder: (context) => new ImageBrowser(
                                            widget.fileSourceType,
                                            // widget._fileSource
                                            //     .where((v) =>
                                            //         v.fileRef1 ==
                                            //         widget._fileSource[index]
                                            //             .fileRef1).toList(), 
                                            widget._fileSource
                                                .where((v) =>
                                                    v.fileRef1 ==
                                                    widget._fileSourceByKeyCategory[index]
                                                        .key).toList(), 
                                                        (String fileUrl) {
                                          setState(() {
                                            if (widget._fileSource.length <=
                                                1) {
                                              widget._initData = false;
                                            } else {
                                              FileItem item = widget._fileSource
                                                  .firstWhere((v) =>
                                                      v.fileUrl == fileUrl);
                                              widget._fileSource.removeWhere(
                                                  (v) => v.fileUrl == fileUrl);
                                              if (widget._fileSource
                                                      .where((v) =>
                                                          v.fileRef1 ==
                                                          item.fileRef1)
                                                      .length ==
                                                  0)
                                                widget._fileSourceByKeyCategory
                                                    .removeWhere((v) =>
                                                        v.key == item.fileRef1);
                                            }
                                          });
                                        }),
                                      ),
                                    );
                                    //====== Jump to ImageBrowser End
                                  },
                                  child: Text(
                                      widget
                                          ._fileSourceByKeyCategory[index].value
                                          .substring(0, 1),
                                      style: TextStyle(color: Colors.white)),
                                  shape: new CircleBorder(),
                                  elevation: 1.0,
                                  fillColor: Colors.black,
                                  padding: const EdgeInsets.all(10.0),
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () {
                                    //==== 刪除目錄所有檔案
                                    if (widget.fileSourceType ==
                                        FileSourceType.offline) {
                                      _removeFilesOfDir(widget
                                          ._fileSourceByKeyCategory[index].key);
                                    }
                                  },
                                ),
                                title: Text(
                                    widget._fileSourceByKeyCategory[index].key,
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('圖片: ' +
                                    widget._fileSource
                                        .where((v) =>
                                            v.fileRef1 ==
                                            widget
                                                ._fileSourceByKeyCategory[index]
                                                .key)
                                        .length
                                        .toString() +
                                    ' 張'),
                              ),
                            ],
                          ));
                        }),
                  )
                : Center(
                    child: Container(
                        child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Colors.green),
                      ),
                      SizedBox(height: 10.0),
                      Text('上傳檔案中....尚有 ' +
                          (widget._fileSource == null
                              ? '0'
                              : widget._fileSource.length.toString()) +
                          ' 筆'),
                    ],
                  )))));
  }

  void _removeFilesOfDir(String dirName) {
    MessageBox.showQuestion(context, '', '刪除所有檔案',
        yesButtonText: '刪除', noButtonText: '放棄', yesFunc: () {
      //widget._fileSource.where((vin) => vin.fileName == key).forEach((v) {
      if (widget.fileSourceType == FileSourceType.offline) {
        //===== Offline Start
        getApplicationDocumentsDirectory().then((Directory dir) {
          Directory _appDocDir = dir;
          if (Directory(
                      _appDocDir.path + '/' + widget.initSubDir + '/' + dirName)
                  .existsSync() ==
              true) {
            //===刪除檔案不要用非同步，不然會有錯誤訊息，雖然實作正常，但錯誤訊息看起來不爽。
            Directory(_appDocDir.path + '/' + widget.initSubDir + '/' + dirName)
                .deleteSync(recursive: true);
            setState(() {
              widget._initData = false;
              //widget._fileSource.removeWhere((f) => f.fileRef1 == dirName);
              //widget._fileKeys.removeWhere((f) => f.key == key);
            });
          }
        });
        Navigator.pop(context);
        //==== Offline End
      }
      //});
    });
  }

  void _getFiles() async {
    widget._initData = true;
    if (widget._fileSource != null) widget._fileSource.clear();
    if (widget._fileSourceByKeyCategory != null)
      widget._fileSourceByKeyCategory.clear();

    if (widget.fileSourceType == FileSourceType.offline) {
      getApplicationDocumentsDirectory().then((Directory dir) {
        Directory _appDocDir = dir;
        if (Directory(_appDocDir.path + '/' + widget.initSubDir).existsSync() ==
            true) {
          List<FileItem> fileSourceList = new List<FileItem>();
          List<KeyValueItem<String, String>> fileSourceByKeyCategoryList =
              new List<KeyValueItem<String, String>>();

          Directory(_appDocDir.path + '/' + widget.initSubDir)
              .list(recursive: true, followLinks: false)
              .listen((FileSystemEntity entity) {
            if (entity is Directory) {
              String keyDirName = path.basenameWithoutExtension(entity.path);
              String categoryName =
                  path.basenameWithoutExtension(entity.parent.path);
              if (fileSourceByKeyCategoryList
                      .where((v) => v.key == keyDirName)
                      .length ==
                  0)
                fileSourceByKeyCategoryList
                    .add(KeyValueItem(keyDirName, categoryName));
            } else {
              File f = File(entity.path);
              int _fileLength = f.lengthSync();

              fileSourceList.add(FileItem(
                  widget.fileSourceType,
                  path.basename(path.dirname(entity.path)),
                  path.extension(entity.path),
                  _fileLength,
                  entity.path,
                  fileRef1:
                      path.basenameWithoutExtension(f.parent.path), // Directory
                  fileRef2: path.basenameWithoutExtension(
                      f.parent.parent.path), //Caregory Directory
                  fileRef3: ''));
            }
          }).onDone(() {
            setState(() {
              widget._fileSource = fileSourceList;
              widget._fileSourceByKeyCategory = fileSourceByKeyCategoryList;
            });
          });
        }
      });
    } else {
      String vin = widget.initSubDir;
      Datagram datagram = Datagram();

      datagram.addText(
          """select * from sys_physical_file where file_ref1='$vin'""");
      ResponseResult result = await Business.send(datagram);
      if (result.flag == ResultFlag.ok) {
        List<Map<String, dynamic>> data = result.getMap();
        if (data.length > 0) {
          List<FileItem> fileSourceList = new List<FileItem>();
          List<KeyValueItem<String, String>> fileSourceByVinCategoryList =
              new List<KeyValueItem<String, String>>();
          for (int i = 0; i < data.length; i++) {
            fileSourceList.add(FileItem(
                widget.fileSourceType,
                data[i]['originalFilename']
                    .toString(), //path.basenameWithoutExtension(entity.path),
                data[i]['originalFileExtName'].toString(),
                data[i]['originalLength'],
                data[i]['url'].toString(),
                fileRef1: data[i]['file_ref1'].toString(), //VIN Directory
                fileRef2: data[i]['file_ref2'].toString(), //Caregory Directory
                fileRef3: ''));

            if (fileSourceByVinCategoryList
                    .where((v) => v.key == data[i]['file_ref1'].toString())
                    .length ==
                0)
              fileSourceByVinCategoryList.add(KeyValueItem(
                  data[i]['file_ref1'].toString(),
                  data[i]['file_ref2'].toString()));
          }
          setState(() {
            widget._fileSource = fileSourceList;
            widget._fileSourceByKeyCategory = fileSourceByVinCategoryList;
          });
        }
      } else {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _uploadFile() async {
    if (widget.fileSourceType == FileSourceType.online) return true;
    if (widget._fileSource != null && widget._fileSource.length > 0) {
      FileItem item = widget._fileSource[0];
      File f = File(item.fileUrl);

      bool success = await widget.uploadProcess(item, f);
      if (success == true) {
        f.delete(recursive: true);

        if (widget._fileSource.length <= 1)
        //如果資料來源 <= 1 筆
        {
          setState(() {
            widget._fileSource.clear();
            widget._fileSourceByKeyCategory.clear();
          });
        } else
        //如果資料來源 > 1 筆
        {
          setState(() {
            widget._fileSource.removeWhere((v) => v.fileUrl == item.fileUrl);
            //如果
            if (widget._fileSource
                    .where((v) => v.fileRef1 == item.fileRef1)
                    .length ==
                0)
            //如果 KeyDir 裡沒有任何檔案時
            {
              widget._fileSourceByKeyCategory
                  .removeWhere((v) => v.key == item.fileRef1);
            }
          });
        }
        if (widget._fileSource
                .where((v) => v.fileRef1 == item.fileRef1)
                .length ==
            0) {
          Directory(f.parent.path).deleteSync(recursive: true);
        }
        //如果資料來源 > 0 , 遞迴呼叫
        if (widget._fileSource.length > 0) {
          await _uploadFile();
        }
      }

      //   ResponseResult result = await Business.sendFile(
      //       widget.initSubDir + '/' + item.fileName, f,
      //       userId: Business.userId,
      //       deviceId: Business.deviceId,
      //       ref1: path.basenameWithoutExtension(f.parent.path),
      //       ref2: path.basenameWithoutExtension(f.parent.parent.path));

      //   //Upload Success
      //   if (result.flag == ResultFlag.ok) {
      //     f.delete(recursive: true);

      //     if (widget._fileSource.length <= 1)
      //     //如果資料來源 <= 1 筆
      //     {
      //       setState(() {
      //         widget._fileSource.clear();
      //         widget._fileSourceByKeyCategory.clear();
      //       });
      //     } else
      //     //如果資料來源 > 1 筆
      //     {
      //       setState(() {
      //         widget._fileSource.removeWhere((v) => v.fileUrl == item.fileUrl);
      //         //如果
      //         if (widget._fileSource
      //                 .where((v) => v.fileRef1 == item.fileRef1)
      //                 .length ==
      //             0)
      //         //如果 KeyDir 裡沒有任何檔案時
      //         {
      //           widget._fileSourceByKeyCategory
      //               .removeWhere((v) => v.key == item.fileRef1);
      //         }
      //       });
      //     }

      //     if (widget._fileSource
      //             .where((v) => v.fileRef1 == item.fileRef1)
      //             .length ==
      //         0) {
      //       Directory(f.parent.path).deleteSync(recursive: true);
      //     }
      //   }
      //   //Upload Failure
      //   else {
      //     //print(result.getNGMessage());
      //     return false;
      //   }

      //   //如果資料來源 > 0 , 遞迴呼叫
      //   if (widget._fileSource.length > 0) {
      //     bool flag = await _uploadFile();
      //     if (flag == false) return false;
      //   } else {
      //     return true;
      //   }
      //   return true;
      // }
      // //沒有任何資料來源
      // else
      //   return true;
    }
  }
}
