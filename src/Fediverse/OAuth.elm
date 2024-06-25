module Fediverse.OAuth exposing (..)


type alias AppData =
    { -- Application ID.
      id : String
    , -- Application name.
      name : String
    , -- Website URL of the application.
      website : Maybe String
    , -- Redirect URI for the application.
      -- Firefish return callbackUrl as optional string.
      redirectUri : Maybe String
    , -- Client ID.
      clientId : String
    , -- Client secret.
      clientSecret : String
    , -- Authorize URL for the application.
      url : Maybe String
    , -- Session token for Firefish.
      sessionToken : Maybe String
    }


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
