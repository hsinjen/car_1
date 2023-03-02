import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:car_1/business/responseresult.dart';
import 'package:flutter/cupertino.dart';

class InputToolBarState {
  var textFieldFocusNode = FocusNode();
  var inputController = TextEditingController();
  int barcodeFixMode = 0; //0:標準 1:去頭 2:F/U
  TextInputType keyboardType = TextInputType.text;
  bool inputEnabled = false;
  int inputMode = 1; //0: keybarod 1: scanner 2:camera
  String action = 'vin';

  void setDefault() {
    inputEnabled = false;
    inputMode = 0;
    action = 'vin';
  }

  void showKeyboard(String action, TextInputType type) {
    this.inputMode = 0;
    this.inputEnabled = true;
    this.action = action;
    this.keyboardType = type;
  }

  void hideKeyboard() {
    this.inputEnabled = false;
  }

  void showScanner(String action) {
    this.inputMode = 1;
    this.inputEnabled = true;
    this.action = action;
  }
}

// ignore: must_be_immutable
class InputToolBar extends StatefulWidget {
  final InputToolBarState state;
  final void Function(String, String) onValueChanged;
  final Function onNotifyParent;

  InputToolBar({Key key, this.state, this.onValueChanged, this.onNotifyParent})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return InputToolBarContext();
  }
}

class InputToolBarContext extends State<InputToolBar> {
  List<String> _barcodeFixModeText = ['標準', '去頭', 'F/U'];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //scanner
    if (widget.state.inputMode == 1) {
      if (widget.state.inputEnabled == true) {
        if (widget.state.textFieldFocusNode.hasFocus == false)
          FocusScope.of(context).requestFocus(widget.state.textFieldFocusNode);
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      } else {
        FocusScope.of(context).requestFocus(new FocusNode());
      }
    }
    //keyboard
    else if (widget.state.inputMode == 0) {
      if (widget.state.inputEnabled == true) {
        FocusScope.of(context).requestFocus(widget.state.textFieldFocusNode);
        SystemChannels.textInput.invokeMethod('TextInput.show');
      } else {
        SystemChannels.textInput.invokeMethod('TextInput.hide');
        FocusScope.of(context).requestFocus(new FocusNode());
      }
    }

