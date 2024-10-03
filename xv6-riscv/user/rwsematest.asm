
user/_rwsematest:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <starttest>:
#include "kernel/types.h"
#include "user/user.h"

void
starttest(int count, void (*test)(int))
{
   0:	7179                	addi	sp,sp,-48
   2:	f406                	sd	ra,40(sp)
   4:	f022                	sd	s0,32(sp)
   6:	ec26                	sd	s1,24(sp)
   8:	e84a                	sd	s2,16(sp)
   a:	e44e                	sd	s3,8(sp)
   c:	1800                	addi	s0,sp,48
   e:	89ae                	mv	s3,a1
  int i,pid = 0;

  for(i = 0; i < count; i++) {
  10:	04a05063          	blez	a0,50 <starttest+0x50>
  14:	892a                	mv	s2,a0
  16:	4481                	li	s1,0
  18:	a011                	j	1c <starttest+0x1c>
  1a:	84be                	mv	s1,a5
    pid = fork();
  1c:	00000097          	auipc	ra,0x0
  20:	4c6080e7          	jalr	1222(ra) # 4e2 <fork>
    if(!pid)
  24:	c51d                	beqz	a0,52 <starttest+0x52>
  for(i = 0; i < count; i++) {
  26:	0014879b          	addiw	a5,s1,1
  2a:	fef918e3          	bne	s2,a5,1a <starttest+0x1a>
      break;
  }

  if(pid) {
    for(i = 0; i < count; i++) 
  2e:	4901                	li	s2,0
      wait(0);
  30:	4501                	li	a0,0
  32:	00000097          	auipc	ra,0x0
  36:	4c0080e7          	jalr	1216(ra) # 4f2 <wait>
    for(i = 0; i < count; i++) 
  3a:	87ca                	mv	a5,s2
  3c:	2905                	addiw	s2,s2,1
  3e:	fef499e3          	bne	s1,a5,30 <starttest+0x30>
  }
  else {
    test(i);
    exit(0);
  }
}
  42:	70a2                	ld	ra,40(sp)
  44:	7402                	ld	s0,32(sp)
  46:	64e2                	ld	s1,24(sp)
  48:	6942                	ld	s2,16(sp)
  4a:	69a2                	ld	s3,8(sp)
  4c:	6145                	addi	sp,sp,48
  4e:	8082                	ret
  for(i = 0; i < count; i++) {
  50:	4481                	li	s1,0
    test(i);
  52:	8526                	mv	a0,s1
  54:	9982                	jalr	s3
    exit(0);
  56:	4501                	li	a0,0
  58:	00000097          	auipc	ra,0x0
  5c:	492080e7          	jalr	1170(ra) # 4ea <exit>

0000000000000060 <readlocktest>:

void 
readlocktest(int time)
{
  60:	1101                	addi	sp,sp,-32
  62:	ec06                	sd	ra,24(sp)
  64:	e822                	sd	s0,16(sp)
  66:	e426                	sd	s1,8(sp)
  68:	1000                	addi	s0,sp,32
  6a:	84aa                	mv	s1,a0
  int r;
  r = rwsematest(1);
  6c:	4505                	li	a0,1
  6e:	00000097          	auipc	ra,0x0
  72:	524080e7          	jalr	1316(ra) # 592 <rwsematest>
  76:	85aa                	mv	a1,a0
  printf ("RD %d\n", r);
  78:	00001517          	auipc	a0,0x1
  7c:	9a050513          	addi	a0,a0,-1632 # a18 <malloc+0xe8>
  80:	00000097          	auipc	ra,0x0
  84:	7f2080e7          	jalr	2034(ra) # 872 <printf>
  sleep(time);
  88:	8526                	mv	a0,s1
  8a:	00000097          	auipc	ra,0x0
  8e:	4f0080e7          	jalr	1264(ra) # 57a <sleep>
  r = rwsematest(2);
  92:	4509                	li	a0,2
  94:	00000097          	auipc	ra,0x0
  98:	4fe080e7          	jalr	1278(ra) # 592 <rwsematest>
  9c:	85aa                	mv	a1,a0
  printf ("RU %d\n", r);
  9e:	00001517          	auipc	a0,0x1
  a2:	98250513          	addi	a0,a0,-1662 # a20 <malloc+0xf0>
  a6:	00000097          	auipc	ra,0x0
  aa:	7cc080e7          	jalr	1996(ra) # 872 <printf>
  sleep(time);
  ae:	8526                	mv	a0,s1
  b0:	00000097          	auipc	ra,0x0
  b4:	4ca080e7          	jalr	1226(ra) # 57a <sleep>
}
  b8:	60e2                	ld	ra,24(sp)
  ba:	6442                	ld	s0,16(sp)
  bc:	64a2                	ld	s1,8(sp)
  be:	6105                	addi	sp,sp,32
  c0:	8082                	ret

00000000000000c2 <test1>:
  printf ("%d UW\n", i);
}

void
test1(int i)
{
  c2:	1141                	addi	sp,sp,-16
  c4:	e406                	sd	ra,8(sp)
  c6:	e022                	sd	s0,0(sp)
  c8:	0800                	addi	s0,sp,16
//  readlocktest(0);
  readlocktest((i+1)*10);
  ca:	2505                	addiw	a0,a0,1
  cc:	0025179b          	slliw	a5,a0,0x2
  d0:	9d3d                	addw	a0,a0,a5
  d2:	0015151b          	slliw	a0,a0,0x1
  d6:	00000097          	auipc	ra,0x0
  da:	f8a080e7          	jalr	-118(ra) # 60 <readlocktest>
}
  de:	60a2                	ld	ra,8(sp)
  e0:	6402                	ld	s0,0(sp)
  e2:	0141                	addi	sp,sp,16
  e4:	8082                	ret

00000000000000e6 <writelocktest>:
{
  e6:	1101                	addi	sp,sp,-32
  e8:	ec06                	sd	ra,24(sp)
  ea:	e822                	sd	s0,16(sp)
  ec:	e426                	sd	s1,8(sp)
  ee:	e04a                	sd	s2,0(sp)
  f0:	1000                	addi	s0,sp,32
  f2:	84aa                	mv	s1,a0
  f4:	892e                	mv	s2,a1
  rwsematest(3);
  f6:	450d                	li	a0,3
  f8:	00000097          	auipc	ra,0x0
  fc:	49a080e7          	jalr	1178(ra) # 592 <rwsematest>
  printf ("%d DW\n", i);
 100:	85a6                	mv	a1,s1
 102:	00001517          	auipc	a0,0x1
 106:	92650513          	addi	a0,a0,-1754 # a28 <malloc+0xf8>
 10a:	00000097          	auipc	ra,0x0
 10e:	768080e7          	jalr	1896(ra) # 872 <printf>
  sleep(time);
 112:	854a                	mv	a0,s2
 114:	00000097          	auipc	ra,0x0
 118:	466080e7          	jalr	1126(ra) # 57a <sleep>
  rwsematest(4);
 11c:	4511                	li	a0,4
 11e:	00000097          	auipc	ra,0x0
 122:	474080e7          	jalr	1140(ra) # 592 <rwsematest>
  printf ("%d UW\n", i);
 126:	85a6                	mv	a1,s1
 128:	00001517          	auipc	a0,0x1
 12c:	90850513          	addi	a0,a0,-1784 # a30 <malloc+0x100>
 130:	00000097          	auipc	ra,0x0
 134:	742080e7          	jalr	1858(ra) # 872 <printf>
}
 138:	60e2                	ld	ra,24(sp)
 13a:	6442                	ld	s0,16(sp)
 13c:	64a2                	ld	s1,8(sp)
 13e:	6902                	ld	s2,0(sp)
 140:	6105                	addi	sp,sp,32
 142:	8082                	ret

0000000000000144 <test2>:

void
test2(int i)
{
 144:	1101                	addi	sp,sp,-32
 146:	ec06                	sd	ra,24(sp)
 148:	e822                	sd	s0,16(sp)
 14a:	e426                	sd	s1,8(sp)
 14c:	1000                	addi	s0,sp,32
 14e:	84aa                	mv	s1,a0
  sleep((5-i)*10);
 150:	4515                	li	a0,5
 152:	9d05                	subw	a0,a0,s1
 154:	0025179b          	slliw	a5,a0,0x2
 158:	9d3d                	addw	a0,a0,a5
 15a:	0015151b          	slliw	a0,a0,0x1
 15e:	00000097          	auipc	ra,0x0
 162:	41c080e7          	jalr	1052(ra) # 57a <sleep>
  writelocktest(i, (i+2)*10);
 166:	0024879b          	addiw	a5,s1,2
 16a:	0027959b          	slliw	a1,a5,0x2
 16e:	9dbd                	addw	a1,a1,a5
 170:	0015959b          	slliw	a1,a1,0x1
 174:	8526                	mv	a0,s1
 176:	00000097          	auipc	ra,0x0
 17a:	f70080e7          	jalr	-144(ra) # e6 <writelocktest>
}
 17e:	60e2                	ld	ra,24(sp)
 180:	6442                	ld	s0,16(sp)
 182:	64a2                	ld	s1,8(sp)
 184:	6105                	addi	sp,sp,32
 186:	8082                	ret

0000000000000188 <test3>:

void 
test3(int i)
{
 188:	1101                	addi	sp,sp,-32
 18a:	ec06                	sd	ra,24(sp)
 18c:	e822                	sd	s0,16(sp)
 18e:	e426                	sd	s1,8(sp)
 190:	1000                	addi	s0,sp,32
 192:	84aa                	mv	s1,a0
  switch (i) {
 194:	4789                	li	a5,2
 196:	02a7c263          	blt	a5,a0,1ba <test3+0x32>
 19a:	04a04563          	bgtz	a0,1e4 <test3+0x5c>
 19e:	ed15                	bnez	a0,1da <test3+0x52>
    case 0: 
      sleep(10);
 1a0:	4529                	li	a0,10
 1a2:	00000097          	auipc	ra,0x0
 1a6:	3d8080e7          	jalr	984(ra) # 57a <sleep>
      writelocktest(i, 50);
 1aa:	03200593          	li	a1,50
 1ae:	4501                	li	a0,0
 1b0:	00000097          	auipc	ra,0x0
 1b4:	f36080e7          	jalr	-202(ra) # e6 <writelocktest>
      break;
 1b8:	a00d                	j	1da <test3+0x52>
  switch (i) {
 1ba:	ffd5079b          	addiw	a5,a0,-3
 1be:	4705                	li	a4,1
 1c0:	00f76d63          	bltu	a4,a5,1da <test3+0x52>
    case 1:
    case 2:
      sleep(25 + i*10);
    case 3:
    case 4:
      readlocktest(50 + i*10);
 1c4:	0024951b          	slliw	a0,s1,0x2
 1c8:	9d25                	addw	a0,a0,s1
 1ca:	0015151b          	slliw	a0,a0,0x1
 1ce:	0325051b          	addiw	a0,a0,50
 1d2:	00000097          	auipc	ra,0x0
 1d6:	e8e080e7          	jalr	-370(ra) # 60 <readlocktest>
  }
}
 1da:	60e2                	ld	ra,24(sp)
 1dc:	6442                	ld	s0,16(sp)
 1de:	64a2                	ld	s1,8(sp)
 1e0:	6105                	addi	sp,sp,32
 1e2:	8082                	ret
      sleep(25 + i*10);
 1e4:	0025151b          	slliw	a0,a0,0x2
 1e8:	9d25                	addw	a0,a0,s1
 1ea:	0015151b          	slliw	a0,a0,0x1
 1ee:	2565                	addiw	a0,a0,25
 1f0:	00000097          	auipc	ra,0x0
 1f4:	38a080e7          	jalr	906(ra) # 57a <sleep>
 1f8:	b7f1                	j	1c4 <test3+0x3c>

00000000000001fa <main>:
		
int 
main()
{
 1fa:	1141                	addi	sp,sp,-16
 1fc:	e406                	sd	ra,8(sp)
 1fe:	e022                	sd	s0,0(sp)
 200:	0800                	addi	s0,sp,16
  // initialize the semaphore
  rwsematest(0);
 202:	4501                	li	a0,0
 204:	00000097          	auipc	ra,0x0
 208:	38e080e7          	jalr	910(ra) # 592 <rwsematest>

  printf("\nread lock test\n");
 20c:	00001517          	auipc	a0,0x1
 210:	82c50513          	addi	a0,a0,-2004 # a38 <malloc+0x108>
 214:	00000097          	auipc	ra,0x0
 218:	65e080e7          	jalr	1630(ra) # 872 <printf>
  starttest(5, test1);
 21c:	00000597          	auipc	a1,0x0
 220:	ea658593          	addi	a1,a1,-346 # c2 <test1>
 224:	4515                	li	a0,5
 226:	00000097          	auipc	ra,0x0
 22a:	dda080e7          	jalr	-550(ra) # 0 <starttest>
  printf("\nwrite lock test\n");
 22e:	00001517          	auipc	a0,0x1
 232:	82250513          	addi	a0,a0,-2014 # a50 <malloc+0x120>
 236:	00000097          	auipc	ra,0x0
 23a:	63c080e7          	jalr	1596(ra) # 872 <printf>
  starttest(5, test2);
 23e:	00000597          	auipc	a1,0x0
 242:	f0658593          	addi	a1,a1,-250 # 144 <test2>
 246:	4515                	li	a0,5
 248:	00000097          	auipc	ra,0x0
 24c:	db8080e7          	jalr	-584(ra) # 0 <starttest>

  printf("\nread & write lock test\n");
 250:	00001517          	auipc	a0,0x1
 254:	81850513          	addi	a0,a0,-2024 # a68 <malloc+0x138>
 258:	00000097          	auipc	ra,0x0
 25c:	61a080e7          	jalr	1562(ra) # 872 <printf>
  starttest(5, test3);
 260:	00000597          	auipc	a1,0x0
 264:	f2858593          	addi	a1,a1,-216 # 188 <test3>
 268:	4515                	li	a0,5
 26a:	00000097          	auipc	ra,0x0
 26e:	d96080e7          	jalr	-618(ra) # 0 <starttest>

  exit(0);
 272:	4501                	li	a0,0
 274:	00000097          	auipc	ra,0x0
 278:	276080e7          	jalr	630(ra) # 4ea <exit>

000000000000027c <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 27c:	1141                	addi	sp,sp,-16
 27e:	e422                	sd	s0,8(sp)
 280:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 282:	87aa                	mv	a5,a0
 284:	0585                	addi	a1,a1,1
 286:	0785                	addi	a5,a5,1
 288:	fff5c703          	lbu	a4,-1(a1)
 28c:	fee78fa3          	sb	a4,-1(a5)
 290:	fb75                	bnez	a4,284 <strcpy+0x8>
    ;
  return os;
}
 292:	6422                	ld	s0,8(sp)
 294:	0141                	addi	sp,sp,16
 296:	8082                	ret

0000000000000298 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 298:	1141                	addi	sp,sp,-16
 29a:	e422                	sd	s0,8(sp)
 29c:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 29e:	00054783          	lbu	a5,0(a0)
 2a2:	cb91                	beqz	a5,2b6 <strcmp+0x1e>
 2a4:	0005c703          	lbu	a4,0(a1)
 2a8:	00f71763          	bne	a4,a5,2b6 <strcmp+0x1e>
    p++, q++;
 2ac:	0505                	addi	a0,a0,1
 2ae:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 2b0:	00054783          	lbu	a5,0(a0)
 2b4:	fbe5                	bnez	a5,2a4 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 2b6:	0005c503          	lbu	a0,0(a1)
}
 2ba:	40a7853b          	subw	a0,a5,a0
 2be:	6422                	ld	s0,8(sp)
 2c0:	0141                	addi	sp,sp,16
 2c2:	8082                	ret

00000000000002c4 <strlen>:

uint
strlen(const char *s)
{
 2c4:	1141                	addi	sp,sp,-16
 2c6:	e422                	sd	s0,8(sp)
 2c8:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 2ca:	00054783          	lbu	a5,0(a0)
 2ce:	cf91                	beqz	a5,2ea <strlen+0x26>
 2d0:	0505                	addi	a0,a0,1
 2d2:	87aa                	mv	a5,a0
 2d4:	4685                	li	a3,1
 2d6:	9e89                	subw	a3,a3,a0
 2d8:	00f6853b          	addw	a0,a3,a5
 2dc:	0785                	addi	a5,a5,1
 2de:	fff7c703          	lbu	a4,-1(a5)
 2e2:	fb7d                	bnez	a4,2d8 <strlen+0x14>
    ;
  return n;
}
 2e4:	6422                	ld	s0,8(sp)
 2e6:	0141                	addi	sp,sp,16
 2e8:	8082                	ret
  for(n = 0; s[n]; n++)
 2ea:	4501                	li	a0,0
 2ec:	bfe5                	j	2e4 <strlen+0x20>

00000000000002ee <memset>:

void*
memset(void *dst, int c, uint n)
{
 2ee:	1141                	addi	sp,sp,-16
 2f0:	e422                	sd	s0,8(sp)
 2f2:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 2f4:	ca19                	beqz	a2,30a <memset+0x1c>
 2f6:	87aa                	mv	a5,a0
 2f8:	1602                	slli	a2,a2,0x20
 2fa:	9201                	srli	a2,a2,0x20
 2fc:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 300:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 304:	0785                	addi	a5,a5,1
 306:	fee79de3          	bne	a5,a4,300 <memset+0x12>
  }
  return dst;
}
 30a:	6422                	ld	s0,8(sp)
 30c:	0141                	addi	sp,sp,16
 30e:	8082                	ret

