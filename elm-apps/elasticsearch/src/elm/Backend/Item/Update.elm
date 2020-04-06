module Backend.Item.Update exposing (update)

import AssocList as Dict exposing (Dict)
import Backend.Item.Decoder exposing (decodeItemsDictAndCount)
import Backend.Item.Model exposing (Msg(..))
import Backend.Model exposing (ModelBackend)
import Backend.Types exposing (BackendReturn)
import Backend.Utils exposing (dictInsertAfter)
import Error.Utils exposing (maybeHttpError, noError)
import HttpBuilder exposing (withExpectJson, withQueryParams, withStringBody)
import PaginatedData
import RemoteData exposing (RemoteData(..))
import Restful.Endpoint exposing (toEntityId)


update : String -> Msg -> ModelBackend -> BackendReturn Msg
update searchUrl msg model =
    let
        noChange =
            BackendReturn model Cmd.none noError []
    in
    case msg of
        Fetch pageNumber ->
            let
                existingFetched =
                    Dict.get () model.items
                        |> Maybe.withDefault RemoteData.Loading

                updatedFetched =
                    Dict.insert () existingFetched model.items

                modelSetLoading modelFunc =
                    modelFunc model updatedFetched

                modelUpdated =
                    modelSetLoading (\model_ dict -> { model_ | items = PaginatedData.setPageAsLoading () pageNumber dict })

                queryString =
                    """
{
    "query": {
        "term": {
            "type": {
                "value": "article"
            }
        }
    }
}
                    """

                -- We get 10 items back from ES, so we will set the offset by.
                queryParams =
                    [ ( "from", String.fromInt ((pageNumber - 1) * 10) ) ]

                cmd =
                    HttpBuilder.post (searchUrl ++ "/_search")
                        |> withStringBody "application/json" queryString
                        |> withQueryParams queryParams
                        |> withExpectJson decodeItemsDictAndCount
                        |> HttpBuilder.send (RemoteData.fromResult >> HandleFetch pageNumber)
            in
            BackendReturn
                modelUpdated
                cmd
                noError
                []

        HandleFetch pageNumber webData ->
            let
                updated =
                    PaginatedData.insertMultiple
                        ()
                        pageNumber
                        webData
                        toEntityId
                        (\( itemId, _ ) -> Just itemId)
                        -- Insert first.
                        (\itemId item accum -> Dict.insert itemId item accum)
                        -- Insert after.
                        (\itemId item ( previousItemLastId, accum ) -> ( previousItemLastId, dictInsertAfter previousItemLastId itemId item accum ))
                        model.items
            in
            BackendReturn
                { model | items = updated }
                Cmd.none
                (maybeHttpError webData "Backend.Update" "HandleFetchItems")
                []
