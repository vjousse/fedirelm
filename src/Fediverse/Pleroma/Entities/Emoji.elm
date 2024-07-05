module Fediverse.Pleroma.Entities.Emoji exposing (..)

import Fediverse.Entities.Emoji as FediverseEmoji
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipe
import Json.Encode as Encode


type alias Emoji =
    { shortcode : String
    , staticUrl : String
    , url : String
    , visibleInPicker : Bool
    }


emojiDecoder : Decode.Decoder Emoji
emojiDecoder =
    Decode.succeed Emoji
        |> Pipe.required "shortcode" Decode.string
        |> Pipe.required "static_url" Decode.string
        |> Pipe.required "url" Decode.string
        |> Pipe.required "visible_in_picker" Decode.bool


emojiEncoder : Emoji -> Encode.Value
emojiEncoder emoji =
    Encode.object
        [ ( "shortcode", Encode.string emoji.shortcode )
        , ( "static_url", Encode.string emoji.staticUrl )
        , ( "url", Encode.string emoji.url )
        , ( "visible_in_picker", Encode.bool emoji.visibleInPicker )
        ]


toEmoji : Emoji -> FediverseEmoji.Emoji
toEmoji self =
    { category = Nothing
    , shortcode = self.shortcode
    , staticUrl = self.staticUrl
    , url = self.url
    , visibleInPicker = self.visibleInPicker
    }
