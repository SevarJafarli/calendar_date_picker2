import 'package:flutter/material.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';


class MyHomePage extends StatefulWidget {
  final String title;
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Scheduled?> _singleDatePickerValueWithDefaultValue = [
    ScheduledDateTime(dt: DateTime.now()),
  ];
  late final CalendarDatePicker2Config config; 

  bool _isInRepeatedMode = false;
  final CalendarController calendarController = CalendarController();
  String value = "";
  
  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    // DateTime firstDate = DateTime(1907, 1, 1);
    // DateTime lastDate = DateTime(now.year, now.month, now.day);
    DateTime firstDate = DateTime(now.year, now.month, now.day);
    DateTime lastDate = DateTime(now.year + 10, now.month, now.day);

    config = CalendarDatePicker2Config(
      // firstDate: DateTime(now.year - 120, now.month, now.day),
      // lastDate: DateTime(now.year, now.month, now.day),
      firstDate: firstDate,
      lastDate: lastDate,
      weekdayLabelTextStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.25, height: 17.07 / 14),
      selectedWeekdayTextStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.25, height: 17.07 / 14, color: Color(0xFF3C69D1)),
      weekdayLabels: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
      firstDayOfWeek: 1,
      dayBorderRadius: BorderRadius.circular(10),
      weekdayBorderRadius: BorderRadius.circular(10),
      controlsHeight: 62, // 40 + 22
      dayTextStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25, height: 17.07 / 14),
      disabledDayTextStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25, height: 17.07 / 14, color: Colors.red), // Color(0xFF848CA0) //! todo:change
      selectedDayTextStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.25, height: 17.07 / 14, color: Color(0xFF3C69D1)),
      controlsTextStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25, height: 17.07 / 14, color: Color(0xFF848CA0)),
      selectedDayHighlightColor: Colors.white.withOpacity(0.8),
      selectedDayBoxShadows: [BoxShadow(blurRadius: 5, color: Colors.black.withOpacity(0.05))],
      selectedWeekdayHighlightColor: Colors.white.withOpacity(0.8),
      selectedWeekdayBoxShadows: [BoxShadow(blurRadius: 5, color: Colors.black.withOpacity(0.05))],
      todayHighlightColor: Colors.transparent,
      // todayTextStyle: ,
      pastOrFutureDaysTextStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25, height: 17.07 / 14, color: Color(0xFF848CA0)),
      splashRadius: 0.0,
      selectableDayPredicate: (day) => !day.isBefore(firstDate) && !day.isAfter(lastDate),
      focusedYearTextStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w400, height: 29.26 / 24, color: Color(0xFF375CB0)),
      // selectedYearTextStyle: ,
      yearTextStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25, height: 17.07 / 14, color: Color(0xFF273B4A))
    );

    calendarController.listen((s) { 
      setState(() {
        _singleDatePickerValueWithDefaultValue = [s];  
        value = s.toString();
      });
    });
  }

  @override
  void dispose() {
    calendarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: SizedBox(
          // width: 375,
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              _buildDefaultSingleDatePickerWithValue(),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildDefaultSingleDatePickerWithValue() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CalendarDatePicker2(
          controller: calendarController,
          config: config,
          initialValue: _singleDatePickerValueWithDefaultValue, 
          includeTimePicker: true,
          isInRepeatedMode: _isInRepeatedMode
        ), 
        const SizedBox(height: 25),
        ElevatedButton(onPressed: () { setState(() {
          _isInRepeatedMode = !_isInRepeatedMode;
        }); }, child: Container(height: 50, width: 50, color: Colors.red)),
        Text(value),
      ],
    );
  }  
}