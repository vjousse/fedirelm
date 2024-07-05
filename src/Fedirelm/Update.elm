module Fedirelm.Update exposing (..)

import Browser.Navigation as Nav
import Fedirelm.AppDataStorage exposing (AppDataStorage, appDataStorageByUuid)
import Fedirelm.Msg
import Fedirelm.Session exposing (FediSessions, sessionsEncoder)
import Fedirelm.Shared exposing (SharedModel)
import Fediverse.Detector exposing (findLink, getNodeInfo)
import Fediverse.Mastodon.Api as MastodonApi
import Fediverse.Msg exposing (BackendMsg(..), GeneralMsg(..), GoToSocialMsg(..), MastodonMsg(..), Msg(..), PleromaMsg(..), backendMsgToFediEntityMsg)
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

                        newAppDataStorages =
                            case shared.appDataStorages of
                                Just appDataStorages ->
                                    Just <| appDataStorage :: appDataStorages

                                Nothing ->
                                    Just [ appDataStorage ]
                    in
                    ( { shared | appDataStorages = newAppDataStorages }
                    , Cmd.batch
                        [ saveAppData uuid appData
                        , case appData.url of
                            Just url ->
                                Nav.load url

                            Nothing ->
                                Cmd.none
                        ]
                    )

                AccountReceived uuid account ->
                    let
                        _ =
                            Debug.log "Account" account
                    in
                    ( shared, Cmd.none )

                LinksDetected baseUrl links ->
                    let
                        _ =
                            Debug.log "linksDetected" links

                        link =
                            findLink links
                    in
                    ( shared
                    , link
                        |> Maybe.map (\l -> getNodeInfo l.href (Fedirelm.Msg.FediMsg << GeneralMsg << GeneralNodeInfoFetched baseUrl))
                        |> Maybe.withDefault Cmd.none
                    )

                NodeInfoFetched baseUrl nodeInfo ->
                    let
                        _ =
                            Debug.log "nodeInfoFetched" nodeInfo
                    in
                    ( shared
                    , Cmd.none
                    )

                TokenDataReceived uuid tokenData ->
                    case appDataStorageByUuid uuid shared.appDataStorages of
                        Just { appData } ->
                            let
                                session =
                                    { account = Nothing, backend = appData.backend, token = tokenData, baseUrl = appData.baseUrl }

                                sessions =
                                    Fedirelm.Session.setCurrentSession shared.sessions session

                                newAppDataStorages =
                                    shared.appDataStorages
                                        |> Maybe.map
                                            (\appDataStorages ->
                                                appDataStorages
                                                    |> List.filter (\a -> a.uuid /= uuid)
                                            )
                            in
                            ( { shared | sessions = sessions, appDataStorages = newAppDataStorages }
                            , Cmd.batch
                                [ Ports.deleteAppData uuid
                                , saveSessions sessions
                                , MastodonApi.getAccount
                                    appData.baseUrl
                                    tokenData.accessToken
                                    (Fedirelm.Msg.FediMsg << MastodonMsg << MastodonAccount uuid)
                                ]
                            )

                        _ ->
                            ( shared, Cmd.none )

        _ ->
            ( shared, Cmd.none )
