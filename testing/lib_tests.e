note
	description: "Tests for simple_mq"
	author: "Larry Rix"
	testing: "covers"
	testing: "execution/serial"

class
	LIB_TESTS

inherit
	TEST_SET_BASE

feature -- Test: Message

	test_message_make
			-- Test message creation.
		local
			msg: SIMPLE_MQ_MESSAGE
		do
			create msg.make ("Hello, World!")
			assert_false ("id not empty", msg.id.is_empty)
			assert_strings_equal ("payload", "Hello, World!", msg.payload)
			assert_true ("timestamp > 0", msg.timestamp > 0)
			assert_integers_equal ("priority", 0, msg.priority)
		end

	test_message_with_id
			-- Test message creation with ID.
		local
			msg: SIMPLE_MQ_MESSAGE
		do
			create msg.make_with_id ("msg-123", "Test payload")
			assert_strings_equal ("id", "msg-123", msg.id)
			assert_strings_equal ("payload", "Test payload", msg.payload)
		end

	test_message_headers
			-- Test message headers.
		local
			msg: SIMPLE_MQ_MESSAGE
		do
			create msg.make ("Test")
			msg.set_header ("content-type", "text/plain")
			msg.set_header ("priority", "high")
			assert_true ("has content-type", msg.has_header ("content-type"))
			if attached msg.header ("content-type") as h then
				assert_strings_equal ("content-type value", "text/plain", h)
			else
				assert_true ("header attached", False)
			end
			msg.remove_header ("content-type")
			assert_false ("no content-type", msg.has_header ("content-type"))
		end

	test_message_priority
			-- Test message priority.
		local
			msg: SIMPLE_MQ_MESSAGE
		do
			create msg.make ("Test")
			msg.set_priority (10)
			assert_integers_equal ("priority", 10, msg.priority)
		end

	test_message_to_json
			-- Test message JSON serialization.
		local
			msg: SIMPLE_MQ_MESSAGE
			json: STRING_8
		do
			create msg.make_with_id ("test-id", "Hello")
			json := msg.to_json
			assert_true ("has id", json.has_substring ("%"id%":%"test-id%""))
			assert_true ("has payload", json.has_substring ("%"payload%":%"Hello%""))
		end

feature -- Test: Queue (In-Memory)

	test_queue_make
			-- Test queue creation.
		local
			queue: SIMPLE_MQ_QUEUE
		do
			create queue.make ("test-queue")
			assert_strings_equal ("name", "test-queue", queue.name)
			assert_true ("empty", queue.is_empty)
			assert_integers_equal ("count", 0, queue.count)
		end

	test_queue_enqueue_dequeue
			-- Test basic enqueue and dequeue.
		local
			queue: SIMPLE_MQ_QUEUE
			msg1, msg2: SIMPLE_MQ_MESSAGE
		do
			create queue.make ("test")
			create msg1.make ("First")
			create msg2.make ("Second")
			queue.enqueue (msg1)
			queue.enqueue (msg2)
			assert_integers_equal ("count 2", 2, queue.count)
			if attached queue.dequeue as received then
				assert_strings_equal ("first out", "First", received.payload)
			else
				assert_true ("first dequeue", False)
			end
			if attached queue.dequeue as received then
				assert_strings_equal ("second out", "Second", received.payload)
			else
				assert_true ("second dequeue", False)
			end
			assert_true ("empty after", queue.is_empty)
		end

	test_queue_peek
			-- Test peek without removing.
		local
			queue: SIMPLE_MQ_QUEUE
			msg: SIMPLE_MQ_MESSAGE
		do
			create queue.make ("test")
			create msg.make ("Peek test")
			queue.enqueue (msg)
			if attached queue.peek as peeked then
				assert_strings_equal ("peeked payload", "Peek test", peeked.payload)
			else
				assert_true ("peek attached", False)
			end
			assert_integers_equal ("still 1", 1, queue.count)
		end

	test_queue_capacity
			-- Test queue with capacity limit.
		local
			queue: SIMPLE_MQ_QUEUE
			msg: SIMPLE_MQ_MESSAGE
		do
			create queue.make_with_capacity ("bounded", 2)
			create msg.make ("1")
			queue.enqueue (msg)
			create msg.make ("2")
			queue.enqueue (msg)
			assert_true ("is full", queue.is_full)
		end

	test_priority_queue
			-- Test priority queue ordering.
		local
			queue: SIMPLE_MQ_QUEUE
			low, high: SIMPLE_MQ_MESSAGE
		do
			create queue.make_priority ("priority-test")
			create low.make ("Low priority")
			low.set_priority (1)
			create high.make ("High priority")
			high.set_priority (10)
			-- Enqueue low first, then high
			queue.enqueue (low)
			queue.enqueue (high)
			-- High priority should come out first
			if attached queue.dequeue as received then
				assert_strings_equal ("high first", "High priority", received.payload)
			else
				assert_true ("first dequeue", False)
			end
			if attached queue.dequeue as received then
				assert_strings_equal ("low second", "Low priority", received.payload)
			else
				assert_true ("second dequeue", False)
			end
		end

	test_queue_find_by_id
			-- Test finding message by ID.
		local
			queue: SIMPLE_MQ_QUEUE
			msg: SIMPLE_MQ_MESSAGE
			found: detachable SIMPLE_MQ_MESSAGE
		do
			create queue.make ("test")
			create msg.make_with_id ("unique-id", "Find me")
			queue.enqueue (msg)
			found := queue.find_by_id ("unique-id")
			assert_true ("found", attached found)
			if attached found as f then
				assert_strings_equal ("payload", "Find me", f.payload)
			end
		end

	test_queue_remove_by_id
			-- Test removing message by ID.
		local
			queue: SIMPLE_MQ_QUEUE
			msg: SIMPLE_MQ_MESSAGE
		do
			create queue.make ("test")
			create msg.make_with_id ("to-remove", "Remove me")
			queue.enqueue (msg)
			assert_true ("has message", queue.has_message ("to-remove"))
			assert_true ("removed", queue.remove_by_id ("to-remove"))
			assert_false ("no longer has", queue.has_message ("to-remove"))
		end

	test_queue_dequeue_batch
			-- Test batch dequeue.
		local
			queue: SIMPLE_MQ_QUEUE
			msg: SIMPLE_MQ_MESSAGE
			batch: ARRAYED_LIST [SIMPLE_MQ_MESSAGE]
			i: INTEGER
		do
			create queue.make ("test")
			from i := 1 until i > 5 loop
				create msg.make ("Message " + i.out)
				queue.enqueue (msg)
				i := i + 1
			end
			batch := queue.dequeue_batch (3)
			assert_integers_equal ("batch size", 3, batch.count)
			assert_integers_equal ("remaining", 2, queue.count)
		end

