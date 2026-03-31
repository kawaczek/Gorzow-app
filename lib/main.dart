import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => super.createHttpClient(context)..badCertificateCallback = (cert, host, port) => true;
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  runApp(const GorzowApp());
}

class GorzowApp extends StatelessWidget {
  const GorzowApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gorzow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, textTheme: GoogleFonts.ubuntuTextTheme()),
      home: const TileDashboard(),
    );
  }
}

class TileDashboard extends StatefulWidget {
  const TileDashboard({super.key});
  @override
  State<TileDashboard> createState() => _TileDashboardState();
}

class _TileDashboardState extends State<TileDashboard> {
  final String _baseUrl = 'https://gorzow.kawak.pl';
  double _currentAppVersion = 2.0; // v2.0
  Map<String, dynamic>? _system;
  List<dynamic> _tiles = [];
  bool _loading = true;
  bool _isEditMode = false;
  Position? _currentPos;
  Map<String, dynamic>? _weather;

  @override
  void initState() { super.initState(); _boot(); }

  Future<void> _boot() async {
    await _loadCache();
    await _fetchData();
    _fetchWeather();
    _currentPos = await _determinePosition();
  }

  Future<void> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedSystem = prefs.getString('cache_system');
      final cachedTiles = prefs.getString('cache_tiles');
      if (cachedSystem != null) setState(() => _system = jsonDecode(cachedSystem));
      if (cachedTiles != null) setState(() => _tiles = jsonDecode(cachedTiles));
      if (_system != null || _tiles.isNotEmpty) setState(() => _loading = false);
    } catch (e) { debugPrint('Cache Error: $e'); }
  }

  Future<void> _fetchData() async {
    try {
      final resSys = await http.get(Uri.parse('$_baseUrl/dane/system.json')).timeout(const Duration(seconds: 5));
      final resTiles = await http.get(Uri.parse('$_baseUrl/dane/tiles.json')).timeout(const Duration(seconds: 5));
      if (resSys.statusCode == 200 && resTiles.statusCode == 200) {
        final sys = jsonDecode(resSys.body);
        final tiles = jsonDecode(resTiles.body)['tiles'] as List;
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('cache_system', jsonEncode(sys));
        prefs.setString('cache_tiles', jsonEncode(tiles));
        setState(() { _system = sys; _tiles = tiles; _loading = false; });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) { 
      debugPrint('Fetch Error: $e'); 
      setState(() => _loading = false); 
    }
  }

  Future<void> _fetchWeather() async {
    try {
      final res = await http.get(Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=52.73&longitude=15.23&current_weather=true&timezone=Europe/Berlin'));
      if (res.statusCode == 200) setState(() => _weather = jsonDecode(res.body)['current_weather']);
    } catch (e) { debugPrint('Weather Error: $e'); }
  }

  Future<Position?> _determinePosition() async {
    try {
      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      return await Geolocator.getCurrentPosition().timeout(const Duration(seconds: 5));
    } catch (e) { return null; }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF008C45))));

    Color primaryColor;
    try {
      String colorStr = (_system?['primary_color'] ?? '#008C45').replaceAll('#', '0xFF');
      primaryColor = Color(int.parse(colorStr));
    } catch (e) {
      primaryColor = const Color(0xFF008C45);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(_system?['app_name'] ?? 'Gorzow', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28)),
        actions: [
          IconButton(icon: Icon(_isEditMode ? Icons.check_circle : Icons.edit, color: Colors.white70), onPressed: () => setState(() => _isEditMode = !_isEditMode)),
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white70), onPressed: _fetchData),
        ],
      ),
      body: ReorderableGridView.count(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        padding: const EdgeInsets.all(12),
        onReorder: (oldIndex, newIndex) {
          setState(() {
            final item = _tiles.removeAt(oldIndex);
            _tiles.insert(newIndex, item);
          });
        },
        children: _tiles.map((t) => _buildTile(t, primaryColor)).toList(),
      ),
    );
  }

  Widget _buildTile(dynamic t, Color primaryColor) {
    final size = t['size'] ?? '1x1';
    int crossSpan = 1;
    int mainSpan = 1;
    if (size == '2x2') { crossSpan = 2; mainSpan = 2; }
    if (size == '4x2') { crossSpan = 4; mainSpan = 2; }

    return ReorderableDelayedDragStartListener(
      key: ValueKey(t['id']),
      index: _tiles.indexOf(t),
      child: GestureDetector(
        onTap: _isEditMode ? null : () => _handleTileTap(t),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: _isEditMode ? Colors.white10 : primaryColor,
            borderRadius: BorderRadius.circular(t['id'] == 'weather' ? 30 : 4),
          ),
          child: _buildTileContent(t),
        ),
      ),
    );
  }

  Widget _buildTileContent(dynamic t) {
    if (t['id'] == 'weather' && _weather != null) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 40),
              const SizedBox(height: 4),
              Text('${_weather!['temperature']}°C', 
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
              const Text('Gorzów', 
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_getIcon(t['icon']), color: Colors.white, size: 30),
                  if (t['size'] != '1x1') const SizedBox(height: 8),
                  if (t['size'] != '1x1') 
                    Text(t['title'] ?? '', 
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
        if (t['size'] == '1x1')
          Positioned(
            bottom: 4, left: 0, right: 0,
            child: Text(t['title'] ?? '', 
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  void _handleTileTap(dynamic t) {
    String url = t['url'] ?? '';
    if (t['type'] == 'map') {
      url = '$_baseUrl/map.php?data=${t['data_url']}&lat=${_currentPos?.latitude ?? 52.73}&lng=${_currentPos?.longitude ?? 15.23}';
    }
    
    if (t['type'] == 'app_link') {
      LaunchApp.openApp(androidPackageName: url.replaceAll('app://', ''));
    } else if (t['type'] == 'web' || t['type'] == 'map') {
      Navigator.push(context, MaterialPageRoute(builder: (c) => WebViewPage(url: url, title: t['title'])));
    }
  }

  IconData _getIcon(String? icon) {
    switch (icon) {
      case 'newspaper': return Icons.newspaper_rounded;
      case 'directions_bus': return Icons.directions_bus_rounded;
      case 'map': return Icons.map_rounded;
      case 'calendar_month': return Icons.calendar_month_rounded;
      default: return Icons.apps_rounded;
    }
  }
}

class WebViewPage extends StatefulWidget {
  final String url;
  final String title;
  const WebViewPage({super.key, required this.url, required this.title});
  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) => setState(() => _loading = true),
        onPageFinished: (url) => setState(() => _loading = false),
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
