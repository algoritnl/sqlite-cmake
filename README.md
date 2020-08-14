# sqlite-cmake: A modern CMake build system for SQLite

<!--
SPDX-FileCopyrightText: 2020 AlgorIT Software Consultancy <https://github.com/algoritnl>
SPDX-License-Identifier: CC0-1.0
-->

[![REUSE status](https://api.reuse.software/badge/github.com/algoritnl/sqlite-cmake)](https://api.reuse.software/info/github.com/algoritnl/sqlite-cmake)
[![pre-commit.ci status](https://results.pre-commit.ci/badge/github/algoritnl/sqlite-cmake/main.svg)](https://results.pre-commit.ci/latest/github/algoritnl/sqlite-cmake/main)
[![CI Test](https://github.com/algoritnl/sqlite-cmake/actions/workflows/ci-test.yaml/badge.svg)](https://github.com/algoritnl/sqlite-cmake/actions/workflows/ci-test.yaml)
![CMake 3.16...4.4+](https://img.shields.io/badge/CMake-3.16...4.4%2B-blue?logo=cmake)

A modern CMake build system to build, install, and integrate the official SQLite Amalgamation into C/C++ projects.

## Features

* **Drop-in replacement:** Includes vendored SQLite sources in the `source/` directory.
* **Integrity Verification**: Includes a SHA3-256 checksum file `source/sqlite3.sha3sum` to verify code authenticity.
* **Highly Configurable:** Native CMake options mapping directly to the official SQLite compile-time options.
* **Customizable:** Swap the included sources with a customized SQLite amalgamation if needed.
* **Modern CMake:** Provides standard CMake export targets for seamless integration.

## Usage

After building and installing this project, you can integrate it into your own CMake project using the standard `CONFIG` mode:

```cmake
find_package(sqlite CONFIG REQUIRED)
target_link_libraries(your_target PRIVATE sqlite::sqlite)
```

Other supported integrations include `FetchContent`  and `add_subdirectory`.

## Licensing

This repository uses a dual-license structure:
* The CMake build configurations and tools are dedicated to the public domain under **CC0-1.0**.
* The SQLite source code files in the `source/` directory are licensed under the official **SQLite Blessing** (`blessing`).

This project is fully REUSE compliant.

## Legal Disclaimer

This repository is an independent open-source project and is not affiliated with, endorsed by, or associated with D. Richard Hipp or the official SQLite contributors. The term "SQLite" and any associated logos are trademarks of Hipp, Wyrick & Company, Inc., and are used in this repository solely for nominative purposes to identify the software being configured and built.
