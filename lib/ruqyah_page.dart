import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'quran_data.dart';

const _ruqyahGreen = Color(0xFF493326);

class _RuqyahPassage {
  final String title;
  final int surah;
  final int from;
  final int to;
  const _RuqyahPassage(this.title, this.surah, this.from, this.to);
}

class _RuqyahLoadedPassage {
  final _RuqyahPassage passage;
  final List<String> verses;
  const _RuqyahLoadedPassage(this.passage, this.verses);
}

const _ruqyahPassages = <_RuqyahPassage>[
  _RuqyahPassage('سورة الفاتحة', 1, 1, 7),
  _RuqyahPassage('أوائل سورة البقرة', 2, 1, 5),
  _RuqyahPassage('آية السحر', 2, 102, 102),
  _RuqyahPassage('آيات التوحيد', 2, 163, 164),
  _RuqyahPassage('آية الكرسي', 2, 255, 255),
  _RuqyahPassage('خواتيم سورة البقرة', 2, 285, 286),
  _RuqyahPassage('آيات إبطال السحر من سورة الأعراف', 7, 117, 122),
  _RuqyahPassage('آيات إبطال السحر من سورة يونس', 10, 81, 82),
  _RuqyahPassage('آية من سورة طه', 20, 69, 69),
  _RuqyahPassage('دعاء المؤمنين من سورة المؤمنون', 23, 115, 118),
  _RuqyahPassage('أوائل سورة الصافات', 37, 1, 10),
  _RuqyahPassage('آيات من سورة الحشر', 59, 21, 24),
  _RuqyahPassage('سورة الإخلاص', 112, 1, 4),
  _RuqyahPassage('سورة الفلق', 113, 1, 5),
  _RuqyahPassage('سورة الناس', 114, 1, 6),
];

class RuqyahPage extends StatefulWidget {
  const RuqyahPage({super.key});

  @override
  State<RuqyahPage> createState() => _RuqyahPageState();
}

class _RuqyahPageState extends State<RuqyahPage> {
  late final Future<List<_RuqyahLoadedPassage>> _content = _load();
  final Set<int> _completed = <int>{};

  Future<List<_RuqyahLoadedPassage>> _load() async {
    final lines = (await rootBundle.loadString('assets/quran-uthmani.txt')).split('\n');
    if (lines.length != 6236) throw Exception('ملف القرآن غير مكتمل');
    return _ruqyahPassages.map((passage) {
      final start = quranAyahCounts.take(passage.surah - 1)
          .fold<int>(0, (sum, count) => sum + count);
      return _RuqyahLoadedPassage(
        passage,
        lines.skip(start + passage.from - 1).take(passage.to - passage.from + 1).toList(),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: FutureBuilder<List<_RuqyahLoadedPassage>>(
      future: _content,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('تعذر تحميل آيات الرقية: ${snapshot.error}'));
        }
        final sections = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Card(
              color: const Color(0xFFFFF8E8),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'الرقية الشرعية بالقرآن الكريم والأدعية الثابتة. اقرأ الآيات كاملة، ويمكنك تحديد كل مقطع بعد قراءته. الرقية لا تغني عن مراجعة الطبيب عند الحاجة.',
                  style: TextStyle(height: 1.8, color: _ruqyahGreen),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(8, 12, 8, 6),
              child: Text('آيات القرآن الكريم', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: _ruqyahGreen)),
            ),
            for (var i = 0; i < sections.length; i++)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ExpansionTile(
                  leading: Checkbox(
                    value: _completed.contains(i),
                    onChanged: (value) => setState(() {
                      if (value == true) _completed.add(i); else _completed.remove(i);
                    }),
                  ),
                  title: Text(sections[i].passage.title, style: const TextStyle(fontWeight: FontWeight.bold, color: _ruqyahGreen)),
                  subtitle: Text('سورة ${quranSurahNames[sections[i].passage.surah - 1]} • الآيات ${sections[i].passage.from}-${sections[i].passage.to}'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                      child: SelectableText(
                        [
                          for (var j = 0; j < sections[i].verses.length; j++)
                            '${sections[i].verses[j]} ﴿${sections[i].passage.from + j}﴾'
                        ].join(' '),
                        textAlign: TextAlign.justify,
                        style: const TextStyle(fontSize: 22, height: 2.1, color: Colors.black87, fontFamily: 'Amiri'),
                      ),
                    ),
                  ],
                ),
              ),
            const Padding(
              padding: EdgeInsets.fromLTRB(8, 12, 8, 6),
              child: Text('أدعية الرقية من السنة', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: _ruqyahGreen)),
            ),
            const _RuqyahDua(
              title: 'دعاء الشفاء',
              text: 'اللَّهُمَّ رَبَّ النَّاسِ، أَذْهِبِ الْبَأْسَ، اشْفِ أَنْتَ الشَّافِي، لَا شِفَاءَ إِلَّا شِفَاؤُكَ، شِفَاءً لَا يُغَادِرُ سَقَمًا.',
              source: 'صحيح البخاري وصحيح مسلم',
            ),
            const _RuqyahDua(
              title: 'رقية جبريل عليه السلام',
              text: 'بِسْمِ اللَّهِ أَرْقِيكَ، مِنْ كُلِّ شَيْءٍ يُؤْذِيكَ، مِنْ شَرِّ كُلِّ نَفْسٍ أَوْ عَيْنِ حَاسِدٍ، اللَّهُ يَشْفِيكَ، بِسْمِ اللَّهِ أَرْقِيكَ.',
              source: 'صحيح مسلم',
            ),
            const _RuqyahDua(
              title: 'التعوذ من الشيطان والعين',
              text: 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّةِ مِنْ كُلِّ شَيْطَانٍ وَهَامَّةٍ، وَمِنْ كُلِّ عَيْنٍ لَامَّةٍ.',
              source: 'صحيح البخاري',
            ),
            const _RuqyahDua(
              title: 'التعوذ من شر المخلوقات',
              text: 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ.',
              source: 'صحيح مسلم',
            ),
            const _RuqyahDua(
              title: 'الرقية عند الشعور بالألم',
              text: 'بِسْمِ اللَّهِ. (ثَلَاثًا) أَعُوذُ بِاللَّهِ وَقُدْرَتِهِ مِنْ شَرِّ مَا أَجِدُ وَأُحَاذِرُ. (سَبْعَ مَرَّاتٍ)',
              source: 'صحيح مسلم',
            ),
            const _RuqyahDua(
              title: 'الدعاء للمريض',
              text: 'أَسْأَلُ اللَّهَ الْعَظِيمَ، رَبَّ الْعَرْشِ الْعَظِيمِ، أَنْ يَشْفِيَكَ.',
              source: 'سنن أبي داود والترمذي؛ يقال سبع مرات',
            ),
            const SizedBox(height: 18),
            Text('المقاطع القرآنية من نص المصحف العثماني المضمّن بالتطبيق، والأدعية مذكور مصدرها بجوار كل دعاء.',
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.6)),
          ],
        );
      },
    ),
  );
}

class _RuqyahDua extends StatelessWidget {
  final String title, text, source;
  const _RuqyahDua({required this.title, required this.text, required this.source});

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _ruqyahGreen)),
          const SizedBox(height: 10),
          SelectableText(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, height: 2, color: Colors.black87)),
          const SizedBox(height: 8),
          Text(source, textAlign: TextAlign.start, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    ),
  );
}
