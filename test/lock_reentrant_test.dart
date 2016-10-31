import "dart:async";

import "package:locking/locking.dart";
import "package:test/test.dart";

Future main() async {
  test("lock reentrant", () async {
    var list = [];
    for (var i = 2; i >= 0; i--) {
      // Requires different zones for concurrency
      list.add(runZoned(() async => outer(i)));
    }

    await Future.wait(list);
  });
}

int _running = 0;

Object _obj = new Object();

Future outer(int i) async {
  await lock(_obj, () async {
    //print("before inner $i");
    await inner(i);
    //print("after inner $i");
  });
}

Future inner(int i) async {
  // If the lock was not reentrant, this lock will block because it was
  // already acquired by the outer function.
  await lock(_obj, () async {
    _running++;
    await sleep(new Duration(milliseconds: i * 200));
    expect(_running, equals(1), reason: "concurrent execution not prevented");
    _running--;
    //print("inner $i");
  });
}
