import 'dart:io';
import 'dart:math';
import 'package:csv/csv.dart';
import 'dart:convert';

class DataProcessor {
  // Process sensor CSV file (accelerometer data)
  static Future<List<List<double>>> processSensorCSV(String filePath) async {
    try {
      final input = File(filePath).openRead();
      final fields = await input
          .transform(utf8.decoder)
          .transform(const CsvToListConverter())
          .toList();

      List<List<double>> data = [];

      // Skip header rows and process data
      for (int i = 1; i < fields.length; i++) {
        var row = fields[i];
        if (row.length >= 4) {
          // time, ax, ay, az, aT
          try {
            // Convert string values to doubles (skip time column at index 0)
            List<double> sensorRow = [
              double.parse(row[1].toString()), // ax
              double.parse(row[2].toString()), // ay
              double.parse(row[3].toString()), // az
            ];
            data.add(sensorRow);
          } catch (e) {
            // Skip rows that can't be parsed
            continue;
          }
        }
      }

      return data;
    } catch (e) {
      print('Error processing sensor CSV: $e');
      return [];
    }
  }

  // Process audio CSV file (dB levels)
  static Future<List<double>> processAudioCSV(String filePath) async {
    try {
      final input = File(filePath).openRead();
      final fields = await input
          .transform(utf8.decoder)
          .transform(const CsvToListConverter())
          .toList();

      List<double> dBLevels = [];

      // Skip header rows and process data
      for (int i = 1; i < fields.length; i++) {
        var row = fields[i];
        if (row.length >= 2) {
          // time, dB
          try {
            // Convert dB value to double (skip time column at index 0)
            double dBValue = double.parse(row[1].toString());
            dBLevels.add(dBValue);
          } catch (e) {
            // Skip rows that can't be parsed
            continue;
          }
        }
      }

      return dBLevels;
    } catch (e) {
      print('Error processing audio CSV: $e');
      return [];
    }
  }

  // Normalize data to a standard range
  static List<List<double>> normalizeSensorData(List<List<double>> data) {
    if (data.isEmpty) return data;

    // Find min and max values for each axis
    double minX = data.map((row) => row[0]).reduce((a, b) => a < b ? a : b);
    double maxX = data.map((row) => row[0]).reduce((a, b) => a > b ? a : b);
    double minY = data.map((row) => row[1]).reduce((a, b) => a < b ? a : b);
    double maxY = data.map((row) => row[1]).reduce((a, b) => a > b ? a : b);
    double minZ = data.map((row) => row[2]).reduce((a, b) => a < b ? a : b);
    double maxZ = data.map((row) => row[2]).reduce((a, b) => a > b ? a : b);

    // Normalize each value to 0-1 range
    return data.map((row) {
      return [
        (row[0] - minX) / (maxX - minX),
        (row[1] - minY) / (maxY - minY),
        (row[2] - minZ) / (maxZ - minZ),
      ];
    }).toList();
  }

  // Filter sensor data to remove outliers
  static List<List<double>> filterOutliers(
    List<List<double>> data,
    double threshold,
  ) {
    if (data.isEmpty) return data;

    // Calculate mean and std for each axis
    double meanX =
        data.map((row) => row[0]).reduce((a, b) => a + b) / data.length;
    double meanY =
        data.map((row) => row[1]).reduce((a, b) => a + b) / data.length;
    double meanZ =
        data.map((row) => row[2]).reduce((a, b) => a + b) / data.length;

    double stdX = sqrt(
      data.map((row) => pow(row[0] - meanX, 2)).reduce((a, b) => a + b) /
          data.length,
    );
    double stdY = sqrt(
      data.map((row) => pow(row[1] - meanY, 2)).reduce((a, b) => a + b) /
          data.length,
    );
    double stdZ = sqrt(
      data.map((row) => pow(row[2] - meanZ, 2)).reduce((a, b) => a + b) /
          data.length,
    );

    // Filter out data points that are beyond threshold standard deviations
    return data.where((row) {
      bool isOutlierX = (row[0] - meanX).abs() > threshold * stdX;
      bool isOutlierY = (row[1] - meanY).abs() > threshold * stdY;
      bool isOutlierZ = (row[2] - meanZ).abs() > threshold * stdZ;
      return !(isOutlierX || isOutlierY || isOutlierZ);
    }).toList();
  }
}
