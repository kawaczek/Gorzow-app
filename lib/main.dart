import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:intl/intl.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => super.createHttpClient(context)..badCertificateCallback = (cert, host, port) => true;
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  runApp(const GorzowApp());
}

class GorzowApp extends StatefulWidget {
  const GorzowApp({super.key});
  @override
  State<GorzowApp> createState() => _GorzowAppState();
}

class _GorzowAppState extends State<GorzowApp> {
  Map<String, dynamic>? _manifest;
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetchManifest(); }

  Future<void> _fetchManifest() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse('https://gorzow.kawak.pl/wersje/manifest.json')).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        setState(() { _manifest = jsonDecode(res.body); _loading = false; });
      } else { _showError(); }
    } catch (e) { _showError(); }
  }

  void _showError() => setState(() => _loading = false);

  @override
  Widget build(BuildContext context) {
    if (_loading) return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
    
    final config = _manifest?['app_config'];
    final primaryColor = Color(int.parse((config?['primary_color'] ?? '#008C45').replaceAll('#', '0xFF')));

    return MaterialApp(
      title: config?['name'] ?? 'Gorzow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: primaryColor, textTheme: GoogleFonts.ubuntuTextTheme()),
      home: MainDashboard(manifest: _manifest, onRefresh: _fetchManifest),
    );
  }
}

class MainDashboard extends StatefulWidget {
  final Map<String, dynamic>? manifest;
  final VoidCallback onRefresh;
  const MainDashboard({super.key, this.manifest, required this.onRefresh});
  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  final double _currentAppVersion = 1.0;
  final String _baseUrl = 'https://gorzow.kawak.pl';
  Position? _currentPos;
  Map<String, dynamic>? _weather;

  @override
  void initState() { super.initState(); _boot(); }
  Future<void> _boot() async { _fetchWeather(); _currentPos = await _determinePosition(); _checkUpdate(); }

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

  void _checkUpdate() {
    if (widget.manifest == null) return;
    final serverVer = double.tryParse(widget.manifest!['app_config']['ota_version'].toString()) ?? 0.0;
    if (serverVer > _currentAppVersion) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Dostępna nowa wersja v$serverVer! 🐾🚀'),
        action: SnackBarAction(label: 'POBIERZ', onPressed: () => launchUrl(Uri.parse(_baseUrl), mode: LaunchMode.externalApplication)),
        duration: const Duration(seconds: 15),
        backgroundColor: Colors.blue[800],
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.manifest?['app_config'];
    final modules = (widget.manifest?['modules'] as List? ?? []).where((m) => m['active'] == true).toList();
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(config?['name'] ?? 'Gorzow', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 24)),
        centerTitle: true,
        actions: [IconButton(icon: Icon(Icons.refresh, color: primaryColor), onPressed: widget.onRefresh)],
      ),
      body: RefreshIndicator(
        onRefresh: () async { widget.onRefresh(); await _boot(); },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildWeatherCard(primaryColor),
            if (config?['notification'] != null) _buildNotification(config!['notification'], primaryColor),
            const SizedBox(height: 25),
            const Text('Twoje Miasto 🏠', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 15),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              children: modules.map((m) => _buildModuleCard(m, primaryColor)).toList(),
            ),
            const SizedBox(height: 40),
            Center(child: Text('System OBERON v$_currentAppVersion 🐾✨', style: const TextStyle(fontSize: 11, color: Colors.grey))),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard(Color col) {
    if (_weather == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(25),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [col, col.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(35),
        boxShadow: [BoxShadow(color: col.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          const Icon(Icons.wb_sunny_rounded, size: 60, color: Colors.white),
          const SizedBox(width: 25),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Gorzów Wielkopolski', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
              Text('${_weather!['temperature']}°C', style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotification(String text, Color col) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: col.withOpacity(0.2))),
      child: Row(
        children: [
          Icon(Icons.notifications_active_rounded, color: col, size: 20),
          const SizedBox(width: 15),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF475569)))),
        ],
      ),
    );
  }

  Widget _buildModuleCard(dynamic m, Color col) {
    return InkWell(
      onTap: () => _handleModuleTap(m),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: col.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(_getIcon(m['icon']), color: col, size: 30),
            ),
            const SizedBox(height: 12),
            Text(m['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
          ],
        ),
      ),
    );
  }

  void _handleModuleTap(dynamic m) {
    String url = m['url'] ?? '';
    if (m['type'] == 'map') {
      url = '$_baseUrl/map.php?data=${m['data_url']}&lat=${_currentPos?.latitude ?? 52.73}&lng=${_currentPos?.longitude ?? 15.23}';
    }
    
    if (m['type'] == 'app_link') {
      LaunchApp.openApp(androidPackageName: url.replaceAll('app://', ''));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (c) => WebViewPage(url: url, title: m['name'])));
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
      appBar: AppBar(title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold))),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
