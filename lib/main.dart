import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Chat App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: VoiceChannelsPage(),
    );
  }
}

class VoiceChannelsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voice Channels'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('Channel 1'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => VoiceChannelPage(channelId: 'channel1')),
              );
            },
          ),
          // Add more list tiles for other channels
        ],
      ),
    );
  }
}

class VoiceChannelPage extends StatefulWidget {
  final String channelId;

  const VoiceChannelPage({required this.channelId});

  @override
  _VoiceChannelPageState createState() => _VoiceChannelPageState();
}

class _VoiceChannelPageState extends State<VoiceChannelPage> {
  bool isMuted = false;
  double volume = 0.5;
  List<int> remoteUids = []; // Track remote user IDs

  RtcEngine? _engine;
  bool _joined = false;

  Future<void> initializeAgora() async {
    await [Permission.microphone].request();
    _engine = await RtcEngine.createWithConfig(RtcEngineConfig('<YOUR_AGORA_APP_ID>'));
    await _engine!.enableAudio();
    _engine!.setEventHandler(
      RtcEngineEventHandler(
        joinChannelSuccess: (String channel, int uid, int elapsed) {
          setState(() {
            _joined = true;
          });
        },
        userJoined: (int uid, int elapsed) {
          setState(() {
            remoteUids.add(uid);
          });
        },
        userOffline: (int uid, UserOfflineReason reason) {
          setState(() {
            remoteUids.remove(uid);
          });
        },
      ),
    );
    await _engine!.joinChannel(null, widget.channelId, null, 0);
  }

  void disposeAgora() {
    _engine?.leaveChannel();
    _engine?.destroy();
  }

  void toggleMute() {
    setState(() {
      isMuted = !isMuted;
      _engine?.muteLocalAudioStream(isMuted);
    });
  }

  void adjustVolume(double newVolume) {
    setState(() {
      volume = newVolume;
      _engine?.adjustPlaybackSignalVolume(newVolume.toInt());
    });
  }

  @override
  void initState() {
    super.initState();
    initializeAgora();
  }

  @override
  void dispose() {
    disposeAgora();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voice Channel ${widget.channelId}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: remoteUids.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('User ${remoteUids[index]}'),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(isMuted ? Icons.mic_off : Icons.mic),
                onPressed: toggleMute,
              ),
              Slider(
                value: volume,
                onChanged: adjustVolume,
              ),
              ElevatedButton(
                onPressed: () {
                  disposeAgora();
                  Navigator.pop(context);
                },
                child: Text('Leave Channel'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
