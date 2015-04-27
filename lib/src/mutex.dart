part of locking;

abstract class Mutex {
  static Zone _zone;

  Future acquire();

  void release();

  static void broadcast(Object contition) {
    // TODO:
    throw new UnimplementedError();
  }

  static void signal(Object contition) {
    // TODO:
    throw new UnimplementedError();
  }

  static Future wait(Object contition, [Duration time]) {
    // TODO:
    throw new UnimplementedError();
  }
}

class NormalMutex extends _Mutex implements Mutex {
  static final _NormalLocker _locker = new _NormalLocker();

  _NormalLocker get locker {
    return _locker;
  }
}

class ReentrantMutex extends _Mutex implements Mutex {
  static final _ReentrantLocker _locker = new _ReentrantLocker();

  _ReentrantLocker get locker {
    return _locker;
  }
}

abstract class _Mutex {
  _Locker get locker;

  Future acquire() {
    var zone = Zone.current;
    var locker = this.locker;
    var locked = new _ByRef<bool>();
    var future = locker.lock(zone, locked);
    if (locked.value) {
      Mutex._zone = zone;
    }

    return future;
  }

  void release() {
    var zone = Zone.current;
    if (zone != Mutex._zone) {
      _error("Current zone does not hold this mutex");
    }

    var locker = this.locker;
    Mutex._zone = locker.unlock(zone);
  }

  void _error(String message) {
    throw new MutexStateException(message);
  }

  static void broadcast(Object contition) {
    //
  }

  static void signal(Object contition) {
    //
  }

  static Future wait(Object contition, [Duration time]) {
    //
  }
}
