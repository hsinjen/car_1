import 'dart:io';
import 'package:flutter/material.dart';
import 'package:car_1/business/datagram.dart';
import 'package:car_1/business/responseresult.dart';
import 'package:car_1/business/business.dart';
import 'package:flutter/cupertino.dart';
import 'dart:convert';

class User {
  final String userId;
  final String userName;
  bool checked = false;

  User({this.userId, this.userName, bool checked = false}) {
    this.checked = checked;
  }
  Map toJson() => {'userId': userId, 'userName': userName};

  factory User.fromJson(Map<String, dynamic> parsedJson) {
    return User(
        userId: parsedJson['userId'],
        userName: parsedJson['userName'],
        checked: true);
  }
}

class UserListView extends StatefulWidget {
  final String action;
  final String title;
  final String userJson;
  final String deptId;
  final Function valueChanged;
  UserListView(this.action, this.title, this.userJson, this.valueChanged,
      {this.deptId = ''});

  @override
  _UserListViewState createState() => _UserListViewState();
}

class _UserListViewState extends State<UserListView> {
  List<User> userList = [];

  @override
  void initState() {
    super.initState();

    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Container(
            child: FlatButton(
              child: Text('OK',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              onPressed: () {
                widget.valueChanged(widget.action, toJson());
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(8.0),
        children: userList == null
            ? Container()
            : userList
                .map((usr) => CheckboxListTile(
                      title: Text(usr.userId + ' (' + usr.userName + ')'),
                      value: usr.checked,
                      onChanged: (val) {
                        setState(() {
                          usr.checked = usr.checked == true ? false : true;
                        });
                      },
                    ))
                .toList(),
      ),
    );
  }

  Future<void> _load() async {
    //  String test1 = jsonEncode(user1);
    //      print(test1);
    if (widget.userJson != '') {
      userList = (json.decode(widget.userJson) as List)
          .map((i) => User.fromJson(i))
          .toList();
    }
    Datagram datagram = Datagram();
    if (widget.deptId == '')
      datagram.addText("""select ixa00401,
                               ixa00403
                        from entirev4.dbo.ifx_a004 where ixa00400 = 'compid' 
                        """, rowIndex: 0, rowSize: 65535);
    else
      datagram.addText("""select ixa00401,
                               ixa00403
                        from entirev4.dbo.ifx_a004 where ixa00400 = 'compid' and ixa00408 = '${widget.deptId}'
                        """, rowIndex: 0, rowSize: 65535);
    ResponseResult result = await Business.apiExecuteDatagram(datagram);
    if (result.flag == ResultFlag.ok) {
      List<Map<String, dynamic>> data = result.getMap();
      if (data.length > 0) {
        for (int i = 0; i < data.length; i++) {
          userList.add(
              User(userId: data[i]['ixa00401'], userName: data[i]['ixa00403']));
        }
        setState(() {});
      }
    }
  }

  String toJson() {
    if (userList.length == 0) return '';
    if (userList.where((element) => element.checked == true).length == 0)
      return '';
    else
      return jsonEncode(
          userList.where((element) => element.checked == true).toList());
  }
}
