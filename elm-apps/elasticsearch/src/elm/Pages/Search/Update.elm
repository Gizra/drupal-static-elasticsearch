module Pages.Search.Update exposing (update)

import App.Model exposing (PagesReturn)
import AssocList as Dict
import Backend.Item.Model
import Backend.Model
import Error.Utils exposing (noError)
import Pages.Search.Model exposing (Model, Msg(..))


update : Msg -> Model -> PagesReturn Model Msg
update msg model =
    let
        noChange =
            PagesReturn
                model
                Cmd.none
                noError
                []
    in
    case msg of
        Fetch ->
            let
                pageNumber =
                    Dict.get () model.page
                        |> Maybe.withDefault 1
            in
            PagesReturn model
                Cmd.none
                noError
                [ Backend.Item.Model.Fetch pageNumber
                    |> Backend.Model.MsgItem
                    |> App.Model.MsgBackend
                ]

        SetPagerPage pageNumber ->
            PagesReturn
                { model | page = Dict.insert () pageNumber model.page }
                Cmd.none
                noError
                [ Backend.Item.Model.Fetch pageNumber
                    |> Backend.Model.MsgItem
                    |> App.Model.MsgBackend
                ]
