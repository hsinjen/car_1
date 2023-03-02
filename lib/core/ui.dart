import 'package:flutter/material.dart';
import 'esimplecombobox.dart';
import 'epasswordbox.dart';
import 'etextbox.dart';
import 'package:intl/intl.dart';

void showDatePickerEx(BuildContext context, String actionName,
    Function(String, String) onValueChanged,
    {DateTime defaultDate, DateTime minimumDate, DateTime maximumDate}) {
  DateTime p1 = defaultDate == null ? DateTime.now() : defaultDate;
  DateTime p2 = minimumDate == null
      ? DateTime.now().add(Duration(days: -180))
      : minimumDate;
  DateTime p3 = maximumDate == null
      ? DateTime.now().add(Duration(days: 180))
      : maximumDate;

  showDatePicker(context: context, initialDate: p1, firstDate: p2, lastDate: p3)
      .then((value) {
    String formattedDate = '';
    if (value != null) formattedDate = DateFormat('yyyy/MM/dd').format(value);
    if (actionName != '' && onValueChanged != null)
      onValueChanged(actionName, formattedDate);
  });
}

Widget iconTextBox(String text, IconData icon,
    {String emptyText = '',
    bool focus = false,
    double width,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.center,
    EdgeInsetsGeometry margin = const EdgeInsets.all(0),
    EdgeInsetsGeometry padding = const EdgeInsets.all(6),
    Function onClick,
    Function onIconClick}) {
  return Container(
    child: Row(
      mainAxisAlignment: mainAxisAlignment,
      children: [
        GestureDetector(
          onTap: onIconClick,
          child: Container(
            margin: EdgeInsets.only(right: 5),
            child: Icon(icon),
          ),
        ),
        ETextBox(
            text: text,
            emptyText: emptyText,
            focus: focus,
            width: width,
            margin: margin,
            padding: padding,
            onClick: onClick),
      ],
    ),
  );
}

Widget iconPasswordBox(String text, IconData icon,
    {String emptyText = '',
    bool focus = false,
    double width,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.center,
    EdgeInsetsGeometry margin = const EdgeInsets.all(0),
    EdgeInsetsGeometry padding = const EdgeInsets.all(6),
    Function onClick,
    Function onIconClick}) {
  return Container(
    child: Row(
      mainAxisAlignment: mainAxisAlignment,
      children: [
        GestureDetector(
          onTap: onIconClick,
          child: Container(
            margin: EdgeInsets.only(right: 5),
            child: Icon(icon),
          ),
        ),
        EPasswordBox(
            text: text,
            emptyText: emptyText,
            focus: focus,
            width: width,
            margin: margin,
            padding: padding,
            onClick: onClick),
      ],
    ),
  );
}

Widget iconSimpleComboBox(Map<String, dynamic> dataSource, String valueMember,
    String displayMember, String value, IconData icon,
    {String emptyText,
    bool focus,
    double width,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.center,
    EdgeInsetsGeometry margin = const EdgeInsets.all(0),
    EdgeInsetsGeometry padding = const EdgeInsets.all(6),
    Function(dynamic value) onClick,
    Function onIconClick}) {
  return Container(
    child: Row(
      mainAxisAlignment: mainAxisAlignment,
      children: [
        GestureDetector(
          onTap: onIconClick,
          child: Container(
            margin: EdgeInsets.only(right: 5),
            child: Icon(icon),
          ),
        ),
        ESimpleComboBox(dataSource, valueMember, displayMember,
            value: value,
            emptyText: emptyText,
            focus: focus,
            width: width,
            margin: margin,
            padding: padding,
            onClick: onClick),
      ],
    ),
  );
}

Widget labelTextBox(String labelText, String text,
    {String emptyText = '',
    bool focus = false,
    double lableWidth = 100,
    double width,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.center,
    EdgeInsetsGeometry margin = const EdgeInsets.all(0),
    EdgeInsetsGeometry padding = const EdgeInsets.all(6),
    Function onClick}) {
  return Container(
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: mainAxisAlignment,
        children: [
          Container(
            width: lableWidth,
            alignment: Alignment.centerRight,
            margin: EdgeInsets.only(right: 10),
            child: Text(labelText),
          ),
          ETextBox(
              text: text,
              emptyText: emptyText,
              focus: focus,
              width: width,
              margin: margin,
              padding: padding,
              onClick: onClick),
        ],
      ),
    ),
  );
}

Widget labelPasswordBox(String labelText, String text,
    {String emptyText = '',
    bool focus = false,
    double lableWidth = 100,
    double width,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.center,
    EdgeInsetsGeometry margin = const EdgeInsets.all(0),
    EdgeInsetsGeometry padding = const EdgeInsets.all(6),
    Function onClick}) {
  return Container(
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: mainAxisAlignment,
        children: [
          Container(
            width: lableWidth,
            alignment: Alignment.centerRight,
            margin: EdgeInsets.only(right: 10),
            child: Text(labelText),
          ),
          EPasswordBox(
              text: text,
              emptyText: emptyText,
              focus: focus,
              width: width,
              margin: margin,
              padding: padding,
              onClick: onClick),
        ],
      ),
    ),
  );
}

Widget labelSimpleComboBox(String labelText, Map<String, dynamic> dataSource,
    String valueMember, String displayMember, String value,
    {String emptyText,
    bool focus,
    double lableWidth = 100,
    double width,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.center,
    EdgeInsetsGeometry margin = const EdgeInsets.all(0),
    EdgeInsetsGeometry padding = const EdgeInsets.all(6),
    Function(dynamic value) onClick}) {
  return Container(
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: mainAxisAlignment,
        children: [
          Container(
            width: lableWidth,
            alignment: Alignment.centerRight,
            margin: EdgeInsets.only(right: 10),
            child: Text(labelText),
          ),
          ESimpleComboBox(dataSource, valueMember, displayMember,
              value: value,
              emptyText: emptyText,
              focus: focus,
              width: width,
              margin: margin,
              padding: padding,
              onClick: onClick),
        ],
      ),
    ),
  );
}

Widget circleButton(
    IconData icon, Color color, Color splashColor, Function onClick,
    {Alignment alignment = Alignment.center, double size = 56}) {
  return Container(
      alignment: alignment,
      child: ClipOval(
        child: Material(
          color: color, // button color
          child: InkWell(
            splashColor: splashColor, // inkwell color
            child: SizedBox(width: size, height: size, child: Icon(icon)),
            onTap: onClick,
          ),
        ),
      ));
}

Widget rectangleButton(
  String text,
  Function onClick, {
  Color color = Colors.blueAccent,
  Color textColor = Colors.white,
  Alignment alignment = Alignment.center,
}) {
  return Container(
      alignment: alignment,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: RaisedButton(
          color: color,
          textColor: textColor,
          onPressed: onClick,
          child: Text(text),
        ),
      ));
}
