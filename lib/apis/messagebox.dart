//https://github.com/RatelHub/rflutter_alert/tree/master/example
import 'package:flutter/material.dart';

import 'animation_transition.dart';
import '../components/dialog_button.dart';

enum MessageBoxType { error, success, info, warning, question, none }
enum AnimationType { fromRight, fromLeft, fromTop, fromBottom, grow, shrink }
const String kImagePath = "assets/images";

class MessageBox {
  //Member
  final BuildContext context;
  final MessageBoxType type;
  final MessageBoxStyle style;
  final Image image;
  final String title;
  final String desc;
  final Widget content;
  final List<DialogButton> buttons;

  //Constructor
  MessageBox({
    @required this.context,
    this.type,
    this.style = const MessageBoxStyle(),
    this.image,
    @required this.title,
    this.desc,
    this.content,
    this.buttons,
  });

  //Public Method
  void show() {
    showGeneralDialog(
      context: context,
      pageBuilder: (BuildContext buildContext, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return _buildDialog();
      },
      barrierDismissible: style.isOverlayTapDismiss,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: style.overlayColor,
      transitionDuration: style.animationDuration,
      transitionBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        Widget child,
      ) =>
          _showAnimation(animation, secondaryAnimation, child),
    );
  }

  void showEmpty() {
    showGeneralDialog(
      context: context,
      pageBuilder: (BuildContext buildContext, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return _buildEmptyDialog();
      },
      barrierDismissible: style.isOverlayTapDismiss,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: style.overlayColor,
      transitionDuration: style.animationDuration,
      transitionBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        Widget child,
      ) =>
          _showAnimation(animation, secondaryAnimation, child),
    );
  }

  static showInformation(BuildContext context, String title, String content) {
    MessageBox(
            context: context,
            type: MessageBoxType.info,
            title: title,
            desc: content)
        .show();
  }

  static showError(BuildContext context, String title, String content) {
    MessageBox(
            context: context,
            type: MessageBoxType.error,
            title: title,
            desc: content)
        .show();
  }

  static showWarning(BuildContext context, String title, String content) {
    MessageBox(
            context: context,
            type: MessageBoxType.warning,
            title: title,
            desc: content)
        .show();
  }

  static showQuestion(BuildContext context, String title, String content,
      {String yesButtonText,
      Function yesFunc,
      String noButtonText,
      Function noFunc}) {
    MessageBox(
      context: context,
      type: MessageBoxType.question,
      title: title,
      desc: content,
      buttons: [
        DialogButton(
          child: Text(
            noButtonText == null ? '否' : noButtonText,
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          onPressed: () {
            if (noFunc != null) noFunc();
            Navigator.pop(context);
          },
          color: Color.fromRGBO(0, 179, 134, 1.0),
        ),
        DialogButton(
          child: Text(
            yesButtonText == null ? '是' : yesButtonText,
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          onPressed: () {
            if (yesFunc != null) yesFunc();
            Navigator.pop(context);
          },
          gradient: LinearGradient(colors: [
            Color.fromRGBO(116, 116, 191, 1.0),
            Color.fromRGBO(52, 138, 199, 1.0)
          ]),
        )
      ],
    ).show();
  }

  //Private Method
  Widget _buildDialog() {
    return AlertDialog(
      shape: style.alertBorder ?? _defaultShape(),
      titlePadding: EdgeInsets.all(0.0),
      title: Container(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _getCloseButton(),
              Padding(
                padding: EdgeInsets.fromLTRB(
                    20, (style.isCloseButton ? 0 : 20), 20, 0),
                child: Column(
                  children: <Widget>[
                    _getImage(),
                    SizedBox(
                      height: 15,
                    ),
                    Text(
                      title,
                      style: style.titleStyle,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height: desc == null ? 5 : 10,
                    ),
                    desc == null
                        ? Container()
                        : Text(
                            desc,
                            style: style.descStyle,
                            textAlign: TextAlign.center,
                          ),
                    content == null ? Container() : content,
                  ],
                ),
              )
            ],
          ),
        ),
      ),
      contentPadding: style.buttonAreaPadding,
      content: Container(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _getButtons(),
        ),
      ),
    );
  }

  Widget _buildEmptyDialog() {

    return AlertDialog(
      //shape: style.alertBorder ?? _defaultShape(),
      titlePadding: EdgeInsets.all(0.0),
      //title:  content == null ? Container() : content,
      contentPadding: EdgeInsets.all(1.0), // style.buttonAreaPadding,
      content: content == null ? Container() : content,
    );
    
  }

  ShapeBorder _defaultShape() {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10.0),
      side: BorderSide(
        color: Colors.blueGrey,
      ),
    );
  }

  Widget _getCloseButton() {
    return style.isCloseButton
        ? Padding(
            padding: const EdgeInsets.fromLTRB(0, 10, 10, 0),
            child: Container(
              alignment: FractionalOffset.topRight,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                      '$kImagePath/messageboxicon_close.png', 
                    ),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          )
        : Container();
  }

  List<Widget> _getButtons() {
    List<Widget> expandedButtons = [];
    if (buttons != null) {
      buttons.forEach(
        (button) {
          var buttonWidget = Padding(
            padding: const EdgeInsets.only(left: 2, right: 2),
            child: button,
          );
          if (button.width != null && buttons.length == 1) {
            expandedButtons.add(buttonWidget);
          } else {
            expandedButtons.add(Expanded(
              child: buttonWidget,
            ));
          }
        },
      );
    } else {
      expandedButtons.add(
        Expanded(
          child: DialogButton(
            child: Text(
              "確定",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      );
    }

    return expandedButtons;
  }

  Widget _getImage() {
    Widget response = image ?? Container();
    switch (type) {
      case MessageBoxType.success:
        response = Image.asset('$kImagePath/messageboxicon_success.png');
        break;
      case MessageBoxType.error:
        response = Image.asset('$kImagePath/messageboxicon_error.png');
        break;
      case MessageBoxType.info:
        response = Image.asset('$kImagePath/messageboxicon_info.png');
        break;
      case MessageBoxType.warning:
        response = Image.asset('$kImagePath/messageboxicon_warning.png');
        break;
      case MessageBoxType.question:
        response = Image.asset('$kImagePath/messageboxicon_question.png');
        break;
      case MessageBoxType.none:
        response = Container();
        break;
    }
    return response;
  }

  _showAnimation(animation, secondaryAnimation, child) {
    if (style.animationType == AnimationType.fromRight) {
      return AnimationTransition.fromRight(
          animation, secondaryAnimation, child);
    } else if (style.animationType == AnimationType.fromLeft) {
      return AnimationTransition.fromLeft(animation, secondaryAnimation, child);
    } else if (style.animationType == AnimationType.fromBottom) {
      return AnimationTransition.fromBottom(
          animation, secondaryAnimation, child);
    } else if (style.animationType == AnimationType.grow) {
      return AnimationTransition.grow(animation, secondaryAnimation, child);
    } else if (style.animationType == AnimationType.shrink) {
      return AnimationTransition.shrink(animation, secondaryAnimation, child);
    } else {
      return AnimationTransition.fromTop(animation, secondaryAnimation, child);
    }
  }
}

class MessageBoxStyle {
  final AnimationType animationType;
  final Duration animationDuration;
  final ShapeBorder alertBorder;
  final bool isCloseButton;
  final bool isOverlayTapDismiss;
  final Color overlayColor;
  final TextStyle titleStyle;
  final TextStyle descStyle;
  final EdgeInsets buttonAreaPadding;

  /// Alert style constructor function
  /// The [animationType] parameter is used for transitions. Default: "fromBottom"
  /// The [animationDuration] parameter is used to set the animation transition time. Default: "200 ms"
  /// The [alertBorder] parameter sets border.
  /// The [isCloseButton] parameter sets visibility of the close button. Default: "true"
  /// The [isOverlayTapDismiss] parameter sets closing the alert by clicking outside. Default: "true"
  /// The [overlayColor] parameter sets the background color of the outside. Default: "Color(0xDD000000)"
  /// The [titleStyle] parameter sets alert title text style.
  /// The [descStyle] parameter sets alert desc text style.
  /// The [buttonAreaPadding] parameter sets button area padding.
  const MessageBoxStyle({
    this.animationType = AnimationType.fromBottom,
    this.animationDuration = const Duration(milliseconds: 200),
    this.alertBorder,
    this.isCloseButton = true,
    this.isOverlayTapDismiss = true,
    this.overlayColor = Colors.black87,
    this.titleStyle = const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.normal,
        fontSize: 22.0),
    this.descStyle = const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.normal,
        fontSize: 18.0),
    this.buttonAreaPadding = const EdgeInsets.all(20.0),
  });
}
