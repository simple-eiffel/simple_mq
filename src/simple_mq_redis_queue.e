note
	description: "[
		Redis-backed message queue using Redis Lists.

		Provides persistent queue storage with Redis as backend.
		Uses LPUSH/RPOP for FIFO ordering (or LPUSH/LPOP for LIFO).

		Features:
		- Persistent storage survives process restarts
		- Distributed access from multiple processes
		- Blocking pop with timeout
		- Reliable queue with acknowledgment (optional)

		Usage:
			queue := create {SIMPLE_MQ_REDIS_QUEUE}.make ("tasks", redis)
			queue.enqueue (msg)
			received := queue.dequeue  -- Blocks until message available
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_MQ_REDIS_QUEUE

create
	make,
	make_with_timeout

feature {NONE} -- Initialization

	make (a_name: READABLE_STRING_8; a_redis: SIMPLE_REDIS)
			-- Create Redis queue with name.
		require
			name_not_empty: not a_name.is_empty
			redis_attached: a_redis /= Void
		do
			name := a_name.to_string_8
			key := "mq:" + name
			redis := a_redis
			blocking_timeout := 0  -- Non-blocking by default
		ensure
			name_set: name.same_string (a_name)
			redis_set: redis = a_redis
		end

	make_with_timeout (a_name: READABLE_STRING_8; a_redis: SIMPLE_REDIS; a_timeout_seconds: INTEGER)
			-- Create Redis queue with blocking timeout.
		require
			name_not_empty: not a_name.is_empty
			redis_attached: a_redis /= Void
			non_negative_timeout: a_timeout_seconds >= 0
		do
			name := a_name.to_string_8
			key := "mq:" + name
			redis := a_redis
			blocking_timeout := a_timeout_seconds
		ensure
			name_set: name.same_string (a_name)
			timeout_set: blocking_timeout = a_timeout_seconds
		end

feature -- Access

	name: STRING_8
			-- Queue name.

	key: STRING_8
			-- Redis key for this queue.

	redis: SIMPLE_REDIS
			-- Redis connection.

	blocking_timeout: INTEGER
			-- Timeout in seconds for blocking operations (0 = non-blocking).

feature -- Status

	is_connected: BOOLEAN
			-- Is Redis connection available?
		do
			Result := redis.is_connected
		end

	is_empty: BOOLEAN
			-- Is queue empty?
		do
			Result := count = 0
		end

	has_messages: BOOLEAN
			-- Does queue have any messages?
		do
			Result := count > 0
		end

	count: INTEGER
			-- Number of messages in queue (LLEN).
		require
			connected: is_connected
		do
			Result := redis.llen (key)
		end

feature -- Command: Enqueue

	enqueue (a_message: SIMPLE_MQ_MESSAGE)
			-- Add message to end of queue (RPUSH).
		require
			message_attached: a_message /= Void
			connected: is_connected
		local
			l_json: STRING_8
			l_result: INTEGER
		do
			l_json := a_message.to_json
			l_result := redis.rpush (key, l_json)
		ensure
			queue_not_empty: has_messages
		end

	enqueue_front (a_message: SIMPLE_MQ_MESSAGE)
			-- Add message to front of queue (LPUSH) - for priority/retry.
		require
			message_attached: a_message /= Void
			connected: is_connected
		local
			l_json: STRING_8
			l_result: INTEGER
		do
			l_json := a_message.to_json
			l_result := redis.lpush (key, l_json)
		end

feature -- Command: Dequeue

	dequeue: detachable SIMPLE_MQ_MESSAGE
			-- Remove and return message from front (LPOP).
		require
			connected: is_connected
		local
			l_response: detachable STRING
		do
			if blocking_timeout > 0 then
				l_response := redis.blpop (key, blocking_timeout)
			else
				l_response := redis.lpop (key)
			end
			if attached l_response as r and then not r.is_empty then
				Result := parse_message (r)
			end
		end

	peek: detachable SIMPLE_MQ_MESSAGE
			-- View front message without removing (LINDEX 0).
		require
			connected: is_connected
		local
			l_response: detachable STRING
		do
			l_response := redis.lindex (key, 0)
			if attached l_response as r and then not r.is_empty then
				Result := parse_message (r)
			end
		end

	dequeue_batch (a_count: INTEGER): ARRAYED_LIST [SIMPLE_MQ_MESSAGE]
			-- Remove and return up to `a_count' messages.
		require
			positive_count: a_count > 0
			connected: is_connected
		local
			i: INTEGER
			l_msg: detachable SIMPLE_MQ_MESSAGE
		do
			create Result.make (a_count)
			from i := 1 until i > a_count loop
				l_msg := dequeue
				if attached l_msg as m then
					Result.extend (m)
				else
					i := a_count + 1  -- Exit loop
				end
				i := i + 1
			end
		end

feature -- Command: Queue Management

	clear
			-- Remove all messages from queue (DEL).
		require
			connected: is_connected
		local
			l_result: BOOLEAN
		do
			l_result := redis.del (key)
		ensure
			empty: is_empty
		end

	trim (a_max_size: INTEGER)
			-- Keep only first `a_max_size' messages (LTRIM).
		require
			positive_size: a_max_size > 0
			connected: is_connected
		local
			l_result: BOOLEAN
		do
			l_result := redis.ltrim (key, 0, a_max_size - 1)
		ensure
			within_size: count <= a_max_size
		end

