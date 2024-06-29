module Fediverse.GoToSocial.Entities.AppRegistration exposing (..)

import Fediverse.Entities.Backend exposing (Backend(..))
import Fediverse.OAuth exposing (AppData)
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipe
import Json.Encode as Encode
import Json.Encode.Optional as Opt
import Url.Builder


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


toAppData : AppDataFromServer -> String -> List String -> AppData
toAppData self baseUrl scopes =
    { backend = GoToSocial
    , baseUrl = baseUrl
    , id = self.id
    , code = Nothing
    , name = self.name
    , website = self.website
    , redirectUri = Just self.redirectUri
    , clientId = self.clientId
    , clientSecret = self.clientSecret
    , url = Just <| generateAuthUrl baseUrl self.clientId scopes self.redirectUri
    , sessionToken = Nothing
    }


generateAuthUrl : String -> String -> List String -> String -> String
generateAuthUrl baseUrl clientId scopes redirectUri =
    Url.Builder.crossOrigin
        baseUrl
        -- crossOrigin prepends a / before every entry so remove it from the start of the path
        [ "oauth/authorize" ]
        [ Url.Builder.string "response_type" "code"
        , Url.Builder.string "client_id" clientId
        , Url.Builder.string "scope" <| String.join " " scopes
        , Url.Builder.string "redirect_uri" (redirectUri ++ "?clientId=" ++ clientId)
        ]
