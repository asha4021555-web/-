import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hijri_date/hijri.dart';
import 'prayer_page.dart';
import 'quran_data.dart';
import 'quran_navigation.dart';
import 'reading_marks.dart';
import 'tafsir_page.dart';
import 'dreams_page.dart';
import 'media_pages.dart';
import 'adhkar_page.dart';
final ValueNotifier<int> hijriOffsetChanged=ValueNotifier(0);
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initialWidgetUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
  runApp(NoorApp(initialWidgetUri: initialWidgetUri));
}
const green=Color(0xFF493326);
const gold=Color(0xFFE8C77B);
const softGold=Color(0xFFE8D4A7);
const ivory=Color(0xFFF5F0E6);
const titles=['القرآن الكريم','أذكار الصباح والمساء','أذكار بعد الصلاة','الأدعية','الأحاديث النبوية','قصص الأنبياء','أسماء الله الحسنى','السبحة الإلكترونية','مواقيت الصلاة','اتجاه القبلة','تفسير القرآن الكريم','تفسير الأحلام','التفسير الميسّر','البث المباشر','المصحف المعلم للأطفال','الأذكار والأدعية اليومية'];
const icons=[Icons.menu_book,Icons.wb_twilight,Icons.mosque,Icons.volunteer_activism,Icons.auto_stories,Icons.history_edu,Icons.star,Icons.radio_button_checked,Icons.access_time,Icons.explore,Icons.menu_book_outlined,Icons.nights_stay,Icons.menu_book,Icons.live_tv,Icons.record_voice_over,Icons.auto_awesome];
class NoorApp extends StatelessWidget {
  final Uri? initialWidgetUri;
  const NoorApp({super.key, this.initialWidgetUri});
  @override
  Widget build(BuildContext c) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'نور الإسلام',
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: green).copyWith(primary: green, onPrimary: Colors.white, secondary: gold, onSecondary: const Color(0xFF332319), surface: ivory), scaffoldBackgroundColor: ivory),
    home: SplashScreen(initialWidgetUri: initialWidgetUri),
  );
}

class SplashScreen extends StatefulWidget {
  final Uri? initialWidgetUri;
  const SplashScreen({super.key, this.initialWidgetUri});
  @override State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomePage(initialWidgetUri: widget.initialWidgetUri)),
      );
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: ivory,
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => showDialog<void>(
              context: context,
              barrierColor: Colors.black87,
              builder: (dialogContext) => Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.all(16),
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.asset('assets/noor_icon.jpg', fit: BoxFit.contain),
                      ),
                    ),
                    IconButton(
                      tooltip: 'إغلاق',
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    ),
                  ],
                ),
              ),
            ),
            child: Container(
              width: 280,
              height: 280,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: green.withValues(alpha: .12), blurRadius: 22, offset: const Offset(0, 8))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset('assets/noor_icon.jpg', fit: BoxFit.contain),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text('نور الإسلام', style: TextStyle(color: green, fontSize: 27, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('رفيقك للقرآن والذكر والعبادة', style: TextStyle(color: green, fontSize: 14)),
        ],
      ),
    ),
  );
}
class HomePage extends StatefulWidget {
  final Uri? initialWidgetUri;
  const HomePage({super.key, this.initialWidgetUri});
  @override State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  int tab = 0;
  StreamSubscription<Uri?>? _widgetSubscription;

  @override
  void initState() {
    super.initState();
    _handleWidgetUri(widget.initialWidgetUri);
    _widgetSubscription = HomeWidget.widgetClicked.listen(_handleWidgetUri);
  }

  Future<void> _openQuranKareemAtLastPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSurah = (prefs.getInt('quran_kareem_last_surah') ?? 1).clamp(1, 114);
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ContinuousQuranReader(
        number: savedSurah,
        name: quranSurahNames[savedSurah - 1],
        restoreLastPosition: true,
      ),
    ));
  }

  void _handleWidgetUri(Uri? uri) {
    if (uri == null) return;
    final target = uri.host.isNotEmpty ? uri.host : (uri.pathSegments.isEmpty ? '' : uri.pathSegments.first);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (target) {
        case 'quran-majeed':
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MushafBookReader()));
          break;
        case 'quran-kareem':
          _openQuranKareemAtLastPosition();
          break;
        case 'adhkar':
          setState(() => tab = 4);
          break;
        case 'tasbeeh':
          setState(() => tab = 0);
          _open(SectionPage(index: 7), titles[7]);
          break;
        case 'prayer-times':
          _open(const PrayerPage(), 'مواقيت الصلاة');
          break;
      }
    });
  }

  @override
  void dispose() {
    _widgetSubscription?.cancel();
    super.dispose();
  }
  Future<void> _handleBack() async {
    if (tab != 0) {
      setState(() => tab = 0);
      return;
    }
    final exit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('الخروج من نور الإسلام'),
        content: const Text('هل تريد الخروج من التطبيق؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('خروج')),
        ],
      ),
    );
    if (exit == true) SystemNavigator.pop();
  }
  void _open(Widget page, String title) => Navigator.push(context, MaterialPageRoute(builder: (_) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(appBar: AppBar(title: Text(title), backgroundColor: green, foregroundColor: Colors.white), body: page))));
  @override Widget build(BuildContext c) {
    final pages = <Widget>[
      ListView(padding: const EdgeInsets.all(16), children: [
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors:[green,Color(0xFF332319)]),borderRadius:BorderRadius.circular(22)), child: const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('أهلاً بك في نور الإسلام',style:TextStyle(color:Colors.white,fontSize:23,fontWeight:FontWeight.bold)),
          SizedBox(height:6),Text('رفيقك للقرآن والذكر والعبادة',style:TextStyle(color:Colors.white70)),
        ])),
        const SizedBox(height:14),
        const PrayerHomeSummary(),
        const SizedBox(height:14),
        Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          const Text('محتويات نور الإسلام',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold,color:green)),
          const SizedBox(height:8),
          Wrap(spacing:8,runSpacing:8,children:[
            for(final item in [(0,'القرآن الكريم',Icons.menu_book),(1,'أذكار الصباح والمساء',Icons.wb_twilight),(2,'أذكار بعد الصلاة',Icons.mosque),(3,'الأدعية',Icons.volunteer_activism),(4,'الأحاديث',Icons.auto_stories),(5,'قصص الأنبياء',Icons.history_edu),(6,'أسماء الله الحسنى',Icons.star),(7,'السبحة',Icons.radio_button_checked),(10,'تفسير القرآن الكريم',Icons.menu_book_outlined),(11,'تفسير الأحلام',Icons.nights_stay),(12,'التفسير الميسّر',Icons.menu_book),(13,'البث المباشر',Icons.live_tv),(14,'المصحف المعلم للأطفال',Icons.record_voice_over),(15,'الأذكار والأدعية اليومية',Icons.auto_awesome)])
              ActionChip(avatar:Icon(item.$3,color:green,size:18),label:Text(item.$2),onPressed:()=>_open(SectionPage(index:item.$1),titles[item.$1])),
          ]),
        ]))),
        const SizedBox(height:12),
        const HijriDateFooter(),
      ]),
      ListView(padding:const EdgeInsets.all(16),children:[
        const Text('الإعدادات',style:TextStyle(fontSize:23,fontWeight:FontWeight.bold,color:green)),
        const SizedBox(height:10),
        ListTile(leading:const Icon(Icons.access_time,color:green),title:const Text('مواقيت الصلاة والتنبيهات'),trailing:const Icon(Icons.chevron_left),onTap:()=>_open(const PrayerPage(),'مواقيت الصلاة')),
        const HijriOffsetSetting(),
      ]),

      const QiblaPage(),
      const QuranPage(),
      const DhikrPage(after:false),
    ];
    return Directionality(textDirection:TextDirection.rtl,child:PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
      appBar:AppBar(title:const Text('نور الإسلام'),backgroundColor:green,foregroundColor:Colors.white,centerTitle:true,actions:[IconButton(tooltip:'بحث في كل التطبيق',icon:const Icon(Icons.search),onPressed:()=>_open(const GlobalSearchPage(),'بحث شامل'))]),
      body:IndexedStack(index:tab,children:pages),
      bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),destinations:const[
        NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home),label:'الرئيسية'),
        NavigationDestination(icon:Icon(Icons.settings_outlined),selectedIcon:Icon(Icons.settings),label:'الإعدادات'),
        NavigationDestination(icon:Icon(Icons.explore_outlined),selectedIcon:Icon(Icons.explore),label:'القبلة'),
        NavigationDestination(icon:Icon(Icons.menu_book_outlined),selectedIcon:Icon(Icons.menu_book),label:'القرآن'),
        NavigationDestination(icon:Icon(Icons.wb_twilight_outlined),selectedIcon:Icon(Icons.wb_twilight),label:'الأذكار'),
      ]),
      ),
    ));
  }
}
class HijriDateFooter extends StatefulWidget {
  const HijriDateFooter({super.key});
  @override State<HijriDateFooter> createState()=>_HijriDateFooterState();
}
class _HijriDateFooterState extends State<HijriDateFooter> {
  int offset=0;
  @override void initState(){super.initState();_load();hijriOffsetChanged.addListener(_load);}
  Future<void> _load() async {
    final prefs=await SharedPreferences.getInstance();
    if(!mounted)return;
    setState(()=>offset=prefs.getInt('hijri_offset')??0);
  }
  @override void dispose(){hijriOffsetChanged.removeListener(_load);super.dispose();}
  @override Widget build(BuildContext context){
    HijriDate.setLocal('ar');
    final date=HijriDate.fromDate(DateTime.now().add(Duration(days:offset)));
    return Card(child:InkWell(borderRadius:BorderRadius.circular(12),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>HijriCalendarPage(year:date.hYear,offset:offset))),child:Padding(padding:const EdgeInsets.all(16),child:Row(children:[
      const Icon(Icons.calendar_month,color:green,size:28),const SizedBox(width:10),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('التاريخ الهجري',style:TextStyle(fontWeight:FontWeight.bold,color:green)),
        Text(date.hDay.toString()+' '+date.getLongMonthName()+' '+date.hYear.toString()+' هـ',style:const TextStyle(fontSize:17,fontWeight:FontWeight.w600)),
        const Text('اضغط لعرض التقويم الهجري للسنة كاملة',style:TextStyle(fontSize:11,color:Colors.black54)),
      ])),
      const Icon(Icons.chevron_left),
    ]))));
  }
}
class HijriCalendarPage extends StatelessWidget {
  final int year;
  final int offset;
  const HijriCalendarPage({super.key,required this.year,required this.offset});
  @override Widget build(BuildContext context){
    HijriDate.setLocal('ar');
    return Directionality(textDirection:TextDirection.rtl,child:ListView(padding:const EdgeInsets.all(12),children:[
      Text('التقويم الهجري لعام '+year.toString()+' هـ',style:const TextStyle(fontSize:21,fontWeight:FontWeight.bold,color:green)),
      const Padding(padding:EdgeInsets.symmetric(vertical:8),child:Text('تقويم أم القرى، ويمكن تقديم التاريخ أو تأخيره يومًا من الإعدادات لمطابقة إعلان رؤية الهلال في بلدك.',style:TextStyle(color:Colors.black54))),
      for(var month=1;month<=12;month++) Builder(builder:(context){
        final first=HijriDate.fromHijri(year,month,1);
        final days=first.lengthOfMonth;
        final gregorianStart=first.hijriToGregorian(year,month,1).subtract(Duration(days:offset));
        final leading=gregorianStart.weekday%7;
        const weekdays=['أحد','إثنين','ثلاثاء','أربعاء','خميس','جمعة','سبت'];
        return Card(margin:const EdgeInsets.only(bottom:10),child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          Text(first.getLongMonthName(),style:const TextStyle(fontWeight:FontWeight.bold,fontSize:18,color:green)),
          const SizedBox(height:8),
          Row(children:[for(final weekday in weekdays)Expanded(child:Center(child:Text(weekday,style:const TextStyle(fontSize:10,color:Colors.black54,fontWeight:FontWeight.bold))))]),
          const SizedBox(height:5),
          Wrap(spacing:0,runSpacing:6,children:[
            for(var blank=0;blank<leading;blank++)SizedBox(width:MediaQuery.of(context).size.width/8.4,height:40),
            for(var day=1;day<=days;day++)SizedBox(width:MediaQuery.of(context).size.width/8.4,height:40,child:Center(child:Container(width:32,height:32,alignment:Alignment.center,decoration:BoxDecoration(color:gold.withValues(alpha:.18),borderRadius:BorderRadius.circular(8)),child:Text(day.toString())))),
          ]),
          const SizedBox(height:4),Text(days.toString()+' يومًا',style:const TextStyle(fontSize:11,color:Colors.black54)),
        ])));
      }),
    ]));
  }
}
class HijriOffsetSetting extends StatefulWidget {
  const HijriOffsetSetting({super.key});
  @override State<HijriOffsetSetting> createState()=>_HijriOffsetSettingState();
}
class _HijriOffsetSettingState extends State<HijriOffsetSetting>{
  int offset=0;
  @override void initState(){super.initState();_load();}
  Future<void> _load() async {final p=await SharedPreferences.getInstance();if(mounted)setState(()=>offset=p.getInt('hijri_offset')??0);}
  Future<void> _set(int value) async {
    final p=await SharedPreferences.getInstance();
    await p.setInt('hijri_offset',value);
    if(!mounted)return;
    setState(()=>offset=value);
    hijriOffsetChanged.value++;
  }
  @override Widget build(BuildContext context)=>Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    const Text('ضبط التاريخ الهجري',style:TextStyle(fontWeight:FontWeight.bold,color:green,fontSize:17)),
    const Text('لو إعلان الهلال في مصر مختلف عن التقويم الحسابي، قدّم أو أخّر يومًا.',style:TextStyle(fontSize:12,color:Colors.black54)),
    Row(children:[
      Expanded(child:Text(offset==0?'بدون تعديل':offset>0?'مقدّم يومًا':'مؤخّر يومًا')),
      IconButton(onPressed:offset>-1?()=>_set(-1):null,icon:const Icon(Icons.remove_circle_outline)),
      Text(offset>0?'+1':offset.toString(),style:const TextStyle(fontWeight:FontWeight.bold)),
      IconButton(onPressed:offset<1?()=>_set(1):null,icon:const Icon(Icons.add_circle_outline)),
      TextButton(onPressed:()=>_set(0),child:const Text('إعادة')),
    ]),
  ])));
}
class SectionPage extends StatelessWidget{final int index;const SectionPage({super.key,required this.index});@override Widget build(BuildContext c)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:Text(titles[index]),backgroundColor:green,foregroundColor:Colors.white,centerTitle:true,actions:[IconButton(tooltip:'بحث في كل التطبيق',icon:const Icon(Icons.search),onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>Scaffold(appBar:AppBar(title:Text('بحث شامل'),backgroundColor:green,foregroundColor:Colors.white),body:GlobalSearchPage()))))]),body:switch(index){0=>const QuranPage(),1=>const DhikrPage(after:false),2=>const DhikrPage(after:true),3=>const EntriesPage(items:duas),4=>const HadithLibraryPage(),5=>const StoriesPage(),6=>const NamesPage(),7=>const TasbeehPage(),8=>const PrayerPage(),9=>const QiblaPage(),10=>const TafsirPage(initialSource:'saadi'),11=>const DreamsPage(),12=>const TafsirPage(initialSource:'muyassar'),13=>const LiveChannelsPage(),14=>const AbdulbasitMuallimPage(),15=>const AdhkarLibraryPage(),_=>const DreamsPage()}));}
class QuranPage extends StatelessWidget {
  const QuranPage({super.key});
  static const surahs = quranSurahNames;
  static const surahAyahCounts = quranAyahCounts;

