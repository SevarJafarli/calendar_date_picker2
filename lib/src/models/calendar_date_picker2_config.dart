import 'package:flutter/material.dart';

enum CalendarDatePicker2Type { single, multi, range }

typedef CalendarDayTextStylePredicate = TextStyle? Function({
  required DateTime date,
});

typedef CalendarDayBuilder = Widget? Function({
  required DateTime date,
  TextStyle? textStyle,
  BoxDecoration? decoration,
  bool? isSelected,
  bool? isDisabled,
  bool? isToday,
});

class CalendarDatePicker2Config {
  CalendarDatePicker2Config({
    CalendarDatePicker2Type? calendarType,
    DateTime? firstDate,
    DateTime? lastDate,
    DateTime? currentDate,
    DatePickerMode? calendarViewMode,
    this.minuteShortStr = "m", 
    this.hourShortStr = "h", 
    this.changeYearStr = "Change Year", 
    this.cancelStr = "Cancel", 
    this.okayStr = "Okay",
    this.splashRadius,
    this.weekdayLabels,
    this.weekdayLabelTextStyle,
    this.firstDayOfWeek,
    this.controlsHeight,
    this.lastMonthIcon,
    this.nextMonthIcon,
    this.controlsTextStyle,
    this.dayTextStyle,
    this.selectedDayTextStyle,
    this.selectedDayHighlightColor,
    this.selectedDayBoxShadows,
    this.todayHighlightColor,
    this.pastOrFutureDaysTextStyle,
    this.disabledDayTextStyle,
    this.todayTextStyle,
    this.yearTextStyle,
    this.selectedYearTextStyle,
    this.dayBorderRadius,
    this.yearBorderRadius,
    this.selectableDayPredicate,
    this.dayTextStylePredicate,
    this.dayBuilder,
    this.disableYearPicker,
    this.focusedYearTextStyle,
    this.selectedWeekdayHighlightColor, 
    this.selectedWeekdayBoxShadows, 
    this.weekdayBorderRadius,
    this.selectedWeekdayTextStyle,
    this.monthYearPanelColor,
    this.monthYearPanelTextStyle,
    this.monthYearPanelEnabledArrowColor,
    this.monthYearPanelDisabledArrowColor, 
    this.timePickerBgColor,
    this.timePickerArrowColor,
    this.timePickerTextStyle,
    this.yearPickerDialogBarrierColor,
    this.yearPickerDialogBgColor,
    this.yearPickerDialogChangeYearLabelTextStyle, 
    this.yearPickerDialogInfoBlockYearTextStyle, 
    this.yearPickerDialogInfoBlockMonthDayTextStyle, 
    this.yearPickerDialogInfoBlockColor, 
    this.yearPickerDialogDividerColor, 
    this.yearPickerDialogCancelBtnBorderColor, 
    this.yearPickerDialogCancelBtnColor, 
    this.yearPickerDialogCancelBtnTextColor, 
    this.yearPickerDialogOkayBtnBorderColor, 
    this.yearPickerDialogOkayBtnColor, 
    this.yearPickerDialogOkayBtnTextColor, 
  })  : calendarType = calendarType ?? CalendarDatePicker2Type.single,
        firstDate = firstDate ?? DateTime(1970),
        lastDate = lastDate ?? DateTime(DateTime.now().year + 50),
        currentDate = currentDate ?? DateUtils.dateOnly(DateTime.now()),
        calendarViewMode = calendarViewMode ?? DatePickerMode.day;

  final String minuteShortStr;
  final String hourShortStr;
  final String changeYearStr;
  final String cancelStr;
  final String okayStr;

  final Color? monthYearPanelColor;

  final TextStyle? monthYearPanelTextStyle;

  final Color? monthYearPanelEnabledArrowColor;

  final Color? monthYearPanelDisabledArrowColor; 

  final Color? timePickerBgColor; 

  final Color? timePickerArrowColor; 

  final TextStyle? timePickerTextStyle; 

  final Color? yearPickerDialogBarrierColor;

  final Color? yearPickerDialogBgColor;

  final TextStyle? yearPickerDialogChangeYearLabelTextStyle; 

  final TextStyle? yearPickerDialogInfoBlockYearTextStyle; 

  final TextStyle? yearPickerDialogInfoBlockMonthDayTextStyle;  

  final Color? yearPickerDialogInfoBlockColor;

  final Color? yearPickerDialogDividerColor;

  final Color? yearPickerDialogCancelBtnBorderColor;

  final Color? yearPickerDialogCancelBtnColor;

  final Color? yearPickerDialogCancelBtnTextColor;

  final Color? yearPickerDialogOkayBtnBorderColor;

  final Color? yearPickerDialogOkayBtnColor;

  final Color? yearPickerDialogOkayBtnTextColor;


