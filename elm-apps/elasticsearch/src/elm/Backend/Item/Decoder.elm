module Backend.Item.Decoder exposing (decodeItem, decodeItemsDictAndCount)

import AssocList as Dict
import Backend.Item.Model exposing (Item, ItemDict)
import Json.Decode exposing (Decoder, andThen, int, list, string, succeed)
import Json.Decode.Pipeline exposing (required, requiredAt)
import Restful.Endpoint exposing (EntityId, decodeEntityId, decodeEntityUuid, toEntityId)


decodeItem : Decoder Item
decodeItem =
    succeed Item
        |> required "_id" decodeEntityIdFromString
        |> requiredAt [ "_source", "title", "0" ] string


{-| Get the entity ID, from string such as "entity:node/101:en". We want to
get hold of the 101, as Int.
-}
decodeEntityIdFromString : Decoder (EntityId a)
decodeEntityIdFromString =
    string
        |> andThen
            (\str ->
                str
                    |> String.replace "entity:node/" ""
                    |> String.replace ":en" ""
                    |> String.toInt
                    |> Maybe.withDefault 0
                    |> toEntityId
                    |> succeed
            )


decodeItemsDictAndCount : Decoder ( ItemDict, Int )
decodeItemsDictAndCount =
    succeed (\a b -> ( a, b ))
        |> requiredAt [ "hits", "hits" ]
            (list decodeItem
                |> andThen
                    (\list_ ->
                        list_
                            |> List.foldl (\val accum -> Dict.insert val.id val accum) Dict.empty
                            |> succeed
                    )
            )
        |> requiredAt [ "hits", "total", "value" ] int
