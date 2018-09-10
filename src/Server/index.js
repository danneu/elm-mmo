const WebSocket = require('ws')

const app = require('./Main.elm').Elm.Main.init({
    flags: null,
})

const wss = new WebSocket.Server({
    port: 8001,
})

const generateClientId = (() => {
    let prevClientId = 0
    return () =>
        (prevClientId = (prevClientId + 1) % (Number.MAX_SAFE_INTEGER - 1))
})()

const clients = new Map()

wss.on('connection', (ws) => {
    const clientId = generateClientId()
    clients.set(clientId, ws)
    app.ports.onClientConnected.send(clientId)

    ws.on('message', (envelope) => {
        app.ports.onClientMessage.send([clientId, envelope])
    })

    ws.on('close', () => {
        clients.delete(clientId)
        app.ports.onClientDisconnected.send(clientId)
    })
})

app.ports.messages.subscribe(([clientId, message]) => {
    const ws = clients.get(clientId)
    ws.send(JSON.stringify(message))
})
