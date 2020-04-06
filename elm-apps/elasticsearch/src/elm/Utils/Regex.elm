module Utils.Regex exposing (replace)

import Regex exposing (Regex)


{-| Helper function to search and replace in a string using regex.
-}
replace : String -> (Regex.Match -> String) -> String -> String
replace pattern replacer string =
    case Regex.fromString pattern of
        Nothing ->
            string

        Just regex ->
            Regex.replace regex replacer string
