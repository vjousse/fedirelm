module Fedirelm.Types exposing (FediSession, FediSessions)

import Fediverse.Entities.Account exposing (Account)
import Fediverse.Entities.Backend exposing (Backend)


type alias FediSession =
    { account : Maybe Account
    , backend : Backend
    , baseUrl : String
    }


type alias FediSessions =
    { currentSession : Maybe FediSession
    , otherSessions : List FediSession
    }
