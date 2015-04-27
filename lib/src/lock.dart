part of locking;

abstract class _Lock {
  final Completer completer;

  final Zone zone;

  _Lock(this.zone) : this.completer = new Completer();

  void lock();

  bool unlock();
}

class _NormalLock extends _Lock {
  _NormalLock(Zone zone) : super(zone);

  void lock() {
    return;
  }

  bool unlock() {
    return true;
  }
}

class _ReentrantLock extends _Lock {
  int _holdCount = 0;

  _ReentrantLock(Zone zone) : super(zone);

  void lock() {
    _holdCount++;
  }

  bool unlock() {
    _holdCount--;
    assert(_holdCount >= 0);
    return _holdCount == 0;
  }
}
