module GLua.TokenTypes where

import Data.List

data Token =
    -- Comments and whitespace
    Whitespace String           |
    DashComment String          |
    DashBlockComment Int String | -- where the Int is the depth of the comment delimiter
    SlashComment String         |
    SlashBlockComment String    |
    Semicolon                   |   -- ;

    -- Constants
    TNumber String              |
    DQString String             |   -- Double quote string
    SQString String             |   -- Single quote string
    MLString String             |   -- Multiline string
    TTrue                       |
    TFalse                      |
    Nil                         |
    VarArg                      |   -- ...

    -- Operators
    Plus                        |   -- +
    Minus                       |   -- -
    Mulitply                    |   -- *
    Divide                      |   -- /
    Modulus                     |   -- %
    Power                       |   -- ^
    TEq                         |   -- ==
    TNEq                        |   -- ~=
    TCNEq                       |   -- !=
    TLEQ                        |   -- <=
    TGEQ                        |   -- >=
    TLT                         |   -- <
    TGT                         |   -- >
    Equals                      |   -- =
    Concatenate                 |   -- ..
    Colon                       |   -- :
    Dot                         |   -- .
    Comma                       |   -- ,
    Hash                        |   -- #
    Not                         |
    CNot                        |   -- !
    And                         |
    CAnd                        |
    Or                          |
    COr                         |

    -- Keywords
    Function                    |
    Local                       |
    If                          |
    Then                        |
    Elseif                      |
    Else                        |
    For                         |
    In                          |
    Do                          |
    While                       |
    Until                       |
    Repeat                      |
    Continue                    |
    Break                       |
    Return                      |
    End                         |
    Goto                        |

    LRound                      |   -- (
    RRound                      |   -- )
    LCurly                      |   -- {
    RCurly                      |   -- }
    LSquare                     |   -- [
    RSquare                     |   -- ]
    Label String                |   -- ::
    Identifier String
    deriving (Eq)

-- Describes a position in a file (line number and column)
data TokenPos = TPos { line :: Int, column :: Int }
instance Show TokenPos where
    show (TPos l c) = '(' : show l ++ ':' : show c ++ ")"

addLines :: Int -> TokenPos -> TokenPos
addLines n (TPos l c) = TPos (l + n) 0

addColumns :: Int -> TokenPos -> TokenPos
addColumns n (TPos l c) = TPos l (c + n)

-- Add the size of a token to a position
addToken :: Token -> TokenPos -> TokenPos
addToken t p@(TPos l c) = if lineCount == 0 then addColumns size p else TPos (l + lineCount) columns
    where
        strTok = show t
        lineCount = length . filter (== '\n') $ strTok
        size = tokenSize t
        columns = size - (last . elemIndices '\n' $ strTok)

-- Metatoken, stores line and column position of token
data MToken = MToken TokenPos Token deriving (Show)

-- Generate metatokens from a list of tokens
-- it does this by assuming the first token starts at position 1 1
makeMTokens :: [Token] -> [MToken]
makeMTokens = build (TPos 1 1)
    where
        build pos (t:ts) = MToken pos t : build (addToken t pos) ts
        build pos [] = []

type TokenAlgebra token = (
    ( -- Comments and whitespace
        String -> token,    -- Whitespace
        String -> token,    -- DashComment
        Int -> String -> token,    -- DashBlockComment
        String -> token,    -- SlashComment
        String -> token,    -- SlashBlockComment
        token               -- Semicolon
    ),
    ( -- Constants
        String -> token,    -- TNumber
        String -> token,    -- DQString
        String -> token,    -- SQString
        String -> token,    -- MLString
        token,              -- TTrue
        token,              -- TFalse
        token,              -- Nil
        token               -- VarArg
    ), -- operators
    (
        token,              -- Plus
        token,              -- Minus
        token,              -- Mulitply
        token,              -- Divide
        token,              -- Modulus
        token,              -- Power
        token,              -- TEq
        token,              -- TNEq
        token,              -- TCNEq
        token,              -- TLEQ
        token,              -- TGEQ
        token,              -- TLT
        token,              -- TGT
        token,              -- Equals
        token,              -- Concatenate
        token,              -- Colon
        token,              -- Dot
        token,              -- Comma
        token,              -- Hash
        token,              -- Not
        token,              -- CNot
        token,              -- And
        token,              -- CAnd
        token,              -- Or
        token               -- COr
    ),
    ( -- Keywords
        token,              -- Function
        token,              -- Local
        token,              -- If
        token,              -- Then
        token,              -- Elseif
        token,              -- Else
        token,              -- For
        token,              -- In
        token,              -- Do
        token,              -- While
        token,              -- Until
        token,              -- Repeat
        token,              -- Continue
        token,              -- Break
        token,              -- Return
        token,              -- End
        token               -- Goto
    ),
    ( -- Brackets
        token,              -- LRound
        token,              -- RRound
        token,              -- LCurly
        token,              -- RCurly
        token,              -- LSquare
        token               -- RSquare
    ),
    ( -- Other
        String -> token,    -- Label
        String -> token     -- Identifier
    )
    )

