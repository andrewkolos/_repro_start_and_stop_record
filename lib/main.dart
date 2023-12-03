import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:path/path.dart';

late String tempDir;
late AudioRecorder recorder;
void main() async {
  tempDir =
      join((await getTemporaryDirectory()).path, 'record_start_stop_repro');
  WidgetsFlutterBinding.ensureInitialized();
  recorder = AudioRecorder();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => _makeRecordings(),
                child: const Text('Make 10 recordings'),
              ),
              const Text(
                  'Warning: clicking this button may record audio from the '
                  'microphone on your device. '),
              Text('You will be able to find the audio files here: $tempDir'),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _makeRecordings() async {
  final Stopwatch stopwatch = Stopwatch()..start();
  for (int i = 0; i < 10; i++) {
    await Future.delayed(const Duration(milliseconds: 150), () async {
      print('Checking recording status at ${stopwatch.elapsed}');
      if (await recorder.isRecording()) {
        print('Stopping recording $i at ${stopwatch.elapsed}');
        await recorder.stop();
        print('Stopped stopped recording $i at ${stopwatch.elapsed}');
      }
    });
    print('Starting recording ${i + 1} at ${stopwatch.elapsed}');
    await recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: join(tempDir, _getRandomString()),
    );
    print('Started recording ${i + 1} at ${stopwatch.elapsed}');
  }
}

final _rand = Random();
String _getRandomString() => '${_rand.nextInt(1000000000)}.m4a';
