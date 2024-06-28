module Fediverse.OAuth exposing (..)

import Json.Encode as Encode
import Json.Encode.Optional as Opt


type alias AppData =
    { -- Client ID.
      clientId : String

    -- Client secret.
    , clientSecret : String

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
    [ ( "clientId", appData.clientId ) |> Opt.field Encode.string
    , ( "clientSecret", appData.clientSecret ) |> Opt.field Encode.string
    , ( "id", appData.id ) |> Opt.field Encode.string
    , ( "name", appData.name ) |> Opt.field Encode.string
    , ( "redirectUri", appData.redirectUri ) |> Opt.optionalField Encode.string
    , ( "sessionToken", appData.sessionToken ) |> Opt.optionalField Encode.string
    , ( "url", appData.url ) |> Opt.optionalField Encode.string
    , ( "website", appData.website ) |> Opt.optionalField Encode.string
    ]
        |> Opt.objectMaySkip


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