feature -- Test: Topic (Pub/Sub)

	test_topic_make
			-- Test topic creation.
		local
			topic: SIMPLE_MQ_TOPIC
		do
			create topic.make ("events.user.created")
			assert_strings_equal ("name", "events.user.created", topic.name)
			assert_integers_equal ("no subscribers", 0, topic.subscriber_count)
		end

	test_topic_subscribe_publish
			-- Test subscribe and publish.
		local
			topic: SIMPLE_MQ_TOPIC
			sub: TEST_SUBSCRIBER
			msg: SIMPLE_MQ_MESSAGE
		do
			create topic.make ("test-topic")
			create sub.make
			topic.subscribe (sub)
			assert_integers_equal ("1 subscriber", 1, topic.subscriber_count)
			create msg.make ("Hello subscribers!")
			topic.publish (msg)
			assert_integers_equal ("received 1", 1, sub.received_count)
			if attached sub.last_message as m then
				assert_strings_equal ("payload", "Hello subscribers!", m.payload)
			end
		end

	test_topic_multiple_subscribers
			-- Test multiple subscribers receive message.
		local
			topic: SIMPLE_MQ_TOPIC
			sub1, sub2, sub3: TEST_SUBSCRIBER
			msg: SIMPLE_MQ_MESSAGE
		do
			create topic.make ("multi-sub")
			create sub1.make
			create sub2.make
			create sub3.make
			topic.subscribe (sub1)
			topic.subscribe (sub2)
			topic.subscribe (sub3)
			create msg.make ("Broadcast")
			topic.publish (msg)
			assert_integers_equal ("sub1 received", 1, sub1.received_count)
			assert_integers_equal ("sub2 received", 1, sub2.received_count)
			assert_integers_equal ("sub3 received", 1, sub3.received_count)
		end

	test_topic_unsubscribe
			-- Test unsubscribe.
		local
			topic: SIMPLE_MQ_TOPIC
			sub: TEST_SUBSCRIBER
			msg: SIMPLE_MQ_MESSAGE
		do
			create topic.make ("unsub-test")
			create sub.make
			topic.subscribe (sub)
			topic.unsubscribe (sub)
			assert_false ("not subscribed", topic.is_subscribed (sub))
			create msg.make ("Should not receive")
			topic.publish (msg)
			assert_integers_equal ("no messages", 0, sub.received_count)
		end

	test_topic_history
			-- Test topic message history.
		local
			topic: SIMPLE_MQ_TOPIC
			msg: SIMPLE_MQ_MESSAGE
			hist: ARRAYED_LIST [SIMPLE_MQ_MESSAGE]
		do
			create topic.make_with_history ("history-topic", 3)
			create msg.make ("Message 1")
			topic.publish (msg)
			create msg.make ("Message 2")
			topic.publish (msg)
			hist := topic.get_history
			assert_integers_equal ("history count", 2, hist.count)
		end

	test_topic_pattern_matching
			-- Test wildcard pattern matching.
		local
			topic: SIMPLE_MQ_TOPIC
		do
			create topic.make ("events.user.created")
			assert_true ("exact match", topic.matches_pattern ("events.user.created"))
			assert_true ("single wildcard", topic.matches_pattern ("events.user.*"))
			assert_true ("multi wildcard", topic.matches_pattern ("events.#"))
			assert_false ("no match", topic.matches_pattern ("events.order.created"))
		end

