module PaginatedData exposing
    ( ContainerDict, PaginatedData, emptyContainer, emptyPaginatedData, fetchAll, fetchPaginated, get, getAll, getItemsByPager, getPager, insertDirectlyFromClient, insertMultiple, remove, setPageAsLoading, update, viewPager
    , insertOrUpdateDirectlyFromClient
    )

{-| A `PaginatedData` represents a dict of values, that are paginated on the
server.

@docs ContainerDict, PaginatedData, emptyContainer, emptyPaginatedData, fetchAll, fetchPaginated, get, getAll, getItemsByPager, getPager, insertDirectlyFromClient, insertMultiple, remove, setPageAsLoading, update, viewPager

-}

import AssocList as Dict exposing (Dict)
import Html exposing (Html, a, li, text, ul)
import Html.Attributes exposing (action, class, classList)
import Html.Events exposing (onClick)
import List.Extra
import RemoteData exposing (WebData)


{-| A container Dict can act as a local cache.

@todo: Add docs.

-}
type alias ContainerDict identifier key value =
    Dict identifier (WebData (PaginatedData key value))


{-| We need to know how much pages we have so we could lazy load.
The pager holds the a tuple with the first and last Item key for that page, so
it's easier to insert new items in the correct place.
-}
type alias PaginatedData key value =
    { data : Dict key value
    , pager : Dict Int (WebData ( key, key ))

    -- We keep the total count, so if we are asked to `fetchAll`, we can
    -- calcualte how many pages we'll have based on the first page's result count.
    , totalCount : Int
    }


{-| Return an empty container.
-}
emptyContainer : identifier -> ContainerDict identifier key value
emptyContainer identifier =
    Dict.singleton identifier RemoteData.NotAsked


{-| Empty data, that has not been fetched yet.
-}
emptyPaginatedData : PaginatedData key value
emptyPaginatedData =
    { data = Dict.empty
    , pager = Dict.empty
    , totalCount = 0
    }


{-| Fetch helper.

@todo: Move <https://github.com/Gizra/elm-essentials/blob/4df1aba4ca15f52552e0ceca34495661826a9a4c/src/Gizra/Update.elm#L1> to own
module.

-}
fetchPaginated :
    ( a, Dict a (WebData (PaginatedData key value)) )
    -> ( b, Dict b Int )
    -> (Int -> c)
    -> List (Maybe c)
fetchPaginated ( backendIdentifier, backendDict ) ( pageIdentifier, pageDict ) func =
    let
        existingData =
            Dict.get backendIdentifier backendDict
                |> Maybe.withDefault RemoteData.NotAsked

        existingDataAndPager =
            existingData
                |> RemoteData.toMaybe
                |> Maybe.withDefault emptyPaginatedData

        currentPage =
            Dict.get pageIdentifier pageDict
                |> Maybe.withDefault 1

        currentPageData =
            Dict.get currentPage existingDataAndPager.pager
                |> Maybe.withDefault RemoteData.NotAsked

        hasNextPage =
            Dict.member (currentPage + 1) existingDataAndPager.pager

        nextPageData =
            Dict.get (currentPage + 1) existingDataAndPager.pager
                |> Maybe.withDefault RemoteData.NotAsked

        -- Prevent endless fetching in case the previous request has ended with `Failure`.
        isPreviousRequestFailed =
            Dict.get backendIdentifier backendDict
                |> Maybe.withDefault RemoteData.NotAsked
                |> RemoteData.isFailure
    in
    if not isPreviousRequestFailed then
        if RemoteData.isNotAsked currentPageData then
            [ Just <| func currentPage ]

        else if
            hasNextPage
                && RemoteData.isNotAsked nextPageData
                -- Check that we haven't already fetched all Items.
                && (Dict.size existingDataAndPager.data < existingDataAndPager.totalCount)
        then
            [ Just <| func (currentPage + 1) ]

        else
            []

    else
        []


