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
    }


type alias MastodonApiResult a =
    Result MastodonApi.Error (MastodonApi.Response a)


type alias GoToSocialApiResult a =
    Result GoToSocialApi.Error (GoToSocialApi.Response a)


type ApiResult a
    = GoToSocialApiResult a
    | MastodonApiResult a


type MastodonMsg
    = MastodonAppCreated (MastodonApiResult MastodonAppRegistration.AppDataFromServer)


type GoToSocialMsg
    = GoToSocialAppCreated (GoToSocialApiResult GoToSocialAppRegistration.AppDataFromServer)


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
    ( { key = key
      , identity = Nothing
      }
    , Cmd.batch
        [ MastodonApi.createApp "fedirelm"
            { scopes = Nothing
            , redirectUri = Nothing
            , website = Nothing
            }
            (FediMsg << MastodonMsg << MastodonAppCreated)

        -- Do it for GoToSocial
        , GoToSocialApi.createApp "fedirelm"
            { scopes = Nothing
            , redirectUri = Nothing
            , website = Nothing
            }
            (FediMsg << GoToSocialMsg << GoToSocialAppCreated)
        ]
    )


backendMsgToFediEntityMsg : BackendMsg -> Result () FediEntityMsg.Msg
backendMsgToFediEntityMsg backendMsg =
    case Debug.log "bck msg" backendMsg of
        MastodonMsg (MastodonAppCreated result) ->
            result
                |> Result.mapError (\_ -> ())
                |> Result.map (\a -> FediEntityMsg.AppDataReceived <| MastodonAppRegistration.toAppData a.decoded)

        GoToSocialMsg (GoToSocialAppCreated result) ->
            result
                |> Result.mapError (\_ -> ())
                |> Result.map (\a -> FediEntityMsg.AppDataReceived <| MastodonAppRegistration.toAppData a.decoded)


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
