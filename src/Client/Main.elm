module Main exposing (Flags, Model, Msg(..), init, main, subscriptions, update, view)

import Browser
import Browser.Events
import Client.Ports as Ports
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events
import Json.Decode as JD
import Json.Encode as JE
import Shared.ClientMessage as ClientMessage
import Shared.ClientRoom as ClientRoom
import Shared.Direction as Direction exposing (Direction)
import Shared.ServerMessage as ServerMessage



-- MODEL


type Model
    = Unauthed { uname : String, log : List String, websocketConnected : Bool }
    | Authed { uname : String, room : ClientRoom.Room, log : List String }


type alias Flags =
    { uname : String }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( Unauthed { uname = flags.uname, log = [], websocketConnected = False }
    , Cmd.none
    )



-- UPDATE


type Msg
    = NoOp
    | WebSocketOpened
    | WebSocketClosed
      -- Unauthed
    | SetUname String
    | SubmitAuth
      -- Authed
    | RecvServerMessage String
    | Move Direction


handleMessage : ServerMessage.Message -> Model -> ( Model, Cmd Msg )
handleMessage message model =
    case ( model, message ) of
        ( Unauthed { uname }, ServerMessage.AuthResponse room ) ->
            ( Authed { room = room, log = [], uname = uname }, Cmd.none )

        ( Authed state, ServerMessage.MoveResponse room ) ->
            ( Authed { state | room = room, log = [] }, Cmd.none )

        ( Authed ({ room, log } as state), ServerMessage.PlayerEnteredRoom maybeDirection player ) ->
            let
                newRoom =
                    { room | players = player :: room.players }

                logMessage =
                    case maybeDirection of
                        Nothing ->
                            player.uname ++ " connected into this room"

                        Just direction ->
                            player.uname ++ " entered from the " ++ Debug.toString direction
            in
            ( Authed { state | room = newRoom, log = logMessage :: log }, Cmd.none )

        ( Authed ({ room, log } as state), ServerMessage.PlayerLeftRoom maybeDirection player ) ->
            let
                newRoom =
                    { room | players = List.filter (\{ uname } -> uname /= player.uname) room.players }

                logMessage =
                    case maybeDirection of
                        Nothing ->
                            player.uname ++ " disconnected"

                        Just direction ->
                            player.uname ++ " left to the " ++ Debug.toString direction
            in
            ( Authed { state | room = newRoom, log = logMessage :: log }, Cmd.none )

        ( Authed ({ room, log } as state), ServerMessage.PlayerDisconnected uname ) ->
            let
                newRoom =
                    { room | players = List.filter (\p -> uname /= p.uname) room.players }
            in
            ( Authed { state | room = newRoom, log = "player disconn" :: log }, Cmd.none )

        ( Unauthed state, ServerMessage.ClientError error ) ->
            ( Unauthed { state | log = error :: state.log }
            , Cmd.none
            )

        ( Authed state, ServerMessage.ClientError error ) ->
            ( Authed { state | log = error :: state.log }
            , Cmd.none
            )

        _ ->
            Debug.todo "impl case"


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        ( NoOp, _ ) ->
            ( model, Cmd.none )

        ( SetUname uname, Unauthed state ) ->
            ( Unauthed { state | uname = uname }
            , Cmd.none
            )

        ( SetUname uname, Authed _ ) ->
            ( model, Cmd.none )

        ( SubmitAuth, Unauthed { uname } ) ->
            ( model
            , Ports.sendMessage (ClientMessage.AuthRequest uname)
            )

        ( SubmitAuth, Authed _ ) ->
            ( model, Cmd.none )

        ( WebSocketClosed, _ ) ->
            let
                newModel =
                    case model of
                        Unauthed ({ uname, log, websocketConnected } as state) ->
                            if websocketConnected then
                                Unauthed { state | log = "websocket disconnected" :: log, websocketConnected = False }

                            else
                                -- Don't log it if we were already disconnected.
                                model

                        Authed _ ->
                            Unauthed { uname = "", log = [ "websocket disconnected" ], websocketConnected = False }
            in
            ( newModel, Cmd.none )

        ( WebSocketOpened, Unauthed state ) ->
            ( Unauthed { state | websocketConnected = True, log = "websocket connected" :: state.log }
            , Cmd.none
            )

        ( WebSocketOpened, Authed _ ) ->
            ( model, Cmd.none )

        ( Move direction, Authed _ ) ->
            ( model, Ports.sendMessage (ClientMessage.MoveRequest direction) )

        ( Move _, Unauthed _ ) ->
            ( model, Cmd.none )

        ( RecvServerMessage json, _ ) ->
            case JD.decodeString ServerMessage.decoder json of
                Err e ->
                    ( model, Cmd.none )

                Ok message ->
                    handleMessage message model



