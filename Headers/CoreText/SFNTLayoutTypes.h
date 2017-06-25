#ifndef OPAL_SFNTLayoutTypes_h
#define OPAL_SFNTLayoutTypes_h

#ifdef __cplusplus
extern "C" {
#endif

enum {
  kAllTypographicFeaturesType = 0,
  kLigaturesType = 1,
  kCursiveConnectionType = 2,
  kLetterCaseType = 3,
  kVerticalSubstitutionType = 4,
  kLinguisticRearrangementType = 5,
  kNumberSpacingType = 6,
  kSmartSwashType = 8,
  kDiacriticsType = 9,
  kVerticalPositionType = 10,
  kFractionsType = 11,
  kOverlappingCharactersType = 13,
  kTypographicExtrasType = 14,
  kMathematicalExtrasType = 15,
  kOrnamentSetsType = 16,
  kCharacterAlternativesType = 17,
  kDesignComplexityType = 18,
  kStyleOptionsType = 19,
  kCharacterShapeType = 20,
  kNumberCaseType = 21,
  kTextSpacingType = 22,
  kTransliterationType = 23,
  kAnnotationType = 24,
  kKanaSpacingType = 25,
  kIdeographicSpacingType = 26,
  kUnicodeDecompositionType = 27,
  kRubyKanaType = 28,
  kCJKSymbolAlternativesType = 29,
  kIdeographicAlternativesType = 30,
  kCJKVerticalRomanPlacementType = 31,
  kItalicCJKRomanType = 32,
  kCaseSensitiveLayoutType = 33,
  kAlternateKanaType = 34,
  kStylisticAlternativesType = 35,
  kContextualAlternatesType = 36,
  kLowerCaseType = 37,
  kUpperCaseType = 38,
  kLanguageTagType = 39,
  kCJKRomanSpacingType = 103,
  kLastFeatureType = -1
};

enum {
  kAllTypeFeaturesOnSelector = 0,
  kAllTypeFeaturesOffSelector = 1
};

enum {
  kRequiredLigaturesOnSelector = 0,
  kRequiredLigaturesOffSelector = 1,
  kCommonLigaturesOnSelector = 2,
  kCommonLigaturesOffSelector = 3,
  kRareLigaturesOnSelector = 4,
  kRareLigaturesOffSelector = 5,
  kLogosOnSelector = 6,
  kLogosOffSelector = 7,
  kRebusPicturesOnSelector = 8,
  kRebusPicturesOffSelector = 9,
  kDiphthongLigaturesOnSelector = 10,
  kDiphthongLigaturesOffSelector = 11,
  kSquaredLigaturesOnSelector = 12,
  kSquaredLigaturesOffSelector = 13,
  kAbbrevSquaredLigaturesOnSelector = 14,
  kAbbrevSquaredLigaturesOffSelector = 15,
  kSymbolLigaturesOnSelector = 16,
  kSymbolLigaturesOffSelector = 17,
  kContextualLigaturesOnSelector = 18,
  kContextualLigaturesOffSelector = 19,
  kHistoricalLigaturesOnSelector = 20,
  kHistoricalLigaturesOffSelector = 21
};

enum {
  kUnconnectedSelector = 0,
  kPartiallyConnectedSelector = 1,
  kCursiveSelector = 2
};

enum {
  kUpperAndLowerCaseSelector = 0,
  kAllCapsSelector = 1,
  kAllLowerCaseSelector = 2,
  kSmallCapsSelector = 3,
  kInitialCapsSelector = 4,
  kInitialCapsAndSmallCapsSelector = 5
};

enum {
  kSubstituteVerticalFormsOnSelector = 0,
  kSubstituteVerticalFormsOffSelector = 1
};

enum {
  kLinguisticRearrangementOnSelector = 0,
  kLinguisticRearrangementOffSelector = 1
};

enum {
  kMonospacedNumbersSelector = 0,
  kProportionalNumbersSelector = 1,
  kThirdWidthNumbersSelector = 2,
  kQuarterWidthNumbersSelector = 3
};

enum {
  kWordInitialSwashesOnSelector = 0,
  kWordInitialSwashesOffSelector = 1,
  kWordFinalSwashesOnSelector = 2,
  kWordFinalSwashesOffSelector = 3,
  kLineInitialSwashesOnSelector = 4,
  kLineInitialSwashesOffSelector = 5,
  kLineFinalSwashesOnSelector = 6,
  kLineFinalSwashesOffSelector = 7,
  kNonFinalSwashesOnSelector = 8,
  kNonFinalSwashesOffSelector = 9
};

enum {
  kShowDiacriticsSelector = 0,
  kHideDiacriticsSelector = 1,
  kDecomposeDiacriticsSelector = 2
};

enum {
  kNormalPositionSelector = 0,
  kSuperiorsSelector = 1,
  kInferiorsSelector = 2,
  kOrdinalsSelector = 3,
  kScientificInferiorsSelector = 4
};

enum {
  kNoFractionsSelector = 0,
  kVerticalFractionsSelector = 1,
  kDiagonalFractionsSelector = 2
};

enum {
  kPreventOverlapOnSelector = 0,
  kPreventOverlapOffSelector = 1
};

enum {
  kHyphensToEmDashOnSelector = 0,
  kHyphensToEmDashOffSelector = 1,
  kHyphenToEnDashOnSelector = 2,
  kHyphenToEnDashOffSelector = 3,
  kSlashedZeroOnSelector = 4,
  kSlashedZeroOffSelector = 5,
  kFormInterrobangOnSelector = 6,
  kFormInterrobangOffSelector = 7,
  kSmartQuotesOnSelector = 8,
  kSmartQuotesOffSelector = 9,
  kPeriodsToEllipsisOnSelector = 10,
  kPeriodsToEllipsisOffSelector = 11
};

enum {
  kHyphenToMinusOnSelector = 0,
  kHyphenToMinusOffSelector = 1,
  kAsteriskToMultiplyOnSelector = 2,
  kAsteriskToMultiplyOffSelector = 3,
  kSlashToDivideOnSelector = 4,
  kSlashToDivideOffSelector = 5,
  kInequalityLigaturesOnSelector = 6,
  kInequalityLigaturesOffSelector = 7,
  kExponentsOnSelector = 8,
  kExponentsOffSelector = 9,
  kMathematicalGreekOnSelector = 10,
  kMathematicalGreekOffSelector = 11
};

enum {
  kNoOrnamentsSelector = 0,
  kDingbatsSelector = 1,
  kPiCharactersSelector = 2,
  kFleuronsSelector = 3,
  kDecorativeBordersSelector = 4,
  kInternationalSymbolsSelector = 5,
  kMathSymbolsSelector = 6
};

enum {
  kNoAlternatesSelector = 0
};

enum {
  kDesignLevel1Selector = 0,
  kDesignLevel2Selector = 1,
  kDesignLevel3Selector = 2,
  kDesignLevel4Selector = 3,
  kDesignLevel5Selector = 4
};

enum {
  kNoStyleOptionsSelector = 0,
  kDisplayTextSelector = 1,
  kEngravedTextSelector = 2,
  kIlluminatedCapsSelector = 3,
  kTitlingCapsSelector = 4,
  kTallCapsSelector = 5
};

enum {
  kTraditionalCharactersSelector = 0,
  kSimplifiedCharactersSelector = 1,
  kJIS1978CharactersSelector = 2,
  kJIS1983CharactersSelector = 3,
  kJIS1990CharactersSelector = 4,
  kTraditionalAltOneSelector = 5,
  kTraditionalAltTwoSelector = 6,
  kTraditionalAltThreeSelector = 7,
  kTraditionalAltFourSelector = 8,
  kTraditionalAltFiveSelector = 9,
  kExpertCharactersSelector = 10,
  kJIS2004CharactersSelector = 11,
  kHojoCharactersSelector = 12,
  kNLCCharactersSelector = 13,
  kTraditionalNamesCharactersSelector = 14
};

enum {
  kLowerCaseNumbersSelector = 0,
  kUpperCaseNumbersSelector = 1
};

enum {
  kProportionalTextSelector = 0,
  kMonospacedTextSelector = 1,
  kHalfWidthTextSelector = 2,
  kThirdWidthTextSelector = 3,
  kQuarterWidthTextSelector = 4,
  kAltProportionalTextSelector = 5,
  kAltHalfWidthTextSelector = 6
};

enum {
  kNoTransliterationSelector = 0,
  kHanjaToHangulSelector = 1,
  kHiraganaToKatakanaSelector = 2,
  kKatakanaToHiraganaSelector = 3,
  kKanaToRomanizationSelector = 4,
  kRomanizationToHiraganaSelector = 5,
  kRomanizationToKatakanaSelector = 6,
  kHanjaToHangulAltOneSelector = 7,
  kHanjaToHangulAltTwoSelector = 8,
  kHanjaToHangulAltThreeSelector = 9
};

enum {
  kNoAnnotationSelector = 0,
  kBoxAnnotationSelector = 1,
  kRoundedBoxAnnotationSelector = 2,
  kCircleAnnotationSelector = 3,
  kInvertedCircleAnnotationSelector = 4,
  kParenthesisAnnotationSelector = 5,
  kPeriodAnnotationSelector = 6,
  kRomanNumeralAnnotationSelector = 7,
  kDiamondAnnotationSelector = 8,
  kInvertedBoxAnnotationSelector = 9,
  kInvertedRoundedBoxAnnotationSelector = 10
};

enum {
  kFullWidthKanaSelector = 0,
  kProportionalKanaSelector = 1
};

enum {
  kFullWidthIdeographsSelector = 0,
  kProportionalIdeographsSelector = 1,
  kHalfWidthIdeographsSelector = 2
};

enum {
  kCanonicalCompositionOnSelector = 0,
  kCanonicalCompositionOffSelector = 1,
  kCompatibilityCompositionOnSelector = 2,
  kCompatibilityCompositionOffSelector = 3,
  kTranscodingCompositionOnSelector = 4,
  kTranscodingCompositionOffSelector = 5
};

enum {
  kNoRubyKanaSelector = 0,
  kRubyKanaSelector = 1,
  kRubyKanaOnSelector = 2,
  kRubyKanaOffSelector = 3
};

enum {
  kNoCJKSymbolAlternativesSelector = 0,
  kCJKSymbolAltOneSelector = 1,
  kCJKSymbolAltTwoSelector = 2,
  kCJKSymbolAltThreeSelector = 3,
  kCJKSymbolAltFourSelector = 4,
  kCJKSymbolAltFiveSelector = 5
};

enum {
  kNoIdeographicAlternativesSelector = 0,
  kIdeographicAltOneSelector = 1,
  kIdeographicAltTwoSelector = 2,
  kIdeographicAltThreeSelector = 3,
  kIdeographicAltFourSelector = 4,
  kIdeographicAltFiveSelector = 5
};

enum {
  kCJKVerticalRomanCenteredSelector = 0,
  kCJKVerticalRomanHBaselineSelector = 1
};

enum {
  kNoCJKItalicRomanSelector = 0,
  kCJKItalicRomanSelector = 1,
  kCJKItalicRomanOnSelector = 2,
  kCJKItalicRomanOffSelector = 3
};

enum {
  kCaseSensitiveLayoutOnSelector = 0,
  kCaseSensitiveLayoutOffSelector = 1,
  kCaseSensitiveSpacingOnSelector = 2,
  kCaseSensitiveSpacingOffSelector = 3
};

enum {
  kAlternateHorizKanaOnSelector = 0,
  kAlternateHorizKanaOffSelector = 1,
  kAlternateVertKanaOnSelector = 2,
  kAlternateVertKanaOffSelector = 3
};

enum {
  kNoStylisticAlternatesSelector = 0,
  kStylisticAltOneOnSelector = 2,
  kStylisticAltOneOffSelector = 3,
  kStylisticAltTwoOnSelector = 4,
  kStylisticAltTwoOffSelector = 5,
  kStylisticAltThreeOnSelector = 6,
  kStylisticAltThreeOffSelector = 7,
  kStylisticAltFourOnSelector = 8,
  kStylisticAltFourOffSelector = 9,
  kStylisticAltFiveOnSelector = 10,
  kStylisticAltFiveOffSelector = 11,
  kStylisticAltSixOnSelector = 12,
  kStylisticAltSixOffSelector = 13,
  kStylisticAltSevenOnSelector = 14,
  kStylisticAltSevenOffSelector = 15,
  kStylisticAltEightOnSelector = 16,
  kStylisticAltEightOffSelector = 17,
  kStylisticAltNineOnSelector = 18,
  kStylisticAltNineOffSelector = 19,
  kStylisticAltTenOnSelector = 20,
  kStylisticAltTenOffSelector = 21,
  kStylisticAltElevenOnSelector = 22,
  kStylisticAltElevenOffSelector = 23,
  kStylisticAltTwelveOnSelector = 24,
  kStylisticAltTwelveOffSelector = 25,
  kStylisticAltThirteenOnSelector = 26,
  kStylisticAltThirteenOffSelector = 27,
  kStylisticAltFourteenOnSelector = 28,
  kStylisticAltFourteenOffSelector = 29,
  kStylisticAltFifteenOnSelector = 30,
  kStylisticAltFifteenOffSelector = 31,
  kStylisticAltSixteenOnSelector = 32,
  kStylisticAltSixteenOffSelector = 33,
  kStylisticAltSeventeenOnSelector = 34,
  kStylisticAltSeventeenOffSelector = 35,
  kStylisticAltEighteenOnSelector = 36,
  kStylisticAltEighteenOffSelector = 37,
  kStylisticAltNineteenOnSelector = 38,
  kStylisticAltNineteenOffSelector = 39,
  kStylisticAltTwentyOnSelector = 40,
  kStylisticAltTwentyOffSelector = 41
};

enum {
  kContextualAlternatesOnSelector = 0,
  kContextualAlternatesOffSelector = 1,
  kSwashAlternatesOnSelector = 2,
  kSwashAlternatesOffSelector = 3,
  kContextualSwashAlternatesOnSelector = 4,
  kContextualSwashAlternatesOffSelector = 5
};

enum {
  kDefaultLowerCaseSelector = 0,
  kLowerCaseSmallCapsSelector = 1,
  kLowerCasePetiteCapsSelector = 2
};

enum {
  kDefaultUpperCaseSelector = 0,
  kUpperCaseSmallCapsSelector = 1,
  kUpperCasePetiteCapsSelector = 2
};

enum {
  kHalfWidthCJKRomanSelector = 0,
  kProportionalCJKRomanSelector = 1,
  kDefaultCJKRomanSelector = 2,
  kFullWidthCJKRomanSelector = 3
};

#ifdef __cplusplus
}
#endif

#endif
