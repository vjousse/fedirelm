module Fediverse.GoToSocial.Api exposing (..)

import Fediverse.Default exposing (defaultScopes, noRedirect)
import Fediverse.GoToSocial.Entities.AppRegistration exposing (AppDataFromServer, appDataFromServerDecoder, appRegistrationDataEncoder)
import Http
import HttpBuilder
import Json.Decode as Decode


type alias StatusCode =
    Int


type alias StatusMsg =
    String


type alias ErrorMsg =
    String


type alias AppInputOptions =
    { -- List of requested OAuth scopes.
      scopes : Maybe (List String)
    , -- Set a URI to redirect the user to.
      redirectUri : Maybe String
    , -- URL of the application.
      website : Maybe String
    }


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
    HttpBuilder.post "https://social.bacardi55.io/api/v1/apps"
        |> withBodyDecoder toMsg appDataFromServerDecoder
        |> HttpBuilder.withJsonBody
            (appRegistrationDataEncoder clientName redirectUri (String.join " " scopes) options.website)
        |> HttpBuilder.request


{-| withBodyDecoder
-}
withBodyDecoder : (Result Error (Response a) -> msg) -> Decode.Decoder a -> HttpBuilder.RequestBuilder b -> HttpBuilder.RequestBuilder msg
withBodyDecoder toMsg decoder builder =
    HttpBuilder.withExpect (Http.expectStringResponse toMsg (decodeResponse decoder)) builder


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
            Err (extractGoToSocialError metadata.statusCode metadata.statusText body)

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


extractGoToSocialError : Int -> String -> String -> Error
extractGoToSocialError statusCode statusMsg body =
    case Decode.decodeString goToSocialErrorDecoder body of
        Ok errRecord ->
            MastodonError statusCode statusMsg errRecord

        Err err ->
            Decode.errorToString err
                |> ServerError statusCode statusMsg


goToSocialErrorDecoder : Decode.Decoder String
goToSocialErrorDecoder =
    Decode.field "error" Decode.string
