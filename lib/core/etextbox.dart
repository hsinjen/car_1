import 'package:flutter/material.dart';

// ignore: must_be_immutable
class ETextBox extends StatelessWidget {
  String text;
  String emptyText;
  bool focus;
  double width;
  EdgeInsetsGeometry margin;
  EdgeInsetsGeometry padding;
  Function onClick;

  ETextBox(
      {Key key,
      String text,
      String emptyText,
      bool focus = false,
      double width,
      EdgeInsetsGeometry margin = const EdgeInsets.all(0),
      EdgeInsetsGeometry padding = const EdgeInsets.all(6),
      Function onClick})
      : super(key: key) {
    this.text = text;
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
        onClick();
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
          text == '' ? emptyText : text,
          style: TextStyle(color: text == '' ? Colors.grey : Colors.black),
        ),
      ),
    );
  }
}
