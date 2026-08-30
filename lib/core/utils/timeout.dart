Future<T> withTimeout<T>(Future<T> future) {
  return future.timeout(
    const Duration(seconds: 25),
    onTimeout: () => throw StateError('Alfred is taking too long to respond.'),
  );
}