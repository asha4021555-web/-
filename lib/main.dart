import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
void main()=>runApp(const NoorApp());
const green=Color(0xFF176B45);
const titles=['القرآن الكريم','أذكار الصباح والمساء','أذكار بعد الصلاة','الأدعية','الأحاديث النبوية','قصص الأنبياء','أسماء الله الحسنى','السبحة الإلكترونية','مواقيت الصلاة','اتجاه القبلة'];
const icons=[Icons.menu_book,Icons.wb_twilight,Icons.mosque,Icons.volunteer_activism,Icons.auto_stories,Icons.history_edu,Icons.star,Icons.radio_button_checked,Icons.access_time,Icons.explore];
class NoorApp extends StatelessWidget{const NoorApp({super.key});@override Widget build(BuildContext c)=>MaterialApp(debugShowCheckedModeBanner:false,title:'نور الإسلام',theme:ThemeData(useMaterial3:true,colorScheme:ColorScheme.fromSeed(seedColor:green),scaffoldBackgroundColor:const Color(0xFFF7F8F3)),home:const HomePage());}
class HomePage extends StatelessWidget{const HomePage({super.key});@override Widget build(BuildContext c)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:const Text('نور الإسلام'),backgroundColor:green,foregroundColor:Colors.white,centerTitle:true),body:ListView(padding:const EdgeInsets.all(16),children:[Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(gradient:const LinearGradient(colors:[green,Color(0xFF0D4930)]),borderRadius:BorderRadius.circular(22)),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('أهلاً بك في نور الإسلام',style:TextStyle(color:Colors.white,fontSize:23,fontWeight:FontWeight.bold)),SizedBox(height:8),Text('رفيقك للقرآن والذكر والعبادة',style:TextStyle(color:Colors.white70))])),const SizedBox(height:18),GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:titles.length,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,crossAxisSpacing:12,mainAxisSpacing:12,childAspectRatio:1.12),itemBuilder:(c,i)=>Card(color:Colors.white,child:InkWell(onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>SectionPage(index:i))),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(icons[i],size:34,color:green),const SizedBox(height:10),Text(titles[i],textAlign:TextAlign.center,style:const TextStyle(fontWeight:FontWeight.bold))]))))])));}
class SectionPage extends StatelessWidget{final int index;const SectionPage({super.key,required this.index});@override Widget build(BuildContext c)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:Text(titles[index]),backgroundColor:green,foregroundColor:Colors.white,centerTitle:true),body:switch(index){0=>const QuranPage(),1=>const DhikrPage(after:false),2=>const DhikrPage(after:true),3=>const EntriesPage(items:duas),4=>const EntriesPage(items:hadiths),5=>const EntriesPage(items:stories),6=>const NamesPage(),7=>const TasbeehPage(),8=>const InfoPage(icon:Icons.access_time,title:'مواقيت الصلاة',message:'حساب المواقيت والتنبيهات لم يُفعّل بعد. يلزم تحديد الموقع واختيار طريقة الحساب وضبط أذونات الإشعارات قبل عرض أوقات دقيقة.'),_=>const InfoPage(icon:Icons.explore,title:'اتجاه القبلة',message:'تحديد اتجاه القبلة يحتاج إلى صلاحية الموقع ومستشعر اتجاه الهاتف. لم نعرض اتجاهًا تقديريًا حتى لا نعطيك اتجاهًا غير صحيح.')}));}
class QuranPage extends StatelessWidget{const QuranPage({super.key});static const surahs=['الفاتحة','البقرة','آل عمران','النساء','المائدة','الأنعام','الأعراف','الأنفال','التوبة','يونس','هود','يوسف','الرعد','إبراهيم','الحجر','النحل','الإسراء','الكهف','مريم','طه','الأنبياء','الحج','المؤمنون','النور','الفرقان','الشعراء','النمل','القصص','العنكبوت','الروم','لقمان','السجدة','الأحزاب','سبأ','فاطر','يس','الصافات','ص','الزمر','غافر','فصلت','الشورى','الزخرف','الدخان','الجاثية','الأحقاف','محمد','الفتح','الحجرات','ق','الذاريات','الطور','النجم','القمر','الرحمن','الواقعة','الحديد','المجادلة','الحشر','الممتحنة','الصف','الجمعة','المنافقون','التغابن','الطلاق','التحريم','الملك','القلم','الحاقة','المعارج','نوح','الجن','المزمل','المدثر','القيامة','الإنسان','المرسلات','النبأ','النازعات','عبس','التكوير','الانفطار','المطففين','الانشقاق','البروج','الطارق','الأعلى','الغاشية','الفجر','البلد','الشمس','الليل','الضحى','الشرح','التين','العلق','القدر','البينة','الزلزلة','العاديات','القارعة','التكاثر','العصر','الهمزة','الفيل','قريش','الماعون','الكوثر','الكافرون','النصر','المسد','الإخلاص','الفلق','الناس'];@override Widget build(BuildContext c)=>ListView.separated(padding:const EdgeInsets.all(12),itemCount:surahs.length,separatorBuilder:(_,__)=>const Divider(height:1),itemBuilder:(c,i)=>ListTile(leading:CircleAvatar(child:Text('${i+1}')),title:Text('سورة ${surahs[i]}'),trailing:const Icon(Icons.chevron_left),onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>SurahReader(number:i+1,name:surahs[i])))));}