  void _openTextReader(BuildContext context, int surah, int ayah) {
    Navigator.push(context, MaterialPageRoute(
      // Choosing a surah/ayah explicitly always starts at that selection.
      // Resume is reserved for the dedicated "continue reading" entry.
      builder: (_) => ContinuousQuranReader(
        number: surah,
        name: surahs[surah - 1],
        initialAyah: ayah,
        restoreLastPosition: false,
      ),
    ));
  }

  Future<void> _openLastPosition(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final surah = (prefs.getInt('quran_kareem_last_surah') ?? 1).clamp(1, 114);
    if (!context.mounted) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ContinuousQuranReader(
        number: surah,
        name: surahs[surah - 1],
        restoreLastPosition: true,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.only(bottom: 16),
    children: [
      QuranLocationPicker(title: 'فهرس القرآن الكريم', onOpen: (surah, ayah) => _openTextReader(context, surah, ayah)),
      Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: ListTile(
          leading: const Icon(Icons.menu_book, color: green, size: 30),
          title: const Text('متابعة قرآن كريم', style: TextStyle(fontWeight: FontWeight.bold, color: green)),
          subtitle: const Text('استكمال آخر سورة وموضع وحجم وسرعة قراءة محفوظة'),
          trailing: const Icon(Icons.chevron_left),
          onTap: () => _openLastPosition(context),
        ),
      ),
      Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: ListTile(
          leading: const Icon(Icons.menu_book, color: green, size: 30),
          title: const Text('قرآن مجيد', style: TextStyle(fontWeight: FontWeight.bold, color: green)),
          subtitle: const Text('مصحف الصفحات المصوّرة - فهرس مستقل'),
          trailing: const Icon(Icons.chevron_left),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MushafBookReader())),
        ),
      ),
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text('سور القرآن الكريم', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: green)),
      ),
      for (var i = 0; i < surahs.length; i++)
        ListTile(
          leading: CircleAvatar(child: Text('${i + 1}')),
          title: Text('سورة ${surahs[i]}'),
          trailing: const Icon(Icons.chevron_left),
          onTap: () => _openTextReader(context, i + 1, 1),
        ),
    ],
  );
}

class SurahReader extends StatefulWidget {
  final int number;
  final String name;
  const SurahReader({super.key, required this.number, required this.name});

  @override
  State<SurahReader> createState() => _SurahReaderState();
}

class _SurahReaderState extends State<SurahReader> {
  late Future<List<dynamic>> verses;
  double fontSize = 25;

  @override
  void initState() {
    super.initState();
    verses = loadVerses();
  }

  Future<List<dynamic>> loadVerses() async {
    // The complete Uthmani Quran text is bundled in the APK (6236 lines).
    // Reading from assets means no internet connection is needed.
    final text = await rootBundle.loadString('assets/quran-uthmani.txt');
    final allAyahs = text.split('\n');
    if (allAyahs.length != 6236) {
      throw Exception('ملف القرآن غير مكتمل: ${allAyahs.length} آية');
    }
    final start = QuranPage.surahAyahCounts
        .take(widget.number - 1)
        .fold<int>(0, (sum, count) => sum + count);
    final count = QuranPage.surahAyahCounts[widget.number - 1];
    return List.generate(
      count,
      (index) => {
        'text': allAyahs[start + index],
        'numberInSurah': index + 1,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('سورة ${widget.name}'),
          backgroundColor: green,
          foregroundColor: Colors.white,
        ),
        body: FutureBuilder<List<dynamic>>(
          future: verses,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 14),
                    Text('جارٍ فتح آيات السورة من داخل التطبيق...'),
                  ],
                ),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off, size: 48, color: green),
                      const SizedBox(height: 12),
                      const Text(
                        'تعذر فتح ملف السورة. أعد المحاولة، وإذا استمرت المشكلة فأعد تثبيت التطبيق.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: () => setState(() => verses = loadVerses()),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final items = snapshot.data ?? [];
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(children: [
                  const Text('حجم الخط'),
                  Expanded(child: Slider(value: fontSize, min: 18, max: 40, divisions: 11, label: fontSize.round().toString(), onChanged: (v) => setState(() => fontSize = v), activeColor: green)),
                  Text(fontSize.round().toString()),
                ]),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: green,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'سُورَةُ ${widget.name}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 7,
                    runSpacing: 12,
                    children: [
                      for (final ayah in items) ...[
                        Text(
                          ayah['text'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: fontSize, height: 2.0),
                        ),
                        Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: green),
                          ),
                          child: Text(
                            ayah['numberInSurah'].toString(),
                            style: const TextStyle(
                              color: green,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class ContinuousQuranReader extends StatefulWidget {
  final int number;
  final String name;
  final int initialAyah;
  final bool restoreLastPosition;
  const ContinuousQuranReader({
    super.key,
    required this.number,
    required this.name,
    this.initialAyah = 1,
    this.restoreLastPosition = false,
  });

  @override
  State<ContinuousQuranReader> createState() => _ContinuousQuranReaderState();
}

class _ContinuousQuranReaderState extends State<ContinuousQuranReader> {
  final ScrollController _scrollController = ScrollController();
  bool _scrolling = false;
  bool _autoRequested = false;
  bool _manualInteraction = false;
  bool _restoreDone = false;
  Timer? _saveTimer;
  double _speed = 140;
  double _fontSize = 24;
  late Future<_ContinuousReaderData> _data;

  static const _lastSurahKey = 'quran_kareem_last_surah';
  static const _fontSizeKey = 'quran_kareem_font_size';
  static const _speedKey = 'quran_kareem_reading_speed';

  String get _positionKey => 'quran_kareem_position_${widget.number}';

  @override
  void initState() {
    super.initState();
    _data = _loadData();
    _scrollController.addListener(_scheduleSavePosition);
    unawaited(_loadReaderPreferences());
  }

  Future<void> _loadReaderPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final savedFont = prefs.getDouble(_fontSizeKey) ?? 24;
    final savedSpeed = prefs.getDouble(_speedKey) ?? 140;
    setState(() {
      _fontSize = savedFont.clamp(18.0, 44.0);
      _speed = savedSpeed.clamp(45.0, 300.0);
    });
    await prefs.setInt(_lastSurahKey, widget.number);
  }

  Future<void> _persistCurrentPosition() async {
    // Capture the offset before awaiting preferences: dispose() may release
    // the ScrollController while this asynchronous write is in progress.
    final offset = _scrollController.hasClients ? _scrollController.offset : null;
    final fontSize = _fontSize;
    final speed = _speed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSurahKey, widget.number);
    await prefs.setDouble(_fontSizeKey, fontSize);
    await prefs.setDouble(_speedKey, speed);
    if (offset != null) {
      await prefs.setDouble(_positionKey, offset);
    }
  }

  void _scheduleSavePosition() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 250), () {
      unawaited(_persistCurrentPosition());
    });
  }

  Future<void> _restorePosition() async {
    if (_restoreDone) return;
    _restoreDone = true;
    final prefs = await SharedPreferences.getInstance();
    final saved = widget.restoreLastPosition && widget.initialAyah == 1
        ? (prefs.getDouble(_positionKey) ?? 0)
        : 0.0;
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients && saved > 0) {
        _scrollController.jumpTo(
          saved.clamp(0.0, _scrollController.position.maxScrollExtent).toDouble(),
        );
      }
    });
  }

  Future<void> _saveReaderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, _fontSize);
    await prefs.setDouble(_speedKey, _speed);
  }

  Future<_ContinuousReaderData> _loadData() async {
    final rawText = await rootBundle.loadString('assets/quran-uthmani.txt');
    final allAyahs = rawText.split('\n');
    if (allAyahs.length != 6236) {
      throw Exception('ملف القرآن غير مكتمل: ${allAyahs.length} آية');
    }
    final start = quranAyahCounts
        .take(widget.number - 1)
        .fold<int>(0, (sum, count) => sum + count);
    final count = quranAyahCounts[widget.number - 1];
    return _ContinuousReaderData(allAyahs.skip(start).take(count).toList());
  }

  int _scrollRunId = 0;

  Future<void> _startScrolling() async {
    if (_scrolling || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    final remaining = position.maxScrollExtent - position.pixels;
    if (remaining <= 1 || _speed <= 0) {
      _autoRequested = false;
      if (mounted) setState(() {});
      return;
    }

    _autoRequested = true;
    final runId = ++_scrollRunId;
    setState(() => _scrolling = true);

    // Keep a constant linear speed. If the user drags, Flutter temporarily
    // takes control; the auto-scroll is resumed from the new offset on release.
    final durationMs = (remaining / _speed * 1000).round().clamp(1, 2147483647);
    try {
      await _scrollController.animateTo(
        position.maxScrollExtent,
        duration: Duration(milliseconds: durationMs),
        curve: Curves.linear,
      );
      if (mounted && runId == _scrollRunId &&
          _scrollController.hasClients &&
          _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 1) {
        _autoRequested = false;
      }
    } finally {
      if (mounted && runId == _scrollRunId) {
        setState(() => _scrolling = false);
      }
    }
  }

  void _resumeAfterManualDrag() {
    if (!_autoRequested) return;
    Future<void>.delayed(const Duration(milliseconds: 80), () {
      if (mounted && _autoRequested && !_manualInteraction && !_scrolling) {
        _startScrolling();
      }
    });
  }

  void _stopScrolling() {
    ++_scrollRunId;
    _autoRequested = false;
    _manualInteraction = false;
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.offset);
    }
    if (mounted) setState(() => _scrolling = false);
  }

  @override
  void dispose() {
    ++_scrollRunId;
    _saveTimer?.cancel();
    unawaited(_persistCurrentPosition());
    _scrollController.removeListener(_scheduleSavePosition);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('قراءة متتابعة - ${widget.name}'),
          backgroundColor: green,
          foregroundColor: Colors.white,
        ),
        body: FutureBuilder<_ContinuousReaderData>(
          future: _data,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('تعذر تحميل القراءة المتتابعة: ${snapshot.error}'));
            }
            final data = snapshot.data!;
            _restorePosition();
            final children = <Widget>[
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: green, borderRadius: BorderRadius.circular(14)),
                child: Column(children: [
                  Text('قرآن كريم • سورة ${widget.name}', style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('قراءة نصية مع تمرير رأسي متواصل', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ]),
              ),
              for (var i = widget.initialAyah - 1; i < data.ayahs.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 5),
                  child: Text(
                    '${data.ayahs[i]} ﴿${i + 1}﴾',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.justify,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                    textWidthBasis: TextWidthBasis.parent,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: _fontSize,
                      height: 2.0,
                      color: const Color(0xFF30251E),
                    ),
                  ),
                ),
            ];
            return Column(children: [
              ReadingMarksControls(
                section: 'quran_text_${widget.number}',
                label: 'سورة ${widget.name} - موضع القراءة الحالي',
                getPosition: () => _scrollController.hasClients ? _scrollController.offset : 0,
                onJump: (value) { _stopScrolling(); if (_scrollController.hasClients) _scrollController.jumpTo(value.clamp(0.0, _scrollController.position.maxScrollExtent).toDouble()); },
              ),
              Expanded(child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollStartNotification &&
                      notification.dragDetails != null) {
                    _manualInteraction = true;
                  } else if (notification is ScrollEndNotification && _manualInteraction) {
                    _manualInteraction = false;
                    _resumeAfterManualDrag();
                  }
                  return false;
                },
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
                  children: children,
                ),
              )),
              Material(
                elevation: 8,
                color: Colors.white,
                child: SafeArea(top: false, child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Row(children: [
                      IconButton(
                        tooltip: 'تصغير حجم الخط',
                        onPressed: _fontSize > 18 ? () => setState(() => _fontSize = (_fontSize - 2).clamp(18, 44)) : null,
                        icon: const Icon(Icons.text_decrease, color: green),
                      ),
                      Expanded(child: Slider(
                        value: _fontSize,
                        min: 18,
                        max: 44,
                        divisions: 13,
                        label: _fontSize.round().toString(),
                        activeColor: green,
                        onChanged: (value) {
                          setState(() => _fontSize = value);
                          unawaited(_saveReaderSettings());
                        },
                      )),
                      IconButton(
                        tooltip: 'تكبير حجم الخط',
                        onPressed: _fontSize < 44 ? () => setState(() => _fontSize = (_fontSize + 2).clamp(18, 44)) : null,
                        icon: const Icon(Icons.text_increase, color: green),
                      ),
                      Text(_fontSize.round().toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ]),
                    Wrap(spacing: 6, children: [
                      for (final preset in const [('بطيء', 45.0), ('متوسط', 140.0), ('سريع', 300.0)])
                        ChoiceChip(
                          label: Text(preset.$1),
                          selected: _speed == preset.$2,
                          onSelected: (_) {
                            setState(() => _speed = preset.$2);
                            unawaited(_saveReaderSettings());
                          },
                        ),
                    ]),
                    Row(children: [
                      const Text('سرعة التمرير', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(child: Slider(
                        value: _speed, min: 20, max: 400, divisions: 38,
                        label: '${_speed.round()}',
                        activeColor: green,
                        onChanged: (value) => setState(() => _speed = value),
                      )),
                      Text('${_speed.round()}'),
                    ]),
                    Row(children: [
                      Expanded(child: FilledButton.icon(
                        onPressed: _autoRequested ? _stopScrolling : _startScrolling,
                        icon: Icon(_autoRequested ? Icons.pause : Icons.play_arrow),
                        label: Text(_autoRequested ? 'إيقاف التمرير' : 'ابدأ التمرير التلقائي'),
                        style: FilledButton.styleFrom(backgroundColor: green),
                      )),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'العودة إلى بداية السورة',
                        onPressed: () {
                          _stopScrolling();
                          if (_scrollController.hasClients) _scrollController.animateTo(0, duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
                        },
                        icon: const Icon(Icons.vertical_align_top, color: green),
                      ),
                    ]),
                  ]),
                )),
              ),
            ]);
          },
        ),
      ),
    );
  }
}


