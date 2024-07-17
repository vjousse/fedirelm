module Fediverse.Mastodon.Entities.Card exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline as Pipe


type CardType
    = Link
    | Photo
    | Rich
    | Video


type alias Card =
    { authorName : String
    , authorUrl : String
    , blurhash : Maybe String
    , description : String
    , embedUrl : String
    , height : Int
    , html : String
    , image : Maybe String
    , providerName : String
    , providerUrl : String
    , title : String
    , type_ : CardType
    , url : String
    , width : Int
    }


cardDecoder : Decode.Decoder Card
cardDecoder =
    Decode.succeed Card
        |> Pipe.required "author_name" Decode.string
        |> Pipe.required "author_url" Decode.string
        |> Pipe.optional "blurhash" (Decode.nullable Decode.string) Nothing
        |> Pipe.required "description" Decode.string
        |> Pipe.required "embed_url" Decode.string
        |> Pipe.required "height" Decode.int
        |> Pipe.required "html" Decode.string
        |> Pipe.optional "image" (Decode.nullable Decode.string) Nothing
        |> Pipe.required "provider_name" Decode.string
        |> Pipe.required "provider_url" Decode.string
        |> Pipe.required "title" Decode.string
        |> Pipe.required "type" cardTypeDecoder
        |> Pipe.required "url" Decode.string
        |> Pipe.required "width" Decode.int


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
