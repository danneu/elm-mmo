module Shared.ClientRoom exposing (Room, decoder, encode, nullRoom)

import Json.Decode as JD
import Json.Encode as JE
import Shared.ClientPlayer as ClientPlayer
import Shared.Direction as Direction exposing (Direction)



-- Room data contains the room's list of players and exits
-- to be sent to the client.


type alias Room =
    { title : String
    , desc : String
    , players : List ClientPlayer.Player
    , exits : List Direction
    }


{-| This is a nonsensical room the user finds themself
in when we make a mistake. Used with Maybe.withDefault
when grabbing rooms from the world.
-}
nullRoom : Room
nullRoom =
    { title = "Null Room", desc = "", players = [], exits = [] }


encode : Room -> JE.Value
encode room =
    JE.object
        [ ( "title", JE.string room.title )
        , ( "desc", JE.string room.desc )
        , ( "players", JE.list ClientPlayer.encode room.players )
        , ( "exits", JE.list Direction.encode room.exits )
        ]


decoder : JD.Decoder Room
decoder =
    JD.map4 Room
        (JD.field "title" JD.string)
        (JD.field "desc" JD.string)
        (JD.field "players" (JD.list ClientPlayer.decoder))
        (JD.field "exits" (JD.list Direction.decoder))
