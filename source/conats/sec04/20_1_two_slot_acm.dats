// #define CONATSCONTRIB
// "https://raw.githubusercontent.com/alex-ren/org.ats-lang.postiats.jats/master/utfpl/src/jats/utfpl/stfpl/test"
// staload "{$CONATSCONTRIB}/conats.sats"

staload "./conats.sats"

// Define types for data slots.
abstype dataslots_t (t@ype, int)

absviewtype own_slot_vt (int)

local
  assume dataslots_t (a:t@ype, x: int) = atomarrayref (a)
  assume own_slot_vt (i: int) = mc_vlock_vt (i, 0, 1, 1)
in
  fun dataslots_create {a:t@ype} {x:pos} (
    x: int x, v: a): dataslots_t (a, x) =
     conats_atomarrayref_create {a} (x, v)

  fun dataslots_update {a:t@ype} {x,i:nat | i < x} 
    ( vpf: own_slot_vt (i)
    | slots: dataslots_t (a, x), i: int i, v: a
    ): (own_slot_vt i | void) = let
    val () = conats_atomarrayref_update (slots, i, v)
  in
    (vpf | ())
  end

  fun dataslots_get {a:t@ype} {x,i:nat | i < x} 
    ( vpf: own_slot_vt (i)
    | slots: dataslots_t (a, x), i: int i
    ): (own_slot_vt i | a) = let
    val v = conats_atomarrayref_get (slots, i)
  in
    (vpf | v)
  end

  prfun mc_acquire_ownership .<>. {i: nat}
    (i: int i): own_slot_vt (i) = mc_vlock_get (i, 0, 1, 1)

  prfun mc_release_ownership .<>. {i: nat}
    (vpf: own_slot_vt (i)): void = mc_vlock_put (vpf)
  
end

// Define type for data slots used in the example.
// We use two data slots.
typedef data_t = dataslots_t (int, 2)
val data: data_t = dataslots_create (2, 0)

typedef int2 = [i: int | i >= 0 && i <= 1] int i

// control variables
val latest = conats_atomref_create {int2} (0)

fun write (item: int): void = let
  val index = 1 - conats_atomref_get (latest)

  prval vpf = mc_acquire_ownership (index)
  val (vpf | _) = dataslots_update (vpf | data, index, item)
  prval () = mc_release_ownership (vpf)

  val () = conats_atomref_update (latest, index)
in
end

fun read (): int = let
  val index = conats_atomref_get (latest)

  prval vpf = mc_acquire_ownership (index)
  val (vpf | item) = dataslots_get (vpf | data, index)
  prval () = mc_release_ownership (vpf)
in
  item
end

fun loop_writer (x: int): void = let
  val () = write (x)
in
  loop_writer (x)
end

fun loop_reader (x: int): void = let
  val _ = read ()
in
  loop_reader (x)
end


// Construct the model of whole system.

val tid1 = conats_tid_allocate ()
val tid2 = conats_tid_allocate ()

val () = conats_thread_create(loop_reader, 0, tid1)
val () = conats_thread_create(loop_writer, 0, tid2)

// List the properties for model checking.

%{$
#assert main deadlockfree;

#assert main |= G sys_assertion;

%}




