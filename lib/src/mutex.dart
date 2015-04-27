part of locking;

abstract class Mutex {
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
  final _Locker locker = new _Locker(_LockingStrategy.Normal);
}

class ReentrantMutex extends _Mutex implements Mutex {
  final _Locker locker = new _Locker(_LockingStrategy.Reentrant);
}

abstract class _Mutex {
  _Locker get locker;

  Future acquire() {
    var zone = Zone.current;
    var lock = locker.lock(zone);
    var completer = lock.completer;
    return completer.future;
  }

  void release() {
    var locker = this.locker;
    locker.unlock();
  }

  Future<bool> tryAcquire([Duration timeout]) async {
    //
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
