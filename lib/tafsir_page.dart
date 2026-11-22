import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'quran_data.dart';
import 'quran_navigation.dart';
import 'reading_marks.dart';

const _tafsirGreen = Color(0xFF493326);

class TafsirPage extends StatefulWidget {
  final String initialSource;
  const TafsirPage({super.key, this.initialSource = 'muyassar'});
  @override
  State<TafsirPage> createState() => _TafsirPageState();
}

class _TafsirPageState extends State<TafsirPage> {
  int surah = 1;
  int firstDisplayedAyah = 1;
  late String source;
  late Future<Map<int, String>> data;
  late Future<List<String>> quranText;
  final ScrollController _readingController = ScrollController();
  Timer? _saveTimer;
  String? _restoredKey;

  @override
  void initState() {
    super.initState();
    _readingController.addListener(_scheduleSavePosition);
    source = widget.initialSource;
    data = _fetch(surah, source);
    quranText = rootBundle.loadString('assets/quran-uthmani.txt').then(
      (value) => LineSplitter.split(value).where((line) => line.trim().isNotEmpty).toList(),
    );
  }

  String get _positionKey => 'tafsir_${source}_${surah}';

  void _scheduleSavePosition() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () {
      if (_readingController.hasClients) ReadingMarks.saveLast(_positionKey, _readingController.offset);
    });
  }

  Future<void> _restorePosition() async {
    final key = _positionKey;
    if (_restoredKey == key) return;
    _restoredKey = key;
    final saved = await ReadingMarks.loadLast(key);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _readingController.hasClients && _positionKey == key && saved > 0) {
        _readingController.jumpTo(saved.clamp(0.0, _readingController.position.maxScrollExtent).toDouble());
      }
    });
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _readingController.removeListener(_scheduleSavePosition);
    _readingController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      data = _fetch(surah, source);
    });
  }

  String _cacheKey(int surahNumber, String tafsirSource) =>
      'noor_tafsir_${tafsirSource}_${surahNumber}_v1';

  Future<Map<int, String>> _fetch(int surahNumber, String tafsirSource) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _cacheKey(surahNumber, tafsirSource);
    Map<int, String>? cached;
    final saved = prefs.getString(key);
    if (saved != null && saved.isNotEmpty) {
      try {
        final decoded = jsonDecode(saved) as Map<String, dynamic>;
        cached = decoded.map((k, v) => MapEntry(int.parse(k), v.toString()));
      } catch (_) {
        await prefs.remove(key);
      }
    }

    try {
      final count = quranAyahCounts[surahNumber - 1];
      final tafsirKey = tafsirSource == 'muyassar' ? 'arabic_moyassar' : 'arabic_saadi';
      final uri = Uri.https(
        'quranenc.com',
        '/api/v1/tafsir/sura/$tafsirKey/$surahNumber',
      );
      final response = await http.get(uri, headers: const {
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 40));

      if (response.statusCode != 200) {
        throw Exception('تعذر تحميل التفسير من المصدر (HTTP ${response.statusCode}).');
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
        throw Exception('التفسير الذي وصل من المصدر ناقص في هذه السورة؛ لم نعرض نصًا غير موثّق.');
      }

      final result = <int, String>{
        for (final entry in byAyah.entries)
          entry.key: entry.value.join('\n\n'),
      };
      await prefs.setString(key, jsonEncode({
        for (final entry in result.entries) entry.key.toString(): entry.value,
      }));
      return result;
    } catch (error) {
      if (cached != null && cached.isNotEmpty) return cached;
      rethrow;
    }
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
                const Text('يُحمّل التفسير أول مرة من مصدره، ثم يُحفظ على الهاتف لقراءته دون إنترنت.'),
                const SizedBox(height: 10),
                QuranLocationPicker(
                  title: 'فهرس التفسير والانتقال',
                  onOpen: (selectedSurah, selectedAyah) {
                    setState(() {
                      surah = selectedSurah;
                      firstDisplayedAyah = selectedAyah;
                      _restoredKey = null;
                      data = _fetch(surah, source);
                    });
                  },
                ),
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
                      firstDisplayedAyah = 1;
                      _restoredKey = null;
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
                      _restoredKey = null;
                      data = _fetch(surah, source);
                    });
                  },
                ),
              ],
            ),
          ),
          ReadingMarksControls(
            section: _positionKey,
            label: '${source == 'muyassar' ? 'التفسير الميسّر' : 'تفسير السعدي'} - سورة ${quranSurahNames[surah - 1]}',
            getPosition: () => _readingController.hasClients ? _readingController.offset : 0,
            onJump: (value) { if (_readingController.hasClients) _readingController.jumpTo(value.clamp(0.0, _readingController.position.maxScrollExtent).toDouble()); },
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
                    _restorePosition();
                    return ListView.builder(
                      controller: _readingController,
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                      itemCount: quranAyahCounts[surah - 1] - firstDisplayedAyah + 2,
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
                        final ayahNumber = firstDisplayedAyah + index - 1;
                        final ayahText = allAyahs[firstAyahIndex + ayahNumber - 1];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 9),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'الآية $ayahNumber',
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
                                  verses[ayahNumber]!,
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
              'المصدر: موسوعة القرآن الكريم QuranEnc. تُحفظ السور التي تم تحميلها على الهاتف للقراءة دون إنترنت.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