  /// splash radius
  final double? splashRadius;

  /// The enabled date picker mode
  final CalendarDatePicker2Type calendarType;

  /// The earliest allowable [DateTime] that the user can select.
  final DateTime firstDate;

  /// The latest allowable [DateTime] that the user can select.
  final DateTime lastDate;

  /// The [DateTime] representing today. It will be highlighted in the day grid.
  final DateTime currentDate;

  /// The initially displayed view of the calendar picker.
  final DatePickerMode calendarViewMode;

  /// Custom weekday labels for the current locale, MUST starts from Sunday
  /// Examples:
  ///
  /// - US English: S, M, T, W, T, F, S
  /// - Russian: вс, пн, вт, ср, чт, пт, сб - notice that the list begins with
  ///   вс (Sunday) even though the first day of week for Russian is Monday.
  final List<String>? weekdayLabels;

  /// Custom text style for weekday labels
  final TextStyle? weekdayLabelTextStyle;

  /// Custom text style for selected weekday label
  final TextStyle? selectedWeekdayTextStyle;

  /// Index of the first day of week, where 0 points to Sunday, and 6 points to Saturday.
  final int? firstDayOfWeek;

  /// Custom height for calendar control toggle's height
  final double? controlsHeight;

  /// Custom icon for last month button control
  final Widget? lastMonthIcon;

  /// Custom icon for next month button control
  final Widget? nextMonthIcon;

  /// Custom text style for calendar mode toggle control
  final TextStyle? controlsTextStyle;

  /// Custom text style for focused year
  final TextStyle? focusedYearTextStyle;

  // /// Custom text style for year
  // final TextStyle? yearTextStyle;

  /// Custom text style for all calendar days
  final TextStyle? dayTextStyle;

  /// The highlight color for days of past or next month
  final TextStyle? pastOrFutureDaysTextStyle;

  /// Custom text style for selected calendar day(s)
  final TextStyle? selectedDayTextStyle;

  /// The highlight color for selected day(s)
  final Color? selectedDayHighlightColor;

  /// The box shadows for selected day(s)
  final List<BoxShadow>? selectedDayBoxShadows;

  /// The highlight color for selected weekday(s)
  final Color? selectedWeekdayHighlightColor;

  /// The box shadows for selected weekday(s)
  final List<BoxShadow>? selectedWeekdayBoxShadows;

  /// The highlight color for today
  final Color? todayHighlightColor;

  /// Custom text style for disabled calendar day(s)
  final TextStyle? disabledDayTextStyle;

  /// Custom text style for today
  final TextStyle? todayTextStyle;

  // Custom text style for years list
  final TextStyle? yearTextStyle;

  // Custom text style for selected year(s)
  final TextStyle? selectedYearTextStyle;

  /// Custom border radius for day indicator
  final BorderRadius? dayBorderRadius;

  /// Custom border radius for weekday indicator
  final BorderRadius? weekdayBorderRadius;

  /// Custom border radius for year indicator
  final BorderRadius? yearBorderRadius;

  /// Function to provide full control over which dates in the calendar can be selected.
  final SelectableDayPredicate? selectableDayPredicate;

  /// Function to provide full control over calendar days text style
  final CalendarDayTextStylePredicate? dayTextStylePredicate;

  /// Function to build customizable day widget
  final CalendarDayBuilder? dayBuilder;

  /// Flag to disable year picker and hide the toggle icon
  final bool? disableYearPicker;

