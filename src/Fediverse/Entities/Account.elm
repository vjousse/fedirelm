module Fediverse.Entities.Account exposing (..)

import Fediverse.Entities.Emoji exposing (Emoji)
import Fediverse.Entities.Field exposing (Field)
import Fediverse.Entities.Role exposing (Role)
import Fediverse.Entities.Source exposing (Source)
import Time exposing (Posix)


type MoveAccount
    = MoveAccount Account


type alias Account =
    { id : String
    , username : String
    , acct : String
    , displayName : String
    , locked : Bool
    , discoverable : Maybe Bool
    , group : Maybe Bool
    , noindex : Maybe Bool
    , moved : Maybe MoveAccount
    , suspended : Maybe Bool
    , limited : Maybe Bool
    , createdAt : Posix
    , followersCount : Int
    , followingCount : Int
    , statusesCount : Int
    , note : String
    , url : String
    , avatar : String
    , avatarStatic : String
    , header : String
    , headerStatic : String
    , emojis : List Emoji
    , fields : List Field
    , bot : Bool
    , source : Maybe Source
    , role : Maybe Role
    , muteExpiresAt : Maybe Posix
    }
