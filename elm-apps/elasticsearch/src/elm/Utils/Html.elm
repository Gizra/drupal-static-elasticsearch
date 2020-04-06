module Utils.Html exposing
    ( AlertType(..)
    , alert
    , emptyNode
    , helpText
    , onBlurWithTargetValue
    , onEnterKeydown
    , onEnterKeydownPreventDefault
    , orSpinnerIfLoading
    , showIf
    , showMaybe
    , spinner
    )

import Html exposing (Attribute, Html, div, i, text)
import Html.Attributes exposing (class, classList, href)
import Html.Events exposing (keyCode, on, preventDefaultOn, targetValue)
import Json.Decode as Json
import RemoteData exposing (RemoteData)


type AlertType
    = Danger
    | Info
    | Success
    | Warning


alert : AlertType -> String -> Html msg
alert alertType string =
    div
        [ classList
            [ ( "alert", True )
            , ( "alert-danger", alertType == Danger )
            , ( "alert-info", alertType == Info )
            , ( "alert-success", alertType == Success )
            , ( "alert-warning", alertType == Warning )
            ]
        ]
        [ text <| string ]


helpText : String -> Html msg
helpText string =
    div [ class "help-inline" ] [ text <| string ]


spinner : Html msg
spinner =
    i [ class "fa fa-spinner fa-spin" ] []


orSpinnerIfLoading : RemoteData e a -> List (Html msg) -> List (Html msg)
orSpinnerIfLoading webData content =
    case webData of
        RemoteData.Loading ->
            [ spinner ]

        _ ->
            content


{-| Helper Html.Event which pass the target value of the input during "blur".
-}
onBlurWithTargetValue : (String -> msg) -> Attribute msg
onBlurWithTargetValue tagger =
    on "blur" (Json.map tagger targetValue)


onEnterKeydown : msg -> Attribute msg
onEnterKeydown msg =
    on "keydown" <| keydownDecoder enterKeycode msg


onEnterKeydownPreventDefault : msg -> Attribute msg
onEnterKeydownPreventDefault msg =
    preventDefaultOn "keydown" (Json.map alwaysPreventDefault (keydownDecoder enterKeycode msg))


alwaysPreventDefault : msg -> ( msg, Bool )
alwaysPreventDefault msg =
    ( msg, True )


keydownDecoder : Int -> msg -> Json.Decoder msg
keydownDecoder keyCodeValue msg =
    keyCode
        |> Json.andThen
            (\c ->
                if c == keyCodeValue then
                    Json.succeed msg

                else
                    Json.fail "Default handler"
            )


enterKeycode : Int
enterKeycode =
    13


emptyNode : Html msg
emptyNode =
    text ""


{-| Conditionally show Html. A bit cleaner than using if expressions in middle
of an html block:
text "I'm shown"
|> showIf True
text "I'm not shown"
|> showIf False
-}
showIf : Bool -> Html msg -> Html msg
showIf condition html =
    if condition then
        html

    else
        emptyNode


{-| Show Maybe Html if Just, or empty node if Nothing.
-}
showMaybe : Maybe (Html msg) -> Html msg
showMaybe =
    Maybe.withDefault emptyNode
