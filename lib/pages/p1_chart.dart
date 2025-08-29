import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart'; // 引入 intl 库來處理日期格式

class ChartPage extends StatefulWidget {
  @override
  _ChartPageState createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  final List<Map<String, dynamic>> _records = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  // 加載保存的紀錄
  Future<void> _loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final String? recordsData = prefs.getString('records');
    if (recordsData != null) {
      final List<dynamic> decodedRecords = jsonDecode(recordsData);
      setState(() {
        _records.clear();
        _records.addAll(decodedRecords.map((record) => Map<String, dynamic>.from(record)));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 取得最近10筆紀錄
    final recentRecords = _getRecentRecords();

    // 創建體重和體脂率的數據點
    List<FlSpot> weightSpots = [];
    List<FlSpot> bodyFatSpots = [];

    // 設定日期格式化，僅顯示「日」
    final DateFormat dateFormat = DateFormat('d'); // 只顯示日

    for (int i = 0; i < recentRecords.length; i++) {
      final record = recentRecords[i];
      final date = DateTime.parse(record['date']);
      final weight = record['weight'];
      final bodyFat = record['bodyFat'];

      // 用數據點的索引作為 x 值
      final x = i.toDouble();

      // 檢查 x 是否為有效數字
      if (x.isFinite && weight.isFinite && bodyFat.isFinite) {
        weightSpots.add(FlSpot(x, weight));
        bodyFatSpots.add(FlSpot(x, bodyFat));
      } else {
        // 處理無效數據
        print('無效數據: x=$x, weight=$weight, bodyFat=$bodyFat');
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('趨勢圖'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            if (recentRecords.isNotEmpty) ...[
              // 標題：體重趨勢圖
              Text(
                '體重趨勢圖',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10), // 在標題和圖表之間添加間距

              // 圖表1：體重
              Container(
                height: 300, // 設定適合的高度
                width: double.infinity, // 設定寬度為父容器的最大寬度
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            // 顯示日期作為 x 軸的標籤
                            if (value < 0 || value >= recentRecords.length) {
                              return Container(); // 如果超過範圍不顯示
                            }
                            final record = recentRecords[value.toInt()];
                            final date = DateTime.parse(record['date']);
                            final formattedDate = dateFormat.format(date); // 只顯示日期
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(formattedDate, style: TextStyle(fontSize: 10)),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false), // 隱藏左側標籤
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            // 顯示體重數值
                            if (value.isFinite) {
                              return Text(value.toStringAsFixed(1), style: TextStyle(fontSize: 10));
                            }
                            return Container();
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: true, border: Border.all(color: Colors.black, width: 1)),
                    lineBarsData: [
                      LineChartBarData(
                        spots: weightSpots,
                        isCurved: true,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        belowBarData: BarAreaData(show: false),
                        dotData: FlDotData(
                          show: true, // 顯示圓點
                        ),
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20), // 在兩個圖表之間添加間距

              // 標題：體脂率趨勢圖
              Text(
                '體脂率趨勢圖',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10), // 在標題和圖表之間添加間距

              // 圖表2：體脂肪
              Container(
                height: 300, // 設定適合的高度
                width: double.infinity, // 設定寬度為父容器的最大寬度
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            // 顯示日期作為 x 軸的標籤
                            if (value < 0 || value >= recentRecords.length) {
                              return Container(); // 如果超過範圍不顯示
                            }
                            final record = recentRecords[value.toInt()];
                            final date = DateTime.parse(record['date']);
                            final formattedDate = dateFormat.format(date); // 只顯示日期
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(formattedDate, style: TextStyle(fontSize: 10)),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false), // 隱藏左側標籤
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            // 顯示體脂肪數值
                            if (value.isFinite) {
                              return Text(value.toStringAsFixed(1), style: TextStyle(fontSize: 10));
                            }
                            return Container();
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: true, border: Border.all(color: Colors.black, width: 1)),
                    lineBarsData: [
                      LineChartBarData(
                        spots: bodyFatSpots,
                        isCurved: true,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        belowBarData: BarAreaData(show: false),
                        dotData: FlDotData(
                          show: true, // 顯示圓點
                        ),
                        color: Colors.red,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (recentRecords.isEmpty)
              Center(child: Text('沒有足夠的數據來顯示圖表')),
          ],
        ),
      ),
    );
  }

  // 取得最近10筆紀錄
  List<Map<String, dynamic>> _getRecentRecords() {
    // 將紀錄按日期排序，然後返回最近10筆
    _records.sort((a, b) {
      DateTime dateA = DateTime.parse(a['date']);
      DateTime dateB = DateTime.parse(b['date']);
      return dateA.compareTo(dateB); // 升序排序，舊的日期排前面
    });

    return _records.take(10).toList(); // 返回最近10筆數據
  }
}
