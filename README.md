# elm-mmo

A proof-of-concept implementation of a MUD-like multiplayer
game over WebSockets built with [Elm][elm].

-   Client talks to a native browser `WebSocket` over ports.
-   Server talks to a Node.js websocket implementation ([ws][ws]) over ports.
-   Client and server share Elm types.

The game is basically a map of connected rooms. Players can move
North/South/East/West between rooms. When players enter/leave rooms or
connect/disconnect, this info is broadcast to other players in a room.

![screenshot](/screenshot.png)

[elm]: https://elm-lang.org/
[ws]: https://www.npmjs.com/package/ws

## Demo

Open three terminal panes at project root.

Build and serve client (rebuilds on file change):

    npm run client:start

Build server (rebuilds on file change):

    npm run server:watch

Start server (reboots on file change):

    npm run server:nodemon

Open client: <http://localhost:8000>.

For convenience, url #hash will pre-fill the username of each client
to make dev/testing quicker:

-   http://localhost:8080/#foo
-   http://localhost:8080/#bar

The demo map is a donut:

    [][][]
    []  []
    [][][]

Players spawn in the north-west room.

## License

MIT