class SurahReader extends StatefulWidget {
  final int number;
  final String name;
  const SurahReader({super.key, required this.number, required this.name});

  @override
  State<SurahReader> createState() => _SurahReaderState();
}

class _SurahReaderState extends State<SurahReader> {
  late Future<List<dynamic>> verses;

  @override
  void initState() {
    super.initState();
    verses = loadVerses();
  }

  Future<List<dynamic>> loadVerses() async {
    final response = await http
        .get(Uri.parse(
            'https://api.alquran.cloud/v1/surah/${widget.number}/quran-uthmani'))
        .timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) {
      throw Exception('تعذر تحميل السورة برمز: ${response.statusCode}');
    }
    final body =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (body['code'] != 200) {
      throw Exception('مصدر القرآن لم يُرجع البيانات المطلوبة');
    }
    return body['data']['ayahs'] as List<dynamic>;
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
                    Text('جارٍ تحميل آيات السورة...'),
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
                        'لم نتمكن من تحميل السورة. تأكد من اتصال الإنترنت ثم حاول مرة أخرى.',
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
                          style: const TextStyle(fontSize: 25, height: 2.0),
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

class Dh{final String t;final int n;const Dh(this.t,this.n);}
const ayatKursi='اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ';
const ikhlas='قُلْ هُوَ اللَّهُ أَحَدٌ ۝ اللَّهُ الصَّمَدُ ۝ لَمْ يَلِدْ وَلَمْ يُولَدْ ۝ وَلَمْ يَكُنْ لَهُ كُفُوًا أَحَدٌ';
const falaq='قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ۝ مِنْ شَرِّ مَا خَلَقَ ۝ وَمِنْ شَرِّ غَاسِقٍ إِذَا وَقَبَ ۝ وَمِنْ شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ ۝ وَمِنْ شَرِّ حَاسِدٍ إِذَا حَسَدَ';
const nas='قُلْ أَعُوذُ بِرَبِّ النَّاسِ ۝ مَلِكِ النَّاسِ ۝ إِلَٰهِ النَّاسِ ۝ مِنْ شَرِّ الْوَسْوَاسِ الْخَنَّاسِ ۝ الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ ۝ مِنَ الْجِنَّةِ وَالنَّاسِ';
const sayyid='اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَٰهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي، فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ.';
const commonMorningEvening=[
 Dh(ayatKursi,1),
 Dh('سورة الإخلاص: '+ikhlas,3),
 Dh('سورة الفلق: '+falaq,3),
 Dh('سورة الناس: '+nas,3),
 Dh(sayyid,1),
 Dh('بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ.',3),
 Dh('رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ ﷺ نَبِيًّا.',3),
 Dh('سُبْحَانَ اللَّهِ وَبِحَمْدِهِ.',100),
];
const morning=[
 ...commonMorningEvening,
 Dh('أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذَا الْيَوْمِ وَخَيْرَ مَا بَعْدَهُ، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذَا الْيَوْمِ وَشَرِّ مَا بَعْدَهُ، رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ.',1),
 Dh('اللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ النُّشُورُ.',1),
 Dh('اللَّهُمَّ إِنِّي أَصْبَحْتُ أُشْهِدُكَ، وَأُشْهِدُ حَمَلَةَ عَرْشِكَ، وَمَلَائِكَتَكَ، وَجَمِيعَ خَلْقِكَ، أَنَّكَ أَنْتَ اللَّهُ لَا إِلَٰهَ إِلَّا أَنْتَ وَحْدَكَ لَا شَرِيكَ لَكَ، وَأَنَّ مُحَمَّدًا عَبْدُكَ وَرَسُولُكَ.',4),
];
const evening=[
 ...commonMorningEvening,
 Dh('أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذِهِ اللَّيْلَةِ وَخَيْرَ مَا بَعْدَهَا، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذِهِ اللَّيْلَةِ وَشَرِّ مَا بَعْدَهَا، رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ.',1),
 Dh('اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ الْمَصِيرُ.',1),
 Dh('أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ.',3),
];
const after=[Dh('أَسْتَغْفِرُ اللَّهَ.',3),Dh('اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ.',1),Dh('سُبْحَانَ اللَّهِ.',33),Dh('الْحَمْدُ لِلَّهِ.',33),Dh('اللَّهُ أَكْبَرُ.',33)];
class DhikrPage extends StatefulWidget{final bool after;const DhikrPage({super.key,required this.after});@override State<DhikrPage> createState()=>_DhikrState();}
class _DhikrState extends State<DhikrPage>{
 bool isEvening=false;
 List<int> counts=[];
 List<Dh> get data=>widget.after?after:(isEvening?evening:morning);
 @override void initState(){super.initState();counts=List<int>.filled(data.length,0);}
 void changePeriod(bool value){setState((){isEvening=value;counts=List<int>.filled(data.length,0);});}
 @override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(12),children:[
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
class _TasbeehState extends State<TasbeehPage>{int count=0,target=33;String phrase='سبحان الله';@override Widget build(BuildContext c)=>Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[DropdownButton<String>(value:phrase,isExpanded:true,items:const [DropdownMenuItem(value:'سبحان الله',child:Text('سبحان الله')),DropdownMenuItem(value:'الحمد لله',child:Text('الحمد لله')),DropdownMenuItem(value:'الله أكبر',child:Text('الله أكبر')),DropdownMenuItem(value:'أستغفر الله',child:Text('أستغفر الله')),DropdownMenuItem(value:'لا إله إلا الله',child:Text('لا إله إلا الله'))],onChanged:(v){setState((){phrase=v!;count=0;});}),Text(phrase,style:const TextStyle(fontSize:23,color:green)),Text('${count}',style:const TextStyle(fontSize:64,color:green,fontWeight:FontWeight.bold)),Text('الهدف: ${target==0?'مفتوح':target}'),Wrap(spacing:8,children:[ChoiceChip(label:const Text('33'),selected:target==33,onSelected:(_)=>setState(()=>target=33)),ChoiceChip(label:const Text('100'),selected:target==100,onSelected:(_)=>setState(()=>target=100)),ChoiceChip(label:const Text('مفتوح'),selected:target==0,onSelected:(_)=>setState(()=>target=0))]),const SizedBox(height:16),SizedBox(width:180,height:180,child:FilledButton(style:FilledButton.styleFrom(shape:const CircleBorder(),backgroundColor:green),onPressed:()=>setState(()=>count++),child:const Text('تسبيح',style:TextStyle(fontSize:28)))),TextButton(onPressed:()=>setState(()=>count=0),child:const Text('تصفير العداد')),if(target>0&&count>=target)const Text('أحسنت، وصلت للهدف!',style:TextStyle(color:green))])));}
class Entry{final String title,body;const Entry(this.title,this.body);}
const duas=[Entry('دعاء جامع','رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ.'),Entry('دعاء المغفرة','رَبَّنَا ظَلَمْنَا أَنْفُسَنَا وَإِنْ لَمْ تَغْفِرْ لَنَا وَتَرْحَمْنَا لَنَكُونَنَّ مِنَ الْخَاسِرِينَ.'),Entry('دعاء العلم','رَبِّ زِدْنِي عِلْمًا.'),Entry('دعاء التيسير','رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي.')];
const hadiths=[Entry('النية','قال رسول الله ﷺ: «إنما الأعمال بالنيات، وإنما لكل امرئ ما نوى». — متفق عليه.'),Entry('الكلمة الطيبة','قال رسول الله ﷺ: «الكلمة الطيبة صدقة». — متفق عليه.'),Entry('محبة الخير','قال رسول الله ﷺ: «لا يؤمن أحدكم حتى يحب لأخيه ما يحب لنفسه». — متفق عليه.'),Entry('الرفق','قال رسول الله ﷺ: «إن الله رفيق يحب الرفق في الأمر كله». — متفق عليه.')];
const stories=[Entry('آدم عليه السلام','خلق الله آدم عليه السلام وعلّمه الأسماء، وأسكنه الجنة، ثم تاب عليه لما تاب وأناب.'),Entry('نوح عليه السلام','دعا نوح عليه السلام قومه إلى عبادة الله زمنًا طويلًا وصبر على أذاهم، فكانت النجاة للمؤمنين في السفينة.'),Entry('إبراهيم عليه السلام','دعا إبراهيم عليه السلام إلى التوحيد، وابتلاه الله فصبر، وجعله إمامًا للناس.'),Entry('يوسف عليه السلام','ابتُلي يوسف عليه السلام بفراق أهله والسجن، ثم أكرمه الله ومكّنه في الأرض.'),Entry('موسى عليه السلام','أرسل الله موسى عليه السلام إلى فرعون، وأيّده بالآيات، ونجّاه وبني إسرائيل.'),Entry('يونس عليه السلام','نادى يونس عليه السلام ربه في الظلمات فاستجاب الله له ونجّاه.')];
class EntriesPage extends StatelessWidget{final List<Entry> items;const EntriesPage({super.key,required this.items});@override Widget build(BuildContext c)=>ListView.builder(padding:const EdgeInsets.all(12),itemCount:items.length,itemBuilder:(c,i)=>Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Text(items[i].title,style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold,color:green)),const SizedBox(height:8),Text(items[i].body,style:const TextStyle(fontSize:18,height:1.8))]))));}
class NamesPage extends StatelessWidget{const NamesPage({super.key});static const names=['الرَّحْمَن','الرَّحِيم','الْمَلِك','الْقُدُّوس','السَّلَام','الْمُؤْمِن','الْمُهَيْمِن','الْعَزِيز','الْجَبَّار','الْمُتَكَبِّر','الْخَالِق','الْبَارِئ','الْمُصَوِّر','الْغَفَّار','الْقَهَّار','الْوَهَّاب','الرَّزَّاق','الْفَتَّاح','الْعَلِيم','الْقَابِض','الْبَاسِط','الْخَافِض','الرَّافِع','الْمُعِزّ','الْمُذِلّ','السَّمِيع','الْبَصِير','الْحَكَم','الْعَدْل','اللَّطِيف','الْخَبِير','الْحَلِيم','الْعَظِيم','الْغَفُور','الشَّكُور','الْعَلِيّ','الْكَبِير','الْحَفِيظ','الْمُقِيت','الْحَسِيب','الْجَلِيل','الْكَرِيم','الرَّقِيب','الْمُجِيب','الْوَاسِع','الْحَكِيم','الْوَدُود','الْمَجِيد','الْبَاعِث','الشَّهِيد','الْحَقّ','الْوَكِيل','الْقَوِيّ','الْمَتِين','الْوَلِيّ','الْحَمِيد','الْمُحْصِي','الْمُبْدِئ','الْمُعِيد','الْمُحْيِي','الْمُمِيت','الْحَيّ','الْقَيُّوم','الْوَاجِد','الْمَاجِد','الْوَاحِد','الصَّمَد','الْقَادِر','الْمُقْتَدِر','الْمُقَدِّم','الْمُؤَخِّر','الْأَوَّل','الْآخِر','الظَّاهِر','الْبَاطِن','الْوَالِي','الْمُتَعَالِي','الْبَرّ','التَّوَّاب','الْمُنْتَقِم','الْعَفُوّ','الرَّؤُوف','مَالِكُ الْمُلْك','ذُو الْجَلَالِ وَالْإِكْرَام','الْمُقْسِط','الْجَامِع','الْغَنِيّ','الْمُغْنِي','الْمَانِع','الضَّارّ','النَّافِع','النُّور','الْهَادِي','الْبَدِيع','الْبَاقِي','الْوَارِث','الرَّشِيد','الصَّبُور'];@override Widget build(BuildContext c)=>GridView.builder(padding:const EdgeInsets.all(12),itemCount:names.length,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,crossAxisSpacing:8,mainAxisSpacing:8,childAspectRatio:2.5),itemBuilder:(c,i)=>Card(child:Center(child:Text('${i+1}. ${names[i]}',style:const TextStyle(color:green,fontWeight:FontWeight.bold)))));}
class InfoPage extends StatelessWidget{final IconData icon;final String title,message;const InfoPage({super.key,required this.icon,required this.title,required this.message});@override Widget build(BuildContext c)=>Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(icon,size:64,color:green),const SizedBox(height:16),Text(title,style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),const SizedBox(height:12),Text(message,textAlign:TextAlign.center,style:const TextStyle(fontSize:17,height:1.7))])));}
