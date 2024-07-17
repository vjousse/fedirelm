module Fediverse.Entities.Tag exposing (..)

import Fediverse.Entities.History exposing (History, historyDecoder)
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipe


type alias Tag =
    { following : Maybe Bool
    , history : List History
    , name : String
    , url : String
    }


tagDecoder : Decode.Decoder Tag
tagDecoder =
    Decode.succeed Tag
        |> Pipe.optional "following" (Decode.nullable Decode.bool) Nothing
        |> Pipe.required "history" (Decode.list historyDecoder)
        |> Pipe.required "name" Decode.string
        |> Pipe.required "url" Decode.string