class MushafPageReader extends StatefulWidget {
 final int number; final String name;
 const MushafPageReader({super.key,required this.number,required this.name});
 @override State<MushafPageReader> createState()=>_MushafPageReaderState();
}
class _MushafPageReaderState extends State<MushafPageReader>{
 late Future<List<Map<String,dynamic>>> futurePages; final PageController controller=PageController(); int index=0;
 @override void initState(){super.initState();futurePages=_load();}
 Future<List<Map<String,dynamic>>> _load() async {
  final lines=(await rootBundle.loadString('assets/quran-uthmani.txt')).split('\n');
  if(lines.length!=6236)throw Exception('ملف القرآن غير مكتمل');
  final meta=jsonDecode(await rootBundle.loadString('assets/quran-pages.json')) as List<dynamic>;
  if(meta.length!=604)throw Exception('بيانات الصفحات غير مكتملة');
  final starts=<String,int>{};var currentPage=1;
  for(final raw in meta){final e=raw as Map<String,dynamic>;final sn=e['sura'] as int;final an=e['aya'] as int;final pn=e['page'] as int;starts['$sn:$an']=pn;if(sn<widget.number||(sn==widget.number&&an<=1))currentPage=pn;}
  final first=QuranPage.surahAyahCounts.take(widget.number-1).fold<int>(0,(a,b)=>a+b);final count=QuranPage.surahAyahCounts[widget.number-1];
  final out=<Map<String,dynamic>>[];var group=<Map<String,dynamic>>[];
  for(var i=0;i<count;i++){final n=i+1;final p=starts['${widget.number}:$n'];if(p!=null&&p!=currentPage&&group.isNotEmpty){out.add({'page':currentPage,'ayahs':group});group=<Map<String,dynamic>>[];currentPage=p;}group.add({'text':lines[first+i],'number':n});}
  if(group.isNotEmpty)out.add({'page':currentPage,'ayahs':group});return out;
 }
 List<InlineSpan> _colorAllah(String text){final out=<InlineSpan>[];final re=RegExp(r'(اللَّهُ|اللَّهِ|اللَّهَ|اللَّه|الله)');var start=0;for(final m in re.allMatches(text)){if(m.start>start)out.add(TextSpan(text:text.substring(start,m.start)));out.add(TextSpan(text:m.group(0),style:const TextStyle(color:Color(0xFFB3261E),fontWeight:FontWeight.w600)));start=m.end;}if(start<text.length)out.add(TextSpan(text:text.substring(start)));return out;}
 @override void dispose(){controller.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(
  appBar:AppBar(title:Text('مصحف ${widget.name}'),backgroundColor:green,foregroundColor:Colors.white),
  body:FutureBuilder<List<Map<String,dynamic>>>(future:futurePages,builder:(context,snap){
   if(snap.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());
   if(snap.hasError)return Center(child:Text('تعذر فتح المصحف: ${snap.error}'));
   final pages=snap.data??[];if(pages.isEmpty)return const Center(child:Text('لا توجد صفحات'));
   return Column(children:[
    Padding(padding:const EdgeInsets.all(8),child:Text('صفحة ${index+1} من ${pages.length} • اسحب أفقيًا لتقليب الورقة',style:const TextStyle(color:green,fontWeight:FontWeight.bold))),
    Expanded(child:PageView.builder(controller:controller,itemCount:pages.length,onPageChanged:(v)=>setState(()=>index=v),itemBuilder:(context,i){
     final p=pages[i];final ayahs=p['ayahs'] as List<Map<String,dynamic>>;
     return Container(margin:const EdgeInsets.fromLTRB(10,4,10,12),padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:ivory,border:Border.all(color:softGold),borderRadius:BorderRadius.circular(8),boxShadow:const [BoxShadow(color:Color(0x22000000),blurRadius:8,offset:Offset(0,3))]),child:SingleChildScrollView(child:Column(children:[
      Text('سُورَةُ ${widget.name}',style:const TextStyle(color:Colors.black,fontWeight:FontWeight.bold,fontSize:19)),const Divider(height:24,color:Color(0xFFB9A77E)),
      Text.rich(TextSpan(children:[for(final a in ayahs)...[..._colorAllah(a['text'] as String),TextSpan(text:' ﴿${a['number']}﴾  ')]]),textAlign:TextAlign.justify,textDirection:TextDirection.rtl,style:const TextStyle(fontSize:22,height:2.05,color:Colors.black)),
      const SizedBox(height:16),Text('— ${p['page']} —',style:const TextStyle(color:Colors.black54)),
     ])));
    })),
    SafeArea(top:false,child:Row(children:[
     IconButton(onPressed:index==0?null:()=>controller.previousPage(duration:const Duration(milliseconds:300),curve:Curves.easeInOut),icon:const Icon(Icons.chevron_right)),
     Expanded(child:Slider(value:index.toDouble(),min:0,max:(pages.length-1).toDouble(),divisions:pages.length>1?pages.length-1:null,onChanged:(v)=>controller.jumpToPage(v.round()),activeColor:green)),
     IconButton(onPressed:index>=pages.length-1?null:()=>controller.nextPage(duration:const Duration(milliseconds:300),curve:Curves.easeInOut),icon:const Icon(Icons.chevron_left)),
    ])),
   ]);
  }),
 ));
}

class MushafBookReader extends StatefulWidget {
  final int initialSurah;
  final int initialAyah;
  const MushafBookReader({super.key, this.initialSurah = 1, this.initialAyah = 1});
  @override
  State<MushafBookReader> createState() => _MushafBookReaderState();
}

class _MushafBookReaderState extends State<MushafBookReader> {
  late Future<List<Map<String, dynamic>>> futurePages;
  final PageController controller = PageController();
  int index = 0;
  bool _initialJumpDone = false;
  bool _restorePageDone = false;

  @override
  void initState() {
    super.initState();
    futurePages = _loadPages();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  Future<List<Map<String, dynamic>>> _loadPages() async {
    final lines = (await rootBundle.loadString('assets/quran-uthmani.txt')).split('\n');
    if (lines.length != 6236) throw Exception('ملف القرآن غير مكتمل: ${lines.length} آية');
    final metadata = jsonDecode(await rootBundle.loadString('assets/quran-pages.json')) as List<dynamic>;
    if (metadata.length != 604) throw Exception('بيانات صفحات المصحف غير مكتملة.');

    final allAyahs = <Map<String, dynamic>>[];
    var offset = 0;
    for (var s = 0; s < quranAyahCounts.length; s++) {
      for (var a = 1; a <= quranAyahCounts[s]; a++) {
        allAyahs.add({'text': lines[offset++], 'number': a, 'surah': s + 1});
      }
    }

    final starts = <int>[];
    for (final raw in metadata) {
      final entry = raw as Map<String, dynamic>;
      final surah = entry['sura'] as int;
      final ayah = entry['aya'] as int;
      if (surah < 1 || surah > 114 || ayah < 1 || ayah > quranAyahCounts[surah - 1]) {
        throw Exception('موضع صفحة غير صحيح في بيانات المصحف.');
      }
      starts.add(quranAyahCounts.take(surah - 1).fold<int>(0, (sum, n) => sum + n) + ayah - 1);
    }
    if (starts.length != 604 || starts.first != 0) throw Exception('بداية صفحات المصحف غير صحيحة.');
    for (var i = 1; i < starts.length; i++) {
      if (starts[i] <= starts[i - 1]) throw Exception('ترتيب صفحات المصحف غير صحيح.');
    }

    return List.generate(604, (pageIndex) {
      final start = starts[pageIndex];
      final end = pageIndex == 603 ? allAyahs.length : starts[pageIndex + 1];
      return {'page': pageIndex + 1, 'ayahs': allAyahs.sublist(start, end)};
    });
  }


  @override
  void dispose() {
    controller.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('قرآن مجيد'), backgroundColor: green, foregroundColor: Colors.white),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: futurePages,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('تعذر فتح المصحف: ${snapshot.error}', textAlign: TextAlign.center)));
          final pages = snapshot.data ?? [];
          if (pages.isEmpty) return const Center(child: Text('لا توجد صفحات'));
          if (!_initialJumpDone) {
            _initialJumpDone = true;
            final target = pages.indexWhere((page) => (page['ayahs'] as List).any((a) => a['surah'] == widget.initialSurah && a['number'] == widget.initialAyah));
            if (target >= 0) {
              index = target;
              WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted && controller.hasClients) controller.jumpToPage(target); });
            }
            ReadingMarks.loadLast('mushaf_pages').then((saved) {
              if (!mounted || _restorePageDone) return;
              _restorePageDone = true;
              if (widget.initialSurah == 1 && widget.initialAyah == 1 && saved > 0) {
                final savedPage = saved.round().clamp(0, pages.length - 1);
                index = savedPage;
                WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted && controller.hasClients) controller.jumpToPage(savedPage); });
              }
            });
          }
          return Column(children: [
            QuranLocationPicker(
              title: 'فهرس قرآن مجيد',
              onOpen: (surah, ayah) {
                final target = pages.indexWhere((page) => (page['ayahs'] as List).any((a) => a['surah'] == surah && a['number'] == ayah));
                if (target >= 0) controller.jumpToPage(target);
              },
            ),
            Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Text('صفحة ${index + 1} من 604 • اسحب يمينًا ويسارًا للتقليب', style: const TextStyle(color: green, fontWeight: FontWeight.bold))),
            Expanded(child: PageView.builder(
              controller: controller,
              itemCount: pages.length,
              onPageChanged: (value) { setState(() => index = value); ReadingMarks.saveLast('mushaf_pages', value.toDouble()); },
              itemBuilder: (context, pageIndex) {
                final pageNumber = pageIndex + 1;
                return Container(
                  margin: const EdgeInsets.fromLTRB(8, 2, 8, 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F3E8),
                    border: Border.all(color: softGold, width: 1.2),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 8, offset: Offset(0, 3))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/mushaf_pages/$pageNumber.png',
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stack) => Center(
                        child: Text('تعذر فتح صورة الصفحة $pageNumber من ملفات التطبيق.', textAlign: TextAlign.center),
                      ),
                    ),
                  ),
                );
              },
            )),
            ReadingMarksControls(
              section: 'mushaf_pages',
              label: 'قرآن مجيد - صفحة ${index + 1}',
              getPosition: () => index.toDouble(),
              onJump: (value) => controller.jumpToPage(value.round().clamp(0, 603).toInt()),
            ),
            SafeArea(top: false, child: Row(children: [
              IconButton(onPressed: index == 0 ? null : () => controller.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut), icon: const Icon(Icons.chevron_right)),
              Expanded(child: Slider(value: index.toDouble(), min: 0, max: 603, divisions: 603, onChanged: (v) => controller.jumpToPage(v.round()), activeColor: green)),
              IconButton(onPressed: index >= 603 ? null : () => controller.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut), icon: const Icon(Icons.chevron_left)),
            ])),
          ]);
        },
      ),
    ),
  );
}

class _ContinuousReaderData {
  final List<String> ayahs;
  const _ContinuousReaderData(this.ayahs);
}

