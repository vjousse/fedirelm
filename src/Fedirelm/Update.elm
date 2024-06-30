module Fedirelm.Update exposing (..)

import Browser.Navigation as Nav
import Fedirelm.AppDataStorage exposing (AppDataStorage, appDataStorageByUuid)
import Fedirelm.Msg
import Fedirelm.Session exposing (FediSessions, sessionsEncoder)
import Fedirelm.Shared exposing (SharedModel)
import Fediverse.Default
import Fediverse.GoToSocial.Entities.AppRegistration as GoToSocialAppRegistration
import Fediverse.Mastodon.Entities.AppRegistration as MastodonAppRegistration
import Fediverse.Msg exposing (BackendMsg(..), GoToSocialMsg(..), MastodonMsg(..), Msg(..))
import Fediverse.OAuth exposing (AppData, appDataEncoder)
import Json.Encode as Encode
import Ports


saveSessions : FediSessions -> Cmd Fedirelm.Msg.Msg
saveSessions sessions =
    sessionsEncoder sessions
        |> Encode.encode 0
        |> Ports.saveSessions


backendMsgToFediEntityMsg : BackendMsg -> Result () Fediverse.Msg.Msg
backendMsgToFediEntityMsg backendMsg =
    case Debug.log "bck msg" backendMsg of
        MastodonMsg (MastodonAppCreated server uuid result) ->
            result
                |> Result.mapError (\_ -> ())
                |> Result.map (\a -> AppDataReceived uuid <| MastodonAppRegistration.toAppData a.decoded server Fediverse.Default.defaultScopes)

        MastodonMsg (MastodonAccessToken uuid result) ->
            result
                |> Result.mapError (\_ -> ())
                |> Result.map (\a -> TokenDataReceived uuid <| MastodonAppRegistration.toTokenData a.decoded)

        GoToSocialMsg (GoToSocialAppCreated server uuid result) ->
            result
                |> Result.mapError (\_ -> ())
                |> Result.map (\a -> AppDataReceived uuid <| GoToSocialAppRegistration.toAppData a.decoded server Fediverse.Default.defaultScopes)

        GoToSocialMsg (GoToSocialAccessToken uuid result) ->
            result
                |> Result.mapError (\_ -> ())
                |> Result.map (\a -> TokenDataReceived uuid <| MastodonAppRegistration.toTokenData a.decoded)


appDataStorageEncoder : AppDataStorage -> Encode.Value
appDataStorageEncoder appDataStorage =
    Encode.object
        [ ( "uuid", Encode.string appDataStorage.uuid )
        , ( "appData", appDataEncoder appDataStorage.appData )
        ]


saveAppData : String -> AppData -> Cmd Fedirelm.Msg.Msg
saveAppData uuid appData =
    appDataStorageEncoder { uuid = uuid, appData = appData }
        |> Encode.encode 0
        |> Ports.saveAppData


update : BackendMsg -> SharedModel -> ( SharedModel, Cmd Fedirelm.Msg.Msg )
update backendMsg shared =
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
                    ( { shared | appDatas = newAppDatas }
                    , Cmd.batch
                        [ saveAppData uuid appData
                        , case appData.url of
                            Just url ->
                                Nav.load url

                            Nothing ->
                                Cmd.none
                        ]
                    )

                TokenDataReceived uuid tokenData ->
                    case appDataStorageByUuid uuid shared.appDatas of
                        Just { appData } ->
                            let
                                session =
                                    { account = Nothing, backend = appData.backend, token = tokenData, baseUrl = appData.baseUrl }

                                sessions =
                                    Fedirelm.Session.setCurrentSession shared.sessions session
                            in
                            ( { shared | sessions = sessions }, Cmd.batch [ Ports.deleteAppData uuid, saveSessions sessions ] )

                        _ ->
                            ( shared, Cmd.none )

        _ ->
            ( shared, Cmd.none )
