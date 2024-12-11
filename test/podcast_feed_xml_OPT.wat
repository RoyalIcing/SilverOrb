(module
  (type (;0;) (func (result i32 i32)))
  (type (;1;) (func (param i32 i32) (result i32)))
  (type (;2;) (func))
  (type (;3;) (func (param i32 i32)))
  (type (;4;) (func (result i32)))
  (type (;5;) (func (param i32 i32 i32 i32)))
  (import "datasource" "get_episodes_count" (func (;0;) (type 4)))
  (import "datasource" "write_episode_id" (func (;1;) (type 1)))
  (import "datasource" "write_episode_title" (func (;2;) (type 1)))
  (import "datasource" "write_episode_description" (func (;3;) (type 1)))
  (func (;4;) (type 2)
    global.get 2
    i32.eqz
    if  ;; label = @1
      i32.const 65536
      global.set 0
      i32.const 65536
      global.set 1
    end
    global.get 2
    i32.const 1
    i32.add
    global.set 2)
  (func (;5;) (type 0) (result i32 i32)
    global.get 2
    i32.const 0
    i32.le_s
    if  ;; label = @1
      unreachable
    end
    global.get 2
    i32.const 1
    i32.sub
    global.set 2
    global.get 1
    global.get 0
    global.get 1
    i32.sub)
  (func (;6;) (type 3) (param i32 i32)
    (local i32)
    local.get 1
    i32.eqz
    local.get 0
    global.get 1
    i32.eq
    i32.or
    if  ;; label = @1
      return
    end
    loop  ;; label = @1
      global.get 0
      local.get 2
      i32.add
      local.get 0
      local.get 2
      i32.add
      i32.load8_u
      i32.store8
      local.get 1
      local.get 2
      i32.gt_s
      if  ;; label = @2
        local.get 2
        i32.const 1
        i32.add
        local.set 2
        br 1 (;@1;)
      end
    end
    global.get 0
    local.get 1
    i32.add
    global.set 0)
  (func (;7;) (type 3) (param i32 i32)
    (local i32 i32)
    call 4
    i32.const 758
    i32.const 2
    call 6
    local.get 0
    local.get 1
    call 6
    i32.const 761
    i32.const 2
    call 6
    call 5
    local.set 3
    local.set 2)
  (func (;8;) (type 5) (param i32 i32 i32 i32)
    call 4
    i32.const 764
    i32.const 1
    call 6
    local.get 0
    local.get 1
    call 6
    i32.const 766
    i32.const 1
    call 6
    call 4
    i32.const 270
    i32.const 9
    call 6
    local.get 2
    local.get 3
    call 6
    i32.const 307
    i32.const 3
    call 6
    call 5
    drop
    drop
    i32.const 758
    i32.const 2
    call 6
    local.get 0
    local.get 1
    call 6
    i32.const 768
    i32.const 3
    call 6
    call 5
    drop
    drop)
  (func (;9;) (type 2)
    (local i32 i32)
    call 0
    local.tee 1
    i32.eqz
    if  ;; label = @1
      return
    end
    loop  ;; label = @1
      call 4
      i32.const 264
      i32.const 5
      call 6
      global.get 0
      i32.const 62
      i32.store8
      global.get 0
      i32.const 1
      i32.add
      global.set 0
      i32.const 280
      i32.const 5
      call 6
      i32.const 286
      i32.const 14
      call 6
      i32.const 301
      i32.const 5
      call 6
      global.get 0
      i32.const 34
      i32.store8
      global.get 0
      i32.const 1
      i32.add
      global.set 0
      global.get 0
      i32.const 62
      i32.store8
      global.get 0
      i32.const 1
      i32.add
      global.set 0
      i32.const 270
      i32.const 9
      call 6
      global.get 0
      local.get 0
      global.get 0
      call 1
      i32.add
      global.set 0
      i32.const 307
      i32.const 3
      call 6
      i32.const 311
      i32.const 4
      call 7
      i32.const 316
      i32.const 6
      call 6
      global.get 0
      i32.const 62
      i32.store8
      global.get 0
      i32.const 1
      i32.add
      global.set 0
      i32.const 270
      i32.const 9
      call 6
      global.get 0
      local.get 0
      global.get 0
      call 2
      i32.add
      global.set 0
      i32.const 307
      i32.const 3
      call 6
      i32.const 323
      i32.const 5
      call 7
      i32.const 329
      i32.const 13
      call 6
      global.get 0
      i32.const 62
      i32.store8
      global.get 0
      i32.const 1
      i32.add
      global.set 0
      i32.const 270
      i32.const 9
      call 6
      global.get 0
      local.get 0
      global.get 0
      call 2
      i32.add
      global.set 0
      i32.const 307
      i32.const 3
      call 6
      i32.const 343
      i32.const 12
      call 7
      i32.const 356
      i32.const 12
      call 6
      global.get 0
      i32.const 62
      i32.store8
      global.get 0
      i32.const 1
      i32.add
      global.set 0
      i32.const 270
      i32.const 9
      call 6
      global.get 0
      local.get 0
      global.get 0
      call 3
      i32.add
      global.set 0
      i32.const 307
      i32.const 3
      call 6
      i32.const 369
      i32.const 11
      call 7
      i32.const 381
      i32.const 16
      call 6
      global.get 0
      i32.const 62
      i32.store8
      global.get 0
      i32.const 1
      i32.add
      global.set 0
      i32.const 270
      i32.const 9
      call 6
      global.get 0
      local.get 0
      global.get 0
      call 3
      i32.add
      global.set 0
      i32.const 307
      i32.const 3
      call 6
      i32.const 398
      i32.const 15
      call 7
      i32.const 414
      i32.const 4
      call 7
      call 5
      drop
      drop
      local.get 0
      i32.const 1
      i32.add
      local.tee 0
      local.get 1
      i32.lt_s
      br_if 0 (;@1;)
    end)
  (func (;10;) (type 0) (result i32 i32)
    (local i32 i32)
    call 4
    i32.const 419
    i32.const 39
    call 6
    i32.const 459
    i32.const 4
    call 6
    i32.const 464
    i32.const 10
    call 6
    i32.const 475
    i32.const 3
    call 6
    global.get 0
    i32.const 34
    i32.store8
    global.get 0
    i32.const 1
    i32.add
    global.set 0
    i32.const 479
    i32.const 15
    call 6
    i32.const 495
    i32.const 42
    call 6
    global.get 0
    i32.const 34
    i32.store8
    global.get 0
    i32.const 1
    i32.add
    global.set 0
    i32.const 538
    i32.const 19
    call 6
    i32.const 558
    i32.const 47
    call 6
    global.get 0
    i32.const 34
    i32.store8
    global.get 0
    i32.const 1
    i32.add
    global.set 0
    i32.const 606
    i32.const 11
    call 6
    i32.const 618
    i32.const 32
    call 6
    global.get 0
    i32.const 34
    i32.store8
    global.get 0
    i32.const 1
    i32.add
    global.set 0
    i32.const 651
    i32.const 16
    call 6
    i32.const 668
    i32.const 40
    call 6
    global.get 0
    i32.const 34
    i32.store8
    global.get 0
    i32.const 1
    i32.add
    global.set 0
    global.get 0
    i32.const 62
    i32.store8
    global.get 0
    i32.const 1
    i32.add
    global.set 0
    global.get 0
    i32.const 10
    i32.store8
    global.get 0
    i32.const 1
    i32.add
    global.set 0
    i32.const 709
    i32.const 8
    call 6
    global.get 0
    i32.const 62
    i32.store8
    global.get 0
    i32.const 1
    i32.add
    global.set 0
    global.get 0
    i32.const 10
    i32.store8
    global.get 0
    i32.const 1
    i32.add
    global.set 0
    i32.const 323
    i32.const 5
    global.get 3
    i32.wrap_i64
    global.get 3
    i64.const 32
    i64.shr_u
    i32.wrap_i64
    call 8
    i32.const 369
    i32.const 11
    global.get 4
    i32.wrap_i64
    global.get 4
    i64.const 32
    i64.shr_u
    i32.wrap_i64
    call 8
    i32.const 398
    i32.const 15
    global.get 4
    i32.wrap_i64
    global.get 4
    i64.const 32
    i64.shr_u
    i32.wrap_i64
    call 8
    i32.const 718
    i32.const 13
    global.get 5
    i32.wrap_i64
    global.get 5
    i64.const 32
    i64.shr_u
    i32.wrap_i64
    call 8
    i32.const 732
    i32.const 4
    global.get 6
    i32.wrap_i64
    global.get 6
    i64.const 32
    i64.shr_u
    i32.wrap_i64
    call 8
    i32.const 737
    i32.const 8
    global.get 7
    i32.wrap_i64
    global.get 7
    i64.const 32
    i64.shr_u
    i32.wrap_i64
    call 8
    call 9
    i32.const 746
    i32.const 7
    call 7
    i32.const 754
    i32.const 3
    call 7
    call 5
    local.set 1
    local.tee 0
    local.get 1)
  (memory (;0;) 67)
  (global (;0;) (mut i32) (i32.const 65536))
  (global (;1;) (mut i32) (i32.const 0))
  (global (;2;) (mut i32) (i32.const 0))
  (global (;3;) (mut i64) (i64.const 21474836735))
  (global (;4;) (mut i64) (i64.const 0))
  (global (;5;) (mut i64) (i64.const 0))
  (global (;6;) (mut i64) (i64.const 0))
  (global (;7;) (mut i64) (i64.const 8589934853))
  (export "memory" (memory 0))
  (export "title" (global 3))
  (export "description" (global 4))
  (export "author" (global 5))
  (export "link" (global 6))
  (export "language" (global 7))
  (export "write_episodes_xml" (func 9))
  (export "text_xml" (func 10))
  (data (;0;) (i32.const 255) "hello")
  (data (;1;) (i32.const 261) "en")
  (data (;2;) (i32.const 264) "<item")
  (data (;3;) (i32.const 270) "<![CDATA[")
  (data (;4;) (i32.const 280) "<guid")
  (data (;5;) (i32.const 286) " isPermaLink=\22")
  (data (;6;) (i32.const 301) "false")
  (data (;7;) (i32.const 307) "]]>")
  (data (;8;) (i32.const 311) "guid")
  (data (;9;) (i32.const 316) "<title")
  (data (;10;) (i32.const 323) "title")
  (data (;11;) (i32.const 329) "<itunes:title")
  (data (;12;) (i32.const 343) "itunes:title")
  (data (;13;) (i32.const 356) "<description")
  (data (;14;) (i32.const 369) "description")
  (data (;15;) (i32.const 381) "<itunes:subtitle")
  (data (;16;) (i32.const 398) "itunes:subtitle")
  (data (;17;) (i32.const 414) "item")
  (data (;18;) (i32.const 419) "<?xml version=\221.0\22 encoding=\22UTF-8\22?>\0a")
  (data (;19;) (i32.const 459) "<rss")
  (data (;20;) (i32.const 464) " version=\22")
  (data (;21;) (i32.const 475) "2.0")
  (data (;22;) (i32.const 479) " xmlns:itunes=\22")
  (data (;23;) (i32.const 495) "http://www.itunes.com/dtds/podcast-1.0.dtd")
  (data (;24;) (i32.const 538) " xmlns:googleplay=\22")
  (data (;25;) (i32.const 558) "http://www.google.com/schemas/play-podcasts/1.0")
  (data (;26;) (i32.const 606) " xmlns:dc=\22")
  (data (;27;) (i32.const 618) "http://purl.org/dc/elements/1.1/")
  (data (;28;) (i32.const 651) " xmlns:content=\22")
  (data (;29;) (i32.const 668) "http://purl.org/rss/1.0/modules/content/")
  (data (;30;) (i32.const 709) "<channel")
  (data (;31;) (i32.const 718) "itunes:author")
  (data (;32;) (i32.const 732) "link")
  (data (;33;) (i32.const 737) "language")
  (data (;34;) (i32.const 746) "channel")
  (data (;35;) (i32.const 754) "rss")
  (data (;36;) (i32.const 758) "</")
  (data (;37;) (i32.const 761) ">\0a")
  (data (;38;) (i32.const 764) "<")
  (data (;39;) (i32.const 766) ">")
  (data (;40;) (i32.const 768) ">\5cn"))