class Dh{final String t;final int n;const Dh(this.t,this.n);}
const ayatKursi='اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ';
const ikhlas='قُلْ هُوَ اللَّهُ أَحَدٌ ۝ اللَّهُ الصَّمَدُ ۝ لَمْ يَلِدْ وَلَمْ يُولَدْ ۝ وَلَمْ يَكُنْ لَهُ كُفُوًا أَحَدٌ';
const falaq='قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ۝ مِنْ شَرِّ مَا خَلَقَ ۝ وَمِنْ شَرِّ غَاسِقٍ إِذَا وَقَبَ ۝ وَمِنْ شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ ۝ وَمِنْ شَرِّ حَاسِدٍ إِذَا حَسَدَ';
const nas='قُلْ أَعُوذُ بِرَبِّ النَّاسِ ۝ مَلِكِ النَّاسِ ۝ إِلَٰهِ النَّاسِ ۝ مِنْ شَرِّ الْوَسْوَاسِ الْخَنَّاسِ ۝ الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ ۝ مِنَ الْجِنَّةِ وَالنَّاسِ';
const sayyid='اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَٰهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي، فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ.';
const commonMorningEvening=[ Dh('اللَّهُمَّ عَالِمَ الْغَيْبِ وَالشَّهَادَةِ، فَاطِرَ السَّمَاوَاتِ وَالْأَرْضِ، رَبَّ كُلِّ شَيْءٍ وَمَلِيكَهُ، أَشْهَدُ أَنْ لَا إِلَٰهَ إِلَّا أَنْتَ، أَعُوذُ بِكَ مِنْ شَرِّ نَفْسِي، وَمِنْ شَرِّ الشَّيْطَانِ وَشِرْكِهِ، وَأَنْ أَقْتَرِفَ عَلَى نَفْسِي سُوءًا أَوْ أَجُرَّهُ إِلَى مُسْلِمٍ.',1),

 Dh(ayatKursi,1),
 Dh('سورة الإخلاص: '+ikhlas,3),
 Dh('سورة الفلق: '+falaq,3),
 Dh('سورة الناس: '+nas,3),
 Dh(sayyid,1),
 Dh('بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ.',3),
 Dh('رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ ﷺ نَبِيًّا.',3),
 Dh('سُبْحَانَ اللَّهِ وَبِحَمْدِهِ.',100),
 Dh('حَسْبِيَ اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ، عَلَيْهِ تَوَكَّلْتُ، وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ.',7),
 Dh('اللَّهُمَّ عَافِنِي فِي بَدَنِي، اللَّهُمَّ عَافِنِي فِي سَمْعِي، اللَّهُمَّ عَافِنِي فِي بَصَرِي، لَا إِلَٰهَ إِلَّا أَنْتَ.',3),
 Dh('اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْكُفْرِ وَالْفَقْرِ، وَأَعُوذُ بِكَ مِنْ عَذَابِ الْقَبْرِ، لَا إِلَٰهَ إِلَّا أَنْتَ.',3),
 Dh('اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدِّينِ وَالدُّنْيَا وَالْآخِرَةِ، اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي دِينِي وَدُنْيَايَ وَأَهْلِي وَمَالِي، اللَّهُمَّ اسْتُرْ عَوْرَاتِي، وَآمِنْ رَوْعَاتِي، اللَّهُمَّ احْفَظْنِي مِنْ بَيْنِ يَدَيَّ، وَمِنْ خَلْفِي، وَعَنْ يَمِينِي، وَعَنْ شِمَالِي، وَمِنْ فَوْقِي، وَأَعُوذُ بِعَظَمَتِكَ أَنْ أُغْتَالَ مِنْ تَحْتِي.',1),
 Dh('يَا حَيُّ يَا قَيُّومُ، بِرَحْمَتِكَ أَسْتَغِيثُ، أَصْلِحْ لِي شَأْنِي كُلَّهُ، وَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ.',3),
 Dh('اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ، وَأَعُوذُ بِكَ مِنَ الْعَجْزِ وَالْكَسَلِ، وَأَعُوذُ بِكَ مِنَ الْجُبْنِ وَالْبُخْلِ، وَأَعُوذُ بِكَ مِنْ غَلَبَةِ الدَّيْنِ وَقَهْرِ الرِّجَالِ.',3),
 Dh('أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ الَّذِي لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ وَأَتُوبُ إِلَيْهِ.',3),
 Dh('يَا رَبِّ، لَكَ الْحَمْدُ كَمَا يَنْبَغِي لِجَلَالِ وَجْهِكَ وَعَظِيمِ سُلْطَانِكَ.',3),
 Dh('اللَّهُمَّ إِنَّا نَعُوذُ بِكَ أَنْ نُشْرِكَ بِكَ شَيْئًا نَعْلَمُهُ، وَنَسْتَغْفِرُكَ لِمَا لَا نَعْلَمُهُ.',3),
 Dh('اللَّهُمَّ صَلِّ وَسَلِّمْ وَبَارِكْ عَلَى سَيِّدِنَا مُحَمَّدٍ.',10),
 Dh('لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ.',10),
];
const morning=[
 ...commonMorningEvening,
 Dh('اللَّهُمَّ مَا أَصْبَحَ بِي مِنْ نِعْمَةٍ، أَوْ بِأَحَدٍ مِنْ خَلْقِكَ، فَمِنْكَ وَحْدَكَ لَا شَرِيكَ لَكَ، فَلَكَ الْحَمْدُ وَلَكَ الشُّكْرُ.',1),
 Dh('اللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ النُّشُورُ.',1),
 Dh('أَصْبَحْنَا عَلَى فِطْرَةِ الْإِسْلَامِ، وَكَلِمَةِ الْإِخْلَاصِ، وَدِينِ نَبِيِّنَا مُحَمَّدٍ ﷺ، وَمِلَّةِ أَبِينَا إِبْرَاهِيمَ حَنِيفًا مُسْلِمًا، وَمَا كَانَ مِنَ الْمُشْرِكِينَ.',1),
 Dh('سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، عَدَدَ خَلْقِهِ، وَرِضَا نَفْسِهِ، وَزِنَةَ عَرْشِهِ، وَمِدَادَ كَلِمَاتِهِ.',3),
 Dh('أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ رَبِّ الْعَالَمِينَ، اللَّهُمَّ إِنِّي أَسْأَلُكَ خَيْرَ هَذَا الْيَوْمِ: فَتْحَهُ، وَنَصْرَهُ، وَنُورَهُ، وَبَرَكَتَهُ، وَهُدَاهُ، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِيهِ وَشَرِّ مَا بَعْدَهُ.',1),
  Dh('أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ. رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذَا الْيَوْمِ وَخَيْرَ مَا بَعْدَهُ، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذَا الْيَوْمِ وَشَرِّ مَا بَعْدَهُ. رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ.',1),
 Dh('اللَّهُمَّ إِنِّي أَصْبَحْتُ مِنْكَ فِي نِعْمَةٍ وَعَافِيَةٍ وَسِتْرٍ، فَأَتِمَّ عَلَيَّ نِعْمَتَكَ وَعَافِيَتَكَ وَسِتْرَكَ فِي الدُّنْيَا وَالْآخِرَةِ.',3),
 Dh('اللَّهُمَّ إِنِّي عَبْدُكَ، وَابْنُ عَبْدِكَ، وَابْنُ أَمَتِكَ، نَاصِيَتِي بِيَدِكَ، مَاضٍ فِيَّ حُكْمُكَ، عَدْلٌ فِيَّ قَضَاؤُكَ، أَسْأَلُكَ بِكُلِّ اسْمٍ هُوَ لَكَ، سَمَّيْتَ بِهِ نَفْسَكَ، أَوْ أَنْزَلْتَهُ فِي كِتَابِكَ، أَوْ عَلَّمْتَهُ أَحَدًا مِنْ خَلْقِكَ، أَوِ اسْتَأْثَرْتَ بِهِ فِي عِلْمِ الْغَيْبِ عِنْدَكَ، أَنْ تَجْعَلَ الْقُرْآنَ رَبِيعَ قَلْبِي، وَنُورَ صَدْرِي، وَجَلَاءَ حُزْنِي، وَذَهَابَ هَمِّي.',1),
 Dh('اللَّهُمَّ أَنْتَ رَبِّي، لَا إِلَٰهَ إِلَّا أَنْتَ، عَلَيْكَ تَوَكَّلْتُ، وَأَنْتَ رَبُّ الْعَرْشِ الْعَظِيمِ، مَا شَاءَ اللَّهُ كَانَ، وَمَا لَمْ يَشَأْ لَمْ يَكُنْ، وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ، أَعْلَمُ أَنَّ اللَّهَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، وَأَنَّ اللَّهَ قَدْ أَحَاطَ بِكُلِّ شَيْءٍ عِلْمًا، اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنْ شَرِّ نَفْسِي، وَمِنْ شَرِّ كُلِّ دَابَّةٍ أَنْتَ آخِذٌ بِنَاصِيَتِهَا، إِنَّ رَبِّي عَلَى صِرَاطٍ مُسْتَقِيمٍ.',1),
 Dh('اللَّهُمَّ إِنِّي أَصْبَحْتُ أُشْهِدُكَ، وَأُشْهِدُ حَمَلَةَ عَرْشِكَ، وَمَلَائِكَتَكَ، وَجَمِيعَ خَلْقِكَ، أَنَّكَ أَنْتَ اللَّهُ لَا إِلَٰهَ إِلَّا أَنْتَ وَحْدَكَ لَا شَرِيكَ لَكَ، وَأَنَّ مُحَمَّدًا عَبْدُكَ وَرَسُولُكَ.',4),
];
const evening=[
 ...commonMorningEvening,
 Dh('اللَّهُمَّ مَا أَمْسَى بِي مِنْ نِعْمَةٍ، أَوْ بِأَحَدٍ مِنْ خَلْقِكَ، فَمِنْكَ وَحْدَكَ لَا شَرِيكَ لَكَ، فَلَكَ الْحَمْدُ وَلَكَ الشُّكْرُ.',1),
 Dh('اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ الْمَصِيرُ.',1),
 Dh('أَمْسَيْنَا عَلَى فِطْرَةِ الْإِسْلَامِ، وَكَلِمَةِ الْإِخْلَاصِ، وَدِينِ نَبِيِّنَا مُحَمَّدٍ ﷺ، وَمِلَّةِ أَبِينَا إِبْرَاهِيمَ حَنِيفًا مُسْلِمًا، وَمَا كَانَ مِنَ الْمُشْرِكِينَ.',1),
 Dh('سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، عَدَدَ خَلْقِهِ، وَرِضَا نَفْسِهِ، وَزِنَةَ عَرْشِهِ، وَمِدَادَ كَلِمَاتِهِ.',3),
 Dh('أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ رَبِّ الْعَالَمِينَ، اللَّهُمَّ إِنِّي أَسْأَلُكَ خَيْرَ هَذِهِ اللَّيْلَةِ: فَتْحَهَا، وَنَصْرَهَا، وَنُورَهَا، وَبَرَكَتَهَا، وَهُدَاهَا، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِيهَا وَشَرِّ مَا بَعْدَهَا.',1),
  Dh('أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ. رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذِهِ اللَّيْلَةِ وَخَيْرَ مَا بَعْدَهَا، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذِهِ اللَّيْلَةِ وَشَرِّ مَا بَعْدَهَا. رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ.',1),
 Dh('اللَّهُمَّ إِنِّي أَمْسَيْتُ مِنْكَ فِي نِعْمَةٍ وَعَافِيَةٍ وَسِتْرٍ، فَأَتِمَّ عَلَيَّ نِعْمَتَكَ وَعَافِيَتَكَ وَسِتْرَكَ فِي الدُّنْيَا وَالْآخِرَةِ.',3),
 Dh('اللَّهُمَّ إِنِّي عَبْدُكَ، وَابْنُ عَبْدِكَ، وَابْنُ أَمَتِكَ، نَاصِيَتِي بِيَدِكَ، مَاضٍ فِيَّ حُكْمُكَ، عَدْلٌ فِيَّ قَضَاؤُكَ، أَسْأَلُكَ بِكُلِّ اسْمٍ هُوَ لَكَ، سَمَّيْتَ بِهِ نَفْسَكَ، أَوْ أَنْزَلْتَهُ فِي كِتَابِكَ، أَوْ عَلَّمْتَهُ أَحَدًا مِنْ خَلْقِكَ، أَوِ اسْتَأْثَرْتَ بِهِ فِي عِلْمِ الْغَيْبِ عِنْدَكَ، أَنْ تَجْعَلَ الْقُرْآنَ رَبِيعَ قَلْبِي، وَنُورَ صَدْرِي، وَجَلَاءَ حُزْنِي، وَذَهَابَ هَمِّي.',1),
 Dh('اللَّهُمَّ أَنْتَ رَبِّي، لَا إِلَٰهَ إِلَّا أَنْتَ، عَلَيْكَ تَوَكَّلْتُ، وَأَنْتَ رَبُّ الْعَرْشِ الْعَظِيمِ، مَا شَاءَ اللَّهُ كَانَ، وَمَا لَمْ يَشَأْ لَمْ يَكُنْ، وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ، أَعْلَمُ أَنَّ اللَّهَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، وَأَنَّ اللَّهَ قَدْ أَحَاطَ بِكُلِّ شَيْءٍ عِلْمًا، اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنْ شَرِّ نَفْسِي، وَمِنْ شَرِّ كُلِّ دَابَّةٍ أَنْتَ آخِذٌ بِنَاصِيَتِهَا، إِنَّ رَبِّي عَلَى صِرَاطٍ مُسْتَقِيمٍ.',1),
 Dh('أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ.',3),
 Dh('اللَّهُمَّ إِنِّي أَمْسَيْتُ أُشْهِدُكَ، وَأُشْهِدُ حَمَلَةَ عَرْشِكَ، وَمَلَائِكَتَكَ، وَجَمِيعَ خَلْقِكَ، أَنَّكَ أَنْتَ اللَّهُ لَا إِلَٰهَ إِلَّا أَنْتَ وَحْدَكَ لَا شَرِيكَ لَكَ، وَأَنَّ مُحَمَّدًا عَبْدُكَ وَرَسُولُكَ.',4),
 Dh('آمَنَ الرَّسُولُ بِمَا أُنْزِلَ إِلَيْهِ مِنْ رَبِّهِ وَالْمُؤْمِنُونَ ۚ كُلٌّ آمَنَ بِاللَّهِ وَمَلَائِكَتِهِ وَكُتُبِهِ وَرُسُلِهِ لَا نُفَرِّقُ بَيْنَ أَحَدٍ مِنْ رُسُلِهِ ۚ وَقَالُوا سَمِعْنَا وَأَطَعْنَا غُفْرَانَكَ رَبَّنَا وَإِلَيْكَ الْمَصِيرُ ۝ لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا ۚ لَهَا مَا كَسَبَتْ وَعَلَيْهَا مَا اكْتَسَبَتْ ۗ رَبَّنَا لَا تُؤَاخِذْنَا إِنْ نَسِينَا أَوْ أَخْطَأْنَا ۚ رَبَّنَا وَلَا تَحْمِلْ عَلَيْنَا إِصْرًا كَمَا حَمَلْتَهُ عَلَى الَّذِينَ مِنْ قَبْلِنَا ۚ رَبَّنَا وَلَا تُحَمِّلْنَا مَا لَا طَاقَةَ لَنَا بِهِ ۖ وَاعْفُ عَنَّا وَاغْفِرْ لَنَا وَارْحَمْنَا ۚ أَنْتَ مَوْلَانَا فَانْصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ.',1),
];
const after=[
 Dh('أَسْتَغْفِرُ اللَّهَ.',3),
 Dh('اللَّهُ أَكْبَرُ كَبِيرًا، عَدَدَ الشَّفْعِ وَالْوَتْرِ، وَكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ.',3),
 Dh('لَا إِلَهَ إِلَّا اللَّهُ، عَدَدَ الشَّفْعِ وَالْوَتْرِ، وَكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ.',3),
 Dh('اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ.',1),
 Dh('اللَّهُمَّ أَنْتَ السَّلَامُ، وَمِنْكَ السَّلَامُ، تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ.',1),
 Dh('لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ.',1),
 Dh('لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ.\nلَا إِلَهَ إِلَّا اللَّهُ، وَلَا نَعْبُدُ إِلَّا إِيَّاهُ، لَهُ النِّعْمَةُ، وَلَهُ الْفَضْلُ، وَلَهُ الثَّنَاءُ الْحَسَنُ.\nلَا إِلَهَ إِلَّا اللَّهُ، مُخْلِصِينَ لَهُ الدِّينَ وَلَوْ كَرِهَ الْكَافِرُونَ.',1),
 Dh('اللَّهُمَّ لَا مَانِعَ لِمَا أَعْطَيْتَ، وَلَا مُعْطِيَ لِمَا مَنَعْتَ، وَلَا يَنْفَعُ ذَا الْجَدِّ مِنْكَ الْجَدُّ.',1),
 Dh('سُبْحَانَ اللَّهِ.',33),
 Dh('الْحَمْدُ لِلَّهِ.',33),
 Dh('اللَّهُ أَكْبَرُ.',33),
 Dh('لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ.',1),
 Dh('آيَةُ الْكُرْسِيِّ: اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ. (البقرة: 255).',1),
 Dh('سُورَةُ الْإِخْلَاصِ: قُلْ هُوَ اللَّهُ أَحَدٌ، اللَّهُ الصَّمَدُ، لَمْ يَلِدْ وَلَمْ يُولَدْ، وَلَمْ يَكُنْ لَهُ كُفُوًا أَحَدٌ.',1),
 Dh('سُورَةُ الْفَلَقِ: قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ۝ مِنْ شَرِّ مَا خَلَقَ ۝ وَمِنْ شَرِّ غَاسِقٍ إِذَا وَقَبَ ۝ وَمِنْ شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ ۝ وَمِنْ شَرِّ حَاسِدٍ إِذَا حَسَدَ.',1),
 Dh('سُورَةُ النَّاسِ: قُلْ أَعُوذُ بِرَبِّ النَّاسِ ۝ مَلِكِ النَّاسِ ۝ إِلَٰهِ النَّاسِ ۝ مِنْ شَرِّ الْوَسْوَاسِ الْخَنَّاسِ ۝ الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ ۝ مِنَ الْجِنَّةِ وَالنَّاسِ.',1),
 Dh('يُقَالُ بَعْدَ صَلَاتَيِ الصُّبْحِ وَالْمَغْرِبِ: لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، يُحْيِي وَيُمِيتُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ.',10),
];
const dhikrOrder=[2,32,3,4,5,26,6,8,21,10,7,22,23,24,11,12,13,14,25,1,30,19,18,15,16,17,27,28,20,29,9,31];
class DhikrPage extends StatefulWidget{final bool after;const DhikrPage({super.key,required this.after});@override State<DhikrPage> createState()=>_DhikrState();}
class _DhikrState extends State<DhikrPage>{
 bool isEvening=false;
 bool afterFajrMaghrib=false;
 List<int> counts=[];
 List<Dh> get data=>widget.after
  ?after.map((d)=>(d.t.startsWith('سُورَةُ الْإِخْلَاصِ')||d.t.startsWith('سُورَةُ الْفَلَقِ')||d.t.startsWith('سُورَةُ النَّاسِ'))?Dh(d.t,afterFajrMaghrib?3:1):d).toList()
  :(isEvening
    ? [for(final id in dhikrOrder) evening[id-1]]
    : [for(final id in dhikrOrder) if(id!=30 && id!=32) morning[id<=20?id-1:(id==31?29:id-1)]]);
 @override void initState(){super.initState();counts=List<int>.filled(data.length,0);}
 void changePeriod(bool value){setState((){isEvening=value;counts=List<int>.filled(data.length,0);});}
 void changeAfterPrayer(bool value){setState((){afterFajrMaghrib=value;counts=List<int>.filled(data.length,0);});}
 @override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(12),children:[
  if(widget.after)Padding(padding:const EdgeInsets.only(bottom:12),child:Row(children:[
   Expanded(child:ChoiceChip(label:const Center(child:Text('الفجر والمغرب')),selected:afterFajrMaghrib,onSelected:(_)=>changeAfterPrayer(true))),
   const SizedBox(width:8),
   Expanded(child:ChoiceChip(label:const Center(child:Text('باقي الصلوات')),selected:!afterFajrMaghrib,onSelected:(_)=>changeAfterPrayer(false))),
  ])),
  if(!widget.after)Padding(padding:const EdgeInsets.only(bottom:12),child:Row(children:[
   Expanded(child:ChoiceChip(label:const Center(child:Text('أذكار الصباح')),selected:!isEvening,onSelected:(_)=>changePeriod(false))),
   const SizedBox(width:8),
   Expanded(child:ChoiceChip(label:const Center(child:Text('أذكار المساء')),selected:isEvening,onSelected:(_)=>changePeriod(true))),
  ])),
  for(int i=0;i<data.length;i++)Builder(builder:(context){
   final d=data[i];final done=counts[i]>=d.n;
   return Card(margin:const EdgeInsets.only(bottom:12),child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    Text(d.t,textAlign:TextAlign.center,style:const TextStyle(fontSize:19,height:1.9)),
    Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text('المطلوب: ${d.n}'),Text('${counts[i]} / ${d.n}'),TextButton(onPressed:()=>setState(()=>counts[i]=0),child:const Text('إعادة'))]),
    LinearProgressIndicator(value:(counts[i]/d.n).clamp(0,1),color:green),
    const SizedBox(height:8),
    FilledButton(onPressed:done?null:()=>setState(()=>counts[i]++),child:Text(done?'اكتمل الذكر':'اضغط للتسبيح')),
   ])));
  }),
 ]);
}

