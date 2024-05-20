# TracingRequester
A simple implementation of a traceable requests sender

[![Swift Version][swift-image]][swift-url]
[![License][license-image]][license-url]

# Features

- Zero external dependencies
- Swift 5
- Swift Concurrency
- XCTest

## Installing

Just clone this repo and open `/TracingRequester`, folder in Xcode:

```bash
git clone git@github.com:gitvalue/TracingRequester.git
xed TracingRequester/
```

## Architecture

1. `Transport` interface is used for abstracting network data transfer
2. `RequestQueueTraceInfo` is a model containing statistics about requests queue performance (e.g. number of succeeded requests)
3. `Requester` is a requests manager. It uses `Transport` abstraction to send serialised requests and `RequestQueueTraceInfo` for collecting stats.

## Algorithm

`Requester` keeps track of available queues through `availableQueues` set. If it runs out of available queues but receives a request to be sent,
it puts it on hold until receives a message from some queue that it has finished processing current request and ready to take a new one. New request
then occupies that queue.

## Versioning

This repo do not use any versioning system because I have no plans of maintaining the application in the future

## Troubleshooting

For any questions please fell free to contact [Dmitry Volosach](dmitry.volosach@gmail.com).

## Authors

* **Dmitry Volosach** - *Initial work* - dmitry.volosach@gmail.com

[swift-image]:https://img.shields.io/badge/swift-5.6-orange.svg
[swift-url]: https://swift.org/
[license-image]: https://img.shields.io/badge/License-MIT-blue.svg
[license-url]: LICENSE