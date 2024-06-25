module Fediverse.Mastodon.Api exposing (..)

import Fediverse.Default exposing (defaultScopes, noRedirect)
import Fediverse.Mastodon.Entities.AppRegistration exposing (AppRegistration)
import Fediverse.OAuth exposing (AppData)


type alias AppInputOptions =
    { -- List of requested OAuth scopes.
      scopes : Maybe (List String)
    , -- Set a URI to redirect the user to.
      redirectUri : Maybe String
    , -- URL of the application.
      website : Maybe String
    }


createApp : String -> AppInputOptions -> AppData
createApp clientName options =
    let
        scopes =
            Maybe.withDefault defaultScopes options.scopes

        redirectUri =
            Maybe.withDefault noRedirect options.redirectUri
    in
    { -- Application ID.
      id = "1"
    , -- Application name.
      name = "1"
    , -- Website URL of the application.
      website = Nothing
    , -- Redirect URI for the application.
      -- Firefish return callbackUrl as optional string.
      redirectUri = Nothing
    , -- Client ID.
      clientId = "clientId"
    , -- Client secret.
      clientSecret = "clientSecret"
    , -- Authorize URL for the application.
      url = Nothing
    , -- Session token for Firefish.
      sessionToken = Nothing
    }
