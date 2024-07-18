module Fediverse.Mastodon.Entities.Attachment exposing (..)

import Fediverse.Entities.Attachment as FediverseAttachment exposing (AttachmentType(..))
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipe


type alias Attachment =
    { blurhash : Maybe String
    , description : Maybe String
    , id : String
    , meta : Maybe AttachmentMeta
    , previewUrl : Maybe String
    , remoteUrl : Maybe String
    , textUrl : Maybe String
    , type_ : AttachmentType
    , url : Maybe String
    }


attachmentDecoder : Decode.Decoder Attachment
attachmentDecoder =
    Decode.succeed Attachment
        |> Pipe.optional "blurhash" (Decode.nullable Decode.string) Nothing
        |> Pipe.optional "description" (Decode.nullable Decode.string) Nothing
        |> Pipe.required "id" Decode.string
        |> Pipe.optional "meta" (Decode.nullable attachmentMetaDecoder) Nothing
        |> Pipe.optional "preview_url" (Decode.nullable Decode.string) Nothing
        |> Pipe.optional "remote_url" (Decode.nullable Decode.string) Nothing
        |> Pipe.optional "text_url" (Decode.nullable Decode.string) Nothing
        |> Pipe.required "type" attachmentTypeDecoder
        |> Pipe.optional "url" (Decode.nullable Decode.string) Nothing


type alias AttachmentMeta =
    { aspect : Maybe Float
    , audioBitrate : Maybe String
    , audioChannel : Maybe String
    , audioEncode : Maybe String
    , duration : Maybe Float
    , focus : Maybe Focus
    , fps : Maybe Int
    , height : Maybe Int
    , length : Maybe String
    , original : Maybe MetaSub
    , size : Maybe String
    , small : Maybe MetaSub
    , width : Maybe Int
    }


attachmentMetaDecoder : Decode.Decoder AttachmentMeta
attachmentMetaDecoder =
    Decode.succeed AttachmentMeta
        |> Pipe.optional "aspect" (Decode.nullable Decode.float) Nothing
        |> Pipe.optional "audio_bitrate" (Decode.nullable Decode.string) Nothing
        |> Pipe.optional "audio_channel" (Decode.nullable Decode.string) Nothing
        |> Pipe.optional "audio_encode" (Decode.nullable Decode.string) Nothing
        |> Pipe.optional "duration" (Decode.nullable Decode.float) Nothing
        |> Pipe.optional "focus" (Decode.nullable focusDecoder) Nothing
        |> Pipe.optional "fps" (Decode.nullable Decode.int) Nothing
        |> Pipe.optional "height" (Decode.nullable Decode.int) Nothing
        |> Pipe.optional "length" (Decode.nullable Decode.string) Nothing
        |> Pipe.optional "original" (Decode.nullable attachmentMetaSubDecoder) Nothing
        |> Pipe.optional "size" (Decode.nullable Decode.string) Nothing
        |> Pipe.optional "small" (Decode.nullable attachmentMetaSubDecoder) Nothing
        |> Pipe.optional "width" (Decode.nullable Decode.int) Nothing


type alias MetaSub =
    { -- For Image, Gifv, Video
      aspect : Maybe Float
    , bitrate : Maybe Int
    , -- For Audio, Gifv, Video
      duration : Maybe Float
    , -- For Gifv, Video
      frameRate : Maybe String
    , height : Maybe Int
    , size : Maybe String
    , width : Maybe Int
    }


attachmentMetaSubDecoder : Decode.Decoder MetaSub
attachmentMetaSubDecoder =
    Decode.succeed MetaSub
        |> Pipe.optional "aspect" (Decode.nullable Decode.float) Nothing
        |> Pipe.optional "bitrate" (Decode.nullable Decode.int) Nothing
        |> Pipe.optional "duration" (Decode.nullable Decode.float) Nothing
        |> Pipe.optional "frame_rate" (Decode.nullable Decode.string) Nothing
        |> Pipe.optional "height" (Decode.nullable Decode.int) Nothing
        |> Pipe.optional "size" (Decode.nullable Decode.string) Nothing
        |> Pipe.optional "width" (Decode.nullable Decode.int) Nothing


type alias Focus =
    { x : Float
    , y : Float
    }


focusDecoder : Decode.Decoder Focus
focusDecoder =
    Decode.succeed Focus
        |> Pipe.required "x" Decode.float
        |> Pipe.required "y" Decode.float


type AttachmentType
    = Audio
    | Gifv
    | Image
    | Unknown
    | Video


attachmentTypeDecoder : Decode.Decoder AttachmentType
attachmentTypeDecoder =
    Decode.string
        |> Decode.andThen
            (\str ->
                case str of
                    "audio" ->
                        Decode.succeed Audio

                    "gifv" ->
                        Decode.succeed Gifv

                    "image" ->
                        Decode.succeed Image

                    "unknown" ->
                        Decode.succeed Unknown

                    "video" ->
                        Decode.succeed Video

                    _ ->
                        Decode.fail "Invalid AttachementType value"
            )


toAttachmentType : AttachmentType -> FediverseAttachment.AttachmentType
toAttachmentType self =
    case self of
        Audio ->
            FediverseAttachment.Audio

        Gifv ->
            FediverseAttachment.Gifv

        Image ->
            FediverseAttachment.Image

        Unknown ->
            FediverseAttachment.Unknown

        Video ->
            FediverseAttachment.Video


toMetaSub : MetaSub -> FediverseAttachment.MetaSub
toMetaSub self =
    { -- For Image, Gifv, Video
      aspect = self.aspect
    , bitrate = self.bitrate
    , -- For Audio, Gifv, Video
      duration = self.duration
    , -- For Gifv, Video
      frameRate = self.frameRate
    , height = self.height
    , size = self.size
    , width = self.width
    }


toAttachmentMeta : AttachmentMeta -> FediverseAttachment.AttachmentMeta
toAttachmentMeta self =
    { aspect = self.aspect
    , audioBitrate = self.audioBitrate
    , audioChannel = self.audioChannel
    , audioEncode = self.audioEncode
    , duration = self.duration
    , focus = self.focus
    , fps = self.fps
    , height = self.height
    , length = self.length
    , original = self.original |> Maybe.map toMetaSub
    , size = self.size
    , small = self.small |> Maybe.map toMetaSub
    , width = self.width
    }


toAttachment : Attachment -> FediverseAttachment.Attachment
toAttachment self =
    { blurhash = self.blurhash
    , description = self.description
    , id = self.id
    , meta = self.meta |> Maybe.map toAttachmentMeta
    , previewUrl = self.previewUrl
    , remoteUrl = self.remoteUrl
    , textUrl = self.textUrl
    , type_ = toAttachmentType self.type_
    , url = self.url |> Maybe.withDefault ""
    }