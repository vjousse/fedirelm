module Fediverse.Entities.Account exposing (..)

import Fediverse.Entities.Emoji exposing (Emoji, emojiDecoder)
import Fediverse.Entities.Field exposing (Field, fieldDecoder)
import Fediverse.Entities.Role exposing (Role, roleDecoder)
import Fediverse.Entities.Source exposing (Source, sourceDecoder)
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipe
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
    , group : Maybe Bool
    , header : String
    , headerStatic : String
    , id : String
    , limited : Maybe Bool
    , locked : Bool
    , moved : Maybe MovedAccount
    , muteExpiresAt : Maybe Posix
    , noindex : Maybe Bool
    , note : String
    , role : Maybe Role
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
        |> Pipe.required "avatarStatic" Decode.string
        |> Pipe.required "bot" Decode.bool
        |> Pipe.required "createdAt" (Decode.int |> Decode.andThen (\t -> Decode.succeed (Time.millisToPosix t)))
        |> Pipe.optional "discoverable" (Decode.nullable Decode.bool) Nothing
        |> Pipe.required "displayName" Decode.string
        |> Pipe.required "emojis" (Decode.list emojiDecoder)
        |> Pipe.required "fields" (Decode.list fieldDecoder)
        |> Pipe.required "followersCount" Decode.int
        |> Pipe.required "followingCount" Decode.int
        |> Pipe.optional "group" (Decode.nullable Decode.bool) Nothing
        |> Pipe.required "header" Decode.string
        |> Pipe.required "headerStatic" Decode.string
        |> Pipe.required "id" Decode.string
        |> Pipe.optional "limited" (Decode.nullable Decode.bool) Nothing
        |> Pipe.required "locked" Decode.bool
        |> Pipe.optional "moved" (Decode.nullable (Decode.map MovedAccount (Decode.lazy (\_ -> accountDecoder)))) Nothing
        |> Pipe.optional "muteExpiresAt" (Decode.nullable (Decode.int |> Decode.andThen (\t -> Decode.succeed (Time.millisToPosix t)))) Nothing
        |> Pipe.optional "noindex" (Decode.nullable Decode.bool) Nothing
        |> Pipe.required "note" Decode.string
        |> Pipe.optional "role" (Decode.nullable roleDecoder) Nothing
        |> Pipe.optional "source" (Decode.nullable sourceDecoder) Nothing
        |> Pipe.required "statusesCount" Decode.int
        |> Pipe.optional "suspended" (Decode.nullable Decode.bool) Nothing
        |> Pipe.required "url" Decode.string
        |> Pipe.required "username" Decode.string
