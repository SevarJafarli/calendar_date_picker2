// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: unnecessary_this

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:calendar_date_picker2/src/widgets/primary_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl; 

const Duration _monthScrollDuration = Duration(milliseconds: 300);

const double _dayPickerRowHeight = 42.0;
const int _maxDayPickerRowCount = 6; // A 31 day month that starts on Saturday.
// One extra row for the day-of-week header.
const double _maxDayPickerHeight =
    _dayPickerRowHeight * (_maxDayPickerRowCount + 1);
const double _monthPickerHorizontalPadding = 8.0;

const int _yearPickerColumnCount = 3;
const double _yearPickerPadding = 16.0;
const double _yearPickerRowHeight = 52.0;
const double _yearPickerRowSpacing = 8.0;

const double _subHeaderHeight = 52.0;
const double _monthNavButtonsWidth = 108.0;

T? _ambiguate<T>(T? value) => value;


class CalendarController { 
  final StreamController<Scheduled?> _streamController = StreamController();
  late final Stream<Scheduled?> _stream;
  Scheduled? _lastElement;
  ScheduledDateTime? _lastDt;

  CalendarController() {
    _stream = _streamController.stream;
  }

  void _setData(Scheduled? s) {
    if(s != null && _lastElement != null && _lastElement!.equals(s)) {
      debugPrint("Oops -> ${_lastElement!.toJson()} - ${s.toJson()}");
      return; 
    }
    _lastElement = s?.clone();
    if(s is ScheduledDateTime)  _lastDt = s;
    _streamController.add(s);
  } 

  bool listen(Function(Scheduled? s) listener) { 
    if(_streamController.hasListener) return false;
    _stream.listen(listener);
    return true;
  } 

  void dispose() {
    _streamController.close();
    _stream.drain();
    _lastElement = null;
    _lastDt = null;
  } 
 
  Scheduled? get lastElement => _lastElement;
  ScheduledDateTime? get lastDt => _lastDt;
}  

class CalendarDatePicker2 extends StatefulWidget {
  CalendarDatePicker2({
    required this.controller,
    required this.initialValue, 
    required this.config, 
    this.onDisplayedMonthChanged,
    this.includeTimePicker = false,
    this.isInRepeatedMode = false,
    Key? key,
  }) : super(key: key) {
    const valid = true;
    const invalid = false;

    origInitialValue = initialValue.map(
      (v) { 
        if(v == null) return null;
        if(v is ScheduledDateTime) {
          return v.dt;
        } 
        DateTime dt = controller.lastDt?.dt ?? DateTime.now();  
        return DateTime(dt.year, dt.month, dt.day, (v as ScheduledWeekDayTime).hour, v.minute);
      }
    ).toList();

    if (config.calendarType == CalendarDatePicker2Type.single) {
      assert(origInitialValue.length < 2,
          'Error: single date picker only allows maximum one initial date');
      
    }

    if (config.calendarType == CalendarDatePicker2Type.range &&
        origInitialValue.length > 1) {
      final isRangePickerValueValid = origInitialValue[0] == null
          ? (origInitialValue[1] != null ? invalid : valid)
          : (origInitialValue[1] != null
              ? (origInitialValue[1]!.isBefore(origInitialValue[0]!) ? invalid : valid)
              : valid);

      assert(
        isRangePickerValueValid,
        'Error: range date picker must has start date set before setting end date, and start date must before end date.',
      );
    } 
  }

  final CalendarController controller;
  final bool includeTimePicker;
  final bool isInRepeatedMode;  
  final List<Scheduled?> initialValue;

  /// The initially selected [DateTime]s that the picker should display.
  late final List<DateTime?> origInitialValue;

  /// Called when the user selects a date in the picker.
  // final ValueChanged<List<Scheduled?>>? onValueChanged;

  /// Called when the user navigates to a new month/year in the picker.
  final ValueChanged<DateTime>? onDisplayedMonthChanged;

  /// The calendar UI related configurations
  final CalendarDatePicker2Config config;

  @override
  State<CalendarDatePicker2> createState() => _CalendarDatePicker2State();
}

class _CalendarDatePicker2State extends State<CalendarDatePicker2> {
  bool _announcedInitialDate = false;
  late List<Scheduled?> _selectedDates;
  late DatePickerMode _mode;
  late DateTime _currentDisplayedMonthDate;
  final GlobalKey _monthPickerKey = GlobalKey();
  final GlobalKey _yearPickerKey = GlobalKey();
  late MaterialLocalizations _localizations;
  late TextDirection _textDirection;

  @override
  void initState() {
    super.initState();
    final config = widget.config;
    final initialDate = widget.origInitialValue.isNotEmpty &&
            widget.origInitialValue[0] != null
        ? DateTime(widget.origInitialValue[0]!.year, widget.origInitialValue[0]!.month)
        : DateUtils.dateOnly(DateTime.now());
    _mode = config.calendarViewMode;
    _currentDisplayedMonthDate = DateTime(initialDate.year, initialDate.month);

    _selectedDates = widget.origInitialValue.map((v) => v != null ? ScheduledDateTime(dt: v) : null).toList(); 
    _curWeekdayIndexes = [widget.origInitialValue[0]?.weekday ?? 1];  
    
    widget.controller._setData(_selectedDates[0]);
  }

  @override
  void didUpdateWidget(CalendarDatePicker2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.config.calendarViewMode != oldWidget.config.calendarViewMode) {
      _mode = widget.config.calendarViewMode;
    }
    _selectedDates = widget.origInitialValue.map((v) => v != null ? ScheduledDateTime(dt: v) : null).toList();

    if(widget.isInRepeatedMode) {
      _selectedDates = _selectedDates.map((d) {
        if(d == null) return null; 
        return d is ScheduledDateTime
          ? ScheduledWeekDayTime(weekdays: _curWeekdayIndexes, hour: d.dt.hour, minute: d.dt.minute)
          : d; 
      }).toList();
    } else {
      _selectedDates = _selectedDates.map((d) {
        if(d == null) return null; 
        if(d is ScheduledWeekDayTime) {
          if(widget.origInitialValue[0] != null) {
            return ScheduledDateTime(dt: widget.origInitialValue[0]!);
          } 
          return ScheduledDateTime(dt: DateTime.now()); 
        }
        return d; 
      }).toList();
    } 
    
