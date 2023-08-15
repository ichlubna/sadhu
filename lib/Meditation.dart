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
  Part(this.priority, this.name);
}

class _MeditationState extends State<Meditation> {
  int _minutesLength = 30;
  late int _secondsLength;
  int _currentTime = 0;
  double _percentTime = 0;
  double _silence = 50;
  bool _meditating = false;
  bool _paused = false;
  bool _muted = false;
  String _pauseButtonLabel = "Pause";
  String _muteButtonLabel = "Mute";
  final _player = AudioPlayer();
  late Timer _timer;
  static const _second = Duration(seconds: 1);
  List<String> meditationPlaylist = [];
  List<String> endPlaylist = [];

  //TODO move to json file
  static List<Part> meditationParts = [
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
  static List<Part> endParts = [
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

  void startMeditation() async
  {
    Map<String, dynamic> assets = await listAssets();
    Duration guidanceTime = Duration();
    for(final part in meditationParts)
    {
      List<String> filtered = assets.keys.where((String key) => key.contains(part.name)).toList();
      int id = Random().nextInt(filtered.length);
      meditationPlaylist.add(filtered[id]);
      final duration = await _player.setUrl(meditationPlaylist.last);
      guidanceTime += duration!;
    }

    for(final part in endParts)
    {
      List<String> filtered = assets.keys.where((String key) => key.contains(part.name)).toList();
      int id = Random().nextInt(filtered.length);
      endPlaylist.add(filtered[id]);
    }
    _player.play();
    _secondsLength = _minutesLength*60;
    _meditating = true;
    Wakelock.enable();

    _timer = Timer.periodic(_second,
    (Timer timer) {
      if (_currentTime == _secondsLength) {
        setState(() {
        stopMeditation();
        });
      } else {
        setState(() {
          _currentTime++;
          _percentTime = (_currentTime / _secondsLength);
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
    }
    else {
      _muteButtonLabel = "Mute";
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if(_meditating) ...
          [
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
              onChanged: (value) => setState(() => _minutesLength = value),
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
                  onChanged: (double value) {
                    setState(() {
                      _silence = value;
                    });
                  }
              ),
            ),
            FilledButton(onPressed: () => {startMeditation()},
                child: const Text('Meditate')),
          ],
      ],
    );
  }
}