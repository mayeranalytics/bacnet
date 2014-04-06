module BACnet.WriterSpec where

import Test.Hspec
import Test.QuickCheck
import BACnet.Writer

spec :: Spec
spec =
  do
    describe "writeNullAP" $
      it "writes [0x00]" $
        runW writeNullAP `shouldBe` [0x00]

    describe "writeBoolAP" $ do
      it "writes [0x10] for Bool input False" $
        runW (writeBoolAP False) `shouldBe` [0x10]

      it "writes [0x11] for Bool input True" $
        runW (writeBoolAP True) `shouldBe` [0x11]

    describe "writeUnsignedAP" $ do
      it "writes [0x21, 0x00] for input 0" $
        runW (writeUnsignedAP 0) `shouldBe` [0x21, 0x00]

      it "writes [0x21, 0xFF] for input 255" $
        runW (writeUnsignedAP 255) `shouldBe` [0x21, 0xFF]

      it "writes [0x22, 0x01, 0x00] for input 256" $
        runW (writeUnsignedAP 256) `shouldBe` [0x22, 0x01, 0x00]

      it "writes [0x22, 0xFF, 0xFF] for input 65535" $
        runW (writeUnsignedAP 65535) `shouldBe` [0x22, 0xFF, 0xFF]

      it "writes [0x23, 0x01, 0x00, 0x00] for input 65536" $
        runW (writeUnsignedAP 65536) `shouldBe` [0x23, 0x01, 0x00, 0x00]

      it "writes [0x23, 0xFF, 0xFF, 0xFF] for input 16777215" $
        runW (writeUnsignedAP 16777215) `shouldBe` [0x23, 0xFF, 0xFF, 0xFF]

      it "writes [0x24, 0x01, 0x00, 0x00, 0x00] for input 16777216" $
        runW (writeUnsignedAP 16777216) `shouldBe` [0x24, 0x01, 0x00, 0x00, 0x00]

    describe "writeSignedAP" $ do
      it "writes [0x31, 0x00] for input 0" $
        runW (writeSignedAP 0) `shouldBe` [0x31, 0x00]
