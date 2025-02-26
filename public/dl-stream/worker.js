class DownloadStream extends ReadableStream {
  constructor(requests, strategy = { highWaterMark: 3 }) {
    const promises = []
    const controller = new AbortController()
    const iterator = 'next' in requests ? requests
    : requests[Symbol.iterator in requests ? Symbol.iterator : Symbol.asyncIterator]()
    super({
      async pull(ctrl) {
        let i = ctrl.desiredSize - promises.length
        while (i--) {
          const { done, value } = await iterator.next()
          if (done) break
          const promise = fetch(value, { signal: controller.signal })
          promises.push(promise)
        }
        if (promises.length) ctrl.enqueue(await promises.shift())
        else ctrl.close()
      },
      cancel(e) {
        controller.abort(e)
        iterator.throw?.(e)
      }
    }, strategy)
  }
  [Symbol.asyncIterator]() {
    const reader = this.getReader()
    return {
      next() { return reader.read() },
      throw(e) { reader.cancel(e) }
    }
  }
}
