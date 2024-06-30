module Shared exposing
    ( connectToGoToSocial
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
import Fedirelm.AppDataStorage exposing (AppDataStorage, appDataStorageByUuid, appDataStorageDecoder)
import Fedirelm.Msg exposing (Msg(..))
import Fedirelm.Session exposing (FediSessions, sessionsDecoder)
import Fedirelm.Shared exposing (SharedModel)
import Fedirelm.Update
import Fediverse.Default
import Fediverse.Entities.Backend exposing (Backend(..))
import Fediverse.Formatter
import Fediverse.GoToSocial.Api as GoToSocialApi
import Fediverse.Mastodon.Api as MastodonApi
import Fediverse.Msg exposing (BackendMsg(..), GoToSocialMsg(..), MastodonMsg(..))
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipe
import Random
import Route exposing (Route)
import UUID
import Url.Builder


identity : SharedModel -> Maybe String
identity =
    .identity


type alias Flags =
    { appDatas : Maybe (List AppDataStorage)
    , location : String
    , prefix : Maybe String
    , seeds : UUID.Seeds
    , sessions : Maybe FediSessions
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
        |> Pipe.optional "prefix" (Decode.nullable Decode.string) Nothing
        |> Pipe.required "seeds" seedsDecoder
        |> Pipe.optional "sessions" (Decode.nullable sessionsDecoder) Nothing


init : Decode.Value -> Nav.Key -> ( SharedModel, Cmd Msg )
init flagsJson key =
    let
        flagsResult =
            Decode.decodeValue flagsDecoder flagsJson
    in
    case flagsResult of
        Ok flags ->
            ( { appDatas = flags.appDatas
              , identity = Nothing
              , key = key
              , location = Url.Builder.crossOrigin flags.location [ Maybe.withDefault "" flags.prefix ] []
              , seeds = flags.seeds
              , sessions = Maybe.withDefault { currentSession = Nothing, otherSessions = [] } flags.sessions
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


update : Msg -> SharedModel -> ( SharedModel, Cmd Msg )
update msg shared =
    case msg of
        ConnectToGoToSocial ->
            let
                ( uuid, seeds ) =
                    UUID.step shared.seeds |> Tuple.mapFirst UUID.toString
            in
            ( { shared | seeds = seeds }
            , GoToSocialApi.createApp
                "https://social.bacardi55.io"
                "fedirelm"
                { scopes = Fediverse.Default.defaultScopes
                , redirectUri = Url.Builder.crossOrigin (Fediverse.Formatter.cleanBaseUrl shared.location) [ "oauth", uuid ] []
                , website = Nothing
                }
                (FediMsg << GoToSocialMsg << GoToSocialAppCreated "https://social.bacardi55.io" uuid)
            )

        ConnectToMastodon ->
            let
                ( uuid, seeds ) =
                    UUID.step shared.seeds |> Tuple.mapFirst UUID.toString
            in
            ( { shared | seeds = seeds }
            , MastodonApi.createApp
                "https://mamot.fr"
                "fedirelm"
                { scopes = Fediverse.Default.defaultScopes
                , redirectUri = Url.Builder.crossOrigin (Fediverse.Formatter.cleanBaseUrl shared.location) [ "oauth", uuid ] []
                , website = Nothing
                }
                (FediMsg << MastodonMsg << MastodonAppCreated "https://mamot.fr" uuid)
            )

        FediMsg backendMsg ->
            Fedirelm.Update.update backendMsg shared

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
                    ( appDataStorageByUuid appDataUuid shared.appDatas, code )
                  of
                    ( Just { appData, uuid }, Just authCode ) ->
                        Cmd.batch
                            [ case appData.backend of
                                Mastodon ->
                                    MastodonApi.getAccessToken authCode appData (FediMsg << MastodonMsg << MastodonAccessToken uuid)

                                GoToSocial ->
                                    GoToSocialApi.getAccessToken authCode appData (FediMsg << GoToSocialMsg << GoToSocialAccessToken uuid)
                            ]

                    _ ->
                        Cmd.none
                ]
            )


subscriptions : SharedModel -> Sub Msg
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
