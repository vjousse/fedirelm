module Pages.Home exposing (page)

import Effect exposing (Effect)
import Fedirelm.Msg
import Fedirelm.Shared exposing (SharedModel)
import Html exposing (Html, a, button, div, text)
import Html.Attributes exposing (href, style)
import Html.Events exposing (onClick)
import Shared
import Spa.Page
import Spa.PageStack exposing (Model)
import View exposing (View)


type Msg
    = ConnectMastodon
    | ConnectGoToSocial
    | ConnectPleroma
    | ConnectUnknown String


type alias Model =
    {}


page : SharedModel -> Spa.Page.Page () Fedirelm.Msg.Msg (View Msg) Model Msg
page shared =
    Spa.Page.element
        { init = init
        , update = update
        , subscriptions = always Sub.none
        , view = view shared
        }


init : () -> ( Model, Effect Fedirelm.Msg.Msg Msg )
init _ =
    {} |> Effect.withNone


update : Msg -> Model -> ( Model, Effect Fedirelm.Msg.Msg Msg )
update msg model =
    case msg of
        ConnectGoToSocial ->
            model
                |> Effect.withShared Shared.connectToGoToSocial

        ConnectMastodon ->
            model
                |> Effect.withShared Shared.connectToMasto

        ConnectPleroma ->
            model
                |> Effect.withShared Shared.connectToPleroma

        ConnectUnknown baseUrl ->
            model
                |> Effect.withShared (Shared.connectToUnknown baseUrl)


view : SharedModel -> Model -> View Msg
view shared _ =
    { title = "Home"
    , body =
        div []
            [ case Shared.identity shared of
                Just identity ->
                    text <| "Welcome Home " ++ identity ++ "!"

                Nothing ->
                    text "Welcome Home!"
            , div [] [ a [ href "/counter" ] [ text "See counter" ] ]
            , div [] [ a [ href "/time" ] [ text "See time" ] ]
            , div [] [ a [ href "/oauth" ] [ text "See oauth" ] ]
            , myButton "Connect to Masto" (ConnectUnknown "https://mamot.fr")
            , myButton "Connect to GoToSocial" ConnectGoToSocial
            , myButton "Connect to Pleroma" ConnectPleroma
            ]
    }


myButton : String -> Msg -> Html Msg
myButton label msg =
    button
        [ onClick msg
        , style "margin" "10px"
        ]
        [ text label ]
