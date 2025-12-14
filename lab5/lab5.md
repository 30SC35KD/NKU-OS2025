# Lab5：用户进程管理
## （小组成员：2312289刘轩麟 2312114李子恒 2213468陈馨颍）
## 练习0：把之前的代码填充到项目里
我们在lab4中我们使用do_fork复制出一个新进程，我们需要做的改动有两处：
1. 设置当前进程为父进程，确保当前进程的 wait_state 为 0
1. 设置进程关系链接，这一步我们直接调用set_link，这其中把子进程插入到父进程的子链表以及全局进程链表
代码如下：
```c
    proc->parent = current;          // 父进程为当前进程
    current->wait_state = 0; // 确保当前进程的 wait_state 为 0
    ...
    set_links(proc); // 设置进程关系链接，并加入全局进程链表
```

另外，我们还要修改trap.c中时间片轮转的逻辑，否则会出错：
```c
    case IRQ_S_TIMER:
         clock_set_next_event();
            ticks++;
            if(ticks%TICK_NUM==0)
            {   
                if(current!=NULL)
                {
                    current->need_resched = 1;
                }
            }
        break;
```
每 TICK_NUM 次中断（如 100 次），进行判断当前是否有进程正在运行，如果有则标记该进程需要被重新调度。
## 练习1: 加载应用程序并执行（需要编码）
do_execv函数调用load_icode来加载并解析一个处于内存中的ELF执行文件格式的应用程序，我们需要在load_icode里补充部分代码。首先我们看一下这个函数做了什么：
1. 创建新的 mm 结构体和页目录表（PDT），进行内存结构初始化
1. 检查ELF是否合法
1. 遍历 ELF 可加载段，创建虚拟内存区域（vma），分配物理页，复制 TEXT/DATA 段内容，将 BSS 段初始化为 0
1. 为用户栈分配虚拟内存空间，并预分配 4 个物理页
1. 绑定当前进程的 mm、页目录物理地址，更新 satp 寄存器
1. 设置好proc_struct结构中的成员变量trapframe中的内容

可以看到，代码中需要我们补充的就是trapframe中寄存器的状态维护，我们需要分别维护**用户进程的栈指针sp**、**epc寄存器**和**status寄存器**。
1. 设置sp为用户栈的顶部地址，我们直接用memlayout.h中定义的宏**USTACKTOP**实现。用户栈是进程运行时用于存储局部变量、函数调用信息等的内存区域
1. 设置用户态进程的程序计数器（epc）为ELF文件的入口点地址**elf->e_entry**，这时用户进程的起始执行地址
1. 状态寄存器的设置需要用到原本保存的状态寄存器的值sstatus，我们要保留其基础的状态，仅对个别位进行调整，我们首先对~SSTATUS_SPP进行与操作，意思是对**SPP**那一位清零，其他位保存。因为SPP 位用于标识**上一次的特权级别**，1 表示上一级是内核态，0 表示上一级是用户态，清除该位后，CPU 从内核态返回时会进入用户态；接着我们对**SSTATUS_SPIE**进行或操作，意思是把SPIE那一位置1，SPIE 位用于控制**返回后是否开启中断**，1 表示恢复到用户态后允许响应中断，0 则禁用，所以我们希望用户态程序运行时能正常处理中断。

代码如下：
```c
    tf->gpr.sp = USTACKTOP;
    tf->epc = elf->e_entry;
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
    ret = 0;
```

### 问题：请简要描述这个用户态进程被ucore选择占用CPU执行（RUNNING态）到具体执行应用程序第一条指令的整个经过。
用户进程被设为RUNNABLE是在do_fork中的wakeup操作进行的，也就是说，此时我们已经创建好了user_main用户进程。不要忘了，我们此时处在init_main内核进程的执行过程中，所以init进程为父进程，用do_wait来控制调度：
```c
    while (do_wait(0, NULL) == 0) 
    {
        schedule();
    }

```
简单来说，触发调度的情况有两种：
1. 在do_wait函数里，没有找到为僵尸状态的子进程，那么直接触发调度
1. 只要还能成功回收一个子进程（僵尸状态），就继续循环触发调度;
既然触发调度了，那执行过程就和lab4很像了，依次经过proc_run->switch_to->forkret->__trapret，最后通过sret跳到epc(kernel_thread_entry)，里面通过汇编连接到了目标进程（user_main），这时才算运行起来了user_main。
这里面需要编译好的用户程序，分别传入名称、内存起始地址和大小，送进了kernel_execve（先经过了几个宏的封装）。kernel_execve中使用了内联汇编：
```c
    asm volatile(
        "li a0, %1\n"
        "lw a1, %2\n"
        "lw a2, %3\n"
        "lw a3, %4\n"
        "lw a4, %5\n"
        "li a7, 10\n"
        "ebreak\n"
        "sw a0, %0\n"
        : "=m"(ret)
        : "i"(SYS_exec), "m"(name), "m"(len), "m"(binary), "m"(size)
        : "memory");
```
前面几个寄存器分别赋值为SYS_exec、name……，为了在异常处理中给syscall提供参数。把a7强制赋为10，为了在异常处理程序中进行特判。Ebreak之后，就进入trap.c中的断点特定处理中：
```c
    case CAUSE_BREAKPOINT:
        cprintf("Breakpoint\n");
        if (tf->gpr.a7 == 10)
        {
            tf->epc += 4;
            syscall();
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
        }
        break;
```
先用a7做了特判，通过设置a7寄存器的值为10说明这不是一个普通的断点中断，而是要转发到syscall()，这样就可以在S态实现系统调用。syscall的实现在syscall/syscall.c中，是根据a1寄存器（系统调用号）转发到不同的系统调用封装，比如SYS_exec=4转发到sys_exec，这里面return了do_execve。
do_execve里面把新的程序加载到当前进程里的工作都在load_icode()函数里完成，我们在补充代码时简要介绍过这里做了什么，我们补充的那部分代码尤其关键，sp设置了用户态栈、epc设置了elf->entry也就是真正的用户代码入口、SPP清零让程序返回用户态，这些trapframe的变量通过kernel_execve_ret放到内核栈上，接着通过__trapret存到对应寄存器当中，这时已经具备执行用户程序的条件了，只需sret，直接跳到epc存的地址（elf->entry），终于到了用户程序的入口，并且由于SPP=0，sret之后是用户态。
## 练习2：父进程复制自己的内存空间给子进程（需要编码）
创建子进程的函数do_fork在执行中将拷贝当前进程（即父进程）的用户内存地址空间中的合法内容到新进程
中（子进程），完成内存资源的复制。具体是通过copy_range函数实现的，在这个函数中，已经找到源页对应的物理页page，并为目标进程分配新的物理页npage。接下来需要我们做的就是将源物理页的虚拟地址内容，完整拷贝到目标物理页的虚拟地址，这就需要我们用page2kva来实现物理地址到虚拟地址的转换。在拷贝完成之后，还需要将目标物理页与目标进程的线性地址建立映射，我们使用page_insert实现。代码如下：
```c
        void *src_kvaddr = page2kva(page); // 获取源页面的内核虚拟地址
        void *dst_kvaddr = page2kva(npage); // 获取目标页面的内核虚拟地址
        memcpy(dst_kvaddr, src_kvaddr, PGSIZE); // 复制页面内容
                
        int ret = page_insert(to, npage, start, perm); // 将目标页面插入到目标进程的页表中
```

关于COW机制，我们在Challenge部分进行讨论。
## Challenge:
copy_mm->lock_mm->dup_mmap->copy_range(share=1)