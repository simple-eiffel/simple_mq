# S03-CONTRACTS.md
## simple_mq - Contract Specifications

**Generation Type:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23

---

## SIMPLE_MQ Contracts

### new_message
```eiffel
new_message (a_payload: READABLE_STRING_8): SIMPLE_MQ_MESSAGE
    require
        payload_not_void: a_payload /= Void
    ensure
        message_created: Result /= Void
        payload_set: Result.payload.same_string (a_payload)
```

### new_message_with_id
```eiffel
new_message_with_id (a_id, a_payload: READABLE_STRING_8): SIMPLE_MQ_MESSAGE
    require
        id_not_empty: not a_id.is_empty
    ensure
        message_created: Result /= Void
        id_set: Result.id.same_string (a_id)
```

### new_queue
```eiffel
new_queue (a_name: READABLE_STRING_8): SIMPLE_MQ_QUEUE
    require
        name_not_empty: not a_name.is_empty
    ensure
        queue_created: Result /= Void
        empty: Result.is_empty
```

### new_queue_with_capacity
```eiffel
new_queue_with_capacity (a_name: READABLE_STRING_8; a_max_size: INTEGER): SIMPLE_MQ_QUEUE
    require
        name_not_empty: not a_name.is_empty
        positive_size: a_max_size > 0
    ensure
        queue_created: Result /= Void
        max_size_set: Result.max_size = a_max_size
```

### new_priority_queue
```eiffel
new_priority_queue (a_name: READABLE_STRING_8): SIMPLE_MQ_QUEUE
    require
        name_not_empty: not a_name.is_empty
    ensure
        queue_created: Result /= Void
        is_priority: Result.is_priority_queue
```

### send
```eiffel
send (a_queue_name, a_payload: READABLE_STRING_8)
    require
        queue_name_not_empty: not a_queue_name.is_empty
        queue_registered: queue (a_queue_name) /= Void
```

### receive
```eiffel
receive (a_queue_name: READABLE_STRING_8): detachable SIMPLE_MQ_MESSAGE
    require
        queue_name_not_empty: not a_queue_name.is_empty
        queue_registered: queue (a_queue_name) /= Void
```

---

## SIMPLE_MQ_MESSAGE Contracts

### make
```eiffel
make (a_payload: READABLE_STRING_8)
    ensure
        id_set: not id.is_empty
        payload_set: payload.same_string (a_payload)
        headers_empty: headers.is_empty
```

### make_with_id
```eiffel
make_with_id (a_id: READABLE_STRING_8; a_payload: READABLE_STRING_8)
    require
        id_not_empty: not a_id.is_empty
    ensure
        id_set: id.same_string (a_id)
        payload_set: payload.same_string (a_payload)
```

### set_header
```eiffel
set_header (a_key, a_value: READABLE_STRING_8)
    require
        key_not_empty: not a_key.is_empty
    ensure
        header_set: attached headers.item (a_key.to_string_8) as v and then v.same_string (a_value)
```

### set_timestamp
```eiffel
set_timestamp (a_timestamp: INTEGER_64)
    require
        positive_timestamp: a_timestamp > 0
    ensure
        timestamp_set: timestamp = a_timestamp
```

### Class Invariant
```eiffel
invariant
    id_not_empty: not id.is_empty
    headers_attached: headers /= Void
```

---

## SIMPLE_MQ_QUEUE Contracts

### make
```eiffel
make (a_name: READABLE_STRING_8)
    require
        name_not_empty: not a_name.is_empty
    ensure
        name_set: name.same_string (a_name)
        empty: is_empty
        unlimited: max_size = 0
```

### make_with_capacity
```eiffel
make_with_capacity (a_name: READABLE_STRING_8; a_max_size: INTEGER)
    require
        name_not_empty: not a_name.is_empty
        positive_size: a_max_size > 0
    ensure
        name_set: name.same_string (a_name)
        max_size_set: max_size = a_max_size
        empty: is_empty
```

### enqueue
```eiffel
enqueue (a_message: SIMPLE_MQ_MESSAGE)
    require
        message_attached: a_message /= Void
        not_full: not is_full
    ensure
        count_increased: count = old count + 1
        message_in_queue: has_message (a_message.id)
```

### dequeue
```eiffel
dequeue: detachable SIMPLE_MQ_MESSAGE
    ensure
        count_decreased: Result /= Void implies count = old count - 1
```

### dequeue_batch
```eiffel
dequeue_batch (a_count: INTEGER): ARRAYED_LIST [SIMPLE_MQ_MESSAGE]
    require
        positive_count: a_count > 0
    ensure
        max_count: Result.count <= a_count
        max_available: Result.count <= old count
```

### remove_by_id
```eiffel
remove_by_id (a_id: READABLE_STRING_8): BOOLEAN
    require
        id_not_empty: not a_id.is_empty
    ensure
        removed: Result implies not has_message (a_id)
```

### Class Invariant
```eiffel
invariant
    name_not_empty: not name.is_empty
    messages_attached: messages /= Void
    count_non_negative: count >= 0
    max_size_non_negative: max_size >= 0
```

---

## SIMPLE_MQ_TOPIC Contracts

### make
```eiffel
make (a_name: READABLE_STRING_8)
    require
        name_not_empty: not a_name.is_empty
    ensure
        name_set: name.same_string (a_name)
        no_subscribers: subscriber_count = 0
        no_history: history_size = 0
```

### make_with_history
```eiffel
make_with_history (a_name: READABLE_STRING_8; a_history_size: INTEGER)
    require
        name_not_empty: not a_name.is_empty
        positive_history: a_history_size > 0
    ensure
        name_set: name.same_string (a_name)
        history_size_set: history_size = a_history_size
```

### subscribe
```eiffel
subscribe (a_subscriber: SIMPLE_MQ_SUBSCRIBER)
    require
        subscriber_attached: a_subscriber /= Void
        not_already_subscribed: not is_subscribed (a_subscriber)
    ensure
        subscribed: is_subscribed (a_subscriber)
        count_increased: subscriber_count = old subscriber_count + 1
```

### publish
```eiffel
publish (a_message: SIMPLE_MQ_MESSAGE)
    require
        message_attached: a_message /= Void
    ensure
        published_count_increased: total_published = old total_published + 1
```

### get_history
```eiffel
get_history: ARRAYED_LIST [SIMPLE_MQ_MESSAGE]
    ensure
        max_size: Result.count <= history_size
```

### Class Invariant
```eiffel
invariant
    name_not_empty: not name.is_empty
    subscribers_attached: subscribers /= Void
    history_attached: history /= Void
    history_size_non_negative: history_size >= 0
```
