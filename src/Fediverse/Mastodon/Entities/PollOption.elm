module Fediverse.Mastodon.Entities.PollOption exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline as Pipe


type alias PollOption =
    { title : String
    , votesCount : Maybe Int
    }


pollOptionDecoder : Decode.Decoder PollOption
pollOptionDecoder =
    Decode.succeed PollOption
        |> Pipe.required "title" Decode.string
        |> Pipe.optional "votes_count" (Decode.nullable Decode.int) Nothing
