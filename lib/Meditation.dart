import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:wakelock/wakelock.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:math';

class Meditation extends StatefulWidget {
  const Meditation({super.key});

  @override
  State<Meditation> createState() =>_MeditationState();
}

enum GuidanceLevel {minimal, normal, verbose}
enum PartPosition{beginning, end}

class Part
{
  late String name;
  String asset = "";
  int duration = 0;
  int time= 0;
  late PartPosition position = PartPosition.beginning;
  Part(this.name, this.position);
}

class PlanLengths
{
  int beginningCount = 0;
  int endCount = 0;
  int beginningDuration = 0;
  int endDuration = 0;
}

class _MeditationState extends State<Meditation> {
  int _minutesLength = 30;
  late int _secondsLength;
  int _currentTime = 0;
  double _percentTime = 0;
  int _guidanceLevel = 1;
  double _guidanceLevelSlider = 1;
  int _speechPauseLevel = 1;
  double _speechPauseLevelSlider = 1;
  int _meditationType = 0;
  static const int _minimalPause = 2;
  static const int _beginningSilence = 4;
  bool _meditating = false;
  bool _paused = false;
  bool _muted = false;
  String _pauseButtonLabel = "Pause";
  String _muteButtonLabel = "Mute";
  var _player = AudioPlayer();
  late Timer _timer;
  static const _second = Duration(seconds: 1);
  List<Part> _plan = [];
  int _partsPlayed = 0;
  static const List<String> _guidanceLevelLabels = ["Minimal", "Normal", "Verbose"];
  static const List<String> _guidanceLevelFiles = ["minimal", "normal", "verbose"];
  static const List<String> _speechPauselLabels = ["Short", "Normal", "Long"];
  static const List<String> _meditationTypes = ["classic"];

  Future listAssets() async
  {
    var assetsFile = await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
    final Map<String, dynamic> result = json.decode(assetsFile);
    return result;
  }

  Future getFileAsList(String filename) async
  {
    var fileContent = await rootBundle.loadString(filename);
    List<String> lines = fileContent.split('\n');
    return lines;
  }

  Future loadMeditationToPlan() async
  {
    var lines = await getFileAsList("assets/meditationPlans/"+_meditationTypes[_meditationType]+"-"+_guidanceLevelFiles[_guidanceLevel]);
    for(final line in lines)
      if(line != null && line.trim() != '')
        _plan.add(Part(line, PartPosition.beginning));

      lines =  await getFileAsList("assets/meditationPlans/"+_meditationTypes[_meditationType]+"-end");
      for(final line in lines)
        if(line != null && line.trim() != '')
          _plan.add(Part(line, PartPosition.end));
  }

  Future initPlanAssets() async
  {
    Map<String, dynamic> assets = await listAssets();
    for(final part in _plan)
    {
      List<String> filtered = assets.keys.where((String key) => key.contains(part.name)).toList();
      int id = Random().nextInt(filtered.length);
      part.asset=(filtered[id]).replaceAll("assets/", "");
      var player =  AudioPlayer();
      await player.setSourceAsset(part.asset);
      final duration = await player.getDuration();
      part.duration = duration!.inSeconds;
    }
  }

  PlanLengths getPlanLengths()
  {
    var lengths = PlanLengths();
    for(final part in _plan)
      if(part.position == PartPosition.beginning)
      {
        lengths.beginningCount++;
        lengths.beginningDuration += part.duration;
      }
      else if(part.position == PartPosition.end)
      {
        lengths.endCount++;
        lengths.endDuration += part.duration;
      }
    return lengths;
  }

  void schedulePlan()
  {
    int space = _minimalPause+_speechPauseLevel;
    var lengths = getPlanLengths();
    int beginningPosition = _beginningSilence;
    int endPosition = _secondsLength-lengths.endCount*space-lengths.endDuration;
    for(final part in _plan)
    {
      if(part.position == PartPosition.beginning)
      {
        part.time = beginningPosition;
        beginningPosition += part.duration+space;
      }
      else if(part.position == PartPosition.end)
      {
        part.time = endPosition;
        endPosition += part.duration+space;
      }
      print(part.asset);
      print(part.name);
      print(part.time);
    }
  }

