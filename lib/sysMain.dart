import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'model/sysMenu.dart';

class SysMain extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _SysMain();
  }
}

class _SysMain extends State<SysMain> with TickerProviderStateMixin {
  AnimationController _animationController;

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );

    super.initState();
    portraitInit();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        appBar: AppBar(
          title: Text('首頁'),
        ),
        drawer: buildMenu(context),
        body: Container(
          child: Container(
            width: MediaQuery.of(context).size.width,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  '車輛管理系統',
                  style: TextStyle(fontSize: 24),
                ),
                //=============================
                MediaQuery.of(context).orientation == Orientation.portrait
                    ? Row(
                        children: <Widget>[
                          Container(
                              width: MediaQuery.of(context).size.width / 2,
                              padding: EdgeInsets.all(0),
                              child: Column(
                                children: <Widget>[
                                  Container(
                                    width:
                                        MediaQuery.of(context).size.width / 2,
                                    padding: EdgeInsets.only(top: 2),
                                    color: Color(0xff1d53aa),
                                    child: Text(
                                      '車輛及零配件物流中心',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.white54),
                                    ),
                                  ),
                                ],
                              )),
                          Container(
                              width: MediaQuery.of(context).size.width / 2,
                              padding: EdgeInsets.all(0),
                              child: Column(
                                children: <Widget>[
                                  Container(
                                    width:
                                        MediaQuery.of(context).size.width / 2,
                                    padding: EdgeInsets.only(top: 2),
                                    color: Color(0xff1d53aa),
                                    child: Text(
                                      '車輛及零配件物流中心',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.white54),
                                    ),
                                  ),
                                ],
                              )),
                        ],
                      )
                    : Container(),
                //=============================
                MediaQuery.of(context).orientation == Orientation.portrait
                    ? Row(
                        children: <Widget>[
                          Container(
                            width: MediaQuery.of(context).size.width / 3,
                            padding: EdgeInsets.all(0),
                            child: Column(
                              children: <Widget>[
                                Container(
                                  width: MediaQuery.of(context).size.width / 3,
                                  //color: Color(0xff1d53aa),
                                  child: Text(
                                    '自負港區物流中心',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                                Container(
                                  width: MediaQuery.of(context).size.width / 3,
                                  padding: EdgeInsets.only(top: 2),
                                  height: 20,
                                  color: Color(0xffe6e9ef),
                                  child: Text(
                                    '境內關外 前店後廠',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.black87, fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width / 3,
                            padding: EdgeInsets.all(0),
                            child: Column(
                              children: <Widget>[
                                Container(
                                  width: MediaQuery.of(context).size.width / 3,
                                  //color: Color(0xff1d53aa),
                                  child: Text(
                                    '汽車物流',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                                Container(
                                  width: MediaQuery.of(context).size.width / 3,
                                  padding: EdgeInsets.only(top: 2),
                                  height: 20,
                                  color: Color(0xffe6e9ef),
                                  child: Text(
                                    '商品車港區加值服務',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.black87, fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width / 3,
                            padding: EdgeInsets.all(0),
                            child: Column(
                              children: <Widget>[
                                Container(
                                  width: MediaQuery.of(context).size.width / 3,
                                  //color: Color(0xff1d53aa),
                                  child: Text(
                                    '港口作業',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                                Container(
                                  width: MediaQuery.of(context).size.width / 3,
                                  padding: EdgeInsets.only(top: 2),
                                  height: 20,
                                  color: Color(0xffe6e9ef),
                                  child: Text(
                                    '商品車進出口裝卸服務',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.black87, fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Container(),
                //=============================
              ],
            ),
          ),
        ),
      ),
      onWillPop: () {
        Navigator.pushNamedAndRemoveUntil(
            context, '/', (route) => route == null);
      },
    );
  }

  void portraitInit() async {
    await SystemChrome.setPreferredOrientations([]);
  }

  void portraitUp() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }
}
