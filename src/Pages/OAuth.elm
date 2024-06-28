module Pages.OAuth exposing (..)

import Effect exposing (Effect)
import Html exposing (text)
import Shared exposing (Shared)
import Spa.Page
import View exposing (View)


page : Shared -> Spa.Page.Page (Maybe String) Shared.Msg (View Msg) Model Msg
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
    { code : Maybe String }


init : Maybe String -> ( Model, Effect Shared.Msg Msg )
init code =
    { code = code }
        |> Effect.withShared
            (Shared.gotCode code)


update : Msg -> Model -> ( Model, Effect Shared.Msg Msg )
update msg model =
    case msg of
        _ ->
            model |> Effect.withNone


view : Model -> View Msg
view _ =
    { title = "OAuth"
    , body = text ""
    }
