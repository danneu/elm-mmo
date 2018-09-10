port module Server.Ports exposing (onClientConnected, onClientDisconnected, onClientMessage, sendMessage)

import Json.Encode as JE
import Shared.ServerMessage as ServerMessage



-- JAVASCRIPT --> ELM


port onClientConnected : (Int -> msg) -> Sub msg


port onClientDisconnected : (Int -> msg) -> Sub msg


port onClientMessage : (( Int, String ) -> msg) -> Sub msg



-- ELM --> JAVASCRIPT


port messages : ( Int, JE.Value ) -> Cmd msg


sendMessage : Int -> ServerMessage.Message -> Cmd msg
sendMessage clientId message =
    messages ( clientId, ServerMessage.encode message )
