part of locking;

final Expando _objects = new Expando();

Future lock(Object object, void action()) async {
  Expando mutexes = _objects[object];
  if (mutexes == null) {
    mutexes = new Expando();
    _objects[object] = mutexes;
  }

  var zone = Zone.current;
  Mutex mutex = mutexes[zone];
  if (mutex == null) {
    mutex = new ReentrantMutex();
    mutexes[zone] = mutex;
  }

  await mutex.acquire();
  try {
    await action();
  } finally {
    mutex.release();
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
