import "dart:async";

import "package:locking/locking.dart";

Future main() async {
  var list = [];
  for (var i = 2; i >= 0; i--) {
    list.add(runZoned(() async => outer(i)));
  }

  await Future.wait(list);
}

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
    await sleep(new Duration(milliseconds: i * 200));
    print("inner $i");
  });
}
