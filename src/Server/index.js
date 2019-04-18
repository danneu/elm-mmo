const WebSocket = require('ws')

// Our websocket server takes manages the connection but
// sends messages into our Elm app which implements
// our server business logic.
const app = require('./Main.elm').Elm.Main.init({
    flags: null,
})

const server = new WebSocket.Server({
    port: 8001,
})
console.log('websocket server listening on :8001')

let prevId = 0
const clients = new Map()

server.on('connection', (socket) => {
    const clientId = ++prevId
    clients.set(clientId, socket)
    app.ports.onClientConnected.send(clientId)

    socket.on('message', (envelope) => {
        app.ports.onClientMessage.send([clientId, envelope])
    })

    socket.on('close', () => {
        clients.delete(clientId)
        app.ports.onClientDisconnected.send(clientId)
    })
})

app.ports.messages.subscribe(([clientId, message]) => {
    const socket = clients.get(clientId)
    socket.send(JSON.stringify(message))
})
