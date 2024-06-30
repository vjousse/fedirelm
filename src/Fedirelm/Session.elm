module Fedirelm.Session exposing (..)

import Fediverse.Entities.Account exposing (Account, accountDecoder)
import Fediverse.Entities.Backend exposing (Backend, backendDecoder)
import Fediverse.OAuth exposing (TokenData, tokenDataDecoder)
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipe
import List.Extra


type alias FediSession =
    { account : Maybe Account
    , backend : Backend
    , token : TokenData
    , baseUrl : String
    }


type alias FediSessions =
    { currentSession : Maybe FediSession
    , otherSessions : List FediSession
    }


sessionDecoder : Decode.Decoder FediSession
sessionDecoder =
    Decode.succeed FediSession
        |> Pipe.required "account" (Decode.nullable accountDecoder)
        |> Pipe.required "backend" backendDecoder
        |> Pipe.required "token" tokenDataDecoder
        |> Pipe.required "baseUrl" Decode.string


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
