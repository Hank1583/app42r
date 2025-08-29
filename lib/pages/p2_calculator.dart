import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CalculatorPage extends StatefulWidget {
  @override
  _CalculatorPageState createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  final TextEditingController _weightController = TextEditingController(text: "85"); // 預設體重 85
  double _proteinMin = 1.5;
  double _proteinMax = 2.0;
  double? _minProteinIntake;
  double? _maxProteinIntake;
  String? _errorMessage;

  final List<Map<String, dynamic>> _foods = [
    {"name": "蛋白粉", "protein": 25.0, "portion": 0},
    {"name": "豆漿", "protein": 3.3, "portion": 0},
    {"name": "雞蛋", "protein": 7.0, "portion": 0},
    {"name": "雞胸肉", "protein": 20.0, "portion": 0},
    {"name": "豆腐", "protein": 8.0, "portion": 0},
    {"name": "其他", "protein": 1.0, "portion": 0},
  ];

  @override
  void initState() {
    super.initState();
    _loadPortions();
    _weightController.addListener(_updateProteinIntake);
    _updateProteinIntake();
  }

  @override
  void dispose() {
    _weightController.removeListener(_updateProteinIntake);
    _weightController.dispose();
    super.dispose();
  }

  // 讀取儲存的份量
  Future<void> _loadPortions() async {
    final prefs = await SharedPreferences.getInstance();
    for (int i = 0; i < _foods.length; i++) {
      int? savedPortion = prefs.getInt('food_${_foods[i]['name']}_portion');
      if (savedPortion != null) {
        setState(() {
          _foods[i]['portion'] = savedPortion;
        });
      }
    }
  }

  // 儲存份量數據
  Future<void> _savePortions() async {
    final prefs = await SharedPreferences.getInstance();
    for (int i = 0; i < _foods.length; i++) {
      await prefs.setInt('food_${_foods[i]['name']}_portion', _foods[i]['portion']);
    }
  }

  void _updateProteinIntake() {
    final double? weight = double.tryParse(_weightController.text);
    setState(() {
      if (weight == null || weight <= 0) {
        _errorMessage = "請輸入有效的體重";
        _minProteinIntake = null;
        _maxProteinIntake = null;
      } else {
        _errorMessage = null;
        _minProteinIntake = weight * _proteinMin;
        _maxProteinIntake = weight * _proteinMax;
      }
    });
  }

  int _calculateFoodTotalProtein(Map<String, dynamic> food) {
    return (food['portion'] * food['protein']).toInt();
  }

  int _calculateDailyTotalProtein() {
    return _foods.fold(0, (total, food) => total + _calculateFoodTotalProtein(food));
  }

  double _calculateRemainingProtein() {
    final dailyTotal = _calculateDailyTotalProtein();
    return (_maxProteinIntake ?? 0) - dailyTotal;
  }

  void _incrementPortion(int index) {
    setState(() {
      _foods[index]['portion'] += 1;
    });
    _savePortions();  // 更新後儲存
  }

  void _decrementPortion(int index) {
    setState(() {
      if (_foods[index]['portion'] > 0) {
        _foods[index]['portion'] -= 1;
      }
    });
    _savePortions();  // 更新後儲存
  }

  void _clearPortions() {
    setState(() {
      for (var food in _foods) {
        food['portion'] = 0;
      }
    });
    _savePortions();  // 清除後儲存
  }

  @override
  Widget build(BuildContext context) {
    final remainingProtein = _calculateRemainingProtein();
    final dailyTotalProtein = _calculateDailyTotalProtein();

    return Scaffold(
      appBar: AppBar(title: Text('蛋白質計算機')),
      body: SingleChildScrollView(  // Wrap the entire body in SingleChildScrollView
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "輸入體重 (kg)",
                border: OutlineInputBorder(),
                errorText: _errorMessage,
              ),
            ),
            SizedBox(height: 20),
            if (_minProteinIntake != null && _maxProteinIntake != null)
              Text(
                "每天所需蛋白質量：\n${_minProteinIntake!.toStringAsFixed(1)} - ${_maxProteinIntake!.toStringAsFixed(1)} 克",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            SizedBox(height: 20),
            Divider(),
            Text(
              "蛋白質分配",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              itemCount: _foods.length,
              itemBuilder: (context, index) {
                final food = _foods[index];
                return Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        food['name'],
                        textAlign: TextAlign.left,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${food['protein']} 克/份',
                        textAlign: TextAlign.left,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove),
                            onPressed: () => _decrementPortion(index),
                          ),
                          SizedBox(
                            width: 40,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              onChanged: (value) {
                                setState(() {
                                  food['portion'] = int.tryParse(value) ?? 0;
                                });
                                _savePortions();  // 即時保存
                              },
                              controller: TextEditingController(
                                text: food['portion'].toString(),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () => _incrementPortion(index),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${_calculateFoodTotalProtein(food)} 克',
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                );
              },
            ),
            Divider(),
            Text(
              "每日蛋白質總計：$dailyTotalProtein 克",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  remainingProtein > 0
                      ? "還需蛋白質：${remainingProtein.toStringAsFixed(1)} 克"
                      : "蛋白質已達標！",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: remainingProtein > 0 ? Colors.red : Colors.green,
                  ),
                ),
                ElevatedButton(
                  onPressed: _clearPortions,
                  child: Text("清除"),
                ),
              ],
            ),
          ],
        ),
      ),
    );

  }
}
