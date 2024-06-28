module Shared exposing
    ( Identity
    , Msg(..)
    , Shared
    , gotCode
    , identity
    , init
    , replaceRoute
    , setIdentity
    , subscriptions
    , update
    )

import Browser.Navigation as Nav
import Fedirelm.Types exposing (Backend(..), FediSessions)
import Fediverse.Default
import Fediverse.Formatter
import Fediverse.GoToSocial.Api as GoToSocialApi
import Fediverse.GoToSocial.Entities.AppRegistration as GoToSocialAppRegistration
import Fediverse.Mastodon.Api as MastodonApi
import Fediverse.Mastodon.Entities.AppRegistration as MastodonAppRegistration
import Fediverse.Msg as FediEntityMsg
import Route exposing (Route)
import Url


type alias Identity =
    String


type alias Shared =
    { key : Nav.Key
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


type GoToSocialMsg
    = GoToSocialAppCreated String (GoToSocialApiResult GoToSocialAppRegistration.AppDataFromServer)


type BackendMsg
    = MastodonMsg MastodonMsg
    | GoToSocialMsg GoToSocialMsg


type Msg
    = FediMsg BackendMsg
    | GotCode (Maybe String)
    | PushRoute Route
    | ReplaceRoute Route
    | ResetIdentity
    | SetIdentity Identity (Maybe String)


identity : Shared -> Maybe String
identity =
    .identity


type alias Flags =
    { location : String
    }


init : Flags -> Nav.Key -> ( Shared, Cmd Msg )
init flags key =
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
    ( { key = key
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
            (\s ->
                case s.backend of
                    Mastodon ->
                        MastodonApi.createApp
                            s.baseUrl
                            "fedirelm"
                            { scopes = Fediverse.Default.defaultScopes
                            , redirectUri = locationWithoutFragment ++ "oauth"
                            , website = Nothing
                            }
                            (FediMsg << MastodonMsg << MastodonAppCreated s.baseUrl)

                    GoToSocial ->
                        GoToSocialApi.createApp
                            s.baseUrl
                            "fedirelm"
                            { scopes = Fediverse.Default.defaultScopes
                            , redirectUri = locationWithoutFragment ++ "oauth"
                            , website = Nothing
                            }
                            (FediMsg << GoToSocialMsg << GoToSocialAppCreated s.baseUrl)
            )
        |> Cmd.batch
    )


backendMsgToFediEntityMsg : BackendMsg -> Result () FediEntityMsg.Msg
backendMsgToFediEntityMsg backendMsg =
    case Debug.log "bck msg" backendMsg of
        MastodonMsg (MastodonAppCreated server result) ->
            result
                |> Result.mapError (\_ -> ())
                |> Result.map (\a -> FediEntityMsg.AppDataReceived <| MastodonAppRegistration.toAppData a.decoded server)

        GoToSocialMsg (GoToSocialAppCreated server result) ->
            result
                |> Result.mapError (\_ -> ())
                |> Result.map (\a -> FediEntityMsg.AppDataReceived <| MastodonAppRegistration.toAppData a.decoded server)


update : Msg -> Shared -> ( Shared, Cmd Msg )
update msg shared =
    case msg of
        FediMsg backendMsg ->
            let
                _ =
                    Debug.log "fediMsg" (backendMsgToFediEntityMsg backendMsg)
            in
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

        GotCode code ->
            let
                _ =
                    Debug.log "Code" code
            in
            ( shared
            , Nav.replaceUrl shared.key <| Route.toUrl Route.Home
            )


subscriptions : Shared -> Sub Msg
subscriptions =
    always Sub.none


setIdentity : String -> Maybe String -> Msg
setIdentity =
    SetIdentity


gotCode : Maybe String -> Msg
gotCode =
    GotCode


replaceRoute : Route -> Msg
replaceRoute =
    ReplaceRoute


pushRoute : Route -> Msg
pushRoute =
    ReplaceRoute
