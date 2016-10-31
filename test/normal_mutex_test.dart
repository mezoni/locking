/**
 * Author: Jake Rote
 * Email: jake.rote1995@gmail.com
 */

import "dart:async";

import "package:locking/locking.dart";
import "package:test/test.dart";

Mutex _mutex = new NormalMutex();

Future webRequest() {
  Completer completer = new Completer();
  Duration duration = new Duration(milliseconds: 100);
  Timer timer = new Timer(duration, () => completer.complete());
  return completer.future;
}

Future waitUntil(bool func()) {
  var completer = new Completer();

  new Timer.periodic(const Duration(milliseconds: 10), (Timer timer) {
    if (func()) {
      completer.complete();
      timer.cancel();
    }
  });

  return completer.future;
}

Future main() async {
  test("Does not run code with `NormalMutex` more than once at same time in the same zone", () async {
    int timesRun = 0;
    var result = [];
    var lockObj = new Object();

    Future addEvent(int id) async {
      if (!result.contains(id)) {
        await _mutex.acquire();
        try {
          if (!result.contains(id)) {
            await webRequest();
            result.add(id);
          }
        } finally {
          _mutex.release();
        }
      }

      timesRun++;
    }

    for (var timesRun = 0; timesRun < 10; timesRun++) {
      for (var id = 0; id < 5; id++) {
        addEvent(id);
      }
    }

    await waitUntil(() => timesRun == 50);

    expect(result.length, 5);
  });
}
