import 'package:flutter/material.dart';
import 'package:flutter_42r/pages/p1_record.dart';
import 'package:flutter_42r/pages/p2_calculator.dart';
import 'package:flutter_42r/pages/p3_recipe.dart';
import 'package:flutter_42r/pages/p4_knowledge.dart';
import 'package:flutter_42r/pages/p5_profile.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue, // 設定主要色調為藍色
        scaffoldBackgroundColor: Colors.blue[50], // 調整背景為淡藍色
      ),
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    RecordPage(),
    CalculatorPage(),
    RecipePage(),
    KnowledgeListPage(),
    FitnessGoalScreen(),
  ];

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
        selectedItemColor: Colors.blue[800], // 選中項目顏色為深藍色
        unselectedItemColor: Colors.blue[300], // 未選中項目顏色為淺藍色
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: '紀錄'),
          BottomNavigationBarItem(icon: Icon(Icons.calculate), label: '計算機'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: '食譜'),
          BottomNavigationBarItem(icon: Icon(Icons.library_books), label: '百科'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}