{-| Fetch all existing pages.

Next page is fetched as the previous one arrives successfully.

-}
fetchAll :
    ( a, Dict a (WebData (PaginatedData key value)) )
    -> (Int -> c)
    -> List (Maybe c)
fetchAll ( backendIdentifier, backendDict ) func =
    let
        existingData =
            Dict.get backendIdentifier backendDict
                |> Maybe.withDefault RemoteData.NotAsked

        existingDataAndPager =
            existingData
                |> RemoteData.toMaybe
                |> Maybe.withDefault emptyPaginatedData

        -- Current page is actually the last page that had a successful
        -- response.
        currentPage =
            existingDataAndPager.pager
                |> Dict.toList
                -- Keep only success values.
                |> List.filter (\( _, webData ) -> RemoteData.isSuccess webData)
                -- Sort the list by page number, and get the highest value.
                |> List.sortBy (\( pageNumber, _ ) -> pageNumber)
                |> List.reverse
                |> List.head
                |> Maybe.andThen (\( pageNumber, _ ) -> Just pageNumber)
                |> Maybe.withDefault 1

        currentPageData =
            Dict.get currentPage existingDataAndPager.pager
                |> Maybe.withDefault RemoteData.NotAsked

        hasNextPage =
            Dict.member (currentPage + 1) existingDataAndPager.pager

        nextPageData =
            Dict.get (currentPage + 1) existingDataAndPager.pager
                |> Maybe.withDefault RemoteData.NotAsked

        -- Prevent endless fetching in case the previous request has ended with `Failure`.
        isPreviousRequestFailed =
            Dict.get backendIdentifier backendDict
                |> Maybe.withDefault RemoteData.NotAsked
                |> RemoteData.isFailure
    in
    if not isPreviousRequestFailed then
        if RemoteData.isNotAsked currentPageData then
            [ Just <| func currentPage ]

        else if hasNextPage && RemoteData.isNotAsked nextPageData then
            [ Just <| func (currentPage + 1) ]

        else
            []

    else
        []



-- CRUD


{-| Get a single value.
-}
get :
    identifier
    -> key
    -> Dict identifier (WebData (PaginatedData key value))
    -> Maybe value
get identifier key dict =
    let
        existing =
            Dict.get identifier dict
                |> Maybe.withDefault (RemoteData.Success emptyPaginatedData)

        dataAndPager =
            existing
                |> RemoteData.toMaybe
                |> Maybe.withDefault emptyPaginatedData
    in
    Dict.get key dataAndPager.data


{-| Get all values.
-}
getAll :
    identifier
    -> Dict identifier (WebData (PaginatedData key value))
    -> Dict key value
getAll identifier dict =
    let
        existing =
            Dict.get identifier dict
                |> Maybe.withDefault (RemoteData.Success emptyPaginatedData)

        dataAndPager =
            existing
                |> RemoteData.toMaybe
                |> Maybe.withDefault emptyPaginatedData
    in
    dataAndPager.data


{-| Update a single value.
-}
update :
    identifier
    -> key
    -> (value -> value)
    -> Dict identifier (WebData (PaginatedData key value))
    -> Dict identifier (WebData (PaginatedData key value))
update identifier key func dict =
    let
        existing =
            Dict.get identifier dict
                |> Maybe.withDefault (RemoteData.Success emptyPaginatedData)

        dataAndPager =
            existing
                |> RemoteData.toMaybe
                |> Maybe.withDefault emptyPaginatedData
    in
    case Dict.get key dataAndPager.data of
        Nothing ->
            dict

        Just value ->
            let
                valueUpdated =
                    func value

                dataAndPagerUpdated =
                    { dataAndPager | data = Dict.insert key valueUpdated dataAndPager.data }
            in
            Dict.insert identifier (RemoteData.Success dataAndPagerUpdated) dict


