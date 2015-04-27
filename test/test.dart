import "dart:async";

import "package:locking/locking.dart";
import "package:unittest/unittest.dart";

var _obj = new Object();

Future main() async {
  await runZoned(() async {
    await lock(_obj, () async {
      try {
        print("x1");
        await install();
        print("x2");
      } finally {
        print("x3");
      }
    });
  });

  await runZoned(() async {
    await lock(_obj, () async {
      try {
        print("z1");
        await install();
        print("z2");
      } finally {
        print("z3");
      }
    });
  });
}

Future install() async {
  try {
    await new Future(() {
      print("y1");
    });
  } finally {
    print("y2");
  }
}
