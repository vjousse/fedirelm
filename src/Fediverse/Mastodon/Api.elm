module Fediverse.Mastodon.Api exposing (..)

import Fediverse.Default exposing (noRedirect)
import Fediverse.Mastodon.Entities.Account exposing (Account, accountDecoder)
import Fediverse.Mastodon.Entities.AppRegistration exposing (AppDataFromServer, TokenDataFromServer, appDataFromServerDecoder, appRegistrationDataEncoder, tokenDataFromServerDecoder)
import Fediverse.Mastodon.Entities.Status exposing (Status, statusDecoder)
import Fediverse.OAuth exposing (AppData)
import Http
import HttpBuilder
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipe
import Json.Encode as Encode


type alias AppInputOptions =
    { -- List of requested OAuth scopes.
      scopes : List String
    , -- Set a URI to redirect the user to.
      redirectUri : String
    , -- URL of the application.
      website : Maybe String
    }


type alias StatusCode =
    Int


type alias StatusMsg =
    String


type alias ErrorMsg =
    { error : String, errorDescription : Maybe String }


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


createApp : String -> String -> AppInputOptions -> (Result Error (Response AppDataFromServer) -> msg) -> Cmd msg
createApp baseUrl clientName options toMsg =
    HttpBuilder.post (baseUrl ++ "/api/v1/apps")
        |> withBodyDecoder toMsg appDataFromServerDecoder
        |> HttpBuilder.withJsonBody
            (appRegistrationDataEncoder clientName options.redirectUri (String.join " " options.scopes) options.website)
        |> HttpBuilder.request


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


verifiyCredentials : String -> String -> (Result Error (Response Account) -> msg) -> Cmd msg
verifiyCredentials baseUrl token toMsg =
    HttpBuilder.get (baseUrl ++ "/api/v1/accounts/verify_credentials")
        |> withBodyDecoder toMsg accountDecoder
        |> HttpBuilder.withHeader "Authorization" ("Bearer " ++ token)
        |> HttpBuilder.request


getPublicTimeline : String -> String -> (Result Error (Response (List Status)) -> msg) -> Cmd msg
getPublicTimeline baseUrl token toMsg =
    HttpBuilder.get (baseUrl ++ "/api/v1/timelines/public")
        |> withBodyDecoder toMsg (Decode.list statusDecoder)
        |> HttpBuilder.withHeader "Authorization" ("Bearer " ++ token)
        |> HttpBuilder.request


{-| mastodonErrorDecoder
-}
mastodonErrorDecoder : Decode.Decoder ErrorMsg
mastodonErrorDecoder =
    Decode.succeed ErrorMsg
        |> Pipe.required "error" Decode.string
        |> Pipe.optional "error_description" (Decode.nullable Decode.string) Nothing


extractMastodonError : Int -> String -> String -> Error
extractMastodonError statusCode statusMsg body =
    case Decode.decodeString mastodonErrorDecoder body of
        Ok errRecord ->
            MastodonError statusCode statusMsg errRecord

        Err err ->
            ServerError statusCode statusMsg { error = Decode.errorToString err, errorDescription = Nothing }


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
                            { error =
                                "Failed decoding JSON: "
                                    ++ body
                                    ++ ", error: "
                                    ++ Decode.errorToString e
                            , errorDescription = Nothing
                            }
                        )


{-| withBodyDecoder
-}
withBodyDecoder : (Result Error (Response a) -> msg) -> Decode.Decoder a -> HttpBuilder.RequestBuilder b -> HttpBuilder.RequestBuilder msg
withBodyDecoder toMsg decoder builder =
    HttpBuilder.withExpect (Http.expectStringResponse toMsg (decodeResponse decoder)) builder