  CalendarDatePicker2Config copyWith({
    CalendarDatePicker2Type? calendarType,
    DateTime? firstDate,
    DateTime? lastDate,
    DateTime? currentDate,
    DatePickerMode? calendarViewMode,
    List<String>? weekdayLabels,
    TextStyle? weekdayLabelTextStyle,
    int? firstDayOfWeek,
    double? controlsHeight,
    Widget? lastMonthIcon,
    Widget? nextMonthIcon,
    TextStyle? controlsTextStyle,
    TextStyle? dayTextStyle,
    TextStyle? selectedDayTextStyle,
    Color? selectedDayHighlightColor,
    TextStyle? disabledDayTextStyle,
    TextStyle? todayTextStyle,
    TextStyle? yearTextStyle,
    TextStyle? selectedYearTextStyle,
    BorderRadius? dayBorderRadius,
    BorderRadius? yearBorderRadius,
    SelectableDayPredicate? selectableDayPredicate,
    CalendarDayTextStylePredicate? dayTextStylePredicate,
    CalendarDayBuilder? dayBuilder,
    bool? disableYearPicker,
  }) {
    return CalendarDatePicker2Config(
      calendarType: calendarType ?? this.calendarType,
      firstDate: firstDate ?? this.firstDate,
      lastDate: lastDate ?? this.lastDate,
      currentDate: currentDate ?? this.currentDate,
      calendarViewMode: calendarViewMode ?? this.calendarViewMode,
      weekdayLabels: weekdayLabels ?? this.weekdayLabels,
      weekdayLabelTextStyle:
          weekdayLabelTextStyle ?? this.weekdayLabelTextStyle,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
      controlsHeight: controlsHeight ?? this.controlsHeight,
      lastMonthIcon: lastMonthIcon ?? this.lastMonthIcon,
      nextMonthIcon: nextMonthIcon ?? this.nextMonthIcon,
      controlsTextStyle: controlsTextStyle ?? this.controlsTextStyle,
      dayTextStyle: dayTextStyle ?? this.dayTextStyle,
      selectedDayTextStyle: selectedDayTextStyle ?? this.selectedDayTextStyle,
      selectedDayHighlightColor:
          selectedDayHighlightColor ?? this.selectedDayHighlightColor,
      disabledDayTextStyle: disabledDayTextStyle ?? this.disabledDayTextStyle,
      todayTextStyle: todayTextStyle ?? this.todayTextStyle,
      yearTextStyle: yearTextStyle ?? this.yearTextStyle,
      selectedYearTextStyle:
          selectedYearTextStyle ?? this.selectedYearTextStyle,
      dayBorderRadius: dayBorderRadius ?? this.dayBorderRadius,
      yearBorderRadius: yearBorderRadius ?? this.yearBorderRadius,
      selectableDayPredicate:
          selectableDayPredicate ?? this.selectableDayPredicate,
      dayTextStylePredicate:
          dayTextStylePredicate ?? this.dayTextStylePredicate,
      dayBuilder: dayBuilder ?? this.dayBuilder,
      disableYearPicker: disableYearPicker ?? this.disableYearPicker,
    );
  }
}

