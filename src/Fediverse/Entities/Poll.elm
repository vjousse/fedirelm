module Fediverse.Entities.Poll exposing (..)

import Fediverse.Entities.Emoji exposing (Emoji, emojiDecoder)
import Fediverse.Entities.PollOption exposing (PollOption, pollOptionDecoder)
import Iso8601
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipe
import Time exposing (Posix)


type alias Poll =
    { id : String
    , emojis : List Emoji
    , expiresAt : Maybe Posix
    , expired : Bool
    , multiple : Bool
    , options : List PollOption
    , voted : Maybe Bool
    , votesCount : Int
    , votersCount : Maybe Int
    }


pollDecoder : Decode.Decoder Poll
pollDecoder =
    Decode.succeed Poll
        |> Pipe.required "id" Decode.string
        |> Pipe.required "emojis" (Decode.list emojiDecoder)
        |> Pipe.optional "expires_at" (Decode.nullable Iso8601.decoder) Nothing
        |> Pipe.required "expired" Decode.bool
        |> Pipe.required "multiple" Decode.bool
        |> Pipe.required "options" (Decode.list pollOptionDecoder)
        |> Pipe.optional "voted" (Decode.nullable Decode.bool) Nothing
        |> Pipe.required "votes_count" Decode.int
        |> Pipe.optional "voters_count" (Decode.nullable Decode.int) Nothing
