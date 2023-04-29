import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:mysql1/mysql1.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';


Future<int> idPers = _MyLoginPageState._getId();

void main() {
  runApp(MyApp());
}



class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
                        GlobalMaterialLocalizations.delegate,
                        GlobalWidgetsLocalizations.delegate,
                        SfGlobalLocalizations.delegate
                ],
                supportedLocales: const [
                        Locale('en'),
                        Locale('fr')
                ],
                locale: const Locale('fr'),
      title: 'Centre Equestre',
      home: MyLoginPage(),
    );
  }
}



class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}



class MyLoginPage extends StatefulWidget {
  @override
  State<MyLoginPage> createState() => _MyLoginPageState();
}



class _MyLoginPageState extends State<MyLoginPage> {
  static String? _login = '';
  static String? _mdp = '';
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('S\'identifier'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Identifiant (mail)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Entrez votre adresse mail';
                  }
                  return null;
                },
                onSaved: (value) {
                  _login = value;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Mot de passe',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Entrez votre mot de passe';
                  }
                  return null;
                },
                onSaved: (value) {
                  _mdp = value;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState?.save();
                    if (await _seConnecter(_login, _mdp)){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MyHomePage()),
                      );
                    }
                    else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Container(
                            padding: EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.all(Radius.circular(20)),
                            ),
                            child: Column( 
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text("Impossible de se connecter :", style: TextStyle(fontSize: 18)),
                                Text("Le mail et le mot de passe ne correspondent pas. Veuillez réesayer."),
                              ]
                            )
                          ),
                          backgroundColor: Colors.transparent,
                          behavior: SnackBarBehavior.floating,
                          elevation: 0,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Se connecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<int> _getId() async {
    final conn = await DatabaseHelper.getConnection();
    final idPersSql = await conn.query('SELECT id_utilisateur FROM utilisateur WHERE nom_utilisateur = ?', [_MyLoginPageState._login]);
    final idPers = idPersSql.first['id_utilisateur'];

    return Future.value(idPers);
  }

  Future<bool> _seConnecter(login, mdp) async {
    final hashmdp = md5.convert(utf8.encode(mdp)).toString();
    final conn = await DatabaseHelper.getConnection();
    const sql = 'SELECT * FROM utilisateur WHERE nom_utilisateur = ? AND mdp = ?';
    final result = await conn.query(sql, [login, hashmdp]);

    return result.length == 1;
  }
}



class _MyHomePageState extends State<MyHomePage> {

