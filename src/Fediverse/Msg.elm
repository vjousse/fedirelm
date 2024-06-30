module Fediverse.Msg exposing (..)

import Fediverse.GoToSocial.Api as GoToSocialApi
import Fediverse.GoToSocial.Entities.AppRegistration as GoToSocialAppRegistration
import Fediverse.Mastodon.Api as MastodonApi
import Fediverse.Mastodon.Entities.AppRegistration as MastodonAppRegistration
import Fediverse.OAuth exposing (AppData, TokenData)


type Msg
    = AppDataReceived String AppData
    | TokenDataReceived String TokenData


type alias MastodonApiResult a =
    Result MastodonApi.Error (MastodonApi.Response a)


type alias GoToSocialApiResult a =
    Result GoToSocialApi.Error (GoToSocialApi.Response a)


type ApiResult a
    = GoToSocialApiResult a
    | MastodonApiResult a


type MastodonMsg
    = MastodonAppCreated String String (MastodonApiResult MastodonAppRegistration.AppDataFromServer)
    | MastodonAccessToken String (MastodonApiResult MastodonAppRegistration.TokenDataFromServer)


type GoToSocialMsg
    = GoToSocialAppCreated String String (GoToSocialApiResult GoToSocialAppRegistration.AppDataFromServer)
    | GoToSocialAccessToken String (GoToSocialApiResult GoToSocialAppRegistration.TokenDataFromServer)


type BackendMsg
    = MastodonMsg MastodonMsg
    | GoToSocialMsg GoToSocialMsg
