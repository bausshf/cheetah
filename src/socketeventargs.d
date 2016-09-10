module cheetah.socketeventargs;

import cheetah.socketserver;
import cheetah.socketclient;

/// Wrapper for socket event arguments
class SocketEventArgs(T) {
  private:
  /// The server.
  SocketServer!T _server;

  /// The client.
  SocketClient!T _client;

  /// The error.
  Exception _error;

  public:
  /**
  * Creates a new socket event argument wrapper.
  * Params:
  *   server =  The server.
  *   client =  The client.
  *   error =   (optional) The error.
  */
  this(SocketServer!T server, SocketClient!T client, Exception error = null) {
    _server = server;
    _client = client;
    _error = error;
  }

  @property {
    /// Gets the server.
    auto server() { return _server; }

    /// Gets the client.
    auto client() { return _client; }

    /// Gets the error.
    auto error() { return _error; }

    /// Gets the amount of available bytes for receive.
    size_t availableReceiveAmount() @trusted { return _client.availableReceiveAmount; }

    /// Gets the current received amount of bytes.
    size_t currentReceiveAmount() pure const @safe { return _client.currentReceiveAmount; }

    /// Gets the current buffer.
    auto buffer() { return _client.buffer; }
  }

  /**
  * Resets the current receive state.
  * Params:
  *   cachedAmount = (optional) An amount of cached bytes.
  */
  void resetReceive(size_t cachedAmount = 0) {
    _client.resetReceive(cachedAmount);
  }
}