  void updateMeditation() {
    if(_paused)
      return;
    var nextPart = _plan[_partsPlayed];
    if (nextPart.time == _currentTime) {
      _player = AudioPlayer();
      _player.play(AssetSource(nextPart.asset));
      _player.release();
      _partsPlayed++;
    }
    _currentTime++;
    _percentTime = (_currentTime / _secondsLength);
  }

  void startMeditation() async
  {
    _guidanceLevelSlider = (_minutesLength < 15) ? 0 : _guidanceLevelSlider;
    _secondsLength = _minutesLength*60;
    await loadMeditationToPlan();
    await initPlanAssets();
    schedulePlan();

    _meditating = true;
    _partsPlayed = 0;
    await Wakelock.enable();

    //await Future.delayed(const Duration(seconds: 2), (){});
    _timer = Timer.periodic(_second,
    (Timer timer) {
      if (_currentTime == _secondsLength) {
        setState(() {
        stopMeditation();
        });
      } else {
        setState(() {
          updateMeditation();
        });
      }});

    setState(() {
    });
  }

  void stopMeditation()
  {
    _plan = [];
    _meditating = false;
    _player.stop();
    _timer.cancel();
    _currentTime = 0;
    Wakelock.disable();
    setState(() {
    });
  }

  void muteMeditation()
  {
    _muted = !_muted;
    if(_muted) {
      _muteButtonLabel = "Unmute";
      _player.setVolume(0);
    }
    else {
      _muteButtonLabel = "Mute";
      _player.setVolume(1);
    }
    setState(() {
    });
  }

  void pauseMeditation()
  {
    _paused = !_paused;
    if(_paused) {
      _player.pause();
      Wakelock.disable();
      _pauseButtonLabel = "Resume";
    }
    else {
      _player.resume();
      Wakelock.enable();
      _pauseButtonLabel = "Pause";
    }
    setState(() {
    });
  }

  @override
  Widget build(BuildContext context) {
    return
      Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if(_meditating) ...
          [
            const SizedBox(height:10),
            Expanded(
              child:
              ShaderMask(
                shaderCallback: (Rect bounds) {
                  return LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.white, Color(0x396AEAA6)],
                    stops: [
                      _percentTime+0.01,
                      _percentTime,
                    ],
                    tileMode: TileMode.mirror,
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: SvgPicture.asset(
                  'assets/images/ajahn.svg',
                  semanticsLabel: 'Ajahn Brahm',
                  //colorFilter: ColorFilter.mode(Colors.red, BlendMode.srcIn),
                  width: MediaQuery.of(context).size.width*0.9,
                ),
              ),
            ),
            const SizedBox(height:10),
            FilledButton(onPressed: () => {pauseMeditation()},
                child: Text(_pauseButtonLabel)),
            const SizedBox(height:10),
            FilledButton(onPressed: () => {muteMeditation()},
                child: Text(_muteButtonLabel)),
            const SizedBox(height:10),
            FilledButton(onPressed: () => {stopMeditation()},
                child: const Text('Stop')),
          ]
        else ...
          [
            const Text("Duration of the meditation:"),
            NumberPicker(
              value: _minutesLength,
              minValue: 5,
              maxValue: 120,
              step: 5,
              axis: Axis.horizontal,
              onChanged: (int value) { setState(() {
                _minutesLength = value;
              });},
            ),
            const Text(
                "Amount of guidance:"),
            Padding(
              padding: const EdgeInsets.all(5.0),
              child:
              Slider(
                  value: (_minutesLength < 15) ? 0 : _guidanceLevelSlider,
                  max: 2,
                  divisions: 2,
                  label: _guidanceLevelLabels[_guidanceLevel],
                  onChanged: (double value) { setState(() {
                    _guidanceLevelSlider = value;
                    _guidanceLevel = value.round();
                    });}
              ),
            ),
            const Text(
                "Length of pauses between speech:"),
            Padding(
              padding: const EdgeInsets.all(5.0),
              child:
              Slider(
                  value: _speechPauseLevelSlider,
                  max: 2,
                  divisions: 2,
                  label:  _speechPauselLabels[_speechPauseLevel],
                  onChanged: (double value) { setState(() {
                    _speechPauseLevelSlider = value;
                    _speechPauseLevel = value.round();
                  });}
              ),
            ),
            FilledButton(onPressed: () => {startMeditation()},
                child: const Text('Meditate')),
          ],
      ],
    );
  }
}