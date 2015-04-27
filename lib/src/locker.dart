part of locking;

enum _LockingStrategy { Normal, Reentrant }

class _Locker {
  final Queue<_Lock> queue = new Queue<_Lock>();

  final _LockingStrategy strategy;

  _Locker(this.strategy) {
    if (strategy == null) {
      throw new ArgumentError.notNull("strategy");
    }
  }

  _Lock lock(Zone zone) {
    if (zone == null) {
      throw new ArgumentError.notNull("zone");
    }

    var lock = new _Lock(zone);
    queue.add(lock);
    if (queue.length == 1) {
      lock.completer.complete();
    } else if (strategy == _LockingStrategy.Reentrant) {
      if (queue.first.zone == zone) {
        lock.completer.complete();
      }
    }

    return lock;
  }

  Zone unlock() {
    if (queue.length == 0) {
      throw new MutexStateException("Mutex is not held");
    }

    var lock = queue.removeFirst();
    if (lock.zone != Zone.current) {
      throw new MutexStateException("Current zone does not hold a mutex");
    }

    var completer = lock.completer;
    if (!completer.isCompleted) {
      completer.complete();
    }

    if (queue.length == 0) {
      return null;
    }

    lock = queue.first;
    completer = lock.completer;
    if (!completer.isCompleted) {
      completer.complete();
    }

    return lock.zone;
  }
}
