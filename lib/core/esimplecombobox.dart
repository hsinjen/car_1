import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

// ignore: must_be_immutable
class ESimpleComboBox extends StatelessWidget {
  //final String displayMember;
  //final String valueMember;
  final Map<String, dynamic> dataSource;
  final String displayMember;
  final String valueMember;
  String value;
  String emptyText;
  bool focus;
  double width;
  EdgeInsetsGeometry margin;
  EdgeInsetsGeometry padding;
  Function(dynamic value) onClick;

  ESimpleComboBox(this.dataSource, this.displayMember, this.valueMember,
      {Key key,
      String value,
      String emptyText,
      bool focus = false,
      double width,
      EdgeInsetsGeometry margin = const EdgeInsets.all(0),
      EdgeInsetsGeometry padding = const EdgeInsets.all(6),
      Function(dynamic value) onClick})
      : super(key: key) {
    this.value = value;
    this.emptyText = emptyText;
    this.focus = focus;
    this.width = width;
    this.margin = margin;
    this.padding = padding;
    this.onClick = onClick;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showComboBox(context);
      },
      child: Container(
        width: width,
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          border: Border.all(
              color: focus == true ? Colors.orangeAccent : Colors.black,
              width: 1.0),
          borderRadius: BorderRadius.all(Radius.circular(4.0)),
        ),
        child: Text(
          value == '' ? emptyText : _getText(),
          style: TextStyle(color: value == '' ? Colors.grey : Colors.black),
        ),
      ),
    );
  }

  void showComboBox(BuildContext context) {
    SimpleDialog dialog = SimpleDialog(
      title: Text('伺服器列表'),
      children: this.dataSource == null
          ? []
          : this.dataSource.entries.map((entry) {
              return SimpleDialogItem(
                icon: MdiIcons.desktopMac,
                color: Colors.blueAccent,
                text: entry.value,
                onPressed: () {
                  this.value = entry.key.toString();
                  onClick(this.value);
                  Navigator.pop(context);
                },
              );
            }).toList(),
    );
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => dialog,
    );
  }

  String _getText() {
    if (dataSource == null) return '';
    if (value == '') return '';
    if (dataSource.containsKey(value))
      return dataSource[value].toString();
    else
      return '';
  }
}

class SimpleDialogItem extends StatelessWidget {
  const SimpleDialogItem(
      {Key key, this.icon, this.color, this.text, this.onPressed})
      : super(key: key);

  final IconData icon;
  final Color color;
  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SimpleDialogOption(
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 36.0, color: color),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 12.0),
            child: Text(text),
          ),
        ],
      ),
    );
  }
}