0000000000000310 <strchr>:

char*
strchr(const char *s, char c)
{
 310:	1141                	addi	sp,sp,-16
 312:	e422                	sd	s0,8(sp)
 314:	0800                	addi	s0,sp,16
  for(; *s; s++)
 316:	00054783          	lbu	a5,0(a0)
 31a:	cb99                	beqz	a5,330 <strchr+0x20>
    if(*s == c)
 31c:	00f58763          	beq	a1,a5,32a <strchr+0x1a>
  for(; *s; s++)
 320:	0505                	addi	a0,a0,1
 322:	00054783          	lbu	a5,0(a0)
 326:	fbfd                	bnez	a5,31c <strchr+0xc>
      return (char*)s;
  return 0;
 328:	4501                	li	a0,0
}
 32a:	6422                	ld	s0,8(sp)
 32c:	0141                	addi	sp,sp,16
 32e:	8082                	ret
  return 0;
 330:	4501                	li	a0,0
 332:	bfe5                	j	32a <strchr+0x1a>

0000000000000334 <gets>:

char*
gets(char *buf, int max)
{
 334:	711d                	addi	sp,sp,-96
 336:	ec86                	sd	ra,88(sp)
 338:	e8a2                	sd	s0,80(sp)
 33a:	e4a6                	sd	s1,72(sp)
 33c:	e0ca                	sd	s2,64(sp)
 33e:	fc4e                	sd	s3,56(sp)
 340:	f852                	sd	s4,48(sp)
 342:	f456                	sd	s5,40(sp)
 344:	f05a                	sd	s6,32(sp)
 346:	ec5e                	sd	s7,24(sp)
 348:	1080                	addi	s0,sp,96
 34a:	8baa                	mv	s7,a0
 34c:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 34e:	892a                	mv	s2,a0
 350:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 352:	4aa9                	li	s5,10
 354:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 356:	89a6                	mv	s3,s1
 358:	2485                	addiw	s1,s1,1
 35a:	0344d863          	bge	s1,s4,38a <gets+0x56>
    cc = read(0, &c, 1);
 35e:	4605                	li	a2,1
 360:	faf40593          	addi	a1,s0,-81
 364:	4501                	li	a0,0
 366:	00000097          	auipc	ra,0x0
 36a:	19c080e7          	jalr	412(ra) # 502 <read>
    if(cc < 1)
 36e:	00a05e63          	blez	a0,38a <gets+0x56>
    buf[i++] = c;
 372:	faf44783          	lbu	a5,-81(s0)
 376:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 37a:	01578763          	beq	a5,s5,388 <gets+0x54>
 37e:	0905                	addi	s2,s2,1
 380:	fd679be3          	bne	a5,s6,356 <gets+0x22>
  for(i=0; i+1 < max; ){
 384:	89a6                	mv	s3,s1
 386:	a011                	j	38a <gets+0x56>
 388:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 38a:	99de                	add	s3,s3,s7
 38c:	00098023          	sb	zero,0(s3)
  return buf;
}
 390:	855e                	mv	a0,s7
 392:	60e6                	ld	ra,88(sp)
 394:	6446                	ld	s0,80(sp)
 396:	64a6                	ld	s1,72(sp)
 398:	6906                	ld	s2,64(sp)
 39a:	79e2                	ld	s3,56(sp)
 39c:	7a42                	ld	s4,48(sp)
 39e:	7aa2                	ld	s5,40(sp)
 3a0:	7b02                	ld	s6,32(sp)
 3a2:	6be2                	ld	s7,24(sp)
 3a4:	6125                	addi	sp,sp,96
 3a6:	8082                	ret

00000000000003a8 <stat>:

int
stat(const char *n, struct stat *st)
{
 3a8:	1101                	addi	sp,sp,-32
 3aa:	ec06                	sd	ra,24(sp)
 3ac:	e822                	sd	s0,16(sp)
 3ae:	e426                	sd	s1,8(sp)
 3b0:	e04a                	sd	s2,0(sp)
 3b2:	1000                	addi	s0,sp,32
 3b4:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 3b6:	4581                	li	a1,0
 3b8:	00000097          	auipc	ra,0x0
 3bc:	172080e7          	jalr	370(ra) # 52a <open>
  if(fd < 0)
 3c0:	02054563          	bltz	a0,3ea <stat+0x42>
 3c4:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 3c6:	85ca                	mv	a1,s2
 3c8:	00000097          	auipc	ra,0x0
 3cc:	17a080e7          	jalr	378(ra) # 542 <fstat>
 3d0:	892a                	mv	s2,a0
  close(fd);
 3d2:	8526                	mv	a0,s1
 3d4:	00000097          	auipc	ra,0x0
 3d8:	13e080e7          	jalr	318(ra) # 512 <close>
  return r;
}
 3dc:	854a                	mv	a0,s2
 3de:	60e2                	ld	ra,24(sp)
 3e0:	6442                	ld	s0,16(sp)
 3e2:	64a2                	ld	s1,8(sp)
 3e4:	6902                	ld	s2,0(sp)
 3e6:	6105                	addi	sp,sp,32
 3e8:	8082                	ret
    return -1;
 3ea:	597d                	li	s2,-1
 3ec:	bfc5                	j	3dc <stat+0x34>

00000000000003ee <atoi>:

int
atoi(const char *s)
{
 3ee:	1141                	addi	sp,sp,-16
 3f0:	e422                	sd	s0,8(sp)
 3f2:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 3f4:	00054603          	lbu	a2,0(a0)
 3f8:	fd06079b          	addiw	a5,a2,-48
 3fc:	0ff7f793          	andi	a5,a5,255
 400:	4725                	li	a4,9
 402:	02f76963          	bltu	a4,a5,434 <atoi+0x46>
 406:	86aa                	mv	a3,a0
  n = 0;
 408:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 40a:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 40c:	0685                	addi	a3,a3,1
 40e:	0025179b          	slliw	a5,a0,0x2
 412:	9fa9                	addw	a5,a5,a0
 414:	0017979b          	slliw	a5,a5,0x1
 418:	9fb1                	addw	a5,a5,a2
 41a:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 41e:	0006c603          	lbu	a2,0(a3)
 422:	fd06071b          	addiw	a4,a2,-48
 426:	0ff77713          	andi	a4,a4,255
 42a:	fee5f1e3          	bgeu	a1,a4,40c <atoi+0x1e>
  return n;
}
 42e:	6422                	ld	s0,8(sp)
 430:	0141                	addi	sp,sp,16
 432:	8082                	ret
  n = 0;
 434:	4501                	li	a0,0
 436:	bfe5                	j	42e <atoi+0x40>

0000000000000438 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 438:	1141                	addi	sp,sp,-16
 43a:	e422                	sd	s0,8(sp)
 43c:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 43e:	02b57463          	bgeu	a0,a1,466 <memmove+0x2e>
    while(n-- > 0)
 442:	00c05f63          	blez	a2,460 <memmove+0x28>
 446:	1602                	slli	a2,a2,0x20
 448:	9201                	srli	a2,a2,0x20
 44a:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 44e:	872a                	mv	a4,a0
      *dst++ = *src++;
 450:	0585                	addi	a1,a1,1
 452:	0705                	addi	a4,a4,1
 454:	fff5c683          	lbu	a3,-1(a1)
 458:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 45c:	fee79ae3          	bne	a5,a4,450 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 460:	6422                	ld	s0,8(sp)
 462:	0141                	addi	sp,sp,16
 464:	8082                	ret
    dst += n;
 466:	00c50733          	add	a4,a0,a2
    src += n;
 46a:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 46c:	fec05ae3          	blez	a2,460 <memmove+0x28>
 470:	fff6079b          	addiw	a5,a2,-1
 474:	1782                	slli	a5,a5,0x20
 476:	9381                	srli	a5,a5,0x20
 478:	fff7c793          	not	a5,a5
 47c:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 47e:	15fd                	addi	a1,a1,-1
 480:	177d                	addi	a4,a4,-1
 482:	0005c683          	lbu	a3,0(a1)
 486:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 48a:	fee79ae3          	bne	a5,a4,47e <memmove+0x46>
 48e:	bfc9                	j	460 <memmove+0x28>

0000000000000490 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 490:	1141                	addi	sp,sp,-16
 492:	e422                	sd	s0,8(sp)
 494:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 496:	ca05                	beqz	a2,4c6 <memcmp+0x36>
 498:	fff6069b          	addiw	a3,a2,-1
 49c:	1682                	slli	a3,a3,0x20
 49e:	9281                	srli	a3,a3,0x20
 4a0:	0685                	addi	a3,a3,1
 4a2:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 4a4:	00054783          	lbu	a5,0(a0)
 4a8:	0005c703          	lbu	a4,0(a1)
 4ac:	00e79863          	bne	a5,a4,4bc <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 4b0:	0505                	addi	a0,a0,1
    p2++;
 4b2:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 4b4:	fed518e3          	bne	a0,a3,4a4 <memcmp+0x14>
  }
  return 0;
 4b8:	4501                	li	a0,0
 4ba:	a019                	j	4c0 <memcmp+0x30>
      return *p1 - *p2;
 4bc:	40e7853b          	subw	a0,a5,a4
}
 4c0:	6422                	ld	s0,8(sp)
 4c2:	0141                	addi	sp,sp,16
 4c4:	8082                	ret
  return 0;
 4c6:	4501                	li	a0,0
 4c8:	bfe5                	j	4c0 <memcmp+0x30>

