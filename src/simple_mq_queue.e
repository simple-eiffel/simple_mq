note
	description: "[
		In-memory message queue with FIFO ordering.

		Provides basic queue operations:
		- enqueue: Add message to end of queue
		- dequeue: Remove and return message from front
		- peek: View front message without removing
		- Priority queue mode available

		Usage:
			queue := create {SIMPLE_MQ_QUEUE}.make ("my-queue")
			queue.enqueue (msg)
			if queue.has_messages then
				received := queue.dequeue
			end
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_MQ_QUEUE

create
	make,
	make_with_capacity,
	make_priority

feature {NONE} -- Initialization

	make (a_name: READABLE_STRING_8)
			-- Create queue with name.
		require
			name_not_empty: not a_name.is_empty
		do
			name := a_name.to_string_8
			create messages.make (100)
			max_size := 0  -- Unlimited
			is_priority_queue := False
		ensure
			name_set: name.same_string (a_name)
			empty: is_empty
			unlimited: max_size = 0
		end

	make_with_capacity (a_name: READABLE_STRING_8; a_max_size: INTEGER)
			-- Create queue with name and maximum capacity.
		require
			name_not_empty: not a_name.is_empty
			positive_size: a_max_size > 0
		do
			name := a_name.to_string_8
			create messages.make (a_max_size)
			max_size := a_max_size
			is_priority_queue := False
		ensure
			name_set: name.same_string (a_name)
			max_size_set: max_size = a_max_size
			empty: is_empty
		end

	make_priority (a_name: READABLE_STRING_8)
			-- Create priority queue (higher priority = dequeued first).
		require
			name_not_empty: not a_name.is_empty
		do
			name := a_name.to_string_8
			create messages.make (100)
			max_size := 0
			is_priority_queue := True
		ensure
			name_set: name.same_string (a_name)
			is_priority: is_priority_queue
			empty: is_empty
		end

feature -- Access

	name: STRING_8
			-- Queue name/identifier.

	max_size: INTEGER
			-- Maximum queue size (0 = unlimited).

	is_priority_queue: BOOLEAN
			-- Is this a priority queue?

	count: INTEGER
			-- Number of messages in queue.
		do
			Result := messages.count
		end

feature -- Status

	is_empty: BOOLEAN
			-- Is queue empty?
		do
			Result := messages.is_empty
		end

	has_messages: BOOLEAN
			-- Does queue have any messages?
		do
			Result := not messages.is_empty
		end

	is_full: BOOLEAN
			-- Is queue at maximum capacity?
		do
			Result := max_size > 0 and then messages.count >= max_size
		end

feature -- Query

	peek: detachable SIMPLE_MQ_MESSAGE
			-- View front message without removing.
		do
			if not messages.is_empty then
				if is_priority_queue then
					Result := highest_priority_message
				else
					Result := messages.first
				end
			end
		end

	peek_all: ARRAYED_LIST [SIMPLE_MQ_MESSAGE]
			-- View all messages without removing (in order).
		local
			i: INTEGER
		do
			create Result.make (messages.count)
			from i := 1 until i > messages.count loop
				Result.extend (messages.i_th (i))
				i := i + 1
			end
			if is_priority_queue then
				sort_by_priority (Result)
			end
		end

	find_by_id (a_id: READABLE_STRING_8): detachable SIMPLE_MQ_MESSAGE
			-- Find message by ID without removing.
		require
			id_not_empty: not a_id.is_empty
		local
			i: INTEGER
		do
			from i := 1 until i > messages.count or Result /= Void loop
				if messages.i_th (i).id.same_string (a_id) then
					Result := messages.i_th (i)
				end
				i := i + 1
			end
		end

feature -- Command: Enqueue

	enqueue (a_message: SIMPLE_MQ_MESSAGE)
			-- Add message to queue.
		require
			message_attached: a_message /= Void
			not_full: not is_full
		do
			messages.extend (a_message)
			total_enqueued := total_enqueued + 1
		ensure
			count_increased: count = old count + 1
			message_in_queue: has_message (a_message.id)
		end

	enqueue_with_priority (a_message: SIMPLE_MQ_MESSAGE; a_priority: INTEGER)
			-- Add message with specific priority.
		require
			message_attached: a_message /= Void
			not_full: not is_full
		do
			a_message.set_priority (a_priority)
			enqueue (a_message)
		ensure
			count_increased: count = old count + 1
			priority_set: a_message.priority = a_priority
		end

