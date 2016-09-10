module cheetah.socketeventtype;

/// Enumeration of socket event types.
enum SocketEventType : size_t {
  /// Event triggered when the server starts.
  start,
  /// Event triggered when the server stops.
  stop,
  /// Event triggered when a client connects.
  connect,
  /// Event triggered when a client disconnects.
  disconnect,
  /// Event triggered when data is received.
  receive,
  /// Event triggered when an error occurres.
  error
}