feature -- Test: SIMPLE_MQ Facade

	test_mq_new_message
			-- Test creating messages via facade.
		local
			mq: SIMPLE_MQ
			msg: SIMPLE_MQ_MESSAGE
		do
			create mq.make
			msg := mq.new_message ("Test")
			assert_strings_equal ("payload", "Test", msg.payload)
		end

	test_mq_new_queue
			-- Test creating queues via facade.
		local
			mq: SIMPLE_MQ
			queue: SIMPLE_MQ_QUEUE
		do
			create mq.make
			queue := mq.new_queue ("tasks")
			assert_strings_equal ("name", "tasks", queue.name)
			assert_false ("not priority", queue.is_priority_queue)
		end

	test_mq_new_priority_queue
			-- Test creating priority queue via facade.
		local
			mq: SIMPLE_MQ
			queue: SIMPLE_MQ_QUEUE
		do
			create mq.make
			queue := mq.new_priority_queue ("important")
			assert_true ("is priority", queue.is_priority_queue)
		end

	test_mq_new_topic
			-- Test creating topics via facade.
		local
			mq: SIMPLE_MQ
			topic: SIMPLE_MQ_TOPIC
		do
			create mq.make
			topic := mq.new_topic ("notifications")
			assert_strings_equal ("name", "notifications", topic.name)
		end

	test_mq_registry
			-- Test queue/topic registration.
		local
			mq: SIMPLE_MQ
			queue: SIMPLE_MQ_QUEUE
			topic: SIMPLE_MQ_TOPIC
		do
			create mq.make
			queue := mq.new_queue ("registered-queue")
			topic := mq.new_topic ("registered-topic")
			mq.register_queue (queue)
			mq.register_topic (topic)
			assert_true ("queue found", attached mq.queue ("registered-queue"))
			assert_true ("topic found", attached mq.topic ("registered-topic"))
		end

	test_mq_quick_send_receive
			-- Test quick send/receive.
		local
			mq: SIMPLE_MQ
			queue: SIMPLE_MQ_QUEUE
			received: detachable SIMPLE_MQ_MESSAGE
		do
			create mq.make
			queue := mq.new_queue ("quick-test")
			mq.register_queue (queue)
			mq.send ("quick-test", "Quick message")
			received := mq.receive ("quick-test")
			assert_true ("received", attached received)
			if attached received as r then
				assert_strings_equal ("payload", "Quick message", r.payload)
			end
		end

	test_mq_topics_matching
			-- Test finding topics by pattern.
		local
			mq: SIMPLE_MQ
			t1, t2, t3: SIMPLE_MQ_TOPIC
			matches: ARRAYED_LIST [SIMPLE_MQ_TOPIC]
		do
			create mq.make
			t1 := mq.new_topic ("events.user.created")
			t2 := mq.new_topic ("events.user.deleted")
			t3 := mq.new_topic ("events.order.created")
			mq.register_topic (t1)
			mq.register_topic (t2)
			mq.register_topic (t3)
			matches := mq.topics_matching ("events.user.*")
			assert_integers_equal ("2 user topics", 2, matches.count)
		end

feature -- Test: Redis Queue (Mock)

	test_redis_queue_make
			-- Test Redis queue creation (without actual Redis).
		local
			redis: SIMPLE_REDIS
			queue: SIMPLE_MQ_REDIS_QUEUE
		do
			create redis.make ("localhost", 6379)
			create queue.make ("test-redis", redis)
			assert_strings_equal ("name", "test-redis", queue.name)
			assert_strings_equal ("key", "mq:test-redis", queue.key)
		end

	test_redis_queue_with_timeout
			-- Test Redis queue with blocking timeout.
		local
			redis: SIMPLE_REDIS
			queue: SIMPLE_MQ_REDIS_QUEUE
		do
			create redis.make ("localhost", 6379)
			create queue.make_with_timeout ("blocking", redis, 30)
			assert_integers_equal ("timeout", 30, queue.blocking_timeout)
		end

end
