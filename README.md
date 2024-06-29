[![Build Status][build status badge]][build status]
[![Platforms][platforms badge]][platforms]
[![Documentation][documentation badge]][documentation]

# Empire

A record store for Swift

Empire is an experiment in persistence.

- Schema is defined by your types
- Macro-based API that is both typesafe and low-overhead
- Built for Swift 6 
- Backed by a sorted-key index data store ([LMDB][LMDB])

> Warning: This is still a WIP.

## Integration

```swift
dependencies: [
    .package(url: "https://github.com/mattmassicotte/Empire", branch: "main")
]
```

## Questions

### Why does this exist?

I'm not sure! I haven't used [CoreData](https://developer.apple.com/documentation/coredata) or [SwiftData](https://developer.apple.com/documentation/swiftdata) too much. But I have used the distributed database [Cassandra](https://cassandra.apache.org) quite a lot and [DynamoDB](https://aws.amazon.com/dynamodb/) a bit. Then one day I discovered [LMDB][LMDB]. Its data model is quite similar to Cassandra and I got interested in playing around with it. This just kinda materialized from those experiments.

### Can I use this?

Sure!

### *Should* I use this?

User data is important. This library has a bunch of tests, but it has no real-world testing. I plan on using this myself, but even I haven't gotten to that yet. It should be considered *functional*, but experimental.

## Contributing and Collaboration

I'd love to hear from you! Get in touch via [mastodon](https://mastodon.social/@mattiem), an issue, or a pull request.

I prefer collaboration, and would love to find ways to work together if you have a similar project.

I prefer indentation with tabs for improved accessibility. But, I'd rather you use the system you want and make a PR than hesitate because of whitespace.

By participating in this project you agree to abide by the [Contributor Code of Conduct](CODE_OF_CONDUCT.md).

[build status]: https://github.com/mattmassicotte/Empire/actions
[build status badge]: https://github.com/mattmassicotte/Empire/workflows/CI/badge.svg
[platforms]: https://swiftpackageindex.com/mattmassicotte/Empire
[platforms badge]: https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmattmassicotte%2FEmpire%2Fbadge%3Ftype%3Dplatforms
[documentation]: https://swiftpackageindex.com/mattmassicotte/Empire/main/documentation
[documentation badge]: https://img.shields.io/badge/Documentation-DocC-blue
[LMDB]: https://www.symas.com/lmdb
