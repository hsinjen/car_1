import 'package:car_1/business/responseresult.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/foundation.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

enum KeyboardMode { none, keyboard, scanner, barcode }

class KeyboardAction {
  var focus = FocusNode();
  var controller = TextEditingController();
  TextInputType keyboardType = TextInputType.text;
  KeyboardMode mode = KeyboardMode.none;
  String actionName = '';
  bool isSetup = false;

  void clear() {
    focus.unfocus();
    controller.clear();
    keyboardType = TextInputType.text;
    mode = KeyboardMode.none;
    actionName = '';
  }

  void showKeyboard(String actionName,
      {String defaultValue = '', TextInputType type = TextInputType.text}) {
    if (this.mode != KeyboardMode.keyboard || this.keyboardType != type) {
      focus.unfocus();
    }
    this.actionName = actionName;
    this.mode = KeyboardMode.keyboard;
    this.controller.text = defaultValue;
    this.keyboardType = type;
  }

  void showScanner(String actionName) {
    if (this.mode != KeyboardMode.scanner ||
        this.keyboardType != TextInputType.text) {
      focus.unfocus();
    }
    this.actionName = actionName;
    this.mode = KeyboardMode.scanner;
    this.controller.text = '';
    this.keyboardType = TextInputType.text;
  }

  void showBarcode(String actionName) {
    if (this.mode != KeyboardMode.barcode) {
      focus.unfocus();
    }
    this.actionName = actionName;
    this.mode = KeyboardMode.barcode;
  }
}

// ignore: must_be_immutable
class Keyboard extends StatefulWidget {
  final KeyboardAction config;
  final void Function(String, String) onValueChanged;
  final void Function(String, String) onTextChanged;
  final Function onNotify;

  Keyboard(
      {Key key,
      this.config,
      this.onValueChanged,
      this.onTextChanged,
      this.onNotify})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return KeyboardState();
  }
}

