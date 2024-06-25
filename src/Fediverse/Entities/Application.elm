module Fediverse.Entities.Application exposing (..)


type alias Application =
    { name : String
    , website : Maybe String
    , vapid_key : Maybe String
    }
