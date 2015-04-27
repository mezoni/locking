locking
=====

The "locking" prevents the simultaneous execution of the "locked" code in the different zones.

Version: 0.0.

Current implementation of locking:

```dart
final Expando _mutexes = new Expando();

Future lock(Object object, void action()) async {
  ReentrantMutex mutex = _mutexes[object];
  if (mutex == null) {
    mutex = new ReentrantMutex();
    _mutexes[object] = mutex;
  }

  await mutex.acquire();
  try {
    await action();
  } finally {
    mutex.release();
  }
}
```

Example:

```dart
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
```

Output:

```
=================
Different zones
=================
task 0: [task 0]
task 1: [task 0, task 1]
task 1: finished
task 0: finished
task 2: [task 2]
task 2: finished
task 3: [task 3]
task 3: finished
=================
The same zone
=================
task 0: [task 0]
task 1: [task 0, task 1]
task 2: [task 0, task 1, task 2]
task 3: [task 0, task 1, task 2, task 3]
task 3: finished
task 2: finished
task 1: finished
task 0: finished
```