module Fediverse.Entities.Status exposing (..)

import Fediverse.Entities.Account exposing (Account)
import Fediverse.Entities.Application exposing (Application)
import Fediverse.Entities.Attachment exposing (Attachment)
import Fediverse.Entities.Card exposing (Card)
import Fediverse.Entities.Emoji exposing (Emoji)
import Fediverse.Entities.Mention exposing (Mention)
import Fediverse.Entities.Poll exposing (Poll)
import Fediverse.Entities.Reaction exposing (Reaction)
import Fediverse.Entities.Tag exposing (Tag)
import Json.Decode as Decode
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
    , content : String
    , createdAt : Posix
    , editedAt : Maybe Posix
    , emojiReactions : Maybe (List Reaction)
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
    , plainContent : Maybe String
    , poll : Maybe Poll
    , quote : Bool
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