00000000000004ca <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 4ca:	1141                	addi	sp,sp,-16
 4cc:	e406                	sd	ra,8(sp)
 4ce:	e022                	sd	s0,0(sp)
 4d0:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 4d2:	00000097          	auipc	ra,0x0
 4d6:	f66080e7          	jalr	-154(ra) # 438 <memmove>
}
 4da:	60a2                	ld	ra,8(sp)
 4dc:	6402                	ld	s0,0(sp)
 4de:	0141                	addi	sp,sp,16
 4e0:	8082                	ret

00000000000004e2 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 4e2:	4885                	li	a7,1
 ecall
 4e4:	00000073          	ecall
 ret
 4e8:	8082                	ret

00000000000004ea <exit>:
.global exit
exit:
 li a7, SYS_exit
 4ea:	4889                	li	a7,2
 ecall
 4ec:	00000073          	ecall
 ret
 4f0:	8082                	ret

00000000000004f2 <wait>:
.global wait
wait:
 li a7, SYS_wait
 4f2:	488d                	li	a7,3
 ecall
 4f4:	00000073          	ecall
 ret
 4f8:	8082                	ret

00000000000004fa <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 4fa:	4891                	li	a7,4
 ecall
 4fc:	00000073          	ecall
 ret
 500:	8082                	ret

