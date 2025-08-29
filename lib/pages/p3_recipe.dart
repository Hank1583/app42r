import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RecipePage extends StatefulWidget {
  @override
  _RecipePageState createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  String _recipe = "";
  TextEditingController _controller = TextEditingController();
  String _selectedRecipe = 'R2';
  bool _isLoading = false;
  Map<String, List<Map<String, String>>> _recipesByCategory = {}; // 儲存每個分類的食譜列表
  bool _hasFetchedData = false; // 確保已經抓取過資料

  @override
  void initState() {
    super.initState();
    _fetchInitialRecipes(); // 加載初始食譜資料
  }

  Future<void> _fetchInitialRecipes() async {
    setState(() {
      _isLoading = true;
    });

    final url =
        'https://www.highlight.url.tw/app_42r/get_recipe.php?userid=hank';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          // 如果返回的資料不是空的，將資料根據分類存儲
          setState(() {
            _recipesByCategory = _organizeRecipesByCategory(data);
            _hasFetchedData = true;
            _isLoading = false;
          });
        } else {
          // 如果回傳空資料，顯示提示訊息
          setState(() {
            _hasFetchedData = true;
            _recipe = '沒有找到食譜資料。';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _recipe = '無法加載食譜資料，請稍後再試。';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _recipe = '錯誤: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> fetchRecipe(String userInput, String recipeType) async {
    setState(() {
      _isLoading = true; // 顯示 loading
    });
    String title = '食譜: $userInput';
    final String googleApiKey =
        'AIzaSyD34tF46F9ZeUJ-HowYWDjdpCh0xOwCB9g'; // Replace with your actual API key
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$googleApiKey');

    final headers = {'Content-Type': 'application/json'};

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': title} // 使用選擇的食譜類型與輸入的食材
          ]
        }
      ]
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          _recipe = data['candidates'][0]['content']['parts'][0]['text'] ??
              'No Recipe generated.';
          _isLoading = false;
        });
        if (_recipe != 'No Recipe generated.') {
          // 成功獲取食譜後，將數據發送到伺服器
          _sendRecipeToServer(userInput, title, _recipe, recipeType);
        }
        // 生成食譜後，跳轉到下一個頁面顯示食譜
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  RecipeResultPage(title: title, recipe: _recipe)),
        );
      } else {
        setState(() {
          _recipe =
              'Failed to generate recipe. Status Code: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _recipe = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _sendRecipeToServer(
      String userInput, String title, String recipe, String category) async {
    final String url = 'https://www.highlight.url.tw/app_42r/send_recipe.php';
    final Map<String, String> params = {
      'userid': 'hank', // 固定userid為hank，根據需求改變
      'title': title,
      'food': userInput,
      'recipe': recipe,
      'category': category,
    };

    try {
      final response = await http.post(Uri.parse(url), body: params);
      if (response.statusCode == 200) {
        // 可以選擇在這裡處理成功的情況
        print('Recipe sent successfully!');
      } else {
        print('Failed to send recipe. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending recipe: $e');
    }
  }

  Map<String, List<Map<String, String>>> _organizeRecipesByCategory(
      dynamic data) {
    Map<String, List<Map<String, String>>> organizedRecipes = {};

    for (var recipe in data) {
      String category = recipe['category']; // 假設每個食譜有 'category' 這個欄位
      String recipeName = recipe['title']; // 假設每個食譜有 'title' 這個欄位
      String recipeContent =
          recipe['recipe']; // 假設每個食譜有 'recipe' 這個欄位，代表食譜的內容或說明

      // 準備每個食譜資料，將其分組並加入 'recipe' 欄位
      Map<String, String> recipeData = {
        'title': recipeName,
        'recipe': recipeContent,
      };

      // 如果已經存在這個類別，則將新的食譜資料加入到對應的類別中
      if (organizedRecipes.containsKey(category)) {
        organizedRecipes[category]?.add(recipeData);
      } else {
        // 否則創建一個新的類別，並將食譜資料放入其中
        organizedRecipes[category] = [recipeData];
      }
    }

    return organizedRecipes;
  }

  // 顯示建立食譜的彈出視窗
  void _showCreateRecipeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('建立食譜'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 下拉選單
              DropdownButton<String>(
                value: _selectedRecipe,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedRecipe = newValue!;
                  });
                },
                items: <String>['R2', 'R3', 'R4']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              // 食材輸入框
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: '請輸入食材',
                ),
              ),
            ],
          ),
          actions: [
            // 取消按鈕
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            // 產生食譜按鈕
            TextButton(
              onPressed: () {
                if (_controller.text.isNotEmpty) {
                  Navigator.of(context).pop();
                  fetchRecipe(_controller.text, _selectedRecipe);
                } else {
                  // 如果沒有輸入食材，顯示錯誤提示
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('請輸入食材')),
                  );
                }
              },
              child: Text('AI產生食譜'),
            ),
          ],
        );
      },
    );
  }

  // 顯示食譜列表
  Widget _buildRecipeList() {
    if (!_hasFetchedData) {
      return Center(child: CircularProgressIndicator());
    }

    if (_recipesByCategory.isEmpty) {
      return Center(child: Text('沒有食譜資料。'));
    }

    return ListView(
      children: <Widget>[
        for (var category in ['R2', 'R3', 'R4'])
          if (_recipesByCategory[category]?.isNotEmpty ?? false)
            ExpansionTile(
              leading: Icon(Icons.menu_outlined),
              title: Text('$category 食譜'),
              children: _recipesByCategory[category]!
                  .map((recipe) => ListTile(
                        leading: Icon(Icons.bookmark_border),
                        title: Text(recipe['title']!),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => RecipeResultPage(
                                    title: recipe['title']!,
                                    recipe: recipe['recipe']!)),
                          );
                        },
                      ))
                  .toList(),
            ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('我的食譜')),
      body: _buildRecipeList(), // 顯示食譜列表或提示訊息
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateRecipeDialog,
        child: Icon(Icons.add),
        tooltip: 'Create Recipe',
      ),
    );
  }
}

// 顯示食譜結果的頁面
class RecipeResultPage extends StatelessWidget {
  final String title;
  final String recipe;

  RecipeResultPage({required this.recipe, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(height: 20),
            Text(
              recipe,
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
