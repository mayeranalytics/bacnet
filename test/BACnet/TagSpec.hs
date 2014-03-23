module TagSpec where

import Tag
import Test.QuickCheck
import Test.Hspec

spec :: Spec
spec = do
  describe "readAPTag" $ do
    it "returns Nothing for input that is empty" $
      runReader readAPTag [] `shouldBe` Nothing
    it "returns Just(apNullTag, bs) on input (0x00 : bs)" $
      property $ (\bs -> runReader readAPTag (0x00 : bs) `shouldBe`
      Just(apNullTag, bs))
    it "returns Nothing on 0x0w where w is non-zero" $
      property $ forAll (choose (1,15))
      (\b -> runReader readAPTag [b] `shouldBe` Nothing)
    it "returns Just(apTrueTag, bs) on input (0x11 : bs)" $
      property $ (\bs -> runReader readAPTag (0x11 : bs) `shouldBe`
      Just(apTrueTag, bs))
    it "returns Just(apFalseTag, bs) on input (0x10 : bs)" $
      property $ (\bs -> runReader readAPTag (0x10 : bs) `shouldBe`
      Just(apFalseTag, bs))
    it "returns Nothing on 0x1w where w is not 0 or 1" $
      property $ forAll (choose (2,15))
      (\b -> runReader readAPTag [(0x10 + b)] `shouldBe` Nothing)
    it "returns Just(apUnsignedTag 0, bs) on input (0x21 : bs)" $
      property $ (\bs -> runReader readAPTag (0x21 : bs) `shouldBe`
      Just(apUnsignedTag 0, bs))