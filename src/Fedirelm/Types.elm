module Fedirelm.Types exposing (Backend(..), FediSession, FediSessions)

import Fediverse.Entities.Account exposing (Account)


type Backend
    = Mastodon
    | GoToSocial


type alias FediSession =
    { account : Maybe Account
    , backend : Backend
    , baseUrl : String
    }


type alias FediSessions =
    { currentSession : Maybe FediSession
    , otherSessions : List FediSession
    }
