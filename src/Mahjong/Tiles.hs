{-# LANGUAGE OverloadedStrings #-}
------------------------------------------------------------------------------
-- | 
-- Module         : Mahjong.Tiles
-- Copyright      : (C) 2014 Samuli Thomasson
-- License        : BSD-style (see the file LICENSE)
-- Maintainer     : Samuli Thomasson <samuli.thomasson@paivola.fi>
-- Stability      : experimental
-- Portability    : non-portable
--
-- The tile type practically ripped from *hajong*.
------------------------------------------------------------------------------
module Mahjong.Tiles where

import Data.String
import Data.Monoid ((<>))
import Control.Monad
import Control.Applicative
import Text.PrettyPrint.ANSI.Leijen (Pretty(..), string)

-- * Types

-- | A (japanese) mahjong tile.
data Tile = Suited TileKind Number Aka
          | Honor Honor
          deriving (Show, Read, Eq, Ord)

data TileKind = ManTile | PinTile | SouTile | HonorTile
              deriving (Show, Read, Eq, Ord)

-- | Is akadora?
type Aka = Bool

-- | The number of man, pin and sou tiles.
data Number = Ii | Ryan | San | Suu | Wu | Rou | Chii | Paa | Chuu
            deriving (Show, Read, Eq, Ord, Enum, Bounded)

data Honor = Sangenpai Sangenpai
           | Kazehai Kazehai
           deriving (Show, Read, Eq, Ord)

data Sangenpai = Haku | Hatsu | Chun
               deriving (Show, Read, Eq, Ord, Enum, Bounded)

data Kazehai = Ton | Nan | Shaa | Pei
             deriving (Show, Read, Eq, Ord, Enum, Bounded)

-- Instances

instance IsString Tile where
    fromString [a]     = fromString [a, ' ']
    fromString [k,num] = case k of
        'G'              -> Honor (Sangenpai Hatsu)
        'R'              -> Honor (Sangenpai Chun)
        'W' | num == '!' -> Honor (Sangenpai Haku)
            | otherwise  -> Honor (Kazehai Shaa)
        'E'              -> Honor (Kazehai Ton)
        'N'              -> Honor (Kazehai Pei)
        'S' | num == ' ' -> Honor (Kazehai Nan)
            | otherwise  -> Suited SouTile (fromString [num]) False
        'M'              -> Suited ManTile (fromString [num]) False
        'P'              -> Suited PinTile (fromString [num]) False
        _                -> error "no read"
    fromString _       = error "no read"

instance Pretty Tile where
    pretty t = case t of
        Suited ManTile n aka -> (if aka then "m" else "M") <> pretty n
        Suited PinTile n aka -> (if aka then "p" else "P") <> pretty n
        Suited SouTile n aka -> (if aka then "s" else "S") <> pretty n
        Suited{} -> error "No such tile"
        Honor (Sangenpai sangen) -> case sangen of
                         Haku    -> "W!"
                         Hatsu   -> "G!"
                         Chun    -> "R!"
        Honor (Kazehai kaze) -> case kaze of
                         Ton     -> "E "
                         Nan     -> "S "
                         Shaa    -> "W "
                         Pei     -> "N "

instance IsString Number where
    fromString = toEnum . (\i -> i - 1 :: Int) . read

instance Pretty Number where
    pretty = string . show . (+ 1) . fromEnum


-- * Build

toSuited :: Number -> TileKind -> Tile
toSuited n tk = Suited tk n False

-- * Functions

(==~) :: Tile -> Tile -> Bool
Suited tk n _ ==~ Suited tk' n' _ = tk == tk' && n == n'
Honor x       ==~ Honor y         = x == y
_             ==~ _               = False

-- | Extract tile kind
tileKind :: Tile -> TileKind
tileKind (Suited k _ _) = k
tileKind (Honor _)      = HonorTile

-- | Number of suited tiles
tileNumber :: Tile -> Maybe Number
tileNumber (Suited _ n _) = Just n
tileNumber (Honor _)      = Nothing

-- | True for Man, Pin and Sou tiles; false for honors.
suited :: Tile -> Bool
suited = (/= HonorTile) . tileKind

-- | Like @succ@ and @pred@, but fail as nothing if the succession wouldn't make sense
-- (i.e the input or output would not be a (defined) suited tile).
succMay, predMay :: Tile -> Maybe Tile
succMay (Suited k n a) = Suited k (succ n) a <$ guard (n /= maxBound)
succMay _              = Nothing

predMay (Suited k n a) = Suited k (pred n) a <$ guard (n /= minBound)
predMay _              = Nothing
