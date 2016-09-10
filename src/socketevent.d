module cheetah.socketevent;

import cheetah.socketeventargs;

/// Represents a socket event.
class SocketEvent(T) {
  private:
  /// The function pointer to the event handler.
  void function(SocketEventArgs!T) _f;
  /// The delegate to the event handler.
  void delegate(SocketEventArgs!T) _d;

  public:
  /**
  * Creates a new socket event based on a function pointer.
  * Params:
  *   f = The function pointer.
  */
  this(void function(SocketEventArgs!T) f) {
    _f = f;
  }

  /**
  * Creates a new socket event based on a delegate.
  * Params:
  *   d = The delegate.
  */
  this(void delegate(SocketEventArgs!T) d) {
    _d = d;
  }

  /*
  * Operator overload for calling the class as a function.
  * Params:
  *   e = The event args.
  */
  void opCall(SocketEventArgs!T e) {
    if (_f) {
      _f(e);
    }
    else if (_d) {
      _d(e);
    }
  }
}
