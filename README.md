# base64-simd

### Benchmark

- ArchLinux 6.3.9-arch1-1
- CPU: AMD Ryzen 7 5800H with Radeon Graphics @ 16x 3.2GHz
- Zig: 0.11.0-dev.3739+939e4d81e, `-Doptimize=ReleaseFast`
- Benchmark Tools: hyperfine 1.17.0

1000 rounds of testing, encoding 9990 records each time.

```
Command './zig-out/bin/bench --std'
  runs:       1000
  mean:      0.030 s
  stddev:    0.001 s
  median:    0.030 s
  min:       0.029 s
  max:       0.036 s

  percentiles:
     P_05 .. P_95:    0.029 s .. 0.032 s
     P_25 .. P_75:    0.030 s .. 0.031 s  (IQR = 0.001 s)

Command './zig-out/bin/bench --simd'
  runs:       1000
  mean:      0.019 s
  stddev:    0.001 s
  median:    0.019 s
  min:       0.018 s
  max:       0.024 s

  percentiles:
     P_05 .. P_95:    0.018 s .. 0.020 s
     P_25 .. P_75:    0.019 s .. 0.019 s  (IQR = 0.001 s)
```
