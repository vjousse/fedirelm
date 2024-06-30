module Fediverse.Entities.Field exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline as Pipe
import Json.Encode as Encode
import Time exposing (Posix)


type alias Field =
    { name : String
    , value : String
    , verified : Maybe Bool
    , verifiedAt : Maybe Posix
    }


fieldDecoder : Decode.Decoder Field
fieldDecoder =
    Decode.succeed Field
        |> Pipe.required "name" Decode.string
        |> Pipe.required "value" Decode.string
        |> Pipe.optional "verified" (Decode.nullable Decode.bool) Nothing
        |> Pipe.optional "verifiedAt"
            (Decode.nullable
                (Decode.int |> Decode.andThen (\t -> Decode.succeed (Time.millisToPosix t)))
            )
            Nothing


fieldEncoder : Field -> Encode.Value
fieldEncoder field =
    Encode.object
        [ ( "name", Encode.string field.name )
        , ( "value", Encode.string field.value )
        , ( "verified"
          , field.verified
                |> Maybe.map Encode.bool
                |> Maybe.withDefault Encode.null
          )
        , ( "verifiedAt"
          , field.verifiedAt
                |> Maybe.map Time.posixToMillis
                |> Maybe.map Encode.int
                |> Maybe.withDefault Encode.null
          )
        ]
