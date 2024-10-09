const maxFiles = 1000;
const maxSize = 300000000000;
const maxZenodo = 50000000000;
const pollingDelay = 10000;

const formatSizeUnits = (bytes) => {
  if (bytes < 1000) {
    return `${bytes} B`;
  }

  const units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
  for (let i = 0; i < units.length; i += 1) {
    if (bytes / 10 ** (3 * (i + 1)) < 1) {
      return `${(bytes / 10 ** (3 * i)).toFixed(2)} ${units[i]}`;
    }
  }
  return true;
};

module.exports = {
  maxFiles,
  maxSize,
  maxZenodo,
  pollingDelay,
  formatSizeUnits,
};
