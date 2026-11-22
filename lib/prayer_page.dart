import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_widget/home_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:math' as math;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

const _green = Color(0xFF493326);
final _notifier = FlutterLocalNotificationsPlugin();
const _adhanChannel = MethodChannel('noor_adhan_background');
final ValueNotifier<int> prayerSettingsVersion = ValueNotifier(0);

final Map<String, Coordinates> _knownCities = {
  'المنيا': Coordinates(28.1099, 30.7503),
  'دير مواس': Coordinates(27.6418, 30.85175),
  'دلجا': Coordinates(27.64343, 30.69962),
  'القاهرة': Coordinates(30.0444, 31.2357),
  'الجيزة': Coordinates(30.0131, 31.2089),
  'الإسكندرية': Coordinates(31.2001, 29.9187),
  'أسيوط': Coordinates(27.1809, 31.1837),
  'سوهاج': Coordinates(26.5591, 31.6957),
  'قنا': Coordinates(26.1551, 32.7160),
  'الأقصر': Coordinates(25.6872, 32.6396),
  'أسوان': Coordinates(24.0889, 32.8998),
  'بني سويف': Coordinates(29.0661, 31.0994),
  'الفيوم': Coordinates(29.3084, 30.8428),
  'بورسعيد': Coordinates(31.2653, 32.3019),
  'الإسماعيلية': Coordinates(30.5965, 32.2715),
  'السويس': Coordinates(29.9668, 32.5498),
};

CalculationParameters _parameters(String key) {
  final method = switch (key) {
    'umm_al_qura' => CalculationMethod.umm_al_qura,
    'muslim_world_league' => CalculationMethod.muslim_world_league,
    'karachi' => CalculationMethod.karachi,
    'north_america' => CalculationMethod.north_america,
    'kuwait' => CalculationMethod.kuwait,
    'qatar' => CalculationMethod.qatar,
    'singapore' => CalculationMethod.singapore,
    'turkey' => CalculationMethod.turkey,
    _ => CalculationMethod.egyptian,
  };
  return method.getParameters()..madhab = Madhab.shafi;
}

Future<Coordinates> _configuredCoordinates() async {
  final prefs = await SharedPreferences.getInstance();
  final lat = prefs.getDouble('prayer_latitude');
  final lon = prefs.getDouble('prayer_longitude');
  if (lat != null && lon != null) return Coordinates(lat, lon);
  final p = await _getPosition();
  await prefs.setDouble('prayer_latitude', p.latitude);
  await prefs.setDouble('prayer_longitude', p.longitude);
  await prefs.setString('prayer_city', 'الموقع الحالي');
  return Coordinates(p.latitude, p.longitude);
}

Future<Position> _getPosition() async {
  if (!await Geolocator.isLocationServiceEnabled()) throw Exception('فعّل خدمة الموقع GPS.');
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
  if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
    throw Exception('اسمح للتطبيق باستخدام الموقع لحساب المواقيت.');
  }
  return Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.best,
      timeLimit: Duration(seconds: 25),
    ),
  );
}

Future<String> _reverseGeocode(double latitude, double longitude) async {
  final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
    'format': 'jsonv2',
    'lat': latitude.toString(),
    'lon': longitude.toString(),
    'zoom': '14',
    'addressdetails': '1',
  });
  final response = await http.get(uri, headers: const {
    'User-Agent': 'NoorAlIslam/1.0 (Android prayer times app)',
    'Accept-Language': 'ar',
  }).timeout(const Duration(seconds: 12));
  if (response.statusCode != 200) {
    throw Exception('تعذر تحويل إحداثيات GPS إلى اسم مدينة (HTTP ${response.statusCode}).');
  }
  final data = jsonDecode(response.body) as Map<String, dynamic>;
  final address = data['address'] as Map<String, dynamic>? ?? {};
  final parts = [
    address['city'],
    address['town'],
    address['village'],
    address['municipality'],
    address['county'],
    address['state'],
    address['country'],
  ].where((value) => value != null && value.toString().trim().isNotEmpty)
   .map((value) => value.toString().trim()).toList();
  if (parts.isEmpty) throw Exception('تم تحديد الإحداثيات لكن لم نتمكن من معرفة اسم المدينة.');
  return parts.toSet().join('، ');
}

Future<void> _initAlerts() async {
  tzdata.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Africa/Cairo'));
  await _notifier.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );
  final android =
      _notifier.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  await android?.requestNotificationsPermission();
  await android?.requestExactAlarmsPermission();
  await android?.createNotificationChannel(
    const AndroidNotificationChannel(
      'noor_prayers',
      'تنبيهات الصلاة',
      description: 'تنبيه قبل الصلاة وعند دخول الوقت وموعد الإقامة',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    ),
  );
}

