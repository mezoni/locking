part of locking;

class _ByRef<T> {
  T value;

  _ByRef([this.value]);

  String toString() {
    return value.toString();
  }
}
