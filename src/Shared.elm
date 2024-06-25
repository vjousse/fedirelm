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
import Fediverse.Mastodon.Api exposing (Error, Response, createApp)
import Fediverse.Mastodon.Entities.AppRegistration exposing (AppDataFromServer)
import Route exposing (Route)


type alias Identity =
    String


type alias Shared =
    { key : Nav.Key
    , identity : Maybe Identity
    }


type alias MastodonApiResult a =
    Result Error (Response a)


type alias GoToSocialApiResult a =
    Result Error (Response a)


type ApiResult a
    = GotoSocialApiResult a
    | MastodonApiResult a


type MastodonMsg
    = AppCreated (MastodonApiResult AppDataFromServer)


type ServerMsg
    = NewAppCreated (ApiResult AppDataFromServer)


type Msg
    = SetIdentity Identity (Maybe String)
    | ResetIdentity
    | PushRoute Route
    | ReplaceRoute Route
    | MastodonEvent MastodonMsg
    | FediEvent ServerMsg


identity : Shared -> Maybe String
identity =
    .identity


init : () -> Nav.Key -> ( Shared, Cmd Msg )
init _ key =
    ( { key = key
      , identity = Nothing
      }
    , createApp "fedirelm" { scopes = Nothing, redirectUri = Nothing, website = Nothing } (MastodonEvent << AppCreated)
    )


update : Msg -> Shared -> ( Shared, Cmd Msg )
update msg shared =
    case msg of
        FediEvent fediMsg ->
            let
                _ =
                    Debug.log "fediMsg" fediMsg
            in
            ( shared, Cmd.none )

        MastodonEvent mastodonMsg ->
            let
                _ =
                    Debug.log "mastodonMsg" mastodonMsg
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
