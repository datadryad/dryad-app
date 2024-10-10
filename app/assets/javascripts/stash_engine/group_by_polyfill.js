const hasGroup = typeof Object.groupBy === typeof undefined || typeof Array.groupToMap === typeof undefined || typeof Array.group === typeof undefined;
if (!hasGroup) {
  const groupBy = (arr, callback) => {
    return arr.reduce((acc = {}, ...args) => {
      const key = callback(...args);
      acc[key] ??= []
      acc[key].push(args[0]);
      return acc;
    }, {});
  };

  if (typeof Object.groupBy === typeof undefined) {
    Object.groupBy = groupBy;
  }

  if (typeof Array.groupToMap === typeof undefined) {
    Array.groupToMap = groupBy;
  }

  if (typeof Array.group === typeof undefined) {
    Array.group = groupBy;
  }
}