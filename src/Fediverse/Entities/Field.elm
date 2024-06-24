module Fediverse.Entities.Field exposing (..)

import Time exposing (Posix)


type alias Field =
    { name : String
    , value : String
    , verifiedAt : Maybe Posix
    , verified : Maybe Bool
    }