DateTime _getTime(Coordinates c, DateTime d, Prayer prayer, [String methodKey = 'egyptian']) {
  final value = PrayerTimes(c, DateComponents(d.year, d.month, d.day), _parameters(methodKey)).timeForPrayer(prayer);
  if (value == null) throw StateError('تعذر حساب موعد الصلاة');
  return value;
}
String _timeText(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return h.toString() + ':' + d.minute.toString().padLeft(2, '0') + (d.hour < 12 ? ' ص' : ' م');
}

Future<void> _syncPrayerTimesWidget(Coordinates coordinates, String methodKey) async {
  try {
    final now = DateTime.now();
    const keys = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
    const prayers = [Prayer.fajr, Prayer.dhuhr, Prayer.asr, Prayer.maghrib, Prayer.isha];
    for (var dayIndex = 0; dayIndex < 7; dayIndex++) {
      final date = DateTime(now.year, now.month, now.day + dayIndex);
      final dateStart = DateTime(date.year, date.month, date.day);
      await HomeWidget.saveWidgetData<int>('prayer_day_${dayIndex}_date_epoch', dateStart.millisecondsSinceEpoch);
      for (var prayerIndex = 0; prayerIndex < prayers.length; prayerIndex++) {
        final time = _getTime(coordinates, date, prayers[prayerIndex], methodKey);
        await HomeWidget.saveWidgetData<int>('prayer_day_${dayIndex}_${keys[prayerIndex]}_epoch', time.millisecondsSinceEpoch);
        if (dayIndex == 0) {
          await HomeWidget.saveWidgetData<String>('prayer_${keys[prayerIndex]}', _timeText(time));
          await HomeWidget.saveWidgetData<String>('prayer_day_0_${keys[prayerIndex]}', _timeText(time));
        }
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await HomeWidget.saveWidgetData<String>('prayer_widget_city', prefs.getString('prayer_city') ?? 'موقعي');
    await HomeWidget.updateWidget(androidName: 'PrayerTimesWidgetProvider');
  } catch (_) { }
}

Future<void> _scheduleAlerts(Coordinates c, int iqama, String methodKey, String? selectedAudioPath, String? selectedIqamaAudioPath, double adhanVolume) async {
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
  final adhanTimes = <int>[];
  final iqamaTimes = <int>[];
  for (var day = 0; day < 7; day++) {
    final date = DateTime(now.year, now.month, now.day + day);
    for (var i = 0; i < prayers.length; i++) {
      final at = _getTime(c, date, prayers[i], methodKey);
      if (at.isAfter(now)) adhanTimes.add(at.millisecondsSinceEpoch);
      final iqamaAt = at.add(Duration(minutes: iqama));
      if (iqamaAt.isAfter(now)) iqamaTimes.add(iqamaAt.millisecondsSinceEpoch);
      final events = [at.subtract(const Duration(minutes: 10)), at, iqamaAt];
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
  await _adhanChannel.invokeMethod('scheduleAdhan', {
    'times': adhanTimes,
    'audioPath': selectedAudioPath,
    'volume': adhanVolume,
    'iqamaTimes': iqamaTimes,
    'iqamaAudioPath': selectedIqamaAudioPath,
  }).catchError((_) {});
}


class PrayerHomeSummary extends StatefulWidget {
  const PrayerHomeSummary({super.key});
  @override State<PrayerHomeSummary> createState()=>_PrayerHomeSummaryState();
}
class _PrayerHomeSummaryState extends State<PrayerHomeSummary> {
  Coordinates? coordinates;
  bool loading=true;
  String? error;
  String methodKey='egyptian';
  DateTime now=DateTime.now();
  Timer? ticker;
  @override void initState(){super.initState();_load();prayerSettingsVersion.addListener(_reloadSettings);ticker=Timer.periodic(const Duration(seconds:1),(_){if(mounted){setState(()=>now=DateTime.now());if(now.second==0&&coordinates!=null)_syncPrayerTimesWidget(coordinates!,methodKey);}});}
  Future<void> _reloadSettings() async {
    final prefs=await SharedPreferences.getInstance();
    final lat=prefs.getDouble('prayer_latitude'),lon=prefs.getDouble('prayer_longitude');
    if(!mounted)return;
    if(lat!=null&&lon!=null)setState(()=>coordinates=Coordinates(lat,lon));
    setState(()=>methodKey=prefs.getString('calculation_method')??'egyptian');
    if(coordinates!=null)await _syncPrayerTimesWidget(coordinates!,methodKey);
  }
  Future<void> _load() async {
    try {
      final prefs=await SharedPreferences.getInstance();
      final lat=prefs.getDouble('prayer_latitude'),lon=prefs.getDouble('prayer_longitude');
      Coordinates c;
      if(lat!=null&&lon!=null){c=Coordinates(lat,lon);}
      else {
        final p=await _getPosition();
        c=Coordinates(p.latitude,p.longitude);
        await prefs.setDouble('prayer_latitude',p.latitude);
        await prefs.setDouble('prayer_longitude',p.longitude);
        await prefs.setString('prayer_city','الموقع الحالي');
      }
      if(!mounted)return;
      setState(()=>coordinates=c);
      await _reloadSettings();
      await _syncPrayerTimesWidget(c,methodKey);
    } catch(e) {
      if(!mounted)return;
      setState(()=>error=e.toString().replaceFirst('Exception: ',''));
    } finally {if(mounted)setState(()=>loading=false);}
  }
  @override void dispose(){ticker?.cancel();prayerSettingsVersion.removeListener(_reloadSettings);super.dispose();}
  @override Widget build(BuildContext context){
    final c=coordinates;
    final today=c==null?null:PrayerTimes.today(c,_parameters(methodKey));
    final rows=today==null?<MapEntry<String,DateTime>>[]:[
      MapEntry('الفجر',today.fajr),MapEntry('الشروق',today.sunrise),MapEntry('الظهر',today.dhuhr),MapEntry('العصر',today.asr),MapEntry('المغرب',today.maghrib),MapEntry('العشاء',today.isha)
    ];
    MapEntry<String,DateTime>? next;
    for(final row in rows){if(row.value.isAfter(now)){next=row;break;}}
    next ??= c==null?null:MapEntry('الفجر',_getTime(c,DateTime(now.year,now.month,now.day+1),Prayer.fajr,methodKey));
    final remaining=next==null?null:next.value.difference(now);
    String countdown(Duration d){final h=d.inHours.toString().padLeft(2,'0');final m=(d.inMinutes%60).toString().padLeft(2,'0');final sec=(d.inSeconds%60).toString().padLeft(2,'0');return h+':'+m+':'+sec;}
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
        Text('الصلاة القادمة: '+next.key,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:17,color:_green)),
        const SizedBox(height:4),const Text('متبقي على الصلاة',style:TextStyle(color:Colors.black54)),
        Text(countdown(remaining.isNegative?Duration.zero:remaining),style:const TextStyle(fontSize:30,fontWeight:FontWeight.bold,color:_green,letterSpacing:2)),
      ])),
      if(c==null) Align(alignment:Alignment.centerLeft,child:TextButton.icon(onPressed:loading?null:_load,icon:const Icon(Icons.my_location),label:const Text('تحديد موقعي لعرض المواقيت'))),
    ])));
  }
}

