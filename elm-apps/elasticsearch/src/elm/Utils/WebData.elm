module Utils.WebData exposing
    ( editableWebDataViewMaybeError
    , errorString
    , getError
    , loadingAreaWrapper
    , loadingAreaWrapperEditable
    , sendWithHandler
    , unwrap
    , viewError
    , whenNotAsked
    , whenSuccess
    )

import App.Types exposing (Language)
import Editable.WebData exposing (EditableWebData)
import Html exposing (..)
import Html.Attributes exposing (class)
import Http
import HttpBuilder exposing (..)
import Json.Decode exposing (Decoder, decodeString)
import RemoteData exposing (..)
import Translate as Trans exposing (TranslationId(..), translate)
import Utils.Html exposing (emptyNode)


{-| Provide some `Html` to view an error message for an `EditableWebData`.
-}
editableWebDataViewMaybeError : Language -> EditableWebData a -> Html msg
editableWebDataViewMaybeError language editable =
    case Editable.WebData.toWebData editable of
        Failure error ->
            viewError language error

        _ ->
            emptyNode


{-| Get Error message as `String`.
-}
errorString : Language -> Http.Error -> String
errorString language error =
    case error of
        Http.BadUrl message ->
            translate language <| HttpError Trans.ErrorBadUrl

        Http.BadPayload message _ ->
            translate language <| HttpError <| Trans.ErrorBadPayload message

        Http.NetworkError ->
            translate language <| HttpError Trans.ErrorNetworkError

        Http.Timeout ->
            translate language <| HttpError Trans.ErrorTimeout

        Http.BadStatus response ->
            translate language <|
                HttpError <|
                    Trans.ErrorBadStatus <|
                        case decodeString decodeTitle response.body of
                            Ok err ->
                                err

                            Err _ ->
                                response.status.message


decodeTitle : Decoder String
decodeTitle =
    Json.Decode.field "title" Json.Decode.string


{-| Provide some `Html` to view an error message.
-}
viewError : Language -> Http.Error -> Html any
viewError language error =
    div [ class "alert alert-danger" ] [ text <| errorString language error ]


whenSuccess : RemoteData e a -> result -> (a -> result) -> result
whenSuccess remoteData default func =
    case remoteData of
        Success val ->
            func val

        _ ->
            default


sendWithHandler : Decoder a -> (Result Http.Error a -> msg) -> RequestBuilder a1 -> Cmd msg
sendWithHandler decoder tagger builder =
    builder
        |> withExpect (Http.expectJson decoder)
        |> send tagger


getError : RemoteData e a -> Maybe e
getError remoteData =
    case remoteData of
        Failure err ->
            Just err

        _ ->
            Nothing


{-| Wrap the given content with a loading area `div`, so whenever the given
data is "Loading", a spinner will be displayed in its center.
-}
loadingAreaWrapperEditable : EditableWebData a -> Html msg -> Html msg
loadingAreaWrapperEditable editable content =
    let
        isLoading =
            Editable.WebData.toWebData editable
                |> RemoteData.isLoading
    in
    loadingAreaWrapper isLoading content


{-| Wrap the given content with a loading area `div`, so whenever the given
boolean is "True", a spinner will be displayed in its center.
-}
loadingAreaWrapper : Bool -> Html msg -> Html msg
loadingAreaWrapper isLoading content =
    if isLoading then
        div
            [ class "loading-area-wrapper" ]
            [ div
                [ class "loading-area" ]
                [ div
                    [ class "spinner" ]
                    []
                ]
            , content
            ]

    else
        content


{-| Return `Just msg` if we're `NotAsked`, otherwise `Nothing`. Sort of the
opposite of `map`. We use this in order to kick off some process if we're
`NotAsked`, but not otherwise.
-}
whenNotAsked : msg -> RemoteData e a -> Maybe msg
whenNotAsked msg data =
    case data of
        NotAsked ->
            Just msg

        _ ->
            Nothing


{-| Ported from RemoteData 5.0.0 (Elm 0.19).
Take a default value, a function and a `RemoteData`.
Return the default value if the `RemoteData` is something other than `Success a`.
If the `RemoteData` is `Success a`, apply the function on `a` and return the `b`.
-}
unwrap : b -> (a -> b) -> RemoteData e a -> b
unwrap default function remoteData =
    case remoteData of
        Success data ->
            function data

        _ ->
            default
