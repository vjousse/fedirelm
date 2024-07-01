module Fedirelm.Update exposing (..)

import Browser.Navigation as Nav
import Fedirelm.AppDataStorage exposing (AppDataStorage, appDataStorageByUuid)
import Fedirelm.Msg
import Fedirelm.Session exposing (FediSessions, sessionsEncoder)
import Fedirelm.Shared exposing (SharedModel)
import Fediverse.Msg exposing (BackendMsg(..), GoToSocialMsg(..), MastodonMsg(..), Msg(..), PleromaMsg(..), backendMsgToFediEntityMsg)
import Fediverse.OAuth exposing (AppData, appDataEncoder)
import Json.Encode as Encode
import Ports


saveSessions : FediSessions -> Cmd Fedirelm.Msg.Msg
saveSessions sessions =
    sessionsEncoder sessions
        |> Encode.encode 0
        |> Ports.saveSessions


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

                LinksDetected baseUrl links ->
                    let
                        _ =
                            Debug.log "linksDetected" links
                    in
                    ( shared, Cmd.none )

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
