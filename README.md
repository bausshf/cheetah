# cheetah

Cheetah is a high performance event-based tcp server socket library based on vibe.d.

It's meant to be scalable in big server application, giving an easy to use and manage interface, but still keeping performance good. It uses an event-based type of interface where you attach event handlers to specific socket events.

Cheetah was written to be used in a game-server project and as a result had to be written in the best manner.

Simple server socket example:
https://github.com/bausshf/cheetah/wiki/Simple-Socket-Server-Example

Advanced server socket example:
https://github.com/ConquerOnlinePServer/5017-server