class PrayerPage extends StatefulWidget {
  const PrayerPage({super.key});
  @override State<PrayerPage> createState() => _PrayerPageState();
}
class _PrayerPageState extends State<PrayerPage> {
  Coordinates? coordinates;
  String cityName='الموقع الحالي';
  String methodKey='egyptian';
  String? error;
  bool loading=false,alerts=false;
  int iqama=10;
  String? audioPath;
  String? iqamaAudioPath;
  double adhanVolume=1.0;
  bool downloadingHaram=false;
  final AudioPlayer audioPlayer=AudioPlayer();

  @override void initState(){super.initState();_loadSettings();}
  Future<void> _loadSettings() async {
    final prefs=await SharedPreferences.getInstance();
    if(!mounted)return;
    final lat=prefs.getDouble('prayer_latitude'),lon=prefs.getDouble('prayer_longitude');
    setState((){
      coordinates=lat!=null&&lon!=null?Coordinates(lat,lon):null;
      cityName=prefs.getString('prayer_city')??'الموقع الحالي';
      methodKey=prefs.getString('calculation_method')??'egyptian';
      alerts=prefs.getBool('prayer_alerts')??false;
      iqama=prefs.getInt('iqama_delay')??10;
      adhanVolume=(prefs.getDouble('adhan_volume')??1.0).clamp(0.0,1.0).toDouble();
      final savedAudio=prefs.getString('adhan_audio_path');
      final isOldHaramAdhan = savedAudio != null && savedAudio.endsWith('adhan_ali_ibn_ahmad_mala.mp3');
      if (isOldHaramAdhan) {
        prefs.remove('adhan_audio_path');
      }
      audioPath=savedAudio!=null && !isOldHaramAdhan && File(savedAudio).existsSync() ? savedAudio : null;
      final savedIqamaAudio=prefs.getString('iqama_audio_path');
      iqamaAudioPath=savedIqamaAudio!=null && File(savedIqamaAudio).existsSync() ? savedIqamaAudio : null;
    });
    if (coordinates == null) {
      await _locate();
    }
    // Restore the next seven days of reminders after every app launch.
    // Android may clear scheduled alarms after force-stop or app updates.
    if (alerts && coordinates != null) {
      try {
        await _refresh();
      } catch (e) {
        if (mounted) {
          _msg('تعذر إعادة ضبط تنبيهات الصلاة: ${e.toString()}');
        }
      }
    }
  }
  Future<void> _saveCoordinates(Coordinates c,String name) async {
    final prefs=await SharedPreferences.getInstance();
    await prefs.setDouble('prayer_latitude',c.latitude);
    await prefs.setDouble('prayer_longitude',c.longitude);
    await prefs.setString('prayer_city',name);
    if(!mounted)return;
    setState(() { coordinates=c; cityName=name; error=null; });
    prayerSettingsVersion.value++;
    if(alerts)await _refresh();
  }
  Future<void> _locate() async {
    setState(() { loading=true; error=null; });
    try {
      final p=await _getPosition();
      String name;
      try {
        name = await _reverseGeocode(p.latitude, p.longitude);
      } catch (_) {
        name = 'موقعي الحالي (${p.latitude.toStringAsFixed(4)}, ${p.longitude.toStringAsFixed(4)})';
      }
      await _saveCoordinates(Coordinates(p.latitude,p.longitude),name);
      if (mounted && name.startsWith('موقعي الحالي')) {
        _msg('تم تحديد موقعك بالإحداثيات، لكن تعذر جلب اسم المدينة. تأكد من الإنترنت.');
      } else if (mounted) {
        _msg('تم تحديد موقعك: $name');
      }
    } catch(e) {
      if(mounted)setState(()=>error=e.toString().replaceFirst('Exception: ',''));
    } finally {if(mounted)setState(()=>loading=false);}
  }
  Future<void> _selectCity(String? city) async {
    if(city==null)return;
    final c=_knownCities[city];
    if(c!=null)await _saveCoordinates(c,city);
  }
  Future<void> _searchWorldCity() async {
    final controller = TextEditingController();
    List<Map<String, dynamic>> results = [];
    bool searching = false;
    String? searchError;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> search() async {
            final query = controller.text.trim();
            if (query.isEmpty) return;
            setDialogState(() { searching = true; searchError = null; results = []; });
            try {
              final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
                'name': query, 'count': '20', 'language': 'ar', 'format': 'json',
              });
              final response = await http.get(uri, headers: const {
                'User-Agent': 'NoorAlIslam/1.0',
              }).timeout(const Duration(seconds: 20));
              if (response.statusCode != 200) {
                throw Exception('خدمة البحث ردّت بالرمز ${response.statusCode}.');
              }
              final data = jsonDecode(response.body) as Map<String, dynamic>;
              final items = (data['results'] as List<dynamic>? ?? []);
              setDialogState(() {
                results = items.whereType<Map<String, dynamic>>().toList();
                if (results.isEmpty) searchError = 'لم نعثر على مدينة بهذا الاسم. جرّب الاسم بالإنجليزية أو اكتب اسم مدينة أكبر قريبة منها.';
              });
            } catch (e) {
              setDialogState(() => searchError = 'تعذر البحث الآن. تأكد من اتصال الإنترنت ثم حاول مرة أخرى.');
            } finally {
              setDialogState(() => searching = false);
            }
          }
          return AlertDialog(
            title: const Text('اختيار مدينة من العالم'),
            content: SizedBox(
              width: 480,
              height: 420,
              child: Column(children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => search(),
                  decoration: InputDecoration(
                    hintText: 'اكتب اسم المدينة أو الدولة',
                    suffixIcon: IconButton(
                      onPressed: searching ? null : search,
                      icon: const Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (searching) const LinearProgressIndicator(),
                if (searchError != null) Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(searchError!, style: const TextStyle(color: Colors.red)),
                ),
                Expanded(child: ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final item = results[index];
                    final name = (item['name'] ?? '').toString();
                    final country = (item['country'] ?? '').toString();
                    final admin = (item['admin1'] ?? '').toString();
                    final lat = (item['latitude'] as num?)?.toDouble();
                    final lon = (item['longitude'] as num?)?.toDouble();
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.location_city, color: _green),
                      title: Text(name),
                      subtitle: Text([admin, country].where((v) => v.isNotEmpty).join('، ')),
                      onTap: lat == null || lon == null ? null : () {
                        Navigator.pop(dialogContext);
                        _saveCoordinates(Coordinates(lat, lon), [name, country].where((v) => v.isNotEmpty).join('، '));
                      },
                    );
                  },
                )),
              ]),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إغلاق'))],
          );
        },
      ),
    );
    controller.dispose();
  }

  Future<void> _manualCoordinates() async {
    final latController=TextEditingController(text:coordinates?.latitude.toString()??'');
    final lonController=TextEditingController(text:coordinates?.longitude.toString()??'');
    final values=await showDialog<List<double>>(context:context,builder:(context)=>AlertDialog(
      title:const Text('إدخال الموقع يدويًا'),
      content:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:latController,keyboardType:const TextInputType.numberWithOptions(decimal:true,signed:true),decoration:const InputDecoration(labelText:'خط العرض Latitude')),
        TextField(controller:lonController,keyboardType:const TextInputType.numberWithOptions(decimal:true,signed:true),decoration:const InputDecoration(labelText:'خط الطول Longitude')),
      ]),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(context),child:const Text('إلغاء')),
        FilledButton(onPressed:(){
          final lat=double.tryParse(latController.text.trim()),lon=double.tryParse(lonController.text.trim());
          if(lat==null||lon==null||lat < -90||lat > 90||lon < -180||lon > 180)return;
          Navigator.pop(context,[lat,lon]);
        },child:const Text('حفظ')),
      ],
    ));
    latController.dispose();lonController.dispose();
    if(values!=null)await _saveCoordinates(Coordinates(values[0],values[1]),'موقع يدوي');
  }
  Future<void> _setMethod(String? value) async {
    if(value==null)return;
    final prefs=await SharedPreferences.getInstance();
    await prefs.setString('calculation_method',value);
    if(!mounted)return;
    setState(()=>methodKey=value);
    prayerSettingsVersion.value++;
    if(alerts)await _refresh();
  }
  Future<void> _refresh() async {
    final c=coordinates;
    if(c==null)return;
    await _scheduleAlerts(c,iqama,methodKey,audioPath,iqamaAudioPath,adhanVolume);
  }
  Future<void> _toggle(bool value) async {
    if(value&&coordinates==null){await _locate();if(coordinates==null)return;}
    final prefs=await SharedPreferences.getInstance();
    await prefs.setBool('prayer_alerts',value);
    if(!mounted)return;
    setState(()=>alerts=value);
    if(value){
      try{await _refresh();_msg('تم ضبط التنبيهات للأيام السبعة القادمة.');}
      catch(e){setState(()=>alerts=false);_msg('تعذر ضبط التنبيهات: '+e.toString());}
    }else{await _notifier.cancelAll();await _adhanChannel.invokeMethod('cancelAdhan').catchError((_) {});await _adhanChannel.invokeMethod('stopPlayback').catchError((_) {});_msg('تم إيقاف التنبيهات والأذان الجاري.');}
  }
  Future<void> _setAdhanVolume(double value) async {
    final volume = value.clamp(0.0,1.0).toDouble();
    final prefs=await SharedPreferences.getInstance();
    await prefs.setDouble('adhan_volume',volume);
    // Apply the new level to an adhan that is already playing, if any.
    await _adhanChannel.invokeMethod('setPlaybackVolume', {'volume': volume})
        .catchError((_) {});
    // Also update the volume stored for future scheduled adhans.
    if(alerts) await _refresh();
  }
  Future<void> _stopAdhanNow() async {
    try {
      await audioPlayer.stop();
      await _adhanChannel.invokeMethod('stopPlayback');
      _msg('تم إرسال أمر إيقاف الأذان.');
    } catch(e) {
      _msg('تعذر إيقاف الأذان: '+e.toString());
    }
  }
  Future<void> _setIqama(int? v) async {
    if(v==null)return;
    setState(()=>iqama=v);
    final prefs=await SharedPreferences.getInstance();
    await prefs.setInt('iqama_delay',v);
    if(alerts)await _refresh();
  }
  Future<void> _chooseAdhan() async {
    final result=await FilePicker.pickFile(type:FileType.audio);
    if(result==null)return;
    final bytes=await result.readAsBytes();
    final ext=result.extension??'audio';
    final dir=await getApplicationDocumentsDirectory();
    final path=dir.path+'/adhan_'+DateTime.now().millisecondsSinceEpoch.toString()+'.'+ext;
    final file=await File(path).writeAsBytes(bytes,flush:true);
    final prefs=await SharedPreferences.getInstance();
    await prefs.setString('adhan_audio_path',file.path);
    if(!mounted)return;
    setState(()=>audioPath=file.path);
    if (alerts) await _refresh();
    _msg('تم حفظ ملف الأذان. سيعمل تلقائيًا عند دخول وقت الصلاة إذا كانت التنبيهات مفعّلة.');
  }

  Future<void> _chooseIqamaAudio() async {
    final result=await FilePicker.pickFile(type:FileType.audio);
    if(result==null)return;
    final bytes=await result.readAsBytes();
    final ext=result.extension??'audio';
    final dir=await getApplicationDocumentsDirectory();
    final path=dir.path+'/iqama_'+DateTime.now().millisecondsSinceEpoch.toString()+'.'+ext;
    final file=await File(path).writeAsBytes(bytes,flush:true);
    final prefs=await SharedPreferences.getInstance();
    await prefs.setString('iqama_audio_path',file.path);
    if(!mounted)return;
    setState(()=>iqamaAudioPath=file.path);
    if (alerts) await _refresh();
    _msg('تم حفظ ملف الإقامة. سيعمل تلقائيًا في موعد الإقامة إذا كانت التنبيهات مفعّلة.');
  }

  Future<void> _downloadHaramAdhan() async {
    if (downloadingHaram) return;
    setState(() => downloadingHaram = true);
    String? lastError;
    try {
      final urls = [
        'https://ia600702.us.archive.org/10/items/athan-nasTv/athan-nasTv.mp3',
      ];
      List<int>? audioBytes;
      for (final address in urls) {
        try {
          final response = await http.get(
            Uri.parse(address),
            headers: const {'User-Agent': 'NoorAlIslamApp/1.0'},
          ).timeout(const Duration(seconds: 120));
          if (response.statusCode != 200) {
            throw Exception('HTTP ${response.statusCode}');
          }
          final bytes = response.bodyBytes;
          final isMp3 = bytes.length > 100000 &&
              ((bytes.length > 3 && bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33) ||
               (bytes.length > 1 && bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0));
          if (!isMp3) throw Exception('الملف المستلم ليس ملف MP3 صالحًا');
          audioBytes = bytes;
          break;
        } catch (e) {
          lastError = e.toString();
        }
      }
      if (audioBytes == null) {
        throw Exception(lastError ?? 'تعذر الوصول إلى مصدر الأذان');
      }

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/adhan_abdulmajeed_alsarihi.mp3');
      await file.writeAsBytes(audioBytes, flush: true);
      if (!await file.exists() || await file.length() != audioBytes.length) {
        throw Exception('لم يكتمل حفظ ملف الأذان على الهاتف');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('adhan_audio_path', file.path);
      if (!mounted) return;
      setState(() => audioPath = file.path);
      if (alerts) await _refresh();
      _msg('تم حفظ أذان الشيخ عبد المجيد السريحي. سيعمل تلقائيًا عند دخول وقت الصلاة مع تفعيل التنبيهات.');
    } catch (e) {
      _msg('لم تتم إضافة أذان عبد المجيد السريحي: ${e.toString()}');
    } finally {
      if (mounted) setState(() => downloadingHaram = false);
    }
  }

  Future<void> _previewAdhan() async {
    if(audioPath==null)return;
    try{await audioPlayer.setFilePath(audioPath!);await audioPlayer.play();}
    catch(e){_msg('تعذر تشغيل الملف: '+e.toString());}
  }
  Future<void> _clearAudio() async {
    final prefs=await SharedPreferences.getInstance();
    await prefs.remove('adhan_audio_path');
    if(!mounted)return;
    setState(()=>audioPath=null);
    if (alerts) await _refresh();
    await _adhanChannel.invokeMethod('cancelAdhan').catchError((_) {});
    await _adhanChannel.invokeMethod('stopPlayback').catchError((_) {});
    _msg('تم الرجوع إلى صوت إشعار الهاتف.');
  }
  Future<void> _previewIqamaAudio() async {
    if(iqamaAudioPath==null)return;
    try{await audioPlayer.setFilePath(iqamaAudioPath!);await audioPlayer.play();}
    catch(e){_msg('تعذر تشغيل ملف الإقامة: '+e.toString());}
  }
  Future<void> _clearIqamaAudio() async {
    final prefs=await SharedPreferences.getInstance();
    await prefs.remove('iqama_audio_path');
    if(!mounted)return;
    setState(()=>iqamaAudioPath=null);
    if (alerts) await _refresh();
    _msg('تم إلغاء صوت الإقامة المخصص.');
  }
  void _msg(String s){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));}
  @override void dispose(){audioPlayer.dispose();super.dispose();}

  @override Widget build(BuildContext context){
    final today=DateTime.now();
    final times=coordinates==null?null:PrayerTimes.today(coordinates!,_parameters(methodKey));
    final rows=times==null?<MapEntry<String,DateTime>>[]:[
      MapEntry('الفجر',times.fajr),MapEntry('الشروق',times.sunrise),MapEntry('الظهر',times.dhuhr),MapEntry('العصر',times.asr),MapEntry('المغرب',times.maghrib),MapEntry('العشاء',times.isha),
    ];
    const methods=<String,String>{
      'egyptian':'الهيئة المصرية العامة للمساحة',
      'umm_al_qura':'أم القرى - السعودية',
      'muslim_world_league':'رابطة العالم الإسلامي',
      'karachi':'جامعة العلوم الإسلامية - كراتشي',
      'north_america':'ISNA - أمريكا الشمالية',
      'kuwait':'وزارة الأوقاف - الكويت',
      'qatar':'قطر',
      'singapore':'سنغافورة',
      'turkey':'الشؤون الدينية التركية',
    };
    return ListView(padding:const EdgeInsets.all(16),children:[
      Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        const Text('الموقع وطريقة حساب المواقيت',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold,color:_green)),
        const SizedBox(height:8),
        Text('المدينة الحالية: '+cityName,style:const TextStyle(fontWeight:FontWeight.w600)),
        OutlinedButton.icon(
          onPressed: _searchWorldCity,
          icon: const Icon(Icons.public),
          label: const Text('البحث عن مدينة في أي دولة بالعالم'),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value:_knownCities.containsKey(cityName)?cityName:null,
          isExpanded:true,
          decoration:const InputDecoration(labelText:'اختيار المدينة يدويًا'),
          items:_knownCities.keys.map((name)=>DropdownMenuItem(value:name,child:Text(name))).toList(),
          onChanged:_selectCity,
        ),
        const SizedBox(height:8),
        Wrap(spacing:8,runSpacing:8,children:[
          OutlinedButton.icon(onPressed:loading?null:_locate,icon:const Icon(Icons.my_location),label:const Text('استخدام موقعي GPS')),
          OutlinedButton.icon(onPressed:_manualCoordinates,icon:const Icon(Icons.edit_location_alt),label:const Text('إدخال إحداثيات يدويًا')),
        ]),
        DropdownButtonFormField<String>(
          value:methodKey,
          isExpanded:true,
          decoration:const InputDecoration(labelText:'طريقة حساب مواقيت الصلاة'),
          items:methods.entries.map((e)=>DropdownMenuItem(value:e.key,child:Text(e.value))).toList(),
          onChanged:_setMethod,
        ),
        if(loading)const LinearProgressIndicator(),
        if(error!=null)Text(error!,style:const TextStyle(color:Colors.red)),
        const Divider(height:22),
        const Text('مواقيت اليوم',style:TextStyle(fontWeight:FontWeight.bold)),
        Text(today.day.toString()+'/'+today.month.toString()+'/'+today.year.toString()),
        for(final row in rows)ListTile(dense:true,contentPadding:EdgeInsets.zero,title:Text(row.key),trailing:Text(_timeText(row.value),style:const TextStyle(fontSize:18,color:_green,fontWeight:FontWeight.bold))),
      ]))),
      Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        const Text('تنبيهات الصلاة',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold,color:_green)),
        SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('تفعيل التنبيهات'),subtitle:const Text('قبل الصلاة بـ10 دقائق، وعند دخول الوقت، ثم الإقامة'),value:alerts,onChanged:_toggle),
        Row(children:[const Expanded(child:Text('الإقامة بعد الأذان')),DropdownButton<int>(value:iqama,items:[5,10,15,20,25,30].map((v)=>DropdownMenuItem(value:v,child:Text(v.toString()+' دقائق'))).toList(),onChanged:_setIqama)]),
      ]))),
      Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        const Text('صوت الأذان',style:TextStyle(fontWeight:FontWeight.bold,fontSize:19,color:_green)),
        Text(audioPath==null?'صوت إشعار الهاتف الافتراضي': 'تم اختيار ملف أذان محفوظ على الهاتف'),
        const SizedBox(height:4),
        const Text('حرّك شريط الصوت لتغيير مستوى الأذان الجاري فورًا، أو لضبط صوت الأذان القادم.',style:TextStyle(color:Colors.black54,fontSize:13)),
        const SizedBox(height:8),
        Row(children:[const Expanded(child:Text('مستوى صوت الأذان')),Text('${(adhanVolume*100).round()}%',style:const TextStyle(fontWeight:FontWeight.bold,color:_green))]),
        Slider(value:adhanVolume.clamp(0.0,1.0).toDouble(),min:0,max:1,divisions:20,label:'${(adhanVolume*100).round()}%',onChanged:(value)=>setState(()=>adhanVolume=value),onChangeEnd:_setAdhanVolume),
        OutlinedButton.icon(onPressed:_stopAdhanNow,icon:const Icon(Icons.stop_circle_outlined),label:const Text('إيقاف الأذان الآن')),
        OutlinedButton.icon(
          onPressed: downloadingHaram ? null : _downloadHaramAdhan,
          icon: downloadingHaram
              ? const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2))
              : const Icon(Icons.mosque),
          label: Text(downloadingHaram ? 'جارٍ تنزيل أذان عبد المجيد السريحي...' : 'تنزيل أذان عبد المجيد السريحي'),
        ),
        Wrap(spacing:8,runSpacing:8,children:[
          OutlinedButton.icon(onPressed:_chooseAdhan,icon:const Icon(Icons.audio_file),label:const Text('اختيار ملف من الهاتف')),
          FilledButton.tonalIcon(onPressed:audioPath==null?null:_previewAdhan,icon:const Icon(Icons.play_arrow),label:const Text('تجربة الصوت')),
          TextButton(onPressed:audioPath==null?null:_clearAudio,child:const Text('الصوت الافتراضي')),
        ]),
        const Text('عند اختيار ملف أذان وتفعيل التنبيهات، سيعمل الأذان كاملًا في الخلفية وقت الصلاة. يمكنك تغيير مستوى صوته من هنا أو إيقافه من زر الإيقاف في هذه الصفحة أو من إشعار الأذان.',style:TextStyle(fontSize:12,color:Colors.black54,height:1.5)),
      ]))),
      Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        const Text('صوت إقامة الصلاة',style:TextStyle(fontWeight:FontWeight.bold,fontSize:19,color:_green)),
        Text(iqamaAudioPath==null?'سيُستخدم صوت إشعار الهاتف عند موعد الإقامة':'تم اختيار ملف إقامة من الهاتف'),
        Wrap(spacing:8,runSpacing:8,children:[
          OutlinedButton.icon(onPressed:_chooseIqamaAudio,icon:const Icon(Icons.audio_file),label:const Text('اختيار ملف الإقامة من الهاتف')),
          FilledButton.tonalIcon(onPressed:iqamaAudioPath==null?null:_previewIqamaAudio,icon:const Icon(Icons.play_arrow),label:const Text('تجربة صوت الإقامة')),
          TextButton(onPressed:iqamaAudioPath==null?null:_clearIqamaAudio,child:const Text('إلغاء الصوت المخصص')),
        ]),
        const Text('اختر ملف إقامة الصلاة بصيغة صوتية من هاتفك. سيُحفظ داخل التطبيق ويُشغّل في موعد الإقامة المحدد بعد الأذان.',style:TextStyle(fontSize:12,color:Colors.black54,height:1.5)),
      ]))),
    ]);
  }
}