    debugPrint("update");
    // widget.controller._setData(_selectedDates[0]); //?
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    assert(debugCheckHasMaterial(context));
    assert(debugCheckHasMaterialLocalizations(context));
    assert(debugCheckHasDirectionality(context));
    _localizations = MaterialLocalizations.of(context);
    _textDirection = Directionality.of(context);
    if (!_announcedInitialDate && _selectedDates.isNotEmpty) {
      _announcedInitialDate = true;
      for (final date in _selectedDates) {
        if (date != null && date is ScheduledDateTime) {
          SemanticsService.announce(
            _localizations.formatFullDate(date.dt),
            _textDirection,
          );
        }
      }
    } 
  } 

  void _vibrate() {
    switch (Theme.of(context).platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        HapticFeedback.vibrate();
        break;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        break;
    }
  }

  void _handleModeChanged(DatePickerMode mode) {
    _vibrate();
    setState(() {
      _mode = mode;
      if (_selectedDates.isNotEmpty) {
        for (final date in _selectedDates) {
          if (date != null && date is ScheduledDateTime) {
            SemanticsService.announce(
              _mode == DatePickerMode.day
                  ? _localizations.formatMonthYear(date.dt)
                  : _localizations.formatYear(date.dt),
              _textDirection,
            );
          }
        }
      }
    });
  }

  void _handleMonthChanged(DateTime date, {bool fromYearPicker = false}) {
    setState(() {
      final currentDisplayedMonthDate = DateTime(
        _currentDisplayedMonthDate.year,
        _currentDisplayedMonthDate.month,
      );
      var newDisplayedMonthDate = currentDisplayedMonthDate;

      if (_currentDisplayedMonthDate.year != date.year ||
          _currentDisplayedMonthDate.month != date.month) {
        newDisplayedMonthDate = DateTime(date.year, date.month);
      }

      if (fromYearPicker) {
        final selectedDatesInThisYear = widget.origInitialValue
            .where((d) => d?.year == date.year)
            .toList()
          ..sort((d1, d2) => d1!.compareTo(d2!));
        if (selectedDatesInThisYear.isNotEmpty) {
          newDisplayedMonthDate =
              DateTime(date.year, selectedDatesInThisYear[0]!.month);
        }
      }

      if (currentDisplayedMonthDate.year != newDisplayedMonthDate.year ||
          currentDisplayedMonthDate.month != newDisplayedMonthDate.month) {
        _currentDisplayedMonthDate = DateTime(
          newDisplayedMonthDate.year,
          newDisplayedMonthDate.month,
        );
        widget.onDisplayedMonthChanged?.call(_currentDisplayedMonthDate);
      }
    });
  }

  void _handleYearChanged(DateTime value) {
    _vibrate();

    if (value.isBefore(widget.config.firstDate)) {
      value = widget.config.firstDate;
    } else if (value.isAfter(widget.config.lastDate)) {
      value = widget.config.lastDate;
    }

    setState(() {
      _mode = DatePickerMode.day;
      _handleMonthChanged(value, fromYearPicker: true);
    });
  }

  void _handleDayChanged(DateTime value) {
    Scheduled scheduledValue = ScheduledDateTime(dt: value);
    _vibrate();
    setState(() {
      var selectedDates = [..._selectedDates];
      selectedDates.removeWhere((d) => d == null);

      if (widget.config.calendarType == CalendarDatePicker2Type.single) {
        selectedDates = [scheduledValue];
      } else if (widget.config.calendarType == CalendarDatePicker2Type.multi) {
        final index =
            selectedDates.indexWhere((d) => DateUtils.isSameDay((d as ScheduledDateTime?)?.dt, value));
        if (index != -1) {
          selectedDates.removeAt(index);
        } else {
          selectedDates.add(scheduledValue);
        }
      } else if (widget.config.calendarType == CalendarDatePicker2Type.range) {
        if (selectedDates.isEmpty) {
          selectedDates.add(scheduledValue);
        } else {
          final isRangeSet =
              selectedDates.length > 1 && selectedDates[1] != null;
          final isSelectedDayBeforeStartDate =
              value.isBefore((selectedDates[0]! as ScheduledDateTime).dt);

          if (isRangeSet || isSelectedDayBeforeStartDate) {
            selectedDates = [scheduledValue, null];
          } else {
            selectedDates = [selectedDates[0], scheduledValue];
          }
        }
      }

      selectedDates
        ..removeWhere((d) => d == null)
        ..sort((d1, d2) => (d1 as ScheduledDateTime).dt.compareTo((d2 as ScheduledDateTime).dt));

      final isValueDifferent =
          widget.config.calendarType != CalendarDatePicker2Type.single ||
              !DateUtils.isSameDay((selectedDates[0] as ScheduledDateTime?)?.dt,
                  _selectedDates.isNotEmpty ? (_selectedDates[0] as ScheduledDateTime?)?.dt : null);
      if (isValueDifferent) {
        int hour = (_selectedDates.first as ScheduledDateTime?)?.dt.hour ?? 0;
        int minute = (_selectedDates.first as ScheduledDateTime?)?.dt.minute ?? 0; 

        // _selectedDates = _selectedDates
        //   ..clear()
        //   ..addAll(selectedDates); 
        _selectedDates.clear();
        selectedDates.forEach((d) { 
          if(d != null) {
            ScheduledDateTime sd = d as ScheduledDateTime;
            _selectedDates.add(ScheduledDateTime(dt: DateTime(sd.dt.year, sd.dt.month, sd.dt.day, hour, minute)));
          }
        });

        if(this._selectedDates[0] != null) {
          this._curWeekdayIndexes = [(this._selectedDates[0]! as ScheduledDateTime).dt.weekday];
        }
        widget.controller._setData(_selectedDates[0]);
        // widget.onValueChanged?.call(_selectedDates);
      }
    });
  }

  Widget _buildPicker() {
    switch (_mode) {
      case DatePickerMode.day:
        return _MonthPicker(
          config: widget.config,
          key: _monthPickerKey,
          initialMonth: _currentDisplayedMonthDate,
          selectedDates: _selectedDates.map((s) => s != null && s is ScheduledDateTime ? s.dt : null).toList(),
          onChanged: _handleDayChanged,
          onDisplayedMonthChanged: _handleMonthChanged,
          onTopBarTap: () async {
            BorderRadius borderRadius = BorderRadius.circular(20);
            String? chosenYear = await showGeneralDialog(
              context: context, 
              barrierDismissible: false, 
              barrierLabel: "",
              barrierColor: widget.config.yearPickerDialogBarrierColor ?? Colors.transparent,
              useRootNavigator: true,
              pageBuilder: (context, animation, secondaryAnimation) => const SizedBox(),
              transitionDuration: const Duration(milliseconds: 300),
              transitionBuilder: (context, a1, a2, child) {  
                final curvedValue = Curves.easeInOut.transform(a1.value);
                return Transform.scale(
                  scale: curvedValue, // a1.value
                  child: DefaultTextStyle(
                    style: const TextStyle(),  
                    child: Opacity(
                      opacity: a1.value,
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 30,
                          sigmaY: 30,
                        ),
                        child: Center(
                          child: AlertDialog(
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: borderRadius, side: BorderSide.none),
                            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                            contentPadding: EdgeInsets.zero,
                            backgroundColor: Colors.transparent,  
                            content: ClipRRect(
                              borderRadius: borderRadius,
                              child: Container( 
                                decoration: BoxDecoration(
                                  color: widget.config.yearPickerDialogBgColor ?? Colors.white,
                                ),      
                                child: Padding(
                                  padding: const EdgeInsets.all(40),
                                  child: YearPicker(
                                    config: widget.config,
                                    key: _yearPickerKey,
                                    initialMonth: _currentDisplayedMonthDate,
                                    selectedDates: _selectedDates.map((s) => s != null && s is ScheduledDateTime ? s.dt : null).toList(),
                                    onChanged: _handleYearChanged,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ); 
            if(chosenYear != null) {
              _handleYearChanged(
                DateTime(
                  int.parse(chosenYear),
                  _currentDisplayedMonthDate.month,
                ),
              );
              _handleDayChanged(DateTime(int.parse(chosenYear), (_selectedDates[0]! as ScheduledDateTime).dt.month, (_selectedDates[0]! as ScheduledDateTime).dt.day));
            }
          }
        );
        default:
          return Container();
      // case DatePickerMode.year: //! for year grid view
      //   return Padding(
      //     padding: EdgeInsets.only(
      //         top: widget.config.controlsHeight ?? _subHeaderHeight),
      //     child: YearPicker(
      //       config: widget.config,
      //       key: _yearPickerKey,
      //       initialMonth: _currentDisplayedMonthDate,
      //       selectedDates: _selectedDates,
      //       onChanged: _handleYearChanged,
      //     ),
      //   );
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    assert(debugCheckHasMaterialLocalizations(context));
    assert(debugCheckHasDirectionality(context)); 
    
    return Column(
      children: <Widget>[
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: AnimatedCrossFade(
            firstChild: _buildWeekdayPicker(), 
            secondChild: _buildDatePicker(), 
            crossFadeState: widget.isInRepeatedMode ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 500), //?
            reverseDuration: const Duration(milliseconds: 500), //?
            firstCurve: Curves.easeInOut,
            secondCurve: Curves.easeInOut,
            sizeCurve: Curves.easeInOut,  
          ),
        ), 
        // widget.isInRepeatedMode 
        //   ? _buildWeekdayPicker()
        //   : _buildDatePicker(),
        widget.includeTimePicker
          ?  _buildTimePicker()
          : const SizedBox()
        // Put the mode toggle button on top so that it won't be covered up by the _MonthPicker
        // _DatePickerModeToggleButton( //! year picker button
        //   config: widget.config,
        //   mode: _mode,
        //   title: _localizations.formatMonthYear(_currentDisplayedMonthDate),
        //   onTitlePressed: () {
        //     // Toggle the day/year mode.
        //     _handleModeChanged(_mode == DatePickerMode.day
        //         ? DatePickerMode.year
        //         : DatePickerMode.day);
        //   },
        // ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return SizedBox(
      height: (widget.config.controlsHeight ?? _subHeaderHeight) +
          _maxDayPickerHeight,
      child: _buildPicker(),
    );
  }

  late List<int> _curWeekdayIndexes; 

  List<String> _getNormalWeekdaysOrder() {
    if(widget.config.weekdayLabels == null) return [];

    List<String> weekdays = widget.config.weekdayLabels!;
    List<String> newLst = []; 
    newLst.addAll(weekdays);
    newLst.insert(weekdays.length, weekdays.first);
    newLst.remove(weekdays.first); 
    return newLst;
  }

  Widget _buildWeekdayPicker() {  
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: this._getNormalWeekdaysOrder().map<Widget>((wd) {
              int index = (widget.config.weekdayLabels ?? []).indexOf(wd);
              bool isSelected = this._curWeekdayIndexes.contains(index);
              return GestureDetector(
                onTap: () { _onWeekdayTap(isSelected: isSelected, index: index); },
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7), 
                    decoration: isSelected ? BoxDecoration(
                      borderRadius: widget.config.weekdayBorderRadius,
                      color: widget.config.selectedWeekdayHighlightColor,  
                      boxShadow: widget.config.selectedWeekdayBoxShadows,
                      shape: widget.config.weekdayBorderRadius != null
                        ? BoxShape.rectangle
                        : BoxShape.circle,
                    ) : null,
                    child: Text(
                      wd, 
                      style: isSelected ? widget.config.selectedWeekdayTextStyle : widget.config.weekdayLabelTextStyle
                    ),
                  )
                )
              );
            }).toList(),
          ), 
        ],
      ),
    );
  }

  void _onWeekdayTap({required bool isSelected, required int index}) { 
    setState(() {
      if(isSelected) {
        if(this._curWeekdayIndexes.length > 1) {
          this._curWeekdayIndexes.remove(index);  
        }
      } else {
        this._curWeekdayIndexes.add(index);  
      }  
    }); 
    Scheduled? s = _selectedDates[0];
    int? h;
    int? m;
    if(s != null) {
      h = s is ScheduledDateTime ? s.dt.hour : (s as ScheduledWeekDayTime).hour;  
      m = s is ScheduledDateTime ? s.dt.minute : (s as ScheduledWeekDayTime).minute;  
    } 
    Scheduled newS = ScheduledWeekDayTime(weekdays: _curWeekdayIndexes, hour: h ?? 0, minute: m ?? 0);
    _selectedDates = [newS]; 
    widget.controller._setData(_selectedDates[0]);
    // widget.onValueChanged?.call(_selectedDates); 
  }

  void _onTimeChanged(int hours, int minutes) { 
    _selectedDates = _selectedDates.map((s) { 
      if(s != null) { 
        return widget.isInRepeatedMode
          ? ScheduledWeekDayTime(weekdays: _curWeekdayIndexes, hour: hours, minute: minutes)
          : ScheduledDateTime(dt: DateTime((s as ScheduledDateTime).dt.year, s.dt.month, s.dt.day, hours, minutes));  
      } 
    }).toList();
    widget.controller._setData(_selectedDates[0]);
    // widget.onValueChanged?.call(_selectedDates);
  }

  Widget _buildTimePicker() { 
    return Padding(
      padding: const EdgeInsets.only(top: 25),
      child: TimePicker(
        config: widget.config,
        onChanged: _onTimeChanged, 
        initHour: widget.origInitialValue.first?.hour, 
        initMinute: widget.origInitialValue.first?.minute
      ),
    );
  } 
}

