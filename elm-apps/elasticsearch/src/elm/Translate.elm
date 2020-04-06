module Translate exposing
    ( StringIdHttpError(..)
    , TranslationId(..)
    , getLanguageCode
    , translate
    , translateText
    )

import App.Types exposing (Language(..))
import Html exposing (Html, text)


type alias TranslationSet =
    { english : String
    }


type StringIdHttpError
    = ErrorBadUrl
    | ErrorBadPayload String
    | ErrorBadStatus String
    | ErrorNetworkError
    | ErrorTimeout


type TranslationId
    = HttpError StringIdHttpError


translateText : Language -> TranslationId -> Html msg
translateText lang trans =
    text <| translate lang trans


translate : Language -> TranslationId -> String
translate language trans =
    let
        translationSet =
            case trans of
                HttpError val ->
                    translateHttpError val

        translateOrFallbackEnglish str =
            if String.isEmpty str then
                .english translationSet

            else
                str
    in
    case language of
        English ->
            .english translationSet


translateHttpError : StringIdHttpError -> TranslationSet
translateHttpError transId =
    case transId of
        ErrorBadUrl ->
            { english = "URL is not valid."
            }

        ErrorBadPayload message ->
            { english = "The server responded with data of an unexpected type: " ++ message
            }

        ErrorBadStatus err ->
            { english = err
            }

        ErrorNetworkError ->
            { english = "There was a network error."
            }

        ErrorTimeout ->
            { english = "The network request timed out."
            }


getLanguageCode : Language -> String
getLanguageCode language =
    case language of
        English ->
            "en"
