# Drift Analysis: simple_mq

Generated: 2026-01-24
Method: `ec.exe -flatshort` vs `specs/*.md` + `research/*.md`

## Specification Sources

| Source | Files | Lines |
|--------|-------|-------|
| specs/*.md | 8 | 1068 |
| research/*.md | 1 | 476 |

## Classes Analyzed

| Class | Spec'd Features | Actual Features | Drift |
|-------|-----------------|-----------------|-------|
| SIMPLE_MQ | 52 | 41 | -11 |

## Feature-Level Drift

### Specified, Implemented ✓
- `new_message` ✓
- `new_message_with_id` ✓
- `new_priority_queue` ✓
- `new_queue` ✓
- `new_queue_with_capacity` ✓
- `new_redis_queue` ✓
- `new_redis_queue_blocking` ✓
- `new_topic` ✓
- `new_topic_with_history` ✓
- `register_queue` ✓
- ... and 2 more

### Specified, NOT Implemented ✗
- `blocking_timeout` ✗
- `clear_history` ✗
- `dequeue_batch` ✗
- `enqueue_with_priority` ✗
- `find_by_id` ✗
- `get_history` ✗
- `get_history_since` ✗
- `has_header` ✗
- `has_message` ✗
- `has_messages` ✗
- ... and 30 more

### Implemented, NOT Specified
- `Io`
- `Operating_environment`
- `author`
- `conforms_to`
- `copy`
- `copyright`
- `date`
- `default_rescue`
- `description`
- `generating_type`
- ... and 19 more

## Summary

| Category | Count |
|----------|-------|
| Spec'd, implemented | 12 |
| Spec'd, missing | 40 |
| Implemented, not spec'd | 29 |
| **Overall Drift** | **HIGH** |

## Conclusion

**simple_mq** has high drift. Significant gaps between spec and implementation.
