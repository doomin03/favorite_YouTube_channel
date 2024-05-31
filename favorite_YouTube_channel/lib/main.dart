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

  List<Map<String, dynamic>> videoList = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performvideos(String id) async {
    final url = Uri.parse('http://127.0.0.1:5000/youtube/videos?id=$id');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        List<String> titles = jsonResponse["title"];
        List<String> thumbnails = jsonResponse["img"];
        List<String> urls = jsonResponse["url"];

        for (int i = 0; i < titles.length; i++) {
          videoList.add({
            "title": titles[i],
            "thumbnail": thumbnails[i],
            "url": urls[i],
          });
        }
        setState(() {});
      } else {
        throw Exception('Failed to load video list');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _performSearch(String query) async {
    final queryEncoded = Uri.encodeComponent(query);
    final url =
    Uri.parse('http://127.0.0.1:5000/youtube/search?title=$queryEncoded');
    try {
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

        if (_searchResult["id"] != null) {
          await _performvideos(_searchResult["id"]);
        }
      } else {
        throw Exception('Failed to load search result');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void openVideoUrl(Map<String, dynamic> videoData) {
    String? videoUrl = videoData["url"];
    print("Opening video URL: $videoUrl");
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
                      SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () async {
                          String query = _searchController.text;
                          await _performSearch(query);
                        },
                        child: Text('검색'),
                      ),
                    ],
                  ),
                  if (_searchResult["icon"] != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        backgroundImage: NetworkImage(_searchResult["icon"]!),
                        radius: 50,
                      ),
                    ),
                  if (_searchResult["name"] != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        _searchResult["name"],
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  if (_searchResult["fans"] != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        _searchResult["fans"],
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  Expanded(
                    child: ListView.separated(
                      itemCount: videoList.length,
                      separatorBuilder: (context, index) => Divider(),
                      itemBuilder: (context, index) {
                        Map<String, dynamic> videoData = videoList[index];
                        return ListTile(
                          leading: Image.network(videoData["img"] as String),
                          title: Text(videoData["title"] as String),
                          onTap: () {
                            openVideoUrl(videoData);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Container(),
          ],
        ),
      ),
    );
  }
}
