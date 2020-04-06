module Utils.Json exposing
    ( decodeDate
    , decodeFloat
    , decodeInt
    , first
    , maybeToDecoder
    )

import Json.Decode exposing (..)
import Json.Decode.Extra exposing (datetime)
import String
import Time


{-| Decodes date from string or from Epoch (i.e. number).
-}
decodeDate : Decoder Time.Posix
decodeDate =
    oneOf
        [ datetime
        , decodeDateFromEpoch
        ]


{-| Decodes date from Epoch (i.e. number).
-}
decodeDateFromEpoch : Decoder Time.Posix
decodeDateFromEpoch =
    map Time.millisToPosix decodeInt


decodeFloat : Decoder Float
decodeFloat =
    oneOf
        [ float
        , string
            |> map String.toFloat
            |> andThen maybeToDecoder
        ]


{-| Cast String to Int.
-}
decodeInt : Decoder Int
decodeInt =
    oneOf
        [ int
        , string
            |> map String.toInt
            |> andThen maybeToDecoder
        ]


maybeToDecoder : Maybe a -> Decoder a
maybeToDecoder res =
    case res of
        Just x ->
            Json.Decode.succeed x

        Nothing ->
            Json.Decode.fail "Cannot decode"


{-| Decode first item in list.
-}
first : Decoder a -> Decoder a
first =
    Json.Decode.at [ "0" ]
