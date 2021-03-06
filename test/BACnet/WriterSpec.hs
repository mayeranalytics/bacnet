{-# OPTIONS_GHC -fno-warn-orphans #-}
module BACnet.WriterSpec where

import Test.Hspec
import Test.QuickCheck
import BACnet.Prim
import BACnet.Writer
import Data.Maybe (fromJust)
import Data.Word (Word8)
import Data.Int (Int32)
import Data.Monoid
import Control.Applicative
import BACnet.EncodableSpec ()

shouldWrite :: Writer -> [Word8] -> Expectation
shouldWrite = shouldBe . runW

infix 1 `shouldWrite`

spec :: Spec
spec =
  do
    describe "writeNullAP" $
      it "writes [0x00]" $
        writeNullAP `shouldWrite` [0x00]

    describe "writeNullCS" $
      it "writeNullCS 254 should write [0xF8, 0xFE]" $
        writeNullCS 254 `shouldWrite` [0xF8, 0xFE]

    describe "writeBoolAP" $ do
      it "writes [0x10] for Bool input False" $
        writeBoolAP False `shouldWrite` [0x10]

      it "writes [0x11] for Bool input True" $
        writeBoolAP True `shouldWrite` [0x11]

    describe "writeUnsignedAP" $ do
      it "writes [0x21, 0x00] for input 0" $
        writeUnsignedAP 0 `shouldWrite` [0x21, 0x00]

      it "writes [0x21, 0xFF] for input 255" $
        writeUnsignedAP 255 `shouldWrite` [0x21, 0xFF]

      it "writes [0x22, 0x01, 0x00] for input 256" $
        writeUnsignedAP 256 `shouldWrite` [0x22, 0x01, 0x00]

      it "writes [0x22, 0xFF, 0xFF] for input 65535" $
        writeUnsignedAP 65535 `shouldWrite` [0x22, 0xFF, 0xFF]

      it "writes [0x23, 0x01, 0x00, 0x00] for input 65536" $
        writeUnsignedAP 65536 `shouldWrite` [0x23, 0x01, 0x00, 0x00]

      it "writes [0x23, 0xFF, 0xFF, 0xFF] for input 16777215" $
        writeUnsignedAP 16777215 `shouldWrite` [0x23, 0xFF, 0xFF, 0xFF]

      it "writes [0x24, 0x01, 0x00, 0x00, 0x00] for input 16777216" $
        writeUnsignedAP 16777216 `shouldWrite` [0x24, 0x01, 0x00, 0x00, 0x00]

    describe "writeSignedAP" $ do
      it "writes [0x31, 0x00] for input 0" $
        writeSignedAP 0 `shouldWrite` [0x31, 0x00]

      it "writes [0x31, 0x7F] for input 127" $
        writeSignedAP 127 `shouldWrite` [0x31, 0x7F]

      it "writes [0x32, 0x00, 0x80] for input 128" $
        writeSignedAP 128 `shouldWrite` [0x32, 0x00, 0x80]

      it "writes [0x32, 0x7F, 0xFF] for input 32767" $
        writeSignedAP 32767 `shouldWrite` [0x32, 0x7F, 0xFF]

      it "writes [0x31, 0xFF] for input -1" $
        writeSignedAP (-1) `shouldWrite` [0x31, 0xFF]

      it "writes [0x31, 0x80] for input -128" $
        writeSignedAP (-128) `shouldWrite` [0x31, 0x80]

      it "writes [0x32, 0xFF, 0x7F] for input -129" $
        writeSignedAP (-129) `shouldWrite` [0x32, 0xFF, 0x7F]

      it "writes [0x32, 0x80, 0x00] for input -32768" $
        writeSignedAP (-32768) `shouldWrite` [0x32, 0x80, 0x00]

      it "writes [0x33, 0xFF, 0x7F, 0xFF] for input -32769" $
        writeSignedAP (-32769) `shouldWrite` [0x33, 0xFF, 0x7F, 0xFF]

      it "writes [0x33, 0x80, 0x00, 0x00] for input -8388608" $
        writeSignedAP (-8388608) `shouldWrite` [0x33, 0x80, 0x00, 0x00]

      it "writes [0x34, 0xFF, 0x7F, 0xFf, 0xFF] for input -8388609" $
        writeSignedAP (-8388609) `shouldWrite` [0x34, 0xFF, 0x7F, 0xFF, 0xFF]

      it "writes [0x34, 0x80, 0x00, 0x00, 0x00] for input -2147483648" $
        writeSignedAP (minBound :: Int32) `shouldWrite`
          [0x34, 0x80, 0x00, 0x00, 0x00]

    describe "writeRealAP" $ do
      it "writes [0x44, 0x00, 0x00, 0x00, 0x01] for input  1.4e-45" $
        writeRealAP  1.4e-45 `shouldWrite` [0x44, 0x00, 0x00, 0x00, 0x01]

      it "writes [0x44, 0x7F, 0x7F, 0xFF, 0xFF] for input 3.4028235E38" $
        writeRealAP 3.4028235E38 `shouldWrite` [0x44, 0x7F, 0x7F, 0xFF, 0xFF]

      it "writes [0x44, 0xFF, 0x80, 0x00, 0x00] for input -infinity" $
        writeRealAP (-1.0/0.0) `shouldWrite` [0x44, 0xFF, 0x80, 0x00, 0x00]

    describe "writeDoubleAP" $ do
      it "writes [0x55, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01] for input 4.9E-324" $
        writeDoubleAP 4.9E-324 `shouldWrite` [0x55, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01]

      it "writes [0x55, 0x08, 0x7F, 0xF0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00] for infinity" $
        writeDoubleAP (1.0/0.0) `shouldWrite` [0x55, 0x08, 0x7F, 0xF0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]

    describe "writeOctetStringAP" $ do
      it "writes [0x60] for empty Octet string" $
        writeOctetStringAP [] `shouldWrite` [0x60]

      it "writes [0x61, 0xAA] for singleton string [0xAA]" $
        writeOctetStringAP [0xAA] `shouldWrite` [0x61, 0xAA]

      it "writes [0x65, 0x06, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06] for string [0x01, 0x02, 0x03, 0x04, 0x05, 0x06]" $
        writeOctetStringAP [0x01, 0x02, 0x03, 0x04, 0x05, 0x06] `shouldWrite`
          [0x65, 0x06, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06]

      it "writes [0x65, 0xFD] ++ bs for input bs where bs is a string of length 253" $
        writeOctetStringAP (replicate 253 17) `shouldWrite`
          ([0x65, 0xFD] ++ replicate 253 17)

      it "writes [0x65, 0xFE, 0x00, 0xFE] ++ bs for input bs where bs is a string of length 254" $
        writeOctetStringAP (replicate 254 18) `shouldWrite`
          ([0x65, 0xFE, 0x00, 0xFE] ++ replicate 254 18)

      it "writes [0x65, 0xFF, 0x00, 0x01, 0x00, 0x00] as the tag for a string of length 65536" $
        writeOctetStringAP (replicate 65536 19) `shouldWrite`
          ([0x65, 0xFF, 0x00, 0x01, 0x00, 0x00] ++ replicate 65536 19)

    describe "writeStringAP" $ do
      it "writes [0x71, 0x00] for empty string" $
        writeStringAP "" `shouldWrite` [0x71, 0x00]

      it "writes [0x73, 0x00, 0x48, 0x49] for \"HI\"" $
        writeStringAP "HI" `shouldWrite` [0x73, 0x00, 0x48, 0x49]

    describe "writeBitStringAP" $ do
      it "writes [0x81, 0x00] for empty bit string" $
        writeBitStringAP bitStringEmpty `shouldWrite` [0x81, 0x00]

      it "writes [0x85, 0x05, 0x03, 0x01, 0x02, 0x03, 0xF0] for input BitString 3 [0x01, 0x02, 0x03, 0xF0]" $
        writeBitStringAP (fromJust $ bitString 3 [0x01, 0x02, 0x03, 0xF0])
          `shouldWrite` [0x85, 0x05, 0x03, 0x01, 0x02, 0x03, 0xF0]

    describe "writeEnumeratedAP" $
      it "writes [0x91, 0x00] for 0" $
        writeEnumeratedAP (Enumerated 0) `shouldWrite` [0x91, 0x00]

    describe "writeDateAP" $
      it "writes [0xA4, 0x72, 0x04, 0x06, 0xFF] for Date 114 4 6 255" $
        writeDateAP (Date 114 4 6 255) `shouldWrite` [0xA4, 0x72, 0x04, 0x06, 0xFF]

    describe "writeTimeAP" $
      it "writes [0xB4, 0x09, 0x1A, 0x13, 0xFF] for Time 9 26 19 255" $
        writeTimeAP (Time 9 26 19 255) `shouldWrite` [0xB4, 0x09, 0x1A, 0x13, 0xFF]

    describe "writeObjectIdentifierAP" $
      it "writes [0xC4, 0x01, 0x00, 0x00, 0xFF] for ObjectIdentifier 4 255" $
        writeObjectIdentifierAP (fromJust $ objectIdentifier 4 255) `shouldWrite`
          [0xC4, 0x01, 0x00, 0x00, 0xFF]

    describe "writeAnyAP" $ do
      it "writes Null" $
        writeAnyAP NullAP `shouldWrite` [0x00]

      it "writes Bool" $
        writeAnyAP (BooleanAP True) `shouldWrite` [0x11]

      it "writes Unsigned" $
        writeAnyAP (UnsignedAP 0x1234) `shouldWrite` [0x22, 0x12, 0x34]

      it "writes Signed" $
        writeAnyAP (SignedAP 0x7764) `shouldWrite` [0x32, 0x77, 0x64]

      it "writes Real" $
        writeAnyAP (RealAP 2.138e19) `shouldWrite` [68,95,148,90,130]

      it "writes Double" $
        writeAnyAP (DoubleAP 3.123e245) `shouldWrite` [85,8,114,230,222,113,2,8,2,207]

      it "writes OctetString" $
        writeAnyAP (OctetStringAP [0x23, 0xFF]) `shouldWrite` [0x62,0x23,0xFF]

      it "writes String" $
        writeAnyAP (CharacterStringAP "HI") `shouldWrite` [0x73,0,72,73]

      it "writes BitString" $
        writeAnyAP (BitStringAP . fromJust $ bitString 3 [0x99,0x34])
          `shouldWrite` [0x83,0x03,0x99,0x34]

      it "writes Enumerated" $
        writeAnyAP (EnumeratedAP $ Enumerated 0xFF8345) `shouldWrite` [0x93,0xFF,0x83,0x45]

      it "writes Date" $
        writeAnyAP (DateAP $ Date 7 9 10 11) `shouldWrite` [0xa4,7,9,10,11]

      it "writes Time" $
        writeAnyAP (TimeAP $ Time 1 5 7 12) `shouldWrite` [0xb4,1,5,7,12]

      it "writes ObjectIdentifier" $
        writeAnyAP (ObjectIdentifierAP . fromJust $ objectIdentifier 3 12)
          `shouldWrite` [0xc4, 0x00, 0xC0, 0x00, 0x0C]

    describe "Writer" $
      context "Is a Monoid" $ do
        it "obeys the law mempty <> writer = writer" $
          property $ \w -> mempty <> w == (w :: Writer)

        it "obeys the law writer <> mempty = writer" $
          property $ \w -> w <> mempty == (w :: Writer)

        it "is associative" $
          property $ \x y z -> (x <> y) <> (z :: Writer) == x <> (y <> z)




-- Orphan instance since I don't want to be dependent on 
-- Arbitrary in my core library when it's only useful in tests.

instance Arbitrary Writer where
  arbitrary = oneof [
    return writeNullAP,
    writeBoolAP <$> arbitrary,
    writeUnsignedAP <$> arbitrary,
    writeSignedAP <$> arbitrary,
    writeRealAP <$> arbitrary,
    writeDoubleAP <$> arbitrary,
    writeOctetStringAP <$> arbitrary,
    writeStringAP <$> arbitrary,
    writeBitStringAP <$> arbitrary,
    writeEnumeratedAP <$> arbitrary,
    writeDateAP <$> arbitrary,
    writeTimeAP <$> arbitrary,
    writeObjectIdentifierAP <$> arbitrary
    ]
