module cheetah.socketeventchain;

import cheetah.socketevent;
import cheetah.socketeventargs;

/// Wrapper for a socket event chain.
class SocketEventChain(T) {
  package(cheetah):
  /// The socket events.
  SocketEvent!T[] _events;

  private:
  /// The execution index.
  size_t _executionIndex;

  public:
  /**
  * Creates a new socket event chain.
  * Params:
  *   events =  The events to chain.
  */
  this(SocketEvent!T[] events) {
    _events = events;
  }

  /// Moves onto the next socket event.
  void moveNext() {
    _executionIndex++;

    if (_executionIndex == _events.length) {
      _executionIndex = 0;
    }
  }

  /*
  * Operator overload for calling the class as a function.
  * Params:
  *   e = The event args.
  */
  void opCall(SocketEventArgs!T e) {
    if (!_events) {
      return;
    }

    auto event = _events[_executionIndex];

    if (event) {
      event(e);
    }
  }
}
