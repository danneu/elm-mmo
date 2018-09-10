module Shared.ServerPlayer exposing (Player)


type alias Player =
    { uname : String
    , hp : ( Int, Int )
    , loc : ( Int, Int )
    }
