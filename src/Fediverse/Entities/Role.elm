module Fediverse.Entities.Role exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline as Pipe
import Json.Encode as Encode


type alias Role =
    { name : String
    }


roleDecoder : Decode.Decoder Role
roleDecoder =
    Decode.succeed Role
        |> Pipe.required "name" Decode.string


roleEncoder : Role -> Encode.Value
roleEncoder role =
    Encode.object
        [ ( "name", Encode.string role.name )
        ]
