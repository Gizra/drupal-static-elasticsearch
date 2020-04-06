module Pages.Search.Fetch exposing (fetch)

import AssocList as Dict exposing (Dict)
import Backend.Item.Model
import Backend.Model
import Pages.Search.Model exposing (Model)
import PaginatedData
import Time


fetch : String -> Backend.Model.ModelBackend -> Model -> List Backend.Model.Msg
fetch searchUrl modelBackend model =
    let
        itemsPager =
            PaginatedData.fetchPaginated
                ( (), modelBackend.items )
                ( (), model.page )
                (\pageNumber ->
                    Backend.Item.Model.Fetch pageNumber
                        |> Backend.Model.MsgItem
                )
    in
    itemsPager
        |> List.filterMap identity
