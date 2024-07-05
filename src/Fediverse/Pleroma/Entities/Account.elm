module Fediverse.Pleroma.Entities.Account exposing (..)

import Fediverse.Entities.Account as FediverseAccount
import Fediverse.Pleroma.Entities.Emoji exposing (Emoji, emojiDecoder, emojiEncoder, toEmoji)
import Fediverse.Pleroma.Entities.Field exposing (Field, fieldDecoder, fieldEncoder, toField)
import Fediverse.Pleroma.Entities.Source exposing (Source, sourceDecoder, sourceEncoder, toSource)
import Iso8601
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipe
import Json.Encode as Encode
import Time exposing (Posix)


type MovedAccount
    = MovedAccount Account


type alias Account =
    { acct : String
    , avatar : String
    , avatarStatic : String
    , bot : Bool
    , createdAt : Posix
    , discoverable : Maybe Bool
    , displayName : String
    , emojis : List Emoji
    , fields : List Field
    , followersCount : Int
    , followingCount : Int
    , header : String
    , headerStatic : String
    , id : String
    , limited : Maybe Bool
    , locked : Bool
    , moved : Maybe MovedAccount
    , noindex : Maybe Bool
    , note : String
    , source : Maybe Source
    , statusesCount : Int
    , suspended : Maybe Bool
    , url : String
    , username : String
    }


accountDecoder : Decode.Decoder Account
accountDecoder =
    Decode.succeed Account
        |> Pipe.required "acct" Decode.string
        |> Pipe.required "avatar" Decode.string
        |> Pipe.required "avatar_static" Decode.string
        |> Pipe.required "bot" Decode.bool
        |> Pipe.required "created_at" Iso8601.decoder
        |> Pipe.optional "discoverable" (Decode.nullable Decode.bool) Nothing
        |> Pipe.required "display_name" Decode.string
        |> Pipe.required "emojis" (Decode.list emojiDecoder)
        |> Pipe.required "fields" (Decode.list fieldDecoder)
        |> Pipe.required "followers_count" Decode.int
        |> Pipe.required "following_count" Decode.int
        |> Pipe.required "header" Decode.string
        |> Pipe.required "header_static" Decode.string
        |> Pipe.required "id" Decode.string
        |> Pipe.optional "limited" (Decode.nullable Decode.bool) Nothing
        |> Pipe.required "locked" Decode.bool
        |> Pipe.optional "moved" (Decode.nullable (Decode.map MovedAccount (Decode.lazy (\_ -> accountDecoder)))) Nothing
        |> Pipe.optional "noindex" (Decode.nullable Decode.bool) Nothing
        |> Pipe.required "note" Decode.string
        |> Pipe.optional "source" (Decode.nullable sourceDecoder) Nothing
        |> Pipe.required "statuses_count" Decode.int
        |> Pipe.optional "suspended" (Decode.nullable Decode.bool) Nothing
        |> Pipe.required "url" Decode.string
        |> Pipe.required "username" Decode.string


accountEncoder : Account -> Encode.Value
accountEncoder a =
    Encode.object
        [ ( "acct", Encode.string a.acct )
        , ( "avatar", Encode.string a.avatar )
        , ( "avatar_static", Encode.string a.avatarStatic )
        , ( "bot", Encode.bool a.bot )
        , ( "created_at", Iso8601.encode a.createdAt )
        , ( "discoverable", a.discoverable |> Maybe.map Encode.bool |> Maybe.withDefault Encode.null )
        , ( "display_name", Encode.string a.displayName )
        , ( "emojis", Encode.list emojiEncoder a.emojis )
        , ( "fields", Encode.list fieldEncoder a.fields )
        , ( "followers_count", Encode.int a.followersCount )
        , ( "following_count", Encode.int a.followingCount )
        , ( "header", Encode.string a.header )
        , ( "header_static", Encode.string a.headerStatic )
        , ( "id", Encode.string a.id )
        , ( "limited", a.limited |> Maybe.map Encode.bool |> Maybe.withDefault Encode.null )
        , ( "locked", Encode.bool a.locked )
        , ( "moved"
          , a.moved
                |> Maybe.map
                    (\ma ->
                        case ma of
                            MovedAccount acc ->
                                accountEncoder acc
                    )
                |> Maybe.withDefault Encode.null
          )
        , ( "noindex", a.noindex |> Maybe.map Encode.bool |> Maybe.withDefault Encode.null )
        , ( "note", Encode.string a.note )
        , ( "source", a.source |> Maybe.map sourceEncoder |> Maybe.withDefault Encode.null )
        , ( "statuses_count", Encode.int a.statusesCount )
        , ( "suspended", a.suspended |> Maybe.map Encode.bool |> Maybe.withDefault Encode.null )
        , ( "url", Encode.string a.url )
        , ( "username", Encode.string a.username )
        ]


toAccount : Account -> FediverseAccount.Account
toAccount self =
    { acct = self.acct
    , avatar = self.avatar
    , avatarStatic = self.avatarStatic
    , bot = self.bot
    , createdAt = self.createdAt
    , discoverable = self.discoverable
    , displayName = self.displayName
    , emojis = self.emojis |> List.map toEmoji
    , fields = self.fields |> List.map toField
    , followersCount = self.followersCount
    , followingCount = self.followingCount
    , group = Nothing
    , header = self.header
    , headerStatic = self.headerStatic
    , id = self.id
    , limited = self.limited
    , locked = self.locked
    , moved = Nothing
    , muteExpiresAt = Nothing
    , noindex = self.noindex
    , note = self.note
    , role = Nothing
    , source = self.source |> Maybe.map toSource
    , statusesCount = self.statusesCount
    , suspended = self.suspended
    , url = self.url
    , username = self.username
    }