0000000000000502 <read>:
.global read
read:
 li a7, SYS_read
 502:	4895                	li	a7,5
 ecall
 504:	00000073          	ecall
 ret
 508:	8082                	ret

000000000000050a <write>:
.global write
write:
 li a7, SYS_write
 50a:	48c1                	li	a7,16
 ecall
 50c:	00000073          	ecall
 ret
 510:	8082                	ret

0000000000000512 <close>:
.global close
close:
 li a7, SYS_close
 512:	48d5                	li	a7,21
 ecall
 514:	00000073          	ecall
 ret
 518:	8082                	ret

000000000000051a <kill>:
.global kill
kill:
 li a7, SYS_kill
 51a:	4899                	li	a7,6
 ecall
 51c:	00000073          	ecall
 ret
 520:	8082                	ret

0000000000000522 <exec>:
.global exec
exec:
 li a7, SYS_exec
 522:	489d                	li	a7,7
 ecall
 524:	00000073          	ecall
 ret
 528:	8082                	ret

000000000000052a <open>:
.global open
open:
 li a7, SYS_open
 52a:	48bd                	li	a7,15
 ecall
 52c:	00000073          	ecall
 ret
 530:	8082                	ret

0000000000000532 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 532:	48c5                	li	a7,17
 ecall
 534:	00000073          	ecall
 ret
 538:	8082                	ret

