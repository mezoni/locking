part of locking;

class _Lock {
  final Completer completer;

  final Zone zone;

  _Lock(this.zone) : this.completer = new Completer();
}
