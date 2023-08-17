import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:wakelock/wakelock.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';

class Meditation extends StatefulWidget {
  const Meditation({super.key});

  @override
  State<Meditation> createState() =>_MeditationState();
}

class Part
{
  late int priority;
  late String name;
  String asset = "";
  int duration = 0;
  Part(this.priority, this.name);
}

class ScheduledPart
{
  late String asset;
  late int time;
  ScheduledPart(this.asset, this.time);
}

class _MeditationState extends State<Meditation> {
  int _minutesLength = 30;
  late int _secondsLength;
  int _currentTime = 0;
  double _silence = 50;
  double _percentTime = 0;
  bool _meditating = false;
  bool _paused = false;
  bool _muted = false;
  String _pauseButtonLabel = "Pause";
  String _muteButtonLabel = "Mute";
  var _player = AudioPlayer();
  late Timer _timer;
  static const _second = Duration(seconds: 1);
  List<ScheduledPart> _plan = [];
  int _partsPlayed = 0;

  //TODO move to json file
  //Priority = 0 means that the part will always be played
  static List<Part> _meditationPartsTemplate = [
    Part(0,"intro"),
    Part(0,"posture"),
    Part(1,"bodyCheck"),
    Part(1,"legsA"),
    Part(1,"legsB"),
    Part(1,"legsC"),
    Part(1,"legsD"),
    Part(1,"bodyA"),
    Part(1,"bodyB"),
    Part(1,"bodyC"),
    Part(1,"handsA"),
    Part(1,"handsB"),
    Part(1,"handsC"),
    Part(1,"headA"),
    Part(1,"headB"),
    Part(2,"aches"),
    Part(2,"safe"),
    Part(1,"mind"),
    Part(2,"aware"),
    Part(2,"care"),
    Part(2,"kindfull"),
    Part(2,"moment"),
    Part(2,"joy"),
    Part(0,"quiet")
  ];
  static List<Part> _endPartsTemplate = [
    Part(0,"closeToEnd"),
    Part(0,"ringGong"),
    Part(0,"gong"),
    Part(0,"gong"),
    Part(0,"gong"),
    Part(0,"smile"),
  ];

  Future listAssets() async
  {
    var assetsFile = await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
    final Map<String, dynamic> result = json.decode(assetsFile);
    return result;
  }

  void initList(List<Part> parts) async
  {
    Map<String, dynamic> assets = await listAssets();
    for(final part in parts)
    {
      List<String> filtered = assets.keys.where((String key) => key.contains(part.name)).toList();
      int id = Random().nextInt(filtered.length);
      part.asset=(filtered[id]);
      var player = AudioPlayer();
      final duration = await player.setAsset(part.asset);
      player.dispose();
      part.duration = duration!.inSeconds;
    }
  }

  int getMaxPriority(List<Part> parts)
  {
    int maxPriority = 0;
    for(final part in parts)
      if(maxPriority < part.priority)
        maxPriority = part.priority;
    return maxPriority;
  }

  int getTotalDuration(List<Part> parts)
  {
    int total = 0;
    for(final part in parts)
      total += part.duration;
    return total;
  }

  void shrinkList(List<Part> parts, int targetDuration) async
  {
    int previousLength = parts.length+1;
    int partsDuration = getTotalDuration(parts);
    int maxPriority = getMaxPriority(parts);
    while(previousLength > parts.length && partsDuration > targetDuration)
    {
      List<int> priorityParts = [];
      previousLength = parts.length;
      for(int priority=maxPriority; priority>=1; priority--)
      {
        for(int i=0; i<parts.length; i++)
          if(parts[i].priority == priority)
            priorityParts.add(i);
        if(priorityParts.isNotEmpty)
          break;
      }
      if(priorityParts.isNotEmpty) {
        int toRemoveNumber = Random().nextInt(priorityParts.length);
        int id = priorityParts[toRemoveNumber];
        partsDuration -= parts[id].duration;
        parts.removeAt(id);
      }
    }
  }

  List<ScheduledPart> schedule(List<Part> guidedParts, int guidedDuration, List<Part> endParts)
  {
    List<ScheduledPart> scheduled = [];
    int guidanceTime = getTotalDuration(guidedParts);
    int space = ((guidedDuration-guidanceTime)/guidedParts.length).round();
    int currentPosition = 0;
    for(final part in guidedParts)
    {
       currentPosition += space;
       scheduled.add(ScheduledPart(part.asset, currentPosition));
       currentPosition += part.duration;
    }
    currentPosition = _secondsLength - getTotalDuration(endParts) - endParts.length*space;
    for(final part in endParts)
    {
      currentPosition += space;
      scheduled.add(ScheduledPart(part.asset, currentPosition));
      currentPosition += part.duration;
    }

    return scheduled;

  }

  void updateMeditation() {
    var nextPart = _plan[_partsPlayed];
    print("STEP");
    print(nextPart.time);
    print(_currentTime);
    if (nextPart.time == _currentTime) {
      var player = AudioPlayer();
      player.setAsset(nextPart.asset);
      player.play();
      player.dispose();
      //_player.setAsset(nextPart.asset);
      //_player.play();
      _partsPlayed++;
    }
    _currentTime++;
    _percentTime = (_currentTime / _secondsLength);
  }

  void startMeditation() async
  {
    _secondsLength = _minutesLength*60;
    int guidanceReservedTime = (_secondsLength * (_silence/100.0)).round();
    var guidedParts = List<Part>.from(_meditationPartsTemplate);
    initList(guidedParts);
    shrinkList(guidedParts, guidanceReservedTime);
    var endParts = List<Part>.from(_endPartsTemplate);
    initList(endParts);
    _plan = schedule(guidedParts, guidanceReservedTime, endParts);

    _meditating = true;
    _partsPlayed = 0;
    Wakelock.enable();

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
      _player.stop();
      Wakelock.disable();
      _pauseButtonLabel = "Resume";
    }
    else {
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
            const Text("Select the duration of the meditation:"),
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
                "Select the length of the silent part with no guidance:"),
            Padding(
              padding: const EdgeInsets.all(5.0),
              child:
              Slider(
                  value: _silence,
                  max: 95,
                  divisions: 100,
                  label: _silence.round().toString() + "%",
                  onChanged: (double value) { setState(() {
                      _silence = value;
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