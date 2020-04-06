module Backend.Utils exposing
    ( dictInsertAfter
    , updateSubModel
    )

import AssocList as Dict exposing (Dict)
import List.Extra


{-| Wire sub Entities to the Backend.
-}
updateSubModel subMsg updateFunc msg model =
    let
        backendReturn =
            updateFunc subMsg model
    in
    { model = backendReturn.model
    , cmd = Cmd.map msg backendReturn.cmd
    , error = backendReturn.error
    , appMsgs = backendReturn.appMsgs
    }


{-| Insert Items after a certain key.
-}
dictInsertAfter previousItemLastId itemId item dict =
    let
        dictKeys =
            dict
                |> Dict.keys

        index =
            dictKeys
                |> List.Extra.elemIndex previousItemLastId
                -- Default to the last item, so we'd get ([1, 2, 3], [])
                |> Maybe.withDefault (List.length dictKeys)

        ( beforeList, afterList ) =
            dict
                |> Dict.toList
                |> List.Extra.splitAt (index + 1)
    in
    beforeList
        |> List.append (( itemId, item ) :: afterList)
        |> Dict.fromList