{-| Using `remove` is not advised, as it can create a situtation where the item
indicated as first or last in the `pager`, is missing from the `data`.
However, it can be used in situations where all the items are shown, without a
pager, so removing will not have an affect on the pager.
-}
remove :
    identifier
    -> key
    -> Dict identifier (WebData (PaginatedData key value))
    -> Dict identifier (WebData (PaginatedData key value))
remove identifier key dict =
    let
        existing =
            Dict.get identifier dict
                |> Maybe.withDefault (RemoteData.Success emptyPaginatedData)

        dataAndPager =
            existing
                |> RemoteData.toMaybe
                |> Maybe.withDefault emptyPaginatedData

        dataAndPagerUpdated =
            { dataAndPager | data = Dict.remove key dataAndPager.data }
    in
    Dict.insert identifier (RemoteData.Success dataAndPagerUpdated) dict


{-| Get the pager info.
-}
getPager : identifier -> Dict identifier (WebData (PaginatedData key value)) -> Dict Int (WebData ( key, key ))
getPager identifier dict =
    let
        existing =
            Dict.get identifier dict
                |> Maybe.withDefault (RemoteData.Success emptyPaginatedData)

        existingDataAndPager =
            existing
                |> RemoteData.toMaybe
                |> Maybe.withDefault emptyPaginatedData
    in
    existingDataAndPager.pager


{-| Used to indicate we're loading a page for the first time.
-}
setPageAsLoading :
    identifier
    -> Int
    -> Dict identifier (WebData (PaginatedData key value))
    -> Dict identifier (WebData (PaginatedData key value))
setPageAsLoading identifier pageNumber dict =
    let
        existing =
            Dict.get identifier dict
                |> Maybe.withDefault (RemoteData.Success emptyPaginatedData)

        existingDataAndPager =
            existing
                |> RemoteData.toMaybe
                |> Maybe.withDefault emptyPaginatedData

        pagerUpdated =
            Dict.insert pageNumber RemoteData.Loading existingDataAndPager.pager

        existingDataAndPagerUpdated =
            { existingDataAndPager | pager = pagerUpdated }
    in
    Dict.insert identifier (RemoteData.Success existingDataAndPagerUpdated) dict


{-| Insert multiple Items into the data and pager dict.
-}
insertMultiple :
    identifier
    -> Int
    -> RemoteData.RemoteData e ( Dict k v, Int )
    -> (number -> a1)
    -> (( k, v ) -> Maybe a1)
    -> (k -> v -> Dict a1 value -> Dict a1 value)
    -> (k -> v -> ( a1, Dict a1 value ) -> ( a1, Dict a1 value ))
    -> Dict identifier (RemoteData.RemoteData e (PaginatedData a1 value))
    -> Dict identifier (RemoteData.RemoteData e (PaginatedData a1 value))