    return Container(
      decoration: BoxDecoration(
          color: Colors.grey[300],
          border: Border(
              top: BorderSide(
            color: Colors.black,
            width: 1.0,
          ))),
      width: MediaQuery.of(context).size.width,
      child: Row(
        children: <Widget>[
          //特殊功能
          IconButton(
              icon: Icon(Icons.add, color: Colors.black),
              padding: EdgeInsets.all(0),
              onPressed: () {
                widget.onNotifyParent();
              }),
          //填滿區域寬度、無邏輯
          Expanded(
            flex: widget.state.inputEnabled == false ||
                    widget.state.inputMode == 1
                ? 2
                : 0,
            child: Container(),
          ),
          //文字方塊
          Expanded(
            flex:
                widget.state.inputMode == 0 && widget.state.inputEnabled == true
                    ? 2
                    : 0,
            child: Container(
              alignment: Alignment.center,
              color: Colors.white,
              width: widget.state.inputMode == 0 &&
                      widget.state.inputEnabled == true
                  ? 1000.0
                  : 0,
              child: TextField(
                controller: widget.state.inputController,
                focusNode: widget.state.textFieldFocusNode,
                autofocus: false,
                keyboardType: widget.state.keyboardType,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22.0),
                textAlignVertical: TextAlignVertical.center,
                onEditingComplete: () {
                  //keyboard
                  if (widget.state.inputMode == 0) {
                    widget.state.inputEnabled = false;
                    if (widget.state.inputController.text.length > 0) {
                      String barcode = widget.state.inputController.text;
                      widget.state.inputController.text = '';
                      widget.onValueChanged(widget.state.action, barcode);
                    }
                    FocusScope.of(context).requestFocus(new FocusNode());
                    //widget.onNotifyParent();
                  }
                  //scanner
                  else if (widget.state.inputMode == 1) {
                    if (widget.state.inputController.text.length < 6) {
                      widget.state.inputController.text = '';
                      _showMessage(ResultFlag.ng, '車身號碼必須大於 6 碼');

                      if (widget.state.textFieldFocusNode.hasFocus == false)
                        FocusScope.of(context)
                            .requestFocus(widget.state.textFieldFocusNode);
                    } else {
                      String barcode = barcodeCheck(widget.state.barcodeFixMode,
                          widget.state.inputController.text);
                      widget.state.inputController.text = '';
                      widget.onValueChanged(this.widget.state.action, barcode);
                    }
                  }
                },
              ),
            ),
          ),
          //條碼格式
          SizedBox(
              width: 60.0,
              child: FlatButton(
                padding:
                    EdgeInsets.only(left: 0, right: 0, top: 2.0, bottom: 0),
                child: Text(_barcodeFixModeText[widget.state.barcodeFixMode],
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
                onPressed: () {
                  if (widget.state.barcodeFixMode == 0)
                    widget.state.barcodeFixMode = 1;
                  else if (widget.state.barcodeFixMode == 1)
                    widget.state.barcodeFixMode = 2;
                  else
                    widget.state.barcodeFixMode = 0;
                  ;
                  widget.onNotifyParent();
                },
              )),
          //scanner button
          IconButton(
              icon: Icon(Icons.all_out,
                  color: widget.state.inputMode == 1 &&
                          this.widget.state.inputEnabled == true
                      ? Colors.orange
                      : Colors.black),
              onPressed: () {
                widget.state.inputMode = 1;
                widget.state.action = 'vin';
                widget.state.inputEnabled = true;
                widget.onNotifyParent();
                //FocusScope.of(context)
                //    .requestFocus(widget.state.textFieldFocusNode);
              }),
          //2:camera
          IconButton(
              icon: Icon(Icons.camera_enhance,
                  color: widget.state.inputMode == 2 &&
                          widget.state.inputEnabled == true
                      ? Colors.orange
                      : Colors.black),
              // padding: EdgeInsets.all(0),
              onPressed: () async {
                widget.state.inputMode = 2;
                widget.state.action = 'vin';
                widget.state.inputEnabled = true;
                try {
                  String barcode = await BarcodeScanner.scan();
                  if (barcode == null) return;
                  if (barcode.length < 6) {
                    _showMessage(ResultFlag.ng, '車身號碼必須大於 6 碼');
                  } else {
                    String value =
                        barcodeCheck(widget.state.barcodeFixMode, barcode);
                    widget.onValueChanged(widget.state.action, value);
                  }
                } catch (e) {
                  _showMessage(ResultFlag.ng, 'Scan Barcode Error 請檢查相機權限');
                }
              }),

          //0:keyboard
          IconButton(
              icon: Icon(Icons.keyboard,
                  color: widget.state.inputMode == 3 &&
                          widget.state.inputEnabled == true
                      ? Colors.orange
                      : Colors.black),
              onPressed: () {
                widget.state.inputMode = 0;
                widget.state.keyboardType = TextInputType.text;
                widget.state.action = 'vin';
                widget.state.inputEnabled = true;
                widget.onNotifyParent();
              }),
        ],
      ),
    );
  }

  void focus() {
    FocusScope.of(context).requestFocus(widget.state.textFieldFocusNode);
  }

  void unfocus() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    FocusScope.of(context).requestFocus(new FocusNode());
  }

  void showMessage(
      GlobalKey<ScaffoldState> context, ResultFlag flag, String message) {
    context.currentState.showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: flag == ResultFlag.ok ? Colors.green : Colors.red,
    ));
  }

  void _showMessage(ResultFlag flag, String message) {
    Scaffold.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: flag == ResultFlag.ok ? Colors.green : Colors.red,
    ));
  }

  String barcodeCheck(int barcodeFixMode, String barcodeValue,
      {String Function(String) checkValue}) {
    String _value = '';
    if (checkValue != null) {
      _value = checkValue(barcodeValue);
    } else {
      //一般
      if (barcodeFixMode == 0) {
        if (barcodeValue.length > 17)
          _value = barcodeValue.substring(0, 17);
        else
          _value = barcodeValue;
      }
      //去頭
      else if (barcodeFixMode == 1) {
        if (barcodeValue.length > 18)
          _value = barcodeValue.substring(1, 18);
        else
          _value = barcodeValue;
      } else
        _value = barcodeValue;
    }
    return _value;
  }
}
