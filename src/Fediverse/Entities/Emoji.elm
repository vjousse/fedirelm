module Fediverse.Entities.Emoji exposing (..)


type alias Emoji =
    { category : Maybe String
    , shortcode : String
    , staticUrl : String
    , url : String
    , visibleInPicker : Bool
    }
