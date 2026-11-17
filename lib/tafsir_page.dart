import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'quran_data.dart';

const _tafsirGreen = Color(0xFF493326);

class TafsirPage extends StatefulWidget {
  final String initialSource;
  const TafsirPage({super.key, this.initialSource = 'muyassar'});
  @override
  State<TafsirPage> createState() => _TafsirPageState();
}

class _TafsirPageState extends State<TafsirPage> {
  int surah = 1;
  late String source;
  late Future<Map<int, String>> data;
  late Future<List<String>> quranText;

  @override
  void initState() {
    super.initState();
    source = widget.initialSource;
    data = _fetch(surah, source);
    quranText = rootBundle.loadString('assets/quran-uthmani.txt').then(
      (value) => value.split('\\n').where((line) => line.trim().isNotEmpty).toList(),
    );
  }

  void _reload() {
    setState(() {
      data = _fetch(surah, source);
    });
  }

  Future<Map<int, String>> _fetch(int surahNumber, String tafsirSource) async {
    final count = quranAyahCounts[surahNumber - 1];
    final key = tafsirSource == 'muyassar' ? 'arabic_moyassar' : 'arabic_saadi';
    final uri = Uri.https(
      'quranenc.com',
      '/api/v1/tafsir/sura/$key/$surahNumber',
    );
    final response = await http.get(uri, headers: const {
      'Accept': 'application/json',
    }).timeout(const Duration(seconds: 40));

    if (response.statusCode != 200) {
      throw Exception('تعذر تحميل التفسير من المصدر (HTTP ${response.statusCode}). تأكد من الإنترنت ثم أعد المحاولة.');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    final rows = decoded is Map ? decoded['result'] : decoded;
    if (rows is! List || rows.isEmpty) {
      throw Exception('المصدر لم يُرجع تفسيرًا لهذه السورة.');
    }

    final byAyah = <int, List<String>>{};
    for (final row in rows) {
      if (row is! Map) continue;
      final text = (row['text'] ?? '').toString().trim();
      final from = int.tryParse((row['from_aya'] ?? '').toString());
      final to = int.tryParse((row['to_aya'] ?? row['from_aya'] ?? '').toString());
      if (text.isEmpty || from == null || to == null) continue;
      if (from < 1 || to < from || from > count) continue;
      final last = to > count ? count : to;
      for (var aya = from; aya <= last; aya++) {
        final blocks = byAyah.putIfAbsent(aya, () => <String>[]);
        if (!blocks.contains(text)) blocks.add(text);
      }
    }

    final missing = <int>[];
    for (var aya = 1; aya <= count; aya++) {
      if (byAyah[aya] == null || byAyah[aya]!.isEmpty) {
        missing.add(aya);
      }
    }
    if (missing.isNotEmpty) {
      throw Exception('التفسير الذي وصل من المصدر ناقص في هذه السورة. الآيات التي لم يصل تفسيرها: ${missing.take(20).join('، ')}${missing.length > 20 ? ' وغيرها' : ''}. لم نضع نصًا بديلًا من عندنا.');
    }

    return {
      for (final entry in byAyah.entries)
        entry.key: entry.value.join('\n\n'),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  source == 'muyassar' ? 'التفسير الميسّر' : 'تفسير السعدي',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _tafsirGreen),
                ),
                const SizedBox(height: 5),
                const Text('التفسير كاملًا للسورة المختارة، آيةً آيةً، من مصدره. يلزم اتصال بالإنترنت لتحميل النص.'),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  value: surah,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'اختر السورة'),
                  items: List.generate(
                    114,
                    (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text('${i + 1} - ${quranSurahNames[i]}'),
                    ),
                  ),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      surah = value;
                      data = _fetch(surah, source);
                    });
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: source,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'اختر التفسير'),
                  items: const [
                    DropdownMenuItem(value: 'muyassar', child: Text('التفسير الميسّر - مجمع الملك فهد')),
                    DropdownMenuItem(value: 'saadi', child: Text('تفسير السعدي')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      source = value;
                      data = _fetch(surah, source);
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<int, String>>(
              future: data,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.menu_book, color: _tafsirGreen, size: 42),
                          const SizedBox(height: 10),
                          Text(snapshot.error.toString(), textAlign: TextAlign.center),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: _reload,
                            icon: const Icon(Icons.refresh),
                            label: const Text('إعادة تحميل التفسير'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final verses = snapshot.data!;
                return FutureBuilder<List<String>>(
                  future: quranText,
                  builder: (context, textSnapshot) {
                    if (textSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (textSnapshot.hasError || textSnapshot.data == null) {
                      return const Center(child: Text('تعذر تحميل نص القرآن لعرض الآية مع تفسيرها.'));
                    }
                    final allAyahs = textSnapshot.data!;
                    var firstAyahIndex = 0;
                    for (var i = 0; i < surah - 1; i++) {
                      firstAyahIndex += quranAyahCounts[i];
                    }
                    if (allAyahs.length < firstAyahIndex + quranAyahCounts[surah - 1]) {
                      return const Center(child: Text('ملف نص القرآن غير مكتمل؛ لم نعرض تفسيرًا دون الآية المقابلة له.'));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                      itemCount: quranAyahCounts[surah - 1] + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              'سورة ${quranSurahNames[surah - 1]} • ${verses.length} موضع تفسير',
                              style: const TextStyle(color: _tafsirGreen, fontWeight: FontWeight.bold),
                            ),
                          );
                        }
                        final ayahText = allAyahs[firstAyahIndex + index - 1];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 9),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'الآية $index',
                                  style: const TextStyle(color: _tafsirGreen, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                SelectableText(
                                  ayahText,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 22, height: 2, fontWeight: FontWeight.w600),
                                ),
                                const Divider(height: 22),
                                const Text('التفسير', style: TextStyle(color: _tafsirGreen, fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 6),
                                SelectableText(
                                  verses[index]!,
                                  style: const TextStyle(fontSize: 17, height: 1.9),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Text(
              'المصدر: موسوعة القرآن الكريم QuranEnc. يُعرض النص كما يرد من المصدر دون إعادة صياغة.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
