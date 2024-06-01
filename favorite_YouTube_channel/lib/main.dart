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
      title: 'Favorite YouTube Channel',
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
  TextEditingController _pathController = TextEditingController();
  String path = "";

  Map<String, dynamic> _searchResult = {
    "name": null,
    "icon": null,
    "fans": null,
    "id": null,
  };

  List<Map<String, dynamic>> videoList = [];
  bool _isLoadingProfile = false; // 프로필 로딩 상태 변수
  bool _isLoadingVideos = false; // 영상 로딩 상태 변수
  bool _isDownloadingVideo = false; // 다운로드 로딩 상태 변수

  bool get _isLoading => _isLoadingProfile || _isLoadingVideos || _isDownloadingVideo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (path.isEmpty) {
        _showPathPrompt(context);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _performVideos(String id) async {
    setState(() {
      _isLoadingVideos = true; // 영상 로딩 시작
    });
    final url = Uri.parse('http://127.0.0.1:5000/youtube/videos?id=$id');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        List<String> titles = (jsonResponse["title"] as List).cast<String>();
        List<String> thumbnails = (jsonResponse["img"] as List).cast<String>();
        List<String> urls = (jsonResponse["url"] as List).cast<String>();

        setState(() {
          videoList.clear();
          for (int i = 0; i < titles.length; i++) {
            videoList.add({
              "title": titles[i],
              "thumbnail": thumbnails[i],
              "url": urls[i],
            });
          }
          _isLoadingVideos = false; // 영상 로딩 완료
        });
      } else {
        throw Exception('Failed to load video list');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _isLoadingVideos = false; // 오류 발생 시 로딩 상태 해제
      });
    }
  }

  Future<void> _performDownload(String _url, String path) async {
    setState(() {
      _isDownloadingVideo = true; // 다운로드 로딩 시작
    });
    final url = Uri.parse('http://127.0.0.1:5000/youtube/download?url=$_url&path=$path');
    try {
      final response = await http.get(url);
      setState(() {
        _isDownloadingVideo = false; // 다운로드 완료 시 로딩 상태 해제
      });
    } catch (e) {
      print('Error: $e');
      setState(() {
        _isDownloadingVideo = false; // 오류 발생 시 로딩 상태 해제
      });
    }
  }

  Future<void> _performSearch(String query) async {
    if (path.isEmpty) {
      // 경로가 설정되지 않은 경우 설정 탭으로 이동
      DefaultTabController.of(context)?.animateTo(1);
      return;
    }

    setState(() {
      _isLoadingProfile = true; // 검색 시작 시 프로필 로딩 상태로 변경
    });

    final queryEncoded = Uri.encodeComponent(query);
    final url = Uri.parse('http://127.0.0.1:5000/youtube/search?title=$queryEncoded');
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
          _isLoadingProfile = false; // 검색 완료 시 프로필 로딩 상태 해제
        });

        if (_searchResult["id"] != null) {
          await _performVideos(_searchResult["id"]);
        }
      } else {
        throw Exception('Failed to load search result');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _isLoadingProfile = false; // 오류 발생 시 로딩 상태 해제
      });
    }
  }

  void openVideoUrl(String url) {
    if (url != null) {
      _performDownload(url, path); // 다운로드할 비디오 URL과 저장 경로 전달
    }
  }

  void _showPathPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('경로를 설정하세요'),
          content: Text('검색을 하기 전에 다운로드 경로를 설정해주세요.'),
          actions: [
            TextButton(
              child: Text('설정'),
              onPressed: () {
                Navigator.of(context).pop();
                DefaultTabController.of(context)?.animateTo(1);
              },
            ),
          ],
        );
      },
    );
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
                Tab(icon: Icon(Icons.settings), text: '설정'),
              ],
            ),
          ),
          body: Stack(
              children: [
          TabBarView(
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
      await _performSearch
        (query);
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
                child: SizedBox(
                  height: 250.0, // 이미지 크기를 키움
                  child: ListView.separated(
                    itemCount: videoList.length,
                    separatorBuilder: (context, index) => Divider(),
                    itemBuilder: (context, index) {
                      Map<String, dynamic> videoData = videoList[index];
                      return ListTile(
                        contentPadding: EdgeInsets.all(8.0), // 내용 패딩을 추가하여 여백을 조절
                        leading: Container(
                          width: 150.0, // 이미지 컨테이너의 너비를 조절
                          height: double.infinity, // 이미지를 컨테이너의 높이에 맞게 조절
                          child: Image.network(
                            videoData["thumbnail"] as String,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(
                          videoData["title"] as String,
                          style: TextStyle(fontSize: 18.0), // 제목 텍스트의 크기를 조절
                        ),
                        onTap: () {
                          openVideoUrl(videoData["url"]);
                        },
                      );
                    },
                  ),
                ),
              ),

            ],
          ),
          ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _pathController,
                    decoration: InputDecoration(
                      hintText: '저장 경로를 입력하세요',
                    ),
                    onChanged: (value) {
                      // 경로 입력 시 \를 /로 변경
                      setState(() {
                        path = value.replaceAll(r'\', '/');
                      });
                    },
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        path = _pathController.text.replaceAll(r'\', '/');
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('저장 경로가 설정되었습니다.')),
                      );
                    },
                    child: Text('경로 설정'),
                  ),
                ],
              ),
            ),
          ],
          ),
                if (_isLoading) // 로딩 상태일 때 로딩 팝업 표시
                  Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue), // 파란색 회전 원
                    ),
                  ),
              ],
          ),
        ),
    );
  }
}
