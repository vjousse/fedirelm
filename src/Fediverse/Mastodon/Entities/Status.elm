module Fediverse.Mastodon.Entities.Status exposing (..)

import Fediverse.Entities.Status as FediverseStatus
import Fediverse.Mastodon.Entities.Account exposing (Account, accountDecoder, toAccount)
import Fediverse.Mastodon.Entities.Application exposing (Application, applicationDecoder)
import Fediverse.Mastodon.Entities.Attachment exposing (Attachment, attachmentDecoder, toAttachment)
import Fediverse.Mastodon.Entities.Card exposing (Card, cardDecoder, toCard)
import Fediverse.Mastodon.Entities.Emoji exposing (Emoji, emojiDecoder)
import Fediverse.Mastodon.Entities.Mention exposing (Mention, mentionDecoder)
import Fediverse.Mastodon.Entities.Poll exposing (Poll, pollDecoder)
import Fediverse.Mastodon.Entities.Tag exposing (Tag, tagDecoder)
import Iso8601
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipe
import Time exposing (Posix)


type RebloggedStatus
    = RebloggedStatus Status


type QuotedStatus
    = QuotedStatus Status


type alias Status =
    { account : Account
    , application : Maybe Application
    , bookmarked : Maybe Bool
    , card : Maybe Card
    , createdAt : Posix
    , content : String
    , editedAt : Maybe Posix
    , emojis : List Emoji
    , favourited : Maybe Bool
    , favouritesCount : Int
    , id : String
    , inReplyToAccountId : Maybe String
    , inReplyToId : Maybe String
    , language : Maybe String
    , mediaAttachments : List Attachment
    , mentions : List Mention
    , muted : Maybe Bool
    , pinned : Maybe Bool
    , poll : Maybe Poll
    , quote : Maybe QuotedStatus
    , reblog : Maybe RebloggedStatus
    , reblogged : Maybe Bool
    , reblogsCount : Int
    , repliesCount : Int
    , sensitive : Bool
    , spoilerText : String
    , tags : List Tag
    , uri : String
    , url : Maybe String
    , visibility : StatusVisibility
    }


statusDecoder : Decode.Decoder Status
statusDecoder =
    Decode.succeed Status
        |> Pipe.required "account" accountDecoder
        |> Pipe.optional "application" (Decode.nullable applicationDecoder) Nothing
        |> Pipe.optional "bookmarked" (Decode.nullable Decode.bool) Nothing
        |> Pipe.optional "card" (Decode.nullable cardDecoder) Nothing
        |> Pipe.required "created_at" Iso8601.decoder
        |> Pipe.required "content" Decode.string
        |> Pipe.optional "edited_at" (Decode.nullable Iso8601.decoder) Nothing
        |> Pipe.required "emojis" (Decode.list emojiDecoder)
        |> Pipe.optional "favourited" (Decode.nullable Decode.bool) Nothing
        |> Pipe.required "favourites_count" Decode.int
        |> Pipe.required "id" Decode.string
        |> Pipe.optional "in_reply_to_account_id" (Decode.nullable Decode.string) Nothing
        |> Pipe.optional "in_reply_to_id" (Decode.nullable Decode.string) Nothing
        |> Pipe.optional "language" (Decode.nullable Decode.string) Nothing
        |> Pipe.required "media_attachments" (Decode.list attachmentDecoder)
        |> Pipe.required "mentions" (Decode.list mentionDecoder)
        |> Pipe.optional "muted" (Decode.nullable Decode.bool) Nothing
        |> Pipe.optional "pinned" (Decode.nullable Decode.bool) Nothing
        |> Pipe.optional "poll" (Decode.nullable pollDecoder) Nothing
        |> Pipe.optional "quote" (Decode.nullable (Decode.map QuotedStatus (Decode.lazy (\_ -> statusDecoder)))) Nothing
        |> Pipe.optional "reblog" (Decode.nullable (Decode.map RebloggedStatus (Decode.lazy (\_ -> statusDecoder)))) Nothing
        |> Pipe.optional "reblogged" (Decode.nullable Decode.bool) Nothing
        |> Pipe.required "reblogs_count" Decode.int
        |> Pipe.required "replies_count" Decode.int
        |> Pipe.required "sensitive" Decode.bool
        |> Pipe.required "spoiler_text" Decode.string
        |> Pipe.required "tags" (Decode.list tagDecoder)
        |> Pipe.required "uri" Decode.string
        |> Pipe.optional "url" (Decode.nullable Decode.string) Nothing
        |> Pipe.required "visibility" statusVisibilityDecoder


type StatusVisibility
    = Direct
    | Private
    | Public
    | Unlisted


statusVisibilityDecoder : Decode.Decoder StatusVisibility
statusVisibilityDecoder =
    Decode.string
        |> Decode.andThen
            (\str ->
                case str of
                    "direct" ->
                        Decode.succeed Direct

                    "private" ->
                        Decode.succeed Private

                    "public" ->
                        Decode.succeed Public

                    "unlisted" ->
                        Decode.succeed Unlisted

                    _ ->
                        Decode.fail "Invalid StatusVisibility value"
            )


toStatusVisibility : StatusVisibility -> FediverseStatus.StatusVisibility
toStatusVisibility self =
    case self of
        Direct ->
            FediverseStatus.Direct

        Private ->
            FediverseStatus.Private

        Public ->
            FediverseStatus.Public

        Unlisted ->
            FediverseStatus.Unlisted


toStatus : Status -> FediverseStatus.Status
toStatus self =
    let
        ( reblogStatus, quoted ) =
            case ( self.reblog, self.quote ) of
                ( Just (RebloggedStatus status), _ ) ->
                    ( Just (FediverseStatus.RebloggedStatus (status |> toStatus)), False )

                ( _, Just (QuotedStatus status) ) ->
                    ( Just (FediverseStatus.RebloggedStatus (status |> toStatus)), True )

                ( _, _ ) ->
                    ( Nothing, False )
    in
    { account = toAccount self.account
    , application = self.application
    , bookmarked = self.bookmarked
    , card = self.card |> Maybe.map toCard
    , content = self.content
    , createdAt = self.createdAt
    , editedAt = self.editedAt
    , emojiReactions = Nothing
    , emojis = self.emojis
    , favourited = self.favourited
    , favouritesCount = self.favouritesCount
    , id = self.id
    , inReplyToAccountId = self.inReplyToAccountId
    , inReplyToId = self.inReplyToId
    , language = self.language
    , mediaAttachments = self.mediaAttachments |> List.map toAttachment
    , mentions = self.mentions
    , muted = self.muted
    , pinned = self.pinned
    , plainContent = Nothing
    , poll = self.poll
    , quote = quoted
    , reblog = reblogStatus
    , reblogged = self.reblogged
    , reblogsCount = self.reblogsCount
    , repliesCount = self.repliesCount
    , sensitive = self.sensitive
    , spoilerText = self.spoilerText
    , tags = self.tags
    , uri = self.uri
    , url = self.url
    , visibility = toStatusVisibility self.visibility
    }
