part of lock;

Future lock(Object obj, void action()) async {
  await Monitor.enter(obj);
  try {
    await action();
  } finally {
    Monitor.exit(obj);
  }
}

Future sleep([Duration duration]) async {
  if (duration == null) {
    duration = new Duration(seconds: 0);
  }

  var completer = new Completer();
  new Timer(duration, () {
    completer.complete();
  });

  return completer.future;
}

class Monitor {
  static final Expando<Object> _objects = new Expando<Object>();

  static Future enter(Object obj) {
    _checkObject(obj);
    _Locker locker = _objects[obj];
    if (locker == null) {
      locker = new _Locker();
      _objects[obj] = locker;
    }

    return locker.enter(Zone.current);
  }

  static void exit(Object obj) {
    _checkObject(obj);
    _Locker locker = _objects[obj];
    if (locker == null) {
      _Locker._error();
    }

    locker.exit(Zone.current);
  }

  static void _checkObject(Object obj) {
    if (obj == null || obj is num || obj is bool || obj is String) {
      throw new ArgumentError("Unable to lock the object of type '${obj.runtimeType}'");
    }
  }
}

class _Counter {
  Completer completer;

  int count = 0;

  Zone zone;

  _Counter(this.completer, this.zone);
}

class _Locker {
  final Map<Zone, _Counter> counters = <Zone, _Counter>{};

  Queue<_Counter> queue = new Queue<_Counter>();

  Future enter(Zone zone) {
    if (zone == null) {
      throw new ArgumentError.notNull("zone");
    }

    var counter = counters[zone];
    if (counter == null) {
      counter = new _Counter(new Completer(), zone);
      counters[zone] = counter;
      if (queue.isEmpty) {
        counter.completer.complete();
      }

      queue.add(counter);
    }

    counter.count++;
    return counter.completer.future;
  }

  void exit(Zone zone) {
    if (zone == null) {
      throw new ArgumentError.notNull("zone");
    }

    if (queue.isEmpty) {
      _error();
    }

    var counter = queue.first;
    if (counter == null) {
      _error();
    }

    if (counter.zone != zone) {
      _error();
    }

    counter.count--;
    if (counter.count == 0) {
      queue.removeFirst();
      counters.remove(zone);
      if (!queue.isEmpty) {
        var next = queue.first;
        next.completer.complete();
      }
    }
  }

  static void _error() {
    throw new ArgumentError("Specified object is not locked by the current zone");
  }
}
