import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<ChartSampleData> _chartData = [];
  String _selectedPair = 'BTCTHB';
  String _selectedDuration = '1d';

  @override
  void initState() {
    super.initState();
    _fetchChartData();
  }

  Future<void> _fetchChartData() async {
    try {
      String formattedPair = _selectedPair.replaceAll('THB', '_THB');
      final response = await http.get(Uri.parse('http://localhost:8080/api/get?pair=$formattedPair&duration=$_selectedDuration'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> dataList = data['data'];

        setState(() {
          _chartData = dataList.map((item) => ChartSampleData(
            x: DateTime.parse(item['time']),
            price: item['value'].toDouble(),
          )).toList();
        });
      } else {
        setState(() {
          _chartData = [];
        });
        throw Exception('Failed to load chart data');
      }
    } catch (e) {
      setState(() {
        _chartData = [];
      });
      print('Error fetching chart data: $e');
    }
  }

  void _onPairChanged(String? newPair) {
    if (newPair != null && newPair != _selectedPair) {
      setState(() {
        _selectedPair = newPair;
        _fetchChartData();  // Fetch data for the new pair
      });
    }
  }

  void _onDurationChanged(String? newDuration) {
    if (newDuration != null && newDuration != _selectedDuration) {
      setState(() {
        _selectedDuration = newDuration;
        _fetchChartData();  // Fetch data for the new duration
      });
    }
  }

  void _refreshData() {
    _fetchChartData();  // Refetch the chart data
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,  // Refresh data on button press
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: 150,  // Adjust the width as needed
                    child: DropdownButton<String>(
                      value: _selectedPair,
                      isExpanded: true,
                      items: <String>['BTCTHB', 'ETHTHB', 'USDTTHB'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: _onPairChanged,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Container(
                    width: 150,  // Adjust the width as needed
                    child: DropdownButton<String>(
                      value: _selectedDuration,
                      isExpanded: true,
                      items: <String>['1h', '4h', '6h', '12h', '1d', '3d', '7d','30d','90d','365d'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: _onDurationChanged,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _chartData.isEmpty
                ? const CircularProgressIndicator()  // Show loading indicator while fetching
                : SfCartesianChart(
                    primaryXAxis: DateTimeAxis(),
                    series: <CartesianSeries>[
                      FastLineSeries<ChartSampleData, DateTime>(
                        dataSource: _chartData,
                        xValueMapper: (ChartSampleData data, _) => data.x,
                        yValueMapper: (ChartSampleData data, _) => data.price,
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

class ChartSampleData {
  ChartSampleData({required this.x, required this.price});
  final DateTime x;
  final double price;
}
