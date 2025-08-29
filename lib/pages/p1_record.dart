import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'p1_chart.dart';

class RecordPage extends StatefulWidget {
  @override
  _RecordPageState createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  final List<Map<String, dynamic>> _records = [];
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _bodyFatController = TextEditingController();
  final TextEditingController _dateController =
      TextEditingController(); // 用來輸入日期

  @override
  void initState() {
    super.initState();
    _loadRecords();
    _dateController.text = _formatDate(DateTime.now()); // 預設日期為今天
  }

  // 加載保存的紀錄
  Future<void> _loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final String? recordsData = prefs.getString('records');
    if (recordsData != null) {
      final List<dynamic> decodedRecords = jsonDecode(recordsData);
      setState(() {
        _records.clear();
        _records.addAll(
            decodedRecords.map((record) => Map<String, dynamic>.from(record)));
      });
    }
  }

  // 保存紀錄到內部存取
  Future<void> _saveRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedRecords = jsonEncode(_records);
    await prefs.setString('records', encodedRecords);
  }

  void _addRecord() {
    final double weight = double.tryParse(_weightController.text) ?? 0;
    final double bodyFat = double.tryParse(_bodyFatController.text) ?? 0;
    final double bodyFatMass = weight * bodyFat / 100;
    final String date = _dateController.text; // 使用用戶輸入的日期

    setState(() {
      _records.insert(0, {
        "date": date,
        "weight": weight,
        "bodyFat": bodyFat,
        "bodyFatMass": bodyFatMass,
      });
      if (_records.length > 50) {
        _records.removeLast();
      }
    });
    _saveRecords();
    _clearInputs();
  }

  void _clearInputs() {
    _weightController.clear();
    _bodyFatController.clear();
    _dateController.text = _formatDate(DateTime.now()); // 重置日期為今天
  }

  void _deleteRecord(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("確認刪除"),
        content: Text("你確定要刪除此紀錄嗎？"),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _records.removeAt(index);
              });
              _saveRecords();
              Navigator.pop(context);
            },
            child: Text("刪除"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context), // 關閉對話框
            child: Text("取消"),
          ),
        ],
      ),
    );
  }

  // 用來顯示日期格式
  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // 按月份分組紀錄
  Map<String, List<Map<String, dynamic>>> _groupRecordsByMonth() {
    Map<String, List<Map<String, dynamic>>> groupedRecords = {};

    for (var record in _records) {
      final DateTime date = DateTime.parse(record['date']);
      final String monthKey =
          "${date.year}-${date.month.toString().padLeft(2, '0')}"; // 用YYYY-MM作為分組鍵

      if (!groupedRecords.containsKey(monthKey)) {
        groupedRecords[monthKey] = [];
      }
      groupedRecords[monthKey]?.add(record);
    }

    return groupedRecords;
  }

  Widget _buildRecordForm() {
    DateTime now = DateTime.now();
    String nowStr = _formatDate(now); // 格式化日期為 yyyy-MM-dd
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _dateController,
          decoration: InputDecoration(
            labelText: "日期 (yyyy-MM-dd)",
            hintText: nowStr,
          ),
          keyboardType: TextInputType.datetime,
          inputFormatters: [
            // 自定義格式化器
            FilteringTextInputFormatter.digitsOnly, // 只允許數字
            DateInputFormatter(),
          ],
        ),
        TextField(
          controller: _weightController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: "體重 (kg)"),
        ),
        TextField(
          controller: _bodyFatController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: "體脂率 (%)"),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupedRecords = _groupRecordsByMonth(); // 分組紀錄

    return Scaffold(
      appBar: AppBar(
        title: Text("紀錄"),
        actions: [
          IconButton(
            icon: Icon(Icons.show_chart), // 圖表圖示
            onPressed: () {
              // 當按鈕被按下，導航到圖表頁面
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChartPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: groupedRecords.keys.map((monthKey) {
            final recordsForMonth = groupedRecords[monthKey]!;

            return ExpansionTile(
              title: Text("月份: $monthKey"),
              children: recordsForMonth.map((record) {
                return ListTile(
                  title: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${record['date']}"),
                            Row(
                              children: [
                                Text("體重: ${record['weight']} kg, "),
                                Text("體脂率: ${record['bodyFat']}%"),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () =>
                                _editRecord(_records.indexOf(record)),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () =>
                                _deleteRecord(_records.indexOf(record)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  subtitle: Text(
                      "體脂重: ${record['bodyFatMass'].toStringAsFixed(2)} kg"),
                );
              }).toList(),
            );
          }).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("新增紀錄"),
              content: _buildRecordForm(),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("重置"),
                ),
                TextButton(
                  onPressed: () {
                    _addRecord();
                    Navigator.pop(context);
                  },
                  child: Text("送出"),
                ),
              ],
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void _editRecord(int index) {
    final record = _records[index];
    _weightController.text = record['weight'].toString();
    _bodyFatController.text = record['bodyFat'].toString();
    _dateController.text = record['date']; // 設置日期為該紀錄的日期

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("編輯紀錄"),
        content: _buildRecordForm(),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("取消"),
          ),
          TextButton(
            onPressed: () {
              _updateRecord(index);
              Navigator.pop(context);
            },
            child: Text("儲存"),
          ),
        ],
      ),
    );
  }

  void _updateRecord(int index) {
    final double weight = double.tryParse(_weightController.text) ?? 0;
    final double bodyFat = double.tryParse(_bodyFatController.text) ?? 0;
    final double bodyFatMass = weight * bodyFat / 100;
    final String date = _dateController.text;

    setState(() {
      _records[index] = {
        "date": date,
        "weight": weight,
        "bodyFat": bodyFat,
        "bodyFatMass": bodyFatMass,
      };
    });
    _saveRecords();
    _clearInputs();
  }
}

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // 去除非數字字符
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // 需要按 yyyy-MM-dd 格式插入 -
    if (newText.length >= 5) {
      newText = newText.substring(0, 4) + '-' + newText.substring(4);
    }
    if (newText.length >= 8) {
      newText = newText.substring(0, 7) + '-' + newText.substring(7);
    }

    // 返回格式化後的文本
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
