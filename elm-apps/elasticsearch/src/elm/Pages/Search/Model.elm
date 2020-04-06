module Pages.Search.Model exposing
    ( Model
    , Msg(..)
    , emptyModel
    )

{-| @todo: In the future we can have "terms" (a.k.a facets) here.
-}

import AssocList as Dict exposing (Dict)


type alias Model =
    { --| Support for PaginatedData.
      page : Dict () Int
    }


emptyModel : Model
emptyModel =
    { page = Dict.empty }


type Msg
    = Fetch
    | SetPagerPage Int
