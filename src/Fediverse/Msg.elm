module Fediverse.Msg exposing (..)

import Fediverse.Default
import Fediverse.Detector exposing (Links, NodeInfo)
import Fediverse.Entities.Account exposing (Account)
import Fediverse.GoToSocial.Api as GoToSocialApi
import Fediverse.GoToSocial.Entities.Account as GoToSocialAccount
import Fediverse.GoToSocial.Entities.AppRegistration as GoToSocialAppRegistration
import Fediverse.Mastodon.Api as MastodonApi
import Fediverse.Mastodon.Entities.Account as MastodonAccount
import Fediverse.Mastodon.Entities.AppRegistration as MastodonAppRegistration
import Fediverse.OAuth exposing (AppData, TokenData)
import Fediverse.Pleroma.Api as PleromaApi
import Fediverse.Pleroma.Entities.AppRegistration as PleromaAppRegistration
import Http


type alias AppDataUUID =
    String


type Msg
    = AppDataReceived AppDataUUID AppData
    | AccountReceived String Account
    | TokenDataReceived AppDataUUID TokenData
    | LinksDetected String Links
    | NodeInfoFetched String NodeInfo


type alias MastodonApiResult a =
    Result MastodonApi.Error (MastodonApi.Response a)


type alias GoToSocialApiResult a =
    Result GoToSocialApi.Error (GoToSocialApi.Response a)


type alias PleromaApiResult a =
    Result PleromaApi.Error (PleromaApi.Response a)


type MastodonMsg
    = MastodonAppCreated String AppDataUUID (MastodonApiResult MastodonAppRegistration.AppDataFromServer)
    | MastodonAccessToken AppDataUUID (MastodonApiResult MastodonAppRegistration.TokenDataFromServer)
    | MastodonAccount String (MastodonApiResult MastodonAccount.Account)


type GoToSocialMsg
    = GoToSocialAppCreated String AppDataUUID (GoToSocialApiResult GoToSocialAppRegistration.AppDataFromServer)
    | GoToSocialAccessToken AppDataUUID (GoToSocialApiResult GoToSocialAppRegistration.TokenDataFromServer)
    | GoToSocialAccount String (GoToSocialApiResult GoToSocialAccount.Account)


type PleromaMsg
    = PleromaAppCreated String AppDataUUID (PleromaApiResult PleromaAppRegistration.AppDataFromServer)
    | PleromaAccessToken AppDataUUID (PleromaApiResult PleromaAppRegistration.TokenDataFromServer)


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

        GoToSocialMsg (GoToSocialAccessToken uuid result) ->
            result
                |> Result.mapError (\_ -> ())
                |> Result.map (\a -> TokenDataReceived uuid <| MastodonAppRegistration.toTokenData a.decoded)

        GoToSocialMsg (GoToSocialAccount uuid result) ->
            result
                |> Result.mapError (\_ -> ())
                |> Result.map (\a -> AccountReceived uuid <| GoToSocialAccount.toAccount a.decoded)

        GoToSocialMsg (GoToSocialAppCreated server uuid result) ->
            result
                |> Result.mapError (\_ -> ())
                |> Result.map (\a -> AppDataReceived uuid <| GoToSocialAppRegistration.toAppData a.decoded server Fediverse.Default.defaultScopes)

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
