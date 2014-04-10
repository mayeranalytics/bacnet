-- | Defines a reader for reading BACnet encoded values
module BACnet.Reader
  (
    Reader,
    -- runReader,
    run,
    readNullAP,
    readBoolAP,
    readUnsignedAP,
    readSignedAP,
    readRealAP,
    readDoubleAP,
    readOctetStringAP,
    readStringAP,
    readBitStringAP,
    readEnumeratedAP,
    readDateAP,
    readTimeAP,
    readObjectIdentifierAP
  ) where

import Control.Applicative
import Control.Monad
import Data.Binary
import Data.Binary.Get
import Data.Binary.IEEE754
import Data.Int
import Data.Maybe
import BACnet.Tag
import BACnet.Reader.Core
import BACnet.Prim
import qualified BACnet.Prim as Pr
import qualified Data.ByteString.Lazy as BS
import qualified Data.ByteString.Lazy.UTF8 as UTF8

-- | Reads an application encoded null value
readNullAP :: Reader ()
readNullAP = void readNullAPTag

readNullCS :: Word8 -> Reader ()
readNullCS = void . readNullCSTag

-- | Reads an application encoded boolean value
readBoolAP :: Reader Bool
readBoolAP = boolVal <$> readBoolAPTag

-- | Reads an application encoded unsigned integral value
readUnsignedAP' :: Reader Word
readUnsignedAP' = readUnsignedAPTag >>=
                  content foldbytes

-- | Reads an application encoded unsigned integral value.
readUnsignedAP :: Reader Word32
readUnsignedAP = fromIntegral <$> readUnsignedAP'

readSignedAP' :: Reader Int
readSignedAP' = readSignedAPTag >>=
                content foldsbytes

readSignedAP :: Reader Int32
readSignedAP = fromIntegral <$> readSignedAP'

readRealAP :: Reader Float
readRealAP = runGet getFloat32be <$ readRealAPTag <*> bytestring 4

readDoubleAP :: Reader Double
readDoubleAP = runGet getFloat64be <$ readDoubleAPTag <*> bytestring 8

readOctetStringAP :: Reader [Word8]
readOctetStringAP =
  do
    t <- readOctetStringAPTag
    bs <- content id t
    return $ BS.unpack bs

readStringAP :: Reader String
readStringAP =
  do
    t <- readStringAPTag
    sat (==0x00) -- encoding is 0x00 which is the value used to indicate UTF-8 (formerly ANSI X3.4)
    bs <- bytestring $ fromIntegral $ tagLength t - 1
    return $ UTF8.toString bs

readBitStringAP :: Reader BitString
readBitStringAP =
  do
    tag <- readBitStringAPTag
    guard (tagLength tag /= 0)
    bs <- content id tag
    let bString = bitString (BS.head bs) (BS.unpack $ BS.tail bs)
    maybe (fail "Invalid BitString encoding") return bString

readEnumeratedAP :: Reader Enumerated
readEnumeratedAP = Enumerated <$> (readEnumeratedAPTag >>= content foldbytes)

readDateAP :: Reader Date
readDateAP = const Date <$> readDateAPTag <*> byte <*> byte <*> byte <*> byte

readTimeAP :: Reader Time
readTimeAP = const Time <$> readTimeAPTag <*> byte <*> byte <*> byte <*> byte

readObjectIdentifierAP :: Reader ObjectIdentifier
readObjectIdentifierAP = (ObjectIdentifier . fromIntegral) <$>
                         (readObjectIdentifierAPTag >>= content foldbytes)


foldbytes :: BS.ByteString -> Word
foldbytes = BS.foldl (\acc w -> acc * 256 + fromIntegral w) 0

-- | The reader @content f t@ reads a 'BS.ByteString' of length indicated by the
--   length specified in the 'Tag', @t@, and returns the value obtained by applying
--   @f@ to that ByteString.
content :: (BS.ByteString -> a) -> Tag -> Reader a
content f t = f <$> bytestring (fromIntegral $ tagLength t)

foldsbytes :: BS.ByteString -> Int
foldsbytes bs | BS.null bs = 0
              | otherwise =
  let (val, len) = BS.foldl (\(accv,accl) w -> (accv * 256 + fromIntegral w, accl+1)) (0,0) (BS.tail bs)
  in fromIntegral (fromIntegral (BS.head bs) :: Int8) * 256 ^ len + val