class TasbeehPage extends StatefulWidget{const TasbeehPage({super.key});@override State<TasbeehPage> createState()=>_TasbeehState();}
class _TasbeehState extends State<TasbeehPage>{
 int count=0,target=33;String phrase='سبحان الله';
 static const phrases=['سبحان الله','الحمد لله','الله أكبر','أستغفر الله','لا إله إلا الله','الصلاة على النبي ﷺ','سبحان الله العظيم وبحمده','لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير','أستغفر الله العظيم الذي لا إله إلا هو الحي القيوم وأتوب إليه','سبحان الله وبحمده سبحان الله العظيم','اللهم إنك عفو تحب العفو فاعف عني','سبحان الله وبحمده، عدد خلقه ورضا نفسه وزنة عرشه ومداد كلماته','سبحان الله والحمد لله ولا إله إلا الله والله أكبر','لا حول ولا قوة إلا بالله'];
 @override Widget build(BuildContext c)=>Center(child:Padding(padding:const EdgeInsets.all(20),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
 DropdownButton<String>(value:phrase,isExpanded:true,items:phrases.map((v)=>DropdownMenuItem(value:v,child:Text(v,maxLines:2,overflow:TextOverflow.ellipsis))).toList(),onChanged:(v){if(v!=null)setState((){phrase=v;count=0;});}),
 const SizedBox(height:12),Text(phrase,textAlign:TextAlign.center,style:const TextStyle(fontSize:20,color:green,height:1.6)),Text('$count',style:const TextStyle(fontSize:64,color:green,fontWeight:FontWeight.bold)),Text('الهدف: ${target==0?'مفتوح':target}'),
 Wrap(spacing:8,children:[ChoiceChip(label:const Text('33'),selected:target==33,onSelected:(_)=>setState(()=>target=33)),ChoiceChip(label:const Text('100'),selected:target==100,onSelected:(_)=>setState(()=>target=100)),ChoiceChip(label:const Text('مفتوح'),selected:target==0,onSelected:(_)=>setState(()=>target=0))]),
 const SizedBox(height:16),SizedBox(width:180,height:180,child:FilledButton(style:FilledButton.styleFrom(shape:const CircleBorder(),backgroundColor:green),onPressed:()=>setState(()=>count++),child:const Text('تسبيح',style:TextStyle(fontSize:28)))),TextButton(onPressed:()=>setState(()=>count=0),child:const Text('تصفير العداد')),if(target>0&&count>=target)const Text('أحسنت، وصلت للهدف!',style:TextStyle(color:green))
 ])));
}
class Entry{final String title,body;const Entry(this.title,this.body);}
const duas=[
Entry('دعاء دخول السوق','لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، يُحْيِي وَيُمِيتُ، وَهُوَ حَيٌّ لَا يَمُوتُ، بِيَدِهِ الْخَيْرُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ.'),
Entry('دعاء جامع','رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ. — البقرة: 201'),
Entry('الهداية والثبات','رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِنْ لَدُنْكَ رَحْمَةً إِنَّكَ أَنْتَ الْوَهَّابُ. — آل عمران: 8'),
Entry('المغفرة','رَبَّنَا ظَلَمْنَا أَنْفُسَنَا وَإِنْ لَمْ تَغْفِرْ لَنَا وَتَرْحَمْنَا لَنَكُونَنَّ مِنَ الْخَاسِرِينَ. — الأعراف: 23'),
Entry('العلم','رَبِّ زِدْنِي عِلْمًا. — طه: 114'),Entry('التيسير','رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي. — طه: 25-26'),
Entry('تفريج الكرب','لَا إِلَهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ. — الأنبياء: 87'),
Entry('الرحمة','رَبِّ اغْفِرْ وَارْحَمْ وَأَنْتَ خَيْرُ الرَّاحِمِينَ. — المؤمنون: 118'),Entry('الوالدان','رَبِّ ارْحَمْهُمَا كَمَا رَبَّيَانِي صَغِيرًا. — الإسراء: 24'),
Entry('الرزق','رَبِّ إِنِّي لِمَا أَنْزَلْتَ إِلَيَّ مِنْ خَيْرٍ فَقِيرٌ. — القصص: 24'),Entry('التوكل','حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ. — آل عمران: 173'),
Entry('صلاح الذرية','رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ وَاجْعَلْنَا لِلْمُتَّقِينَ إِمَامًا. — الفرقان: 74'),
Entry('قبول العمل','رَبَّنَا تَقَبَّلْ مِنَّا إِنَّكَ أَنْتَ السَّمِيعُ الْعَلِيمُ. — البقرة: 127'),
Entry('العفو والعافية','اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالْآخِرَةِ. — أبو داود'),
Entry('الهدى والتقى','اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى وَالتُّقَى وَالْعَفَافَ وَالْغِنَى. — مسلم'),
Entry('إصلاح الدين والدنيا','اللَّهُمَّ أَصْلِحْ لِي دِينِيَ الَّذِي هُوَ عِصْمَةُ أَمْرِي، وَأَصْلِحْ لِي دُنْيَايَ الَّتِي فِيهَا مَعَاشِي، وَأَصْلِحْ لِي آخِرَتِي الَّتِي فِيهَا مَعَادِي. — مسلم'),
Entry('الثبات','يَا مُقَلِّبَ الْقُلُوبِ ثَبِّتْ قَلْبِي عَلَى دِينِكَ. — الترمذي'),
Entry('قضاء الدين','اللَّهُمَّ اكْفِنِي بِحَلَالِكَ عَنْ حَرَامِكَ، وَأَغْنِنِي بِفَضْلِكَ عَمَّنْ سِوَاكَ. — الترمذي'),
Entry('الهم والحزن','اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ، وَالْعَجْزِ وَالْكَسَلِ، وَالْجُبْنِ وَالْبُخْلِ، وَضَلَعِ الدَّيْنِ وَغَلَبَةِ الرِّجَالِ. — البخاري'),
Entry('سيد الاستغفار','اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي، فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ. — البخاري'),
Entry('عند المصيبة','إِنَّا لِلَّهِ وَإِنَّا إِلَيْهِ رَاجِعُونَ، اللَّهُمَّ أْجُرْنِي فِي مُصِيبَتِي وَأَخْلِفْ لِي خَيْرًا مِنْهَا. — مسلم')
];
const hadiths=[
Entry('1. الأعمال بالنيات','«إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ، وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى». — متفق عليه'),
Entry('2. مراتب الدين','حديث جبريل في الإسلام والإيمان والإحسان والإيمان بالساعة وأماراتها. — مسلم'),
Entry('3. أركان الإسلام','«بُنِيَ الْإِسْلَامُ عَلَى خَمْسٍ: شَهَادَةِ أَنْ لَا إِلَهَ إِلَّا اللَّهُ... وَإِقَامِ الصَّلَاةِ وَإِيتَاءِ الزَّكَاةِ وَالْحَجِّ وَصَوْمِ رَمَضَانَ». — متفق عليه'),
Entry('4. القدر','حديث ابن مسعود في أطوار خلق الإنسان وكتابة رزقه وأجله وعمله. — متفق عليه'),
Entry('5. رد البدع','«مَنْ أَحْدَثَ فِي أَمْرِنَا هَذَا مَا لَيْسَ مِنْهُ فَهُوَ رَدٌّ». — متفق عليه'),
Entry('6. الحلال والحرام','«إِنَّ الْحَلَالَ بَيِّنٌ وَإِنَّ الْحَرَامَ بَيِّنٌ، وَبَيْنَهُمَا أُمُورٌ مُشْتَبِهَاتٌ». — متفق عليه'),
Entry('7. النصيحة','«الدِّينُ النَّصِيحَةُ». قيل: لمن؟ قال: «لِلَّهِ وَلِكِتَابِهِ وَلِرَسُولِهِ وَلِأَئِمَّةِ الْمُسْلِمِينَ وَعَامَّتِهِمْ». — مسلم'),
Entry('8. عصمة الدم','حديث «أُمِرْتُ أَنْ أُقَاتِلَ النَّاسَ...» في الشهادة والصلاة والزكاة. — متفق عليه'),
Entry('9. اجتناب النهي','«مَا نَهَيْتُكُمْ عَنْهُ فَاجْتَنِبُوهُ، وَمَا أَمَرْتُكُمْ بِهِ فَأْتُوا مِنْهُ مَا اسْتَطَعْتُمْ». — متفق عليه'),
Entry('10. طيب المطعم','«إِنَّ اللَّهَ طَيِّبٌ لَا يَقْبَلُ إِلَّا طَيِّبًا». — مسلم'),
Entry('11. ترك الشبهات','«دَعْ مَا يَرِيبُكَ إِلَى مَا لَا يَرِيبُكَ». — الترمذي والنسائي'),
Entry('12. ترك ما لا يعني','«مِنْ حُسْنِ إِسْلَامِ الْمَرْءِ تَرْكُهُ مَا لَا يَعْنِيهِ». — الترمذي'),
Entry('13. محبة الخير','«لَا يُؤْمِنُ أَحَدُكُمْ حَتَّى يُحِبَّ لِأَخِيهِ مَا يُحِبُّ لِنَفْسِهِ». — متفق عليه'),
Entry('14. حرمة الدم','«لَا يَحِلُّ دَمُ امْرِئٍ مُسْلِمٍ... إِلَّا بِإِحْدَى ثَلَاثٍ». — متفق عليه'),
Entry('15. إكرام الجار','«مَنْ كَانَ يُؤْمِنُ بِاللَّهِ وَالْيَوْمِ الْآخِرِ فَلْيَقُلْ خَيْرًا أَوْ لِيَصْمُتْ، وَلْيُكْرِمْ جَارَهُ وَضَيْفَهُ». — متفق عليه'),
Entry('16. ترك الغضب','«لَا تَغْضَبْ». — البخاري'),Entry('17. الإحسان','«إِنَّ اللَّهَ كَتَبَ الْإِحْسَانَ عَلَى كُلِّ شَيْءٍ». — مسلم'),
Entry('18. التقوى','«اتَّقِ اللَّهَ حَيْثُمَا كُنْتَ، وَأَتْبِعِ السَّيِّئَةَ الْحَسَنَةَ تَمْحُهَا، وَخَالِقِ النَّاسَ بِخُلُقٍ حَسَنٍ». — الترمذي'),
Entry('19. احفظ الله','«احْفَظِ اللَّهَ يَحْفَظْكَ». — الترمذي'),Entry('20. الحياء','«إِذَا لَمْ تَسْتَحْيِ فَاصْنَعْ مَا شِئْتَ». — البخاري'),
Entry('21. الاستقامة','«قُلْ آمَنْتُ بِاللَّهِ ثُمَّ اسْتَقِمْ». — مسلم'),Entry('22. طريق الجنة','حديث الرجل الذي سأل عن الفرائض فقال ﷺ: «أَفْلَحَ إِنْ صَدَقَ». — مسلم'),
Entry('23. جوامع الخير','«الطُّهُورُ شَطْرُ الْإِيمَانِ... وَالصَّلَاةُ نُورٌ، وَالصَّدَقَةُ بُرْهَانٌ، وَالصَّبْرُ ضِيَاءٌ». — مسلم'),
Entry('24. تحريم الظلم','في الحديث القدسي: «إِنِّي حَرَّمْتُ الظُّلْمَ عَلَى نَفْسِي وَجَعَلْتُهُ بَيْنَكُمْ مُحَرَّمًا». — مسلم'),
Entry('25. أبواب الصدقة','«كُلُّ تَسْبِيحَةٍ صَدَقَةٌ، وَكُلُّ تَكْبِيرَةٍ صَدَقَةٌ». — مسلم'),
Entry('26. المعروف صدقة','«كُلُّ سُلَامَى مِنَ النَّاسِ عَلَيْهِ صَدَقَةٌ... وَيُجْزِئُ مِنْ ذَلِكَ رَكْعَتَانِ مِنَ الضُّحَى». — مسلم'),
Entry('27. البر والإثم','«الْبِرُّ حُسْنُ الْخُلُقِ، وَالْإِثْمُ مَا حَاكَ فِي صَدْرِكَ». — مسلم'),
Entry('28. لزوم السنة','«عَلَيْكُمْ بِسُنَّتِي وَسُنَّةِ الْخُلَفَاءِ الرَّاشِدِينَ الْمَهْدِيِّينَ». — أبو داود والترمذي'),
Entry('29. عمود الدين','«رَأْسُ الْأَمْرِ الْإِسْلَامُ، وَعَمُودُهُ الصَّلَاةُ». — الترمذي'),
Entry('30. حدود الله','«إِنَّ اللَّهَ فَرَضَ فَرَائِضَ فَلَا تُضَيِّعُوهَا، وَحَدَّ حُدُودًا فَلَا تَعْتَدُوهَا». — الدارقطني'),
Entry('31. الزهد','«ازْهَدْ فِي الدُّنْيَا يُحِبَّكَ اللَّهُ، وَازْهَدْ فِيمَا عِنْدَ النَّاسِ يُحِبَّكَ النَّاسُ». — ابن ماجه'),
Entry('32. لا ضرر','«لَا ضَرَرَ وَلَا ضِرَارَ». — ابن ماجه والدارقطني'),
Entry('33. البينة','«الْبَيِّنَةُ عَلَى الْمُدَّعِي وَالْيَمِينُ عَلَى مَنْ أَنْكَرَ». — البيهقي'),
Entry('34. تغيير المنكر','«مَنْ رَأَى مِنْكُمْ مُنْكَرًا فَلْيُغَيِّرْهُ بِيَدِهِ، فَإِنْ لَمْ يَسْتَطِعْ فَبِلِسَانِهِ». — مسلم'),
Entry('35. الأخوة','«لَا تَحَاسَدُوا وَلَا تَنَاجَشُوا وَلَا تَبَاغَضُوا... وَكُونُوا عِبَادَ اللَّهِ إِخْوَانًا». — مسلم'),
Entry('36. قضاء الحوائج','«مَنْ نَفَّسَ عَنْ مُؤْمِنٍ كُرْبَةً... وَاللَّهُ فِي عَوْنِ الْعَبْدِ». — مسلم'),
Entry('37. فضل الله','«إِنَّ اللَّهَ كَتَبَ الْحَسَنَاتِ وَالسَّيِّئَاتِ ثُمَّ بَيَّنَ ذَلِكَ». — متفق عليه'),
Entry('38. التقرب إلى الله','«مَنْ عَادَى لِي وَلِيًّا فَقَدْ آذَنْتُهُ بِالْحَرْبِ». — البخاري'),
Entry('39. التجاوز','«إِنَّ اللَّهَ تَجَاوَزَ لِي عَنْ أُمَّتِي الْخَطَأَ وَالنِّسْيَانَ وَمَا اسْتُكْرِهُوا عَلَيْهِ». — ابن ماجه'),
Entry('40. كن غريبًا','«كُنْ فِي الدُّنْيَا كَأَنَّكَ غَرِيبٌ أَوْ عَابِرُ سَبِيلٍ». — البخاري')
];
const stories = [
Entry('1. آدم عليه السلام', '''خلق الله آدم من تراب وسوّاه وعلّمه الأسماء، وأمر الملائكة بالسجود له فسجدوا إلا إبليس استكبر. وأسكن الله آدم وزوجه الجنة ونهاهما عن شجرة، فوسوس لهما الشيطان فأكلا منها. فاعترفا بذنبهما وقالا: ربنا ظلمنا أنفسنا وإن لم تغفر لنا وترحمنا لنكونن من الخاسرين. فتاب الله عليهما وهداهما، وأهبطهما إلى الأرض لتبدأ حياة البشر، وأخبرهما أن من اتبع هداه فلا خوف عليه ولا يحزن. وتعلّمنا قصته أن الكبر سبب السقوط، وأن التوبة الصادقة طريق الرجوع إلى الله.
المراجع: البقرة 30-39، الأعراف 11-27، طه 115-123.'''),
Entry('2. إدريس عليه السلام', '''ذكر الله إدريس عليه السلام في القرآن ووصفه بأنه صِدّيق نبي، وأخبر أنه رفعه مكانًا عليًا. وذكره مع إسماعيل وذي الكفل في جملة الصابرين الذين أدخلهم الله في رحمته، كما ذكره مع الأنبياء المصطفين. ولا يورد القرآن تفاصيل دعوته أو قومه أو أحداث حياته، لذلك لا يصح أن نضيف إلى قصته أخبارًا لا تثبت. والثابت أنه نبي كريم صادق، اصطفاه الله ورفع قدره، وكان من الصابرين ومن أهل رحمة الله.
المراجع: مريم 56-57، الأنبياء 85-86.'''),
Entry('3. نوح عليه السلام', '''أرسل الله نوحًا إلى قومه يدعوهم إلى عبادة الله وحده، فلبث فيهم ألف سنة إلا خمسين عامًا يدعوهم ليلًا ونهارًا، سرًا وجهرًا، ويذكّرهم بمغفرة الله. لكن أكثرهم كذبوا واستكبروا وتمسكوا بأصنامهم. فأوحى الله إليه أنه لن يؤمن إلا من قد آمن، وأمره بصنع السفينة. وسخر منه قومه، لكنه صبر حتى جاء أمر الله وفار التنور، فحمل في السفينة المؤمنين ومن كل زوجين اثنين. ورفض ابنه الركوب واعتصم بالجبل فكان من المغرقين. ثم استوت السفينة على الجودي ونجّى الله نوحًا والمؤمنين. وتعلمنا قصته طول النفس والثبات، وأن النجاة بالإيمان لا بمجرد القرابة.
المراجع: هود 25-49، نوح كاملة، المؤمنون 23-30، العنكبوت 14-15.'''),
Entry('4. هود عليه السلام', '''أرسل الله هودًا إلى عاد، وكانوا أصحاب قوة وبناء، فاغتروا بقوتهم وعبدوا غير الله. دعاهم هود إلى التوحيد والاستغفار، وذكّرهم بنعم الله ونهاهم عن التجبر والبطش. اتهموه بالسفاهة والكذب وأصروا على آلهتهم. فلما رأوا سحابة ظنوها مطرًا، فإذا هي الريح التي استعجلوها؛ ريح شديدة عاتية سلّطها الله عليهم أيامًا، فصاروا كأعجاز نخل خاوية. ونجّى الله هودًا والذين آمنوا معه. وتبين قصته أن القوة والمال لا يمنعان عذاب الله، وأن الشكر والتواضع خير من الغرور.
المراجع: الأعراف 65-72، هود 50-60، الأحقاف 21-26، الحاقة 6-8.'''),
Entry('5. صالح عليه السلام', '''أرسل الله صالحًا إلى ثمود، وكانوا ينحتون من الجبال بيوتًا، فدعاهم إلى عبادة الله وحده. طلبوا آية، فجعل الله لهم الناقة آية، وأمرهم أن يتركوها تأكل في أرض الله وألا يمسوها بسوء. لكن المستكبرين كذبوا وتآمروا على قتل الناقة فعقروها، وتحدوا صالحًا بالعذاب. فأخبرهم أن يتمتعوا في دارهم ثلاثة أيام، ثم أخذتهم الصيحة والرجفة فأصبحوا في ديارهم جاثمين. ونجّى الله صالحًا والمؤمنين. وتعلمنا قصته أن آيات الله تستوجب الإيمان والشكر، وأن العناد بعد قيام الحجة عاقبته وخيمة.
المراجع: الأعراف 73-79، هود 61-68، الحجر 80-84، الشعراء 141-159.'''),
Entry('6. إبراهيم عليه السلام', '''أنكر إبراهيم عبادة الأصنام والكواكب، ودعا أباه وقومه إلى عبادة الله خالق السماوات والأرض. وحين خرج قومه حطّم أصنامهم ليقيم عليهم الحجة، فلما سألوه أشار إلى كبيرها ليتبين عجزها عن الكلام. فألقوه في النار، فجعلها الله بردًا وسلامًا عليه. وهاجر في سبيل ربه، ورزقه الله إسماعيل وإسحاق، وابتلاه بالأمر بذبح ابنه فاستسلما لأمر الله وفداه الله بذبح عظيم. ثم رفع إبراهيم وإسماعيل قواعد الكعبة ودعوا الله أن يتقبل منهما. وجعل الله إبراهيم إمامًا وخليلًا. وقصته مثال للتوحيد واليقين والتضحية والتوكل.
المراجع: البقرة 124-129، الأنعام 74-83، الأنبياء 51-70، الصافات 99-113، إبراهيم 35-41.'''),
Entry('7. لوط عليه السلام', '''أرسل الله لوطًا إلى قوم اشتهروا بالفاحشة وقطع الطريق والمنكر، فدعاهم إلى تقوى الله وترك ما هم عليه. لكنهم استكبروا وهددوه بالإخراج من قريتهم. وجاءت الملائكة إلى لوط في صورة ضيوف، فساءه أمرهم، ثم أخبروه أنهم رسل ربه وأن قومه لن يصلوا إليهم. وأُمر لوط أن يسري بأهله ليلًا، إلا امرأته التي كانت مع الغابرين. فلما جاء أمر الله جعل عالي القرى سافلها وأمطر عليها حجارة، ونجّى لوطًا وأهله المؤمنين. وتؤكد قصته أن النجاة في طاعة الله، وأن الإصرار على الفاحشة والظلم عاقبته الهلاك.
المراجع: هود 77-83، الحجر 57-77، الشعراء 160-175، النمل 54-58.'''),
Entry('8. إسماعيل عليه السلام', '''إسماعيل ابن إبراهيم، وصفه الله بأنه صادق الوعد ورسول نبي، وكان يأمر أهله بالصلاة والزكاة. وفي ابتلاء الذبح رأى إبراهيم أنه يذبح ابنه، فعرض عليه الرؤيا، فقال إسماعيل: يا أبت افعل ما تؤمر ستجدني إن شاء الله من الصابرين. فلما أسلما وتله للجبين ناداه الله أنه قد صدّق الرؤيا وفداه بذبح عظيم. ثم شارك أباه في رفع قواعد الكعبة، وكانا يدعوان الله أن يتقبل منهما ويجعل من ذريتهما أمة مسلمة. وتبرز سيرته الصبر والوفاء والبر بالأب والتسليم لأمر الله.
المراجع: البقرة 125-129، مريم 54-55، الصافات 100-107.'''),
Entry('9. إسحاق عليه السلام', '''بشّرت الملائكة إبراهيم وزوجه سارة بإسحاق على كبر سنهما، فتعجبت سارة، فأخبرتهم الملائكة أن أمر الله لا يعجزه شيء. وجعل الله إسحاق نبيًا من الصالحين، ووهبه يعقوب، وبارك فيهما، وجعل في ذريتهما النبوة والكتاب. ويذكر القرآن إسحاق في مواضع الثناء على إبراهيم وأهل بيته، ويصفه بأنه من عباده المؤمنين المحسنين. ولا يفصل القرآن أحداث دعوته أو قومه كما فصل قصة يوسف وموسى، لذلك نقتصر على ما ثبت من البشارة والنبوّة والصلاح وامتداد النبوة في ذريته.
المراجع: هود 69-73، الحجر 51-56، الصافات 112-113، الأنبياء 72-73.'''),
Entry('10. يعقوب عليه السلام', '''يعقوب هو إسرائيل ابن إسحاق. ابتُلي بفقد ابنه يوسف بعد أن جاءه أبناؤه بقميصه وعليه دم كذب، فعرف أن الأمر مكيدة وقال: فصبر جميل. طال حزنه حتى ابيضت عيناه من الحزن، لكنه لم ييأس من روح الله، وأمر أبناءه أن يتحسسوا من يوسف وأخيه وألا يقنطوا من رحمة الله. ثم عاد الأبناء بقميص يوسف فألقوه على وجهه فارتد بصيرًا، واجتمع شمل الأسرة في مصر، وتحققت رؤيا يوسف القديمة. وتعلمنا قصته الصبر الجميل وحسن الظن بالله وعدم اليأس مهما طال البلاء.
المراجع: يوسف 4-18، 83-101، البقرة 132-133.'''),
Entry('11. يوسف عليه السلام', '''رأى يوسف صغيرًا أحد عشر كوكبًا والشمس والقمر يسجدون له، فنصحه أبوه ألا يقص الرؤيا على إخوته. غار إخوته فألقوه في الجب، ثم بيع في مصر ونشأ في بيت العزيز. راودته امرأة العزيز عن نفسه فاستعصم بالله، ثم سجن ظلمًا. وفي السجن دعا إلى التوحيد وفسر رؤيا صاحبيه. ثم فسر رؤيا الملك عن سنوات الخصب والجدب، فظهرت براءته وتولى خزائن الأرض. وجاء إخوته يطلبون الطعام فعرفهم، ثم كشف لهم عن نفسه وعفا عنهم. وأرسل قميصه إلى أبيه فعاد بصيرًا، واجتمعوا جميعًا. قصته تعلم العفة والصبر والعفو وحسن تدبير الله.
المراجع: سورة يوسف كاملة.'''),
Entry('12. أيوب عليه السلام', '''ابتلى الله أيوب في جسده وأهله وماله، فصبر ولم يترك عبادة ربه. دعا ربه بأدب: أني مسني الضر وأنت أرحم الراحمين، فاستجاب الله له وأمره أن يضرب برجله الأرض، فنبعت عين فاغتسل منها وشرب فكشف الله ما به من ضر. وردّ عليه أهله ومثلهم معهم رحمة من عنده. وأثنى الله عليه بأنه صابر ونعم العبد إنه أواب. ولا يذكر القرآن تفاصيل المرض أو مدته، فلا يصح الجزم بما لم يرد. وتعلمنا قصته أن البلاء لا يعني هوان العبد، وأن الدعاء والصبر والرجوع إلى الله أبواب للفرج.
المراجع: الأنبياء 83-84، ص 41-44.'''),
Entry('13. شعيب عليه السلام', '''أرسل الله شعيبًا إلى مدين، فدعاهم إلى عبادة الله وحده، ونهاهم عن التطفيف في الكيل والميزان وبخس الناس أشياءهم والإفساد في الأرض. ذكّرهم أن الحلال خير مما يجمعونه بالغش، وأنه لا يريد منهم أجرًا. استكبر الملأ وهددوه ومن آمن معه بالإخراج أو العودة إلى ملتهم، فتوكل على الله وسأله أن يحكم بالحق. أصر المكذبون على فسادهم، فجاءهم عذاب الرجفة والصيحة، فأصبحوا في ديارهم جاثمين، ونجّى الله شعيبًا والمؤمنين. وتبرز قصته أن الدين يشمل الأمانة في البيع والشراء، وأن الظلم والفساد من أسباب هلاك المجتمعات.
المراجع: الأعراف 85-93، هود 84-95، الشعراء 176-191.'''),
Entry('14. موسى عليه السلام', '''ولد موسى في زمن كان فرعون يقتل أبناء بني إسرائيل، فأوحى الله إلى أمه أن تلقيه في اليم إذا خافت عليه ووعدها أن يرده إليها. التقطه آل فرعون، وردّه الله إلى أمه ليرضع. ولما كبر خرج من مصر بعد حادثة قتل الرجل خطأً، وذهب إلى مدين. وفي طريق عودته ناداه الله في الوادي المقدس وكلفه بالرسالة إلى فرعون، وأيده بالعصا واليد البيضاء، وجعل هارون أخاه وزيرًا. دعا فرعون إلى التوحيد، فجمع السحرة فغلبت آية الله سحرهم فآمنوا. ثم خرج موسى ببني إسرائيل، فلحقهم فرعون، فضرب البحر بعصاه فانفلق ونجا المؤمنون وغرق فرعون. وأنزل الله عليه التوراة، وابتلي قومه بعبادة العجل. وقصته مثال الثقة بوعد الله ومواجهة الطغيان.
المراجع: القصص 3-46، طه 9-98، الشعراء 10-68، الأعراف 103-171.'''),
Entry('15. هارون عليه السلام', '''هارون أخو موسى، دعا موسى ربه أن يشد أزره به ويشركه في أمره، فجعله الله نبيًا ووزيرًا. خرج مع موسى إلى فرعون وشاركه في تبليغ الرسالة. وحين ذهب موسى لميقات ربه استخلف هارون على بني إسرائيل وأوصاه بالإصلاح. لكن السامري أضل طائفة منهم وصنع لهم عجلًا جسدًا له خوار، فحاول هارون أن يردهم إلى التوحيد ويحذرهم أنهم فُتنوا به وأن ربهم الرحمن. خشي أن يشتد الخلاف فينقسم بنو إسرائيل، فلما رجع موسى تبين له موقف أخيه. وتعلمنا قصته التعاون في الخير والحكمة في معالجة الفتن.
المراجع: طه 29-36، 90-94، الأعراف 142-151، مريم 53.'''),
Entry('16. ذو الكفل عليه السلام', '''ذكر الله ذا الكفل مع إسماعيل وإدريس، ووصفهم بالصبر وإدخالهم في رحمته، وذكره مرة أخرى في جملة الأخيار. ولم يذكر القرآن تفاصيل قومه أو رسالته أو أحداث حياته، كما لم يثبت في النص القرآني ما يسمح بسرد قصة طويلة محددة له. لذلك لا ننسب إليه حكايات متداولة لا دليل عليها. والثابت أنه عبد صالح أثنى الله عليه وقرنه بالصابرين والأخيار. وفي قصته تذكير بأن منزلة العبد عند الله تكون بالإيمان والصبر والعمل الصالح، لا بكثرة ما يعرف الناس من أخباره.
المراجع: الأنبياء 85-86، ص 48.'''),
Entry('17. داود عليه السلام', '''آتَى الله داود الملك والحكمة والنبوة وأنزل عليه الزبور، وألان له الحديد وعلّمه صنعة الدروع، وسخّر معه الجبال والطير يسبحن. وبرز في قصة طالوت حين قتل جالوت بإذن الله، ثم آتاه الله الملك والحكمة. وابتلاه الله بقصة الخصمين اللذين تسورا المحراب، ففهم أن ذلك اختبار فاستغفر ربه وخر راكعًا وأناب. وأمره الله أن يحكم بين الناس بالحق وألا يتبع الهوى. وكان عبدًا أوابًا كثير الرجوع إلى الله. وتظهر سيرته اجتماع القوة والعدل والعبادة، وأن صاحب السلطان يحتاج إلى مراقبة الله والإنابة إليه.
المراجع: البقرة 251، النساء 163، ص 17-26، سبأ 10-11، الأنبياء 78-80.'''),
Entry('18. سليمان عليه السلام', '''ورث سليمان داود في النبوة والملك، وعلّمه الله منطق الطير وسخّر له الريح والجن. تفقد الطير فلم يجد الهدهد، فلما جاءه بخبر ملكة سبأ وقومها الذين يسجدون للشمس، أرسل إليها كتابًا يدعوها إلى الإسلام. تشاور أهل مملكتها ثم جاءت إلى سليمان، فأراها آية من آيات الله ودعاها إلى عبادة الله وحده، فأسلمت لله رب العالمين. ومن قصته النملة التي حذرت قومها فتبسم سليمان من قولها وحمد الله. ولما مات لم تعلم الجن بموته إلا بعد أن أكلت دابة الأرض عصاه فخرّ، فعرفوا أنهم لا يعلمون الغيب. وتعلمنا قصته شكر النعمة والتواضع.
المراجع: النمل 15-44، سبأ 12-14، ص 30-40، الأنبياء 81-82.'''),
Entry('19. إلياس عليه السلام', '''أرسل الله إلياس إلى قومه، فدعاهم إلى تقوى الله وترك عبادة بعل الذي اتخذوه من دون الله. أنكر عليهم تركهم أحسن الخالقين، الله ربهم ورب آبائهم الأولين، فلم يستجيبوا إلا قليلًا. وأخبر الله أنه ترك عليه ثناءً حسنًا في الآخرين، وسلّم عليه، وأثنى عليه بأنه من عباده المؤمنين المحسنين. ولا يذكر القرآن تفاصيل زمنه أو أسماء قومه أو أحداثًا مطولة من حياته، لذلك نقتصر على ما ثبت ولا نضيف أخبارًا غير محققة. وفي قصته تذكير بأن أصل دعوة الأنبياء إخلاص العبادة لله وحده.
المراجع: الصافات 123-132، الأنعام 85.'''),
Entry('20. اليسع عليه السلام', '''ذكر الله اليسع في جملة الأنبياء الذين أنعم عليهم، ووصفه بأنه من الأخيار، وقرنه بإسماعيل ويونس ولوط في القرآن. ولا يورد القرآن تفاصيل دعوته أو قومه أو معجزاته أو مراحل حياته، لذلك لا يصح أن نملأ القصة بأخبار لا تثبت. والثابت أنه نبي كريم من عباد الله المصطفين الأخيار. وفي ذكره ضمن سلسلة الأنبياء تذكير بوحدة الرسالة، وبأن الله يختار من عباده من يشاء ويهديهم إلى صراط مستقيم.
المراجع: الأنعام 86-90، ص 48.'''),
Entry('21. يونس عليه السلام', '''خرج يونس مغاضبًا قبل أن يأذن الله له، فركب سفينة فساهم أهلها فكان من المدحضين، فالتقمه الحوت وهو مليم. وفي ظلمات البحر وبطن الحوت نادى ربه: لا إله إلا أنت سبحانك إني كنت من الظالمين. فاستجاب الله له ونجّاه من الغم، وقذفه بالعراء وهو سقيم، وأنبت عليه شجرة من يقطين. ثم أرسله الله إلى مائة ألف أو يزيدون، فآمنوا فمتعهم الله إلى حين. وكانت توبة قومه وإيمانهم سببًا في رفع العذاب عنهم. وتعلمنا قصته ألا نيأس من رحمة الله، وأن الدعاء والاعتراف بالخطأ والرجوع إلى الله أبواب للفرج.
المراجع: الأنبياء 87-88، الصافات 139-148، يونس 98، القلم 48-50.'''),
Entry('22. زكريا عليه السلام', '''كان زكريا نبيًا صالحًا وكفل مريم، وكان كلما دخل عليها المحراب وجد عندها رزقًا، فسألها عن مصدره فقالت إنه من عند الله. عند ذلك دعا ربه أن يهب له ذرية طيبة مع كبر سنه وعقم امرأته، فلم ييأس من رحمة الله. فاستجاب الله دعاءه وبشره بيحيى، وجعل له علامة ألا يكلم الناس ثلاث ليال وهو سوي. وكان زكريا وأهله يسارعون في الخيرات ويدعون الله رغبًا ورهبًا. وتعلمنا قصته حسن الظن بالله والإلحاح في الدعاء، وأن القدرة الإلهية لا تحدها الأسباب المعتادة.
المراجع: آل عمران 37-41، مريم 2-15، الأنبياء 89-90.'''),
Entry('23. يحيى عليه السلام', '''بشّر الله زكريا بيحيى وجعل اسمه مميزًا. آتاه الله الحكم صبيًا، وأعطاه الحنان والزكاة، وكان تقيًا بارًا بوالديه لا متكبرًا ولا عاصيًا. وأمره الله أن يأخذ الكتاب بقوة، فكان من الصالحين. وذكره القرآن بالسلام يوم ولد ويوم يموت ويوم يبعث حيًا. ولا يسرد القرآن تفاصيل دعوته أو وفاته، لذلك لا نضيف إلى قصته أخبارًا لا تثبت. وتبرز سيرته الطهر والتقوى والرحمة وبر الوالدين، وأن الهداية والفضل من الله يؤتيهما من يشاء.
المراجع: مريم 7-15، آل عمران 39، الأنبياء 90.'''),
Entry('24. عيسى عليه السلام', '''خلق الله عيسى من أم بلا أب آية للناس، وبشّر الملائكة مريم به وجيهًا في الدنيا والآخرة. ولما جاءت به قومها اتهموها، فأشار عيسى وهو في المهد إلى أنه عبد الله آتاه الكتاب وجعله نبيًا. أرسله الله إلى بني إسرائيل مصدقًا للتوراة، وأيده بالمعجزات بإذن الله: يخلق من الطين كهيئة الطير فينفخ فيه فيكون طيرًا بإذن الله، ويبرئ الأكمه والأبرص ويحيي الموتى بإذن الله. دعا إلى عبادة الله ربه وربهم، وآمن به الحواريون. وتآمر أعداؤه، لكن الله أخبر أنه رفعه إليه وما قتلوه وما صلبوه. وهو عبد الله ورسوله، وليس إلهًا ولا ابن إله.
المراجع: آل عمران 42-59، النساء 156-159، المائدة 110-120، مريم 16-36.'''),
Entry('25. محمد ﷺ', '''نشأ محمد بن عبد الله ﷺ يتيمًا، ورعاه الله، وعُرف بين قومه بالصدق والأمانة. ولما بلغ الأربعين نزل عليه الوحي وأمره الله أن يقرأ باسم ربه. بدأ الدعوة ثم جهر بها، فدعا قريشًا إلى توحيد الله وترك الأصنام، فآذاه المشركون وآذوا أصحابه، فصبر وثبت. ثم هاجر إلى المدينة وأقام مجتمعًا يقوم على الإيمان والأخوة والعدل، وواجه المسلمون الغزوات والشدائد. وكان النبي يشاور أصحابه ويعفو ويعلّمهم القرآن والسنة. ثم فتح الله له مكة فدخلها متواضعًا وعفا عن كثير ممن آذوه، وأتم الله به الدين. وبعد حجة الوداع توفي ﷺ وقد بلّغ الرسالة وأدى الأمانة. وهو خاتم النبيين، أرسله الله رحمة للعالمين.
المراجع: العلق 1-5، المدثر 1-7، الأحزاب 40، المائدة 3، الأنبياء 107، الفتح.'''),
];

