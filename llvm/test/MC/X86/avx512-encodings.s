// RUN: llvm-mc -triple x86_64-unknown-unknown -mcpu=knl --show-encoding %s | FileCheck %s

// CHECK: vinserti32x4
// CHECK: encoding: [0x62,0xa3,0x55,0x48,0x38,0xcd,0x01]
vinserti32x4  $1, %xmm21, %zmm5, %zmm17

// CHECK: vinserti32x4
// CHECK: encoding: [0x62,0xe3,0x1d,0x40,0x38,0x4f,0x10,0x01]
vinserti32x4  $1, 256(%rdi), %zmm28, %zmm17

// CHECK: vextracti32x4
// CHECK: encoding: [0x62,0x33,0x7d,0x48,0x39,0xc9,0x01]
vextracti32x4  $1, %zmm9, %xmm17

// CHECK: vextracti64x4
// CHECK: encoding: [0x62,0x33,0xfd,0x48,0x3b,0xc9,0x01]
vextracti64x4  $1, %zmm9, %ymm17

// CHECK: vextracti64x4
// CHECK: encoding: [0x62,0x73,0xfd,0x48,0x3b,0x4f,0x10,0x01]
vextracti64x4  $1, %zmm9, 512(%rdi)

// CHECK: vpsrad
// CHECK: encoding: [0x62,0xb1,0x35,0x40,0x72,0xe1,0x02]
vpsrad $2, %zmm17, %zmm25

// CHECK: vpsrad
// CHECK: encoding: [0x62,0xf1,0x35,0x40,0x72,0x64,0xb7,0x08,0x02]
vpsrad $2, 512(%rdi, %rsi, 4), %zmm25

// CHECK: vpsrad
// CHECK: encoding: [0x62,0x21,0x1d,0x48,0xe2,0xc9]
vpsrad %xmm17, %zmm12, %zmm25

// CHECK: vpsrad
// CHECK: encoding: [0x62,0x61,0x1d,0x48,0xe2,0x4c,0xb7,0x20]
vpsrad 512(%rdi, %rsi, 4), %zmm12, %zmm25

// CHECK: vpbroadcastd {{.*}} {%k1} {z}
// CHECK: encoding: [0x62,0xf2,0x7d,0xc9,0x58,0xc8]
vpbroadcastd  %xmm0, %zmm1 {%k1} {z}

// CHECK: vmovdqu64 {{.*}} {%k3}
// CHECK: encoding: [0x62,0xf1,0xfe,0x4b,0x6f,0xc8]
vmovdqu64 %zmm0, %zmm1 {%k3}

// CHECK: vmovd
// CHECK: encoding: [0x62,0xe1,0x7d,0x08,0x7e,0xb4,0x24,0xac,0xff,0xff,0xff]
vmovd %xmm22, -84(%rsp)

// CHECK: vextractps
// CHECK: encoding: [0x62,0xe3,0x7d,0x08,0x17,0x61,0x1f,0x02]
vextractps      $2, %xmm20, 124(%rcx)