enum _TimeType {
  hours,
  minutes   
} 
enum _ButtonDirection {
  up,
  down
} 
class TimePicker extends StatefulWidget {
  final int? initHour;
  final int? initMinute;
  final Function(int hours, int minutes)? onChanged;
  final CalendarDatePicker2Config config;

  TimePicker({Key? key, this.onChanged, this.initHour, this.initMinute, required this.config}) : super(key: key) {
    if(initHour != null)  assert(initHour! >= 0 && initHour! < 24);
    if(initMinute != null)  assert(initMinute! >= 0 && initMinute! < 60);
  }

  @override
  State<TimePicker> createState() => _TimePickerState();
}

class _TimePickerState extends State<TimePicker> {  
  final TextStyle _textStyle = const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, letterSpacing: 0.15, height: 24 / 20);

  late int _hours;
  late int _minutes; 

  Timer? _timer;
  bool _longPressCanceled = false; 

  @override
  void initState() {
    super.initState();
    _hours = widget.initHour ?? 8;
    _minutes = widget.initMinute ?? 0;
  }

  void _incrementHours() => setState(() => _hours = _hours == 23 ? 0 : _hours + 1); 
  void _decrementHours() => setState(() => _hours = _hours == 0 ? 23 : _hours - 1);

  void _incrementMinutes() {
    setState(() {
      if(_minutes == 59) {
        _incrementHours(); 
        _minutes = 0;
      } else {
        _minutes += 1;
      } 
    });
  }

  void _decrementMinutes() {
    setState(() {
      if(_minutes == 0) {
        _decrementHours(); 
        _minutes = 59;
      } else {
        _minutes -= 1;
      } 
    });
  }

  void _increaseValue(_TimeType type) => type == _TimeType.hours ? _incrementHours() : _incrementMinutes(); 
  void _decreaseValue(_TimeType type) => type == _TimeType.hours ? _decrementHours() : _decrementMinutes(); 
  void _changeValue(_TimeType type, _ButtonDirection direction) {
    direction == _ButtonDirection.up ? _increaseValue(type) : _decreaseValue(type); 
    widget.onChanged?.call(_hours, _minutes);
  }

  void _cancelLongPress() {
    _timer?.cancel();
    _longPressCanceled = true;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildContainer(_TimeType.hours),
          SizedBox(width: 25, child: Center(child: Text(":", style: _textStyle))),
          _buildContainer(_TimeType.minutes),
        ],
      ),
    );
  }

  Widget _buildContainer(_TimeType type) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        color: widget.config.timePickerBgColor ?? Colors.white, 
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
          child: Column(
            children: [ 
              _buildButton(type: type, direction: _ButtonDirection.up),
              _buildValue(type),
              _buildButton(type: type, direction: _ButtonDirection.down)
            ],
          ),
        ),
      ),
    );
  } 

  Widget _buildValue(_TimeType type) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Container(
        constraints: const BoxConstraints(minWidth: 46), 
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedFlipCounter(
              duration: const Duration(milliseconds: 150),
              value: type == _TimeType.hours 
                ? _hours 
                : _minutes,
              textStyle: widget.config.timePickerTextStyle ?? _textStyle,
              curve: Curves.easeInOut,
              wholeDigits: 2,
              suffix: type == _TimeType.hours ? widget.config.hourShortStr: widget.config.minuteShortStr,
            ), 
          ],
        ),
      ) 
    );
  }

  Widget _buildButton({required _TimeType type, required _ButtonDirection direction}) {
    return GestureDetector(
      onTap: () { _changeValue(type, direction); },
      onLongPressEnd: (_) { _cancelLongPress(); },
      onLongPress: () {
        _longPressCanceled = false;
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!_longPressCanceled) {
            _timer = Timer.periodic(const Duration(milliseconds: 170), (timer) {
              _changeValue(type, direction);
            });
          }
        });
      },
      onLongPressUp: _cancelLongPress,
      onLongPressMoveUpdate: (details) {
        if (details.localOffsetFromOrigin.distance > 20) {
          _cancelLongPress();
        }
      },
      child: Icon(direction == _ButtonDirection.up ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded, color: widget.config.timePickerArrowColor ??const Color(0xFFCCD2E3), size: 30)
    );
  } 
}


