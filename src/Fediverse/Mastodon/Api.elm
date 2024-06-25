module Fediverse.Mastodon.Api exposing (..)

import Fediverse.Default exposing (defaultScopes, noRedirect)
import Fediverse.Mastodon.Entities.AppRegistration exposing (AppDataFromServer, appDataFromServerDecoder, appRegistrationDataEncoder)
import Http
import HttpBuilder
import Json.Decode as Decode


type alias AppInputOptions =
    { -- List of requested OAuth scopes.
      scopes : Maybe (List String)
    , -- Set a URI to redirect the user to.
      redirectUri : Maybe String
    , -- URL of the application.
      website : Maybe String
    }


type alias StatusCode =
    Int


type alias StatusMsg =
    String


type alias ErrorMsg =
    String


type Error
    = MastodonError StatusCode StatusMsg ErrorMsg
    | ServerError StatusCode StatusMsg ErrorMsg
    | TimeoutError
    | NetworkError


{-| Request
-}
type alias Request a =
    HttpBuilder.RequestBuilder (Response a)


{-| Response
-}
type alias Response a =
    { decoded : a
    }


createApp : String -> AppInputOptions -> (Result Error (Response AppDataFromServer) -> msg) -> Cmd msg
createApp clientName options toMsg =
    let
        scopes =
            Maybe.withDefault defaultScopes options.scopes

        redirectUri =
            Maybe.withDefault noRedirect options.redirectUri
    in
    HttpBuilder.post "https://mamot.fr/api/v1/apps"
        |> withBodyDecoder toMsg appDataFromServerDecoder
        |> HttpBuilder.withJsonBody
            (appRegistrationDataEncoder clientName redirectUri (String.join " " scopes) options.website)
        |> HttpBuilder.request


{-| mastodonErrorDecoder
-}
mastodonErrorDecoder : Decode.Decoder String
mastodonErrorDecoder =
    Decode.field "error" Decode.string


extractMastodonError : Int -> String -> String -> Error
extractMastodonError statusCode statusMsg body =
    case Decode.decodeString mastodonErrorDecoder body of
        Ok errRecord ->
            MastodonError statusCode statusMsg errRecord

        Err err ->
            Decode.errorToString err
                |> ServerError statusCode statusMsg


decodeResponse : Decode.Decoder a -> Http.Response String -> Result.Result Error (Response a)
decodeResponse decoder response =
    case response of
        Http.BadUrl_ _ ->
            Err NetworkError

        Http.Timeout_ ->
            Err TimeoutError

        Http.NetworkError_ ->
            Err NetworkError

        Http.BadStatus_ metadata body ->
            Err (extractMastodonError metadata.statusCode metadata.statusText body)

        Http.GoodStatus_ metadata body ->
            case Decode.decodeString decoder body of
                Ok value ->
                    Ok <| Response value

                Err e ->
                    Err
                        (ServerError metadata.statusCode
                            metadata.statusText
                            ("Failed decoding JSON: "
                                ++ body
                                ++ ", error: "
                                ++ Decode.errorToString e
                            )
                        )


{-| withBodyDecoder
-}
withBodyDecoder : (Result Error (Response a) -> msg) -> Decode.Decoder a -> HttpBuilder.RequestBuilder b -> HttpBuilder.RequestBuilder msg
withBodyDecoder toMsg decoder builder =
    HttpBuilder.withExpect (Http.expectStringResponse toMsg (decodeResponse decoder)) builder