module Fediverse.GoToSocial.Entities.Emoji exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline as Pipe
import Json.Encode as Encode


type alias Emoji =
    { category : Maybe String
    , shortcode : String
    , staticUrl : String
    , url : String
    , visibleInPicker : Bool
    }


emojiDecoder : Decode.Decoder Emoji
emojiDecoder =
    Decode.succeed Emoji
        |> Pipe.optional "category" (Decode.nullable Decode.string) Nothing
        |> Pipe.required "shortcode" Decode.string
        |> Pipe.required "static_url" Decode.string
        |> Pipe.required "url" Decode.string
        |> Pipe.required "visible_in_picker" Decode.bool


emojiEncoder : Emoji -> Encode.Value
emojiEncoder emoji =
    Encode.object
        [ ( "category"
          , emoji.category
                |> Maybe.map Encode.string
                |> Maybe.withDefault Encode.null
          )
        , ( "shortcode", Encode.string emoji.shortcode )
        , ( "static_url", Encode.string emoji.staticUrl )
        , ( "url", Encode.string emoji.url )
        , ( "visible_in_picker", Encode.bool emoji.visibleInPicker )
        ]
