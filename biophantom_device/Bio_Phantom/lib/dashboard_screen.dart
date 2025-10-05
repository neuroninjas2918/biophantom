import 'dart:async';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'logic/detector_logic.dart';
import 'transport/transport_facade.dart';
import 'package:protocol/protocol.dart';

class DashboardScreen extends StatefulWidget {
  final DetectorLogic detectorLogic;

  const DashboardScreen({super.key, required this.detectorLogic});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<SensorData> _sensorData = [];
  List<double> _audioDbData = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Update the graph data periodically
    _refreshTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      _updateGraphData();
    });
    _updateGraphData();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _updateGraphData() {
    setState(() {
      _sensorData = widget.detectorLogic.getSensorDataHistory();
      _audioDbData = widget.detectorLogic.getAudioDbHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Dashboard'),
        leading: Image.asset(
          'assets/biophantom_logo.png',
          width: 40,
          height: 40,
        ), // Custom logo
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _updateGraphData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    widget.detectorLogic.isRunning
                        ? Icons.play_circle_filled
                        : Icons.pause_circle_filled,
                    color: widget.detectorLogic.isRunning
                        ? Colors.green
                        : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.detectorLogic.isRunning
                        ? 'Detector Running'
                        : 'Detector Stopped',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Sensor Readings Visualization',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _sensorData.isEmpty && !widget.detectorLogic.isRunning
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.sensors_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No sensor data available',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Start the detector to see graphs',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Back to Detector'),
                          ),
                        ],
                      ),
                    )
                  : _sensorData.isEmpty && widget.detectorLogic.isRunning
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          const Text(
                            'Collecting sensor data...',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Please move your device to generate data',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        _buildCharts(),
                        if (_audioDbData.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          // Audio dB Chart
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Audio dB Levels',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    height: 200,
                                    child: SfCartesianChart(
                                      primaryXAxis: NumericAxis(
                                        title: AxisTitle(text: 'Time'),
                                        isVisible: true,
                                      ),
                                      primaryYAxis: NumericAxis(
                                        title: AxisTitle(text: 'dB'),
                                        isVisible: true,
                                        minimum: 20,
                                        maximum: 120,
                                      ),
                                      legend: Legend(isVisible: true),
                                      series: _getAudioDbSeries(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCharts() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Accelerometer Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Accelerometer (m/s²)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 200,
                    child: SfCartesianChart(
                      primaryXAxis: NumericAxis(
                        title: AxisTitle(text: 'Time'),
                        isVisible: true,
                      ),
                      primaryYAxis: NumericAxis(
                        title: AxisTitle(text: 'Acceleration'),
                        isVisible: true,
                      ),
                      legend: Legend(isVisible: true),
                      series: _getAccelerometerSeries(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Gyroscope Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gyroscope (rad/s)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 200,
                    child: SfCartesianChart(
                      primaryXAxis: NumericAxis(
                        title: AxisTitle(text: 'Time'),
                        isVisible: true,
                      ),
                      primaryYAxis: NumericAxis(
                        title: AxisTitle(text: 'Rotation'),
                        isVisible: true,
                      ),
                      legend: Legend(isVisible: true),
                      series: _getGyroscopeSeries(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Magnitude Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sensor Magnitudes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 200,
                    child: SfCartesianChart(
                      primaryXAxis: NumericAxis(
                        title: AxisTitle(text: 'Time'),
                        isVisible: true,
                      ),
                      primaryYAxis: NumericAxis(
                        title: AxisTitle(text: 'Magnitude'),
                        isVisible: true,
                      ),
                      legend: Legend(isVisible: true),
                      series: _getMagnitudeSeries(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<LineSeries<SensorData, int>> _getAccelerometerSeries() {
    return [
      LineSeries<SensorData, int>(
        dataSource: _sensorData,
        xValueMapper: (data, index) => index,
        yValueMapper: (data, _) => data.accX,
        name: 'X',
        color: Colors.red,
      ),
      LineSeries<SensorData, int>(
        dataSource: _sensorData,
        xValueMapper: (data, index) => index,
        yValueMapper: (data, _) => data.accY,
        name: 'Y',
        color: Colors.green,
      ),
      LineSeries<SensorData, int>(
        dataSource: _sensorData,
        xValueMapper: (data, index) => index,
        yValueMapper: (data, _) => data.accZ,
        name: 'Z',
        color: Colors.blue,
      ),
    ];
  }

  List<LineSeries<SensorData, int>> _getGyroscopeSeries() {
    return [
      LineSeries<SensorData, int>(
        dataSource: _sensorData,
        xValueMapper: (data, index) => index,
        yValueMapper: (data, _) => data.gyroX,
        name: 'X',
        color: Colors.red,
      ),
      LineSeries<SensorData, int>(
        dataSource: _sensorData,
        xValueMapper: (data, index) => index,
        yValueMapper: (data, _) => data.gyroY,
        name: 'Y',
        color: Colors.green,
      ),
      LineSeries<SensorData, int>(
        dataSource: _sensorData,
        xValueMapper: (data, index) => index,
        yValueMapper: (data, _) => data.gyroZ,
        name: 'Z',
        color: Colors.blue,
      ),
    ];
  }

  List<LineSeries<SensorData, int>> _getMagnitudeSeries() {
    return [
      LineSeries<SensorData, int>(
        dataSource: _sensorData,
        xValueMapper: (data, index) => index,
        yValueMapper: (data, _) => data.accMagnitude,
        name: 'Acc Magnitude',
        color: Colors.purple,
      ),
      LineSeries<SensorData, int>(
        dataSource: _sensorData,
        xValueMapper: (data, index) => index,
        yValueMapper: (data, _) => data.gyroMagnitude,
        name: 'Gyro Magnitude',
        color: Colors.orange,
      ),
    ];
  }

  List<LineSeries<double, int>> _getAudioDbSeries() {
    return [
      LineSeries<double, int>(
        dataSource: _audioDbData,
        xValueMapper: (data, index) => index,
        yValueMapper: (data, _) => data,
        name: 'Audio dB',
        color: Colors.teal,
        width: 2,
      ),
    ];
  }
}
