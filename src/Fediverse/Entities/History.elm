module Fediverse.Entities.History exposing (..)

import Fediverse.Decoder exposing (stringToIntDecoder)
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipe


type alias History =
    { accounts : Int
    , day : Int
    , uses : Int
    }


historyDecoder : Decode.Decoder History
historyDecoder =
    Decode.succeed History
        |> Pipe.required "accounts" stringToIntDecoder
        |> Pipe.required "day" stringToIntDecoder
        |> Pipe.required "uses" stringToIntDecoder