insertMultiple identifier pageNumber webdata defaultItemFunc getItemFunc insertFunc insertAfterFunc dict =
    let
        existing =
            Dict.get identifier dict
                |> Maybe.withDefault (RemoteData.Success emptyPaginatedData)

        existingDataAndPager =
            existing
                |> RemoteData.toMaybe
                |> Maybe.withDefault emptyPaginatedData
    in
    case webdata of
        RemoteData.Success ( items, totalCount ) ->
            let
                maybePreviousItemLastUuid =
                    if pageNumber > 1 then
                        List.foldl
                            (\index accum ->
                                let
                                    pagerInfo =
                                        Dict.get (pageNumber - 1) existingDataAndPager.pager
                                            |> Maybe.andThen RemoteData.toMaybe
                                in
                                case accum of
                                    Just val ->
                                        accum

                                    Nothing ->
                                        case pagerInfo of
                                            Nothing ->
                                                accum

                                            Just pagerInfo_ ->
                                                Just <| Tuple.second pagerInfo_
                            )
                            Nothing
                            (List.reverse <| List.range 1 (pageNumber - 1))

                    else
                        -- This is the first page, so there's nothing before it.
                        Nothing

                itemsUpdated =
                    case maybePreviousItemLastUuid of
                        Nothing ->
                            if totalCount == 0 then
                                -- No items with placed bid.
                                Dict.empty

                            else
                                -- This is the first page, we can enter by order.
                                Dict.foldl
                                    insertFunc
                                    existingDataAndPager.data
                                    items

                        Just previousItemLastUuid ->
                            -- This page is after the previous one. As we know the last
                            -- item from the previous page, we'll have to reverse to new items
                            -- so they will end up correctly.
                            -- That is, if we had these existing items key [1, 2, 3]
                            -- we know that 3 is the last item. So, if we have the new items
                            -- [4, 5, 6] we will reverse them and enter one by one
                            -- [1, 2, 3, 6]. This looks wrong, but since we keep pushing after 3
                            -- the next item will result with [1, 2, 3, 5, 6] and the process
                            -- will end as expected with [1, 2, 3, 4, 5, 6].
                            Dict.foldl
                                insertAfterFunc
                                ( previousItemLastUuid, existingDataAndPager.data )
                                (items
                                    |> Dict.toList
                                    |> List.reverse
                                    |> Dict.fromList
                                )
                                |> Tuple.second

                totalItems =
                    Dict.size items

                totalPages =
                    -- For example if we have 120 items, and we got 25 items back
                    -- it means there will be 5 pages.
                    (toFloat totalCount / toFloat totalItems)
                        |> ceiling

                -- Get the first and last item, which might be the same one, in case
                -- we have a single item.
                ( firstItem, lastItem ) =
                    ( items
                        |> Dict.toList
                        |> List.Extra.getAt 0
                        |> Maybe.andThen getItemFunc
                        |> Maybe.withDefault (defaultItemFunc 0)
                    , items
                        -- If we have 25 items, the last one will be in index 24.
                        |> Dict.toList
                        |> List.Extra.getAt (totalItems - 1)
                        |> Maybe.andThen getItemFunc
                        |> Maybe.withDefault (defaultItemFunc 0)
                    )

                pagerUpdated =
                    if totalCount == 0 then
                        -- Update the pager, so we won't continue fetching.
                        Dict.insert pageNumber (RemoteData.Success ( firstItem, lastItem )) existingDataAndPager.pager

                    else if Dict.size existingDataAndPager.pager <= 1 then
                        -- If the pager dict was not built yet, or we just have the
                        -- first page `Loading` - before we knew how many items we'll
                        -- have in total.
                        List.range 1 totalPages
                            |> List.foldl
                                (\index accum ->
                                    let
                                        value =
                                            if index == pageNumber then
                                                RemoteData.Success ( firstItem, lastItem )

                                            else
                                                RemoteData.NotAsked
                                    in
                                    Dict.insert index value accum
                                )
                                Dict.empty

                    else
                        -- Update the existing pager dict.
                        Dict.insert pageNumber (RemoteData.Success ( firstItem, lastItem )) existingDataAndPager.pager

                existingDataAndPagerUpdated =
                    { existingDataAndPager
                        | data = itemsUpdated
                        , pager = pagerUpdated
                        , totalCount = totalCount
                    }
            in
            Dict.insert identifier (RemoteData.Success existingDataAndPagerUpdated) dict

        RemoteData.Failure error ->
            Dict.insert identifier (RemoteData.Failure error) dict

        _ ->
            -- Satisfy the compiler.
            dict


{-| Insert a new value or update an existing one depending on identifier+key.
-}
insertOrUpdateDirectlyFromClient :
    identifier
    -> ( key, value )
    -> Dict identifier (WebData (PaginatedData key value))
    -> Dict identifier (WebData (PaginatedData key value))
insertOrUpdateDirectlyFromClient identifier ( key, value ) dict =
    case get identifier key dict of
        Just _ ->
            -- Value is already in dict.
            update identifier key (\_ -> value) dict

        Nothing ->
            insertDirectlyFromClient identifier ( key, value ) dict


