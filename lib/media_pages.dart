import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

const _liveQuranUrl = 'https://win.holol.com/live/quran/playlist.m3u8';
const _liveSunnahUrl = 'https://win.holol.com/live/sunnah/playlist.m3u8';

class LiveChannelsPage extends StatelessWidget {
  const LiveChannelsPage({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(12),
    children: [
      const Padding(
        padding: EdgeInsets.all(8),
        child: Text(
          'بث القناتين مباشرة داخل التطبيق، من غير فتح يوتيوب.',
          style: TextStyle(fontSize: 15, height: 1.7),
        ),
      ),
      _MediaCard(
        icon: Icons.mosque,
        title: 'قناة القرآن الكريم - الحرم المكي',
        subtitle: 'بث مباشر من المسجد الحرام',
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => const _LivePlayerPage(
            title: 'قناة القرآن الكريم - الحرم المكي',
            url: _liveQuranUrl,
          ),
        )),
      ),
      _MediaCard(
        icon: Icons.auto_stories,
        title: 'قناة السنة النبوية - المسجد النبوي',
        subtitle: 'بث مباشر من المسجد النبوي',
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => const _LivePlayerPage(
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
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.library_music, size: 52, color: Color(0xFF493326)),
          SizedBox(height: 14),
          Text(
            'المصحف المعلم - عبد الباسط عبد الصمد',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Color(0xFF493326),
            ),
          ),
          SizedBox(height: 10),
          Text(
            'ترديد الأطفال - حفص عن عاصم',
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Text(
            'لن نشغّل صفحة خارجية أو إعلانات. جاري تجهيز روابط ملفات الصوت المباشرة حتى يعمل المصحف من مشغّل نور الإسلام نفسه.',
            textAlign: TextAlign.center,
            style: TextStyle(height: 1.8),
          ),
        ],
      ),
    ),
  );
}

class _MediaCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _MediaCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

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

class _LivePlayerPage extends StatefulWidget {
  final String title;
  final String url;
  const _LivePlayerPage({required this.title, required this.url});

  @override
  State<_LivePlayerPage> createState() => _LivePlayerPageState();
}

class _LivePlayerPageState extends State<_LivePlayerPage> {
  late final VideoPlayerController _player;
  String? _error;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _player = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _player.initialize();
      if (!mounted) return;
      setState(() => _ready = true);
      await _player.play();
    } catch (_) {
      if (mounted) setState(() => _error =
        'تعذر تشغيل البث حاليًا. تحقق من الإنترنت وحاول مرة أخرى.');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title),
      backgroundColor: const Color(0xFF493326),
      foregroundColor: Colors.white,
    ),
    body: Center(
      child: _error != null
        ? Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off, size: 44),
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    setState(() { _error = null; _ready = false; });
                    _initialize();
                  },
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          )
        : !_ready
          ? const CircularProgressIndicator()
          : AspectRatio(
              aspectRatio: _player.value.aspectRatio,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  VideoPlayer(_player),
                  VideoProgressIndicator(
                    _player,
                    allowScrubbing: false,
                    colors: const VideoProgressColors(
                      playedColor: Color(0xFFE8C77B),
                      bufferedColor: Colors.white38,
                      backgroundColor: Colors.black26,
                    ),
                  ),
                  Center(
                    child: IconButton.filled(
                      iconSize: 38,
                      onPressed: () => setState(() {
                        _player.value.isPlaying
                          ? _player.pause()
                          : _player.play();
                      }),
                      icon: Icon(_player.value.isPlaying
                        ? Icons.pause : Icons.play_arrow),
                    ),
                  ),
                ],
              ),
            ),
    ),
  );
}
