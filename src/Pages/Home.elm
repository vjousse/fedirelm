module Pages.Home exposing (page)

import Effect exposing (Effect)
import Html exposing (Html, a, br, button, div, text)
import Html.Attributes exposing (href, style)
import Html.Events exposing (onClick)
import Shared exposing (Shared)
import Spa.Page
import Spa.PageStack exposing (Model)
import View exposing (View)


type Msg
    = ConnectMastodon


type alias Model =
    { shared : Shared }


page : Shared -> Spa.Page.Page () Shared.Msg (View Msg) Model Msg
page shared =
    Spa.Page.element
        { init = init shared
        , update = update
        , subscriptions = always Sub.none
        , view = view
        }


init : Shared -> () -> ( Model, Effect Shared.Msg Msg )
init shared _ =
    { shared = shared } |> Effect.withNone


update : Msg -> Model -> ( Model, Effect Shared.Msg Msg )
update msg model =
    case msg of
        ConnectMastodon ->
            model
                |> Effect.withShared Shared.connectToMasto


view : Model -> View Msg
view model =
    { title = "Home"
    , body =
        div []
            [ case Shared.identity model.shared of
                Just identity ->
                    text <| "Welcome Home " ++ identity ++ "!"

                Nothing ->
                    text "Welcome Home!"
            , div [] [ a [ href "/counter" ] [ text "See counter" ] ]
            , div [] [ a [ href "/time" ] [ text "See time" ] ]
            , div [] [ a [ href "/oauth" ] [ text "See oauth" ] ]
            , myButton "Connect to Masto" ConnectMastodon
            , div []
                [ case model.shared.appDatas of
                    Just appDatas ->
                        if List.length appDatas == 0 then
                            text "Empty app datas"

                        else
                            div []
                                (List.map
                                    (\{ appData } ->
                                        div []
                                            [ text ("Id: " ++ appData.clientId ++ ", secret: " ++ appData.clientSecret ++ ", redirect: " ++ Maybe.withDefault "" appData.redirectUri)
                                            , br [] []
                                            , a [ href <| Maybe.withDefault "" appData.url ] [ text "link to mamot" ]
                                            ]
                                    )
                                    appDatas
                                )

                    Nothing ->
                        text "No app datas"
                ]
            ]
    }


myButton : String -> Msg -> Html Msg
myButton label msg =
    button
        [ onClick msg
        , style "margin" "10px"
        ]
        [ text label ]
