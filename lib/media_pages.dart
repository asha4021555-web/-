import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

const _liveQuranUrl = 'https://www.youtube.com/embed/kYqGbBqmp8g?autoplay=1';
const _liveSunnahUrl = 'https://www.youtube.com/embed/9A1S0xAPVIs?autoplay=1';
const _abdulbasitMuallimUrl = 'https://alkabbah.com/recitations/playlist/352651/aabd-albast-maalm-trdyd-alatfal-almshf-almaalm-mshf-mksm-agzaaa-kaml-aabd-alsmd';

class LiveChannelsPage extends StatelessWidget {
  const LiveChannelsPage({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(12),
    children: [
      const Padding(
        padding: EdgeInsets.all(8),
        child: Text('بث مباشر عبر الإنترنت من القنوات الرسمية السعودية.',
          style: TextStyle(fontSize: 15, height: 1.7)),
      ),
      _MediaCard(
        icon: Icons.mosque,
        title: 'قناة القرآن الكريم - الحرم المكي',
        subtitle: 'بث مباشر من المسجد الحرام بمكة المكرمة',
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => const _OnlineMediaPlayerPage(
            title: 'قناة القرآن الكريم - الحرم المكي',
            url: _liveQuranUrl,
          ),
        )),
      ),
      _MediaCard(
        icon: Icons.auto_stories,
        title: 'قناة السنة النبوية - المسجد النبوي',
        subtitle: 'بث مباشر من المسجد النبوي بالمدينة المنورة',
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => const _OnlineMediaPlayerPage(
            title: 'قناة السنة النبوية',
            url: _liveSunnahUrl,
          ),
        )),
      ),
    ],
  );
}

class AbdulbasitMuallimPage extends StatelessWidget {
  const AbdulbasitMuallimPage({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(12),
    children: [
      const Card(child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'المصحف المعلم للشيخ عبد الباسط عبد الصمد مع ترديد الأطفال. '
          'يحتاج إلى اتصال بالإنترنت، ويمكن تشغيل الأجزاء من القائمة.',
          style: TextStyle(height: 1.8),
        ),
      )),
      _MediaCard(
        icon: Icons.play_circle_fill,
        title: 'تشغيل المصحف المعلم',
        subtitle: 'عبد الباسط عبد الصمد - حفص عن عاصم - ترديد الأطفال',
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => const _OnlineMediaPlayerPage(
            title: 'المصحف المعلم - عبد الباسط',
            url: _abdulbasitMuallimUrl,
          ),
        )),
      ),
    ],
  );
}

class _MediaCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _MediaCard({required this.icon, required this.title,
    required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFE8C77B),
        child: Icon(icon, color: const Color(0xFF493326)),
      ),
      title: Text(title, style: const TextStyle(
        color: Color(0xFF493326), fontWeight: FontWeight.bold)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(subtitle),
      ),
      trailing: const Icon(Icons.play_arrow, color: Color(0xFF493326)),
      onTap: onTap,
    ),
  );
}

class _OnlineMediaPlayerPage extends StatefulWidget {
  final String title;
  final String url;
  const _OnlineMediaPlayerPage({required this.title, required this.url});

  @override
  State<_OnlineMediaPlayerPage> createState() => _OnlineMediaPlayerPageState();
}

class _OnlineMediaPlayerPageState extends State<_OnlineMediaPlayerPage> {
  late final WebViewController _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF5F0E6))
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) { if (mounted) setState(() { _loading = true; _error = null; }); },
        onPageFinished: (_) { if (mounted) setState(() => _loading = false); },
        onWebResourceError: (error) {
          if (error.isForMainFrame == true && mounted) {
            setState(() { _loading = false; _error = 'تعذر تحميل المحتوى. تحقق من اتصال الإنترنت ثم أعد المحاولة.'; });
          }
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title),
      backgroundColor: const Color(0xFF493326),
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          tooltip: 'إعادة التحميل',
          icon: const Icon(Icons.refresh),
          onPressed: () => _controller.reload(),
        ),
      ],
    ),
    body: Stack(children: [
      WebViewWidget(controller: _controller),
      if (_loading) const Align(
        alignment: Alignment.topCenter,
        child: LinearProgressIndicator(color: Color(0xFFE8C77B)),
      ),
      if (_error != null) Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.wifi_off, size: 42, color: Color(0xFF493326)),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => _controller.reload(),
              child: const Text('إعادة المحاولة'),
            ),
          ]),
        ),
      ),
    ]),
  );
}
