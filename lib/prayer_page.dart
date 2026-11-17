import 'dart:io';
import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

const _green = Color(0xFF176B45);
final _notifier = FlutterLocalNotificationsPlugin();

Future<Position> _getPosition() async {
  if (!await Geolocator.isLocationServiceEnabled()) throw Exception('فعّل خدمة الموقع GPS.');
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
  if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
    throw Exception('اسمح للتطبيق باستخدام الموقع لحساب المواقيت.');
  }
  return Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
}

Future<void> _initAlerts() async {
  tzdata.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Africa/Cairo'));
  await _notifier.initialize(const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')));
  final android = _notifier.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  await android?.requestNotificationsPermission();
  await android?.requestExactAlarmsPermission();
}

DateTime _getTime(Coordinates c, DateTime d, Prayer prayer) {
  final params = CalculationMethod.egyptian.getParameters()..madhab = Madhab.shafi;
  final value = PrayerTimes(c, DateComponents(d.year, d.month, d.day), params).timeForPrayer(prayer);
  if (value == null) throw StateError('تعذر حساب موعد الصلاة');
  return value;
}
String _timeText(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return h.toString() + ':' + d.minute.toString().padLeft(2, '0') + (d.hour < 12 ? ' ص' : ' م');
}

Future<void> _scheduleAlerts(Coordinates c, int iqama) async {
  await _initAlerts();
  await _notifier.cancelAll();
  const details = NotificationDetails(android: AndroidNotificationDetails(
    'noor_prayers', 'تنبيهات الصلاة',
    channelDescription: 'تنبيه قبل الصلاة وعند دخول الوقت وموعد الإقامة',
    importance: Importance.max, priority: Priority.high, playSound: true, enableVibration: true,
  ));
  final now = DateTime.now();
  const prayers = [Prayer.fajr, Prayer.dhuhr, Prayer.asr, Prayer.maghrib, Prayer.isha];
  const names = ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'];
  for (var day = 0; day < 7; day++) {
    final date = DateTime(now.year, now.month, now.day + day);
    for (var i = 0; i < prayers.length; i++) {
      final at = _getTime(c, date, prayers[i]);
      final events = [at.subtract(const Duration(minutes: 10)), at, at.add(Duration(minutes: iqama))];
      final labels = ['باقي 10 دقائق على صلاة ' + names[i], 'حان الآن وقت صلاة ' + names[i], 'موعد الإقامة لصلاة ' + names[i]];
      for (var kind = 0; kind < events.length; kind++) {
        if (!events[kind].isAfter(now)) continue;
        await _notifier.zonedSchedule(
          day * 100 + i * 3 + kind + 1,
          kind == 0 ? 'تنبيه الصلاة' : (kind == 1 ? 'حان وقت الصلاة' : 'موعد الإقامة'),
          labels[kind],
          tz.TZDateTime.from(events[kind], tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
    }
  }
}


class PrayerHomeSummary extends StatefulWidget {
  const PrayerHomeSummary({super.key});
  @override State<PrayerHomeSummary> createState()=>_PrayerHomeSummaryState();
}
class _PrayerHomeSummaryState extends State<PrayerHomeSummary> {
  Position? position;
  bool loading=true;
  String? error;
  DateTime now=DateTime.now();
  Timer? ticker;
  @override void initState(){super.initState();_load();ticker=Timer.periodic(const Duration(seconds:1),(_){if(mounted)setState(()=>now=DateTime.now());});}
  Future<void> _load() async {
    try {
      final p=await _getPosition();
      if(!mounted)return;
      setState(()=>position=p);
    } catch(e) {
      if(!mounted)return;
      setState(()=>error=e.toString().replaceFirst('Exception: ',''));
    } finally {if(mounted)setState(()=>loading=false);}
  }
  @override void dispose(){ticker?.cancel();super.dispose();}
  @override Widget build(BuildContext context){
    final p=position;
    final coordinates=p==null?null:Coordinates(p.latitude,p.longitude);
    final today=coordinates==null?null:PrayerTimes.today(coordinates,CalculationMethod.egyptian.getParameters()..madhab=Madhab.shafi);
    final rows=today==null?<MapEntry<String,DateTime>>[]:[
      MapEntry('الفجر',today.fajr),MapEntry('الشروق',today.sunrise),MapEntry('الظهر',today.dhuhr),MapEntry('العصر',today.asr),MapEntry('المغرب',today.maghrib),MapEntry('العشاء',today.isha)
    ];
    MapEntry<String,DateTime>? next;
    for(final row in rows){if(row.value.isAfter(now)){next=row;break;}}
    next ??= coordinates==null?null:MapEntry('الفجر',_getTime(coordinates,DateTime(now.year,now.month,now.day+1),Prayer.fajr));
    final remaining=next==null?null:next.value.difference(now);
    String countdown(Duration d){final h=d.inHours.toString().padLeft(2,'0');final m=(d.inMinutes%60).toString().padLeft(2,'0');final s=(d.inSeconds%60).toString().padLeft(2,'0');return '\$h:\$m:\$s';}
    return Card(color:Colors.white,child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      const Text('مواقيت الصلاة اليوم',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold,color:_green)),
      const SizedBox(height:8),
      if(loading) const Center(child:Padding(padding:EdgeInsets.all(12),child:CircularProgressIndicator())),
      if(error!=null) Text(error!,style:const TextStyle(color:Colors.red)),
      if(rows.isNotEmpty) Wrap(alignment:WrapAlignment.spaceBetween,runSpacing:10,children:[
        for(final row in rows) SizedBox(width:MediaQuery.of(context).size.width/3.8,child:Column(children:[
          Text(row.key,style:const TextStyle(color:Colors.black54,fontSize:13)),
          Text(_timeText(row.value),style:const TextStyle(fontSize:16,fontWeight:FontWeight.bold,color:_green)),
        ])),
      ]),
      if(next!=null&&remaining!=null) Container(margin:const EdgeInsets.only(top:14),padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:_green.withValues(alpha:.08),borderRadius:BorderRadius.circular(14)),child:Column(children:[
        Text('الصلاة القادمة: \${next.key}',style:const TextStyle(fontWeight:FontWeight.bold,fontSize:17,color:_green)),
        const SizedBox(height:4),const Text('متبقي على الصلاة',style:TextStyle(color:Colors.black54)),
        Text(countdown(remaining.isNegative?Duration.zero:remaining),style:const TextStyle(fontSize:30,fontWeight:FontWeight.bold,color:_green,letterSpacing:2)),
      ])),
      if(p==null) Align(alignment:Alignment.centerLeft,child:TextButton.icon(onPressed:loading?null:_load,icon:const Icon(Icons.my_location),label:const Text('تحديد موقعي لعرض المواقيت'))),
    ])));
  }
}

