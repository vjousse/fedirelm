module Fediverse.Mastodon.Entities.AppRegistration exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline as Pipe
import Json.Encode as Encode
import Json.Encode.Optional as Opt


{-| App registration
-}
type alias AppRegistration =
    { server : String
    , scope : String
    , clientId : String
    , clientSecret : String
    , id : String
    , redirectUri : String
    }


{-| appRegistrationDecoder
-}
appRegistrationDecoder : String -> String -> Decode.Decoder AppRegistration
appRegistrationDecoder server scope =
    Decode.succeed AppRegistration
        |> Pipe.hardcoded server
        |> Pipe.hardcoded scope
        |> Pipe.required "client_id" Decode.string
        |> Pipe.required "client_secret" Decode.string
        |> Pipe.required "id" Decode.string
        |> Pipe.required "redirect_uri" Decode.string


{-| appRegistrationEncoder
-}
appRegistrationEncoder : String -> String -> String -> Maybe String -> Encode.Value
appRegistrationEncoder clientName redirectUris scope website =
    [ ( "client_name", clientName ) |> Opt.field Encode.string
    , ( "redirect_uris", redirectUris ) |> Opt.field Encode.string
    , ( "scopes", scope ) |> Opt.field Encode.string
    , ( "website", website ) |> Opt.optionalField Encode.string
    ]
        |> Opt.objectMaySkip
