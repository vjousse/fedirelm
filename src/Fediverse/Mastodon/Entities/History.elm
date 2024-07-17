module Fediverse.Mastodon.Entities.History exposing (..)

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
        |> Pipe.required "accounts" Decode.int
        |> Pipe.required "day" Decode.int
        |> Pipe.required "uses" Decode.int
