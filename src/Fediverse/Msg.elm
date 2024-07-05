module Fediverse.Msg exposing (..)

import Fediverse.Default
import Fediverse.Detector exposing (Links, NodeInfo)
import Fediverse.Entities.Account exposing (Account)
import Fediverse.GoToSocial.Api as GoToSocialApi
import Fediverse.GoToSocial.Entities.AppRegistration as GoToSocialAppRegistration
import Fediverse.Mastodon.Api as MastodonApi
import Fediverse.Mastodon.Entities.Account as MastodonAccount
import Fediverse.Mastodon.Entities.AppRegistration as MastodonAppRegistration
import Fediverse.OAuth exposing (AppData, TokenData)
import Fediverse.Pleroma.Api as PleromaApi
import Fediverse.Pleroma.Entities.AppRegistration as PleromaAppRegistration
import Http


type Msg
    = AppDataReceived String AppData
    | AccountReceived String Account
    | TokenDataReceived String TokenData
    | LinksDetected String Links
    | NodeInfoFetched String NodeInfo


type alias MastodonApiResult a =
    Result MastodonApi.Error (MastodonApi.Response a)


type alias GoToSocialApiResult a =
    Result GoToSocialApi.Error (GoToSocialApi.Response a)


type alias PleromaApiResult a =
    Result PleromaApi.Error (PleromaApi.Response a)


type MastodonMsg
    = MastodonAppCreated String String (MastodonApiResult MastodonAppRegistration.AppDataFromServer)
    | MastodonAccessToken String (MastodonApiResult MastodonAppRegistration.TokenDataFromServer)
    | MastodonAccount String (MastodonApiResult MastodonAccount.Account)


type GoToSocialMsg
    = GoToSocialAppCreated String String (GoToSocialApiResult GoToSocialAppRegistration.AppDataFromServer)
    | GoToSocialAccessToken String (GoToSocialApiResult GoToSocialAppRegistration.TokenDataFromServer)


type PleromaMsg
    = PleromaAppCreated String String (PleromaApiResult PleromaAppRegistration.AppDataFromServer)
    | PleromaAccessToken String (PleromaApiResult PleromaAppRegistration.TokenDataFromServer)


type GeneralMsg
    = GeneralLinksDetected String (Result Http.Error Links)
    | GeneralNodeInfoFetched String (Result Http.Error NodeInfo)


type BackendMsg
    = MastodonMsg MastodonMsg
    | GoToSocialMsg GoToSocialMsg
    | PleromaMsg PleromaMsg
    | GeneralMsg GeneralMsg


backendMsgToFediEntityMsg : BackendMsg -> Result () Msg
backendMsgToFediEntityMsg backendMsg =
    case Debug.log "bck msg" backendMsg of
        GeneralMsg (GeneralLinksDetected baseUrl result) ->
            result
                |> Result.mapError (\_ -> ())
                |> Result.map (\links -> LinksDetected baseUrl links)

        GeneralMsg (GeneralNodeInfoFetched baseUrl result) ->
            result
                |> Result.mapError (\_ -> ())
                |> Result.map (\a -> NodeInfoFetched baseUrl a)

        GoToSocialMsg (GoToSocialAppCreated server uuid result) ->
            result
                |> Result.mapError (\_ -> ())
                |> Result.map (\a -> AppDataReceived uuid <| GoToSocialAppRegistration.toAppData a.decoded server Fediverse.Default.defaultScopes)

        GoToSocialMsg (GoToSocialAccessToken uuid result) ->
            result
                |> Result.mapError (\_ -> ())
                |> Result.map (\a -> TokenDataReceived uuid <| MastodonAppRegistration.toTokenData a.decoded)

        MastodonMsg (MastodonAccessToken uuid result) ->
            result
                |> Result.mapError (\_ -> ())
                |> Result.map (\a -> TokenDataReceived uuid <| MastodonAppRegistration.toTokenData a.decoded)

        MastodonMsg (MastodonAccount uuid result) ->
            result
                |> Result.mapError (\_ -> ())
                |> Result.map (\a -> AccountReceived uuid <| MastodonAccount.toAccount a.decoded)

        MastodonMsg (MastodonAppCreated server uuid result) ->
            result
                |> Result.mapError (\_ -> ())
                |> Result.map (\a -> AppDataReceived uuid <| MastodonAppRegistration.toAppData a.decoded server Fediverse.Default.defaultScopes)

        PleromaMsg (PleromaAppCreated server uuid result) ->
            result
                |> Result.mapError (\_ -> ())
                |> Result.map (\a -> AppDataReceived uuid <| PleromaAppRegistration.toAppData a.decoded server Fediverse.Default.defaultScopes)

        PleromaMsg (PleromaAccessToken uuid result) ->
            result
                |> Result.mapError (\_ -> ())
                |> Result.map (\a -> TokenDataReceived uuid <| PleromaAppRegistration.toTokenData a.decoded)
