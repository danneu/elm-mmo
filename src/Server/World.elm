module Server.World exposing (Room, World, fromList, getExits, getRoom, simple)

import Array exposing (Array)
import Dict exposing (Dict)
import Json.Encode as JE
import Set exposing (Set)
import Shared.ClientRoom as ClientRoom
import Shared.Direction as Direction exposing (Direction)


type alias World =
    { rooms : Array (Array (Maybe Room)) }


type alias Room =
    { title : String
    , desc : String
    }


fromList : List (List (Maybe Room)) -> World
fromList rows =
    let
        height =
            List.length rows

        width =
            List.head rows |> Maybe.withDefault [] |> List.length
    in
    { rooms =
        List.map Array.fromList rows
            |> Array.fromList
    }


getExits : ( Int, Int ) -> World -> List Direction
getExits loc world =
    List.filterMap
        (\direction ->
            getRoom (Direction.apply loc direction) world
                |> Maybe.map (\_ -> direction)
        )
        Direction.list


getRoom : ( Int, Int ) -> World -> Maybe Room
getRoom (( x, y ) as loc) ({ rooms } as world) =
    Array.get y rooms
        |> Maybe.andThen (Array.get x)
        |> Maybe.withDefault Nothing



-- SIMPLE MAP


roomNW =
    Room
        "North-West Room"
        """
        A pleasant room.
        """


roomN =
    Room
        "North Room"
        ""


roomNE =
    Room
        "North-East Room"
        ""


roomW =
    Room
        "West Room"
        ""


roomE =
    Room
        "East Room"
        ""


roomSW =
    Room
        "South-West Room"
        ""


roomS =
    Room
        "South Room"
        ""


roomSE =
    Room
        "South-East Room"
        ""


simple : World
simple =
    fromList
        [ [ Just roomNW, Just roomN, Just roomNE ]
        , [ Just roomW, Nothing, Just roomE ]
        , [ Just roomSW, Just roomS, Just roomSE ]
        ]
