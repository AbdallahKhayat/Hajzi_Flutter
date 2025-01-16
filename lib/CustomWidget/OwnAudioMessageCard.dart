import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class OwnAudioMessageCard extends StatefulWidget {
  final String audioUrl; // Audio file URL
  final String time; // Timestamp to display
  final Color messageColor; // Bubble color
  final Color textColor; // Text color
  final VoidCallback? onLongPress; // Long-press logic

  const OwnAudioMessageCard({
    Key? key,
    required this.audioUrl,
    required this.time,
    required this.messageColor,
    required this.textColor,
    this.onLongPress,
  }) : super(key: key);

  @override
  State<OwnAudioMessageCard> createState() => _OwnAudioMessageCardState();
}

class _OwnAudioMessageCardState extends State<OwnAudioMessageCard> {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool isPlaying = false;
  bool isPaused = false;
  String _timerLabel = '0:00 / 0:00'; // Combined timer label
  double _sliderValue = 0.0; // Slider position
  double _playbackSpeed = 1.0; // Default playback speed
  Duration? _totalDuration; // Total duration in milliseconds
  bool _isDragging = false; // Indicates if the slider is being dragged

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      await _player.openPlayer();
      _player.setSubscriptionDuration(const Duration(milliseconds: 500));
      _player.onProgress?.listen((event) {
        if (event != null && !_isDragging) {
          final position = event.position.inMilliseconds;
          final duration = event.duration?.inMilliseconds ?? 1; // Prevent divide by zero
          setState(() {
            _sliderValue = position / duration;
            _totalDuration = Duration(milliseconds: duration);
            _timerLabel =
            '${_durationToMMSS(position ~/ 1000)} / ${_durationToMMSS((duration / 1000).toInt())}';
          });
        }
      });
    } catch (e) {
      debugPrint("Error initializing player: $e");
    }
  }

  @override
  void dispose() {
    _player.closePlayer();
    super.dispose();
  }

  Future<void> _playAudio() async {
    try {
      if (!isPlaying) {
        if (isPaused) {
          await _player.resumePlayer();
        } else {
          await _player.startPlayer(
            fromURI: widget.audioUrl,
            whenFinished: () {
              setState(() {
                isPlaying = false;
                _sliderValue = 0.0;
                _timerLabel = '0:00 / ${_durationToMMSS((_totalDuration?.inSeconds ?? 0))}';
              });
            },
          );
        }
        await _player.setSpeed(_playbackSpeed); // Set the playback speed
        setState(() {
          isPlaying = true;
          isPaused = false;
        });
      } else {
        await _player.pausePlayer();
        setState(() {
          isPaused = true;
          isPlaying = false;
        });
      }
    } catch (e) {
      debugPrint("Error during playback: $e");
    }
  }

  String _durationToMMSS(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _changeSpeed() {
    setState(() {
      if (_playbackSpeed == 1.0) {
        _playbackSpeed = 1.5;
      } else if (_playbackSpeed == 1.5) {
        _playbackSpeed = 2.0;
      } else {
        _playbackSpeed = 1.0;
      }
      if (isPlaying) {
        _player.setSpeed(_playbackSpeed);
      }
    });
  }

  void _seek(double value) async {
    if (_totalDuration != null) {
      final position = Duration(milliseconds: (value * _totalDuration!.inMilliseconds).toInt());
      await _player.seekToPlayer(position);
      setState(() {
        _sliderValue = value;
        _timerLabel =
        '${_durationToMMSS(position.inSeconds)} / ${_durationToMMSS((_totalDuration?.inSeconds ?? 0))}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: widget.onLongPress,
      child: Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width - 145,),
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: widget.messageColor,
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: 4,
                    right: 4,
                    top: 0,
                    bottom: 4,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // 🛠️ Use this to reduce vertical space in the Column.
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                              color: widget.textColor,
                            ),
                            onPressed: _playAudio,
                          ),
                          Text(
                            AppLocalizations.of(context)!.audioMessage,
                            style: TextStyle(
                              fontSize: 14,
                              color: widget.textColor,
                              fontWeight: FontWeight.bold,
                              height: 1, // 🛠️ Reduce line height for tighter spacing (default is 1.2 or more).
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _changeSpeed,
                            child: Text(
                              'x$_playbackSpeed',
                              style: TextStyle(
                                fontSize: 14,
                                color: widget.textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _sliderValue,
                        onChanged: (value) {
                          setState(() {
                            _isDragging = true;
                            _sliderValue = value;
                          });
                        },
                        onChangeEnd: (value) {
                          setState(() {
                            _isDragging = false;
                          });
                          _seek(value);
                        },
                        activeColor: widget.textColor,
                        inactiveColor: widget.textColor.withOpacity(0.5),
                      ),
                      Text(
                        _timerLabel,
                        style: TextStyle(
                          fontSize: 14,
                          color: widget.textColor.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 4,
                  right: 10,
                  child: Row(
                    children: [
                      Text(
                        widget.time,
                        style: TextStyle(
                          fontSize: 13,
                          color: widget.textColor.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.done_all,
                        size: 20,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
