module Fedirelm.AppDataStorage exposing (..)

import Fediverse.OAuth exposing (AppData, appDataDecoder)
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipe
import List.Extra


appDataStorageByUuid : String -> Maybe (List AppDataStorage) -> Maybe AppDataStorage
appDataStorageByUuid uuid appDatas =
    appDatas
        |> Maybe.withDefault []
        |> List.Extra.find (\a -> a.uuid == uuid)


type alias AppDataStorage =
    { uuid : String
    , appData : AppData
    }


appDataStorageDecoder : Decode.Decoder AppDataStorage
appDataStorageDecoder =
    Decode.succeed AppDataStorage
        |> Pipe.required "uuid" Decode.string
        |> Pipe.required "appData" appDataDecoder
