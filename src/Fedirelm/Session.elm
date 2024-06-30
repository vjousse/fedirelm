module Fedirelm.Session exposing (..)

import Fediverse.Entities.Account exposing (Account, accountDecoder, accountEncoder)
import Fediverse.Entities.Backend exposing (Backend, backendDecoder, backendEncoder)
import Fediverse.OAuth exposing (TokenData, tokenDataDecoder, tokenDataEncoder)
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipe
import Json.Encode as Encode
import List.Extra


type alias FediSession =
    { account : Maybe Account
    , backend : Backend
    , baseUrl : String
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
        |> Pipe.required "token" tokenDataDecoder


sessionsDecoder : Decode.Decoder FediSessions
sessionsDecoder =
    Decode.succeed FediSessions
        |> Pipe.required "currentSession" (Decode.nullable sessionDecoder)
        |> Pipe.required "otherSessions" (Decode.list sessionDecoder)


setCurrentSession : FediSessions -> FediSession -> FediSessions
setCurrentSession sessions currentSession =
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
