module Fediverse.Formatter exposing (..)


cleanBaseUrl : String -> String
cleanBaseUrl baseUrl =
    if String.endsWith "/" baseUrl then
        String.dropRight 1 baseUrl

    else
        baseUrl