class PrayerPage extends StatefulWidget {
  const PrayerPage({super.key});
  @override State<PrayerPage> createState() => _PrayerPageState();
}
class _PrayerPageState extends State<PrayerPage> {
  Position? position;
  String? error;
  bool loading = false, alerts = false;
  int iqama = 10;
  String? audioPath;
  final AudioPlayer audioPlayer = AudioPlayer();

  @override void initState() { super.initState(); _loadSettings(); _locate(); }
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() { alerts = prefs.getBool('prayer_alerts') ?? false; iqama = prefs.getInt('iqama_delay') ?? 10; audioPath = prefs.getString('adhan_audio_path'); });
  }
  Future<void> _locate() async {
    setState(() { loading = true; error = null; });
    try {
      final p = await _getPosition();
      if (!mounted) return;
      setState(() { position = p; loading = false; });
      if (alerts) await _refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() { error = e.toString().replaceFirst('Exception: ', ''); loading = false; });
    }
  }
  Future<void> _refresh() async {
    if (position == null) return;
    await _scheduleAlerts(Coordinates(position!.latitude, position!.longitude), iqama);
  }
  Future<void> _toggle(bool value) async {
    if (value && position == null) { await _locate(); if (position == null) return; }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('prayer_alerts', value);
    setState(() => alerts = value);
    if (value) {
      try { await _refresh(); _msg('تم ضبط التنبيهات للأيام السبعة القادمة.'); }
      catch (e) { setState(() => alerts = false); _msg('تعذر ضبط التنبيهات: ' + e.toString()); }
    } else { await _notifier.cancelAll(); _msg('تم إيقاف التنبيهات.'); }
  }
  Future<void> _setIqama(int? v) async {
    if (v == null) return;
    setState(() => iqama = v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('iqama_delay', v);
    if (alerts) await _refresh();
  }
  Future<void> _chooseAdhan() async {
    final result = await FilePicker.pickFile(type: FileType.audio);
    if (result == null) return;
    final picked = result;
    final bytes = await picked.readAsBytes();
    final ext = picked.extension ?? 'audio';
    final dir = await getApplicationDocumentsDirectory();
    final path = dir.path + '/adhan_' + DateTime.now().millisecondsSinceEpoch.toString() + '.' + ext;
    final file = await File(path).writeAsBytes(bytes, flush: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('adhan_audio_path', file.path);
    if (!mounted) return;
    setState(() => audioPath = file.path);
    _msg('تم حفظ ملف الأذان داخل التطبيق.');
  }
  Future<void> _previewAdhan() async {
    if (audioPath == null) return;
    try { await audioPlayer.setFilePath(audioPath!); await audioPlayer.play(); }
    catch (e) { _msg('تعذر تشغيل الملف: ' + e.toString()); }
  }
  void _msg(String s) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s))); }

  @override void dispose() { audioPlayer.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final p = position;
    final today = DateTime.now();
    final times = p == null ? null : PrayerTimes.today(
      Coordinates(p.latitude, p.longitude),
      CalculationMethod.egyptian.getParameters()..madhab = Madhab.shafi,
    );
    final rows = times == null ? <MapEntry<String, DateTime>>[] : [
      MapEntry('الفجر', times.fajr), MapEntry('الشروق', times.sunrise),
      MapEntry('الظهر', times.dhuhr), MapEntry('العصر', times.asr),
      MapEntry('المغرب', times.maghrib), MapEntry('العشاء', times.isha),
    ];
    return ListView(padding: const EdgeInsets.all(16), children: [
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('مواقيت الصلاة اليوم', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: _green)),
        Text(today.day.toString() + '/' + today.month.toString() + '/' + today.year.toString()),
        if (loading) const Center(child: CircularProgressIndicator()),
        if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
        for (final row in rows) ListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text(row.key), trailing: Text(_timeText(row.value), style: const TextStyle(fontSize: 18, color: _green, fontWeight: FontWeight.bold))),
        OutlinedButton.icon(onPressed: loading ? null : _locate, icon: const Icon(Icons.my_location), label: const Text('تحديث موقعي')),
      ]))),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('تنبيهات الصلاة', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: _green)),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('تفعيل التنبيهات'), subtitle: const Text('قبل الصلاة بـ10 دقائق، وعند دخول الوقت، ثم الإقامة'), value: alerts, onChanged: _toggle),
        Row(children: [
          const Expanded(child: Text('الإقامة بعد الأذان')),
          DropdownButton<int>(value: iqama, items: [5, 10, 15, 20, 25, 30].map((v) => DropdownMenuItem(value: v, child: Text(v.toString() + ' دقائق'))).toList(), onChanged: _setIqama),
        ]),
        const Divider(),
        const Text('صوت الأذان من الهاتف', style: TextStyle(fontWeight: FontWeight.bold)),
        Text(audioPath == null ? 'لم يتم اختيار ملف صوتي.' : 'تم حفظ ملف صوتي مخصص.'),
        Wrap(spacing: 8, children: [
          OutlinedButton.icon(onPressed: _chooseAdhan, icon: const Icon(Icons.audio_file), label: const Text('اختيار ملف')),
          FilledButton.tonalIcon(onPressed: audioPath == null ? null : _previewAdhan, icon: const Icon(Icons.play_arrow), label: const Text('تشغيل تجريبي')),
        ]),
        const Text('التنبيه المجدول يستخدم صوت إشعار الهاتف. تشغيل ملف الأذان كاملًا تلقائيًا والهاتف مغلق يحتاج خدمة صوت خلفية مستقلة، ولم أفعّلها بعد.', style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.5)),
        const Text('طريقة الحساب: الهيئة المصرية العامة للمساحة. يلزم السماح بالموقع والإشعارات.', style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.5)),
      ]))),
    ]);
  }
}

class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key});
  @override State<QiblaPage> createState() => _QiblaPageState();
}
class _QiblaPageState extends State<QiblaPage> {
  double? bearing; String? error; bool loading = false;
  Future<void> _calculate() async {
    setState(() { loading = true; error = null; });
    try {
      final p = await _getPosition();
      final value = Qibla(Coordinates(p.latitude, p.longitude)).direction;
      if (!mounted) return;
      setState(() { bearing = value; loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { error = e.toString().replaceFirst('Exception: ', ''); loading = false; });
    }
  }
  @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.explore, size: 64, color: _green),
    const Text('اتجاه القبلة', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
    if (loading) const CircularProgressIndicator(),
    if (bearing != null) Text(bearing!.toStringAsFixed(1) + '°', style: const TextStyle(fontSize: 42, color: _green, fontWeight: FontWeight.bold)),
    if (bearing != null) const Text('الزاوية من الشمال الجغرافي، وليست اتجاه الهاتف اللحظي.'),
    if (error != null) Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
    FilledButton.icon(onPressed: loading ? null : _calculate, icon: const Icon(Icons.my_location), label: const Text('تحديد القبلة من موقعي')),
  ])));
}
