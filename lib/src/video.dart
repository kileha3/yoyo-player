import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screen_wake/flutter_screen_wake.dart';
import 'package:orientation/orientation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock/wakelock.dart';
import 'package:http/http.dart' as http;
import 'package:yoyo_player/src/utils/utils.dart';
import 'package:yoyo_player/src/widget/widget_bottombar.dart';
import 'package:yoyo_player/yoyo_player.dart';
import 'model/audio.dart';
import 'model/m3u8.dart';
import 'model/m3u8s.dart';
import 'responses/regex_response.dart';
import 'widget/top_chip.dart';

class YoYoPlayer extends StatefulWidget {
  ///Video[source],
  ///```dart
  ///url:"https://example.com/index.m3u8";
  ///```
  final List<String> urls;

  Duration? seekToDuration;

  final VideoStyle? videoStyle;

  /// Video Loading Style
  final VideoLoadingStyle? videoLoadingStyle;

  /// Video AspectRatio [aspectRatio : 16 / 9 ]
  final double aspectRatio;

  /// video state fullScreen
  final void Function(bool fullScreenTurnedOn)? onFullScreen;

  final void Function(Duration playPosition)? onPlayerDurationChanged;

  /// video Type
  final void Function(String videoType)? onPlayingVideo;

  final void Function()? onPlayEnd; 

  final void Function(String url)? onPlaying; 

  final List<String> filterQuality;

  YoYoPlayer({
    Key? key,
    required this.urls,
    required this.aspectRatio,
    this.videoStyle,
    this.videoLoadingStyle,
    this.onFullScreen,
    this.onPlayingVideo,
    this.onPlayEnd,
    this.onPlaying,
    this.seekToDuration = const Duration(),
    this.filterQuality = const ["Auto","SD", "HD", "Full HD", "UHD", "4K"],
    this.onPlayerDurationChanged,
  }) : super(key: key);

  @override
  _YoYoPlayerState createState() => _YoYoPlayerState();
}

