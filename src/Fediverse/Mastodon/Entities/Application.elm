module Fediverse.Mastodon.Entities.Application exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline as Pipe


type alias Application =
    { name : String
    , vapidKey : Maybe String
    , website : Maybe String
    }


applicationDecoder : Decode.Decoder Application
applicationDecoder =
    Decode.succeed Application
        |> Pipe.required "name" Decode.string
        |> Pipe.optional "vapid_key" (Decode.nullable Decode.string) Nothing
        |> Pipe.optional "website" (Decode.nullable Decode.string) Nothing
