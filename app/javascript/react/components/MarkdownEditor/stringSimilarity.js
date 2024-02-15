/* eslint-disable no-param-reassign */
const stringSimilarity = (
  str1,
  str2,
  substringLength = 2,
  caseSensitive = false,
) => {
  if (!caseSensitive) {
    str1 = str1.toLowerCase();
    str2 = str2.toLowerCase();
  }

  if (str1.length < substringLength || str2.length < substringLength) return 0;

  const map = new Map();
  for (let i = 0; i < str1.length - (substringLength - 1); i += 1) {
    const substr1 = str1.substr(i, substringLength);
    map.set(substr1, map.has(substr1) ? map.get(substr1) + 1 : 1);
  }

  let match = 0;
  for (let j = 0; j < str2.length - (substringLength - 1); j += 1) {
    const substr2 = str2.substr(j, substringLength);
    const count = map.has(substr2) ? map.get(substr2) : 0;
    if (count > 0) {
      map.set(substr2, count - 1);
      match += 1;
    }
  }

  return (match * 2) / (str1.length + str2.length - (substringLength - 1) * 2);
};
/* eslint-enable no-param-reassign */

export default stringSimilarity;
