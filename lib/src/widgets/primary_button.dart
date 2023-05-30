import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({Key? key, 
    required this.label,
    this.color,
    this.textColor,
    this.trailingWidget,
    this.onPressed,
    this.leadingWidget,
    this.borderColor,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.buttonHeight = 60,
    this.buttonWidth
  }) : super(key: key);

  final Color? color;
  final Color? textColor;
  final String label;
  final Widget? trailingWidget;
  final Widget? leadingWidget;
  final void Function()? onPressed;
  final Color? borderColor;
  final MainAxisAlignment mainAxisAlignment;
  final double buttonHeight;
  final double? buttonWidth;

  final TextStyle buttonSize14 = const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 1.25, height: 17 / 14);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        width: buttonWidth ?? MediaQuery.of(context).size.width,
        height: buttonHeight,
        decoration: BoxDecoration(
          color: color ?? const Color(0xFF3C69D1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor == null ? Colors.transparent : borderColor!,
          ),
        ),
        child: leadingWidget != null
            ? Row(
                mainAxisAlignment: mainAxisAlignment,
                children: [
                  leadingWidget != null ? leadingWidget! : const SizedBox(),
                  Text(label, style: buttonSize14.copyWith(color: textColor)),
                  trailingWidget != null ? trailingWidget! : const SizedBox(),
                ],
              )
            : trailingWidget != null
                ? Row(
                    mainAxisAlignment: mainAxisAlignment,
                    children: [
                      Text(label, style: buttonSize14.copyWith(color: textColor)),
                      trailingWidget != null ? trailingWidget! : const SizedBox(),
                    ],
                  )
                : Center(child: Text(label, style: buttonSize14.copyWith(color: textColor))),
      ),
    );
  }

  Widget get child {
    if (leadingWidget != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          leadingWidget!,
          Text(label, style: buttonSize14.copyWith(color: textColor)),
        ],
      );
    } else if (trailingWidget != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label, style: buttonSize14.copyWith(color: textColor)),
          trailingWidget!,
        ],
      );
    }

    return Center(
      child: Text(label, style: buttonSize14.copyWith(color: textColor)),
    );
  }
}
