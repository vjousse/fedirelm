module Fedirelm.Types exposing (..)

import Fediverse.Entities.Account exposing (Account)


type alias Accounts =
    { currentAccount : Account
    , otherAccounts : List Account
    }
