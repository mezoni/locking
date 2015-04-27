import "dart:async";

import "package:locking/locking.dart";
import "package:unittest/unittest.dart";

Future main() async {
  var list = [];
  for (var i = 2; i >= 0; i--) {
    // Requires different zones for concurency
    list.add(runZoned(() async => outer(i)));
  }

  await Future.wait(list);
}

int _running = 0;

Object _obj = new Object();

Future outer(int i) async {
  await lock(_obj, () async {
    print("before inner $i");
    await inner(i);
    print("after inner $i");
  });
}

Future inner(int i) async {
  await lock(_obj, () async {
    _running++;
    await sleep(new Duration(milliseconds: i * 200));
    expect(_running, 1, reason : "_running $_running != 1");
    _running--;
    print("inner $i");
  });
}
