module Fediverse.Entities.Card exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline as Pipe


type alias Card =
    { authorName : Maybe String
    , authorUrl : Maybe String
    , blurhash : Maybe String
    , description : String
    , embedUrl : Maybe String
    , height : Maybe Int
    , html : Maybe String
    , image : Maybe String
    , providerName : String
    , providerUrl : String
    , title : String
    , type_ : CardType
    , url : String
    , width : Maybe Int
    }


cardDecoder : Decode.Decoder Card
cardDecoder =
    Decode.succeed Card
        |> Pipe.optional "author_name" (Decode.nullable Decode.string) Nothing
        |> Pipe.optional "author_url" (Decode.nullable Decode.string) Nothing
        |> Pipe.optional "blurhash" (Decode.nullable Decode.string) Nothing
        |> Pipe.required "description" Decode.string
        |> Pipe.optional "embed_url" (Decode.nullable Decode.string) Nothing
        |> Pipe.optional "height" (Decode.nullable Decode.int) Nothing
        |> Pipe.optional "html" (Decode.nullable Decode.string) Nothing
        |> Pipe.optional "image" (Decode.nullable Decode.string) Nothing
        |> Pipe.required "provider_name" Decode.string
        |> Pipe.required "provider_url" Decode.string
        |> Pipe.required "title" Decode.string
        |> Pipe.required "type" cardTypeDecoder
        |> Pipe.required "url" Decode.string
        |> Pipe.optional "width" (Decode.nullable Decode.int) Nothing


type CardType
    = Link
    | Photo
    | Rich
    | Video


cardTypeDecoder : Decode.Decoder CardType
cardTypeDecoder =
    Decode.string
        |> Decode.andThen
            (\str ->
                case str of
                    "link" ->
                        Decode.succeed Link

                    "photo" ->
                        Decode.succeed Photo

                    "rich" ->
                        Decode.succeed Rich

                    "video" ->
                        Decode.succeed Video

                    _ ->
                        Decode.fail "Invalid CardType value"
            )