class HadithLibraryPage extends StatefulWidget {
  const HadithLibraryPage({super.key});
  @override State<HadithLibraryPage> createState() => _HadithLibraryPageState();
}
class _HadithLibraryPageState extends State<HadithLibraryPage> {
  late Future<List<dynamic>> _hadiths;
  @override void initState() { super.initState(); _hadiths = _load(); }
  Future<List<dynamic>> _load() async {
    final raw = await rootBundle.loadString('assets/hadiths-1000.json');
    final decoded = jsonDecode(raw);
    if (decoded is! List || decoded.length != 1000) {
      throw Exception('ملف الأحاديث غير مكتمل؛ العدد المتوقع 1000 حديث.');
    }
    return decoded;
  }
  @override Widget build(BuildContext context) => FutureBuilder<List<dynamic>>(
    future: _hadiths,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(snapshot.error.toString(), textAlign: TextAlign.center)));
      }
      final rows = snapshot.data!;
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: rows.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) return const Padding(
            padding: EdgeInsets.fromLTRB(8, 8, 8, 16),
            child: Text('1000 حديث من صحيح البخاري وصحيح مسلم، بالنص العربي الكامل مع المصدر والرقم ودرجة الصحة.',
              style: TextStyle(color: green, fontWeight: FontWeight.bold, height: 1.7)),
          );
          final h = Map<String, dynamic>.from(rows[i - 1] as Map);
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('${i}. ${h['reference'] ?? 'حديث رقم $i'}',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: green)),
                const SizedBox(height: 8),
                SelectableText((h['text_ar'] ?? '').toString(),
                  style: const TextStyle(fontSize: 19, height: 2)),
                const SizedBox(height: 10),
                Text('${h['source'] ?? ''} • ${h['grade'] ?? 'صحيح بالإدراج في الصحيح'}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ]),
            ),
          );
        },
      );
    },
  );
}

