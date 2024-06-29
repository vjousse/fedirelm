module Fediverse.Entities.Backend exposing (Backend(..), backendDecoder, backendEncoder)

import Json.Decode as Decode
import Json.Encode as Encode


type Backend
    = Mastodon
    | GoToSocial


backendEncoder : Backend -> Encode.Value
backendEncoder backend =
    Encode.string <|
        case backend of
            Mastodon ->
                "Mastodon"

            GoToSocial ->
                "GoToSocial"


backendDecoder : Decode.Decoder Backend
backendDecoder =
    Decode.string
        |> Decode.andThen
            (\str ->
                case str of
                    "Mastodon" ->
                        Decode.succeed Mastodon

                    "GoToSocial" ->
                        Decode.succeed GoToSocial

                    _ ->
                        Decode.fail "Invalid Backend type value"
            )
