;; NOTE: Assertions have been generated by update_lit_checks.py --all-items and should not be edited.

;; Check that array types and operations are emitted properly in the binary format.

;; RUN: wasm-opt %s -all -S -o - | filecheck %s
;; RUN: wasm-opt %s -all --roundtrip -S -o - | filecheck %s --check-prefix=ROUNDTRIP

;; Check that we can roundtrip through the text format as well.

;; RUN: wasm-opt %s -all -S -o - | wasm-opt -all -S -o - | filecheck %s

(module
 ;; CHECK:      (type $0 (func (param arrayref) (result i32)))

 ;; CHECK:      (type $byte-array (array (mut i8)))
 ;; ROUNDTRIP:      (type $0 (func (param arrayref) (result i32)))

 ;; ROUNDTRIP:      (type $byte-array (array (mut i8)))
 (type $byte-array (array (mut i8)))
 ;; CHECK:      (type $func-array (array (mut funcref)))
 ;; ROUNDTRIP:      (type $func-array (array (mut funcref)))
 (type $func-array (array (mut funcref)))

 (data "hello")
 (elem func $len $impossible-len $unreachable-len)


 ;; CHECK:      (type $3 (func (param (ref array)) (result i32)))

 ;; CHECK:      (type $4 (func (param nullref) (result i32)))

 ;; CHECK:      (type $5 (func (result (ref $byte-array))))

 ;; CHECK:      (type $6 (func (result (ref $func-array))))

 ;; CHECK:      (data $0 "hello")

 ;; CHECK:      (elem $0 func $len $impossible-len $unreachable-len)

 ;; CHECK:      (func $len (type $3) (param $a (ref array)) (result i32)
 ;; CHECK-NEXT:  (array.len
 ;; CHECK-NEXT:   (local.get $a)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 ;; ROUNDTRIP:      (type $3 (func (param (ref array)) (result i32)))

 ;; ROUNDTRIP:      (type $4 (func (param nullref) (result i32)))

 ;; ROUNDTRIP:      (type $5 (func (result (ref $byte-array))))

 ;; ROUNDTRIP:      (type $6 (func (result (ref $func-array))))

 ;; ROUNDTRIP:      (data $0 "hello")

 ;; ROUNDTRIP:      (elem $0 func $len $impossible-len $unreachable-len)

 ;; ROUNDTRIP:      (func $len (type $3) (param $a (ref array)) (result i32)
 ;; ROUNDTRIP-NEXT:  (array.len
 ;; ROUNDTRIP-NEXT:   (local.get $a)
 ;; ROUNDTRIP-NEXT:  )
 ;; ROUNDTRIP-NEXT: )
 (func $len (param $a (ref array)) (result i32)
  (array.len
   (local.get $a)
  )
 )

 ;; CHECK:      (func $impossible-len (type $4) (param $none nullref) (result i32)
 ;; CHECK-NEXT:  (array.len
 ;; CHECK-NEXT:   (local.get $none)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 ;; ROUNDTRIP:      (func $impossible-len (type $4) (param $none nullref) (result i32)
 ;; ROUNDTRIP-NEXT:  (array.len
 ;; ROUNDTRIP-NEXT:   (local.get $none)
 ;; ROUNDTRIP-NEXT:  )
 ;; ROUNDTRIP-NEXT: )
 (func $impossible-len (param $none nullref) (result i32)
  (array.len
   (local.get $none)
  )
 )

 ;; CHECK:      (func $unreachable-len (type $0) (param $a arrayref) (result i32)
 ;; CHECK-NEXT:  (array.len
 ;; CHECK-NEXT:   (unreachable)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 ;; ROUNDTRIP:      (func $unreachable-len (type $0) (param $a arrayref) (result i32)
 ;; ROUNDTRIP-NEXT:  (unreachable)
 ;; ROUNDTRIP-NEXT: )
 (func $unreachable-len (param $a arrayref) (result i32)
  (array.len
   (unreachable)
  )
 )

 ;; CHECK:      (func $unannotated-len (type $0) (param $a arrayref) (result i32)
 ;; CHECK-NEXT:  (array.len
 ;; CHECK-NEXT:   (local.get $a)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 ;; ROUNDTRIP:      (func $unannotated-len (type $0) (param $a arrayref) (result i32)
 ;; ROUNDTRIP-NEXT:  (array.len
 ;; ROUNDTRIP-NEXT:   (local.get $a)
 ;; ROUNDTRIP-NEXT:  )
 ;; ROUNDTRIP-NEXT: )
 (func $unannotated-len (param $a arrayref) (result i32)
  (array.len
   (local.get $a)
  )
 )

 ;; CHECK:      (func $new-data (type $5) (result (ref $byte-array))
 ;; CHECK-NEXT:  (array.new_data $byte-array $0
 ;; CHECK-NEXT:   (i32.const 0)
 ;; CHECK-NEXT:   (i32.const 5)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 ;; ROUNDTRIP:      (func $new-data (type $5) (result (ref $byte-array))
 ;; ROUNDTRIP-NEXT:  (array.new_data $byte-array $0
 ;; ROUNDTRIP-NEXT:   (i32.const 0)
 ;; ROUNDTRIP-NEXT:   (i32.const 5)
 ;; ROUNDTRIP-NEXT:  )
 ;; ROUNDTRIP-NEXT: )
 (func $new-data (result (ref $byte-array))
  (array.new_data $byte-array 0
   (i32.const 0)
   (i32.const 5)
  )
 )

 ;; CHECK:      (func $new-elem (type $6) (result (ref $func-array))
 ;; CHECK-NEXT:  (array.new_elem $func-array $0
 ;; CHECK-NEXT:   (i32.const 0)
 ;; CHECK-NEXT:   (i32.const 3)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 ;; ROUNDTRIP:      (func $new-elem (type $6) (result (ref $func-array))
 ;; ROUNDTRIP-NEXT:  (array.new_elem $func-array $0
 ;; ROUNDTRIP-NEXT:   (i32.const 0)
 ;; ROUNDTRIP-NEXT:   (i32.const 3)
 ;; ROUNDTRIP-NEXT:  )
 ;; ROUNDTRIP-NEXT: )
 (func $new-elem (result (ref $func-array))
  (array.new_elem $func-array 0
   (i32.const 0)
   (i32.const 3)
  )
 )
)
