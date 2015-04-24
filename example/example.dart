import "dart:async";

import "package:locking/lock.dart";

Future main() async {
  print("=================");
  print("Different zones");
  print("=================");
  var t1 = task("task 0", 800);
  var t2 = task("task 1", 400);
  var t3 = runZoned(() => task("task 2", 200));
  var t4 = runZoned(() => task("task 3", 100));
  await Future.wait([t1, t2, t3, t4]);

  print("=================");
  print("The same zone");
  print("=================");
  t1 = task("task 0", 800);
  t2 = task("task 1", 400);
  t3 = task("task 2", 200);
  t4 = task("task 3", 100);
  await Future.wait([t1, t2, t3, t4]);
}

Object _obj = new Object();

List _running = [];

Future task(String name, int ms) async {
  await lock(_obj, () async {
    _running.add(name);
    print("$name: [${_running.join(", ")}]");
    await sleep(new Duration(milliseconds: ms));
    _running.remove(name);
    print("$name: finished");
  });
}