class _YoYoPlayerState extends State<YoYoPlayer>
    with SingleTickerProviderStateMixin {
  //video play type (hls,mp4,mkv,offline)
  String? playType;
  // Animation Controller
  late AnimationController controlBarAnimationController;
  // Video Top Bar Animation
  Animation<double>? controlTopBarAnimation;
  // Video Bottom Bar Animation
  Animation<double>? controlBottomBarAnimation;
  // Video Player Controller
  VideoPlayerController? controller;
  // Video init error default :false
  bool hasInitError = false;
  // Video Total Time duration
  Duration? videoDuration;
  // Video Seek to
  Duration? videoSeek = Duration(milliseconds: 0);

  //m3u8 data video list for user choice
  List<M3U8pass> yoyo = [];
  // m3u8 audio list
  List<AUDIO> audioList = [];
  // m3u8 temp data
  String? m3u8Content;
  // subtitle temp data
  String? subtitleContent;
  // menu show m3u8 list
  bool m3u8show = false;
  // video full screen
  bool fullScreen = false;
  // menu show
  bool showMenu = false;
  // auto show subtitle
  bool showSubtitles = false;
  // video status
  bool? offline;

  bool wasPlaying = false;

  int currentPlayingIndex = -1;

  late M3U8pass currentm3u8Data;

  // time for duration
  Timer? showTime;
  //Current ScreenSize
  Size get screenSize => MediaQuery.of(context).size;
  //
  @override
  void initState() {
    _playNext();
    super.initState();

    /// Control bar animation
    controlBarAnimationController = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    controlTopBarAnimation = Tween(begin: -(36.0 + 0.0 * 2), end: 0.0)
        .animate(controlBarAnimationController);
    controlBottomBarAnimation = Tween(begin: -(36.0 + 0.0 * 2), end: 0.0)
        .animate(controlBarAnimationController);
    var widgetsBinding = WidgetsBinding.instance!;

    widgetsBinding.addPostFrameCallback((callback) {
      widgetsBinding.addPersistentFrameCallback((callback) {
        if (context == null) return;
        var orientation = MediaQuery.of(context).orientation;
        bool? _fullscreen;
        if (orientation == Orientation.landscape) {
          //Horizontal screen
          _fullscreen = true;
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
        } else if (orientation == Orientation.portrait) {
          _fullscreen = false;
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        }
        if (_fullscreen != fullScreen) {
          setState(() {
            fullScreen = !fullScreen;
            _navigateLocally(context);
            if (widget.onFullScreen != null) {
              widget.onFullScreen!(fullScreen);
            }
          });
        }
        widgetsBinding.scheduleFrame();
      });
    });
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    FlutterScreenWake.keepOn(true);
  }

  _playNext({bool next = true}){
    currentPlayingIndex += next ? 1 : -1;

    if(currentPlayingIndex >= 0 && widget.urls.length >= currentPlayingIndex){
      final url = widget.urls[currentPlayingIndex];
      print("Current playing at $currentPlayingIndex");
      currentm3u8Data = M3U8pass(label: widget.filterQuality.first, dataURL: url);
      urlCheck(currentm3u8Data.dataURL!);
    }
  }

  @override
  void dispose() {
    m3u8clean();
    controller!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videoChildren = <Widget>[
      GestureDetector(
        onTap: () {
          toggleControls();
        },
        onDoubleTap: () {
          togglePlay();
        },
        child: ClipRect(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black,
            child: Center(
                child: AspectRatio(
              aspectRatio: controller!.value.aspectRatio,
              child: VideoPlayer(controller!),
            )),
          ),
        ),
      ),
    ];
    videoChildren.addAll(videoBuiltInChildren());
    return AspectRatio(
      aspectRatio: fullScreen
          ? calculateAspectRatio(context, screenSize)
          : widget.aspectRatio,
      child: controller != null && (controller!.value.isInitialized || controller!.value.isPlaying)
          ? Stack(children: videoChildren)
          : widget.videoLoadingStyle!.loading,
    );
  }

  /// Video Player ActionBar
  Widget actionBar() {
    return showMenu
        ? Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: 40,
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 5,
                  ),
                  topChip(
                    Text(currentm3u8Data.label!, style: widget.videoStyle!.qualitystyle.qualitystyle),
                    widget.videoStyle!.qualitystyle.qualityColor,
                    () {
                      // quality function
                      setState(() {
                        m3u8show = true;
                      });
                    },
                  ),
                  Container(
                    width: 10,
                  )
                ],
              ),
            ),
          )
        : Container();
  }

  Widget m3u8list() {
    yoyo.sort((data, _data) => data.qualityRank! - _data.qualityRank!);
    return m3u8show == true
        ? Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 40.0, right: 5),
              child: SingleChildScrollView(
                child: Column(
                  children: yoyo.map((e) => InkWell(
                            onTap: () {
                              m3u8show = false;
                              onSelectQuality(e);
                              },
                            child: Container(
                                width: 90,
                                color: widget.videoStyle!.qualitystyle.dropDownColor,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    "${e.label}",
                                    style: widget.videoStyle!.qualitystyle.dropDownText,
                                  ),
                                )),
                          ))
                      .toList(),
                ),
              ),
            ),
          )
        : Container();
  }

  List<Widget> videoBuiltInChildren() {
    return [
      actionBar(),
      btm(),
      m3u8list(),
    ];
  }

  Widget btm() {
    final lastIndex = widget.urls.length - 1;
    return showMenu
        ? bottomBar(
            controller: controller,
            spaceBetweenControls: widget.videoStyle!.spaceBetweenControls,
            videoSeekTo: videoSeek,
            videoDuration: videoDuration,
            videoStyle: widget.videoStyle,
            showMenu: showMenu,
            fullScreen: fullScreen,
            onSkipNext: (next) {
              togglePlay();
              _playNext(next: next);
            },
            showNext: lastIndex > currentPlayingIndex ,
            showPrevious: lastIndex >= currentPlayingIndex && currentPlayingIndex > 1,
            onFullScreen: () => toggleFullScreen(),
            onSeekChange: onSeekChanged,
            play: () => togglePlay())
        : Container();
  }

  void onSeekChanged(Duration duration){
    setState(() {
      videoSeek = duration;
    });
    controller?.seekTo(duration);
  }

  void urlCheck(String url) {
    final netRegex = new RegExp(r'^(http|https):\/\/([\w.]+\/?)\S*');
    final isNetwork = netRegex.hasMatch(url);
    final a = Uri.parse(url);
    if (isNetwork) {
      setState(() {
        offline = false;
      });
      if (a.pathSegments.last.endsWith("mkv")) {
        setState(() {
          playType = "MKV";
        });
        if (widget.onPlayingVideo != null) widget.onPlayingVideo!("MKV");

        videoControlSetup(url);
      } else if (a.pathSegments.last.endsWith("mp4")) {
        setState(() {
          playType = "MP4";
        });
        if (widget.onPlayingVideo != null) widget.onPlayingVideo!("MP4");
        videoControlSetup(url);
      } else if (a.pathSegments.last.endsWith("m3u8")) {
        setState(() {
          playType = "HLS";
        });

        if (widget.onPlayingVideo != null) widget.onPlayingVideo!("M3U8");
        setState(() {
          currentm3u8Data = M3U8pass(dataURL: url, 
          label: widget.filterQuality.first);
        });
        videoControlSetup(url);
        getM3U8(url);
      } else {
        videoControlSetup(url);
        getM3U8(url);
      }
    } else {
      setState(() {
        offline = true;
      });
      videoControlSetup(url);
    }
  }

