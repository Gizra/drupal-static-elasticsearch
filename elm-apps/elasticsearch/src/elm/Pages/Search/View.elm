module Pages.Search.View exposing (view)

import App.Types exposing (Language(..))
import AssocList as Dict exposing (Dict)
import Backend.Entities exposing (ItemId)
import Backend.Item.Model exposing (Item, ItemDict)
import Backend.Model exposing (ModelBackend)
import Html exposing (..)
import Html.Attributes exposing (action, class, classList, href)
import Html.Events exposing (onClick)
import Pages.Search.Model exposing (Model, Msg(..))
import PaginatedData
import RemoteData exposing (RemoteData(..))
import Restful.Endpoint exposing (fromEntityId)
import Utils.Html exposing (emptyNode)


view : Language -> ModelBackend -> Model -> Html Msg
view language modelBackend model =
    let
        existing =
            Dict.get () modelBackend.items
                |> Maybe.withDefault RemoteData.NotAsked
    in
    case existing of
        Success dataAndPager ->
            div []
                [ viewItems language modelBackend dataAndPager model
                , nav [ class "pager" ]
                    [ viewPager () dataAndPager model.page (\pageNumber -> SetPagerPage pageNumber)
                    ]
                ]

        _ ->
            emptyNode


viewItems :
    Language
    -> ModelBackend
    -> PaginatedData.PaginatedData ItemId Item
    ->
        { r
            | page : Dict () Int
        }
    -> Html Msg
viewItems language modelBackend dataAndPager model =
    let
        currentPage =
            Dict.get () model.page
                |> Maybe.withDefault 1

        pagerInfo =
            Dict.get currentPage dataAndPager.pager
                |> Maybe.withDefault RemoteData.NotAsked
    in
    div []
        [ if RemoteData.isLoading pagerInfo then
            div [] [ text "Loading..." ]

          else if Dict.isEmpty dataAndPager.data then
            div [] [ text <| "No items found." ]

          else
            ul []
                (PaginatedData.getItemsByPager () dataAndPager model.page
                    |> Dict.toList
                    |> List.map
                        (\( itemId, item ) ->
                            li []
                                [ a [ href <| "/node/" ++ String.fromInt (fromEntityId itemId) ++ "/" ] [ text item.label ]
                                ]
                        )
                )
        ]


{-| View helper.

We don't use PagindatedData.viewPager, as we want our classes.
@todo: Extend PagindatedData.

-}
viewPager :
    identifier
    -> { dataAndPager | pager : Dict Int v }
    -> Dict identifier Int
    -> (Int -> msg)
    -> Html msg
viewPager identifier { pager } pageProperty func =
    if Dict.size pager <= 1 then
        text ""

    else
        let
            currentPage =
                Dict.get identifier pageProperty
                    |> Maybe.withDefault 1
        in
        -- @todo :Allow adding own attributes to ul/ li
        ul [ class "pagination pager__items" ]
            (pager
                |> Dict.keys
                |> List.sort
                |> List.map
                    (\pageNumber ->
                        let
                            aAttr =
                                if pageNumber == currentPage then
                                    [ action "javascript:void(0);" ]

                                else
                                    [ onClick <| func pageNumber ]
                        in
                        li
                            [ classList
                                [ ( "is-active", pageNumber == currentPage )
                                , ( "pager__item with-bg", True )
                                ]
                            ]
                            [ a aAttr [ text <| String.fromInt pageNumber ]
                            ]
                    )
            )
