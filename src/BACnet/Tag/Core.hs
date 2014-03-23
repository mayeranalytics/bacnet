module Tag.Core (
  isAP,
  isCS,
  lvt,
  isOpen,
  openType,
  isClose,
  closeType,
  isExtendedLength,
  tagNumber,
  Word4,
  Word3
  ) where

import Control.Exception
import Data.Word
import Data.Bits

-- | 'True' if the Class bit (the 3rd bit) is not set
isAP :: Word8 -> Bool
isAP = not . isCS

-- | 'True' if the Class bit (the 3rd bit) is set
isCS :: Word8 -> Bool
isCS = flip testBit 3

-- | The value B'111', used to mask off the 3 least significant bits
lvtMask :: Word8
lvtMask = 0x07

-- | The value B'101' (0x05)
extendedLength :: Word8
extendedLength = 0x05

-- | The value B'110' (0x0E)
openType :: Word8
openType = 0x06

-- | The value B'111' (0x0F)
closeType :: Word8
closeType = 0x07

-- | Returns the length/value/type which is the 3 least significant bits
lvt :: Word8 -> Word8
lvt = (.&. lvtMask)

-- | Returns true if the class and length/value/type bits match
clvtMatches :: Word8 -> Word8 -> Bool
clvtMatches expected = (== expected) . (.&. 0x0F)

-- | 'True' if 'isCS' and 'lvt' == 'openType'
isOpen :: Word8 -> Bool
isOpen = clvtMatches 0x0E

-- | 'True' if 'isCS' and 'lvt' == 'closeType'
isClose :: Word8 -> Bool
isClose = clvtMatches 0x0F

-- | 'True' if 'lvt' == 'extendedLength'
isExtendedLength :: Word8 -> Bool
isExtendedLength = (== 0x05) . lvt


-- | Returns the tag number valud encoded into an initial octet.
--   As one would expect it can't return the actual tag number in the
--   case of extended tag numbers since it is only given the initial octet
--   as input.
tagNumber :: Word8 -> Word8
tagNumber b | isCS b = tNum
            | otherwise = assert (tNum < 13) tNum
  where tNum = (0x0F .&.) $ shiftR b 4


class SubByte a where
  toWord8 :: a -> Word8
  fromWord8 :: Word8 -> a

newtype Word4 = Word4 Word8 deriving (Eq, Show, Ord)

instance SubByte Word4 where
  fromWord8 = Word4 . (0x0F .&.)
  toWord8 (Word4 w8) = w8

instance Num Word4 where
  (Word4 a) + (Word4 b) = fromWord8 (a + b)
  (Word4 a) - (Word4 b) = fromWord8 (a - b)
  (Word4 a) * (Word4 b) = fromWord8 (a * b)
  abs w = w
  signum 0 = 0
  signum _ = 1
  fromInteger = fromWord8 . fromInteger

instance Bounded Word4 where
  minBound = 0
  maxBound = 15

newtype Word3 = Word3 Word8 deriving (Eq, Show, Ord)

instance SubByte Word3 where
  fromWord8 = Word3 . (0x07 .&.)
  toWord8 (Word3 w8) = w8

instance Num Word3 where
  (Word3 a) + (Word3 b) = fromWord8 (a + b)
  (Word3 a) - (Word3 b) = fromWord8 (a - b)
  (Word3 a) * (Word3 b) = fromWord8 (a * b)
  abs w = w
  signum 0 = 0
  signum _ = 1
  fromInteger = fromWord8 . fromInteger

instance Bounded Word3 where
  minBound = 0
  maxBound = 7