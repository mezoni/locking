part of locking;

final Expando _mutexes = new Expando();

Future lock(Object object, void action()) async {
  ReentrantMutex mutex = _mutexes[object];
  if (mutex == null) {
    mutex = new ReentrantMutex();
    _mutexes[object] = mutex;
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
