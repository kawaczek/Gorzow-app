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
  double _currentAppVersion = 3.4; // v2.0
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
      final ts = DateTime.now().millisecondsSinceEpoch;
      final resSys = await http.get(Uri.parse('$_baseUrl/dane/system.json?t=$ts')).timeout(const Duration(seconds: 5));
      final resTiles = await http.get(Uri.parse('$_baseUrl/dane/tiles.json?t=$ts')).timeout(const Duration(seconds: 5));
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
    if (_loading) return Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator(color: Color(int.parse((_system?['primary_color'] ?? '#008C45').replaceAll('#', '0xFF'))))));

    Color primaryColor;
    try {
      String colorStr = (_system?['primary_color'] ?? '#008C45').replaceAll('#', '0xFF');
      primaryColor = Color(int.parse(colorStr));
    } catch (e) {
      primaryColor = const Color(0xFF008C45);
    }

    final quickActions = _tiles.where((t) => t['parent_id'] == null || t['parent_id'] == '').toList();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeroBanner(primaryColor),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text('Szybkie Akcje ⚡', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 110,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: quickActions.length,
                itemBuilder: (context, index) => _buildQuickAction(quickActions[index], primaryColor),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Odkryj Miasto 🏙️', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final topLevelTiles = _tiles.where((t) => t['parent_id'] == null || t['parent_id'] == '').toList();
                  return _buildModernCard(topLevelTiles[index], primaryColor);
                },
                childCount: _tiles.where((t) => t['parent_id'] == null || t['parent_id'] == '').length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(Color primary) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primary, primary.withBlue(100)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -20,
                child: Icon(Icons.wb_sunny_rounded, size: 200, color: Colors.white.withOpacity(0.1)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 80, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Witaj w Bastionie! 🐾', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(_system?['app_name'] ?? 'Gorzów', 
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
                    if (_weather != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.thermostat_rounded, color: Colors.white, size: 20),
                          Text(' ${_weather!['temperature']}°C', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 16),
                          const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
                          const Text(' Gorzów Wlkp.', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(icon: const Icon(Icons.admin_panel_settings, color: Colors.white), onPressed: () => setState(() => _isEditMode = !_isEditMode)),
        IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _boot),
      ],
    );
  }

  Widget _buildQuickAction(dynamic t, Color primary) {
    return GestureDetector(
      onTap: () => _handleTileTap(t),
      child: Container(
        width: 85,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Icon(_getIcon(t['icon']), color: primary, size: 28),
            ),
            const SizedBox(height: 8),
            Text(t['title'] ?? '', 
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _buildModernCard(dynamic t, Color primary) {
    return GestureDetector(
      onTap: () => _handleTileTap(t),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              if (t['type'] == 'folder')
                Positioned(right: -10, top: -10, child: Icon(Icons.folder_rounded, size: 80, color: primary.withOpacity(0.05))),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: primary.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                      child: Icon(_getIcon(t['icon']), color: primary, size: 24),
                    ),
                    Text(t['title'] ?? '', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTileTap(dynamic t) {
    if (t['type'] == 'folder') {
      _showFolder(t);
      return;
    }

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

  void _showFolder(dynamic folder) {
    final children = _tiles.where((t) => t['parent_id'] == folder['id']).toList();
    Color primaryColor = Color(int.parse((_system?['primary_color'] ?? '#008C45').replaceAll('#', '0xFF')));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(_getIcon(folder['icon']), color: primaryColor, size: 28),
                const SizedBox(width: 12),
                Text(folder['title'] ?? 'Folder', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: children.isEmpty 
                ? const Center(child: Text('Ten folder jest pusty 🐾'))
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 20, crossAxisSpacing: 20, childAspectRatio: 0.8),
                    itemCount: children.length,
                    itemBuilder: (context, index) => _buildQuickAction(children[index], primaryColor),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String? icon) {
    switch (icon) {
      case 'newspaper': return Icons.newspaper_rounded;
      case 'directions_bus': return Icons.directions_bus_rounded;
      case 'map': return Icons.map_rounded;
      case 'calendar_month': return Icons.calendar_month_rounded;
      case 'wb_sunny': return Icons.wb_sunny_rounded;
      case 'account_balance': return Icons.account_balance_rounded;
      case 'feed': return Icons.feed_rounded;
      case 'radio': return Icons.radio_rounded;
      case 'public': return Icons.public_rounded;
      case 'delete_outline': return Icons.delete_outline_rounded;
      case 'folder': return Icons.folder_rounded;
      case 'thermostat': return Icons.thermostat_rounded;
      case 'location_on': return Icons.location_on_rounded;
      case 'info': return Icons.info_outline_rounded;
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
