module App.View exposing (view)

import App.Model exposing (..)
import App.Types exposing (Page(..))
import Error.View
import Html exposing (..)
import Pages.Search.View


view : Model -> Html Msg
view model =
    let
        errorElement =
            Error.View.view model.language model.errors

        --        _ =
        --            Debug.log "activePage" model.activePage
    in
    case model.activePage of
        Search ->
            div []
                [ errorElement
                , Html.map MsgPageSearch <|
                    Pages.Search.View.view
                        model.language
                        model.backend
                        model.pageSearch
                ]

        _ ->
            div []
                [ text "Wrong page?"
                ]
