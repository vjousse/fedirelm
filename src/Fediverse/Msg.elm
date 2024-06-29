module Fediverse.Msg exposing (Msg(..))

import Fediverse.OAuth exposing (AppData, TokenData)


type Msg
    = AppDataReceived String AppData
    | TokenDataReceived String TokenData
