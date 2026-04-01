import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => super.createHttpClient(context)..badCertificateCallback = (cert, host, port) => true;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  await initializeDateFormatting('pl_PL', null);
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
  double _currentAppVersion = 4.0; // v2.0
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
      final cachedSystem = prefs.getString('v3_system');
      final cachedTiles = prefs.getString('v3_tiles');
      if (cachedSystem != null) setState(() => _system = jsonDecode(cachedSystem));
      if (cachedTiles != null) setState(() => _tiles = jsonDecode(cachedTiles));
      if (_system != null || _tiles.isNotEmpty) setState(() => _loading = false);
    } catch (e) { debugPrint('Cache Error: $e'); }
  }

  Future<void> _fetchData() async {
    try {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final resSys = await http.get(Uri.parse('$_baseUrl/dane/system.json?nocache=$ts')).timeout(const Duration(seconds: 15));
      final resTiles = await http.get(Uri.parse('$_baseUrl/dane/tiles.json?nocache=$ts')).timeout(const Duration(seconds: 15));
      
      if (resSys.statusCode == 200 && resTiles.statusCode == 200) {
        final sys = jsonDecode(resSys.body);
        final tilesRaw = jsonDecode(resTiles.body);
        final List tiles = (tilesRaw['tiles'] ?? []) as List;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('v3_system', jsonEncode(sys));
        await prefs.setString('v3_tiles', jsonEncode(tiles));
        
        setState(() { 
          _system = sys; 
          _tiles = tiles; 
          _loading = false; 
        });
      } else {
        _showSnack('Błąd serwera: ${resSys.statusCode}');
        setState(() => _loading = false);
      }
    } catch (e) { 
      _showSnack('Brak połączenia z Bastionem 🐾');
      setState(() => _loading = false); 
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating)
    );
  }

  Future<void> _fetchWeather() async {
    try {
      final res = await http.get(Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=52.73&longitude=15.23&current_weather=true&hourly=temperature_2m,weathercode&daily=weathercode,temperature_2m_max,temperature_2m_min&timezone=Europe/Berlin'));
      if (res.statusCode == 200) setState(() => _weather = jsonDecode(res.body));
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

    final quickActions = _tiles.where((t) {
      final pid = t['parent_id'];
      return pid == null || pid == '' || pid == 'null';
    }).toList();
    
    debugPrint('UI: Rendering ${quickActions.length} top tiles.');
    
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
    final weatherData = _weather;
    final current = weatherData?['current_weather'];
    final bool isDay = (current?['is_day'] ?? 1) == 1;
    final weatherCode = current?['weathercode'] ?? 0;
    
    IconData weatherIcon = Icons.wb_sunny_rounded;
    List<Color> bannerColors = [primary, primary.withBlue(150)];
    String welcomeMsg = isDay ? 'Witaj w Bastionie! 🐾' : 'Dobry wieczór, Szefie! 🌙';

    if (weatherCode == 0) {
      weatherIcon = isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round;
      bannerColors = isDay ? [const Color(0xFFFFB300), const Color(0xFFF57C00)] : [const Color(0xFF1A237E), const Color(0xFF000000)];
    } else if (weatherCode <= 3) {
      weatherIcon = isDay ? Icons.wb_cloudy_rounded : Icons.cloudy_snowing;
      bannerColors = isDay ? [const Color(0xFF4FC3F7), const Color(0xFF0288D1)] : [const Color(0xFF303F9F), const Color(0xFF1A237E)];
    } else if (weatherCode >= 51) {
      weatherIcon = Icons.umbrella_rounded;
      bannerColors = [const Color(0xFF455A64), const Color(0xFF263238)];
      welcomeMsg = 'Pada w Gorzowie... 🌧️';
    }

    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: bannerColors[0],
      flexibleSpace: FlexibleSpaceBar(
        background: AnimatedContainer(
          duration: const Duration(seconds: 2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: bannerColors,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30, top: -30,
                child: Opacity(
                  opacity: 0.2,
                  child: Icon(weatherIcon, size: 250, color: Colors.white),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(welcomeMsg, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(_system?['app_name'] ?? 'Gorzów', 
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1)),
                    if (current != null) ...[
                      const SizedBox(height: 15),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => WeatherDetailPage(data: _weather!))),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(weatherIcon, color: Colors.white, size: 22),
                              const SizedBox(width: 10),
                              Text('${current['temperature']}°C', 
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                              const VerticalDivider(color: Colors.white24, width: 20),
                              const Text('Gorzów Wlkp.', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
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

class WeatherDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;
  const WeatherDetailPage({super.key, required this.data});

  String _getWeatherDesc(int code) {
    if (code == 0) return 'Czyste niebo';
    if (code <= 3) return 'Zachmurzenie';
    if (code <= 48) return 'Mgła';
    if (code <= 65) return 'Opady deszczu';
    if (code <= 75) return 'Opady śniegu';
    if (code <= 99) return 'Burza';
    return 'Pogoda';
  }

  @override
  Widget build(BuildContext context) {
    final current = data['current_weather'];
    final daily = data['daily'];
    final hourly = data['hourly'];
    final bool isDay = (current['is_day'] ?? 1) == 1;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDay ? [const Color(0xFF4FC3F7), const Color(0xFF0288D1)] : [const Color(0xFF1A237E), const Color(0xFF000000)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Text('Gorzów Wlkp.', style: GoogleFonts.poppins(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              Text(DateFormat('d MMMM yyyy', 'pl_PL').format(DateTime.now()), style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 30),
              Icon(isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round, size: 100, color: Colors.white),
              Text('${current['temperature']}°', style: GoogleFonts.poppins(color: Colors.white, fontSize: 80, fontWeight: FontWeight.w200)),
              Text(_getWeatherDesc(current['weathercode']), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              Text('Wiatr: ${current['windspeed']} km/h', style: const TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 40),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withOpacity(0.2))),
                      child: Column(
                        children: [
                          const Row(children: [Icon(Icons.access_time, color: Colors.white70, size: 18), SizedBox(width: 8), Text('PROGNOZA GODZINOWA', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold))]),
                          const SizedBox(height: 15),
                          SizedBox(
                            height: 80,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: 12,
                              itemBuilder: (context, i) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 25),
                                  child: Column(
                                    children: [
                                      Text('${(DateTime.now().hour + i) % 24}:00', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                      const SizedBox(height: 8),
                                      Text('${hourly['temperature_2m'][i]}°', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: 7,
                  itemBuilder: (context, i) {
                    final date = DateTime.now().add(Duration(days: i));
                    final dayName = i == 0 ? 'Dzisiaj' : i == 1 ? 'Jutro' : DateFormat('EEEE', 'pl_PL').format(date);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(dayName, style: const TextStyle(color: Colors.white, fontSize: 16)),
                          Row(
                            children: [
                              Text(_getWeatherDesc(daily['weathercode'][i]), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                              const SizedBox(width: 15),
                              Text('${daily['temperature_2m_max'][i]}°', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 10),
                              Text('${daily['temperature_2m_min'][i]}°', style: const TextStyle(color: Colors.white54)),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
