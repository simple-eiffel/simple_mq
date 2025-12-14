note
	description: "[
		Message container for message queue operations.

		A message consists of:
		- id: Unique identifier (auto-generated or assigned)
		- payload: The message content (string)
		- headers: Optional key-value metadata
		- timestamp: When the message was created
		- priority: Optional priority level (higher = more important)

		Usage:
			msg := create {SIMPLE_MQ_MESSAGE}.make ("Hello, World!")
			msg.set_header ("content-type", "text/plain")
			msg.set_priority (10)
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_MQ_MESSAGE

create
	make,
	make_with_id

feature {NONE} -- Initialization

	make (a_payload: READABLE_STRING_8)
			-- Create message with payload and auto-generated ID.
		do
			id := generate_id
			payload := a_payload.to_string_8
			create headers.make (4)
			timestamp := current_timestamp
			priority := 0
		ensure
			id_set: not id.is_empty
			payload_set: payload.same_string (a_payload)
			headers_empty: headers.is_empty
		end

	make_with_id (a_id: READABLE_STRING_8; a_payload: READABLE_STRING_8)
			-- Create message with specific ID and payload.
		require
			id_not_empty: not a_id.is_empty
		do
			id := a_id.to_string_8
			payload := a_payload.to_string_8
			create headers.make (4)
			timestamp := current_timestamp
			priority := 0
		ensure
			id_set: id.same_string (a_id)
			payload_set: payload.same_string (a_payload)
		end

feature -- Access

	id: STRING_8
			-- Unique message identifier.

	payload: STRING_8
			-- Message content.

	headers: HASH_TABLE [STRING_8, STRING_8]
			-- Optional message metadata.

	timestamp: INTEGER_64
			-- Unix timestamp when message was created.

	priority: INTEGER
			-- Message priority (higher = more important, 0 = default).

feature -- Header Access

	header (a_key: READABLE_STRING_8): detachable STRING_8
			-- Get header value by key.
		require
			key_not_empty: not a_key.is_empty
		do
			Result := headers.item (a_key.to_string_8)
		end

	has_header (a_key: READABLE_STRING_8): BOOLEAN
			-- Does message have this header?
		require
			key_not_empty: not a_key.is_empty
		do
			Result := headers.has (a_key.to_string_8)
		end

feature -- Modification

	set_payload (a_payload: READABLE_STRING_8)
			-- Update message payload.
		do
			payload := a_payload.to_string_8
		ensure
			payload_set: payload.same_string (a_payload)
		end

	set_header (a_key, a_value: READABLE_STRING_8)
			-- Set a header value.
		require
			key_not_empty: not a_key.is_empty
		do
			headers.force (a_value.to_string_8, a_key.to_string_8)
		ensure
			header_set: attached headers.item (a_key.to_string_8) as v and then v.same_string (a_value)
		end

	remove_header (a_key: READABLE_STRING_8)
			-- Remove a header.
		require
			key_not_empty: not a_key.is_empty
		do
			headers.remove (a_key.to_string_8)
		ensure
			header_removed: not headers.has (a_key.to_string_8)
		end

	set_priority (a_priority: INTEGER)
			-- Set message priority.
		do
			priority := a_priority
		ensure
			priority_set: priority = a_priority
		end

	set_timestamp (a_timestamp: INTEGER_64)
			-- Set message timestamp.
		require
			positive_timestamp: a_timestamp > 0
		do
			timestamp := a_timestamp
		ensure
			timestamp_set: timestamp = a_timestamp
		end

feature -- Serialization

	to_json: STRING_8
			-- Serialize message to JSON.
		local
			l_json: STRING_8
			l_first: BOOLEAN
		do
			create l_json.make (100)
			l_json.append ("{%"id%":%"")
			l_json.append (escaped_json (id))
			l_json.append ("%",%"payload%":%"")
			l_json.append (escaped_json (payload))
			l_json.append ("%",%"timestamp%":")
			l_json.append (timestamp.out)
			l_json.append (",%"priority%":")
			l_json.append_integer (priority)
			if not headers.is_empty then
				l_json.append (",%"headers%":{")
				l_first := True
				from headers.start until headers.after loop
					if not l_first then
						l_json.append (",")
					end
					l_first := False
					l_json.append ("%"")
					l_json.append (escaped_json (headers.key_for_iteration))
					l_json.append ("%":%"")
					l_json.append (escaped_json (headers.item_for_iteration))
					l_json.append ("%"")
					headers.forth
				end
				l_json.append ("}")
			end
			l_json.append ("}")
			Result := l_json
		end

feature -- Comparison

	is_higher_priority_than (other: SIMPLE_MQ_MESSAGE): BOOLEAN
			-- Is this message higher priority than `other'?
		do
			Result := priority > other.priority
		end

	is_older_than (other: SIMPLE_MQ_MESSAGE): BOOLEAN
			-- Was this message created before `other'?
		do
			Result := timestamp < other.timestamp
		end

feature {NONE} -- Implementation

	generate_id: STRING_8
			-- Generate unique message ID.
		local
			l_uuid: SIMPLE_UUID
		do
			create l_uuid.make
			Result := l_uuid.new_v4_string
		end

	current_timestamp: INTEGER_64
			-- Current Unix timestamp in milliseconds.
		local
			l_dt: SIMPLE_DATE_TIME
		do
			create l_dt.make_now
			Result := l_dt.to_timestamp * 1000
		end

	escaped_json (s: READABLE_STRING_8): STRING_8
			-- Escape string for JSON.
		do
			create Result.make (s.count)
			across s as ic loop
				inspect ic
				when '"' then
					Result.append ("\%"")
				when '\' then
					Result.append ("\\")
				when '%N' then
					Result.append ("\n")
				when '%R' then
					Result.append ("\r")
				when '%T' then
					Result.append ("\t")
				else
					Result.append_character (ic)
				end
			end
		end

invariant
	id_not_empty: not id.is_empty
	headers_attached: headers /= Void

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
