
staload "./conats.sats"

val gref = conats_atomref_create (0)

val s = conats_shared_create{atomref int}(gref)


fun producer (x: int):<fun1> void = let
  val ref = conats_shared_acquire (s)

  fun loop () =
    if conats_atomref_get (ref) = 1 then let
      val ref = conats_shared_condwait (s, ref)
    in
      loop ()
    end else let 
      val () = conats_atomref_update (ref, conats_atomref_get (ref) + 1)
      val ref = conats_shared_signal (s, ref)
      val () = conats_shared_release (s, ref)
    in
      producer (x)
    end
in
  loop ()
end

fun consumer (x: int):<fun1> void = let
  val ref = conats_shared_acquire (s)

  fun loop () = 
    if conats_atomref_get (ref) = 0 then let
      val ref = conats_shared_condwait (s, ref)
    in
      loop ()
    end else let
      val () = conats_atomref_update (ref, conats_atomref_get (ref) - 1)
      val ref = conats_shared_signal (s, ref)
      val () = conats_shared_release (s, ref)
    in
      consumer (x)
    end
in
  loop ()
end

val tid1 = conats_tid_allocate ()
val tid2 = conats_tid_allocate ()
val () = conats_thread_create(producer, 0, tid1)
val () = conats_thread_create(consumer, 0, tid2)
