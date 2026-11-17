import 'package:flutter/material.dart';

void main() {
  runApp(const NoorAlIslamApp());
}

class NoorAlIslamApp extends StatelessWidget {
  const NoorAlIslamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'نور الإسلام',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF176B45),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8F3),
        fontFamily: 'Arial',
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const sections = <({String title, IconData icon, String subtitle})>[
    (title: 'القرآن الكريم', icon: Icons.menu_book_rounded, subtitle: 'قراءة سور القرآن الكريم'),
    (title: 'أذكار الصباح والمساء', icon: Icons.wb_twilight_rounded, subtitle: 'أذكار يومية'),
    (title: 'أذكار بعد الصلاة', icon: Icons.mosque_rounded, subtitle: 'أذكار الصلاة'),
    (title: 'الأدعية', icon: Icons.volunteer_activism_rounded, subtitle: 'أدعية من القرآن والسنة'),
    (title: 'الأحاديث النبوية', icon: Icons.auto_stories_rounded, subtitle: 'أحاديث نبوية مختارة'),
    (title: 'قصص الأنبياء', icon: Icons.history_edu_rounded, subtitle: 'قصص وعبر'),
    (title: 'أسماء الله الحسنى', icon: Icons.star_rounded, subtitle: 'الأسماء ومعانيها'),
    (title: 'السبحة الإلكترونية', icon: Icons.radio_button_checked_rounded, subtitle: 'عداد للتسبيح'),
    (title: 'مواقيت الصلاة', icon: Icons.access_time_rounded, subtitle: 'الصلوات الخمس والتنبيهات'),
    (title: 'اتجاه القبلة', icon: Icons.explore_rounded, subtitle: 'تحديد اتجاه القبلة'),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('نور الإسلام', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF176B45),
          foregroundColor: Colors.white,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF176B45), Color(0xFF0D4930)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('أهلاً بك في نور الإسلام', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('رفيقك للقرآن والذكر والعبادة', style: TextStyle(color: Colors.white70, fontSize: 15)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sections.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.12,
              ),
              itemBuilder: (context, index) {
                final item = sections[index];
                return Card(
                  elevation: 1,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('قسم ${item.title} قيد التجهيز')),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(item.icon, size: 34, color: const Color(0xFF176B45)),
                          const SizedBox(height: 10),
                          Text(item.title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 5),
                          Text(item.subtitle, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
