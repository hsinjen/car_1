import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/cupertino.dart';

class Utility {
  static void showFullScreenDialog(BuildContext context, Widget widget) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => WillPopScope(
          onWillPop: () async => false,
          child: widget,
        ),
        fullscreenDialog: true,
      ),
    );
  }
}

//==================================================================
class DialogBox {
  static void showFullScreenDialog(BuildContext context, Widget widget) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => WillPopScope(
          onWillPop: () async => false,
          child: widget,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  static Future<String> showText(BuildContext context, String title,
      {String content,
      String button1Text,
      String button2Text,
      int maxLines,
      int maxTextLength,
      Color titleBackColor,
      Color titleForeColor}) {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => WillPopScope(
              onWillPop: () async => false,
              child: TextDialogBox(
                context,
                title,
                content: content,
                button1Text: button1Text,
                button2Text: button2Text,
                maxLines: maxLines,
                maxTextLength: maxTextLength,
                titleBackColor: titleBackColor,
                titleForeColor: titleForeColor,
              ),
            ));
  }

  static Future<DialogResult> show(BuildContext context, DialogType type,
      {String title,
      String content,
      String button1Text,
      String button2Text,
      String titleImage}) {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => WillPopScope(
              onWillPop: () async => false,
              child: MessageDialogBox(
                context,
                title: title ?? "",
                content: content ?? "",
                type: DialogType.success,
                button1Text: button1Text,
                button2Text: button2Text,
                titleImg: titleImage,
              ),
            ));
  }

  static Future<DialogResult> showSuccess(BuildContext context, String content,
      {String title, String buttonText}) {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => WillPopScope(
              onWillPop: () async => false,
              child: MessageDialogBox(
                context,
                title: title ?? "",
                content: content ?? "",
                type: DialogType.success,
                button1Text: buttonText,
              ),
            ));
  }

  static Future<DialogResult> showError(BuildContext context, String content,
      {String title, String buttonText}) {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => WillPopScope(
              onWillPop: () async => false,
              child: MessageDialogBox(
                context,
                title: title ?? "",
                content: content ?? "",
                type: DialogType.error,
                button1Text: buttonText,
              ),
            ));
  }

  static Future<DialogResult> showInfo(BuildContext context, String content,
      {String title, String buttonText}) {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => WillPopScope(
              onWillPop: () async => false,
              child: MessageDialogBox(
                context,
                title: title ?? "",
                content: content ?? "",
                type: DialogType.information,
                button1Text: buttonText,
              ),
            ));
  }

  static Future<DialogResult> showWarning(BuildContext context, String content,
      {String title, String buttonText}) {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => WillPopScope(
              onWillPop: () async => false,
              child: MessageDialogBox(
                context,
                title: title ?? "",
                content: content ?? "",
                type: DialogType.warning,
                button1Text: buttonText,
              ),
            ));
  }

  static Future<DialogResult> showQuestion(BuildContext context, String content,
      {String title, String button1Text, String button2Text}) {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => WillPopScope(
              onWillPop: () async => false,
              child: MessageDialogBox(
                context,
                title: title ?? "",
                content: content ?? "",
                type: DialogType.question,
                button1Text: button1Text,
                button2Text: button2Text,
              ),
            ));
  }
}

// ignore: must_be_immutable
class TextDialogBox extends StatefulWidget {
  final BuildContext context;
  final String title, content, button1Text, button2Text;
  final Color titleBackColor;
  final Color titleForeColor;
  final int maxLines;
  final int maxTextLength;
  final bool multiLines;

  var _textController;
  var _focusNode = FocusNode();

  TextDialogBox(this.context, this.title,
      {Key key,
      this.content,
      this.button1Text,
      this.button2Text,
      this.titleBackColor,
      this.titleForeColor,
      this.multiLines,
      this.maxLines,
      this.maxTextLength})
      : super(key: key) {
    _textController = new TextEditingController(text: '');
  }

  @override
  _TextDialogBoxState createState() => _TextDialogBoxState();
}

