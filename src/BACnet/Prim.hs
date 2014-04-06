module BACnet.Prim
  (
    CharacterString(..),
    OctetString(..),
    BitString,
    bitString,
    empty,
    testBit,
    Enumerated(..),
    Date(..),
    Time(..),
    ObjectIdentifier(..),
    objectIdentifier
  ) where

import Data.Word (Word8, Word16, Word32, Word)
import Data.Bits (shiftR, shiftL, (.&.), (.|.))
import qualified Data.Bits as B

newtype CharacterString = CharacterString { getString :: String }
newtype OctetString = OctetString { getOSBytes :: [Word8] }
data BitString = BitString { getUnusedBits :: Word8, getBSBytes :: [Word8] }
  deriving (Eq, Show)

empty :: BitString
empty = BitString 0 []

bitString :: Word8 -> [Word8] -> BitString
bitString n bs | n < 8 = BitString n bs
               | otherwise = error "invalid number of unused bits"

-- | The function @testBit b n@ returns true if the nth bit is set. Counting
--   starts at 0 at the left most bit of the left most byte of 'getBytes'
testBit :: BitString -> Word -> Bool
testBit (BitString unusedBits bs) = testBit' unusedBits bs

testBit' :: Word8 -> [Word8] -> Word -> Bool
testBit' _ [] _ = error "empty list of bytes"
testBit' u [b] n | n > fromIntegral (7 - u) = error "index out of bounds"
                 | otherwise   = B.testBit b (fromIntegral $ 7 - n)
testBit' u (b:bs) n | n > 7 = testBit' u bs (n - 8)
                    | otherwise = B.testBit b (fromIntegral $ 7 - n)

newtype Enumerated = Enumerated { getEnumValue :: Word } deriving (Eq, Show)

data Date = Date
  {
    getYear :: Word8,
    getMonth :: Word8,
    getDayOfMonth :: Word8,
    getDayOfWeek :: Word8
  } deriving (Show, Eq)

data Time = Time
  {
    getHour :: Word8,
    getMinute :: Word8,
    getSecond :: Word8,
    getHundredth :: Word8
  } deriving (Show, Eq)

newtype ObjectIdentifier = ObjectIdentifier { getRawValue :: Word32 }
  deriving (Show, Eq)

objectIdentifier :: Word16 -> Word32 -> ObjectIdentifier
objectIdentifier ot inum =
  ObjectIdentifier rawValue
  where rawValue = inum' + shiftL ot' 22
        inum'
          | inum > 0x3FFFFF = error "invalid instance number > 0x3FFFFF"
          | otherwise = inum
        ot'
          | ot > 0x3FF = error "invalid object type > 0x3FF"
          | otherwise = fromIntegral ot

getObjectType :: ObjectIdentifier -> Word16
getObjectType = fromIntegral . (.&. 0x3F) . flip shiftR 22 . getRawValue

getInstanceNumber :: ObjectIdentifier -> Word32
getInstanceNumber = (.&. 0x003FFFFF) . getRawValue