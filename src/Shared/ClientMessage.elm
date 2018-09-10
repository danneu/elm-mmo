module Shared.ClientMessage exposing (Message(..), decoder, encode)

import Json.Decode as JD
import Json.Encode as JE
import Shared.Direction as Direction exposing (Direction)



-- These are messages that client sends server


type Message
    = AuthRequest String
    | MoveRequest Direction


decoder : JD.Decoder Message
decoder =
    JD.index 0 JD.string
        |> JD.andThen
            (\messageName ->
                JD.index 1
                    (case messageName of
                        "AuthRequest" ->
                            JD.map AuthRequest
                                (JD.field "uname" JD.string)

                        "MoveRequest" ->
                            JD.map MoveRequest
                                (JD.field "direction" Direction.decoder)

                        _ ->
                            JD.fail "invalid message"
                    )
            )


encode : Message -> JE.Value
encode message =
    case message of
        AuthRequest uname ->
            JE.list identity
                [ JE.string "AuthRequest"
                , JE.object [ ( "uname", JE.string uname ) ]
                ]

        MoveRequest direction ->
            JE.list identity
                [ JE.string "MoveRequest"
                , JE.object [ ( "direction", Direction.encode direction ) ]
                ]
