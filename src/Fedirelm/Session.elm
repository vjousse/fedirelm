module Fedirelm.Session exposing (..)

import Fediverse.Entities.Account exposing (Account, accountDecoder, accountEncoder)
import Fediverse.Entities.Backend exposing (Backend, backendDecoder, backendEncoder)
import Fediverse.OAuth exposing (TokenData, tokenDataDecoder, tokenDataEncoder)
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipe
import Json.Encode as Encode
import List.Extra


type alias SessionId =
    String


type alias FediSession =
    { account : Maybe Account
    , backend : Backend
    , baseUrl : String
    , id : SessionId
    , token : TokenData
    }


type alias FediSessions =
    { currentSession : Maybe FediSession
    , otherSessions : List FediSession
    }


sessionEncoder : FediSession -> Encode.Value
sessionEncoder s =
    Encode.object
        [ ( "account", s.account |> Maybe.map accountEncoder |> Maybe.withDefault Encode.null )
        , ( "backend", backendEncoder s.backend )
        , ( "baseUrl", Encode.string s.baseUrl )
        , ( "id", Encode.string s.id )
        , ( "token", tokenDataEncoder s.token )
        ]


sessionsEncoder : FediSessions -> Encode.Value
sessionsEncoder s =
    Encode.object
        [ ( "currentSession", s.currentSession |> Maybe.map sessionEncoder |> Maybe.withDefault Encode.null )
        , ( "otherSessions", Encode.list sessionEncoder s.otherSessions )
        ]


sessionDecoder : Decode.Decoder FediSession
sessionDecoder =
    Decode.succeed FediSession
        |> Pipe.required "account" (Decode.nullable accountDecoder)
        |> Pipe.required "backend" backendDecoder
        |> Pipe.required "baseUrl" Decode.string
        |> Pipe.required "id" Decode.string
        |> Pipe.required "token" tokenDataDecoder


sessionsDecoder : Decode.Decoder FediSessions
sessionsDecoder =
    Decode.succeed FediSessions
        |> Pipe.required "currentSession" (Decode.nullable sessionDecoder)
        |> Pipe.required "otherSessions" (Decode.list sessionDecoder)


sessionsToList : FediSessions -> List FediSession
sessionsToList sessions =
    sessions.otherSessions ++ (sessions.currentSession |> Maybe.map List.singleton |> Maybe.withDefault [])


findSessionById : String -> FediSessions -> Maybe FediSession
findSessionById id sessions =
    sessions
        |> sessionsToList
        |> List.Extra.find (\s -> s.id == id)


updateSession : FediSession -> FediSessions -> Maybe FediSessions
updateSession updatedSession sessions =
    case ( sessions.currentSession, sessions.otherSessions ) of
        ( Nothing, otherSessions ) ->
            let
                sessionInOtherSessions =
                    otherSessions |> List.Extra.find (\s -> s.id == updatedSession.id)
            in
            sessionInOtherSessions
                |> Maybe.map
                    (\_ ->
                        { currentSession = Nothing
                        , otherSessions =
                            otherSessions
                                |> List.map
                                    (\s ->
                                        if s.id == updatedSession.id then
                                            { account = s.account
                                            , backend = s.backend
                                            , baseUrl = s.baseUrl
                                            , id = s.id
                                            , token = s.token
                                            }

                                        else
                                            s
                                    )
                        }
                    )

        ( Just currentSession, _ ) ->
            if currentSession.id == updatedSession.id then
                Just { sessions | currentSession = Just updatedSession }

            else
                Nothing


setCurrentSession : FediSession -> FediSessions -> FediSessions
setCurrentSession currentSession sessions =
    let
        previousCurrentSession =
            sessions.currentSession

        -- Remove the session from the existing one
        otherSessionsWithoutCurrent =
            List.Extra.remove currentSession sessions.otherSessions
    in
    { currentSession = Just currentSession
    , otherSessions =
        case previousCurrentSession of
            Just session ->
                session :: otherSessionsWithoutCurrent

            Nothing ->
                sessions.otherSessions
    }
