module Fediverse.Mastodon.Entities.Mention exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline as Pipe


type alias Mention =
    { acct : String
    , id : String
    , url : String
    , username : String
    }


mentionDecoder : Decode.Decoder Mention
mentionDecoder =
    Decode.succeed Mention
        |> Pipe.required "acct" Decode.string
        |> Pipe.required "id" Decode.string
        |> Pipe.required "url" Decode.string
        |> Pipe.required "username" Decode.string
