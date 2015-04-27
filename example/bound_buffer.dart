import "dart:async";

import "package:locking/locking.dart";

Future main() async {
  var length = 5;
  var buffer = new BoundedBuffer<String>(length);
  var t1 = await runZoned(() async {
    for (var i = 0; i < length * 2; i++) {
      var string = await buffer.take();
      print("take: $string");
    }
  });

  var t2 = await runZoned(() async {
    for (var i = 0; i < length * 2; i++) {
      var string = "String $i";
      await buffer.put(string);
      print("put: $string");
    }
  });

  await Future.wait([t1, t2]);
}

class BoundedBuffer<T> {
  final int length;

  int _count = 0;

  List<T> _items;

  final Mutex _mutex = new ReentrantMutex();

  Object _notFull = new Object();

  Object _notEmpty = new Object();

  int _putptr = 0;

  int _takeptr = 0;

  BoundedBuffer(this.length) {
    if (length == 0) {
      throw new ArgumentError.notNull("length");
    }

    if (length < 0) {
      throw new RangeError.value(length, "length");
    }

    _items = new List<T>(length);
  }

  Future put(T x) async {
    await _mutex.acquire();
    try {
      while (_count == _items.length) {
        await Mutex.wait(_notFull);
      }

      _items[_putptr] = x;
      if (++_putptr == _items.length) {
        _putptr = 0;
      }

      ++_count;
      await Mutex.signal(_notEmpty);
    } finally {
      _mutex.release();
    }
  }

  Future<T> take() async {
    await _mutex.acquire();
    try {
      while (_count == 0) {
        await Mutex.wait(_notEmpty);
      }

      var x = _items[_takeptr];
      if (++_takeptr == _items.length) {
        _takeptr = 0;
      }

      --_count;
      await Mutex.signal(_notFull);
      return x;
    } finally {
      _mutex.release();
    }
  }
}
