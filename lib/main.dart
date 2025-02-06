import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';
import 'mycolor.dart';
import 'dart:async';
import 'dart:math';
import 'filepicker.dart';
import 'myiconbutton.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    // 縦向き
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Colors.blue,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Colors.blue,
        ),
      ),
      themeMode: ThemeMode.dark,
      initialRoute: '/',
      routes: {
        '/':(context)=>InitPage(title: 'MyPlayer'),
      },
    );
  }
}

class InitPage extends StatefulWidget {
  const InitPage({super.key, required this.title});

  final String title;

  @override
  State<InitPage> createState() => InitPageState();
}

class InitPageState extends State<InitPage> {
  List<List<dynamic>> PlayList=[];

  bool isplay=false;
  bool isautoplay=true;

  ({Map<String, List<List<dynamic>>> data, bool success, String message}) file_pick_result = 
    (data: {}, success: false, message: "まだファイルが選択されていません");

  String snack_message="";

  int play_count=0;
  int sheet_count=0;

  String url_now="";
  int sec_now=0;

  List<List<dynamic>> urllist=[];
  List<List<dynamic>> shuffled_urllist=[];

  late WebViewController controller;

  final snackBar = SnackBar(
            content: const Text('リストを読み込みました！'),
            //action: SnackBarAction(label: 'Undo',onPressed: () {},),
          );

  int current_timer=0;
  bool trigger=false;
  
  @override
    void initState() {
      super.initState();

      controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted) // JavaScript有効化
        ..loadRequest(Uri.parse("https://m.youtube.com")) // YouTubeのモバイル版を開く
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) async {
              if (!isautoplay){
                controller.runJavaScript("""document.querySelector("video").pause();""");//自動再生オフにしたい場合はこれ！
              }
              if (isplay){
                trigger=false;
                Timer? timer =Timer.periodic(Duration(milliseconds: 800), (timer) async {
                  var currentTimer= await controller.runJavaScriptReturningResult('document.querySelector("video").currentTime;');
                  debugPrint("$currentTimer");
                  if (currentTimer is double){
                    if (!trigger){
                      trigger=true;
                      if (currentTimer>1){
                        controller.runJavaScript('document.querySelector("video").currentTime=0;',);
                        currentTimer=0;
                      }
                    }
                    if (currentTimer>shuffled_urllist[play_count][1]){
                      play_count++;
                      if (play_count>=urllist.length){
                        play_count=0;
                      }
                      controller.loadRequest(Uri.parse(shuffled_urllist[play_count][0]));
                      timer.cancel();
                    }
                  }
                });
              }
            }
          )
        );
  }


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    List<List<dynamic>> GetURLList(eList,count){
      return eList[eList.keys.elementAt(count)];
    }

    List<List<dynamic>> shufflePlaylistWithRandomValues(List<List<dynamic>> urllist) {
      var random = Random();

      debugPrint("$urllist");
      // 各要素についてランダムな値を生成
      List<List<dynamic>> newurllist = urllist.map((item) {
        double randomValue = random.nextDouble() * (item[2].value - item[1].value) + item[1].value; // item[1] と item[2] の間のランダムな値
        return [item[0], randomValue];
      }).toList();

      // リストをシャッフル
      newurllist.shuffle(random);

      return newurllist;
    } 

    void FilePick()async{
      var result= await pickFile();
      setState(() {
        file_pick_result = result;
        snack_message=result.message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(snack_message),
          //action: SnackBarAction(label: 'Undo',onPressed: () {},),
        ));
    }

    void StartMusic()async{
      setState(() {
        isplay=true;
      });
      urllist=GetURLList(file_pick_result.data,sheet_count);
      shuffled_urllist=shufflePlaylistWithRandomValues(urllist);
      debugPrint("$shuffled_urllist");
      controller.loadRequest(Uri.parse(shuffled_urllist[play_count][0]));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: MyColor.primary,
        title: Text("AutoPlayer"),
        actions: [
          StartMusicButton(file_pick_result.success, StartMusic),
          FilePickButton(FilePick),
          ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            file_pick_result.success
              ? Expanded(
                  child: WebViewWidget(controller: controller),
                )
              : Text("ファイルを選択してください"),
          ],
        ),
      ),
    );
  }
}