/// A button that used to toggle the [DatePickerMode] for a date picker.
///
/// This appears above the calendar grid and allows the user to toggle the
/// [DatePickerMode] to display either the calendar view or the year list.
class _DatePickerModeToggleButton extends StatefulWidget {
  const _DatePickerModeToggleButton({
    required this.mode,
    required this.title,
    required this.onTitlePressed,
    required this.config,
  });

  /// The current display of the calendar picker.
  final DatePickerMode mode;

  /// The text that displays the current month/year being viewed.
  final String title;

  /// The callback when the title is pressed.
  final VoidCallback onTitlePressed;

  /// The calendar configurations
  final CalendarDatePicker2Config config;

  @override
  _DatePickerModeToggleButtonState createState() =>
      _DatePickerModeToggleButtonState();
}

class _DatePickerModeToggleButtonState
    extends State<_DatePickerModeToggleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      value: widget.mode == DatePickerMode.year ? 0.5 : 0,
      upperBound: 0.5,
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(_DatePickerModeToggleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode == widget.mode) {
      return;
    }

    if (widget.mode == DatePickerMode.year) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color controlColor = colorScheme.onSurface.withOpacity(0.60);

    return Container(
      padding: const EdgeInsetsDirectional.only(start: 16, end: 4),
      height: (widget.config.controlsHeight ?? _subHeaderHeight),
      child: Row(
        children: <Widget>[
          Flexible(
            child: Semantics(
              label: MaterialLocalizations.of(context).selectYearSemanticsLabel,
              excludeSemantics: true,
              button: true,
              child: SizedBox(
                height: (widget.config.controlsHeight ?? _subHeaderHeight),
                child: InkWell(
                  onTap: widget.config.disableYearPicker == true
                      ? null
                      : widget.onTitlePressed,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            widget.title,
                            overflow: TextOverflow.ellipsis,
                            style: widget.config.controlsTextStyle ??
                                textTheme.titleSmall?.copyWith(
                                  color: controlColor,
                                ),
                          ),
                        ),
                        widget.config.disableYearPicker == true
                            ? const SizedBox()
                            : RotationTransition(
                                turns: _controller,
                                child: Icon(
                                  Icons.arrow_drop_down,
                                  color:
                                      widget.config.controlsTextStyle?.color ??
                                          controlColor,
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (widget.mode == DatePickerMode.day)
            // Give space for the prev/next month buttons that are underneath this row
            const SizedBox(width: _monthNavButtonsWidth),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _MonthPicker extends StatefulWidget {
  /// Creates a month picker.
  const _MonthPicker({
    required this.config,
    required this.initialMonth,
    required this.selectedDates,
    required this.onChanged,
    required this.onDisplayedMonthChanged,
    this.onTopBarTap,
    Key? key,
  }) : super(key: key);

  /// for opening dialog for choosing year
  final Function? onTopBarTap;

  /// The calendar configurations
  final CalendarDatePicker2Config config;

  /// The initial month to display.
  final DateTime initialMonth;

  /// The currently selected dates.
  ///
  /// Selected dates are highlighted in the picker.
  final List<DateTime?> selectedDates;

  /// Called when the user picks a day.
  final ValueChanged<DateTime> onChanged;

  /// Called when the user navigates to a new month.
  final ValueChanged<DateTime> onDisplayedMonthChanged;

  @override
  _MonthPickerState createState() => _MonthPickerState();
}

class _MonthPickerState extends State<_MonthPicker> {
  final GlobalKey _pageViewKey = GlobalKey();
  late DateTime _currentMonth;
  late PageController _pageController;
  late MaterialLocalizations _localizations;
  late TextDirection _textDirection;
  Map<ShortcutActivator, Intent>? _shortcutMap;
  Map<Type, Action<Intent>>? _actionMap;
  late FocusNode _dayGridFocus;
  DateTime? _focusedDay;

  @override
  void initState() {
    super.initState();
    _currentMonth = widget.initialMonth;
    _pageController = PageController(
        initialPage:
            DateUtils.monthDelta(widget.config.firstDate, _currentMonth));
    _shortcutMap = const <ShortcutActivator, Intent>{
      SingleActivator(LogicalKeyboardKey.arrowLeft):
          DirectionalFocusIntent(TraversalDirection.left),
      SingleActivator(LogicalKeyboardKey.arrowRight):
          DirectionalFocusIntent(TraversalDirection.right),
      SingleActivator(LogicalKeyboardKey.arrowDown):
          DirectionalFocusIntent(TraversalDirection.down),
      SingleActivator(LogicalKeyboardKey.arrowUp):
          DirectionalFocusIntent(TraversalDirection.up),
    };
    _actionMap = <Type, Action<Intent>>{
      NextFocusIntent:
          CallbackAction<NextFocusIntent>(onInvoke: _handleGridNextFocus),
      PreviousFocusIntent: CallbackAction<PreviousFocusIntent>(
          onInvoke: _handleGridPreviousFocus),
      DirectionalFocusIntent: CallbackAction<DirectionalFocusIntent>(
          onInvoke: _handleDirectionFocus),
    };
    _dayGridFocus = FocusNode(debugLabel: 'Day Grid');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _localizations = MaterialLocalizations.of(context);
    _textDirection = Directionality.of(context);
  }

  @override
  void didUpdateWidget(_MonthPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialMonth != oldWidget.initialMonth &&
        widget.initialMonth != _currentMonth) {
      // We can't interrupt this widget build with a scroll, so do it next frame
      // Add workaround to fix Flutter 3.0.0 compiler issue
      // https://github.com/flutter/flutter/issues/103561#issuecomment-1125512962
      // https://github.com/flutter/website/blob/3e6d87f13ad2a8dd9cf16081868cc3b3794abb90/src/development/tools/sdk/release-notes/release-notes-3.0.0.md#your-code
      _ambiguate(WidgetsBinding.instance)!.addPostFrameCallback(
        (Duration timeStamp) => _showMonth(widget.initialMonth, jump: true),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _dayGridFocus.dispose();
    super.dispose();
  }

  void _handleDateSelected(DateTime selectedDate) {
    _focusedDay = selectedDate;
    widget.onChanged(selectedDate);
  }

  void _handlePastOrFutureDateSelected(DateTime selectedDate, bool isPast) {
    Duration monthScrollDuration = _monthScrollDuration;
    Curve curve = Curves.ease;

    if(isPast) {
      _pageController.previousPage(
        duration: monthScrollDuration, 
        curve: curve
      );
    } else {
      _pageController.nextPage(
        duration: monthScrollDuration,
        curve: curve,
      );
    }

    _focusedDay = selectedDate;
  }

  void _handleMonthPageChanged(int monthPage) {
    setState(() {
      final DateTime monthDate =
          DateUtils.addMonthsToMonthDate(widget.config.firstDate, monthPage);
      if (!DateUtils.isSameMonth(_currentMonth, monthDate)) {
        _currentMonth = DateTime(monthDate.year, monthDate.month);
        widget.onDisplayedMonthChanged(_currentMonth);
        if (_focusedDay != null &&
            !DateUtils.isSameMonth(_focusedDay, _currentMonth)) {
          // We have navigated to a new month with the grid focused, but the
          // focused day is not in this month. Choose a new one trying to keep
          // the same day of the month.
          _focusedDay = _focusableDayForMonth(_currentMonth, _focusedDay!.day);
        }
        SemanticsService.announce(
          _localizations.formatMonthYear(_currentMonth),
          _textDirection,
        );
      }
    });
  }

  /// Returns a focusable date for the given month.
  ///
  /// If the preferredDay is available in the month it will be returned,
  /// otherwise the first selectable day in the month will be returned. If
  /// no dates are selectable in the month, then it will return null.
  DateTime? _focusableDayForMonth(DateTime month, int preferredDay) {
    final int daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);

    // Can we use the preferred day in this month?
    if (preferredDay <= daysInMonth) {
      final DateTime newFocus = DateTime(month.year, month.month, preferredDay);
      if (_isSelectable(newFocus)) return newFocus;
    }

    // Start at the 1st and take the first selectable date.
    for (int day = 1; day <= daysInMonth; day++) {
      final DateTime newFocus = DateTime(month.year, month.month, day);
      if (_isSelectable(newFocus)) return newFocus;
    }
    return null;
  }

  /// Navigate to the next month.
  void _handleNextMonth() { //!
    if (!_isDisplayingLastMonth) {
      _pageController.nextPage(
        duration: _monthScrollDuration,
        curve: Curves.ease,
      );
    }
  }

  /// Navigate to the previous month.
  void _handlePreviousMonth() {
    if (!_isDisplayingFirstMonth) {
      _pageController.previousPage(
        duration: _monthScrollDuration,
        curve: Curves.ease,
      );
    }
  }

  /// Navigate to the given month.
  void _showMonth(DateTime month, {bool jump = false}) {
    final int monthPage = DateUtils.monthDelta(widget.config.firstDate, month);
    if (jump) {
      _pageController.jumpToPage(monthPage);
    } else {
      _pageController.animateToPage(
        monthPage,
        duration: _monthScrollDuration,
        curve: Curves.ease,
      );
    }
  }

  /// True if the earliest allowable month is displayed.
  bool get _isDisplayingFirstMonth {
    return !_currentMonth.isAfter(
      DateTime(widget.config.firstDate.year, widget.config.firstDate.month),
    );
  }

  /// True if the latest allowable month is displayed.
  bool get _isDisplayingLastMonth {
    return !_currentMonth.isBefore(
      DateTime(widget.config.lastDate.year, widget.config.lastDate.month),
    );
  }

  /// Handler for when the overall day grid obtains or loses focus.
  void _handleGridFocusChange(bool focused) {
    setState(() {
      if (focused && _focusedDay == null && widget.selectedDates.isNotEmpty) {
        if (DateUtils.isSameMonth(widget.selectedDates[0], _currentMonth)) {
          _focusedDay = widget.selectedDates[0];
        } else if (DateUtils.isSameMonth(
            widget.config.currentDate, _currentMonth)) {
          _focusedDay = _focusableDayForMonth(
              _currentMonth, widget.config.currentDate.day);
        } else {
          _focusedDay = _focusableDayForMonth(_currentMonth, 1);
        }
      }
    });
  }

  /// Move focus to the next element after the day grid.
  void _handleGridNextFocus(NextFocusIntent intent) {
    _dayGridFocus.requestFocus();
    _dayGridFocus.nextFocus();
  }

  /// Move focus to the previous element before the day grid.
  void _handleGridPreviousFocus(PreviousFocusIntent intent) {
    _dayGridFocus.requestFocus();
    _dayGridFocus.previousFocus();
  }

  /// Move the internal focus date in the direction of the given intent.
  ///
  /// This will attempt to move the focused day to the next selectable day in
  /// the given direction. If the new date is not in the current month, then
  /// the page view will be scrolled to show the new date's month.
  ///
  /// For horizontal directions, it will move forward or backward a day (depending
  /// on the current [TextDirection]). For vertical directions it will move up and
  /// down a week at a time.
  void _handleDirectionFocus(DirectionalFocusIntent intent) {
    setState(() {
      if (_focusedDay != null) {
        final nextDate = _nextDateInDirection(_focusedDay!, intent.direction);
        if (nextDate != null) {
          _focusedDay = nextDate;
          if (!DateUtils.isSameMonth(_focusedDay, _currentMonth)) {
            _showMonth(_focusedDay!);
          }
        }
      } else {
        _focusedDay ??= widget.initialMonth;
      }
    });
  }

  static const Map<TraversalDirection, int> _directionOffset =
      <TraversalDirection, int>{
    TraversalDirection.up: -DateTime.daysPerWeek,
    TraversalDirection.right: 1,
    TraversalDirection.down: DateTime.daysPerWeek,
    TraversalDirection.left: -1,
  };

  int _dayDirectionOffset(
      TraversalDirection traversalDirection, TextDirection textDirection) {
    // Swap left and right if the text direction if RTL
    if (textDirection == TextDirection.rtl) {
      if (traversalDirection == TraversalDirection.left) {
        traversalDirection = TraversalDirection.right;
      } else if (traversalDirection == TraversalDirection.right) {
        traversalDirection = TraversalDirection.left;
      }
    }
    return _directionOffset[traversalDirection]!;
  }

  DateTime? _nextDateInDirection(DateTime date, TraversalDirection direction) {
    final TextDirection textDirection = Directionality.of(context);
    DateTime nextDate = DateUtils.addDaysToDate(
        date, _dayDirectionOffset(direction, textDirection));
    while (!nextDate.isBefore(widget.config.firstDate) &&
        !nextDate.isAfter(widget.config.lastDate)) {
      if (_isSelectable(nextDate)) {
        return nextDate;
      }
      nextDate = DateUtils.addDaysToDate(
          nextDate, _dayDirectionOffset(direction, textDirection));
    }
    return null;
  }

  bool _isSelectable(DateTime date) {
    return widget.config.selectableDayPredicate?.call(date) ?? true;
  }

  Widget _buildItems(BuildContext context, int index) {
    final DateTime month =
        DateUtils.addMonthsToMonthDate(widget.config.firstDate, index);
    return _DayPicker(
      key: ValueKey<DateTime>(month),
      selectedDates: (widget.selectedDates..removeWhere((d) => d == null))
          .cast<DateTime>(),
      onChanged: _handleDateSelected,
      onPastOrFutureDateSelected: _handlePastOrFutureDateSelected,
      config: widget.config,
      displayedMonth: month,
      pageController: _pageController
    );
  }

  Widget _buildMonthToggleButton({required bool isLeft}) {
    return GestureDetector(
      onTap: isLeft
        ? _isDisplayingFirstMonth ? null : _handlePreviousMonth
        : _isDisplayingLastMonth ? null : _handleNextMonth,
      behavior: HitTestBehavior.translucent,
      child: SizedBox(height: 40, width: 40, 
        child: Center(
          child: (isLeft
            ? widget.config.lastMonthIcon
            : widget.config.nextMonthIcon) 
            ?? Icon(isLeft ? Icons.arrow_back_ios : Icons.arrow_forward_ios, size: 14, 
              color: isLeft
                ? _isDisplayingFirstMonth ? widget.config.monthYearPanelEnabledArrowColor : widget.config.monthYearPanelDisabledArrowColor
                : _isDisplayingLastMonth ? widget.config.monthYearPanelEnabledArrowColor : widget.config.monthYearPanelDisabledArrowColor
            )
        )
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color controlColor =
        Theme.of(context).colorScheme.onSurface.withOpacity(0.60);

    return Semantics(
      child: Column(
        children: <Widget>[
          Container(  //! for month toggle
            padding: EdgeInsets.zero, // const EdgeInsetsDirectional.only(start: 16, end: 4),
            height: 40,
            
            child: Container(
              decoration: BoxDecoration(
                color: widget.config.monthYearPanelColor ?? Colors.white,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 10,
                    color: Colors.black.withOpacity(0.05)
                  )
                ]
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildMonthToggleButton(isLeft: true),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          if(this.widget.onTopBarTap != null) {
                            this.widget.onTopBarTap!();
                          }
                        },
                        child: Center(
                          child: Text(
                            _localizations.formatMonthYear(_currentMonth), 
                            style: widget.config.monthYearPanelTextStyle ?? const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25, height: 17.07 / 14, color: Color(0xFF848CA0))
                          )
                        )
                      )
                    ),
                    _buildMonthToggleButton(isLeft: false),
                  ],
                ),
              ),
            )
            // Row(
            //   children: <Widget>[
            //     const Spacer(),
            //     IconButton(
            //       icon: widget.config.lastMonthIcon ??
            //           const Icon(Icons.chevron_left),
            //       color: controlColor,
            //       tooltip: _isDisplayingFirstMonth
            //           ? null
            //           : _localizations.previousMonthTooltip,
            //       onPressed:
            //           _isDisplayingFirstMonth ? null : _handlePreviousMonth,
            //     ),
            //     IconButton(
            //       icon: widget.config.nextMonthIcon ??
            //           const Icon(Icons.chevron_right),
            //       color: controlColor,
            //       tooltip: _isDisplayingLastMonth
            //           ? null
            //           : _localizations.nextMonthTooltip,
            //       onPressed: _isDisplayingLastMonth ? null : _handleNextMonth,
            //     ),
            //   ],
            // ),
          ),
          const SizedBox(height: 22), //! padding
          Expanded(
            child: FocusableActionDetector(
              shortcuts: _shortcutMap,
              actions: _actionMap,
              focusNode: _dayGridFocus,
              onFocusChange: _handleGridFocusChange,
              child: _FocusedDate(
                date: _dayGridFocus.hasFocus ? _focusedDay : null,
                child: PageView.builder(
                  key: _pageViewKey,
                  controller: _pageController,
                  itemBuilder: _buildItems,
                  itemCount: DateUtils.monthDelta(
                          widget.config.firstDate, widget.config.lastDate) +
                      1,
                  onPageChanged: _handleMonthPageChanged,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// InheritedWidget indicating what the current focused date is for its children.
///
/// This is used by the [_MonthPicker] to let its children [_DayPicker]s know
/// what the currently focused date (if any) should be.
class _FocusedDate extends InheritedWidget {
  const _FocusedDate({
    Key? key,
    required Widget child,
    this.date,
  }) : super(key: key, child: child);

  final DateTime? date;

  @override
  bool updateShouldNotify(_FocusedDate oldWidget) {
    return !DateUtils.isSameDay(date, oldWidget.date);
  }

  static DateTime? maybeOf(BuildContext context) {
    final _FocusedDate? focusedDate =
        context.dependOnInheritedWidgetOfExactType<_FocusedDate>();
    return focusedDate?.date;
  }
}

/// Displays the days of a given month and allows choosing a day.
///
/// The days are arranged in a rectangular grid with one column for each day of
/// the week.
class _DayPicker extends StatefulWidget {
  /// Creates a day picker.
  const _DayPicker({
    required this.config,
    required this.displayedMonth,
    required this.selectedDates,
    required this.onChanged,
    required this.onPastOrFutureDateSelected,
    this.pageController,
    Key? key,
  }) : super(key: key);

  /// The calendar configurations
  final CalendarDatePicker2Config config;

  /// The currently selected dates.
  ///
  /// Selected dates are highlighted in the picker.
  final List<DateTime> selectedDates;

  /// Called when the user picks a day.
  final ValueChanged<DateTime> onChanged;

  /// Called when the user picks a day from past or next month.
  final Function(DateTime dateTime, bool isPast) onPastOrFutureDateSelected;

  /// The month whose days are displayed by this picker.
  final DateTime displayedMonth;

  final PageController? pageController;

  @override
  _DayPickerState createState() => _DayPickerState();
}

class _DayPickerState extends State<_DayPicker> {
  /// List of [FocusNode]s, one for each day of the month.
  late List<FocusNode> _dayFocusNodes;

  @override
  void initState() {
    super.initState();
    final int daysInMonth = DateUtils.getDaysInMonth(
        widget.displayedMonth.year, widget.displayedMonth.month);
    _dayFocusNodes = List<FocusNode>.generate(
      daysInMonth,
      (int index) =>
          FocusNode(skipTraversal: true, debugLabel: 'Day ${index + 1}'),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check to see if the focused date is in this month, if so focus it.
    final DateTime? focusedDate = _FocusedDate.maybeOf(context);
    if (focusedDate != null &&
        DateUtils.isSameMonth(widget.displayedMonth, focusedDate)) {
      _dayFocusNodes[focusedDate.day - 1].requestFocus();
    }
  }

  @override
  void dispose() {
    for (final FocusNode node in _dayFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  /// Builds widgets showing abbreviated days of week. The first widget in the
  /// returned list corresponds to the first day of week for the current locale.
  ///
  /// Examples:
  ///
  /// ```
  /// ┌ Sunday is the first day of week in the US (en_US)
  /// |
  /// S M T W T F S  <-- the returned list contains these widgets
  /// _ _ _ _ _ 1 2
  /// 3 4 5 6 7 8 9
  ///
  /// ┌ But it's Monday in the UK (en_GB)
  /// |
  /// M T W T F S S  <-- the returned list contains these widgets
  /// _ _ _ _ 1 2 3
  /// 4 5 6 7 8 9 10
  /// ```
  List<Widget> _dayHeaders(
      TextStyle? headerStyle, MaterialLocalizations localizations) {
    final List<Widget> result = <Widget>[];
    final weekdays =
        widget.config.weekdayLabels ?? localizations.narrowWeekdays;
    final firstDayOfWeek =
        widget.config.firstDayOfWeek ?? localizations.firstDayOfWeekIndex;
    assert(firstDayOfWeek >= 0 && firstDayOfWeek <= 6,
        'firstDayOfWeek must between 0 and 6');
    for (int i = firstDayOfWeek; true; i = (i + 1) % 7) {
      final String weekday = weekdays[i];
      result.add(ExcludeSemantics(
        child: Center(
          child: Text(
            weekday,
            style: widget.config.weekdayLabelTextStyle ?? headerStyle,
          ),
        ),
      ));
      if (i == (firstDayOfWeek - 1) % 7) break;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle? headerStyle = textTheme.bodySmall?.apply(
      color: colorScheme.onSurface.withOpacity(0.60),
    );
    final TextStyle dayStyle = textTheme.bodySmall!;
    final Color enabledDayColor = colorScheme.onSurface.withOpacity(0.87);
    final Color disabledDayColor = colorScheme.onSurface.withOpacity(0.38);
    final Color selectedDayColor = colorScheme.onPrimary;
    final Color pastOrFutureDayColor = colorScheme.onPrimary;
    final Color selectedDayBackground = colorScheme.primary;
    final Color todayColor = colorScheme.primary;

    final int year = widget.displayedMonth.year;
    final int month = widget.displayedMonth.month;

    final int daysInMonth = DateUtils.getDaysInMonth(year, month);
    final int dayOffset = getMonthFirstDayOffset(year, month,
        widget.config.firstDayOfWeek ?? localizations.firstDayOfWeekIndex);

    final List<Widget> dayItems = _dayHeaders(headerStyle, localizations);
    // 1-based day of month, e.g. 1-31 for January, and 1-29 for February on
    // a leap year. 

    int day = -dayOffset;
    // int day = 0;

    // while (day < daysInMonth) { //?
    while ((day + dayOffset) < (daysInMonth + dayOffset) + ((daysInMonth + dayOffset) % 7 == 0 ? 0 : 7 - (daysInMonth + dayOffset) % 7) ) { //?
      // print(day.toString() + " " + dayOffset.toString() + " " + daysInMonth.toString());

      day++;

      // if (day < 1) {
      //   dayItems.add(Container());
      // } else {
        
        DateTime dayToBuild;
        bool isDisabled;
        bool isSelectedDay;
        bool isToday;
        bool isFromPastOrFuture = false;

        if(day < 1) {
          dayToBuild = DateTime(year, month - 1 > 0 ? month - 1 : 12, DateUtils.getDaysInMonth(year, month - 1 > 0 ? month - 1 : 12) - day);
          isDisabled = false;
          isSelectedDay = false;
          isToday = false;
          isFromPastOrFuture = true;
        } else if (day > daysInMonth) {
          dayToBuild = DateTime(year, month + 1 <= 12 ? month + 1 : 1, day - daysInMonth);
          isDisabled = false;
          isSelectedDay = false;
          isToday = false;
          isFromPastOrFuture = true;
        } 

        dayToBuild = DateTime(year, month, day);
        isDisabled = dayToBuild.isAfter(widget.config.lastDate) ||
            dayToBuild.isBefore(widget.config.firstDate) ||
            !(widget.config.selectableDayPredicate?.call(dayToBuild) ?? true);
        isSelectedDay =
            widget.selectedDates.any((d) => DateUtils.isSameDay(d, dayToBuild));

        isToday =
            DateUtils.isSameDay(widget.config.currentDate, dayToBuild);

        BoxDecoration? decoration;
        Color dayColor = enabledDayColor;

        
        if(isFromPastOrFuture) {
          dayColor = pastOrFutureDayColor;
        } else if (isSelectedDay) {
          // The selected day gets a circle background highlight, and a
          // contrasting text color.
          dayColor = selectedDayColor;
          decoration = BoxDecoration(
            borderRadius: widget.config.dayBorderRadius,
            color: widget.config.selectedDayHighlightColor ??
              selectedDayBackground,
            boxShadow: widget.config.selectedDayBoxShadows,
            shape: widget.config.dayBorderRadius != null
                ? BoxShape.rectangle
                : BoxShape.circle,
          );
        } else if (isDisabled) {
          dayColor = disabledDayColor;
        } else if (isToday) {
          // The current day gets a different text color and a circle stroke
          // border.
          dayColor = widget.config.todayHighlightColor ?? todayColor;
          decoration = BoxDecoration(
            borderRadius: widget.config.dayBorderRadius,
            border: Border.all(color: dayColor),
            shape: widget.config.dayBorderRadius != null
                ? BoxShape.rectangle
                : BoxShape.circle,
          );
        }




        var customDayTextStyle =
            widget.config.dayTextStylePredicate?.call(date: dayToBuild) ??
                widget.config.dayTextStyle;

        if (isToday && widget.config.todayTextStyle != null) {
          customDayTextStyle = widget.config.todayTextStyle;
        }

        if (isDisabled) {
          customDayTextStyle = customDayTextStyle?.copyWith(
            color: disabledDayColor,
            fontWeight: FontWeight.normal,
          );
          if (widget.config.disabledDayTextStyle != null) {
            customDayTextStyle = widget.config.disabledDayTextStyle;
          }
        }

        if (isSelectedDay) {
          customDayTextStyle = widget.config.selectedDayTextStyle;
        }

        if (isFromPastOrFuture) {
          customDayTextStyle = widget.config.pastOrFutureDaysTextStyle;
        }

        final dayTextStyle =
            customDayTextStyle ?? dayStyle.apply(color: dayColor);

        Widget dayWidget = widget.config.dayBuilder?.call(
              date: dayToBuild,
              textStyle: dayTextStyle,
              decoration: decoration,
              isSelected: isSelectedDay,
              isDisabled: isDisabled,
              isToday: isToday,
            ) ??
            _buildDefaultDayWidgetContent(
              decoration,
              localizations,
              dayToBuild.day,
              dayTextStyle,
            );

        if (widget.config.calendarType == CalendarDatePicker2Type.range) {
          if (widget.selectedDates.length == 2) {
            final startDate = DateUtils.dateOnly(widget.selectedDates[0]);
            final endDate = DateUtils.dateOnly(widget.selectedDates[1]);
            final isDateInRange = !(dayToBuild.isBefore(startDate) ||
                dayToBuild.isAfter(endDate));
            final isStartDateSameToEndDate =
                DateUtils.isSameDay(startDate, endDate);

            if (isDateInRange && !isStartDateSameToEndDate) {
              final rangePickerIncludedDayDecoration = BoxDecoration(
                color: (widget.config.selectedDayHighlightColor ??
                        selectedDayBackground)
                    .withOpacity(0.15),
              );

              if (DateUtils.isSameDay(startDate, dayToBuild)) {
                dayWidget = Stack(
                  children: [
                    Row(children: [
                      const Spacer(),
                      Expanded(
                        child: Container(
                            decoration: rangePickerIncludedDayDecoration),
                      ),
                    ]),
                    dayWidget,
                  ],
                );
              } else if (DateUtils.isSameDay(endDate, dayToBuild)) {
                dayWidget = Stack(
                  children: [
                    Row(children: [
                      Expanded(
                        child: Container(
                            decoration: rangePickerIncludedDayDecoration),
                      ),
                      const Spacer(),
                    ]),
                    dayWidget,
                  ],
                );
              } else {
                dayWidget = Stack(
                  children: [
                    Container(decoration: rangePickerIncludedDayDecoration),
                    dayWidget,
                  ],
                );
              }
            }
          }
        }

        dayWidget = Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: dayWidget,
        );

        // debugPrint("here" + widget.displayedMonth.toString());
        // debugPrint("here");
        // if(isDisabled) {
        //   dayWidget = ExcludeSemantics(
        //     child: dayWidget,
        //   );
        // } else {
        //   debugPrint("here too");
        //   dayWidget = FadeTapAnimation(
        //     animate: isSelectedDay,
        //     onTap: () {
        //       if(isFromPastOrFuture) {
        //         widget.onPastOrFutureDateSelected(dayToBuild, dayToBuild.difference(widget.displayedMonth).isNegative);
        //       } 
        //       widget.onChanged(dayToBuild);
        //       setState(() {
                
        //       });
        //     },
        //     child: dayWidget,
        //   );
        // }

        if (isDisabled) {
          dayWidget = ExcludeSemantics(
            child: dayWidget,
          );
        } else {
          dayWidget = InkResponse(
            // focusNode: _dayFocusNodes[day - 1],
            onTap: () {
              if(isFromPastOrFuture) {
                widget.onPastOrFutureDateSelected(dayToBuild, dayToBuild.difference(widget.displayedMonth).isNegative);
              } 
              widget.onChanged(dayToBuild);
            },
            radius: widget.config.splashRadius ?? _dayPickerRowHeight / 2 + 4,
            splashColor: selectedDayBackground.withOpacity(0.38),
            child: Semantics(
              // We want the day of month to be spoken first irrespective of the
              // locale-specific preferences or TextDirection. This is because
              // an accessibility user is more likely to be interested in the
              // day of month before the rest of the date, as they are looking
              // for the day of month. To do that we prepend day of month to the
              // formatted full date.
              label:
                  '${localizations.formatDecimal(day)}, ${localizations.formatFullDate(dayToBuild)}',
              selected: isSelectedDay || isFromPastOrFuture,
              excludeSemantics: true,
              child: dayWidget,
            ),
          );
        }

        dayItems.add(dayWidget);
      // }
    } 
    return Padding( //!smth here
      padding: const EdgeInsets.symmetric(
        horizontal: _monthPickerHorizontalPadding,
      ),
      child: GridView.custom(
        padding: EdgeInsets.zero,
        physics: const ClampingScrollPhysics(),
        gridDelegate: _dayPickerGridDelegate,
        childrenDelegate: SliverChildListDelegate(
          dayItems,
          addRepaintBoundaries: false,
        ),
      ),
    );
  }

  Widget _buildDefaultDayWidgetContent(
    BoxDecoration? decoration,
    MaterialLocalizations localizations,
    int day,
    TextStyle dayTextStyle,
  ) {
    return Row(
      children: [
        const Spacer(),
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            height: 35,
            width: 35,
            decoration: decoration,
            child: Center(
              child: Text(
                localizations.formatDecimal(day),
                style: dayTextStyle,
              ),
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

class _DayPickerGridDelegate extends SliverGridDelegate {
  const _DayPickerGridDelegate();

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    const int columnCount = DateTime.daysPerWeek;
    final double tileWidth = constraints.crossAxisExtent / columnCount;
    final double tileHeight = math.min(
      _dayPickerRowHeight,
      constraints.viewportMainAxisExtent / (_maxDayPickerRowCount + 1),
    );
    return SliverGridRegularTileLayout(
      childCrossAxisExtent: tileWidth,
      childMainAxisExtent: tileHeight,
      crossAxisCount: columnCount,
      crossAxisStride: tileWidth,
      mainAxisStride: tileHeight,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(_DayPickerGridDelegate oldDelegate) => false;
}

const _DayPickerGridDelegate _dayPickerGridDelegate = _DayPickerGridDelegate();

/// A scrollable grid of years to allow picking a year.
///
/// The year picker widget is rarely used directly. Instead, consider using
/// [CalendarDatePicker2], or [showDatePicker2] which create full date pickers.
///
/// See also:
///
///  * [CalendarDatePicker2], which provides a Material Design date picker
///    interface.
///
///  * [showDatePicker2], which shows a dialog containing a Material Design
///    date picker.
///
class YearPicker extends StatefulWidget {
  /// Creates a year picker.
  const YearPicker({
    required this.config,
    required this.selectedDates,
    required this.onChanged,
    required this.initialMonth,
    this.dragStartBehavior = DragStartBehavior.start,
    Key? key,
  }) : super(key: key);

  /// The calendar configurations
  final CalendarDatePicker2Config config;

  /// The currently selected dates.
  ///
  /// Selected dates are highlighted in the picker.
  final List<DateTime?> selectedDates;

  /// Called when the user picks a year.
  final ValueChanged<DateTime> onChanged;

  /// The initial month to display.
  final DateTime initialMonth;

  /// {@macro flutter.widgets.scrollable.dragStartBehavior}
  final DragStartBehavior dragStartBehavior;

  @override
  State<YearPicker> createState() => _YearPickerState();
}

class _YearPickerState extends State<YearPicker> { 

  @override
  void initState() {
    super.initState();  
    _selectedIndex = widget.selectedDates[0]!.year - widget.config.firstDate.year;
  } 

  Widget _buildYearItem(BuildContext context, int index, {bool isInCenter = false}) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    // Backfill the _YearPicker with disabled years if necessary. 
    final int year = widget.config.firstDate.year + index;
    final bool isSelected = isInCenter;// widget.selectedDates.any((d) => d?.year == year);
    // final bool isCurrentYear = year == widget.config.currentDate.year;
    final bool isDisabled = year < widget.config.firstDate.year ||
        year > widget.config.lastDate.year; 

    final Color textColor;
    if (isSelected) {
      textColor = colorScheme.onPrimary;
    } else if (isDisabled) {
      textColor = colorScheme.onSurface.withOpacity(0.38);
    // } else if (isCurrentYear) {
    //   textColor =
    //       widget.config.selectedDayHighlightColor ?? colorScheme.primary;
    } else {
      textColor = colorScheme.onSurface.withOpacity(0.87);
    }
    TextStyle? itemStyle = widget.config.yearTextStyle ??
        textTheme.bodyText1?.apply(color: textColor);
    if (isSelected) {
      // itemStyle = widget.config.selectedYearTextStyle ?? itemStyle;
      itemStyle = widget.config.focusedYearTextStyle ?? itemStyle;
    } 

    Widget yearItem = Text(
      year.toString(),
      style: isSelected ? itemStyle : null,
    ); 

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Center(child: yearItem),
    );
  }

  int get _itemCount {
    return widget.config.lastDate.year - widget.config.firstDate.year + 1;
  }

  late int _selectedIndex;

  @override
  Widget build(BuildContext context) {
    // assert(debugCheckHasMaterial(context)); 
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoBlock(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Text(widget.config.changeYearStr, style: widget.config.yearPickerDialogChangeYearLabelTextStyle),
        ),
        _buildYearPicker(),
        const SizedBox(height: 15),
        _buildButtons()
      ],
    ); 
  }

  Widget _buildInfoBlock() {
    String locale = Localizations.localeOf(context).languageCode;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        Navigator.pop(context);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          color: widget.config.yearPickerDialogInfoBlockColor ?? const Color(0xFF375CB0),
          width: MediaQuery.of(context).size.width,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.selectedDates[0]!.year.toString(), style: widget.config.yearPickerDialogInfoBlockYearTextStyle ?? null),
                const SizedBox(height: 5),
                Text("${intl.DateFormat.MMM(locale).format(widget.selectedDates[0]!)} ${widget.selectedDates[0]!.day}", style: widget.config.yearPickerDialogInfoBlockMonthDayTextStyle ?? null),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildYearPicker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(
          color: widget.config.yearPickerDialogDividerColor ?? Color(0xFFE2EAFD),
          height: 1, 
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: SizedBox(
            height: 221,
            child: CupertinoTheme(
              data: CupertinoThemeData(
                textTheme: CupertinoTextThemeData(
                  pickerTextStyle: widget.config.yearTextStyle,
                )
              ),
              child: CupertinoPicker(
                children: List.generate(_itemCount, (index) => index).map(
                  (index) => _buildYearItem(context, index, isInCenter: index == _selectedIndex)
                ).toList(),
                onSelectedItemChanged: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                backgroundColor: Colors.transparent,
                selectionOverlay: null,
                itemExtent: 40,
                // useMagnifier: true,
                // magnification: 1.2,
                diameterRatio: 5,
                scrollController: FixedExtentScrollController(initialItem: widget.selectedDates[0]!.year - widget.config.firstDate.year),
              ),
            ),
          ),
        ),
        Divider(
          color: widget.config.yearPickerDialogDividerColor ?? Color(0xFFE2EAFD),
          height: 1, 
        ),
      ],
    );
  }

  Widget _buildButtons() {
    double btnWidth = (MediaQuery.of(context).size.width - (40 * 2 + 16 * 2 + 10)) / 2;

    return Row(
      children: [
        PrimaryButton(
          label: widget.config.cancelStr,
          buttonHeight: 40,
          buttonWidth: btnWidth,
          borderColor: widget.config.yearPickerDialogCancelBtnBorderColor ?? const Color(0xFF375CB0),
          color: widget.config.yearPickerDialogCancelBtnColor ?? Colors.transparent,
          textColor: widget.config.yearPickerDialogCancelBtnTextColor ?? const Color(0xFF375CB0),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        const SizedBox(width: 10),
        PrimaryButton(
          label: widget.config.okayStr,
          buttonHeight: 40,
          buttonWidth: btnWidth,
          borderColor: widget.config.yearPickerDialogOkayBtnBorderColor ?? const Color(0xFF375CB0),
          color: widget.config.yearPickerDialogOkayBtnColor ?? const Color(0xFF375CB0),
          textColor: widget.config.yearPickerDialogOkayBtnTextColor ?? Colors.white,
          onPressed: () {
            Navigator.pop(context, (_selectedIndex + widget.config.firstDate.year).toString());
          },
        )
      ],
    );
  }

} 