import wordsToNumbers from '@insomnia-dev/words-to-numbers';
import {brill} from 'brill'

const TOKENS = /(\S+)|(.)/g;
const IS_SPECIAL_CASE = /[\.#][\p{L}\p{N}]/u; // #tag, example.com, etc.
const IS_MANUAL_CASE = /\p{Ll}(?=[\p{Lu}])/u; // iPhone, iOS, etc.
const ALPHANUMERIC_PATTERN = /[\p{L}\p{N}]+/gu;
const IS_ACRONYM = /^([^\p{L}])*(?:\p{L}\.){2,}([^\p{L}])*$/u;
export const WORD_SEPARATORS = new Set(["—", "–", "-", "―", "/", "'"]);
export const SENTENCE_TERMINATORS = new Set([".", "!", "?"]);
export const TITLE_TERMINATORS = new Set([
  ...SENTENCE_TERMINATORS,
  ":",
  '"',
  "'",
  "”",
  ]);
export const SMALL_WORDS = new Set([
  "a",
  "an",
  "and",
  "as",
  "at",
  "are",
  "because",
  "but",
  "by",
  "en",
  "for",
  "if",
  "in",
  "neither",
  "nor",
  "of",
  "on",
  "only",
  "or",
  "over",
  "per",
  "so",
  "some",
  "than",
  "that",
  "the",
  "to",
  "up",
  "upon",
  "v",
  "versus",
  "via",
  "vs",
  "when",
  "with",
  "without",
  "yet",
  // common Dryad lowercases
  "raw",
  "data",
  "dataset",
  "supplement",
  "supplementary",
  "supporting"
  ]);
export function sentenceCase(input, options = {}) {
  const { locale = 'en-US', sentenceCase = false, sentenceTerminators = SENTENCE_TERMINATORS, titleTerminators = TITLE_TERMINATORS, smallWords = SMALL_WORDS, wordSeparators = WORD_SEPARATORS, } = typeof options === "string" || Array.isArray(options)
  ? { locale: options }
  : options;
  const terminators = sentenceCase ? sentenceTerminators : titleTerminators;
  let result = "";
  let isNewSentence = true;
  for (const m of input.matchAll(TOKENS)) {
    const { 1: token, 2: whiteSpace, index = 0 } = m;
    if (whiteSpace) {
      result += whiteSpace;
      continue;
    }
    // Ignore URLs, email addresses, acronyms, etc.
    if (IS_SPECIAL_CASE.test(token)) {
      const acronym = token.match(IS_ACRONYM);
      // The period at the end of an acronym is not a new sentence,
      // but we should uppercase first for i.e., e.g., etc.
      if (acronym) {
        const [_, prefix = "", suffix = ""] = acronym;
        result += !isNewSentence ? token : upperAt(token, prefix.length, locale);
        isNewSentence = terminators.has(suffix.charAt(0));
        continue;
      }
      result += token;
      isNewSentence = terminators.has(token.charAt(token.length - 1));
    }
    else {
      const matches = Array.from(token.matchAll(ALPHANUMERIC_PATTERN));
      let value = token;
      let isSentenceEnd = false;
      for (let i = 0; i < matches.length; i++) {
        const { 0: word, index: wordIndex = 0 } = matches[i];
        const nextChar = token.charAt(wordIndex + word.length);
        isSentenceEnd = terminators.has(nextChar);
        const tag = brill[lower(word, locale)] || brill[upperAt(lower(word), 0, locale)];
        if (IS_MANUAL_CASE.test(word)) {
          value = value;
          continue;
        } else if (smallWords.has(lower(word)) || !isNaN(wordsToNumbers(word))) {
          value = lower(value, locale)
        } else if (tag && tag.includes('NNP')) {
          value = upperAt(lower(value), wordIndex, locale);
        } else if (tag) {
          value = lower(value, locale)
        } else {
          if (word === lower(word, locale) || word === upper(word, locale)) {
            value = value
          } else {
            value = upperAt(lower(value), wordIndex, locale);
          }
        }
        // Always the capitalize first word and reset "new sentence".
        if (isNewSentence) {
          value = upperAt(value, wordIndex, locale);
          isNewSentence = false;
          continue;
        }
      }
      result += value;
      isNewSentence =
      isSentenceEnd || terminators.has(token.charAt(token.length - 1));
    }
  }
  return result;
}
function upper(input, locale) {
  return input.toLocaleUpperCase(locale)
}
function lower(input, locale) {
  return input.toLocaleLowerCase(locale)
}
function upperAt(input, index, locale) {
  return (input.slice(0, index) +
    input.charAt(index).toLocaleUpperCase(locale) +
    input.slice(index + 1));
}
function lowerAt(input, locale) {
  return (input.slice(0, index) +
    input.charAt(index).toLocaleLowerCase(locale) +
    input.slice(index + 1));
}