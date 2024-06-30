module Shared exposing
    ( Identity
    , Msg(..)
    , Shared
    , connectToGoToSocial
    , connectToMasto
    , gotCode
    , identity
    , init
    , replaceRoute
    , setIdentity
    , subscriptions
    , update
    )

import Browser.Navigation as Nav
import Fedirelm.Types exposing (FediSessions)
import Fediverse.Default
import Fediverse.Entities.Backend exposing (Backend(..))
import Fediverse.Formatter
import Fediverse.GoToSocial.Api as GoToSocialApi
import Fediverse.GoToSocial.Entities.AppRegistration as GoToSocialAppRegistration
import Fediverse.Mastodon.Api as MastodonApi
import Fediverse.Mastodon.Entities.AppRegistration as MastodonAppRegistration
import Fediverse.Msg as FediEntityMsg exposing (Msg(..))
import Fediverse.OAuth exposing (AppData, appDataDecoder, appDataEncoder)
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipe
import Json.Encode as Encode
import List.Extra
import Ports
import Random
import Route exposing (Route)
import UUID
import Url
import Url.Builder


type alias Identity =
    String


type alias Shared =
    { appDatas : Maybe (List AppDataStorage)
    , identity : Maybe Identity
    , key : Nav.Key
    , location : String
    , seeds : UUID.Seeds
    , sessions : FediSessions
    }


type alias MastodonApiResult a =
    Result MastodonApi.Error (MastodonApi.Response a)


type alias GoToSocialApiResult a =
    Result GoToSocialApi.Error (GoToSocialApi.Response a)


type ApiResult a
    = GoToSocialApiResult a
    | MastodonApiResult a


type MastodonMsg
    = MastodonAppCreated String String (MastodonApiResult MastodonAppRegistration.AppDataFromServer)
    | MastodonAccessToken String (MastodonApiResult MastodonAppRegistration.TokenDataFromServer)


type GoToSocialMsg
    = GoToSocialAppCreated String String (GoToSocialApiResult GoToSocialAppRegistration.AppDataFromServer)
    | GoToSocialAccessToken String (GoToSocialApiResult GoToSocialAppRegistration.TokenDataFromServer)


type BackendMsg
    = MastodonMsg MastodonMsg
    | GoToSocialMsg GoToSocialMsg


type Msg
    = ConnectToMastodon
    | ConnectToGoToSocial
    | FediMsg BackendMsg
    | GotOAuthCode ( String, Maybe String )
    | PushRoute Route
    | ReplaceRoute Route
    | ResetIdentity
    | SetIdentity Identity (Maybe String)


type alias AppDataStorage =
    { uuid : String
    , appData : AppData
    }


appDataStorageEncoder : AppDataStorage -> Encode.Value
appDataStorageEncoder appDataStorage =
    Encode.object
        [ ( "uuid", Encode.string appDataStorage.uuid )
        , ( "appData", appDataEncoder appDataStorage.appData )
        ]


appDataStorageDecoder : Decode.Decoder AppDataStorage
appDataStorageDecoder =
    Decode.succeed AppDataStorage
        |> Pipe.required "uuid" Decode.string
        |> Pipe.required "appData" appDataDecoder


saveAppData : String -> AppData -> Cmd Msg
saveAppData uuid appData =
    appDataStorageEncoder { uuid = uuid, appData = appData }
        |> Encode.encode 0
        |> Ports.saveAppData


identity : Shared -> Maybe String
identity =
    .identity


type alias Flags =
    { appDatas : Maybe (List AppDataStorage)
    , location : String
    , seeds : UUID.Seeds
    }


seedsDecoder : Decode.Decoder UUID.Seeds
seedsDecoder =
    let
        seedDecoder =
            Decode.int
                |> Decode.andThen (\s -> Decode.succeed (Random.initialSeed s))
    in
    Decode.succeed UUID.Seeds
        |> Pipe.required "seed1" seedDecoder
        |> Pipe.required "seed2" seedDecoder
        |> Pipe.required "seed3" seedDecoder
        |> Pipe.required "seed4" seedDecoder