000000000000053a <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 53a:	48c9                	li	a7,18
 ecall
 53c:	00000073          	ecall
 ret
 540:	8082                	ret

0000000000000542 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 542:	48a1                	li	a7,8
 ecall
 544:	00000073          	ecall
 ret
 548:	8082                	ret

000000000000054a <link>:
.global link
link:
 li a7, SYS_link
 54a:	48cd                	li	a7,19
 ecall
 54c:	00000073          	ecall
 ret
 550:	8082                	ret

0000000000000552 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 552:	48d1                	li	a7,20
 ecall
 554:	00000073          	ecall
 ret
 558:	8082                	ret

000000000000055a <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 55a:	48a5                	li	a7,9
 ecall
 55c:	00000073          	ecall
 ret
 560:	8082                	ret

0000000000000562 <dup>:
.global dup
dup:
 li a7, SYS_dup
 562:	48a9                	li	a7,10
 ecall
 564:	00000073          	ecall
 ret
 568:	8082                	ret

000000000000056a <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 56a:	48ad                	li	a7,11
 ecall
 56c:	00000073          	ecall
 ret
 570:	8082                	ret

0000000000000572 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 572:	48b1                	li	a7,12
 ecall
 574:	00000073          	ecall
 ret
 578:	8082                	ret

000000000000057a <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 57a:	48b5                	li	a7,13
 ecall
 57c:	00000073          	ecall
 ret
 580:	8082                	ret

0000000000000582 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 582:	48b9                	li	a7,14
 ecall
 584:	00000073          	ecall
 ret
 588:	8082                	ret

000000000000058a <sematest>:
.global sematest
sematest:
 li a7, SYS_sematest
 58a:	48d9                	li	a7,22
 ecall
 58c:	00000073          	ecall
 ret
 590:	8082                	ret

0000000000000592 <rwsematest>:
.global rwsematest
rwsematest:
 li a7, SYS_rwsematest
 592:	48dd                	li	a7,23
 ecall
 594:	00000073          	ecall
 ret
 598:	8082                	ret

000000000000059a <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 59a:	1101                	addi	sp,sp,-32
 59c:	ec06                	sd	ra,24(sp)
 59e:	e822                	sd	s0,16(sp)
 5a0:	1000                	addi	s0,sp,32
 5a2:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 5a6:	4605                	li	a2,1
 5a8:	fef40593          	addi	a1,s0,-17
 5ac:	00000097          	auipc	ra,0x0
 5b0:	f5e080e7          	jalr	-162(ra) # 50a <write>
}
 5b4:	60e2                	ld	ra,24(sp)
 5b6:	6442                	ld	s0,16(sp)
 5b8:	6105                	addi	sp,sp,32
 5ba:	8082                	ret

