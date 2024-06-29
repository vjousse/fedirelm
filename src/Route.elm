module Route exposing (Route(..), matchCounter, matchHome, matchOAuth, matchSignIn, matchTime, toRoute, toUrl)

import Url exposing (Url)
import Url.Builder as Builder
import Url.Parser exposing ((</>), (<?>), Parser, map, oneOf, parse, s, top)
import Url.Parser.Query as Query


type Route
    = Home
    | Counter Int
    | OAuthRedirect (Maybe String) (Maybe String)
    | SignIn (Maybe String)
    | Time
    | NotFound Url


route : Parser (Route -> a) a
route =
    oneOf
        [ map Home top
        , map SignIn <| s "sign-in" <?> Query.string "redirect"
        , map Counter <| s "counter" <?> (Query.int "value" |> Query.map (Maybe.withDefault 0))
        , map Time <| s "time"
        , map OAuthRedirect <| s "oauth" <?> Query.string "clientId" <?> Query.string "code"
        ]


toRoute : Url -> Route
toRoute url =
    url
        |> parse route
        |> Maybe.withDefault (NotFound url)


toUrl : Route -> String
toUrl r =
    case r of
        Home ->
            "/"

        SignIn redirect ->
            Builder.absolute [ "sign-in" ]
                (redirect
                    |> Maybe.map (Builder.string "redirect" >> List.singleton)
                    |> Maybe.withDefault []
                )

        Counter value ->
            "/counter?value=" ++ String.fromInt value

        Time ->
            "/time"

        OAuthRedirect clientId code ->
            Builder.absolute [ "oauth" ]
                ((clientId
                    |> Maybe.map (Builder.string "clientId" >> List.singleton)
                    |> Maybe.withDefault []
                 )
                    ++ (code
                            |> Maybe.map (Builder.string "code" >> List.singleton)
                            |> Maybe.withDefault []
                       )
                )

        NotFound url ->
            Url.toString url


matchAny : Route -> Route -> Maybe ()
matchAny any r =
    if any == r then
        Just ()

    else
        Nothing


matchHome : Route -> Maybe ()
matchHome =
    matchAny Home


matchSignIn : Route -> Maybe (Maybe String)
matchSignIn r =
    case r of
        SignIn redirect ->
            Just redirect

        _ ->
            Nothing


matchOAuth : Route -> Maybe ( Maybe String, Maybe String )
matchOAuth r =
    case r of
        OAuthRedirect code clientId ->
            Just ( code, clientId )

        _ ->
            Nothing


matchCounter : Route -> Maybe Int
matchCounter r =
    case r of
        Counter value ->
            Just value

        _ ->
            Nothing


matchTime : Route -> Maybe ()
matchTime =
    matchAny Time
