module Backend.Item.Model exposing
    ( Item
    , ItemDict
    , ItemsDict
    , Msg(..)
    )

import AssocList exposing (Dict)
import Backend.Entities exposing (ItemId, ItemUuid)
import Editable.WebData exposing (EditableWebData)
import PaginatedData exposing (ContainerDict)
import RemoteData exposing (WebData)


type alias Item =
    { id : ItemId
    , label : String
    }


type alias ItemDict =
    Dict ItemId Item


{-| @todo: In the future, instead of `()` we would key by the "terms" (a.k.a
facets).
-}
type alias ItemsDict =
    ContainerDict () ItemId Item


type alias PageNumber =
    Int


type alias TotalCount =
    Int


type Msg
    = Fetch PageNumber
    | HandleFetch PageNumber (WebData ( ItemDict, Int ))
