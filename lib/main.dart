import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:async';

const String supabaseUrl = '********************';
const String supabaseAnonKey = '*******************';

class SensorData {
  final int id;
  final double temperature;
  final double humidity;
  final bool alertStatus;
  final bool temperatureAlert;
  final bool humidityAlert;
  final String deviceId;
  final DateTime createdAt;

  SensorData({
    required this.id, required this.temperature, required this.humidity,
    required this.alertStatus, required this.temperatureAlert, required this.humidityAlert,
    required this.deviceId, required this.createdAt,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) => SensorData(
    id: json['id'],
    temperature: double.parse(json['temperature'].toString()),
    humidity: double.parse(json['humidity'].toString()),
    alertStatus: json['alert_status'] ?? false,
    temperatureAlert: json['temperature_alert'] ?? false,
    humidityAlert: json['humidity_alert'] ?? false,
    deviceId: json['device_id'] ?? '',
    createdAt: DateTime.parse(json['created_at']),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DHT22 Dashboard',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
      ),
      home: SensorDashboard(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SensorDashboard extends StatefulWidget {
  @override
  _SensorDashboardState createState() => _SensorDashboardState();
}

class _SensorDashboardState extends State<SensorDashboard> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<SensorData> sensorDataList = [];
  SensorData? latestData;
  bool isLoading = true;
  String errorMessage = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    loadSensorData();
    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (mounted) loadSensorData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> loadSensorData() async {
    try {
      setState(() { isLoading = true; errorMessage = ''; });
      
      final response = await supabase.from('sensor_data')
          .select('*').order('created_at', ascending: false).limit(50);

      final List<SensorData> data = (response as List)
          .map((item) => SensorData.fromJson(item)).toList();

      setState(() {
        sensorDataList = data;
        latestData = data.isNotEmpty ? data.first : null;
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        errorMessage = 'Erreur: ${error.toString()}';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: isLoading ? _buildLoadingState() : 
            errorMessage.isNotEmpty ? _buildErrorState() : 
            _buildDashboard(isMobile),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
          ),
          SizedBox(height: 24),
          Text('Chargement...', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(32),
        margin: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            SizedBox(height: 16),
            Text('Erreur de connexion', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(errorMessage, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: loadSensorData,
              icon: Icon(Icons.refresh),
              label: Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(bool isMobile) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          backgroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 80,
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.sensors, color: Colors.white, size: 24),
              ),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DHT22 Dashboard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                  Text('Monitoring en temps réel', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
          actions: [
            Container(
              margin: EdgeInsets.only(right: 16),
              child: IconButton(
                onPressed: loadSensorData,
                icon: Icon(Icons.refresh, color: Color(0xFF6366F1)),
                style: IconButton.styleFrom(
                  backgroundColor: Color(0xFF6366F1).withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
        SliverPadding(
          padding: EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildMetricsCards(isMobile),
              SizedBox(height: 24),
              _buildChartSection(),
              SizedBox(height: 24),
              _buildHistorySection(),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsCards(bool isMobile) {
    if (latestData == null) return SizedBox.shrink();

    return isMobile 
      ? Column(children: [_buildTemperatureCard(), SizedBox(height: 16), _buildHumidityCard()])
      : Row(children: [
          Expanded(child: _buildTemperatureCard()),
          SizedBox(width: 16),
          Expanded(child: _buildHumidityCard()),
        ]);
  }

  Widget _buildTemperatureCard() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFEA580C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Color(0xFFF97316).withOpacity(0.3), blurRadius: 12, offset: Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.thermostat, color: Colors.white, size: 28),
              Spacer(),
              if (latestData!.temperatureAlert) Icon(Icons.warning, color: Colors.white, size: 24),
            ],
          ),
          SizedBox(height: 16),
          Text('Température', style: TextStyle(color: Colors.white70, fontSize: 16)),
          SizedBox(height: 4),
          Text('${latestData!.temperature.toStringAsFixed(1)}°C', 
               style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          LinearProgressIndicator(
            value: latestData!.temperature / 50,
            backgroundColor: Colors.white30,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildHumidityCard() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Color(0xFF3B82F6).withOpacity(0.3), blurRadius: 12, offset: Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.water_drop, color: Colors.white, size: 28),
              Spacer(),
              if (latestData!.humidityAlert) Icon(Icons.warning, color: Colors.white, size: 24),
            ],
          ),
          SizedBox(height: 16),
          Text('Humidité', style: TextStyle(color: Colors.white70, fontSize: 16)),
          SizedBox(height: 4),
          Text('${latestData!.humidity.toStringAsFixed(1)}%', 
               style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          LinearProgressIndicator(
            value: latestData!.humidity / 100,
            backgroundColor: Colors.white30,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    if (sensorDataList.length < 2) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tendances', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
          SizedBox(height: 24),
          Container(height: 200, child: _buildChart()),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final data = sensorDataList.reversed.take(20).toList();
    
    return LineChart(
      LineChartData(
        minX: 0, maxX: data.length.toDouble() - 1, minY: 0, maxY: 100,
        gridData: FlGridData(show: true, drawVerticalLine: false, 
                             getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[200]!, strokeWidth: 1)),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.temperature)).toList(),
            isCurved: true, color: Color(0xFFF97316), barWidth: 3,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: true, 
                                     color: Color(0xFFF97316).withOpacity(0.1)),
          ),
          LineChartBarData(
            spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.humidity)).toList(),
            isCurved: true, color: Color(0xFF3B82F6), barWidth: 3,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: true, 
                                     color: Color(0xFF3B82F6).withOpacity(0.1)),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Historique', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
          SizedBox(height: 16),
          ...sensorDataList.take(10).map((data) => Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: data.alertStatus ? Colors.red[300]! : Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: data.alertStatus ? Colors.red[100] : Colors.green[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    data.alertStatus ? Icons.warning : Icons.check_circle,
                    color: data.alertStatus ? Colors.red[600] : Colors.green[600],
                    size: 16,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('${data.temperature.toStringAsFixed(1)}°C', 
                               style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF97316))),
                          SizedBox(width: 16),
                          Text('${data.humidity.toStringAsFixed(1)}%', 
                               style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
                        ],
                      ),
                      Text(DateFormat('dd/MM HH:mm').format(data.createdAt),
                           style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
}
