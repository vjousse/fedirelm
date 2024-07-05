module Fedirelm.Shared exposing (..)

import Browser.Navigation as Nav
import Fedirelm.AppDataStorage exposing (AppDataStorage)
import Fedirelm.Session exposing (FediSessions)
import UUID


type alias Identity =
    String


type alias SharedModel =
    { appDataStorages : Maybe (List AppDataStorage)
    , identity : Maybe Identity
    , key : Nav.Key
    , location : String
    , seeds : UUID.Seeds
    , sessions : FediSessions
    }
