module Fedirelm.Msg exposing (Msg(..))

import Fedirelm.Shared exposing (Identity)
import Fediverse.Msg exposing (BackendMsg(..))
import Route exposing (Route)


type Msg
    = ConnectToMastodon
    | ConnectToGoToSocial
    | FediMsg BackendMsg
    | GotOAuthCode ( String, Maybe String )
    | PushRoute Route
    | ReplaceRoute Route
    | ResetIdentity
    | SetIdentity Identity (Maybe String)
