note
	description: "[
		Zero-configuration message queue facade for beginners.

		One-liner pub/sub and queue operations.
		For full control, use SIMPLE_MQ directly.

		Quick Start Examples:
			create mq.make

			-- Simple queue operations
			mq.send ("tasks", "Process order #123")
			message := mq.receive ("tasks")

			-- Check queue status
			if mq.has_messages ("tasks") then
				print ("Pending tasks: " + mq.queue_size ("tasks").out)
			end
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_MQ_QUICK

create
	make

feature {NONE} -- Initialization

	make
			-- Create quick message queue facade.
		do
			create mq.make
			create queues.make (10)
			create topics.make (10)
		ensure
			mq_exists: mq /= Void
		end

feature -- Queue Operations (Point-to-Point)

	send (a_queue_name: STRING; a_message: STRING)
			-- Send message to queue.
			-- Creates queue if it doesn't exist.
		require
			queue_name_not_empty: not a_queue_name.is_empty
			message_not_empty: not a_message.is_empty
		local
			l_queue: SIMPLE_MQ_QUEUE
			l_msg: SIMPLE_MQ_MESSAGE
		do
			l_queue := get_or_create_queue (a_queue_name)
			l_msg := mq.new_message (a_message)
			l_queue.enqueue (l_msg)
		end

	receive (a_queue_name: STRING): detachable STRING
			-- Receive message from queue.
			-- Returns Void if queue is empty.
		require
			queue_name_not_empty: not a_queue_name.is_empty
		local
			l_queue: SIMPLE_MQ_QUEUE
			l_msg: detachable SIMPLE_MQ_MESSAGE
		do
			l_queue := get_or_create_queue (a_queue_name)
			l_msg := l_queue.dequeue
			if attached l_msg as m then
				Result := m.payload
			end
		end

	peek (a_queue_name: STRING): detachable STRING
			-- Look at next message without removing it.
		require
			queue_name_not_empty: not a_queue_name.is_empty
		local
			l_queue: SIMPLE_MQ_QUEUE
			l_msg: detachable SIMPLE_MQ_MESSAGE
		do
			l_queue := get_or_create_queue (a_queue_name)
			l_msg := l_queue.peek
			if attached l_msg as m then
				Result := m.payload
			end
		end

feature -- Queue Status

	has_messages (a_queue_name: STRING): BOOLEAN
			-- Does queue have pending messages?
		require
			queue_name_not_empty: not a_queue_name.is_empty
		do
			Result := queue_size (a_queue_name) > 0
		end

	queue_size (a_queue_name: STRING): INTEGER
			-- Number of messages in queue.
		require
			queue_name_not_empty: not a_queue_name.is_empty
		local
			l_queue: SIMPLE_MQ_QUEUE
		do
			l_queue := get_or_create_queue (a_queue_name)
			Result := l_queue.count
		ensure
			non_negative: Result >= 0
		end

	clear_queue (a_queue_name: STRING)
			-- Remove all messages from queue.
		require
			queue_name_not_empty: not a_queue_name.is_empty
		local
			l_queue: SIMPLE_MQ_QUEUE
		do
			l_queue := get_or_create_queue (a_queue_name)
			l_queue.clear
		ensure
			empty: queue_size (a_queue_name) = 0
		end

feature -- Pub/Sub Operations

	publish (a_topic: STRING; a_message: STRING)
			-- Publish message to topic.
			-- All subscribers receive the message.
		require
			topic_not_empty: not a_topic.is_empty
			message_not_empty: not a_message.is_empty
		local
			l_topic: SIMPLE_MQ_TOPIC
			l_msg: SIMPLE_MQ_MESSAGE
		do
			l_topic := get_or_create_topic (a_topic)
			l_msg := mq.new_message (a_message)
			l_topic.publish (l_msg)
		end

feature -- Batch Operations

	send_all (a_queue_name: STRING; a_messages: ARRAY [STRING])
			-- Send multiple messages to queue.
		require
			queue_name_not_empty: not a_queue_name.is_empty
			has_messages: a_messages.count > 0
		do
			across a_messages as msg loop
				send (a_queue_name, msg)
			end
		end

	receive_all (a_queue_name: STRING; a_max: INTEGER): ARRAYED_LIST [STRING]
			-- Receive up to max messages from queue.
		require
			queue_name_not_empty: not a_queue_name.is_empty
			positive_max: a_max > 0
		local
			l_msg: detachable STRING
			l_count: INTEGER
		do
			create Result.make (a_max)
			from
				l_count := 0
				l_msg := receive (a_queue_name)
			until
				l_msg = Void or l_count >= a_max
			loop
				Result.extend (l_msg)
				l_count := l_count + 1
				l_msg := receive (a_queue_name)
			end
		ensure
			result_exists: Result /= Void
			max_respected: Result.count <= a_max
		end

feature -- Advanced Access

	mq: SIMPLE_MQ
			-- Access underlying MQ for advanced operations.

feature {NONE} -- Implementation

	queues: STRING_TABLE [SIMPLE_MQ_QUEUE]
			-- Cached queues by name.

	topics: STRING_TABLE [SIMPLE_MQ_TOPIC]
			-- Cached topics by name.

	get_or_create_queue (a_name: STRING): SIMPLE_MQ_QUEUE
			-- Get existing queue or create new one.
		do
			if attached queues.item (a_name) as q then
				Result := q
			else
				Result := mq.new_queue (a_name)
				queues.put (Result, a_name)
			end
		ensure
			result_exists: Result /= Void
		end

	get_or_create_topic (a_name: STRING): SIMPLE_MQ_TOPIC
			-- Get existing topic or create new one.
		do
			if attached topics.item (a_name) as t then
				Result := t
			else
				Result := mq.new_topic (a_name)
				topics.put (Result, a_name)
			end
		ensure
			result_exists: Result /= Void
		end

invariant
	mq_exists: mq /= Void
	queues_exists: queues /= Void
	topics_exists: topics /= Void

end
