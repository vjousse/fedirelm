module Fediverse.GoToSocial.Entities.Field exposing (..)

import Fediverse.Entities.Field as FediverseField
import Iso8601
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipe
import Json.Encode as Encode
import Time exposing (Posix)


type alias Field =
    { name : String
    , value : String
    , verifiedAt : Maybe Posix
    }


fieldDecoder : Decode.Decoder Field
fieldDecoder =
    Decode.succeed Field
        |> Pipe.required "name" Decode.string
        |> Pipe.required "value" Decode.string
        |> Pipe.optional "verified_at" (Decode.nullable Iso8601.decoder) Nothing


fieldEncoder : Field -> Encode.Value
fieldEncoder field =
    Encode.object
        [ ( "name", Encode.string field.name )
        , ( "value", Encode.string field.value )
        , ( "verified_at"
          , field.verifiedAt
                |> Maybe.map Iso8601.encode
                |> Maybe.withDefault Encode.null
          )
        ]


toField : Field -> FediverseField.Field
toField self =
    { name = self.name
    , value = self.value
    , verifiedAt = self.verifiedAt
    , verified = Nothing
    }
