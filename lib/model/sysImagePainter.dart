import 'dart:io';
import 'dart:ui' as ui;
import 'package:car_1/business/business.dart';
import 'package:car_1/business/datagram.dart';
import 'package:car_1/business/responseresult.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';
import 'package:camera/camera.dart';
import '../model/sysCamera.dart';

//=========
class PointItem {
  final String id;
  final String type;
  final Offset location;
  final String place;
  final String error;
  final double zoomWidthPerc;
  final double zoomHeightPerc;
  final List<ImageItem> imageList;
  Offset displayLocation(BuildContext context) {
    double pW = MediaQuery.of(context).size.width / 1000.0;
    double pH = MediaQuery.of(context).size.height / 500.0;

    return Offset(this.location.dx, this.location.dy);
  }

  PointItem(
      {this.id,
      this.type,
      this.location,
      this.place,
      this.error,
      this.zoomWidthPerc,
      this.zoomHeightPerc,
      this.imageList}) {
    // displayLocation = Offset(
    //     this.location.dx * zoomWidthPerc, this.location.dy * zoomHeightPerc);
  }

  Map toJson() => {
        'id': id,
        'type': type,
        'locationX': location.dx,
        'locationY': location.dy,
        'place': place,
        'error': error,
        'zoomWidthPerc': zoomWidthPerc,
        'zoomHeightPerc': zoomHeightPerc
      };

  factory PointItem.fromJson(Map<String, dynamic> parsedJson) {
    return PointItem(
        id: parsedJson['id'],
        type: parsedJson['type'],
        location: Offset(parsedJson['locationX'], parsedJson['locationY']),
        place: parsedJson['place'],
        error: parsedJson['error'],
        zoomWidthPerc: parsedJson['zoomWidthPerc'],
        zoomHeightPerc: parsedJson['zoomHeightPerc']);
  }
}

class ImagePainter extends CustomPainter {
  final BuildContext context;
  final String type;
  final List<PointItem> points;
  final ui.Image image;
  final double scale;

  ImagePainter(this.context,
      {this.type, this.image, this.points, this.scale = 1});

  @override
  void paint(Canvas canvas, Size size) {
    if (image != null) {
      Offset imageSize =
          Offset(image.width.toDouble(), image.height.toDouble());
      Paint paint = new Paint()..color = Colors.green;
      // canvas.drawCircle(size.center(Offset.zero), 20.0, paint);

      // print(size);
      //canvas.save();
      var scale1 = size.width / image.width;
      canvas.scale(scale);
      // canvas.translate(image.width/2 * scale, image.height/2 * scale);
      // canvas.rotate(45 * PI /180);
      // canvas.translate(- image.width /2/ scale, - image.height/2/scale);
      canvas.drawImage(image, Offset.zero, paint);

      // Rect imageRect = Rect.fromPoints(Offset(0.0, 0.0), Offset(1000.0, 500.0));
      // Rect screenRect =
      //     Rect.fromPoints(Offset(0.0, 0.0), Offset(size.width, size.height));
      // canvas.drawImageRect(image, imageRect, screenRect, new Paint());
    }

    points.forEach((point) {
      if (type == '全部') {
        drawPoint(canvas, point);
        //canvas.drawCircle(point, radius, paint);
        drawString(canvas, size, point);
      } else if (point.type == type) {
        drawPoint(canvas, point);
        //canvas.drawCircle(point, radius, paint);
        drawString(canvas, size, point);
      }
    });
  }

