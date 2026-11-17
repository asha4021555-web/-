import 'package:flutter/material.dart';

class DreamsPage extends StatefulWidget {
  const DreamsPage({super.key});
  static List<MapEntry<String, String>> get searchItems => _DreamsPageState.symbols;
  @override State<DreamsPage> createState() => _DreamsPageState();
}

class _DreamsPageState extends State<DreamsPage> {
  String query = '';
  static const symbols = <MapEntry<String, String>>[
    MapEntry('الماء الصافي','قد يُعبّر عن الخير والحياة والصفاء، ويتغير المعنى بحسب كثرته وحال الرائي.'),
    MapEntry('الماء العكر','قد يشير في بعض كتب التعبير إلى همّ أو أمر غير صافٍ؛ ولا يُحكم به دون تفاصيل الرؤيا.'),
    MapEntry('المطر','يرتبط غالبًا بالرحمة والرزق إذا كان نافعًا بلا ضرر، أما المطر المؤذي فله سياق مختلف.'),
    MapEntry('البحر','قد يرمز إلى أمر عظيم أو سلطان أو سعة، والخوف أو الغرق يغيّر دلالة الرؤيا.'),
    MapEntry('النهر','قد يدل على رزق أو حياة جارية أو أمر ينتفع به الرائي، بحسب صفاء الماء ومجرى النهر.'),
    MapEntry('الشجرة','قد تعبّر عن إنسان أو أهل أو أصل ثابت؛ وتختلف الدلالة باختلاف نوع الشجرة وحالها.'),
    MapEntry('الثمر والفاكهة','قد تدل على رزق ومنفعة، ويُنظر إلى نوع الثمر وموسمه وطعمه وحاله.'),
    MapEntry('العسل','يرتبط في التعبير بالرزق الطيب والعلم النافع والشفاء في بعض السياقات.'),
    MapEntry('اللبن','قد يُعبّر عن الفطرة أو العلم أو الرزق الحلال، وتختلف الدلالة باختلاف حاله.'),
    MapEntry('الخبز','قد يرمز إلى المعاش والرزق وأسباب الحياة، ويختلف بحسب جودته ووجوده.'),
    MapEntry('البيت','قد يعبّر عن حال صاحبه وأهله وخصوصيته؛ وبناء البيت أو خرابه لهما سياقان مختلفان.'),
    MapEntry('الثوب الجديد','قد يشير إلى الستر أو تحسن الحال أو بداية جديدة، بحسب لونه ونظافته ومناسبة لبسه.'),
    MapEntry('المسجد','يرتبط بالعبادة والأمان والاجتماع على الخير، وتفاصيل الصلاة أو الدخول مهمة في الفهم.'),
    MapEntry('الصلاة','قد تدل على الاستقامة أو قضاء حاجة أو أداء أمانة، ويُنظر إلى تمام الصلاة أو نقصها.'),
    MapEntry('الأذان','قد يرتبط بالدعوة إلى الحق أو الإعلان عن أمر، ولا يصح الجزم بمعناه من الرمز وحده.'),
    MapEntry('الكعبة','ترتبط في كتب التعبير بالدين والأمان والحج والقبلة، ويُراعى ما حدث حولها في الرؤيا.'),
    MapEntry('السفر','قد يرمز إلى انتقال من حال إلى حال أو طلب رزق أو علم؛ والوجهة ومشاعر الرائي مؤثرة.'),
    MapEntry('الطريق','قد يعبّر عن مسار الإنسان واختياراته؛ والطريق الواضح غير المظلم أو المنقطع.'),
    MapEntry('المفتاح','قد يشير إلى فتح باب أو تيسير أمر أو علم، بحسب ما فُتح به وما تعذّر.'),
    MapEntry('الباب','قد يرمز إلى مدخل أمر جديد أو فرصة أو خصوصية البيت؛ وحاله مفتوحًا أو مغلقًا مهم.'),
    MapEntry('الزواج','قد يرتبط بالمسؤولية أو الشراكة أو الانتقال إلى مرحلة جديدة، وليس بالضرورة زواجًا حرفيًا.'),
    MapEntry('الطفل','قد يدل على مسؤولية أو بداية أو أمر يحتاج إلى رعاية؛ ويختلف المعنى بحسب حال الطفل.'),
    MapEntry('الموت','لا يعني بالضرورة موتًا حقيقيًا؛ وقد يرد في التعبير بمعاني التغير أو انقطاع حال، ولا يُفزع منه.'),
    MapEntry('الثعبان','يُذكر في كتب التعبير كثيرًا رمزًا للعداوة أو الخوف، لكن لا يجوز اتهام شخص بعينه بسبب حلم.'),
    MapEntry('الأسد','قد يرمز إلى القوة أو صاحب سلطة أو خصومة شديدة، بحسب قربه وتصرفه وشعور الرائي.'),
    MapEntry('الكلب','تختلف دلالته في كتب التعبير باختلاف هيئته وسلوكه؛ فلا يُحكم على شخص أو علاقة بسببه.'),
    MapEntry('الطير','قد يرتبط بالخبر أو السفر أو الحرية أو الرزق، ويختلف باختلاف نوع الطائر وحاله.'),
    MapEntry('الذهب','تختلف دلالته بحسب الرائي والسياق والاستعمال؛ ولا يصح اعتبار رؤيته بشارة أو نذيرًا ثابتًا.'),
    MapEntry('الفضة','قد ترتبط بالمال أو الزينة أو أمر ذي قيمة، وتفاصيل الرؤيا هي التي ترجّح المعنى.'),
    MapEntry('النار','قد تدل على منفعة أو تحذير أو خصومة بحسب كونها نافعة أو مؤذية ومكانها.'),
  ];

