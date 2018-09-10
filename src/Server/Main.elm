module Main exposing (Flags, Model, Msg(..), init, main, subscriptions, update)

import Array exposing (Array)
import Dict exposing (Dict)
import Json.Decode as JD
import Json.Encode as JE
import Platform
import Regex
import Server.Ports as Ports
import Server.World as World exposing (World)
import Set exposing (Set)
import Shared.ClientMessage as ClientMessage
import Shared.ClientPlayer as ClientPlayer
import Shared.ClientRoom as ClientRoom
import Shared.Direction as Direction exposing (Direction)
import Shared.ServerMessage as ServerMessage
import Shared.ServerPlayer as ServerPlayer


type
    Client
    -- Attempts to model the fact that only authenticated clients
    -- can have a player.
    = UnauthedClient Int
    | AuthedClient Int ServerPlayer.Player


type alias Model =
    { clients : Dict Int Client
    , world : World
    }


type alias Flags =
    {}


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { clients = Dict.empty
      , world = World.simple
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = NoOp
    | ClientConnected Int
    | ClientDisconnected Int
    | ClientMessage ( Int, String )


getAllPlayers : Dict Int Client -> List ServerPlayer.Player
getAllPlayers clients =
    clients
        |> Dict.values
        |> List.filterMap
            (\client ->
                case client of
                    UnauthedClient _ ->
                        Nothing

                    AuthedClient _ player ->
                        Just player
            )


getClientIdsAtLoc : ( Int, Int ) -> Dict Int Client -> List Int
getClientIdsAtLoc targetLoc clients =
    clients
        |> Dict.values
        |> List.filterMap
            (\client ->
                case client of
                    AuthedClient id player ->
                        if targetLoc == player.loc then
                            Just id

                        else
                            Nothing

                    _ ->
                        Nothing
            )


getPlayersAtLoc : ( Int, Int ) -> Dict Int Client -> List ServerPlayer.Player
getPlayersAtLoc targetLoc clients =
    clients
        |> Dict.values
        |> List.filterMap
            (\client ->
                case client of
                    UnauthedClient _ ->
                        Nothing

                    AuthedClient _ otherPlayer ->
                        if targetLoc == otherPlayer.loc then
                            Just otherPlayer

                        else
                            Nothing
            )


getClientRoom : ( Int, Int ) -> Model -> Maybe ClientRoom.Room
getClientRoom loc model =
    let
        exits =
            World.getExits loc model.world

        players =
            getPlayersAtLoc loc model.clients
                |> List.map ClientPlayer.fromServerPlayer
    in
    World.getRoom loc model.world
        |> Maybe.map (\{ title, desc } -> { title = title, desc = desc, exits = exits, players = players })


usernameRegex : Regex.Regex
usernameRegex =
    Regex.fromString "^[a-zA-Z0-9]+$"
        |> Maybe.withDefault Regex.never


isValidUsername : String -> Bool
isValidUsername uname =
    Regex.contains usernameRegex uname


isUsernameTaken : String -> Dict Int Client -> Bool
isUsernameTaken uname clients =
    getAllPlayers clients
        |> List.any (\player -> String.toLower player.uname == String.toLower uname)


handleMessage : Model -> Client -> ClientMessage.Message -> ( Model, Cmd Msg )
handleMessage model client message =
    case ( message, client ) of
        ( ClientMessage.MoveRequest direction, AuthedClient clientId player ) ->
            let
                oldLoc =
                    player.loc

                newLoc =
                    Direction.apply player.loc direction
            in
            case getClientRoom newLoc model of
                Nothing ->
                    ( model
                    , Ports.sendMessage clientId (ServerMessage.ClientError ("cannot move " ++ Direction.toString direction))
                    )

                Just nextRoom ->
                    let
                        newPlayer =
                            { player | loc = newLoc }

                        newClient =
                            AuthedClient clientId newPlayer

                        newClients =
                            Dict.insert clientId newClient model.clients

                        roomPlayers =
                            newPlayer :: getPlayersAtLoc newLoc model.clients

                        nextRoomWithPlayer =
                            { nextRoom | players = List.map ClientPlayer.fromServerPlayer roomPlayers }

                        cmds =
                            List.concat
                                [ [ Ports.sendMessage clientId (ServerMessage.MoveResponse nextRoomWithPlayer) ]
                                , getClientIdsAtLoc oldLoc model.clients
                                    -- Ignore self
                                    |> List.filter ((/=) clientId)
                                    |> List.map (\otherId -> Ports.sendMessage otherId (ServerMessage.PlayerLeftRoom (Just direction) (ClientPlayer.fromServerPlayer newPlayer)))
                                , getClientIdsAtLoc newLoc model.clients
                                    |> List.map (\otherId -> Ports.sendMessage otherId (ServerMessage.PlayerEnteredRoom (Just (Direction.opposite direction)) (ClientPlayer.fromServerPlayer newPlayer)))
                                ]
                    in
                    ( { model | clients = newClients }
                    , Cmd.batch cmds
                    )

        ( ClientMessage.AuthRequest uname, UnauthedClient id ) ->
            if not (isValidUsername uname) then
                ( model
                , Ports.sendMessage id (ServerMessage.ClientError "username must only contain chars a-z and 0-9")
                )

            else if String.length uname < 3 || String.length uname > 15 then
                ( model
                , Ports.sendMessage id (ServerMessage.ClientError "username must be 3-15 chars")
                )

            else if isUsernameTaken uname model.clients then
                ( model
                , Ports.sendMessage id (ServerMessage.ClientError "username taken")
                )

            else
                let
                    player =
                        { hp = ( 100, 100 ), uname = uname, loc = ( 0, 0 ) }

                    currentRoom =
                        getClientRoom ( 0, 0 ) model
                            |> Maybe.withDefault ClientRoom.nullRoom
                            -- Add current player to room
                            |> (\room -> { room | players = ClientPlayer.fromServerPlayer player :: room.players })

                    newClient =
                        AuthedClient id player

                    cmds =
                        List.concat
                            [ [ Ports.sendMessage id (ServerMessage.AuthResponse currentRoom) ]
                            , getClientIdsAtLoc player.loc model.clients
                                |> List.map
                                    (\otherId ->
                                        Ports.sendMessage otherId (ServerMessage.PlayerEnteredRoom Nothing (ClientPlayer.fromServerPlayer player))
                                    )
                            ]
                in
                ( { model
                    | clients = Dict.insert id newClient model.clients
                  }
                , Cmd.batch cmds
                )

        ( _, _ ) ->
            let
                clientId =
                    case client of
                        UnauthedClient id ->
                            id

                        AuthedClient id _ ->
                            id
            in
            ( model, Ports.sendMessage clientId (ServerMessage.ClientError "unexpected message") )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        ClientConnected id ->
            let
                client =
                    UnauthedClient id
            in
            ( { model | clients = Dict.insert id client model.clients }
            , Cmd.none
            )

        ClientDisconnected id ->
            case Dict.get id model.clients of
                Nothing ->
                    ( model, Cmd.none )

                Just client ->
                    let
                        cmd =
                            case client of
                                UnauthedClient _ ->
                                    Cmd.none

                                AuthedClient _ player ->
                                    getClientIdsAtLoc player.loc model.clients
                                        |> List.filter ((/=) id)
                                        |> List.map
                                            (\otherId ->
                                                Ports.sendMessage otherId
                                                    (ServerMessage.PlayerLeftRoom Nothing (ClientPlayer.fromServerPlayer player))
                                            )
                                        |> Cmd.batch
                    in
                    ( { model | clients = Dict.remove id model.clients }
                    , cmd
                    )

        ClientMessage ( clientId, json ) ->
            case JD.decodeString ClientMessage.decoder json of
                Err _ ->
                    ( model
                    , Ports.sendMessage clientId (ServerMessage.ClientError "invalid message")
                    )

                Ok message ->
                    case Dict.get clientId model.clients of
                        Nothing ->
                            ( model, Cmd.none )

                        Just client ->
                            handleMessage model client message



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ports.onClientConnected ClientConnected
        , Ports.onClientDisconnected ClientDisconnected
        , Ports.onClientMessage ClientMessage
        ]


main : Program Flags Model Msg
main =
    Platform.worker
        { init = init
        , update = update
        , subscriptions = subscriptions
        }
