port module Ports exposing (..)


port saveAppData : String -> Cmd msg


port saveSessions : String -> Cmd msg


port deleteAppData : String -> Cmd msg