00000000000005bc <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 5bc:	7139                	addi	sp,sp,-64
 5be:	fc06                	sd	ra,56(sp)
 5c0:	f822                	sd	s0,48(sp)
 5c2:	f426                	sd	s1,40(sp)
 5c4:	f04a                	sd	s2,32(sp)
 5c6:	ec4e                	sd	s3,24(sp)
 5c8:	0080                	addi	s0,sp,64
 5ca:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 5cc:	c299                	beqz	a3,5d2 <printint+0x16>
 5ce:	0805c863          	bltz	a1,65e <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 5d2:	2581                	sext.w	a1,a1
  neg = 0;
 5d4:	4881                	li	a7,0
 5d6:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 5da:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 5dc:	2601                	sext.w	a2,a2
 5de:	00000517          	auipc	a0,0x0
 5e2:	4b250513          	addi	a0,a0,1202 # a90 <digits>
 5e6:	883a                	mv	a6,a4
 5e8:	2705                	addiw	a4,a4,1
 5ea:	02c5f7bb          	remuw	a5,a1,a2
 5ee:	1782                	slli	a5,a5,0x20
 5f0:	9381                	srli	a5,a5,0x20
 5f2:	97aa                	add	a5,a5,a0
 5f4:	0007c783          	lbu	a5,0(a5)
 5f8:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 5fc:	0005879b          	sext.w	a5,a1
 600:	02c5d5bb          	divuw	a1,a1,a2
 604:	0685                	addi	a3,a3,1
 606:	fec7f0e3          	bgeu	a5,a2,5e6 <printint+0x2a>
  if(neg)
 60a:	00088b63          	beqz	a7,620 <printint+0x64>
    buf[i++] = '-';
 60e:	fd040793          	addi	a5,s0,-48
 612:	973e                	add	a4,a4,a5
 614:	02d00793          	li	a5,45
 618:	fef70823          	sb	a5,-16(a4)
 61c:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 620:	02e05863          	blez	a4,650 <printint+0x94>
 624:	fc040793          	addi	a5,s0,-64
 628:	00e78933          	add	s2,a5,a4
 62c:	fff78993          	addi	s3,a5,-1
 630:	99ba                	add	s3,s3,a4
 632:	377d                	addiw	a4,a4,-1
 634:	1702                	slli	a4,a4,0x20
 636:	9301                	srli	a4,a4,0x20
 638:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 63c:	fff94583          	lbu	a1,-1(s2)
 640:	8526                	mv	a0,s1
 642:	00000097          	auipc	ra,0x0
 646:	f58080e7          	jalr	-168(ra) # 59a <putc>
  while(--i >= 0)
 64a:	197d                	addi	s2,s2,-1
 64c:	ff3918e3          	bne	s2,s3,63c <printint+0x80>
}
 650:	70e2                	ld	ra,56(sp)
 652:	7442                	ld	s0,48(sp)
 654:	74a2                	ld	s1,40(sp)
 656:	7902                	ld	s2,32(sp)
 658:	69e2                	ld	s3,24(sp)
 65a:	6121                	addi	sp,sp,64
 65c:	8082                	ret
    x = -xx;
 65e:	40b005bb          	negw	a1,a1
    neg = 1;
 662:	4885                	li	a7,1
    x = -xx;
 664:	bf8d                	j	5d6 <printint+0x1a>

