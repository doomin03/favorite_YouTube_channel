import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'favorite YouTube channel',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController _searchController = TextEditingController();
  Map<String, dynamic> _searchResult = {
    "name": null,
    "icon": null,
    "fans": null,
    "id": null,
  };

  Future<void> _performSearch(String query) async {
    final queryEncoded = Uri.encodeComponent(query);
    final url =
        Uri.parse('http://127.0.0.1:5000/youtube/search?title=$queryEncoded');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      setState(() {
        _searchResult = {
          "name": jsonResponse["name"],
          "icon": jsonResponse["icon"],
          "fans": jsonResponse["fans"],
          "id": jsonResponse["id"],
        };
      });
      print(_searchResult["icon"]);
    } else {
      throw Exception('Failed to load search result');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text("최애 유튜브"),
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.search), text: '검색'),
              Tab(
                icon: Icon(Icons.settings),
                text: '설정',
              )
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 첫 번째 탭
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: '검색어를 입력하세요',
                          ),
                        ),
                      ),
                      SizedBox(width: 10), // 간격 추가
                      ElevatedButton(
                        onPressed: () {
                          String query = _searchController.text;
                          _performSearch(query);
                        },
                        child: Text('검색'),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_searchResult["icon"] != null)
                      // 아이콘이 있는 경우 이미지를 표시
                        CircleAvatar(
                          backgroundImage: NetworkImage(_searchResult["icon"]!),
                          radius: 50, // 반지름 설정
                        ),
                      Column(
                        children: [
                          if (_searchResult["name"] != null)
                            Text(_searchResult["name"]),

                          if (_searchResult["fans"] != null)
                            Text(_searchResult["fans"]), // 텍스트를 빈 문자열로 표시하는 텍스트 위젯
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),
            // 두 번째 탭
            Container(),
          ],
        ),
      ),
    );
  }
}
