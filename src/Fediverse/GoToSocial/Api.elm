module Fediverse.GoToSocial.Api exposing (..)

import Fediverse.Default exposing (noRedirect)
import Fediverse.GoToSocial.Entities.Account exposing (Account, accountDecoder)
import Fediverse.GoToSocial.Entities.AppRegistration exposing (AppDataFromServer, TokenDataFromServer, appDataFromServerDecoder, appRegistrationDataEncoder, tokenDataFromServerDecoder)
import Fediverse.OAuth exposing (AppData)
import Http
import HttpBuilder
import Json.Decode as Decode
import Json.Encode as Encode


type alias StatusCode =
    Int


type alias StatusMsg =
    String


type alias ErrorMsg =
    String


type alias AppInputOptions =
    { -- List of requested OAuth scopes.
      scopes : List String
    , -- Set a URI to redirect the user to.
      redirectUri : String
    , -- URL of the application.
      website : Maybe String
    }


type Error
    = GoToSocialError StatusCode StatusMsg ErrorMsg
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


{-| authorizationCodeEncoder
-}
accessTokenPayloadEncoder : AppData -> String -> Encode.Value
accessTokenPayloadEncoder appData authCode =
    Encode.object
        [ ( "client_id", Encode.string appData.clientId )
        , ( "client_secret", Encode.string appData.clientSecret )
        , ( "grant_type", Encode.string "authorization_code" )
        , ( "redirect_uri", Encode.string (Maybe.withDefault noRedirect appData.redirectUri) )
        , ( "code", Encode.string authCode )
        ]


getAccessToken : String -> AppData -> (Result Error (Response TokenDataFromServer) -> msg) -> Cmd msg
getAccessToken authCode appData toMsg =
    HttpBuilder.post (appData.baseUrl ++ "/oauth/token")
        |> withBodyDecoder toMsg tokenDataFromServerDecoder
        |> HttpBuilder.withJsonBody
            (accessTokenPayloadEncoder appData authCode)
        |> HttpBuilder.request


createApp : String -> String -> AppInputOptions -> (Result Error (Response AppDataFromServer) -> msg) -> Cmd msg
createApp baseUrl clientName options toMsg =
    HttpBuilder.post (baseUrl ++ "/api/v1/apps")
        |> withBodyDecoder toMsg appDataFromServerDecoder
        |> HttpBuilder.withJsonBody
            (appRegistrationDataEncoder clientName options.redirectUri (String.join " " options.scopes) options.website)
        |> HttpBuilder.request


getAccount : String -> String -> (Result Error (Response Account) -> msg) -> Cmd msg
getAccount baseUrl token toMsg =
    HttpBuilder.get (baseUrl ++ "/api/v1/accounts/verify_credentials")
        |> withBodyDecoder toMsg accountDecoder
        |> HttpBuilder.withHeader "Authorization" ("Bearer " ++ token)
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
            GoToSocialError statusCode statusMsg errRecord

        Err err ->
            Decode.errorToString err
                |> ServerError statusCode statusMsg


goToSocialErrorDecoder : Decode.Decoder String
goToSocialErrorDecoder =
    Decode.field "error" Decode.string
