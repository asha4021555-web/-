import 'package:flutter/material.dart';

class DreamsPage extends StatelessWidget {
  const DreamsPage({super.key});

  @override Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: ListView(padding: const EdgeInsets.all(16), children: [
      const Text('تعبير الرؤى والأحلام', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF176B45))),
      const SizedBox(height: 8),
      const Text('ليس كل ما يراه النائم رؤيا تحتاج إلى تعبير؛ فقد تكون رؤيا صالحة، أو حلمًا مزعجًا، أو حديث نفس. ولا يجوز الجزم بمعنى الحلم أو ادعاء معرفة الغيب.'),
      const SizedBox(height: 14),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('إذا رأيت ما تحب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF176B45))),
        const SizedBox(height: 6),
        const Text('احمد الله، ولا تحدّث بها إلا من تحب أو من تثق بنصحه.'),
      ]))),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('إذا رأيت ما تكره', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF176B45))),
        const SizedBox(height: 6),
        const Text('استعذ بالله من الشيطان ومن شر ما رأيت، وانفث عن يسارك ثلاثًا، وتحول عن جنبك، ولا تحدّث بها أحدًا.'),
      ]))),
      const SizedBox(height: 10),
      const Text('تنبيه مهم', style: TextStyle(fontWeight: FontWeight.bold)),
      const Text('كتب التعبير القديمة تنقل اجتهادات وظنونًا تختلف باختلاف حال الرائي وسياق الرؤيا، وليست أحكامًا شرعية ولا تنبؤًا بالمستقبل. لن ننسب معنى إلى ابن سيرين أو غيره دون مصدر يمكن التحقق منه.'),
      const SizedBox(height: 10),
      const Text('سيُضاف معجم رموز موثّق من كتب التعبير مع ذكر المصدر لكل مدخل؛ لذلك لا نعرض الآن معاني رموز غير متحققة.', style: TextStyle(color: Colors.black54, height: 1.6)),
    ]),
  );
}
