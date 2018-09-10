module Shared.Direction exposing (Direction(..), apply, decoder, encode, fromKey, list, opposite, toString)

import Json.Decode as JD
import Json.Encode as JE


type Direction
    = North
    | South
    | East
    | West


toString : Direction -> String
toString direction =
    case direction of
        North ->
            "North"

        South ->
            "South"

        East ->
            "East"

        West ->
            "West"


list : List Direction
list =
    [ North, South, East, West ]


opposite : Direction -> Direction
opposite direction =
    case direction of
        North ->
            South

        South ->
            North

        West ->
            East

        East ->
            West


apply : ( Int, Int ) -> Direction -> ( Int, Int )
apply ( x, y ) direction =
    case direction of
        North ->
            ( x, y - 1 )

        South ->
            ( x, y + 1 )

        East ->
            ( x + 1, y )

        West ->
            ( x - 1, y )


encode : Direction -> JE.Value
encode =
    JE.string << toString


decoder : JD.Decoder Direction
decoder =
    JD.string
        |> JD.andThen
            (\string ->
                case string of
                    "North" ->
                        JD.succeed North

                    "South" ->
                        JD.succeed South

                    "East" ->
                        JD.succeed East

                    "West" ->
                        JD.succeed West

                    _ ->
                        JD.fail "Invalid Direction"
            )


fromKey : String -> Maybe Direction
fromKey key =
    case key of
        "ArrowLeft" ->
            Just West

        "ArrowRight" ->
            Just East

        "ArrowUp" ->
            Just North

        "ArrowDown" ->
            Just South

        _ ->
            Nothing