  final List<_MyAppointment> _meetings = <_MyAppointment>[];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SfCalendar(
        view: CalendarView.day,
        allowedViews: const [CalendarView.day, CalendarView.week, CalendarView.month],
        minDate: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, DateTime.now().hour),
        dataSource: _getDataSource(),
        monthViewSettings: const MonthViewSettings(
            appointmentDisplayMode: MonthAppointmentDisplayMode.appointment
        ),
        onTap: calendarTapped,
      )
    );
  }

  void calendarTapped(CalendarTapDetails details) {

    if (details.targetElement == CalendarElement.appointment || details.targetElement == CalendarElement.agenda) {
      final _MyAppointment appointmentDetails = details.appointments![0];
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
              actions: [
                FutureBuilder<List<Widget>>(
                  future: _getAction(details),
                  builder: (context, snapshot) {
                    if(snapshot.connectionState == ConnectionState.done){
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: snapshot.data!,
                );
                    } else {
                      return Text('Aucune données trouvées');
                    }
                  }
                )
              ]
            );
          });
    }
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

  //Resources
  final List<CalendarResource> _resources = <CalendarResource>
  [
    CalendarResource(
      displayName: 'Inscrit',
      id: '1',
      color: Colors.grey,
    ),
    CalendarResource(
      displayName: 'Désinscrit',
      id: '2',
      color: Colors.blue,
    ),
  ];

  //Appointments
  Future<List<_MyAppointment>> _getMeetings() async {
    final meetings = <_MyAppointment>[];
    final conn = await DatabaseHelper.getConnection();
    final cours = await conn.query('SELECT * FROM cours WHERE actif = ?', [1]);
    //TODO: afficher seulement les cours qui n'ont pas commencé.
    // final cours = await conn.query('SELECT * FROM cours WHERE start_event > SQL_NOW() ');

    for (var uncours in cours) {
      final idCours = uncours['id_cours'];
      final idWeekCours = uncours['id_week_cours'];
      final isInscrit = await _isInscritById(idPers, idCours, idWeekCours);
      print('isInscrit to $idCours - $idWeekCours :');
      print(isInscrit);
      
      meetings.add(_MyAppointment(
        id: idCours,
        idWeekCours: idWeekCours,
        startTime: uncours['start_event'],
        endTime: uncours['end_event'],
        subject: uncours['title'],
        color: isInscrit ? _resources.firstWhere((res) => res.id == '2').color : _resources.firstWhere((res) => res.id == '1').color ,
        resourceIds: (isInscrit) ? ['2'] : ['1']
      ));
    }
    await conn.close();
    return meetings;
  }

  //Première inscription à un cours
  void _participer(CalendarTapDetails details) async {
    final selectedAppointment = details.appointments?.first;
    final idCours = selectedAppointment.id;
    final conn = await DatabaseHelper.getConnection();
    final idWeekCours = selectedAppointment.idWeekCours;
  
    try{
      await conn.query('INSERT INTO participation(id_cour, id_week_cour, id_cav, actif) VALUES(?, ?, ?, ?)', [idCours, idWeekCours, await idPers, 1]);
    } on MySqlException catch (e){
      print(e);
      _reParticiper(details);
    } finally {
      await conn.close();
      _loadMeetings();
    }
    
    print('Selected appointment fields value: id = $idCours; idWeek = $idWeekCours; idCav = $idPers');
  }

  void _participerAll(CalendarTapDetails details) async {
    final selectedAppointment = details.appointments?.first;
    final idCours = selectedAppointment.id;
    final conn = await DatabaseHelper.getConnection();

    final coursSelected = await conn.query('SELECT id_week_cours FROM cours WHERE id_cours = ?', [idCours]);
    final idsWeekCour = coursSelected;
  
    for (var idweek in idsWeekCour) {
      try{  
          int idWeekCours = idweek['id_week_cours'];
          await conn.query('INSERT INTO participation(id_cour, id_week_cour, id_cav, actif) VALUES(?, ?, ?, ?)', [idCours, idWeekCours, await idPers, 1]);
          print('Selected appointment fields value: id = $idCours; idWeek = $idWeekCours; idCav = $idPers');    
      } on MySqlException catch (e) {
        print(e);
        _reParticiperAll(details);
      } 
    }
    await conn.close();
    _loadMeetings();    
  }

  void _reParticiper(CalendarTapDetails details) async {
    final selectedAppointment = details.appointments?.first;
    final idCours = selectedAppointment.id;
    final idWeekCours = selectedAppointment.idWeekCours;
    const actif = 1;
    final conn = await DatabaseHelper.getConnection();

    try{
      await conn.query('UPDATE participation SET actif = ? WHERE id_cour = ? AND id_cav = ? AND id_week_cour = ?', [actif, idCours, await idPers, idWeekCours]);
    } on MySqlException catch (e) {
      throw Exception("Une erreur est survenue lors de la modification en base : $e");
    } finally {
      await conn.close();
      _loadMeetings();
    } 
  }

  void _reParticiperAll(CalendarTapDetails details) async {
    final selectedAppointment = details.appointments?.first;
    final idCours = selectedAppointment.id;
    const actif = 1;
    final conn = await DatabaseHelper.getConnection();

    final coursSelected = await conn.query('SELECT id_week_cours FROM cours WHERE id_cours = ?', [idCours]);
    final idsWeekCour = coursSelected;
    await conn.close();
  
    try{
      for (var idweek in idsWeekCour) {
        final conn = await DatabaseHelper.getConnection();
        try{
          int idWeekCours = idweek['id_week_cours'];
          await conn.query('UPDATE participation SET actif = ? WHERE id_cour = ? AND id_week_cour = ? AND id_cav = ?', [actif, idCours, idWeekCours, await idPers]);
        } on MySqlException catch (e) {
          throw Exception("Une erreur est survenue lors de la modification en base : $e");
        } finally {
          await conn.close();
        }
      }
    } finally {
      _loadMeetings();
    } 
  }

  void _seDesinscrire(CalendarTapDetails details) async {
    final selectedAppointment = details.appointments?.first;
    const actif = 0;
    final idCours = selectedAppointment.id;
    final idWeekCours = selectedAppointment.idWeekCours;
    final conn = await DatabaseHelper.getConnection();

    try{
      await conn.query("UPDATE participation SET actif = ? WHERE id_cour = ? AND id_week_cour = ? AND id_cav = ?", [actif, idCours, idWeekCours, await idPers]);
    } on MySqlException catch (e) {
      throw Exception("Une erreur est survenue lors de la modification en base");
    } finally {
      await conn.close();
      _loadMeetings();
    }
  }

  void _seDesinscrireAll(CalendarTapDetails details) async {
    final selectedAppointment = details.appointments?.first;
    const actif = 0;
    final idCours = selectedAppointment.id;
    final conn = await DatabaseHelper.getConnection();

    final coursSelected = await conn.query('SELECT id_week_cours FROM cours WHERE id_cours = ?', [idCours]);
    final idsWeekCour = coursSelected;
    await conn.close();
  
    
      try{
        for (var idweek in idsWeekCour) {
          final conn = await DatabaseHelper.getConnection();
          try{
            int idWeekCours = idweek['id_week_cours'];
            await conn.query("UPDATE participation SET actif = ? WHERE id_cour = ? AND id_week_cour = ? AND id_cav = ?", [actif, idCours, idWeekCours, await idPers]);
          } on MySqlException catch (e) {
            throw Exception("Une erreur est survenue lors de la modification en base"); 
          } finally {
            await conn.close();
          }
        }  
      } finally {
        _loadMeetings();
      }
  }

  Future<bool> _isInscritById(idPers, idCours, idWeekCours) async{
    final conn = await DatabaseHelper.getConnection();

    try{
      final sql = await conn.query('SELECT actif FROM participation WHERE id_cav = ? AND id_cour = ? AND id_week_cour = ?', [await idPers, idCours, idWeekCours]);
      final isInscrit = sql.first['actif'];
      return isInscrit == 1;
    } catch (e){
      return false;
    }  
  }

  Future<bool> _isInscrit(CalendarTapDetails details) async{
    print("Id utilisateur : ");
    print(await idPers);
    final selectedAppointment = details.appointments?.first;
    final idCours = selectedAppointment.id;
    final idWeekCours = selectedAppointment.idWeekCours;
    final conn = await DatabaseHelper.getConnection();

  try{
    final sql = await conn.query('SELECT actif FROM participation WHERE id_cav = ? AND id_cour = ? AND id_week_cour = ?', [await idPers, idCours, idWeekCours]);
    final isInscrit = sql.first['actif'];
    return isInscrit == 1;
  } catch (e){
    return false;
  }
    
    
  }

  Future<List<Widget>> _getAction(details) async {
    List<Widget> actions = 
    [
      TextButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text('Annuler')
      ),
    ];

    if(await _isInscrit(details)){
      actions.add(
        TextButton(
          style: const ButtonStyle(
            foregroundColor: MaterialStatePropertyAll<Color>(Colors.red)
          ),
          onPressed: () {
            _seDesinscrire(details);
            Navigator.of(context).pop();
          },
          child: const Text('Se désinscrire')
        )
      );
      actions.add(
        TextButton(
          style: const ButtonStyle(
            foregroundColor: MaterialStatePropertyAll<Color>(Colors.red)
          ),
          onPressed: () {
            _seDesinscrireAll(details);
            Navigator.of(context).pop();
          },
          child: const Text('Se désinscrire de tous les cours')
        )
      );
    } else {
      actions.add(
        TextButton(
          onPressed: () {
            _participer(details);
            Navigator.of(context).pop();
          },
          child: const Text('S\'inscrire')
        )
      );
      actions.add(
        TextButton(
          onPressed: () {
            _participerAll(details);
            Navigator.of(context).pop();
          },
          child: const Text('S\'inscrire à tous les cours')
        )
      );
    }

    return actions;
  }

  _getDataSource() {
    return _EventDataSource(_meetings, _resources);
  }

}



class _EventDataSource extends CalendarDataSource {
  _EventDataSource(List<_MyAppointment> source,  List<CalendarResource> resourceColl) {
    appointments = source;
    resources = resourceColl;
  }
}



class _MyAppointment extends Appointment {

  int ?idWeekCours;

  final bool isInscrit;
  _MyAppointment({
    required super.startTime,
    required super.endTime,
    super.id,
    this.idWeekCours,
    super.subject,
    super.color,
    super.resourceIds,
    }) : isInscrit = false;

  Future<bool> _isInscrit(int idCav) async{
    print("isIncrit method launched");
    final idCours = this.id;
    final conn = await DatabaseHelper.getConnection();

    try {
      final sql = await conn.query('SELECT actif FROM participation WHERE id_cav = ? AND id_cour = ?', [idCav, idCours]);
      final isInscrit = sql.first['actif'];
    } on StateError catch (e) {
      print("Catch!");
      const isInscrit = 0;
    }
    
    if(isInscrit == 1) {
      return true;
    }
    else {
      return false;
    }
  }
}

