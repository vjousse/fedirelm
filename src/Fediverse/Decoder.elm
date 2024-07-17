module Fediverse.Decoder exposing (..)

import Json.Decode as Decode


stringToIntDecoder : Decode.Decoder Int
stringToIntDecoder =
    Decode.string
        |> Decode.andThen
            (\s ->
                s
                    |> String.toInt
                    |> Maybe.map (\v -> Decode.succeed v)
                    |> Maybe.withDefault (Decode.fail "Unable to decode string value to int")
            )
