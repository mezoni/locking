part of locking;

class Objects {
  static final Expando _monitors = new Expando();

  /**
   * Wakes up a single zone that is waiting on this object's monitor.
   */
  Future notify(Object object) {
    _checkObject(object, "notify");
  }

  /**
   * Wakes up all zone that are waiting on this object's monitor.
   */
  Future notifyAll(Object object) {
    _checkObject(object, "notify");
  }

  /**
   * Causes the current zone to wait until either another zone invokes the
   * notify() method or the notifyAll() method for this object, or a specified
   * amount of time has elapsed.
   */
  static Future wait(Object object, [Duration timeout]) async {
    _checkObject(object, "wait");
    var zone = Zone.current;
    _Monitor monitor = _monitors[object];
    if (monitor != null) {
      var owner = monitor.zone;
      if (owner == zone) {
        throw new MutexStateException("Current zone already owns the object's monitor");
      } else {
        throw new MutexStateException("Current zone is not the owner of the object's monitor");
      }
    }

    monitor = new _Monitor(zone);
    _monitors[object] = monitor;
    var completer = monitor.completer;
    if (timeout != null) {
      new Timer(timeout, () {
        completer.complete();
      });
    }

    return completer.future;
  }

  static void _checkObject(Object object, String operation) {
    if (object == null || object is num || object is bool || object is String) {
      throw new ArgumentError("Unable to $operation the object of type '${object.runtimeType}'");
    }
  }
}

class _Monitor {
  Completer completer = new Completer();

  Zone zone;

  Set<Zone> zones = new Set<Zone>();

  _Monitor(this.zone) {
    if (zone == null) {
      throw new ArgumentError.notNull("owner");
    }
  }
}
