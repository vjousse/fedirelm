module Fediverse.Msg exposing (Msg(..))

import Fediverse.OAuth exposing (AppData, TokenData)


type Msg
    = AppDataReceived AppData
    | TokenDataReceived TokenData
