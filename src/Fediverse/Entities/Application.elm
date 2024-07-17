module Fediverse.Entities.Application exposing (..)


type alias Application =
    { name : String
    , vapidKey : Maybe String
    , website : Maybe String
    }
