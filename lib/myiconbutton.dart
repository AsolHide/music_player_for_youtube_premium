import 'package:flutter/material.dart';

Widget StartMusicButton(bool isload,bool isplay, VoidCallback func) {
  return Visibility(
    visible: isload,
    child: TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.7, end: 1.0), // 0.8倍から1.0倍へアニメーション
      duration: Duration(milliseconds: 500), // 300ms かけて拡大
      curve: Curves.easeOutBack, // 少し弾むようなアニメーション
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: IconButton(
        onPressed: func,
        icon: isplay
        ?Icon(Icons.pause_outlined, size: 36, color: Colors.redAccent)
        :Icon(Icons.play_arrow_outlined, size: 36, color: Colors.greenAccent),
      ),
    ),
  );
}

Widget FilePickButton(VoidCallback func){
  return IconButton(
    onPressed: func, 
    icon: Icon(Icons.file_copy)
  );
}