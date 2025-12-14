note
	description: "[
		Message Queue facade - factory for queues, topics, and messages.

		Provides a unified API for message queue operations:
		- In-memory queues for single-process use
		- Redis-backed queues for distributed/persistent use
		- Pub/Sub topics for broadcast messaging

		Usage:
			mq := create {SIMPLE_MQ}.make

			-- Create messages
			msg := mq.new_message ("Hello, World!")
			msg.set_header ("type", "greeting")

			-- In-memory queue
			queue := mq.new_queue ("tasks")
			queue.enqueue (msg)

			-- Pub/Sub
			topic := mq.new_topic ("events.user.created")
			topic.subscribe (handler)
			topic.publish (msg)

			-- Redis-backed (distributed)
			redis_queue := mq.new_redis_queue ("jobs", redis)
			redis_queue.enqueue (msg)
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_MQ

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize message queue facade.
		do
			create queues.make (10)
			create topics.make (10)
		end

feature -- Message Factory

	new_message (a_payload: READABLE_STRING_8): SIMPLE_MQ_MESSAGE
			-- Create new message with payload.
		require
			payload_not_void: a_payload /= Void
		do
			create Result.make (a_payload)
		ensure
			message_created: Result /= Void
			payload_set: Result.payload.same_string (a_payload)
		end

	new_message_with_id (a_id, a_payload: READABLE_STRING_8): SIMPLE_MQ_MESSAGE
			-- Create new message with specific ID.
		require
			id_not_empty: not a_id.is_empty
		do
			create Result.make_with_id (a_id, a_payload)
		ensure
			message_created: Result /= Void
			id_set: Result.id.same_string (a_id)
		end

feature -- Queue Factory (In-Memory)

	new_queue (a_name: READABLE_STRING_8): SIMPLE_MQ_QUEUE
			-- Create new in-memory queue.
		require
			name_not_empty: not a_name.is_empty
		do
			create Result.make (a_name)
		ensure
			queue_created: Result /= Void
			empty: Result.is_empty
		end

	new_queue_with_capacity (a_name: READABLE_STRING_8; a_max_size: INTEGER): SIMPLE_MQ_QUEUE
			-- Create new in-memory queue with maximum capacity.
		require
			name_not_empty: not a_name.is_empty
			positive_size: a_max_size > 0
		do
			create Result.make_with_capacity (a_name, a_max_size)
		ensure
			queue_created: Result /= Void
			max_size_set: Result.max_size = a_max_size
		end

	new_priority_queue (a_name: READABLE_STRING_8): SIMPLE_MQ_QUEUE
			-- Create new priority queue (higher priority dequeued first).
		require
			name_not_empty: not a_name.is_empty
		do
			create Result.make_priority (a_name)
		ensure
			queue_created: Result /= Void
			is_priority: Result.is_priority_queue
		end

feature -- Topic Factory (Pub/Sub)

	new_topic (a_name: READABLE_STRING_8): SIMPLE_MQ_TOPIC
			-- Create new pub/sub topic.
		require
			name_not_empty: not a_name.is_empty
		do
			create Result.make (a_name)
		ensure
			topic_created: Result /= Void
			no_subscribers: Result.subscriber_count = 0
		end

	new_topic_with_history (a_name: READABLE_STRING_8; a_history_size: INTEGER): SIMPLE_MQ_TOPIC
			-- Create topic with message history retention.
		require
			name_not_empty: not a_name.is_empty
			positive_history: a_history_size > 0
		do
			create Result.make_with_history (a_name, a_history_size)
		ensure
			topic_created: Result /= Void
			history_enabled: Result.history_size = a_history_size
		end

