Dynamic Ruby Debugger
---------------------

Ruby debugging tool that avoids file reload time when debugging running code. This is done by injecting a fixed line (see below)
that works by a configuration independent by the inspected code.

Example of a code inspection:

```
my_var = DynamicDebugger.debug(:bar) { bar()  }
                                      ^    ^^^
                                      A    BCD

- (A) Pre-call inspection
- (B) Return value inspection
- (C) Post-call inspection
- (D) Return value alteration
```

Example configuration:

```yaml
breakpoints:
  bar:
    enabled: true
    return:
    return_code: foo.bar()
    return_call:
    - puts retval
    pre_call:
    - call_experiment_method()
    - puts result
    post_call:
    - GC.disable
```

## What can you do at a "breakpoint"?

- Print (log, etc) local scope variables / state
- Run a debugger (`binging.pry`)
- Change local state
- Alter the enclosed (inside `{ ... }`) expression
- Toggle
- Unlimited number of breakpoints (tagged uniquely)