foldToken :: TokenAlgebra t -> Token -> t
foldToken ((tWhitespace, tDashComment, tDashBlockComment, tSlashComment, tSlashBlockComment, tSemicolon), (tTNumber, tDQString, tSQString, tMLString, tTTrue, tTFalse, tNil, tVarArg), (tPlus, tMinus, tMulitply, tDivide, tModulus, tPower, tTEq, tTNEq, tTCNEq, tTLEQ, tTGEQ, tTLT, tTGT, tEquals, tConcatenate, tColon, tDot, tComma, tHash, tNot, tCNot, tAnd, tCAnd, tOr, tCOr), (tFunction, tLocal, tIf, tThen, tElseif, tElse, tFor, tIn, tDo, tWhile, tUntil, tRepeat, tContinue, tBreak, tReturn, tEnd, tGoto), (tLRound, tRRound, tLCurly, tRCurly, tLSquare, tRSquare), (tLabel, tIdentifier)) = fold
    where
        fold (Whitespace str) = tWhitespace str
        fold (DashComment str) = tDashComment str
        fold (DashBlockComment depth str) = tDashBlockComment depth str
        fold (SlashComment str) = tSlashComment str
        fold (SlashBlockComment str) = tSlashBlockComment str
        fold (TNumber str) = tTNumber str
        fold (Label str) = tLabel str
        fold (Identifier str) = tIdentifier str
        fold (DQString str) = tDQString str
        fold (SQString str) = tSQString str
        fold (MLString str) = tMLString str
        fold And = tAnd
        fold CAnd = tCAnd
        fold Break = tBreak
        fold Do = tDo
        fold Else = tElse
        fold Elseif = tElseif
        fold End = tEnd
        fold TFalse = tTFalse
        fold For = tFor
        fold Function = tFunction
        fold Goto = tGoto
        fold If = tIf
        fold In = tIn
        fold Local = tLocal
        fold Nil = tNil
        fold Not = tNot
        fold CNot = tCNot
        fold Or = tOr
        fold COr = tCOr
        fold Repeat = tRepeat
        fold Continue = tContinue
        fold Return = tReturn
        fold Then = tThen
        fold TTrue = tTTrue
        fold Until = tUntil
        fold While = tWhile
        fold Plus = tPlus
        fold Minus = tMinus
        fold Mulitply = tMulitply
        fold Divide = tDivide
        fold Modulus = tModulus
        fold Power = tPower
        fold Hash = tHash
        fold TEq = tTEq
        fold TNEq = tTNEq
        fold TCNEq = tTCNEq
        fold TLEQ = tTLEQ
        fold TGEQ = tTGEQ
        fold TLT = tTLT
        fold TGT = tTGT
        fold Equals = tEquals
        fold LRound = tLRound
        fold RRound = tRRound
        fold LCurly = tLCurly
        fold RCurly = tRCurly
        fold LSquare = tLSquare
        fold RSquare = tRSquare
        fold Semicolon = tSemicolon
        fold Colon = tColon
        fold Comma = tComma
        fold Dot = tDot
        fold Concatenate = tConcatenate
        fold VarArg = tVarArg

