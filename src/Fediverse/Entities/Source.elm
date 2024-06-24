module Fediverse.Entities.Source exposing (..)

import Fediverse.Entities.Field exposing (Field)


type alias Source =
    { privacy : Maybe String
    , sensitive : Maybe Bool
    , language : Maybe String
    , note : String
    , fields : Maybe (List Field)
    }
