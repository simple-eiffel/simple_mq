note
	description: "[
		Pub/Sub topic for broadcast messaging.

		A topic allows multiple subscribers to receive copies of
		published messages. Unlike queues, messages are delivered
		to ALL subscribers (fan-out pattern).

		Features:
		- Subscribe/unsubscribe handlers
		- Publish broadcasts to all subscribers
		- Message history with configurable retention
		- Wildcard topic matching (optional)

		Usage:
			topic := create {SIMPLE_MQ_TOPIC}.make ("events.user.created")
			topic.subscribe (my_handler)
			topic.publish (msg)  -- Delivered to all subscribers
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_MQ_TOPIC

create
	make,
	make_with_history

feature {NONE} -- Initialization

	make (a_name: READABLE_STRING_8)
			-- Create topic with name.
		require
			name_not_empty: not a_name.is_empty
		do
			name := a_name.to_string_8
			create subscribers.make (10)
			create history.make (0)
			history_size := 0  -- No history by default
		ensure
			name_set: name.same_string (a_name)
			no_subscribers: subscriber_count = 0
			no_history: history_size = 0
		end

	make_with_history (a_name: READABLE_STRING_8; a_history_size: INTEGER)
			-- Create topic with message history retention.
		require
			name_not_empty: not a_name.is_empty
			positive_history: a_history_size > 0
		do
			name := a_name.to_string_8
			create subscribers.make (10)
			create history.make (a_history_size)
			history_size := a_history_size
		ensure
			name_set: name.same_string (a_name)
			history_size_set: history_size = a_history_size
		end

feature -- Access

	name: STRING_8
			-- Topic name (can use dot notation like "events.user.created").

	subscriber_count: INTEGER
			-- Number of active subscribers.
		do
			Result := subscribers.count
		end

	history_size: INTEGER
			-- Number of messages to retain in history (0 = none).

feature -- Status

	has_subscribers: BOOLEAN
			-- Does this topic have any subscribers?
		do
			Result := not subscribers.is_empty
		end

	is_subscribed (a_subscriber: SIMPLE_MQ_SUBSCRIBER): BOOLEAN
			-- Is this subscriber registered?
		do
			Result := subscribers.has (a_subscriber.subscriber_id)
		end

feature -- Subscription

	subscribe (a_subscriber: SIMPLE_MQ_SUBSCRIBER)
			-- Add subscriber to receive messages.
		require
			subscriber_attached: a_subscriber /= Void
			not_already_subscribed: not is_subscribed (a_subscriber)
		do
			subscribers.put (a_subscriber, a_subscriber.subscriber_id)
		ensure
			subscribed: is_subscribed (a_subscriber)
			count_increased: subscriber_count = old subscriber_count + 1
		end

	unsubscribe (a_subscriber: SIMPLE_MQ_SUBSCRIBER)
			-- Remove subscriber from receiving messages.
		require
			subscriber_attached: a_subscriber /= Void
		do
			subscribers.remove (a_subscriber.subscriber_id)
		ensure
			not_subscribed: not is_subscribed (a_subscriber)
		end

	unsubscribe_all
			-- Remove all subscribers.
		do
			subscribers.wipe_out
		ensure
			no_subscribers: subscriber_count = 0
		end

feature -- Publishing

	publish (a_message: SIMPLE_MQ_MESSAGE)
			-- Publish message to all subscribers.
		require
			message_attached: a_message /= Void
		do
			-- Add to history if enabled
			if history_size > 0 then
				add_to_history (a_message)
			end

			-- Deliver to all subscribers
			across subscribers as ic loop
				ic.on_message (a_message)
			end

			total_published := total_published + 1
			total_delivered := total_delivered + subscribers.count
		ensure
			published_count_increased: total_published = old total_published + 1
		end

	publish_payload (a_payload: READABLE_STRING_8)
			-- Create and publish message with payload.
		require
			payload_not_empty: not a_payload.is_empty
		local
			l_msg: SIMPLE_MQ_MESSAGE
		do
			create l_msg.make (a_payload)
			publish (l_msg)
		end

feature -- History

	get_history: ARRAYED_LIST [SIMPLE_MQ_MESSAGE]
			-- Get retained message history (oldest first).
		do
			create Result.make (history.count)
			across history as ic loop
				Result.extend (ic)
			end
		ensure
			max_size: Result.count <= history_size
		end

	get_history_since (a_timestamp: INTEGER_64): ARRAYED_LIST [SIMPLE_MQ_MESSAGE]
			-- Get messages from history since timestamp.
		do
			create Result.make (history.count)
			across history as ic loop
				if ic.timestamp >= a_timestamp then
					Result.extend (ic)
				end
			end
		end

	clear_history
			-- Clear message history.
		do
			history.wipe_out
		ensure
			history_empty: history.is_empty
		end

feature -- Statistics

	total_published: INTEGER_64
			-- Total messages ever published.

	total_delivered: INTEGER_64
			-- Total message deliveries (published * subscribers at time).

feature -- Topic Matching

	matches_pattern (a_pattern: READABLE_STRING_8): BOOLEAN
			-- Does this topic name match the pattern?
			-- Supports wildcards: * (single level), # (multi-level)
			-- Example: "events.user.*" matches "events.user.created"
			-- Example: "events.#" matches "events.user.created.success"
		require
			pattern_not_empty: not a_pattern.is_empty
		local
			l_topic_parts, l_pattern_parts: LIST [READABLE_STRING_8]
			i: INTEGER
			l_match: BOOLEAN
		do
			if a_pattern.same_string (name) then
				Result := True
			elseif a_pattern.has ('#') or a_pattern.has ('*') then
				l_topic_parts := name.split ('.')
				l_pattern_parts := a_pattern.split ('.')
				l_match := True
				from i := 1 until i > l_pattern_parts.count or not l_match loop
					if l_pattern_parts.i_th (i).same_string ("#") then
						-- # matches everything remaining
						Result := True
						l_match := False  -- Exit loop
					elseif l_pattern_parts.i_th (i).same_string ("*") then
						-- * matches single level
						if i > l_topic_parts.count then
							l_match := False
						end
					elseif i > l_topic_parts.count then
						l_match := False
					elseif not l_pattern_parts.i_th (i).same_string (l_topic_parts.i_th (i)) then
						l_match := False
					end
					i := i + 1
				end
				if l_match and i > l_pattern_parts.count then
					Result := i > l_topic_parts.count
				end
			end
		end

feature {NONE} -- Implementation

	subscribers: HASH_TABLE [SIMPLE_MQ_SUBSCRIBER, STRING_8]
			-- Registered subscribers by ID.

	history: ARRAYED_LIST [SIMPLE_MQ_MESSAGE]
			-- Message history (if enabled).

	add_to_history (a_message: SIMPLE_MQ_MESSAGE)
			-- Add message to history, removing oldest if at capacity.
		do
			if history.count >= history_size then
				history.start
				history.remove
			end
			history.extend (a_message)
		ensure
			within_capacity: history.count <= history_size
		end

invariant
	name_not_empty: not name.is_empty
	subscribers_attached: subscribers /= Void
	history_attached: history /= Void
	history_size_non_negative: history_size >= 0

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