  void drawString(Canvas canvas, Size size, PointItem point) {
    final textStyle = TextStyle(
      color: Colors.deepOrangeAccent,
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
    final textSpan = TextSpan(
      text: point.place + ' ' + point.error,
      style: textStyle,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(
      minWidth: 0,
      maxWidth: size.width,
    );
    final offset = Offset(point.displayLocation(context).dx + 8,
        point.displayLocation(context).dy - 12);
    textPainter.paint(canvas, offset);
  }

  void drawCenterPoint(Canvas canvas, Size size) {
    var paint = Paint()..color = Colors.deepOrangeAccent;
    paint.strokeWidth = 3;
    canvas.drawLine(Offset(size.width / 2 - 5, size.height / 2 - 5),
        Offset(size.width / 2 + 5, size.height / 2 + 5), paint);

    canvas.drawLine(Offset(size.width / 2 + 5, size.height / 2 - 5),
        Offset(size.width / 2 - 5, size.height / 2 + 5), paint);
  }

  void drawPoint(Canvas canvas, PointItem point) {
    var paint = Paint()..color = Colors.deepOrangeAccent;

    paint.strokeWidth = 3;

    canvas.drawLine(Offset(point.location.dx - 5, point.location.dy - 5),
        Offset(point.location.dx + 5, point.location.dy + 5), paint);

    canvas.drawLine(Offset(point.location.dx + 5, point.location.dy - 5),
        Offset(point.location.dx - 5, point.location.dy + 5), paint);
  }

  @override
  bool shouldRepaint(ImagePainter other) =>
      //points.length != other.points.length;
      true;
}

class ImageEditor extends StatefulWidget {
  final String type;
  final List<PointItem> points;

  ImageEditor({Key key, this.type, this.points}) : super(key: key);

  @override
  _ImageEditorState createState() => _ImageEditorState();
}

class _ImageEditorState extends State<ImageEditor> {
  GlobalKey<ScaffoldState> _drawerKey = GlobalKey();
  ui.Image image;
  bool isImageloaded = false;
  List<Map<String, dynamic>> _vinSpec;
  List<Map<String, dynamic>> _vinIssue;
  String _currentPlace = '';
  String _currentError = '';
  List<CameraDescription> cameras;

  void initState() {
    super.initState();
    // SystemChrome.setPreferredOrientations([
    //   DeviceOrientation.landscapeLeft,
    // ]);
    init();
    _loadVinPlace();
    _loadVinError();
  }

  @override
  void dispose() {
    super.dispose();
    SystemChrome.setPreferredOrientations([]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _drawerKey,
      appBar: AppBar(
        centerTitle: true,
        title: Row(children: [
          GestureDetector(
            onTapDown: (v) {
              _drawerKey.currentState.openDrawer();
            },
            child: Container(
                child: Text(_currentPlace == '' ? '請選擇部位' : _currentPlace)),
          ),
          Expanded(
              child: Text('${widget.type}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.lightGreenAccent[200],
                      fontWeight: FontWeight.bold))),
          GestureDetector(
            onTapDown: (v) {
              _drawerKey.currentState.openEndDrawer();
            },
            child: Container(
                child: Text(_currentError == '' ? '請選擇異常原因' : _currentError)),
          ),
        ]),
      ),
      drawer: _vinSpec == null ? null : buildVinPlace(context),
      endDrawer: _vinIssue == null ? null : buildVinError(context),
      body: isImageloaded == false
          ? Container(child: Text('Loading'))
          : GestureDetector(
              child: CustomPaint(
                size: Size(
                    image.width *
                        (MediaQuery.of(context).size.width / image.width),
                    image.height *
                        (MediaQuery.of(context).size.width / image.width)),
                painter: ImagePainter(context,
                    type: widget.type,
                    image: image,
                    points: widget.points,
                    scale: MediaQuery.of(context).size.width / image.width),
              ),
              onLongPress: () {
                showDialog(
                    context: context,
                    builder: (context) {
                      return StatefulBuilder(builder: (context, setState) {
                        return new AlertDialog(
                          title: Container(
                            //color: Colors.black,
                            child: Text("點位維護",
                                style: TextStyle(
                                    // color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                          content: Container(
                            height: MediaQuery.of(context).size.height,
                            width:
                                MediaQuery.of(context).size.width / 100.0 * 50,
                            child: ListView.builder(
                              itemBuilder: (BuildContext context, int index) =>
                                  Card(
                                child: ListTile(
                                    contentPadding: const EdgeInsets.all(0.0),
                                    leading: Container(
                                      child: IconButton(
                                        icon: Icon(Icons.cancel,
                                            color: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            widget.points.removeWhere(
                                                (element) =>
                                                    element.id ==
                                                    widget.points[index].id);
                                          });
                                        },
                                      ),
                                    ),
                                    title: Row(children: [
                                      Container(
                                        width:
                                            MediaQuery.of(context).size.width /
                                                100.0 *
                                                5,
                                        child: Text(
                                          (index + 1)
                                              .toString()
                                              .padLeft(3, '0'),
                                          style: TextStyle(
                                              fontSize: 18.0,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          widget.points[index].place,
                                          style: TextStyle(
                                              fontSize: 16.0,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          widget.points[index].error,
                                          style: TextStyle(
                                              fontSize: 16.0,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ])),
                              ),
                              itemCount: widget.points.length,
                            ),
                          ),
                          actions: <Widget>[
                            new FlatButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: new Text("取消"),
                            ),
                          ],
                        );
                      });
                    }).then((value) {
                  setState(() {});
                });
              },
              onPanDown: (details) async {
                if (_currentPlace == '' || _currentError == '') return;
                double pScale = MediaQuery.of(context).size.width / 1000.0;

                if (cameras == null) cameras = await availableCameras();
                if (cameras != null) {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CameraWindow(
                          cameraType: CameraType.camera,
                          cameraList: cameras,
                          imageDirPath: 'PDIVision',
                          imageList: [],
                          keyNo: 'PDIVision',
                          groupKey: 'PDIVision',
                          tag2: _currentPlace + '-' + _currentError,
                          onConfirm: (v) {
                            //
                            setState(() {
                              widget.points.add(PointItem(
                                  id: Uuid().v4(),
                                  type: widget.type,
                                  location: Offset(
                                      details.localPosition.dx / pScale,
                                      details.localPosition.dy / pScale),
                                  place: _currentPlace,
                                  error: _currentError,
                                  zoomWidthPerc: pScale,
                                  zoomHeightPerc: pScale,
                                  imageList: v));
                              _currentError = '';
                            });
                          },
                          onCancel: () {
                            //
                          },
                        ),
                      ));
                }
              },
            ),
    );
  }

  Widget buildVinPlace(BuildContext context) {
    return Drawer(
      child: Column(children: [
        SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height,
            child: ListView.builder(
              itemBuilder: (BuildContext context, int index) => Container(
                color: _vinSpec[index]['vs004901'] == '無'
                    ? Colors.orange
                    : Colors.grey[300],
                child: ListTile(
                    contentPadding: const EdgeInsets.all(3.0),
                    //leading: Icon(Icons.home),
                    title: Container(
                      padding: EdgeInsets.only(left: 10),
                      child: Text(
                        _vinSpec[index]['vs004901'] == '無'
                            ? '${widget.type}部位'
                            : _vinSpec[index]['vs004901'],
                        style: TextStyle(
                            fontSize: 18.0, fontWeight: FontWeight.bold),
                      ),
                    ),
                    onTap: () {
                      if (index > 0) {
                        setState(() {
                          _currentPlace = _vinSpec[index]['vs004901'];
                        });
                        Navigator.pop(context);
                      }
                    }),
              ),
              itemCount: _vinSpec.length,
            ),
          ),
        )
      ]),
    );
  }

  Widget buildVinError(BuildContext context) {
    return Drawer(
      child: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          child: ListView.builder(
            itemBuilder: (BuildContext context, int index) => Container(
              color: _vinIssue[index]['vs005001'] == '無'
                  ? Colors.orange
                  : Colors.grey[300],
              child: ListTile(
                  contentPadding: const EdgeInsets.all(3.0),
                  //leading: Icon(Icons.home),
                  title: Container(
                    padding: EdgeInsets.only(left: 10),
                    child: Text(
                      _vinIssue[index]['vs005001'] == '無'
                          ? '異常原因'
                          : _vinIssue[index]['vs005001'],
                      style: TextStyle(
                          fontSize: 18.0, fontWeight: FontWeight.bold),
                    ),
                  ),
                  onTap: () {
                    if (index > 0) {
                      setState(() {
                        _currentError = _vinIssue[index]['vs005001'];
                      });
                      Navigator.pop(context);
                    }
                  }),
            ),
            itemCount: _vinIssue.length,
          ),
        ),
      ),
    );
  }

  Future<Null> _loadVinPlace() async {
    Datagram datagram = Datagram();
    datagram.addText(
        """select vs004900,vs004901 from xvms_0049 where vs004902 = '' or
                                                                       charindex(vs004902,'${widget.type}') >0
                        """,
        rowIndex: 0, rowSize: 65535);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      if (data.length > 0) {
        setState(() {
          _vinSpec = data;
        });
      }
    }
  }

  Future<Null> _loadVinError() async {
    Datagram datagram = Datagram();
    datagram.addText("""select vs005000,vs005001 from xvms_0050
                        """, rowIndex: 0, rowSize: 65535);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      if (data.length > 0) {
        setState(() {
          _vinIssue = data;
        });
      }
    }
  }

  Future<Null> init() async {
    final ByteData data = await rootBundle.load('assets/images/vin.jpg');
    image = await loadImage(new Uint8List.view(data.buffer));
  }

  Future<ui.Image> loadImage(List<int> img) async {
    final Completer<ui.Image> completer = new Completer();
    ui.decodeImageFromList(img, (ui.Image img) {
      setState(() {
        isImageloaded = true;
      });
      return completer.complete(img);
    });
    return completer.future;
  }
}
