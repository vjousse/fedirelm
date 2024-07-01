module Fedirelm.Msg exposing (Msg(..))

import Fedirelm.Shared exposing (Identity)
import Fediverse.Default
import Fediverse.GoToSocial.Entities.AppRegistration as GoToSocialAppRegistration
import Fediverse.Mastodon.Entities.AppRegistration as MastodonAppRegistration
import Fediverse.Msg exposing (BackendMsg(..), GoToSocialMsg(..), MastodonMsg(..), Msg(..), PleromaMsg(..))
import Fediverse.Pleroma.Entities.AppRegistration as PleromaAppRegistration
import Route exposing (Route)


type Msg
    = ConnectToMastodon
    | ConnectToGoToSocial
    | ConnectToPleroma
    | FediMsg BackendMsg
    | GotOAuthCode ( String, Maybe String )
    | PushRoute Route
    | ReplaceRoute Route
    | ResetIdentity
    | SetIdentity Identity (Maybe String)
