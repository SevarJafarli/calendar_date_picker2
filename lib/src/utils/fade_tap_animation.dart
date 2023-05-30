import 'package:flutter/material.dart';

class FadeTapAnimation extends StatefulWidget {
  FadeTapAnimation({Key? key, 
    this.onTap,
    required this.child,
    this.animate = false,
  }) : super(key: key) {
    // debugPrint("constr");
  }
  final Function()? onTap;
  final Widget child;
  final bool animate;

  @override
  State<FadeTapAnimation> createState() => _FadeTapAnimationState();
}

class _FadeTapAnimationState extends State<FadeTapAnimation> {
  bool isHover = true;

  @override
  void initState() {
    debugPrint("init");
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) {
          debugPrint("postFrame");
          setState(() {
            isHover = false;
          });
        });

  }

  // @override
  // FutureOr<void> afterFirstLayout(BuildContext context) {
  //   debugPrint(widget.animate.toString());
  //   setState(() {
  //     isHover = false;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      focusColor: Colors.transparent,
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      // onHighlightChanged: (value) => setState(() {
      //   isHover = value;
      // }),
      onTap: widget.onTap,
      child: AnimatedOpacity(
        opacity: widget.animate && isHover ? 0 : 1,
        duration: const Duration(seconds: 5),
        child: widget.child,
      ),
    );
  }
  
}
