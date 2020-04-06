module Backend.Entities exposing
    ( ItemId
    , ItemUuid
    )

{-| -}

import Restful.Endpoint exposing (EntityId(..), EntityUuid(..))


type alias ItemId =
    EntityId ItemIdType


type ItemIdType
    = ItemIdType



-- Uuids


type alias ItemUuid =
    EntityUuid ItemUuidType


type ItemUuidType
    = ItemUuidType
