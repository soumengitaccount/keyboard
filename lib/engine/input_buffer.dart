class InputBuffer {
  final StringBuffer _buffer = StringBuffer();

  String get text => _buffer.toString();

  void add(
    String value,
  ) {
    _buffer.write(value);
  }

  void removeLast() {
    final current = _buffer.toString();

    if (current.isEmpty) {
      return;
    }

    _buffer.clear();

    _buffer.write(
      current.substring(
        0,
        current.length - 1,
      ),
    );
  }

  void clear() {
    _buffer.clear();
  }
}
