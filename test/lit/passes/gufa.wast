;; NOTE: Assertions have been generated by update_lit_checks.py --all-items and should not be edited.
;; RUN: foreach %s %t wasm-opt -all --gufa -S -o - | filecheck %s

(module
  ;; CHECK:      (type $none_=>_i32 (func (result i32)))

  ;; CHECK:      (type $none_=>_none (func))

  ;; CHECK:      (type $i32_i32_=>_i32 (func (param i32 i32) (result i32)))

  ;; CHECK:      (type $i32_=>_i32 (func (param i32) (result i32)))

  ;; CHECK:      (import "a" "b" (func $import (result i32)))
  (import "a" "b" (func $import (result i32)))


  ;; CHECK:      (export "param-no" (func $param-no))

  ;; CHECK:      (func $never-called (param $param i32) (result i32)
  ;; CHECK-NEXT:  (unreachable)
  ;; CHECK-NEXT: )
  (func $never-called (param $param i32) (result i32)
    ;; This function is never called, so no content is possible in $param, and
    ;; we know this must be unreachable code that can be removed (replaced with
    ;; an unreachable).
    (local.get $param)
  )

  ;; CHECK:      (func $foo (result i32)
  ;; CHECK-NEXT:  (i32.const 1)
  ;; CHECK-NEXT: )
  (func $foo (result i32)
    (i32.const 1)
  )

  ;; CHECK:      (func $bar
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block (result i32)
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (select
  ;; CHECK-NEXT:      (block (result i32)
  ;; CHECK-NEXT:       (drop
  ;; CHECK-NEXT:        (call $foo)
  ;; CHECK-NEXT:       )
  ;; CHECK-NEXT:       (i32.const 1)
  ;; CHECK-NEXT:      )
  ;; CHECK-NEXT:      (i32.const 1)
  ;; CHECK-NEXT:      (call $import)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (i32.const 1)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $bar
    ;; Both arms of the select have identical values, 1. Inlining +
    ;; OptimizeInstructions could of course discover that in this case, but
    ;; GUFA can do so even without inlining. As a result the select will be
    ;; dropped (due to the call which may have effects, we keep it), and after
    ;; the select we emit the constant 1 for the value.
    (drop
      (select
        (call $foo)
        (i32.const 1)
        (call $import)
      )
    )
  )

  ;; CHECK:      (func $baz
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (select
  ;; CHECK-NEXT:    (block (result i32)
  ;; CHECK-NEXT:     (drop
  ;; CHECK-NEXT:      (call $foo)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:     (i32.const 1)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (i32.eqz
  ;; CHECK-NEXT:     (i32.eqz
  ;; CHECK-NEXT:      (i32.const 1)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (call $import)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $baz
    (drop
      (select
        (call $foo)
        ;; As above, but replace 1 with eqz(eqz(1)).This pass assumes any eqz
        ;; etc is a new value, and so here we do not optimize the select (we do
        ;; still optimize the call's result, though).
        (i32.eqz
          (i32.eqz
            (i32.const 1)
          )
        )
        (call $import)
      )
    )
  )

  ;; CHECK:      (func $return (result i32)
  ;; CHECK-NEXT:  (if
  ;; CHECK-NEXT:   (i32.const 0)
  ;; CHECK-NEXT:   (return
  ;; CHECK-NEXT:    (i32.const 1)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (i32.const 2)
  ;; CHECK-NEXT: )
  (func $return (result i32)
    ;; Helper function that returns one result in a return and flows another
    ;; out.
    (if
      (i32.const 0)
      (return
        (i32.const 1)
      )
    )
    (i32.const 2)
  )

  ;; CHECK:      (func $call-return
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (call $return)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $call-return
    ;; The called function has two possible return values, so we cannot optimize
    ;; anything here.
    (drop
      (call $return)
    )
  )

  ;; CHECK:      (func $return-same (result i32)
  ;; CHECK-NEXT:  (if
  ;; CHECK-NEXT:   (i32.const 0)
  ;; CHECK-NEXT:   (return
  ;; CHECK-NEXT:    (i32.const 1)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (i32.const 1)
  ;; CHECK-NEXT: )
  (func $return-same (result i32)
    ;; Helper function that returns the same result in a return as it flows out.
    ;; This is the same as above, but now the values are identical.
    (if
      (i32.const 0)
      (return
        (i32.const 1)
      )
    )
    (i32.const 1)
  )

  ;; CHECK:      (func $call-return-same
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block (result i32)
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (call $return-same)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (i32.const 1)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $call-return-same
    ;; Unlike in $call-return, now we can optimize here.
    (drop
      (call $return-same)
    )
  )

  ;; CHECK:      (func $local-no (result i32)
  ;; CHECK-NEXT:  (local $x i32)
  ;; CHECK-NEXT:  (if
  ;; CHECK-NEXT:   (call $import)
  ;; CHECK-NEXT:   (local.set $x
  ;; CHECK-NEXT:    (i32.const 1)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (local.get $x)
  ;; CHECK-NEXT: )
  (func $local-no (result i32)
    (local $x i32)
    (if
      (call $import)
      (local.set $x
        (i32.const 1)
      )
    )
    ;; $x has two possible values, 1 and the default 0, so we cannot optimize
    ;; anything here.
    (local.get $x)
  )

  ;; CHECK:      (func $local-yes (result i32)
  ;; CHECK-NEXT:  (local $x i32)
  ;; CHECK-NEXT:  (if
  ;; CHECK-NEXT:   (call $import)
  ;; CHECK-NEXT:   (local.set $x
  ;; CHECK-NEXT:    (i32.const 0)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (i32.const 0)
  ;; CHECK-NEXT: )
  (func $local-yes (result i32)
    (local $x i32)
    (if
      (call $import)
      (local.set $x
        ;; As above, but now we set 0 here. We can optimize the local.get to 0
        ;; in this case.
        (i32.const 0)
      )
    )
    (local.get $x)
  )

  ;; CHECK:      (func $param-no (param $param i32) (result i32)
  ;; CHECK-NEXT:  (if
  ;; CHECK-NEXT:   (local.get $param)
  ;; CHECK-NEXT:   (local.set $param
  ;; CHECK-NEXT:    (i32.const 1)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (local.get $param)
  ;; CHECK-NEXT: )
  (func $param-no (export "param-no") (param $param i32) (result i32)
    (if
      (local.get $param)
      (local.set $param
        (i32.const 1)
      )
    )
    ;; $x has two possible values, the incoming param value and 1, so we cannot
    ;; optimize, since the function is exported - anything on the outside could
    ;; call it with values we are not aware of during the optimization.
    (local.get $param)
  )

  ;; CHECK:      (func $param-yes (param $param i32) (result i32)
  ;; CHECK-NEXT:  (if
  ;; CHECK-NEXT:   (i32.const 1)
  ;; CHECK-NEXT:   (local.set $param
  ;; CHECK-NEXT:    (i32.const 1)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (i32.const 1)
  ;; CHECK-NEXT: )
  (func $param-yes (param $param i32) (result i32)
    (if
      (local.get $param)
      (local.set $param
        (i32.const 1)
      )
    )
    ;; As above, but now the function is not exported. That means it has no
    ;; callers, so the only possible contents for $param are the local.set here,
    ;; as this code is unreachable. We will infer a constant of 1 for all values
    ;; of $param here. (With an SSA analysis, we could see that the first
    ;; local.get must be unreachable, and optimize even better; as things are,
    ;; we see the local.set and it is the only thing that sends values to the
    ;; local.)
    (local.get $param)
  )

  ;; CHECK:      (func $cycle (param $x i32) (param $y i32) (result i32)
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block (result i32)
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (block (result i32)
  ;; CHECK-NEXT:      (drop
  ;; CHECK-NEXT:       (call $cycle
  ;; CHECK-NEXT:        (i32.const 42)
  ;; CHECK-NEXT:        (i32.const 1)
  ;; CHECK-NEXT:       )
  ;; CHECK-NEXT:      )
  ;; CHECK-NEXT:      (i32.const 42)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (block (result i32)
  ;; CHECK-NEXT:     (drop
  ;; CHECK-NEXT:      (select
  ;; CHECK-NEXT:       (i32.const 42)
  ;; CHECK-NEXT:       (block (result i32)
  ;; CHECK-NEXT:        (drop
  ;; CHECK-NEXT:         (call $cycle
  ;; CHECK-NEXT:          (i32.const 42)
  ;; CHECK-NEXT:          (i32.const 1)
  ;; CHECK-NEXT:         )
  ;; CHECK-NEXT:        )
  ;; CHECK-NEXT:        (i32.const 42)
  ;; CHECK-NEXT:       )
  ;; CHECK-NEXT:       (i32.const 1)
  ;; CHECK-NEXT:      )
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:     (i32.const 42)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (i32.const 42)
  ;; CHECK-NEXT: )
  (func $cycle (param $x i32) (param $y i32) (result i32)
    ;; Return 42, or else the result from a recursive call. The only possible
    ;; value is 42, which we can optimize to.
    ;; (Nothing else calls $cycle, so this is dead code in actuality, but this
    ;; pass leaves such things to other passes.)
    ;; Note that the first call passes constants for $x and $y which lets us
    ;; optimize them too (as we see no other contents arrive to them).
    (drop
      (call $cycle
        (i32.const 42)
        (i32.const 1)
      )
    )
    (select
      (i32.const 42)
      (call $cycle
        (local.get $x)
        (local.get $y)
      )
      (local.get $y)
    )
  )

  ;; CHECK:      (func $cycle-2 (param $x i32) (param $y i32) (result i32)
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block (result i32)
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (block (result i32)
  ;; CHECK-NEXT:      (drop
  ;; CHECK-NEXT:       (call $cycle-2
  ;; CHECK-NEXT:        (i32.const 42)
  ;; CHECK-NEXT:        (i32.const 1)
  ;; CHECK-NEXT:       )
  ;; CHECK-NEXT:      )
  ;; CHECK-NEXT:      (i32.const 42)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (block (result i32)
  ;; CHECK-NEXT:     (drop
  ;; CHECK-NEXT:      (select
  ;; CHECK-NEXT:       (i32.const 42)
  ;; CHECK-NEXT:       (block (result i32)
  ;; CHECK-NEXT:        (drop
  ;; CHECK-NEXT:         (call $cycle-2
  ;; CHECK-NEXT:          (i32.const 1)
  ;; CHECK-NEXT:          (i32.const 1)
  ;; CHECK-NEXT:         )
  ;; CHECK-NEXT:        )
  ;; CHECK-NEXT:        (i32.const 42)
  ;; CHECK-NEXT:       )
  ;; CHECK-NEXT:       (local.get $x)
  ;; CHECK-NEXT:      )
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:     (i32.const 42)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (i32.const 42)
  ;; CHECK-NEXT: )
  (func $cycle-2 (param $x i32) (param $y i32) (result i32)
    (drop
      (call $cycle-2
        (i32.const 42)
        (i32.const 1)
      )
    )
    ;; As above, but flip one $x and $y on the first and last local.gets. There
    ;; is still only the one value possible as nothing else flows in.
    (select
      (i32.const 42)
      (call $cycle-2
        (local.get $y)
        (local.get $y)
      )
      (local.get $x)
    )
  )

  ;; CHECK:      (func $cycle-3 (param $x i32) (param $y i32) (result i32)
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block (result i32)
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (block (result i32)
  ;; CHECK-NEXT:      (drop
  ;; CHECK-NEXT:       (call $cycle-3
  ;; CHECK-NEXT:        (i32.const 1337)
  ;; CHECK-NEXT:        (i32.const 1)
  ;; CHECK-NEXT:       )
  ;; CHECK-NEXT:      )
  ;; CHECK-NEXT:      (i32.const 42)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (block (result i32)
  ;; CHECK-NEXT:     (drop
  ;; CHECK-NEXT:      (select
  ;; CHECK-NEXT:       (i32.const 42)
  ;; CHECK-NEXT:       (block (result i32)
  ;; CHECK-NEXT:        (drop
  ;; CHECK-NEXT:         (call $cycle-3
  ;; CHECK-NEXT:          (i32.eqz
  ;; CHECK-NEXT:           (local.get $x)
  ;; CHECK-NEXT:          )
  ;; CHECK-NEXT:          (i32.const 1)
  ;; CHECK-NEXT:         )
  ;; CHECK-NEXT:        )
  ;; CHECK-NEXT:        (i32.const 42)
  ;; CHECK-NEXT:       )
  ;; CHECK-NEXT:       (i32.const 1)
  ;; CHECK-NEXT:      )
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:     (i32.const 42)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (i32.const 42)
  ;; CHECK-NEXT: )
  (func $cycle-3 (param $x i32) (param $y i32) (result i32)
    ;; Even adding a caller with a different value for $x does not prevent us
    ;; from optimizing here.
    (drop
      (call $cycle-3
        (i32.const 1337)
        (i32.const 1)
      )
    )
    ;; As $cycle, but add an i32.eqz on $x. We can still optimize this, as
    ;; while the eqz is a new value arriving in $x, we do not actually return
    ;; $x, and again the only possible value flowing in the graph is 42.
    (select
      (i32.const 42)
      (call $cycle-3
        (i32.eqz
          (local.get $x)
        )
        (local.get $y)
      )
      (local.get $y)
    )
  )

  ;; CHECK:      (func $cycle-4 (param $x i32) (param $y i32) (result i32)
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (call $cycle-4
  ;; CHECK-NEXT:    (i32.const 1337)
  ;; CHECK-NEXT:    (i32.const 1)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (select
  ;; CHECK-NEXT:   (local.get $x)
  ;; CHECK-NEXT:   (call $cycle-4
  ;; CHECK-NEXT:    (i32.eqz
  ;; CHECK-NEXT:     (local.get $x)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (i32.const 1)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:   (i32.const 1)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $cycle-4 (param $x i32) (param $y i32) (result i32)
    (drop
      (call $cycle-4
        (i32.const 1337)
        (i32.const 1)
      )
    )
    (select
      ;; As above, but we have no constant here, but $x. We may now return $x or
      ;; $eqz of $x, which means we cannot infer the result of the call. (But we
      ;; can still infer the value of $y, which is 1.)
      (local.get $x)
      (call $cycle-4
        (i32.eqz
          (local.get $x)
        )
        (local.get $y)
      )
      (local.get $y)
    )
  )

  ;; CHECK:      (func $cycle-5 (param $x i32) (param $y i32) (result i32)
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block (result i32)
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (block (result i32)
  ;; CHECK-NEXT:      (drop
  ;; CHECK-NEXT:       (call $cycle-5
  ;; CHECK-NEXT:        (i32.const 1337)
  ;; CHECK-NEXT:        (i32.const 1)
  ;; CHECK-NEXT:       )
  ;; CHECK-NEXT:      )
  ;; CHECK-NEXT:      (i32.const 1337)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (block (result i32)
  ;; CHECK-NEXT:     (drop
  ;; CHECK-NEXT:      (select
  ;; CHECK-NEXT:       (i32.const 1337)
  ;; CHECK-NEXT:       (block (result i32)
  ;; CHECK-NEXT:        (drop
  ;; CHECK-NEXT:         (call $cycle-5
  ;; CHECK-NEXT:          (i32.const 1337)
  ;; CHECK-NEXT:          (i32.const 1)
  ;; CHECK-NEXT:         )
  ;; CHECK-NEXT:        )
  ;; CHECK-NEXT:        (i32.const 1337)
  ;; CHECK-NEXT:       )
  ;; CHECK-NEXT:       (i32.const 1)
  ;; CHECK-NEXT:      )
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:     (i32.const 1337)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (i32.const 1337)
  ;; CHECK-NEXT: )
  (func $cycle-5 (param $x i32) (param $y i32) (result i32)
    (drop
      (call $cycle-5
        (i32.const 1337)
        (i32.const 1)
      )
    )
    (select
      (local.get $x)
      (call $cycle-5
        ;; As above, but now we return $x in both cases, so we can optimize, and
        ;; infer the result is the 1337 which is passed in the earlier call.
        (local.get $x)
        (local.get $y)
      )
      (local.get $y)
    )
  )

  ;; CHECK:      (func $blocks
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block $block (result i32)
  ;; CHECK-NEXT:    (nop)
  ;; CHECK-NEXT:    (i32.const 1)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block $named (result i32)
  ;; CHECK-NEXT:    (nop)
  ;; CHECK-NEXT:    (i32.const 1)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block (result i32)
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (block $named0 (result i32)
  ;; CHECK-NEXT:      (if
  ;; CHECK-NEXT:       (i32.const 0)
  ;; CHECK-NEXT:       (br $named0
  ;; CHECK-NEXT:        (i32.const 1)
  ;; CHECK-NEXT:       )
  ;; CHECK-NEXT:      )
  ;; CHECK-NEXT:      (i32.const 1)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (i32.const 1)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block $named1 (result i32)
  ;; CHECK-NEXT:    (if
  ;; CHECK-NEXT:     (i32.const 0)
  ;; CHECK-NEXT:     (br $named1
  ;; CHECK-NEXT:      (i32.const 2)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (i32.const 1)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $blocks
    ;; We can infer a constant value here, but should not make any changes, as
    ;; the pattern we try to optimize things to is exactly a block ending in a
    ;; constant. So we do not optimize such things, which would keep increasing
    ;; code size each time we run, with no benefit.
    (drop
      (block (result i32)
        (nop)
        (i32.const 1)
      )
    )
    ;; Even if the block has a name, we should not make any changes.
    (drop
      (block $named (result i32)
        (nop)
        (i32.const 1)
      )
    )
    ;; But if the block also has a branch to it, then we should: we'd be placing
    ;; something simpler (a nameless block with no branches to it) on the
    ;; outside.
    (drop
      (block $named (result i32)
        (if
          (i32.const 0)
          (br $named
            (i32.const 1)
          )
        )
        (i32.const 1)
      )
    )
    ;; As above, but the two values reaching the block do not agree, so we
    ;; should not optimize.
    (drop
      (block $named (result i32)
        (if
          (i32.const 0)
          (br $named
            (i32.const 2) ;; this changed
          )
        )
        (i32.const 1)
      )
    )
  )
)

(module
  ;; CHECK:      (type $i (func (param i32)))
  (type $i (func (param i32)))

  (table 10 funcref)
  (elem (i32.const 0) funcref
    (ref.func $reffed)
  )

  ;; CHECK:      (type $none_=>_none (func))

  ;; CHECK:      (table $0 10 funcref)

  ;; CHECK:      (elem (i32.const 0) $reffed)

  ;; CHECK:      (export "table" (table $0))
  (export "table" (table 0))

  ;; CHECK:      (func $reffed (param $x i32)
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $x)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $reffed (param $x i32)
    ;; This function is in the table, and the table is exported, so we cannot
    ;; see all callers, and cannot infer the value here.
    (drop
      (local.get $x)
    )
  )

  ;; CHECK:      (func $do-calls
  ;; CHECK-NEXT:  (call $reffed
  ;; CHECK-NEXT:   (i32.const 42)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (call_indirect $0 (type $i)
  ;; CHECK-NEXT:   (i32.const 42)
  ;; CHECK-NEXT:   (i32.const 0)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $do-calls
    (call $reffed
      (i32.const 42)
    )
    (call_indirect (type $i)
      (i32.const 42)
      (i32.const 0)
    )
  )
)

;; As above, but the table is not exported. We have a direct and an indirect
;; call with the same value, so we can optimize.
(module
  ;; CHECK:      (type $i (func (param i32)))
  (type $i (func (param i32)))

  (table 10 funcref)
  (elem (i32.const 0) funcref
    (ref.func $reffed)
  )

  ;; CHECK:      (type $none_=>_none (func))

  ;; CHECK:      (table $0 10 funcref)

  ;; CHECK:      (elem (i32.const 0) $reffed)

  ;; CHECK:      (func $reffed (param $x i32)
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (i32.const 42)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $reffed (param $x i32)
    (drop
      (local.get $x)
    )
  )

  ;; CHECK:      (func $do-calls
  ;; CHECK-NEXT:  (call $reffed
  ;; CHECK-NEXT:   (i32.const 42)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (call_indirect $0 (type $i)
  ;; CHECK-NEXT:   (i32.const 42)
  ;; CHECK-NEXT:   (i32.const 0)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $do-calls
    (call $reffed
      (i32.const 42)
    )
    (call_indirect (type $i)
      (i32.const 42)
      (i32.const 0)
    )
  )
)

;; As above but the only calls are indirect.
(module
  ;; CHECK:      (type $i (func (param i32)))
  (type $i (func (param i32)))

  (table 10 funcref)
  (elem (i32.const 0) funcref
    (ref.func $reffed)
  )

  ;; CHECK:      (type $none_=>_none (func))

  ;; CHECK:      (table $0 10 funcref)

  ;; CHECK:      (elem (i32.const 0) $reffed)

  ;; CHECK:      (func $reffed (param $x i32)
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (i32.const 42)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $reffed (param $x i32)
    (drop
      (local.get $x)
    )
  )

  ;; CHECK:      (func $do-calls
  ;; CHECK-NEXT:  (call_indirect $0 (type $i)
  ;; CHECK-NEXT:   (i32.const 42)
  ;; CHECK-NEXT:   (i32.const 0)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (call_indirect $0 (type $i)
  ;; CHECK-NEXT:   (i32.const 42)
  ;; CHECK-NEXT:   (i32.const 0)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $do-calls
    (call_indirect (type $i)
      (i32.const 42)
      (i32.const 0)
    )
    (call_indirect (type $i)
      (i32.const 42)
      (i32.const 0)
    )
  )
)

;; As above but the indirect calls have different parameters.
(module
  ;; CHECK:      (type $i (func (param i32)))
  (type $i (func (param i32)))

  (table 10 funcref)
  (elem (i32.const 0) funcref
    (ref.func $reffed)
  )

  ;; CHECK:      (type $none_=>_none (func))

  ;; CHECK:      (table $0 10 funcref)

  ;; CHECK:      (elem (i32.const 0) $reffed)

  ;; CHECK:      (func $reffed (param $x i32)
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $x)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $reffed (param $x i32)
    (drop
      (local.get $x)
    )
  )

  ;; CHECK:      (func $do-calls
  ;; CHECK-NEXT:  (call_indirect $0 (type $i)
  ;; CHECK-NEXT:   (i32.const 42)
  ;; CHECK-NEXT:   (i32.const 0)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (call_indirect $0 (type $i)
  ;; CHECK-NEXT:   (i32.const 1337)
  ;; CHECK-NEXT:   (i32.const 0)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $do-calls
    (call_indirect (type $i)
      (i32.const 42)
      (i32.const 0)
    )
    (call_indirect (type $i)
      (i32.const 1337)
      (i32.const 0)
    )
  )
)

;; As above but the second call is of another signature, so it does not prevent
;; us from optimizing.
(module
  ;; CHECK:      (type $i (func (param i32)))
  (type $i (func (param i32)))
  ;; CHECK:      (type $none_=>_none (func))

  ;; CHECK:      (type $f (func (param f32)))
  (type $f (func (param f32)))

  (table 10 funcref)
  (elem (i32.const 0) funcref
    (ref.func $reffed)
  )

  ;; CHECK:      (table $0 10 funcref)

  ;; CHECK:      (elem (i32.const 0) $reffed)

  ;; CHECK:      (func $reffed (param $x i32)
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (i32.const 42)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $reffed (param $x i32)
    (drop
      (local.get $x)
    )
  )

  ;; CHECK:      (func $do-calls
  ;; CHECK-NEXT:  (call_indirect $0 (type $i)
  ;; CHECK-NEXT:   (i32.const 42)
  ;; CHECK-NEXT:   (i32.const 0)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (call_indirect $0 (type $f)
  ;; CHECK-NEXT:   (f32.const 1337)
  ;; CHECK-NEXT:   (i32.const 0)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $do-calls
    (call_indirect (type $i)
      (i32.const 42)
      (i32.const 0)
    )
    (call_indirect (type $f)
      (f32.const 1337)
      (i32.const 0)
    )
  )
)

(module
  ;; CHECK:      (type $none_=>_i32 (func (result i32)))

  ;; CHECK:      (type $none_=>_none (func))

  ;; CHECK:      (func $const (result i32)
  ;; CHECK-NEXT:  (i32.const 42)
  ;; CHECK-NEXT: )
  (func $const (result i32)
    ;; Return a const to the caller below.
    (i32.const 42)
  )

  ;; CHECK:      (func $retcall (result i32)
  ;; CHECK-NEXT:  (return_call $const)
  ;; CHECK-NEXT: )
  (func $retcall (result i32)
    ;; Do a return call. This tests that we pass its value out as a result.
    (return_call $const)
  )

  ;; CHECK:      (func $caller
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block (result i32)
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (call $retcall)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (i32.const 42)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $caller
    ;; Call the return caller. We can optimize this value to 42.
    (drop
      (call $retcall)
    )
  )
)

;; Imports have unknown values.
(module
  ;; CHECK:      (type $none_=>_i32 (func (result i32)))

  ;; CHECK:      (type $none_=>_none (func))

  ;; CHECK:      (import "a" "b" (func $import (result i32)))
  (import "a" "b" (func $import (result i32)))

  ;; CHECK:      (func $internal (result i32)
  ;; CHECK-NEXT:  (i32.const 42)
  ;; CHECK-NEXT: )
  (func $internal (result i32)
    (i32.const 42)
  )

  ;; CHECK:      (func $calls
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (call $import)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block (result i32)
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (call $internal)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (i32.const 42)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $calls
    (drop
      (call $import)
    )
    (drop
      (call $internal)
    )
  )
)