feature -- Command: Dequeue

	dequeue: detachable SIMPLE_MQ_MESSAGE
			-- Remove and return front message (or highest priority).
		local
			l_index: INTEGER
		do
			if not messages.is_empty then
				if is_priority_queue then
					Result := highest_priority_message
					if attached Result as r then
						l_index := message_index (r.id)
						if l_index > 0 and then l_index <= messages.count then
							messages.go_i_th (l_index)
							messages.remove
						end
					end
				else
					Result := messages.first
					messages.start
					messages.remove
				end
				total_dequeued := total_dequeued + 1
			end
		ensure
			count_decreased: Result /= Void implies count = old count - 1
		end

	dequeue_batch (a_count: INTEGER): ARRAYED_LIST [SIMPLE_MQ_MESSAGE]
			-- Remove and return up to `a_count' messages.
		require
			positive_count: a_count > 0
		local
			i: INTEGER
			l_msg: detachable SIMPLE_MQ_MESSAGE
		do
			create Result.make (a_count.min (count))
			from i := 1 until i > a_count or is_empty loop
				l_msg := dequeue
				if attached l_msg as m then
					Result.extend (m)
				end
				i := i + 1
			end
		ensure
			max_count: Result.count <= a_count
			max_available: Result.count <= old count
		end

feature -- Command: Remove

	remove_by_id (a_id: READABLE_STRING_8): BOOLEAN
			-- Remove message by ID. Returns True if found and removed.
		require
			id_not_empty: not a_id.is_empty
		local
			l_index: INTEGER
		do
			l_index := message_index (a_id)
			if l_index > 0 then
				messages.go_i_th (l_index)
				messages.remove
				Result := True
			end
		ensure
			removed: Result implies not has_message (a_id)
		end

	clear
			-- Remove all messages from queue.
		do
			messages.wipe_out
		ensure
			empty: is_empty
		end

feature -- Query: Contains

	has_message (a_id: READABLE_STRING_8): BOOLEAN
			-- Does queue contain message with this ID?
		require
			id_not_empty: not a_id.is_empty
		do
			Result := message_index (a_id) > 0
		end

feature -- Statistics

	total_enqueued: INTEGER_64
			-- Total messages ever enqueued.

	total_dequeued: INTEGER_64
			-- Total messages ever dequeued.

	pending_count: INTEGER
			-- Alias for `count'.
		do
			Result := count
		end

feature {NONE} -- Implementation

	messages: ARRAYED_LIST [SIMPLE_MQ_MESSAGE]
			-- Internal message storage.

	message_index (a_id: READABLE_STRING_8): INTEGER
			-- Index of message with ID, or 0 if not found.
		local
			i: INTEGER
		do
			from i := 1 until i > messages.count or Result > 0 loop
				if messages.i_th (i).id.same_string (a_id) then
					Result := i
				end
				i := i + 1
			end
		end

	highest_priority_message: detachable SIMPLE_MQ_MESSAGE
			-- Message with highest priority (ties broken by timestamp).
		local
			l_best: detachable SIMPLE_MQ_MESSAGE
			l_msg: SIMPLE_MQ_MESSAGE
			i: INTEGER
		do
			from i := 1 until i > messages.count loop
				l_msg := messages.i_th (i)
				if not attached l_best then
					l_best := l_msg
				elseif l_msg.priority > l_best.priority then
					l_best := l_msg
				elseif l_msg.priority = l_best.priority and then l_msg.timestamp < l_best.timestamp then
					l_best := l_msg
				end
				i := i + 1
			end
			Result := l_best
		end

	sort_by_priority (a_list: ARRAYED_LIST [SIMPLE_MQ_MESSAGE])
			-- Sort list by priority (descending) then timestamp (ascending).
		local
			i, j: INTEGER
			l_temp: SIMPLE_MQ_MESSAGE
		do
			-- Simple insertion sort
			from i := 2 until i > a_list.count loop
				l_temp := a_list.i_th (i)
				j := i - 1
				from until j < 1 or else not should_come_before (l_temp, a_list.i_th (j)) loop
					a_list.put_i_th (a_list.i_th (j), j + 1)
					j := j - 1
				end
				a_list.put_i_th (l_temp, j + 1)
				i := i + 1
			end
		end

	should_come_before (a, b: SIMPLE_MQ_MESSAGE): BOOLEAN
			-- Should `a' come before `b' in priority order?
		do
			if a.priority > b.priority then
				Result := True
			elseif a.priority = b.priority then
				Result := a.timestamp < b.timestamp
			end
		end

invariant
	name_not_empty: not name.is_empty
	messages_attached: messages /= Void
	count_non_negative: count >= 0
	max_size_non_negative: max_size >= 0

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
