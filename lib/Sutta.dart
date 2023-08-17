import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wakelock/wakelock.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:async';
import 'dart:convert';
import 'dart:math';

class Sutta extends StatefulWidget {
  const Sutta({super.key});

  @override
  State<Sutta> createState() =>_SuttaState();
}

class _SuttaState extends State<Sutta> {
  int _currentTime = 0;
  int _musicLevel = 1;
  double _musicLevelSlider = 1;
  int _speed = 1;
  double _speedSlider = 1;
  int _suttaType = 0;
  static const int _beginningSilence = 4;
  bool _singing = false;
  bool _paused = false;
  bool _muted = false;
  String _pauseButtonLabel = "Pause";
  String _muteButtonLabel = "Mute";
  var _player = AudioPlayer();
  late Timer _timer;
  static const _second = Duration(seconds: 1);
  static const List<String> _speedLabels = ["Silent", "Tones", "Metronome"];
  static const List<String> _musicLevelLabels = ["Short", "Normal", "Long"];
  static const List<String> _suttaTypes = ["metta"];

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

  Future loadSuttaToPlan() async
  {
    var lines = await getFileAsList("assets/meditationPlans/");
    for(final line in lines)
      if(line != null && line.trim() != '')
      {
      }
  }

  void updateMeditation() {
    if(_paused)
      return;

      _player = AudioPlayer();
      //_player.play(AssetSource(nextPart.asset));
      _player.release();

    _currentTime++;
  }


  void startSutta() async
  {

    _singing = true;
    await Wakelock.enable();

    //await Future.delayed(const Duration(seconds: 2), (){});
    _timer = Timer.periodic(_second,
    (Timer timer) {
      //TODO end
      if (_currentTime == 500) {
        setState(() {

        });
      } else {
        setState(() {
          updateMeditation();
        });
      }});

    setState(() {
    });
  }

  void stopSutta()
  {
    _singing = false;
    _player.stop();
    _timer.cancel();
    _currentTime = 0;
    Wakelock.disable();
    setState(() {
    });
  }

  void muteSutta()
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

  void pauseSutta()
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
        if(_singing) ...
          [
            const SizedBox(height:10),

            const SizedBox(height:10),
            FilledButton(onPressed: () => {pauseSutta()},
                child: Text(_pauseButtonLabel)),
            const SizedBox(height:10),
            FilledButton(onPressed: () => {muteSutta()},
                child: Text(_muteButtonLabel)),
            const SizedBox(height:10),
            FilledButton(onPressed: () => {stopSutta()},
                child: const Text('Stop')),
          ]
        else ...
          [
            const Text(
                "Speed:"),
            Padding(
              padding: const EdgeInsets.all(5.0),
              child:
              Slider(
                  value: _speedSlider,
                  max: 2,
                  divisions: 2,
                  label: _speedLabels[_speed],
                  onChanged: (double value) { setState(() {
                    _speedSlider = value;
                    _speed = value.round();
                    });}
              ),
            ),
            const Text(
                "Amount of music:"),
            Padding(
              padding: const EdgeInsets.all(5.0),
              child:
              Slider(
                  value: _musicLevelSlider,
                  max: 2,
                  divisions: 2,
                  label:  _musicLevelLabels[_musicLevel],
                  onChanged: (double value) { setState(() {
                    _musicLevelSlider = value;
                    _musicLevel = value.round();
                  });}
              ),
            ),
            FilledButton(onPressed: () => {startSutta()},
                child: const Text('Sing')),
          ],
      ],
    );
  }
}