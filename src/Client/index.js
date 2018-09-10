require('./index.scss')

const app = require('./Main.elm').Elm.Main.init({
    node: document.getElementById('main'),
    flags: {
        uname: window.location.hash.slice(1) || '',
    },
})

const endpoint = 'ws://localhost:8001'
let ws = null

app.ports.messages.subscribe((message) => {
    if (ws) {
        ws.send(JSON.stringify(message))
    } else {
        console.warn('ws not set')
    }
})

connect()

function connect(attempts = 0) {
    if (ws) {
        ws.close()
        return
    }

    ws = new WebSocket(endpoint)

    ws.onopen = () => {
        attempts = 0
        app.ports.onWebSocketChange.send(true)
    }

    ws.onerror = (event) => {}

    ws.onclose = (event) => {
        app.ports.onWebSocketChange.send(false)
        ws = null

        const delay = Math.min(1000 * attempts, 10000)
        console.log(attempts, delay + 'ms')

        setTimeout(() => {
            connect(attempts + 1)
        }, delay)
    }

    ws.onmessage = (envelope) => {
        console.log('message from server:', envelope.data)
        app.ports.onServerMessage.send(envelope.data)
    }
}