0000000000000666 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 666:	7119                	addi	sp,sp,-128
 668:	fc86                	sd	ra,120(sp)
 66a:	f8a2                	sd	s0,112(sp)
 66c:	f4a6                	sd	s1,104(sp)
 66e:	f0ca                	sd	s2,96(sp)
 670:	ecce                	sd	s3,88(sp)
 672:	e8d2                	sd	s4,80(sp)
 674:	e4d6                	sd	s5,72(sp)
 676:	e0da                	sd	s6,64(sp)
 678:	fc5e                	sd	s7,56(sp)
 67a:	f862                	sd	s8,48(sp)
 67c:	f466                	sd	s9,40(sp)
 67e:	f06a                	sd	s10,32(sp)
 680:	ec6e                	sd	s11,24(sp)
 682:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 684:	0005c903          	lbu	s2,0(a1)
 688:	18090f63          	beqz	s2,826 <vprintf+0x1c0>
 68c:	8aaa                	mv	s5,a0
 68e:	8b32                	mv	s6,a2
 690:	00158493          	addi	s1,a1,1
  state = 0;
 694:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 696:	02500a13          	li	s4,37
      if(c == 'd'){
 69a:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 69e:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 6a2:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 6a6:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 6aa:	00000b97          	auipc	s7,0x0
 6ae:	3e6b8b93          	addi	s7,s7,998 # a90 <digits>
 6b2:	a839                	j	6d0 <vprintf+0x6a>
        putc(fd, c);
 6b4:	85ca                	mv	a1,s2
 6b6:	8556                	mv	a0,s5
 6b8:	00000097          	auipc	ra,0x0
 6bc:	ee2080e7          	jalr	-286(ra) # 59a <putc>
 6c0:	a019                	j	6c6 <vprintf+0x60>
    } else if(state == '%'){
 6c2:	01498f63          	beq	s3,s4,6e0 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 6c6:	0485                	addi	s1,s1,1
 6c8:	fff4c903          	lbu	s2,-1(s1)
 6cc:	14090d63          	beqz	s2,826 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 6d0:	0009079b          	sext.w	a5,s2
    if(state == 0){
 6d4:	fe0997e3          	bnez	s3,6c2 <vprintf+0x5c>
      if(c == '%'){
 6d8:	fd479ee3          	bne	a5,s4,6b4 <vprintf+0x4e>
        state = '%';
 6dc:	89be                	mv	s3,a5
 6de:	b7e5                	j	6c6 <vprintf+0x60>
      if(c == 'd'){
 6e0:	05878063          	beq	a5,s8,720 <vprintf+0xba>
      } else if(c == 'l') {
 6e4:	05978c63          	beq	a5,s9,73c <vprintf+0xd6>
      } else if(c == 'x') {
 6e8:	07a78863          	beq	a5,s10,758 <vprintf+0xf2>
      } else if(c == 'p') {
 6ec:	09b78463          	beq	a5,s11,774 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 6f0:	07300713          	li	a4,115
 6f4:	0ce78663          	beq	a5,a4,7c0 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 6f8:	06300713          	li	a4,99
 6fc:	0ee78e63          	beq	a5,a4,7f8 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 700:	11478863          	beq	a5,s4,810 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 704:	85d2                	mv	a1,s4
 706:	8556                	mv	a0,s5
 708:	00000097          	auipc	ra,0x0
 70c:	e92080e7          	jalr	-366(ra) # 59a <putc>
        putc(fd, c);
 710:	85ca                	mv	a1,s2
 712:	8556                	mv	a0,s5
 714:	00000097          	auipc	ra,0x0
 718:	e86080e7          	jalr	-378(ra) # 59a <putc>
      }
      state = 0;
 71c:	4981                	li	s3,0
 71e:	b765                	j	6c6 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 720:	008b0913          	addi	s2,s6,8
 724:	4685                	li	a3,1
 726:	4629                	li	a2,10
 728:	000b2583          	lw	a1,0(s6)
 72c:	8556                	mv	a0,s5
 72e:	00000097          	auipc	ra,0x0
 732:	e8e080e7          	jalr	-370(ra) # 5bc <printint>
 736:	8b4a                	mv	s6,s2
      state = 0;
 738:	4981                	li	s3,0
 73a:	b771                	j	6c6 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 73c:	008b0913          	addi	s2,s6,8
 740:	4681                	li	a3,0
 742:	4629                	li	a2,10
 744:	000b2583          	lw	a1,0(s6)
 748:	8556                	mv	a0,s5
 74a:	00000097          	auipc	ra,0x0
 74e:	e72080e7          	jalr	-398(ra) # 5bc <printint>
 752:	8b4a                	mv	s6,s2
      state = 0;
 754:	4981                	li	s3,0
 756:	bf85                	j	6c6 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 758:	008b0913          	addi	s2,s6,8
 75c:	4681                	li	a3,0
 75e:	4641                	li	a2,16
 760:	000b2583          	lw	a1,0(s6)
 764:	8556                	mv	a0,s5
 766:	00000097          	auipc	ra,0x0
 76a:	e56080e7          	jalr	-426(ra) # 5bc <printint>
 76e:	8b4a                	mv	s6,s2
      state = 0;
 770:	4981                	li	s3,0
 772:	bf91                	j	6c6 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 774:	008b0793          	addi	a5,s6,8
 778:	f8f43423          	sd	a5,-120(s0)
 77c:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 780:	03000593          	li	a1,48
 784:	8556                	mv	a0,s5
 786:	00000097          	auipc	ra,0x0
 78a:	e14080e7          	jalr	-492(ra) # 59a <putc>
  putc(fd, 'x');
 78e:	85ea                	mv	a1,s10
 790:	8556                	mv	a0,s5
 792:	00000097          	auipc	ra,0x0
 796:	e08080e7          	jalr	-504(ra) # 59a <putc>
 79a:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 79c:	03c9d793          	srli	a5,s3,0x3c
 7a0:	97de                	add	a5,a5,s7
 7a2:	0007c583          	lbu	a1,0(a5)
 7a6:	8556                	mv	a0,s5
 7a8:	00000097          	auipc	ra,0x0
 7ac:	df2080e7          	jalr	-526(ra) # 59a <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 7b0:	0992                	slli	s3,s3,0x4
 7b2:	397d                	addiw	s2,s2,-1
 7b4:	fe0914e3          	bnez	s2,79c <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 7b8:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 7bc:	4981                	li	s3,0
 7be:	b721                	j	6c6 <vprintf+0x60>
        s = va_arg(ap, char*);
 7c0:	008b0993          	addi	s3,s6,8
 7c4:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 7c8:	02090163          	beqz	s2,7ea <vprintf+0x184>
        while(*s != 0){
 7cc:	00094583          	lbu	a1,0(s2)
 7d0:	c9a1                	beqz	a1,820 <vprintf+0x1ba>
          putc(fd, *s);
 7d2:	8556                	mv	a0,s5
 7d4:	00000097          	auipc	ra,0x0
 7d8:	dc6080e7          	jalr	-570(ra) # 59a <putc>
          s++;
 7dc:	0905                	addi	s2,s2,1
        while(*s != 0){
 7de:	00094583          	lbu	a1,0(s2)
 7e2:	f9e5                	bnez	a1,7d2 <vprintf+0x16c>
        s = va_arg(ap, char*);
 7e4:	8b4e                	mv	s6,s3
      state = 0;
 7e6:	4981                	li	s3,0
 7e8:	bdf9                	j	6c6 <vprintf+0x60>
          s = "(null)";
 7ea:	00000917          	auipc	s2,0x0
 7ee:	29e90913          	addi	s2,s2,670 # a88 <malloc+0x158>
        while(*s != 0){
 7f2:	02800593          	li	a1,40
 7f6:	bff1                	j	7d2 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 7f8:	008b0913          	addi	s2,s6,8
 7fc:	000b4583          	lbu	a1,0(s6)
 800:	8556                	mv	a0,s5
 802:	00000097          	auipc	ra,0x0
 806:	d98080e7          	jalr	-616(ra) # 59a <putc>
 80a:	8b4a                	mv	s6,s2
      state = 0;
 80c:	4981                	li	s3,0
 80e:	bd65                	j	6c6 <vprintf+0x60>
        putc(fd, c);
 810:	85d2                	mv	a1,s4
 812:	8556                	mv	a0,s5
 814:	00000097          	auipc	ra,0x0
 818:	d86080e7          	jalr	-634(ra) # 59a <putc>
      state = 0;
 81c:	4981                	li	s3,0
 81e:	b565                	j	6c6 <vprintf+0x60>
        s = va_arg(ap, char*);
 820:	8b4e                	mv	s6,s3
      state = 0;
 822:	4981                	li	s3,0
 824:	b54d                	j	6c6 <vprintf+0x60>
    }
  }
}
 826:	70e6                	ld	ra,120(sp)
 828:	7446                	ld	s0,112(sp)
 82a:	74a6                	ld	s1,104(sp)
 82c:	7906                	ld	s2,96(sp)
 82e:	69e6                	ld	s3,88(sp)
 830:	6a46                	ld	s4,80(sp)
 832:	6aa6                	ld	s5,72(sp)
 834:	6b06                	ld	s6,64(sp)
 836:	7be2                	ld	s7,56(sp)
 838:	7c42                	ld	s8,48(sp)
 83a:	7ca2                	ld	s9,40(sp)
 83c:	7d02                	ld	s10,32(sp)
 83e:	6de2                	ld	s11,24(sp)
 840:	6109                	addi	sp,sp,128
 842:	8082                	ret

0000000000000844 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 844:	715d                	addi	sp,sp,-80
 846:	ec06                	sd	ra,24(sp)
 848:	e822                	sd	s0,16(sp)
 84a:	1000                	addi	s0,sp,32
 84c:	e010                	sd	a2,0(s0)
 84e:	e414                	sd	a3,8(s0)
 850:	e818                	sd	a4,16(s0)
 852:	ec1c                	sd	a5,24(s0)
 854:	03043023          	sd	a6,32(s0)
 858:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 85c:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 860:	8622                	mv	a2,s0
 862:	00000097          	auipc	ra,0x0
 866:	e04080e7          	jalr	-508(ra) # 666 <vprintf>
}
 86a:	60e2                	ld	ra,24(sp)
 86c:	6442                	ld	s0,16(sp)
 86e:	6161                	addi	sp,sp,80
 870:	8082                	ret

0000000000000872 <printf>:

void
printf(const char *fmt, ...)
{
 872:	711d                	addi	sp,sp,-96
 874:	ec06                	sd	ra,24(sp)
 876:	e822                	sd	s0,16(sp)
 878:	1000                	addi	s0,sp,32
 87a:	e40c                	sd	a1,8(s0)
 87c:	e810                	sd	a2,16(s0)
 87e:	ec14                	sd	a3,24(s0)
 880:	f018                	sd	a4,32(s0)
 882:	f41c                	sd	a5,40(s0)
 884:	03043823          	sd	a6,48(s0)
 888:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 88c:	00840613          	addi	a2,s0,8
 890:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 894:	85aa                	mv	a1,a0
 896:	4505                	li	a0,1
 898:	00000097          	auipc	ra,0x0
 89c:	dce080e7          	jalr	-562(ra) # 666 <vprintf>
}
 8a0:	60e2                	ld	ra,24(sp)
 8a2:	6442                	ld	s0,16(sp)
 8a4:	6125                	addi	sp,sp,96
 8a6:	8082                	ret

00000000000008a8 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 8a8:	1141                	addi	sp,sp,-16
 8aa:	e422                	sd	s0,8(sp)
 8ac:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 8ae:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 8b2:	00000797          	auipc	a5,0x0
 8b6:	1f67b783          	ld	a5,502(a5) # aa8 <freep>
 8ba:	a805                	j	8ea <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 8bc:	4618                	lw	a4,8(a2)
 8be:	9db9                	addw	a1,a1,a4
 8c0:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 8c4:	6398                	ld	a4,0(a5)
 8c6:	6318                	ld	a4,0(a4)
 8c8:	fee53823          	sd	a4,-16(a0)
 8cc:	a091                	j	910 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 8ce:	ff852703          	lw	a4,-8(a0)
 8d2:	9e39                	addw	a2,a2,a4
 8d4:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 8d6:	ff053703          	ld	a4,-16(a0)
 8da:	e398                	sd	a4,0(a5)
 8dc:	a099                	j	922 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 8de:	6398                	ld	a4,0(a5)
 8e0:	00e7e463          	bltu	a5,a4,8e8 <free+0x40>
 8e4:	00e6ea63          	bltu	a3,a4,8f8 <free+0x50>
{
 8e8:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 8ea:	fed7fae3          	bgeu	a5,a3,8de <free+0x36>
 8ee:	6398                	ld	a4,0(a5)
 8f0:	00e6e463          	bltu	a3,a4,8f8 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 8f4:	fee7eae3          	bltu	a5,a4,8e8 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 8f8:	ff852583          	lw	a1,-8(a0)
 8fc:	6390                	ld	a2,0(a5)
 8fe:	02059713          	slli	a4,a1,0x20
 902:	9301                	srli	a4,a4,0x20
 904:	0712                	slli	a4,a4,0x4
 906:	9736                	add	a4,a4,a3
 908:	fae60ae3          	beq	a2,a4,8bc <free+0x14>
    bp->s.ptr = p->s.ptr;
 90c:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 910:	4790                	lw	a2,8(a5)
 912:	02061713          	slli	a4,a2,0x20
 916:	9301                	srli	a4,a4,0x20
 918:	0712                	slli	a4,a4,0x4
 91a:	973e                	add	a4,a4,a5
 91c:	fae689e3          	beq	a3,a4,8ce <free+0x26>
  } else
    p->s.ptr = bp;
 920:	e394                	sd	a3,0(a5)
  freep = p;
 922:	00000717          	auipc	a4,0x0
 926:	18f73323          	sd	a5,390(a4) # aa8 <freep>
}
 92a:	6422                	ld	s0,8(sp)
 92c:	0141                	addi	sp,sp,16
 92e:	8082                	ret

0000000000000930 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 930:	7139                	addi	sp,sp,-64
 932:	fc06                	sd	ra,56(sp)
 934:	f822                	sd	s0,48(sp)
 936:	f426                	sd	s1,40(sp)
 938:	f04a                	sd	s2,32(sp)
 93a:	ec4e                	sd	s3,24(sp)
 93c:	e852                	sd	s4,16(sp)
 93e:	e456                	sd	s5,8(sp)
 940:	e05a                	sd	s6,0(sp)
 942:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 944:	02051493          	slli	s1,a0,0x20
 948:	9081                	srli	s1,s1,0x20
 94a:	04bd                	addi	s1,s1,15
 94c:	8091                	srli	s1,s1,0x4
 94e:	0014899b          	addiw	s3,s1,1
 952:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 954:	00000517          	auipc	a0,0x0
 958:	15453503          	ld	a0,340(a0) # aa8 <freep>
 95c:	c515                	beqz	a0,988 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 95e:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 960:	4798                	lw	a4,8(a5)
 962:	02977f63          	bgeu	a4,s1,9a0 <malloc+0x70>
 966:	8a4e                	mv	s4,s3
 968:	0009871b          	sext.w	a4,s3
 96c:	6685                	lui	a3,0x1
 96e:	00d77363          	bgeu	a4,a3,974 <malloc+0x44>
 972:	6a05                	lui	s4,0x1
 974:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 978:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 97c:	00000917          	auipc	s2,0x0
 980:	12c90913          	addi	s2,s2,300 # aa8 <freep>
  if(p == (char*)-1)
 984:	5afd                	li	s5,-1
 986:	a88d                	j	9f8 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 988:	00000797          	auipc	a5,0x0
 98c:	12878793          	addi	a5,a5,296 # ab0 <base>
 990:	00000717          	auipc	a4,0x0
 994:	10f73c23          	sd	a5,280(a4) # aa8 <freep>
 998:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 99a:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 99e:	b7e1                	j	966 <malloc+0x36>
      if(p->s.size == nunits)
 9a0:	02e48b63          	beq	s1,a4,9d6 <malloc+0xa6>
        p->s.size -= nunits;
 9a4:	4137073b          	subw	a4,a4,s3
 9a8:	c798                	sw	a4,8(a5)
        p += p->s.size;
 9aa:	1702                	slli	a4,a4,0x20
 9ac:	9301                	srli	a4,a4,0x20
 9ae:	0712                	slli	a4,a4,0x4
 9b0:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 9b2:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 9b6:	00000717          	auipc	a4,0x0
 9ba:	0ea73923          	sd	a0,242(a4) # aa8 <freep>
      return (void*)(p + 1);
 9be:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 9c2:	70e2                	ld	ra,56(sp)
 9c4:	7442                	ld	s0,48(sp)
 9c6:	74a2                	ld	s1,40(sp)
 9c8:	7902                	ld	s2,32(sp)
 9ca:	69e2                	ld	s3,24(sp)
 9cc:	6a42                	ld	s4,16(sp)
 9ce:	6aa2                	ld	s5,8(sp)
 9d0:	6b02                	ld	s6,0(sp)
 9d2:	6121                	addi	sp,sp,64
 9d4:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 9d6:	6398                	ld	a4,0(a5)
 9d8:	e118                	sd	a4,0(a0)
 9da:	bff1                	j	9b6 <malloc+0x86>
  hp->s.size = nu;
 9dc:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 9e0:	0541                	addi	a0,a0,16
 9e2:	00000097          	auipc	ra,0x0
 9e6:	ec6080e7          	jalr	-314(ra) # 8a8 <free>
  return freep;
 9ea:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 9ee:	d971                	beqz	a0,9c2 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 9f0:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 9f2:	4798                	lw	a4,8(a5)
 9f4:	fa9776e3          	bgeu	a4,s1,9a0 <malloc+0x70>
    if(p == freep)
 9f8:	00093703          	ld	a4,0(s2)
 9fc:	853e                	mv	a0,a5
 9fe:	fef719e3          	bne	a4,a5,9f0 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 a02:	8552                	mv	a0,s4
 a04:	00000097          	auipc	ra,0x0
 a08:	b6e080e7          	jalr	-1170(ra) # 572 <sbrk>
  if(p == (char*)-1)
 a0c:	fd5518e3          	bne	a0,s5,9dc <malloc+0xac>
        return 0;
 a10:	4501                	li	a0,0
 a12:	bf45                	j	9c2 <malloc+0x92>
