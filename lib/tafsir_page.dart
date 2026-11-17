import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'quran_data.dart';

const _tafsirGreen = Color(0xFF176B45);

class TafsirPage extends StatefulWidget {
  const TafsirPage({super.key});
  @override State<TafsirPage> createState() => _TafsirPageState();
}
class _TafsirPageState extends State<TafsirPage> {
  int surah = 1;
  int ayah = 1;
  String source = 'muyassar';
  Future<Map<int, String>>? data;

  @override void initState() { super.initState(); _load(); }
  void _load() { setState(() { data = _fetch(); }); }

  Future<Map<int, String>> _fetch() async {
    final uri = source == 'muyassar'
      ? Uri.parse('https://quranenc.com/api/v1/translation/sura/arabic_moyassar/' + surah.toString())
      : Uri.parse('https://cdn.jsdelivr.net/gh/spa5k/tafsir_api@v1.2.3/tafsir/ar-tafsir-ibn-kathir/' + surah.toString() + '.json');
    final response = await http.get(uri).timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) throw Exception('المصدر لم يستجب. تأكد من الإنترنت ثم أعد المحاولة.');
    final Map<int, String> result = {};
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (source == 'muyassar') {
      final rows = decoded['result'] as List;
      for (final row in rows) {
        final n = int.tryParse(row['aya'].toString());
        if (n != null) result[n] = row['translation'].toString();
      }
    } else {
      final rows = decoded as List;
      for (final row in rows) {
        final n = int.tryParse(row['ayah'].toString());
        if (n != null) result[n] = row['text'].toString();
      }
    }
    return result;
  }

  @override Widget build(BuildContext context) {
    final count = quranAyahCounts[surah - 1];
    if (ayah > count) ayah = count;
    return Directionality(textDirection: TextDirection.rtl, child: ListView(padding: const EdgeInsets.all(16), children: [
      const Text('تفسير القرآن الكريم', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _tafsirGreen)),
      const SizedBox(height: 6),
      const Text('اختر السورة والآية، ثم بدّل بين التفسيرين. يلزم اتصال بالإنترنت لتحميل النصوص.'),
      const SizedBox(height: 12),
      DropdownButtonFormField<int>(
        value: surah, isExpanded: true, decoration: const InputDecoration(labelText: 'السورة'),
        items: List.generate(114, (i) => DropdownMenuItem(value: i + 1, child: Text((i + 1).toString() + ' - ' + quranSurahNames[i]))),
        onChanged: (v) { if (v == null) return; setState(() { surah = v; ayah = 1; }); _load(); },
      ),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        value: source, isExpanded: true, decoration: const InputDecoration(labelText: 'اختر التفسير'),
        items: const [
          DropdownMenuItem(value: 'muyassar', child: Text('التفسير الميسّر - مجمع الملك فهد')),
          DropdownMenuItem(value: 'ibnkathir', child: Text('تفسير ابن كثير')),
        ],
        onChanged: (v) { if (v == null) return; setState(() { source = v; }); _load(); },
      ),
      const SizedBox(height: 10),
      DropdownButtonFormField<int>(
        value: ayah, isExpanded: true, decoration: const InputDecoration(labelText: 'رقم الآية'),
        items: List.generate(count, (i) => DropdownMenuItem(value: i + 1, child: Text('الآية ' + (i + 1).toString()))),
        onChanged: (v) { if (v != null) setState(() => ayah = v); },
      ),
      const SizedBox(height: 14),
      FutureBuilder<Map<int, String>>(
        future: data,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator()));
          if (snapshot.hasError) return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            const Icon(Icons.wifi_off, color: _tafsirGreen, size: 36),
            const SizedBox(height: 8),
            Text(snapshot.error.toString(), textAlign: TextAlign.center),
            TextButton(onPressed: _load, child: const Text('إعادة المحاولة')),
          ])));
          final text = snapshot.data?[ayah];
          return Card(color: Colors.white, child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('سورة ' + quranSurahNames[surah - 1] + ' - الآية ' + ayah.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: _tafsirGreen)),
            const Divider(),
            SelectableText(text ?? 'لا يتوفر نص لهذه الآية في النسخة الرقمية الحالية.', style: const TextStyle(fontSize: 18, height: 2)),
          ])));
        },
      ),
      const SizedBox(height: 10),
      const Text('المصادر: التفسير الميسّر عبر QuranEnc / مجمع الملك فهد لطباعة المصحف الشريف؛ تفسير ابن كثير عبر نسخة Tafsir API الرقمية. قد تختلف صياغة الطبعات، والنصوص المعروضة من المصادر كما وردت.', style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.6)),
    ]));
  }
}
