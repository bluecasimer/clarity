# Contributing guidelines

## Contribution checklist

Before opening a pull request with your contributions, make sure you followed this list.

- Please read the [Contributing guidelines](CONTRIBUTING.md).
- Please read the [Code of Conduct](CODE_OF_CONDUCT.md).
- Please make sure code style conforms with the [Code Style Guide](#code-style-guide).

## How to become a contributor and submit your own code

We would love to receive your suggestions and code submissions. In order to do that you have to agree with some conditions.

Clarity is an open source project adopting the [Apache 2.0 license](LICENSE.md). Use of the project and/or contributions to it must also comply with the terms of the license.

### Code style guide

Prior to submitting contributions in a pull request make sure your changes conform to the code style guide. We use [ClangFormat](https://clang.llvm.org/docs/ClangFormat.html) to encoded in the coding style. You can find the encoding in the [.clang-format](.clang-format) file.

It is encouraged that your have ClangFormat installed and implement a pre-commit hook to apply the code style prior to submitting your code contribution.

In order to make it easier, we provide the [setup_clang_format.sh](setup_clang_format.sh) script that will configure the pre-commit hook for you. From the `clarity` directory run:

```bash
./setup_clang_format.sh
```

You must also include the Apache 2.0 notice at the top of your files, as described in [APPENDIX: HOW TO APPLY THE APACHE LICENSE TO YOUR WORK](https://www.apache.org/licenses/LICENSE-2.0.html#apply)