flagsDecoder : Decode.Decoder Flags
flagsDecoder =
    Decode.succeed Flags
        |> Pipe.required "appDatas" (Decode.nullable (Decode.list appDataStorageDecoder))
        |> Pipe.required "location" Decode.string
        |> Pipe.required "seeds" seedsDecoder


init : Decode.Value -> Nav.Key -> ( Shared, Cmd Msg )
init flagsJson key =
    let
        flagsResult =
            Decode.decodeValue flagsDecoder flagsJson
    in
    case flagsResult of
        Ok flags ->
            let
                locationWithoutFragment =
                    flags.location
                        |> Url.fromString
                        |> Maybe.map
                            (\location ->
                                { protocol = location.protocol
                                , host = location.host
                                , port_ = location.port_
                                , path = location.path
                                , query = location.fragment
                                , fragment = Nothing
                                }
                            )
                        |> Maybe.map Url.toString
                        |> Maybe.withDefault ""

                sessions =
                    { currentSession =
                        Just
                            { account = Nothing
                            , backend = Mastodon
                            , baseUrl = Fediverse.Formatter.cleanBaseUrl "https://mamot.fr"
                            }
                    , otherSessions =
                        [ { account = Nothing
                          , backend = GoToSocial
                          , baseUrl = Fediverse.Formatter.cleanBaseUrl "https://social.bacardi55.io"
                          }
                        ]
                    }
            in
            ( { appDatas = flags.appDatas
              , identity = Nothing
              , key = key
              , location = locationWithoutFragment
              , seeds = flags.seeds
              , sessions = sessions
              }
            , Cmd.none
            )

        --@TODO: properly manage the flag decoding error
        Err _ ->
            ( { appDatas = Nothing
              , identity = Nothing
              , key = key
              , location = ""
              , seeds =
                    { seed1 = Random.initialSeed 0
                    , seed2 = Random.initialSeed 0
                    , seed3 = Random.initialSeed 0
                    , seed4 = Random.initialSeed 0
                    }
              , sessions = { currentSession = Nothing, otherSessions = [] }
              }
            , Cmd.none
            )


backendMsgToFediEntityMsg : BackendMsg -> Result () FediEntityMsg.Msg
backendMsgToFediEntityMsg backendMsg =
    case Debug.log "bck msg" backendMsg of
        MastodonMsg (MastodonAppCreated server uuid result) ->
            result
                |> Result.mapError (\_ -> ())
                |> Result.map (\a -> FediEntityMsg.AppDataReceived uuid <| MastodonAppRegistration.toAppData a.decoded server Fediverse.Default.defaultScopes)

        MastodonMsg (MastodonAccessToken uuid result) ->
            result
                |> Result.mapError (\_ -> ())
                |> Result.map (\a -> FediEntityMsg.TokenDataReceived uuid <| MastodonAppRegistration.toTokenData a.decoded)

        GoToSocialMsg (GoToSocialAppCreated server uuid result) ->
            result
                |> Result.mapError (\_ -> ())
                |> Result.map (\a -> FediEntityMsg.AppDataReceived uuid <| GoToSocialAppRegistration.toAppData a.decoded server Fediverse.Default.defaultScopes)

        GoToSocialMsg (GoToSocialAccessToken uuid result) ->
            result
                |> Result.mapError (\_ -> ())
                |> Result.map (\a -> FediEntityMsg.TokenDataReceived uuid <| MastodonAppRegistration.toTokenData a.decoded)


