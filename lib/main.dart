import 'package:flutter/material.dart';
import 'dart:developer';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:webview_flutter/webview_flutter.dart';
//import 'package:webview_flutter_plus/webview_flutter_plus.dart';
import 'package:flutter/services.dart';
import 'mycolor.dart';
import 'dart:async';


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
  const MyApp({Key? key}) : super(key: key);

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

  String? fileName="未選択";
  Map<String, List<List<dynamic>>> excelData = {};
  int sheetnum=0;
  bool isload=false;
  bool isplay=false;

  int play_count=0;

  String url_now="";
  int sec_now=0;

  List urllist=[
    ["https://youtu.be/09vT1DxxEcc?t=0",30],
    ["https://youtu.be/TYQkEbI8p-Y?t=0",30],
    ["https://youtu.be/lv29JX3ttLE?t=0",7]
  ];

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
        //..setUserAgent("Mozilla/5.0 (Linux; Android 10; Pixel 4 XL) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36") // PC版を開く
        ..loadRequest(Uri.parse("https://m.youtube.com")) // YouTubeのモバイル版を開く
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) async {
              if (isplay){
                trigger=false;
                //Future.delayed(Duration(milliseconds: 600), () {controller.runJavaScript('document.querySelector("video").muted = false;',);});
                Timer? timer =Timer.periodic(Duration(milliseconds: 500), (timer) async {
                  var current_timer= await controller.runJavaScriptReturningResult('document.querySelector("video").currentTime;');
                  debugPrint("$current_timer");
                  if (current_timer is double){
                    if (current_timer<0.6 && !trigger){
                      trigger=true;
                      controller.runJavaScript('document.querySelector("video").pause();',);
                    }
                    if (current_timer>urllist[play_count][1]){
                      play_count++;
                      if (play_count>=urllist.length){
                        play_count=0;
                      }
                      controller.loadRequest(Uri.parse(urllist[play_count][0]));
                      timer.cancel();
                    }
                  }  // トリガーが true の間は関数を実行
                });
              }
            }
          )
        );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    Future<void> pickFile() async {

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        allowMultiple: false,
        withData: true,
      );

      if (result!=null){
        PlatformFile file = result.files.first;
        setState(() {
          fileName = file.name; // ファイル名を保存
        });

        // Excelファイルを読み取る
        Uint8List? fileBytes = file.bytes;
        if (fileBytes != null){
          try {
            final Excel excel = Excel.decodeBytes(fileBytes);
            Map<String, List<List<dynamic>>> tempData = {};

            // Excelファイル内のデータを読み取る
            for (var table in excel.tables.keys) {
              List<List<dynamic>> rows = [];

              for (var row in excel.tables[table]!.rows) {
                List<dynamic> convertedRow = [];

                for (int colIndex = 0; colIndex < row.length; colIndex++) {
                  var cell = row[colIndex];
                  if (cell?.value != null) {
                    var value = cell?.value;
                    if (colIndex==0){
                      convertedRow.add(value.toString());
                    }else{
                      convertedRow.add(value);
                    }
                  
                  } else {
                    convertedRow.add("");  // セルがnullの場合は空文字列を追加
                  }
                }
                bool isEmptyRow = (convertedRow[0]=="" || convertedRow[1]=="" || convertedRow[2]=="");
                if (!isEmptyRow) {
                  rows.add(convertedRow);
                }
              }
              debugPrint("$rows");
              tempData[table] = rows; // シート名をキーにしてデータを保存
            }

            setState(() {
              excelData = tempData; // ファイル内容を保存
              sheetnum = tempData.keys.length;
              isload=true;
            });
            ScaffoldMessenger.of(context).showSnackBar(snackBar);

          }catch (e, stackTrace) {
            debugPrint("読み込めませんでした");
          }
          
        }else{
          debugPrint("読み込めませんでした");
        }
      }

      debugPrint("読み込めませんでした");

    }

    

    return Scaffold(
      appBar: AppBar(
        backgroundColor: MyColor.primary,
        title: Text("$url_now：$sec_now"),
        actions: [
          Visibility(
                visible: isload,
                child:IconButton(
                  onPressed: ()async{
                    final cookies = await controller.runJavaScriptReturningResult(
                      'document.cookie',
                    );
                    debugPrint("$cookies");
                    setState(() {
                      isplay=true;
                    });
                    play_count++;
                    controller.loadRequest(Uri.parse(urllist[play_count][0]));
                  }, 
                  icon: Icon(Icons.play_arrow_outlined)
                )
          ),
          IconButton(onPressed: pickFile, icon: Icon(Icons.file_copy)),
          ],
      ),
      body: Center(
        child:Column(
          mainAxisAlignment:MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: isload
              ?WebViewWidget(controller: controller,)
              :Text("ファイルを選択してください"),
            ),
          ],
        ),
      ),
    );
  }
}