feature -- Command: Reliable Queue

	processing_key: STRING_8
			-- Key for processing queue (for reliable queue pattern).
		do
			Result := key + ":processing"
		end

	dequeue_reliable: detachable SIMPLE_MQ_MESSAGE
			-- Move message to processing queue atomically (RPOPLPUSH).
			-- Call `acknowledge' after successful processing.
		require
			connected: is_connected
		local
			l_response: detachable STRING
		do
			l_response := redis.rpoplpush (key, processing_key)
			if attached l_response as r and then not r.is_empty then
				Result := parse_message (r)
			end
		end

	acknowledge (a_message: SIMPLE_MQ_MESSAGE)
			-- Acknowledge message processing complete (remove from processing queue).
		require
			message_attached: a_message /= Void
			connected: is_connected
		local
			l_result: INTEGER
		do
			l_result := redis.lrem (processing_key, 1, a_message.to_json)
		end

	requeue_failed
			-- Move all messages from processing queue back to main queue.
			-- Use for recovering from crashed processors.
		require
			connected: is_connected
		local
			l_response: detachable STRING
		do
			from
				l_response := redis.rpoplpush (processing_key, key)
			until
				not attached l_response or else l_response.is_empty
			loop
				l_response := redis.rpoplpush (processing_key, key)
			end
		end

feature -- Settings

	set_blocking_timeout (a_seconds: INTEGER)
			-- Set blocking timeout for dequeue operations.
		require
			non_negative: a_seconds >= 0
		do
			blocking_timeout := a_seconds
		ensure
			timeout_set: blocking_timeout = a_seconds
		end

feature {NONE} -- Implementation

	parse_message (a_json: READABLE_STRING_8): detachable SIMPLE_MQ_MESSAGE
			-- Parse JSON string to message.
			-- Simplified parsing - assumes valid JSON from our format.
		local
			l_id, l_payload: STRING_8
			l_pos, l_end: INTEGER
		do
			-- Extract id
			l_pos := a_json.substring_index ("%"id%":%"", 1)
			if l_pos > 0 then
				l_pos := l_pos + 6
				l_end := a_json.index_of ('"', l_pos)
				if l_end > l_pos then
					l_id := a_json.substring (l_pos, l_end - 1).to_string_8
				end
			end
			-- Extract payload
			l_pos := a_json.substring_index ("%"payload%":%"", 1)
			if l_pos > 0 then
				l_pos := l_pos + 11
				l_end := find_string_end (a_json, l_pos)
				if l_end > l_pos then
					l_payload := unescape_json (a_json.substring (l_pos, l_end - 1).to_string_8)
				end
			end
			if attached l_id and attached l_payload then
				create Result.make_with_id (l_id, l_payload)
			end
		end

	find_string_end (s: READABLE_STRING_8; start: INTEGER): INTEGER
			-- Find end of JSON string (unescaped quote).
		local
			i: INTEGER
			escaped: BOOLEAN
		do
			from i := start until i > s.count or (s.item (i) = '"' and not escaped) loop
				if s.item (i) = '\' then
					escaped := not escaped
				else
					escaped := False
				end
				i := i + 1
			end
			Result := i
		end

	unescape_json (s: READABLE_STRING_8): STRING_8
			-- Unescape JSON string.
		local
			i: INTEGER
		do
			create Result.make (s.count)
			from i := 1 until i > s.count loop
				if s.item (i) = '\' and i < s.count then
					inspect s.item (i + 1)
					when 'n' then
						Result.append_character ('%N')
					when 'r' then
						Result.append_character ('%R')
					when 't' then
						Result.append_character ('%T')
					when '"' then
						Result.append_character ('"')
					when '\' then
						Result.append_character ('\')
					else
						Result.append_character (s.item (i + 1))
					end
					i := i + 2
				else
					Result.append_character (s.item (i))
					i := i + 1
				end
			end
		end

invariant
	name_not_empty: not name.is_empty
	key_not_empty: not key.is_empty
	redis_attached: redis /= Void
	timeout_non_negative: blocking_timeout >= 0

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
