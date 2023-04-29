import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:mysql1/mysql1.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Syncfusion Calendar Example',
      home: MyHomePage(),
    );
  }
}


class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}


class _MyHomePageState extends State<MyHomePage> {
  final List<Appointment> _meetings = <Appointment>[];
  String? _subjectText = '',
    _startTimeText = '',
    _endTimeText = '',
    _timeDetails = '';
  Color? _headerColor, _viewHeaderColor, _calendarColor;

  @override
  void initState() {
    super.initState();
    // Initialize state variables here
    _loadMeetings();
  }

  void calendarTapped(CalendarTapDetails details) {

  if (details.targetElement == CalendarElement.appointment || details.targetElement == CalendarElement.agenda) {
    final Appointment appointmentDetails = details.appointments![0];
    _subjectText = appointmentDetails.subject;
    _startTimeText = DateFormat('hh:mm').format(appointmentDetails.startTime).toString();
    _endTimeText =  DateFormat('hh:mm').format(appointmentDetails.endTime).toString();
    if (appointmentDetails.isAllDay) {
      _timeDetails = 'All day';
    } else {
      _timeDetails = 'De $_startTimeText\h jusqu\'à $_endTimeText\h';
    }
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Container(child: new Text('$_subjectText')),
            content: Container(
              height: 80,
              child: Column(
                children: <Widget>[
                  Row(
                    children: const <Widget>[
                      Text(
                        'Cours',
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: const <Widget>[
                      Text(''),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Text(_timeDetails!,
                          style: const TextStyle(
                              fontWeight: FontWeight.w400, fontSize: 15)),
                    ],
                  )
                ],
              ),
            ),
            actions: _getAction(details)
          );
        });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SfCalendar(
      view: CalendarView.month,
      dataSource: _getDataSource(),
      monthViewSettings: const MonthViewSettings(
          appointmentDisplayMode: MonthAppointmentDisplayMode.appointment
      ),
      onTap: calendarTapped,
    ));
  }

  Future<void> _loadMeetings() async {
    try {
      final meetings = await _getMeetings();
      setState(() {
        _meetings.clear();
        _meetings.addAll(meetings);
      });
    } catch (e) {
      // Handle error here
      print('Error while loading meetings: $e');
    }
  }

  Future<List<Appointment>> _getMeetings() async {
    final meetings = <Appointment>[];
    final settings = ConnectionSettings(
      host: 'localhost',
      port: 3306,
      user: 'root',
      db: 'tp_centre_equestre',
    );
    final conn = await MySqlConnection.connect(settings);
    final cours = await conn.query('SELECT * FROM cours');
    await conn.close();
    for (var uncours in cours) {
      meetings.add(Appointment(
        id: uncours['id_cours'],
        startTime: uncours['start_event'],
        endTime: uncours['end_event'],
        subject: uncours['title'],
      ));
    }
    return meetings;
  }

  //Première inscription à un cours
  void _participer(CalendarTapDetails details) async {
    final selectedAppointment = details.appointments?.first;
    final idCours = selectedAppointment.id;
    const idCav = 1; 
    final settings = ConnectionSettings(
      host: 'localhost',
      port: 3306,
      user: 'root',
      db: 'tp_centre_equestre',
    );
    final conn = await MySqlConnection.connect(settings);
    final coursSelected = await conn.query('SELECT id_week_cours FROM cours WHERE id_cours = ?', [idCours]);
    final idWeekCour = coursSelected.first['id_week_cour'];
  
    try{
      await conn.query('INSERT INTO participation(id_cour, id_week_cour, id_cav, actif) VALUES(?, ?, ?, ?)', [idCours, idWeekCour, idCav, 1]);
    } on MySqlException catch (e) {
      _reParticiper(details);
    } finally {
      await conn.close();
    }
    
    print('Selected appointment fields value: id = $idCours; idWeek = $idWeekCour; idCav = $idCav');
  }

  void _reParticiper(CalendarTapDetails details) async {
    final selectedAppointment = details.appointments?.first;
    final idCours = selectedAppointment.id;
    const actif = 1;
    const idCav = 1;
    final settings = ConnectionSettings(
      host: 'localhost',
      port: 3306,
      user: 'root',
      db: 'tp_centre_equestre',
    );
    final conn = await MySqlConnection.connect(settings);

    try{
      await conn.query('UPDATE participation SET actif = ? WHERE id_cour = ? AND id_cav = ?', [actif, idCours, idCav]);
    } on MySqlException catch (e) {
      throw Exception("Une erreur est survenue lors de la modification en base");
    } finally {
      await conn.close();
    }

  
  }



  void _seDesinscrire(CalendarTapDetails details) async {
    final selectedAppointment = details.appointments?.first;
    const actif = 0;
    final idCours = selectedAppointment.id;
    final settings = ConnectionSettings(
      host: 'localhost',
      port: 3306,
      user: 'root',
      db: 'tp_centre_equestre',
    );
    final conn = await MySqlConnection.connect(settings);

    try{
      await conn.query("UPDATE participation SET actif = ? WHERE id_cour = ?", [actif, idCours]);
    } on MySqlException catch (e) {
      throw Exception("Une erreur est survenue lors de la modification en base");
    } finally {
      await conn.close();
    }
  }

  Future<bool> _isInscrit(CalendarTapDetails details, int idCav) async{
    final selectedAppointment = details.appointments?.first;
    final idCours = selectedAppointment.id;
    final settings = ConnectionSettings(
      host: 'localhost',
      port: 3306,
      user: 'root',
      db: 'tp_centre_equestre',
    );
    final conn = await MySqlConnection.connect(settings);
    final sql = await conn.query('SELECT actif FROM participation WHERE id_cav = ? AND id_cour = ?', [idCav, idCours]);
    final isInscrit = sql.first['actif'];
    
    print (isInscrit);
    return true;
  }

  _getDataSource() {
    List<Appointment> meetings = _meetings;
    return _EventDataSource(meetings);
  }

  List<Widget> _getAction(details) {
    List<Widget> actions = [TextButton(
                onPressed: () {
                    Navigator.of(context).pop();
                },
                child: const Text('Annuler')
                
              ),];

    if (1 == 2) {
      actions.add(
        TextButton(
          onPressed: () {
            _participer(details);
            Navigator.of(context).pop();

          },
            child: const Text('S\'inscrire')
                ));
    } else  {
      actions.add(
        TextButton(
          onPressed: () {
            _seDesinscrire(details);
            Navigator.of(context).pop();

          },
            child: const Text('Se désinscrire')
                ));
    }

    return actions;
  }
}


class _EventDataSource extends CalendarDataSource {
  _EventDataSource(List<Appointment> source) {
    appointments = source;
  }
}
