import 'package:flutter/material.dart';
import 'package:yoyo_player/yoyo_player.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool fullscreen = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Material App',
      home: Scaffold(
        appBar: fullscreen == false
            ? AppBar(
                backgroundColor: Colors.blue,
                title: Image(
                  image: AssetImage('image/yoyo_logo.png'),
                  fit: BoxFit.fitHeight,
                  height: 50,
                ),
                centerTitle: true,
              )
            : null,
        body: Column(
          children: [
            YoYoPlayer(
              aspectRatio: 16 / 9,
              urls:
                  ["https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4",
                  "http://d3rlna7iyyu8wu.cloudfront.net/skip_armstrong/skip_armstrong_multi_language_subs.m3u8",
                  "http://sample.vodobox.com/we_are_blood_4k/we_are_blood_4k.m3u8"],
              videoStyle: VideoStyle(),
              onPlaying: (url){
                //print("Currently playing: $url");
              },
              videoLoadingStyle: VideoLoadingStyle(
                loading: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image(
                        image: AssetImage('image/yoyo_logo.png'),
                        fit: BoxFit.fitHeight,
                        height: 50,
                      ),
                      Text("Loading video"),
                    ],
                  ),
                ),
              ),
              onPlayEnd: (){
                print("Play finished");
              },
              onFullScreen: (t) {
                setState(() {
                  fullscreen = t;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
