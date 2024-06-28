module Shared exposing
    ( Identity
    , Msg(..)
    , Shared
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
import Fediverse.GoToSocial.Api as GoToSocialApi
import Fediverse.GoToSocial.Entities.AppRegistration as GoToSocialAppRegistration
import Fediverse.Mastodon.Api as MastodonApi
import Fediverse.Mastodon.Entities.AppRegistration as MastodonAppRegistration
import Fediverse.Msg as FediEntityMsg
import Route exposing (Route)


type alias Identity =
    String


type alias Shared =
    { key : Nav.Key
    , identity : Maybe Identity
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
    = MastodonAppCreated String (MastodonApiResult MastodonAppRegistration.AppDataFromServer)


type GoToSocialMsg
    = GoToSocialAppCreated String (GoToSocialApiResult GoToSocialAppRegistration.AppDataFromServer)


type BackendMsg
    = MastodonMsg MastodonMsg
    | GoToSocialMsg GoToSocialMsg


type Msg
    = SetIdentity Identity (Maybe String)
    | ResetIdentity
    | PushRoute Route
    | ReplaceRoute Route
    | FediMsg BackendMsg


identity : Shared -> Maybe String
identity =
    .identity


init : () -> Nav.Key -> ( Shared, Cmd Msg )
init _ key =
    let
        sessions =
            { currentSession =
                Just
                    { account = Nothing
                    , backend = Mastodon
                    , baseUrl = "https://mamot.fr"
                    }
            , otherSessions =
                [ { account = Nothing
                  , backend = GoToSocial
                  , baseUrl = "https://social.bacardi55.io"
                  }
                ]
            }
    in
    ( { key = key
      , identity = Nothing
      , sessions = sessions
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
                            , redirectUri = Fediverse.Default.noRedirect
                            , website = Nothing
                            }
                            (FediMsg << MastodonMsg << MastodonAppCreated s.baseUrl)

                    GoToSocial ->
                        GoToSocialApi.createApp
                            s.baseUrl
                            "fedirelm"
                            { scopes = Fediverse.Default.defaultScopes
                            , redirectUri = Fediverse.Default.noRedirect
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


subscriptions : Shared -> Sub Msg
subscriptions =
    always Sub.none


setIdentity : String -> Maybe String -> Msg
setIdentity =
    SetIdentity


replaceRoute : Route -> Msg
replaceRoute =
    ReplaceRoute


pushRoute : Route -> Msg
pushRoute =
    ReplaceRoute
