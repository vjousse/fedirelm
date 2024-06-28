module Fediverse.Msg exposing (Msg(..))

import Fediverse.OAuth exposing (AppData)


type Msg
    = AppDataReceived AppData
