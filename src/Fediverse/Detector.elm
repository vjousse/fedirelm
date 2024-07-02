module Fediverse.Detector exposing (..)

import Fediverse.Formatter
import Http
import HttpBuilder
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipe
import List.Extra
import Url.Builder


type alias Links =
    { links : List Link
    }


type alias Link =
    { href : String
    , rel : String
    }


type alias NodeInfo =
    { metadata : Metadata
    , software : Software
    }


type alias Software =
    { name : String
    }


type alias Metadata =
    { upstream : Maybe Upstream
    }


type alias Upstream =
    { name : String
    }


softwareDecoder : Decode.Decoder Software
softwareDecoder =
    Decode.succeed Software
        |> Pipe.required "name" Decode.string


upstreamDecoder : Decode.Decoder Upstream
upstreamDecoder =
    Decode.succeed Upstream
        |> Pipe.required "name" Decode.string


metadataDecoder : Decode.Decoder Metadata
metadataDecoder =
    Decode.succeed Metadata
        |> Pipe.optional "upstream" (Decode.nullable upstreamDecoder) Nothing


nodeInfoDecoder : Decode.Decoder NodeInfo
nodeInfoDecoder =
    Decode.succeed NodeInfo
        |> Pipe.required "metadata" metadataDecoder
        |> Pipe.required "software" softwareDecoder


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


findLink : Links -> Maybe Link
findLink links =
    List.Extra.find (\l -> l.rel == nodeInfo20Url || l.rel == nodeInfo21Url || l.rel == nodeInfo10Url) links.links


getLinks : String -> (Result Http.Error Links -> msg) -> Cmd msg
getLinks baseUrl toMsg =
    HttpBuilder.get (Fediverse.Formatter.cleanBaseUrl baseUrl ++ "/.well-known/nodeinfo")
        |> withBodyDecoder toMsg linksDecoder
        |> HttpBuilder.request


getNodeInfo : String -> (Result Http.Error NodeInfo -> msg) -> Cmd msg
getNodeInfo baseUrl toMsg =
    let
        crossOriginUrl =
            Url.Builder.crossOrigin (Fediverse.Formatter.cleanBaseUrl baseUrl) [] []
    in
    HttpBuilder.get crossOriginUrl
        |> withBodyDecoder toMsg nodeInfoDecoder
        |> HttpBuilder.request


{-| withBodyDecoder
-}
withBodyDecoder : (Result Http.Error a -> msg) -> Decode.Decoder a -> HttpBuilder.RequestBuilder b -> HttpBuilder.RequestBuilder msg
withBodyDecoder toMsg decoder builder =
    builder
        |> HttpBuilder.withExpect (Http.expectJson toMsg decoder)
