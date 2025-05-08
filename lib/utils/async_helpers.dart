import 'dart:async';
import 'dart:isolate';

Future<String> heavyComputation(String data) async {
  // 실제로는 compute()를 사용할 수도 있음
  await Future.delayed(Duration(seconds: 1));
  return 'Processed $data';
}

Future<String> runInIsolate(String data) async {
  final p = ReceivePort();
  await Isolate.spawn(_isolateEntry, [p.sendPort, data]);
  return await p.first;
}

void _isolateEntry(List<dynamic> args) {
  SendPort sendPort = args[0];
  String data = args[1];
  sendPort.send('Isolate processed $data');
} 