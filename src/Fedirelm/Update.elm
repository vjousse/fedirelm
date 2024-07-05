module Fedirelm.Update exposing (..)

import Browser.Navigation as Nav
import Fedirelm.AppDataStorage exposing (AppDataStorage, appDataStorageByUuid)
import Fedirelm.Msg
import Fedirelm.Session exposing (FediSessions, sessionsEncoder)
import Fedirelm.Shared exposing (SharedModel)
import Fediverse.Detector exposing (findLink, getNodeInfo)
import Fediverse.Entities.Backend exposing (Backend(..))
import Fediverse.GoToSocial.Api as GoToSocialApi
import Fediverse.Mastodon.Api as MastodonApi
import Fediverse.Msg exposing (BackendMsg(..), GeneralMsg(..), GoToSocialMsg(..), MastodonMsg(..), Msg(..), PleromaMsg(..), backendMsgToFediEntityMsg)
import Fediverse.OAuth exposing (AppData, appDataEncoder)
import Fediverse.Pleroma.Api as PleromaApi
import Json.Encode as Encode
import Ports
import UUID


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

                AccountReceived sessionUuid account ->
                    let
                        -- Update the session with the new account
                        newSessions =
                            shared.sessions
                                -- If we have the session locally
                                |> Fedirelm.Session.findSessionById sessionUuid
                                -- We update the shared.sessions with it
                                |> Maybe.map
                                    (\session ->
                                        shared.sessions
                                            |> Fedirelm.Session.updateSession { session | account = Just account }
                                            |> Maybe.withDefault shared.sessions
                                    )
                                -- Otherwise we do Nothing
                                -- @FIXME: throw an error if we don't find the session locally because we should…
                                |> Maybe.withDefault shared.sessions
                    in
                    ( { shared | sessions = newSessions }, saveSessions newSessions )

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
                        -- We got a Token and we have a corresponding appData (same uuid) locally
                        Just { appData } ->
                            let
                                -- Generate new UUID for the session
                                ( sessionUuid, seeds ) =
                                    UUID.step shared.seeds |> Tuple.mapFirst UUID.toString

                                -- Create a session for this token and set it as the current session
                                session =
                                    { account = Nothing
                                    , backend = appData.backend
                                    , baseUrl = appData.baseUrl
                                    , id = sessionUuid
                                    , token = tokenData
                                    }

                                sessions =
                                    shared.sessions
                                        |> Fedirelm.Session.setCurrentSession session

                                -- We can now remove the appData from the local cache, we don't need it anymore
                                newAppDataStorages =
                                    shared.appDataStorages
                                        |> Maybe.map
                                            (\appDataStorages ->
                                                appDataStorages
                                                    |> List.filter (\a -> a.uuid /= uuid)
                                            )
                            in
                            ( { shared
                                | sessions = sessions
                                , appDataStorages = newAppDataStorages
                                , seeds = seeds
                              }
                            , Cmd.batch
                                [ -- Delete the appData from localStorage
                                  Ports.deleteAppData uuid

                                -- Update the sessions with the new one
                                , saveSessions sessions

                                -- Use the new created token to get the corresponding account
                                , case appData.backend of
                                    GoToSocial ->
                                        GoToSocialApi.verifiyCredentials appData.baseUrl tokenData.accessToken (Fedirelm.Msg.FediMsg << GoToSocialMsg << GoToSocialAccount sessionUuid)

                                    Mastodon ->
                                        MastodonApi.verifiyCredentials appData.baseUrl tokenData.accessToken (Fedirelm.Msg.FediMsg << MastodonMsg << MastodonAccount sessionUuid)

                                    Pleroma ->
                                        PleromaApi.verifiyCredentials appData.baseUrl tokenData.accessToken (Fedirelm.Msg.FediMsg << PleromaMsg << PleromaAccount sessionUuid)
                                ]
                            )

                        _ ->
                            ( shared, Cmd.none )

        _ ->
            ( shared, Cmd.none )
