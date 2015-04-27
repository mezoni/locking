import "dart:async";

import 'package:locking/locking.dart';

void main() {
  var count = 1000000;
  measure("lock $count times", () async {
    var obj = new Object();
    for (var i = 0; i < count; i++) {
      await lock(obj, () async {
        return;
      });
    }
  });

  measure("Mutex $count times", () async {
    var mutex = new ReentrantMutex();
    for (var i = 0; i < count; i++) {
      await mutex.acquire();
      try {
        //
      } finally {
        mutex.release();
      }
    }
  });
}

Future measure(String text, f()) async {
  var sw = new Stopwatch();
  sw.start();
  await f();
  sw.stop();
  var time = sw.elapsedMilliseconds / 1000;
  print("$text: $time sec");
}
