import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class KnowledgeListPage extends StatefulWidget {
  @override
  _KnowledgeListPageState createState() => _KnowledgeListPageState();
}

class _KnowledgeListPageState extends State<KnowledgeListPage> {
  List<dynamic> knowledgeList = [];

  @override
  void initState() {
    super.initState();
    fetchKnowledge();
  }

  // 從 PHP API 抓取資料
  Future<void> fetchKnowledge() async {
    final url = 'https://www.highlight.url.tw/app_42r/get_knowledge.php';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      setState(() {
        knowledgeList = json.decode(response.body);
      });
    } else {
      // 處理錯誤
      print('Failed to load data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('百科'),
      ),
      body: ListView.builder(
        itemCount: knowledgeList.length,
        itemBuilder: (context, index) {
          var item = knowledgeList[index];
          return ListTile(
            leading: Icon(Icons.article),
            title: Text(item['title']),
            onTap: () {
              // 點選標題後跳轉到詳細頁面
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => KnowledgeDetailPage(item),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class KnowledgeDetailPage extends StatelessWidget {
  final dynamic item;

  KnowledgeDetailPage(this.item);

  Future<void> _launchURL(path) async {
    final Uri url = Uri.parse(path);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(item['title']),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item['title'],
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(item['content']),
            if (item['image'] != null && item['image'].isNotEmpty) ...[
              SizedBox(height: 16),
              Image.network(item['image']),
            ],
            if (item['link'] != null && item['link'].isNotEmpty) ...[
              SizedBox(height: 16),
              Center(
                  child: ElevatedButton(
                onPressed: () {
                  _launchURL(item['link']);
                },
                child: Text('相關連結'),
              )),
            ],
          ],
        ),
      ),
    );
  }
}