class CalendarDatePicker2WithActionButtonsConfig
    extends CalendarDatePicker2Config {
  CalendarDatePicker2WithActionButtonsConfig({
    CalendarDatePicker2Type? calendarType,
    DateTime? firstDate,
    DateTime? lastDate,
    DateTime? currentDate,
    DatePickerMode? calendarViewMode,
    List<String>? weekdayLabels,
    TextStyle? weekdayLabelTextStyle,
    int? firstDayOfWeek,
    double? controlsHeight,
    Widget? lastMonthIcon,
    Widget? nextMonthIcon,
    TextStyle? controlsTextStyle,
    TextStyle? dayTextStyle,
    TextStyle? selectedDayTextStyle,
    Color? selectedDayHighlightColor,
    TextStyle? disabledDayTextStyle,
    TextStyle? todayTextStyle,
    TextStyle? yearTextStyle,
    TextStyle? selectedYearTextStyle,
    BorderRadius? dayBorderRadius,
    BorderRadius? yearBorderRadius,
    SelectableDayPredicate? selectableDayPredicate,
    CalendarDayTextStylePredicate? dayTextStylePredicate,
    CalendarDayBuilder? dayBuilder,
    bool? disableYearPicker,
    this.gapBetweenCalendarAndButtons,
    this.cancelButtonTextStyle,
    this.cancelButton,
    this.okButtonTextStyle,
    this.okButton,
    this.openedFromDialog,
    this.closeDialogOnCancelTapped,
    this.closeDialogOnOkTapped,
  }) : super(
          calendarType: calendarType,
          firstDate: firstDate,
          lastDate: lastDate,
          currentDate: currentDate,
          calendarViewMode: calendarViewMode,
          weekdayLabels: weekdayLabels,
          weekdayLabelTextStyle: weekdayLabelTextStyle,
          firstDayOfWeek: firstDayOfWeek,
          controlsHeight: controlsHeight,
          lastMonthIcon: lastMonthIcon,
          nextMonthIcon: nextMonthIcon,
          controlsTextStyle: controlsTextStyle,
          dayTextStyle: dayTextStyle,
          selectedDayTextStyle: selectedDayTextStyle,
          selectedDayHighlightColor: selectedDayHighlightColor,
          disabledDayTextStyle: disabledDayTextStyle,
          todayTextStyle: todayTextStyle,
          yearTextStyle: yearTextStyle,
          selectedYearTextStyle: selectedYearTextStyle,
          dayBorderRadius: dayBorderRadius,
          yearBorderRadius: yearBorderRadius,
          selectableDayPredicate: selectableDayPredicate,
          dayTextStylePredicate: dayTextStylePredicate,
          dayBuilder: dayBuilder,
          disableYearPicker: disableYearPicker,
        );

  /// The gap between calendar and action buttons
  final double? gapBetweenCalendarAndButtons;

  /// Text style for cancel button
  final TextStyle? cancelButtonTextStyle;

  /// Custom cancel button
  final Widget? cancelButton;

  /// Text style for ok button
  final TextStyle? okButtonTextStyle;

  /// Custom ok button
  final Widget? okButton;

  /// Is the calendar opened from dialog
  final bool? openedFromDialog;

  /// If the dialog should be closed when user taps the CANCEL button
  final bool? closeDialogOnCancelTapped;

  /// If the dialog should be closed when user taps the OK button
  final bool? closeDialogOnOkTapped;

  @override
  CalendarDatePicker2WithActionButtonsConfig copyWith({
    CalendarDatePicker2Type? calendarType,
    DateTime? firstDate,
    DateTime? lastDate,
    DateTime? currentDate,
    DatePickerMode? calendarViewMode,
    List<String>? weekdayLabels,
    TextStyle? weekdayLabelTextStyle,
    int? firstDayOfWeek,
    double? controlsHeight,
    Widget? lastMonthIcon,
    Widget? nextMonthIcon,
    TextStyle? controlsTextStyle,
    TextStyle? dayTextStyle,
    TextStyle? selectedDayTextStyle,
    Color? selectedDayHighlightColor,
    TextStyle? disabledDayTextStyle,
    TextStyle? todayTextStyle,
    TextStyle? yearTextStyle,
    TextStyle? selectedYearTextStyle,
    double? gapBetweenCalendarAndButtons,
    TextStyle? cancelButtonTextStyle,
    Widget? cancelButton,
    TextStyle? okButtonTextStyle,
    Widget? okButton,
    bool? openedFromDialog,
    bool? closeDialogOnCancelTapped,
    bool? closeDialogOnOkTapped,
    BorderRadius? dayBorderRadius,
    BorderRadius? yearBorderRadius,
    SelectableDayPredicate? selectableDayPredicate,
    CalendarDayTextStylePredicate? dayTextStylePredicate,
    CalendarDayBuilder? dayBuilder,
    bool? disableYearPicker,
  }) {
    return CalendarDatePicker2WithActionButtonsConfig(
      calendarType: calendarType ?? this.calendarType,
      firstDate: firstDate ?? this.firstDate,
      lastDate: lastDate ?? this.lastDate,
      currentDate: currentDate ?? this.currentDate,
      calendarViewMode: calendarViewMode ?? this.calendarViewMode,
      weekdayLabels: weekdayLabels ?? this.weekdayLabels,
      weekdayLabelTextStyle:
          weekdayLabelTextStyle ?? this.weekdayLabelTextStyle,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
      controlsHeight: controlsHeight ?? this.controlsHeight,
      lastMonthIcon: lastMonthIcon ?? this.lastMonthIcon,
      nextMonthIcon: nextMonthIcon ?? this.nextMonthIcon,
      controlsTextStyle: controlsTextStyle ?? this.controlsTextStyle,
      dayTextStyle: dayTextStyle ?? this.dayTextStyle,
      selectedDayTextStyle: selectedDayTextStyle ?? this.selectedDayTextStyle,
      selectedDayHighlightColor:
          selectedDayHighlightColor ?? this.selectedDayHighlightColor,
      disabledDayTextStyle: disabledDayTextStyle ?? this.disabledDayTextStyle,
      todayTextStyle: todayTextStyle ?? this.todayTextStyle,
      yearTextStyle: yearTextStyle ?? this.yearTextStyle,
      selectedYearTextStyle:
          selectedYearTextStyle ?? this.selectedYearTextStyle,
      gapBetweenCalendarAndButtons:
          gapBetweenCalendarAndButtons ?? this.gapBetweenCalendarAndButtons,
      cancelButtonTextStyle:
          cancelButtonTextStyle ?? this.cancelButtonTextStyle,
      cancelButton: cancelButton ?? this.cancelButton,
      okButtonTextStyle: okButtonTextStyle ?? this.okButtonTextStyle,
      okButton: okButton ?? this.okButton,
      openedFromDialog: openedFromDialog ?? this.openedFromDialog,
      closeDialogOnCancelTapped:
          closeDialogOnCancelTapped ?? this.closeDialogOnCancelTapped,
      closeDialogOnOkTapped:
          closeDialogOnOkTapped ?? this.closeDialogOnOkTapped,
      dayBorderRadius: dayBorderRadius ?? this.dayBorderRadius,
      yearBorderRadius: yearBorderRadius ?? this.yearBorderRadius,
      selectableDayPredicate:
          selectableDayPredicate ?? this.selectableDayPredicate,
      dayTextStylePredicate:
          dayTextStylePredicate ?? this.dayTextStylePredicate,
      dayBuilder: dayBuilder ?? this.dayBuilder,
      disableYearPicker: disableYearPicker ?? this.disableYearPicker,
    );
  }
}
