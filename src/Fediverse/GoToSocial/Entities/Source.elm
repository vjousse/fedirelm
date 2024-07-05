module Fediverse.GoToSocial.Entities.Source exposing (..)

import Fediverse.Entities.Source as FediverseSource
import Fediverse.GoToSocial.Entities.Field exposing (Field, fieldDecoder, fieldEncoder, toField)
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipe
import Json.Encode as Encode


type alias Source =
    { fields : Maybe (List Field)
    , privacy : Maybe String
    , language : Maybe String
    , note : String
    , sensitive : Maybe Bool
    }


sourceDecoder : Decode.Decoder Source
sourceDecoder =
    Decode.succeed Source
        |> Pipe.optional "fields" (Decode.nullable (Decode.list fieldDecoder)) Nothing
        |> Pipe.optional "privacy" (Decode.nullable Decode.string) Nothing
        |> Pipe.optional "language" (Decode.nullable Decode.string) Nothing
        |> Pipe.required "note" Decode.string
        |> Pipe.optional "sensitive" (Decode.nullable Decode.bool) Nothing


sourceEncoder : Source -> Encode.Value
sourceEncoder source =
    Encode.object
        [ ( "fields"
          , source.fields
                |> Maybe.map (Encode.list fieldEncoder)
                |> Maybe.withDefault Encode.null
          )
        , ( "privacy"
          , source.privacy
                |> Maybe.map Encode.string
                |> Maybe.withDefault Encode.null
          )
        , ( "language"
          , source.language
                |> Maybe.map Encode.string
                |> Maybe.withDefault Encode.null
          )
        , ( "note", Encode.string source.note )
        , ( "sensitive"
          , source.sensitive
                |> Maybe.map Encode.bool
                |> Maybe.withDefault Encode.null
          )
        ]


toSource : Source -> FediverseSource.Source
toSource self =
    { fields = self.fields |> Maybe.map (\l -> l |> List.map toField)
    , privacy = self.privacy
    , language = self.language
    , note = self.note
    , sensitive = self.sensitive
    }
