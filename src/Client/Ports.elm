port module Client.Ports exposing (onServerMessage, onWebSocketChange, sendMessage)

import Json.Encode as JE
import Shared.ClientMessage as ClientMessage



-- JAVASCRIPT --> ELM


port onWebSocketChange : (Bool -> msg) -> Sub msg


port onServerMessage : (String -> msg) -> Sub msg



-- ELM --> JAVASCRIPT


port messages : JE.Value -> Cmd msg


sendMessage : ClientMessage.Message -> Cmd msg
sendMessage message =
    messages (ClientMessage.encode message)