class KeyboardState extends State<Keyboard> {
  @override
  void initState() {
    super.initState();

    widget.config.controller.addListener(() {
      final newText = widget.config.controller.text.toLowerCase();
      widget.config.controller.value = widget.config.controller.value.copyWith(
        text: newText,
        selection: TextSelection(
            baseOffset: newText.length, extentOffset: newText.length),
        composing: TextRange.empty,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    //scanner
    if (widget.config.mode == KeyboardMode.scanner) {
      if (widget.config.actionName != '') {
        if (widget.config.focus.hasFocus == false)
          FocusScope.of(context).requestFocus(widget.config.focus);
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      } else {
        FocusScope.of(context).unfocus();
      }
    }
    //keyboard
    else if (widget.config.mode == KeyboardMode.keyboard) {
      if (widget.config.actionName != '') {
        FocusScope.of(context).requestFocus(widget.config.focus);
        SystemChannels.textInput.invokeMethod('TextInput.show');
      } else {
        SystemChannels.textInput.invokeMethod('TextInput.hide');
        FocusScope.of(context).unfocus();
      }
    }

    return Container(
      //color: Colors.grey[300],
      padding: EdgeInsets.only(left: 2, top: 0, bottom: 0),
      width: MediaQuery.of(context).size.width,
      child: Row(
        children: <Widget>[
          widget.config.actionName == ''
              ? Expanded(flex: 2, child: Container())
              : widget.config.mode == KeyboardMode.barcode
                  ? Expanded(
                      child: Container(
                          padding: EdgeInsets.only(left: 50),
                          child: MaterialButton(
                            padding: const EdgeInsets.all(0.0),
                            onPressed: () async {
                              String value;
                              try {
                                value = await BarcodeScanner.scan();
                                if (widget.config.actionName != "")
                                  widget.onValueChanged(
                                      this.widget.config.actionName, value);
                              } on PlatformException {
                                if (widget.config.actionName != "")
                                  widget.onValueChanged(
                                      this.widget.config.actionName, "ERROR");
                              }

                              if (!mounted) return;
                            },
                            color: Colors.blue,
                            textColor: Colors.white,
                            child: Icon(
                              Icons.camera_alt,
                              size: 18,
                            ),
                            shape: CircleBorder(),
                          )))
                  : Expanded(
                      child: TextField(
                      decoration: new InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.all(5.0),
                          border: new OutlineInputBorder(
                            borderRadius: const BorderRadius.all(
                              const Radius.circular(5.0),
                            ),
                          ),
                          filled: true,
                          hintStyle: new TextStyle(color: Colors.grey[800]),
                          //hintText: "Type in your text",
                          fillColor: Colors.white70),
                      controller: widget.config.controller,
                      focusNode: widget.config.focus,
                      autofocus: false,
                      readOnly: widget.config.actionName == '' &&
                              widget.config.mode != KeyboardMode.scanner
                          ? true
                          : false,
                      keyboardType: widget.config.keyboardType,
                      textAlignVertical: TextAlignVertical.center,
                      onChanged: (String value) {
                        if (widget.config.actionName == "") return;
                        if (widget.config.mode == KeyboardMode.scanner) {
                          // widget.onValueChanged(
                          //     widget.config.actionName, value);
                          // widget.config.controller.clear();
                          // widget.config.actionName = '';
                          // if (widget.config.focus.hasFocus == false)
                          //   widget.config.focus.requestFocus();
                        } else {
                          widget.onTextChanged(widget.config.actionName, value);
                        }
                      },
                      onEditingComplete: () {
                        if (widget.config.mode == KeyboardMode.keyboard ||
                            widget.config.mode == KeyboardMode.scanner) {
                          if (widget.config.actionName != '') {
                            String value = widget.config.controller.text;
                            String originalActionName =
                                widget.config.actionName;
                            widget.config.actionName = '';
                            widget.onValueChanged(originalActionName, value);
                          }
                        }
                      },
                    )),

          //====================================================================
          //scanner button
          widget.config.isSetup == true
              ? IconButton(
                  icon: Icon(MdiIcons.flash, color: Colors.black),
                  onPressed: () {
                    widget.config.controller.clear();
                    widget.config.mode = KeyboardMode.scanner;
                    widget.config.isSetup = false;
                    widget.onNotify();
                  })
              : Container(),

          //barcode
          widget.config.isSetup == true
              ? IconButton(
                  icon: new Icon(MdiIcons.qrcode, color: Colors.black),
                  onPressed: () {
                    widget.config.mode = KeyboardMode.barcode;
                    widget.config.isSetup = false;
                    widget.onNotify();
                  })
              : Container(),

          //Keyboard
          widget.config.isSetup == true
              ? IconButton(
                  icon: Icon(Icons.keyboard, color: Colors.black),
                  onPressed: () {
                    widget.config.mode = KeyboardMode.keyboard;
                    widget.config.isSetup = false;
                    widget.onNotify();
                  })
              : Container(),

          //Setting
          IconButton(
              icon: Icon(
                _getModeIcon(),
              ),
              onPressed: () {
                widget.config.isSetup = !widget.config.isSetup;
                widget.onNotify();
              }),
        ],
      ),
    );
  }

  void showMessage(
      GlobalKey<ScaffoldState> context, ResultFlag flag, String message) {
    context.currentState.showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: flag == ResultFlag.ok ? Colors.green : Colors.red,
    ));
  }

  void showBarcode(String actionName) {
    try {
      BarcodeScanner.scan().then((value) {
        if (actionName != "") {
          widget.onValueChanged(actionName, value);
        }
      });
    } on PlatformException {
      if (actionName != "") widget.onValueChanged(actionName, "ERROR");
    }

    if (!mounted) return;
  }

  IconData _getModeIcon() {
    if (widget.config.mode == KeyboardMode.none)
      return Icons.settings;
    else if (widget.config.mode == KeyboardMode.scanner)
      return MdiIcons.flash;
    else if (widget.config.mode == KeyboardMode.barcode)
      return MdiIcons.qrcode;
    else
      return Icons.keyboard;
  }
}
