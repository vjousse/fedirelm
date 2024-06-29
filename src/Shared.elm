module Shared exposing
    ( Identity
    , Msg(..)
    , Shared
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
import Route exposing (Route)
import Url


type alias Identity =
    String


type alias Shared =
    { appDatas : Maybe (List AppData)
    , key : Nav.Key
    , identity : Maybe Identity
    , sessions : FediSessions
    , location : String
    }


type alias MastodonApiResult a =
    Result MastodonApi.Error (MastodonApi.Response a)


type alias GoToSocialApiResult a =
    Result GoToSocialApi.Error (GoToSocialApi.Response a)


type ApiResult a
    = GoToSocialApiResult a
    | MastodonApiResult a


type MastodonMsg
    = MastodonAppCreated String (MastodonApiResult MastodonAppRegistration.AppDataFromServer)
    | MastodonAccessToken (MastodonApiResult MastodonAppRegistration.TokenDataFromServer)


type GoToSocialMsg
    = GoToSocialAppCreated String (GoToSocialApiResult GoToSocialAppRegistration.AppDataFromServer)


type BackendMsg
    = MastodonMsg MastodonMsg
    | GoToSocialMsg GoToSocialMsg


type Msg
    = ConnectToMastodon
    | FediMsg BackendMsg
    | GotOAuthCode ( Maybe String, Maybe String )
    | PushRoute Route
    | ReplaceRoute Route
    | ResetIdentity
    | SetIdentity Identity (Maybe String)


saveAppData : AppData -> Cmd Msg
saveAppData appData =
    appDataEncoder appData
        |> Encode.encode 0
        |> Ports.saveAppData


identity : Shared -> Maybe String
identity =
    .identity


type alias Flags =
    { location : String
    , appDatas : Maybe (List AppData)
    }


{-| appDataFromServer
-}
flagsDecoder : Decode.Decoder Flags
flagsDecoder =
    Decode.succeed Flags
        |> Pipe.required "location" Decode.string
        |> Pipe.required "appDatas" (Decode.nullable (Decode.list appDataDecoder))


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
              , key = key
              , identity = Nothing
              , sessions = sessions
              , location = locationWithoutFragment
              }
            , (case sessions.currentSession of
                Just currentSession ->
                    currentSession :: sessions.otherSessions

                Nothing ->
                    sessions.otherSessions
              )
                |> List.map
                    (\s -> Cmd.none
                     -- case s.backend of
                     --     Mastodon ->
                     --         MastodonApi.createApp
                     --             s.baseUrl
                     --             "fedirelm"
                     --             { scopes = Fediverse.Default.defaultScopes
                     --             , redirectUri = locationWithoutFragment ++ "oauth"
                     --             , website = Nothing
                     --             }
                     --             (FediMsg << MastodonMsg << MastodonAppCreated s.baseUrl)
                     --
                     --     GoToSocial ->
                     --         GoToSocialApi.createApp
                     --             s.baseUrl
                     --             "fedirelm"
                     --             { scopes = Fediverse.Default.defaultScopes
                     --             , redirectUri = locationWithoutFragment ++ "oauth"
                     --             , website = Nothing
                     --             }
                     --             (FediMsg << GoToSocialMsg << GoToSocialAppCreated s.baseUrl)
                    )
                |> Cmd.batch
            )

        --@TODO: properly manage the flag decoding error
        Err _ ->
            ( { appDatas = Nothing
              , key = key
              , identity = Nothing
              , sessions = { currentSession = Nothing, otherSessions = [] }
              , location = ""
              }
            , Cmd.none
            )


backendMsgToFediEntityMsg : BackendMsg -> Result () FediEntityMsg.Msg
backendMsgToFediEntityMsg backendMsg =
    case Debug.log "bck msg" backendMsg of
        MastodonMsg (MastodonAppCreated server result) ->
            result
                |> Result.mapError (\_ -> ())
                |> Result.map (\a -> FediEntityMsg.AppDataReceived <| MastodonAppRegistration.toAppData a.decoded server Fediverse.Default.defaultScopes)

        MastodonMsg (MastodonAccessToken result) ->
            result
                |> Result.mapError (\_ -> ())
                |> Result.map (\a -> FediEntityMsg.TokenDataReceived <| MastodonAppRegistration.toTokenData a.decoded)

        GoToSocialMsg (GoToSocialAppCreated server result) ->
            result
                |> Result.mapError (\_ -> ())
                |> Result.map (\a -> FediEntityMsg.AppDataReceived <| GoToSocialAppRegistration.toAppData a.decoded server Fediverse.Default.defaultScopes)


update : Msg -> Shared -> ( Shared, Cmd Msg )
update msg shared =
    case msg of
        -- Find the first Mastodon instance in sessions and connect to it
        ConnectToMastodon ->
            ( shared
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
                            , redirectUri = shared.location ++ "oauth"
                            , website = Nothing
                            }
                            (FediMsg << MastodonMsg << MastodonAppCreated s.baseUrl)
                    )
                |> Maybe.withDefault Cmd.none
            )

        FediMsg backendMsg ->
            -- Save AppData here
            let
                fediMsg =
                    Debug.log "fediMsg" (backendMsgToFediEntityMsg backendMsg)
            in
            ( shared
            , case fediMsg of
                Ok m ->
                    case m of
                        AppDataReceived appData ->
                            saveAppData appData

                        TokenDataReceived tokenData ->
                            Cmd.none

                _ ->
                    Cmd.none
            )

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

        GotOAuthCode ( clientId, code ) ->
            let
                _ =
                    Debug.log "GotAuthCode (clientId, code)" ( clientId, code )
            in
            ( shared
            , Cmd.batch
                [ Nav.replaceUrl shared.key <| Route.toUrl Route.Home
                , case
                    ( shared.appDatas
                        |> Maybe.withDefault []
                        |> List.Extra.find (\a -> Just a.clientId == clientId)
                    , code
                    )
                  of
                    ( Just appData, Just authCode ) ->
                        Cmd.batch
                            [ Ports.deleteAppData appData.clientId
                            , case appData.backend of
                                Mastodon ->
                                    MastodonApi.getAccessToken authCode appData (FediMsg << MastodonMsg << MastodonAccessToken)

                                _ ->
                                    Cmd.none
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


gotCode : ( Maybe String, Maybe String ) -> Msg
gotCode =
    GotOAuthCode


replaceRoute : Route -> Msg
replaceRoute =
    ReplaceRoute
