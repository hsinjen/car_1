import 'dart:io';
import 'package:flutter/material.dart';
import 'messagebox.dart';
import '../business/classes.dart';
import '../business/business.dart';

class ImageBrowser extends StatefulWidget {
  final FileSourceType imageSourceType;
  final List<FileItem> imageSource;
  final Function removeCallback;

  ImageBrowser(this.imageSourceType, this.imageSource, this.removeCallback);

  @override
  State<StatefulWidget> createState() {
    return _ImageBrowser();
  }
}

class _ImageBrowser extends State<ImageBrowser> {
  @override
  void initState() {
    Business.setImageScale = 50;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        //======================= App Bar Start
        appBar: new AppBar(
          title: new Text("圖片瀏覽器"),
        ),
        //======================= App Bar End
        body: widget.imageSourceType == FileSourceType.offline
            ?
            //===== Offline Start
            Container(
                child: ListView.builder(
                    itemCount: widget.imageSource == null
                        ? 0
                        : widget.imageSource.length,
                    itemBuilder: (BuildContext context, int index) {
                      if (index.isOdd) return Divider();

                      if (index + 1 < widget.imageSource.length)
                        return _buildImageTwoRow(
                            widget.imageSource[index].fileUrl,
                            widget.imageSource[index + 1].fileUrl);
                      else
                        return _buildImageTwoRow(
                            widget.imageSource[index].fileUrl, '');
                    }),
              )
            //===== Offline End
            :
            //===== Online Start
            //Container(child: Text('Online Not Plugin')),
            Container(
                child: ListView.builder(
                    itemCount: widget.imageSource == null
                        ? 0
                        : widget.imageSource.length,
                    itemBuilder: (BuildContext context, int index) {
                      if (index.isOdd) return Divider();

                      if (index + 1 < widget.imageSource.length)
                        return _buildImageTwoRow(
                            widget.imageSource[index].fileUrl,
                            widget.imageSource[index + 1].fileUrl);
                      else
                        return _buildImageTwoRow(
                            widget.imageSource[index].fileUrl, '');
                    }),
              )
        //===== Online End
        );
  }

  Widget _buildImageTwoRow(String leftImagePath, String rightImagePath) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        //========= Left Image Satrt
        GestureDetector(
          onLongPress: () {
            if (widget.imageSourceType == FileSourceType.offline) {
              MessageBox.showQuestion(context, '', '刪除圖片',
                  yesButtonText: '刪除', noButtonText: '放棄', yesFunc: () {
                File f = File(leftImagePath);
                if (f.existsSync() == true) {
                  f.deleteSync(recursive: true);
                  setState(() {
                    if (widget.imageSource.length > 1) {
                      widget.imageSource
                          .removeWhere((v) => v.fileUrl == leftImagePath);
                    } else {
                      widget.imageSource.clear();
                      Directory(f.parent.path).deleteSync(recursive: true);
                    }
                    widget.removeCallback(leftImagePath);
                    if (widget.imageSource.length == 0) {
                      Navigator.pop(context);
                    }
                  });
                }
              });
            }
          },
          child: Container(
            width: (MediaQuery.of(context).size.width - 15) / 2,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(2.0)),
              color: Colors.black,
            ),
            child: widget.imageSourceType == FileSourceType.offline
                ? Image.file(File(leftImagePath))
                : Image.network(
                    Business.remoteUrl + '/' + leftImagePath,
                    headers: Business.appTokenMap,
                  ),

            // CachedNetworkImage(
            //     imageUrl: Business.remoteUrl + '/' + leftImagePath,
            //     httpHeaders: Business.appTokenMap,
            //     placeholder: (context, url) =>
            //         new CircularProgressIndicator(
            //             valueColor: AlwaysStoppedAnimation(Colors.green)),
            //     errorWidget: (context, url, error) => new Icon(Icons.error),
            //   ),
            // Image.network(Business.remoteUrl + '/' + leftImagePath,
            //     headers: Business.appTokenMap)
          ),
        ),
        //========= Left Image End
        SizedBox(width: 5),
        rightImagePath == ''
            ? SizedBox(
                width: (MediaQuery.of(context).size.width - 15) / 2,
                height: 200)
            :
            //========= Right Image Satrt
            GestureDetector(
                onLongPress: () {
                  if (widget.imageSourceType == FileSourceType.offline) {
                    MessageBox.showQuestion(context, '', '刪除圖片',
                        yesButtonText: '刪除', noButtonText: '放棄', yesFunc: () {
                      File f = File(rightImagePath);
                      if (f.existsSync() == true) {
                        f.deleteSync(recursive: true);
                        setState(() {
                          widget.imageSource
                              .removeWhere((v) => v.fileUrl == rightImagePath);
                          widget.removeCallback(rightImagePath);
                        });
                      }
                    });
                  }
                },
                child: Container(
                  width: (MediaQuery.of(context).size.width - 15) / 2,
                  height: 200.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    color: Colors.black,
                  ),
                  child: widget.imageSourceType == FileSourceType.offline
                      ? Image.file(File(rightImagePath))
                      : Image.network(
                          Business.remoteUrl + '/' + rightImagePath,
                          headers: Business.appTokenMap,
                        ),
                  // CachedNetworkImage(
                  //     imageUrl: Business.remoteUrl + '/' + rightImagePath,
                  //     httpHeaders: Business.appTokenMap,
                  //     placeholder: (context, url) =>
                  //         new CircularProgressIndicator(
                  //             valueColor:
                  //                 AlwaysStoppedAnimation(Colors.green)),
                  //     errorWidget: (context, url, error) =>
                  //         new Icon(Icons.error),
                  //   ),

                  // Image.network(
                  //     Business.remoteUrl + '/' + rightImagePath,
                  //     headers: Business.appTokenMap)
                ),
              )
        //========= Right Image End
      ],
    );
  }
}
