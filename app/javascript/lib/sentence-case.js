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
    // ignore URLs, email addresses, acronyms with dots, etc.
    if (IS_SPECIAL_CASE.test(token)) {
      const acronym = token.match(IS_ACRONYM);
      // the period at the end of an acronym is not a new sentence,
      // but uppercase first letter for i.e., e.g., etc.
      if (acronym) {
        const [_, prefix = "", suffix = ""] = acronym;
        result += !isNewSentence ? token : upperAt(token, prefix.length, locale);
        isNewSentence = terminators.has(suffix.charAt(0));
        continue;
      }
      result += token;
      isNewSentence = terminators.has(token.charAt(token.length - 1));
    } else {
      const matches = Array.from(token.matchAll(ALPHANUMERIC_PATTERN));
      let value = token;
      let isSentenceEnd = false;
      for (let i = 0; i < matches.length; i++) {
        const { 0: word, index: wordIndex = 0 } = matches[i];
        const nextChar = token.charAt(wordIndex + word.length);
        isSentenceEnd = terminators.has(nextChar);
        const tag = brill[lower(word, locale)] || brill[upperAt(lower(word), 0, locale)];
        if (IS_MANUAL_CASE.test(word)) {
          // keep manual casing
          value = value;
          continue;
        } else if (smallWords.has(lower(word)) || !isNaN(wordsToNumbers(word))) {
          // lowercase all small/common/counting words
          value = lower(value, locale)
        } else if (tag && (tag.includes('NNP') || tag.includes('NNPS'))) {
          // uppercase recognized proper nouns
          value = upperAt(lower(value), wordIndex, locale);
        } else if (tag) {
          // lowercase if word is not a proper noun but is recognized
          value = lower(value, locale)
        } else {
          // if the word is all upper or lowercase
          if (word === lower(word, locale) || word === upper(word, locale)) {
            // force lowercase if the whole sentence is all caps
            if (input === upper(input, locale)) {
              value = lower(value, locale)
            } else {
              // otherwise keep existing upper or lower casing
              // for acronyms without dots
              value = value
            }
          } else {
            // if all else fails, uppercase first letter
            value = upperAt(lower(value), wordIndex, locale);
          }
        }
        // always capitalize the first word and reset "new sentence"
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