feature -- Redis Queue Factory (Distributed)

	new_redis_queue (a_name: READABLE_STRING_8; a_redis: SIMPLE_REDIS): SIMPLE_MQ_REDIS_QUEUE
			-- Create Redis-backed queue.
		require
			name_not_empty: not a_name.is_empty
			redis_attached: a_redis /= Void
		do
			create Result.make (a_name, a_redis)
		ensure
			queue_created: Result /= Void
		end

	new_redis_queue_blocking (a_name: READABLE_STRING_8; a_redis: SIMPLE_REDIS; a_timeout: INTEGER): SIMPLE_MQ_REDIS_QUEUE
			-- Create Redis-backed queue with blocking dequeue.
		require
			name_not_empty: not a_name.is_empty
			redis_attached: a_redis /= Void
			positive_timeout: a_timeout > 0
		do
			create Result.make_with_timeout (a_name, a_redis, a_timeout)
		ensure
			queue_created: Result /= Void
			timeout_set: Result.blocking_timeout = a_timeout
		end

feature -- Named Queue/Topic Registry

	register_queue (a_queue: SIMPLE_MQ_QUEUE)
			-- Register queue for lookup by name.
		require
			queue_attached: a_queue /= Void
		do
			queues.force (a_queue, a_queue.name)
		ensure
			registered: queues.has (a_queue.name)
		end

	queue (a_name: READABLE_STRING_8): detachable SIMPLE_MQ_QUEUE
			-- Get registered queue by name.
		require
			name_not_empty: not a_name.is_empty
		do
			Result := queues.item (a_name.to_string_8)
		end

	register_topic (a_topic: SIMPLE_MQ_TOPIC)
			-- Register topic for lookup by name.
		require
			topic_attached: a_topic /= Void
		do
			topics.force (a_topic, a_topic.name)
		ensure
			registered: topics.has (a_topic.name)
		end

	topic (a_name: READABLE_STRING_8): detachable SIMPLE_MQ_TOPIC
			-- Get registered topic by name.
		require
			name_not_empty: not a_name.is_empty
		do
			Result := topics.item (a_name.to_string_8)
		end

	topics_matching (a_pattern: READABLE_STRING_8): ARRAYED_LIST [SIMPLE_MQ_TOPIC]
			-- Get all registered topics matching pattern.
			-- Supports wildcards: * (single level), # (multi-level)
		require
			pattern_not_empty: not a_pattern.is_empty
		do
			create Result.make (5)
			across topics as ic loop
				if ic.matches_pattern (a_pattern) then
					Result.extend (ic)
				end
			end
		end

feature -- Convenience: Quick Send

	send (a_queue_name, a_payload: READABLE_STRING_8)
			-- Quick send: create message and enqueue to named queue.
		require
			queue_name_not_empty: not a_queue_name.is_empty
			queue_registered: queue (a_queue_name) /= Void
		local
			l_msg: SIMPLE_MQ_MESSAGE
		do
			if attached queue (a_queue_name) as q then
				create l_msg.make (a_payload)
				q.enqueue (l_msg)
			end
		end

	publish (a_topic_name, a_payload: READABLE_STRING_8)
			-- Quick publish: create message and publish to named topic.
		require
			topic_name_not_empty: not a_topic_name.is_empty
			topic_registered: topic (a_topic_name) /= Void
		local
			l_msg: SIMPLE_MQ_MESSAGE
		do
			if attached topic (a_topic_name) as t then
				create l_msg.make (a_payload)
				t.publish (l_msg)
			end
		end

	receive (a_queue_name: READABLE_STRING_8): detachable SIMPLE_MQ_MESSAGE
			-- Quick receive: dequeue from named queue.
		require
			queue_name_not_empty: not a_queue_name.is_empty
			queue_registered: queue (a_queue_name) /= Void
		do
			if attached queue (a_queue_name) as q then
				Result := q.dequeue
			end
		end

feature -- Statistics

	registered_queue_count: INTEGER
			-- Number of registered queues.
		do
			Result := queues.count
		end

	registered_topic_count: INTEGER
			-- Number of registered topics.
		do
			Result := topics.count
		end

feature {NONE} -- Implementation

	queues: HASH_TABLE [SIMPLE_MQ_QUEUE, STRING_8]
			-- Registered queues by name.

	topics: HASH_TABLE [SIMPLE_MQ_TOPIC, STRING_8]
			-- Registered topics by name.

invariant
	queues_attached: queues /= Void
	topics_attached: topics /= Void

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
