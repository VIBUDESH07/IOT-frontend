import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';  // Import for Timer

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IoT Data Display',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const DataDisplayPage(),
    );
  }
}

class DataDisplayPage extends StatefulWidget {
  const DataDisplayPage({Key? key}) : super(key: key);

  @override
  State<DataDisplayPage> createState() => _DataDisplayPageState();
}

class _DataDisplayPageState extends State<DataDisplayPage> {
  Map<String, dynamic>? data;
  bool isLoading = true;
  late Timer _timer;  // Timer variable to periodically fetch data

  @override
  void initState() {
    super.initState();
    fetchData();  // Initial fetch
    // Set up a timer to fetch data every 20 seconds
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => fetchData());
  }

  @override
  void dispose() {
    _timer.cancel();  // Cancel the timer when the widget is disposed
    super.dispose();
  }

  Future<void> fetchData() async {
    final url = Uri.parse('https://iot-3ogs.onrender.com/receive'); // Replace with your actual URL

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          data = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error: $e');
    }
  }

  Color getColorForValue(double value) {
    if (value <= 25) return Colors.red;
    if (value <= 50) return Colors.blue;
    if (value <= 75) return Colors.yellow;
    return Colors.green;
  }

  Widget buildProgressIndicator(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.toStringAsFixed(1)}%'),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: value / 100,
          color: getColorForValue(value),
          backgroundColor: Colors.grey[300],
          minHeight: 10,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Future<void> sendPipeRequest(String status) async {
    // Simulate sending a request to open/close the pipe
    final url = Uri.parse('https://iot-3ogs.onrender.com/send');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"status": status}),
      );

      if (response.statusCode == 200) {
        print('Pipe status changed to: $status');
      } else {
        print('Failed to change pipe status');
      }
    } catch (e) {
      print('Error sending pipe request: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IoT Data Display'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : data == null || data!.isEmpty
              ? const Center(child: Text("No data found"))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildProgressIndicator("Temperature", data!['temperature'].toDouble()),
                      buildProgressIndicator("Humidity", data!['humidity'].toDouble()),
                      buildProgressIndicator("Soil Moisture", data!['soilMoisture'].toDouble()),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: () => sendPipeRequest('on'),
                        child: const Text('Open the Pipe'),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => sendPipeRequest('off'),
                        child: const Text('Close the Pipe'),
                      ),
                    ],
                  ),
                ),
    );
  }
}