// M3U8 Data Setup
  void getM3U8(String video) {
    if (yoyo.length > 0) {
      m3u8clean();
    }
    m3u8video(video);
  }

  Future<M3U8s> m3u8video(String video) async {
    yoyo.add(M3U8pass(dataQuality: "Auto", dataURL: video, label: "Auto", qualityRank: 0));
    RegExp regExpAudio = new RegExp(
      RegexResponse.regexMEDIA,
      caseSensitive: false,
      multiLine: true,
    );
    RegExp regExp = new RegExp(
      r"#EXT-X-STREAM-INF:(?:.*,RESOLUTION=(\d+x\d+))?,?(.*)\r?\n(.*)",
      caseSensitive: false,
      multiLine: true,
    );
    setState(
      () {
        if (m3u8Content != null) {
          m3u8Content = null;
        }
      },
    );
    if (m3u8Content == null && video != null) {
      http.Response response = await http.get(Uri.parse(video));
      if (response.statusCode == 200) {
        m3u8Content = utf8.decode(response.bodyBytes);
      }
    }
    List<RegExpMatch> matches = regExp.allMatches(m3u8Content!).toList();
    List<RegExpMatch> audioMatches =
        regExpAudio.allMatches(m3u8Content!).toList();

    matches.forEach(
      (RegExpMatch regExpMatch) async {
        String quality = (regExpMatch.group(1)).toString();
        String sourceURL = (regExpMatch.group(3)).toString();
        final netRegex = new RegExp(r'^(http|https):\/\/([\w.]+\/?)\S*');
        final netRegex2 = new RegExp(r'(.*)\r?\/');
        final isNetwork = netRegex.hasMatch(sourceURL);
        final match = netRegex2.firstMatch(video);
        String url;
        if (isNetwork) {
          url = sourceURL;
        } else {
          final dataURL = match!.group(0);
          url = "$dataURL$sourceURL";
        }
        audioMatches.forEach(
          (RegExpMatch regExpMatch2) async {
            String audioURL = (regExpMatch2.group(1)).toString();
            final isNetwork = netRegex.hasMatch(audioURL);
            final match = netRegex2.firstMatch(video);
            String auURL = audioURL;
            if (isNetwork) {
              auURL = audioURL;
            } else {
              final auDataURL = match!.group(0);
              auURL = "$auDataURL$audioURL";
            }
            audioList.add(AUDIO(url: auURL));
          },
        );
        String audio = "";
        if (audioList.length != 0) {
          audio =
              """#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio-medium",NAME="audio",AUTOSELECT=YES,DEFAULT=YES,CHANNELS="2",URI="${audioList.last.url}"\n""";
        } else {
          audio = "";
        }
        try {
          final Directory directory = await getApplicationDocumentsDirectory();
          final File file = File('${directory.path}/yoyo$quality.m3u8');
          await file.writeAsString(
              """#EXTM3U\n#EXT-X-INDEPENDENT-SEGMENTS\n$audio#EXT-X-STREAM-INF:CLOSED-CAPTIONS=NONE,BANDWIDTH=1469712,RESOLUTION=$quality,FRAME-RATE=30.000\n$url""");
        } catch (e) {
          print("Couldn't write file");
        }
        final m38 = processM3U8pass(M3U8pass(dataQuality: quality, dataURL: url));
        if(widget.filterQuality.contains(m38.label)){
          yoyo.add(m38);
        }
      
      },
    );
    M3U8s m3u8s = M3U8s(m3u8s: yoyo);
    return m3u8s;
  }

  M3U8pass processM3U8pass(M3U8pass data){
    if(data.dataQuality!.contains("480")){
        data.label = "SD";
        data.qualityRank = 1;
    }else if(data.dataQuality!.contains("720")){
        data.label = "HD";
        data.qualityRank = 2;
      }else if(data.dataQuality!.contains("1080")){
        data.label = "Full HD";
        data.qualityRank = 3;
      }else if(data.dataQuality!.contains("3840")){
        data.label = "UHD";
        data.qualityRank = 4;
      }else if(data.dataQuality!.contains("4096")){
        data.label = "4K";
        data.qualityRank = 5;
    }
    return data;
  }

// Video controller
  void videoControlSetup(String? url) {
    videoInit(url);
    controller!.addListener(listener);
    controller!.play();
  }

