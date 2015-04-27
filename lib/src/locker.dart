part of locking;

enum _LockingStrategy { Normal, Reentrant }

class _Locker {
  final _LockingStrategy strategy;

  int _holdCount = 0;

  final Queue<_Lock> _locked = new Queue<_Lock>();

  final Queue<_Lock> _pending = new Queue<_Lock>();

  Zone _zone;

  _Locker(this.strategy) {
    if (strategy == null) {
      throw new ArgumentError.notNull("strategy");
    }
  }

  _Lock lock(Zone zone) {
    if (zone == null) {
      throw new ArgumentError.notNull("zone");
    }

    _holdCount++;
    var lock = new _Lock(zone);
    var completer = lock.completer;
    if (_locked.length == 0) {
      _complete(lock);
    } else if (strategy == _LockingStrategy.Reentrant) {
      if (zone == _zone) {
        _complete(lock);
      }
    }

    if (!completer.isCompleted) {
      _pending.add(lock);
    }

    return lock;
  }

  void unlock() {
    if (--_holdCount < 0) {
      throw new MutexStateException("Mutex is not held");
    }

    if (_locked.length > 0) {
      var lock = _locked.removeFirst();
      if (lock.zone != Zone.current) {
        throw new MutexStateException("Current zone does not hold a mutex");
      }

      if (_locked.length != 0) {
        return;
      }
    }

    if (_pending.length != 0) {
      var lock = _pending.removeFirst();
      _complete(lock);
      return;
    }
  }

  void _complete(_Lock lock, [Object value]) {
    lock.completer.complete(value);
    _zone = lock.zone;
    _locked.addFirst(lock);
  }
}
