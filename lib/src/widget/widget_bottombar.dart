import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:yoyo_player/src/responses/play_response.dart';
import 'package:yoyo_player/src/source/video_style.dart';

Widget bottomBar(
    {VideoPlayerController? controller,
    required double spaceBetweenControls,
    Duration? videoDuration,
    Duration? videoSeekTo,
    VideoStyle? videoStyle,
    required bool fullScreen,
    required bool showMenu,
    required bool showNext,
    required bool showPrevious,
    required Function (Duration duration) onSeekChange,
    Function(bool next) ? onSkipNext,
    Function? onFullScreen,
    Function? play}) {
  return showMenu
      ? Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 80,
            child: Padding(
              padding: EdgeInsets.all(0.0),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        InkWell(
                            onTap: () {
                              onSkipNext!(false);
                            },
                            child: videoStyle?.previous),
                        SizedBox(width: spaceBetweenControls),
                        InkWell(
                            onTap: () {
                              rewind(controller!);
                            },
                            child: videoStyle?.backward),
                        SizedBox(width: spaceBetweenControls),
                        InkWell(
                          onTap: play as void Function()?,
                          child: controller!.value.isPlaying
                              ? videoStyle?.pause
                              : videoStyle?.play,
                        ),
                        SizedBox(width: spaceBetweenControls),
                        InkWell(
                            onTap: () {
                              fastForward(controller: controller);
                            },
                            child: videoStyle?.forward),
                        SizedBox(width: spaceBetweenControls),
                        InkWell(
                            onTap: () {
                              onSkipNext!(true);
                            },
                            child: videoStyle?.next),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(10, 0, 5, 0),
                    child: Row(
                      children: [
                        Expanded(
                            child: Text(
                          convertDurationToString(videoSeekTo != null ? videoSeekTo : Duration(milliseconds: 0)),
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white),
                          textAlign: TextAlign.end,
                        )),
                        Expanded(
                            flex: 6,
                            child: Slider(
                                thumbColor: videoStyle?.thumbColor,
                                activeColor: videoStyle?.playedColor,
                                inactiveColor: videoStyle?.sliderColor,
                                min: 0.0,
                                value: videoSeekTo!.inSeconds.toDouble(),
                                max: videoDuration!.inSeconds.toDouble(),
                                onChanged: (value) {
                                  onSeekChange(Duration(seconds: value.toInt()));
                                })),
                        Expanded(
                          flex: 2,
                            child: Row(
                              children: [
                                Text(
                                  convertDurationToString (videoDuration != null
                                      ? videoDuration
                                      : Duration(milliseconds: 0)),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                                SizedBox(width: fullScreen ? 20:10),
                                InkWell(
                                  child: fullScreen
                                      ? videoStyle?.fullscreenExit
                                      : videoStyle?.fullscreen,
                                  onTap: onFullScreen as void Function()?,
                                )
                              ],
                            ))
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
      : Container();
}

String convertDurationToString(Duration duration) {
  var minutes = duration.inMinutes.toString();
  if (minutes.length == 1) {
    minutes = '0' + minutes;
  }
  var seconds = (duration.inSeconds % 60).toString();
  if (seconds.length == 1) {
    seconds = '0' + seconds;
  }
  return "$minutes:$seconds";
}