-- VIEW


view : Model -> Html Msg
view model =
    case model of
        Unauthed { uname, log, websocketConnected } ->
            div
                [ class "container" ]
                [ div [ class "columns", style "padding-top" "50px" ]
                    [ div [ class "column col-6 col-md-8 col-sm-12 col-mx-auto" ]
                        [ div
                            []
                            [ text "Websocket Connected: "
                            , if websocketConnected then
                                text "✅"

                              else
                                text "❌"
                            ]
                        , Html.form
                            [ Html.Events.onSubmit SubmitAuth
                            ]
                            [ div [ class "input-group" ]
                                [ input
                                    [ placeholder "Username"
                                    , value uname
                                    , Html.Events.onInput SetUname
                                    , class "form-input"
                                    , autofocus True
                                    ]
                                    []
                                , input
                                    [ type_ "submit"
                                    , value "Join"
                                    , class "btn btn-primary input-group-btn"
                                    , disabled (not websocketConnected)
                                    ]
                                    []
                                ]
                            ]
                        ]
                    ]
                , ul []
                    (List.map
                        (\line ->
                            li [] [ text line ]
                        )
                        log
                    )
                ]

        Authed { uname, room, log } ->
            div
                [ class "container" ]
                [ div [ class "columns col-gapless" ]
                    [ div [ class "column col-1 col-sm-2" ] []
                    , div [ class "column col-1 col-sm-2" ]
                        [ button
                            [ Html.Events.onClick (Move Direction.North)
                            , disabled (not (List.member Direction.North room.exits))
                            , class "btn btn-block"
                            , classList [ ( "btn-link", not (List.member Direction.North room.exits) ) ]
                            ]
                            [ text "North" ]
                        ]
                    ]
                , div [ class "columns col-gapless" ]
                    [ div [ class "column col-1 col-sm-2" ]
                        [ button
                            [ Html.Events.onClick (Move Direction.West)
                            , disabled (not (List.member Direction.West room.exits))
                            , class "btn btn-block"
                            , classList [ ( "btn-link", not (List.member Direction.West room.exits) ) ]
                            ]
                            [ text "West" ]
                        ]
                    , div [ class "column col-1 col-sm-2" ]
                        [ button
                            [ Html.Events.onClick (Move Direction.South)
                            , disabled (not (List.member Direction.South room.exits))
                            , class "btn btn-block"
                            , classList [ ( "btn-link", not (List.member Direction.South room.exits) ) ]
                            ]
                            [ text "South" ]
                        ]
                    , div [ class "column col-1 col-sm-2" ]
                        [ button
                            [ Html.Events.onClick (Move Direction.East)
                            , disabled (not (List.member Direction.East room.exits))
                            , class "btn btn-block"
                            , classList [ ( "btn-link", not (List.member Direction.East room.exits) ) ]
                            ]
                            [ text "East" ]
                        ]
                    ]
                , br [ style "margin-bottom" "20px" ] []
                , p [ style "font-weight" "bold" ] [ text ("Room: " ++ room.title) ]
                , if not (String.isEmpty room.desc) then
                    p [] [ text room.desc ]

                  else
                    text ""
                , p [] [ text "Players:" ]
                , if List.length room.players > 0 then
                    ul
                        []
                        (List.map
                            (\player ->
                                li []
                                    [ text player.uname
                                    , if player.uname == uname then
                                        text " (You)"

                                      else
                                        text ""
                                    ]
                            )
                            room.players
                        )

                  else
                    text "--None--"
                , p [] [ text "Log Messages:" ]
                , ul []
                    (List.map
                        (\line ->
                            li [] [ text line ]
                        )
                        log
                    )
                ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ports.onWebSocketChange
            (\isConnected ->
                if isConnected then
                    WebSocketOpened

                else
                    WebSocketClosed
            )
        , Ports.onServerMessage RecvServerMessage
        , case model of
            Unauthed _ ->
                Sub.none

            Authed _ ->
                Browser.Events.onKeyDown
                    (JD.field "key" (JD.map Direction.fromKey JD.string)
                        |> JD.andThen
                            (\maybeDirection ->
                                case maybeDirection of
                                    Just direction ->
                                        JD.succeed (Move direction)

                                    Nothing ->
                                        JD.succeed NoOp
                            )
                    )
        ]


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
