module cheetah.socketserver;

import vibe.core.net : listenTCP;
import vibe.core.net : TCPListener, TCPConnection;

import cheetah.socketeventtype;
import cheetah.socketeventchain;
import cheetah.socketevent;
import cheetah.socketclient;
import cheetah.socketeventargs;

/// Wrapper for a tcp socket server.
class SocketServer(T) {
  private:
  /// The IP Address tied to the server.
  string _ip;

  /// The port tied to the server.
  ushort _port;

  /// All listeners tied to the server.
  TCPListener[] _listeners;

  /// The event args tied to the server.
  SocketEventArgs!T _eventArgs;

  /// The start events.
  SocketEventChain!T _startEvents;

  /// The stop events.
  SocketEventChain!T _stopEvents;

  /// The connect events.
  SocketEventChain!T _connectEvents;

  /// The disconnect events.
  SocketEventChain!T _disconnectEvents;

  /// The receive events.
  SocketEventChain!T _receiveEvents;

  /// The error events.
  SocketEventChain!T _errorEvents;

  /// Boolean determining whether the connect events should be copied.
  bool _copyConnectEvents;

  /// Boolean determining whether the disconnect events should be copied.
  bool _copyDisconnectEvents;

  /// Boolean determining whether the receive events should be copied.
  bool _copyReceiveEvents;

  /// Boolean determining whether the error events should be copied.
  bool _copyErrorEvents;

  /// Boolean determining whether the server is running or not.
  bool _running;

  public:
  /**
  * Creates a new tcp socket server.
  * Params:
  *   ip =    The IP address to listen for connections at.
  *   port =  The port to listen for connections at.
  */
  this(string ip, ushort port) {
    _ip = ip;
    _port = port;
    _eventArgs = new SocketEventArgs!T(this, null);
  }

  /**
  * Creates a new tcp socket server.
  * Params:
  *   port =  The port to listen for connections at.
  */
  this(ushort port) {
    _port = port;
    _eventArgs = new SocketEventArgs!T(this, null);
  }

  @property {
    /// Gets a boolean determining whether the connect events should be copied or not.
    bool copyConnectEvents() { return _copyConnectEvents; }

    /**
    * Sets a boolean determining whether the connect events should be copied or not.
    * Params:
    *   shouldCopy = Boolean determining whether the connect events should be copied or not.
    */
    void copyConnectEvents(bool shouldCopy) {
      _copyConnectEvents = shouldCopy;
    }

    /// Gets a boolean determining whether the disconnect events should be copied or not.
    bool copyDisconnectEvents() { return _copyDisconnectEvents; }

    /**
    * Sets a boolean determining whether the disconnect events should be copied or not.
    * Params:
    *   shouldCopy = Boolean determining whether the disconnect events should be copied or not.
    */
    void copyDisconnectEvents(bool shouldCopy) {
      _copyDisconnectEvents = shouldCopy;
    }

    /// Gets a boolean determining whether the receive events should be copied or not.
    bool copyReceiveEvents() { return _copyReceiveEvents; }

    /**
    * Sets a boolean determining whether the receive events should be copied or not.
    * Params:
    *   shouldCopy = Boolean determining whether the receive events should be copied or not.
    */
    void copyReceiveEvents(bool shouldCopy) {
      _copyReceiveEvents = shouldCopy;
    }

    /// Gets a boolean determining whether the error events should be copied or not.
    bool copyErrorEvents() { return _copyErrorEvents; }

    /**
    * Sets a boolean determining whether the error events should be copied or not.
    * Params:
    *   shouldCopy = Boolean determining whether the error events should be copied or not.
    */
    void copyErrorEvents(bool shouldCopy) {
      _copyErrorEvents = shouldCopy;
    }
  }

  /**
  * Attachs an event.
  * Params:
  *   eventType = The event type to attach.
  *   event =     The event handler to attach.
  */
  void attach(SocketEventType eventType, SocketEvent!T event) {
    final switch (eventType) {
      case SocketEventType.start: {
        _startEvents = new SocketEventChain!T([event]);
        break;
      }
      case SocketEventType.stop: {
        _stopEvents = new SocketEventChain!T([event]);
        break;
      }
      case SocketEventType.connect: {
        _connectEvents = new SocketEventChain!T([event]);
        break;
      }
      case SocketEventType.disconnect: {
        _disconnectEvents = new SocketEventChain!T([event]);
        break;
      }
      case SocketEventType.receive: {
        _receiveEvents = new SocketEventChain!T([event]);
        break;
      }
      case SocketEventType.error: {
        _errorEvents = new SocketEventChain!T([event]);
        break;
      }
    }
  }

