module Fediverse.Entities.Backend exposing (Backend(..), backendDecoder, backendEncoder)

import Json.Decode as Decode
import Json.Encode as Encode


type Backend
    = GoToSocial
    | Mastodon
    | Pleroma


backendEncoder : Backend -> Encode.Value
backendEncoder backend =
    Encode.string <|
        case backend of
            GoToSocial ->
                "GoToSocial"

            Mastodon ->
                "Mastodon"

            Pleroma ->
                "Pleroma"


backendDecoder : Decode.Decoder Backend
backendDecoder =
    Decode.string
        |> Decode.andThen
            (\str ->
                case str of
                    "GoToSocial" ->
                        Decode.succeed GoToSocial

                    "Mastodon" ->
                        Decode.succeed Mastodon

                    "Pleroma" ->
                        Decode.succeed Pleroma

                    _ ->
                        Decode.fail "Invalid Backend type value"
            )