class QiblaPage extends StatefulWidget {
 const QiblaPage({super.key});
 @override State<QiblaPage> createState()=>_QiblaPageState();
}
class _QiblaPageState extends State<QiblaPage>{
 double? qibla;String? error;bool loading=false;
 Future<void> _calculate() async {
  setState(() { loading=true; error=null; });
  try{final c=await _configuredCoordinates();final value=Qibla(c).direction;if(!mounted)return;setState(() { qibla=value; loading=false; });}
  catch(e){if(!mounted)return;setState(() { error=e.toString().replaceFirst('Exception: ' , ''); loading=false; });}
 }
 @override void initState(){super.initState();_calculate();}
 @override Widget build(BuildContext context)=>Center(child:Padding(padding:const EdgeInsets.all(24),child:StreamBuilder<CompassEvent>(
  stream:FlutterCompass.events,builder:(context,snapshot){
   final heading=snapshot.data?.heading;final available=heading!=null;
   final angle=qibla==null||heading==null?0.0:(qibla!-heading)*math.pi/180;
   return Column(mainAxisSize:MainAxisSize.min,children:[
    const Text('بوصلة اتجاه القبلة',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold)),
    const SizedBox(height:18),
    SizedBox(width:270,height:270,child:Stack(alignment:Alignment.center,children:[
     Container(width:260,height:260,decoration:BoxDecoration(shape:BoxShape.circle,color:const Color(0xFFF5F0E6),border:Border.all(color:_green,width:5),boxShadow:const [BoxShadow(color:Color(0x22000000),blurRadius:10,offset:Offset(0,4))])),
     const Positioned(top:12,child:Text('شمال',style:TextStyle(fontWeight:FontWeight.bold,color:_green))),
     const Positioned(bottom:12,child:Text('جنوب',style:TextStyle(color:Colors.black54))),
     const Positioned(left:12,child:Text('شرق',style:TextStyle(color:Colors.black54))),
     const Positioned(right:12,child:Text('غرب',style:TextStyle(color:Colors.black54))),
     if(qibla!=null&&available)Transform.rotate(angle:angle,child:const Icon(Icons.navigation,size:145,color:Color(0xFFB3261E))),
     if(qibla==null||!available)const Icon(Icons.explore,size:110,color:Colors.black26),
     const CircleAvatar(radius:7,backgroundColor:_green),
     if(qibla!=null&&available)const Positioned(bottom:48,child:Text('اتجاه القبلة',style:TextStyle(color:Color(0xFFB3261E),fontWeight:FontWeight.bold))),
    ])),
    const SizedBox(height:14),
    if(heading!=null)Text('اتجاه الهاتف: ${heading.toStringAsFixed(0)}° • القبلة: ${qibla?.toStringAsFixed(0)??'--'}°',style:const TextStyle(fontWeight:FontWeight.w600)),
    if(qibla!=null&&!available)const Text('حساس البوصلة غير متاح في هذا الهاتف.',textAlign:TextAlign.center),
    if(error!=null)Text(error!,textAlign:TextAlign.center,style:const TextStyle(color:Colors.red)),
    if(loading)const Padding(padding:EdgeInsets.all(8),child:CircularProgressIndicator()),
    const SizedBox(height:10),
    OutlinedButton.icon(onPressed:loading?null:_calculate,icon:const Icon(Icons.my_location),label:const Text('تحديث موقعي واتجاه القبلة')),
    const Text('حرّك الهاتف ببطء؛ السهم الأحمر يتحرك مع اتجاه الجهاز نحو القبلة.',textAlign:TextAlign.center,style:TextStyle(fontSize:12,color:Colors.black54)),
   ]);
  },
 )));
}