update : Msg -> Shared -> ( Shared, Cmd Msg )
update msg shared =
    case msg of
        ConnectToGoToSocial ->
            let
                ( uuid, seeds ) =
                    UUID.step shared.seeds |> Tuple.mapFirst UUID.toString
            in
            ( { shared | seeds = seeds }
            , (case shared.sessions.currentSession of
                Just currentSession ->
                    currentSession :: shared.sessions.otherSessions

                Nothing ->
                    shared.sessions.otherSessions
              )
                |> List.Extra.find (\s -> s.backend == GoToSocial)
                |> Maybe.map
                    (\s ->
                        GoToSocialApi.createApp
                            s.baseUrl
                            "fedirelm"
                            { scopes = Fediverse.Default.defaultScopes
                            , redirectUri = Url.Builder.crossOrigin (Fediverse.Formatter.cleanBaseUrl shared.location) [ "oauth", uuid ] []
                            , website = Nothing
                            }
                            (FediMsg << GoToSocialMsg << GoToSocialAppCreated s.baseUrl uuid)
                    )
                |> Maybe.withDefault Cmd.none
            )

        -- Find the first Mastodon instance in sessions and connect to it
        ConnectToMastodon ->
            let
                ( uuid, seeds ) =
                    UUID.step shared.seeds |> Tuple.mapFirst UUID.toString
            in
            ( { shared | seeds = seeds }
            , (case shared.sessions.currentSession of
                Just currentSession ->
                    currentSession :: shared.sessions.otherSessions

                Nothing ->
                    shared.sessions.otherSessions
              )
                |> List.Extra.find (\s -> s.backend == Mastodon)
                |> Maybe.map
                    (\s ->
                        MastodonApi.createApp
                            s.baseUrl
                            "fedirelm"
                            { scopes = Fediverse.Default.defaultScopes
                            , redirectUri = Url.Builder.crossOrigin (Fediverse.Formatter.cleanBaseUrl shared.location) [ "oauth", uuid ] []
                            , website = Nothing
                            }
                            (FediMsg << MastodonMsg << MastodonAppCreated s.baseUrl uuid)
                    )
                |> Maybe.withDefault Cmd.none
            )

        FediMsg backendMsg ->
            -- Save AppData here
            let
                fediMsg =
                    Debug.log "fediMsg" (backendMsgToFediEntityMsg backendMsg)
            in
            case fediMsg of
                Ok m ->
                    case m of
                        AppDataReceived uuid appData ->
                            let
                                appDataStorage =
                                    { uuid = uuid, appData = appData }

                                newAppDatas =
                                    case shared.appDatas of
                                        Just appDatas ->
                                            Just <| appDataStorage :: appDatas

                                        Nothing ->
                                            Just [ appDataStorage ]
                            in
                            ( { shared | appDatas = newAppDatas }, saveAppData uuid appData )

                        TokenDataReceived uuid tokenData ->
                            ( shared, Cmd.none )

                _ ->
                    ( shared, Cmd.none )

        PushRoute route ->
            ( shared, Nav.pushUrl shared.key <| Route.toUrl route )

        ReplaceRoute route ->
            ( shared, Nav.replaceUrl shared.key <| Route.toUrl route )

        ResetIdentity ->
            ( { shared | identity = Nothing }, Cmd.none )

        SetIdentity newIdentity redirect ->
            ( { shared | identity = Just newIdentity }
            , redirect
                |> Maybe.map (Nav.replaceUrl shared.key)
                |> Maybe.withDefault Cmd.none
            )

        GotOAuthCode ( appDataUuid, code ) ->
            let
                _ =
                    Debug.log "GotAuthCode (appDataUuid, code)" ( appDataUuid, code )
            in
            ( shared
            , Cmd.batch
                [ Nav.replaceUrl shared.key <| Route.toUrl Route.Home
                , case
                    ( shared.appDatas
                        |> Maybe.withDefault []
                        |> List.Extra.find (\a -> a.uuid == appDataUuid)
                    , code
                    )
                  of
                    ( Just { appData, uuid }, Just authCode ) ->
                        Cmd.batch
                            [ Ports.deleteAppData uuid
                            , case appData.backend of
                                Mastodon ->
                                    MastodonApi.getAccessToken authCode appData (FediMsg << MastodonMsg << MastodonAccessToken uuid)

                                GoToSocial ->
                                    GoToSocialApi.getAccessToken authCode appData (FediMsg << GoToSocialMsg << GoToSocialAccessToken uuid)
                            ]

                    _ ->
                        Cmd.none
                ]
            )


subscriptions : Shared -> Sub Msg
subscriptions =
    always Sub.none


setIdentity : String -> Maybe String -> Msg
setIdentity =
    SetIdentity


connectToMasto : Msg
connectToMasto =
    ConnectToMastodon


connectToGoToSocial : Msg
connectToGoToSocial =
    ConnectToGoToSocial


gotCode : ( String, Maybe String ) -> Msg
gotCode =
    GotOAuthCode


replaceRoute : Route -> Msg
replaceRoute =
    ReplaceRoute