{-| @todo: Add docs, and improve
-}
insertDirectlyFromClient :
    identifier
    -> ( key, value )
    -> Dict identifier (WebData (PaginatedData key value))
    -> Dict identifier (WebData (PaginatedData key value))
insertDirectlyFromClient identifier ( key, value ) dict =
    case get identifier key dict of
        Just _ ->
            -- Value is already in dict.
            dict

        Nothing ->
            -- Very naively just add it to the end of the last page
            -- which was Successfully fetched.
            let
                existing =
                    Dict.get identifier dict
                        |> Maybe.withDefault (RemoteData.Success emptyPaginatedData)

                existingDataAndPager =
                    existing
                        |> RemoteData.toMaybe
                        |> Maybe.withDefault emptyPaginatedData

                ( page, pager ) =
                    existingDataAndPager.pager
                        |> Dict.toList
                        |> List.filter (\( _, webData ) -> RemoteData.isSuccess webData)
                        |> List.sortBy (\( key_, _ ) -> key_)
                        |> List.reverse
                        |> List.head
                        |> Maybe.withDefault ( 1, RemoteData.NotAsked )

                pagerUpdated =
                    case pager of
                        RemoteData.NotAsked ->
                            -- First and last key are now the only page.
                            RemoteData.Success ( key, key )

                        RemoteData.Success ( start, _ ) ->
                            -- Last key is now the new key.
                            RemoteData.Success ( start, key )

                        _ ->
                            -- Satisfy the compiler.
                            pager

                existingDataAndPagerUpdated =
                    { existingDataAndPager
                        | data = Dict.insert key value existingDataAndPager.data
                        , pager = Dict.insert page pagerUpdated existingDataAndPager.pager
                        , totalCount = existingDataAndPager.totalCount + 1
                    }
            in
            Dict.insert identifier (RemoteData.Success existingDataAndPagerUpdated) dict


{-| View helper.
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
                        li [ classList [ ( "is_active", pageNumber == currentPage ), ( "pager__item", True ) ] ]
                            [ a aAttr [ text <| String.fromInt pageNumber ]
                            ]
                    )
            )


{-| Get localy Items from the dict, by their page number.
-}
getItemsByPager :
    identifier
    ->
        { dataAndPager
            | data : Dict k v
            , pager : Dict Int (WebData ( k, k ))
        }
    -> Dict identifier Int
    -> Dict k v
getItemsByPager identifier { data, pager } pageProperty =
    if
        Dict.size pager <= 1
        -- We have only a single page.
    then
        data

    else
        let
            currentPage =
                Dict.get identifier pageProperty
                    |> Maybe.withDefault 1

            pagerInfo =
                Dict.get currentPage pager
                    |> Maybe.withDefault RemoteData.NotAsked
        in
        case pagerInfo of
            RemoteData.Success ( firstItem, lastItem ) ->
                let
                    firstIndex =
                        data
                            |> Dict.toList
                            |> List.Extra.findIndex (\( key, _ ) -> key == firstItem)
                            |> Maybe.withDefault 0

                    lastIndex =
                        data
                            |> Dict.toList
                            |> List.Extra.findIndex (\( key, _ ) -> key == lastItem)
                            |> Maybe.withDefault 0
                in
                -- Rebuild the subset of items.
                List.foldl
                    (\index accum ->
                        let
                            val =
                                data
                                    |> Dict.toList
                                    |> List.Extra.getAt index
                        in
                        case val of
                            Just ( k, v ) ->
                                Dict.insert k v accum

                            Nothing ->
                                -- Satisfy the compiler.
                                accum
                    )
                    Dict.empty
                    (List.range firstIndex lastIndex)

            _ ->
                -- We have no pager info yet, so we don't know which items to return.
                Dict.empty
