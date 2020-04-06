module App.Update exposing
    ( init
    , subscriptions
    , update
    )

import App.Fetch exposing (fetch)
import App.Model exposing (..)
import App.Utils exposing (updateSubModel)
import Backend.Update
import Pages.Search.Update
import Task
import Time


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        modelUpdated =
            { emptyModel | searchUrl = flags.searchUrl }

        cmds =
            fetch modelUpdated
                |> List.map
                    (\msg ->
                        Task.succeed msg
                            |> Task.perform identity
                    )
                |> List.append
                    [ Task.perform SetCurrentDate Time.now
                    ]
                |> Cmd.batch
    in
    ( modelUpdated
      -- Let the Fetcher act upon the active page.
    , cmds
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MsgBackend subMsg ->
            updateSubModel
                subMsg
                model.backend
                (\subMsg_ subModel -> Backend.Update.updateBackend model.currentDate model.searchUrl subMsg_ subModel)
                (\subModel model_ -> { model_ | backend = subModel })
                (\subCmds -> MsgBackend subCmds)
                model

        MsgPageSearch subMsg ->
            updateSubModel
                subMsg
                model.pageSearch
                (\subMsg_ subModel -> Pages.Search.Update.update subMsg_ subModel)
                (\subModel model_ -> { model_ | pageSearch = subModel })
                (\subCmds -> MsgPageSearch subCmds)
                model

        NoOp ->
            ( model, Cmd.none )

        SetActivePage activePage ->
            ( { model | activePage = activePage }
            , Cmd.none
            )

        SetCurrentDate date ->
            ( { model | currentDate = date }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
