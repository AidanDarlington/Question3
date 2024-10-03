
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	18010113          	addi	sp,sp,384 # 80009180 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	d7c78793          	addi	a5,a5,-644 # 80005de0 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dc478793          	addi	a5,a5,-572 # 80000e72 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	324080e7          	jalr	804(ra) # 80002450 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	77a080e7          	jalr	1914(ra) # 800008b6 <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	ff650513          	addi	a0,a0,-10 # 80011180 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a3e080e7          	jalr	-1474(ra) # 80000bd0 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	fe648493          	addi	s1,s1,-26 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	07690913          	addi	s2,s2,118 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305863          	blez	s3,80000220 <consoleread+0xbc>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71463          	bne	a4,a5,800001e4 <consoleread+0x80>
      if(myproc()->killed){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7d6080e7          	jalr	2006(ra) # 80001996 <myproc>
    800001c8:	551c                	lw	a5,40(a0)
    800001ca:	e7b5                	bnez	a5,80000236 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001cc:	85a6                	mv	a1,s1
    800001ce:	854a                	mv	a0,s2
    800001d0:	00002097          	auipc	ra,0x2
    800001d4:	e86080e7          	jalr	-378(ra) # 80002056 <sleep>
    while(cons.r == cons.w){
    800001d8:	0984a783          	lw	a5,152(s1)
    800001dc:	09c4a703          	lw	a4,156(s1)
    800001e0:	fef700e3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e4:	0017871b          	addiw	a4,a5,1
    800001e8:	08e4ac23          	sw	a4,152(s1)
    800001ec:	07f7f713          	andi	a4,a5,127
    800001f0:	9726                	add	a4,a4,s1
    800001f2:	01874703          	lbu	a4,24(a4)
    800001f6:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    800001fa:	077d0563          	beq	s10,s7,80000264 <consoleread+0x100>
    cbuf = c;
    800001fe:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000202:	4685                	li	a3,1
    80000204:	f9f40613          	addi	a2,s0,-97
    80000208:	85d2                	mv	a1,s4
    8000020a:	8556                	mv	a0,s5
    8000020c:	00002097          	auipc	ra,0x2
    80000210:	1ee080e7          	jalr	494(ra) # 800023fa <either_copyout>
    80000214:	01850663          	beq	a0,s8,80000220 <consoleread+0xbc>
    dst++;
    80000218:	0a05                	addi	s4,s4,1
    --n;
    8000021a:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    8000021c:	f99d1ae3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000220:	00011517          	auipc	a0,0x11
    80000224:	f6050513          	addi	a0,a0,-160 # 80011180 <cons>
    80000228:	00001097          	auipc	ra,0x1
    8000022c:	a5c080e7          	jalr	-1444(ra) # 80000c84 <release>

  return target - n;
    80000230:	413b053b          	subw	a0,s6,s3
    80000234:	a811                	j	80000248 <consoleread+0xe4>
        release(&cons.lock);
    80000236:	00011517          	auipc	a0,0x11
    8000023a:	f4a50513          	addi	a0,a0,-182 # 80011180 <cons>
    8000023e:	00001097          	auipc	ra,0x1
    80000242:	a46080e7          	jalr	-1466(ra) # 80000c84 <release>
        return -1;
    80000246:	557d                	li	a0,-1
}
    80000248:	70a6                	ld	ra,104(sp)
    8000024a:	7406                	ld	s0,96(sp)
    8000024c:	64e6                	ld	s1,88(sp)
    8000024e:	6946                	ld	s2,80(sp)
    80000250:	69a6                	ld	s3,72(sp)
    80000252:	6a06                	ld	s4,64(sp)
    80000254:	7ae2                	ld	s5,56(sp)
    80000256:	7b42                	ld	s6,48(sp)
    80000258:	7ba2                	ld	s7,40(sp)
    8000025a:	7c02                	ld	s8,32(sp)
    8000025c:	6ce2                	ld	s9,24(sp)
    8000025e:	6d42                	ld	s10,16(sp)
    80000260:	6165                	addi	sp,sp,112
    80000262:	8082                	ret
      if(n < target){
    80000264:	0009871b          	sext.w	a4,s3
    80000268:	fb677ce3          	bgeu	a4,s6,80000220 <consoleread+0xbc>
        cons.r--;
    8000026c:	00011717          	auipc	a4,0x11
    80000270:	faf72623          	sw	a5,-84(a4) # 80011218 <cons+0x98>
    80000274:	b775                	j	80000220 <consoleread+0xbc>

0000000080000276 <consputc>:
{
    80000276:	1141                	addi	sp,sp,-16
    80000278:	e406                	sd	ra,8(sp)
    8000027a:	e022                	sd	s0,0(sp)
    8000027c:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000027e:	10000793          	li	a5,256
    80000282:	00f50a63          	beq	a0,a5,80000296 <consputc+0x20>
    uartputc_sync(c);
    80000286:	00000097          	auipc	ra,0x0
    8000028a:	55e080e7          	jalr	1374(ra) # 800007e4 <uartputc_sync>
}
    8000028e:	60a2                	ld	ra,8(sp)
    80000290:	6402                	ld	s0,0(sp)
    80000292:	0141                	addi	sp,sp,16
    80000294:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000296:	4521                	li	a0,8
    80000298:	00000097          	auipc	ra,0x0
    8000029c:	54c080e7          	jalr	1356(ra) # 800007e4 <uartputc_sync>
    800002a0:	02000513          	li	a0,32
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	540080e7          	jalr	1344(ra) # 800007e4 <uartputc_sync>
    800002ac:	4521                	li	a0,8
    800002ae:	00000097          	auipc	ra,0x0
    800002b2:	536080e7          	jalr	1334(ra) # 800007e4 <uartputc_sync>
    800002b6:	bfe1                	j	8000028e <consputc+0x18>

00000000800002b8 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002b8:	1101                	addi	sp,sp,-32
    800002ba:	ec06                	sd	ra,24(sp)
    800002bc:	e822                	sd	s0,16(sp)
    800002be:	e426                	sd	s1,8(sp)
    800002c0:	e04a                	sd	s2,0(sp)
    800002c2:	1000                	addi	s0,sp,32
    800002c4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002c6:	00011517          	auipc	a0,0x11
    800002ca:	eba50513          	addi	a0,a0,-326 # 80011180 <cons>
    800002ce:	00001097          	auipc	ra,0x1
    800002d2:	902080e7          	jalr	-1790(ra) # 80000bd0 <acquire>

  switch(c){
    800002d6:	47d5                	li	a5,21
    800002d8:	0af48663          	beq	s1,a5,80000384 <consoleintr+0xcc>
    800002dc:	0297ca63          	blt	a5,s1,80000310 <consoleintr+0x58>
    800002e0:	47a1                	li	a5,8
    800002e2:	0ef48763          	beq	s1,a5,800003d0 <consoleintr+0x118>
    800002e6:	47c1                	li	a5,16
    800002e8:	10f49a63          	bne	s1,a5,800003fc <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002ec:	00002097          	auipc	ra,0x2
    800002f0:	1ba080e7          	jalr	442(ra) # 800024a6 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002f4:	00011517          	auipc	a0,0x11
    800002f8:	e8c50513          	addi	a0,a0,-372 # 80011180 <cons>
    800002fc:	00001097          	auipc	ra,0x1
    80000300:	988080e7          	jalr	-1656(ra) # 80000c84 <release>
}
    80000304:	60e2                	ld	ra,24(sp)
    80000306:	6442                	ld	s0,16(sp)
    80000308:	64a2                	ld	s1,8(sp)
    8000030a:	6902                	ld	s2,0(sp)
    8000030c:	6105                	addi	sp,sp,32
    8000030e:	8082                	ret
  switch(c){
    80000310:	07f00793          	li	a5,127
    80000314:	0af48e63          	beq	s1,a5,800003d0 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000318:	00011717          	auipc	a4,0x11
    8000031c:	e6870713          	addi	a4,a4,-408 # 80011180 <cons>
    80000320:	0a072783          	lw	a5,160(a4)
    80000324:	09872703          	lw	a4,152(a4)
    80000328:	9f99                	subw	a5,a5,a4
    8000032a:	07f00713          	li	a4,127
    8000032e:	fcf763e3          	bltu	a4,a5,800002f4 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000332:	47b5                	li	a5,13
    80000334:	0cf48763          	beq	s1,a5,80000402 <consoleintr+0x14a>
      consputc(c);
    80000338:	8526                	mv	a0,s1
    8000033a:	00000097          	auipc	ra,0x0
    8000033e:	f3c080e7          	jalr	-196(ra) # 80000276 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000342:	00011797          	auipc	a5,0x11
    80000346:	e3e78793          	addi	a5,a5,-450 # 80011180 <cons>
    8000034a:	0a07a703          	lw	a4,160(a5)
    8000034e:	0017069b          	addiw	a3,a4,1
    80000352:	0006861b          	sext.w	a2,a3
    80000356:	0ad7a023          	sw	a3,160(a5)
    8000035a:	07f77713          	andi	a4,a4,127
    8000035e:	97ba                	add	a5,a5,a4
    80000360:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000364:	47a9                	li	a5,10
    80000366:	0cf48563          	beq	s1,a5,80000430 <consoleintr+0x178>
    8000036a:	4791                	li	a5,4
    8000036c:	0cf48263          	beq	s1,a5,80000430 <consoleintr+0x178>
    80000370:	00011797          	auipc	a5,0x11
    80000374:	ea87a783          	lw	a5,-344(a5) # 80011218 <cons+0x98>
    80000378:	0807879b          	addiw	a5,a5,128
    8000037c:	f6f61ce3          	bne	a2,a5,800002f4 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000380:	863e                	mv	a2,a5
    80000382:	a07d                	j	80000430 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000384:	00011717          	auipc	a4,0x11
    80000388:	dfc70713          	addi	a4,a4,-516 # 80011180 <cons>
    8000038c:	0a072783          	lw	a5,160(a4)
    80000390:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000394:	00011497          	auipc	s1,0x11
    80000398:	dec48493          	addi	s1,s1,-532 # 80011180 <cons>
    while(cons.e != cons.w &&
    8000039c:	4929                	li	s2,10
    8000039e:	f4f70be3          	beq	a4,a5,800002f4 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a2:	37fd                	addiw	a5,a5,-1
    800003a4:	07f7f713          	andi	a4,a5,127
    800003a8:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003aa:	01874703          	lbu	a4,24(a4)
    800003ae:	f52703e3          	beq	a4,s2,800002f4 <consoleintr+0x3c>
      cons.e--;
    800003b2:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003b6:	10000513          	li	a0,256
    800003ba:	00000097          	auipc	ra,0x0
    800003be:	ebc080e7          	jalr	-324(ra) # 80000276 <consputc>
    while(cons.e != cons.w &&
    800003c2:	0a04a783          	lw	a5,160(s1)
    800003c6:	09c4a703          	lw	a4,156(s1)
    800003ca:	fcf71ce3          	bne	a4,a5,800003a2 <consoleintr+0xea>
    800003ce:	b71d                	j	800002f4 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d0:	00011717          	auipc	a4,0x11
    800003d4:	db070713          	addi	a4,a4,-592 # 80011180 <cons>
    800003d8:	0a072783          	lw	a5,160(a4)
    800003dc:	09c72703          	lw	a4,156(a4)
    800003e0:	f0f70ae3          	beq	a4,a5,800002f4 <consoleintr+0x3c>
      cons.e--;
    800003e4:	37fd                	addiw	a5,a5,-1
    800003e6:	00011717          	auipc	a4,0x11
    800003ea:	e2f72d23          	sw	a5,-454(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003ee:	10000513          	li	a0,256
    800003f2:	00000097          	auipc	ra,0x0
    800003f6:	e84080e7          	jalr	-380(ra) # 80000276 <consputc>
    800003fa:	bded                	j	800002f4 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    800003fc:	ee048ce3          	beqz	s1,800002f4 <consoleintr+0x3c>
    80000400:	bf21                	j	80000318 <consoleintr+0x60>
      consputc(c);
    80000402:	4529                	li	a0,10
    80000404:	00000097          	auipc	ra,0x0
    80000408:	e72080e7          	jalr	-398(ra) # 80000276 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000040c:	00011797          	auipc	a5,0x11
    80000410:	d7478793          	addi	a5,a5,-652 # 80011180 <cons>
    80000414:	0a07a703          	lw	a4,160(a5)
    80000418:	0017069b          	addiw	a3,a4,1
    8000041c:	0006861b          	sext.w	a2,a3
    80000420:	0ad7a023          	sw	a3,160(a5)
    80000424:	07f77713          	andi	a4,a4,127
    80000428:	97ba                	add	a5,a5,a4
    8000042a:	4729                	li	a4,10
    8000042c:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000430:	00011797          	auipc	a5,0x11
    80000434:	dec7a623          	sw	a2,-532(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    80000438:	00011517          	auipc	a0,0x11
    8000043c:	de050513          	addi	a0,a0,-544 # 80011218 <cons+0x98>
    80000440:	00002097          	auipc	ra,0x2
    80000444:	da2080e7          	jalr	-606(ra) # 800021e2 <wakeup>
    80000448:	b575                	j	800002f4 <consoleintr+0x3c>

000000008000044a <consoleinit>:

void
consoleinit(void)
{
    8000044a:	1141                	addi	sp,sp,-16
    8000044c:	e406                	sd	ra,8(sp)
    8000044e:	e022                	sd	s0,0(sp)
    80000450:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000452:	00008597          	auipc	a1,0x8
    80000456:	bbe58593          	addi	a1,a1,-1090 # 80008010 <etext+0x10>
    8000045a:	00011517          	auipc	a0,0x11
    8000045e:	d2650513          	addi	a0,a0,-730 # 80011180 <cons>
    80000462:	00000097          	auipc	ra,0x0
    80000466:	6de080e7          	jalr	1758(ra) # 80000b40 <initlock>

  uartinit();
    8000046a:	00000097          	auipc	ra,0x0
    8000046e:	32a080e7          	jalr	810(ra) # 80000794 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000472:	00021797          	auipc	a5,0x21
    80000476:	f0e78793          	addi	a5,a5,-242 # 80021380 <devsw>
    8000047a:	00000717          	auipc	a4,0x0
    8000047e:	cea70713          	addi	a4,a4,-790 # 80000164 <consoleread>
    80000482:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000484:	00000717          	auipc	a4,0x0
    80000488:	c7e70713          	addi	a4,a4,-898 # 80000102 <consolewrite>
    8000048c:	ef98                	sd	a4,24(a5)
}
    8000048e:	60a2                	ld	ra,8(sp)
    80000490:	6402                	ld	s0,0(sp)
    80000492:	0141                	addi	sp,sp,16
    80000494:	8082                	ret

0000000080000496 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000496:	7179                	addi	sp,sp,-48
    80000498:	f406                	sd	ra,40(sp)
    8000049a:	f022                	sd	s0,32(sp)
    8000049c:	ec26                	sd	s1,24(sp)
    8000049e:	e84a                	sd	s2,16(sp)
    800004a0:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a2:	c219                	beqz	a2,800004a8 <printint+0x12>
    800004a4:	08054663          	bltz	a0,80000530 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004a8:	2501                	sext.w	a0,a0
    800004aa:	4881                	li	a7,0
    800004ac:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b0:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b2:	2581                	sext.w	a1,a1
    800004b4:	00008617          	auipc	a2,0x8
    800004b8:	b8c60613          	addi	a2,a2,-1140 # 80008040 <digits>
    800004bc:	883a                	mv	a6,a4
    800004be:	2705                	addiw	a4,a4,1
    800004c0:	02b577bb          	remuw	a5,a0,a1
    800004c4:	1782                	slli	a5,a5,0x20
    800004c6:	9381                	srli	a5,a5,0x20
    800004c8:	97b2                	add	a5,a5,a2
    800004ca:	0007c783          	lbu	a5,0(a5)
    800004ce:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d2:	0005079b          	sext.w	a5,a0
    800004d6:	02b5553b          	divuw	a0,a0,a1
    800004da:	0685                	addi	a3,a3,1
    800004dc:	feb7f0e3          	bgeu	a5,a1,800004bc <printint+0x26>

  if(sign)
    800004e0:	00088b63          	beqz	a7,800004f6 <printint+0x60>
    buf[i++] = '-';
    800004e4:	fe040793          	addi	a5,s0,-32
    800004e8:	973e                	add	a4,a4,a5
    800004ea:	02d00793          	li	a5,45
    800004ee:	fef70823          	sb	a5,-16(a4)
    800004f2:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004f6:	02e05763          	blez	a4,80000524 <printint+0x8e>
    800004fa:	fd040793          	addi	a5,s0,-48
    800004fe:	00e784b3          	add	s1,a5,a4
    80000502:	fff78913          	addi	s2,a5,-1
    80000506:	993a                	add	s2,s2,a4
    80000508:	377d                	addiw	a4,a4,-1
    8000050a:	1702                	slli	a4,a4,0x20
    8000050c:	9301                	srli	a4,a4,0x20
    8000050e:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000512:	fff4c503          	lbu	a0,-1(s1)
    80000516:	00000097          	auipc	ra,0x0
    8000051a:	d60080e7          	jalr	-672(ra) # 80000276 <consputc>
  while(--i >= 0)
    8000051e:	14fd                	addi	s1,s1,-1
    80000520:	ff2499e3          	bne	s1,s2,80000512 <printint+0x7c>
}
    80000524:	70a2                	ld	ra,40(sp)
    80000526:	7402                	ld	s0,32(sp)
    80000528:	64e2                	ld	s1,24(sp)
    8000052a:	6942                	ld	s2,16(sp)
    8000052c:	6145                	addi	sp,sp,48
    8000052e:	8082                	ret
    x = -xx;
    80000530:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000534:	4885                	li	a7,1
    x = -xx;
    80000536:	bf9d                	j	800004ac <printint+0x16>

0000000080000538 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000538:	1101                	addi	sp,sp,-32
    8000053a:	ec06                	sd	ra,24(sp)
    8000053c:	e822                	sd	s0,16(sp)
    8000053e:	e426                	sd	s1,8(sp)
    80000540:	1000                	addi	s0,sp,32
    80000542:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000544:	00011797          	auipc	a5,0x11
    80000548:	ce07ae23          	sw	zero,-772(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    8000054c:	00008517          	auipc	a0,0x8
    80000550:	acc50513          	addi	a0,a0,-1332 # 80008018 <etext+0x18>
    80000554:	00000097          	auipc	ra,0x0
    80000558:	02e080e7          	jalr	46(ra) # 80000582 <printf>
  printf(s);
    8000055c:	8526                	mv	a0,s1
    8000055e:	00000097          	auipc	ra,0x0
    80000562:	024080e7          	jalr	36(ra) # 80000582 <printf>
  printf("\n");
    80000566:	00008517          	auipc	a0,0x8
    8000056a:	b6250513          	addi	a0,a0,-1182 # 800080c8 <digits+0x88>
    8000056e:	00000097          	auipc	ra,0x0
    80000572:	014080e7          	jalr	20(ra) # 80000582 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000576:	4785                	li	a5,1
    80000578:	00009717          	auipc	a4,0x9
    8000057c:	a8f72423          	sw	a5,-1400(a4) # 80009000 <panicked>
  for(;;)
    80000580:	a001                	j	80000580 <panic+0x48>

0000000080000582 <printf>:
{
    80000582:	7131                	addi	sp,sp,-192
    80000584:	fc86                	sd	ra,120(sp)
    80000586:	f8a2                	sd	s0,112(sp)
    80000588:	f4a6                	sd	s1,104(sp)
    8000058a:	f0ca                	sd	s2,96(sp)
    8000058c:	ecce                	sd	s3,88(sp)
    8000058e:	e8d2                	sd	s4,80(sp)
    80000590:	e4d6                	sd	s5,72(sp)
    80000592:	e0da                	sd	s6,64(sp)
    80000594:	fc5e                	sd	s7,56(sp)
    80000596:	f862                	sd	s8,48(sp)
    80000598:	f466                	sd	s9,40(sp)
    8000059a:	f06a                	sd	s10,32(sp)
    8000059c:	ec6e                	sd	s11,24(sp)
    8000059e:	0100                	addi	s0,sp,128
    800005a0:	8a2a                	mv	s4,a0
    800005a2:	e40c                	sd	a1,8(s0)
    800005a4:	e810                	sd	a2,16(s0)
    800005a6:	ec14                	sd	a3,24(s0)
    800005a8:	f018                	sd	a4,32(s0)
    800005aa:	f41c                	sd	a5,40(s0)
    800005ac:	03043823          	sd	a6,48(s0)
    800005b0:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005b4:	00011d97          	auipc	s11,0x11
    800005b8:	c8cdad83          	lw	s11,-884(s11) # 80011240 <pr+0x18>
  if(locking)
    800005bc:	020d9b63          	bnez	s11,800005f2 <printf+0x70>
  if (fmt == 0)
    800005c0:	040a0263          	beqz	s4,80000604 <printf+0x82>
  va_start(ap, fmt);
    800005c4:	00840793          	addi	a5,s0,8
    800005c8:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005cc:	000a4503          	lbu	a0,0(s4)
    800005d0:	14050f63          	beqz	a0,8000072e <printf+0x1ac>
    800005d4:	4981                	li	s3,0
    if(c != '%'){
    800005d6:	02500a93          	li	s5,37
    switch(c){
    800005da:	07000b93          	li	s7,112
  consputc('x');
    800005de:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e0:	00008b17          	auipc	s6,0x8
    800005e4:	a60b0b13          	addi	s6,s6,-1440 # 80008040 <digits>
    switch(c){
    800005e8:	07300c93          	li	s9,115
    800005ec:	06400c13          	li	s8,100
    800005f0:	a82d                	j	8000062a <printf+0xa8>
    acquire(&pr.lock);
    800005f2:	00011517          	auipc	a0,0x11
    800005f6:	c3650513          	addi	a0,a0,-970 # 80011228 <pr>
    800005fa:	00000097          	auipc	ra,0x0
    800005fe:	5d6080e7          	jalr	1494(ra) # 80000bd0 <acquire>
    80000602:	bf7d                	j	800005c0 <printf+0x3e>
    panic("null fmt");
    80000604:	00008517          	auipc	a0,0x8
    80000608:	a2450513          	addi	a0,a0,-1500 # 80008028 <etext+0x28>
    8000060c:	00000097          	auipc	ra,0x0
    80000610:	f2c080e7          	jalr	-212(ra) # 80000538 <panic>
      consputc(c);
    80000614:	00000097          	auipc	ra,0x0
    80000618:	c62080e7          	jalr	-926(ra) # 80000276 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000061c:	2985                	addiw	s3,s3,1
    8000061e:	013a07b3          	add	a5,s4,s3
    80000622:	0007c503          	lbu	a0,0(a5)
    80000626:	10050463          	beqz	a0,8000072e <printf+0x1ac>
    if(c != '%'){
    8000062a:	ff5515e3          	bne	a0,s5,80000614 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000062e:	2985                	addiw	s3,s3,1
    80000630:	013a07b3          	add	a5,s4,s3
    80000634:	0007c783          	lbu	a5,0(a5)
    80000638:	0007849b          	sext.w	s1,a5
    if(c == 0)
    8000063c:	cbed                	beqz	a5,8000072e <printf+0x1ac>
    switch(c){
    8000063e:	05778a63          	beq	a5,s7,80000692 <printf+0x110>
    80000642:	02fbf663          	bgeu	s7,a5,8000066e <printf+0xec>
    80000646:	09978863          	beq	a5,s9,800006d6 <printf+0x154>
    8000064a:	07800713          	li	a4,120
    8000064e:	0ce79563          	bne	a5,a4,80000718 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000652:	f8843783          	ld	a5,-120(s0)
    80000656:	00878713          	addi	a4,a5,8
    8000065a:	f8e43423          	sd	a4,-120(s0)
    8000065e:	4605                	li	a2,1
    80000660:	85ea                	mv	a1,s10
    80000662:	4388                	lw	a0,0(a5)
    80000664:	00000097          	auipc	ra,0x0
    80000668:	e32080e7          	jalr	-462(ra) # 80000496 <printint>
      break;
    8000066c:	bf45                	j	8000061c <printf+0x9a>
    switch(c){
    8000066e:	09578f63          	beq	a5,s5,8000070c <printf+0x18a>
    80000672:	0b879363          	bne	a5,s8,80000718 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000676:	f8843783          	ld	a5,-120(s0)
    8000067a:	00878713          	addi	a4,a5,8
    8000067e:	f8e43423          	sd	a4,-120(s0)
    80000682:	4605                	li	a2,1
    80000684:	45a9                	li	a1,10
    80000686:	4388                	lw	a0,0(a5)
    80000688:	00000097          	auipc	ra,0x0
    8000068c:	e0e080e7          	jalr	-498(ra) # 80000496 <printint>
      break;
    80000690:	b771                	j	8000061c <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000692:	f8843783          	ld	a5,-120(s0)
    80000696:	00878713          	addi	a4,a5,8
    8000069a:	f8e43423          	sd	a4,-120(s0)
    8000069e:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a2:	03000513          	li	a0,48
    800006a6:	00000097          	auipc	ra,0x0
    800006aa:	bd0080e7          	jalr	-1072(ra) # 80000276 <consputc>
  consputc('x');
    800006ae:	07800513          	li	a0,120
    800006b2:	00000097          	auipc	ra,0x0
    800006b6:	bc4080e7          	jalr	-1084(ra) # 80000276 <consputc>
    800006ba:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006bc:	03c95793          	srli	a5,s2,0x3c
    800006c0:	97da                	add	a5,a5,s6
    800006c2:	0007c503          	lbu	a0,0(a5)
    800006c6:	00000097          	auipc	ra,0x0
    800006ca:	bb0080e7          	jalr	-1104(ra) # 80000276 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006ce:	0912                	slli	s2,s2,0x4
    800006d0:	34fd                	addiw	s1,s1,-1
    800006d2:	f4ed                	bnez	s1,800006bc <printf+0x13a>
    800006d4:	b7a1                	j	8000061c <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006d6:	f8843783          	ld	a5,-120(s0)
    800006da:	00878713          	addi	a4,a5,8
    800006de:	f8e43423          	sd	a4,-120(s0)
    800006e2:	6384                	ld	s1,0(a5)
    800006e4:	cc89                	beqz	s1,800006fe <printf+0x17c>
      for(; *s; s++)
    800006e6:	0004c503          	lbu	a0,0(s1)
    800006ea:	d90d                	beqz	a0,8000061c <printf+0x9a>
        consputc(*s);
    800006ec:	00000097          	auipc	ra,0x0
    800006f0:	b8a080e7          	jalr	-1142(ra) # 80000276 <consputc>
      for(; *s; s++)
    800006f4:	0485                	addi	s1,s1,1
    800006f6:	0004c503          	lbu	a0,0(s1)
    800006fa:	f96d                	bnez	a0,800006ec <printf+0x16a>
    800006fc:	b705                	j	8000061c <printf+0x9a>
        s = "(null)";
    800006fe:	00008497          	auipc	s1,0x8
    80000702:	92248493          	addi	s1,s1,-1758 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000706:	02800513          	li	a0,40
    8000070a:	b7cd                	j	800006ec <printf+0x16a>
      consputc('%');
    8000070c:	8556                	mv	a0,s5
    8000070e:	00000097          	auipc	ra,0x0
    80000712:	b68080e7          	jalr	-1176(ra) # 80000276 <consputc>
      break;
    80000716:	b719                	j	8000061c <printf+0x9a>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b5c080e7          	jalr	-1188(ra) # 80000276 <consputc>
      consputc(c);
    80000722:	8526                	mv	a0,s1
    80000724:	00000097          	auipc	ra,0x0
    80000728:	b52080e7          	jalr	-1198(ra) # 80000276 <consputc>
      break;
    8000072c:	bdc5                	j	8000061c <printf+0x9a>
  if(locking)
    8000072e:	020d9163          	bnez	s11,80000750 <printf+0x1ce>
}
    80000732:	70e6                	ld	ra,120(sp)
    80000734:	7446                	ld	s0,112(sp)
    80000736:	74a6                	ld	s1,104(sp)
    80000738:	7906                	ld	s2,96(sp)
    8000073a:	69e6                	ld	s3,88(sp)
    8000073c:	6a46                	ld	s4,80(sp)
    8000073e:	6aa6                	ld	s5,72(sp)
    80000740:	6b06                	ld	s6,64(sp)
    80000742:	7be2                	ld	s7,56(sp)
    80000744:	7c42                	ld	s8,48(sp)
    80000746:	7ca2                	ld	s9,40(sp)
    80000748:	7d02                	ld	s10,32(sp)
    8000074a:	6de2                	ld	s11,24(sp)
    8000074c:	6129                	addi	sp,sp,192
    8000074e:	8082                	ret
    release(&pr.lock);
    80000750:	00011517          	auipc	a0,0x11
    80000754:	ad850513          	addi	a0,a0,-1320 # 80011228 <pr>
    80000758:	00000097          	auipc	ra,0x0
    8000075c:	52c080e7          	jalr	1324(ra) # 80000c84 <release>
}
    80000760:	bfc9                	j	80000732 <printf+0x1b0>

0000000080000762 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000762:	1101                	addi	sp,sp,-32
    80000764:	ec06                	sd	ra,24(sp)
    80000766:	e822                	sd	s0,16(sp)
    80000768:	e426                	sd	s1,8(sp)
    8000076a:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000076c:	00011497          	auipc	s1,0x11
    80000770:	abc48493          	addi	s1,s1,-1348 # 80011228 <pr>
    80000774:	00008597          	auipc	a1,0x8
    80000778:	8c458593          	addi	a1,a1,-1852 # 80008038 <etext+0x38>
    8000077c:	8526                	mv	a0,s1
    8000077e:	00000097          	auipc	ra,0x0
    80000782:	3c2080e7          	jalr	962(ra) # 80000b40 <initlock>
  pr.locking = 1;
    80000786:	4785                	li	a5,1
    80000788:	cc9c                	sw	a5,24(s1)
}
    8000078a:	60e2                	ld	ra,24(sp)
    8000078c:	6442                	ld	s0,16(sp)
    8000078e:	64a2                	ld	s1,8(sp)
    80000790:	6105                	addi	sp,sp,32
    80000792:	8082                	ret

0000000080000794 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000794:	1141                	addi	sp,sp,-16
    80000796:	e406                	sd	ra,8(sp)
    80000798:	e022                	sd	s0,0(sp)
    8000079a:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000079c:	100007b7          	lui	a5,0x10000
    800007a0:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007a4:	f8000713          	li	a4,-128
    800007a8:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007ac:	470d                	li	a4,3
    800007ae:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b2:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007b6:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007ba:	469d                	li	a3,7
    800007bc:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c0:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007c4:	00008597          	auipc	a1,0x8
    800007c8:	89458593          	addi	a1,a1,-1900 # 80008058 <digits+0x18>
    800007cc:	00011517          	auipc	a0,0x11
    800007d0:	a7c50513          	addi	a0,a0,-1412 # 80011248 <uart_tx_lock>
    800007d4:	00000097          	auipc	ra,0x0
    800007d8:	36c080e7          	jalr	876(ra) # 80000b40 <initlock>
}
    800007dc:	60a2                	ld	ra,8(sp)
    800007de:	6402                	ld	s0,0(sp)
    800007e0:	0141                	addi	sp,sp,16
    800007e2:	8082                	ret

00000000800007e4 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007e4:	1101                	addi	sp,sp,-32
    800007e6:	ec06                	sd	ra,24(sp)
    800007e8:	e822                	sd	s0,16(sp)
    800007ea:	e426                	sd	s1,8(sp)
    800007ec:	1000                	addi	s0,sp,32
    800007ee:	84aa                	mv	s1,a0
  push_off();
    800007f0:	00000097          	auipc	ra,0x0
    800007f4:	394080e7          	jalr	916(ra) # 80000b84 <push_off>

  if(panicked){
    800007f8:	00009797          	auipc	a5,0x9
    800007fc:	8087a783          	lw	a5,-2040(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000800:	10000737          	lui	a4,0x10000
  if(panicked){
    80000804:	c391                	beqz	a5,80000808 <uartputc_sync+0x24>
    for(;;)
    80000806:	a001                	j	80000806 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000080c:	0207f793          	andi	a5,a5,32
    80000810:	dfe5                	beqz	a5,80000808 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000812:	0ff4f513          	andi	a0,s1,255
    80000816:	100007b7          	lui	a5,0x10000
    8000081a:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    8000081e:	00000097          	auipc	ra,0x0
    80000822:	406080e7          	jalr	1030(ra) # 80000c24 <pop_off>
}
    80000826:	60e2                	ld	ra,24(sp)
    80000828:	6442                	ld	s0,16(sp)
    8000082a:	64a2                	ld	s1,8(sp)
    8000082c:	6105                	addi	sp,sp,32
    8000082e:	8082                	ret

0000000080000830 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000830:	00008797          	auipc	a5,0x8
    80000834:	7d87b783          	ld	a5,2008(a5) # 80009008 <uart_tx_r>
    80000838:	00008717          	auipc	a4,0x8
    8000083c:	7d873703          	ld	a4,2008(a4) # 80009010 <uart_tx_w>
    80000840:	06f70a63          	beq	a4,a5,800008b4 <uartstart+0x84>
{
    80000844:	7139                	addi	sp,sp,-64
    80000846:	fc06                	sd	ra,56(sp)
    80000848:	f822                	sd	s0,48(sp)
    8000084a:	f426                	sd	s1,40(sp)
    8000084c:	f04a                	sd	s2,32(sp)
    8000084e:	ec4e                	sd	s3,24(sp)
    80000850:	e852                	sd	s4,16(sp)
    80000852:	e456                	sd	s5,8(sp)
    80000854:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000856:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000085a:	00011a17          	auipc	s4,0x11
    8000085e:	9eea0a13          	addi	s4,s4,-1554 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000862:	00008497          	auipc	s1,0x8
    80000866:	7a648493          	addi	s1,s1,1958 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086a:	00008997          	auipc	s3,0x8
    8000086e:	7a698993          	addi	s3,s3,1958 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000872:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000876:	02077713          	andi	a4,a4,32
    8000087a:	c705                	beqz	a4,800008a2 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000087c:	01f7f713          	andi	a4,a5,31
    80000880:	9752                	add	a4,a4,s4
    80000882:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    80000886:	0785                	addi	a5,a5,1
    80000888:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000088a:	8526                	mv	a0,s1
    8000088c:	00002097          	auipc	ra,0x2
    80000890:	956080e7          	jalr	-1706(ra) # 800021e2 <wakeup>
    
    WriteReg(THR, c);
    80000894:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    80000898:	609c                	ld	a5,0(s1)
    8000089a:	0009b703          	ld	a4,0(s3)
    8000089e:	fcf71ae3          	bne	a4,a5,80000872 <uartstart+0x42>
  }
}
    800008a2:	70e2                	ld	ra,56(sp)
    800008a4:	7442                	ld	s0,48(sp)
    800008a6:	74a2                	ld	s1,40(sp)
    800008a8:	7902                	ld	s2,32(sp)
    800008aa:	69e2                	ld	s3,24(sp)
    800008ac:	6a42                	ld	s4,16(sp)
    800008ae:	6aa2                	ld	s5,8(sp)
    800008b0:	6121                	addi	sp,sp,64
    800008b2:	8082                	ret
    800008b4:	8082                	ret

00000000800008b6 <uartputc>:
{
    800008b6:	7179                	addi	sp,sp,-48
    800008b8:	f406                	sd	ra,40(sp)
    800008ba:	f022                	sd	s0,32(sp)
    800008bc:	ec26                	sd	s1,24(sp)
    800008be:	e84a                	sd	s2,16(sp)
    800008c0:	e44e                	sd	s3,8(sp)
    800008c2:	e052                	sd	s4,0(sp)
    800008c4:	1800                	addi	s0,sp,48
    800008c6:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008c8:	00011517          	auipc	a0,0x11
    800008cc:	98050513          	addi	a0,a0,-1664 # 80011248 <uart_tx_lock>
    800008d0:	00000097          	auipc	ra,0x0
    800008d4:	300080e7          	jalr	768(ra) # 80000bd0 <acquire>
  if(panicked){
    800008d8:	00008797          	auipc	a5,0x8
    800008dc:	7287a783          	lw	a5,1832(a5) # 80009000 <panicked>
    800008e0:	c391                	beqz	a5,800008e4 <uartputc+0x2e>
    for(;;)
    800008e2:	a001                	j	800008e2 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e4:	00008717          	auipc	a4,0x8
    800008e8:	72c73703          	ld	a4,1836(a4) # 80009010 <uart_tx_w>
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	71c7b783          	ld	a5,1820(a5) # 80009008 <uart_tx_r>
    800008f4:	02078793          	addi	a5,a5,32
    800008f8:	02e79b63          	bne	a5,a4,8000092e <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    800008fc:	00011997          	auipc	s3,0x11
    80000900:	94c98993          	addi	s3,s3,-1716 # 80011248 <uart_tx_lock>
    80000904:	00008497          	auipc	s1,0x8
    80000908:	70448493          	addi	s1,s1,1796 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090c:	00008917          	auipc	s2,0x8
    80000910:	70490913          	addi	s2,s2,1796 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000914:	85ce                	mv	a1,s3
    80000916:	8526                	mv	a0,s1
    80000918:	00001097          	auipc	ra,0x1
    8000091c:	73e080e7          	jalr	1854(ra) # 80002056 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00093703          	ld	a4,0(s2)
    80000924:	609c                	ld	a5,0(s1)
    80000926:	02078793          	addi	a5,a5,32
    8000092a:	fee785e3          	beq	a5,a4,80000914 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    8000092e:	00011497          	auipc	s1,0x11
    80000932:	91a48493          	addi	s1,s1,-1766 # 80011248 <uart_tx_lock>
    80000936:	01f77793          	andi	a5,a4,31
    8000093a:	97a6                	add	a5,a5,s1
    8000093c:	01478c23          	sb	s4,24(a5)
      uart_tx_w += 1;
    80000940:	0705                	addi	a4,a4,1
    80000942:	00008797          	auipc	a5,0x8
    80000946:	6ce7b723          	sd	a4,1742(a5) # 80009010 <uart_tx_w>
      uartstart();
    8000094a:	00000097          	auipc	ra,0x0
    8000094e:	ee6080e7          	jalr	-282(ra) # 80000830 <uartstart>
      release(&uart_tx_lock);
    80000952:	8526                	mv	a0,s1
    80000954:	00000097          	auipc	ra,0x0
    80000958:	330080e7          	jalr	816(ra) # 80000c84 <release>
}
    8000095c:	70a2                	ld	ra,40(sp)
    8000095e:	7402                	ld	s0,32(sp)
    80000960:	64e2                	ld	s1,24(sp)
    80000962:	6942                	ld	s2,16(sp)
    80000964:	69a2                	ld	s3,8(sp)
    80000966:	6a02                	ld	s4,0(sp)
    80000968:	6145                	addi	sp,sp,48
    8000096a:	8082                	ret

000000008000096c <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000096c:	1141                	addi	sp,sp,-16
    8000096e:	e422                	sd	s0,8(sp)
    80000970:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000972:	100007b7          	lui	a5,0x10000
    80000976:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000097a:	8b85                	andi	a5,a5,1
    8000097c:	cb91                	beqz	a5,80000990 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    8000097e:	100007b7          	lui	a5,0x10000
    80000982:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    80000986:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000098a:	6422                	ld	s0,8(sp)
    8000098c:	0141                	addi	sp,sp,16
    8000098e:	8082                	ret
    return -1;
    80000990:	557d                	li	a0,-1
    80000992:	bfe5                	j	8000098a <uartgetc+0x1e>

0000000080000994 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000994:	1101                	addi	sp,sp,-32
    80000996:	ec06                	sd	ra,24(sp)
    80000998:	e822                	sd	s0,16(sp)
    8000099a:	e426                	sd	s1,8(sp)
    8000099c:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    8000099e:	54fd                	li	s1,-1
    800009a0:	a029                	j	800009aa <uartintr+0x16>
      break;
    consoleintr(c);
    800009a2:	00000097          	auipc	ra,0x0
    800009a6:	916080e7          	jalr	-1770(ra) # 800002b8 <consoleintr>
    int c = uartgetc();
    800009aa:	00000097          	auipc	ra,0x0
    800009ae:	fc2080e7          	jalr	-62(ra) # 8000096c <uartgetc>
    if(c == -1)
    800009b2:	fe9518e3          	bne	a0,s1,800009a2 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009b6:	00011497          	auipc	s1,0x11
    800009ba:	89248493          	addi	s1,s1,-1902 # 80011248 <uart_tx_lock>
    800009be:	8526                	mv	a0,s1
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	210080e7          	jalr	528(ra) # 80000bd0 <acquire>
  uartstart();
    800009c8:	00000097          	auipc	ra,0x0
    800009cc:	e68080e7          	jalr	-408(ra) # 80000830 <uartstart>
  release(&uart_tx_lock);
    800009d0:	8526                	mv	a0,s1
    800009d2:	00000097          	auipc	ra,0x0
    800009d6:	2b2080e7          	jalr	690(ra) # 80000c84 <release>
}
    800009da:	60e2                	ld	ra,24(sp)
    800009dc:	6442                	ld	s0,16(sp)
    800009de:	64a2                	ld	s1,8(sp)
    800009e0:	6105                	addi	sp,sp,32
    800009e2:	8082                	ret

00000000800009e4 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e4:	1101                	addi	sp,sp,-32
    800009e6:	ec06                	sd	ra,24(sp)
    800009e8:	e822                	sd	s0,16(sp)
    800009ea:	e426                	sd	s1,8(sp)
    800009ec:	e04a                	sd	s2,0(sp)
    800009ee:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f0:	03451793          	slli	a5,a0,0x34
    800009f4:	ebb9                	bnez	a5,80000a4a <kfree+0x66>
    800009f6:	84aa                	mv	s1,a0
    800009f8:	00025797          	auipc	a5,0x25
    800009fc:	60878793          	addi	a5,a5,1544 # 80026000 <end>
    80000a00:	04f56563          	bltu	a0,a5,80000a4a <kfree+0x66>
    80000a04:	47c5                	li	a5,17
    80000a06:	07ee                	slli	a5,a5,0x1b
    80000a08:	04f57163          	bgeu	a0,a5,80000a4a <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a0c:	6605                	lui	a2,0x1
    80000a0e:	4585                	li	a1,1
    80000a10:	00000097          	auipc	ra,0x0
    80000a14:	2bc080e7          	jalr	700(ra) # 80000ccc <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a18:	00011917          	auipc	s2,0x11
    80000a1c:	86890913          	addi	s2,s2,-1944 # 80011280 <kmem>
    80000a20:	854a                	mv	a0,s2
    80000a22:	00000097          	auipc	ra,0x0
    80000a26:	1ae080e7          	jalr	430(ra) # 80000bd0 <acquire>
  r->next = kmem.freelist;
    80000a2a:	01893783          	ld	a5,24(s2)
    80000a2e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a30:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	24e080e7          	jalr	590(ra) # 80000c84 <release>
}
    80000a3e:	60e2                	ld	ra,24(sp)
    80000a40:	6442                	ld	s0,16(sp)
    80000a42:	64a2                	ld	s1,8(sp)
    80000a44:	6902                	ld	s2,0(sp)
    80000a46:	6105                	addi	sp,sp,32
    80000a48:	8082                	ret
    panic("kfree");
    80000a4a:	00007517          	auipc	a0,0x7
    80000a4e:	61650513          	addi	a0,a0,1558 # 80008060 <digits+0x20>
    80000a52:	00000097          	auipc	ra,0x0
    80000a56:	ae6080e7          	jalr	-1306(ra) # 80000538 <panic>

0000000080000a5a <freerange>:
{
    80000a5a:	7179                	addi	sp,sp,-48
    80000a5c:	f406                	sd	ra,40(sp)
    80000a5e:	f022                	sd	s0,32(sp)
    80000a60:	ec26                	sd	s1,24(sp)
    80000a62:	e84a                	sd	s2,16(sp)
    80000a64:	e44e                	sd	s3,8(sp)
    80000a66:	e052                	sd	s4,0(sp)
    80000a68:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6a:	6785                	lui	a5,0x1
    80000a6c:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a70:	94aa                	add	s1,s1,a0
    80000a72:	757d                	lui	a0,0xfffff
    80000a74:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a76:	94be                	add	s1,s1,a5
    80000a78:	0095ee63          	bltu	a1,s1,80000a94 <freerange+0x3a>
    80000a7c:	892e                	mv	s2,a1
    kfree(p);
    80000a7e:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a80:	6985                	lui	s3,0x1
    kfree(p);
    80000a82:	01448533          	add	a0,s1,s4
    80000a86:	00000097          	auipc	ra,0x0
    80000a8a:	f5e080e7          	jalr	-162(ra) # 800009e4 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8e:	94ce                	add	s1,s1,s3
    80000a90:	fe9979e3          	bgeu	s2,s1,80000a82 <freerange+0x28>
}
    80000a94:	70a2                	ld	ra,40(sp)
    80000a96:	7402                	ld	s0,32(sp)
    80000a98:	64e2                	ld	s1,24(sp)
    80000a9a:	6942                	ld	s2,16(sp)
    80000a9c:	69a2                	ld	s3,8(sp)
    80000a9e:	6a02                	ld	s4,0(sp)
    80000aa0:	6145                	addi	sp,sp,48
    80000aa2:	8082                	ret

0000000080000aa4 <kinit>:
{
    80000aa4:	1141                	addi	sp,sp,-16
    80000aa6:	e406                	sd	ra,8(sp)
    80000aa8:	e022                	sd	s0,0(sp)
    80000aaa:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aac:	00007597          	auipc	a1,0x7
    80000ab0:	5bc58593          	addi	a1,a1,1468 # 80008068 <digits+0x28>
    80000ab4:	00010517          	auipc	a0,0x10
    80000ab8:	7cc50513          	addi	a0,a0,1996 # 80011280 <kmem>
    80000abc:	00000097          	auipc	ra,0x0
    80000ac0:	084080e7          	jalr	132(ra) # 80000b40 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ac4:	45c5                	li	a1,17
    80000ac6:	05ee                	slli	a1,a1,0x1b
    80000ac8:	00025517          	auipc	a0,0x25
    80000acc:	53850513          	addi	a0,a0,1336 # 80026000 <end>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	f8a080e7          	jalr	-118(ra) # 80000a5a <freerange>
}
    80000ad8:	60a2                	ld	ra,8(sp)
    80000ada:	6402                	ld	s0,0(sp)
    80000adc:	0141                	addi	sp,sp,16
    80000ade:	8082                	ret

0000000080000ae0 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae0:	1101                	addi	sp,sp,-32
    80000ae2:	ec06                	sd	ra,24(sp)
    80000ae4:	e822                	sd	s0,16(sp)
    80000ae6:	e426                	sd	s1,8(sp)
    80000ae8:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000aea:	00010497          	auipc	s1,0x10
    80000aee:	79648493          	addi	s1,s1,1942 # 80011280 <kmem>
    80000af2:	8526                	mv	a0,s1
    80000af4:	00000097          	auipc	ra,0x0
    80000af8:	0dc080e7          	jalr	220(ra) # 80000bd0 <acquire>
  r = kmem.freelist;
    80000afc:	6c84                	ld	s1,24(s1)
  if(r)
    80000afe:	c885                	beqz	s1,80000b2e <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b00:	609c                	ld	a5,0(s1)
    80000b02:	00010517          	auipc	a0,0x10
    80000b06:	77e50513          	addi	a0,a0,1918 # 80011280 <kmem>
    80000b0a:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b0c:	00000097          	auipc	ra,0x0
    80000b10:	178080e7          	jalr	376(ra) # 80000c84 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b14:	6605                	lui	a2,0x1
    80000b16:	4595                	li	a1,5
    80000b18:	8526                	mv	a0,s1
    80000b1a:	00000097          	auipc	ra,0x0
    80000b1e:	1b2080e7          	jalr	434(ra) # 80000ccc <memset>
  return (void*)r;
}
    80000b22:	8526                	mv	a0,s1
    80000b24:	60e2                	ld	ra,24(sp)
    80000b26:	6442                	ld	s0,16(sp)
    80000b28:	64a2                	ld	s1,8(sp)
    80000b2a:	6105                	addi	sp,sp,32
    80000b2c:	8082                	ret
  release(&kmem.lock);
    80000b2e:	00010517          	auipc	a0,0x10
    80000b32:	75250513          	addi	a0,a0,1874 # 80011280 <kmem>
    80000b36:	00000097          	auipc	ra,0x0
    80000b3a:	14e080e7          	jalr	334(ra) # 80000c84 <release>
  if(r)
    80000b3e:	b7d5                	j	80000b22 <kalloc+0x42>

0000000080000b40 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b40:	1141                	addi	sp,sp,-16
    80000b42:	e422                	sd	s0,8(sp)
    80000b44:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b46:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b48:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b4c:	00053823          	sd	zero,16(a0)
}
    80000b50:	6422                	ld	s0,8(sp)
    80000b52:	0141                	addi	sp,sp,16
    80000b54:	8082                	ret

0000000080000b56 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b56:	411c                	lw	a5,0(a0)
    80000b58:	e399                	bnez	a5,80000b5e <holding+0x8>
    80000b5a:	4501                	li	a0,0
  return r;
}
    80000b5c:	8082                	ret
{
    80000b5e:	1101                	addi	sp,sp,-32
    80000b60:	ec06                	sd	ra,24(sp)
    80000b62:	e822                	sd	s0,16(sp)
    80000b64:	e426                	sd	s1,8(sp)
    80000b66:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b68:	6904                	ld	s1,16(a0)
    80000b6a:	00001097          	auipc	ra,0x1
    80000b6e:	e10080e7          	jalr	-496(ra) # 8000197a <mycpu>
    80000b72:	40a48533          	sub	a0,s1,a0
    80000b76:	00153513          	seqz	a0,a0
}
    80000b7a:	60e2                	ld	ra,24(sp)
    80000b7c:	6442                	ld	s0,16(sp)
    80000b7e:	64a2                	ld	s1,8(sp)
    80000b80:	6105                	addi	sp,sp,32
    80000b82:	8082                	ret

0000000080000b84 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b84:	1101                	addi	sp,sp,-32
    80000b86:	ec06                	sd	ra,24(sp)
    80000b88:	e822                	sd	s0,16(sp)
    80000b8a:	e426                	sd	s1,8(sp)
    80000b8c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b8e:	100024f3          	csrr	s1,sstatus
    80000b92:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b96:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b98:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000b9c:	00001097          	auipc	ra,0x1
    80000ba0:	dde080e7          	jalr	-546(ra) # 8000197a <mycpu>
    80000ba4:	5d3c                	lw	a5,120(a0)
    80000ba6:	cf89                	beqz	a5,80000bc0 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000ba8:	00001097          	auipc	ra,0x1
    80000bac:	dd2080e7          	jalr	-558(ra) # 8000197a <mycpu>
    80000bb0:	5d3c                	lw	a5,120(a0)
    80000bb2:	2785                	addiw	a5,a5,1
    80000bb4:	dd3c                	sw	a5,120(a0)
}
    80000bb6:	60e2                	ld	ra,24(sp)
    80000bb8:	6442                	ld	s0,16(sp)
    80000bba:	64a2                	ld	s1,8(sp)
    80000bbc:	6105                	addi	sp,sp,32
    80000bbe:	8082                	ret
    mycpu()->intena = old;
    80000bc0:	00001097          	auipc	ra,0x1
    80000bc4:	dba080e7          	jalr	-582(ra) # 8000197a <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bc8:	8085                	srli	s1,s1,0x1
    80000bca:	8885                	andi	s1,s1,1
    80000bcc:	dd64                	sw	s1,124(a0)
    80000bce:	bfe9                	j	80000ba8 <push_off+0x24>

0000000080000bd0 <acquire>:
{
    80000bd0:	1101                	addi	sp,sp,-32
    80000bd2:	ec06                	sd	ra,24(sp)
    80000bd4:	e822                	sd	s0,16(sp)
    80000bd6:	e426                	sd	s1,8(sp)
    80000bd8:	1000                	addi	s0,sp,32
    80000bda:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bdc:	00000097          	auipc	ra,0x0
    80000be0:	fa8080e7          	jalr	-88(ra) # 80000b84 <push_off>
  if(holding(lk))
    80000be4:	8526                	mv	a0,s1
    80000be6:	00000097          	auipc	ra,0x0
    80000bea:	f70080e7          	jalr	-144(ra) # 80000b56 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bee:	4705                	li	a4,1
  if(holding(lk))
    80000bf0:	e115                	bnez	a0,80000c14 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf2:	87ba                	mv	a5,a4
    80000bf4:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bf8:	2781                	sext.w	a5,a5
    80000bfa:	ffe5                	bnez	a5,80000bf2 <acquire+0x22>
  __sync_synchronize();
    80000bfc:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c00:	00001097          	auipc	ra,0x1
    80000c04:	d7a080e7          	jalr	-646(ra) # 8000197a <mycpu>
    80000c08:	e888                	sd	a0,16(s1)
}
    80000c0a:	60e2                	ld	ra,24(sp)
    80000c0c:	6442                	ld	s0,16(sp)
    80000c0e:	64a2                	ld	s1,8(sp)
    80000c10:	6105                	addi	sp,sp,32
    80000c12:	8082                	ret
    panic("acquire");
    80000c14:	00007517          	auipc	a0,0x7
    80000c18:	45c50513          	addi	a0,a0,1116 # 80008070 <digits+0x30>
    80000c1c:	00000097          	auipc	ra,0x0
    80000c20:	91c080e7          	jalr	-1764(ra) # 80000538 <panic>

0000000080000c24 <pop_off>:

void
pop_off(void)
{
    80000c24:	1141                	addi	sp,sp,-16
    80000c26:	e406                	sd	ra,8(sp)
    80000c28:	e022                	sd	s0,0(sp)
    80000c2a:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c2c:	00001097          	auipc	ra,0x1
    80000c30:	d4e080e7          	jalr	-690(ra) # 8000197a <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c34:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c38:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c3a:	e78d                	bnez	a5,80000c64 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c3c:	5d3c                	lw	a5,120(a0)
    80000c3e:	02f05b63          	blez	a5,80000c74 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c42:	37fd                	addiw	a5,a5,-1
    80000c44:	0007871b          	sext.w	a4,a5
    80000c48:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c4a:	eb09                	bnez	a4,80000c5c <pop_off+0x38>
    80000c4c:	5d7c                	lw	a5,124(a0)
    80000c4e:	c799                	beqz	a5,80000c5c <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c50:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c54:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c58:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c5c:	60a2                	ld	ra,8(sp)
    80000c5e:	6402                	ld	s0,0(sp)
    80000c60:	0141                	addi	sp,sp,16
    80000c62:	8082                	ret
    panic("pop_off - interruptible");
    80000c64:	00007517          	auipc	a0,0x7
    80000c68:	41450513          	addi	a0,a0,1044 # 80008078 <digits+0x38>
    80000c6c:	00000097          	auipc	ra,0x0
    80000c70:	8cc080e7          	jalr	-1844(ra) # 80000538 <panic>
    panic("pop_off");
    80000c74:	00007517          	auipc	a0,0x7
    80000c78:	41c50513          	addi	a0,a0,1052 # 80008090 <digits+0x50>
    80000c7c:	00000097          	auipc	ra,0x0
    80000c80:	8bc080e7          	jalr	-1860(ra) # 80000538 <panic>

0000000080000c84 <release>:
{
    80000c84:	1101                	addi	sp,sp,-32
    80000c86:	ec06                	sd	ra,24(sp)
    80000c88:	e822                	sd	s0,16(sp)
    80000c8a:	e426                	sd	s1,8(sp)
    80000c8c:	1000                	addi	s0,sp,32
    80000c8e:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	ec6080e7          	jalr	-314(ra) # 80000b56 <holding>
    80000c98:	c115                	beqz	a0,80000cbc <release+0x38>
  lk->cpu = 0;
    80000c9a:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000c9e:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca2:	0f50000f          	fence	iorw,ow
    80000ca6:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	f7a080e7          	jalr	-134(ra) # 80000c24 <pop_off>
}
    80000cb2:	60e2                	ld	ra,24(sp)
    80000cb4:	6442                	ld	s0,16(sp)
    80000cb6:	64a2                	ld	s1,8(sp)
    80000cb8:	6105                	addi	sp,sp,32
    80000cba:	8082                	ret
    panic("release");
    80000cbc:	00007517          	auipc	a0,0x7
    80000cc0:	3dc50513          	addi	a0,a0,988 # 80008098 <digits+0x58>
    80000cc4:	00000097          	auipc	ra,0x0
    80000cc8:	874080e7          	jalr	-1932(ra) # 80000538 <panic>

0000000080000ccc <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ccc:	1141                	addi	sp,sp,-16
    80000cce:	e422                	sd	s0,8(sp)
    80000cd0:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd2:	ca19                	beqz	a2,80000ce8 <memset+0x1c>
    80000cd4:	87aa                	mv	a5,a0
    80000cd6:	1602                	slli	a2,a2,0x20
    80000cd8:	9201                	srli	a2,a2,0x20
    80000cda:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000cde:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce2:	0785                	addi	a5,a5,1
    80000ce4:	fee79de3          	bne	a5,a4,80000cde <memset+0x12>
  }
  return dst;
}
    80000ce8:	6422                	ld	s0,8(sp)
    80000cea:	0141                	addi	sp,sp,16
    80000cec:	8082                	ret

0000000080000cee <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cee:	1141                	addi	sp,sp,-16
    80000cf0:	e422                	sd	s0,8(sp)
    80000cf2:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cf4:	ca05                	beqz	a2,80000d24 <memcmp+0x36>
    80000cf6:	fff6069b          	addiw	a3,a2,-1
    80000cfa:	1682                	slli	a3,a3,0x20
    80000cfc:	9281                	srli	a3,a3,0x20
    80000cfe:	0685                	addi	a3,a3,1
    80000d00:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d02:	00054783          	lbu	a5,0(a0)
    80000d06:	0005c703          	lbu	a4,0(a1)
    80000d0a:	00e79863          	bne	a5,a4,80000d1a <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d0e:	0505                	addi	a0,a0,1
    80000d10:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d12:	fed518e3          	bne	a0,a3,80000d02 <memcmp+0x14>
  }

  return 0;
    80000d16:	4501                	li	a0,0
    80000d18:	a019                	j	80000d1e <memcmp+0x30>
      return *s1 - *s2;
    80000d1a:	40e7853b          	subw	a0,a5,a4
}
    80000d1e:	6422                	ld	s0,8(sp)
    80000d20:	0141                	addi	sp,sp,16
    80000d22:	8082                	ret
  return 0;
    80000d24:	4501                	li	a0,0
    80000d26:	bfe5                	j	80000d1e <memcmp+0x30>

0000000080000d28 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d28:	1141                	addi	sp,sp,-16
    80000d2a:	e422                	sd	s0,8(sp)
    80000d2c:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d2e:	c205                	beqz	a2,80000d4e <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d30:	02a5e263          	bltu	a1,a0,80000d54 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d34:	1602                	slli	a2,a2,0x20
    80000d36:	9201                	srli	a2,a2,0x20
    80000d38:	00c587b3          	add	a5,a1,a2
{
    80000d3c:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d3e:	0585                	addi	a1,a1,1
    80000d40:	0705                	addi	a4,a4,1
    80000d42:	fff5c683          	lbu	a3,-1(a1)
    80000d46:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d4a:	fef59ae3          	bne	a1,a5,80000d3e <memmove+0x16>

  return dst;
}
    80000d4e:	6422                	ld	s0,8(sp)
    80000d50:	0141                	addi	sp,sp,16
    80000d52:	8082                	ret
  if(s < d && s + n > d){
    80000d54:	02061693          	slli	a3,a2,0x20
    80000d58:	9281                	srli	a3,a3,0x20
    80000d5a:	00d58733          	add	a4,a1,a3
    80000d5e:	fce57be3          	bgeu	a0,a4,80000d34 <memmove+0xc>
    d += n;
    80000d62:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d64:	fff6079b          	addiw	a5,a2,-1
    80000d68:	1782                	slli	a5,a5,0x20
    80000d6a:	9381                	srli	a5,a5,0x20
    80000d6c:	fff7c793          	not	a5,a5
    80000d70:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d72:	177d                	addi	a4,a4,-1
    80000d74:	16fd                	addi	a3,a3,-1
    80000d76:	00074603          	lbu	a2,0(a4)
    80000d7a:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d7e:	fee79ae3          	bne	a5,a4,80000d72 <memmove+0x4a>
    80000d82:	b7f1                	j	80000d4e <memmove+0x26>

0000000080000d84 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d84:	1141                	addi	sp,sp,-16
    80000d86:	e406                	sd	ra,8(sp)
    80000d88:	e022                	sd	s0,0(sp)
    80000d8a:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d8c:	00000097          	auipc	ra,0x0
    80000d90:	f9c080e7          	jalr	-100(ra) # 80000d28 <memmove>
}
    80000d94:	60a2                	ld	ra,8(sp)
    80000d96:	6402                	ld	s0,0(sp)
    80000d98:	0141                	addi	sp,sp,16
    80000d9a:	8082                	ret

0000000080000d9c <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d9c:	1141                	addi	sp,sp,-16
    80000d9e:	e422                	sd	s0,8(sp)
    80000da0:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da2:	ce11                	beqz	a2,80000dbe <strncmp+0x22>
    80000da4:	00054783          	lbu	a5,0(a0)
    80000da8:	cf89                	beqz	a5,80000dc2 <strncmp+0x26>
    80000daa:	0005c703          	lbu	a4,0(a1)
    80000dae:	00f71a63          	bne	a4,a5,80000dc2 <strncmp+0x26>
    n--, p++, q++;
    80000db2:	367d                	addiw	a2,a2,-1
    80000db4:	0505                	addi	a0,a0,1
    80000db6:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000db8:	f675                	bnez	a2,80000da4 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dba:	4501                	li	a0,0
    80000dbc:	a809                	j	80000dce <strncmp+0x32>
    80000dbe:	4501                	li	a0,0
    80000dc0:	a039                	j	80000dce <strncmp+0x32>
  if(n == 0)
    80000dc2:	ca09                	beqz	a2,80000dd4 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dc4:	00054503          	lbu	a0,0(a0)
    80000dc8:	0005c783          	lbu	a5,0(a1)
    80000dcc:	9d1d                	subw	a0,a0,a5
}
    80000dce:	6422                	ld	s0,8(sp)
    80000dd0:	0141                	addi	sp,sp,16
    80000dd2:	8082                	ret
    return 0;
    80000dd4:	4501                	li	a0,0
    80000dd6:	bfe5                	j	80000dce <strncmp+0x32>

0000000080000dd8 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dd8:	1141                	addi	sp,sp,-16
    80000dda:	e422                	sd	s0,8(sp)
    80000ddc:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dde:	872a                	mv	a4,a0
    80000de0:	8832                	mv	a6,a2
    80000de2:	367d                	addiw	a2,a2,-1
    80000de4:	01005963          	blez	a6,80000df6 <strncpy+0x1e>
    80000de8:	0705                	addi	a4,a4,1
    80000dea:	0005c783          	lbu	a5,0(a1)
    80000dee:	fef70fa3          	sb	a5,-1(a4)
    80000df2:	0585                	addi	a1,a1,1
    80000df4:	f7f5                	bnez	a5,80000de0 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000df6:	86ba                	mv	a3,a4
    80000df8:	00c05c63          	blez	a2,80000e10 <strncpy+0x38>
    *s++ = 0;
    80000dfc:	0685                	addi	a3,a3,1
    80000dfe:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e02:	fff6c793          	not	a5,a3
    80000e06:	9fb9                	addw	a5,a5,a4
    80000e08:	010787bb          	addw	a5,a5,a6
    80000e0c:	fef048e3          	bgtz	a5,80000dfc <strncpy+0x24>
  return os;
}
    80000e10:	6422                	ld	s0,8(sp)
    80000e12:	0141                	addi	sp,sp,16
    80000e14:	8082                	ret

0000000080000e16 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e16:	1141                	addi	sp,sp,-16
    80000e18:	e422                	sd	s0,8(sp)
    80000e1a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e1c:	02c05363          	blez	a2,80000e42 <safestrcpy+0x2c>
    80000e20:	fff6069b          	addiw	a3,a2,-1
    80000e24:	1682                	slli	a3,a3,0x20
    80000e26:	9281                	srli	a3,a3,0x20
    80000e28:	96ae                	add	a3,a3,a1
    80000e2a:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e2c:	00d58963          	beq	a1,a3,80000e3e <safestrcpy+0x28>
    80000e30:	0585                	addi	a1,a1,1
    80000e32:	0785                	addi	a5,a5,1
    80000e34:	fff5c703          	lbu	a4,-1(a1)
    80000e38:	fee78fa3          	sb	a4,-1(a5)
    80000e3c:	fb65                	bnez	a4,80000e2c <safestrcpy+0x16>
    ;
  *s = 0;
    80000e3e:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e42:	6422                	ld	s0,8(sp)
    80000e44:	0141                	addi	sp,sp,16
    80000e46:	8082                	ret

0000000080000e48 <strlen>:

int
strlen(const char *s)
{
    80000e48:	1141                	addi	sp,sp,-16
    80000e4a:	e422                	sd	s0,8(sp)
    80000e4c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e4e:	00054783          	lbu	a5,0(a0)
    80000e52:	cf91                	beqz	a5,80000e6e <strlen+0x26>
    80000e54:	0505                	addi	a0,a0,1
    80000e56:	87aa                	mv	a5,a0
    80000e58:	4685                	li	a3,1
    80000e5a:	9e89                	subw	a3,a3,a0
    80000e5c:	00f6853b          	addw	a0,a3,a5
    80000e60:	0785                	addi	a5,a5,1
    80000e62:	fff7c703          	lbu	a4,-1(a5)
    80000e66:	fb7d                	bnez	a4,80000e5c <strlen+0x14>
    ;
  return n;
}
    80000e68:	6422                	ld	s0,8(sp)
    80000e6a:	0141                	addi	sp,sp,16
    80000e6c:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e6e:	4501                	li	a0,0
    80000e70:	bfe5                	j	80000e68 <strlen+0x20>

0000000080000e72 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e72:	1141                	addi	sp,sp,-16
    80000e74:	e406                	sd	ra,8(sp)
    80000e76:	e022                	sd	s0,0(sp)
    80000e78:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e7a:	00001097          	auipc	ra,0x1
    80000e7e:	af0080e7          	jalr	-1296(ra) # 8000196a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e82:	00008717          	auipc	a4,0x8
    80000e86:	19670713          	addi	a4,a4,406 # 80009018 <started>
  if(cpuid() == 0){
    80000e8a:	c139                	beqz	a0,80000ed0 <main+0x5e>
    while(started == 0)
    80000e8c:	431c                	lw	a5,0(a4)
    80000e8e:	2781                	sext.w	a5,a5
    80000e90:	dff5                	beqz	a5,80000e8c <main+0x1a>
      ;
    __sync_synchronize();
    80000e92:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	ad4080e7          	jalr	-1324(ra) # 8000196a <cpuid>
    80000e9e:	85aa                	mv	a1,a0
    80000ea0:	00007517          	auipc	a0,0x7
    80000ea4:	21850513          	addi	a0,a0,536 # 800080b8 <digits+0x78>
    80000ea8:	fffff097          	auipc	ra,0xfffff
    80000eac:	6da080e7          	jalr	1754(ra) # 80000582 <printf>
    kvminithart();    // turn on paging
    80000eb0:	00000097          	auipc	ra,0x0
    80000eb4:	0d8080e7          	jalr	216(ra) # 80000f88 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb8:	00001097          	auipc	ra,0x1
    80000ebc:	72e080e7          	jalr	1838(ra) # 800025e6 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00005097          	auipc	ra,0x5
    80000ec4:	f60080e7          	jalr	-160(ra) # 80005e20 <plicinithart>
  }

  scheduler();        
    80000ec8:	00001097          	auipc	ra,0x1
    80000ecc:	fdc080e7          	jalr	-36(ra) # 80001ea4 <scheduler>
    consoleinit();
    80000ed0:	fffff097          	auipc	ra,0xfffff
    80000ed4:	57a080e7          	jalr	1402(ra) # 8000044a <consoleinit>
    printfinit();
    80000ed8:	00000097          	auipc	ra,0x0
    80000edc:	88a080e7          	jalr	-1910(ra) # 80000762 <printfinit>
    printf("\n");
    80000ee0:	00007517          	auipc	a0,0x7
    80000ee4:	1e850513          	addi	a0,a0,488 # 800080c8 <digits+0x88>
    80000ee8:	fffff097          	auipc	ra,0xfffff
    80000eec:	69a080e7          	jalr	1690(ra) # 80000582 <printf>
    printf("xv6 kernel is booting\n");
    80000ef0:	00007517          	auipc	a0,0x7
    80000ef4:	1b050513          	addi	a0,a0,432 # 800080a0 <digits+0x60>
    80000ef8:	fffff097          	auipc	ra,0xfffff
    80000efc:	68a080e7          	jalr	1674(ra) # 80000582 <printf>
    printf("\n");
    80000f00:	00007517          	auipc	a0,0x7
    80000f04:	1c850513          	addi	a0,a0,456 # 800080c8 <digits+0x88>
    80000f08:	fffff097          	auipc	ra,0xfffff
    80000f0c:	67a080e7          	jalr	1658(ra) # 80000582 <printf>
    kinit();         // physical page allocator
    80000f10:	00000097          	auipc	ra,0x0
    80000f14:	b94080e7          	jalr	-1132(ra) # 80000aa4 <kinit>
    kvminit();       // create kernel page table
    80000f18:	00000097          	auipc	ra,0x0
    80000f1c:	322080e7          	jalr	802(ra) # 8000123a <kvminit>
    kvminithart();   // turn on paging
    80000f20:	00000097          	auipc	ra,0x0
    80000f24:	068080e7          	jalr	104(ra) # 80000f88 <kvminithart>
    procinit();      // process table
    80000f28:	00001097          	auipc	ra,0x1
    80000f2c:	992080e7          	jalr	-1646(ra) # 800018ba <procinit>
    trapinit();      // trap vectors
    80000f30:	00001097          	auipc	ra,0x1
    80000f34:	68e080e7          	jalr	1678(ra) # 800025be <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00001097          	auipc	ra,0x1
    80000f3c:	6ae080e7          	jalr	1710(ra) # 800025e6 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00005097          	auipc	ra,0x5
    80000f44:	eca080e7          	jalr	-310(ra) # 80005e0a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	ed8080e7          	jalr	-296(ra) # 80005e20 <plicinithart>
    binit();         // buffer cache
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	0a6080e7          	jalr	166(ra) # 80002ff6 <binit>
    iinit();         // inode table
    80000f58:	00002097          	auipc	ra,0x2
    80000f5c:	736080e7          	jalr	1846(ra) # 8000368e <iinit>
    fileinit();      // file table
    80000f60:	00003097          	auipc	ra,0x3
    80000f64:	6e0080e7          	jalr	1760(ra) # 80004640 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	fda080e7          	jalr	-38(ra) # 80005f42 <virtio_disk_init>
    userinit();      // first user process
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	cfe080e7          	jalr	-770(ra) # 80001c6e <userinit>
    __sync_synchronize();
    80000f78:	0ff0000f          	fence
    started = 1;
    80000f7c:	4785                	li	a5,1
    80000f7e:	00008717          	auipc	a4,0x8
    80000f82:	08f72d23          	sw	a5,154(a4) # 80009018 <started>
    80000f86:	b789                	j	80000ec8 <main+0x56>

0000000080000f88 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f88:	1141                	addi	sp,sp,-16
    80000f8a:	e422                	sd	s0,8(sp)
    80000f8c:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000f8e:	00008797          	auipc	a5,0x8
    80000f92:	0927b783          	ld	a5,146(a5) # 80009020 <kernel_pagetable>
    80000f96:	83b1                	srli	a5,a5,0xc
    80000f98:	577d                	li	a4,-1
    80000f9a:	177e                	slli	a4,a4,0x3f
    80000f9c:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000f9e:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fa2:	12000073          	sfence.vma
  sfence_vma();
}
    80000fa6:	6422                	ld	s0,8(sp)
    80000fa8:	0141                	addi	sp,sp,16
    80000faa:	8082                	ret

0000000080000fac <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fac:	7139                	addi	sp,sp,-64
    80000fae:	fc06                	sd	ra,56(sp)
    80000fb0:	f822                	sd	s0,48(sp)
    80000fb2:	f426                	sd	s1,40(sp)
    80000fb4:	f04a                	sd	s2,32(sp)
    80000fb6:	ec4e                	sd	s3,24(sp)
    80000fb8:	e852                	sd	s4,16(sp)
    80000fba:	e456                	sd	s5,8(sp)
    80000fbc:	e05a                	sd	s6,0(sp)
    80000fbe:	0080                	addi	s0,sp,64
    80000fc0:	84aa                	mv	s1,a0
    80000fc2:	89ae                	mv	s3,a1
    80000fc4:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fc6:	57fd                	li	a5,-1
    80000fc8:	83e9                	srli	a5,a5,0x1a
    80000fca:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fcc:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fce:	04b7f263          	bgeu	a5,a1,80001012 <walk+0x66>
    panic("walk");
    80000fd2:	00007517          	auipc	a0,0x7
    80000fd6:	0fe50513          	addi	a0,a0,254 # 800080d0 <digits+0x90>
    80000fda:	fffff097          	auipc	ra,0xfffff
    80000fde:	55e080e7          	jalr	1374(ra) # 80000538 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fe2:	060a8663          	beqz	s5,8000104e <walk+0xa2>
    80000fe6:	00000097          	auipc	ra,0x0
    80000fea:	afa080e7          	jalr	-1286(ra) # 80000ae0 <kalloc>
    80000fee:	84aa                	mv	s1,a0
    80000ff0:	c529                	beqz	a0,8000103a <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ff2:	6605                	lui	a2,0x1
    80000ff4:	4581                	li	a1,0
    80000ff6:	00000097          	auipc	ra,0x0
    80000ffa:	cd6080e7          	jalr	-810(ra) # 80000ccc <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000ffe:	00c4d793          	srli	a5,s1,0xc
    80001002:	07aa                	slli	a5,a5,0xa
    80001004:	0017e793          	ori	a5,a5,1
    80001008:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000100c:	3a5d                	addiw	s4,s4,-9
    8000100e:	036a0063          	beq	s4,s6,8000102e <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001012:	0149d933          	srl	s2,s3,s4
    80001016:	1ff97913          	andi	s2,s2,511
    8000101a:	090e                	slli	s2,s2,0x3
    8000101c:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000101e:	00093483          	ld	s1,0(s2)
    80001022:	0014f793          	andi	a5,s1,1
    80001026:	dfd5                	beqz	a5,80000fe2 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001028:	80a9                	srli	s1,s1,0xa
    8000102a:	04b2                	slli	s1,s1,0xc
    8000102c:	b7c5                	j	8000100c <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000102e:	00c9d513          	srli	a0,s3,0xc
    80001032:	1ff57513          	andi	a0,a0,511
    80001036:	050e                	slli	a0,a0,0x3
    80001038:	9526                	add	a0,a0,s1
}
    8000103a:	70e2                	ld	ra,56(sp)
    8000103c:	7442                	ld	s0,48(sp)
    8000103e:	74a2                	ld	s1,40(sp)
    80001040:	7902                	ld	s2,32(sp)
    80001042:	69e2                	ld	s3,24(sp)
    80001044:	6a42                	ld	s4,16(sp)
    80001046:	6aa2                	ld	s5,8(sp)
    80001048:	6b02                	ld	s6,0(sp)
    8000104a:	6121                	addi	sp,sp,64
    8000104c:	8082                	ret
        return 0;
    8000104e:	4501                	li	a0,0
    80001050:	b7ed                	j	8000103a <walk+0x8e>

0000000080001052 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001052:	57fd                	li	a5,-1
    80001054:	83e9                	srli	a5,a5,0x1a
    80001056:	00b7f463          	bgeu	a5,a1,8000105e <walkaddr+0xc>
    return 0;
    8000105a:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000105c:	8082                	ret
{
    8000105e:	1141                	addi	sp,sp,-16
    80001060:	e406                	sd	ra,8(sp)
    80001062:	e022                	sd	s0,0(sp)
    80001064:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001066:	4601                	li	a2,0
    80001068:	00000097          	auipc	ra,0x0
    8000106c:	f44080e7          	jalr	-188(ra) # 80000fac <walk>
  if(pte == 0)
    80001070:	c105                	beqz	a0,80001090 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001072:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001074:	0117f693          	andi	a3,a5,17
    80001078:	4745                	li	a4,17
    return 0;
    8000107a:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000107c:	00e68663          	beq	a3,a4,80001088 <walkaddr+0x36>
}
    80001080:	60a2                	ld	ra,8(sp)
    80001082:	6402                	ld	s0,0(sp)
    80001084:	0141                	addi	sp,sp,16
    80001086:	8082                	ret
  pa = PTE2PA(*pte);
    80001088:	00a7d513          	srli	a0,a5,0xa
    8000108c:	0532                	slli	a0,a0,0xc
  return pa;
    8000108e:	bfcd                	j	80001080 <walkaddr+0x2e>
    return 0;
    80001090:	4501                	li	a0,0
    80001092:	b7fd                	j	80001080 <walkaddr+0x2e>

0000000080001094 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001094:	715d                	addi	sp,sp,-80
    80001096:	e486                	sd	ra,72(sp)
    80001098:	e0a2                	sd	s0,64(sp)
    8000109a:	fc26                	sd	s1,56(sp)
    8000109c:	f84a                	sd	s2,48(sp)
    8000109e:	f44e                	sd	s3,40(sp)
    800010a0:	f052                	sd	s4,32(sp)
    800010a2:	ec56                	sd	s5,24(sp)
    800010a4:	e85a                	sd	s6,16(sp)
    800010a6:	e45e                	sd	s7,8(sp)
    800010a8:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010aa:	c639                	beqz	a2,800010f8 <mappages+0x64>
    800010ac:	8aaa                	mv	s5,a0
    800010ae:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010b0:	77fd                	lui	a5,0xfffff
    800010b2:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010b6:	15fd                	addi	a1,a1,-1
    800010b8:	00c589b3          	add	s3,a1,a2
    800010bc:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010c0:	8952                	mv	s2,s4
    800010c2:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010c6:	6b85                	lui	s7,0x1
    800010c8:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010cc:	4605                	li	a2,1
    800010ce:	85ca                	mv	a1,s2
    800010d0:	8556                	mv	a0,s5
    800010d2:	00000097          	auipc	ra,0x0
    800010d6:	eda080e7          	jalr	-294(ra) # 80000fac <walk>
    800010da:	cd1d                	beqz	a0,80001118 <mappages+0x84>
    if(*pte & PTE_V)
    800010dc:	611c                	ld	a5,0(a0)
    800010de:	8b85                	andi	a5,a5,1
    800010e0:	e785                	bnez	a5,80001108 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010e2:	80b1                	srli	s1,s1,0xc
    800010e4:	04aa                	slli	s1,s1,0xa
    800010e6:	0164e4b3          	or	s1,s1,s6
    800010ea:	0014e493          	ori	s1,s1,1
    800010ee:	e104                	sd	s1,0(a0)
    if(a == last)
    800010f0:	05390063          	beq	s2,s3,80001130 <mappages+0x9c>
    a += PGSIZE;
    800010f4:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800010f6:	bfc9                	j	800010c8 <mappages+0x34>
    panic("mappages: size");
    800010f8:	00007517          	auipc	a0,0x7
    800010fc:	fe050513          	addi	a0,a0,-32 # 800080d8 <digits+0x98>
    80001100:	fffff097          	auipc	ra,0xfffff
    80001104:	438080e7          	jalr	1080(ra) # 80000538 <panic>
      panic("mappages: remap");
    80001108:	00007517          	auipc	a0,0x7
    8000110c:	fe050513          	addi	a0,a0,-32 # 800080e8 <digits+0xa8>
    80001110:	fffff097          	auipc	ra,0xfffff
    80001114:	428080e7          	jalr	1064(ra) # 80000538 <panic>
      return -1;
    80001118:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000111a:	60a6                	ld	ra,72(sp)
    8000111c:	6406                	ld	s0,64(sp)
    8000111e:	74e2                	ld	s1,56(sp)
    80001120:	7942                	ld	s2,48(sp)
    80001122:	79a2                	ld	s3,40(sp)
    80001124:	7a02                	ld	s4,32(sp)
    80001126:	6ae2                	ld	s5,24(sp)
    80001128:	6b42                	ld	s6,16(sp)
    8000112a:	6ba2                	ld	s7,8(sp)
    8000112c:	6161                	addi	sp,sp,80
    8000112e:	8082                	ret
  return 0;
    80001130:	4501                	li	a0,0
    80001132:	b7e5                	j	8000111a <mappages+0x86>

0000000080001134 <kvmmap>:
{
    80001134:	1141                	addi	sp,sp,-16
    80001136:	e406                	sd	ra,8(sp)
    80001138:	e022                	sd	s0,0(sp)
    8000113a:	0800                	addi	s0,sp,16
    8000113c:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000113e:	86b2                	mv	a3,a2
    80001140:	863e                	mv	a2,a5
    80001142:	00000097          	auipc	ra,0x0
    80001146:	f52080e7          	jalr	-174(ra) # 80001094 <mappages>
    8000114a:	e509                	bnez	a0,80001154 <kvmmap+0x20>
}
    8000114c:	60a2                	ld	ra,8(sp)
    8000114e:	6402                	ld	s0,0(sp)
    80001150:	0141                	addi	sp,sp,16
    80001152:	8082                	ret
    panic("kvmmap");
    80001154:	00007517          	auipc	a0,0x7
    80001158:	fa450513          	addi	a0,a0,-92 # 800080f8 <digits+0xb8>
    8000115c:	fffff097          	auipc	ra,0xfffff
    80001160:	3dc080e7          	jalr	988(ra) # 80000538 <panic>

0000000080001164 <kvmmake>:
{
    80001164:	1101                	addi	sp,sp,-32
    80001166:	ec06                	sd	ra,24(sp)
    80001168:	e822                	sd	s0,16(sp)
    8000116a:	e426                	sd	s1,8(sp)
    8000116c:	e04a                	sd	s2,0(sp)
    8000116e:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001170:	00000097          	auipc	ra,0x0
    80001174:	970080e7          	jalr	-1680(ra) # 80000ae0 <kalloc>
    80001178:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000117a:	6605                	lui	a2,0x1
    8000117c:	4581                	li	a1,0
    8000117e:	00000097          	auipc	ra,0x0
    80001182:	b4e080e7          	jalr	-1202(ra) # 80000ccc <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001186:	4719                	li	a4,6
    80001188:	6685                	lui	a3,0x1
    8000118a:	10000637          	lui	a2,0x10000
    8000118e:	100005b7          	lui	a1,0x10000
    80001192:	8526                	mv	a0,s1
    80001194:	00000097          	auipc	ra,0x0
    80001198:	fa0080e7          	jalr	-96(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000119c:	4719                	li	a4,6
    8000119e:	6685                	lui	a3,0x1
    800011a0:	10001637          	lui	a2,0x10001
    800011a4:	100015b7          	lui	a1,0x10001
    800011a8:	8526                	mv	a0,s1
    800011aa:	00000097          	auipc	ra,0x0
    800011ae:	f8a080e7          	jalr	-118(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011b2:	4719                	li	a4,6
    800011b4:	004006b7          	lui	a3,0x400
    800011b8:	0c000637          	lui	a2,0xc000
    800011bc:	0c0005b7          	lui	a1,0xc000
    800011c0:	8526                	mv	a0,s1
    800011c2:	00000097          	auipc	ra,0x0
    800011c6:	f72080e7          	jalr	-142(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011ca:	00007917          	auipc	s2,0x7
    800011ce:	e3690913          	addi	s2,s2,-458 # 80008000 <etext>
    800011d2:	4729                	li	a4,10
    800011d4:	80007697          	auipc	a3,0x80007
    800011d8:	e2c68693          	addi	a3,a3,-468 # 8000 <_entry-0x7fff8000>
    800011dc:	4605                	li	a2,1
    800011de:	067e                	slli	a2,a2,0x1f
    800011e0:	85b2                	mv	a1,a2
    800011e2:	8526                	mv	a0,s1
    800011e4:	00000097          	auipc	ra,0x0
    800011e8:	f50080e7          	jalr	-176(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011ec:	4719                	li	a4,6
    800011ee:	46c5                	li	a3,17
    800011f0:	06ee                	slli	a3,a3,0x1b
    800011f2:	412686b3          	sub	a3,a3,s2
    800011f6:	864a                	mv	a2,s2
    800011f8:	85ca                	mv	a1,s2
    800011fa:	8526                	mv	a0,s1
    800011fc:	00000097          	auipc	ra,0x0
    80001200:	f38080e7          	jalr	-200(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001204:	4729                	li	a4,10
    80001206:	6685                	lui	a3,0x1
    80001208:	00006617          	auipc	a2,0x6
    8000120c:	df860613          	addi	a2,a2,-520 # 80007000 <_trampoline>
    80001210:	040005b7          	lui	a1,0x4000
    80001214:	15fd                	addi	a1,a1,-1
    80001216:	05b2                	slli	a1,a1,0xc
    80001218:	8526                	mv	a0,s1
    8000121a:	00000097          	auipc	ra,0x0
    8000121e:	f1a080e7          	jalr	-230(ra) # 80001134 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	600080e7          	jalr	1536(ra) # 80001824 <proc_mapstacks>
}
    8000122c:	8526                	mv	a0,s1
    8000122e:	60e2                	ld	ra,24(sp)
    80001230:	6442                	ld	s0,16(sp)
    80001232:	64a2                	ld	s1,8(sp)
    80001234:	6902                	ld	s2,0(sp)
    80001236:	6105                	addi	sp,sp,32
    80001238:	8082                	ret

000000008000123a <kvminit>:
{
    8000123a:	1141                	addi	sp,sp,-16
    8000123c:	e406                	sd	ra,8(sp)
    8000123e:	e022                	sd	s0,0(sp)
    80001240:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001242:	00000097          	auipc	ra,0x0
    80001246:	f22080e7          	jalr	-222(ra) # 80001164 <kvmmake>
    8000124a:	00008797          	auipc	a5,0x8
    8000124e:	dca7bb23          	sd	a0,-554(a5) # 80009020 <kernel_pagetable>
}
    80001252:	60a2                	ld	ra,8(sp)
    80001254:	6402                	ld	s0,0(sp)
    80001256:	0141                	addi	sp,sp,16
    80001258:	8082                	ret

000000008000125a <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000125a:	715d                	addi	sp,sp,-80
    8000125c:	e486                	sd	ra,72(sp)
    8000125e:	e0a2                	sd	s0,64(sp)
    80001260:	fc26                	sd	s1,56(sp)
    80001262:	f84a                	sd	s2,48(sp)
    80001264:	f44e                	sd	s3,40(sp)
    80001266:	f052                	sd	s4,32(sp)
    80001268:	ec56                	sd	s5,24(sp)
    8000126a:	e85a                	sd	s6,16(sp)
    8000126c:	e45e                	sd	s7,8(sp)
    8000126e:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001270:	03459793          	slli	a5,a1,0x34
    80001274:	e795                	bnez	a5,800012a0 <uvmunmap+0x46>
    80001276:	8a2a                	mv	s4,a0
    80001278:	892e                	mv	s2,a1
    8000127a:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000127c:	0632                	slli	a2,a2,0xc
    8000127e:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001282:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001284:	6b05                	lui	s6,0x1
    80001286:	0735e263          	bltu	a1,s3,800012ea <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000128a:	60a6                	ld	ra,72(sp)
    8000128c:	6406                	ld	s0,64(sp)
    8000128e:	74e2                	ld	s1,56(sp)
    80001290:	7942                	ld	s2,48(sp)
    80001292:	79a2                	ld	s3,40(sp)
    80001294:	7a02                	ld	s4,32(sp)
    80001296:	6ae2                	ld	s5,24(sp)
    80001298:	6b42                	ld	s6,16(sp)
    8000129a:	6ba2                	ld	s7,8(sp)
    8000129c:	6161                	addi	sp,sp,80
    8000129e:	8082                	ret
    panic("uvmunmap: not aligned");
    800012a0:	00007517          	auipc	a0,0x7
    800012a4:	e6050513          	addi	a0,a0,-416 # 80008100 <digits+0xc0>
    800012a8:	fffff097          	auipc	ra,0xfffff
    800012ac:	290080e7          	jalr	656(ra) # 80000538 <panic>
      panic("uvmunmap: walk");
    800012b0:	00007517          	auipc	a0,0x7
    800012b4:	e6850513          	addi	a0,a0,-408 # 80008118 <digits+0xd8>
    800012b8:	fffff097          	auipc	ra,0xfffff
    800012bc:	280080e7          	jalr	640(ra) # 80000538 <panic>
      panic("uvmunmap: not mapped");
    800012c0:	00007517          	auipc	a0,0x7
    800012c4:	e6850513          	addi	a0,a0,-408 # 80008128 <digits+0xe8>
    800012c8:	fffff097          	auipc	ra,0xfffff
    800012cc:	270080e7          	jalr	624(ra) # 80000538 <panic>
      panic("uvmunmap: not a leaf");
    800012d0:	00007517          	auipc	a0,0x7
    800012d4:	e7050513          	addi	a0,a0,-400 # 80008140 <digits+0x100>
    800012d8:	fffff097          	auipc	ra,0xfffff
    800012dc:	260080e7          	jalr	608(ra) # 80000538 <panic>
    *pte = 0;
    800012e0:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012e4:	995a                	add	s2,s2,s6
    800012e6:	fb3972e3          	bgeu	s2,s3,8000128a <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012ea:	4601                	li	a2,0
    800012ec:	85ca                	mv	a1,s2
    800012ee:	8552                	mv	a0,s4
    800012f0:	00000097          	auipc	ra,0x0
    800012f4:	cbc080e7          	jalr	-836(ra) # 80000fac <walk>
    800012f8:	84aa                	mv	s1,a0
    800012fa:	d95d                	beqz	a0,800012b0 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800012fc:	6108                	ld	a0,0(a0)
    800012fe:	00157793          	andi	a5,a0,1
    80001302:	dfdd                	beqz	a5,800012c0 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001304:	3ff57793          	andi	a5,a0,1023
    80001308:	fd7784e3          	beq	a5,s7,800012d0 <uvmunmap+0x76>
    if(do_free){
    8000130c:	fc0a8ae3          	beqz	s5,800012e0 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001310:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001312:	0532                	slli	a0,a0,0xc
    80001314:	fffff097          	auipc	ra,0xfffff
    80001318:	6d0080e7          	jalr	1744(ra) # 800009e4 <kfree>
    8000131c:	b7d1                	j	800012e0 <uvmunmap+0x86>

000000008000131e <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000131e:	1101                	addi	sp,sp,-32
    80001320:	ec06                	sd	ra,24(sp)
    80001322:	e822                	sd	s0,16(sp)
    80001324:	e426                	sd	s1,8(sp)
    80001326:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001328:	fffff097          	auipc	ra,0xfffff
    8000132c:	7b8080e7          	jalr	1976(ra) # 80000ae0 <kalloc>
    80001330:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001332:	c519                	beqz	a0,80001340 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001334:	6605                	lui	a2,0x1
    80001336:	4581                	li	a1,0
    80001338:	00000097          	auipc	ra,0x0
    8000133c:	994080e7          	jalr	-1644(ra) # 80000ccc <memset>
  return pagetable;
}
    80001340:	8526                	mv	a0,s1
    80001342:	60e2                	ld	ra,24(sp)
    80001344:	6442                	ld	s0,16(sp)
    80001346:	64a2                	ld	s1,8(sp)
    80001348:	6105                	addi	sp,sp,32
    8000134a:	8082                	ret

000000008000134c <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000134c:	7179                	addi	sp,sp,-48
    8000134e:	f406                	sd	ra,40(sp)
    80001350:	f022                	sd	s0,32(sp)
    80001352:	ec26                	sd	s1,24(sp)
    80001354:	e84a                	sd	s2,16(sp)
    80001356:	e44e                	sd	s3,8(sp)
    80001358:	e052                	sd	s4,0(sp)
    8000135a:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000135c:	6785                	lui	a5,0x1
    8000135e:	04f67863          	bgeu	a2,a5,800013ae <uvminit+0x62>
    80001362:	8a2a                	mv	s4,a0
    80001364:	89ae                	mv	s3,a1
    80001366:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001368:	fffff097          	auipc	ra,0xfffff
    8000136c:	778080e7          	jalr	1912(ra) # 80000ae0 <kalloc>
    80001370:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001372:	6605                	lui	a2,0x1
    80001374:	4581                	li	a1,0
    80001376:	00000097          	auipc	ra,0x0
    8000137a:	956080e7          	jalr	-1706(ra) # 80000ccc <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000137e:	4779                	li	a4,30
    80001380:	86ca                	mv	a3,s2
    80001382:	6605                	lui	a2,0x1
    80001384:	4581                	li	a1,0
    80001386:	8552                	mv	a0,s4
    80001388:	00000097          	auipc	ra,0x0
    8000138c:	d0c080e7          	jalr	-756(ra) # 80001094 <mappages>
  memmove(mem, src, sz);
    80001390:	8626                	mv	a2,s1
    80001392:	85ce                	mv	a1,s3
    80001394:	854a                	mv	a0,s2
    80001396:	00000097          	auipc	ra,0x0
    8000139a:	992080e7          	jalr	-1646(ra) # 80000d28 <memmove>
}
    8000139e:	70a2                	ld	ra,40(sp)
    800013a0:	7402                	ld	s0,32(sp)
    800013a2:	64e2                	ld	s1,24(sp)
    800013a4:	6942                	ld	s2,16(sp)
    800013a6:	69a2                	ld	s3,8(sp)
    800013a8:	6a02                	ld	s4,0(sp)
    800013aa:	6145                	addi	sp,sp,48
    800013ac:	8082                	ret
    panic("inituvm: more than a page");
    800013ae:	00007517          	auipc	a0,0x7
    800013b2:	daa50513          	addi	a0,a0,-598 # 80008158 <digits+0x118>
    800013b6:	fffff097          	auipc	ra,0xfffff
    800013ba:	182080e7          	jalr	386(ra) # 80000538 <panic>

00000000800013be <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013be:	1101                	addi	sp,sp,-32
    800013c0:	ec06                	sd	ra,24(sp)
    800013c2:	e822                	sd	s0,16(sp)
    800013c4:	e426                	sd	s1,8(sp)
    800013c6:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013c8:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013ca:	00b67d63          	bgeu	a2,a1,800013e4 <uvmdealloc+0x26>
    800013ce:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013d0:	6785                	lui	a5,0x1
    800013d2:	17fd                	addi	a5,a5,-1
    800013d4:	00f60733          	add	a4,a2,a5
    800013d8:	767d                	lui	a2,0xfffff
    800013da:	8f71                	and	a4,a4,a2
    800013dc:	97ae                	add	a5,a5,a1
    800013de:	8ff1                	and	a5,a5,a2
    800013e0:	00f76863          	bltu	a4,a5,800013f0 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013e4:	8526                	mv	a0,s1
    800013e6:	60e2                	ld	ra,24(sp)
    800013e8:	6442                	ld	s0,16(sp)
    800013ea:	64a2                	ld	s1,8(sp)
    800013ec:	6105                	addi	sp,sp,32
    800013ee:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013f0:	8f99                	sub	a5,a5,a4
    800013f2:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013f4:	4685                	li	a3,1
    800013f6:	0007861b          	sext.w	a2,a5
    800013fa:	85ba                	mv	a1,a4
    800013fc:	00000097          	auipc	ra,0x0
    80001400:	e5e080e7          	jalr	-418(ra) # 8000125a <uvmunmap>
    80001404:	b7c5                	j	800013e4 <uvmdealloc+0x26>

0000000080001406 <uvmalloc>:
  if(newsz < oldsz)
    80001406:	0ab66163          	bltu	a2,a1,800014a8 <uvmalloc+0xa2>
{
    8000140a:	7139                	addi	sp,sp,-64
    8000140c:	fc06                	sd	ra,56(sp)
    8000140e:	f822                	sd	s0,48(sp)
    80001410:	f426                	sd	s1,40(sp)
    80001412:	f04a                	sd	s2,32(sp)
    80001414:	ec4e                	sd	s3,24(sp)
    80001416:	e852                	sd	s4,16(sp)
    80001418:	e456                	sd	s5,8(sp)
    8000141a:	0080                	addi	s0,sp,64
    8000141c:	8aaa                	mv	s5,a0
    8000141e:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001420:	6985                	lui	s3,0x1
    80001422:	19fd                	addi	s3,s3,-1
    80001424:	95ce                	add	a1,a1,s3
    80001426:	79fd                	lui	s3,0xfffff
    80001428:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000142c:	08c9f063          	bgeu	s3,a2,800014ac <uvmalloc+0xa6>
    80001430:	894e                	mv	s2,s3
    mem = kalloc();
    80001432:	fffff097          	auipc	ra,0xfffff
    80001436:	6ae080e7          	jalr	1710(ra) # 80000ae0 <kalloc>
    8000143a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000143c:	c51d                	beqz	a0,8000146a <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000143e:	6605                	lui	a2,0x1
    80001440:	4581                	li	a1,0
    80001442:	00000097          	auipc	ra,0x0
    80001446:	88a080e7          	jalr	-1910(ra) # 80000ccc <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000144a:	4779                	li	a4,30
    8000144c:	86a6                	mv	a3,s1
    8000144e:	6605                	lui	a2,0x1
    80001450:	85ca                	mv	a1,s2
    80001452:	8556                	mv	a0,s5
    80001454:	00000097          	auipc	ra,0x0
    80001458:	c40080e7          	jalr	-960(ra) # 80001094 <mappages>
    8000145c:	e905                	bnez	a0,8000148c <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000145e:	6785                	lui	a5,0x1
    80001460:	993e                	add	s2,s2,a5
    80001462:	fd4968e3          	bltu	s2,s4,80001432 <uvmalloc+0x2c>
  return newsz;
    80001466:	8552                	mv	a0,s4
    80001468:	a809                	j	8000147a <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000146a:	864e                	mv	a2,s3
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	f4e080e7          	jalr	-178(ra) # 800013be <uvmdealloc>
      return 0;
    80001478:	4501                	li	a0,0
}
    8000147a:	70e2                	ld	ra,56(sp)
    8000147c:	7442                	ld	s0,48(sp)
    8000147e:	74a2                	ld	s1,40(sp)
    80001480:	7902                	ld	s2,32(sp)
    80001482:	69e2                	ld	s3,24(sp)
    80001484:	6a42                	ld	s4,16(sp)
    80001486:	6aa2                	ld	s5,8(sp)
    80001488:	6121                	addi	sp,sp,64
    8000148a:	8082                	ret
      kfree(mem);
    8000148c:	8526                	mv	a0,s1
    8000148e:	fffff097          	auipc	ra,0xfffff
    80001492:	556080e7          	jalr	1366(ra) # 800009e4 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001496:	864e                	mv	a2,s3
    80001498:	85ca                	mv	a1,s2
    8000149a:	8556                	mv	a0,s5
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	f22080e7          	jalr	-222(ra) # 800013be <uvmdealloc>
      return 0;
    800014a4:	4501                	li	a0,0
    800014a6:	bfd1                	j	8000147a <uvmalloc+0x74>
    return oldsz;
    800014a8:	852e                	mv	a0,a1
}
    800014aa:	8082                	ret
  return newsz;
    800014ac:	8532                	mv	a0,a2
    800014ae:	b7f1                	j	8000147a <uvmalloc+0x74>

00000000800014b0 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014b0:	7179                	addi	sp,sp,-48
    800014b2:	f406                	sd	ra,40(sp)
    800014b4:	f022                	sd	s0,32(sp)
    800014b6:	ec26                	sd	s1,24(sp)
    800014b8:	e84a                	sd	s2,16(sp)
    800014ba:	e44e                	sd	s3,8(sp)
    800014bc:	e052                	sd	s4,0(sp)
    800014be:	1800                	addi	s0,sp,48
    800014c0:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014c2:	84aa                	mv	s1,a0
    800014c4:	6905                	lui	s2,0x1
    800014c6:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014c8:	4985                	li	s3,1
    800014ca:	a821                	j	800014e2 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014cc:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ce:	0532                	slli	a0,a0,0xc
    800014d0:	00000097          	auipc	ra,0x0
    800014d4:	fe0080e7          	jalr	-32(ra) # 800014b0 <freewalk>
      pagetable[i] = 0;
    800014d8:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014dc:	04a1                	addi	s1,s1,8
    800014de:	03248163          	beq	s1,s2,80001500 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014e2:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	00f57793          	andi	a5,a0,15
    800014e8:	ff3782e3          	beq	a5,s3,800014cc <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014ec:	8905                	andi	a0,a0,1
    800014ee:	d57d                	beqz	a0,800014dc <freewalk+0x2c>
      panic("freewalk: leaf");
    800014f0:	00007517          	auipc	a0,0x7
    800014f4:	c8850513          	addi	a0,a0,-888 # 80008178 <digits+0x138>
    800014f8:	fffff097          	auipc	ra,0xfffff
    800014fc:	040080e7          	jalr	64(ra) # 80000538 <panic>
    }
  }
  kfree((void*)pagetable);
    80001500:	8552                	mv	a0,s4
    80001502:	fffff097          	auipc	ra,0xfffff
    80001506:	4e2080e7          	jalr	1250(ra) # 800009e4 <kfree>
}
    8000150a:	70a2                	ld	ra,40(sp)
    8000150c:	7402                	ld	s0,32(sp)
    8000150e:	64e2                	ld	s1,24(sp)
    80001510:	6942                	ld	s2,16(sp)
    80001512:	69a2                	ld	s3,8(sp)
    80001514:	6a02                	ld	s4,0(sp)
    80001516:	6145                	addi	sp,sp,48
    80001518:	8082                	ret

000000008000151a <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000151a:	1101                	addi	sp,sp,-32
    8000151c:	ec06                	sd	ra,24(sp)
    8000151e:	e822                	sd	s0,16(sp)
    80001520:	e426                	sd	s1,8(sp)
    80001522:	1000                	addi	s0,sp,32
    80001524:	84aa                	mv	s1,a0
  if(sz > 0)
    80001526:	e999                	bnez	a1,8000153c <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001528:	8526                	mv	a0,s1
    8000152a:	00000097          	auipc	ra,0x0
    8000152e:	f86080e7          	jalr	-122(ra) # 800014b0 <freewalk>
}
    80001532:	60e2                	ld	ra,24(sp)
    80001534:	6442                	ld	s0,16(sp)
    80001536:	64a2                	ld	s1,8(sp)
    80001538:	6105                	addi	sp,sp,32
    8000153a:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000153c:	6605                	lui	a2,0x1
    8000153e:	167d                	addi	a2,a2,-1
    80001540:	962e                	add	a2,a2,a1
    80001542:	4685                	li	a3,1
    80001544:	8231                	srli	a2,a2,0xc
    80001546:	4581                	li	a1,0
    80001548:	00000097          	auipc	ra,0x0
    8000154c:	d12080e7          	jalr	-750(ra) # 8000125a <uvmunmap>
    80001550:	bfe1                	j	80001528 <uvmfree+0xe>

0000000080001552 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001552:	c679                	beqz	a2,80001620 <uvmcopy+0xce>
{
    80001554:	715d                	addi	sp,sp,-80
    80001556:	e486                	sd	ra,72(sp)
    80001558:	e0a2                	sd	s0,64(sp)
    8000155a:	fc26                	sd	s1,56(sp)
    8000155c:	f84a                	sd	s2,48(sp)
    8000155e:	f44e                	sd	s3,40(sp)
    80001560:	f052                	sd	s4,32(sp)
    80001562:	ec56                	sd	s5,24(sp)
    80001564:	e85a                	sd	s6,16(sp)
    80001566:	e45e                	sd	s7,8(sp)
    80001568:	0880                	addi	s0,sp,80
    8000156a:	8b2a                	mv	s6,a0
    8000156c:	8aae                	mv	s5,a1
    8000156e:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001570:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001572:	4601                	li	a2,0
    80001574:	85ce                	mv	a1,s3
    80001576:	855a                	mv	a0,s6
    80001578:	00000097          	auipc	ra,0x0
    8000157c:	a34080e7          	jalr	-1484(ra) # 80000fac <walk>
    80001580:	c531                	beqz	a0,800015cc <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001582:	6118                	ld	a4,0(a0)
    80001584:	00177793          	andi	a5,a4,1
    80001588:	cbb1                	beqz	a5,800015dc <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000158a:	00a75593          	srli	a1,a4,0xa
    8000158e:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001592:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001596:	fffff097          	auipc	ra,0xfffff
    8000159a:	54a080e7          	jalr	1354(ra) # 80000ae0 <kalloc>
    8000159e:	892a                	mv	s2,a0
    800015a0:	c939                	beqz	a0,800015f6 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015a2:	6605                	lui	a2,0x1
    800015a4:	85de                	mv	a1,s7
    800015a6:	fffff097          	auipc	ra,0xfffff
    800015aa:	782080e7          	jalr	1922(ra) # 80000d28 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ae:	8726                	mv	a4,s1
    800015b0:	86ca                	mv	a3,s2
    800015b2:	6605                	lui	a2,0x1
    800015b4:	85ce                	mv	a1,s3
    800015b6:	8556                	mv	a0,s5
    800015b8:	00000097          	auipc	ra,0x0
    800015bc:	adc080e7          	jalr	-1316(ra) # 80001094 <mappages>
    800015c0:	e515                	bnez	a0,800015ec <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015c2:	6785                	lui	a5,0x1
    800015c4:	99be                	add	s3,s3,a5
    800015c6:	fb49e6e3          	bltu	s3,s4,80001572 <uvmcopy+0x20>
    800015ca:	a081                	j	8000160a <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015cc:	00007517          	auipc	a0,0x7
    800015d0:	bbc50513          	addi	a0,a0,-1092 # 80008188 <digits+0x148>
    800015d4:	fffff097          	auipc	ra,0xfffff
    800015d8:	f64080e7          	jalr	-156(ra) # 80000538 <panic>
      panic("uvmcopy: page not present");
    800015dc:	00007517          	auipc	a0,0x7
    800015e0:	bcc50513          	addi	a0,a0,-1076 # 800081a8 <digits+0x168>
    800015e4:	fffff097          	auipc	ra,0xfffff
    800015e8:	f54080e7          	jalr	-172(ra) # 80000538 <panic>
      kfree(mem);
    800015ec:	854a                	mv	a0,s2
    800015ee:	fffff097          	auipc	ra,0xfffff
    800015f2:	3f6080e7          	jalr	1014(ra) # 800009e4 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800015f6:	4685                	li	a3,1
    800015f8:	00c9d613          	srli	a2,s3,0xc
    800015fc:	4581                	li	a1,0
    800015fe:	8556                	mv	a0,s5
    80001600:	00000097          	auipc	ra,0x0
    80001604:	c5a080e7          	jalr	-934(ra) # 8000125a <uvmunmap>
  return -1;
    80001608:	557d                	li	a0,-1
}
    8000160a:	60a6                	ld	ra,72(sp)
    8000160c:	6406                	ld	s0,64(sp)
    8000160e:	74e2                	ld	s1,56(sp)
    80001610:	7942                	ld	s2,48(sp)
    80001612:	79a2                	ld	s3,40(sp)
    80001614:	7a02                	ld	s4,32(sp)
    80001616:	6ae2                	ld	s5,24(sp)
    80001618:	6b42                	ld	s6,16(sp)
    8000161a:	6ba2                	ld	s7,8(sp)
    8000161c:	6161                	addi	sp,sp,80
    8000161e:	8082                	ret
  return 0;
    80001620:	4501                	li	a0,0
}
    80001622:	8082                	ret

0000000080001624 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001624:	1141                	addi	sp,sp,-16
    80001626:	e406                	sd	ra,8(sp)
    80001628:	e022                	sd	s0,0(sp)
    8000162a:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000162c:	4601                	li	a2,0
    8000162e:	00000097          	auipc	ra,0x0
    80001632:	97e080e7          	jalr	-1666(ra) # 80000fac <walk>
  if(pte == 0)
    80001636:	c901                	beqz	a0,80001646 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001638:	611c                	ld	a5,0(a0)
    8000163a:	9bbd                	andi	a5,a5,-17
    8000163c:	e11c                	sd	a5,0(a0)
}
    8000163e:	60a2                	ld	ra,8(sp)
    80001640:	6402                	ld	s0,0(sp)
    80001642:	0141                	addi	sp,sp,16
    80001644:	8082                	ret
    panic("uvmclear");
    80001646:	00007517          	auipc	a0,0x7
    8000164a:	b8250513          	addi	a0,a0,-1150 # 800081c8 <digits+0x188>
    8000164e:	fffff097          	auipc	ra,0xfffff
    80001652:	eea080e7          	jalr	-278(ra) # 80000538 <panic>

0000000080001656 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001656:	c6bd                	beqz	a3,800016c4 <copyout+0x6e>
{
    80001658:	715d                	addi	sp,sp,-80
    8000165a:	e486                	sd	ra,72(sp)
    8000165c:	e0a2                	sd	s0,64(sp)
    8000165e:	fc26                	sd	s1,56(sp)
    80001660:	f84a                	sd	s2,48(sp)
    80001662:	f44e                	sd	s3,40(sp)
    80001664:	f052                	sd	s4,32(sp)
    80001666:	ec56                	sd	s5,24(sp)
    80001668:	e85a                	sd	s6,16(sp)
    8000166a:	e45e                	sd	s7,8(sp)
    8000166c:	e062                	sd	s8,0(sp)
    8000166e:	0880                	addi	s0,sp,80
    80001670:	8b2a                	mv	s6,a0
    80001672:	8c2e                	mv	s8,a1
    80001674:	8a32                	mv	s4,a2
    80001676:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001678:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000167a:	6a85                	lui	s5,0x1
    8000167c:	a015                	j	800016a0 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000167e:	9562                	add	a0,a0,s8
    80001680:	0004861b          	sext.w	a2,s1
    80001684:	85d2                	mv	a1,s4
    80001686:	41250533          	sub	a0,a0,s2
    8000168a:	fffff097          	auipc	ra,0xfffff
    8000168e:	69e080e7          	jalr	1694(ra) # 80000d28 <memmove>

    len -= n;
    80001692:	409989b3          	sub	s3,s3,s1
    src += n;
    80001696:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001698:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000169c:	02098263          	beqz	s3,800016c0 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016a0:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016a4:	85ca                	mv	a1,s2
    800016a6:	855a                	mv	a0,s6
    800016a8:	00000097          	auipc	ra,0x0
    800016ac:	9aa080e7          	jalr	-1622(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    800016b0:	cd01                	beqz	a0,800016c8 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016b2:	418904b3          	sub	s1,s2,s8
    800016b6:	94d6                	add	s1,s1,s5
    if(n > len)
    800016b8:	fc99f3e3          	bgeu	s3,s1,8000167e <copyout+0x28>
    800016bc:	84ce                	mv	s1,s3
    800016be:	b7c1                	j	8000167e <copyout+0x28>
  }
  return 0;
    800016c0:	4501                	li	a0,0
    800016c2:	a021                	j	800016ca <copyout+0x74>
    800016c4:	4501                	li	a0,0
}
    800016c6:	8082                	ret
      return -1;
    800016c8:	557d                	li	a0,-1
}
    800016ca:	60a6                	ld	ra,72(sp)
    800016cc:	6406                	ld	s0,64(sp)
    800016ce:	74e2                	ld	s1,56(sp)
    800016d0:	7942                	ld	s2,48(sp)
    800016d2:	79a2                	ld	s3,40(sp)
    800016d4:	7a02                	ld	s4,32(sp)
    800016d6:	6ae2                	ld	s5,24(sp)
    800016d8:	6b42                	ld	s6,16(sp)
    800016da:	6ba2                	ld	s7,8(sp)
    800016dc:	6c02                	ld	s8,0(sp)
    800016de:	6161                	addi	sp,sp,80
    800016e0:	8082                	ret

00000000800016e2 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016e2:	caa5                	beqz	a3,80001752 <copyin+0x70>
{
    800016e4:	715d                	addi	sp,sp,-80
    800016e6:	e486                	sd	ra,72(sp)
    800016e8:	e0a2                	sd	s0,64(sp)
    800016ea:	fc26                	sd	s1,56(sp)
    800016ec:	f84a                	sd	s2,48(sp)
    800016ee:	f44e                	sd	s3,40(sp)
    800016f0:	f052                	sd	s4,32(sp)
    800016f2:	ec56                	sd	s5,24(sp)
    800016f4:	e85a                	sd	s6,16(sp)
    800016f6:	e45e                	sd	s7,8(sp)
    800016f8:	e062                	sd	s8,0(sp)
    800016fa:	0880                	addi	s0,sp,80
    800016fc:	8b2a                	mv	s6,a0
    800016fe:	8a2e                	mv	s4,a1
    80001700:	8c32                	mv	s8,a2
    80001702:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001704:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001706:	6a85                	lui	s5,0x1
    80001708:	a01d                	j	8000172e <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000170a:	018505b3          	add	a1,a0,s8
    8000170e:	0004861b          	sext.w	a2,s1
    80001712:	412585b3          	sub	a1,a1,s2
    80001716:	8552                	mv	a0,s4
    80001718:	fffff097          	auipc	ra,0xfffff
    8000171c:	610080e7          	jalr	1552(ra) # 80000d28 <memmove>

    len -= n;
    80001720:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001724:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001726:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000172a:	02098263          	beqz	s3,8000174e <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000172e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001732:	85ca                	mv	a1,s2
    80001734:	855a                	mv	a0,s6
    80001736:	00000097          	auipc	ra,0x0
    8000173a:	91c080e7          	jalr	-1764(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    8000173e:	cd01                	beqz	a0,80001756 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001740:	418904b3          	sub	s1,s2,s8
    80001744:	94d6                	add	s1,s1,s5
    if(n > len)
    80001746:	fc99f2e3          	bgeu	s3,s1,8000170a <copyin+0x28>
    8000174a:	84ce                	mv	s1,s3
    8000174c:	bf7d                	j	8000170a <copyin+0x28>
  }
  return 0;
    8000174e:	4501                	li	a0,0
    80001750:	a021                	j	80001758 <copyin+0x76>
    80001752:	4501                	li	a0,0
}
    80001754:	8082                	ret
      return -1;
    80001756:	557d                	li	a0,-1
}
    80001758:	60a6                	ld	ra,72(sp)
    8000175a:	6406                	ld	s0,64(sp)
    8000175c:	74e2                	ld	s1,56(sp)
    8000175e:	7942                	ld	s2,48(sp)
    80001760:	79a2                	ld	s3,40(sp)
    80001762:	7a02                	ld	s4,32(sp)
    80001764:	6ae2                	ld	s5,24(sp)
    80001766:	6b42                	ld	s6,16(sp)
    80001768:	6ba2                	ld	s7,8(sp)
    8000176a:	6c02                	ld	s8,0(sp)
    8000176c:	6161                	addi	sp,sp,80
    8000176e:	8082                	ret

0000000080001770 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001770:	c6c5                	beqz	a3,80001818 <copyinstr+0xa8>
{
    80001772:	715d                	addi	sp,sp,-80
    80001774:	e486                	sd	ra,72(sp)
    80001776:	e0a2                	sd	s0,64(sp)
    80001778:	fc26                	sd	s1,56(sp)
    8000177a:	f84a                	sd	s2,48(sp)
    8000177c:	f44e                	sd	s3,40(sp)
    8000177e:	f052                	sd	s4,32(sp)
    80001780:	ec56                	sd	s5,24(sp)
    80001782:	e85a                	sd	s6,16(sp)
    80001784:	e45e                	sd	s7,8(sp)
    80001786:	0880                	addi	s0,sp,80
    80001788:	8a2a                	mv	s4,a0
    8000178a:	8b2e                	mv	s6,a1
    8000178c:	8bb2                	mv	s7,a2
    8000178e:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001790:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001792:	6985                	lui	s3,0x1
    80001794:	a035                	j	800017c0 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001796:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000179a:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000179c:	0017b793          	seqz	a5,a5
    800017a0:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017a4:	60a6                	ld	ra,72(sp)
    800017a6:	6406                	ld	s0,64(sp)
    800017a8:	74e2                	ld	s1,56(sp)
    800017aa:	7942                	ld	s2,48(sp)
    800017ac:	79a2                	ld	s3,40(sp)
    800017ae:	7a02                	ld	s4,32(sp)
    800017b0:	6ae2                	ld	s5,24(sp)
    800017b2:	6b42                	ld	s6,16(sp)
    800017b4:	6ba2                	ld	s7,8(sp)
    800017b6:	6161                	addi	sp,sp,80
    800017b8:	8082                	ret
    srcva = va0 + PGSIZE;
    800017ba:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017be:	c8a9                	beqz	s1,80001810 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017c0:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017c4:	85ca                	mv	a1,s2
    800017c6:	8552                	mv	a0,s4
    800017c8:	00000097          	auipc	ra,0x0
    800017cc:	88a080e7          	jalr	-1910(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    800017d0:	c131                	beqz	a0,80001814 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017d2:	41790833          	sub	a6,s2,s7
    800017d6:	984e                	add	a6,a6,s3
    if(n > max)
    800017d8:	0104f363          	bgeu	s1,a6,800017de <copyinstr+0x6e>
    800017dc:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017de:	955e                	add	a0,a0,s7
    800017e0:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017e4:	fc080be3          	beqz	a6,800017ba <copyinstr+0x4a>
    800017e8:	985a                	add	a6,a6,s6
    800017ea:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017ec:	41650633          	sub	a2,a0,s6
    800017f0:	14fd                	addi	s1,s1,-1
    800017f2:	9b26                	add	s6,s6,s1
    800017f4:	00f60733          	add	a4,a2,a5
    800017f8:	00074703          	lbu	a4,0(a4)
    800017fc:	df49                	beqz	a4,80001796 <copyinstr+0x26>
        *dst = *p;
    800017fe:	00e78023          	sb	a4,0(a5)
      --max;
    80001802:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001806:	0785                	addi	a5,a5,1
    while(n > 0){
    80001808:	ff0796e3          	bne	a5,a6,800017f4 <copyinstr+0x84>
      dst++;
    8000180c:	8b42                	mv	s6,a6
    8000180e:	b775                	j	800017ba <copyinstr+0x4a>
    80001810:	4781                	li	a5,0
    80001812:	b769                	j	8000179c <copyinstr+0x2c>
      return -1;
    80001814:	557d                	li	a0,-1
    80001816:	b779                	j	800017a4 <copyinstr+0x34>
  int got_null = 0;
    80001818:	4781                	li	a5,0
  if(got_null){
    8000181a:	0017b793          	seqz	a5,a5
    8000181e:	40f00533          	neg	a0,a5
}
    80001822:	8082                	ret

0000000080001824 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001824:	7139                	addi	sp,sp,-64
    80001826:	fc06                	sd	ra,56(sp)
    80001828:	f822                	sd	s0,48(sp)
    8000182a:	f426                	sd	s1,40(sp)
    8000182c:	f04a                	sd	s2,32(sp)
    8000182e:	ec4e                	sd	s3,24(sp)
    80001830:	e852                	sd	s4,16(sp)
    80001832:	e456                	sd	s5,8(sp)
    80001834:	e05a                	sd	s6,0(sp)
    80001836:	0080                	addi	s0,sp,64
    80001838:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000183a:	00010497          	auipc	s1,0x10
    8000183e:	e9648493          	addi	s1,s1,-362 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001842:	8b26                	mv	s6,s1
    80001844:	00006a97          	auipc	s5,0x6
    80001848:	7bca8a93          	addi	s5,s5,1980 # 80008000 <etext>
    8000184c:	04000937          	lui	s2,0x4000
    80001850:	197d                	addi	s2,s2,-1
    80001852:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001854:	00016a17          	auipc	s4,0x16
    80001858:	87ca0a13          	addi	s4,s4,-1924 # 800170d0 <tickslock>
    char *pa = kalloc();
    8000185c:	fffff097          	auipc	ra,0xfffff
    80001860:	284080e7          	jalr	644(ra) # 80000ae0 <kalloc>
    80001864:	862a                	mv	a2,a0
    if(pa == 0)
    80001866:	c131                	beqz	a0,800018aa <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001868:	416485b3          	sub	a1,s1,s6
    8000186c:	858d                	srai	a1,a1,0x3
    8000186e:	000ab783          	ld	a5,0(s5)
    80001872:	02f585b3          	mul	a1,a1,a5
    80001876:	2585                	addiw	a1,a1,1
    80001878:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000187c:	4719                	li	a4,6
    8000187e:	6685                	lui	a3,0x1
    80001880:	40b905b3          	sub	a1,s2,a1
    80001884:	854e                	mv	a0,s3
    80001886:	00000097          	auipc	ra,0x0
    8000188a:	8ae080e7          	jalr	-1874(ra) # 80001134 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000188e:	16848493          	addi	s1,s1,360
    80001892:	fd4495e3          	bne	s1,s4,8000185c <proc_mapstacks+0x38>
  }
}
    80001896:	70e2                	ld	ra,56(sp)
    80001898:	7442                	ld	s0,48(sp)
    8000189a:	74a2                	ld	s1,40(sp)
    8000189c:	7902                	ld	s2,32(sp)
    8000189e:	69e2                	ld	s3,24(sp)
    800018a0:	6a42                	ld	s4,16(sp)
    800018a2:	6aa2                	ld	s5,8(sp)
    800018a4:	6b02                	ld	s6,0(sp)
    800018a6:	6121                	addi	sp,sp,64
    800018a8:	8082                	ret
      panic("kalloc");
    800018aa:	00007517          	auipc	a0,0x7
    800018ae:	92e50513          	addi	a0,a0,-1746 # 800081d8 <digits+0x198>
    800018b2:	fffff097          	auipc	ra,0xfffff
    800018b6:	c86080e7          	jalr	-890(ra) # 80000538 <panic>

00000000800018ba <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018ba:	7139                	addi	sp,sp,-64
    800018bc:	fc06                	sd	ra,56(sp)
    800018be:	f822                	sd	s0,48(sp)
    800018c0:	f426                	sd	s1,40(sp)
    800018c2:	f04a                	sd	s2,32(sp)
    800018c4:	ec4e                	sd	s3,24(sp)
    800018c6:	e852                	sd	s4,16(sp)
    800018c8:	e456                	sd	s5,8(sp)
    800018ca:	e05a                	sd	s6,0(sp)
    800018cc:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018ce:	00007597          	auipc	a1,0x7
    800018d2:	91258593          	addi	a1,a1,-1774 # 800081e0 <digits+0x1a0>
    800018d6:	00010517          	auipc	a0,0x10
    800018da:	9ca50513          	addi	a0,a0,-1590 # 800112a0 <pid_lock>
    800018de:	fffff097          	auipc	ra,0xfffff
    800018e2:	262080e7          	jalr	610(ra) # 80000b40 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018e6:	00007597          	auipc	a1,0x7
    800018ea:	90258593          	addi	a1,a1,-1790 # 800081e8 <digits+0x1a8>
    800018ee:	00010517          	auipc	a0,0x10
    800018f2:	9ca50513          	addi	a0,a0,-1590 # 800112b8 <wait_lock>
    800018f6:	fffff097          	auipc	ra,0xfffff
    800018fa:	24a080e7          	jalr	586(ra) # 80000b40 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018fe:	00010497          	auipc	s1,0x10
    80001902:	dd248493          	addi	s1,s1,-558 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001906:	00007b17          	auipc	s6,0x7
    8000190a:	8f2b0b13          	addi	s6,s6,-1806 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    8000190e:	8aa6                	mv	s5,s1
    80001910:	00006a17          	auipc	s4,0x6
    80001914:	6f0a0a13          	addi	s4,s4,1776 # 80008000 <etext>
    80001918:	04000937          	lui	s2,0x4000
    8000191c:	197d                	addi	s2,s2,-1
    8000191e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001920:	00015997          	auipc	s3,0x15
    80001924:	7b098993          	addi	s3,s3,1968 # 800170d0 <tickslock>
      initlock(&p->lock, "proc");
    80001928:	85da                	mv	a1,s6
    8000192a:	8526                	mv	a0,s1
    8000192c:	fffff097          	auipc	ra,0xfffff
    80001930:	214080e7          	jalr	532(ra) # 80000b40 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001934:	415487b3          	sub	a5,s1,s5
    80001938:	878d                	srai	a5,a5,0x3
    8000193a:	000a3703          	ld	a4,0(s4)
    8000193e:	02e787b3          	mul	a5,a5,a4
    80001942:	2785                	addiw	a5,a5,1
    80001944:	00d7979b          	slliw	a5,a5,0xd
    80001948:	40f907b3          	sub	a5,s2,a5
    8000194c:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000194e:	16848493          	addi	s1,s1,360
    80001952:	fd349be3          	bne	s1,s3,80001928 <procinit+0x6e>
  }
}
    80001956:	70e2                	ld	ra,56(sp)
    80001958:	7442                	ld	s0,48(sp)
    8000195a:	74a2                	ld	s1,40(sp)
    8000195c:	7902                	ld	s2,32(sp)
    8000195e:	69e2                	ld	s3,24(sp)
    80001960:	6a42                	ld	s4,16(sp)
    80001962:	6aa2                	ld	s5,8(sp)
    80001964:	6b02                	ld	s6,0(sp)
    80001966:	6121                	addi	sp,sp,64
    80001968:	8082                	ret

000000008000196a <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    8000196a:	1141                	addi	sp,sp,-16
    8000196c:	e422                	sd	s0,8(sp)
    8000196e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001970:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001972:	2501                	sext.w	a0,a0
    80001974:	6422                	ld	s0,8(sp)
    80001976:	0141                	addi	sp,sp,16
    80001978:	8082                	ret

000000008000197a <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    8000197a:	1141                	addi	sp,sp,-16
    8000197c:	e422                	sd	s0,8(sp)
    8000197e:	0800                	addi	s0,sp,16
    80001980:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001982:	2781                	sext.w	a5,a5
    80001984:	079e                	slli	a5,a5,0x7
  return c;
}
    80001986:	00010517          	auipc	a0,0x10
    8000198a:	94a50513          	addi	a0,a0,-1718 # 800112d0 <cpus>
    8000198e:	953e                	add	a0,a0,a5
    80001990:	6422                	ld	s0,8(sp)
    80001992:	0141                	addi	sp,sp,16
    80001994:	8082                	ret

0000000080001996 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001996:	1101                	addi	sp,sp,-32
    80001998:	ec06                	sd	ra,24(sp)
    8000199a:	e822                	sd	s0,16(sp)
    8000199c:	e426                	sd	s1,8(sp)
    8000199e:	1000                	addi	s0,sp,32
  push_off();
    800019a0:	fffff097          	auipc	ra,0xfffff
    800019a4:	1e4080e7          	jalr	484(ra) # 80000b84 <push_off>
    800019a8:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019aa:	2781                	sext.w	a5,a5
    800019ac:	079e                	slli	a5,a5,0x7
    800019ae:	00010717          	auipc	a4,0x10
    800019b2:	8f270713          	addi	a4,a4,-1806 # 800112a0 <pid_lock>
    800019b6:	97ba                	add	a5,a5,a4
    800019b8:	7b84                	ld	s1,48(a5)
  pop_off();
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	26a080e7          	jalr	618(ra) # 80000c24 <pop_off>
  return p;
}
    800019c2:	8526                	mv	a0,s1
    800019c4:	60e2                	ld	ra,24(sp)
    800019c6:	6442                	ld	s0,16(sp)
    800019c8:	64a2                	ld	s1,8(sp)
    800019ca:	6105                	addi	sp,sp,32
    800019cc:	8082                	ret

00000000800019ce <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019ce:	1141                	addi	sp,sp,-16
    800019d0:	e406                	sd	ra,8(sp)
    800019d2:	e022                	sd	s0,0(sp)
    800019d4:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019d6:	00000097          	auipc	ra,0x0
    800019da:	fc0080e7          	jalr	-64(ra) # 80001996 <myproc>
    800019de:	fffff097          	auipc	ra,0xfffff
    800019e2:	2a6080e7          	jalr	678(ra) # 80000c84 <release>

  if (first) {
    800019e6:	00007797          	auipc	a5,0x7
    800019ea:	e6a7a783          	lw	a5,-406(a5) # 80008850 <first.1>
    800019ee:	eb89                	bnez	a5,80001a00 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    800019f0:	00001097          	auipc	ra,0x1
    800019f4:	c0e080e7          	jalr	-1010(ra) # 800025fe <usertrapret>
}
    800019f8:	60a2                	ld	ra,8(sp)
    800019fa:	6402                	ld	s0,0(sp)
    800019fc:	0141                	addi	sp,sp,16
    800019fe:	8082                	ret
    first = 0;
    80001a00:	00007797          	auipc	a5,0x7
    80001a04:	e407a823          	sw	zero,-432(a5) # 80008850 <first.1>
    fsinit(ROOTDEV);
    80001a08:	4505                	li	a0,1
    80001a0a:	00002097          	auipc	ra,0x2
    80001a0e:	c04080e7          	jalr	-1020(ra) # 8000360e <fsinit>
    80001a12:	bff9                	j	800019f0 <forkret+0x22>

0000000080001a14 <allocpid>:
allocpid() {
    80001a14:	1101                	addi	sp,sp,-32
    80001a16:	ec06                	sd	ra,24(sp)
    80001a18:	e822                	sd	s0,16(sp)
    80001a1a:	e426                	sd	s1,8(sp)
    80001a1c:	e04a                	sd	s2,0(sp)
    80001a1e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a20:	00010917          	auipc	s2,0x10
    80001a24:	88090913          	addi	s2,s2,-1920 # 800112a0 <pid_lock>
    80001a28:	854a                	mv	a0,s2
    80001a2a:	fffff097          	auipc	ra,0xfffff
    80001a2e:	1a6080e7          	jalr	422(ra) # 80000bd0 <acquire>
  pid = nextpid;
    80001a32:	00007797          	auipc	a5,0x7
    80001a36:	e2278793          	addi	a5,a5,-478 # 80008854 <nextpid>
    80001a3a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a3c:	0014871b          	addiw	a4,s1,1
    80001a40:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a42:	854a                	mv	a0,s2
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	240080e7          	jalr	576(ra) # 80000c84 <release>
}
    80001a4c:	8526                	mv	a0,s1
    80001a4e:	60e2                	ld	ra,24(sp)
    80001a50:	6442                	ld	s0,16(sp)
    80001a52:	64a2                	ld	s1,8(sp)
    80001a54:	6902                	ld	s2,0(sp)
    80001a56:	6105                	addi	sp,sp,32
    80001a58:	8082                	ret

0000000080001a5a <proc_pagetable>:
{
    80001a5a:	1101                	addi	sp,sp,-32
    80001a5c:	ec06                	sd	ra,24(sp)
    80001a5e:	e822                	sd	s0,16(sp)
    80001a60:	e426                	sd	s1,8(sp)
    80001a62:	e04a                	sd	s2,0(sp)
    80001a64:	1000                	addi	s0,sp,32
    80001a66:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a68:	00000097          	auipc	ra,0x0
    80001a6c:	8b6080e7          	jalr	-1866(ra) # 8000131e <uvmcreate>
    80001a70:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a72:	c121                	beqz	a0,80001ab2 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a74:	4729                	li	a4,10
    80001a76:	00005697          	auipc	a3,0x5
    80001a7a:	58a68693          	addi	a3,a3,1418 # 80007000 <_trampoline>
    80001a7e:	6605                	lui	a2,0x1
    80001a80:	040005b7          	lui	a1,0x4000
    80001a84:	15fd                	addi	a1,a1,-1
    80001a86:	05b2                	slli	a1,a1,0xc
    80001a88:	fffff097          	auipc	ra,0xfffff
    80001a8c:	60c080e7          	jalr	1548(ra) # 80001094 <mappages>
    80001a90:	02054863          	bltz	a0,80001ac0 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001a94:	4719                	li	a4,6
    80001a96:	05893683          	ld	a3,88(s2)
    80001a9a:	6605                	lui	a2,0x1
    80001a9c:	020005b7          	lui	a1,0x2000
    80001aa0:	15fd                	addi	a1,a1,-1
    80001aa2:	05b6                	slli	a1,a1,0xd
    80001aa4:	8526                	mv	a0,s1
    80001aa6:	fffff097          	auipc	ra,0xfffff
    80001aaa:	5ee080e7          	jalr	1518(ra) # 80001094 <mappages>
    80001aae:	02054163          	bltz	a0,80001ad0 <proc_pagetable+0x76>
}
    80001ab2:	8526                	mv	a0,s1
    80001ab4:	60e2                	ld	ra,24(sp)
    80001ab6:	6442                	ld	s0,16(sp)
    80001ab8:	64a2                	ld	s1,8(sp)
    80001aba:	6902                	ld	s2,0(sp)
    80001abc:	6105                	addi	sp,sp,32
    80001abe:	8082                	ret
    uvmfree(pagetable, 0);
    80001ac0:	4581                	li	a1,0
    80001ac2:	8526                	mv	a0,s1
    80001ac4:	00000097          	auipc	ra,0x0
    80001ac8:	a56080e7          	jalr	-1450(ra) # 8000151a <uvmfree>
    return 0;
    80001acc:	4481                	li	s1,0
    80001ace:	b7d5                	j	80001ab2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ad0:	4681                	li	a3,0
    80001ad2:	4605                	li	a2,1
    80001ad4:	040005b7          	lui	a1,0x4000
    80001ad8:	15fd                	addi	a1,a1,-1
    80001ada:	05b2                	slli	a1,a1,0xc
    80001adc:	8526                	mv	a0,s1
    80001ade:	fffff097          	auipc	ra,0xfffff
    80001ae2:	77c080e7          	jalr	1916(ra) # 8000125a <uvmunmap>
    uvmfree(pagetable, 0);
    80001ae6:	4581                	li	a1,0
    80001ae8:	8526                	mv	a0,s1
    80001aea:	00000097          	auipc	ra,0x0
    80001aee:	a30080e7          	jalr	-1488(ra) # 8000151a <uvmfree>
    return 0;
    80001af2:	4481                	li	s1,0
    80001af4:	bf7d                	j	80001ab2 <proc_pagetable+0x58>

0000000080001af6 <proc_freepagetable>:
{
    80001af6:	1101                	addi	sp,sp,-32
    80001af8:	ec06                	sd	ra,24(sp)
    80001afa:	e822                	sd	s0,16(sp)
    80001afc:	e426                	sd	s1,8(sp)
    80001afe:	e04a                	sd	s2,0(sp)
    80001b00:	1000                	addi	s0,sp,32
    80001b02:	84aa                	mv	s1,a0
    80001b04:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b06:	4681                	li	a3,0
    80001b08:	4605                	li	a2,1
    80001b0a:	040005b7          	lui	a1,0x4000
    80001b0e:	15fd                	addi	a1,a1,-1
    80001b10:	05b2                	slli	a1,a1,0xc
    80001b12:	fffff097          	auipc	ra,0xfffff
    80001b16:	748080e7          	jalr	1864(ra) # 8000125a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b1a:	4681                	li	a3,0
    80001b1c:	4605                	li	a2,1
    80001b1e:	020005b7          	lui	a1,0x2000
    80001b22:	15fd                	addi	a1,a1,-1
    80001b24:	05b6                	slli	a1,a1,0xd
    80001b26:	8526                	mv	a0,s1
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	732080e7          	jalr	1842(ra) # 8000125a <uvmunmap>
  uvmfree(pagetable, sz);
    80001b30:	85ca                	mv	a1,s2
    80001b32:	8526                	mv	a0,s1
    80001b34:	00000097          	auipc	ra,0x0
    80001b38:	9e6080e7          	jalr	-1562(ra) # 8000151a <uvmfree>
}
    80001b3c:	60e2                	ld	ra,24(sp)
    80001b3e:	6442                	ld	s0,16(sp)
    80001b40:	64a2                	ld	s1,8(sp)
    80001b42:	6902                	ld	s2,0(sp)
    80001b44:	6105                	addi	sp,sp,32
    80001b46:	8082                	ret

0000000080001b48 <freeproc>:
{
    80001b48:	1101                	addi	sp,sp,-32
    80001b4a:	ec06                	sd	ra,24(sp)
    80001b4c:	e822                	sd	s0,16(sp)
    80001b4e:	e426                	sd	s1,8(sp)
    80001b50:	1000                	addi	s0,sp,32
    80001b52:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b54:	6d28                	ld	a0,88(a0)
    80001b56:	c509                	beqz	a0,80001b60 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b58:	fffff097          	auipc	ra,0xfffff
    80001b5c:	e8c080e7          	jalr	-372(ra) # 800009e4 <kfree>
  p->trapframe = 0;
    80001b60:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b64:	68a8                	ld	a0,80(s1)
    80001b66:	c511                	beqz	a0,80001b72 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b68:	64ac                	ld	a1,72(s1)
    80001b6a:	00000097          	auipc	ra,0x0
    80001b6e:	f8c080e7          	jalr	-116(ra) # 80001af6 <proc_freepagetable>
  p->pagetable = 0;
    80001b72:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b76:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b7a:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b7e:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b82:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b86:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001b8a:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001b8e:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001b92:	0004ac23          	sw	zero,24(s1)
}
    80001b96:	60e2                	ld	ra,24(sp)
    80001b98:	6442                	ld	s0,16(sp)
    80001b9a:	64a2                	ld	s1,8(sp)
    80001b9c:	6105                	addi	sp,sp,32
    80001b9e:	8082                	ret

0000000080001ba0 <allocproc>:
{
    80001ba0:	1101                	addi	sp,sp,-32
    80001ba2:	ec06                	sd	ra,24(sp)
    80001ba4:	e822                	sd	s0,16(sp)
    80001ba6:	e426                	sd	s1,8(sp)
    80001ba8:	e04a                	sd	s2,0(sp)
    80001baa:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bac:	00010497          	auipc	s1,0x10
    80001bb0:	b2448493          	addi	s1,s1,-1244 # 800116d0 <proc>
    80001bb4:	00015917          	auipc	s2,0x15
    80001bb8:	51c90913          	addi	s2,s2,1308 # 800170d0 <tickslock>
    acquire(&p->lock);
    80001bbc:	8526                	mv	a0,s1
    80001bbe:	fffff097          	auipc	ra,0xfffff
    80001bc2:	012080e7          	jalr	18(ra) # 80000bd0 <acquire>
    if(p->state == UNUSED) {
    80001bc6:	4c9c                	lw	a5,24(s1)
    80001bc8:	cf81                	beqz	a5,80001be0 <allocproc+0x40>
      release(&p->lock);
    80001bca:	8526                	mv	a0,s1
    80001bcc:	fffff097          	auipc	ra,0xfffff
    80001bd0:	0b8080e7          	jalr	184(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bd4:	16848493          	addi	s1,s1,360
    80001bd8:	ff2492e3          	bne	s1,s2,80001bbc <allocproc+0x1c>
  return 0;
    80001bdc:	4481                	li	s1,0
    80001bde:	a889                	j	80001c30 <allocproc+0x90>
  p->pid = allocpid();
    80001be0:	00000097          	auipc	ra,0x0
    80001be4:	e34080e7          	jalr	-460(ra) # 80001a14 <allocpid>
    80001be8:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001bea:	4785                	li	a5,1
    80001bec:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001bee:	fffff097          	auipc	ra,0xfffff
    80001bf2:	ef2080e7          	jalr	-270(ra) # 80000ae0 <kalloc>
    80001bf6:	892a                	mv	s2,a0
    80001bf8:	eca8                	sd	a0,88(s1)
    80001bfa:	c131                	beqz	a0,80001c3e <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001bfc:	8526                	mv	a0,s1
    80001bfe:	00000097          	auipc	ra,0x0
    80001c02:	e5c080e7          	jalr	-420(ra) # 80001a5a <proc_pagetable>
    80001c06:	892a                	mv	s2,a0
    80001c08:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c0a:	c531                	beqz	a0,80001c56 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c0c:	07000613          	li	a2,112
    80001c10:	4581                	li	a1,0
    80001c12:	06048513          	addi	a0,s1,96
    80001c16:	fffff097          	auipc	ra,0xfffff
    80001c1a:	0b6080e7          	jalr	182(ra) # 80000ccc <memset>
  p->context.ra = (uint64)forkret;
    80001c1e:	00000797          	auipc	a5,0x0
    80001c22:	db078793          	addi	a5,a5,-592 # 800019ce <forkret>
    80001c26:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c28:	60bc                	ld	a5,64(s1)
    80001c2a:	6705                	lui	a4,0x1
    80001c2c:	97ba                	add	a5,a5,a4
    80001c2e:	f4bc                	sd	a5,104(s1)
}
    80001c30:	8526                	mv	a0,s1
    80001c32:	60e2                	ld	ra,24(sp)
    80001c34:	6442                	ld	s0,16(sp)
    80001c36:	64a2                	ld	s1,8(sp)
    80001c38:	6902                	ld	s2,0(sp)
    80001c3a:	6105                	addi	sp,sp,32
    80001c3c:	8082                	ret
    freeproc(p);
    80001c3e:	8526                	mv	a0,s1
    80001c40:	00000097          	auipc	ra,0x0
    80001c44:	f08080e7          	jalr	-248(ra) # 80001b48 <freeproc>
    release(&p->lock);
    80001c48:	8526                	mv	a0,s1
    80001c4a:	fffff097          	auipc	ra,0xfffff
    80001c4e:	03a080e7          	jalr	58(ra) # 80000c84 <release>
    return 0;
    80001c52:	84ca                	mv	s1,s2
    80001c54:	bff1                	j	80001c30 <allocproc+0x90>
    freeproc(p);
    80001c56:	8526                	mv	a0,s1
    80001c58:	00000097          	auipc	ra,0x0
    80001c5c:	ef0080e7          	jalr	-272(ra) # 80001b48 <freeproc>
    release(&p->lock);
    80001c60:	8526                	mv	a0,s1
    80001c62:	fffff097          	auipc	ra,0xfffff
    80001c66:	022080e7          	jalr	34(ra) # 80000c84 <release>
    return 0;
    80001c6a:	84ca                	mv	s1,s2
    80001c6c:	b7d1                	j	80001c30 <allocproc+0x90>

0000000080001c6e <userinit>:
{
    80001c6e:	1101                	addi	sp,sp,-32
    80001c70:	ec06                	sd	ra,24(sp)
    80001c72:	e822                	sd	s0,16(sp)
    80001c74:	e426                	sd	s1,8(sp)
    80001c76:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c78:	00000097          	auipc	ra,0x0
    80001c7c:	f28080e7          	jalr	-216(ra) # 80001ba0 <allocproc>
    80001c80:	84aa                	mv	s1,a0
  initproc = p;
    80001c82:	00007797          	auipc	a5,0x7
    80001c86:	3aa7b323          	sd	a0,934(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001c8a:	03400613          	li	a2,52
    80001c8e:	00007597          	auipc	a1,0x7
    80001c92:	bd258593          	addi	a1,a1,-1070 # 80008860 <initcode>
    80001c96:	6928                	ld	a0,80(a0)
    80001c98:	fffff097          	auipc	ra,0xfffff
    80001c9c:	6b4080e7          	jalr	1716(ra) # 8000134c <uvminit>
  p->sz = PGSIZE;
    80001ca0:	6785                	lui	a5,0x1
    80001ca2:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001ca4:	6cb8                	ld	a4,88(s1)
    80001ca6:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001caa:	6cb8                	ld	a4,88(s1)
    80001cac:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cae:	4641                	li	a2,16
    80001cb0:	00006597          	auipc	a1,0x6
    80001cb4:	55058593          	addi	a1,a1,1360 # 80008200 <digits+0x1c0>
    80001cb8:	15848513          	addi	a0,s1,344
    80001cbc:	fffff097          	auipc	ra,0xfffff
    80001cc0:	15a080e7          	jalr	346(ra) # 80000e16 <safestrcpy>
  p->cwd = namei("/");
    80001cc4:	00006517          	auipc	a0,0x6
    80001cc8:	54c50513          	addi	a0,a0,1356 # 80008210 <digits+0x1d0>
    80001ccc:	00002097          	auipc	ra,0x2
    80001cd0:	370080e7          	jalr	880(ra) # 8000403c <namei>
    80001cd4:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cd8:	478d                	li	a5,3
    80001cda:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cdc:	8526                	mv	a0,s1
    80001cde:	fffff097          	auipc	ra,0xfffff
    80001ce2:	fa6080e7          	jalr	-90(ra) # 80000c84 <release>
}
    80001ce6:	60e2                	ld	ra,24(sp)
    80001ce8:	6442                	ld	s0,16(sp)
    80001cea:	64a2                	ld	s1,8(sp)
    80001cec:	6105                	addi	sp,sp,32
    80001cee:	8082                	ret

0000000080001cf0 <growproc>:
{
    80001cf0:	1101                	addi	sp,sp,-32
    80001cf2:	ec06                	sd	ra,24(sp)
    80001cf4:	e822                	sd	s0,16(sp)
    80001cf6:	e426                	sd	s1,8(sp)
    80001cf8:	e04a                	sd	s2,0(sp)
    80001cfa:	1000                	addi	s0,sp,32
    80001cfc:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001cfe:	00000097          	auipc	ra,0x0
    80001d02:	c98080e7          	jalr	-872(ra) # 80001996 <myproc>
    80001d06:	892a                	mv	s2,a0
  sz = p->sz;
    80001d08:	652c                	ld	a1,72(a0)
    80001d0a:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d0e:	00904f63          	bgtz	s1,80001d2c <growproc+0x3c>
  } else if(n < 0){
    80001d12:	0204cc63          	bltz	s1,80001d4a <growproc+0x5a>
  p->sz = sz;
    80001d16:	1602                	slli	a2,a2,0x20
    80001d18:	9201                	srli	a2,a2,0x20
    80001d1a:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d1e:	4501                	li	a0,0
}
    80001d20:	60e2                	ld	ra,24(sp)
    80001d22:	6442                	ld	s0,16(sp)
    80001d24:	64a2                	ld	s1,8(sp)
    80001d26:	6902                	ld	s2,0(sp)
    80001d28:	6105                	addi	sp,sp,32
    80001d2a:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d2c:	9e25                	addw	a2,a2,s1
    80001d2e:	1602                	slli	a2,a2,0x20
    80001d30:	9201                	srli	a2,a2,0x20
    80001d32:	1582                	slli	a1,a1,0x20
    80001d34:	9181                	srli	a1,a1,0x20
    80001d36:	6928                	ld	a0,80(a0)
    80001d38:	fffff097          	auipc	ra,0xfffff
    80001d3c:	6ce080e7          	jalr	1742(ra) # 80001406 <uvmalloc>
    80001d40:	0005061b          	sext.w	a2,a0
    80001d44:	fa69                	bnez	a2,80001d16 <growproc+0x26>
      return -1;
    80001d46:	557d                	li	a0,-1
    80001d48:	bfe1                	j	80001d20 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d4a:	9e25                	addw	a2,a2,s1
    80001d4c:	1602                	slli	a2,a2,0x20
    80001d4e:	9201                	srli	a2,a2,0x20
    80001d50:	1582                	slli	a1,a1,0x20
    80001d52:	9181                	srli	a1,a1,0x20
    80001d54:	6928                	ld	a0,80(a0)
    80001d56:	fffff097          	auipc	ra,0xfffff
    80001d5a:	668080e7          	jalr	1640(ra) # 800013be <uvmdealloc>
    80001d5e:	0005061b          	sext.w	a2,a0
    80001d62:	bf55                	j	80001d16 <growproc+0x26>

0000000080001d64 <fork>:
{
    80001d64:	7139                	addi	sp,sp,-64
    80001d66:	fc06                	sd	ra,56(sp)
    80001d68:	f822                	sd	s0,48(sp)
    80001d6a:	f426                	sd	s1,40(sp)
    80001d6c:	f04a                	sd	s2,32(sp)
    80001d6e:	ec4e                	sd	s3,24(sp)
    80001d70:	e852                	sd	s4,16(sp)
    80001d72:	e456                	sd	s5,8(sp)
    80001d74:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d76:	00000097          	auipc	ra,0x0
    80001d7a:	c20080e7          	jalr	-992(ra) # 80001996 <myproc>
    80001d7e:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001d80:	00000097          	auipc	ra,0x0
    80001d84:	e20080e7          	jalr	-480(ra) # 80001ba0 <allocproc>
    80001d88:	10050c63          	beqz	a0,80001ea0 <fork+0x13c>
    80001d8c:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d8e:	048ab603          	ld	a2,72(s5)
    80001d92:	692c                	ld	a1,80(a0)
    80001d94:	050ab503          	ld	a0,80(s5)
    80001d98:	fffff097          	auipc	ra,0xfffff
    80001d9c:	7ba080e7          	jalr	1978(ra) # 80001552 <uvmcopy>
    80001da0:	04054863          	bltz	a0,80001df0 <fork+0x8c>
  np->sz = p->sz;
    80001da4:	048ab783          	ld	a5,72(s5)
    80001da8:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001dac:	058ab683          	ld	a3,88(s5)
    80001db0:	87b6                	mv	a5,a3
    80001db2:	058a3703          	ld	a4,88(s4)
    80001db6:	12068693          	addi	a3,a3,288
    80001dba:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dbe:	6788                	ld	a0,8(a5)
    80001dc0:	6b8c                	ld	a1,16(a5)
    80001dc2:	6f90                	ld	a2,24(a5)
    80001dc4:	01073023          	sd	a6,0(a4)
    80001dc8:	e708                	sd	a0,8(a4)
    80001dca:	eb0c                	sd	a1,16(a4)
    80001dcc:	ef10                	sd	a2,24(a4)
    80001dce:	02078793          	addi	a5,a5,32
    80001dd2:	02070713          	addi	a4,a4,32
    80001dd6:	fed792e3          	bne	a5,a3,80001dba <fork+0x56>
  np->trapframe->a0 = 0;
    80001dda:	058a3783          	ld	a5,88(s4)
    80001dde:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001de2:	0d0a8493          	addi	s1,s5,208
    80001de6:	0d0a0913          	addi	s2,s4,208
    80001dea:	150a8993          	addi	s3,s5,336
    80001dee:	a00d                	j	80001e10 <fork+0xac>
    freeproc(np);
    80001df0:	8552                	mv	a0,s4
    80001df2:	00000097          	auipc	ra,0x0
    80001df6:	d56080e7          	jalr	-682(ra) # 80001b48 <freeproc>
    release(&np->lock);
    80001dfa:	8552                	mv	a0,s4
    80001dfc:	fffff097          	auipc	ra,0xfffff
    80001e00:	e88080e7          	jalr	-376(ra) # 80000c84 <release>
    return -1;
    80001e04:	597d                	li	s2,-1
    80001e06:	a059                	j	80001e8c <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001e08:	04a1                	addi	s1,s1,8
    80001e0a:	0921                	addi	s2,s2,8
    80001e0c:	01348b63          	beq	s1,s3,80001e22 <fork+0xbe>
    if(p->ofile[i])
    80001e10:	6088                	ld	a0,0(s1)
    80001e12:	d97d                	beqz	a0,80001e08 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e14:	00003097          	auipc	ra,0x3
    80001e18:	8be080e7          	jalr	-1858(ra) # 800046d2 <filedup>
    80001e1c:	00a93023          	sd	a0,0(s2)
    80001e20:	b7e5                	j	80001e08 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e22:	150ab503          	ld	a0,336(s5)
    80001e26:	00002097          	auipc	ra,0x2
    80001e2a:	a22080e7          	jalr	-1502(ra) # 80003848 <idup>
    80001e2e:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e32:	4641                	li	a2,16
    80001e34:	158a8593          	addi	a1,s5,344
    80001e38:	158a0513          	addi	a0,s4,344
    80001e3c:	fffff097          	auipc	ra,0xfffff
    80001e40:	fda080e7          	jalr	-38(ra) # 80000e16 <safestrcpy>
  pid = np->pid;
    80001e44:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e48:	8552                	mv	a0,s4
    80001e4a:	fffff097          	auipc	ra,0xfffff
    80001e4e:	e3a080e7          	jalr	-454(ra) # 80000c84 <release>
  acquire(&wait_lock);
    80001e52:	0000f497          	auipc	s1,0xf
    80001e56:	46648493          	addi	s1,s1,1126 # 800112b8 <wait_lock>
    80001e5a:	8526                	mv	a0,s1
    80001e5c:	fffff097          	auipc	ra,0xfffff
    80001e60:	d74080e7          	jalr	-652(ra) # 80000bd0 <acquire>
  np->parent = p;
    80001e64:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e68:	8526                	mv	a0,s1
    80001e6a:	fffff097          	auipc	ra,0xfffff
    80001e6e:	e1a080e7          	jalr	-486(ra) # 80000c84 <release>
  acquire(&np->lock);
    80001e72:	8552                	mv	a0,s4
    80001e74:	fffff097          	auipc	ra,0xfffff
    80001e78:	d5c080e7          	jalr	-676(ra) # 80000bd0 <acquire>
  np->state = RUNNABLE;
    80001e7c:	478d                	li	a5,3
    80001e7e:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e82:	8552                	mv	a0,s4
    80001e84:	fffff097          	auipc	ra,0xfffff
    80001e88:	e00080e7          	jalr	-512(ra) # 80000c84 <release>
}
    80001e8c:	854a                	mv	a0,s2
    80001e8e:	70e2                	ld	ra,56(sp)
    80001e90:	7442                	ld	s0,48(sp)
    80001e92:	74a2                	ld	s1,40(sp)
    80001e94:	7902                	ld	s2,32(sp)
    80001e96:	69e2                	ld	s3,24(sp)
    80001e98:	6a42                	ld	s4,16(sp)
    80001e9a:	6aa2                	ld	s5,8(sp)
    80001e9c:	6121                	addi	sp,sp,64
    80001e9e:	8082                	ret
    return -1;
    80001ea0:	597d                	li	s2,-1
    80001ea2:	b7ed                	j	80001e8c <fork+0x128>

0000000080001ea4 <scheduler>:
{
    80001ea4:	7139                	addi	sp,sp,-64
    80001ea6:	fc06                	sd	ra,56(sp)
    80001ea8:	f822                	sd	s0,48(sp)
    80001eaa:	f426                	sd	s1,40(sp)
    80001eac:	f04a                	sd	s2,32(sp)
    80001eae:	ec4e                	sd	s3,24(sp)
    80001eb0:	e852                	sd	s4,16(sp)
    80001eb2:	e456                	sd	s5,8(sp)
    80001eb4:	e05a                	sd	s6,0(sp)
    80001eb6:	0080                	addi	s0,sp,64
    80001eb8:	8792                	mv	a5,tp
  int id = r_tp();
    80001eba:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ebc:	00779a93          	slli	s5,a5,0x7
    80001ec0:	0000f717          	auipc	a4,0xf
    80001ec4:	3e070713          	addi	a4,a4,992 # 800112a0 <pid_lock>
    80001ec8:	9756                	add	a4,a4,s5
    80001eca:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ece:	0000f717          	auipc	a4,0xf
    80001ed2:	40a70713          	addi	a4,a4,1034 # 800112d8 <cpus+0x8>
    80001ed6:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001ed8:	498d                	li	s3,3
        p->state = RUNNING;
    80001eda:	4b11                	li	s6,4
        c->proc = p;
    80001edc:	079e                	slli	a5,a5,0x7
    80001ede:	0000fa17          	auipc	s4,0xf
    80001ee2:	3c2a0a13          	addi	s4,s4,962 # 800112a0 <pid_lock>
    80001ee6:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ee8:	00015917          	auipc	s2,0x15
    80001eec:	1e890913          	addi	s2,s2,488 # 800170d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ef0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ef4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ef8:	10079073          	csrw	sstatus,a5
    80001efc:	0000f497          	auipc	s1,0xf
    80001f00:	7d448493          	addi	s1,s1,2004 # 800116d0 <proc>
    80001f04:	a811                	j	80001f18 <scheduler+0x74>
      release(&p->lock);
    80001f06:	8526                	mv	a0,s1
    80001f08:	fffff097          	auipc	ra,0xfffff
    80001f0c:	d7c080e7          	jalr	-644(ra) # 80000c84 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f10:	16848493          	addi	s1,s1,360
    80001f14:	fd248ee3          	beq	s1,s2,80001ef0 <scheduler+0x4c>
      acquire(&p->lock);
    80001f18:	8526                	mv	a0,s1
    80001f1a:	fffff097          	auipc	ra,0xfffff
    80001f1e:	cb6080e7          	jalr	-842(ra) # 80000bd0 <acquire>
      if(p->state == RUNNABLE) {
    80001f22:	4c9c                	lw	a5,24(s1)
    80001f24:	ff3791e3          	bne	a5,s3,80001f06 <scheduler+0x62>
        p->state = RUNNING;
    80001f28:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f2c:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f30:	06048593          	addi	a1,s1,96
    80001f34:	8556                	mv	a0,s5
    80001f36:	00000097          	auipc	ra,0x0
    80001f3a:	61e080e7          	jalr	1566(ra) # 80002554 <swtch>
        c->proc = 0;
    80001f3e:	020a3823          	sd	zero,48(s4)
    80001f42:	b7d1                	j	80001f06 <scheduler+0x62>

0000000080001f44 <sched>:
{
    80001f44:	7179                	addi	sp,sp,-48
    80001f46:	f406                	sd	ra,40(sp)
    80001f48:	f022                	sd	s0,32(sp)
    80001f4a:	ec26                	sd	s1,24(sp)
    80001f4c:	e84a                	sd	s2,16(sp)
    80001f4e:	e44e                	sd	s3,8(sp)
    80001f50:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f52:	00000097          	auipc	ra,0x0
    80001f56:	a44080e7          	jalr	-1468(ra) # 80001996 <myproc>
    80001f5a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f5c:	fffff097          	auipc	ra,0xfffff
    80001f60:	bfa080e7          	jalr	-1030(ra) # 80000b56 <holding>
    80001f64:	c93d                	beqz	a0,80001fda <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f66:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f68:	2781                	sext.w	a5,a5
    80001f6a:	079e                	slli	a5,a5,0x7
    80001f6c:	0000f717          	auipc	a4,0xf
    80001f70:	33470713          	addi	a4,a4,820 # 800112a0 <pid_lock>
    80001f74:	97ba                	add	a5,a5,a4
    80001f76:	0a87a703          	lw	a4,168(a5)
    80001f7a:	4785                	li	a5,1
    80001f7c:	06f71763          	bne	a4,a5,80001fea <sched+0xa6>
  if(p->state == RUNNING)
    80001f80:	4c98                	lw	a4,24(s1)
    80001f82:	4791                	li	a5,4
    80001f84:	06f70b63          	beq	a4,a5,80001ffa <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f88:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f8c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f8e:	efb5                	bnez	a5,8000200a <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f90:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f92:	0000f917          	auipc	s2,0xf
    80001f96:	30e90913          	addi	s2,s2,782 # 800112a0 <pid_lock>
    80001f9a:	2781                	sext.w	a5,a5
    80001f9c:	079e                	slli	a5,a5,0x7
    80001f9e:	97ca                	add	a5,a5,s2
    80001fa0:	0ac7a983          	lw	s3,172(a5)
    80001fa4:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fa6:	2781                	sext.w	a5,a5
    80001fa8:	079e                	slli	a5,a5,0x7
    80001faa:	0000f597          	auipc	a1,0xf
    80001fae:	32e58593          	addi	a1,a1,814 # 800112d8 <cpus+0x8>
    80001fb2:	95be                	add	a1,a1,a5
    80001fb4:	06048513          	addi	a0,s1,96
    80001fb8:	00000097          	auipc	ra,0x0
    80001fbc:	59c080e7          	jalr	1436(ra) # 80002554 <swtch>
    80001fc0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fc2:	2781                	sext.w	a5,a5
    80001fc4:	079e                	slli	a5,a5,0x7
    80001fc6:	97ca                	add	a5,a5,s2
    80001fc8:	0b37a623          	sw	s3,172(a5)
}
    80001fcc:	70a2                	ld	ra,40(sp)
    80001fce:	7402                	ld	s0,32(sp)
    80001fd0:	64e2                	ld	s1,24(sp)
    80001fd2:	6942                	ld	s2,16(sp)
    80001fd4:	69a2                	ld	s3,8(sp)
    80001fd6:	6145                	addi	sp,sp,48
    80001fd8:	8082                	ret
    panic("sched p->lock");
    80001fda:	00006517          	auipc	a0,0x6
    80001fde:	23e50513          	addi	a0,a0,574 # 80008218 <digits+0x1d8>
    80001fe2:	ffffe097          	auipc	ra,0xffffe
    80001fe6:	556080e7          	jalr	1366(ra) # 80000538 <panic>
    panic("sched locks");
    80001fea:	00006517          	auipc	a0,0x6
    80001fee:	23e50513          	addi	a0,a0,574 # 80008228 <digits+0x1e8>
    80001ff2:	ffffe097          	auipc	ra,0xffffe
    80001ff6:	546080e7          	jalr	1350(ra) # 80000538 <panic>
    panic("sched running");
    80001ffa:	00006517          	auipc	a0,0x6
    80001ffe:	23e50513          	addi	a0,a0,574 # 80008238 <digits+0x1f8>
    80002002:	ffffe097          	auipc	ra,0xffffe
    80002006:	536080e7          	jalr	1334(ra) # 80000538 <panic>
    panic("sched interruptible");
    8000200a:	00006517          	auipc	a0,0x6
    8000200e:	23e50513          	addi	a0,a0,574 # 80008248 <digits+0x208>
    80002012:	ffffe097          	auipc	ra,0xffffe
    80002016:	526080e7          	jalr	1318(ra) # 80000538 <panic>

000000008000201a <yield>:
{
    8000201a:	1101                	addi	sp,sp,-32
    8000201c:	ec06                	sd	ra,24(sp)
    8000201e:	e822                	sd	s0,16(sp)
    80002020:	e426                	sd	s1,8(sp)
    80002022:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002024:	00000097          	auipc	ra,0x0
    80002028:	972080e7          	jalr	-1678(ra) # 80001996 <myproc>
    8000202c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000202e:	fffff097          	auipc	ra,0xfffff
    80002032:	ba2080e7          	jalr	-1118(ra) # 80000bd0 <acquire>
  p->state = RUNNABLE;
    80002036:	478d                	li	a5,3
    80002038:	cc9c                	sw	a5,24(s1)
  sched();
    8000203a:	00000097          	auipc	ra,0x0
    8000203e:	f0a080e7          	jalr	-246(ra) # 80001f44 <sched>
  release(&p->lock);
    80002042:	8526                	mv	a0,s1
    80002044:	fffff097          	auipc	ra,0xfffff
    80002048:	c40080e7          	jalr	-960(ra) # 80000c84 <release>
}
    8000204c:	60e2                	ld	ra,24(sp)
    8000204e:	6442                	ld	s0,16(sp)
    80002050:	64a2                	ld	s1,8(sp)
    80002052:	6105                	addi	sp,sp,32
    80002054:	8082                	ret

0000000080002056 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002056:	7179                	addi	sp,sp,-48
    80002058:	f406                	sd	ra,40(sp)
    8000205a:	f022                	sd	s0,32(sp)
    8000205c:	ec26                	sd	s1,24(sp)
    8000205e:	e84a                	sd	s2,16(sp)
    80002060:	e44e                	sd	s3,8(sp)
    80002062:	1800                	addi	s0,sp,48
    80002064:	89aa                	mv	s3,a0
    80002066:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002068:	00000097          	auipc	ra,0x0
    8000206c:	92e080e7          	jalr	-1746(ra) # 80001996 <myproc>
    80002070:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002072:	fffff097          	auipc	ra,0xfffff
    80002076:	b5e080e7          	jalr	-1186(ra) # 80000bd0 <acquire>
  release(lk);
    8000207a:	854a                	mv	a0,s2
    8000207c:	fffff097          	auipc	ra,0xfffff
    80002080:	c08080e7          	jalr	-1016(ra) # 80000c84 <release>

  // Go to sleep.
  p->chan = chan;
    80002084:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002088:	4789                	li	a5,2
    8000208a:	cc9c                	sw	a5,24(s1)

  sched();
    8000208c:	00000097          	auipc	ra,0x0
    80002090:	eb8080e7          	jalr	-328(ra) # 80001f44 <sched>

  // Tidy up.
  p->chan = 0;
    80002094:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002098:	8526                	mv	a0,s1
    8000209a:	fffff097          	auipc	ra,0xfffff
    8000209e:	bea080e7          	jalr	-1046(ra) # 80000c84 <release>
  acquire(lk);
    800020a2:	854a                	mv	a0,s2
    800020a4:	fffff097          	auipc	ra,0xfffff
    800020a8:	b2c080e7          	jalr	-1236(ra) # 80000bd0 <acquire>
}
    800020ac:	70a2                	ld	ra,40(sp)
    800020ae:	7402                	ld	s0,32(sp)
    800020b0:	64e2                	ld	s1,24(sp)
    800020b2:	6942                	ld	s2,16(sp)
    800020b4:	69a2                	ld	s3,8(sp)
    800020b6:	6145                	addi	sp,sp,48
    800020b8:	8082                	ret

00000000800020ba <wait>:
{
    800020ba:	715d                	addi	sp,sp,-80
    800020bc:	e486                	sd	ra,72(sp)
    800020be:	e0a2                	sd	s0,64(sp)
    800020c0:	fc26                	sd	s1,56(sp)
    800020c2:	f84a                	sd	s2,48(sp)
    800020c4:	f44e                	sd	s3,40(sp)
    800020c6:	f052                	sd	s4,32(sp)
    800020c8:	ec56                	sd	s5,24(sp)
    800020ca:	e85a                	sd	s6,16(sp)
    800020cc:	e45e                	sd	s7,8(sp)
    800020ce:	e062                	sd	s8,0(sp)
    800020d0:	0880                	addi	s0,sp,80
    800020d2:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800020d4:	00000097          	auipc	ra,0x0
    800020d8:	8c2080e7          	jalr	-1854(ra) # 80001996 <myproc>
    800020dc:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800020de:	0000f517          	auipc	a0,0xf
    800020e2:	1da50513          	addi	a0,a0,474 # 800112b8 <wait_lock>
    800020e6:	fffff097          	auipc	ra,0xfffff
    800020ea:	aea080e7          	jalr	-1302(ra) # 80000bd0 <acquire>
    havekids = 0;
    800020ee:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800020f0:	4a15                	li	s4,5
        havekids = 1;
    800020f2:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    800020f4:	00015997          	auipc	s3,0x15
    800020f8:	fdc98993          	addi	s3,s3,-36 # 800170d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800020fc:	0000fc17          	auipc	s8,0xf
    80002100:	1bcc0c13          	addi	s8,s8,444 # 800112b8 <wait_lock>
    havekids = 0;
    80002104:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002106:	0000f497          	auipc	s1,0xf
    8000210a:	5ca48493          	addi	s1,s1,1482 # 800116d0 <proc>
    8000210e:	a0bd                	j	8000217c <wait+0xc2>
          pid = np->pid;
    80002110:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002114:	000b0e63          	beqz	s6,80002130 <wait+0x76>
    80002118:	4691                	li	a3,4
    8000211a:	02c48613          	addi	a2,s1,44
    8000211e:	85da                	mv	a1,s6
    80002120:	05093503          	ld	a0,80(s2)
    80002124:	fffff097          	auipc	ra,0xfffff
    80002128:	532080e7          	jalr	1330(ra) # 80001656 <copyout>
    8000212c:	02054563          	bltz	a0,80002156 <wait+0x9c>
          freeproc(np);
    80002130:	8526                	mv	a0,s1
    80002132:	00000097          	auipc	ra,0x0
    80002136:	a16080e7          	jalr	-1514(ra) # 80001b48 <freeproc>
          release(&np->lock);
    8000213a:	8526                	mv	a0,s1
    8000213c:	fffff097          	auipc	ra,0xfffff
    80002140:	b48080e7          	jalr	-1208(ra) # 80000c84 <release>
          release(&wait_lock);
    80002144:	0000f517          	auipc	a0,0xf
    80002148:	17450513          	addi	a0,a0,372 # 800112b8 <wait_lock>
    8000214c:	fffff097          	auipc	ra,0xfffff
    80002150:	b38080e7          	jalr	-1224(ra) # 80000c84 <release>
          return pid;
    80002154:	a09d                	j	800021ba <wait+0x100>
            release(&np->lock);
    80002156:	8526                	mv	a0,s1
    80002158:	fffff097          	auipc	ra,0xfffff
    8000215c:	b2c080e7          	jalr	-1236(ra) # 80000c84 <release>
            release(&wait_lock);
    80002160:	0000f517          	auipc	a0,0xf
    80002164:	15850513          	addi	a0,a0,344 # 800112b8 <wait_lock>
    80002168:	fffff097          	auipc	ra,0xfffff
    8000216c:	b1c080e7          	jalr	-1252(ra) # 80000c84 <release>
            return -1;
    80002170:	59fd                	li	s3,-1
    80002172:	a0a1                	j	800021ba <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002174:	16848493          	addi	s1,s1,360
    80002178:	03348463          	beq	s1,s3,800021a0 <wait+0xe6>
      if(np->parent == p){
    8000217c:	7c9c                	ld	a5,56(s1)
    8000217e:	ff279be3          	bne	a5,s2,80002174 <wait+0xba>
        acquire(&np->lock);
    80002182:	8526                	mv	a0,s1
    80002184:	fffff097          	auipc	ra,0xfffff
    80002188:	a4c080e7          	jalr	-1460(ra) # 80000bd0 <acquire>
        if(np->state == ZOMBIE){
    8000218c:	4c9c                	lw	a5,24(s1)
    8000218e:	f94781e3          	beq	a5,s4,80002110 <wait+0x56>
        release(&np->lock);
    80002192:	8526                	mv	a0,s1
    80002194:	fffff097          	auipc	ra,0xfffff
    80002198:	af0080e7          	jalr	-1296(ra) # 80000c84 <release>
        havekids = 1;
    8000219c:	8756                	mv	a4,s5
    8000219e:	bfd9                	j	80002174 <wait+0xba>
    if(!havekids || p->killed){
    800021a0:	c701                	beqz	a4,800021a8 <wait+0xee>
    800021a2:	02892783          	lw	a5,40(s2)
    800021a6:	c79d                	beqz	a5,800021d4 <wait+0x11a>
      release(&wait_lock);
    800021a8:	0000f517          	auipc	a0,0xf
    800021ac:	11050513          	addi	a0,a0,272 # 800112b8 <wait_lock>
    800021b0:	fffff097          	auipc	ra,0xfffff
    800021b4:	ad4080e7          	jalr	-1324(ra) # 80000c84 <release>
      return -1;
    800021b8:	59fd                	li	s3,-1
}
    800021ba:	854e                	mv	a0,s3
    800021bc:	60a6                	ld	ra,72(sp)
    800021be:	6406                	ld	s0,64(sp)
    800021c0:	74e2                	ld	s1,56(sp)
    800021c2:	7942                	ld	s2,48(sp)
    800021c4:	79a2                	ld	s3,40(sp)
    800021c6:	7a02                	ld	s4,32(sp)
    800021c8:	6ae2                	ld	s5,24(sp)
    800021ca:	6b42                	ld	s6,16(sp)
    800021cc:	6ba2                	ld	s7,8(sp)
    800021ce:	6c02                	ld	s8,0(sp)
    800021d0:	6161                	addi	sp,sp,80
    800021d2:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800021d4:	85e2                	mv	a1,s8
    800021d6:	854a                	mv	a0,s2
    800021d8:	00000097          	auipc	ra,0x0
    800021dc:	e7e080e7          	jalr	-386(ra) # 80002056 <sleep>
    havekids = 0;
    800021e0:	b715                	j	80002104 <wait+0x4a>

00000000800021e2 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800021e2:	7139                	addi	sp,sp,-64
    800021e4:	fc06                	sd	ra,56(sp)
    800021e6:	f822                	sd	s0,48(sp)
    800021e8:	f426                	sd	s1,40(sp)
    800021ea:	f04a                	sd	s2,32(sp)
    800021ec:	ec4e                	sd	s3,24(sp)
    800021ee:	e852                	sd	s4,16(sp)
    800021f0:	e456                	sd	s5,8(sp)
    800021f2:	0080                	addi	s0,sp,64
    800021f4:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800021f6:	0000f497          	auipc	s1,0xf
    800021fa:	4da48493          	addi	s1,s1,1242 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800021fe:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002200:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002202:	00015917          	auipc	s2,0x15
    80002206:	ece90913          	addi	s2,s2,-306 # 800170d0 <tickslock>
    8000220a:	a811                	j	8000221e <wakeup+0x3c>
      }
      release(&p->lock);
    8000220c:	8526                	mv	a0,s1
    8000220e:	fffff097          	auipc	ra,0xfffff
    80002212:	a76080e7          	jalr	-1418(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002216:	16848493          	addi	s1,s1,360
    8000221a:	03248663          	beq	s1,s2,80002246 <wakeup+0x64>
    if(p != myproc()){
    8000221e:	fffff097          	auipc	ra,0xfffff
    80002222:	778080e7          	jalr	1912(ra) # 80001996 <myproc>
    80002226:	fea488e3          	beq	s1,a0,80002216 <wakeup+0x34>
      acquire(&p->lock);
    8000222a:	8526                	mv	a0,s1
    8000222c:	fffff097          	auipc	ra,0xfffff
    80002230:	9a4080e7          	jalr	-1628(ra) # 80000bd0 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002234:	4c9c                	lw	a5,24(s1)
    80002236:	fd379be3          	bne	a5,s3,8000220c <wakeup+0x2a>
    8000223a:	709c                	ld	a5,32(s1)
    8000223c:	fd4798e3          	bne	a5,s4,8000220c <wakeup+0x2a>
        p->state = RUNNABLE;
    80002240:	0154ac23          	sw	s5,24(s1)
    80002244:	b7e1                	j	8000220c <wakeup+0x2a>
    }
  }
}
    80002246:	70e2                	ld	ra,56(sp)
    80002248:	7442                	ld	s0,48(sp)
    8000224a:	74a2                	ld	s1,40(sp)
    8000224c:	7902                	ld	s2,32(sp)
    8000224e:	69e2                	ld	s3,24(sp)
    80002250:	6a42                	ld	s4,16(sp)
    80002252:	6aa2                	ld	s5,8(sp)
    80002254:	6121                	addi	sp,sp,64
    80002256:	8082                	ret

0000000080002258 <reparent>:
{
    80002258:	7179                	addi	sp,sp,-48
    8000225a:	f406                	sd	ra,40(sp)
    8000225c:	f022                	sd	s0,32(sp)
    8000225e:	ec26                	sd	s1,24(sp)
    80002260:	e84a                	sd	s2,16(sp)
    80002262:	e44e                	sd	s3,8(sp)
    80002264:	e052                	sd	s4,0(sp)
    80002266:	1800                	addi	s0,sp,48
    80002268:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000226a:	0000f497          	auipc	s1,0xf
    8000226e:	46648493          	addi	s1,s1,1126 # 800116d0 <proc>
      pp->parent = initproc;
    80002272:	00007a17          	auipc	s4,0x7
    80002276:	db6a0a13          	addi	s4,s4,-586 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000227a:	00015997          	auipc	s3,0x15
    8000227e:	e5698993          	addi	s3,s3,-426 # 800170d0 <tickslock>
    80002282:	a029                	j	8000228c <reparent+0x34>
    80002284:	16848493          	addi	s1,s1,360
    80002288:	01348d63          	beq	s1,s3,800022a2 <reparent+0x4a>
    if(pp->parent == p){
    8000228c:	7c9c                	ld	a5,56(s1)
    8000228e:	ff279be3          	bne	a5,s2,80002284 <reparent+0x2c>
      pp->parent = initproc;
    80002292:	000a3503          	ld	a0,0(s4)
    80002296:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002298:	00000097          	auipc	ra,0x0
    8000229c:	f4a080e7          	jalr	-182(ra) # 800021e2 <wakeup>
    800022a0:	b7d5                	j	80002284 <reparent+0x2c>
}
    800022a2:	70a2                	ld	ra,40(sp)
    800022a4:	7402                	ld	s0,32(sp)
    800022a6:	64e2                	ld	s1,24(sp)
    800022a8:	6942                	ld	s2,16(sp)
    800022aa:	69a2                	ld	s3,8(sp)
    800022ac:	6a02                	ld	s4,0(sp)
    800022ae:	6145                	addi	sp,sp,48
    800022b0:	8082                	ret

00000000800022b2 <exit>:
{
    800022b2:	7179                	addi	sp,sp,-48
    800022b4:	f406                	sd	ra,40(sp)
    800022b6:	f022                	sd	s0,32(sp)
    800022b8:	ec26                	sd	s1,24(sp)
    800022ba:	e84a                	sd	s2,16(sp)
    800022bc:	e44e                	sd	s3,8(sp)
    800022be:	e052                	sd	s4,0(sp)
    800022c0:	1800                	addi	s0,sp,48
    800022c2:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022c4:	fffff097          	auipc	ra,0xfffff
    800022c8:	6d2080e7          	jalr	1746(ra) # 80001996 <myproc>
    800022cc:	89aa                	mv	s3,a0
  if(p == initproc)
    800022ce:	00007797          	auipc	a5,0x7
    800022d2:	d5a7b783          	ld	a5,-678(a5) # 80009028 <initproc>
    800022d6:	0d050493          	addi	s1,a0,208
    800022da:	15050913          	addi	s2,a0,336
    800022de:	02a79363          	bne	a5,a0,80002304 <exit+0x52>
    panic("init exiting");
    800022e2:	00006517          	auipc	a0,0x6
    800022e6:	f7e50513          	addi	a0,a0,-130 # 80008260 <digits+0x220>
    800022ea:	ffffe097          	auipc	ra,0xffffe
    800022ee:	24e080e7          	jalr	590(ra) # 80000538 <panic>
      fileclose(f);
    800022f2:	00002097          	auipc	ra,0x2
    800022f6:	432080e7          	jalr	1074(ra) # 80004724 <fileclose>
      p->ofile[fd] = 0;
    800022fa:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800022fe:	04a1                	addi	s1,s1,8
    80002300:	01248563          	beq	s1,s2,8000230a <exit+0x58>
    if(p->ofile[fd]){
    80002304:	6088                	ld	a0,0(s1)
    80002306:	f575                	bnez	a0,800022f2 <exit+0x40>
    80002308:	bfdd                	j	800022fe <exit+0x4c>
  begin_op();
    8000230a:	00002097          	auipc	ra,0x2
    8000230e:	f4e080e7          	jalr	-178(ra) # 80004258 <begin_op>
  iput(p->cwd);
    80002312:	1509b503          	ld	a0,336(s3)
    80002316:	00001097          	auipc	ra,0x1
    8000231a:	72a080e7          	jalr	1834(ra) # 80003a40 <iput>
  end_op();
    8000231e:	00002097          	auipc	ra,0x2
    80002322:	fba080e7          	jalr	-70(ra) # 800042d8 <end_op>
  p->cwd = 0;
    80002326:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000232a:	0000f497          	auipc	s1,0xf
    8000232e:	f8e48493          	addi	s1,s1,-114 # 800112b8 <wait_lock>
    80002332:	8526                	mv	a0,s1
    80002334:	fffff097          	auipc	ra,0xfffff
    80002338:	89c080e7          	jalr	-1892(ra) # 80000bd0 <acquire>
  reparent(p);
    8000233c:	854e                	mv	a0,s3
    8000233e:	00000097          	auipc	ra,0x0
    80002342:	f1a080e7          	jalr	-230(ra) # 80002258 <reparent>
  wakeup(p->parent);
    80002346:	0389b503          	ld	a0,56(s3)
    8000234a:	00000097          	auipc	ra,0x0
    8000234e:	e98080e7          	jalr	-360(ra) # 800021e2 <wakeup>
  acquire(&p->lock);
    80002352:	854e                	mv	a0,s3
    80002354:	fffff097          	auipc	ra,0xfffff
    80002358:	87c080e7          	jalr	-1924(ra) # 80000bd0 <acquire>
  p->xstate = status;
    8000235c:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002360:	4795                	li	a5,5
    80002362:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002366:	8526                	mv	a0,s1
    80002368:	fffff097          	auipc	ra,0xfffff
    8000236c:	91c080e7          	jalr	-1764(ra) # 80000c84 <release>
  sched();
    80002370:	00000097          	auipc	ra,0x0
    80002374:	bd4080e7          	jalr	-1068(ra) # 80001f44 <sched>
  panic("zombie exit");
    80002378:	00006517          	auipc	a0,0x6
    8000237c:	ef850513          	addi	a0,a0,-264 # 80008270 <digits+0x230>
    80002380:	ffffe097          	auipc	ra,0xffffe
    80002384:	1b8080e7          	jalr	440(ra) # 80000538 <panic>

0000000080002388 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002388:	7179                	addi	sp,sp,-48
    8000238a:	f406                	sd	ra,40(sp)
    8000238c:	f022                	sd	s0,32(sp)
    8000238e:	ec26                	sd	s1,24(sp)
    80002390:	e84a                	sd	s2,16(sp)
    80002392:	e44e                	sd	s3,8(sp)
    80002394:	1800                	addi	s0,sp,48
    80002396:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002398:	0000f497          	auipc	s1,0xf
    8000239c:	33848493          	addi	s1,s1,824 # 800116d0 <proc>
    800023a0:	00015997          	auipc	s3,0x15
    800023a4:	d3098993          	addi	s3,s3,-720 # 800170d0 <tickslock>
    acquire(&p->lock);
    800023a8:	8526                	mv	a0,s1
    800023aa:	fffff097          	auipc	ra,0xfffff
    800023ae:	826080e7          	jalr	-2010(ra) # 80000bd0 <acquire>
    if(p->pid == pid){
    800023b2:	589c                	lw	a5,48(s1)
    800023b4:	01278d63          	beq	a5,s2,800023ce <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800023b8:	8526                	mv	a0,s1
    800023ba:	fffff097          	auipc	ra,0xfffff
    800023be:	8ca080e7          	jalr	-1846(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800023c2:	16848493          	addi	s1,s1,360
    800023c6:	ff3491e3          	bne	s1,s3,800023a8 <kill+0x20>
  }
  return -1;
    800023ca:	557d                	li	a0,-1
    800023cc:	a829                	j	800023e6 <kill+0x5e>
      p->killed = 1;
    800023ce:	4785                	li	a5,1
    800023d0:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800023d2:	4c98                	lw	a4,24(s1)
    800023d4:	4789                	li	a5,2
    800023d6:	00f70f63          	beq	a4,a5,800023f4 <kill+0x6c>
      release(&p->lock);
    800023da:	8526                	mv	a0,s1
    800023dc:	fffff097          	auipc	ra,0xfffff
    800023e0:	8a8080e7          	jalr	-1880(ra) # 80000c84 <release>
      return 0;
    800023e4:	4501                	li	a0,0
}
    800023e6:	70a2                	ld	ra,40(sp)
    800023e8:	7402                	ld	s0,32(sp)
    800023ea:	64e2                	ld	s1,24(sp)
    800023ec:	6942                	ld	s2,16(sp)
    800023ee:	69a2                	ld	s3,8(sp)
    800023f0:	6145                	addi	sp,sp,48
    800023f2:	8082                	ret
        p->state = RUNNABLE;
    800023f4:	478d                	li	a5,3
    800023f6:	cc9c                	sw	a5,24(s1)
    800023f8:	b7cd                	j	800023da <kill+0x52>

00000000800023fa <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800023fa:	7179                	addi	sp,sp,-48
    800023fc:	f406                	sd	ra,40(sp)
    800023fe:	f022                	sd	s0,32(sp)
    80002400:	ec26                	sd	s1,24(sp)
    80002402:	e84a                	sd	s2,16(sp)
    80002404:	e44e                	sd	s3,8(sp)
    80002406:	e052                	sd	s4,0(sp)
    80002408:	1800                	addi	s0,sp,48
    8000240a:	84aa                	mv	s1,a0
    8000240c:	892e                	mv	s2,a1
    8000240e:	89b2                	mv	s3,a2
    80002410:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002412:	fffff097          	auipc	ra,0xfffff
    80002416:	584080e7          	jalr	1412(ra) # 80001996 <myproc>
  if(user_dst){
    8000241a:	c08d                	beqz	s1,8000243c <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000241c:	86d2                	mv	a3,s4
    8000241e:	864e                	mv	a2,s3
    80002420:	85ca                	mv	a1,s2
    80002422:	6928                	ld	a0,80(a0)
    80002424:	fffff097          	auipc	ra,0xfffff
    80002428:	232080e7          	jalr	562(ra) # 80001656 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000242c:	70a2                	ld	ra,40(sp)
    8000242e:	7402                	ld	s0,32(sp)
    80002430:	64e2                	ld	s1,24(sp)
    80002432:	6942                	ld	s2,16(sp)
    80002434:	69a2                	ld	s3,8(sp)
    80002436:	6a02                	ld	s4,0(sp)
    80002438:	6145                	addi	sp,sp,48
    8000243a:	8082                	ret
    memmove((char *)dst, src, len);
    8000243c:	000a061b          	sext.w	a2,s4
    80002440:	85ce                	mv	a1,s3
    80002442:	854a                	mv	a0,s2
    80002444:	fffff097          	auipc	ra,0xfffff
    80002448:	8e4080e7          	jalr	-1820(ra) # 80000d28 <memmove>
    return 0;
    8000244c:	8526                	mv	a0,s1
    8000244e:	bff9                	j	8000242c <either_copyout+0x32>

0000000080002450 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002450:	7179                	addi	sp,sp,-48
    80002452:	f406                	sd	ra,40(sp)
    80002454:	f022                	sd	s0,32(sp)
    80002456:	ec26                	sd	s1,24(sp)
    80002458:	e84a                	sd	s2,16(sp)
    8000245a:	e44e                	sd	s3,8(sp)
    8000245c:	e052                	sd	s4,0(sp)
    8000245e:	1800                	addi	s0,sp,48
    80002460:	892a                	mv	s2,a0
    80002462:	84ae                	mv	s1,a1
    80002464:	89b2                	mv	s3,a2
    80002466:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002468:	fffff097          	auipc	ra,0xfffff
    8000246c:	52e080e7          	jalr	1326(ra) # 80001996 <myproc>
  if(user_src){
    80002470:	c08d                	beqz	s1,80002492 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002472:	86d2                	mv	a3,s4
    80002474:	864e                	mv	a2,s3
    80002476:	85ca                	mv	a1,s2
    80002478:	6928                	ld	a0,80(a0)
    8000247a:	fffff097          	auipc	ra,0xfffff
    8000247e:	268080e7          	jalr	616(ra) # 800016e2 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002482:	70a2                	ld	ra,40(sp)
    80002484:	7402                	ld	s0,32(sp)
    80002486:	64e2                	ld	s1,24(sp)
    80002488:	6942                	ld	s2,16(sp)
    8000248a:	69a2                	ld	s3,8(sp)
    8000248c:	6a02                	ld	s4,0(sp)
    8000248e:	6145                	addi	sp,sp,48
    80002490:	8082                	ret
    memmove(dst, (char*)src, len);
    80002492:	000a061b          	sext.w	a2,s4
    80002496:	85ce                	mv	a1,s3
    80002498:	854a                	mv	a0,s2
    8000249a:	fffff097          	auipc	ra,0xfffff
    8000249e:	88e080e7          	jalr	-1906(ra) # 80000d28 <memmove>
    return 0;
    800024a2:	8526                	mv	a0,s1
    800024a4:	bff9                	j	80002482 <either_copyin+0x32>

00000000800024a6 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800024a6:	715d                	addi	sp,sp,-80
    800024a8:	e486                	sd	ra,72(sp)
    800024aa:	e0a2                	sd	s0,64(sp)
    800024ac:	fc26                	sd	s1,56(sp)
    800024ae:	f84a                	sd	s2,48(sp)
    800024b0:	f44e                	sd	s3,40(sp)
    800024b2:	f052                	sd	s4,32(sp)
    800024b4:	ec56                	sd	s5,24(sp)
    800024b6:	e85a                	sd	s6,16(sp)
    800024b8:	e45e                	sd	s7,8(sp)
    800024ba:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800024bc:	00006517          	auipc	a0,0x6
    800024c0:	c0c50513          	addi	a0,a0,-1012 # 800080c8 <digits+0x88>
    800024c4:	ffffe097          	auipc	ra,0xffffe
    800024c8:	0be080e7          	jalr	190(ra) # 80000582 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800024cc:	0000f497          	auipc	s1,0xf
    800024d0:	35c48493          	addi	s1,s1,860 # 80011828 <proc+0x158>
    800024d4:	00015917          	auipc	s2,0x15
    800024d8:	d5490913          	addi	s2,s2,-684 # 80017228 <bcache+0xd8>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800024dc:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800024de:	00006997          	auipc	s3,0x6
    800024e2:	da298993          	addi	s3,s3,-606 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    800024e6:	00006a97          	auipc	s5,0x6
    800024ea:	da2a8a93          	addi	s5,s5,-606 # 80008288 <digits+0x248>
    printf("\n");
    800024ee:	00006a17          	auipc	s4,0x6
    800024f2:	bdaa0a13          	addi	s4,s4,-1062 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800024f6:	00006b97          	auipc	s7,0x6
    800024fa:	dcab8b93          	addi	s7,s7,-566 # 800082c0 <states.0>
    800024fe:	a00d                	j	80002520 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002500:	ed86a583          	lw	a1,-296(a3)
    80002504:	8556                	mv	a0,s5
    80002506:	ffffe097          	auipc	ra,0xffffe
    8000250a:	07c080e7          	jalr	124(ra) # 80000582 <printf>
    printf("\n");
    8000250e:	8552                	mv	a0,s4
    80002510:	ffffe097          	auipc	ra,0xffffe
    80002514:	072080e7          	jalr	114(ra) # 80000582 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002518:	16848493          	addi	s1,s1,360
    8000251c:	03248163          	beq	s1,s2,8000253e <procdump+0x98>
    if(p->state == UNUSED)
    80002520:	86a6                	mv	a3,s1
    80002522:	ec04a783          	lw	a5,-320(s1)
    80002526:	dbed                	beqz	a5,80002518 <procdump+0x72>
      state = "???";
    80002528:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000252a:	fcfb6be3          	bltu	s6,a5,80002500 <procdump+0x5a>
    8000252e:	1782                	slli	a5,a5,0x20
    80002530:	9381                	srli	a5,a5,0x20
    80002532:	078e                	slli	a5,a5,0x3
    80002534:	97de                	add	a5,a5,s7
    80002536:	6390                	ld	a2,0(a5)
    80002538:	f661                	bnez	a2,80002500 <procdump+0x5a>
      state = "???";
    8000253a:	864e                	mv	a2,s3
    8000253c:	b7d1                	j	80002500 <procdump+0x5a>
  }
}
    8000253e:	60a6                	ld	ra,72(sp)
    80002540:	6406                	ld	s0,64(sp)
    80002542:	74e2                	ld	s1,56(sp)
    80002544:	7942                	ld	s2,48(sp)
    80002546:	79a2                	ld	s3,40(sp)
    80002548:	7a02                	ld	s4,32(sp)
    8000254a:	6ae2                	ld	s5,24(sp)
    8000254c:	6b42                	ld	s6,16(sp)
    8000254e:	6ba2                	ld	s7,8(sp)
    80002550:	6161                	addi	sp,sp,80
    80002552:	8082                	ret

0000000080002554 <swtch>:
    80002554:	00153023          	sd	ra,0(a0)
    80002558:	00253423          	sd	sp,8(a0)
    8000255c:	e900                	sd	s0,16(a0)
    8000255e:	ed04                	sd	s1,24(a0)
    80002560:	03253023          	sd	s2,32(a0)
    80002564:	03353423          	sd	s3,40(a0)
    80002568:	03453823          	sd	s4,48(a0)
    8000256c:	03553c23          	sd	s5,56(a0)
    80002570:	05653023          	sd	s6,64(a0)
    80002574:	05753423          	sd	s7,72(a0)
    80002578:	05853823          	sd	s8,80(a0)
    8000257c:	05953c23          	sd	s9,88(a0)
    80002580:	07a53023          	sd	s10,96(a0)
    80002584:	07b53423          	sd	s11,104(a0)
    80002588:	0005b083          	ld	ra,0(a1)
    8000258c:	0085b103          	ld	sp,8(a1)
    80002590:	6980                	ld	s0,16(a1)
    80002592:	6d84                	ld	s1,24(a1)
    80002594:	0205b903          	ld	s2,32(a1)
    80002598:	0285b983          	ld	s3,40(a1)
    8000259c:	0305ba03          	ld	s4,48(a1)
    800025a0:	0385ba83          	ld	s5,56(a1)
    800025a4:	0405bb03          	ld	s6,64(a1)
    800025a8:	0485bb83          	ld	s7,72(a1)
    800025ac:	0505bc03          	ld	s8,80(a1)
    800025b0:	0585bc83          	ld	s9,88(a1)
    800025b4:	0605bd03          	ld	s10,96(a1)
    800025b8:	0685bd83          	ld	s11,104(a1)
    800025bc:	8082                	ret

00000000800025be <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800025be:	1141                	addi	sp,sp,-16
    800025c0:	e406                	sd	ra,8(sp)
    800025c2:	e022                	sd	s0,0(sp)
    800025c4:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800025c6:	00006597          	auipc	a1,0x6
    800025ca:	d2a58593          	addi	a1,a1,-726 # 800082f0 <states.0+0x30>
    800025ce:	00015517          	auipc	a0,0x15
    800025d2:	b0250513          	addi	a0,a0,-1278 # 800170d0 <tickslock>
    800025d6:	ffffe097          	auipc	ra,0xffffe
    800025da:	56a080e7          	jalr	1386(ra) # 80000b40 <initlock>
}
    800025de:	60a2                	ld	ra,8(sp)
    800025e0:	6402                	ld	s0,0(sp)
    800025e2:	0141                	addi	sp,sp,16
    800025e4:	8082                	ret

00000000800025e6 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800025e6:	1141                	addi	sp,sp,-16
    800025e8:	e422                	sd	s0,8(sp)
    800025ea:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800025ec:	00003797          	auipc	a5,0x3
    800025f0:	76478793          	addi	a5,a5,1892 # 80005d50 <kernelvec>
    800025f4:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800025f8:	6422                	ld	s0,8(sp)
    800025fa:	0141                	addi	sp,sp,16
    800025fc:	8082                	ret

00000000800025fe <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800025fe:	1141                	addi	sp,sp,-16
    80002600:	e406                	sd	ra,8(sp)
    80002602:	e022                	sd	s0,0(sp)
    80002604:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002606:	fffff097          	auipc	ra,0xfffff
    8000260a:	390080e7          	jalr	912(ra) # 80001996 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000260e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002612:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002614:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002618:	00005617          	auipc	a2,0x5
    8000261c:	9e860613          	addi	a2,a2,-1560 # 80007000 <_trampoline>
    80002620:	00005697          	auipc	a3,0x5
    80002624:	9e068693          	addi	a3,a3,-1568 # 80007000 <_trampoline>
    80002628:	8e91                	sub	a3,a3,a2
    8000262a:	040007b7          	lui	a5,0x4000
    8000262e:	17fd                	addi	a5,a5,-1
    80002630:	07b2                	slli	a5,a5,0xc
    80002632:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002634:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002638:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000263a:	180026f3          	csrr	a3,satp
    8000263e:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002640:	6d38                	ld	a4,88(a0)
    80002642:	6134                	ld	a3,64(a0)
    80002644:	6585                	lui	a1,0x1
    80002646:	96ae                	add	a3,a3,a1
    80002648:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000264a:	6d38                	ld	a4,88(a0)
    8000264c:	00000697          	auipc	a3,0x0
    80002650:	13868693          	addi	a3,a3,312 # 80002784 <usertrap>
    80002654:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002656:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002658:	8692                	mv	a3,tp
    8000265a:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000265c:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002660:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002664:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002668:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000266c:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000266e:	6f18                	ld	a4,24(a4)
    80002670:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002674:	692c                	ld	a1,80(a0)
    80002676:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002678:	00005717          	auipc	a4,0x5
    8000267c:	a1870713          	addi	a4,a4,-1512 # 80007090 <userret>
    80002680:	8f11                	sub	a4,a4,a2
    80002682:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002684:	577d                	li	a4,-1
    80002686:	177e                	slli	a4,a4,0x3f
    80002688:	8dd9                	or	a1,a1,a4
    8000268a:	02000537          	lui	a0,0x2000
    8000268e:	157d                	addi	a0,a0,-1
    80002690:	0536                	slli	a0,a0,0xd
    80002692:	9782                	jalr	a5
}
    80002694:	60a2                	ld	ra,8(sp)
    80002696:	6402                	ld	s0,0(sp)
    80002698:	0141                	addi	sp,sp,16
    8000269a:	8082                	ret

000000008000269c <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000269c:	1101                	addi	sp,sp,-32
    8000269e:	ec06                	sd	ra,24(sp)
    800026a0:	e822                	sd	s0,16(sp)
    800026a2:	e426                	sd	s1,8(sp)
    800026a4:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800026a6:	00015497          	auipc	s1,0x15
    800026aa:	a2a48493          	addi	s1,s1,-1494 # 800170d0 <tickslock>
    800026ae:	8526                	mv	a0,s1
    800026b0:	ffffe097          	auipc	ra,0xffffe
    800026b4:	520080e7          	jalr	1312(ra) # 80000bd0 <acquire>
  ticks++;
    800026b8:	00007517          	auipc	a0,0x7
    800026bc:	97850513          	addi	a0,a0,-1672 # 80009030 <ticks>
    800026c0:	411c                	lw	a5,0(a0)
    800026c2:	2785                	addiw	a5,a5,1
    800026c4:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800026c6:	00000097          	auipc	ra,0x0
    800026ca:	b1c080e7          	jalr	-1252(ra) # 800021e2 <wakeup>
  release(&tickslock);
    800026ce:	8526                	mv	a0,s1
    800026d0:	ffffe097          	auipc	ra,0xffffe
    800026d4:	5b4080e7          	jalr	1460(ra) # 80000c84 <release>
}
    800026d8:	60e2                	ld	ra,24(sp)
    800026da:	6442                	ld	s0,16(sp)
    800026dc:	64a2                	ld	s1,8(sp)
    800026de:	6105                	addi	sp,sp,32
    800026e0:	8082                	ret

00000000800026e2 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800026e2:	1101                	addi	sp,sp,-32
    800026e4:	ec06                	sd	ra,24(sp)
    800026e6:	e822                	sd	s0,16(sp)
    800026e8:	e426                	sd	s1,8(sp)
    800026ea:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800026ec:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800026f0:	00074d63          	bltz	a4,8000270a <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800026f4:	57fd                	li	a5,-1
    800026f6:	17fe                	slli	a5,a5,0x3f
    800026f8:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800026fa:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800026fc:	06f70363          	beq	a4,a5,80002762 <devintr+0x80>
  }
}
    80002700:	60e2                	ld	ra,24(sp)
    80002702:	6442                	ld	s0,16(sp)
    80002704:	64a2                	ld	s1,8(sp)
    80002706:	6105                	addi	sp,sp,32
    80002708:	8082                	ret
     (scause & 0xff) == 9){
    8000270a:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000270e:	46a5                	li	a3,9
    80002710:	fed792e3          	bne	a5,a3,800026f4 <devintr+0x12>
    int irq = plic_claim();
    80002714:	00003097          	auipc	ra,0x3
    80002718:	744080e7          	jalr	1860(ra) # 80005e58 <plic_claim>
    8000271c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000271e:	47a9                	li	a5,10
    80002720:	02f50763          	beq	a0,a5,8000274e <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002724:	4785                	li	a5,1
    80002726:	02f50963          	beq	a0,a5,80002758 <devintr+0x76>
    return 1;
    8000272a:	4505                	li	a0,1
    } else if(irq){
    8000272c:	d8f1                	beqz	s1,80002700 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000272e:	85a6                	mv	a1,s1
    80002730:	00006517          	auipc	a0,0x6
    80002734:	bc850513          	addi	a0,a0,-1080 # 800082f8 <states.0+0x38>
    80002738:	ffffe097          	auipc	ra,0xffffe
    8000273c:	e4a080e7          	jalr	-438(ra) # 80000582 <printf>
      plic_complete(irq);
    80002740:	8526                	mv	a0,s1
    80002742:	00003097          	auipc	ra,0x3
    80002746:	73a080e7          	jalr	1850(ra) # 80005e7c <plic_complete>
    return 1;
    8000274a:	4505                	li	a0,1
    8000274c:	bf55                	j	80002700 <devintr+0x1e>
      uartintr();
    8000274e:	ffffe097          	auipc	ra,0xffffe
    80002752:	246080e7          	jalr	582(ra) # 80000994 <uartintr>
    80002756:	b7ed                	j	80002740 <devintr+0x5e>
      virtio_disk_intr();
    80002758:	00004097          	auipc	ra,0x4
    8000275c:	bb6080e7          	jalr	-1098(ra) # 8000630e <virtio_disk_intr>
    80002760:	b7c5                	j	80002740 <devintr+0x5e>
    if(cpuid() == 0){
    80002762:	fffff097          	auipc	ra,0xfffff
    80002766:	208080e7          	jalr	520(ra) # 8000196a <cpuid>
    8000276a:	c901                	beqz	a0,8000277a <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000276c:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002770:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002772:	14479073          	csrw	sip,a5
    return 2;
    80002776:	4509                	li	a0,2
    80002778:	b761                	j	80002700 <devintr+0x1e>
      clockintr();
    8000277a:	00000097          	auipc	ra,0x0
    8000277e:	f22080e7          	jalr	-222(ra) # 8000269c <clockintr>
    80002782:	b7ed                	j	8000276c <devintr+0x8a>

0000000080002784 <usertrap>:
{
    80002784:	1101                	addi	sp,sp,-32
    80002786:	ec06                	sd	ra,24(sp)
    80002788:	e822                	sd	s0,16(sp)
    8000278a:	e426                	sd	s1,8(sp)
    8000278c:	e04a                	sd	s2,0(sp)
    8000278e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002790:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002794:	1007f793          	andi	a5,a5,256
    80002798:	e3ad                	bnez	a5,800027fa <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000279a:	00003797          	auipc	a5,0x3
    8000279e:	5b678793          	addi	a5,a5,1462 # 80005d50 <kernelvec>
    800027a2:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800027a6:	fffff097          	auipc	ra,0xfffff
    800027aa:	1f0080e7          	jalr	496(ra) # 80001996 <myproc>
    800027ae:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800027b0:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800027b2:	14102773          	csrr	a4,sepc
    800027b6:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027b8:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800027bc:	47a1                	li	a5,8
    800027be:	04f71c63          	bne	a4,a5,80002816 <usertrap+0x92>
    if(p->killed)
    800027c2:	551c                	lw	a5,40(a0)
    800027c4:	e3b9                	bnez	a5,8000280a <usertrap+0x86>
    p->trapframe->epc += 4;
    800027c6:	6cb8                	ld	a4,88(s1)
    800027c8:	6f1c                	ld	a5,24(a4)
    800027ca:	0791                	addi	a5,a5,4
    800027cc:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027ce:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800027d2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027d6:	10079073          	csrw	sstatus,a5
    syscall();
    800027da:	00000097          	auipc	ra,0x0
    800027de:	48e080e7          	jalr	1166(ra) # 80002c68 <syscall>
  if(p->killed)
    800027e2:	549c                	lw	a5,40(s1)
    800027e4:	ebc1                	bnez	a5,80002874 <usertrap+0xf0>
  usertrapret();
    800027e6:	00000097          	auipc	ra,0x0
    800027ea:	e18080e7          	jalr	-488(ra) # 800025fe <usertrapret>
}
    800027ee:	60e2                	ld	ra,24(sp)
    800027f0:	6442                	ld	s0,16(sp)
    800027f2:	64a2                	ld	s1,8(sp)
    800027f4:	6902                	ld	s2,0(sp)
    800027f6:	6105                	addi	sp,sp,32
    800027f8:	8082                	ret
    panic("usertrap: not from user mode");
    800027fa:	00006517          	auipc	a0,0x6
    800027fe:	b1e50513          	addi	a0,a0,-1250 # 80008318 <states.0+0x58>
    80002802:	ffffe097          	auipc	ra,0xffffe
    80002806:	d36080e7          	jalr	-714(ra) # 80000538 <panic>
      exit(-1);
    8000280a:	557d                	li	a0,-1
    8000280c:	00000097          	auipc	ra,0x0
    80002810:	aa6080e7          	jalr	-1370(ra) # 800022b2 <exit>
    80002814:	bf4d                	j	800027c6 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002816:	00000097          	auipc	ra,0x0
    8000281a:	ecc080e7          	jalr	-308(ra) # 800026e2 <devintr>
    8000281e:	892a                	mv	s2,a0
    80002820:	c501                	beqz	a0,80002828 <usertrap+0xa4>
  if(p->killed)
    80002822:	549c                	lw	a5,40(s1)
    80002824:	c3a1                	beqz	a5,80002864 <usertrap+0xe0>
    80002826:	a815                	j	8000285a <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002828:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000282c:	5890                	lw	a2,48(s1)
    8000282e:	00006517          	auipc	a0,0x6
    80002832:	b0a50513          	addi	a0,a0,-1270 # 80008338 <states.0+0x78>
    80002836:	ffffe097          	auipc	ra,0xffffe
    8000283a:	d4c080e7          	jalr	-692(ra) # 80000582 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000283e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002842:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002846:	00006517          	auipc	a0,0x6
    8000284a:	b2250513          	addi	a0,a0,-1246 # 80008368 <states.0+0xa8>
    8000284e:	ffffe097          	auipc	ra,0xffffe
    80002852:	d34080e7          	jalr	-716(ra) # 80000582 <printf>
    p->killed = 1;
    80002856:	4785                	li	a5,1
    80002858:	d49c                	sw	a5,40(s1)
    exit(-1);
    8000285a:	557d                	li	a0,-1
    8000285c:	00000097          	auipc	ra,0x0
    80002860:	a56080e7          	jalr	-1450(ra) # 800022b2 <exit>
  if(which_dev == 2)
    80002864:	4789                	li	a5,2
    80002866:	f8f910e3          	bne	s2,a5,800027e6 <usertrap+0x62>
    yield();
    8000286a:	fffff097          	auipc	ra,0xfffff
    8000286e:	7b0080e7          	jalr	1968(ra) # 8000201a <yield>
    80002872:	bf95                	j	800027e6 <usertrap+0x62>
  int which_dev = 0;
    80002874:	4901                	li	s2,0
    80002876:	b7d5                	j	8000285a <usertrap+0xd6>

0000000080002878 <kerneltrap>:
{
    80002878:	7179                	addi	sp,sp,-48
    8000287a:	f406                	sd	ra,40(sp)
    8000287c:	f022                	sd	s0,32(sp)
    8000287e:	ec26                	sd	s1,24(sp)
    80002880:	e84a                	sd	s2,16(sp)
    80002882:	e44e                	sd	s3,8(sp)
    80002884:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002886:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000288a:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000288e:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002892:	1004f793          	andi	a5,s1,256
    80002896:	cb85                	beqz	a5,800028c6 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002898:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000289c:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    8000289e:	ef85                	bnez	a5,800028d6 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800028a0:	00000097          	auipc	ra,0x0
    800028a4:	e42080e7          	jalr	-446(ra) # 800026e2 <devintr>
    800028a8:	cd1d                	beqz	a0,800028e6 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800028aa:	4789                	li	a5,2
    800028ac:	06f50a63          	beq	a0,a5,80002920 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028b0:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028b4:	10049073          	csrw	sstatus,s1
}
    800028b8:	70a2                	ld	ra,40(sp)
    800028ba:	7402                	ld	s0,32(sp)
    800028bc:	64e2                	ld	s1,24(sp)
    800028be:	6942                	ld	s2,16(sp)
    800028c0:	69a2                	ld	s3,8(sp)
    800028c2:	6145                	addi	sp,sp,48
    800028c4:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800028c6:	00006517          	auipc	a0,0x6
    800028ca:	ac250513          	addi	a0,a0,-1342 # 80008388 <states.0+0xc8>
    800028ce:	ffffe097          	auipc	ra,0xffffe
    800028d2:	c6a080e7          	jalr	-918(ra) # 80000538 <panic>
    panic("kerneltrap: interrupts enabled");
    800028d6:	00006517          	auipc	a0,0x6
    800028da:	ada50513          	addi	a0,a0,-1318 # 800083b0 <states.0+0xf0>
    800028de:	ffffe097          	auipc	ra,0xffffe
    800028e2:	c5a080e7          	jalr	-934(ra) # 80000538 <panic>
    printf("scause %p\n", scause);
    800028e6:	85ce                	mv	a1,s3
    800028e8:	00006517          	auipc	a0,0x6
    800028ec:	ae850513          	addi	a0,a0,-1304 # 800083d0 <states.0+0x110>
    800028f0:	ffffe097          	auipc	ra,0xffffe
    800028f4:	c92080e7          	jalr	-878(ra) # 80000582 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028f8:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028fc:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002900:	00006517          	auipc	a0,0x6
    80002904:	ae050513          	addi	a0,a0,-1312 # 800083e0 <states.0+0x120>
    80002908:	ffffe097          	auipc	ra,0xffffe
    8000290c:	c7a080e7          	jalr	-902(ra) # 80000582 <printf>
    panic("kerneltrap");
    80002910:	00006517          	auipc	a0,0x6
    80002914:	ae850513          	addi	a0,a0,-1304 # 800083f8 <states.0+0x138>
    80002918:	ffffe097          	auipc	ra,0xffffe
    8000291c:	c20080e7          	jalr	-992(ra) # 80000538 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002920:	fffff097          	auipc	ra,0xfffff
    80002924:	076080e7          	jalr	118(ra) # 80001996 <myproc>
    80002928:	d541                	beqz	a0,800028b0 <kerneltrap+0x38>
    8000292a:	fffff097          	auipc	ra,0xfffff
    8000292e:	06c080e7          	jalr	108(ra) # 80001996 <myproc>
    80002932:	4d18                	lw	a4,24(a0)
    80002934:	4791                	li	a5,4
    80002936:	f6f71de3          	bne	a4,a5,800028b0 <kerneltrap+0x38>
    yield();
    8000293a:	fffff097          	auipc	ra,0xfffff
    8000293e:	6e0080e7          	jalr	1760(ra) # 8000201a <yield>
    80002942:	b7bd                	j	800028b0 <kerneltrap+0x38>

0000000080002944 <initsema>:
#include "kernel/riscv.h"
#include "kernel/spinlock.h"
#include "kernel/semaphore.h"
#include "kernel/defs.h"

void initsema(struct semaphore* s, int count) {
    80002944:	1141                	addi	sp,sp,-16
    80002946:	e406                	sd	ra,8(sp)
    80002948:	e022                	sd	s0,0(sp)
    8000294a:	0800                	addi	s0,sp,16
  s->value = count;
    8000294c:	c10c                	sw	a1,0(a0)
  initlock(&s->lk, "Counting Semaphore");
    8000294e:	00006597          	auipc	a1,0x6
    80002952:	aba58593          	addi	a1,a1,-1350 # 80008408 <states.0+0x148>
    80002956:	0521                	addi	a0,a0,8
    80002958:	ffffe097          	auipc	ra,0xffffe
    8000295c:	1e8080e7          	jalr	488(ra) # 80000b40 <initlock>
}
    80002960:	60a2                	ld	ra,8(sp)
    80002962:	6402                	ld	s0,0(sp)
    80002964:	0141                	addi	sp,sp,16
    80002966:	8082                	ret

0000000080002968 <downsema>:

int downsema(struct semaphore* s) {
    80002968:	1101                	addi	sp,sp,-32
    8000296a:	ec06                	sd	ra,24(sp)
    8000296c:	e822                	sd	s0,16(sp)
    8000296e:	e426                	sd	s1,8(sp)
    80002970:	e04a                	sd	s2,0(sp)
    80002972:	1000                	addi	s0,sp,32
    80002974:	84aa                	mv	s1,a0
  acquire(&s->lk);
    80002976:	00850913          	addi	s2,a0,8
    8000297a:	854a                	mv	a0,s2
    8000297c:	ffffe097          	auipc	ra,0xffffe
    80002980:	254080e7          	jalr	596(ra) # 80000bd0 <acquire>
  while (s->value <=0)
    80002984:	409c                	lw	a5,0(s1)
    80002986:	00f04b63          	bgtz	a5,8000299c <downsema+0x34>
    sleep(s,&s->lk);
    8000298a:	85ca                	mv	a1,s2
    8000298c:	8526                	mv	a0,s1
    8000298e:	fffff097          	auipc	ra,0xfffff
    80002992:	6c8080e7          	jalr	1736(ra) # 80002056 <sleep>
  while (s->value <=0)
    80002996:	409c                	lw	a5,0(s1)
    80002998:	fef059e3          	blez	a5,8000298a <downsema+0x22>
  s->value--;
    8000299c:	37fd                	addiw	a5,a5,-1
    8000299e:	c09c                	sw	a5,0(s1)
  release(&s->lk);
    800029a0:	854a                	mv	a0,s2
    800029a2:	ffffe097          	auipc	ra,0xffffe
    800029a6:	2e2080e7          	jalr	738(ra) # 80000c84 <release>
  return s->value;
}
    800029aa:	4088                	lw	a0,0(s1)
    800029ac:	60e2                	ld	ra,24(sp)
    800029ae:	6442                	ld	s0,16(sp)
    800029b0:	64a2                	ld	s1,8(sp)
    800029b2:	6902                	ld	s2,0(sp)
    800029b4:	6105                	addi	sp,sp,32
    800029b6:	8082                	ret

00000000800029b8 <upsema>:

int upsema(struct semaphore* s) {
    800029b8:	1101                	addi	sp,sp,-32
    800029ba:	ec06                	sd	ra,24(sp)
    800029bc:	e822                	sd	s0,16(sp)
    800029be:	e426                	sd	s1,8(sp)
    800029c0:	e04a                	sd	s2,0(sp)
    800029c2:	1000                	addi	s0,sp,32
    800029c4:	84aa                	mv	s1,a0
  acquire(&s->lk);
    800029c6:	00850913          	addi	s2,a0,8
    800029ca:	854a                	mv	a0,s2
    800029cc:	ffffe097          	auipc	ra,0xffffe
    800029d0:	204080e7          	jalr	516(ra) # 80000bd0 <acquire>
  s->value++;
    800029d4:	409c                	lw	a5,0(s1)
    800029d6:	2785                	addiw	a5,a5,1
    800029d8:	c09c                	sw	a5,0(s1)
  wakeup(s);
    800029da:	8526                	mv	a0,s1
    800029dc:	00000097          	auipc	ra,0x0
    800029e0:	806080e7          	jalr	-2042(ra) # 800021e2 <wakeup>
  release(&s->lk);
    800029e4:	854a                	mv	a0,s2
    800029e6:	ffffe097          	auipc	ra,0xffffe
    800029ea:	29e080e7          	jalr	670(ra) # 80000c84 <release>
  return s->value;
}
    800029ee:	4088                	lw	a0,0(s1)
    800029f0:	60e2                	ld	ra,24(sp)
    800029f2:	6442                	ld	s0,16(sp)
    800029f4:	64a2                	ld	s1,8(sp)
    800029f6:	6902                	ld	s2,0(sp)
    800029f8:	6105                	addi	sp,sp,32
    800029fa:	8082                	ret

00000000800029fc <initrwsema>:

void initrwsema(struct rwsemaphore *rws)
{
    800029fc:	1101                	addi	sp,sp,-32
    800029fe:	ec06                	sd	ra,24(sp)
    80002a00:	e822                	sd	s0,16(sp)
    80002a02:	e426                	sd	s1,8(sp)
    80002a04:	1000                	addi	s0,sp,32
    80002a06:	84aa                	mv	s1,a0
   // Lecture slide page 14
   rws->readers = 0;
    80002a08:	04052023          	sw	zero,64(a0)
   initsema(&rws->mutex, 1);
    80002a0c:	4585                	li	a1,1
    80002a0e:	00000097          	auipc	ra,0x0
    80002a12:	f36080e7          	jalr	-202(ra) # 80002944 <initsema>
   initsema(&rws->roomEmpty, 1); 
    80002a16:	4585                	li	a1,1
    80002a18:	02048513          	addi	a0,s1,32
    80002a1c:	00000097          	auipc	ra,0x0
    80002a20:	f28080e7          	jalr	-216(ra) # 80002944 <initsema>
}
    80002a24:	60e2                	ld	ra,24(sp)
    80002a26:	6442                	ld	s0,16(sp)
    80002a28:	64a2                	ld	s1,8(sp)
    80002a2a:	6105                	addi	sp,sp,32
    80002a2c:	8082                	ret

0000000080002a2e <downreadsema>:

// A Reader enters room
int downreadsema(struct rwsemaphore *rws)
{
    80002a2e:	1101                	addi	sp,sp,-32
    80002a30:	ec06                	sd	ra,24(sp)
    80002a32:	e822                	sd	s0,16(sp)
    80002a34:	e426                	sd	s1,8(sp)
    80002a36:	1000                	addi	s0,sp,32
    80002a38:	84aa                	mv	s1,a0
   downsema(&rws->mutex); // Locking mutex
    80002a3a:	00000097          	auipc	ra,0x0
    80002a3e:	f2e080e7          	jalr	-210(ra) # 80002968 <downsema>
   rws->readers++;
    80002a42:	40bc                	lw	a5,64(s1)
    80002a44:	2785                	addiw	a5,a5,1
    80002a46:	0007871b          	sext.w	a4,a5
    80002a4a:	c0bc                	sw	a5,64(s1)

   if (rws->readers == 1)
    80002a4c:	4785                	li	a5,1
    80002a4e:	00f70d63          	beq	a4,a5,80002a68 <downreadsema+0x3a>
   {
      downsema(&rws->roomEmpty); // Locking roomEmpty
   }

   upsema(&rws->mutex); // Unlocking mutex
    80002a52:	8526                	mv	a0,s1
    80002a54:	00000097          	auipc	ra,0x0
    80002a58:	f64080e7          	jalr	-156(ra) # 800029b8 <upsema>

   return rws->readers;
}
    80002a5c:	40a8                	lw	a0,64(s1)
    80002a5e:	60e2                	ld	ra,24(sp)
    80002a60:	6442                	ld	s0,16(sp)
    80002a62:	64a2                	ld	s1,8(sp)
    80002a64:	6105                	addi	sp,sp,32
    80002a66:	8082                	ret
      downsema(&rws->roomEmpty); // Locking roomEmpty
    80002a68:	02048513          	addi	a0,s1,32
    80002a6c:	00000097          	auipc	ra,0x0
    80002a70:	efc080e7          	jalr	-260(ra) # 80002968 <downsema>
    80002a74:	bff9                	j	80002a52 <downreadsema+0x24>

0000000080002a76 <upreadsema>:

// A Reader exits room
int upreadsema(struct rwsemaphore *rws)
{
    80002a76:	1101                	addi	sp,sp,-32
    80002a78:	ec06                	sd	ra,24(sp)
    80002a7a:	e822                	sd	s0,16(sp)
    80002a7c:	e426                	sd	s1,8(sp)
    80002a7e:	1000                	addi	s0,sp,32
    80002a80:	84aa                	mv	s1,a0
    downsema(&rws->mutex);
    80002a82:	00000097          	auipc	ra,0x0
    80002a86:	ee6080e7          	jalr	-282(ra) # 80002968 <downsema>
    rws->readers--;
    80002a8a:	40bc                	lw	a5,64(s1)
    80002a8c:	37fd                	addiw	a5,a5,-1
    80002a8e:	0007871b          	sext.w	a4,a5
    80002a92:	c0bc                	sw	a5,64(s1)

    if (rws->readers == 0)
    80002a94:	cf01                	beqz	a4,80002aac <upreadsema+0x36>
    {
       upsema(&rws->roomEmpty); // Unlocking roomEmpty
    }

    upsema(&rws->mutex);
    80002a96:	8526                	mv	a0,s1
    80002a98:	00000097          	auipc	ra,0x0
    80002a9c:	f20080e7          	jalr	-224(ra) # 800029b8 <upsema>

    return rws->readers;
}
    80002aa0:	40a8                	lw	a0,64(s1)
    80002aa2:	60e2                	ld	ra,24(sp)
    80002aa4:	6442                	ld	s0,16(sp)
    80002aa6:	64a2                	ld	s1,8(sp)
    80002aa8:	6105                	addi	sp,sp,32
    80002aaa:	8082                	ret
       upsema(&rws->roomEmpty); // Unlocking roomEmpty
    80002aac:	02048513          	addi	a0,s1,32
    80002ab0:	00000097          	auipc	ra,0x0
    80002ab4:	f08080e7          	jalr	-248(ra) # 800029b8 <upsema>
    80002ab8:	bff9                	j	80002a96 <upreadsema+0x20>

0000000080002aba <downwritesema>:

// A Writer enters room
void downwritesema(struct rwsemaphore *rws)
{
    80002aba:	1141                	addi	sp,sp,-16
    80002abc:	e406                	sd	ra,8(sp)
    80002abe:	e022                	sd	s0,0(sp)
    80002ac0:	0800                	addi	s0,sp,16
   downsema(&rws->roomEmpty);
    80002ac2:	02050513          	addi	a0,a0,32
    80002ac6:	00000097          	auipc	ra,0x0
    80002aca:	ea2080e7          	jalr	-350(ra) # 80002968 <downsema>
}
    80002ace:	60a2                	ld	ra,8(sp)
    80002ad0:	6402                	ld	s0,0(sp)
    80002ad2:	0141                	addi	sp,sp,16
    80002ad4:	8082                	ret

0000000080002ad6 <upwritesema>:

// A writer exits room
void upwritesema(struct rwsemaphore *rws)
{
    80002ad6:	1141                	addi	sp,sp,-16
    80002ad8:	e406                	sd	ra,8(sp)
    80002ada:	e022                	sd	s0,0(sp)
    80002adc:	0800                	addi	s0,sp,16
   upsema(&rws->roomEmpty);
    80002ade:	02050513          	addi	a0,a0,32
    80002ae2:	00000097          	auipc	ra,0x0
    80002ae6:	ed6080e7          	jalr	-298(ra) # 800029b8 <upsema>
    80002aea:	60a2                	ld	ra,8(sp)
    80002aec:	6402                	ld	s0,0(sp)
    80002aee:	0141                	addi	sp,sp,16
    80002af0:	8082                	ret

0000000080002af2 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002af2:	1101                	addi	sp,sp,-32
    80002af4:	ec06                	sd	ra,24(sp)
    80002af6:	e822                	sd	s0,16(sp)
    80002af8:	e426                	sd	s1,8(sp)
    80002afa:	1000                	addi	s0,sp,32
    80002afc:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002afe:	fffff097          	auipc	ra,0xfffff
    80002b02:	e98080e7          	jalr	-360(ra) # 80001996 <myproc>
  switch (n) {
    80002b06:	4795                	li	a5,5
    80002b08:	0497e163          	bltu	a5,s1,80002b4a <argraw+0x58>
    80002b0c:	048a                	slli	s1,s1,0x2
    80002b0e:	00006717          	auipc	a4,0x6
    80002b12:	93a70713          	addi	a4,a4,-1734 # 80008448 <states.0+0x188>
    80002b16:	94ba                	add	s1,s1,a4
    80002b18:	409c                	lw	a5,0(s1)
    80002b1a:	97ba                	add	a5,a5,a4
    80002b1c:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b1e:	6d3c                	ld	a5,88(a0)
    80002b20:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b22:	60e2                	ld	ra,24(sp)
    80002b24:	6442                	ld	s0,16(sp)
    80002b26:	64a2                	ld	s1,8(sp)
    80002b28:	6105                	addi	sp,sp,32
    80002b2a:	8082                	ret
    return p->trapframe->a1;
    80002b2c:	6d3c                	ld	a5,88(a0)
    80002b2e:	7fa8                	ld	a0,120(a5)
    80002b30:	bfcd                	j	80002b22 <argraw+0x30>
    return p->trapframe->a2;
    80002b32:	6d3c                	ld	a5,88(a0)
    80002b34:	63c8                	ld	a0,128(a5)
    80002b36:	b7f5                	j	80002b22 <argraw+0x30>
    return p->trapframe->a3;
    80002b38:	6d3c                	ld	a5,88(a0)
    80002b3a:	67c8                	ld	a0,136(a5)
    80002b3c:	b7dd                	j	80002b22 <argraw+0x30>
    return p->trapframe->a4;
    80002b3e:	6d3c                	ld	a5,88(a0)
    80002b40:	6bc8                	ld	a0,144(a5)
    80002b42:	b7c5                	j	80002b22 <argraw+0x30>
    return p->trapframe->a5;
    80002b44:	6d3c                	ld	a5,88(a0)
    80002b46:	6fc8                	ld	a0,152(a5)
    80002b48:	bfe9                	j	80002b22 <argraw+0x30>
  panic("argraw");
    80002b4a:	00006517          	auipc	a0,0x6
    80002b4e:	8d650513          	addi	a0,a0,-1834 # 80008420 <states.0+0x160>
    80002b52:	ffffe097          	auipc	ra,0xffffe
    80002b56:	9e6080e7          	jalr	-1562(ra) # 80000538 <panic>

0000000080002b5a <fetchaddr>:
{
    80002b5a:	1101                	addi	sp,sp,-32
    80002b5c:	ec06                	sd	ra,24(sp)
    80002b5e:	e822                	sd	s0,16(sp)
    80002b60:	e426                	sd	s1,8(sp)
    80002b62:	e04a                	sd	s2,0(sp)
    80002b64:	1000                	addi	s0,sp,32
    80002b66:	84aa                	mv	s1,a0
    80002b68:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b6a:	fffff097          	auipc	ra,0xfffff
    80002b6e:	e2c080e7          	jalr	-468(ra) # 80001996 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002b72:	653c                	ld	a5,72(a0)
    80002b74:	02f4f863          	bgeu	s1,a5,80002ba4 <fetchaddr+0x4a>
    80002b78:	00848713          	addi	a4,s1,8
    80002b7c:	02e7e663          	bltu	a5,a4,80002ba8 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b80:	46a1                	li	a3,8
    80002b82:	8626                	mv	a2,s1
    80002b84:	85ca                	mv	a1,s2
    80002b86:	6928                	ld	a0,80(a0)
    80002b88:	fffff097          	auipc	ra,0xfffff
    80002b8c:	b5a080e7          	jalr	-1190(ra) # 800016e2 <copyin>
    80002b90:	00a03533          	snez	a0,a0
    80002b94:	40a00533          	neg	a0,a0
}
    80002b98:	60e2                	ld	ra,24(sp)
    80002b9a:	6442                	ld	s0,16(sp)
    80002b9c:	64a2                	ld	s1,8(sp)
    80002b9e:	6902                	ld	s2,0(sp)
    80002ba0:	6105                	addi	sp,sp,32
    80002ba2:	8082                	ret
    return -1;
    80002ba4:	557d                	li	a0,-1
    80002ba6:	bfcd                	j	80002b98 <fetchaddr+0x3e>
    80002ba8:	557d                	li	a0,-1
    80002baa:	b7fd                	j	80002b98 <fetchaddr+0x3e>

0000000080002bac <fetchstr>:
{
    80002bac:	7179                	addi	sp,sp,-48
    80002bae:	f406                	sd	ra,40(sp)
    80002bb0:	f022                	sd	s0,32(sp)
    80002bb2:	ec26                	sd	s1,24(sp)
    80002bb4:	e84a                	sd	s2,16(sp)
    80002bb6:	e44e                	sd	s3,8(sp)
    80002bb8:	1800                	addi	s0,sp,48
    80002bba:	892a                	mv	s2,a0
    80002bbc:	84ae                	mv	s1,a1
    80002bbe:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002bc0:	fffff097          	auipc	ra,0xfffff
    80002bc4:	dd6080e7          	jalr	-554(ra) # 80001996 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002bc8:	86ce                	mv	a3,s3
    80002bca:	864a                	mv	a2,s2
    80002bcc:	85a6                	mv	a1,s1
    80002bce:	6928                	ld	a0,80(a0)
    80002bd0:	fffff097          	auipc	ra,0xfffff
    80002bd4:	ba0080e7          	jalr	-1120(ra) # 80001770 <copyinstr>
  if(err < 0)
    80002bd8:	00054763          	bltz	a0,80002be6 <fetchstr+0x3a>
  return strlen(buf);
    80002bdc:	8526                	mv	a0,s1
    80002bde:	ffffe097          	auipc	ra,0xffffe
    80002be2:	26a080e7          	jalr	618(ra) # 80000e48 <strlen>
}
    80002be6:	70a2                	ld	ra,40(sp)
    80002be8:	7402                	ld	s0,32(sp)
    80002bea:	64e2                	ld	s1,24(sp)
    80002bec:	6942                	ld	s2,16(sp)
    80002bee:	69a2                	ld	s3,8(sp)
    80002bf0:	6145                	addi	sp,sp,48
    80002bf2:	8082                	ret

0000000080002bf4 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002bf4:	1101                	addi	sp,sp,-32
    80002bf6:	ec06                	sd	ra,24(sp)
    80002bf8:	e822                	sd	s0,16(sp)
    80002bfa:	e426                	sd	s1,8(sp)
    80002bfc:	1000                	addi	s0,sp,32
    80002bfe:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c00:	00000097          	auipc	ra,0x0
    80002c04:	ef2080e7          	jalr	-270(ra) # 80002af2 <argraw>
    80002c08:	c088                	sw	a0,0(s1)
  return 0;
}
    80002c0a:	4501                	li	a0,0
    80002c0c:	60e2                	ld	ra,24(sp)
    80002c0e:	6442                	ld	s0,16(sp)
    80002c10:	64a2                	ld	s1,8(sp)
    80002c12:	6105                	addi	sp,sp,32
    80002c14:	8082                	ret

0000000080002c16 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002c16:	1101                	addi	sp,sp,-32
    80002c18:	ec06                	sd	ra,24(sp)
    80002c1a:	e822                	sd	s0,16(sp)
    80002c1c:	e426                	sd	s1,8(sp)
    80002c1e:	1000                	addi	s0,sp,32
    80002c20:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c22:	00000097          	auipc	ra,0x0
    80002c26:	ed0080e7          	jalr	-304(ra) # 80002af2 <argraw>
    80002c2a:	e088                	sd	a0,0(s1)
  return 0;
}
    80002c2c:	4501                	li	a0,0
    80002c2e:	60e2                	ld	ra,24(sp)
    80002c30:	6442                	ld	s0,16(sp)
    80002c32:	64a2                	ld	s1,8(sp)
    80002c34:	6105                	addi	sp,sp,32
    80002c36:	8082                	ret

0000000080002c38 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c38:	1101                	addi	sp,sp,-32
    80002c3a:	ec06                	sd	ra,24(sp)
    80002c3c:	e822                	sd	s0,16(sp)
    80002c3e:	e426                	sd	s1,8(sp)
    80002c40:	e04a                	sd	s2,0(sp)
    80002c42:	1000                	addi	s0,sp,32
    80002c44:	84ae                	mv	s1,a1
    80002c46:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002c48:	00000097          	auipc	ra,0x0
    80002c4c:	eaa080e7          	jalr	-342(ra) # 80002af2 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002c50:	864a                	mv	a2,s2
    80002c52:	85a6                	mv	a1,s1
    80002c54:	00000097          	auipc	ra,0x0
    80002c58:	f58080e7          	jalr	-168(ra) # 80002bac <fetchstr>
}
    80002c5c:	60e2                	ld	ra,24(sp)
    80002c5e:	6442                	ld	s0,16(sp)
    80002c60:	64a2                	ld	s1,8(sp)
    80002c62:	6902                	ld	s2,0(sp)
    80002c64:	6105                	addi	sp,sp,32
    80002c66:	8082                	ret

0000000080002c68 <syscall>:
[SYS_rwsematest] sys_rwsematest,
};

void
syscall(void)
{
    80002c68:	1101                	addi	sp,sp,-32
    80002c6a:	ec06                	sd	ra,24(sp)
    80002c6c:	e822                	sd	s0,16(sp)
    80002c6e:	e426                	sd	s1,8(sp)
    80002c70:	e04a                	sd	s2,0(sp)
    80002c72:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c74:	fffff097          	auipc	ra,0xfffff
    80002c78:	d22080e7          	jalr	-734(ra) # 80001996 <myproc>
    80002c7c:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c7e:	05853903          	ld	s2,88(a0)
    80002c82:	0a893783          	ld	a5,168(s2)
    80002c86:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c8a:	37fd                	addiw	a5,a5,-1
    80002c8c:	4759                	li	a4,22
    80002c8e:	00f76f63          	bltu	a4,a5,80002cac <syscall+0x44>
    80002c92:	00369713          	slli	a4,a3,0x3
    80002c96:	00005797          	auipc	a5,0x5
    80002c9a:	7ca78793          	addi	a5,a5,1994 # 80008460 <syscalls>
    80002c9e:	97ba                	add	a5,a5,a4
    80002ca0:	639c                	ld	a5,0(a5)
    80002ca2:	c789                	beqz	a5,80002cac <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002ca4:	9782                	jalr	a5
    80002ca6:	06a93823          	sd	a0,112(s2)
    80002caa:	a839                	j	80002cc8 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002cac:	15848613          	addi	a2,s1,344
    80002cb0:	588c                	lw	a1,48(s1)
    80002cb2:	00005517          	auipc	a0,0x5
    80002cb6:	77650513          	addi	a0,a0,1910 # 80008428 <states.0+0x168>
    80002cba:	ffffe097          	auipc	ra,0xffffe
    80002cbe:	8c8080e7          	jalr	-1848(ra) # 80000582 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002cc2:	6cbc                	ld	a5,88(s1)
    80002cc4:	577d                	li	a4,-1
    80002cc6:	fbb8                	sd	a4,112(a5)
  }
}
    80002cc8:	60e2                	ld	ra,24(sp)
    80002cca:	6442                	ld	s0,16(sp)
    80002ccc:	64a2                	ld	s1,8(sp)
    80002cce:	6902                	ld	s2,0(sp)
    80002cd0:	6105                	addi	sp,sp,32
    80002cd2:	8082                	ret

0000000080002cd4 <sys_exit>:
#include "proc.h"
#include "kernel/semaphore.h"

uint64
sys_exit(void)
{
    80002cd4:	1101                	addi	sp,sp,-32
    80002cd6:	ec06                	sd	ra,24(sp)
    80002cd8:	e822                	sd	s0,16(sp)
    80002cda:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002cdc:	fec40593          	addi	a1,s0,-20
    80002ce0:	4501                	li	a0,0
    80002ce2:	00000097          	auipc	ra,0x0
    80002ce6:	f12080e7          	jalr	-238(ra) # 80002bf4 <argint>
    return -1;
    80002cea:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002cec:	00054963          	bltz	a0,80002cfe <sys_exit+0x2a>
  exit(n);
    80002cf0:	fec42503          	lw	a0,-20(s0)
    80002cf4:	fffff097          	auipc	ra,0xfffff
    80002cf8:	5be080e7          	jalr	1470(ra) # 800022b2 <exit>
  return 0;  // not reached
    80002cfc:	4781                	li	a5,0
}
    80002cfe:	853e                	mv	a0,a5
    80002d00:	60e2                	ld	ra,24(sp)
    80002d02:	6442                	ld	s0,16(sp)
    80002d04:	6105                	addi	sp,sp,32
    80002d06:	8082                	ret

0000000080002d08 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d08:	1141                	addi	sp,sp,-16
    80002d0a:	e406                	sd	ra,8(sp)
    80002d0c:	e022                	sd	s0,0(sp)
    80002d0e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d10:	fffff097          	auipc	ra,0xfffff
    80002d14:	c86080e7          	jalr	-890(ra) # 80001996 <myproc>
}
    80002d18:	5908                	lw	a0,48(a0)
    80002d1a:	60a2                	ld	ra,8(sp)
    80002d1c:	6402                	ld	s0,0(sp)
    80002d1e:	0141                	addi	sp,sp,16
    80002d20:	8082                	ret

0000000080002d22 <sys_fork>:

uint64
sys_fork(void)
{
    80002d22:	1141                	addi	sp,sp,-16
    80002d24:	e406                	sd	ra,8(sp)
    80002d26:	e022                	sd	s0,0(sp)
    80002d28:	0800                	addi	s0,sp,16
  return fork();
    80002d2a:	fffff097          	auipc	ra,0xfffff
    80002d2e:	03a080e7          	jalr	58(ra) # 80001d64 <fork>
}
    80002d32:	60a2                	ld	ra,8(sp)
    80002d34:	6402                	ld	s0,0(sp)
    80002d36:	0141                	addi	sp,sp,16
    80002d38:	8082                	ret

0000000080002d3a <sys_wait>:

uint64
sys_wait(void)
{
    80002d3a:	1101                	addi	sp,sp,-32
    80002d3c:	ec06                	sd	ra,24(sp)
    80002d3e:	e822                	sd	s0,16(sp)
    80002d40:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002d42:	fe840593          	addi	a1,s0,-24
    80002d46:	4501                	li	a0,0
    80002d48:	00000097          	auipc	ra,0x0
    80002d4c:	ece080e7          	jalr	-306(ra) # 80002c16 <argaddr>
    80002d50:	87aa                	mv	a5,a0
    return -1;
    80002d52:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002d54:	0007c863          	bltz	a5,80002d64 <sys_wait+0x2a>
  return wait(p);
    80002d58:	fe843503          	ld	a0,-24(s0)
    80002d5c:	fffff097          	auipc	ra,0xfffff
    80002d60:	35e080e7          	jalr	862(ra) # 800020ba <wait>
}
    80002d64:	60e2                	ld	ra,24(sp)
    80002d66:	6442                	ld	s0,16(sp)
    80002d68:	6105                	addi	sp,sp,32
    80002d6a:	8082                	ret

0000000080002d6c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d6c:	7179                	addi	sp,sp,-48
    80002d6e:	f406                	sd	ra,40(sp)
    80002d70:	f022                	sd	s0,32(sp)
    80002d72:	ec26                	sd	s1,24(sp)
    80002d74:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002d76:	fdc40593          	addi	a1,s0,-36
    80002d7a:	4501                	li	a0,0
    80002d7c:	00000097          	auipc	ra,0x0
    80002d80:	e78080e7          	jalr	-392(ra) # 80002bf4 <argint>
    return -1;
    80002d84:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002d86:	00054f63          	bltz	a0,80002da4 <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002d8a:	fffff097          	auipc	ra,0xfffff
    80002d8e:	c0c080e7          	jalr	-1012(ra) # 80001996 <myproc>
    80002d92:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002d94:	fdc42503          	lw	a0,-36(s0)
    80002d98:	fffff097          	auipc	ra,0xfffff
    80002d9c:	f58080e7          	jalr	-168(ra) # 80001cf0 <growproc>
    80002da0:	00054863          	bltz	a0,80002db0 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002da4:	8526                	mv	a0,s1
    80002da6:	70a2                	ld	ra,40(sp)
    80002da8:	7402                	ld	s0,32(sp)
    80002daa:	64e2                	ld	s1,24(sp)
    80002dac:	6145                	addi	sp,sp,48
    80002dae:	8082                	ret
    return -1;
    80002db0:	54fd                	li	s1,-1
    80002db2:	bfcd                	j	80002da4 <sys_sbrk+0x38>

0000000080002db4 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002db4:	7139                	addi	sp,sp,-64
    80002db6:	fc06                	sd	ra,56(sp)
    80002db8:	f822                	sd	s0,48(sp)
    80002dba:	f426                	sd	s1,40(sp)
    80002dbc:	f04a                	sd	s2,32(sp)
    80002dbe:	ec4e                	sd	s3,24(sp)
    80002dc0:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002dc2:	fcc40593          	addi	a1,s0,-52
    80002dc6:	4501                	li	a0,0
    80002dc8:	00000097          	auipc	ra,0x0
    80002dcc:	e2c080e7          	jalr	-468(ra) # 80002bf4 <argint>
    return -1;
    80002dd0:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002dd2:	06054563          	bltz	a0,80002e3c <sys_sleep+0x88>
  acquire(&tickslock);
    80002dd6:	00014517          	auipc	a0,0x14
    80002dda:	2fa50513          	addi	a0,a0,762 # 800170d0 <tickslock>
    80002dde:	ffffe097          	auipc	ra,0xffffe
    80002de2:	df2080e7          	jalr	-526(ra) # 80000bd0 <acquire>
  ticks0 = ticks;
    80002de6:	00006917          	auipc	s2,0x6
    80002dea:	24a92903          	lw	s2,586(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002dee:	fcc42783          	lw	a5,-52(s0)
    80002df2:	cf85                	beqz	a5,80002e2a <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002df4:	00014997          	auipc	s3,0x14
    80002df8:	2dc98993          	addi	s3,s3,732 # 800170d0 <tickslock>
    80002dfc:	00006497          	auipc	s1,0x6
    80002e00:	23448493          	addi	s1,s1,564 # 80009030 <ticks>
    if(myproc()->killed){
    80002e04:	fffff097          	auipc	ra,0xfffff
    80002e08:	b92080e7          	jalr	-1134(ra) # 80001996 <myproc>
    80002e0c:	551c                	lw	a5,40(a0)
    80002e0e:	ef9d                	bnez	a5,80002e4c <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002e10:	85ce                	mv	a1,s3
    80002e12:	8526                	mv	a0,s1
    80002e14:	fffff097          	auipc	ra,0xfffff
    80002e18:	242080e7          	jalr	578(ra) # 80002056 <sleep>
  while(ticks - ticks0 < n){
    80002e1c:	409c                	lw	a5,0(s1)
    80002e1e:	412787bb          	subw	a5,a5,s2
    80002e22:	fcc42703          	lw	a4,-52(s0)
    80002e26:	fce7efe3          	bltu	a5,a4,80002e04 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002e2a:	00014517          	auipc	a0,0x14
    80002e2e:	2a650513          	addi	a0,a0,678 # 800170d0 <tickslock>
    80002e32:	ffffe097          	auipc	ra,0xffffe
    80002e36:	e52080e7          	jalr	-430(ra) # 80000c84 <release>
  return 0;
    80002e3a:	4781                	li	a5,0
}
    80002e3c:	853e                	mv	a0,a5
    80002e3e:	70e2                	ld	ra,56(sp)
    80002e40:	7442                	ld	s0,48(sp)
    80002e42:	74a2                	ld	s1,40(sp)
    80002e44:	7902                	ld	s2,32(sp)
    80002e46:	69e2                	ld	s3,24(sp)
    80002e48:	6121                	addi	sp,sp,64
    80002e4a:	8082                	ret
      release(&tickslock);
    80002e4c:	00014517          	auipc	a0,0x14
    80002e50:	28450513          	addi	a0,a0,644 # 800170d0 <tickslock>
    80002e54:	ffffe097          	auipc	ra,0xffffe
    80002e58:	e30080e7          	jalr	-464(ra) # 80000c84 <release>
      return -1;
    80002e5c:	57fd                	li	a5,-1
    80002e5e:	bff9                	j	80002e3c <sys_sleep+0x88>

0000000080002e60 <sys_kill>:

uint64
sys_kill(void)
{
    80002e60:	1101                	addi	sp,sp,-32
    80002e62:	ec06                	sd	ra,24(sp)
    80002e64:	e822                	sd	s0,16(sp)
    80002e66:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002e68:	fec40593          	addi	a1,s0,-20
    80002e6c:	4501                	li	a0,0
    80002e6e:	00000097          	auipc	ra,0x0
    80002e72:	d86080e7          	jalr	-634(ra) # 80002bf4 <argint>
    80002e76:	87aa                	mv	a5,a0
    return -1;
    80002e78:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002e7a:	0007c863          	bltz	a5,80002e8a <sys_kill+0x2a>
  return kill(pid);
    80002e7e:	fec42503          	lw	a0,-20(s0)
    80002e82:	fffff097          	auipc	ra,0xfffff
    80002e86:	506080e7          	jalr	1286(ra) # 80002388 <kill>
}
    80002e8a:	60e2                	ld	ra,24(sp)
    80002e8c:	6442                	ld	s0,16(sp)
    80002e8e:	6105                	addi	sp,sp,32
    80002e90:	8082                	ret

0000000080002e92 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e92:	1101                	addi	sp,sp,-32
    80002e94:	ec06                	sd	ra,24(sp)
    80002e96:	e822                	sd	s0,16(sp)
    80002e98:	e426                	sd	s1,8(sp)
    80002e9a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e9c:	00014517          	auipc	a0,0x14
    80002ea0:	23450513          	addi	a0,a0,564 # 800170d0 <tickslock>
    80002ea4:	ffffe097          	auipc	ra,0xffffe
    80002ea8:	d2c080e7          	jalr	-724(ra) # 80000bd0 <acquire>
  xticks = ticks;
    80002eac:	00006497          	auipc	s1,0x6
    80002eb0:	1844a483          	lw	s1,388(s1) # 80009030 <ticks>
  release(&tickslock);
    80002eb4:	00014517          	auipc	a0,0x14
    80002eb8:	21c50513          	addi	a0,a0,540 # 800170d0 <tickslock>
    80002ebc:	ffffe097          	auipc	ra,0xffffe
    80002ec0:	dc8080e7          	jalr	-568(ra) # 80000c84 <release>
  return xticks;
}
    80002ec4:	02049513          	slli	a0,s1,0x20
    80002ec8:	9101                	srli	a0,a0,0x20
    80002eca:	60e2                	ld	ra,24(sp)
    80002ecc:	6442                	ld	s0,16(sp)
    80002ece:	64a2                	ld	s1,8(sp)
    80002ed0:	6105                	addi	sp,sp,32
    80002ed2:	8082                	ret

0000000080002ed4 <sys_sematest>:
// Aidan Darlington
// Student ID: 21134427
// Assignment 1 Additions
int
sys_sematest(void)
{
    80002ed4:	1101                	addi	sp,sp,-32
    80002ed6:	ec06                	sd	ra,24(sp)
    80002ed8:	e822                	sd	s0,16(sp)
    80002eda:	1000                	addi	s0,sp,32
  static struct semaphore lk; // Static semaphore variable
  int cmd, ret = 0; // Command and return value initialization
  
  if(argint(0, &cmd) < 0) // Retrieve the command argument
    80002edc:	fec40593          	addi	a1,s0,-20
    80002ee0:	4501                	li	a0,0
    80002ee2:	00000097          	auipc	ra,0x0
    80002ee6:	d12080e7          	jalr	-750(ra) # 80002bf4 <argint>
    80002eea:	04054d63          	bltz	a0,80002f44 <sys_sematest+0x70>
  return -1;

  switch(cmd) {
    80002eee:	fec42783          	lw	a5,-20(s0)
    80002ef2:	4705                	li	a4,1
    80002ef4:	02e78663          	beq	a5,a4,80002f20 <sys_sematest+0x4c>
    80002ef8:	4709                	li	a4,2
    80002efa:	02e78c63          	beq	a5,a4,80002f32 <sys_sematest+0x5e>
    80002efe:	4501                	li	a0,0
    80002f00:	c789                	beqz	a5,80002f0a <sys_sematest+0x36>
  case 0: initsema(&lk, 5); ret = 5; break; // Initialize semaphore with value 5
  case 1: ret = downsema(&lk); break; // Perform down operation on semaphore
  case 2: ret = upsema(&lk); break; // Perform up operation on semaphore
  }
  return ret; // Return the result of the operation
}
    80002f02:	60e2                	ld	ra,24(sp)
    80002f04:	6442                	ld	s0,16(sp)
    80002f06:	6105                	addi	sp,sp,32
    80002f08:	8082                	ret
  case 0: initsema(&lk, 5); ret = 5; break; // Initialize semaphore with value 5
    80002f0a:	4595                	li	a1,5
    80002f0c:	00014517          	auipc	a0,0x14
    80002f10:	1dc50513          	addi	a0,a0,476 # 800170e8 <lk.1>
    80002f14:	00000097          	auipc	ra,0x0
    80002f18:	a30080e7          	jalr	-1488(ra) # 80002944 <initsema>
    80002f1c:	4515                	li	a0,5
    80002f1e:	b7d5                	j	80002f02 <sys_sematest+0x2e>
  case 1: ret = downsema(&lk); break; // Perform down operation on semaphore
    80002f20:	00014517          	auipc	a0,0x14
    80002f24:	1c850513          	addi	a0,a0,456 # 800170e8 <lk.1>
    80002f28:	00000097          	auipc	ra,0x0
    80002f2c:	a40080e7          	jalr	-1472(ra) # 80002968 <downsema>
    80002f30:	bfc9                	j	80002f02 <sys_sematest+0x2e>
  case 2: ret = upsema(&lk); break; // Perform up operation on semaphore
    80002f32:	00014517          	auipc	a0,0x14
    80002f36:	1b650513          	addi	a0,a0,438 # 800170e8 <lk.1>
    80002f3a:	00000097          	auipc	ra,0x0
    80002f3e:	a7e080e7          	jalr	-1410(ra) # 800029b8 <upsema>
    80002f42:	b7c1                	j	80002f02 <sys_sematest+0x2e>
  return -1;
    80002f44:	557d                	li	a0,-1
    80002f46:	bf75                	j	80002f02 <sys_sematest+0x2e>

0000000080002f48 <sys_rwsematest>:
  
int
sys_rwsematest(void)
{
    80002f48:	7179                	addi	sp,sp,-48
    80002f4a:	f406                	sd	ra,40(sp)
    80002f4c:	f022                	sd	s0,32(sp)
    80002f4e:	ec26                	sd	s1,24(sp)
    80002f50:	1800                	addi	s0,sp,48
  static struct rwsemaphore lk; // Static read-write semaphore variable
  int cmd, ret = 0; // Command and return value initialization

  if(argint(0, &cmd) < 0) // Retrieve the command argument
    80002f52:	fdc40593          	addi	a1,s0,-36
    80002f56:	4501                	li	a0,0
    80002f58:	00000097          	auipc	ra,0x0
    80002f5c:	c9c080e7          	jalr	-868(ra) # 80002bf4 <argint>
    80002f60:	08054763          	bltz	a0,80002fee <sys_rwsematest+0xa6>
  return -1;

  switch(cmd) {
    80002f64:	fdc42483          	lw	s1,-36(s0)
    80002f68:	4791                	li	a5,4
    80002f6a:	0897e463          	bltu	a5,s1,80002ff2 <sys_rwsematest+0xaa>
    80002f6e:	00249713          	slli	a4,s1,0x2
    80002f72:	00005697          	auipc	a3,0x5
    80002f76:	5ae68693          	addi	a3,a3,1454 # 80008520 <syscalls+0xc0>
    80002f7a:	9736                	add	a4,a4,a3
    80002f7c:	431c                	lw	a5,0(a4)
    80002f7e:	97b6                	add	a5,a5,a3
    80002f80:	8782                	jr	a5
  case 0: initrwsema(&lk); break; // Initialize read-write semaphore
    80002f82:	00014517          	auipc	a0,0x14
    80002f86:	18650513          	addi	a0,a0,390 # 80017108 <lk.0>
    80002f8a:	00000097          	auipc	ra,0x0
    80002f8e:	a72080e7          	jalr	-1422(ra) # 800029fc <initrwsema>
  case 2: ret = upreadsema(&lk); break; // Perform up read operation on semaphore
  case 3: downwritesema(&lk); break; // Perform down write operation on semaphore
  case 4: upwritesema(&lk); break; // Perform up write operation on semaphore
  }
  return ret; // Return the result of the operation
}
    80002f92:	8526                	mv	a0,s1
    80002f94:	70a2                	ld	ra,40(sp)
    80002f96:	7402                	ld	s0,32(sp)
    80002f98:	64e2                	ld	s1,24(sp)
    80002f9a:	6145                	addi	sp,sp,48
    80002f9c:	8082                	ret
  case 1: ret = downreadsema(&lk); break; // Perform down read operation on semaphore
    80002f9e:	00014517          	auipc	a0,0x14
    80002fa2:	16a50513          	addi	a0,a0,362 # 80017108 <lk.0>
    80002fa6:	00000097          	auipc	ra,0x0
    80002faa:	a88080e7          	jalr	-1400(ra) # 80002a2e <downreadsema>
    80002fae:	84aa                	mv	s1,a0
    80002fb0:	b7cd                	j	80002f92 <sys_rwsematest+0x4a>
  case 2: ret = upreadsema(&lk); break; // Perform up read operation on semaphore
    80002fb2:	00014517          	auipc	a0,0x14
    80002fb6:	15650513          	addi	a0,a0,342 # 80017108 <lk.0>
    80002fba:	00000097          	auipc	ra,0x0
    80002fbe:	abc080e7          	jalr	-1348(ra) # 80002a76 <upreadsema>
    80002fc2:	84aa                	mv	s1,a0
    80002fc4:	b7f9                	j	80002f92 <sys_rwsematest+0x4a>
  case 3: downwritesema(&lk); break; // Perform down write operation on semaphore
    80002fc6:	00014517          	auipc	a0,0x14
    80002fca:	14250513          	addi	a0,a0,322 # 80017108 <lk.0>
    80002fce:	00000097          	auipc	ra,0x0
    80002fd2:	aec080e7          	jalr	-1300(ra) # 80002aba <downwritesema>
  int cmd, ret = 0; // Command and return value initialization
    80002fd6:	4481                	li	s1,0
  case 3: downwritesema(&lk); break; // Perform down write operation on semaphore
    80002fd8:	bf6d                	j	80002f92 <sys_rwsematest+0x4a>
  case 4: upwritesema(&lk); break; // Perform up write operation on semaphore
    80002fda:	00014517          	auipc	a0,0x14
    80002fde:	12e50513          	addi	a0,a0,302 # 80017108 <lk.0>
    80002fe2:	00000097          	auipc	ra,0x0
    80002fe6:	af4080e7          	jalr	-1292(ra) # 80002ad6 <upwritesema>
  int cmd, ret = 0; // Command and return value initialization
    80002fea:	4481                	li	s1,0
  case 4: upwritesema(&lk); break; // Perform up write operation on semaphore
    80002fec:	b75d                	j	80002f92 <sys_rwsematest+0x4a>
  return -1;
    80002fee:	54fd                	li	s1,-1
    80002ff0:	b74d                	j	80002f92 <sys_rwsematest+0x4a>
  switch(cmd) {
    80002ff2:	4481                	li	s1,0
    80002ff4:	bf79                	j	80002f92 <sys_rwsematest+0x4a>

0000000080002ff6 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002ff6:	7179                	addi	sp,sp,-48
    80002ff8:	f406                	sd	ra,40(sp)
    80002ffa:	f022                	sd	s0,32(sp)
    80002ffc:	ec26                	sd	s1,24(sp)
    80002ffe:	e84a                	sd	s2,16(sp)
    80003000:	e44e                	sd	s3,8(sp)
    80003002:	e052                	sd	s4,0(sp)
    80003004:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003006:	00005597          	auipc	a1,0x5
    8000300a:	53258593          	addi	a1,a1,1330 # 80008538 <syscalls+0xd8>
    8000300e:	00014517          	auipc	a0,0x14
    80003012:	14250513          	addi	a0,a0,322 # 80017150 <bcache>
    80003016:	ffffe097          	auipc	ra,0xffffe
    8000301a:	b2a080e7          	jalr	-1238(ra) # 80000b40 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000301e:	0001c797          	auipc	a5,0x1c
    80003022:	13278793          	addi	a5,a5,306 # 8001f150 <bcache+0x8000>
    80003026:	0001c717          	auipc	a4,0x1c
    8000302a:	39270713          	addi	a4,a4,914 # 8001f3b8 <bcache+0x8268>
    8000302e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003032:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003036:	00014497          	auipc	s1,0x14
    8000303a:	13248493          	addi	s1,s1,306 # 80017168 <bcache+0x18>
    b->next = bcache.head.next;
    8000303e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003040:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003042:	00005a17          	auipc	s4,0x5
    80003046:	4fea0a13          	addi	s4,s4,1278 # 80008540 <syscalls+0xe0>
    b->next = bcache.head.next;
    8000304a:	2b893783          	ld	a5,696(s2)
    8000304e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003050:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003054:	85d2                	mv	a1,s4
    80003056:	01048513          	addi	a0,s1,16
    8000305a:	00001097          	auipc	ra,0x1
    8000305e:	4bc080e7          	jalr	1212(ra) # 80004516 <initsleeplock>
    bcache.head.next->prev = b;
    80003062:	2b893783          	ld	a5,696(s2)
    80003066:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003068:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000306c:	45848493          	addi	s1,s1,1112
    80003070:	fd349de3          	bne	s1,s3,8000304a <binit+0x54>
  }
}
    80003074:	70a2                	ld	ra,40(sp)
    80003076:	7402                	ld	s0,32(sp)
    80003078:	64e2                	ld	s1,24(sp)
    8000307a:	6942                	ld	s2,16(sp)
    8000307c:	69a2                	ld	s3,8(sp)
    8000307e:	6a02                	ld	s4,0(sp)
    80003080:	6145                	addi	sp,sp,48
    80003082:	8082                	ret

0000000080003084 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003084:	7179                	addi	sp,sp,-48
    80003086:	f406                	sd	ra,40(sp)
    80003088:	f022                	sd	s0,32(sp)
    8000308a:	ec26                	sd	s1,24(sp)
    8000308c:	e84a                	sd	s2,16(sp)
    8000308e:	e44e                	sd	s3,8(sp)
    80003090:	1800                	addi	s0,sp,48
    80003092:	892a                	mv	s2,a0
    80003094:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003096:	00014517          	auipc	a0,0x14
    8000309a:	0ba50513          	addi	a0,a0,186 # 80017150 <bcache>
    8000309e:	ffffe097          	auipc	ra,0xffffe
    800030a2:	b32080e7          	jalr	-1230(ra) # 80000bd0 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800030a6:	0001c497          	auipc	s1,0x1c
    800030aa:	3624b483          	ld	s1,866(s1) # 8001f408 <bcache+0x82b8>
    800030ae:	0001c797          	auipc	a5,0x1c
    800030b2:	30a78793          	addi	a5,a5,778 # 8001f3b8 <bcache+0x8268>
    800030b6:	02f48f63          	beq	s1,a5,800030f4 <bread+0x70>
    800030ba:	873e                	mv	a4,a5
    800030bc:	a021                	j	800030c4 <bread+0x40>
    800030be:	68a4                	ld	s1,80(s1)
    800030c0:	02e48a63          	beq	s1,a4,800030f4 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800030c4:	449c                	lw	a5,8(s1)
    800030c6:	ff279ce3          	bne	a5,s2,800030be <bread+0x3a>
    800030ca:	44dc                	lw	a5,12(s1)
    800030cc:	ff3799e3          	bne	a5,s3,800030be <bread+0x3a>
      b->refcnt++;
    800030d0:	40bc                	lw	a5,64(s1)
    800030d2:	2785                	addiw	a5,a5,1
    800030d4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030d6:	00014517          	auipc	a0,0x14
    800030da:	07a50513          	addi	a0,a0,122 # 80017150 <bcache>
    800030de:	ffffe097          	auipc	ra,0xffffe
    800030e2:	ba6080e7          	jalr	-1114(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    800030e6:	01048513          	addi	a0,s1,16
    800030ea:	00001097          	auipc	ra,0x1
    800030ee:	466080e7          	jalr	1126(ra) # 80004550 <acquiresleep>
      return b;
    800030f2:	a8b9                	j	80003150 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030f4:	0001c497          	auipc	s1,0x1c
    800030f8:	30c4b483          	ld	s1,780(s1) # 8001f400 <bcache+0x82b0>
    800030fc:	0001c797          	auipc	a5,0x1c
    80003100:	2bc78793          	addi	a5,a5,700 # 8001f3b8 <bcache+0x8268>
    80003104:	00f48863          	beq	s1,a5,80003114 <bread+0x90>
    80003108:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000310a:	40bc                	lw	a5,64(s1)
    8000310c:	cf81                	beqz	a5,80003124 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000310e:	64a4                	ld	s1,72(s1)
    80003110:	fee49de3          	bne	s1,a4,8000310a <bread+0x86>
  panic("bget: no buffers");
    80003114:	00005517          	auipc	a0,0x5
    80003118:	43450513          	addi	a0,a0,1076 # 80008548 <syscalls+0xe8>
    8000311c:	ffffd097          	auipc	ra,0xffffd
    80003120:	41c080e7          	jalr	1052(ra) # 80000538 <panic>
      b->dev = dev;
    80003124:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003128:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000312c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003130:	4785                	li	a5,1
    80003132:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003134:	00014517          	auipc	a0,0x14
    80003138:	01c50513          	addi	a0,a0,28 # 80017150 <bcache>
    8000313c:	ffffe097          	auipc	ra,0xffffe
    80003140:	b48080e7          	jalr	-1208(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    80003144:	01048513          	addi	a0,s1,16
    80003148:	00001097          	auipc	ra,0x1
    8000314c:	408080e7          	jalr	1032(ra) # 80004550 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003150:	409c                	lw	a5,0(s1)
    80003152:	cb89                	beqz	a5,80003164 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003154:	8526                	mv	a0,s1
    80003156:	70a2                	ld	ra,40(sp)
    80003158:	7402                	ld	s0,32(sp)
    8000315a:	64e2                	ld	s1,24(sp)
    8000315c:	6942                	ld	s2,16(sp)
    8000315e:	69a2                	ld	s3,8(sp)
    80003160:	6145                	addi	sp,sp,48
    80003162:	8082                	ret
    virtio_disk_rw(b, 0);
    80003164:	4581                	li	a1,0
    80003166:	8526                	mv	a0,s1
    80003168:	00003097          	auipc	ra,0x3
    8000316c:	f1e080e7          	jalr	-226(ra) # 80006086 <virtio_disk_rw>
    b->valid = 1;
    80003170:	4785                	li	a5,1
    80003172:	c09c                	sw	a5,0(s1)
  return b;
    80003174:	b7c5                	j	80003154 <bread+0xd0>

0000000080003176 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003176:	1101                	addi	sp,sp,-32
    80003178:	ec06                	sd	ra,24(sp)
    8000317a:	e822                	sd	s0,16(sp)
    8000317c:	e426                	sd	s1,8(sp)
    8000317e:	1000                	addi	s0,sp,32
    80003180:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003182:	0541                	addi	a0,a0,16
    80003184:	00001097          	auipc	ra,0x1
    80003188:	466080e7          	jalr	1126(ra) # 800045ea <holdingsleep>
    8000318c:	cd01                	beqz	a0,800031a4 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000318e:	4585                	li	a1,1
    80003190:	8526                	mv	a0,s1
    80003192:	00003097          	auipc	ra,0x3
    80003196:	ef4080e7          	jalr	-268(ra) # 80006086 <virtio_disk_rw>
}
    8000319a:	60e2                	ld	ra,24(sp)
    8000319c:	6442                	ld	s0,16(sp)
    8000319e:	64a2                	ld	s1,8(sp)
    800031a0:	6105                	addi	sp,sp,32
    800031a2:	8082                	ret
    panic("bwrite");
    800031a4:	00005517          	auipc	a0,0x5
    800031a8:	3bc50513          	addi	a0,a0,956 # 80008560 <syscalls+0x100>
    800031ac:	ffffd097          	auipc	ra,0xffffd
    800031b0:	38c080e7          	jalr	908(ra) # 80000538 <panic>

00000000800031b4 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800031b4:	1101                	addi	sp,sp,-32
    800031b6:	ec06                	sd	ra,24(sp)
    800031b8:	e822                	sd	s0,16(sp)
    800031ba:	e426                	sd	s1,8(sp)
    800031bc:	e04a                	sd	s2,0(sp)
    800031be:	1000                	addi	s0,sp,32
    800031c0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031c2:	01050913          	addi	s2,a0,16
    800031c6:	854a                	mv	a0,s2
    800031c8:	00001097          	auipc	ra,0x1
    800031cc:	422080e7          	jalr	1058(ra) # 800045ea <holdingsleep>
    800031d0:	c92d                	beqz	a0,80003242 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800031d2:	854a                	mv	a0,s2
    800031d4:	00001097          	auipc	ra,0x1
    800031d8:	3d2080e7          	jalr	978(ra) # 800045a6 <releasesleep>

  acquire(&bcache.lock);
    800031dc:	00014517          	auipc	a0,0x14
    800031e0:	f7450513          	addi	a0,a0,-140 # 80017150 <bcache>
    800031e4:	ffffe097          	auipc	ra,0xffffe
    800031e8:	9ec080e7          	jalr	-1556(ra) # 80000bd0 <acquire>
  b->refcnt--;
    800031ec:	40bc                	lw	a5,64(s1)
    800031ee:	37fd                	addiw	a5,a5,-1
    800031f0:	0007871b          	sext.w	a4,a5
    800031f4:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800031f6:	eb05                	bnez	a4,80003226 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800031f8:	68bc                	ld	a5,80(s1)
    800031fa:	64b8                	ld	a4,72(s1)
    800031fc:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800031fe:	64bc                	ld	a5,72(s1)
    80003200:	68b8                	ld	a4,80(s1)
    80003202:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003204:	0001c797          	auipc	a5,0x1c
    80003208:	f4c78793          	addi	a5,a5,-180 # 8001f150 <bcache+0x8000>
    8000320c:	2b87b703          	ld	a4,696(a5)
    80003210:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003212:	0001c717          	auipc	a4,0x1c
    80003216:	1a670713          	addi	a4,a4,422 # 8001f3b8 <bcache+0x8268>
    8000321a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000321c:	2b87b703          	ld	a4,696(a5)
    80003220:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003222:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003226:	00014517          	auipc	a0,0x14
    8000322a:	f2a50513          	addi	a0,a0,-214 # 80017150 <bcache>
    8000322e:	ffffe097          	auipc	ra,0xffffe
    80003232:	a56080e7          	jalr	-1450(ra) # 80000c84 <release>
}
    80003236:	60e2                	ld	ra,24(sp)
    80003238:	6442                	ld	s0,16(sp)
    8000323a:	64a2                	ld	s1,8(sp)
    8000323c:	6902                	ld	s2,0(sp)
    8000323e:	6105                	addi	sp,sp,32
    80003240:	8082                	ret
    panic("brelse");
    80003242:	00005517          	auipc	a0,0x5
    80003246:	32650513          	addi	a0,a0,806 # 80008568 <syscalls+0x108>
    8000324a:	ffffd097          	auipc	ra,0xffffd
    8000324e:	2ee080e7          	jalr	750(ra) # 80000538 <panic>

0000000080003252 <bpin>:

void
bpin(struct buf *b) {
    80003252:	1101                	addi	sp,sp,-32
    80003254:	ec06                	sd	ra,24(sp)
    80003256:	e822                	sd	s0,16(sp)
    80003258:	e426                	sd	s1,8(sp)
    8000325a:	1000                	addi	s0,sp,32
    8000325c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000325e:	00014517          	auipc	a0,0x14
    80003262:	ef250513          	addi	a0,a0,-270 # 80017150 <bcache>
    80003266:	ffffe097          	auipc	ra,0xffffe
    8000326a:	96a080e7          	jalr	-1686(ra) # 80000bd0 <acquire>
  b->refcnt++;
    8000326e:	40bc                	lw	a5,64(s1)
    80003270:	2785                	addiw	a5,a5,1
    80003272:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003274:	00014517          	auipc	a0,0x14
    80003278:	edc50513          	addi	a0,a0,-292 # 80017150 <bcache>
    8000327c:	ffffe097          	auipc	ra,0xffffe
    80003280:	a08080e7          	jalr	-1528(ra) # 80000c84 <release>
}
    80003284:	60e2                	ld	ra,24(sp)
    80003286:	6442                	ld	s0,16(sp)
    80003288:	64a2                	ld	s1,8(sp)
    8000328a:	6105                	addi	sp,sp,32
    8000328c:	8082                	ret

000000008000328e <bunpin>:

void
bunpin(struct buf *b) {
    8000328e:	1101                	addi	sp,sp,-32
    80003290:	ec06                	sd	ra,24(sp)
    80003292:	e822                	sd	s0,16(sp)
    80003294:	e426                	sd	s1,8(sp)
    80003296:	1000                	addi	s0,sp,32
    80003298:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000329a:	00014517          	auipc	a0,0x14
    8000329e:	eb650513          	addi	a0,a0,-330 # 80017150 <bcache>
    800032a2:	ffffe097          	auipc	ra,0xffffe
    800032a6:	92e080e7          	jalr	-1746(ra) # 80000bd0 <acquire>
  b->refcnt--;
    800032aa:	40bc                	lw	a5,64(s1)
    800032ac:	37fd                	addiw	a5,a5,-1
    800032ae:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032b0:	00014517          	auipc	a0,0x14
    800032b4:	ea050513          	addi	a0,a0,-352 # 80017150 <bcache>
    800032b8:	ffffe097          	auipc	ra,0xffffe
    800032bc:	9cc080e7          	jalr	-1588(ra) # 80000c84 <release>
}
    800032c0:	60e2                	ld	ra,24(sp)
    800032c2:	6442                	ld	s0,16(sp)
    800032c4:	64a2                	ld	s1,8(sp)
    800032c6:	6105                	addi	sp,sp,32
    800032c8:	8082                	ret

00000000800032ca <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800032ca:	1101                	addi	sp,sp,-32
    800032cc:	ec06                	sd	ra,24(sp)
    800032ce:	e822                	sd	s0,16(sp)
    800032d0:	e426                	sd	s1,8(sp)
    800032d2:	e04a                	sd	s2,0(sp)
    800032d4:	1000                	addi	s0,sp,32
    800032d6:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800032d8:	00d5d59b          	srliw	a1,a1,0xd
    800032dc:	0001c797          	auipc	a5,0x1c
    800032e0:	5507a783          	lw	a5,1360(a5) # 8001f82c <sb+0x1c>
    800032e4:	9dbd                	addw	a1,a1,a5
    800032e6:	00000097          	auipc	ra,0x0
    800032ea:	d9e080e7          	jalr	-610(ra) # 80003084 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800032ee:	0074f713          	andi	a4,s1,7
    800032f2:	4785                	li	a5,1
    800032f4:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800032f8:	14ce                	slli	s1,s1,0x33
    800032fa:	90d9                	srli	s1,s1,0x36
    800032fc:	00950733          	add	a4,a0,s1
    80003300:	05874703          	lbu	a4,88(a4)
    80003304:	00e7f6b3          	and	a3,a5,a4
    80003308:	c69d                	beqz	a3,80003336 <bfree+0x6c>
    8000330a:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000330c:	94aa                	add	s1,s1,a0
    8000330e:	fff7c793          	not	a5,a5
    80003312:	8ff9                	and	a5,a5,a4
    80003314:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003318:	00001097          	auipc	ra,0x1
    8000331c:	118080e7          	jalr	280(ra) # 80004430 <log_write>
  brelse(bp);
    80003320:	854a                	mv	a0,s2
    80003322:	00000097          	auipc	ra,0x0
    80003326:	e92080e7          	jalr	-366(ra) # 800031b4 <brelse>
}
    8000332a:	60e2                	ld	ra,24(sp)
    8000332c:	6442                	ld	s0,16(sp)
    8000332e:	64a2                	ld	s1,8(sp)
    80003330:	6902                	ld	s2,0(sp)
    80003332:	6105                	addi	sp,sp,32
    80003334:	8082                	ret
    panic("freeing free block");
    80003336:	00005517          	auipc	a0,0x5
    8000333a:	23a50513          	addi	a0,a0,570 # 80008570 <syscalls+0x110>
    8000333e:	ffffd097          	auipc	ra,0xffffd
    80003342:	1fa080e7          	jalr	506(ra) # 80000538 <panic>

0000000080003346 <balloc>:
{
    80003346:	711d                	addi	sp,sp,-96
    80003348:	ec86                	sd	ra,88(sp)
    8000334a:	e8a2                	sd	s0,80(sp)
    8000334c:	e4a6                	sd	s1,72(sp)
    8000334e:	e0ca                	sd	s2,64(sp)
    80003350:	fc4e                	sd	s3,56(sp)
    80003352:	f852                	sd	s4,48(sp)
    80003354:	f456                	sd	s5,40(sp)
    80003356:	f05a                	sd	s6,32(sp)
    80003358:	ec5e                	sd	s7,24(sp)
    8000335a:	e862                	sd	s8,16(sp)
    8000335c:	e466                	sd	s9,8(sp)
    8000335e:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003360:	0001c797          	auipc	a5,0x1c
    80003364:	4b47a783          	lw	a5,1204(a5) # 8001f814 <sb+0x4>
    80003368:	cbd1                	beqz	a5,800033fc <balloc+0xb6>
    8000336a:	8baa                	mv	s7,a0
    8000336c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000336e:	0001cb17          	auipc	s6,0x1c
    80003372:	4a2b0b13          	addi	s6,s6,1186 # 8001f810 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003376:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003378:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000337a:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000337c:	6c89                	lui	s9,0x2
    8000337e:	a831                	j	8000339a <balloc+0x54>
    brelse(bp);
    80003380:	854a                	mv	a0,s2
    80003382:	00000097          	auipc	ra,0x0
    80003386:	e32080e7          	jalr	-462(ra) # 800031b4 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000338a:	015c87bb          	addw	a5,s9,s5
    8000338e:	00078a9b          	sext.w	s5,a5
    80003392:	004b2703          	lw	a4,4(s6)
    80003396:	06eaf363          	bgeu	s5,a4,800033fc <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000339a:	41fad79b          	sraiw	a5,s5,0x1f
    8000339e:	0137d79b          	srliw	a5,a5,0x13
    800033a2:	015787bb          	addw	a5,a5,s5
    800033a6:	40d7d79b          	sraiw	a5,a5,0xd
    800033aa:	01cb2583          	lw	a1,28(s6)
    800033ae:	9dbd                	addw	a1,a1,a5
    800033b0:	855e                	mv	a0,s7
    800033b2:	00000097          	auipc	ra,0x0
    800033b6:	cd2080e7          	jalr	-814(ra) # 80003084 <bread>
    800033ba:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033bc:	004b2503          	lw	a0,4(s6)
    800033c0:	000a849b          	sext.w	s1,s5
    800033c4:	8662                	mv	a2,s8
    800033c6:	faa4fde3          	bgeu	s1,a0,80003380 <balloc+0x3a>
      m = 1 << (bi % 8);
    800033ca:	41f6579b          	sraiw	a5,a2,0x1f
    800033ce:	01d7d69b          	srliw	a3,a5,0x1d
    800033d2:	00c6873b          	addw	a4,a3,a2
    800033d6:	00777793          	andi	a5,a4,7
    800033da:	9f95                	subw	a5,a5,a3
    800033dc:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800033e0:	4037571b          	sraiw	a4,a4,0x3
    800033e4:	00e906b3          	add	a3,s2,a4
    800033e8:	0586c683          	lbu	a3,88(a3)
    800033ec:	00d7f5b3          	and	a1,a5,a3
    800033f0:	cd91                	beqz	a1,8000340c <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033f2:	2605                	addiw	a2,a2,1
    800033f4:	2485                	addiw	s1,s1,1
    800033f6:	fd4618e3          	bne	a2,s4,800033c6 <balloc+0x80>
    800033fa:	b759                	j	80003380 <balloc+0x3a>
  panic("balloc: out of blocks");
    800033fc:	00005517          	auipc	a0,0x5
    80003400:	18c50513          	addi	a0,a0,396 # 80008588 <syscalls+0x128>
    80003404:	ffffd097          	auipc	ra,0xffffd
    80003408:	134080e7          	jalr	308(ra) # 80000538 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000340c:	974a                	add	a4,a4,s2
    8000340e:	8fd5                	or	a5,a5,a3
    80003410:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003414:	854a                	mv	a0,s2
    80003416:	00001097          	auipc	ra,0x1
    8000341a:	01a080e7          	jalr	26(ra) # 80004430 <log_write>
        brelse(bp);
    8000341e:	854a                	mv	a0,s2
    80003420:	00000097          	auipc	ra,0x0
    80003424:	d94080e7          	jalr	-620(ra) # 800031b4 <brelse>
  bp = bread(dev, bno);
    80003428:	85a6                	mv	a1,s1
    8000342a:	855e                	mv	a0,s7
    8000342c:	00000097          	auipc	ra,0x0
    80003430:	c58080e7          	jalr	-936(ra) # 80003084 <bread>
    80003434:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003436:	40000613          	li	a2,1024
    8000343a:	4581                	li	a1,0
    8000343c:	05850513          	addi	a0,a0,88
    80003440:	ffffe097          	auipc	ra,0xffffe
    80003444:	88c080e7          	jalr	-1908(ra) # 80000ccc <memset>
  log_write(bp);
    80003448:	854a                	mv	a0,s2
    8000344a:	00001097          	auipc	ra,0x1
    8000344e:	fe6080e7          	jalr	-26(ra) # 80004430 <log_write>
  brelse(bp);
    80003452:	854a                	mv	a0,s2
    80003454:	00000097          	auipc	ra,0x0
    80003458:	d60080e7          	jalr	-672(ra) # 800031b4 <brelse>
}
    8000345c:	8526                	mv	a0,s1
    8000345e:	60e6                	ld	ra,88(sp)
    80003460:	6446                	ld	s0,80(sp)
    80003462:	64a6                	ld	s1,72(sp)
    80003464:	6906                	ld	s2,64(sp)
    80003466:	79e2                	ld	s3,56(sp)
    80003468:	7a42                	ld	s4,48(sp)
    8000346a:	7aa2                	ld	s5,40(sp)
    8000346c:	7b02                	ld	s6,32(sp)
    8000346e:	6be2                	ld	s7,24(sp)
    80003470:	6c42                	ld	s8,16(sp)
    80003472:	6ca2                	ld	s9,8(sp)
    80003474:	6125                	addi	sp,sp,96
    80003476:	8082                	ret

0000000080003478 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003478:	7179                	addi	sp,sp,-48
    8000347a:	f406                	sd	ra,40(sp)
    8000347c:	f022                	sd	s0,32(sp)
    8000347e:	ec26                	sd	s1,24(sp)
    80003480:	e84a                	sd	s2,16(sp)
    80003482:	e44e                	sd	s3,8(sp)
    80003484:	e052                	sd	s4,0(sp)
    80003486:	1800                	addi	s0,sp,48
    80003488:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000348a:	47ad                	li	a5,11
    8000348c:	04b7fe63          	bgeu	a5,a1,800034e8 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003490:	ff45849b          	addiw	s1,a1,-12
    80003494:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003498:	0ff00793          	li	a5,255
    8000349c:	0ae7e363          	bltu	a5,a4,80003542 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800034a0:	08052583          	lw	a1,128(a0)
    800034a4:	c5ad                	beqz	a1,8000350e <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800034a6:	00092503          	lw	a0,0(s2)
    800034aa:	00000097          	auipc	ra,0x0
    800034ae:	bda080e7          	jalr	-1062(ra) # 80003084 <bread>
    800034b2:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800034b4:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800034b8:	02049593          	slli	a1,s1,0x20
    800034bc:	9181                	srli	a1,a1,0x20
    800034be:	058a                	slli	a1,a1,0x2
    800034c0:	00b784b3          	add	s1,a5,a1
    800034c4:	0004a983          	lw	s3,0(s1)
    800034c8:	04098d63          	beqz	s3,80003522 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800034cc:	8552                	mv	a0,s4
    800034ce:	00000097          	auipc	ra,0x0
    800034d2:	ce6080e7          	jalr	-794(ra) # 800031b4 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800034d6:	854e                	mv	a0,s3
    800034d8:	70a2                	ld	ra,40(sp)
    800034da:	7402                	ld	s0,32(sp)
    800034dc:	64e2                	ld	s1,24(sp)
    800034de:	6942                	ld	s2,16(sp)
    800034e0:	69a2                	ld	s3,8(sp)
    800034e2:	6a02                	ld	s4,0(sp)
    800034e4:	6145                	addi	sp,sp,48
    800034e6:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800034e8:	02059493          	slli	s1,a1,0x20
    800034ec:	9081                	srli	s1,s1,0x20
    800034ee:	048a                	slli	s1,s1,0x2
    800034f0:	94aa                	add	s1,s1,a0
    800034f2:	0504a983          	lw	s3,80(s1)
    800034f6:	fe0990e3          	bnez	s3,800034d6 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800034fa:	4108                	lw	a0,0(a0)
    800034fc:	00000097          	auipc	ra,0x0
    80003500:	e4a080e7          	jalr	-438(ra) # 80003346 <balloc>
    80003504:	0005099b          	sext.w	s3,a0
    80003508:	0534a823          	sw	s3,80(s1)
    8000350c:	b7e9                	j	800034d6 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000350e:	4108                	lw	a0,0(a0)
    80003510:	00000097          	auipc	ra,0x0
    80003514:	e36080e7          	jalr	-458(ra) # 80003346 <balloc>
    80003518:	0005059b          	sext.w	a1,a0
    8000351c:	08b92023          	sw	a1,128(s2)
    80003520:	b759                	j	800034a6 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003522:	00092503          	lw	a0,0(s2)
    80003526:	00000097          	auipc	ra,0x0
    8000352a:	e20080e7          	jalr	-480(ra) # 80003346 <balloc>
    8000352e:	0005099b          	sext.w	s3,a0
    80003532:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003536:	8552                	mv	a0,s4
    80003538:	00001097          	auipc	ra,0x1
    8000353c:	ef8080e7          	jalr	-264(ra) # 80004430 <log_write>
    80003540:	b771                	j	800034cc <bmap+0x54>
  panic("bmap: out of range");
    80003542:	00005517          	auipc	a0,0x5
    80003546:	05e50513          	addi	a0,a0,94 # 800085a0 <syscalls+0x140>
    8000354a:	ffffd097          	auipc	ra,0xffffd
    8000354e:	fee080e7          	jalr	-18(ra) # 80000538 <panic>

0000000080003552 <iget>:
{
    80003552:	7179                	addi	sp,sp,-48
    80003554:	f406                	sd	ra,40(sp)
    80003556:	f022                	sd	s0,32(sp)
    80003558:	ec26                	sd	s1,24(sp)
    8000355a:	e84a                	sd	s2,16(sp)
    8000355c:	e44e                	sd	s3,8(sp)
    8000355e:	e052                	sd	s4,0(sp)
    80003560:	1800                	addi	s0,sp,48
    80003562:	89aa                	mv	s3,a0
    80003564:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003566:	0001c517          	auipc	a0,0x1c
    8000356a:	2ca50513          	addi	a0,a0,714 # 8001f830 <itable>
    8000356e:	ffffd097          	auipc	ra,0xffffd
    80003572:	662080e7          	jalr	1634(ra) # 80000bd0 <acquire>
  empty = 0;
    80003576:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003578:	0001c497          	auipc	s1,0x1c
    8000357c:	2d048493          	addi	s1,s1,720 # 8001f848 <itable+0x18>
    80003580:	0001e697          	auipc	a3,0x1e
    80003584:	d5868693          	addi	a3,a3,-680 # 800212d8 <log>
    80003588:	a039                	j	80003596 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000358a:	02090b63          	beqz	s2,800035c0 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000358e:	08848493          	addi	s1,s1,136
    80003592:	02d48a63          	beq	s1,a3,800035c6 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003596:	449c                	lw	a5,8(s1)
    80003598:	fef059e3          	blez	a5,8000358a <iget+0x38>
    8000359c:	4098                	lw	a4,0(s1)
    8000359e:	ff3716e3          	bne	a4,s3,8000358a <iget+0x38>
    800035a2:	40d8                	lw	a4,4(s1)
    800035a4:	ff4713e3          	bne	a4,s4,8000358a <iget+0x38>
      ip->ref++;
    800035a8:	2785                	addiw	a5,a5,1
    800035aa:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800035ac:	0001c517          	auipc	a0,0x1c
    800035b0:	28450513          	addi	a0,a0,644 # 8001f830 <itable>
    800035b4:	ffffd097          	auipc	ra,0xffffd
    800035b8:	6d0080e7          	jalr	1744(ra) # 80000c84 <release>
      return ip;
    800035bc:	8926                	mv	s2,s1
    800035be:	a03d                	j	800035ec <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035c0:	f7f9                	bnez	a5,8000358e <iget+0x3c>
    800035c2:	8926                	mv	s2,s1
    800035c4:	b7e9                	j	8000358e <iget+0x3c>
  if(empty == 0)
    800035c6:	02090c63          	beqz	s2,800035fe <iget+0xac>
  ip->dev = dev;
    800035ca:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800035ce:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800035d2:	4785                	li	a5,1
    800035d4:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800035d8:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800035dc:	0001c517          	auipc	a0,0x1c
    800035e0:	25450513          	addi	a0,a0,596 # 8001f830 <itable>
    800035e4:	ffffd097          	auipc	ra,0xffffd
    800035e8:	6a0080e7          	jalr	1696(ra) # 80000c84 <release>
}
    800035ec:	854a                	mv	a0,s2
    800035ee:	70a2                	ld	ra,40(sp)
    800035f0:	7402                	ld	s0,32(sp)
    800035f2:	64e2                	ld	s1,24(sp)
    800035f4:	6942                	ld	s2,16(sp)
    800035f6:	69a2                	ld	s3,8(sp)
    800035f8:	6a02                	ld	s4,0(sp)
    800035fa:	6145                	addi	sp,sp,48
    800035fc:	8082                	ret
    panic("iget: no inodes");
    800035fe:	00005517          	auipc	a0,0x5
    80003602:	fba50513          	addi	a0,a0,-70 # 800085b8 <syscalls+0x158>
    80003606:	ffffd097          	auipc	ra,0xffffd
    8000360a:	f32080e7          	jalr	-206(ra) # 80000538 <panic>

000000008000360e <fsinit>:
fsinit(int dev) {
    8000360e:	7179                	addi	sp,sp,-48
    80003610:	f406                	sd	ra,40(sp)
    80003612:	f022                	sd	s0,32(sp)
    80003614:	ec26                	sd	s1,24(sp)
    80003616:	e84a                	sd	s2,16(sp)
    80003618:	e44e                	sd	s3,8(sp)
    8000361a:	1800                	addi	s0,sp,48
    8000361c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000361e:	4585                	li	a1,1
    80003620:	00000097          	auipc	ra,0x0
    80003624:	a64080e7          	jalr	-1436(ra) # 80003084 <bread>
    80003628:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000362a:	0001c997          	auipc	s3,0x1c
    8000362e:	1e698993          	addi	s3,s3,486 # 8001f810 <sb>
    80003632:	02000613          	li	a2,32
    80003636:	05850593          	addi	a1,a0,88
    8000363a:	854e                	mv	a0,s3
    8000363c:	ffffd097          	auipc	ra,0xffffd
    80003640:	6ec080e7          	jalr	1772(ra) # 80000d28 <memmove>
  brelse(bp);
    80003644:	8526                	mv	a0,s1
    80003646:	00000097          	auipc	ra,0x0
    8000364a:	b6e080e7          	jalr	-1170(ra) # 800031b4 <brelse>
  if(sb.magic != FSMAGIC)
    8000364e:	0009a703          	lw	a4,0(s3)
    80003652:	102037b7          	lui	a5,0x10203
    80003656:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000365a:	02f71263          	bne	a4,a5,8000367e <fsinit+0x70>
  initlog(dev, &sb);
    8000365e:	0001c597          	auipc	a1,0x1c
    80003662:	1b258593          	addi	a1,a1,434 # 8001f810 <sb>
    80003666:	854a                	mv	a0,s2
    80003668:	00001097          	auipc	ra,0x1
    8000366c:	b4c080e7          	jalr	-1204(ra) # 800041b4 <initlog>
}
    80003670:	70a2                	ld	ra,40(sp)
    80003672:	7402                	ld	s0,32(sp)
    80003674:	64e2                	ld	s1,24(sp)
    80003676:	6942                	ld	s2,16(sp)
    80003678:	69a2                	ld	s3,8(sp)
    8000367a:	6145                	addi	sp,sp,48
    8000367c:	8082                	ret
    panic("invalid file system");
    8000367e:	00005517          	auipc	a0,0x5
    80003682:	f4a50513          	addi	a0,a0,-182 # 800085c8 <syscalls+0x168>
    80003686:	ffffd097          	auipc	ra,0xffffd
    8000368a:	eb2080e7          	jalr	-334(ra) # 80000538 <panic>

000000008000368e <iinit>:
{
    8000368e:	7179                	addi	sp,sp,-48
    80003690:	f406                	sd	ra,40(sp)
    80003692:	f022                	sd	s0,32(sp)
    80003694:	ec26                	sd	s1,24(sp)
    80003696:	e84a                	sd	s2,16(sp)
    80003698:	e44e                	sd	s3,8(sp)
    8000369a:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000369c:	00005597          	auipc	a1,0x5
    800036a0:	f4458593          	addi	a1,a1,-188 # 800085e0 <syscalls+0x180>
    800036a4:	0001c517          	auipc	a0,0x1c
    800036a8:	18c50513          	addi	a0,a0,396 # 8001f830 <itable>
    800036ac:	ffffd097          	auipc	ra,0xffffd
    800036b0:	494080e7          	jalr	1172(ra) # 80000b40 <initlock>
  for(i = 0; i < NINODE; i++) {
    800036b4:	0001c497          	auipc	s1,0x1c
    800036b8:	1a448493          	addi	s1,s1,420 # 8001f858 <itable+0x28>
    800036bc:	0001e997          	auipc	s3,0x1e
    800036c0:	c2c98993          	addi	s3,s3,-980 # 800212e8 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800036c4:	00005917          	auipc	s2,0x5
    800036c8:	f2490913          	addi	s2,s2,-220 # 800085e8 <syscalls+0x188>
    800036cc:	85ca                	mv	a1,s2
    800036ce:	8526                	mv	a0,s1
    800036d0:	00001097          	auipc	ra,0x1
    800036d4:	e46080e7          	jalr	-442(ra) # 80004516 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800036d8:	08848493          	addi	s1,s1,136
    800036dc:	ff3498e3          	bne	s1,s3,800036cc <iinit+0x3e>
}
    800036e0:	70a2                	ld	ra,40(sp)
    800036e2:	7402                	ld	s0,32(sp)
    800036e4:	64e2                	ld	s1,24(sp)
    800036e6:	6942                	ld	s2,16(sp)
    800036e8:	69a2                	ld	s3,8(sp)
    800036ea:	6145                	addi	sp,sp,48
    800036ec:	8082                	ret

00000000800036ee <ialloc>:
{
    800036ee:	715d                	addi	sp,sp,-80
    800036f0:	e486                	sd	ra,72(sp)
    800036f2:	e0a2                	sd	s0,64(sp)
    800036f4:	fc26                	sd	s1,56(sp)
    800036f6:	f84a                	sd	s2,48(sp)
    800036f8:	f44e                	sd	s3,40(sp)
    800036fa:	f052                	sd	s4,32(sp)
    800036fc:	ec56                	sd	s5,24(sp)
    800036fe:	e85a                	sd	s6,16(sp)
    80003700:	e45e                	sd	s7,8(sp)
    80003702:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003704:	0001c717          	auipc	a4,0x1c
    80003708:	11872703          	lw	a4,280(a4) # 8001f81c <sb+0xc>
    8000370c:	4785                	li	a5,1
    8000370e:	04e7fa63          	bgeu	a5,a4,80003762 <ialloc+0x74>
    80003712:	8aaa                	mv	s5,a0
    80003714:	8bae                	mv	s7,a1
    80003716:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003718:	0001ca17          	auipc	s4,0x1c
    8000371c:	0f8a0a13          	addi	s4,s4,248 # 8001f810 <sb>
    80003720:	00048b1b          	sext.w	s6,s1
    80003724:	0044d793          	srli	a5,s1,0x4
    80003728:	018a2583          	lw	a1,24(s4)
    8000372c:	9dbd                	addw	a1,a1,a5
    8000372e:	8556                	mv	a0,s5
    80003730:	00000097          	auipc	ra,0x0
    80003734:	954080e7          	jalr	-1708(ra) # 80003084 <bread>
    80003738:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000373a:	05850993          	addi	s3,a0,88
    8000373e:	00f4f793          	andi	a5,s1,15
    80003742:	079a                	slli	a5,a5,0x6
    80003744:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003746:	00099783          	lh	a5,0(s3)
    8000374a:	c785                	beqz	a5,80003772 <ialloc+0x84>
    brelse(bp);
    8000374c:	00000097          	auipc	ra,0x0
    80003750:	a68080e7          	jalr	-1432(ra) # 800031b4 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003754:	0485                	addi	s1,s1,1
    80003756:	00ca2703          	lw	a4,12(s4)
    8000375a:	0004879b          	sext.w	a5,s1
    8000375e:	fce7e1e3          	bltu	a5,a4,80003720 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003762:	00005517          	auipc	a0,0x5
    80003766:	e8e50513          	addi	a0,a0,-370 # 800085f0 <syscalls+0x190>
    8000376a:	ffffd097          	auipc	ra,0xffffd
    8000376e:	dce080e7          	jalr	-562(ra) # 80000538 <panic>
      memset(dip, 0, sizeof(*dip));
    80003772:	04000613          	li	a2,64
    80003776:	4581                	li	a1,0
    80003778:	854e                	mv	a0,s3
    8000377a:	ffffd097          	auipc	ra,0xffffd
    8000377e:	552080e7          	jalr	1362(ra) # 80000ccc <memset>
      dip->type = type;
    80003782:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003786:	854a                	mv	a0,s2
    80003788:	00001097          	auipc	ra,0x1
    8000378c:	ca8080e7          	jalr	-856(ra) # 80004430 <log_write>
      brelse(bp);
    80003790:	854a                	mv	a0,s2
    80003792:	00000097          	auipc	ra,0x0
    80003796:	a22080e7          	jalr	-1502(ra) # 800031b4 <brelse>
      return iget(dev, inum);
    8000379a:	85da                	mv	a1,s6
    8000379c:	8556                	mv	a0,s5
    8000379e:	00000097          	auipc	ra,0x0
    800037a2:	db4080e7          	jalr	-588(ra) # 80003552 <iget>
}
    800037a6:	60a6                	ld	ra,72(sp)
    800037a8:	6406                	ld	s0,64(sp)
    800037aa:	74e2                	ld	s1,56(sp)
    800037ac:	7942                	ld	s2,48(sp)
    800037ae:	79a2                	ld	s3,40(sp)
    800037b0:	7a02                	ld	s4,32(sp)
    800037b2:	6ae2                	ld	s5,24(sp)
    800037b4:	6b42                	ld	s6,16(sp)
    800037b6:	6ba2                	ld	s7,8(sp)
    800037b8:	6161                	addi	sp,sp,80
    800037ba:	8082                	ret

00000000800037bc <iupdate>:
{
    800037bc:	1101                	addi	sp,sp,-32
    800037be:	ec06                	sd	ra,24(sp)
    800037c0:	e822                	sd	s0,16(sp)
    800037c2:	e426                	sd	s1,8(sp)
    800037c4:	e04a                	sd	s2,0(sp)
    800037c6:	1000                	addi	s0,sp,32
    800037c8:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037ca:	415c                	lw	a5,4(a0)
    800037cc:	0047d79b          	srliw	a5,a5,0x4
    800037d0:	0001c597          	auipc	a1,0x1c
    800037d4:	0585a583          	lw	a1,88(a1) # 8001f828 <sb+0x18>
    800037d8:	9dbd                	addw	a1,a1,a5
    800037da:	4108                	lw	a0,0(a0)
    800037dc:	00000097          	auipc	ra,0x0
    800037e0:	8a8080e7          	jalr	-1880(ra) # 80003084 <bread>
    800037e4:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037e6:	05850793          	addi	a5,a0,88
    800037ea:	40c8                	lw	a0,4(s1)
    800037ec:	893d                	andi	a0,a0,15
    800037ee:	051a                	slli	a0,a0,0x6
    800037f0:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800037f2:	04449703          	lh	a4,68(s1)
    800037f6:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800037fa:	04649703          	lh	a4,70(s1)
    800037fe:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003802:	04849703          	lh	a4,72(s1)
    80003806:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000380a:	04a49703          	lh	a4,74(s1)
    8000380e:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003812:	44f8                	lw	a4,76(s1)
    80003814:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003816:	03400613          	li	a2,52
    8000381a:	05048593          	addi	a1,s1,80
    8000381e:	0531                	addi	a0,a0,12
    80003820:	ffffd097          	auipc	ra,0xffffd
    80003824:	508080e7          	jalr	1288(ra) # 80000d28 <memmove>
  log_write(bp);
    80003828:	854a                	mv	a0,s2
    8000382a:	00001097          	auipc	ra,0x1
    8000382e:	c06080e7          	jalr	-1018(ra) # 80004430 <log_write>
  brelse(bp);
    80003832:	854a                	mv	a0,s2
    80003834:	00000097          	auipc	ra,0x0
    80003838:	980080e7          	jalr	-1664(ra) # 800031b4 <brelse>
}
    8000383c:	60e2                	ld	ra,24(sp)
    8000383e:	6442                	ld	s0,16(sp)
    80003840:	64a2                	ld	s1,8(sp)
    80003842:	6902                	ld	s2,0(sp)
    80003844:	6105                	addi	sp,sp,32
    80003846:	8082                	ret

0000000080003848 <idup>:
{
    80003848:	1101                	addi	sp,sp,-32
    8000384a:	ec06                	sd	ra,24(sp)
    8000384c:	e822                	sd	s0,16(sp)
    8000384e:	e426                	sd	s1,8(sp)
    80003850:	1000                	addi	s0,sp,32
    80003852:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003854:	0001c517          	auipc	a0,0x1c
    80003858:	fdc50513          	addi	a0,a0,-36 # 8001f830 <itable>
    8000385c:	ffffd097          	auipc	ra,0xffffd
    80003860:	374080e7          	jalr	884(ra) # 80000bd0 <acquire>
  ip->ref++;
    80003864:	449c                	lw	a5,8(s1)
    80003866:	2785                	addiw	a5,a5,1
    80003868:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000386a:	0001c517          	auipc	a0,0x1c
    8000386e:	fc650513          	addi	a0,a0,-58 # 8001f830 <itable>
    80003872:	ffffd097          	auipc	ra,0xffffd
    80003876:	412080e7          	jalr	1042(ra) # 80000c84 <release>
}
    8000387a:	8526                	mv	a0,s1
    8000387c:	60e2                	ld	ra,24(sp)
    8000387e:	6442                	ld	s0,16(sp)
    80003880:	64a2                	ld	s1,8(sp)
    80003882:	6105                	addi	sp,sp,32
    80003884:	8082                	ret

0000000080003886 <ilock>:
{
    80003886:	1101                	addi	sp,sp,-32
    80003888:	ec06                	sd	ra,24(sp)
    8000388a:	e822                	sd	s0,16(sp)
    8000388c:	e426                	sd	s1,8(sp)
    8000388e:	e04a                	sd	s2,0(sp)
    80003890:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003892:	c115                	beqz	a0,800038b6 <ilock+0x30>
    80003894:	84aa                	mv	s1,a0
    80003896:	451c                	lw	a5,8(a0)
    80003898:	00f05f63          	blez	a5,800038b6 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000389c:	0541                	addi	a0,a0,16
    8000389e:	00001097          	auipc	ra,0x1
    800038a2:	cb2080e7          	jalr	-846(ra) # 80004550 <acquiresleep>
  if(ip->valid == 0){
    800038a6:	40bc                	lw	a5,64(s1)
    800038a8:	cf99                	beqz	a5,800038c6 <ilock+0x40>
}
    800038aa:	60e2                	ld	ra,24(sp)
    800038ac:	6442                	ld	s0,16(sp)
    800038ae:	64a2                	ld	s1,8(sp)
    800038b0:	6902                	ld	s2,0(sp)
    800038b2:	6105                	addi	sp,sp,32
    800038b4:	8082                	ret
    panic("ilock");
    800038b6:	00005517          	auipc	a0,0x5
    800038ba:	d5250513          	addi	a0,a0,-686 # 80008608 <syscalls+0x1a8>
    800038be:	ffffd097          	auipc	ra,0xffffd
    800038c2:	c7a080e7          	jalr	-902(ra) # 80000538 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038c6:	40dc                	lw	a5,4(s1)
    800038c8:	0047d79b          	srliw	a5,a5,0x4
    800038cc:	0001c597          	auipc	a1,0x1c
    800038d0:	f5c5a583          	lw	a1,-164(a1) # 8001f828 <sb+0x18>
    800038d4:	9dbd                	addw	a1,a1,a5
    800038d6:	4088                	lw	a0,0(s1)
    800038d8:	fffff097          	auipc	ra,0xfffff
    800038dc:	7ac080e7          	jalr	1964(ra) # 80003084 <bread>
    800038e0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038e2:	05850593          	addi	a1,a0,88
    800038e6:	40dc                	lw	a5,4(s1)
    800038e8:	8bbd                	andi	a5,a5,15
    800038ea:	079a                	slli	a5,a5,0x6
    800038ec:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800038ee:	00059783          	lh	a5,0(a1)
    800038f2:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800038f6:	00259783          	lh	a5,2(a1)
    800038fa:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800038fe:	00459783          	lh	a5,4(a1)
    80003902:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003906:	00659783          	lh	a5,6(a1)
    8000390a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000390e:	459c                	lw	a5,8(a1)
    80003910:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003912:	03400613          	li	a2,52
    80003916:	05b1                	addi	a1,a1,12
    80003918:	05048513          	addi	a0,s1,80
    8000391c:	ffffd097          	auipc	ra,0xffffd
    80003920:	40c080e7          	jalr	1036(ra) # 80000d28 <memmove>
    brelse(bp);
    80003924:	854a                	mv	a0,s2
    80003926:	00000097          	auipc	ra,0x0
    8000392a:	88e080e7          	jalr	-1906(ra) # 800031b4 <brelse>
    ip->valid = 1;
    8000392e:	4785                	li	a5,1
    80003930:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003932:	04449783          	lh	a5,68(s1)
    80003936:	fbb5                	bnez	a5,800038aa <ilock+0x24>
      panic("ilock: no type");
    80003938:	00005517          	auipc	a0,0x5
    8000393c:	cd850513          	addi	a0,a0,-808 # 80008610 <syscalls+0x1b0>
    80003940:	ffffd097          	auipc	ra,0xffffd
    80003944:	bf8080e7          	jalr	-1032(ra) # 80000538 <panic>

0000000080003948 <iunlock>:
{
    80003948:	1101                	addi	sp,sp,-32
    8000394a:	ec06                	sd	ra,24(sp)
    8000394c:	e822                	sd	s0,16(sp)
    8000394e:	e426                	sd	s1,8(sp)
    80003950:	e04a                	sd	s2,0(sp)
    80003952:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003954:	c905                	beqz	a0,80003984 <iunlock+0x3c>
    80003956:	84aa                	mv	s1,a0
    80003958:	01050913          	addi	s2,a0,16
    8000395c:	854a                	mv	a0,s2
    8000395e:	00001097          	auipc	ra,0x1
    80003962:	c8c080e7          	jalr	-884(ra) # 800045ea <holdingsleep>
    80003966:	cd19                	beqz	a0,80003984 <iunlock+0x3c>
    80003968:	449c                	lw	a5,8(s1)
    8000396a:	00f05d63          	blez	a5,80003984 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000396e:	854a                	mv	a0,s2
    80003970:	00001097          	auipc	ra,0x1
    80003974:	c36080e7          	jalr	-970(ra) # 800045a6 <releasesleep>
}
    80003978:	60e2                	ld	ra,24(sp)
    8000397a:	6442                	ld	s0,16(sp)
    8000397c:	64a2                	ld	s1,8(sp)
    8000397e:	6902                	ld	s2,0(sp)
    80003980:	6105                	addi	sp,sp,32
    80003982:	8082                	ret
    panic("iunlock");
    80003984:	00005517          	auipc	a0,0x5
    80003988:	c9c50513          	addi	a0,a0,-868 # 80008620 <syscalls+0x1c0>
    8000398c:	ffffd097          	auipc	ra,0xffffd
    80003990:	bac080e7          	jalr	-1108(ra) # 80000538 <panic>

0000000080003994 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003994:	7179                	addi	sp,sp,-48
    80003996:	f406                	sd	ra,40(sp)
    80003998:	f022                	sd	s0,32(sp)
    8000399a:	ec26                	sd	s1,24(sp)
    8000399c:	e84a                	sd	s2,16(sp)
    8000399e:	e44e                	sd	s3,8(sp)
    800039a0:	e052                	sd	s4,0(sp)
    800039a2:	1800                	addi	s0,sp,48
    800039a4:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800039a6:	05050493          	addi	s1,a0,80
    800039aa:	08050913          	addi	s2,a0,128
    800039ae:	a021                	j	800039b6 <itrunc+0x22>
    800039b0:	0491                	addi	s1,s1,4
    800039b2:	01248d63          	beq	s1,s2,800039cc <itrunc+0x38>
    if(ip->addrs[i]){
    800039b6:	408c                	lw	a1,0(s1)
    800039b8:	dde5                	beqz	a1,800039b0 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800039ba:	0009a503          	lw	a0,0(s3)
    800039be:	00000097          	auipc	ra,0x0
    800039c2:	90c080e7          	jalr	-1780(ra) # 800032ca <bfree>
      ip->addrs[i] = 0;
    800039c6:	0004a023          	sw	zero,0(s1)
    800039ca:	b7dd                	j	800039b0 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800039cc:	0809a583          	lw	a1,128(s3)
    800039d0:	e185                	bnez	a1,800039f0 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800039d2:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800039d6:	854e                	mv	a0,s3
    800039d8:	00000097          	auipc	ra,0x0
    800039dc:	de4080e7          	jalr	-540(ra) # 800037bc <iupdate>
}
    800039e0:	70a2                	ld	ra,40(sp)
    800039e2:	7402                	ld	s0,32(sp)
    800039e4:	64e2                	ld	s1,24(sp)
    800039e6:	6942                	ld	s2,16(sp)
    800039e8:	69a2                	ld	s3,8(sp)
    800039ea:	6a02                	ld	s4,0(sp)
    800039ec:	6145                	addi	sp,sp,48
    800039ee:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800039f0:	0009a503          	lw	a0,0(s3)
    800039f4:	fffff097          	auipc	ra,0xfffff
    800039f8:	690080e7          	jalr	1680(ra) # 80003084 <bread>
    800039fc:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800039fe:	05850493          	addi	s1,a0,88
    80003a02:	45850913          	addi	s2,a0,1112
    80003a06:	a021                	j	80003a0e <itrunc+0x7a>
    80003a08:	0491                	addi	s1,s1,4
    80003a0a:	01248b63          	beq	s1,s2,80003a20 <itrunc+0x8c>
      if(a[j])
    80003a0e:	408c                	lw	a1,0(s1)
    80003a10:	dde5                	beqz	a1,80003a08 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003a12:	0009a503          	lw	a0,0(s3)
    80003a16:	00000097          	auipc	ra,0x0
    80003a1a:	8b4080e7          	jalr	-1868(ra) # 800032ca <bfree>
    80003a1e:	b7ed                	j	80003a08 <itrunc+0x74>
    brelse(bp);
    80003a20:	8552                	mv	a0,s4
    80003a22:	fffff097          	auipc	ra,0xfffff
    80003a26:	792080e7          	jalr	1938(ra) # 800031b4 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a2a:	0809a583          	lw	a1,128(s3)
    80003a2e:	0009a503          	lw	a0,0(s3)
    80003a32:	00000097          	auipc	ra,0x0
    80003a36:	898080e7          	jalr	-1896(ra) # 800032ca <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a3a:	0809a023          	sw	zero,128(s3)
    80003a3e:	bf51                	j	800039d2 <itrunc+0x3e>

0000000080003a40 <iput>:
{
    80003a40:	1101                	addi	sp,sp,-32
    80003a42:	ec06                	sd	ra,24(sp)
    80003a44:	e822                	sd	s0,16(sp)
    80003a46:	e426                	sd	s1,8(sp)
    80003a48:	e04a                	sd	s2,0(sp)
    80003a4a:	1000                	addi	s0,sp,32
    80003a4c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a4e:	0001c517          	auipc	a0,0x1c
    80003a52:	de250513          	addi	a0,a0,-542 # 8001f830 <itable>
    80003a56:	ffffd097          	auipc	ra,0xffffd
    80003a5a:	17a080e7          	jalr	378(ra) # 80000bd0 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a5e:	4498                	lw	a4,8(s1)
    80003a60:	4785                	li	a5,1
    80003a62:	02f70363          	beq	a4,a5,80003a88 <iput+0x48>
  ip->ref--;
    80003a66:	449c                	lw	a5,8(s1)
    80003a68:	37fd                	addiw	a5,a5,-1
    80003a6a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a6c:	0001c517          	auipc	a0,0x1c
    80003a70:	dc450513          	addi	a0,a0,-572 # 8001f830 <itable>
    80003a74:	ffffd097          	auipc	ra,0xffffd
    80003a78:	210080e7          	jalr	528(ra) # 80000c84 <release>
}
    80003a7c:	60e2                	ld	ra,24(sp)
    80003a7e:	6442                	ld	s0,16(sp)
    80003a80:	64a2                	ld	s1,8(sp)
    80003a82:	6902                	ld	s2,0(sp)
    80003a84:	6105                	addi	sp,sp,32
    80003a86:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a88:	40bc                	lw	a5,64(s1)
    80003a8a:	dff1                	beqz	a5,80003a66 <iput+0x26>
    80003a8c:	04a49783          	lh	a5,74(s1)
    80003a90:	fbf9                	bnez	a5,80003a66 <iput+0x26>
    acquiresleep(&ip->lock);
    80003a92:	01048913          	addi	s2,s1,16
    80003a96:	854a                	mv	a0,s2
    80003a98:	00001097          	auipc	ra,0x1
    80003a9c:	ab8080e7          	jalr	-1352(ra) # 80004550 <acquiresleep>
    release(&itable.lock);
    80003aa0:	0001c517          	auipc	a0,0x1c
    80003aa4:	d9050513          	addi	a0,a0,-624 # 8001f830 <itable>
    80003aa8:	ffffd097          	auipc	ra,0xffffd
    80003aac:	1dc080e7          	jalr	476(ra) # 80000c84 <release>
    itrunc(ip);
    80003ab0:	8526                	mv	a0,s1
    80003ab2:	00000097          	auipc	ra,0x0
    80003ab6:	ee2080e7          	jalr	-286(ra) # 80003994 <itrunc>
    ip->type = 0;
    80003aba:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003abe:	8526                	mv	a0,s1
    80003ac0:	00000097          	auipc	ra,0x0
    80003ac4:	cfc080e7          	jalr	-772(ra) # 800037bc <iupdate>
    ip->valid = 0;
    80003ac8:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003acc:	854a                	mv	a0,s2
    80003ace:	00001097          	auipc	ra,0x1
    80003ad2:	ad8080e7          	jalr	-1320(ra) # 800045a6 <releasesleep>
    acquire(&itable.lock);
    80003ad6:	0001c517          	auipc	a0,0x1c
    80003ada:	d5a50513          	addi	a0,a0,-678 # 8001f830 <itable>
    80003ade:	ffffd097          	auipc	ra,0xffffd
    80003ae2:	0f2080e7          	jalr	242(ra) # 80000bd0 <acquire>
    80003ae6:	b741                	j	80003a66 <iput+0x26>

0000000080003ae8 <iunlockput>:
{
    80003ae8:	1101                	addi	sp,sp,-32
    80003aea:	ec06                	sd	ra,24(sp)
    80003aec:	e822                	sd	s0,16(sp)
    80003aee:	e426                	sd	s1,8(sp)
    80003af0:	1000                	addi	s0,sp,32
    80003af2:	84aa                	mv	s1,a0
  iunlock(ip);
    80003af4:	00000097          	auipc	ra,0x0
    80003af8:	e54080e7          	jalr	-428(ra) # 80003948 <iunlock>
  iput(ip);
    80003afc:	8526                	mv	a0,s1
    80003afe:	00000097          	auipc	ra,0x0
    80003b02:	f42080e7          	jalr	-190(ra) # 80003a40 <iput>
}
    80003b06:	60e2                	ld	ra,24(sp)
    80003b08:	6442                	ld	s0,16(sp)
    80003b0a:	64a2                	ld	s1,8(sp)
    80003b0c:	6105                	addi	sp,sp,32
    80003b0e:	8082                	ret

0000000080003b10 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b10:	1141                	addi	sp,sp,-16
    80003b12:	e422                	sd	s0,8(sp)
    80003b14:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b16:	411c                	lw	a5,0(a0)
    80003b18:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b1a:	415c                	lw	a5,4(a0)
    80003b1c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b1e:	04451783          	lh	a5,68(a0)
    80003b22:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b26:	04a51783          	lh	a5,74(a0)
    80003b2a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b2e:	04c56783          	lwu	a5,76(a0)
    80003b32:	e99c                	sd	a5,16(a1)
}
    80003b34:	6422                	ld	s0,8(sp)
    80003b36:	0141                	addi	sp,sp,16
    80003b38:	8082                	ret

0000000080003b3a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b3a:	457c                	lw	a5,76(a0)
    80003b3c:	0ed7e963          	bltu	a5,a3,80003c2e <readi+0xf4>
{
    80003b40:	7159                	addi	sp,sp,-112
    80003b42:	f486                	sd	ra,104(sp)
    80003b44:	f0a2                	sd	s0,96(sp)
    80003b46:	eca6                	sd	s1,88(sp)
    80003b48:	e8ca                	sd	s2,80(sp)
    80003b4a:	e4ce                	sd	s3,72(sp)
    80003b4c:	e0d2                	sd	s4,64(sp)
    80003b4e:	fc56                	sd	s5,56(sp)
    80003b50:	f85a                	sd	s6,48(sp)
    80003b52:	f45e                	sd	s7,40(sp)
    80003b54:	f062                	sd	s8,32(sp)
    80003b56:	ec66                	sd	s9,24(sp)
    80003b58:	e86a                	sd	s10,16(sp)
    80003b5a:	e46e                	sd	s11,8(sp)
    80003b5c:	1880                	addi	s0,sp,112
    80003b5e:	8baa                	mv	s7,a0
    80003b60:	8c2e                	mv	s8,a1
    80003b62:	8ab2                	mv	s5,a2
    80003b64:	84b6                	mv	s1,a3
    80003b66:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b68:	9f35                	addw	a4,a4,a3
    return 0;
    80003b6a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b6c:	0ad76063          	bltu	a4,a3,80003c0c <readi+0xd2>
  if(off + n > ip->size)
    80003b70:	00e7f463          	bgeu	a5,a4,80003b78 <readi+0x3e>
    n = ip->size - off;
    80003b74:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b78:	0a0b0963          	beqz	s6,80003c2a <readi+0xf0>
    80003b7c:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b7e:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b82:	5cfd                	li	s9,-1
    80003b84:	a82d                	j	80003bbe <readi+0x84>
    80003b86:	020a1d93          	slli	s11,s4,0x20
    80003b8a:	020ddd93          	srli	s11,s11,0x20
    80003b8e:	05890793          	addi	a5,s2,88
    80003b92:	86ee                	mv	a3,s11
    80003b94:	963e                	add	a2,a2,a5
    80003b96:	85d6                	mv	a1,s5
    80003b98:	8562                	mv	a0,s8
    80003b9a:	fffff097          	auipc	ra,0xfffff
    80003b9e:	860080e7          	jalr	-1952(ra) # 800023fa <either_copyout>
    80003ba2:	05950d63          	beq	a0,s9,80003bfc <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ba6:	854a                	mv	a0,s2
    80003ba8:	fffff097          	auipc	ra,0xfffff
    80003bac:	60c080e7          	jalr	1548(ra) # 800031b4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bb0:	013a09bb          	addw	s3,s4,s3
    80003bb4:	009a04bb          	addw	s1,s4,s1
    80003bb8:	9aee                	add	s5,s5,s11
    80003bba:	0569f763          	bgeu	s3,s6,80003c08 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003bbe:	000ba903          	lw	s2,0(s7)
    80003bc2:	00a4d59b          	srliw	a1,s1,0xa
    80003bc6:	855e                	mv	a0,s7
    80003bc8:	00000097          	auipc	ra,0x0
    80003bcc:	8b0080e7          	jalr	-1872(ra) # 80003478 <bmap>
    80003bd0:	0005059b          	sext.w	a1,a0
    80003bd4:	854a                	mv	a0,s2
    80003bd6:	fffff097          	auipc	ra,0xfffff
    80003bda:	4ae080e7          	jalr	1198(ra) # 80003084 <bread>
    80003bde:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003be0:	3ff4f613          	andi	a2,s1,1023
    80003be4:	40cd07bb          	subw	a5,s10,a2
    80003be8:	413b073b          	subw	a4,s6,s3
    80003bec:	8a3e                	mv	s4,a5
    80003bee:	2781                	sext.w	a5,a5
    80003bf0:	0007069b          	sext.w	a3,a4
    80003bf4:	f8f6f9e3          	bgeu	a3,a5,80003b86 <readi+0x4c>
    80003bf8:	8a3a                	mv	s4,a4
    80003bfa:	b771                	j	80003b86 <readi+0x4c>
      brelse(bp);
    80003bfc:	854a                	mv	a0,s2
    80003bfe:	fffff097          	auipc	ra,0xfffff
    80003c02:	5b6080e7          	jalr	1462(ra) # 800031b4 <brelse>
      tot = -1;
    80003c06:	59fd                	li	s3,-1
  }
  return tot;
    80003c08:	0009851b          	sext.w	a0,s3
}
    80003c0c:	70a6                	ld	ra,104(sp)
    80003c0e:	7406                	ld	s0,96(sp)
    80003c10:	64e6                	ld	s1,88(sp)
    80003c12:	6946                	ld	s2,80(sp)
    80003c14:	69a6                	ld	s3,72(sp)
    80003c16:	6a06                	ld	s4,64(sp)
    80003c18:	7ae2                	ld	s5,56(sp)
    80003c1a:	7b42                	ld	s6,48(sp)
    80003c1c:	7ba2                	ld	s7,40(sp)
    80003c1e:	7c02                	ld	s8,32(sp)
    80003c20:	6ce2                	ld	s9,24(sp)
    80003c22:	6d42                	ld	s10,16(sp)
    80003c24:	6da2                	ld	s11,8(sp)
    80003c26:	6165                	addi	sp,sp,112
    80003c28:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c2a:	89da                	mv	s3,s6
    80003c2c:	bff1                	j	80003c08 <readi+0xce>
    return 0;
    80003c2e:	4501                	li	a0,0
}
    80003c30:	8082                	ret

0000000080003c32 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c32:	457c                	lw	a5,76(a0)
    80003c34:	10d7e863          	bltu	a5,a3,80003d44 <writei+0x112>
{
    80003c38:	7159                	addi	sp,sp,-112
    80003c3a:	f486                	sd	ra,104(sp)
    80003c3c:	f0a2                	sd	s0,96(sp)
    80003c3e:	eca6                	sd	s1,88(sp)
    80003c40:	e8ca                	sd	s2,80(sp)
    80003c42:	e4ce                	sd	s3,72(sp)
    80003c44:	e0d2                	sd	s4,64(sp)
    80003c46:	fc56                	sd	s5,56(sp)
    80003c48:	f85a                	sd	s6,48(sp)
    80003c4a:	f45e                	sd	s7,40(sp)
    80003c4c:	f062                	sd	s8,32(sp)
    80003c4e:	ec66                	sd	s9,24(sp)
    80003c50:	e86a                	sd	s10,16(sp)
    80003c52:	e46e                	sd	s11,8(sp)
    80003c54:	1880                	addi	s0,sp,112
    80003c56:	8b2a                	mv	s6,a0
    80003c58:	8c2e                	mv	s8,a1
    80003c5a:	8ab2                	mv	s5,a2
    80003c5c:	8936                	mv	s2,a3
    80003c5e:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003c60:	00e687bb          	addw	a5,a3,a4
    80003c64:	0ed7e263          	bltu	a5,a3,80003d48 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c68:	00043737          	lui	a4,0x43
    80003c6c:	0ef76063          	bltu	a4,a5,80003d4c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c70:	0c0b8863          	beqz	s7,80003d40 <writei+0x10e>
    80003c74:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c76:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c7a:	5cfd                	li	s9,-1
    80003c7c:	a091                	j	80003cc0 <writei+0x8e>
    80003c7e:	02099d93          	slli	s11,s3,0x20
    80003c82:	020ddd93          	srli	s11,s11,0x20
    80003c86:	05848793          	addi	a5,s1,88
    80003c8a:	86ee                	mv	a3,s11
    80003c8c:	8656                	mv	a2,s5
    80003c8e:	85e2                	mv	a1,s8
    80003c90:	953e                	add	a0,a0,a5
    80003c92:	ffffe097          	auipc	ra,0xffffe
    80003c96:	7be080e7          	jalr	1982(ra) # 80002450 <either_copyin>
    80003c9a:	07950263          	beq	a0,s9,80003cfe <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003c9e:	8526                	mv	a0,s1
    80003ca0:	00000097          	auipc	ra,0x0
    80003ca4:	790080e7          	jalr	1936(ra) # 80004430 <log_write>
    brelse(bp);
    80003ca8:	8526                	mv	a0,s1
    80003caa:	fffff097          	auipc	ra,0xfffff
    80003cae:	50a080e7          	jalr	1290(ra) # 800031b4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cb2:	01498a3b          	addw	s4,s3,s4
    80003cb6:	0129893b          	addw	s2,s3,s2
    80003cba:	9aee                	add	s5,s5,s11
    80003cbc:	057a7663          	bgeu	s4,s7,80003d08 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003cc0:	000b2483          	lw	s1,0(s6)
    80003cc4:	00a9559b          	srliw	a1,s2,0xa
    80003cc8:	855a                	mv	a0,s6
    80003cca:	fffff097          	auipc	ra,0xfffff
    80003cce:	7ae080e7          	jalr	1966(ra) # 80003478 <bmap>
    80003cd2:	0005059b          	sext.w	a1,a0
    80003cd6:	8526                	mv	a0,s1
    80003cd8:	fffff097          	auipc	ra,0xfffff
    80003cdc:	3ac080e7          	jalr	940(ra) # 80003084 <bread>
    80003ce0:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ce2:	3ff97513          	andi	a0,s2,1023
    80003ce6:	40ad07bb          	subw	a5,s10,a0
    80003cea:	414b873b          	subw	a4,s7,s4
    80003cee:	89be                	mv	s3,a5
    80003cf0:	2781                	sext.w	a5,a5
    80003cf2:	0007069b          	sext.w	a3,a4
    80003cf6:	f8f6f4e3          	bgeu	a3,a5,80003c7e <writei+0x4c>
    80003cfa:	89ba                	mv	s3,a4
    80003cfc:	b749                	j	80003c7e <writei+0x4c>
      brelse(bp);
    80003cfe:	8526                	mv	a0,s1
    80003d00:	fffff097          	auipc	ra,0xfffff
    80003d04:	4b4080e7          	jalr	1204(ra) # 800031b4 <brelse>
  }

  if(off > ip->size)
    80003d08:	04cb2783          	lw	a5,76(s6)
    80003d0c:	0127f463          	bgeu	a5,s2,80003d14 <writei+0xe2>
    ip->size = off;
    80003d10:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003d14:	855a                	mv	a0,s6
    80003d16:	00000097          	auipc	ra,0x0
    80003d1a:	aa6080e7          	jalr	-1370(ra) # 800037bc <iupdate>

  return tot;
    80003d1e:	000a051b          	sext.w	a0,s4
}
    80003d22:	70a6                	ld	ra,104(sp)
    80003d24:	7406                	ld	s0,96(sp)
    80003d26:	64e6                	ld	s1,88(sp)
    80003d28:	6946                	ld	s2,80(sp)
    80003d2a:	69a6                	ld	s3,72(sp)
    80003d2c:	6a06                	ld	s4,64(sp)
    80003d2e:	7ae2                	ld	s5,56(sp)
    80003d30:	7b42                	ld	s6,48(sp)
    80003d32:	7ba2                	ld	s7,40(sp)
    80003d34:	7c02                	ld	s8,32(sp)
    80003d36:	6ce2                	ld	s9,24(sp)
    80003d38:	6d42                	ld	s10,16(sp)
    80003d3a:	6da2                	ld	s11,8(sp)
    80003d3c:	6165                	addi	sp,sp,112
    80003d3e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d40:	8a5e                	mv	s4,s7
    80003d42:	bfc9                	j	80003d14 <writei+0xe2>
    return -1;
    80003d44:	557d                	li	a0,-1
}
    80003d46:	8082                	ret
    return -1;
    80003d48:	557d                	li	a0,-1
    80003d4a:	bfe1                	j	80003d22 <writei+0xf0>
    return -1;
    80003d4c:	557d                	li	a0,-1
    80003d4e:	bfd1                	j	80003d22 <writei+0xf0>

0000000080003d50 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d50:	1141                	addi	sp,sp,-16
    80003d52:	e406                	sd	ra,8(sp)
    80003d54:	e022                	sd	s0,0(sp)
    80003d56:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d58:	4639                	li	a2,14
    80003d5a:	ffffd097          	auipc	ra,0xffffd
    80003d5e:	042080e7          	jalr	66(ra) # 80000d9c <strncmp>
}
    80003d62:	60a2                	ld	ra,8(sp)
    80003d64:	6402                	ld	s0,0(sp)
    80003d66:	0141                	addi	sp,sp,16
    80003d68:	8082                	ret

0000000080003d6a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d6a:	7139                	addi	sp,sp,-64
    80003d6c:	fc06                	sd	ra,56(sp)
    80003d6e:	f822                	sd	s0,48(sp)
    80003d70:	f426                	sd	s1,40(sp)
    80003d72:	f04a                	sd	s2,32(sp)
    80003d74:	ec4e                	sd	s3,24(sp)
    80003d76:	e852                	sd	s4,16(sp)
    80003d78:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d7a:	04451703          	lh	a4,68(a0)
    80003d7e:	4785                	li	a5,1
    80003d80:	00f71a63          	bne	a4,a5,80003d94 <dirlookup+0x2a>
    80003d84:	892a                	mv	s2,a0
    80003d86:	89ae                	mv	s3,a1
    80003d88:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d8a:	457c                	lw	a5,76(a0)
    80003d8c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d8e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d90:	e79d                	bnez	a5,80003dbe <dirlookup+0x54>
    80003d92:	a8a5                	j	80003e0a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003d94:	00005517          	auipc	a0,0x5
    80003d98:	89450513          	addi	a0,a0,-1900 # 80008628 <syscalls+0x1c8>
    80003d9c:	ffffc097          	auipc	ra,0xffffc
    80003da0:	79c080e7          	jalr	1948(ra) # 80000538 <panic>
      panic("dirlookup read");
    80003da4:	00005517          	auipc	a0,0x5
    80003da8:	89c50513          	addi	a0,a0,-1892 # 80008640 <syscalls+0x1e0>
    80003dac:	ffffc097          	auipc	ra,0xffffc
    80003db0:	78c080e7          	jalr	1932(ra) # 80000538 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003db4:	24c1                	addiw	s1,s1,16
    80003db6:	04c92783          	lw	a5,76(s2)
    80003dba:	04f4f763          	bgeu	s1,a5,80003e08 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003dbe:	4741                	li	a4,16
    80003dc0:	86a6                	mv	a3,s1
    80003dc2:	fc040613          	addi	a2,s0,-64
    80003dc6:	4581                	li	a1,0
    80003dc8:	854a                	mv	a0,s2
    80003dca:	00000097          	auipc	ra,0x0
    80003dce:	d70080e7          	jalr	-656(ra) # 80003b3a <readi>
    80003dd2:	47c1                	li	a5,16
    80003dd4:	fcf518e3          	bne	a0,a5,80003da4 <dirlookup+0x3a>
    if(de.inum == 0)
    80003dd8:	fc045783          	lhu	a5,-64(s0)
    80003ddc:	dfe1                	beqz	a5,80003db4 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003dde:	fc240593          	addi	a1,s0,-62
    80003de2:	854e                	mv	a0,s3
    80003de4:	00000097          	auipc	ra,0x0
    80003de8:	f6c080e7          	jalr	-148(ra) # 80003d50 <namecmp>
    80003dec:	f561                	bnez	a0,80003db4 <dirlookup+0x4a>
      if(poff)
    80003dee:	000a0463          	beqz	s4,80003df6 <dirlookup+0x8c>
        *poff = off;
    80003df2:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003df6:	fc045583          	lhu	a1,-64(s0)
    80003dfa:	00092503          	lw	a0,0(s2)
    80003dfe:	fffff097          	auipc	ra,0xfffff
    80003e02:	754080e7          	jalr	1876(ra) # 80003552 <iget>
    80003e06:	a011                	j	80003e0a <dirlookup+0xa0>
  return 0;
    80003e08:	4501                	li	a0,0
}
    80003e0a:	70e2                	ld	ra,56(sp)
    80003e0c:	7442                	ld	s0,48(sp)
    80003e0e:	74a2                	ld	s1,40(sp)
    80003e10:	7902                	ld	s2,32(sp)
    80003e12:	69e2                	ld	s3,24(sp)
    80003e14:	6a42                	ld	s4,16(sp)
    80003e16:	6121                	addi	sp,sp,64
    80003e18:	8082                	ret

0000000080003e1a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e1a:	711d                	addi	sp,sp,-96
    80003e1c:	ec86                	sd	ra,88(sp)
    80003e1e:	e8a2                	sd	s0,80(sp)
    80003e20:	e4a6                	sd	s1,72(sp)
    80003e22:	e0ca                	sd	s2,64(sp)
    80003e24:	fc4e                	sd	s3,56(sp)
    80003e26:	f852                	sd	s4,48(sp)
    80003e28:	f456                	sd	s5,40(sp)
    80003e2a:	f05a                	sd	s6,32(sp)
    80003e2c:	ec5e                	sd	s7,24(sp)
    80003e2e:	e862                	sd	s8,16(sp)
    80003e30:	e466                	sd	s9,8(sp)
    80003e32:	1080                	addi	s0,sp,96
    80003e34:	84aa                	mv	s1,a0
    80003e36:	8aae                	mv	s5,a1
    80003e38:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e3a:	00054703          	lbu	a4,0(a0)
    80003e3e:	02f00793          	li	a5,47
    80003e42:	02f70363          	beq	a4,a5,80003e68 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e46:	ffffe097          	auipc	ra,0xffffe
    80003e4a:	b50080e7          	jalr	-1200(ra) # 80001996 <myproc>
    80003e4e:	15053503          	ld	a0,336(a0)
    80003e52:	00000097          	auipc	ra,0x0
    80003e56:	9f6080e7          	jalr	-1546(ra) # 80003848 <idup>
    80003e5a:	89aa                	mv	s3,a0
  while(*path == '/')
    80003e5c:	02f00913          	li	s2,47
  len = path - s;
    80003e60:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003e62:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e64:	4b85                	li	s7,1
    80003e66:	a865                	j	80003f1e <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003e68:	4585                	li	a1,1
    80003e6a:	4505                	li	a0,1
    80003e6c:	fffff097          	auipc	ra,0xfffff
    80003e70:	6e6080e7          	jalr	1766(ra) # 80003552 <iget>
    80003e74:	89aa                	mv	s3,a0
    80003e76:	b7dd                	j	80003e5c <namex+0x42>
      iunlockput(ip);
    80003e78:	854e                	mv	a0,s3
    80003e7a:	00000097          	auipc	ra,0x0
    80003e7e:	c6e080e7          	jalr	-914(ra) # 80003ae8 <iunlockput>
      return 0;
    80003e82:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e84:	854e                	mv	a0,s3
    80003e86:	60e6                	ld	ra,88(sp)
    80003e88:	6446                	ld	s0,80(sp)
    80003e8a:	64a6                	ld	s1,72(sp)
    80003e8c:	6906                	ld	s2,64(sp)
    80003e8e:	79e2                	ld	s3,56(sp)
    80003e90:	7a42                	ld	s4,48(sp)
    80003e92:	7aa2                	ld	s5,40(sp)
    80003e94:	7b02                	ld	s6,32(sp)
    80003e96:	6be2                	ld	s7,24(sp)
    80003e98:	6c42                	ld	s8,16(sp)
    80003e9a:	6ca2                	ld	s9,8(sp)
    80003e9c:	6125                	addi	sp,sp,96
    80003e9e:	8082                	ret
      iunlock(ip);
    80003ea0:	854e                	mv	a0,s3
    80003ea2:	00000097          	auipc	ra,0x0
    80003ea6:	aa6080e7          	jalr	-1370(ra) # 80003948 <iunlock>
      return ip;
    80003eaa:	bfe9                	j	80003e84 <namex+0x6a>
      iunlockput(ip);
    80003eac:	854e                	mv	a0,s3
    80003eae:	00000097          	auipc	ra,0x0
    80003eb2:	c3a080e7          	jalr	-966(ra) # 80003ae8 <iunlockput>
      return 0;
    80003eb6:	89e6                	mv	s3,s9
    80003eb8:	b7f1                	j	80003e84 <namex+0x6a>
  len = path - s;
    80003eba:	40b48633          	sub	a2,s1,a1
    80003ebe:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003ec2:	099c5463          	bge	s8,s9,80003f4a <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003ec6:	4639                	li	a2,14
    80003ec8:	8552                	mv	a0,s4
    80003eca:	ffffd097          	auipc	ra,0xffffd
    80003ece:	e5e080e7          	jalr	-418(ra) # 80000d28 <memmove>
  while(*path == '/')
    80003ed2:	0004c783          	lbu	a5,0(s1)
    80003ed6:	01279763          	bne	a5,s2,80003ee4 <namex+0xca>
    path++;
    80003eda:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003edc:	0004c783          	lbu	a5,0(s1)
    80003ee0:	ff278de3          	beq	a5,s2,80003eda <namex+0xc0>
    ilock(ip);
    80003ee4:	854e                	mv	a0,s3
    80003ee6:	00000097          	auipc	ra,0x0
    80003eea:	9a0080e7          	jalr	-1632(ra) # 80003886 <ilock>
    if(ip->type != T_DIR){
    80003eee:	04499783          	lh	a5,68(s3)
    80003ef2:	f97793e3          	bne	a5,s7,80003e78 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003ef6:	000a8563          	beqz	s5,80003f00 <namex+0xe6>
    80003efa:	0004c783          	lbu	a5,0(s1)
    80003efe:	d3cd                	beqz	a5,80003ea0 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f00:	865a                	mv	a2,s6
    80003f02:	85d2                	mv	a1,s4
    80003f04:	854e                	mv	a0,s3
    80003f06:	00000097          	auipc	ra,0x0
    80003f0a:	e64080e7          	jalr	-412(ra) # 80003d6a <dirlookup>
    80003f0e:	8caa                	mv	s9,a0
    80003f10:	dd51                	beqz	a0,80003eac <namex+0x92>
    iunlockput(ip);
    80003f12:	854e                	mv	a0,s3
    80003f14:	00000097          	auipc	ra,0x0
    80003f18:	bd4080e7          	jalr	-1068(ra) # 80003ae8 <iunlockput>
    ip = next;
    80003f1c:	89e6                	mv	s3,s9
  while(*path == '/')
    80003f1e:	0004c783          	lbu	a5,0(s1)
    80003f22:	05279763          	bne	a5,s2,80003f70 <namex+0x156>
    path++;
    80003f26:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f28:	0004c783          	lbu	a5,0(s1)
    80003f2c:	ff278de3          	beq	a5,s2,80003f26 <namex+0x10c>
  if(*path == 0)
    80003f30:	c79d                	beqz	a5,80003f5e <namex+0x144>
    path++;
    80003f32:	85a6                	mv	a1,s1
  len = path - s;
    80003f34:	8cda                	mv	s9,s6
    80003f36:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003f38:	01278963          	beq	a5,s2,80003f4a <namex+0x130>
    80003f3c:	dfbd                	beqz	a5,80003eba <namex+0xa0>
    path++;
    80003f3e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f40:	0004c783          	lbu	a5,0(s1)
    80003f44:	ff279ce3          	bne	a5,s2,80003f3c <namex+0x122>
    80003f48:	bf8d                	j	80003eba <namex+0xa0>
    memmove(name, s, len);
    80003f4a:	2601                	sext.w	a2,a2
    80003f4c:	8552                	mv	a0,s4
    80003f4e:	ffffd097          	auipc	ra,0xffffd
    80003f52:	dda080e7          	jalr	-550(ra) # 80000d28 <memmove>
    name[len] = 0;
    80003f56:	9cd2                	add	s9,s9,s4
    80003f58:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003f5c:	bf9d                	j	80003ed2 <namex+0xb8>
  if(nameiparent){
    80003f5e:	f20a83e3          	beqz	s5,80003e84 <namex+0x6a>
    iput(ip);
    80003f62:	854e                	mv	a0,s3
    80003f64:	00000097          	auipc	ra,0x0
    80003f68:	adc080e7          	jalr	-1316(ra) # 80003a40 <iput>
    return 0;
    80003f6c:	4981                	li	s3,0
    80003f6e:	bf19                	j	80003e84 <namex+0x6a>
  if(*path == 0)
    80003f70:	d7fd                	beqz	a5,80003f5e <namex+0x144>
  while(*path != '/' && *path != 0)
    80003f72:	0004c783          	lbu	a5,0(s1)
    80003f76:	85a6                	mv	a1,s1
    80003f78:	b7d1                	j	80003f3c <namex+0x122>

0000000080003f7a <dirlink>:
{
    80003f7a:	7139                	addi	sp,sp,-64
    80003f7c:	fc06                	sd	ra,56(sp)
    80003f7e:	f822                	sd	s0,48(sp)
    80003f80:	f426                	sd	s1,40(sp)
    80003f82:	f04a                	sd	s2,32(sp)
    80003f84:	ec4e                	sd	s3,24(sp)
    80003f86:	e852                	sd	s4,16(sp)
    80003f88:	0080                	addi	s0,sp,64
    80003f8a:	892a                	mv	s2,a0
    80003f8c:	8a2e                	mv	s4,a1
    80003f8e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f90:	4601                	li	a2,0
    80003f92:	00000097          	auipc	ra,0x0
    80003f96:	dd8080e7          	jalr	-552(ra) # 80003d6a <dirlookup>
    80003f9a:	e93d                	bnez	a0,80004010 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f9c:	04c92483          	lw	s1,76(s2)
    80003fa0:	c49d                	beqz	s1,80003fce <dirlink+0x54>
    80003fa2:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fa4:	4741                	li	a4,16
    80003fa6:	86a6                	mv	a3,s1
    80003fa8:	fc040613          	addi	a2,s0,-64
    80003fac:	4581                	li	a1,0
    80003fae:	854a                	mv	a0,s2
    80003fb0:	00000097          	auipc	ra,0x0
    80003fb4:	b8a080e7          	jalr	-1142(ra) # 80003b3a <readi>
    80003fb8:	47c1                	li	a5,16
    80003fba:	06f51163          	bne	a0,a5,8000401c <dirlink+0xa2>
    if(de.inum == 0)
    80003fbe:	fc045783          	lhu	a5,-64(s0)
    80003fc2:	c791                	beqz	a5,80003fce <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fc4:	24c1                	addiw	s1,s1,16
    80003fc6:	04c92783          	lw	a5,76(s2)
    80003fca:	fcf4ede3          	bltu	s1,a5,80003fa4 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003fce:	4639                	li	a2,14
    80003fd0:	85d2                	mv	a1,s4
    80003fd2:	fc240513          	addi	a0,s0,-62
    80003fd6:	ffffd097          	auipc	ra,0xffffd
    80003fda:	e02080e7          	jalr	-510(ra) # 80000dd8 <strncpy>
  de.inum = inum;
    80003fde:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fe2:	4741                	li	a4,16
    80003fe4:	86a6                	mv	a3,s1
    80003fe6:	fc040613          	addi	a2,s0,-64
    80003fea:	4581                	li	a1,0
    80003fec:	854a                	mv	a0,s2
    80003fee:	00000097          	auipc	ra,0x0
    80003ff2:	c44080e7          	jalr	-956(ra) # 80003c32 <writei>
    80003ff6:	872a                	mv	a4,a0
    80003ff8:	47c1                	li	a5,16
  return 0;
    80003ffa:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ffc:	02f71863          	bne	a4,a5,8000402c <dirlink+0xb2>
}
    80004000:	70e2                	ld	ra,56(sp)
    80004002:	7442                	ld	s0,48(sp)
    80004004:	74a2                	ld	s1,40(sp)
    80004006:	7902                	ld	s2,32(sp)
    80004008:	69e2                	ld	s3,24(sp)
    8000400a:	6a42                	ld	s4,16(sp)
    8000400c:	6121                	addi	sp,sp,64
    8000400e:	8082                	ret
    iput(ip);
    80004010:	00000097          	auipc	ra,0x0
    80004014:	a30080e7          	jalr	-1488(ra) # 80003a40 <iput>
    return -1;
    80004018:	557d                	li	a0,-1
    8000401a:	b7dd                	j	80004000 <dirlink+0x86>
      panic("dirlink read");
    8000401c:	00004517          	auipc	a0,0x4
    80004020:	63450513          	addi	a0,a0,1588 # 80008650 <syscalls+0x1f0>
    80004024:	ffffc097          	auipc	ra,0xffffc
    80004028:	514080e7          	jalr	1300(ra) # 80000538 <panic>
    panic("dirlink");
    8000402c:	00004517          	auipc	a0,0x4
    80004030:	73450513          	addi	a0,a0,1844 # 80008760 <syscalls+0x300>
    80004034:	ffffc097          	auipc	ra,0xffffc
    80004038:	504080e7          	jalr	1284(ra) # 80000538 <panic>

000000008000403c <namei>:

struct inode*
namei(char *path)
{
    8000403c:	1101                	addi	sp,sp,-32
    8000403e:	ec06                	sd	ra,24(sp)
    80004040:	e822                	sd	s0,16(sp)
    80004042:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004044:	fe040613          	addi	a2,s0,-32
    80004048:	4581                	li	a1,0
    8000404a:	00000097          	auipc	ra,0x0
    8000404e:	dd0080e7          	jalr	-560(ra) # 80003e1a <namex>
}
    80004052:	60e2                	ld	ra,24(sp)
    80004054:	6442                	ld	s0,16(sp)
    80004056:	6105                	addi	sp,sp,32
    80004058:	8082                	ret

000000008000405a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000405a:	1141                	addi	sp,sp,-16
    8000405c:	e406                	sd	ra,8(sp)
    8000405e:	e022                	sd	s0,0(sp)
    80004060:	0800                	addi	s0,sp,16
    80004062:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004064:	4585                	li	a1,1
    80004066:	00000097          	auipc	ra,0x0
    8000406a:	db4080e7          	jalr	-588(ra) # 80003e1a <namex>
}
    8000406e:	60a2                	ld	ra,8(sp)
    80004070:	6402                	ld	s0,0(sp)
    80004072:	0141                	addi	sp,sp,16
    80004074:	8082                	ret

0000000080004076 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004076:	1101                	addi	sp,sp,-32
    80004078:	ec06                	sd	ra,24(sp)
    8000407a:	e822                	sd	s0,16(sp)
    8000407c:	e426                	sd	s1,8(sp)
    8000407e:	e04a                	sd	s2,0(sp)
    80004080:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004082:	0001d917          	auipc	s2,0x1d
    80004086:	25690913          	addi	s2,s2,598 # 800212d8 <log>
    8000408a:	01892583          	lw	a1,24(s2)
    8000408e:	02892503          	lw	a0,40(s2)
    80004092:	fffff097          	auipc	ra,0xfffff
    80004096:	ff2080e7          	jalr	-14(ra) # 80003084 <bread>
    8000409a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000409c:	02c92683          	lw	a3,44(s2)
    800040a0:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800040a2:	02d05763          	blez	a3,800040d0 <write_head+0x5a>
    800040a6:	0001d797          	auipc	a5,0x1d
    800040aa:	26278793          	addi	a5,a5,610 # 80021308 <log+0x30>
    800040ae:	05c50713          	addi	a4,a0,92
    800040b2:	36fd                	addiw	a3,a3,-1
    800040b4:	1682                	slli	a3,a3,0x20
    800040b6:	9281                	srli	a3,a3,0x20
    800040b8:	068a                	slli	a3,a3,0x2
    800040ba:	0001d617          	auipc	a2,0x1d
    800040be:	25260613          	addi	a2,a2,594 # 8002130c <log+0x34>
    800040c2:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800040c4:	4390                	lw	a2,0(a5)
    800040c6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800040c8:	0791                	addi	a5,a5,4
    800040ca:	0711                	addi	a4,a4,4
    800040cc:	fed79ce3          	bne	a5,a3,800040c4 <write_head+0x4e>
  }
  bwrite(buf);
    800040d0:	8526                	mv	a0,s1
    800040d2:	fffff097          	auipc	ra,0xfffff
    800040d6:	0a4080e7          	jalr	164(ra) # 80003176 <bwrite>
  brelse(buf);
    800040da:	8526                	mv	a0,s1
    800040dc:	fffff097          	auipc	ra,0xfffff
    800040e0:	0d8080e7          	jalr	216(ra) # 800031b4 <brelse>
}
    800040e4:	60e2                	ld	ra,24(sp)
    800040e6:	6442                	ld	s0,16(sp)
    800040e8:	64a2                	ld	s1,8(sp)
    800040ea:	6902                	ld	s2,0(sp)
    800040ec:	6105                	addi	sp,sp,32
    800040ee:	8082                	ret

00000000800040f0 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800040f0:	0001d797          	auipc	a5,0x1d
    800040f4:	2147a783          	lw	a5,532(a5) # 80021304 <log+0x2c>
    800040f8:	0af05d63          	blez	a5,800041b2 <install_trans+0xc2>
{
    800040fc:	7139                	addi	sp,sp,-64
    800040fe:	fc06                	sd	ra,56(sp)
    80004100:	f822                	sd	s0,48(sp)
    80004102:	f426                	sd	s1,40(sp)
    80004104:	f04a                	sd	s2,32(sp)
    80004106:	ec4e                	sd	s3,24(sp)
    80004108:	e852                	sd	s4,16(sp)
    8000410a:	e456                	sd	s5,8(sp)
    8000410c:	e05a                	sd	s6,0(sp)
    8000410e:	0080                	addi	s0,sp,64
    80004110:	8b2a                	mv	s6,a0
    80004112:	0001da97          	auipc	s5,0x1d
    80004116:	1f6a8a93          	addi	s5,s5,502 # 80021308 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000411a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000411c:	0001d997          	auipc	s3,0x1d
    80004120:	1bc98993          	addi	s3,s3,444 # 800212d8 <log>
    80004124:	a00d                	j	80004146 <install_trans+0x56>
    brelse(lbuf);
    80004126:	854a                	mv	a0,s2
    80004128:	fffff097          	auipc	ra,0xfffff
    8000412c:	08c080e7          	jalr	140(ra) # 800031b4 <brelse>
    brelse(dbuf);
    80004130:	8526                	mv	a0,s1
    80004132:	fffff097          	auipc	ra,0xfffff
    80004136:	082080e7          	jalr	130(ra) # 800031b4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000413a:	2a05                	addiw	s4,s4,1
    8000413c:	0a91                	addi	s5,s5,4
    8000413e:	02c9a783          	lw	a5,44(s3)
    80004142:	04fa5e63          	bge	s4,a5,8000419e <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004146:	0189a583          	lw	a1,24(s3)
    8000414a:	014585bb          	addw	a1,a1,s4
    8000414e:	2585                	addiw	a1,a1,1
    80004150:	0289a503          	lw	a0,40(s3)
    80004154:	fffff097          	auipc	ra,0xfffff
    80004158:	f30080e7          	jalr	-208(ra) # 80003084 <bread>
    8000415c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000415e:	000aa583          	lw	a1,0(s5)
    80004162:	0289a503          	lw	a0,40(s3)
    80004166:	fffff097          	auipc	ra,0xfffff
    8000416a:	f1e080e7          	jalr	-226(ra) # 80003084 <bread>
    8000416e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004170:	40000613          	li	a2,1024
    80004174:	05890593          	addi	a1,s2,88
    80004178:	05850513          	addi	a0,a0,88
    8000417c:	ffffd097          	auipc	ra,0xffffd
    80004180:	bac080e7          	jalr	-1108(ra) # 80000d28 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004184:	8526                	mv	a0,s1
    80004186:	fffff097          	auipc	ra,0xfffff
    8000418a:	ff0080e7          	jalr	-16(ra) # 80003176 <bwrite>
    if(recovering == 0)
    8000418e:	f80b1ce3          	bnez	s6,80004126 <install_trans+0x36>
      bunpin(dbuf);
    80004192:	8526                	mv	a0,s1
    80004194:	fffff097          	auipc	ra,0xfffff
    80004198:	0fa080e7          	jalr	250(ra) # 8000328e <bunpin>
    8000419c:	b769                	j	80004126 <install_trans+0x36>
}
    8000419e:	70e2                	ld	ra,56(sp)
    800041a0:	7442                	ld	s0,48(sp)
    800041a2:	74a2                	ld	s1,40(sp)
    800041a4:	7902                	ld	s2,32(sp)
    800041a6:	69e2                	ld	s3,24(sp)
    800041a8:	6a42                	ld	s4,16(sp)
    800041aa:	6aa2                	ld	s5,8(sp)
    800041ac:	6b02                	ld	s6,0(sp)
    800041ae:	6121                	addi	sp,sp,64
    800041b0:	8082                	ret
    800041b2:	8082                	ret

00000000800041b4 <initlog>:
{
    800041b4:	7179                	addi	sp,sp,-48
    800041b6:	f406                	sd	ra,40(sp)
    800041b8:	f022                	sd	s0,32(sp)
    800041ba:	ec26                	sd	s1,24(sp)
    800041bc:	e84a                	sd	s2,16(sp)
    800041be:	e44e                	sd	s3,8(sp)
    800041c0:	1800                	addi	s0,sp,48
    800041c2:	892a                	mv	s2,a0
    800041c4:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800041c6:	0001d497          	auipc	s1,0x1d
    800041ca:	11248493          	addi	s1,s1,274 # 800212d8 <log>
    800041ce:	00004597          	auipc	a1,0x4
    800041d2:	49258593          	addi	a1,a1,1170 # 80008660 <syscalls+0x200>
    800041d6:	8526                	mv	a0,s1
    800041d8:	ffffd097          	auipc	ra,0xffffd
    800041dc:	968080e7          	jalr	-1688(ra) # 80000b40 <initlock>
  log.start = sb->logstart;
    800041e0:	0149a583          	lw	a1,20(s3)
    800041e4:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800041e6:	0109a783          	lw	a5,16(s3)
    800041ea:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800041ec:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800041f0:	854a                	mv	a0,s2
    800041f2:	fffff097          	auipc	ra,0xfffff
    800041f6:	e92080e7          	jalr	-366(ra) # 80003084 <bread>
  log.lh.n = lh->n;
    800041fa:	4d34                	lw	a3,88(a0)
    800041fc:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800041fe:	02d05563          	blez	a3,80004228 <initlog+0x74>
    80004202:	05c50793          	addi	a5,a0,92
    80004206:	0001d717          	auipc	a4,0x1d
    8000420a:	10270713          	addi	a4,a4,258 # 80021308 <log+0x30>
    8000420e:	36fd                	addiw	a3,a3,-1
    80004210:	1682                	slli	a3,a3,0x20
    80004212:	9281                	srli	a3,a3,0x20
    80004214:	068a                	slli	a3,a3,0x2
    80004216:	06050613          	addi	a2,a0,96
    8000421a:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000421c:	4390                	lw	a2,0(a5)
    8000421e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004220:	0791                	addi	a5,a5,4
    80004222:	0711                	addi	a4,a4,4
    80004224:	fed79ce3          	bne	a5,a3,8000421c <initlog+0x68>
  brelse(buf);
    80004228:	fffff097          	auipc	ra,0xfffff
    8000422c:	f8c080e7          	jalr	-116(ra) # 800031b4 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004230:	4505                	li	a0,1
    80004232:	00000097          	auipc	ra,0x0
    80004236:	ebe080e7          	jalr	-322(ra) # 800040f0 <install_trans>
  log.lh.n = 0;
    8000423a:	0001d797          	auipc	a5,0x1d
    8000423e:	0c07a523          	sw	zero,202(a5) # 80021304 <log+0x2c>
  write_head(); // clear the log
    80004242:	00000097          	auipc	ra,0x0
    80004246:	e34080e7          	jalr	-460(ra) # 80004076 <write_head>
}
    8000424a:	70a2                	ld	ra,40(sp)
    8000424c:	7402                	ld	s0,32(sp)
    8000424e:	64e2                	ld	s1,24(sp)
    80004250:	6942                	ld	s2,16(sp)
    80004252:	69a2                	ld	s3,8(sp)
    80004254:	6145                	addi	sp,sp,48
    80004256:	8082                	ret

0000000080004258 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004258:	1101                	addi	sp,sp,-32
    8000425a:	ec06                	sd	ra,24(sp)
    8000425c:	e822                	sd	s0,16(sp)
    8000425e:	e426                	sd	s1,8(sp)
    80004260:	e04a                	sd	s2,0(sp)
    80004262:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004264:	0001d517          	auipc	a0,0x1d
    80004268:	07450513          	addi	a0,a0,116 # 800212d8 <log>
    8000426c:	ffffd097          	auipc	ra,0xffffd
    80004270:	964080e7          	jalr	-1692(ra) # 80000bd0 <acquire>
  while(1){
    if(log.committing){
    80004274:	0001d497          	auipc	s1,0x1d
    80004278:	06448493          	addi	s1,s1,100 # 800212d8 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000427c:	4979                	li	s2,30
    8000427e:	a039                	j	8000428c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004280:	85a6                	mv	a1,s1
    80004282:	8526                	mv	a0,s1
    80004284:	ffffe097          	auipc	ra,0xffffe
    80004288:	dd2080e7          	jalr	-558(ra) # 80002056 <sleep>
    if(log.committing){
    8000428c:	50dc                	lw	a5,36(s1)
    8000428e:	fbed                	bnez	a5,80004280 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004290:	509c                	lw	a5,32(s1)
    80004292:	0017871b          	addiw	a4,a5,1
    80004296:	0007069b          	sext.w	a3,a4
    8000429a:	0027179b          	slliw	a5,a4,0x2
    8000429e:	9fb9                	addw	a5,a5,a4
    800042a0:	0017979b          	slliw	a5,a5,0x1
    800042a4:	54d8                	lw	a4,44(s1)
    800042a6:	9fb9                	addw	a5,a5,a4
    800042a8:	00f95963          	bge	s2,a5,800042ba <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800042ac:	85a6                	mv	a1,s1
    800042ae:	8526                	mv	a0,s1
    800042b0:	ffffe097          	auipc	ra,0xffffe
    800042b4:	da6080e7          	jalr	-602(ra) # 80002056 <sleep>
    800042b8:	bfd1                	j	8000428c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800042ba:	0001d517          	auipc	a0,0x1d
    800042be:	01e50513          	addi	a0,a0,30 # 800212d8 <log>
    800042c2:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800042c4:	ffffd097          	auipc	ra,0xffffd
    800042c8:	9c0080e7          	jalr	-1600(ra) # 80000c84 <release>
      break;
    }
  }
}
    800042cc:	60e2                	ld	ra,24(sp)
    800042ce:	6442                	ld	s0,16(sp)
    800042d0:	64a2                	ld	s1,8(sp)
    800042d2:	6902                	ld	s2,0(sp)
    800042d4:	6105                	addi	sp,sp,32
    800042d6:	8082                	ret

00000000800042d8 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800042d8:	7139                	addi	sp,sp,-64
    800042da:	fc06                	sd	ra,56(sp)
    800042dc:	f822                	sd	s0,48(sp)
    800042de:	f426                	sd	s1,40(sp)
    800042e0:	f04a                	sd	s2,32(sp)
    800042e2:	ec4e                	sd	s3,24(sp)
    800042e4:	e852                	sd	s4,16(sp)
    800042e6:	e456                	sd	s5,8(sp)
    800042e8:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800042ea:	0001d497          	auipc	s1,0x1d
    800042ee:	fee48493          	addi	s1,s1,-18 # 800212d8 <log>
    800042f2:	8526                	mv	a0,s1
    800042f4:	ffffd097          	auipc	ra,0xffffd
    800042f8:	8dc080e7          	jalr	-1828(ra) # 80000bd0 <acquire>
  log.outstanding -= 1;
    800042fc:	509c                	lw	a5,32(s1)
    800042fe:	37fd                	addiw	a5,a5,-1
    80004300:	0007891b          	sext.w	s2,a5
    80004304:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004306:	50dc                	lw	a5,36(s1)
    80004308:	e7b9                	bnez	a5,80004356 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000430a:	04091e63          	bnez	s2,80004366 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000430e:	0001d497          	auipc	s1,0x1d
    80004312:	fca48493          	addi	s1,s1,-54 # 800212d8 <log>
    80004316:	4785                	li	a5,1
    80004318:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000431a:	8526                	mv	a0,s1
    8000431c:	ffffd097          	auipc	ra,0xffffd
    80004320:	968080e7          	jalr	-1688(ra) # 80000c84 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004324:	54dc                	lw	a5,44(s1)
    80004326:	06f04763          	bgtz	a5,80004394 <end_op+0xbc>
    acquire(&log.lock);
    8000432a:	0001d497          	auipc	s1,0x1d
    8000432e:	fae48493          	addi	s1,s1,-82 # 800212d8 <log>
    80004332:	8526                	mv	a0,s1
    80004334:	ffffd097          	auipc	ra,0xffffd
    80004338:	89c080e7          	jalr	-1892(ra) # 80000bd0 <acquire>
    log.committing = 0;
    8000433c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004340:	8526                	mv	a0,s1
    80004342:	ffffe097          	auipc	ra,0xffffe
    80004346:	ea0080e7          	jalr	-352(ra) # 800021e2 <wakeup>
    release(&log.lock);
    8000434a:	8526                	mv	a0,s1
    8000434c:	ffffd097          	auipc	ra,0xffffd
    80004350:	938080e7          	jalr	-1736(ra) # 80000c84 <release>
}
    80004354:	a03d                	j	80004382 <end_op+0xaa>
    panic("log.committing");
    80004356:	00004517          	auipc	a0,0x4
    8000435a:	31250513          	addi	a0,a0,786 # 80008668 <syscalls+0x208>
    8000435e:	ffffc097          	auipc	ra,0xffffc
    80004362:	1da080e7          	jalr	474(ra) # 80000538 <panic>
    wakeup(&log);
    80004366:	0001d497          	auipc	s1,0x1d
    8000436a:	f7248493          	addi	s1,s1,-142 # 800212d8 <log>
    8000436e:	8526                	mv	a0,s1
    80004370:	ffffe097          	auipc	ra,0xffffe
    80004374:	e72080e7          	jalr	-398(ra) # 800021e2 <wakeup>
  release(&log.lock);
    80004378:	8526                	mv	a0,s1
    8000437a:	ffffd097          	auipc	ra,0xffffd
    8000437e:	90a080e7          	jalr	-1782(ra) # 80000c84 <release>
}
    80004382:	70e2                	ld	ra,56(sp)
    80004384:	7442                	ld	s0,48(sp)
    80004386:	74a2                	ld	s1,40(sp)
    80004388:	7902                	ld	s2,32(sp)
    8000438a:	69e2                	ld	s3,24(sp)
    8000438c:	6a42                	ld	s4,16(sp)
    8000438e:	6aa2                	ld	s5,8(sp)
    80004390:	6121                	addi	sp,sp,64
    80004392:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004394:	0001da97          	auipc	s5,0x1d
    80004398:	f74a8a93          	addi	s5,s5,-140 # 80021308 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000439c:	0001da17          	auipc	s4,0x1d
    800043a0:	f3ca0a13          	addi	s4,s4,-196 # 800212d8 <log>
    800043a4:	018a2583          	lw	a1,24(s4)
    800043a8:	012585bb          	addw	a1,a1,s2
    800043ac:	2585                	addiw	a1,a1,1
    800043ae:	028a2503          	lw	a0,40(s4)
    800043b2:	fffff097          	auipc	ra,0xfffff
    800043b6:	cd2080e7          	jalr	-814(ra) # 80003084 <bread>
    800043ba:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800043bc:	000aa583          	lw	a1,0(s5)
    800043c0:	028a2503          	lw	a0,40(s4)
    800043c4:	fffff097          	auipc	ra,0xfffff
    800043c8:	cc0080e7          	jalr	-832(ra) # 80003084 <bread>
    800043cc:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800043ce:	40000613          	li	a2,1024
    800043d2:	05850593          	addi	a1,a0,88
    800043d6:	05848513          	addi	a0,s1,88
    800043da:	ffffd097          	auipc	ra,0xffffd
    800043de:	94e080e7          	jalr	-1714(ra) # 80000d28 <memmove>
    bwrite(to);  // write the log
    800043e2:	8526                	mv	a0,s1
    800043e4:	fffff097          	auipc	ra,0xfffff
    800043e8:	d92080e7          	jalr	-622(ra) # 80003176 <bwrite>
    brelse(from);
    800043ec:	854e                	mv	a0,s3
    800043ee:	fffff097          	auipc	ra,0xfffff
    800043f2:	dc6080e7          	jalr	-570(ra) # 800031b4 <brelse>
    brelse(to);
    800043f6:	8526                	mv	a0,s1
    800043f8:	fffff097          	auipc	ra,0xfffff
    800043fc:	dbc080e7          	jalr	-580(ra) # 800031b4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004400:	2905                	addiw	s2,s2,1
    80004402:	0a91                	addi	s5,s5,4
    80004404:	02ca2783          	lw	a5,44(s4)
    80004408:	f8f94ee3          	blt	s2,a5,800043a4 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000440c:	00000097          	auipc	ra,0x0
    80004410:	c6a080e7          	jalr	-918(ra) # 80004076 <write_head>
    install_trans(0); // Now install writes to home locations
    80004414:	4501                	li	a0,0
    80004416:	00000097          	auipc	ra,0x0
    8000441a:	cda080e7          	jalr	-806(ra) # 800040f0 <install_trans>
    log.lh.n = 0;
    8000441e:	0001d797          	auipc	a5,0x1d
    80004422:	ee07a323          	sw	zero,-282(a5) # 80021304 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004426:	00000097          	auipc	ra,0x0
    8000442a:	c50080e7          	jalr	-944(ra) # 80004076 <write_head>
    8000442e:	bdf5                	j	8000432a <end_op+0x52>

0000000080004430 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004430:	1101                	addi	sp,sp,-32
    80004432:	ec06                	sd	ra,24(sp)
    80004434:	e822                	sd	s0,16(sp)
    80004436:	e426                	sd	s1,8(sp)
    80004438:	e04a                	sd	s2,0(sp)
    8000443a:	1000                	addi	s0,sp,32
    8000443c:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000443e:	0001d917          	auipc	s2,0x1d
    80004442:	e9a90913          	addi	s2,s2,-358 # 800212d8 <log>
    80004446:	854a                	mv	a0,s2
    80004448:	ffffc097          	auipc	ra,0xffffc
    8000444c:	788080e7          	jalr	1928(ra) # 80000bd0 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004450:	02c92603          	lw	a2,44(s2)
    80004454:	47f5                	li	a5,29
    80004456:	06c7c563          	blt	a5,a2,800044c0 <log_write+0x90>
    8000445a:	0001d797          	auipc	a5,0x1d
    8000445e:	e9a7a783          	lw	a5,-358(a5) # 800212f4 <log+0x1c>
    80004462:	37fd                	addiw	a5,a5,-1
    80004464:	04f65e63          	bge	a2,a5,800044c0 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004468:	0001d797          	auipc	a5,0x1d
    8000446c:	e907a783          	lw	a5,-368(a5) # 800212f8 <log+0x20>
    80004470:	06f05063          	blez	a5,800044d0 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004474:	4781                	li	a5,0
    80004476:	06c05563          	blez	a2,800044e0 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000447a:	44cc                	lw	a1,12(s1)
    8000447c:	0001d717          	auipc	a4,0x1d
    80004480:	e8c70713          	addi	a4,a4,-372 # 80021308 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004484:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004486:	4314                	lw	a3,0(a4)
    80004488:	04b68c63          	beq	a3,a1,800044e0 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000448c:	2785                	addiw	a5,a5,1
    8000448e:	0711                	addi	a4,a4,4
    80004490:	fef61be3          	bne	a2,a5,80004486 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004494:	0621                	addi	a2,a2,8
    80004496:	060a                	slli	a2,a2,0x2
    80004498:	0001d797          	auipc	a5,0x1d
    8000449c:	e4078793          	addi	a5,a5,-448 # 800212d8 <log>
    800044a0:	963e                	add	a2,a2,a5
    800044a2:	44dc                	lw	a5,12(s1)
    800044a4:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800044a6:	8526                	mv	a0,s1
    800044a8:	fffff097          	auipc	ra,0xfffff
    800044ac:	daa080e7          	jalr	-598(ra) # 80003252 <bpin>
    log.lh.n++;
    800044b0:	0001d717          	auipc	a4,0x1d
    800044b4:	e2870713          	addi	a4,a4,-472 # 800212d8 <log>
    800044b8:	575c                	lw	a5,44(a4)
    800044ba:	2785                	addiw	a5,a5,1
    800044bc:	d75c                	sw	a5,44(a4)
    800044be:	a835                	j	800044fa <log_write+0xca>
    panic("too big a transaction");
    800044c0:	00004517          	auipc	a0,0x4
    800044c4:	1b850513          	addi	a0,a0,440 # 80008678 <syscalls+0x218>
    800044c8:	ffffc097          	auipc	ra,0xffffc
    800044cc:	070080e7          	jalr	112(ra) # 80000538 <panic>
    panic("log_write outside of trans");
    800044d0:	00004517          	auipc	a0,0x4
    800044d4:	1c050513          	addi	a0,a0,448 # 80008690 <syscalls+0x230>
    800044d8:	ffffc097          	auipc	ra,0xffffc
    800044dc:	060080e7          	jalr	96(ra) # 80000538 <panic>
  log.lh.block[i] = b->blockno;
    800044e0:	00878713          	addi	a4,a5,8
    800044e4:	00271693          	slli	a3,a4,0x2
    800044e8:	0001d717          	auipc	a4,0x1d
    800044ec:	df070713          	addi	a4,a4,-528 # 800212d8 <log>
    800044f0:	9736                	add	a4,a4,a3
    800044f2:	44d4                	lw	a3,12(s1)
    800044f4:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800044f6:	faf608e3          	beq	a2,a5,800044a6 <log_write+0x76>
  }
  release(&log.lock);
    800044fa:	0001d517          	auipc	a0,0x1d
    800044fe:	dde50513          	addi	a0,a0,-546 # 800212d8 <log>
    80004502:	ffffc097          	auipc	ra,0xffffc
    80004506:	782080e7          	jalr	1922(ra) # 80000c84 <release>
}
    8000450a:	60e2                	ld	ra,24(sp)
    8000450c:	6442                	ld	s0,16(sp)
    8000450e:	64a2                	ld	s1,8(sp)
    80004510:	6902                	ld	s2,0(sp)
    80004512:	6105                	addi	sp,sp,32
    80004514:	8082                	ret

0000000080004516 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004516:	1101                	addi	sp,sp,-32
    80004518:	ec06                	sd	ra,24(sp)
    8000451a:	e822                	sd	s0,16(sp)
    8000451c:	e426                	sd	s1,8(sp)
    8000451e:	e04a                	sd	s2,0(sp)
    80004520:	1000                	addi	s0,sp,32
    80004522:	84aa                	mv	s1,a0
    80004524:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004526:	00004597          	auipc	a1,0x4
    8000452a:	18a58593          	addi	a1,a1,394 # 800086b0 <syscalls+0x250>
    8000452e:	0521                	addi	a0,a0,8
    80004530:	ffffc097          	auipc	ra,0xffffc
    80004534:	610080e7          	jalr	1552(ra) # 80000b40 <initlock>
  lk->name = name;
    80004538:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000453c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004540:	0204a423          	sw	zero,40(s1)
}
    80004544:	60e2                	ld	ra,24(sp)
    80004546:	6442                	ld	s0,16(sp)
    80004548:	64a2                	ld	s1,8(sp)
    8000454a:	6902                	ld	s2,0(sp)
    8000454c:	6105                	addi	sp,sp,32
    8000454e:	8082                	ret

0000000080004550 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004550:	1101                	addi	sp,sp,-32
    80004552:	ec06                	sd	ra,24(sp)
    80004554:	e822                	sd	s0,16(sp)
    80004556:	e426                	sd	s1,8(sp)
    80004558:	e04a                	sd	s2,0(sp)
    8000455a:	1000                	addi	s0,sp,32
    8000455c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000455e:	00850913          	addi	s2,a0,8
    80004562:	854a                	mv	a0,s2
    80004564:	ffffc097          	auipc	ra,0xffffc
    80004568:	66c080e7          	jalr	1644(ra) # 80000bd0 <acquire>
  while (lk->locked) {
    8000456c:	409c                	lw	a5,0(s1)
    8000456e:	cb89                	beqz	a5,80004580 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004570:	85ca                	mv	a1,s2
    80004572:	8526                	mv	a0,s1
    80004574:	ffffe097          	auipc	ra,0xffffe
    80004578:	ae2080e7          	jalr	-1310(ra) # 80002056 <sleep>
  while (lk->locked) {
    8000457c:	409c                	lw	a5,0(s1)
    8000457e:	fbed                	bnez	a5,80004570 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004580:	4785                	li	a5,1
    80004582:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004584:	ffffd097          	auipc	ra,0xffffd
    80004588:	412080e7          	jalr	1042(ra) # 80001996 <myproc>
    8000458c:	591c                	lw	a5,48(a0)
    8000458e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004590:	854a                	mv	a0,s2
    80004592:	ffffc097          	auipc	ra,0xffffc
    80004596:	6f2080e7          	jalr	1778(ra) # 80000c84 <release>
}
    8000459a:	60e2                	ld	ra,24(sp)
    8000459c:	6442                	ld	s0,16(sp)
    8000459e:	64a2                	ld	s1,8(sp)
    800045a0:	6902                	ld	s2,0(sp)
    800045a2:	6105                	addi	sp,sp,32
    800045a4:	8082                	ret

00000000800045a6 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800045a6:	1101                	addi	sp,sp,-32
    800045a8:	ec06                	sd	ra,24(sp)
    800045aa:	e822                	sd	s0,16(sp)
    800045ac:	e426                	sd	s1,8(sp)
    800045ae:	e04a                	sd	s2,0(sp)
    800045b0:	1000                	addi	s0,sp,32
    800045b2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045b4:	00850913          	addi	s2,a0,8
    800045b8:	854a                	mv	a0,s2
    800045ba:	ffffc097          	auipc	ra,0xffffc
    800045be:	616080e7          	jalr	1558(ra) # 80000bd0 <acquire>
  lk->locked = 0;
    800045c2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045c6:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800045ca:	8526                	mv	a0,s1
    800045cc:	ffffe097          	auipc	ra,0xffffe
    800045d0:	c16080e7          	jalr	-1002(ra) # 800021e2 <wakeup>
  release(&lk->lk);
    800045d4:	854a                	mv	a0,s2
    800045d6:	ffffc097          	auipc	ra,0xffffc
    800045da:	6ae080e7          	jalr	1710(ra) # 80000c84 <release>
}
    800045de:	60e2                	ld	ra,24(sp)
    800045e0:	6442                	ld	s0,16(sp)
    800045e2:	64a2                	ld	s1,8(sp)
    800045e4:	6902                	ld	s2,0(sp)
    800045e6:	6105                	addi	sp,sp,32
    800045e8:	8082                	ret

00000000800045ea <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800045ea:	7179                	addi	sp,sp,-48
    800045ec:	f406                	sd	ra,40(sp)
    800045ee:	f022                	sd	s0,32(sp)
    800045f0:	ec26                	sd	s1,24(sp)
    800045f2:	e84a                	sd	s2,16(sp)
    800045f4:	e44e                	sd	s3,8(sp)
    800045f6:	1800                	addi	s0,sp,48
    800045f8:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800045fa:	00850913          	addi	s2,a0,8
    800045fe:	854a                	mv	a0,s2
    80004600:	ffffc097          	auipc	ra,0xffffc
    80004604:	5d0080e7          	jalr	1488(ra) # 80000bd0 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004608:	409c                	lw	a5,0(s1)
    8000460a:	ef99                	bnez	a5,80004628 <holdingsleep+0x3e>
    8000460c:	4481                	li	s1,0
  release(&lk->lk);
    8000460e:	854a                	mv	a0,s2
    80004610:	ffffc097          	auipc	ra,0xffffc
    80004614:	674080e7          	jalr	1652(ra) # 80000c84 <release>
  return r;
}
    80004618:	8526                	mv	a0,s1
    8000461a:	70a2                	ld	ra,40(sp)
    8000461c:	7402                	ld	s0,32(sp)
    8000461e:	64e2                	ld	s1,24(sp)
    80004620:	6942                	ld	s2,16(sp)
    80004622:	69a2                	ld	s3,8(sp)
    80004624:	6145                	addi	sp,sp,48
    80004626:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004628:	0284a983          	lw	s3,40(s1)
    8000462c:	ffffd097          	auipc	ra,0xffffd
    80004630:	36a080e7          	jalr	874(ra) # 80001996 <myproc>
    80004634:	5904                	lw	s1,48(a0)
    80004636:	413484b3          	sub	s1,s1,s3
    8000463a:	0014b493          	seqz	s1,s1
    8000463e:	bfc1                	j	8000460e <holdingsleep+0x24>

0000000080004640 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004640:	1141                	addi	sp,sp,-16
    80004642:	e406                	sd	ra,8(sp)
    80004644:	e022                	sd	s0,0(sp)
    80004646:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004648:	00004597          	auipc	a1,0x4
    8000464c:	07858593          	addi	a1,a1,120 # 800086c0 <syscalls+0x260>
    80004650:	0001d517          	auipc	a0,0x1d
    80004654:	dd050513          	addi	a0,a0,-560 # 80021420 <ftable>
    80004658:	ffffc097          	auipc	ra,0xffffc
    8000465c:	4e8080e7          	jalr	1256(ra) # 80000b40 <initlock>
}
    80004660:	60a2                	ld	ra,8(sp)
    80004662:	6402                	ld	s0,0(sp)
    80004664:	0141                	addi	sp,sp,16
    80004666:	8082                	ret

0000000080004668 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004668:	1101                	addi	sp,sp,-32
    8000466a:	ec06                	sd	ra,24(sp)
    8000466c:	e822                	sd	s0,16(sp)
    8000466e:	e426                	sd	s1,8(sp)
    80004670:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004672:	0001d517          	auipc	a0,0x1d
    80004676:	dae50513          	addi	a0,a0,-594 # 80021420 <ftable>
    8000467a:	ffffc097          	auipc	ra,0xffffc
    8000467e:	556080e7          	jalr	1366(ra) # 80000bd0 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004682:	0001d497          	auipc	s1,0x1d
    80004686:	db648493          	addi	s1,s1,-586 # 80021438 <ftable+0x18>
    8000468a:	0001e717          	auipc	a4,0x1e
    8000468e:	d4e70713          	addi	a4,a4,-690 # 800223d8 <ftable+0xfb8>
    if(f->ref == 0){
    80004692:	40dc                	lw	a5,4(s1)
    80004694:	cf99                	beqz	a5,800046b2 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004696:	02848493          	addi	s1,s1,40
    8000469a:	fee49ce3          	bne	s1,a4,80004692 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000469e:	0001d517          	auipc	a0,0x1d
    800046a2:	d8250513          	addi	a0,a0,-638 # 80021420 <ftable>
    800046a6:	ffffc097          	auipc	ra,0xffffc
    800046aa:	5de080e7          	jalr	1502(ra) # 80000c84 <release>
  return 0;
    800046ae:	4481                	li	s1,0
    800046b0:	a819                	j	800046c6 <filealloc+0x5e>
      f->ref = 1;
    800046b2:	4785                	li	a5,1
    800046b4:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800046b6:	0001d517          	auipc	a0,0x1d
    800046ba:	d6a50513          	addi	a0,a0,-662 # 80021420 <ftable>
    800046be:	ffffc097          	auipc	ra,0xffffc
    800046c2:	5c6080e7          	jalr	1478(ra) # 80000c84 <release>
}
    800046c6:	8526                	mv	a0,s1
    800046c8:	60e2                	ld	ra,24(sp)
    800046ca:	6442                	ld	s0,16(sp)
    800046cc:	64a2                	ld	s1,8(sp)
    800046ce:	6105                	addi	sp,sp,32
    800046d0:	8082                	ret

00000000800046d2 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800046d2:	1101                	addi	sp,sp,-32
    800046d4:	ec06                	sd	ra,24(sp)
    800046d6:	e822                	sd	s0,16(sp)
    800046d8:	e426                	sd	s1,8(sp)
    800046da:	1000                	addi	s0,sp,32
    800046dc:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800046de:	0001d517          	auipc	a0,0x1d
    800046e2:	d4250513          	addi	a0,a0,-702 # 80021420 <ftable>
    800046e6:	ffffc097          	auipc	ra,0xffffc
    800046ea:	4ea080e7          	jalr	1258(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    800046ee:	40dc                	lw	a5,4(s1)
    800046f0:	02f05263          	blez	a5,80004714 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800046f4:	2785                	addiw	a5,a5,1
    800046f6:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800046f8:	0001d517          	auipc	a0,0x1d
    800046fc:	d2850513          	addi	a0,a0,-728 # 80021420 <ftable>
    80004700:	ffffc097          	auipc	ra,0xffffc
    80004704:	584080e7          	jalr	1412(ra) # 80000c84 <release>
  return f;
}
    80004708:	8526                	mv	a0,s1
    8000470a:	60e2                	ld	ra,24(sp)
    8000470c:	6442                	ld	s0,16(sp)
    8000470e:	64a2                	ld	s1,8(sp)
    80004710:	6105                	addi	sp,sp,32
    80004712:	8082                	ret
    panic("filedup");
    80004714:	00004517          	auipc	a0,0x4
    80004718:	fb450513          	addi	a0,a0,-76 # 800086c8 <syscalls+0x268>
    8000471c:	ffffc097          	auipc	ra,0xffffc
    80004720:	e1c080e7          	jalr	-484(ra) # 80000538 <panic>

0000000080004724 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004724:	7139                	addi	sp,sp,-64
    80004726:	fc06                	sd	ra,56(sp)
    80004728:	f822                	sd	s0,48(sp)
    8000472a:	f426                	sd	s1,40(sp)
    8000472c:	f04a                	sd	s2,32(sp)
    8000472e:	ec4e                	sd	s3,24(sp)
    80004730:	e852                	sd	s4,16(sp)
    80004732:	e456                	sd	s5,8(sp)
    80004734:	0080                	addi	s0,sp,64
    80004736:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004738:	0001d517          	auipc	a0,0x1d
    8000473c:	ce850513          	addi	a0,a0,-792 # 80021420 <ftable>
    80004740:	ffffc097          	auipc	ra,0xffffc
    80004744:	490080e7          	jalr	1168(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    80004748:	40dc                	lw	a5,4(s1)
    8000474a:	06f05163          	blez	a5,800047ac <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000474e:	37fd                	addiw	a5,a5,-1
    80004750:	0007871b          	sext.w	a4,a5
    80004754:	c0dc                	sw	a5,4(s1)
    80004756:	06e04363          	bgtz	a4,800047bc <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000475a:	0004a903          	lw	s2,0(s1)
    8000475e:	0094ca83          	lbu	s5,9(s1)
    80004762:	0104ba03          	ld	s4,16(s1)
    80004766:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000476a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000476e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004772:	0001d517          	auipc	a0,0x1d
    80004776:	cae50513          	addi	a0,a0,-850 # 80021420 <ftable>
    8000477a:	ffffc097          	auipc	ra,0xffffc
    8000477e:	50a080e7          	jalr	1290(ra) # 80000c84 <release>

  if(ff.type == FD_PIPE){
    80004782:	4785                	li	a5,1
    80004784:	04f90d63          	beq	s2,a5,800047de <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004788:	3979                	addiw	s2,s2,-2
    8000478a:	4785                	li	a5,1
    8000478c:	0527e063          	bltu	a5,s2,800047cc <fileclose+0xa8>
    begin_op();
    80004790:	00000097          	auipc	ra,0x0
    80004794:	ac8080e7          	jalr	-1336(ra) # 80004258 <begin_op>
    iput(ff.ip);
    80004798:	854e                	mv	a0,s3
    8000479a:	fffff097          	auipc	ra,0xfffff
    8000479e:	2a6080e7          	jalr	678(ra) # 80003a40 <iput>
    end_op();
    800047a2:	00000097          	auipc	ra,0x0
    800047a6:	b36080e7          	jalr	-1226(ra) # 800042d8 <end_op>
    800047aa:	a00d                	j	800047cc <fileclose+0xa8>
    panic("fileclose");
    800047ac:	00004517          	auipc	a0,0x4
    800047b0:	f2450513          	addi	a0,a0,-220 # 800086d0 <syscalls+0x270>
    800047b4:	ffffc097          	auipc	ra,0xffffc
    800047b8:	d84080e7          	jalr	-636(ra) # 80000538 <panic>
    release(&ftable.lock);
    800047bc:	0001d517          	auipc	a0,0x1d
    800047c0:	c6450513          	addi	a0,a0,-924 # 80021420 <ftable>
    800047c4:	ffffc097          	auipc	ra,0xffffc
    800047c8:	4c0080e7          	jalr	1216(ra) # 80000c84 <release>
  }
}
    800047cc:	70e2                	ld	ra,56(sp)
    800047ce:	7442                	ld	s0,48(sp)
    800047d0:	74a2                	ld	s1,40(sp)
    800047d2:	7902                	ld	s2,32(sp)
    800047d4:	69e2                	ld	s3,24(sp)
    800047d6:	6a42                	ld	s4,16(sp)
    800047d8:	6aa2                	ld	s5,8(sp)
    800047da:	6121                	addi	sp,sp,64
    800047dc:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800047de:	85d6                	mv	a1,s5
    800047e0:	8552                	mv	a0,s4
    800047e2:	00000097          	auipc	ra,0x0
    800047e6:	34c080e7          	jalr	844(ra) # 80004b2e <pipeclose>
    800047ea:	b7cd                	j	800047cc <fileclose+0xa8>

00000000800047ec <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800047ec:	715d                	addi	sp,sp,-80
    800047ee:	e486                	sd	ra,72(sp)
    800047f0:	e0a2                	sd	s0,64(sp)
    800047f2:	fc26                	sd	s1,56(sp)
    800047f4:	f84a                	sd	s2,48(sp)
    800047f6:	f44e                	sd	s3,40(sp)
    800047f8:	0880                	addi	s0,sp,80
    800047fa:	84aa                	mv	s1,a0
    800047fc:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800047fe:	ffffd097          	auipc	ra,0xffffd
    80004802:	198080e7          	jalr	408(ra) # 80001996 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004806:	409c                	lw	a5,0(s1)
    80004808:	37f9                	addiw	a5,a5,-2
    8000480a:	4705                	li	a4,1
    8000480c:	04f76763          	bltu	a4,a5,8000485a <filestat+0x6e>
    80004810:	892a                	mv	s2,a0
    ilock(f->ip);
    80004812:	6c88                	ld	a0,24(s1)
    80004814:	fffff097          	auipc	ra,0xfffff
    80004818:	072080e7          	jalr	114(ra) # 80003886 <ilock>
    stati(f->ip, &st);
    8000481c:	fb840593          	addi	a1,s0,-72
    80004820:	6c88                	ld	a0,24(s1)
    80004822:	fffff097          	auipc	ra,0xfffff
    80004826:	2ee080e7          	jalr	750(ra) # 80003b10 <stati>
    iunlock(f->ip);
    8000482a:	6c88                	ld	a0,24(s1)
    8000482c:	fffff097          	auipc	ra,0xfffff
    80004830:	11c080e7          	jalr	284(ra) # 80003948 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004834:	46e1                	li	a3,24
    80004836:	fb840613          	addi	a2,s0,-72
    8000483a:	85ce                	mv	a1,s3
    8000483c:	05093503          	ld	a0,80(s2)
    80004840:	ffffd097          	auipc	ra,0xffffd
    80004844:	e16080e7          	jalr	-490(ra) # 80001656 <copyout>
    80004848:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000484c:	60a6                	ld	ra,72(sp)
    8000484e:	6406                	ld	s0,64(sp)
    80004850:	74e2                	ld	s1,56(sp)
    80004852:	7942                	ld	s2,48(sp)
    80004854:	79a2                	ld	s3,40(sp)
    80004856:	6161                	addi	sp,sp,80
    80004858:	8082                	ret
  return -1;
    8000485a:	557d                	li	a0,-1
    8000485c:	bfc5                	j	8000484c <filestat+0x60>

000000008000485e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000485e:	7179                	addi	sp,sp,-48
    80004860:	f406                	sd	ra,40(sp)
    80004862:	f022                	sd	s0,32(sp)
    80004864:	ec26                	sd	s1,24(sp)
    80004866:	e84a                	sd	s2,16(sp)
    80004868:	e44e                	sd	s3,8(sp)
    8000486a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000486c:	00854783          	lbu	a5,8(a0)
    80004870:	c3d5                	beqz	a5,80004914 <fileread+0xb6>
    80004872:	84aa                	mv	s1,a0
    80004874:	89ae                	mv	s3,a1
    80004876:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004878:	411c                	lw	a5,0(a0)
    8000487a:	4705                	li	a4,1
    8000487c:	04e78963          	beq	a5,a4,800048ce <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004880:	470d                	li	a4,3
    80004882:	04e78d63          	beq	a5,a4,800048dc <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004886:	4709                	li	a4,2
    80004888:	06e79e63          	bne	a5,a4,80004904 <fileread+0xa6>
    ilock(f->ip);
    8000488c:	6d08                	ld	a0,24(a0)
    8000488e:	fffff097          	auipc	ra,0xfffff
    80004892:	ff8080e7          	jalr	-8(ra) # 80003886 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004896:	874a                	mv	a4,s2
    80004898:	5094                	lw	a3,32(s1)
    8000489a:	864e                	mv	a2,s3
    8000489c:	4585                	li	a1,1
    8000489e:	6c88                	ld	a0,24(s1)
    800048a0:	fffff097          	auipc	ra,0xfffff
    800048a4:	29a080e7          	jalr	666(ra) # 80003b3a <readi>
    800048a8:	892a                	mv	s2,a0
    800048aa:	00a05563          	blez	a0,800048b4 <fileread+0x56>
      f->off += r;
    800048ae:	509c                	lw	a5,32(s1)
    800048b0:	9fa9                	addw	a5,a5,a0
    800048b2:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800048b4:	6c88                	ld	a0,24(s1)
    800048b6:	fffff097          	auipc	ra,0xfffff
    800048ba:	092080e7          	jalr	146(ra) # 80003948 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800048be:	854a                	mv	a0,s2
    800048c0:	70a2                	ld	ra,40(sp)
    800048c2:	7402                	ld	s0,32(sp)
    800048c4:	64e2                	ld	s1,24(sp)
    800048c6:	6942                	ld	s2,16(sp)
    800048c8:	69a2                	ld	s3,8(sp)
    800048ca:	6145                	addi	sp,sp,48
    800048cc:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800048ce:	6908                	ld	a0,16(a0)
    800048d0:	00000097          	auipc	ra,0x0
    800048d4:	3c0080e7          	jalr	960(ra) # 80004c90 <piperead>
    800048d8:	892a                	mv	s2,a0
    800048da:	b7d5                	j	800048be <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800048dc:	02451783          	lh	a5,36(a0)
    800048e0:	03079693          	slli	a3,a5,0x30
    800048e4:	92c1                	srli	a3,a3,0x30
    800048e6:	4725                	li	a4,9
    800048e8:	02d76863          	bltu	a4,a3,80004918 <fileread+0xba>
    800048ec:	0792                	slli	a5,a5,0x4
    800048ee:	0001d717          	auipc	a4,0x1d
    800048f2:	a9270713          	addi	a4,a4,-1390 # 80021380 <devsw>
    800048f6:	97ba                	add	a5,a5,a4
    800048f8:	639c                	ld	a5,0(a5)
    800048fa:	c38d                	beqz	a5,8000491c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800048fc:	4505                	li	a0,1
    800048fe:	9782                	jalr	a5
    80004900:	892a                	mv	s2,a0
    80004902:	bf75                	j	800048be <fileread+0x60>
    panic("fileread");
    80004904:	00004517          	auipc	a0,0x4
    80004908:	ddc50513          	addi	a0,a0,-548 # 800086e0 <syscalls+0x280>
    8000490c:	ffffc097          	auipc	ra,0xffffc
    80004910:	c2c080e7          	jalr	-980(ra) # 80000538 <panic>
    return -1;
    80004914:	597d                	li	s2,-1
    80004916:	b765                	j	800048be <fileread+0x60>
      return -1;
    80004918:	597d                	li	s2,-1
    8000491a:	b755                	j	800048be <fileread+0x60>
    8000491c:	597d                	li	s2,-1
    8000491e:	b745                	j	800048be <fileread+0x60>

0000000080004920 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004920:	715d                	addi	sp,sp,-80
    80004922:	e486                	sd	ra,72(sp)
    80004924:	e0a2                	sd	s0,64(sp)
    80004926:	fc26                	sd	s1,56(sp)
    80004928:	f84a                	sd	s2,48(sp)
    8000492a:	f44e                	sd	s3,40(sp)
    8000492c:	f052                	sd	s4,32(sp)
    8000492e:	ec56                	sd	s5,24(sp)
    80004930:	e85a                	sd	s6,16(sp)
    80004932:	e45e                	sd	s7,8(sp)
    80004934:	e062                	sd	s8,0(sp)
    80004936:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004938:	00954783          	lbu	a5,9(a0)
    8000493c:	10078663          	beqz	a5,80004a48 <filewrite+0x128>
    80004940:	892a                	mv	s2,a0
    80004942:	8aae                	mv	s5,a1
    80004944:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004946:	411c                	lw	a5,0(a0)
    80004948:	4705                	li	a4,1
    8000494a:	02e78263          	beq	a5,a4,8000496e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000494e:	470d                	li	a4,3
    80004950:	02e78663          	beq	a5,a4,8000497c <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004954:	4709                	li	a4,2
    80004956:	0ee79163          	bne	a5,a4,80004a38 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000495a:	0ac05d63          	blez	a2,80004a14 <filewrite+0xf4>
    int i = 0;
    8000495e:	4981                	li	s3,0
    80004960:	6b05                	lui	s6,0x1
    80004962:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004966:	6b85                	lui	s7,0x1
    80004968:	c00b8b9b          	addiw	s7,s7,-1024
    8000496c:	a861                	j	80004a04 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000496e:	6908                	ld	a0,16(a0)
    80004970:	00000097          	auipc	ra,0x0
    80004974:	22e080e7          	jalr	558(ra) # 80004b9e <pipewrite>
    80004978:	8a2a                	mv	s4,a0
    8000497a:	a045                	j	80004a1a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000497c:	02451783          	lh	a5,36(a0)
    80004980:	03079693          	slli	a3,a5,0x30
    80004984:	92c1                	srli	a3,a3,0x30
    80004986:	4725                	li	a4,9
    80004988:	0cd76263          	bltu	a4,a3,80004a4c <filewrite+0x12c>
    8000498c:	0792                	slli	a5,a5,0x4
    8000498e:	0001d717          	auipc	a4,0x1d
    80004992:	9f270713          	addi	a4,a4,-1550 # 80021380 <devsw>
    80004996:	97ba                	add	a5,a5,a4
    80004998:	679c                	ld	a5,8(a5)
    8000499a:	cbdd                	beqz	a5,80004a50 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000499c:	4505                	li	a0,1
    8000499e:	9782                	jalr	a5
    800049a0:	8a2a                	mv	s4,a0
    800049a2:	a8a5                	j	80004a1a <filewrite+0xfa>
    800049a4:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800049a8:	00000097          	auipc	ra,0x0
    800049ac:	8b0080e7          	jalr	-1872(ra) # 80004258 <begin_op>
      ilock(f->ip);
    800049b0:	01893503          	ld	a0,24(s2)
    800049b4:	fffff097          	auipc	ra,0xfffff
    800049b8:	ed2080e7          	jalr	-302(ra) # 80003886 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800049bc:	8762                	mv	a4,s8
    800049be:	02092683          	lw	a3,32(s2)
    800049c2:	01598633          	add	a2,s3,s5
    800049c6:	4585                	li	a1,1
    800049c8:	01893503          	ld	a0,24(s2)
    800049cc:	fffff097          	auipc	ra,0xfffff
    800049d0:	266080e7          	jalr	614(ra) # 80003c32 <writei>
    800049d4:	84aa                	mv	s1,a0
    800049d6:	00a05763          	blez	a0,800049e4 <filewrite+0xc4>
        f->off += r;
    800049da:	02092783          	lw	a5,32(s2)
    800049de:	9fa9                	addw	a5,a5,a0
    800049e0:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800049e4:	01893503          	ld	a0,24(s2)
    800049e8:	fffff097          	auipc	ra,0xfffff
    800049ec:	f60080e7          	jalr	-160(ra) # 80003948 <iunlock>
      end_op();
    800049f0:	00000097          	auipc	ra,0x0
    800049f4:	8e8080e7          	jalr	-1816(ra) # 800042d8 <end_op>

      if(r != n1){
    800049f8:	009c1f63          	bne	s8,s1,80004a16 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800049fc:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a00:	0149db63          	bge	s3,s4,80004a16 <filewrite+0xf6>
      int n1 = n - i;
    80004a04:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004a08:	84be                	mv	s1,a5
    80004a0a:	2781                	sext.w	a5,a5
    80004a0c:	f8fb5ce3          	bge	s6,a5,800049a4 <filewrite+0x84>
    80004a10:	84de                	mv	s1,s7
    80004a12:	bf49                	j	800049a4 <filewrite+0x84>
    int i = 0;
    80004a14:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004a16:	013a1f63          	bne	s4,s3,80004a34 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a1a:	8552                	mv	a0,s4
    80004a1c:	60a6                	ld	ra,72(sp)
    80004a1e:	6406                	ld	s0,64(sp)
    80004a20:	74e2                	ld	s1,56(sp)
    80004a22:	7942                	ld	s2,48(sp)
    80004a24:	79a2                	ld	s3,40(sp)
    80004a26:	7a02                	ld	s4,32(sp)
    80004a28:	6ae2                	ld	s5,24(sp)
    80004a2a:	6b42                	ld	s6,16(sp)
    80004a2c:	6ba2                	ld	s7,8(sp)
    80004a2e:	6c02                	ld	s8,0(sp)
    80004a30:	6161                	addi	sp,sp,80
    80004a32:	8082                	ret
    ret = (i == n ? n : -1);
    80004a34:	5a7d                	li	s4,-1
    80004a36:	b7d5                	j	80004a1a <filewrite+0xfa>
    panic("filewrite");
    80004a38:	00004517          	auipc	a0,0x4
    80004a3c:	cb850513          	addi	a0,a0,-840 # 800086f0 <syscalls+0x290>
    80004a40:	ffffc097          	auipc	ra,0xffffc
    80004a44:	af8080e7          	jalr	-1288(ra) # 80000538 <panic>
    return -1;
    80004a48:	5a7d                	li	s4,-1
    80004a4a:	bfc1                	j	80004a1a <filewrite+0xfa>
      return -1;
    80004a4c:	5a7d                	li	s4,-1
    80004a4e:	b7f1                	j	80004a1a <filewrite+0xfa>
    80004a50:	5a7d                	li	s4,-1
    80004a52:	b7e1                	j	80004a1a <filewrite+0xfa>

0000000080004a54 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a54:	7179                	addi	sp,sp,-48
    80004a56:	f406                	sd	ra,40(sp)
    80004a58:	f022                	sd	s0,32(sp)
    80004a5a:	ec26                	sd	s1,24(sp)
    80004a5c:	e84a                	sd	s2,16(sp)
    80004a5e:	e44e                	sd	s3,8(sp)
    80004a60:	e052                	sd	s4,0(sp)
    80004a62:	1800                	addi	s0,sp,48
    80004a64:	84aa                	mv	s1,a0
    80004a66:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a68:	0005b023          	sd	zero,0(a1)
    80004a6c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a70:	00000097          	auipc	ra,0x0
    80004a74:	bf8080e7          	jalr	-1032(ra) # 80004668 <filealloc>
    80004a78:	e088                	sd	a0,0(s1)
    80004a7a:	c551                	beqz	a0,80004b06 <pipealloc+0xb2>
    80004a7c:	00000097          	auipc	ra,0x0
    80004a80:	bec080e7          	jalr	-1044(ra) # 80004668 <filealloc>
    80004a84:	00aa3023          	sd	a0,0(s4)
    80004a88:	c92d                	beqz	a0,80004afa <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a8a:	ffffc097          	auipc	ra,0xffffc
    80004a8e:	056080e7          	jalr	86(ra) # 80000ae0 <kalloc>
    80004a92:	892a                	mv	s2,a0
    80004a94:	c125                	beqz	a0,80004af4 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a96:	4985                	li	s3,1
    80004a98:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a9c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004aa0:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004aa4:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004aa8:	00004597          	auipc	a1,0x4
    80004aac:	c5858593          	addi	a1,a1,-936 # 80008700 <syscalls+0x2a0>
    80004ab0:	ffffc097          	auipc	ra,0xffffc
    80004ab4:	090080e7          	jalr	144(ra) # 80000b40 <initlock>
  (*f0)->type = FD_PIPE;
    80004ab8:	609c                	ld	a5,0(s1)
    80004aba:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004abe:	609c                	ld	a5,0(s1)
    80004ac0:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004ac4:	609c                	ld	a5,0(s1)
    80004ac6:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004aca:	609c                	ld	a5,0(s1)
    80004acc:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004ad0:	000a3783          	ld	a5,0(s4)
    80004ad4:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004ad8:	000a3783          	ld	a5,0(s4)
    80004adc:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004ae0:	000a3783          	ld	a5,0(s4)
    80004ae4:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004ae8:	000a3783          	ld	a5,0(s4)
    80004aec:	0127b823          	sd	s2,16(a5)
  return 0;
    80004af0:	4501                	li	a0,0
    80004af2:	a025                	j	80004b1a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004af4:	6088                	ld	a0,0(s1)
    80004af6:	e501                	bnez	a0,80004afe <pipealloc+0xaa>
    80004af8:	a039                	j	80004b06 <pipealloc+0xb2>
    80004afa:	6088                	ld	a0,0(s1)
    80004afc:	c51d                	beqz	a0,80004b2a <pipealloc+0xd6>
    fileclose(*f0);
    80004afe:	00000097          	auipc	ra,0x0
    80004b02:	c26080e7          	jalr	-986(ra) # 80004724 <fileclose>
  if(*f1)
    80004b06:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b0a:	557d                	li	a0,-1
  if(*f1)
    80004b0c:	c799                	beqz	a5,80004b1a <pipealloc+0xc6>
    fileclose(*f1);
    80004b0e:	853e                	mv	a0,a5
    80004b10:	00000097          	auipc	ra,0x0
    80004b14:	c14080e7          	jalr	-1004(ra) # 80004724 <fileclose>
  return -1;
    80004b18:	557d                	li	a0,-1
}
    80004b1a:	70a2                	ld	ra,40(sp)
    80004b1c:	7402                	ld	s0,32(sp)
    80004b1e:	64e2                	ld	s1,24(sp)
    80004b20:	6942                	ld	s2,16(sp)
    80004b22:	69a2                	ld	s3,8(sp)
    80004b24:	6a02                	ld	s4,0(sp)
    80004b26:	6145                	addi	sp,sp,48
    80004b28:	8082                	ret
  return -1;
    80004b2a:	557d                	li	a0,-1
    80004b2c:	b7fd                	j	80004b1a <pipealloc+0xc6>

0000000080004b2e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b2e:	1101                	addi	sp,sp,-32
    80004b30:	ec06                	sd	ra,24(sp)
    80004b32:	e822                	sd	s0,16(sp)
    80004b34:	e426                	sd	s1,8(sp)
    80004b36:	e04a                	sd	s2,0(sp)
    80004b38:	1000                	addi	s0,sp,32
    80004b3a:	84aa                	mv	s1,a0
    80004b3c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b3e:	ffffc097          	auipc	ra,0xffffc
    80004b42:	092080e7          	jalr	146(ra) # 80000bd0 <acquire>
  if(writable){
    80004b46:	02090d63          	beqz	s2,80004b80 <pipeclose+0x52>
    pi->writeopen = 0;
    80004b4a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b4e:	21848513          	addi	a0,s1,536
    80004b52:	ffffd097          	auipc	ra,0xffffd
    80004b56:	690080e7          	jalr	1680(ra) # 800021e2 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b5a:	2204b783          	ld	a5,544(s1)
    80004b5e:	eb95                	bnez	a5,80004b92 <pipeclose+0x64>
    release(&pi->lock);
    80004b60:	8526                	mv	a0,s1
    80004b62:	ffffc097          	auipc	ra,0xffffc
    80004b66:	122080e7          	jalr	290(ra) # 80000c84 <release>
    kfree((char*)pi);
    80004b6a:	8526                	mv	a0,s1
    80004b6c:	ffffc097          	auipc	ra,0xffffc
    80004b70:	e78080e7          	jalr	-392(ra) # 800009e4 <kfree>
  } else
    release(&pi->lock);
}
    80004b74:	60e2                	ld	ra,24(sp)
    80004b76:	6442                	ld	s0,16(sp)
    80004b78:	64a2                	ld	s1,8(sp)
    80004b7a:	6902                	ld	s2,0(sp)
    80004b7c:	6105                	addi	sp,sp,32
    80004b7e:	8082                	ret
    pi->readopen = 0;
    80004b80:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b84:	21c48513          	addi	a0,s1,540
    80004b88:	ffffd097          	auipc	ra,0xffffd
    80004b8c:	65a080e7          	jalr	1626(ra) # 800021e2 <wakeup>
    80004b90:	b7e9                	j	80004b5a <pipeclose+0x2c>
    release(&pi->lock);
    80004b92:	8526                	mv	a0,s1
    80004b94:	ffffc097          	auipc	ra,0xffffc
    80004b98:	0f0080e7          	jalr	240(ra) # 80000c84 <release>
}
    80004b9c:	bfe1                	j	80004b74 <pipeclose+0x46>

0000000080004b9e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b9e:	711d                	addi	sp,sp,-96
    80004ba0:	ec86                	sd	ra,88(sp)
    80004ba2:	e8a2                	sd	s0,80(sp)
    80004ba4:	e4a6                	sd	s1,72(sp)
    80004ba6:	e0ca                	sd	s2,64(sp)
    80004ba8:	fc4e                	sd	s3,56(sp)
    80004baa:	f852                	sd	s4,48(sp)
    80004bac:	f456                	sd	s5,40(sp)
    80004bae:	f05a                	sd	s6,32(sp)
    80004bb0:	ec5e                	sd	s7,24(sp)
    80004bb2:	e862                	sd	s8,16(sp)
    80004bb4:	1080                	addi	s0,sp,96
    80004bb6:	84aa                	mv	s1,a0
    80004bb8:	8aae                	mv	s5,a1
    80004bba:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004bbc:	ffffd097          	auipc	ra,0xffffd
    80004bc0:	dda080e7          	jalr	-550(ra) # 80001996 <myproc>
    80004bc4:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004bc6:	8526                	mv	a0,s1
    80004bc8:	ffffc097          	auipc	ra,0xffffc
    80004bcc:	008080e7          	jalr	8(ra) # 80000bd0 <acquire>
  while(i < n){
    80004bd0:	0b405363          	blez	s4,80004c76 <pipewrite+0xd8>
  int i = 0;
    80004bd4:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004bd6:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004bd8:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004bdc:	21c48b93          	addi	s7,s1,540
    80004be0:	a089                	j	80004c22 <pipewrite+0x84>
      release(&pi->lock);
    80004be2:	8526                	mv	a0,s1
    80004be4:	ffffc097          	auipc	ra,0xffffc
    80004be8:	0a0080e7          	jalr	160(ra) # 80000c84 <release>
      return -1;
    80004bec:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004bee:	854a                	mv	a0,s2
    80004bf0:	60e6                	ld	ra,88(sp)
    80004bf2:	6446                	ld	s0,80(sp)
    80004bf4:	64a6                	ld	s1,72(sp)
    80004bf6:	6906                	ld	s2,64(sp)
    80004bf8:	79e2                	ld	s3,56(sp)
    80004bfa:	7a42                	ld	s4,48(sp)
    80004bfc:	7aa2                	ld	s5,40(sp)
    80004bfe:	7b02                	ld	s6,32(sp)
    80004c00:	6be2                	ld	s7,24(sp)
    80004c02:	6c42                	ld	s8,16(sp)
    80004c04:	6125                	addi	sp,sp,96
    80004c06:	8082                	ret
      wakeup(&pi->nread);
    80004c08:	8562                	mv	a0,s8
    80004c0a:	ffffd097          	auipc	ra,0xffffd
    80004c0e:	5d8080e7          	jalr	1496(ra) # 800021e2 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c12:	85a6                	mv	a1,s1
    80004c14:	855e                	mv	a0,s7
    80004c16:	ffffd097          	auipc	ra,0xffffd
    80004c1a:	440080e7          	jalr	1088(ra) # 80002056 <sleep>
  while(i < n){
    80004c1e:	05495d63          	bge	s2,s4,80004c78 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004c22:	2204a783          	lw	a5,544(s1)
    80004c26:	dfd5                	beqz	a5,80004be2 <pipewrite+0x44>
    80004c28:	0289a783          	lw	a5,40(s3)
    80004c2c:	fbdd                	bnez	a5,80004be2 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004c2e:	2184a783          	lw	a5,536(s1)
    80004c32:	21c4a703          	lw	a4,540(s1)
    80004c36:	2007879b          	addiw	a5,a5,512
    80004c3a:	fcf707e3          	beq	a4,a5,80004c08 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c3e:	4685                	li	a3,1
    80004c40:	01590633          	add	a2,s2,s5
    80004c44:	faf40593          	addi	a1,s0,-81
    80004c48:	0509b503          	ld	a0,80(s3)
    80004c4c:	ffffd097          	auipc	ra,0xffffd
    80004c50:	a96080e7          	jalr	-1386(ra) # 800016e2 <copyin>
    80004c54:	03650263          	beq	a0,s6,80004c78 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c58:	21c4a783          	lw	a5,540(s1)
    80004c5c:	0017871b          	addiw	a4,a5,1
    80004c60:	20e4ae23          	sw	a4,540(s1)
    80004c64:	1ff7f793          	andi	a5,a5,511
    80004c68:	97a6                	add	a5,a5,s1
    80004c6a:	faf44703          	lbu	a4,-81(s0)
    80004c6e:	00e78c23          	sb	a4,24(a5)
      i++;
    80004c72:	2905                	addiw	s2,s2,1
    80004c74:	b76d                	j	80004c1e <pipewrite+0x80>
  int i = 0;
    80004c76:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004c78:	21848513          	addi	a0,s1,536
    80004c7c:	ffffd097          	auipc	ra,0xffffd
    80004c80:	566080e7          	jalr	1382(ra) # 800021e2 <wakeup>
  release(&pi->lock);
    80004c84:	8526                	mv	a0,s1
    80004c86:	ffffc097          	auipc	ra,0xffffc
    80004c8a:	ffe080e7          	jalr	-2(ra) # 80000c84 <release>
  return i;
    80004c8e:	b785                	j	80004bee <pipewrite+0x50>

0000000080004c90 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c90:	715d                	addi	sp,sp,-80
    80004c92:	e486                	sd	ra,72(sp)
    80004c94:	e0a2                	sd	s0,64(sp)
    80004c96:	fc26                	sd	s1,56(sp)
    80004c98:	f84a                	sd	s2,48(sp)
    80004c9a:	f44e                	sd	s3,40(sp)
    80004c9c:	f052                	sd	s4,32(sp)
    80004c9e:	ec56                	sd	s5,24(sp)
    80004ca0:	e85a                	sd	s6,16(sp)
    80004ca2:	0880                	addi	s0,sp,80
    80004ca4:	84aa                	mv	s1,a0
    80004ca6:	892e                	mv	s2,a1
    80004ca8:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004caa:	ffffd097          	auipc	ra,0xffffd
    80004cae:	cec080e7          	jalr	-788(ra) # 80001996 <myproc>
    80004cb2:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004cb4:	8526                	mv	a0,s1
    80004cb6:	ffffc097          	auipc	ra,0xffffc
    80004cba:	f1a080e7          	jalr	-230(ra) # 80000bd0 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cbe:	2184a703          	lw	a4,536(s1)
    80004cc2:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004cc6:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cca:	02f71463          	bne	a4,a5,80004cf2 <piperead+0x62>
    80004cce:	2244a783          	lw	a5,548(s1)
    80004cd2:	c385                	beqz	a5,80004cf2 <piperead+0x62>
    if(pr->killed){
    80004cd4:	028a2783          	lw	a5,40(s4)
    80004cd8:	ebc1                	bnez	a5,80004d68 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004cda:	85a6                	mv	a1,s1
    80004cdc:	854e                	mv	a0,s3
    80004cde:	ffffd097          	auipc	ra,0xffffd
    80004ce2:	378080e7          	jalr	888(ra) # 80002056 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ce6:	2184a703          	lw	a4,536(s1)
    80004cea:	21c4a783          	lw	a5,540(s1)
    80004cee:	fef700e3          	beq	a4,a5,80004cce <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cf2:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004cf4:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cf6:	05505363          	blez	s5,80004d3c <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004cfa:	2184a783          	lw	a5,536(s1)
    80004cfe:	21c4a703          	lw	a4,540(s1)
    80004d02:	02f70d63          	beq	a4,a5,80004d3c <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d06:	0017871b          	addiw	a4,a5,1
    80004d0a:	20e4ac23          	sw	a4,536(s1)
    80004d0e:	1ff7f793          	andi	a5,a5,511
    80004d12:	97a6                	add	a5,a5,s1
    80004d14:	0187c783          	lbu	a5,24(a5)
    80004d18:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d1c:	4685                	li	a3,1
    80004d1e:	fbf40613          	addi	a2,s0,-65
    80004d22:	85ca                	mv	a1,s2
    80004d24:	050a3503          	ld	a0,80(s4)
    80004d28:	ffffd097          	auipc	ra,0xffffd
    80004d2c:	92e080e7          	jalr	-1746(ra) # 80001656 <copyout>
    80004d30:	01650663          	beq	a0,s6,80004d3c <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d34:	2985                	addiw	s3,s3,1
    80004d36:	0905                	addi	s2,s2,1
    80004d38:	fd3a91e3          	bne	s5,s3,80004cfa <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d3c:	21c48513          	addi	a0,s1,540
    80004d40:	ffffd097          	auipc	ra,0xffffd
    80004d44:	4a2080e7          	jalr	1186(ra) # 800021e2 <wakeup>
  release(&pi->lock);
    80004d48:	8526                	mv	a0,s1
    80004d4a:	ffffc097          	auipc	ra,0xffffc
    80004d4e:	f3a080e7          	jalr	-198(ra) # 80000c84 <release>
  return i;
}
    80004d52:	854e                	mv	a0,s3
    80004d54:	60a6                	ld	ra,72(sp)
    80004d56:	6406                	ld	s0,64(sp)
    80004d58:	74e2                	ld	s1,56(sp)
    80004d5a:	7942                	ld	s2,48(sp)
    80004d5c:	79a2                	ld	s3,40(sp)
    80004d5e:	7a02                	ld	s4,32(sp)
    80004d60:	6ae2                	ld	s5,24(sp)
    80004d62:	6b42                	ld	s6,16(sp)
    80004d64:	6161                	addi	sp,sp,80
    80004d66:	8082                	ret
      release(&pi->lock);
    80004d68:	8526                	mv	a0,s1
    80004d6a:	ffffc097          	auipc	ra,0xffffc
    80004d6e:	f1a080e7          	jalr	-230(ra) # 80000c84 <release>
      return -1;
    80004d72:	59fd                	li	s3,-1
    80004d74:	bff9                	j	80004d52 <piperead+0xc2>

0000000080004d76 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004d76:	de010113          	addi	sp,sp,-544
    80004d7a:	20113c23          	sd	ra,536(sp)
    80004d7e:	20813823          	sd	s0,528(sp)
    80004d82:	20913423          	sd	s1,520(sp)
    80004d86:	21213023          	sd	s2,512(sp)
    80004d8a:	ffce                	sd	s3,504(sp)
    80004d8c:	fbd2                	sd	s4,496(sp)
    80004d8e:	f7d6                	sd	s5,488(sp)
    80004d90:	f3da                	sd	s6,480(sp)
    80004d92:	efde                	sd	s7,472(sp)
    80004d94:	ebe2                	sd	s8,464(sp)
    80004d96:	e7e6                	sd	s9,456(sp)
    80004d98:	e3ea                	sd	s10,448(sp)
    80004d9a:	ff6e                	sd	s11,440(sp)
    80004d9c:	1400                	addi	s0,sp,544
    80004d9e:	892a                	mv	s2,a0
    80004da0:	dea43423          	sd	a0,-536(s0)
    80004da4:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004da8:	ffffd097          	auipc	ra,0xffffd
    80004dac:	bee080e7          	jalr	-1042(ra) # 80001996 <myproc>
    80004db0:	84aa                	mv	s1,a0

  begin_op();
    80004db2:	fffff097          	auipc	ra,0xfffff
    80004db6:	4a6080e7          	jalr	1190(ra) # 80004258 <begin_op>

  if((ip = namei(path)) == 0){
    80004dba:	854a                	mv	a0,s2
    80004dbc:	fffff097          	auipc	ra,0xfffff
    80004dc0:	280080e7          	jalr	640(ra) # 8000403c <namei>
    80004dc4:	c93d                	beqz	a0,80004e3a <exec+0xc4>
    80004dc6:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004dc8:	fffff097          	auipc	ra,0xfffff
    80004dcc:	abe080e7          	jalr	-1346(ra) # 80003886 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004dd0:	04000713          	li	a4,64
    80004dd4:	4681                	li	a3,0
    80004dd6:	e5040613          	addi	a2,s0,-432
    80004dda:	4581                	li	a1,0
    80004ddc:	8556                	mv	a0,s5
    80004dde:	fffff097          	auipc	ra,0xfffff
    80004de2:	d5c080e7          	jalr	-676(ra) # 80003b3a <readi>
    80004de6:	04000793          	li	a5,64
    80004dea:	00f51a63          	bne	a0,a5,80004dfe <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004dee:	e5042703          	lw	a4,-432(s0)
    80004df2:	464c47b7          	lui	a5,0x464c4
    80004df6:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004dfa:	04f70663          	beq	a4,a5,80004e46 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004dfe:	8556                	mv	a0,s5
    80004e00:	fffff097          	auipc	ra,0xfffff
    80004e04:	ce8080e7          	jalr	-792(ra) # 80003ae8 <iunlockput>
    end_op();
    80004e08:	fffff097          	auipc	ra,0xfffff
    80004e0c:	4d0080e7          	jalr	1232(ra) # 800042d8 <end_op>
  }
  return -1;
    80004e10:	557d                	li	a0,-1
}
    80004e12:	21813083          	ld	ra,536(sp)
    80004e16:	21013403          	ld	s0,528(sp)
    80004e1a:	20813483          	ld	s1,520(sp)
    80004e1e:	20013903          	ld	s2,512(sp)
    80004e22:	79fe                	ld	s3,504(sp)
    80004e24:	7a5e                	ld	s4,496(sp)
    80004e26:	7abe                	ld	s5,488(sp)
    80004e28:	7b1e                	ld	s6,480(sp)
    80004e2a:	6bfe                	ld	s7,472(sp)
    80004e2c:	6c5e                	ld	s8,464(sp)
    80004e2e:	6cbe                	ld	s9,456(sp)
    80004e30:	6d1e                	ld	s10,448(sp)
    80004e32:	7dfa                	ld	s11,440(sp)
    80004e34:	22010113          	addi	sp,sp,544
    80004e38:	8082                	ret
    end_op();
    80004e3a:	fffff097          	auipc	ra,0xfffff
    80004e3e:	49e080e7          	jalr	1182(ra) # 800042d8 <end_op>
    return -1;
    80004e42:	557d                	li	a0,-1
    80004e44:	b7f9                	j	80004e12 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e46:	8526                	mv	a0,s1
    80004e48:	ffffd097          	auipc	ra,0xffffd
    80004e4c:	c12080e7          	jalr	-1006(ra) # 80001a5a <proc_pagetable>
    80004e50:	8b2a                	mv	s6,a0
    80004e52:	d555                	beqz	a0,80004dfe <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e54:	e7042783          	lw	a5,-400(s0)
    80004e58:	e8845703          	lhu	a4,-376(s0)
    80004e5c:	c735                	beqz	a4,80004ec8 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e5e:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e60:	e0043423          	sd	zero,-504(s0)
    if((ph.vaddr % PGSIZE) != 0)
    80004e64:	6a05                	lui	s4,0x1
    80004e66:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004e6a:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004e6e:	6d85                	lui	s11,0x1
    80004e70:	7d7d                	lui	s10,0xfffff
    80004e72:	ac1d                	j	800050a8 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e74:	00004517          	auipc	a0,0x4
    80004e78:	89450513          	addi	a0,a0,-1900 # 80008708 <syscalls+0x2a8>
    80004e7c:	ffffb097          	auipc	ra,0xffffb
    80004e80:	6bc080e7          	jalr	1724(ra) # 80000538 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e84:	874a                	mv	a4,s2
    80004e86:	009c86bb          	addw	a3,s9,s1
    80004e8a:	4581                	li	a1,0
    80004e8c:	8556                	mv	a0,s5
    80004e8e:	fffff097          	auipc	ra,0xfffff
    80004e92:	cac080e7          	jalr	-852(ra) # 80003b3a <readi>
    80004e96:	2501                	sext.w	a0,a0
    80004e98:	1aa91863          	bne	s2,a0,80005048 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004e9c:	009d84bb          	addw	s1,s11,s1
    80004ea0:	013d09bb          	addw	s3,s10,s3
    80004ea4:	1f74f263          	bgeu	s1,s7,80005088 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004ea8:	02049593          	slli	a1,s1,0x20
    80004eac:	9181                	srli	a1,a1,0x20
    80004eae:	95e2                	add	a1,a1,s8
    80004eb0:	855a                	mv	a0,s6
    80004eb2:	ffffc097          	auipc	ra,0xffffc
    80004eb6:	1a0080e7          	jalr	416(ra) # 80001052 <walkaddr>
    80004eba:	862a                	mv	a2,a0
    if(pa == 0)
    80004ebc:	dd45                	beqz	a0,80004e74 <exec+0xfe>
      n = PGSIZE;
    80004ebe:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004ec0:	fd49f2e3          	bgeu	s3,s4,80004e84 <exec+0x10e>
      n = sz - i;
    80004ec4:	894e                	mv	s2,s3
    80004ec6:	bf7d                	j	80004e84 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004ec8:	4481                	li	s1,0
  iunlockput(ip);
    80004eca:	8556                	mv	a0,s5
    80004ecc:	fffff097          	auipc	ra,0xfffff
    80004ed0:	c1c080e7          	jalr	-996(ra) # 80003ae8 <iunlockput>
  end_op();
    80004ed4:	fffff097          	auipc	ra,0xfffff
    80004ed8:	404080e7          	jalr	1028(ra) # 800042d8 <end_op>
  p = myproc();
    80004edc:	ffffd097          	auipc	ra,0xffffd
    80004ee0:	aba080e7          	jalr	-1350(ra) # 80001996 <myproc>
    80004ee4:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004ee6:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004eea:	6785                	lui	a5,0x1
    80004eec:	17fd                	addi	a5,a5,-1
    80004eee:	94be                	add	s1,s1,a5
    80004ef0:	77fd                	lui	a5,0xfffff
    80004ef2:	8fe5                	and	a5,a5,s1
    80004ef4:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004ef8:	6609                	lui	a2,0x2
    80004efa:	963e                	add	a2,a2,a5
    80004efc:	85be                	mv	a1,a5
    80004efe:	855a                	mv	a0,s6
    80004f00:	ffffc097          	auipc	ra,0xffffc
    80004f04:	506080e7          	jalr	1286(ra) # 80001406 <uvmalloc>
    80004f08:	8c2a                	mv	s8,a0
  ip = 0;
    80004f0a:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f0c:	12050e63          	beqz	a0,80005048 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f10:	75f9                	lui	a1,0xffffe
    80004f12:	95aa                	add	a1,a1,a0
    80004f14:	855a                	mv	a0,s6
    80004f16:	ffffc097          	auipc	ra,0xffffc
    80004f1a:	70e080e7          	jalr	1806(ra) # 80001624 <uvmclear>
  stackbase = sp - PGSIZE;
    80004f1e:	7afd                	lui	s5,0xfffff
    80004f20:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f22:	df043783          	ld	a5,-528(s0)
    80004f26:	6388                	ld	a0,0(a5)
    80004f28:	c925                	beqz	a0,80004f98 <exec+0x222>
    80004f2a:	e9040993          	addi	s3,s0,-368
    80004f2e:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004f32:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f34:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004f36:	ffffc097          	auipc	ra,0xffffc
    80004f3a:	f12080e7          	jalr	-238(ra) # 80000e48 <strlen>
    80004f3e:	0015079b          	addiw	a5,a0,1
    80004f42:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f46:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004f4a:	13596363          	bltu	s2,s5,80005070 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f4e:	df043d83          	ld	s11,-528(s0)
    80004f52:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004f56:	8552                	mv	a0,s4
    80004f58:	ffffc097          	auipc	ra,0xffffc
    80004f5c:	ef0080e7          	jalr	-272(ra) # 80000e48 <strlen>
    80004f60:	0015069b          	addiw	a3,a0,1
    80004f64:	8652                	mv	a2,s4
    80004f66:	85ca                	mv	a1,s2
    80004f68:	855a                	mv	a0,s6
    80004f6a:	ffffc097          	auipc	ra,0xffffc
    80004f6e:	6ec080e7          	jalr	1772(ra) # 80001656 <copyout>
    80004f72:	10054363          	bltz	a0,80005078 <exec+0x302>
    ustack[argc] = sp;
    80004f76:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f7a:	0485                	addi	s1,s1,1
    80004f7c:	008d8793          	addi	a5,s11,8
    80004f80:	def43823          	sd	a5,-528(s0)
    80004f84:	008db503          	ld	a0,8(s11)
    80004f88:	c911                	beqz	a0,80004f9c <exec+0x226>
    if(argc >= MAXARG)
    80004f8a:	09a1                	addi	s3,s3,8
    80004f8c:	fb3c95e3          	bne	s9,s3,80004f36 <exec+0x1c0>
  sz = sz1;
    80004f90:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f94:	4a81                	li	s5,0
    80004f96:	a84d                	j	80005048 <exec+0x2d2>
  sp = sz;
    80004f98:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f9a:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f9c:	00349793          	slli	a5,s1,0x3
    80004fa0:	f9040713          	addi	a4,s0,-112
    80004fa4:	97ba                	add	a5,a5,a4
    80004fa6:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffd8f00>
  sp -= (argc+1) * sizeof(uint64);
    80004faa:	00148693          	addi	a3,s1,1
    80004fae:	068e                	slli	a3,a3,0x3
    80004fb0:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004fb4:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004fb8:	01597663          	bgeu	s2,s5,80004fc4 <exec+0x24e>
  sz = sz1;
    80004fbc:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fc0:	4a81                	li	s5,0
    80004fc2:	a059                	j	80005048 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004fc4:	e9040613          	addi	a2,s0,-368
    80004fc8:	85ca                	mv	a1,s2
    80004fca:	855a                	mv	a0,s6
    80004fcc:	ffffc097          	auipc	ra,0xffffc
    80004fd0:	68a080e7          	jalr	1674(ra) # 80001656 <copyout>
    80004fd4:	0a054663          	bltz	a0,80005080 <exec+0x30a>
  p->trapframe->a1 = sp;
    80004fd8:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80004fdc:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004fe0:	de843783          	ld	a5,-536(s0)
    80004fe4:	0007c703          	lbu	a4,0(a5)
    80004fe8:	cf11                	beqz	a4,80005004 <exec+0x28e>
    80004fea:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004fec:	02f00693          	li	a3,47
    80004ff0:	a039                	j	80004ffe <exec+0x288>
      last = s+1;
    80004ff2:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004ff6:	0785                	addi	a5,a5,1
    80004ff8:	fff7c703          	lbu	a4,-1(a5)
    80004ffc:	c701                	beqz	a4,80005004 <exec+0x28e>
    if(*s == '/')
    80004ffe:	fed71ce3          	bne	a4,a3,80004ff6 <exec+0x280>
    80005002:	bfc5                	j	80004ff2 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80005004:	4641                	li	a2,16
    80005006:	de843583          	ld	a1,-536(s0)
    8000500a:	158b8513          	addi	a0,s7,344
    8000500e:	ffffc097          	auipc	ra,0xffffc
    80005012:	e08080e7          	jalr	-504(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    80005016:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    8000501a:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    8000501e:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005022:	058bb783          	ld	a5,88(s7)
    80005026:	e6843703          	ld	a4,-408(s0)
    8000502a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000502c:	058bb783          	ld	a5,88(s7)
    80005030:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005034:	85ea                	mv	a1,s10
    80005036:	ffffd097          	auipc	ra,0xffffd
    8000503a:	ac0080e7          	jalr	-1344(ra) # 80001af6 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000503e:	0004851b          	sext.w	a0,s1
    80005042:	bbc1                	j	80004e12 <exec+0x9c>
    80005044:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005048:	df843583          	ld	a1,-520(s0)
    8000504c:	855a                	mv	a0,s6
    8000504e:	ffffd097          	auipc	ra,0xffffd
    80005052:	aa8080e7          	jalr	-1368(ra) # 80001af6 <proc_freepagetable>
  if(ip){
    80005056:	da0a94e3          	bnez	s5,80004dfe <exec+0x88>
  return -1;
    8000505a:	557d                	li	a0,-1
    8000505c:	bb5d                	j	80004e12 <exec+0x9c>
    8000505e:	de943c23          	sd	s1,-520(s0)
    80005062:	b7dd                	j	80005048 <exec+0x2d2>
    80005064:	de943c23          	sd	s1,-520(s0)
    80005068:	b7c5                	j	80005048 <exec+0x2d2>
    8000506a:	de943c23          	sd	s1,-520(s0)
    8000506e:	bfe9                	j	80005048 <exec+0x2d2>
  sz = sz1;
    80005070:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005074:	4a81                	li	s5,0
    80005076:	bfc9                	j	80005048 <exec+0x2d2>
  sz = sz1;
    80005078:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000507c:	4a81                	li	s5,0
    8000507e:	b7e9                	j	80005048 <exec+0x2d2>
  sz = sz1;
    80005080:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005084:	4a81                	li	s5,0
    80005086:	b7c9                	j	80005048 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005088:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000508c:	e0843783          	ld	a5,-504(s0)
    80005090:	0017869b          	addiw	a3,a5,1
    80005094:	e0d43423          	sd	a3,-504(s0)
    80005098:	e0043783          	ld	a5,-512(s0)
    8000509c:	0387879b          	addiw	a5,a5,56
    800050a0:	e8845703          	lhu	a4,-376(s0)
    800050a4:	e2e6d3e3          	bge	a3,a4,80004eca <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800050a8:	2781                	sext.w	a5,a5
    800050aa:	e0f43023          	sd	a5,-512(s0)
    800050ae:	03800713          	li	a4,56
    800050b2:	86be                	mv	a3,a5
    800050b4:	e1840613          	addi	a2,s0,-488
    800050b8:	4581                	li	a1,0
    800050ba:	8556                	mv	a0,s5
    800050bc:	fffff097          	auipc	ra,0xfffff
    800050c0:	a7e080e7          	jalr	-1410(ra) # 80003b3a <readi>
    800050c4:	03800793          	li	a5,56
    800050c8:	f6f51ee3          	bne	a0,a5,80005044 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    800050cc:	e1842783          	lw	a5,-488(s0)
    800050d0:	4705                	li	a4,1
    800050d2:	fae79de3          	bne	a5,a4,8000508c <exec+0x316>
    if(ph.memsz < ph.filesz)
    800050d6:	e4043603          	ld	a2,-448(s0)
    800050da:	e3843783          	ld	a5,-456(s0)
    800050de:	f8f660e3          	bltu	a2,a5,8000505e <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800050e2:	e2843783          	ld	a5,-472(s0)
    800050e6:	963e                	add	a2,a2,a5
    800050e8:	f6f66ee3          	bltu	a2,a5,80005064 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800050ec:	85a6                	mv	a1,s1
    800050ee:	855a                	mv	a0,s6
    800050f0:	ffffc097          	auipc	ra,0xffffc
    800050f4:	316080e7          	jalr	790(ra) # 80001406 <uvmalloc>
    800050f8:	dea43c23          	sd	a0,-520(s0)
    800050fc:	d53d                	beqz	a0,8000506a <exec+0x2f4>
    if((ph.vaddr % PGSIZE) != 0)
    800050fe:	e2843c03          	ld	s8,-472(s0)
    80005102:	de043783          	ld	a5,-544(s0)
    80005106:	00fc77b3          	and	a5,s8,a5
    8000510a:	ff9d                	bnez	a5,80005048 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000510c:	e2042c83          	lw	s9,-480(s0)
    80005110:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005114:	f60b8ae3          	beqz	s7,80005088 <exec+0x312>
    80005118:	89de                	mv	s3,s7
    8000511a:	4481                	li	s1,0
    8000511c:	b371                	j	80004ea8 <exec+0x132>

000000008000511e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000511e:	7179                	addi	sp,sp,-48
    80005120:	f406                	sd	ra,40(sp)
    80005122:	f022                	sd	s0,32(sp)
    80005124:	ec26                	sd	s1,24(sp)
    80005126:	e84a                	sd	s2,16(sp)
    80005128:	1800                	addi	s0,sp,48
    8000512a:	892e                	mv	s2,a1
    8000512c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000512e:	fdc40593          	addi	a1,s0,-36
    80005132:	ffffe097          	auipc	ra,0xffffe
    80005136:	ac2080e7          	jalr	-1342(ra) # 80002bf4 <argint>
    8000513a:	04054063          	bltz	a0,8000517a <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000513e:	fdc42703          	lw	a4,-36(s0)
    80005142:	47bd                	li	a5,15
    80005144:	02e7ed63          	bltu	a5,a4,8000517e <argfd+0x60>
    80005148:	ffffd097          	auipc	ra,0xffffd
    8000514c:	84e080e7          	jalr	-1970(ra) # 80001996 <myproc>
    80005150:	fdc42703          	lw	a4,-36(s0)
    80005154:	01a70793          	addi	a5,a4,26
    80005158:	078e                	slli	a5,a5,0x3
    8000515a:	953e                	add	a0,a0,a5
    8000515c:	611c                	ld	a5,0(a0)
    8000515e:	c395                	beqz	a5,80005182 <argfd+0x64>
    return -1;
  if(pfd)
    80005160:	00090463          	beqz	s2,80005168 <argfd+0x4a>
    *pfd = fd;
    80005164:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005168:	4501                	li	a0,0
  if(pf)
    8000516a:	c091                	beqz	s1,8000516e <argfd+0x50>
    *pf = f;
    8000516c:	e09c                	sd	a5,0(s1)
}
    8000516e:	70a2                	ld	ra,40(sp)
    80005170:	7402                	ld	s0,32(sp)
    80005172:	64e2                	ld	s1,24(sp)
    80005174:	6942                	ld	s2,16(sp)
    80005176:	6145                	addi	sp,sp,48
    80005178:	8082                	ret
    return -1;
    8000517a:	557d                	li	a0,-1
    8000517c:	bfcd                	j	8000516e <argfd+0x50>
    return -1;
    8000517e:	557d                	li	a0,-1
    80005180:	b7fd                	j	8000516e <argfd+0x50>
    80005182:	557d                	li	a0,-1
    80005184:	b7ed                	j	8000516e <argfd+0x50>

0000000080005186 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005186:	1101                	addi	sp,sp,-32
    80005188:	ec06                	sd	ra,24(sp)
    8000518a:	e822                	sd	s0,16(sp)
    8000518c:	e426                	sd	s1,8(sp)
    8000518e:	1000                	addi	s0,sp,32
    80005190:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005192:	ffffd097          	auipc	ra,0xffffd
    80005196:	804080e7          	jalr	-2044(ra) # 80001996 <myproc>
    8000519a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000519c:	0d050793          	addi	a5,a0,208
    800051a0:	4501                	li	a0,0
    800051a2:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800051a4:	6398                	ld	a4,0(a5)
    800051a6:	cb19                	beqz	a4,800051bc <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800051a8:	2505                	addiw	a0,a0,1
    800051aa:	07a1                	addi	a5,a5,8
    800051ac:	fed51ce3          	bne	a0,a3,800051a4 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800051b0:	557d                	li	a0,-1
}
    800051b2:	60e2                	ld	ra,24(sp)
    800051b4:	6442                	ld	s0,16(sp)
    800051b6:	64a2                	ld	s1,8(sp)
    800051b8:	6105                	addi	sp,sp,32
    800051ba:	8082                	ret
      p->ofile[fd] = f;
    800051bc:	01a50793          	addi	a5,a0,26
    800051c0:	078e                	slli	a5,a5,0x3
    800051c2:	963e                	add	a2,a2,a5
    800051c4:	e204                	sd	s1,0(a2)
      return fd;
    800051c6:	b7f5                	j	800051b2 <fdalloc+0x2c>

00000000800051c8 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800051c8:	715d                	addi	sp,sp,-80
    800051ca:	e486                	sd	ra,72(sp)
    800051cc:	e0a2                	sd	s0,64(sp)
    800051ce:	fc26                	sd	s1,56(sp)
    800051d0:	f84a                	sd	s2,48(sp)
    800051d2:	f44e                	sd	s3,40(sp)
    800051d4:	f052                	sd	s4,32(sp)
    800051d6:	ec56                	sd	s5,24(sp)
    800051d8:	0880                	addi	s0,sp,80
    800051da:	89ae                	mv	s3,a1
    800051dc:	8ab2                	mv	s5,a2
    800051de:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800051e0:	fb040593          	addi	a1,s0,-80
    800051e4:	fffff097          	auipc	ra,0xfffff
    800051e8:	e76080e7          	jalr	-394(ra) # 8000405a <nameiparent>
    800051ec:	892a                	mv	s2,a0
    800051ee:	12050e63          	beqz	a0,8000532a <create+0x162>
    return 0;

  ilock(dp);
    800051f2:	ffffe097          	auipc	ra,0xffffe
    800051f6:	694080e7          	jalr	1684(ra) # 80003886 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800051fa:	4601                	li	a2,0
    800051fc:	fb040593          	addi	a1,s0,-80
    80005200:	854a                	mv	a0,s2
    80005202:	fffff097          	auipc	ra,0xfffff
    80005206:	b68080e7          	jalr	-1176(ra) # 80003d6a <dirlookup>
    8000520a:	84aa                	mv	s1,a0
    8000520c:	c921                	beqz	a0,8000525c <create+0x94>
    iunlockput(dp);
    8000520e:	854a                	mv	a0,s2
    80005210:	fffff097          	auipc	ra,0xfffff
    80005214:	8d8080e7          	jalr	-1832(ra) # 80003ae8 <iunlockput>
    ilock(ip);
    80005218:	8526                	mv	a0,s1
    8000521a:	ffffe097          	auipc	ra,0xffffe
    8000521e:	66c080e7          	jalr	1644(ra) # 80003886 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005222:	2981                	sext.w	s3,s3
    80005224:	4789                	li	a5,2
    80005226:	02f99463          	bne	s3,a5,8000524e <create+0x86>
    8000522a:	0444d783          	lhu	a5,68(s1)
    8000522e:	37f9                	addiw	a5,a5,-2
    80005230:	17c2                	slli	a5,a5,0x30
    80005232:	93c1                	srli	a5,a5,0x30
    80005234:	4705                	li	a4,1
    80005236:	00f76c63          	bltu	a4,a5,8000524e <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000523a:	8526                	mv	a0,s1
    8000523c:	60a6                	ld	ra,72(sp)
    8000523e:	6406                	ld	s0,64(sp)
    80005240:	74e2                	ld	s1,56(sp)
    80005242:	7942                	ld	s2,48(sp)
    80005244:	79a2                	ld	s3,40(sp)
    80005246:	7a02                	ld	s4,32(sp)
    80005248:	6ae2                	ld	s5,24(sp)
    8000524a:	6161                	addi	sp,sp,80
    8000524c:	8082                	ret
    iunlockput(ip);
    8000524e:	8526                	mv	a0,s1
    80005250:	fffff097          	auipc	ra,0xfffff
    80005254:	898080e7          	jalr	-1896(ra) # 80003ae8 <iunlockput>
    return 0;
    80005258:	4481                	li	s1,0
    8000525a:	b7c5                	j	8000523a <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000525c:	85ce                	mv	a1,s3
    8000525e:	00092503          	lw	a0,0(s2)
    80005262:	ffffe097          	auipc	ra,0xffffe
    80005266:	48c080e7          	jalr	1164(ra) # 800036ee <ialloc>
    8000526a:	84aa                	mv	s1,a0
    8000526c:	c521                	beqz	a0,800052b4 <create+0xec>
  ilock(ip);
    8000526e:	ffffe097          	auipc	ra,0xffffe
    80005272:	618080e7          	jalr	1560(ra) # 80003886 <ilock>
  ip->major = major;
    80005276:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000527a:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000527e:	4a05                	li	s4,1
    80005280:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005284:	8526                	mv	a0,s1
    80005286:	ffffe097          	auipc	ra,0xffffe
    8000528a:	536080e7          	jalr	1334(ra) # 800037bc <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000528e:	2981                	sext.w	s3,s3
    80005290:	03498a63          	beq	s3,s4,800052c4 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005294:	40d0                	lw	a2,4(s1)
    80005296:	fb040593          	addi	a1,s0,-80
    8000529a:	854a                	mv	a0,s2
    8000529c:	fffff097          	auipc	ra,0xfffff
    800052a0:	cde080e7          	jalr	-802(ra) # 80003f7a <dirlink>
    800052a4:	06054b63          	bltz	a0,8000531a <create+0x152>
  iunlockput(dp);
    800052a8:	854a                	mv	a0,s2
    800052aa:	fffff097          	auipc	ra,0xfffff
    800052ae:	83e080e7          	jalr	-1986(ra) # 80003ae8 <iunlockput>
  return ip;
    800052b2:	b761                	j	8000523a <create+0x72>
    panic("create: ialloc");
    800052b4:	00003517          	auipc	a0,0x3
    800052b8:	47450513          	addi	a0,a0,1140 # 80008728 <syscalls+0x2c8>
    800052bc:	ffffb097          	auipc	ra,0xffffb
    800052c0:	27c080e7          	jalr	636(ra) # 80000538 <panic>
    dp->nlink++;  // for ".."
    800052c4:	04a95783          	lhu	a5,74(s2)
    800052c8:	2785                	addiw	a5,a5,1
    800052ca:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800052ce:	854a                	mv	a0,s2
    800052d0:	ffffe097          	auipc	ra,0xffffe
    800052d4:	4ec080e7          	jalr	1260(ra) # 800037bc <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800052d8:	40d0                	lw	a2,4(s1)
    800052da:	00003597          	auipc	a1,0x3
    800052de:	45e58593          	addi	a1,a1,1118 # 80008738 <syscalls+0x2d8>
    800052e2:	8526                	mv	a0,s1
    800052e4:	fffff097          	auipc	ra,0xfffff
    800052e8:	c96080e7          	jalr	-874(ra) # 80003f7a <dirlink>
    800052ec:	00054f63          	bltz	a0,8000530a <create+0x142>
    800052f0:	00492603          	lw	a2,4(s2)
    800052f4:	00003597          	auipc	a1,0x3
    800052f8:	44c58593          	addi	a1,a1,1100 # 80008740 <syscalls+0x2e0>
    800052fc:	8526                	mv	a0,s1
    800052fe:	fffff097          	auipc	ra,0xfffff
    80005302:	c7c080e7          	jalr	-900(ra) # 80003f7a <dirlink>
    80005306:	f80557e3          	bgez	a0,80005294 <create+0xcc>
      panic("create dots");
    8000530a:	00003517          	auipc	a0,0x3
    8000530e:	43e50513          	addi	a0,a0,1086 # 80008748 <syscalls+0x2e8>
    80005312:	ffffb097          	auipc	ra,0xffffb
    80005316:	226080e7          	jalr	550(ra) # 80000538 <panic>
    panic("create: dirlink");
    8000531a:	00003517          	auipc	a0,0x3
    8000531e:	43e50513          	addi	a0,a0,1086 # 80008758 <syscalls+0x2f8>
    80005322:	ffffb097          	auipc	ra,0xffffb
    80005326:	216080e7          	jalr	534(ra) # 80000538 <panic>
    return 0;
    8000532a:	84aa                	mv	s1,a0
    8000532c:	b739                	j	8000523a <create+0x72>

000000008000532e <sys_dup>:
{
    8000532e:	7179                	addi	sp,sp,-48
    80005330:	f406                	sd	ra,40(sp)
    80005332:	f022                	sd	s0,32(sp)
    80005334:	ec26                	sd	s1,24(sp)
    80005336:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005338:	fd840613          	addi	a2,s0,-40
    8000533c:	4581                	li	a1,0
    8000533e:	4501                	li	a0,0
    80005340:	00000097          	auipc	ra,0x0
    80005344:	dde080e7          	jalr	-546(ra) # 8000511e <argfd>
    return -1;
    80005348:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000534a:	02054363          	bltz	a0,80005370 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000534e:	fd843503          	ld	a0,-40(s0)
    80005352:	00000097          	auipc	ra,0x0
    80005356:	e34080e7          	jalr	-460(ra) # 80005186 <fdalloc>
    8000535a:	84aa                	mv	s1,a0
    return -1;
    8000535c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000535e:	00054963          	bltz	a0,80005370 <sys_dup+0x42>
  filedup(f);
    80005362:	fd843503          	ld	a0,-40(s0)
    80005366:	fffff097          	auipc	ra,0xfffff
    8000536a:	36c080e7          	jalr	876(ra) # 800046d2 <filedup>
  return fd;
    8000536e:	87a6                	mv	a5,s1
}
    80005370:	853e                	mv	a0,a5
    80005372:	70a2                	ld	ra,40(sp)
    80005374:	7402                	ld	s0,32(sp)
    80005376:	64e2                	ld	s1,24(sp)
    80005378:	6145                	addi	sp,sp,48
    8000537a:	8082                	ret

000000008000537c <sys_read>:
{
    8000537c:	7179                	addi	sp,sp,-48
    8000537e:	f406                	sd	ra,40(sp)
    80005380:	f022                	sd	s0,32(sp)
    80005382:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005384:	fe840613          	addi	a2,s0,-24
    80005388:	4581                	li	a1,0
    8000538a:	4501                	li	a0,0
    8000538c:	00000097          	auipc	ra,0x0
    80005390:	d92080e7          	jalr	-622(ra) # 8000511e <argfd>
    return -1;
    80005394:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005396:	04054163          	bltz	a0,800053d8 <sys_read+0x5c>
    8000539a:	fe440593          	addi	a1,s0,-28
    8000539e:	4509                	li	a0,2
    800053a0:	ffffe097          	auipc	ra,0xffffe
    800053a4:	854080e7          	jalr	-1964(ra) # 80002bf4 <argint>
    return -1;
    800053a8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053aa:	02054763          	bltz	a0,800053d8 <sys_read+0x5c>
    800053ae:	fd840593          	addi	a1,s0,-40
    800053b2:	4505                	li	a0,1
    800053b4:	ffffe097          	auipc	ra,0xffffe
    800053b8:	862080e7          	jalr	-1950(ra) # 80002c16 <argaddr>
    return -1;
    800053bc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053be:	00054d63          	bltz	a0,800053d8 <sys_read+0x5c>
  return fileread(f, p, n);
    800053c2:	fe442603          	lw	a2,-28(s0)
    800053c6:	fd843583          	ld	a1,-40(s0)
    800053ca:	fe843503          	ld	a0,-24(s0)
    800053ce:	fffff097          	auipc	ra,0xfffff
    800053d2:	490080e7          	jalr	1168(ra) # 8000485e <fileread>
    800053d6:	87aa                	mv	a5,a0
}
    800053d8:	853e                	mv	a0,a5
    800053da:	70a2                	ld	ra,40(sp)
    800053dc:	7402                	ld	s0,32(sp)
    800053de:	6145                	addi	sp,sp,48
    800053e0:	8082                	ret

00000000800053e2 <sys_write>:
{
    800053e2:	7179                	addi	sp,sp,-48
    800053e4:	f406                	sd	ra,40(sp)
    800053e6:	f022                	sd	s0,32(sp)
    800053e8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053ea:	fe840613          	addi	a2,s0,-24
    800053ee:	4581                	li	a1,0
    800053f0:	4501                	li	a0,0
    800053f2:	00000097          	auipc	ra,0x0
    800053f6:	d2c080e7          	jalr	-724(ra) # 8000511e <argfd>
    return -1;
    800053fa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053fc:	04054163          	bltz	a0,8000543e <sys_write+0x5c>
    80005400:	fe440593          	addi	a1,s0,-28
    80005404:	4509                	li	a0,2
    80005406:	ffffd097          	auipc	ra,0xffffd
    8000540a:	7ee080e7          	jalr	2030(ra) # 80002bf4 <argint>
    return -1;
    8000540e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005410:	02054763          	bltz	a0,8000543e <sys_write+0x5c>
    80005414:	fd840593          	addi	a1,s0,-40
    80005418:	4505                	li	a0,1
    8000541a:	ffffd097          	auipc	ra,0xffffd
    8000541e:	7fc080e7          	jalr	2044(ra) # 80002c16 <argaddr>
    return -1;
    80005422:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005424:	00054d63          	bltz	a0,8000543e <sys_write+0x5c>
  return filewrite(f, p, n);
    80005428:	fe442603          	lw	a2,-28(s0)
    8000542c:	fd843583          	ld	a1,-40(s0)
    80005430:	fe843503          	ld	a0,-24(s0)
    80005434:	fffff097          	auipc	ra,0xfffff
    80005438:	4ec080e7          	jalr	1260(ra) # 80004920 <filewrite>
    8000543c:	87aa                	mv	a5,a0
}
    8000543e:	853e                	mv	a0,a5
    80005440:	70a2                	ld	ra,40(sp)
    80005442:	7402                	ld	s0,32(sp)
    80005444:	6145                	addi	sp,sp,48
    80005446:	8082                	ret

0000000080005448 <sys_close>:
{
    80005448:	1101                	addi	sp,sp,-32
    8000544a:	ec06                	sd	ra,24(sp)
    8000544c:	e822                	sd	s0,16(sp)
    8000544e:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005450:	fe040613          	addi	a2,s0,-32
    80005454:	fec40593          	addi	a1,s0,-20
    80005458:	4501                	li	a0,0
    8000545a:	00000097          	auipc	ra,0x0
    8000545e:	cc4080e7          	jalr	-828(ra) # 8000511e <argfd>
    return -1;
    80005462:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005464:	02054463          	bltz	a0,8000548c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005468:	ffffc097          	auipc	ra,0xffffc
    8000546c:	52e080e7          	jalr	1326(ra) # 80001996 <myproc>
    80005470:	fec42783          	lw	a5,-20(s0)
    80005474:	07e9                	addi	a5,a5,26
    80005476:	078e                	slli	a5,a5,0x3
    80005478:	97aa                	add	a5,a5,a0
    8000547a:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000547e:	fe043503          	ld	a0,-32(s0)
    80005482:	fffff097          	auipc	ra,0xfffff
    80005486:	2a2080e7          	jalr	674(ra) # 80004724 <fileclose>
  return 0;
    8000548a:	4781                	li	a5,0
}
    8000548c:	853e                	mv	a0,a5
    8000548e:	60e2                	ld	ra,24(sp)
    80005490:	6442                	ld	s0,16(sp)
    80005492:	6105                	addi	sp,sp,32
    80005494:	8082                	ret

0000000080005496 <sys_fstat>:
{
    80005496:	1101                	addi	sp,sp,-32
    80005498:	ec06                	sd	ra,24(sp)
    8000549a:	e822                	sd	s0,16(sp)
    8000549c:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000549e:	fe840613          	addi	a2,s0,-24
    800054a2:	4581                	li	a1,0
    800054a4:	4501                	li	a0,0
    800054a6:	00000097          	auipc	ra,0x0
    800054aa:	c78080e7          	jalr	-904(ra) # 8000511e <argfd>
    return -1;
    800054ae:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054b0:	02054563          	bltz	a0,800054da <sys_fstat+0x44>
    800054b4:	fe040593          	addi	a1,s0,-32
    800054b8:	4505                	li	a0,1
    800054ba:	ffffd097          	auipc	ra,0xffffd
    800054be:	75c080e7          	jalr	1884(ra) # 80002c16 <argaddr>
    return -1;
    800054c2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054c4:	00054b63          	bltz	a0,800054da <sys_fstat+0x44>
  return filestat(f, st);
    800054c8:	fe043583          	ld	a1,-32(s0)
    800054cc:	fe843503          	ld	a0,-24(s0)
    800054d0:	fffff097          	auipc	ra,0xfffff
    800054d4:	31c080e7          	jalr	796(ra) # 800047ec <filestat>
    800054d8:	87aa                	mv	a5,a0
}
    800054da:	853e                	mv	a0,a5
    800054dc:	60e2                	ld	ra,24(sp)
    800054de:	6442                	ld	s0,16(sp)
    800054e0:	6105                	addi	sp,sp,32
    800054e2:	8082                	ret

00000000800054e4 <sys_link>:
{
    800054e4:	7169                	addi	sp,sp,-304
    800054e6:	f606                	sd	ra,296(sp)
    800054e8:	f222                	sd	s0,288(sp)
    800054ea:	ee26                	sd	s1,280(sp)
    800054ec:	ea4a                	sd	s2,272(sp)
    800054ee:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054f0:	08000613          	li	a2,128
    800054f4:	ed040593          	addi	a1,s0,-304
    800054f8:	4501                	li	a0,0
    800054fa:	ffffd097          	auipc	ra,0xffffd
    800054fe:	73e080e7          	jalr	1854(ra) # 80002c38 <argstr>
    return -1;
    80005502:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005504:	10054e63          	bltz	a0,80005620 <sys_link+0x13c>
    80005508:	08000613          	li	a2,128
    8000550c:	f5040593          	addi	a1,s0,-176
    80005510:	4505                	li	a0,1
    80005512:	ffffd097          	auipc	ra,0xffffd
    80005516:	726080e7          	jalr	1830(ra) # 80002c38 <argstr>
    return -1;
    8000551a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000551c:	10054263          	bltz	a0,80005620 <sys_link+0x13c>
  begin_op();
    80005520:	fffff097          	auipc	ra,0xfffff
    80005524:	d38080e7          	jalr	-712(ra) # 80004258 <begin_op>
  if((ip = namei(old)) == 0){
    80005528:	ed040513          	addi	a0,s0,-304
    8000552c:	fffff097          	auipc	ra,0xfffff
    80005530:	b10080e7          	jalr	-1264(ra) # 8000403c <namei>
    80005534:	84aa                	mv	s1,a0
    80005536:	c551                	beqz	a0,800055c2 <sys_link+0xde>
  ilock(ip);
    80005538:	ffffe097          	auipc	ra,0xffffe
    8000553c:	34e080e7          	jalr	846(ra) # 80003886 <ilock>
  if(ip->type == T_DIR){
    80005540:	04449703          	lh	a4,68(s1)
    80005544:	4785                	li	a5,1
    80005546:	08f70463          	beq	a4,a5,800055ce <sys_link+0xea>
  ip->nlink++;
    8000554a:	04a4d783          	lhu	a5,74(s1)
    8000554e:	2785                	addiw	a5,a5,1
    80005550:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005554:	8526                	mv	a0,s1
    80005556:	ffffe097          	auipc	ra,0xffffe
    8000555a:	266080e7          	jalr	614(ra) # 800037bc <iupdate>
  iunlock(ip);
    8000555e:	8526                	mv	a0,s1
    80005560:	ffffe097          	auipc	ra,0xffffe
    80005564:	3e8080e7          	jalr	1000(ra) # 80003948 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005568:	fd040593          	addi	a1,s0,-48
    8000556c:	f5040513          	addi	a0,s0,-176
    80005570:	fffff097          	auipc	ra,0xfffff
    80005574:	aea080e7          	jalr	-1302(ra) # 8000405a <nameiparent>
    80005578:	892a                	mv	s2,a0
    8000557a:	c935                	beqz	a0,800055ee <sys_link+0x10a>
  ilock(dp);
    8000557c:	ffffe097          	auipc	ra,0xffffe
    80005580:	30a080e7          	jalr	778(ra) # 80003886 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005584:	00092703          	lw	a4,0(s2)
    80005588:	409c                	lw	a5,0(s1)
    8000558a:	04f71d63          	bne	a4,a5,800055e4 <sys_link+0x100>
    8000558e:	40d0                	lw	a2,4(s1)
    80005590:	fd040593          	addi	a1,s0,-48
    80005594:	854a                	mv	a0,s2
    80005596:	fffff097          	auipc	ra,0xfffff
    8000559a:	9e4080e7          	jalr	-1564(ra) # 80003f7a <dirlink>
    8000559e:	04054363          	bltz	a0,800055e4 <sys_link+0x100>
  iunlockput(dp);
    800055a2:	854a                	mv	a0,s2
    800055a4:	ffffe097          	auipc	ra,0xffffe
    800055a8:	544080e7          	jalr	1348(ra) # 80003ae8 <iunlockput>
  iput(ip);
    800055ac:	8526                	mv	a0,s1
    800055ae:	ffffe097          	auipc	ra,0xffffe
    800055b2:	492080e7          	jalr	1170(ra) # 80003a40 <iput>
  end_op();
    800055b6:	fffff097          	auipc	ra,0xfffff
    800055ba:	d22080e7          	jalr	-734(ra) # 800042d8 <end_op>
  return 0;
    800055be:	4781                	li	a5,0
    800055c0:	a085                	j	80005620 <sys_link+0x13c>
    end_op();
    800055c2:	fffff097          	auipc	ra,0xfffff
    800055c6:	d16080e7          	jalr	-746(ra) # 800042d8 <end_op>
    return -1;
    800055ca:	57fd                	li	a5,-1
    800055cc:	a891                	j	80005620 <sys_link+0x13c>
    iunlockput(ip);
    800055ce:	8526                	mv	a0,s1
    800055d0:	ffffe097          	auipc	ra,0xffffe
    800055d4:	518080e7          	jalr	1304(ra) # 80003ae8 <iunlockput>
    end_op();
    800055d8:	fffff097          	auipc	ra,0xfffff
    800055dc:	d00080e7          	jalr	-768(ra) # 800042d8 <end_op>
    return -1;
    800055e0:	57fd                	li	a5,-1
    800055e2:	a83d                	j	80005620 <sys_link+0x13c>
    iunlockput(dp);
    800055e4:	854a                	mv	a0,s2
    800055e6:	ffffe097          	auipc	ra,0xffffe
    800055ea:	502080e7          	jalr	1282(ra) # 80003ae8 <iunlockput>
  ilock(ip);
    800055ee:	8526                	mv	a0,s1
    800055f0:	ffffe097          	auipc	ra,0xffffe
    800055f4:	296080e7          	jalr	662(ra) # 80003886 <ilock>
  ip->nlink--;
    800055f8:	04a4d783          	lhu	a5,74(s1)
    800055fc:	37fd                	addiw	a5,a5,-1
    800055fe:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005602:	8526                	mv	a0,s1
    80005604:	ffffe097          	auipc	ra,0xffffe
    80005608:	1b8080e7          	jalr	440(ra) # 800037bc <iupdate>
  iunlockput(ip);
    8000560c:	8526                	mv	a0,s1
    8000560e:	ffffe097          	auipc	ra,0xffffe
    80005612:	4da080e7          	jalr	1242(ra) # 80003ae8 <iunlockput>
  end_op();
    80005616:	fffff097          	auipc	ra,0xfffff
    8000561a:	cc2080e7          	jalr	-830(ra) # 800042d8 <end_op>
  return -1;
    8000561e:	57fd                	li	a5,-1
}
    80005620:	853e                	mv	a0,a5
    80005622:	70b2                	ld	ra,296(sp)
    80005624:	7412                	ld	s0,288(sp)
    80005626:	64f2                	ld	s1,280(sp)
    80005628:	6952                	ld	s2,272(sp)
    8000562a:	6155                	addi	sp,sp,304
    8000562c:	8082                	ret

000000008000562e <sys_unlink>:
{
    8000562e:	7151                	addi	sp,sp,-240
    80005630:	f586                	sd	ra,232(sp)
    80005632:	f1a2                	sd	s0,224(sp)
    80005634:	eda6                	sd	s1,216(sp)
    80005636:	e9ca                	sd	s2,208(sp)
    80005638:	e5ce                	sd	s3,200(sp)
    8000563a:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000563c:	08000613          	li	a2,128
    80005640:	f3040593          	addi	a1,s0,-208
    80005644:	4501                	li	a0,0
    80005646:	ffffd097          	auipc	ra,0xffffd
    8000564a:	5f2080e7          	jalr	1522(ra) # 80002c38 <argstr>
    8000564e:	18054163          	bltz	a0,800057d0 <sys_unlink+0x1a2>
  begin_op();
    80005652:	fffff097          	auipc	ra,0xfffff
    80005656:	c06080e7          	jalr	-1018(ra) # 80004258 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000565a:	fb040593          	addi	a1,s0,-80
    8000565e:	f3040513          	addi	a0,s0,-208
    80005662:	fffff097          	auipc	ra,0xfffff
    80005666:	9f8080e7          	jalr	-1544(ra) # 8000405a <nameiparent>
    8000566a:	84aa                	mv	s1,a0
    8000566c:	c979                	beqz	a0,80005742 <sys_unlink+0x114>
  ilock(dp);
    8000566e:	ffffe097          	auipc	ra,0xffffe
    80005672:	218080e7          	jalr	536(ra) # 80003886 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005676:	00003597          	auipc	a1,0x3
    8000567a:	0c258593          	addi	a1,a1,194 # 80008738 <syscalls+0x2d8>
    8000567e:	fb040513          	addi	a0,s0,-80
    80005682:	ffffe097          	auipc	ra,0xffffe
    80005686:	6ce080e7          	jalr	1742(ra) # 80003d50 <namecmp>
    8000568a:	14050a63          	beqz	a0,800057de <sys_unlink+0x1b0>
    8000568e:	00003597          	auipc	a1,0x3
    80005692:	0b258593          	addi	a1,a1,178 # 80008740 <syscalls+0x2e0>
    80005696:	fb040513          	addi	a0,s0,-80
    8000569a:	ffffe097          	auipc	ra,0xffffe
    8000569e:	6b6080e7          	jalr	1718(ra) # 80003d50 <namecmp>
    800056a2:	12050e63          	beqz	a0,800057de <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800056a6:	f2c40613          	addi	a2,s0,-212
    800056aa:	fb040593          	addi	a1,s0,-80
    800056ae:	8526                	mv	a0,s1
    800056b0:	ffffe097          	auipc	ra,0xffffe
    800056b4:	6ba080e7          	jalr	1722(ra) # 80003d6a <dirlookup>
    800056b8:	892a                	mv	s2,a0
    800056ba:	12050263          	beqz	a0,800057de <sys_unlink+0x1b0>
  ilock(ip);
    800056be:	ffffe097          	auipc	ra,0xffffe
    800056c2:	1c8080e7          	jalr	456(ra) # 80003886 <ilock>
  if(ip->nlink < 1)
    800056c6:	04a91783          	lh	a5,74(s2)
    800056ca:	08f05263          	blez	a5,8000574e <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800056ce:	04491703          	lh	a4,68(s2)
    800056d2:	4785                	li	a5,1
    800056d4:	08f70563          	beq	a4,a5,8000575e <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800056d8:	4641                	li	a2,16
    800056da:	4581                	li	a1,0
    800056dc:	fc040513          	addi	a0,s0,-64
    800056e0:	ffffb097          	auipc	ra,0xffffb
    800056e4:	5ec080e7          	jalr	1516(ra) # 80000ccc <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056e8:	4741                	li	a4,16
    800056ea:	f2c42683          	lw	a3,-212(s0)
    800056ee:	fc040613          	addi	a2,s0,-64
    800056f2:	4581                	li	a1,0
    800056f4:	8526                	mv	a0,s1
    800056f6:	ffffe097          	auipc	ra,0xffffe
    800056fa:	53c080e7          	jalr	1340(ra) # 80003c32 <writei>
    800056fe:	47c1                	li	a5,16
    80005700:	0af51563          	bne	a0,a5,800057aa <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005704:	04491703          	lh	a4,68(s2)
    80005708:	4785                	li	a5,1
    8000570a:	0af70863          	beq	a4,a5,800057ba <sys_unlink+0x18c>
  iunlockput(dp);
    8000570e:	8526                	mv	a0,s1
    80005710:	ffffe097          	auipc	ra,0xffffe
    80005714:	3d8080e7          	jalr	984(ra) # 80003ae8 <iunlockput>
  ip->nlink--;
    80005718:	04a95783          	lhu	a5,74(s2)
    8000571c:	37fd                	addiw	a5,a5,-1
    8000571e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005722:	854a                	mv	a0,s2
    80005724:	ffffe097          	auipc	ra,0xffffe
    80005728:	098080e7          	jalr	152(ra) # 800037bc <iupdate>
  iunlockput(ip);
    8000572c:	854a                	mv	a0,s2
    8000572e:	ffffe097          	auipc	ra,0xffffe
    80005732:	3ba080e7          	jalr	954(ra) # 80003ae8 <iunlockput>
  end_op();
    80005736:	fffff097          	auipc	ra,0xfffff
    8000573a:	ba2080e7          	jalr	-1118(ra) # 800042d8 <end_op>
  return 0;
    8000573e:	4501                	li	a0,0
    80005740:	a84d                	j	800057f2 <sys_unlink+0x1c4>
    end_op();
    80005742:	fffff097          	auipc	ra,0xfffff
    80005746:	b96080e7          	jalr	-1130(ra) # 800042d8 <end_op>
    return -1;
    8000574a:	557d                	li	a0,-1
    8000574c:	a05d                	j	800057f2 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000574e:	00003517          	auipc	a0,0x3
    80005752:	01a50513          	addi	a0,a0,26 # 80008768 <syscalls+0x308>
    80005756:	ffffb097          	auipc	ra,0xffffb
    8000575a:	de2080e7          	jalr	-542(ra) # 80000538 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000575e:	04c92703          	lw	a4,76(s2)
    80005762:	02000793          	li	a5,32
    80005766:	f6e7f9e3          	bgeu	a5,a4,800056d8 <sys_unlink+0xaa>
    8000576a:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000576e:	4741                	li	a4,16
    80005770:	86ce                	mv	a3,s3
    80005772:	f1840613          	addi	a2,s0,-232
    80005776:	4581                	li	a1,0
    80005778:	854a                	mv	a0,s2
    8000577a:	ffffe097          	auipc	ra,0xffffe
    8000577e:	3c0080e7          	jalr	960(ra) # 80003b3a <readi>
    80005782:	47c1                	li	a5,16
    80005784:	00f51b63          	bne	a0,a5,8000579a <sys_unlink+0x16c>
    if(de.inum != 0)
    80005788:	f1845783          	lhu	a5,-232(s0)
    8000578c:	e7a1                	bnez	a5,800057d4 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000578e:	29c1                	addiw	s3,s3,16
    80005790:	04c92783          	lw	a5,76(s2)
    80005794:	fcf9ede3          	bltu	s3,a5,8000576e <sys_unlink+0x140>
    80005798:	b781                	j	800056d8 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000579a:	00003517          	auipc	a0,0x3
    8000579e:	fe650513          	addi	a0,a0,-26 # 80008780 <syscalls+0x320>
    800057a2:	ffffb097          	auipc	ra,0xffffb
    800057a6:	d96080e7          	jalr	-618(ra) # 80000538 <panic>
    panic("unlink: writei");
    800057aa:	00003517          	auipc	a0,0x3
    800057ae:	fee50513          	addi	a0,a0,-18 # 80008798 <syscalls+0x338>
    800057b2:	ffffb097          	auipc	ra,0xffffb
    800057b6:	d86080e7          	jalr	-634(ra) # 80000538 <panic>
    dp->nlink--;
    800057ba:	04a4d783          	lhu	a5,74(s1)
    800057be:	37fd                	addiw	a5,a5,-1
    800057c0:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800057c4:	8526                	mv	a0,s1
    800057c6:	ffffe097          	auipc	ra,0xffffe
    800057ca:	ff6080e7          	jalr	-10(ra) # 800037bc <iupdate>
    800057ce:	b781                	j	8000570e <sys_unlink+0xe0>
    return -1;
    800057d0:	557d                	li	a0,-1
    800057d2:	a005                	j	800057f2 <sys_unlink+0x1c4>
    iunlockput(ip);
    800057d4:	854a                	mv	a0,s2
    800057d6:	ffffe097          	auipc	ra,0xffffe
    800057da:	312080e7          	jalr	786(ra) # 80003ae8 <iunlockput>
  iunlockput(dp);
    800057de:	8526                	mv	a0,s1
    800057e0:	ffffe097          	auipc	ra,0xffffe
    800057e4:	308080e7          	jalr	776(ra) # 80003ae8 <iunlockput>
  end_op();
    800057e8:	fffff097          	auipc	ra,0xfffff
    800057ec:	af0080e7          	jalr	-1296(ra) # 800042d8 <end_op>
  return -1;
    800057f0:	557d                	li	a0,-1
}
    800057f2:	70ae                	ld	ra,232(sp)
    800057f4:	740e                	ld	s0,224(sp)
    800057f6:	64ee                	ld	s1,216(sp)
    800057f8:	694e                	ld	s2,208(sp)
    800057fa:	69ae                	ld	s3,200(sp)
    800057fc:	616d                	addi	sp,sp,240
    800057fe:	8082                	ret

0000000080005800 <sys_open>:

uint64
sys_open(void)
{
    80005800:	7131                	addi	sp,sp,-192
    80005802:	fd06                	sd	ra,184(sp)
    80005804:	f922                	sd	s0,176(sp)
    80005806:	f526                	sd	s1,168(sp)
    80005808:	f14a                	sd	s2,160(sp)
    8000580a:	ed4e                	sd	s3,152(sp)
    8000580c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000580e:	08000613          	li	a2,128
    80005812:	f5040593          	addi	a1,s0,-176
    80005816:	4501                	li	a0,0
    80005818:	ffffd097          	auipc	ra,0xffffd
    8000581c:	420080e7          	jalr	1056(ra) # 80002c38 <argstr>
    return -1;
    80005820:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005822:	0c054163          	bltz	a0,800058e4 <sys_open+0xe4>
    80005826:	f4c40593          	addi	a1,s0,-180
    8000582a:	4505                	li	a0,1
    8000582c:	ffffd097          	auipc	ra,0xffffd
    80005830:	3c8080e7          	jalr	968(ra) # 80002bf4 <argint>
    80005834:	0a054863          	bltz	a0,800058e4 <sys_open+0xe4>

  begin_op();
    80005838:	fffff097          	auipc	ra,0xfffff
    8000583c:	a20080e7          	jalr	-1504(ra) # 80004258 <begin_op>

  if(omode & O_CREATE){
    80005840:	f4c42783          	lw	a5,-180(s0)
    80005844:	2007f793          	andi	a5,a5,512
    80005848:	cbdd                	beqz	a5,800058fe <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000584a:	4681                	li	a3,0
    8000584c:	4601                	li	a2,0
    8000584e:	4589                	li	a1,2
    80005850:	f5040513          	addi	a0,s0,-176
    80005854:	00000097          	auipc	ra,0x0
    80005858:	974080e7          	jalr	-1676(ra) # 800051c8 <create>
    8000585c:	892a                	mv	s2,a0
    if(ip == 0){
    8000585e:	c959                	beqz	a0,800058f4 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005860:	04491703          	lh	a4,68(s2)
    80005864:	478d                	li	a5,3
    80005866:	00f71763          	bne	a4,a5,80005874 <sys_open+0x74>
    8000586a:	04695703          	lhu	a4,70(s2)
    8000586e:	47a5                	li	a5,9
    80005870:	0ce7ec63          	bltu	a5,a4,80005948 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005874:	fffff097          	auipc	ra,0xfffff
    80005878:	df4080e7          	jalr	-524(ra) # 80004668 <filealloc>
    8000587c:	89aa                	mv	s3,a0
    8000587e:	10050263          	beqz	a0,80005982 <sys_open+0x182>
    80005882:	00000097          	auipc	ra,0x0
    80005886:	904080e7          	jalr	-1788(ra) # 80005186 <fdalloc>
    8000588a:	84aa                	mv	s1,a0
    8000588c:	0e054663          	bltz	a0,80005978 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005890:	04491703          	lh	a4,68(s2)
    80005894:	478d                	li	a5,3
    80005896:	0cf70463          	beq	a4,a5,8000595e <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000589a:	4789                	li	a5,2
    8000589c:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800058a0:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800058a4:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800058a8:	f4c42783          	lw	a5,-180(s0)
    800058ac:	0017c713          	xori	a4,a5,1
    800058b0:	8b05                	andi	a4,a4,1
    800058b2:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800058b6:	0037f713          	andi	a4,a5,3
    800058ba:	00e03733          	snez	a4,a4
    800058be:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800058c2:	4007f793          	andi	a5,a5,1024
    800058c6:	c791                	beqz	a5,800058d2 <sys_open+0xd2>
    800058c8:	04491703          	lh	a4,68(s2)
    800058cc:	4789                	li	a5,2
    800058ce:	08f70f63          	beq	a4,a5,8000596c <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800058d2:	854a                	mv	a0,s2
    800058d4:	ffffe097          	auipc	ra,0xffffe
    800058d8:	074080e7          	jalr	116(ra) # 80003948 <iunlock>
  end_op();
    800058dc:	fffff097          	auipc	ra,0xfffff
    800058e0:	9fc080e7          	jalr	-1540(ra) # 800042d8 <end_op>

  return fd;
}
    800058e4:	8526                	mv	a0,s1
    800058e6:	70ea                	ld	ra,184(sp)
    800058e8:	744a                	ld	s0,176(sp)
    800058ea:	74aa                	ld	s1,168(sp)
    800058ec:	790a                	ld	s2,160(sp)
    800058ee:	69ea                	ld	s3,152(sp)
    800058f0:	6129                	addi	sp,sp,192
    800058f2:	8082                	ret
      end_op();
    800058f4:	fffff097          	auipc	ra,0xfffff
    800058f8:	9e4080e7          	jalr	-1564(ra) # 800042d8 <end_op>
      return -1;
    800058fc:	b7e5                	j	800058e4 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800058fe:	f5040513          	addi	a0,s0,-176
    80005902:	ffffe097          	auipc	ra,0xffffe
    80005906:	73a080e7          	jalr	1850(ra) # 8000403c <namei>
    8000590a:	892a                	mv	s2,a0
    8000590c:	c905                	beqz	a0,8000593c <sys_open+0x13c>
    ilock(ip);
    8000590e:	ffffe097          	auipc	ra,0xffffe
    80005912:	f78080e7          	jalr	-136(ra) # 80003886 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005916:	04491703          	lh	a4,68(s2)
    8000591a:	4785                	li	a5,1
    8000591c:	f4f712e3          	bne	a4,a5,80005860 <sys_open+0x60>
    80005920:	f4c42783          	lw	a5,-180(s0)
    80005924:	dba1                	beqz	a5,80005874 <sys_open+0x74>
      iunlockput(ip);
    80005926:	854a                	mv	a0,s2
    80005928:	ffffe097          	auipc	ra,0xffffe
    8000592c:	1c0080e7          	jalr	448(ra) # 80003ae8 <iunlockput>
      end_op();
    80005930:	fffff097          	auipc	ra,0xfffff
    80005934:	9a8080e7          	jalr	-1624(ra) # 800042d8 <end_op>
      return -1;
    80005938:	54fd                	li	s1,-1
    8000593a:	b76d                	j	800058e4 <sys_open+0xe4>
      end_op();
    8000593c:	fffff097          	auipc	ra,0xfffff
    80005940:	99c080e7          	jalr	-1636(ra) # 800042d8 <end_op>
      return -1;
    80005944:	54fd                	li	s1,-1
    80005946:	bf79                	j	800058e4 <sys_open+0xe4>
    iunlockput(ip);
    80005948:	854a                	mv	a0,s2
    8000594a:	ffffe097          	auipc	ra,0xffffe
    8000594e:	19e080e7          	jalr	414(ra) # 80003ae8 <iunlockput>
    end_op();
    80005952:	fffff097          	auipc	ra,0xfffff
    80005956:	986080e7          	jalr	-1658(ra) # 800042d8 <end_op>
    return -1;
    8000595a:	54fd                	li	s1,-1
    8000595c:	b761                	j	800058e4 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000595e:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005962:	04691783          	lh	a5,70(s2)
    80005966:	02f99223          	sh	a5,36(s3)
    8000596a:	bf2d                	j	800058a4 <sys_open+0xa4>
    itrunc(ip);
    8000596c:	854a                	mv	a0,s2
    8000596e:	ffffe097          	auipc	ra,0xffffe
    80005972:	026080e7          	jalr	38(ra) # 80003994 <itrunc>
    80005976:	bfb1                	j	800058d2 <sys_open+0xd2>
      fileclose(f);
    80005978:	854e                	mv	a0,s3
    8000597a:	fffff097          	auipc	ra,0xfffff
    8000597e:	daa080e7          	jalr	-598(ra) # 80004724 <fileclose>
    iunlockput(ip);
    80005982:	854a                	mv	a0,s2
    80005984:	ffffe097          	auipc	ra,0xffffe
    80005988:	164080e7          	jalr	356(ra) # 80003ae8 <iunlockput>
    end_op();
    8000598c:	fffff097          	auipc	ra,0xfffff
    80005990:	94c080e7          	jalr	-1716(ra) # 800042d8 <end_op>
    return -1;
    80005994:	54fd                	li	s1,-1
    80005996:	b7b9                	j	800058e4 <sys_open+0xe4>

0000000080005998 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005998:	7175                	addi	sp,sp,-144
    8000599a:	e506                	sd	ra,136(sp)
    8000599c:	e122                	sd	s0,128(sp)
    8000599e:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800059a0:	fffff097          	auipc	ra,0xfffff
    800059a4:	8b8080e7          	jalr	-1864(ra) # 80004258 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800059a8:	08000613          	li	a2,128
    800059ac:	f7040593          	addi	a1,s0,-144
    800059b0:	4501                	li	a0,0
    800059b2:	ffffd097          	auipc	ra,0xffffd
    800059b6:	286080e7          	jalr	646(ra) # 80002c38 <argstr>
    800059ba:	02054963          	bltz	a0,800059ec <sys_mkdir+0x54>
    800059be:	4681                	li	a3,0
    800059c0:	4601                	li	a2,0
    800059c2:	4585                	li	a1,1
    800059c4:	f7040513          	addi	a0,s0,-144
    800059c8:	00000097          	auipc	ra,0x0
    800059cc:	800080e7          	jalr	-2048(ra) # 800051c8 <create>
    800059d0:	cd11                	beqz	a0,800059ec <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059d2:	ffffe097          	auipc	ra,0xffffe
    800059d6:	116080e7          	jalr	278(ra) # 80003ae8 <iunlockput>
  end_op();
    800059da:	fffff097          	auipc	ra,0xfffff
    800059de:	8fe080e7          	jalr	-1794(ra) # 800042d8 <end_op>
  return 0;
    800059e2:	4501                	li	a0,0
}
    800059e4:	60aa                	ld	ra,136(sp)
    800059e6:	640a                	ld	s0,128(sp)
    800059e8:	6149                	addi	sp,sp,144
    800059ea:	8082                	ret
    end_op();
    800059ec:	fffff097          	auipc	ra,0xfffff
    800059f0:	8ec080e7          	jalr	-1812(ra) # 800042d8 <end_op>
    return -1;
    800059f4:	557d                	li	a0,-1
    800059f6:	b7fd                	j	800059e4 <sys_mkdir+0x4c>

00000000800059f8 <sys_mknod>:

uint64
sys_mknod(void)
{
    800059f8:	7135                	addi	sp,sp,-160
    800059fa:	ed06                	sd	ra,152(sp)
    800059fc:	e922                	sd	s0,144(sp)
    800059fe:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a00:	fffff097          	auipc	ra,0xfffff
    80005a04:	858080e7          	jalr	-1960(ra) # 80004258 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a08:	08000613          	li	a2,128
    80005a0c:	f7040593          	addi	a1,s0,-144
    80005a10:	4501                	li	a0,0
    80005a12:	ffffd097          	auipc	ra,0xffffd
    80005a16:	226080e7          	jalr	550(ra) # 80002c38 <argstr>
    80005a1a:	04054a63          	bltz	a0,80005a6e <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005a1e:	f6c40593          	addi	a1,s0,-148
    80005a22:	4505                	li	a0,1
    80005a24:	ffffd097          	auipc	ra,0xffffd
    80005a28:	1d0080e7          	jalr	464(ra) # 80002bf4 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a2c:	04054163          	bltz	a0,80005a6e <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005a30:	f6840593          	addi	a1,s0,-152
    80005a34:	4509                	li	a0,2
    80005a36:	ffffd097          	auipc	ra,0xffffd
    80005a3a:	1be080e7          	jalr	446(ra) # 80002bf4 <argint>
     argint(1, &major) < 0 ||
    80005a3e:	02054863          	bltz	a0,80005a6e <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a42:	f6841683          	lh	a3,-152(s0)
    80005a46:	f6c41603          	lh	a2,-148(s0)
    80005a4a:	458d                	li	a1,3
    80005a4c:	f7040513          	addi	a0,s0,-144
    80005a50:	fffff097          	auipc	ra,0xfffff
    80005a54:	778080e7          	jalr	1912(ra) # 800051c8 <create>
     argint(2, &minor) < 0 ||
    80005a58:	c919                	beqz	a0,80005a6e <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a5a:	ffffe097          	auipc	ra,0xffffe
    80005a5e:	08e080e7          	jalr	142(ra) # 80003ae8 <iunlockput>
  end_op();
    80005a62:	fffff097          	auipc	ra,0xfffff
    80005a66:	876080e7          	jalr	-1930(ra) # 800042d8 <end_op>
  return 0;
    80005a6a:	4501                	li	a0,0
    80005a6c:	a031                	j	80005a78 <sys_mknod+0x80>
    end_op();
    80005a6e:	fffff097          	auipc	ra,0xfffff
    80005a72:	86a080e7          	jalr	-1942(ra) # 800042d8 <end_op>
    return -1;
    80005a76:	557d                	li	a0,-1
}
    80005a78:	60ea                	ld	ra,152(sp)
    80005a7a:	644a                	ld	s0,144(sp)
    80005a7c:	610d                	addi	sp,sp,160
    80005a7e:	8082                	ret

0000000080005a80 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a80:	7135                	addi	sp,sp,-160
    80005a82:	ed06                	sd	ra,152(sp)
    80005a84:	e922                	sd	s0,144(sp)
    80005a86:	e526                	sd	s1,136(sp)
    80005a88:	e14a                	sd	s2,128(sp)
    80005a8a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a8c:	ffffc097          	auipc	ra,0xffffc
    80005a90:	f0a080e7          	jalr	-246(ra) # 80001996 <myproc>
    80005a94:	892a                	mv	s2,a0
  
  begin_op();
    80005a96:	ffffe097          	auipc	ra,0xffffe
    80005a9a:	7c2080e7          	jalr	1986(ra) # 80004258 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a9e:	08000613          	li	a2,128
    80005aa2:	f6040593          	addi	a1,s0,-160
    80005aa6:	4501                	li	a0,0
    80005aa8:	ffffd097          	auipc	ra,0xffffd
    80005aac:	190080e7          	jalr	400(ra) # 80002c38 <argstr>
    80005ab0:	04054b63          	bltz	a0,80005b06 <sys_chdir+0x86>
    80005ab4:	f6040513          	addi	a0,s0,-160
    80005ab8:	ffffe097          	auipc	ra,0xffffe
    80005abc:	584080e7          	jalr	1412(ra) # 8000403c <namei>
    80005ac0:	84aa                	mv	s1,a0
    80005ac2:	c131                	beqz	a0,80005b06 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005ac4:	ffffe097          	auipc	ra,0xffffe
    80005ac8:	dc2080e7          	jalr	-574(ra) # 80003886 <ilock>
  if(ip->type != T_DIR){
    80005acc:	04449703          	lh	a4,68(s1)
    80005ad0:	4785                	li	a5,1
    80005ad2:	04f71063          	bne	a4,a5,80005b12 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005ad6:	8526                	mv	a0,s1
    80005ad8:	ffffe097          	auipc	ra,0xffffe
    80005adc:	e70080e7          	jalr	-400(ra) # 80003948 <iunlock>
  iput(p->cwd);
    80005ae0:	15093503          	ld	a0,336(s2)
    80005ae4:	ffffe097          	auipc	ra,0xffffe
    80005ae8:	f5c080e7          	jalr	-164(ra) # 80003a40 <iput>
  end_op();
    80005aec:	ffffe097          	auipc	ra,0xffffe
    80005af0:	7ec080e7          	jalr	2028(ra) # 800042d8 <end_op>
  p->cwd = ip;
    80005af4:	14993823          	sd	s1,336(s2)
  return 0;
    80005af8:	4501                	li	a0,0
}
    80005afa:	60ea                	ld	ra,152(sp)
    80005afc:	644a                	ld	s0,144(sp)
    80005afe:	64aa                	ld	s1,136(sp)
    80005b00:	690a                	ld	s2,128(sp)
    80005b02:	610d                	addi	sp,sp,160
    80005b04:	8082                	ret
    end_op();
    80005b06:	ffffe097          	auipc	ra,0xffffe
    80005b0a:	7d2080e7          	jalr	2002(ra) # 800042d8 <end_op>
    return -1;
    80005b0e:	557d                	li	a0,-1
    80005b10:	b7ed                	j	80005afa <sys_chdir+0x7a>
    iunlockput(ip);
    80005b12:	8526                	mv	a0,s1
    80005b14:	ffffe097          	auipc	ra,0xffffe
    80005b18:	fd4080e7          	jalr	-44(ra) # 80003ae8 <iunlockput>
    end_op();
    80005b1c:	ffffe097          	auipc	ra,0xffffe
    80005b20:	7bc080e7          	jalr	1980(ra) # 800042d8 <end_op>
    return -1;
    80005b24:	557d                	li	a0,-1
    80005b26:	bfd1                	j	80005afa <sys_chdir+0x7a>

0000000080005b28 <sys_exec>:

uint64
sys_exec(void)
{
    80005b28:	7145                	addi	sp,sp,-464
    80005b2a:	e786                	sd	ra,456(sp)
    80005b2c:	e3a2                	sd	s0,448(sp)
    80005b2e:	ff26                	sd	s1,440(sp)
    80005b30:	fb4a                	sd	s2,432(sp)
    80005b32:	f74e                	sd	s3,424(sp)
    80005b34:	f352                	sd	s4,416(sp)
    80005b36:	ef56                	sd	s5,408(sp)
    80005b38:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b3a:	08000613          	li	a2,128
    80005b3e:	f4040593          	addi	a1,s0,-192
    80005b42:	4501                	li	a0,0
    80005b44:	ffffd097          	auipc	ra,0xffffd
    80005b48:	0f4080e7          	jalr	244(ra) # 80002c38 <argstr>
    return -1;
    80005b4c:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b4e:	0c054a63          	bltz	a0,80005c22 <sys_exec+0xfa>
    80005b52:	e3840593          	addi	a1,s0,-456
    80005b56:	4505                	li	a0,1
    80005b58:	ffffd097          	auipc	ra,0xffffd
    80005b5c:	0be080e7          	jalr	190(ra) # 80002c16 <argaddr>
    80005b60:	0c054163          	bltz	a0,80005c22 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005b64:	10000613          	li	a2,256
    80005b68:	4581                	li	a1,0
    80005b6a:	e4040513          	addi	a0,s0,-448
    80005b6e:	ffffb097          	auipc	ra,0xffffb
    80005b72:	15e080e7          	jalr	350(ra) # 80000ccc <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b76:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005b7a:	89a6                	mv	s3,s1
    80005b7c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005b7e:	02000a13          	li	s4,32
    80005b82:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b86:	00391793          	slli	a5,s2,0x3
    80005b8a:	e3040593          	addi	a1,s0,-464
    80005b8e:	e3843503          	ld	a0,-456(s0)
    80005b92:	953e                	add	a0,a0,a5
    80005b94:	ffffd097          	auipc	ra,0xffffd
    80005b98:	fc6080e7          	jalr	-58(ra) # 80002b5a <fetchaddr>
    80005b9c:	02054a63          	bltz	a0,80005bd0 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005ba0:	e3043783          	ld	a5,-464(s0)
    80005ba4:	c3b9                	beqz	a5,80005bea <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ba6:	ffffb097          	auipc	ra,0xffffb
    80005baa:	f3a080e7          	jalr	-198(ra) # 80000ae0 <kalloc>
    80005bae:	85aa                	mv	a1,a0
    80005bb0:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005bb4:	cd11                	beqz	a0,80005bd0 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005bb6:	6605                	lui	a2,0x1
    80005bb8:	e3043503          	ld	a0,-464(s0)
    80005bbc:	ffffd097          	auipc	ra,0xffffd
    80005bc0:	ff0080e7          	jalr	-16(ra) # 80002bac <fetchstr>
    80005bc4:	00054663          	bltz	a0,80005bd0 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005bc8:	0905                	addi	s2,s2,1
    80005bca:	09a1                	addi	s3,s3,8
    80005bcc:	fb491be3          	bne	s2,s4,80005b82 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bd0:	10048913          	addi	s2,s1,256
    80005bd4:	6088                	ld	a0,0(s1)
    80005bd6:	c529                	beqz	a0,80005c20 <sys_exec+0xf8>
    kfree(argv[i]);
    80005bd8:	ffffb097          	auipc	ra,0xffffb
    80005bdc:	e0c080e7          	jalr	-500(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005be0:	04a1                	addi	s1,s1,8
    80005be2:	ff2499e3          	bne	s1,s2,80005bd4 <sys_exec+0xac>
  return -1;
    80005be6:	597d                	li	s2,-1
    80005be8:	a82d                	j	80005c22 <sys_exec+0xfa>
      argv[i] = 0;
    80005bea:	0a8e                	slli	s5,s5,0x3
    80005bec:	fc040793          	addi	a5,s0,-64
    80005bf0:	9abe                	add	s5,s5,a5
    80005bf2:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd8e80>
  int ret = exec(path, argv);
    80005bf6:	e4040593          	addi	a1,s0,-448
    80005bfa:	f4040513          	addi	a0,s0,-192
    80005bfe:	fffff097          	auipc	ra,0xfffff
    80005c02:	178080e7          	jalr	376(ra) # 80004d76 <exec>
    80005c06:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c08:	10048993          	addi	s3,s1,256
    80005c0c:	6088                	ld	a0,0(s1)
    80005c0e:	c911                	beqz	a0,80005c22 <sys_exec+0xfa>
    kfree(argv[i]);
    80005c10:	ffffb097          	auipc	ra,0xffffb
    80005c14:	dd4080e7          	jalr	-556(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c18:	04a1                	addi	s1,s1,8
    80005c1a:	ff3499e3          	bne	s1,s3,80005c0c <sys_exec+0xe4>
    80005c1e:	a011                	j	80005c22 <sys_exec+0xfa>
  return -1;
    80005c20:	597d                	li	s2,-1
}
    80005c22:	854a                	mv	a0,s2
    80005c24:	60be                	ld	ra,456(sp)
    80005c26:	641e                	ld	s0,448(sp)
    80005c28:	74fa                	ld	s1,440(sp)
    80005c2a:	795a                	ld	s2,432(sp)
    80005c2c:	79ba                	ld	s3,424(sp)
    80005c2e:	7a1a                	ld	s4,416(sp)
    80005c30:	6afa                	ld	s5,408(sp)
    80005c32:	6179                	addi	sp,sp,464
    80005c34:	8082                	ret

0000000080005c36 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c36:	7139                	addi	sp,sp,-64
    80005c38:	fc06                	sd	ra,56(sp)
    80005c3a:	f822                	sd	s0,48(sp)
    80005c3c:	f426                	sd	s1,40(sp)
    80005c3e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c40:	ffffc097          	auipc	ra,0xffffc
    80005c44:	d56080e7          	jalr	-682(ra) # 80001996 <myproc>
    80005c48:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005c4a:	fd840593          	addi	a1,s0,-40
    80005c4e:	4501                	li	a0,0
    80005c50:	ffffd097          	auipc	ra,0xffffd
    80005c54:	fc6080e7          	jalr	-58(ra) # 80002c16 <argaddr>
    return -1;
    80005c58:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005c5a:	0e054063          	bltz	a0,80005d3a <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005c5e:	fc840593          	addi	a1,s0,-56
    80005c62:	fd040513          	addi	a0,s0,-48
    80005c66:	fffff097          	auipc	ra,0xfffff
    80005c6a:	dee080e7          	jalr	-530(ra) # 80004a54 <pipealloc>
    return -1;
    80005c6e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c70:	0c054563          	bltz	a0,80005d3a <sys_pipe+0x104>
  fd0 = -1;
    80005c74:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c78:	fd043503          	ld	a0,-48(s0)
    80005c7c:	fffff097          	auipc	ra,0xfffff
    80005c80:	50a080e7          	jalr	1290(ra) # 80005186 <fdalloc>
    80005c84:	fca42223          	sw	a0,-60(s0)
    80005c88:	08054c63          	bltz	a0,80005d20 <sys_pipe+0xea>
    80005c8c:	fc843503          	ld	a0,-56(s0)
    80005c90:	fffff097          	auipc	ra,0xfffff
    80005c94:	4f6080e7          	jalr	1270(ra) # 80005186 <fdalloc>
    80005c98:	fca42023          	sw	a0,-64(s0)
    80005c9c:	06054863          	bltz	a0,80005d0c <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ca0:	4691                	li	a3,4
    80005ca2:	fc440613          	addi	a2,s0,-60
    80005ca6:	fd843583          	ld	a1,-40(s0)
    80005caa:	68a8                	ld	a0,80(s1)
    80005cac:	ffffc097          	auipc	ra,0xffffc
    80005cb0:	9aa080e7          	jalr	-1622(ra) # 80001656 <copyout>
    80005cb4:	02054063          	bltz	a0,80005cd4 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005cb8:	4691                	li	a3,4
    80005cba:	fc040613          	addi	a2,s0,-64
    80005cbe:	fd843583          	ld	a1,-40(s0)
    80005cc2:	0591                	addi	a1,a1,4
    80005cc4:	68a8                	ld	a0,80(s1)
    80005cc6:	ffffc097          	auipc	ra,0xffffc
    80005cca:	990080e7          	jalr	-1648(ra) # 80001656 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005cce:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005cd0:	06055563          	bgez	a0,80005d3a <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005cd4:	fc442783          	lw	a5,-60(s0)
    80005cd8:	07e9                	addi	a5,a5,26
    80005cda:	078e                	slli	a5,a5,0x3
    80005cdc:	97a6                	add	a5,a5,s1
    80005cde:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005ce2:	fc042503          	lw	a0,-64(s0)
    80005ce6:	0569                	addi	a0,a0,26
    80005ce8:	050e                	slli	a0,a0,0x3
    80005cea:	9526                	add	a0,a0,s1
    80005cec:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005cf0:	fd043503          	ld	a0,-48(s0)
    80005cf4:	fffff097          	auipc	ra,0xfffff
    80005cf8:	a30080e7          	jalr	-1488(ra) # 80004724 <fileclose>
    fileclose(wf);
    80005cfc:	fc843503          	ld	a0,-56(s0)
    80005d00:	fffff097          	auipc	ra,0xfffff
    80005d04:	a24080e7          	jalr	-1500(ra) # 80004724 <fileclose>
    return -1;
    80005d08:	57fd                	li	a5,-1
    80005d0a:	a805                	j	80005d3a <sys_pipe+0x104>
    if(fd0 >= 0)
    80005d0c:	fc442783          	lw	a5,-60(s0)
    80005d10:	0007c863          	bltz	a5,80005d20 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005d14:	01a78513          	addi	a0,a5,26
    80005d18:	050e                	slli	a0,a0,0x3
    80005d1a:	9526                	add	a0,a0,s1
    80005d1c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d20:	fd043503          	ld	a0,-48(s0)
    80005d24:	fffff097          	auipc	ra,0xfffff
    80005d28:	a00080e7          	jalr	-1536(ra) # 80004724 <fileclose>
    fileclose(wf);
    80005d2c:	fc843503          	ld	a0,-56(s0)
    80005d30:	fffff097          	auipc	ra,0xfffff
    80005d34:	9f4080e7          	jalr	-1548(ra) # 80004724 <fileclose>
    return -1;
    80005d38:	57fd                	li	a5,-1
}
    80005d3a:	853e                	mv	a0,a5
    80005d3c:	70e2                	ld	ra,56(sp)
    80005d3e:	7442                	ld	s0,48(sp)
    80005d40:	74a2                	ld	s1,40(sp)
    80005d42:	6121                	addi	sp,sp,64
    80005d44:	8082                	ret
	...

0000000080005d50 <kernelvec>:
    80005d50:	7111                	addi	sp,sp,-256
    80005d52:	e006                	sd	ra,0(sp)
    80005d54:	e40a                	sd	sp,8(sp)
    80005d56:	e80e                	sd	gp,16(sp)
    80005d58:	ec12                	sd	tp,24(sp)
    80005d5a:	f016                	sd	t0,32(sp)
    80005d5c:	f41a                	sd	t1,40(sp)
    80005d5e:	f81e                	sd	t2,48(sp)
    80005d60:	fc22                	sd	s0,56(sp)
    80005d62:	e0a6                	sd	s1,64(sp)
    80005d64:	e4aa                	sd	a0,72(sp)
    80005d66:	e8ae                	sd	a1,80(sp)
    80005d68:	ecb2                	sd	a2,88(sp)
    80005d6a:	f0b6                	sd	a3,96(sp)
    80005d6c:	f4ba                	sd	a4,104(sp)
    80005d6e:	f8be                	sd	a5,112(sp)
    80005d70:	fcc2                	sd	a6,120(sp)
    80005d72:	e146                	sd	a7,128(sp)
    80005d74:	e54a                	sd	s2,136(sp)
    80005d76:	e94e                	sd	s3,144(sp)
    80005d78:	ed52                	sd	s4,152(sp)
    80005d7a:	f156                	sd	s5,160(sp)
    80005d7c:	f55a                	sd	s6,168(sp)
    80005d7e:	f95e                	sd	s7,176(sp)
    80005d80:	fd62                	sd	s8,184(sp)
    80005d82:	e1e6                	sd	s9,192(sp)
    80005d84:	e5ea                	sd	s10,200(sp)
    80005d86:	e9ee                	sd	s11,208(sp)
    80005d88:	edf2                	sd	t3,216(sp)
    80005d8a:	f1f6                	sd	t4,224(sp)
    80005d8c:	f5fa                	sd	t5,232(sp)
    80005d8e:	f9fe                	sd	t6,240(sp)
    80005d90:	ae9fc0ef          	jal	ra,80002878 <kerneltrap>
    80005d94:	6082                	ld	ra,0(sp)
    80005d96:	6122                	ld	sp,8(sp)
    80005d98:	61c2                	ld	gp,16(sp)
    80005d9a:	7282                	ld	t0,32(sp)
    80005d9c:	7322                	ld	t1,40(sp)
    80005d9e:	73c2                	ld	t2,48(sp)
    80005da0:	7462                	ld	s0,56(sp)
    80005da2:	6486                	ld	s1,64(sp)
    80005da4:	6526                	ld	a0,72(sp)
    80005da6:	65c6                	ld	a1,80(sp)
    80005da8:	6666                	ld	a2,88(sp)
    80005daa:	7686                	ld	a3,96(sp)
    80005dac:	7726                	ld	a4,104(sp)
    80005dae:	77c6                	ld	a5,112(sp)
    80005db0:	7866                	ld	a6,120(sp)
    80005db2:	688a                	ld	a7,128(sp)
    80005db4:	692a                	ld	s2,136(sp)
    80005db6:	69ca                	ld	s3,144(sp)
    80005db8:	6a6a                	ld	s4,152(sp)
    80005dba:	7a8a                	ld	s5,160(sp)
    80005dbc:	7b2a                	ld	s6,168(sp)
    80005dbe:	7bca                	ld	s7,176(sp)
    80005dc0:	7c6a                	ld	s8,184(sp)
    80005dc2:	6c8e                	ld	s9,192(sp)
    80005dc4:	6d2e                	ld	s10,200(sp)
    80005dc6:	6dce                	ld	s11,208(sp)
    80005dc8:	6e6e                	ld	t3,216(sp)
    80005dca:	7e8e                	ld	t4,224(sp)
    80005dcc:	7f2e                	ld	t5,232(sp)
    80005dce:	7fce                	ld	t6,240(sp)
    80005dd0:	6111                	addi	sp,sp,256
    80005dd2:	10200073          	sret
    80005dd6:	00000013          	nop
    80005dda:	00000013          	nop
    80005dde:	0001                	nop

0000000080005de0 <timervec>:
    80005de0:	34051573          	csrrw	a0,mscratch,a0
    80005de4:	e10c                	sd	a1,0(a0)
    80005de6:	e510                	sd	a2,8(a0)
    80005de8:	e914                	sd	a3,16(a0)
    80005dea:	6d0c                	ld	a1,24(a0)
    80005dec:	7110                	ld	a2,32(a0)
    80005dee:	6194                	ld	a3,0(a1)
    80005df0:	96b2                	add	a3,a3,a2
    80005df2:	e194                	sd	a3,0(a1)
    80005df4:	4589                	li	a1,2
    80005df6:	14459073          	csrw	sip,a1
    80005dfa:	6914                	ld	a3,16(a0)
    80005dfc:	6510                	ld	a2,8(a0)
    80005dfe:	610c                	ld	a1,0(a0)
    80005e00:	34051573          	csrrw	a0,mscratch,a0
    80005e04:	30200073          	mret
	...

0000000080005e0a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e0a:	1141                	addi	sp,sp,-16
    80005e0c:	e422                	sd	s0,8(sp)
    80005e0e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e10:	0c0007b7          	lui	a5,0xc000
    80005e14:	4705                	li	a4,1
    80005e16:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e18:	c3d8                	sw	a4,4(a5)
}
    80005e1a:	6422                	ld	s0,8(sp)
    80005e1c:	0141                	addi	sp,sp,16
    80005e1e:	8082                	ret

0000000080005e20 <plicinithart>:

void
plicinithart(void)
{
    80005e20:	1141                	addi	sp,sp,-16
    80005e22:	e406                	sd	ra,8(sp)
    80005e24:	e022                	sd	s0,0(sp)
    80005e26:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e28:	ffffc097          	auipc	ra,0xffffc
    80005e2c:	b42080e7          	jalr	-1214(ra) # 8000196a <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e30:	0085171b          	slliw	a4,a0,0x8
    80005e34:	0c0027b7          	lui	a5,0xc002
    80005e38:	97ba                	add	a5,a5,a4
    80005e3a:	40200713          	li	a4,1026
    80005e3e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e42:	00d5151b          	slliw	a0,a0,0xd
    80005e46:	0c2017b7          	lui	a5,0xc201
    80005e4a:	953e                	add	a0,a0,a5
    80005e4c:	00052023          	sw	zero,0(a0)
}
    80005e50:	60a2                	ld	ra,8(sp)
    80005e52:	6402                	ld	s0,0(sp)
    80005e54:	0141                	addi	sp,sp,16
    80005e56:	8082                	ret

0000000080005e58 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e58:	1141                	addi	sp,sp,-16
    80005e5a:	e406                	sd	ra,8(sp)
    80005e5c:	e022                	sd	s0,0(sp)
    80005e5e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e60:	ffffc097          	auipc	ra,0xffffc
    80005e64:	b0a080e7          	jalr	-1270(ra) # 8000196a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005e68:	00d5179b          	slliw	a5,a0,0xd
    80005e6c:	0c201537          	lui	a0,0xc201
    80005e70:	953e                	add	a0,a0,a5
  return irq;
}
    80005e72:	4148                	lw	a0,4(a0)
    80005e74:	60a2                	ld	ra,8(sp)
    80005e76:	6402                	ld	s0,0(sp)
    80005e78:	0141                	addi	sp,sp,16
    80005e7a:	8082                	ret

0000000080005e7c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005e7c:	1101                	addi	sp,sp,-32
    80005e7e:	ec06                	sd	ra,24(sp)
    80005e80:	e822                	sd	s0,16(sp)
    80005e82:	e426                	sd	s1,8(sp)
    80005e84:	1000                	addi	s0,sp,32
    80005e86:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005e88:	ffffc097          	auipc	ra,0xffffc
    80005e8c:	ae2080e7          	jalr	-1310(ra) # 8000196a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e90:	00d5151b          	slliw	a0,a0,0xd
    80005e94:	0c2017b7          	lui	a5,0xc201
    80005e98:	97aa                	add	a5,a5,a0
    80005e9a:	c3c4                	sw	s1,4(a5)
}
    80005e9c:	60e2                	ld	ra,24(sp)
    80005e9e:	6442                	ld	s0,16(sp)
    80005ea0:	64a2                	ld	s1,8(sp)
    80005ea2:	6105                	addi	sp,sp,32
    80005ea4:	8082                	ret

0000000080005ea6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005ea6:	1141                	addi	sp,sp,-16
    80005ea8:	e406                	sd	ra,8(sp)
    80005eaa:	e022                	sd	s0,0(sp)
    80005eac:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005eae:	479d                	li	a5,7
    80005eb0:	06a7c963          	blt	a5,a0,80005f22 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005eb4:	0001d797          	auipc	a5,0x1d
    80005eb8:	14c78793          	addi	a5,a5,332 # 80023000 <disk>
    80005ebc:	00a78733          	add	a4,a5,a0
    80005ec0:	6789                	lui	a5,0x2
    80005ec2:	97ba                	add	a5,a5,a4
    80005ec4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005ec8:	e7ad                	bnez	a5,80005f32 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005eca:	00451793          	slli	a5,a0,0x4
    80005ece:	0001f717          	auipc	a4,0x1f
    80005ed2:	13270713          	addi	a4,a4,306 # 80025000 <disk+0x2000>
    80005ed6:	6314                	ld	a3,0(a4)
    80005ed8:	96be                	add	a3,a3,a5
    80005eda:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005ede:	6314                	ld	a3,0(a4)
    80005ee0:	96be                	add	a3,a3,a5
    80005ee2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005ee6:	6314                	ld	a3,0(a4)
    80005ee8:	96be                	add	a3,a3,a5
    80005eea:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005eee:	6318                	ld	a4,0(a4)
    80005ef0:	97ba                	add	a5,a5,a4
    80005ef2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005ef6:	0001d797          	auipc	a5,0x1d
    80005efa:	10a78793          	addi	a5,a5,266 # 80023000 <disk>
    80005efe:	97aa                	add	a5,a5,a0
    80005f00:	6509                	lui	a0,0x2
    80005f02:	953e                	add	a0,a0,a5
    80005f04:	4785                	li	a5,1
    80005f06:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005f0a:	0001f517          	auipc	a0,0x1f
    80005f0e:	10e50513          	addi	a0,a0,270 # 80025018 <disk+0x2018>
    80005f12:	ffffc097          	auipc	ra,0xffffc
    80005f16:	2d0080e7          	jalr	720(ra) # 800021e2 <wakeup>
}
    80005f1a:	60a2                	ld	ra,8(sp)
    80005f1c:	6402                	ld	s0,0(sp)
    80005f1e:	0141                	addi	sp,sp,16
    80005f20:	8082                	ret
    panic("free_desc 1");
    80005f22:	00003517          	auipc	a0,0x3
    80005f26:	88650513          	addi	a0,a0,-1914 # 800087a8 <syscalls+0x348>
    80005f2a:	ffffa097          	auipc	ra,0xffffa
    80005f2e:	60e080e7          	jalr	1550(ra) # 80000538 <panic>
    panic("free_desc 2");
    80005f32:	00003517          	auipc	a0,0x3
    80005f36:	88650513          	addi	a0,a0,-1914 # 800087b8 <syscalls+0x358>
    80005f3a:	ffffa097          	auipc	ra,0xffffa
    80005f3e:	5fe080e7          	jalr	1534(ra) # 80000538 <panic>

0000000080005f42 <virtio_disk_init>:
{
    80005f42:	1101                	addi	sp,sp,-32
    80005f44:	ec06                	sd	ra,24(sp)
    80005f46:	e822                	sd	s0,16(sp)
    80005f48:	e426                	sd	s1,8(sp)
    80005f4a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f4c:	00003597          	auipc	a1,0x3
    80005f50:	87c58593          	addi	a1,a1,-1924 # 800087c8 <syscalls+0x368>
    80005f54:	0001f517          	auipc	a0,0x1f
    80005f58:	1d450513          	addi	a0,a0,468 # 80025128 <disk+0x2128>
    80005f5c:	ffffb097          	auipc	ra,0xffffb
    80005f60:	be4080e7          	jalr	-1052(ra) # 80000b40 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f64:	100017b7          	lui	a5,0x10001
    80005f68:	4398                	lw	a4,0(a5)
    80005f6a:	2701                	sext.w	a4,a4
    80005f6c:	747277b7          	lui	a5,0x74727
    80005f70:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f74:	0ef71163          	bne	a4,a5,80006056 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f78:	100017b7          	lui	a5,0x10001
    80005f7c:	43dc                	lw	a5,4(a5)
    80005f7e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f80:	4705                	li	a4,1
    80005f82:	0ce79a63          	bne	a5,a4,80006056 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f86:	100017b7          	lui	a5,0x10001
    80005f8a:	479c                	lw	a5,8(a5)
    80005f8c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f8e:	4709                	li	a4,2
    80005f90:	0ce79363          	bne	a5,a4,80006056 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005f94:	100017b7          	lui	a5,0x10001
    80005f98:	47d8                	lw	a4,12(a5)
    80005f9a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f9c:	554d47b7          	lui	a5,0x554d4
    80005fa0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005fa4:	0af71963          	bne	a4,a5,80006056 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fa8:	100017b7          	lui	a5,0x10001
    80005fac:	4705                	li	a4,1
    80005fae:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fb0:	470d                	li	a4,3
    80005fb2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005fb4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005fb6:	c7ffe737          	lui	a4,0xc7ffe
    80005fba:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005fbe:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005fc0:	2701                	sext.w	a4,a4
    80005fc2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fc4:	472d                	li	a4,11
    80005fc6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fc8:	473d                	li	a4,15
    80005fca:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005fcc:	6705                	lui	a4,0x1
    80005fce:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005fd0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005fd4:	5bdc                	lw	a5,52(a5)
    80005fd6:	2781                	sext.w	a5,a5
  if(max == 0)
    80005fd8:	c7d9                	beqz	a5,80006066 <virtio_disk_init+0x124>
  if(max < NUM)
    80005fda:	471d                	li	a4,7
    80005fdc:	08f77d63          	bgeu	a4,a5,80006076 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005fe0:	100014b7          	lui	s1,0x10001
    80005fe4:	47a1                	li	a5,8
    80005fe6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005fe8:	6609                	lui	a2,0x2
    80005fea:	4581                	li	a1,0
    80005fec:	0001d517          	auipc	a0,0x1d
    80005ff0:	01450513          	addi	a0,a0,20 # 80023000 <disk>
    80005ff4:	ffffb097          	auipc	ra,0xffffb
    80005ff8:	cd8080e7          	jalr	-808(ra) # 80000ccc <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005ffc:	0001d717          	auipc	a4,0x1d
    80006000:	00470713          	addi	a4,a4,4 # 80023000 <disk>
    80006004:	00c75793          	srli	a5,a4,0xc
    80006008:	2781                	sext.w	a5,a5
    8000600a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000600c:	0001f797          	auipc	a5,0x1f
    80006010:	ff478793          	addi	a5,a5,-12 # 80025000 <disk+0x2000>
    80006014:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006016:	0001d717          	auipc	a4,0x1d
    8000601a:	06a70713          	addi	a4,a4,106 # 80023080 <disk+0x80>
    8000601e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006020:	0001e717          	auipc	a4,0x1e
    80006024:	fe070713          	addi	a4,a4,-32 # 80024000 <disk+0x1000>
    80006028:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000602a:	4705                	li	a4,1
    8000602c:	00e78c23          	sb	a4,24(a5)
    80006030:	00e78ca3          	sb	a4,25(a5)
    80006034:	00e78d23          	sb	a4,26(a5)
    80006038:	00e78da3          	sb	a4,27(a5)
    8000603c:	00e78e23          	sb	a4,28(a5)
    80006040:	00e78ea3          	sb	a4,29(a5)
    80006044:	00e78f23          	sb	a4,30(a5)
    80006048:	00e78fa3          	sb	a4,31(a5)
}
    8000604c:	60e2                	ld	ra,24(sp)
    8000604e:	6442                	ld	s0,16(sp)
    80006050:	64a2                	ld	s1,8(sp)
    80006052:	6105                	addi	sp,sp,32
    80006054:	8082                	ret
    panic("could not find virtio disk");
    80006056:	00002517          	auipc	a0,0x2
    8000605a:	78250513          	addi	a0,a0,1922 # 800087d8 <syscalls+0x378>
    8000605e:	ffffa097          	auipc	ra,0xffffa
    80006062:	4da080e7          	jalr	1242(ra) # 80000538 <panic>
    panic("virtio disk has no queue 0");
    80006066:	00002517          	auipc	a0,0x2
    8000606a:	79250513          	addi	a0,a0,1938 # 800087f8 <syscalls+0x398>
    8000606e:	ffffa097          	auipc	ra,0xffffa
    80006072:	4ca080e7          	jalr	1226(ra) # 80000538 <panic>
    panic("virtio disk max queue too short");
    80006076:	00002517          	auipc	a0,0x2
    8000607a:	7a250513          	addi	a0,a0,1954 # 80008818 <syscalls+0x3b8>
    8000607e:	ffffa097          	auipc	ra,0xffffa
    80006082:	4ba080e7          	jalr	1210(ra) # 80000538 <panic>

0000000080006086 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006086:	7119                	addi	sp,sp,-128
    80006088:	fc86                	sd	ra,120(sp)
    8000608a:	f8a2                	sd	s0,112(sp)
    8000608c:	f4a6                	sd	s1,104(sp)
    8000608e:	f0ca                	sd	s2,96(sp)
    80006090:	ecce                	sd	s3,88(sp)
    80006092:	e8d2                	sd	s4,80(sp)
    80006094:	e4d6                	sd	s5,72(sp)
    80006096:	e0da                	sd	s6,64(sp)
    80006098:	fc5e                	sd	s7,56(sp)
    8000609a:	f862                	sd	s8,48(sp)
    8000609c:	f466                	sd	s9,40(sp)
    8000609e:	f06a                	sd	s10,32(sp)
    800060a0:	ec6e                	sd	s11,24(sp)
    800060a2:	0100                	addi	s0,sp,128
    800060a4:	8aaa                	mv	s5,a0
    800060a6:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800060a8:	00c52c83          	lw	s9,12(a0)
    800060ac:	001c9c9b          	slliw	s9,s9,0x1
    800060b0:	1c82                	slli	s9,s9,0x20
    800060b2:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800060b6:	0001f517          	auipc	a0,0x1f
    800060ba:	07250513          	addi	a0,a0,114 # 80025128 <disk+0x2128>
    800060be:	ffffb097          	auipc	ra,0xffffb
    800060c2:	b12080e7          	jalr	-1262(ra) # 80000bd0 <acquire>
  for(int i = 0; i < 3; i++){
    800060c6:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800060c8:	44a1                	li	s1,8
      disk.free[i] = 0;
    800060ca:	0001dc17          	auipc	s8,0x1d
    800060ce:	f36c0c13          	addi	s8,s8,-202 # 80023000 <disk>
    800060d2:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    800060d4:	4b0d                	li	s6,3
    800060d6:	a0ad                	j	80006140 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    800060d8:	00fc0733          	add	a4,s8,a5
    800060dc:	975e                	add	a4,a4,s7
    800060de:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800060e2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800060e4:	0207c563          	bltz	a5,8000610e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800060e8:	2905                	addiw	s2,s2,1
    800060ea:	0611                	addi	a2,a2,4
    800060ec:	19690d63          	beq	s2,s6,80006286 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    800060f0:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800060f2:	0001f717          	auipc	a4,0x1f
    800060f6:	f2670713          	addi	a4,a4,-218 # 80025018 <disk+0x2018>
    800060fa:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800060fc:	00074683          	lbu	a3,0(a4)
    80006100:	fee1                	bnez	a3,800060d8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006102:	2785                	addiw	a5,a5,1
    80006104:	0705                	addi	a4,a4,1
    80006106:	fe979be3          	bne	a5,s1,800060fc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000610a:	57fd                	li	a5,-1
    8000610c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000610e:	01205d63          	blez	s2,80006128 <virtio_disk_rw+0xa2>
    80006112:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006114:	000a2503          	lw	a0,0(s4)
    80006118:	00000097          	auipc	ra,0x0
    8000611c:	d8e080e7          	jalr	-626(ra) # 80005ea6 <free_desc>
      for(int j = 0; j < i; j++)
    80006120:	2d85                	addiw	s11,s11,1
    80006122:	0a11                	addi	s4,s4,4
    80006124:	ffb918e3          	bne	s2,s11,80006114 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006128:	0001f597          	auipc	a1,0x1f
    8000612c:	00058593          	mv	a1,a1
    80006130:	0001f517          	auipc	a0,0x1f
    80006134:	ee850513          	addi	a0,a0,-280 # 80025018 <disk+0x2018>
    80006138:	ffffc097          	auipc	ra,0xffffc
    8000613c:	f1e080e7          	jalr	-226(ra) # 80002056 <sleep>
  for(int i = 0; i < 3; i++){
    80006140:	f8040a13          	addi	s4,s0,-128
{
    80006144:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006146:	894e                	mv	s2,s3
    80006148:	b765                	j	800060f0 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000614a:	0001f697          	auipc	a3,0x1f
    8000614e:	eb66b683          	ld	a3,-330(a3) # 80025000 <disk+0x2000>
    80006152:	96ba                	add	a3,a3,a4
    80006154:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006158:	0001d817          	auipc	a6,0x1d
    8000615c:	ea880813          	addi	a6,a6,-344 # 80023000 <disk>
    80006160:	0001f697          	auipc	a3,0x1f
    80006164:	ea068693          	addi	a3,a3,-352 # 80025000 <disk+0x2000>
    80006168:	6290                	ld	a2,0(a3)
    8000616a:	963a                	add	a2,a2,a4
    8000616c:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80006170:	0015e593          	ori	a1,a1,1
    80006174:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006178:	f8842603          	lw	a2,-120(s0)
    8000617c:	628c                	ld	a1,0(a3)
    8000617e:	972e                	add	a4,a4,a1
    80006180:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006184:	20050593          	addi	a1,a0,512
    80006188:	0592                	slli	a1,a1,0x4
    8000618a:	95c2                	add	a1,a1,a6
    8000618c:	577d                	li	a4,-1
    8000618e:	02e58823          	sb	a4,48(a1) # 80025158 <disk+0x2158>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006192:	00461713          	slli	a4,a2,0x4
    80006196:	6290                	ld	a2,0(a3)
    80006198:	963a                	add	a2,a2,a4
    8000619a:	03078793          	addi	a5,a5,48
    8000619e:	97c2                	add	a5,a5,a6
    800061a0:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    800061a2:	629c                	ld	a5,0(a3)
    800061a4:	97ba                	add	a5,a5,a4
    800061a6:	4605                	li	a2,1
    800061a8:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800061aa:	629c                	ld	a5,0(a3)
    800061ac:	97ba                	add	a5,a5,a4
    800061ae:	4809                	li	a6,2
    800061b0:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800061b4:	629c                	ld	a5,0(a3)
    800061b6:	973e                	add	a4,a4,a5
    800061b8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800061bc:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    800061c0:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800061c4:	6698                	ld	a4,8(a3)
    800061c6:	00275783          	lhu	a5,2(a4)
    800061ca:	8b9d                	andi	a5,a5,7
    800061cc:	0786                	slli	a5,a5,0x1
    800061ce:	97ba                	add	a5,a5,a4
    800061d0:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    800061d4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800061d8:	6698                	ld	a4,8(a3)
    800061da:	00275783          	lhu	a5,2(a4)
    800061de:	2785                	addiw	a5,a5,1
    800061e0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800061e4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800061e8:	100017b7          	lui	a5,0x10001
    800061ec:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800061f0:	004aa783          	lw	a5,4(s5)
    800061f4:	02c79163          	bne	a5,a2,80006216 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    800061f8:	0001f917          	auipc	s2,0x1f
    800061fc:	f3090913          	addi	s2,s2,-208 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006200:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006202:	85ca                	mv	a1,s2
    80006204:	8556                	mv	a0,s5
    80006206:	ffffc097          	auipc	ra,0xffffc
    8000620a:	e50080e7          	jalr	-432(ra) # 80002056 <sleep>
  while(b->disk == 1) {
    8000620e:	004aa783          	lw	a5,4(s5)
    80006212:	fe9788e3          	beq	a5,s1,80006202 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006216:	f8042903          	lw	s2,-128(s0)
    8000621a:	20090793          	addi	a5,s2,512
    8000621e:	00479713          	slli	a4,a5,0x4
    80006222:	0001d797          	auipc	a5,0x1d
    80006226:	dde78793          	addi	a5,a5,-546 # 80023000 <disk>
    8000622a:	97ba                	add	a5,a5,a4
    8000622c:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006230:	0001f997          	auipc	s3,0x1f
    80006234:	dd098993          	addi	s3,s3,-560 # 80025000 <disk+0x2000>
    80006238:	00491713          	slli	a4,s2,0x4
    8000623c:	0009b783          	ld	a5,0(s3)
    80006240:	97ba                	add	a5,a5,a4
    80006242:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006246:	854a                	mv	a0,s2
    80006248:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000624c:	00000097          	auipc	ra,0x0
    80006250:	c5a080e7          	jalr	-934(ra) # 80005ea6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006254:	8885                	andi	s1,s1,1
    80006256:	f0ed                	bnez	s1,80006238 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006258:	0001f517          	auipc	a0,0x1f
    8000625c:	ed050513          	addi	a0,a0,-304 # 80025128 <disk+0x2128>
    80006260:	ffffb097          	auipc	ra,0xffffb
    80006264:	a24080e7          	jalr	-1500(ra) # 80000c84 <release>
}
    80006268:	70e6                	ld	ra,120(sp)
    8000626a:	7446                	ld	s0,112(sp)
    8000626c:	74a6                	ld	s1,104(sp)
    8000626e:	7906                	ld	s2,96(sp)
    80006270:	69e6                	ld	s3,88(sp)
    80006272:	6a46                	ld	s4,80(sp)
    80006274:	6aa6                	ld	s5,72(sp)
    80006276:	6b06                	ld	s6,64(sp)
    80006278:	7be2                	ld	s7,56(sp)
    8000627a:	7c42                	ld	s8,48(sp)
    8000627c:	7ca2                	ld	s9,40(sp)
    8000627e:	7d02                	ld	s10,32(sp)
    80006280:	6de2                	ld	s11,24(sp)
    80006282:	6109                	addi	sp,sp,128
    80006284:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006286:	f8042503          	lw	a0,-128(s0)
    8000628a:	20050793          	addi	a5,a0,512
    8000628e:	0792                	slli	a5,a5,0x4
  if(write)
    80006290:	0001d817          	auipc	a6,0x1d
    80006294:	d7080813          	addi	a6,a6,-656 # 80023000 <disk>
    80006298:	00f80733          	add	a4,a6,a5
    8000629c:	01a036b3          	snez	a3,s10
    800062a0:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    800062a4:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800062a8:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    800062ac:	7679                	lui	a2,0xffffe
    800062ae:	963e                	add	a2,a2,a5
    800062b0:	0001f697          	auipc	a3,0x1f
    800062b4:	d5068693          	addi	a3,a3,-688 # 80025000 <disk+0x2000>
    800062b8:	6298                	ld	a4,0(a3)
    800062ba:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800062bc:	0a878593          	addi	a1,a5,168
    800062c0:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    800062c2:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800062c4:	6298                	ld	a4,0(a3)
    800062c6:	9732                	add	a4,a4,a2
    800062c8:	45c1                	li	a1,16
    800062ca:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800062cc:	6298                	ld	a4,0(a3)
    800062ce:	9732                	add	a4,a4,a2
    800062d0:	4585                	li	a1,1
    800062d2:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800062d6:	f8442703          	lw	a4,-124(s0)
    800062da:	628c                	ld	a1,0(a3)
    800062dc:	962e                	add	a2,a2,a1
    800062de:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    800062e2:	0712                	slli	a4,a4,0x4
    800062e4:	6290                	ld	a2,0(a3)
    800062e6:	963a                	add	a2,a2,a4
    800062e8:	058a8593          	addi	a1,s5,88
    800062ec:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800062ee:	6294                	ld	a3,0(a3)
    800062f0:	96ba                	add	a3,a3,a4
    800062f2:	40000613          	li	a2,1024
    800062f6:	c690                	sw	a2,8(a3)
  if(write)
    800062f8:	e40d19e3          	bnez	s10,8000614a <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800062fc:	0001f697          	auipc	a3,0x1f
    80006300:	d046b683          	ld	a3,-764(a3) # 80025000 <disk+0x2000>
    80006304:	96ba                	add	a3,a3,a4
    80006306:	4609                	li	a2,2
    80006308:	00c69623          	sh	a2,12(a3)
    8000630c:	b5b1                	j	80006158 <virtio_disk_rw+0xd2>

000000008000630e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000630e:	1101                	addi	sp,sp,-32
    80006310:	ec06                	sd	ra,24(sp)
    80006312:	e822                	sd	s0,16(sp)
    80006314:	e426                	sd	s1,8(sp)
    80006316:	e04a                	sd	s2,0(sp)
    80006318:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000631a:	0001f517          	auipc	a0,0x1f
    8000631e:	e0e50513          	addi	a0,a0,-498 # 80025128 <disk+0x2128>
    80006322:	ffffb097          	auipc	ra,0xffffb
    80006326:	8ae080e7          	jalr	-1874(ra) # 80000bd0 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000632a:	10001737          	lui	a4,0x10001
    8000632e:	533c                	lw	a5,96(a4)
    80006330:	8b8d                	andi	a5,a5,3
    80006332:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006334:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006338:	0001f797          	auipc	a5,0x1f
    8000633c:	cc878793          	addi	a5,a5,-824 # 80025000 <disk+0x2000>
    80006340:	6b94                	ld	a3,16(a5)
    80006342:	0207d703          	lhu	a4,32(a5)
    80006346:	0026d783          	lhu	a5,2(a3)
    8000634a:	06f70163          	beq	a4,a5,800063ac <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000634e:	0001d917          	auipc	s2,0x1d
    80006352:	cb290913          	addi	s2,s2,-846 # 80023000 <disk>
    80006356:	0001f497          	auipc	s1,0x1f
    8000635a:	caa48493          	addi	s1,s1,-854 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000635e:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006362:	6898                	ld	a4,16(s1)
    80006364:	0204d783          	lhu	a5,32(s1)
    80006368:	8b9d                	andi	a5,a5,7
    8000636a:	078e                	slli	a5,a5,0x3
    8000636c:	97ba                	add	a5,a5,a4
    8000636e:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006370:	20078713          	addi	a4,a5,512
    80006374:	0712                	slli	a4,a4,0x4
    80006376:	974a                	add	a4,a4,s2
    80006378:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000637c:	e731                	bnez	a4,800063c8 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000637e:	20078793          	addi	a5,a5,512
    80006382:	0792                	slli	a5,a5,0x4
    80006384:	97ca                	add	a5,a5,s2
    80006386:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006388:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000638c:	ffffc097          	auipc	ra,0xffffc
    80006390:	e56080e7          	jalr	-426(ra) # 800021e2 <wakeup>

    disk.used_idx += 1;
    80006394:	0204d783          	lhu	a5,32(s1)
    80006398:	2785                	addiw	a5,a5,1
    8000639a:	17c2                	slli	a5,a5,0x30
    8000639c:	93c1                	srli	a5,a5,0x30
    8000639e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800063a2:	6898                	ld	a4,16(s1)
    800063a4:	00275703          	lhu	a4,2(a4)
    800063a8:	faf71be3          	bne	a4,a5,8000635e <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800063ac:	0001f517          	auipc	a0,0x1f
    800063b0:	d7c50513          	addi	a0,a0,-644 # 80025128 <disk+0x2128>
    800063b4:	ffffb097          	auipc	ra,0xffffb
    800063b8:	8d0080e7          	jalr	-1840(ra) # 80000c84 <release>
}
    800063bc:	60e2                	ld	ra,24(sp)
    800063be:	6442                	ld	s0,16(sp)
    800063c0:	64a2                	ld	s1,8(sp)
    800063c2:	6902                	ld	s2,0(sp)
    800063c4:	6105                	addi	sp,sp,32
    800063c6:	8082                	ret
      panic("virtio_disk_intr status");
    800063c8:	00002517          	auipc	a0,0x2
    800063cc:	47050513          	addi	a0,a0,1136 # 80008838 <syscalls+0x3d8>
    800063d0:	ffffa097          	auipc	ra,0xffffa
    800063d4:	168080e7          	jalr	360(ra) # 80000538 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
