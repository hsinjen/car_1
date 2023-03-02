import 'package:flutter/material.dart';

class TVS0109999 extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _TVS0109999();
  }
}

class _TVS0109999 extends State<TVS0109999> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('字體大小展示'),
      ),
      body: Scrollbar(
        child: ListView(
          padding: EdgeInsets.all(20.0),
          children: [
            Row(
              children: <Widget>[
                Text('Size:12 '),
                Text(
                  '公司全名',
                  style: TextStyle(fontSize: 12.0),
                ),
              ],
            ),
            SizedBox(
              height: 10,
            ),
            Row(
              children: <Widget>[
                Text('Size:14 '),
                Text(
                  '公司全名',
                  style: TextStyle(fontSize: 14.0),
                ),
              ],
            ),
            SizedBox(
              height: 10,
            ),
            Row(
              children: <Widget>[
                Text('Size:16 '),
                Text(
                  '公司全名',
                  style: TextStyle(fontSize: 16.0),
                ),
              ],
            ),
            SizedBox(
              height: 10,
            ),
            Row(
              children: <Widget>[
                Text('Size:18 '),
                Text(
                  '公司全名',
                  style: TextStyle(fontSize: 18.0),
                ),
              ],
            ),
            SizedBox(
              height: 10,
            ),
            Row(
              children: <Widget>[
                Text('Size:20 '),
                Text(
                  '公司全名',
                  style: TextStyle(fontSize: 20.0),
                ),
              ],
            ),
            SizedBox(
              height: 10,
            ),
            Row(
              children: <Widget>[
                Text('Size:22 '),
                Text(
                  '公司全名',
                  style: TextStyle(fontSize: 22.0),
                ),
              ],
            ),
            SizedBox(
              height: 10,
            ),
            Row(
              children: <Widget>[
                Text('Size:24 '),
                Text(
                  '公司全名',
                  style: TextStyle(fontSize: 24.0),
                ),
              ],
            ),
            SizedBox(
              height: 10,
            ),
            Row(
              children: <Widget>[
                Text('Size:26 '),
                Text(
                  '公司全名',
                  style: TextStyle(fontSize: 26.0),
                ),
              ],
            ),
            SizedBox(
              height: 10,
            ),
            Row(
              children: <Widget>[
                Text('Size:28 '),
                Text(
                  '公司全名',
                  style: TextStyle(fontSize: 28.0),
                ),
              ],
            ),
            SizedBox(
              height: 10,
            ),
            Row(
              children: <Widget>[
                Text('Size:30 '),
                Text(
                  '公司全名',
                  style: TextStyle(fontSize: 30.0),
                ),
              ],
            ),
            SizedBox(
              height: 40,
            ),
            Row(
              children: <Widget>[
                Text('Size:32 '),
                Text(
                  '公司全名',
                  style: TextStyle(fontSize: 32.0),
                ),
              ],
            ),
            //=========
          ],
        ),
      ),
      resizeToAvoidBottomInset: false,
    );
  }
}
