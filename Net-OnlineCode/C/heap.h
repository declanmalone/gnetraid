// Priority queue implementation (heap-based)

// The structures and routines here are intended to support more
// efficient reads from an external message file or check block file.
// The naive approach would be:
//
// In the encoder:
//
//   do a single pass over the file to calculate aux blocks (always
//   cached in memory)
//
//   for each check block, read in all the constituent message blocks
//   and xor them together
//
// In the decoder:
//
//   receive a decoded message or aux block, which is expressed as a
//   list of check blocks and previously-solved aux/message blocks (if
//   message expansion option isn't used)
//
//   Read any aux blocks from memory and XOR them
//
//   For each check block (and message blocks), read it in from the
//   file and XOR it.
//
// This approach is fine, and it works, but it involves a lot of
// random seeking in the message/check block file. By using a heap to
// store the list of disk blocks to be read in, we can read each block
// back in sequence, resulting in fewer seeks (skipping only unwanted
// blocks and seeking back to the start after eof).
//
// To further improve the effectiveness of the heap (priority queue),
// both the encoder and decoder will have the option of running the OC
// code algorithm and the disk I/O parts as separate threads. Assuming
// the OC algorithm generates block requests faster than the I/O part
// can fulfill them this should improve throughput by:
//
// * reducing the number of seeks (smaller gaps)
//
// * more frequent re-use of blocks that are read in (in the encoder,
//   for example, message blocks may be XORed with several pending
//   check blocks)
//
// See "diskio.h" for more details of using the priority queue as part
// of a caching/command queueing strategy.

typedef struct {

  int            block;		// ID of block to be read from file
  oc_block_list *xor_list;	// will be XORed into these blocks

} oc_heap_entry;

typedef struct {

  oc_heap_entry *heap;

  int max_size;
  int size;

  // The encoder and decoder will read over the file in a circular
  // manner. That means that the heap will have to sort block IDs
  // relative to the current read position (seek pointer) rather than
  // relative to the start of the file.

  int read_position;

} oc_heap;