  /**
  * Attachs a chain of events.
  * Params:
  *   eventType = The event type to attach.
  *   events =     The chain of event handlers to attach.
  */
  void attach(SocketEventType eventType, SocketEvent!T[] events) {
    final switch (eventType) {
      case SocketEventType.start: {
        _startEvents = new SocketEventChain!T(events);
        break;
      }
      case SocketEventType.stop: {
        _stopEvents = new SocketEventChain!T(events);
        break;
      }
      case SocketEventType.connect: {
        _connectEvents = new SocketEventChain!T(events);
        break;
      }
      case SocketEventType.disconnect: {
        _disconnectEvents = new SocketEventChain!T(events);
        break;
      }
      case SocketEventType.receive: {
        _receiveEvents = new SocketEventChain!T(events);
        break;
      }
      case SocketEventType.error: {
        _errorEvents = new SocketEventChain!T(events);
        break;
      }
    }
  }

  /**
  * Moves onto the next event handler in a chain.
  * Params:
  *   eventType = The event type to move onto next event handler.
  */
  void moveNext(SocketEventType eventType) {
    final switch (eventType) {
      case SocketEventType.start: {
        _startEvents.moveNext();
        break;
      }
      case SocketEventType.stop: {
        _stopEvents.moveNext();
        break;
      }
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
    }
  }

  /// Starts the server.
  void start() {
    if (_running) {
      return;
    }

    try {
      fireEvent(SocketEventType.start, _eventArgs);
    }
    catch (Exception e) {
      report(e, this);
    }

    setup();

    _running = true;
  }

  /// Stops the server.
  void stop() {
    if (!_running) {
      return;
    }

    try {
      foreach (listener; _listeners) {
        listener.stopListening();
      }
    }
    catch (Exception e) {
      report(e, this);
    }

    _running = false;
  }

  package(cheetah) {
    /**
    * Fires a socket event.
    * Params:
    *   eventType = The event type to fire.
    *   e =         The event args to pass to the handler.
    */
    void fireEvent(SocketEventType eventType, SocketEventArgs!T e) {
      final switch (eventType) {
        case SocketEventType.start: {
          if (_startEvents) _startEvents(e);
          break;
        }
        case SocketEventType.stop: {
          if (_stopEvents) _stopEvents(e);
          break;
        }
        case SocketEventType.connect: {
          if (_connectEvents) _connectEvents(e);
          break;
        }
        case SocketEventType.disconnect: {
          if (_disconnectEvents) _disconnectEvents(e);
          break;
        }
        case SocketEventType.receive: {
          if (_receiveEvents) _receiveEvents(e);
          break;
        }
        case SocketEventType.error: {
          if (_errorEvents) _errorEvents(e);
          break;
        }
      }
    }

    /**
    * Reports an error to the error handler.
    * Params:
    *   error =   The error to handle.
    *   server =  The server tied to the error.
    *   client =  The client tied to the error.
    */
    void report(Exception error, SocketServer!T server = null, SocketClient!T client = null) {
      fireEvent(SocketEventType.error, new SocketEventArgs!T(server, client, error));
    }
  }

  private:
  /// Sets up the listeners for the server.
  void setup() {
    try {
      if (_ip) {
        _listeners = [listenTCP(_port, &handleConnections, _ip)];
      }
      else {
        _listeners = listenTCP(_port, &handleConnections);
      }
    }
    catch (Exception e) {
      report(e, this);
    }
  }

  /**
  * Handles a connection.
  * Params:
  *   connection =  The low-level tcp connection that has connected.
  */
  void handleConnections(TCPConnection connection) {
    auto client = new SocketClient!T(this, connection);
    client.setupEvents(
      _copyConnectEvents ? _connectEvents : null,
      _copyDisconnectEvents ? _disconnectEvents : null,
      _copyReceiveEvents ? _receiveEvents : null,
      _copyErrorEvents ? _errorEvents : null
    );

    client.fireEvent(SocketEventType.connect, client.eventArgs);

    client.process();
  }
}
