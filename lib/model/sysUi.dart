import 'package:flutter/material.dart';

/*
   One Row
*/
Widget buildHeaderOneRow(BuildContext context, String header1, double width1) {
  return Row(children: [
    Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        border: Border(
            left: BorderSide(width: 1),
            top: BorderSide(width: 1),
            right: BorderSide(width: 1)),
      ),
      alignment: Alignment.center,
      width: MediaQuery.of(context).size.width / 100 * width1,
      child: Text(header1,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    ),
  ]);
}

Widget buildDataOneRow(BuildContext context, String value1, double width1,
    {bool endRow = false}) {
  return Row(children: [
    Container(
      decoration: BoxDecoration(
        border: Border(
            left: BorderSide(width: 1),
            top: BorderSide(width: 1),
            right: BorderSide(width: 1),
            bottom: BorderSide(width: 1)),
      ),
      alignment: Alignment.center,
      width: MediaQuery.of(context).size.width / 100 * width1,
      height: 24.0,
      child: Text(value1),
    ),
  ]);
}

/*
   Two Row
*/
Widget buildHeaderTwoRow(BuildContext context, String header1, double width1,
    String header2, double width2) {
  return Row(children: [
    Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        border: Border(
            left: BorderSide(width: 1),
            top: BorderSide(width: 1),
            right: BorderSide(width: 1)),
      ),
      alignment: Alignment.center,
      width: MediaQuery.of(context).size.width / 100 * width1,
      child: Text(header1,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    ),
    Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        border: Border(top: BorderSide(width: 1), right: BorderSide(width: 1)),
      ),
      alignment: Alignment.center,
      width: MediaQuery.of(context).size.width / 100 * width2,
      child: Text(header2,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    ),
  ]);
}

Widget buildDataTwoRow(BuildContext context, String value1, double width1,
    String value2, double width2) {
  return Row(children: [
    Container(
      decoration: BoxDecoration(
        border: Border(
            left: BorderSide(width: 1),
            top: BorderSide(width: 1),
            right: BorderSide(width: 1),
            bottom: BorderSide(width: 1)),
      ),
      alignment: Alignment.center,
      width: MediaQuery.of(context).size.width / 100 * width1,
      height: 24.0,
      child: Text(value1, style: TextStyle(fontSize: 12)),
    ),
    Container(
      decoration: BoxDecoration(
        border: Border(
            top: BorderSide(width: 1),
            right: BorderSide(width: 1),
            bottom: BorderSide(width: 1)),
      ),
      alignment: Alignment.center,
      width: MediaQuery.of(context).size.width / 100 * width2,
      height: 24.0,
      child: Text(value2, style: TextStyle(fontSize: 12)),
    ),
  ]);
}

Widget buildDataTwoRowWithContainer(
    BuildContext context, String value1, double width1, Container container2) {
  return Row(children: [
    Container(
      decoration: BoxDecoration(
        border: Border(
            left: BorderSide(width: 1),
            top: BorderSide(width: 1),
            right: BorderSide(width: 1),
            bottom: BorderSide(width: 1)),
      ),
      alignment: Alignment.center,
      height: 24.0,
      width: MediaQuery.of(context).size.width / 100 * width1,
      child: Text(value1),
    ),
    container2
  ]);
}

/*
   Three Row
*/
Widget buildHeaderThreeRow(BuildContext context, String header1, double width1,
    String header2, double width2, String header3, double width3) {
  return Row(children: [
    Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        border: Border(
            left: BorderSide(width: 1),
            top: BorderSide(width: 1),
            right: BorderSide(width: 1)),
      ),
      alignment: Alignment.center,
      width: MediaQuery.of(context).size.width / 100 * width1,
      child: Text(header1,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    ),
    Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        border: Border(top: BorderSide(width: 1), right: BorderSide(width: 1)),
      ),
      alignment: Alignment.center,
      width: MediaQuery.of(context).size.width / 100 * width2,
      child: Text(header2,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    ),
    Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        border: Border(top: BorderSide(width: 1), right: BorderSide(width: 1)),
      ),
      alignment: Alignment.center,
      width: MediaQuery.of(context).size.width / 100 * width3,
      child: Text(header3,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    ),
  ]);
}

Widget buildDataThreeRow(BuildContext context, String value1, double width1,
    String value2, double width2, String value3, double width3) {
  return Row(children: [
    Container(
      decoration: BoxDecoration(
        border: Border(
            left: BorderSide(width: 1),
            top: BorderSide(width: 1),
            right: BorderSide(width: 1)),
      ),
      alignment: Alignment.center,
      width: MediaQuery.of(context).size.width / 100 * width1,
      height: 24.0,
      child: Text(value1, style: TextStyle(fontSize: 12)),
    ),
    Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(width: 1), right: BorderSide(width: 1)),
      ),
      alignment: Alignment.center,
      width: MediaQuery.of(context).size.width / 100 * width2,
      height: 24.0,
      child: Text(value2, style: TextStyle(fontSize: 12)),
    ),
    Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(width: 1), right: BorderSide(width: 1)),
      ),
      alignment: Alignment.center,
      width: MediaQuery.of(context).size.width / 100 * width3,
      height: 24.0,
      child: Text(value3, style: TextStyle(fontSize: 12)),
    ),
  ]);
}

Widget buildGridViewHeaderThreeRow(
    BuildContext context,
    String header1,
    double width1,
    String header2,
    double width2,
    String header3,
    double width3) {
  return Row(children: [
    Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        border: Border(
            left: BorderSide(width: 1),
            top: BorderSide(width: 1),
            right: BorderSide(width: 1)),
      ),
      alignment: Alignment.center,
      width: MediaQuery.of(context).size.width / 100 * width1,
      child: Text(header1),
    ),
    Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        border: Border(top: BorderSide(width: 1), right: BorderSide(width: 1)),
      ),
      alignment: Alignment.center,
      width: MediaQuery.of(context).size.width / 100 * width2,
      child: Text(header2),
    ),
    Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        border: Border(top: BorderSide(width: 1), right: BorderSide(width: 1)),
      ),
      alignment: Alignment.center,
      width: MediaQuery.of(context).size.width / 100 * width3,
      child: Text(header3),
    ),
  ]);
}

/*
   Four Row
*/
Widget buildHeaderFourRow(
    BuildContext context,
    String header1,
    double width1,
    String header2,
    double width2,
    String header3,
    double width3,
    String header4,
    double width4) {
  return Row(children: [
    Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        border: Border(
            left: BorderSide(width: 1),
            top: BorderSide(width: 1),
            right: BorderSide(width: 1)),
      ),
      alignment: Alignment.center,
      width: MediaQuery.of(context).size.width / 100 * width1,
      child: Text(header1,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    ),
    Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        border: Border(top: BorderSide(width: 1), right: BorderSide(width: 1)),
      ),
      alignment: Alignment.center,
      width: MediaQuery.of(context).size.width / 100 * width2,
      child: Text(header2,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    ),
    Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        border: Border(top: BorderSide(width: 1), right: BorderSide(width: 1)),
      ),
      alignment: Alignment.center,
      width: MediaQuery.of(context).size.width / 100 * width3,
      child: Text(header3,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    ),
    Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        border: Border(top: BorderSide(width: 1), right: BorderSide(width: 1)),
      ),
      alignment: Alignment.center,
      width: MediaQuery.of(context).size.width / 100 * width4,
      child: Text(header4,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    ),
  ]);
}