class _TextDialogBoxState extends State<TextDialogBox> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: contentBox(context),
    );
  }

  contentBox(context) {
    return Stack(
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(left: 0, top: 0, right: 0, bottom: 0),
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              //=================================== Title
              Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  color: widget.titleBackColor ?? Colors.orangeAccent,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10.0),
                      topRight: Radius.circular(10.0)),
                ),
                width: double.infinity,
                height: 35,
                child: Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: widget.titleForeColor ?? Colors.black),
                ),
              ),
              SizedBox(
                height: 5,
              ),
              //==================================== Content
              Container(
                  padding: EdgeInsets.only(left: 5, right: 5),
                  child: TextField(
                    maxLength: widget.maxTextLength ?? 250,
                    maxLines: widget.maxLines ?? 5,
                    style: TextStyle(color: Colors.black),
                    decoration: new InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.all(5.0),
                        border: new OutlineInputBorder(
                          borderRadius: const BorderRadius.all(
                            const Radius.circular(5.0),
                          ),
                        ),
                        filled: true,
                        hintStyle: new TextStyle(color: Colors.grey[500]),
                        hintText: widget.content,
                        fillColor: Colors.white70),
                    controller: widget._textController,
                    focusNode: widget._focusNode,
                    keyboardType: TextInputType.multiline,
                    textAlignVertical: TextAlignVertical.center,
                  )),
              //==================================== Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  //==================================== No
                  FlatButton(
                      padding: EdgeInsets.only(top: 0),
                      onPressed: () {
                        Navigator.pop(widget.context, widget.content);
                      },
                      child: Text(
                        widget.button2Text ?? "Cancel",
                        style: TextStyle(fontSize: 14),
                      )),
                  //==================================== OK
                  Container(
                    child: FlatButton(
                        padding: EdgeInsets.only(top: 0),
                        onPressed: () {
                          Navigator.pop(
                              widget.context,
                              widget.multiLines == null ||
                                      widget.multiLines == false
                                  ? widget._textController.text
                                      .replaceAll("\n", "")
                                  : widget._textController.text);
                        },
                        child: Text(
                          widget.button1Text ?? "OK",
                          style: TextStyle(fontSize: 14),
                        )),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

//==================================================================

enum DialogResult { yes, no }
enum DialogType { information, error, warning, question, success }

class MessageDialogBox extends StatefulWidget {
  final BuildContext context;
  final String title, content, button1Text, button2Text;
  final String titleImg;
  final DialogType type;
  final Color titleBackColor;
  final Color titleForeColor;

  const MessageDialogBox(this.context,
      {Key key,
      this.title,
      this.content,
      this.type = DialogType.information,
      this.button1Text,
      this.button2Text,
      this.titleImg,
      this.titleBackColor,
      this.titleForeColor})
      : super(key: key);

  @override
  _MessageDialogBoxState createState() => _MessageDialogBoxState();
}

class _MessageDialogBoxState extends State<MessageDialogBox> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: contentBox(context),
    );
  }

  contentBox(context) {
    return Stack(
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(left: 0, top: 0, right: 0, bottom: 0),
          margin: EdgeInsets.only(top: 50),
          decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                    color: Colors.black, offset: Offset(0, 10), blurRadius: 10),
              ]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              //=================================== Title
              widget.title != ''
                  ? Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        color: widget.titleBackColor ?? Colors.orangeAccent,
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10.0),
                            topRight: Radius.circular(10.0)),
                      ),
                      width: double.infinity,
                      height: 35,
                      child: Text(
                        widget.title,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: widget.titleForeColor ?? Colors.black),
                      ),
                    )
                  : Container(),
              SizedBox(
                height: 15,
              ),
              //==================================== Content
              Container(
                padding: EdgeInsets.only(left: 5, right: 5),
                child: Text(
                  widget.content,
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
              //==================================== Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  //==================================== No
                  widget.type == DialogType.question
                      ? FlatButton(
                          onPressed: () {
                            Navigator.pop(widget.context, DialogResult.no);
                            //Navigator.of(context).pop(widget.context);
                          },
                          child: Text(
                            widget.button2Text ?? _getButton2DefaultText(),
                            style: TextStyle(fontSize: 18),
                          ))
                      : Container(),
                  //==================================== Yes
                  FlatButton(
                      onPressed: () {
                        Navigator.pop(widget.context, DialogResult.yes);
                        //Navigator.of(context).pop();
                      },
                      child: Text(
                        widget.button1Text ?? _getButton1DefaultText(),
                        style: TextStyle(fontSize: 18),
                      )),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          left: -180,
          right: 20,
          child: CircleAvatar(
            backgroundColor: Colors.transparent,
            radius: 45,
            child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(45)),
                child: Image.asset(_getImageUrl())),
          ),
        )
      ],
    );
  }

  String _getImageUrl() {
    if (widget.titleImg != null)
      return widget.titleImg;
    else {
      if (widget.type == DialogType.error)
        return "assets/images/messageboxicon_error.png";
      else if (widget.type == DialogType.information)
        return "assets/images/messageboxicon_info.png";
      else if (widget.type == DialogType.warning)
        return "assets/images/messageboxicon_warning.png";
      else if (widget.type == DialogType.success)
        return "assets/images/messageboxicon_success.png";
      else
        return "assets/images/messageboxicon_question.png";
    }
  }

  String _getButton1DefaultText() {
    if (widget.type == DialogType.error)
      return "OK";
    else if (widget.type == DialogType.information)
      return "OK";
    else if (widget.type == DialogType.warning)
      return "OK";
    else if (widget.type == DialogType.success)
      return "OK";
    else
      return "Yes";
  }

  String _getButton2DefaultText() {
    if (widget.type == DialogType.error)
      return "OK";
    else if (widget.type == DialogType.information)
      return "OK";
    else if (widget.type == DialogType.warning)
      return "OK";
    else if (widget.type == DialogType.success)
      return "OK";
    else
      return "No";
  }
}
