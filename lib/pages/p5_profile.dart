import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FitnessGoalScreen extends StatefulWidget {
  @override
  _FitnessGoalScreenState createState() => _FitnessGoalScreenState();
}

class _FitnessGoalScreenState extends State<FitnessGoalScreen> {
  // 預設值
  DateTime? _selectedDate;
  double _targetWeight = 60.0;
  double _targetBodyFat = 20.0;
  double _currentWeight = 75.0;
  double _currentBodyFat = 25.0;

  // 檢核點資料
  List<Map<String, dynamic>> _check = [];
  List<Map<String, dynamic>> _records = [];

  // 輸入框控制器
  TextEditingController _dateController = TextEditingController();
  TextEditingController _weightController = TextEditingController();
  TextEditingController _bodyFatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData(); // 加載資料
  }

  // 加載資料：從 SharedPreferences 讀取
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // 讀取目標資料
    final String? targetDate = prefs.get('targetDate').toString();
    final String? targetWeight = prefs.get('targetWeight').toString();
    final String? targetBodyFat = prefs.get('targetBodyFat').toString();

    if (targetDate != null) {
      setState(() {
        _dateController.text = targetDate;
        _selectedDate = DateTime.parse(targetDate);
      });
    }
    if (targetWeight != null) {
      setState(() {
        _targetWeight = double.tryParse(targetWeight) ?? _targetWeight;
      });
    }
    if (targetBodyFat != null) {
      setState(() {
        _targetBodyFat = double.tryParse(targetBodyFat) ?? _targetBodyFat;
      });
    }

    // 讀取檢核點資料
    final String? checkPoint = prefs.getString('checkpoint');
    if (checkPoint != null) {
      final List<dynamic> decodedRecords = jsonDecode(checkPoint);
      setState(() {
        _check.clear();
        _check.addAll(
            decodedRecords.map((check) => Map<String, dynamic>.from(check)));
      });
    }

    final String? recordData = prefs.getString('records');
    if (recordData != null) {
      final List<dynamic> decodedRecords = jsonDecode(recordData);
      setState(() {
        _records.clear();
        _records.addAll(
            decodedRecords.map((record) => Map<String, dynamic>.from(record)));
      });
      _updateCurrentValues();
    }
  }

  // 儲存資料：儲存開始日期、目標體重、目標體脂率到 SharedPreferences
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('targetDate', _dateController.text);
    await prefs.setDouble('targetWeight', _targetWeight);
    await prefs.setDouble('targetBodyFat', _targetBodyFat);
  }

  // 儲存檢核點資料到 SharedPreferences
  Future<void> _saveCheckpoints() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedRecords = jsonEncode(_check);
    await prefs.setString('check_point', encodedRecords);
  }

  // 根據最近的記錄更新當前體重與體脂肪
  void _updateCurrentValues() {
    if (_records.isNotEmpty) {
      _records.sort((a, b) => b['date'].compareTo(a['date']));
      var latestRecord = _records.first;
      setState(() {
        print("=========="+latestRecord['weight'].toString()+"__"+latestRecord['bodyFat'].toString());
        _currentWeight = latestRecord['weight'];
        _currentBodyFat = latestRecord['bodyFat'];
      });
    }
  }

  // 計算距開始日期的天數
  int _getDaysUntilTarget() {
    if (_selectedDate != null) {
      return _selectedDate!.difference(DateTime.now()).inDays;
    }
    return 0;
  }

  // 新增檢核點
  void _addCheckpoint() {
    if (_weightController.text.isNotEmpty &&
        _bodyFatController.text.isNotEmpty &&
        _selectedDate != null) {
      setState(() {
        _check.add({
          'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
          'weight': double.tryParse(_weightController.text) ?? 0.0,
          'bodyFat': double.tryParse(_bodyFatController.text) ?? 0.0,
        });
      });
      _saveCheckpoints(); // 儲存檢核點資料
      _weightController.clear();
      _bodyFatController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('個人目標')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 開始日期
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _dateController,
                      decoration: InputDecoration(labelText: '開始日期'),
                      keyboardType: TextInputType.datetime,
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2101),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            _selectedDate = pickedDate;
                            _dateController.text =
                                DateFormat('yyyy-MM-dd').format(pickedDate);
                          });
                          _saveData(); // 儲存開始日期
                        }
                      },
                    ),
                  ),
                  SizedBox(width: 10),
                  Text('距今 ${_getDaysUntilTarget()} 天'),
                ],
              ),
              SizedBox(height: 20),

              // 目標體重與體脂率
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(labelText: '目標體重(kg):' + _targetWeight.toString()),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _targetWeight = double.tryParse(value) ?? _targetWeight;
                        });
                        _saveData(); // 儲存目標體重
                      },
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(labelText: '目標體脂率(%):' + _targetBodyFat.toString()),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _targetBodyFat = double.tryParse(value) ?? _targetBodyFat;
                        });
                        _saveData(); // 儲存目標體脂率
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // 顯示體重和體脂率差距
              Text(
                '體重差距: ${(_currentWeight - _targetWeight).toStringAsFixed(1)} kg',
                style: TextStyle(fontSize: 18),
              ),
              Text(
                '體脂率差距: ${(_currentBodyFat - _targetBodyFat).toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 20),

              // 分隔線
              Divider(),

              // 檢核點列表
              Text(
                '檢核點',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              // Wrap the ListView.builder with Expanded
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _check.length,
                  itemBuilder: (context, index) {
                    var record = _check[index];
                    return ListTile(
                      title: Text('${record['date']}'),
                      subtitle: Text(
                          '體重: ${record['weight']} kg, 體脂: ${record['bodyFat']}%'),
                    );
                  },
                ),
              ),
            ],
          ),
      ),
      // 浮動按鈕新增檢核點
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('新增檢核點'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _dateController,
                      decoration: InputDecoration(labelText: '檢核日期'),
                      keyboardType: TextInputType.datetime,
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2101),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            _selectedDate = pickedDate;
                            _dateController.text =
                                DateFormat('yyyy-MM-dd').format(pickedDate);
                          });
                          _saveData(); // 儲存開始日期
                        }
                      },
                    ),
                    TextField(
                      controller: _weightController,
                      decoration: InputDecoration(labelText: '體重(kg)'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: _bodyFatController,
                      decoration: InputDecoration(labelText: '體脂率(%)'),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('取消'),
                  ),
                  TextButton(
                    onPressed: () {
                      _addCheckpoint();
                      Navigator.pop(context);
                    },
                    child: Text('儲存'),
                  ),
                ],
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
