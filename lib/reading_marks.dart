import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReadingMarks {
  static String _key(String section) => 'noor_reading_marks_$section';
  static String _lastKey(String section) => 'noor_reading_last_$section';

  static Future<double> loadLast(String section) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_lastKey(section)) ?? 0;
  }

  static Future<void> saveLast(String section, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_lastKey(section), value);
  }

  static Future<List<Map<String, dynamic>>> loadMarks(String section) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key(section)) ?? <String>[];
    return raw.map((item) {
      final parts = item.split('|');
      return <String, dynamic>{'label': parts.first, 'position': double.tryParse(parts.length > 1 ? parts[1] : '') ?? 0};
    }).toList();
  }

  static Future<void> addMark(String section, String label, double position) async {
    final prefs = await SharedPreferences.getInstance();
    final marks = prefs.getStringList(_key(section)) ?? <String>[];
    marks.add('$label|$position');
    await prefs.setStringList(_key(section), marks);
  }

  static Future<void> removeMark(String section, int index) async {
    final prefs = await SharedPreferences.getInstance();
    final marks = prefs.getStringList(_key(section)) ?? <String>[];
    if (index >= 0 && index < marks.length) {
      marks.removeAt(index);
      await prefs.setStringList(_key(section), marks);
    }
  }
}

class ReadingMarksControls extends StatefulWidget {
  final String section;
  final String label;
  final double position;
  final ValueChanged<double> onJump;
  const ReadingMarksControls({super.key, required this.section, required this.label, required this.position, required this.onJump});

  @override
  State<ReadingMarksControls> createState() => _ReadingMarksControlsState();
}

class _ReadingMarksControlsState extends State<ReadingMarksControls> {
  Future<void> _add() async {
    await ReadingMarks.addMark(widget.section, widget.label, widget.position);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ العلامة المرجعية')));
  }

  Future<void> _show() async {
    var marks = await ReadingMarks.loadMarks(widget.section);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(builder: (context, refresh) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('علاماتي المحفوظة', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (marks.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text('لا توجد علامات محفوظة حتى الآن')),
            if (marks.isNotEmpty) Flexible(child: ListView.builder(
              shrinkWrap: true,
              itemCount: marks.length,
              itemBuilder: (context, index) => ListTile(
                leading: const Icon(Icons.bookmark, color: Color(0xFF493326)),
                title: Text(marks[index]['label'].toString()),
                trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () async {
                  await ReadingMarks.removeMark(widget.section, index);
                  marks = await ReadingMarks.loadMarks(widget.section);
                  refresh(() {});
                }),
                onTap: () {
                  Navigator.pop(sheetContext);
                  widget.onJump((marks[index]['position'] as num).toDouble());
                },
              ),
            )),
          ]),
        ),
      )),
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
    child: Row(children: [
      Expanded(child: OutlinedButton.icon(onPressed: _add, icon: const Icon(Icons.bookmark_add_outlined), label: const Text('حفظ علامة'))),
      const SizedBox(width: 8),
      Expanded(child: OutlinedButton.icon(onPressed: _show, icon: const Icon(Icons.bookmarks_outlined), label: const Text('علاماتي المحفوظة'))),
    ]),
  );
}
