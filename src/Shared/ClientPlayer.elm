module Shared.ClientPlayer exposing (Player, decoder, encode, fromServerPlayer)

import Json.Decode as JD
import Json.Encode as JE
import Shared.ServerPlayer as ServerPlayer


type alias Player =
    { uname : String
    , hp : ( Int, Int )
    }


fromServerPlayer : ServerPlayer.Player -> Player
fromServerPlayer player =
    Player player.uname player.hp


encode : Player -> JE.Value
encode player =
    JE.object
        [ ( "uname", JE.string player.uname )
        , ( "hp", JE.list JE.int [ Tuple.first player.hp, Tuple.second player.hp ] )
        ]


decoder : JD.Decoder Player
decoder =
    JD.map2 Player
        (JD.field "uname" JD.string)
        (JD.field "hp"
            (JD.map2 Tuple.pair
                (JD.index 0 JD.int)
                (JD.index 1 JD.int)
            )
        )
