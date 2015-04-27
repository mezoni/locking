part of locking;

abstract class _Locker<T extends _Lock> {
  final Map<Zone, T> locks = new LinkedHashMap<Zone, T>();

  final Queue<T> queue = new Queue<T>();

  Future lock(Zone zone, _ByRef<bool> locked) {
    if (zone == null) {
      throw new ArgumentError.notNull("zone");
    }

    locked.value = false;
    var lock = locks[zone];
    if (lock == null) {
      lock = newLock(zone);
      locks[zone] = lock;
      queue.add(lock);
      if (queue.length == 1) {
        locked.value = true;
        lock.completer.complete();
      }
    }

    lock.lock();
    return lock.completer.future;
  }

  T newLock(Zone zone);

  Zone unlock(Zone zone) {
    if (zone == null) {
      throw new ArgumentError.notNull("zone");
    }

    if (locks.isEmpty) {
      _error();
    }

    var lock = locks[zone];
    if (lock.zone != zone) {
      _error();
    }

    if (lock.unlock()) {
      locks.remove(zone);
      queue.removeFirst();
      if (queue.length != 0) {
        var next = queue.first;
        next.completer.complete();
        return next.zone;
      }

      return null;
    }

    return zone;
  }

  void _error() {
    throw new MutexStateException("Current zone is not the owner of the mutex");
  }
}

class _NormalLocker extends _Locker {
  _NormalLock newLock(Zone zone) {
    if (zone == null) {
      throw new ArgumentError.notNull("zone");
    }

    return new _NormalLock(zone);
  }
}

class _ReentrantLocker extends _Locker {
  _ReentrantLock newLock(Zone zone) {
    if (zone == null) {
      throw new ArgumentError.notNull("zone");
    }

    return new _ReentrantLock(zone);
  }
}
