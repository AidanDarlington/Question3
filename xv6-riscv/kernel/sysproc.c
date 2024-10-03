#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "date.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"
#include "kernel/semaphore.h"

uint64
sys_exit(void)
{
  int n;
  if(argint(0, &n) < 0)
    return -1;
  exit(n);
  return 0;  // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return fork();
}

uint64
sys_wait(void)
{
  uint64 p;
  if(argaddr(0, &p) < 0)
    return -1;
  return wait(p);
}

uint64
sys_sbrk(void)
{
  int addr;
  int n;

  if(argint(0, &n) < 0)
    return -1;
  addr = myproc()->sz;
  if(growproc(n) < 0)
    return -1;
  return addr;
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  if(argint(0, &pid) < 0)
    return -1;
  return kill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}

// Aidan Darlington
// Student ID: 21134427
// Assignment 1 Additions
int
sys_sematest(void)
{
  static struct semaphore lk; // Static semaphore variable
  int cmd, ret = 0; // Command and return value initialization
  
  if(argint(0, &cmd) < 0) // Retrieve the command argument
  return -1;

  switch(cmd) {
  case 0: initsema(&lk, 5); ret = 5; break; // Initialize semaphore with value 5
  case 1: ret = downsema(&lk); break; // Perform down operation on semaphore
  case 2: ret = upsema(&lk); break; // Perform up operation on semaphore
  }
  return ret; // Return the result of the operation
}
  
int
sys_rwsematest(void)
{
  static struct rwsemaphore lk; // Static read-write semaphore variable
  int cmd, ret = 0; // Command and return value initialization

  if(argint(0, &cmd) < 0) // Retrieve the command argument
  return -1;

  switch(cmd) {
  case 0: initrwsema(&lk); break; // Initialize read-write semaphore
  case 1: ret = downreadsema(&lk); break; // Perform down read operation on semaphore
  case 2: ret = upreadsema(&lk); break; // Perform up read operation on semaphore
  case 3: downwritesema(&lk); break; // Perform down write operation on semaphore
  case 4: upwritesema(&lk); break; // Perform up write operation on semaphore
  }
  return ret; // Return the result of the operation
}
