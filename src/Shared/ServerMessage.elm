module Shared.ServerMessage exposing (Message(..), decoder, encode)

import Json.Decode as JD
import Json.Encode as JE
import Shared.ClientPlayer as ClientPlayer
import Shared.ClientRoom as ClientRoom
import Shared.Direction as Direction exposing (Direction)



-- Messages that server sends to client


type
    Message
    -- Unsolicited
    = PlayerDisconnected String
    | PlayerEnteredRoom (Maybe Direction) ClientPlayer.Player
    | PlayerLeftRoom (Maybe Direction) ClientPlayer.Player
      -- Responses
    | AuthResponse ClientRoom.Room
    | MoveResponse ClientRoom.Room
    | ClientError String


encode : Message -> JE.Value
encode outbound =
    case outbound of
        ClientError text ->
            JE.list identity
                [ JE.string "ClientError"
                , JE.string text
                ]

        AuthResponse room ->
            JE.list identity
                [ JE.string "AuthResponse"
                , ClientRoom.encode room
                ]

        MoveResponse room ->
            JE.list identity
                [ JE.string "MoveResponse"
                , ClientRoom.encode room
                ]

        PlayerDisconnected uname ->
            JE.list identity
                [ JE.string "PlayerDisconnected"
                , JE.object [ ( "uname", JE.string uname ) ]
                ]

        PlayerEnteredRoom maybeFrom player ->
            JE.list identity
                [ JE.string "PlayerEnteredRoom"
                , JE.object
                    [ ( "player", ClientPlayer.encode player )
                    , ( "direction"
                      , case maybeFrom of
                            Just direction ->
                                Direction.encode direction

                            Nothing ->
                                JE.null
                      )
                    ]
                ]

        PlayerLeftRoom maybeTo player ->
            JE.list identity
                [ JE.string "PlayerLeftRoom"
                , JE.object
                    [ ( "player", ClientPlayer.encode player )
                    , ( "direction"
                      , case maybeTo of
                            Just direction ->
                                Direction.encode direction

                            Nothing ->
                                JE.null
                      )
                    ]
                ]


decoder : JD.Decoder Message
decoder =
    JD.index 0 JD.string
        |> JD.andThen
            (\messageName ->
                JD.index 1
                    (case messageName of
                        "ClientError" ->
                            JD.map ClientError JD.string

                        "AuthResponse" ->
                            JD.map AuthResponse ClientRoom.decoder

                        "MoveResponse" ->
                            JD.map MoveResponse ClientRoom.decoder

                        "PlayerEnteredRoom" ->
                            JD.map2 PlayerEnteredRoom
                                (JD.field "direction" (JD.nullable Direction.decoder))
                                (JD.field "player" ClientPlayer.decoder)

                        "PlayerLeftRoom" ->
                            JD.map2 PlayerLeftRoom
                                (JD.field "direction" (JD.nullable Direction.decoder))
                                (JD.field "player" ClientPlayer.decoder)

                        "PlayerDisconnected" ->
                            JD.map PlayerDisconnected
                                (JD.field "uname" JD.string)

                        _ ->
                            JD.fail "invalid message"
                    )
            )
