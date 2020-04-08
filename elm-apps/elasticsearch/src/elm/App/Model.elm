module App.Model exposing
    ( Flags
    , Model
    , Msg(..)
    , PagesReturn
    , ServerCredentials
    , emptyModel
    )

import App.Types exposing (Language(..), Page(..))
import Backend.Model
import Error.Model exposing (Error)
import Pages.Search.Model
import Time


type alias PagesReturn subModel subMsg =
    { model : subModel
    , cmd : Cmd subMsg
    , error : Maybe Error
    , appMsgs : List Msg
    }


type Msg
    = MsgBackend Backend.Model.Msg
    | MsgPageSearch Pages.Search.Model.Msg
    | NoOp
    | SetActivePage Page
    | SetCurrentDate Time.Posix


type alias Flags =
    { searchUrl : String
    , indexName : String
    }


type alias Model =
    { backend : Backend.Model.ModelBackend
    , errors : List Error
    , language : Language
    , activePage : Page
    , currentDate : Time.Posix
    , searchUrlAndIndexName : ( String, String )
    , pageSearch : Pages.Search.Model.Model
    }


type alias ServerCredentials =
    { url : String
    }


emptyModel : Model
emptyModel =
    { backend = Backend.Model.emptyModelBackend
    , errors = []
    , language = English
    , activePage = Search
    , currentDate = Time.millisToPosix 0
    , searchUrlAndIndexName = ( "", "" )
    , pageSearch = Pages.Search.Model.emptyModel
    }