  @override Widget build(BuildContext context) {
    final q = query.trim();
    final filtered = symbols.where((e) => e.key.contains(q) || e.value.contains(q)).toList();
    return Directionality(textDirection: TextDirection.rtl, child: ListView(padding: const EdgeInsets.all(16), children: [
      const Text('تعبير الرؤى والأحلام', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF493326))),
      const SizedBox(height: 8),
      const Text('معجم موسّع لرموز شائعة في كتب التعبير. المعاني احتمالية وتتغير باختلاف الرائي وتفاصيل الرؤيا، وليست علمًا بالغيب أو أحكامًا قطعية.'),
      const SizedBox(height: 12),
      TextField(decoration: InputDecoration(labelText: 'ابحث عن رمز في المنام', hintText: 'مثل: الماء، المطر، البيت، السفر', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), onChanged: (v) => setState(() => query = v)),
      const SizedBox(height: 12),
      const Text('معجم الرموز', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF493326))),
      for (final e in filtered)
        Card(margin: const EdgeInsets.only(top: 7), child: ExpansionTile(title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold)), childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14), children: [Text(e.value, style: const TextStyle(fontSize: 16, height: 1.8))])),
      if (filtered.isEmpty) const Padding(padding: EdgeInsets.all(18), child: Text('الرمز غير موجود في المعجم حاليًا.', textAlign: TextAlign.center)),
      const SizedBox(height: 12),
      Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('آداب التعامل مع الرؤيا', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF493326), fontSize: 17)),
        const SizedBox(height: 6),
        const Text('الرؤيا الصالحة يُحمد الله عليها، ولا تُقص إلا على محب أو ناصح. وإذا رأى الإنسان ما يكره فليستعذ بالله من شرها ومن الشيطان، وينفث عن يساره ثلاثًا، ولا يحدّث بها أحدًا.'),
        const SizedBox(height: 8),
        const Text('قد تكون المنامات من حديث النفس أو مما يحزن به الشيطان؛ فلا تبنِ قرارًا مصيريًا أو اتهامًا أو حكمًا شرعيًا على حلم.', style: TextStyle(height: 1.7)),
      ]))),
    ]));
  }
}