module Fediverse.Detector exposing (..)

import Fediverse.Formatter
import Http
import HttpBuilder
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipe


type alias Links =
    { links : List Link
    }


type alias Link =
    { href : String
    , rel : String
    }


linkDecoder : Decode.Decoder Link
linkDecoder =
    Decode.succeed Link
        |> Pipe.required "href" Decode.string
        |> Pipe.required "rel" Decode.string


linksDecoder : Decode.Decoder Links
linksDecoder =
    Decode.succeed Links
        |> Pipe.required "links" (Decode.list linkDecoder)


nodeInfo10Url : String
nodeInfo10Url =
    "http://nodeinfo.diaspora.software/ns/schema/1.0"


nodeInfo20Url : String
nodeInfo20Url =
    "http://nodeinfo.diaspora.software/ns/schema/2.0"


nodeInfo21Url : String
nodeInfo21Url =
    "http://nodeinfo.diaspora.software/ns/schema/2.1"


getLinks : String -> (Result Http.Error Links -> msg) -> Cmd msg
getLinks baseUrl toMsg =
    HttpBuilder.get (Fediverse.Formatter.cleanBaseUrl baseUrl ++ "/.well-known/nodeinfo")
        |> withBodyDecoder toMsg linksDecoder
        |> HttpBuilder.request


{-| withBodyDecoder
-}
withBodyDecoder : (Result Http.Error a -> msg) -> Decode.Decoder a -> HttpBuilder.RequestBuilder b -> HttpBuilder.RequestBuilder msg
withBodyDecoder toMsg decoder builder =
    builder
        |> HttpBuilder.withExpect (Http.expectJson toMsg decoder)
