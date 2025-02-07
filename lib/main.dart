import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';
import 'mycolor.dart';
import 'dart:async';
import 'dart:math';
import 'filepicker.dart';
import 'myiconbutton.dart';

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
  String appbar_message="AutoPlayer";
  double appbar_message_size=25;

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
  Timer timer=Timer.periodic(Duration(milliseconds: 1000), (timer) async {});

  void update_appbar_status(){
    if (isplay){
      setState(() {
        appbar_message="${file_pick_result.data.keys.elementAt(sheet_count)}（${play_count+1}/${shuffled_urllist.length}）";
        if (appbar_message.length>15){
          appbar_message_size=375.0/appbar_message.length;
        }else{
          appbar_message_size=25;
        }
      });
    }else{
      setState(() {
        appbar_message_size=25;
        appbar_message="AutoPlayer";
      });
    }
  }
  
  @override
    void initState() {
      super.initState();

      controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted) // JavaScript有効化
        ..loadRequest(Uri.parse("https://m.youtube.com")) // YouTubeのモバイル版を開く
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) async {
              timer.cancel();
              if (!isautoplay){
                controller.runJavaScript("""document.querySelector("video").pause();""");//自動再生オフにしたい場合はこれ！
              }

              Future<double> getDuration()async{
                Object result= await controller.runJavaScriptReturningResult('document.querySelector("video").duration.toString();');
                // 結果を String に変換し、不要な文字を削除
                String durationStr = result.toString().replaceAll(RegExp(r'[^0-9.]'), '');

                // String を double に変換
                return double.tryParse(durationStr) ?? 0.0;
              }

              if (isplay){
                trigger=false;
                timer = Timer.periodic(Duration(milliseconds: 800), (timer) async {
                  if (!isplay){
                    timer.cancel();
                  }
                  double duration = await getDuration();
                  debugPrint("/////$duration/////"*100);
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

                    void NextMusic(){
                      play_count++;
                      if (play_count>=urllist.length){//曲が最後まで言ったら
                        play_count=0;
                        //リストが２つ以上だったら次のリストの再生準備（リスト取得、シャッフル）。逆にリストが１つだったらそのリストをシャッフルせずに再生し続ける。                        
                        if (file_pick_result.data.keys.length>1){
                          sheet_count++;
                          if (sheet_count>=file_pick_result.data.keys.length){
                            sheet_count=0;
                          }
                          urllist=GetURLList(file_pick_result.data,sheet_count);
                          shuffled_urllist=shufflePlaylistWithRandomValues(urllist);
                        }
                      }
                      //次に流す曲の情報を更新
                      update_appbar_status();
                      controller.loadRequest(Uri.parse(shuffled_urllist[play_count][0]));
                    }
                    
                    if (currentTimer>shuffled_urllist[play_count][1] || (duration!=0.0 && duration-1.6<currentTimer)){
                      timer.cancel();
                      NextMusic();
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

    void ControlMusic()async{
      if (!isplay) {
        setState(() {
          isplay=true;
        });
        urllist=GetURLList(file_pick_result.data,sheet_count);
        shuffled_urllist=shufflePlaylistWithRandomValues(urllist);
        update_appbar_status();
        controller.loadRequest(Uri.parse(shuffled_urllist[play_count][0]));
      }else{
        setState(() {
          isplay=false;
        });
        controller.loadRequest(Uri.parse("https://m.youtube.com"));
      }
      
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: MyColor.primary,
        title: Text(appbar_message,style: TextStyle(fontSize: appbar_message_size,),),
        actions: [
          StartMusicButton(file_pick_result.success,isplay, ControlMusic),
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