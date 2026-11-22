import 'package:flutter/material.dart';
import 'quran_data.dart';

const List<(int,int)> quranJuzStarts = [
  (1,1),(2,142),(2,253),(3,93),(4,24),(4,148),(5,82),(6,111),(7,88),(8,41),
  (9,93),(11,6),(12,53),(15,1),(17,1),(18,75),(21,1),(23,1),(25,21),(27,56),
  (29,46),(33,31),(36,28),(39,32),(41,47),(46,1),(51,31),(58,1),(67,1),(78,1),
];

(int,int) quranJuzLocation(int juz) => quranJuzStarts[juz - 1];

class QuranLocationPicker extends StatefulWidget {
  final String title;
  final void Function(int surah, int ayah) onOpen;
  const QuranLocationPicker({super.key, this.title = 'الفهرس والانتقال', required this.onOpen});
  @override
  State<QuranLocationPicker> createState() => _QuranLocationPickerState();
}

class _QuranLocationPickerState extends State<QuranLocationPicker> {
  int surah = 1;
  int ayah = 1;
  int juz = 1;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.fromLTRB(10, 4, 10, 4),
    child: ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      title: Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF493326))),
      subtitle: const Text('اضغط لفتح الفهرس واختيار السورة أو الآية أو الجزء', style: TextStyle(fontSize: 11)),
      initiallyExpanded: false,
      children: [
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF493326))),
        const SizedBox(height: 10),
        const Text('الانتقال إلى سورة', style: TextStyle(fontWeight: FontWeight.bold)),
        Row(children: [
          Expanded(child: DropdownButtonFormField<int>(
            value: surah, isExpanded: true,
            decoration: const InputDecoration(labelText: 'السورة'),
            items: List.generate(114, (i) => DropdownMenuItem(value: i + 1, child: Text(quranSurahNames[i]))),
            onChanged: (v) => setState(() { surah = v ?? 1; ayah = 1; }),
          )),
          const SizedBox(width: 8),
          Expanded(child: DropdownButtonFormField<int>(
            value: ayah, isExpanded: true,
            decoration: const InputDecoration(labelText: 'رقم الآية'),
            items: List.generate(quranAyahCounts[surah - 1], (i) => DropdownMenuItem(value: i + 1, child: Text((i + 1).toString()))),
            onChanged: (v) => setState(() => ayah = v ?? 1),
          )),
        ]),
        const SizedBox(height: 6),
        Align(alignment: Alignment.centerLeft, child: FilledButton.icon(
          onPressed: () => widget.onOpen(surah, ayah),
          icon: const Icon(Icons.menu_book), label: const Text('فتح السورة والآية'),
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF493326)),
        )),
        const Divider(height: 24),
        const Text('الانتقال إلى جزء مستقل', style: TextStyle(fontWeight: FontWeight.bold)),
        Row(children: [
          Expanded(child: DropdownButtonFormField<int>(
            value: juz, isExpanded: true,
            decoration: const InputDecoration(labelText: 'رقم الجزء'),
            items: List.generate(30, (i) => DropdownMenuItem(value: i + 1, child: Text('الجزء ${i + 1}'))),
            onChanged: (v) => setState(() => juz = v ?? 1),
          )),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () { final loc = quranJuzLocation(juz); widget.onOpen(loc.$1, loc.$2); },
            icon: const Icon(Icons.bookmark), label: const Text('فتح الجزء'),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF493326)),
          ),
        ]),
      ]),
      ],
    ),
  );
}