instance Show Token where
    show = foldToken ((
        id, -- Whitespace
        \s -> "--" ++ s, -- DashComment
        \d s -> let n = replicate d '=' in "--[" ++ n ++ '[' : s ++ ']' : n ++ "]", -- DashBlockComment
        \s -> "//" ++ s, -- SlashComment
        \s -> "/*" ++ s ++ "*/", -- SlashBlockComment
        ";" -- Semicolon
        ),
        (
        id, -- TNumber
        \s -> "\"" ++ s ++ "\"", -- DQString
        \s -> "'" ++ s ++ "'", -- SQString
        id, -- MLString
        "true", -- TTrue
        "false", -- TFalse
        "nil", -- Nil
        "..." -- VarArg
        ),
        (
        "+", -- Plus
        "-", -- Minus
        "*", -- Mulitply
        "/", -- Divide
        "%", -- Modulus
        "^", -- Power
        "==", -- TEq
        "~=", -- TNEq
        "!=", -- TCNEq
        "<=", -- TLEQ
        ">=", -- TGEQ
        "<", -- TLT
        ">", -- TGT
        "=", -- Equals
        "..", -- Concatenate
        ":", -- Colon
        ".", -- Dot
        ",", -- Comma
        "#", -- Hash
        "not", -- Not
        "!", -- CNot
        "and", -- And
        "&&", -- CAnd
        "or", -- Or
        "||" -- COr
        ),
        (
        "function", -- Function
        "local", -- Local
        "if", -- If
        "then", -- Then
        "elseif", -- Elseif
        "else", -- Else
        "for", -- For
        "in", -- In
        "do", -- Do
        "while", -- While
        "until", -- Until
        "repeat", -- Repeat
        "continue", -- Continue
        "break", -- Break
        "return", -- Return
        "end", -- End
        "goto" -- Goto
        ),
        (
        "(", -- LRound
        ")", -- RRound
        "{", -- LCurly
        "}", -- RCurly
        "[", -- LSquare
        "]" -- RSquare
        ),
        (
        \s -> "::" ++ s, -- Label
        id -- Identifier
        )
        )

-- Whether a token is whitespace
isWhitespace :: Token -> Bool
isWhitespace = foldToken ((const True,const False,\d s -> False,const False,const False,False),( const False,const False,const False,const False,False,False,False,False),(False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False),(False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False),(False,False,False,False,False,False),(const False,const False))

-- the size of a token in characters
tokenSize = foldToken ((
    length, -- Whitespace
    (+2) . length, -- DashComment
    \d s -> 6 + length s + 2 * d, -- DashBlockComment
    (+2) . length, -- SlashComment
    (+4) . length, -- SlashBlockComment
    1 -- Semicolon
    ),
    (
    length, -- TNumber
    (+2) . length, -- DQString
    (+2) . length, -- SQString
    length, -- MLString
    4, -- TTrue
    5, -- TFalse
    3, -- Nil
    3 -- VarArg
    ),
    (
    1, -- Plus
    1, -- Minus
    1, -- Mulitply
    1, -- Divide
    1, -- Modulus
    1, -- Power
    2, -- TEq
    2, -- TNEq
    2, -- TCNEq
    2, -- TLEQ
    2, -- TGEQ
    1, -- TLT
    1, -- TGT
    1, -- Equals
    2, -- Concatenate
    1, -- Colon
    1, -- Dot
    1, -- Comma
    1, -- Hash
    3, -- Not
    1, -- CNot
    3, -- And
    2, -- CAnd
    2, -- Or
    2 -- COr
    ),
    (
    8, -- Function
    5, -- Local
    2, -- If
    4, -- Then
    6, -- Elseif
    4, -- Else
    3, -- For
    2, -- In
    2, -- Do
    5, -- While
    5, -- Until
    6, -- Repeat
    8, -- Continue
    5, -- Break
    6, -- Return
    3, -- End
    4 -- Goto
    ),
    (
    1, -- LRound
    1, -- RRound
    1, -- LCurly
    1, -- RCurly
    1, -- LSquare
    1 -- RSquare
    ),
    (
    (+2) . length, -- Label
    length -- Identifier
    )
    )