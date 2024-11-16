import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

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
      debugShowCheckedModeBanner: false,
      home: const DataDisplayPage(),
    );
  }
}

class DataDisplayPage extends StatefulWidget {
  const DataDisplayPage({Key? key}) : super(key: key);

  @override
  State<DataDisplayPage> createState() => _DataDisplayPageState();
}

class _DataDisplayPageState extends State<DataDisplayPage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? data;
  bool isLoading = true;
  bool isPipeOn = false;
  late Timer _timer;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    fetchData();
    fetchPipeStatus(); // Fetch initial pipe status
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => fetchData());
  }

  @override
  void dispose() {
    _timer.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> fetchData() async {
    final url = Uri.parse('https://iot-3ogs.onrender.com/receive');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          data = json.decode(response.body);
          isLoading = false;
        });

        final soilMoisture = data!['soilMoisture']?.toDouble() ?? 0.0;
        if (soilMoisture < 40) {
          // Log message instead of sending a notification
          print('Warning: Soil moisture is below 40%.');
        }
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

  Future<void> fetchPipeStatus() async {
    final url = Uri.parse('https://iot-3ogs.onrender.com/pipe_status');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          final pipeData = json.decode(response.body);
          isPipeOn = pipeData['pipeStatus'] == 'on';
        });
      } else {
        print('Failed to fetch pipe status');
      }
    } catch (e) {
      print('Error fetching pipe status: $e');
    }
  }

  Future<void> sendPipeRequest(String status) async {
    final url = Uri.parse('https://iot-3ogs.onrender.com/send');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"status": status}),
      );

      if (response.statusCode == 200) {
        setState(() {
          isPipeOn = status == 'on';
        });
        // Log pipe status change instead of sending a notification
        print('Pipe is now ${isPipeOn ? "on" : "off"}');
      } else {
        print('Failed to change pipe status');
      }
    } catch (e) {
      print('Error sending pipe request: $e');
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
        Text(
          '$label: ${value.toStringAsFixed(1)}%',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: value / 100,
            color: getColorForValue(value),
            backgroundColor: Colors.grey[300],
            minHeight: 12,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IoT Data Display'),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        elevation: 10,
        flexibleSpace: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurple,
                    Colors.purple.withOpacity(0.5 + 0.5 * _controller.value),
                    Colors.deepPurple,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            );
          },
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : data == null || data!.isEmpty
              ? const Center(child: Text("No data found"))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          color: Colors.deepPurpleAccent,
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                buildProgressIndicator(
                                  "Soil Moisture",
                                  data!['soilMoisture']?.toDouble() ?? 0.0,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Pipe Status: ${isPipeOn ? "On" : "Off"}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Center(
                          child: ElevatedButton(
                            onPressed: () => sendPipeRequest('on'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 50, vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Open the Pipe',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: ElevatedButton(
                            onPressed: () => sendPipeRequest('off'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 50, vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Close the Pipe',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