class _SearchHit {
  final String category, title, body;
  final int? section, surah;
  const _SearchHit(this.category, this.title, this.body, {this.section, this.surah});
}
String _foldArabic(String value) => value.toLowerCase()
  .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '')
  .replaceAll(RegExp(r'[أإآٱ]'), 'ا')
  .replaceAll('ى', 'ي')
  .replaceAll('ة', 'ه');

class GlobalSearchPage extends StatefulWidget {
  const GlobalSearchPage({super.key});
  @override State<GlobalSearchPage> createState() => _GlobalSearchPageState();
}
class _GlobalSearchPageState extends State<GlobalSearchPage> {
  final TextEditingController _controller = TextEditingController();
  final List<_SearchHit> _index = [];
  List<_SearchHit> _results = [];
  bool _loading = true;
  String _error = '';

  @override void initState() { super.initState(); _buildIndex(); }
  @override void dispose() { _controller.dispose(); super.dispose(); }

  void _add(String category, String title, String body, {int? section, int? surah}) {
    if (body.trim().isEmpty) return;
    _index.add(_SearchHit(category, title, body, section: section, surah: surah));
  }

  Future<void> _buildIndex() async {
    try {
      final quranText = await rootBundle.loadString('assets/quran-uthmani.txt');
      final ayahs = quranText.split('\n');
      if (ayahs.length != 6236) throw Exception('ملف القرآن غير مكتمل.');
      var position = 0;
      for (var s = 0; s < quranAyahCounts.length; s++) {
        for (var a = 1; a <= quranAyahCounts[s]; a++) {
          _add('القرآن الكريم', 'سورة ${quranSurahNames[s]} - الآية $a',
            ayahs[position++], surah: s + 1);
        }
      }

      for (final d in morning) { _add('أذكار الصباح', d.t, d.t, section: 1); }
      for (final d in evening) { _add('أذكار المساء', d.t, d.t, section: 1); }
      for (final d in after) { _add('أذكار بعد الصلاة', d.t, d.t, section: 2); }
      for (final e in duas) { _add('الأدعية', e.title, e.body, section: 3); }
      for (final e in stories) { _add('قصص الأنبياء', e.title, e.body, section: 5); }
      for (var i = 0; i < NamesPage.names.length; i++) {
        _add('أسماء الله الحسنى', '${i + 1}. ${NamesPage.names[i]}', NamesPage.names[i], section: 6);
      }
      for (final item in DreamsPage.searchItems) {
        _add('تفسير الأحلام', item.key, item.value, section: 11);
      }

      final hadithText = await rootBundle.loadString('assets/hadiths-1000.json');
      final hadithRows = jsonDecode(hadithText);
      if (hadithRows is! List || hadithRows.length != 1000) {
        throw Exception('قاعدة الأحاديث غير مكتملة.');
      }
      for (final row in hadithRows) {
        final h = Map<String, dynamic>.from(row as Map);
        _add('الأحاديث النبوية', (h['reference'] ?? 'حديث').toString(),
          '${h['text_ar'] ?? ''} ${h['source'] ?? ''}', section: 4);
      }
      if (mounted) {
        setState(() { _loading = false; });
        if (_controller.text.trim().isNotEmpty) _search(_controller.text);
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  void _search(String value) {
    final query = _foldArabic(value.trim());
    setState(() {
      if (query.isEmpty) { _results = []; return; }
      final matches = _index.where((hit) =>
        _foldArabic('${hit.title} ${hit.body} ${hit.category}').contains(query)
      );
      final perCategory = <String, int>{};
      _results = matches.where((hit) {
        final count = perCategory[hit.category] ?? 0;
        if (count >= 25) return false;
        perCategory[hit.category] = count + 1;
        return true;
      }).take(150).toList();
    });
  }

  void _openHit(_SearchHit hit) {
    Widget page;
    String title = hit.category;
    if (hit.surah != null) {
      final n = hit.surah!;
      page = SurahReader(number: n, name: quranSurahNames[n - 1]);
      title = 'سورة ${quranSurahNames[n - 1]}';
    } else if (hit.section == 4) {
      page = const HadithLibraryPage();
    } else {
      page = SectionPage(index: hit.section ?? 0);
    }
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => Directionality(textDirection: TextDirection.rtl,
        child: Scaffold(appBar: AppBar(title: Text(title), backgroundColor: green, foregroundColor: Colors.white), body: page)),
    ));
  }

  @override Widget build(BuildContext context) => Column(children: [
    Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.search,
        onChanged: _search,
        decoration: InputDecoration(
          hintText: 'ابحث عن آية أو حديث أو ذكر أو دعاء أو موضوع...',
          prefixIcon: const Icon(Icons.search, color: green),
          suffixIcon: IconButton(icon: const Icon(Icons.close), onPressed: () { _controller.clear(); _search(''); }),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    ),
    Expanded(child: _loading
      ? const Center(child: CircularProgressIndicator())
      : _error.isNotEmpty
        ? Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(_error, textAlign: TextAlign.center)))
        : _controller.text.trim().isEmpty
          ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('اكتب كلمة للبحث في القرآن والأذكار والأدعية والأحاديث والقصص والأسماء وتفسير الأحلام.', textAlign: TextAlign.center, style: TextStyle(height: 1.8))))
          : _results.isEmpty
            ? const Center(child: Text('لا توجد نتائج مطابقة.'))
            : ListView.separated(
                itemCount: _results.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final hit = _results[i];
                  return ListTile(
                    title: Text(hit.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${hit.category} • ${hit.body}', maxLines: 3, overflow: TextOverflow.ellipsis),
                    onTap: () => _openHit(hit),
                  );
                },
              )),
  ]);
}


