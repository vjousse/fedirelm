module Fediverse.OAuth exposing (..)

import Fediverse.Entities.Backend exposing (Backend(..), backendDecoder, backendEncoder)
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipe
import Json.Encode as Encode
import Json.Encode.Optional as Opt


type alias AppData =
    { -- Backend type, mastodon, gotosocial, …
      backend : Backend

    -- The base url of the server this data is coming from
    , baseUrl : String

    -- Client ID.
    , clientId : String

    -- Client secret.
    , clientSecret : String

    -- Code returned from OAuth flow
    , code : Maybe String

    -- Application ID.
    , id : String
    , -- Application name.
      name : String
    , -- Redirect URI for the application.
      -- Firefish return callbackUrl as optional string.
      redirectUri : Maybe String
    , -- Authorize URL for the application.
      sessionToken : Maybe String
    , -- Website URL of the application.
      url : Maybe String
    , -- Session token for Firefish.
      website : Maybe String
    }


{-| appRegistrationEncoder
-}
appDataEncoder : AppData -> Encode.Value
appDataEncoder appData =
    [ ( "backend", appData.backend ) |> Opt.field backendEncoder
    , ( "baseUrl", appData.baseUrl ) |> Opt.field Encode.string
    , ( "clientId", appData.clientId ) |> Opt.field Encode.string
    , ( "clientSecret", appData.clientSecret ) |> Opt.field Encode.string
    , ( "id", appData.id ) |> Opt.field Encode.string
    , ( "name", appData.name ) |> Opt.field Encode.string
    , ( "redirectUri", appData.redirectUri ) |> Opt.optionalField Encode.string
    , ( "sessionToken", appData.sessionToken ) |> Opt.optionalField Encode.string
    , ( "url", appData.url ) |> Opt.optionalField Encode.string
    , ( "website", appData.website ) |> Opt.optionalField Encode.string
    ]
        |> Opt.objectMayNullify


appDataDecoder : Decode.Decoder AppData
appDataDecoder =
    Decode.succeed AppData
        |> Pipe.required "backend" backendDecoder
        |> Pipe.required "baseUrl" Decode.string
        |> Pipe.required "clientId" Decode.string
        |> Pipe.required "clientSecret" Decode.string
        |> Pipe.optional "code" (Decode.nullable Decode.string) Nothing
        |> Pipe.required "id" Decode.string
        |> Pipe.required "name" Decode.string
        |> Pipe.optional "redirectUri" (Decode.nullable Decode.string) Nothing
        |> Pipe.optional "sessionToken" (Decode.nullable Decode.string) Nothing
        |> Pipe.optional "url" (Decode.nullable Decode.string) Nothing
        |> Pipe.optional "website" (Decode.nullable Decode.string) Nothing


type alias TokenData =
    { -- Access token for the authorized user.
      accessToken : String
    , -- Token type of the access token.
      tokenType : String
    , -- Scope of the access token.
      -- Firefish does not have scope.
      scope : Maybe String
    , -- Created date of the access token.
      -- Firefish does not have created_at.
      createdAt : Maybe Int
    , -- Expires date of the access token.
      expiresIn : Maybe Int
    , -- Refresh token of the access token.
      refreshToken : Maybe String
    }
