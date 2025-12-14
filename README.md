<p align="center">
  <img src="https://raw.githubusercontent.com/simple-eiffel/claude_eiffel_op_docs/main/artwork/LOGO.png" alt="simple_ library logo" width="400">
</p>

# simple_mq

**[Documentation](https://simple-eiffel.github.io/simple_mq/)** | **[GitHub](https://github.com/simple-eiffel/simple_mq)**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Eiffel](https://img.shields.io/badge/Eiffel-25.02-blue.svg)](https://www.eiffel.org/)
[![Design by Contract](https://img.shields.io/badge/DbC-enforced-orange.svg)]()
[![SCOOP](https://img.shields.io/badge/SCOOP-compatible-orange.svg)]()

Message queue library for Eiffel with Redis Streams, pub/sub, and async messaging patterns.

Part of the [Simple Eiffel](https://github.com/simple-eiffel) ecosystem.

## Status

**Beta**

## Overview

simple_mq provides a clean API for message queue operations including Redis Streams integration, publish/subscribe patterns, and asynchronous message handling. Built with Design by Contract and SCOOP compatibility for concurrent applications.

```eiffel
-- Publish a message
local
    mq: SIMPLE_MQ
    msg: SIMPLE_MQ_MESSAGE
do
    create mq.make
    create msg.make ("user.created", "{%"id%": 123}")
    mq.publish (msg)
end
```

## Features

- **Message Queues** - In-memory and Redis-backed queues
- **Pub/Sub** - Topic-based publish/subscribe patterns
- **Message Types** - Structured messages with metadata
- **Subscribers** - Event handlers for incoming messages
- **SCOOP Ready** - Thread-safe concurrent design

## Installation

1. Set environment variable:
```bash
export SIMPLE_MQ=/path/to/simple_mq
```

2. Add to ECF:
```xml
<library name="simple_mq" location="$SIMPLE_MQ/simple_mq.ecf"/>
```

## Dependencies

- simple_json - Message serialization
- simple_uuid - Message IDs
- simple_datetime - Timestamps
- simple_cache - Queue storage

## License

MIT License