// video Listener
  void listener() async {
    if (controller!.value.isInitialized && controller!.value.isPlaying) {
      wasPlaying = true;
      if(widget.onPlaying != null){
        widget.onPlaying!(widget.urls[currentPlayingIndex]);
      }

      if (!await Wakelock.enabled) {
        await Wakelock.enable();
      }

      setState(() {
        videoDuration = controller!.value.duration;
        videoSeek = controller!.value.position;
        widget.seekToDuration = videoSeek;
      
        if(widget.onPlayerDurationChanged != null){
          widget.onPlayerDurationChanged!(controller!.value.position);
        }
      });
    } else {
      if (await Wakelock.enabled) {
        await Wakelock.disable();
      }
      if(wasPlaying && controller!.value.position >= controller!.value.duration && widget.onPlayEnd != null){
          wasPlaying = false;
          _playNext();
          widget.onPlayEnd!();
      }
    }
  }

  void createHideControlBarTimer() {
    clearHideControlBarTimer();
    showTime = Timer(Duration(milliseconds: 5000), () {
      if (controller != null && controller!.value.isPlaying) {
        if (showMenu) {
          setState(() {
            showMenu = false;
            m3u8show = false;
            controlBarAnimationController.reverse();
          });
        }
      }
    });
  }

  void clearHideControlBarTimer() {
    showTime?.cancel();
  }

  void toggleControls() {
    clearHideControlBarTimer();

    if (!showMenu) {
      showMenu = true;
      createHideControlBarTimer();
    } else {
      m3u8show = false;
      showMenu = false;
    }
    setState(() {
      if (showMenu) {
        controlBarAnimationController.forward();
      } else {
        controlBarAnimationController.reverse();
      }
    });
  }

  void togglePlay() {
    createHideControlBarTimer();
    if (controller!.value.isPlaying) {
      controller!.pause();
    } else {
      controller!.play();
    }
    setState(() {});
  }

  void seekIfRequired(){
    if(widget.seekToDuration != null){
      controller!.seekTo(widget.seekToDuration!);
    }
  }

  void videoInit(String? url) {
    if (offline == false) {
      if (playType == "MP4") {
        // Play MP4
        controller =
            VideoPlayerController.network(url!, formatHint: VideoFormat.other)
              ..initialize();
      } else if (playType == "MKV") {
        controller =
            VideoPlayerController.network(url!, formatHint: VideoFormat.dash)
              ..initialize();
      } else if (playType == "HLS") {
        controller =
            VideoPlayerController.network(url!, formatHint: VideoFormat.hls)
              ..initialize()
                  .then((_) => setState((){
                    seekIfRequired();
                    hasInitError = false;
                  }))
                  .catchError((e) => setState(() => hasInitError = true));
      }
    } else {
      controller = VideoPlayerController.file(File(url!))
        ..initialize()
            .then((value) => setState(() { 
              seekIfRequired();
              hasInitError = false;
            })).catchError((e) => setState(() => hasInitError = true));
    }
  }

  void _navigateLocally(context) async {
    if (!fullScreen) {
      if (ModalRoute.of(context)!.willHandlePopInternally) {
        Navigator.of(context).pop();
      }
      return;
    }
    ModalRoute.of(context)!.addLocalHistoryEntry(LocalHistoryEntry(onRemove: () {
      if (fullScreen) toggleFullScreen();
    }));
  }

  void onSelectQuality(M3U8pass data) async {
    setState(() {
      currentm3u8Data = data;
    });
    controller!.value.isPlaying ? controller!.pause() : controller!.pause();
    if (data.dataQuality == "Auto") {
      videoControlSetup(data.dataURL);
    } else {
      try {
        String text;
        final Directory directory = await getApplicationDocumentsDirectory();
        final File file =
            File('${directory.path}/yoyo${data.dataQuality}.m3u8');
        text = await file.readAsString();
        localM3U8play(file);
        // videoControlSetup(file);
      } catch (e) {
        print("Couldn't read file ${data.dataQuality} e: $e");
      }
      print("data : ${data.dataQuality}");
    }
  }

  void localM3U8play(File file) {
    controller = VideoPlayerController.file(
      file,
    )..initialize()
        .then((_) => setState(() {
          seekIfRequired();
          hasInitError = false;
          }))
        .catchError((e) => setState(() => hasInitError = true));
    controller!.addListener(listener);
    controller!.play();
  }

  void m3u8clean() async {
    for (int i = 2; i < yoyo.length; i++) {
      try {
        final Directory directory = await getApplicationDocumentsDirectory();
        final File file = File('${directory.path}/${yoyo[i].dataQuality}.m3u8');
        file.delete();
      } catch (e) {
        print("Couldn't delete file $e");
      }
    }
    try {
      audioList.clear();
    } catch (e) {
      print("Audio list clean error $e");
    }
    audioList.clear();
    try {
      yoyo.clear();
    } catch (e) {
      print("m3u8 video list clean error $e");
    }
  }

  void toggleFullScreen() {
    if (fullScreen) {
      OrientationPlugin.forceOrientation(DeviceOrientation.portraitUp);
    } else {
      OrientationPlugin.forceOrientation(DeviceOrientation.landscapeRight);
    }
  }
}
