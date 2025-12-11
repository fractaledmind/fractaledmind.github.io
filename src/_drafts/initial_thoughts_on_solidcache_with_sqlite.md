What is the policy for Litecache? FIFO, LRU, something else?

LRU, there is an index that tracks that which I lazily update

Looking at Solid cache, I believe Litecache is the best of both worlds, can grow much larger than a redis cache and is also quite faster for all reads and single threaded writes

Also, for litecache there are actually two indices, one tracks LRU and the other tracks expires_on, when eviction is needed, all expired items are deleted first, if that is enough then good, otherwise an arbitrary number of LRU entries is removed
