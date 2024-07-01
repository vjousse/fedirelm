module Fedirelm.Msg exposing (Msg(..))

import Fedirelm.Shared exposing (Identity)
import Fediverse.Msg exposing (BackendMsg(..), GoToSocialMsg(..), MastodonMsg(..), Msg(..), PleromaMsg(..))
import Route exposing (Route)


type Msg
    = ConnectToMastodon
    | ConnectToGoToSocial
    | ConnectToPleroma
    | ConnectToUnknown String
    | FediMsg BackendMsg
    | GotOAuthCode ( String, Maybe String )
    | PushRoute Route
    | ReplaceRoute Route
    | ResetIdentity
    | SetIdentity Identity (Maybe String)
