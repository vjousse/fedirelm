module Fediverse.GoToSocial.Entities.AppRegistration exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline as Pipe
import Json.Encode as Encode
import Json.Encode.Optional as Opt


type alias AppDataFromServer =
    { id : String
    , clientId : String
    , clientSecret : String
    , name : String
    , redirectUri : String
    , website : Maybe String
    }


{-| appDataFromServer
-}
appDataFromServerDecoder : Decode.Decoder AppDataFromServer
appDataFromServerDecoder =
    Decode.succeed AppDataFromServer
        |> Pipe.required "id" Decode.string
        |> Pipe.required "client_id" Decode.string
        |> Pipe.required "client_secret" Decode.string
        |> Pipe.required "name" Decode.string
        |> Pipe.required "redirect_uri" Decode.string
        |> Pipe.optional "website" (Decode.nullable Decode.string) Nothing


{-| appRegistrationEncoder
-}
appRegistrationDataEncoder : String -> String -> String -> Maybe String -> Encode.Value
appRegistrationDataEncoder clientName redirectUris scopes website =
    [ ( "client_name", clientName ) |> Opt.field Encode.string
    , ( "redirect_uris", redirectUris ) |> Opt.field Encode.string
    , ( "scopes", scopes ) |> Opt.field Encode.string
    , ( "website", website ) |> Opt.optionalField Encode.string
    ]
        |> Opt.objectMaySkip
