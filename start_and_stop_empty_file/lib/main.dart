// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:path/path.dart';

late String tempDir;
late AudioRecorder recorder;
void main() async {
  tempDir = join((await getApplicationDocumentsDirectory()).path,
      'record_start_stop_empty_file_repro');
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
                onPressed: () => _makeRecording(Duration.zero),
                child: const Text('Make a zero-length recording'),
              ),
              ElevatedButton(
                onPressed: () =>
                    _makeRecording(const Duration(milliseconds: 250)),
                child: const Text('Make a quarter--second-long recording'),
              ),
              ElevatedButton(
                onPressed: () =>
                    _makeRecording(const Duration(milliseconds: 500)),
                child: const Text('Make a half-second-long recording'),
              ),
              ElevatedButton(
                onPressed: () => _makeRecording(const Duration(seconds: 1)),
                child: const Text('Make a second-long recording'),
              ),
              ElevatedButton(
                onPressed: () => _makeRecording(const Duration(seconds: 5)),
                child: const Text('Make a five second-long recording'),
              ),
              const Text(
                  'Warning: clicking these buttons will record audio from the '
                  'microphone on your device. '),
              Text('You will be able to find the audio files here: $tempDir'),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _makeRecording(Duration duration) async {
  final audioPath = join(tempDir, _getRandomString());
  await File(audioPath).parent.create(recursive: true);

  print('Started recording with a duration of $duration');
  final Stopwatch stopwatch = Stopwatch()..start();
  final startCalledAt = stopwatch.elapsedMilliseconds;
  await recorder.start(
    const RecordConfig(encoder: AudioEncoder.aacLc),
    path: audioPath,
  );
  final startFinishedAt = stopwatch.elapsedMilliseconds;
  if (duration > Duration.zero) {
    await Future.delayed(duration);
  }
  print(
    'Stopping recording at ${stopwatch.elapsedMilliseconds} milliseconds...',
  );
  final stopCalledAt = stopwatch.elapsedMilliseconds;
  await recorder.stop();
  final stopFinishedAt = stopwatch.elapsedMilliseconds;
  stopwatch.stop();

  print('Finished stopping at ${stopwatch.elapsedMilliseconds} milliseconds.');
  print('You can find your audio file at $audioPath');

  print(
    'Duration between .start() being called and .stop() being  called was ${Duration(milliseconds: stopCalledAt - startCalledAt)}',
  );

  print(
    'Duration between .start() being called and .start() finishing was ${Duration(milliseconds: startFinishedAt - startCalledAt)}',
  );
  print(
    'Duration between .start() finishing and .stop() being called was ${Duration(milliseconds: stopCalledAt - startFinishedAt)}',
  );

  print(
    'Duration between .start() finishing and .stop() finishing was ${Duration(milliseconds: stopFinishedAt - startFinishedAt)}',
  );

  print(
    'Duration between .start() being called and .stop() finishing was ${Duration(milliseconds: stopFinishedAt - startCalledAt)}',
  );

  if (await _isFfprobeAvailable()) {
    var args = [
      '-i',
      File(audioPath).path,
      '-show_entries',
      'format=duration',
      '-sexagesimal',
      '-v',
      'quiet',
      '-of',
      'csv=p=0',
    ];
    final ffprobeOutput = await Process.run('ffprobe', args);

    print('Running ffprobe: ffprobe ${args.join(' ')}');
    if (ffprobeOutput.exitCode == 0) {
      print('Audio file produced has a length of ${ffprobeOutput.stdout}');
    } else {
      print('ffprobe failed to run. Is the file empty?');
      print(ffprobeOutput.stderr);
    }
  }
}

final _rand = Random();
String _getRandomString() => '${_rand.nextInt(1000000000)}.m4a';

Future<bool> _isFfprobeAvailable() async {
  try {
    final result = await Process.run('ffprobe', ['-version']);
    return result.exitCode == 0;
  } catch (e) {
    return false;
  }
}