class StoriesPage extends StatelessWidget {
  const StoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: stories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final story = stories[index];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => StoryDetailPage(story: story),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              child: Row(
                children: [
                  CircleAvatar(child: Text('${index + 1}')),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(story.title, style: const TextStyle(fontWeight: FontWeight.bold, color: green, fontSize: 17)),
                        const SizedBox(height: 5),
                        const Text('اضغط لقراءة القصة كاملة'),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_left, color: green),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class StoryDetailPage extends StatelessWidget {
  final Entry story;
  const StoryDetailPage({super.key, required this.story});

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(
        title: Text(story.title),
        backgroundColor: green,
        foregroundColor: Colors.white,
      ),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(story.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: green)),
            const Divider(height: 24),
            Text(story.body, style: const TextStyle(fontSize: 19, height: 2)),
            const SizedBox(height: 18),
            const Text('المعلومات المعروضة مبنية على ما ورد في القرآن الكريم، ولا تُضاف تفاصيل غير ثابتة.', style: TextStyle(color: Colors.black54, height: 1.7)),
          ],
        ),
      ),
    ),
  );
}

class EntriesPage extends StatelessWidget{final List<Entry> items;const EntriesPage({super.key,required this.items});@override Widget build(BuildContext c)=>ListView.builder(padding:const EdgeInsets.all(12),itemCount:items.length,itemBuilder:(c,i)=>Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Text(items[i].title,style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold,color:green)),const SizedBox(height:8),Text(items[i].body,style:const TextStyle(fontSize:18,height:1.8))]))));}
class NamesPage extends StatelessWidget{const NamesPage({super.key});static const names=['الرَّحْمَن','الرَّحِيم','الْمَلِك','الْقُدُّوس','السَّلَام','الْمُؤْمِن','الْمُهَيْمِن','الْعَزِيز','الْجَبَّار','الْمُتَكَبِّر','الْخَالِق','الْبَارِئ','الْمُصَوِّر','الْغَفَّار','الْقَهَّار','الْوَهَّاب','الرَّزَّاق','الْفَتَّاح','الْعَلِيم','الْقَابِض','الْبَاسِط','الْخَافِض','الرَّافِع','الْمُعِزّ','الْمُذِلّ','السَّمِيع','الْبَصِير','الْحَكَم','الْعَدْل','اللَّطِيف','الْخَبِير','الْحَلِيم','الْعَظِيم','الْغَفُور','الشَّكُور','الْعَلِيّ','الْكَبِير','الْحَفِيظ','الْمُقِيت','الْحَسِيب','الْجَلِيل','الْكَرِيم','الرَّقِيب','الْمُجِيب','الْوَاسِع','الْحَكِيم','الْوَدُود','الْمَجِيد','الْبَاعِث','الشَّهِيد','الْحَقّ','الْوَكِيل','الْقَوِيّ','الْمَتِين','الْوَلِيّ','الْحَمِيد','الْمُحْصِي','الْمُبْدِئ','الْمُعِيد','الْمُحْيِي','الْمُمِيت','الْحَيّ','الْقَيُّوم','الْوَاجِد','الْمَاجِد','الْوَاحِد','الصَّمَد','الْقَادِر','الْمُقْتَدِر','الْمُقَدِّم','الْمُؤَخِّر','الْأَوَّل','الْآخِر','الظَّاهِر','الْبَاطِن','الْوَالِي','الْمُتَعَالِي','الْبَرّ','التَّوَّاب','الْمُنْتَقِم','الْعَفُوّ','الرَّؤُوف','مَالِكُ الْمُلْك','ذُو الْجَلَالِ وَالْإِكْرَام','الْمُقْسِط','الْجَامِع','الْغَنِيّ','الْمُغْنِي','الْمَانِع','الضَّارّ','النَّافِع','النُّور','الْهَادِي','الْبَدِيع','الْبَاقِي','الْوَارِث','الرَّشِيد','الصَّبُور'];@override Widget build(BuildContext c)=>GridView.builder(padding:const EdgeInsets.all(12),itemCount:names.length,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,crossAxisSpacing:8,mainAxisSpacing:8,childAspectRatio:2.5),itemBuilder:(c,i)=>Card(child:Center(child:Text('${i+1}. ${names[i]}',style:const TextStyle(color:green,fontWeight:FontWeight.bold)))));}
class InfoPage extends StatelessWidget{final IconData icon;final String title,message;const InfoPage({super.key,required this.icon,required this.title,required this.message});@override Widget build(BuildContext c)=>Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(icon,size:64,color:green),const SizedBox(height:16),Text(title,style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),const SizedBox(height:12),Text(message,textAlign:TextAlign.center,style:const TextStyle(fontSize:17,height:1.7))])));}