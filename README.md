# `aws-easy`

[![Travis branch](https://img.shields.io/travis/rcook/aws-easy/master.svg)](https://travis-ci.org/rcook/aws-easy)
[![Hackage](https://img.shields.io/hackage/v/aws-easy.svg)](http://hackage.haskell.org/package/aws-easy)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/rcook/aws-easy/master/LICENSE)

This is a collection of helper functions and some Template Haskell that I use regularly and has streamlined my use of the [amazonka][amazonka] framework for interacting with [Amazon Web Services][aws]. It was extracted from the code I wrote as part of my [AWS via Haskell][aws-via-haskell] series of blog posts.


## Setup

### Clone repository

```
git clone https://github.com/rcook/aws-easy.git
```

### Install compiler

```
stack setup
```

### Build

```
stack build --fast
```

### Test

```
stack test
```

## Licence

Released under [MIT License][licence]

[amazonka]: https://hackage.haskell.org/package/amazonka
[aws]: https://aws.amazon.com/
[aws-via-haskell]: http://blog.rcook.org/blog/2017/aws-via-haskell/
[licence]: LICENSE
