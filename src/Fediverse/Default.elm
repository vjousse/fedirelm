module Fediverse.Default exposing (..)

{-| Default values
-}


{-| A static value for no redirect url.
Please use this value when you get an access token.
-}
noRedirect : String
noRedirect =
    "urn:ietf:wg:oauth:2.0:oob"


{-| Default User-Agent value.
-}
defaultUa : String
defaultUa =
    "fedirelm"


{-| Default scopes value for register app.
-}
defaultScopes : List String
defaultScopes =
    [ "read", "write", "follow" ]
