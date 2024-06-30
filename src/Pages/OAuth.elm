module Pages.OAuth exposing (..)

import Effect exposing (Effect)
import Fedirelm.Msg
import Fedirelm.Shared exposing (SharedModel)
import Html exposing (text)
import Shared
import Spa.Page
import View exposing (View)


page : SharedModel -> Spa.Page.Page ( String, Maybe String ) Fedirelm.Msg.Msg (View Msg) Model Msg
page _ =
    Spa.Page.element
        { init = init
        , update = update
        , view = view
        , subscriptions = always Sub.none
        }


type Msg
    = NoOp


type alias Model =
    { appDataUuid : String, code : Maybe String }


init : ( String, Maybe String ) -> ( Model, Effect Fedirelm.Msg.Msg Msg )
init ( appDataUuid, code ) =
    { appDataUuid = appDataUuid, code = code }
        |> Effect.withShared
            (Shared.gotCode ( appDataUuid, code ))


update : Msg -> Model -> ( Model, Effect Fedirelm.Msg.Msg Msg )
update msg model =
    case msg of
        _ ->
            model |> Effect.withNone


view : Model -> View Msg
view _ =
    { title = "OAuth"
    , body = text ""
    }
