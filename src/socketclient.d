module cheetah.socketclient;

import vibe.core.net : TCPConnection;
import vibe.core.core : runTask;
import vibe.core.task : Task;

import cheetah.socketserver;
import cheetah.socketeventargs;
import cheetah.socketeventtype;
import cheetah.socketeventchain;

/// Wrapper for a tcp socket client.
class SocketClient(T) {
  private:
  /// The server the client is connected to.
  SocketServer!T _server;

  /// The low-level tcp connection.
  TCPConnection _connection;

  /// The reading task.
  Task _readTask;

  /// The event args for the client.
  SocketEventArgs!T _eventArgs;

  /// The connect events.
  SocketEventChain!T _connectEvents;

  /// The disconnect events.
  SocketEventChain!T _disconnectEvents;

  /// The receive events.
  SocketEventChain!T _receiveEvents;

  /// The error events.
  SocketEventChain!T _errorEvents;

  /// The buffer.
  ubyte[] _buffer;

  /// The current received amount of bytes.
  size_t _currentReceiveAmount;

  /// Boolean determining whether the client has been disconnected or not.
  bool _disconnected;

  /// Generic data that can be associated with the client.
  T _data;

  public:
  /**
  * Creates a new tcp client.
  * Params:
  *   server =  The server.
  *   connection = The low-level tcp connection.
  */
  this(SocketServer!T server, TCPConnection connection) {
    _server = server;
    _connection = connection;
    _eventArgs = new SocketEventArgs!T(_server, this);
  }

  @property {
    /// Gets the amount of available bytes for receive.
    size_t availableReceiveAmount() @trusted { return cast(size_t)_connection.leastSize; }

    /// Gets the current received amount of bytes.
    size_t currentReceiveAmount() pure const @safe { return _currentReceiveAmount; }

    /// Gets the current buffer.
    auto buffer() { return _buffer; }

    /// Gets a boolean determining whether the client has been disconnected or not.
    bool disconnected() pure const @safe { return _disconnected; }

    /// Gets a boolean determining whether the client is connected or not.
    bool connected() @trusted { return !_disconnected && _connection.connected; }

    /// Gets the generic data associated with the client.
    T data() { return _data; }

    /**
    * Sets the generic data associated with the client.
    * Params:
    *   newData = The generic data to associated with the client.
    */
    void data(T newData) {
      _data = newData;
    }
  }

  /**
  * Resets the current receive state.
  * Params:
  *   cachedAmount = (optional) An amount of cached bytes.
  */
  void resetReceive(size_t cachedAmount = 0) {
    _currentReceiveAmount = cachedAmount;

    _buffer = _currentReceiveAmount ? _buffer[$-_currentReceiveAmount .. $] : [];
  }

  /// Reads the current available bytes.
  void read() {
    read(availableReceiveAmount);
  }

  /**
  * Reads a specific amount of bytes.
  * Paramms:
  *   amount =  The amount of bytes to read.
  */
  void read(size_t amount) {
    if (!amount) {
      return;
    }

    auto available = availableReceiveAmount;

    if (amount > available) {
      amount = available;
    }

    try {
      auto temp = new ubyte[amount];

      _connection.read(temp);

      _buffer ~= temp;

      _currentReceiveAmount += amount;
    }
    catch (Exception e) {
      report(e);
    }
  }

  /**
  * Writes a buffer to the socket.
  * Params:
  *   buffer = The buffer to write.
  */
  void write(ubyte[] buffer) {
    try {
      _connection.write(buffer);
    }
    catch (Exception e) {
      report(e);
    }
  }

  /// Closes the socket.
  void close() {
    synchronized {
      if (_disconnected) {
        return;
      }

      _disconnected = true;

      try {
        if (_connection.connected) {
          _connection.close();
        }

        fireEvent(SocketEventType.disconnect, _eventArgs);
      }
      catch (Exception e) {
        report(e);
      }
    }
  }

  /**
  * Moves onto the next event handler in a chain.
  * Params:
  *   eventType = The event type to move onto next event handler.
  */
  void moveNext(SocketEventType eventType) {
    switch (eventType) {
      case SocketEventType.connect: {
        _connectEvents.moveNext();
        break;
      }
      case SocketEventType.disconnect: {
        _disconnectEvents.moveNext();
        break;
      }
      case SocketEventType.receive: {
        _receiveEvents.moveNext();
        break;
      }
      case SocketEventType.error: {
        _errorEvents.moveNext();
        break;
      }

      default: {
          _server.moveNext(eventType);
          break;
      }
    }
  }


  package(cheetah):
  @property {
    /// Gets the event args of the client.
    auto eventArgs() { return _eventArgs; }
  }

  /**
  * Sets up events for the client.
  * Params:
  *   connectEvents =     The connect events to setup.
  *   disconnectEvents =  The disconnect events to setup.
  *   receiveEvents =     The receive events to setup.
  *   errorEvents =       The error events to setup.
  */
  void setupEvents(SocketEventChain!T connectEvents, SocketEventChain!T disconnectEvents, SocketEventChain!T receiveEvents, SocketEventChain!T errorEvents) {
    if (connectEvents) _connectEvents = new SocketEventChain!T(connectEvents._events);
    if (disconnectEvents) _disconnectEvents = new SocketEventChain!T(disconnectEvents._events);
    if (receiveEvents) _receiveEvents = new SocketEventChain!T(receiveEvents._events);
    if (errorEvents) _errorEvents = new SocketEventChain!T(errorEvents._events);
  }

  /**
  * Fires a socket event.
  * Params:
  *   eventType = The event type to fire.
  *   e =         The event args to pass to the handler.
  */
  void fireEvent(SocketEventType eventType, SocketEventArgs!T e) {
    switch (eventType) {
      case SocketEventType.connect: {
        if (_connectEvents) {
          _connectEvents(e);
          return;
        }
        break;
      }
      case SocketEventType.disconnect: {
        if (_disconnectEvents) {
          _disconnectEvents(e);
          return;
        }
        break;
      }
      case SocketEventType.receive: {
        if (_receiveEvents) {
          _receiveEvents(e);
          return;
        }
        break;
      }
      case SocketEventType.error: {
        if (_errorEvents) {
          _errorEvents(e);
          return;
        }
        break;
      }

      default: break;
    }

    _server.fireEvent(eventType, e);
  }

  /**
  * Reports an error to the error handler.
  * Params:
  *   error =   The error to handle.
  *   server =  The server tied to the error.
  *   client =  The client tied to the error.
  */
  void report(Exception error) {
    fireEvent(SocketEventType.error, new SocketEventArgs!T(_server, this, error));
  }

  /// Processes the client.
  void process() {
    _readTask = runTask({
      try {
        while (connected) {
          if (_connection.leastSize) {
            fireEvent(SocketEventType.receive, _eventArgs);
          }
        }
      }
      catch (Exception e) {
        report(e);
      }
    });

    _readTask.join();

    close();
  }
}
