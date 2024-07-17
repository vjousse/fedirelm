module Fediverse.Entities.Reaction exposing (..)

import Fediverse.Entities.Account exposing (Account)


type alias Reaction =
    { accounts : Maybe (List Account)
    , accountIds : Maybe (List String)
    , count : Int
    , me : Bool
    , name : String
    , staticUrl : Maybe String
    , url : Maybe String
    }
