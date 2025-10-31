# Lab3：中断与中断处理流程
##（小组成员：2312289刘轩麟 2312114李子恒 2213468陈馨颍）
## 练习1
首先我们完善IRQ_S_TIMER的逻辑，其主要逻辑如下：
1. 设置下次时钟中断
1. 计数器加一
1. 当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断
1. 判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机

对此，我们的实现如下：
```c
case IRQ_S_TIMER:
    clock_set_next_event();
    ticks++;
    if(ticks%TICK_NUM==0)
    {   
        print_ticks();
        PRINT_COUNT++;
        if(PRINT_COUNT==10) 
        sbi_shutdown();
    }
                
                break;
```
设置时钟中断采用**clock_set_next_event()**，这个函数在clock.c中实现：
```c
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
```
使用了sbi中的接口，基本逻辑是timer的数值变为当前时间 + timebase 后，触发一次时钟中断。在代码中，已经定义了timebase=100000,对于QEMU, timer增加1，过去了10^-7 s， 也就是100ns，所以单次中断的时间间隔是0.01s，那么100次大约就是1s。我们的结果也是1s输出一次"100ticks"。至于停止，我设置了一个全局变量**PRINT_COUNT**，每次打印加1，10次打印之后，调用sbi.h中提供的接口**sbi_shutdown()**，关闭机器。

## Challenge1: 描述与理解中断流程
代码从**entry.S**进入**kern_init**。与之前实验不同的是，我们在初始化的过程中增加了**idt_init**函数，其定义如下：
```c
void idt_init(void) {
    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
}
```
声明外部符号 **__alltraps** 是一个在trapentry.S中定义的中断、异常入口标记，这个初始化函数的作用是初始化sscratch寄存器，然后把__alltraps的地址给stvec。stvec即中断向量表基址。中断向量表的作用就是把不同种类的中断映射到对应的中断处理程序。显然我们有必要了解__alltraps标签，其代码如下：
```c
__alltraps:
    SAVE_ALL

    move  a0, sp
    jal trap
    # sp should be the same as before "jal trap"
```
这段代码首先调用了在trapentry.S定义的宏**SAVE_ALL**，我们可以查看一下其具体实现：
```c
.macro SAVE_ALL

    csrw sscratch, sp

    addi sp, sp, -36 * REGBYTES
    # save x registers
    STORE x0, 0*REGBYTES(sp)
    ...
    .endm
```
这个宏的作用是保存所有寄存器到栈顶，我们看到先把原栈顶指针保存到sscratch，然后开辟36个寄存器的栈空间（高地址向低地址增长），然后依次从低地址向栈中保存寄存器。36个寄存器包括通用寄存器x0到x31,然后依次排列4个和中断相关的CSR。这个宏中**REGBYTES**来自riscv.h文件。如果是64位，那么这个大小是8bytes。sscratch即 RISC-V 架构硬件定义的控制状态寄存器，sscratch寄存器在处理用户态程序的中断时才起作用。要注意的是，RISCV不能直接从CSR写到内存, 需要csrr把CSR读取到通用寄存器，再从通用寄存器STORE到内存

我们回到__alltraps中，**move a0, sp**的作用是将栈指针寄存器 sp 的值复制到参数寄存器 a0 中，相当于保存现场。更重要的是，a0是RISC-V函数调用约定中规定的第一个参数寄存器，因为接下来的指令就是**jal trap**，调用了trap函数，所以我们接下来要看看trap函数发生了什么。

回到trap.c中，我们看到trap函数：
```c
void trap(struct trapframe *tf) {
    // dispatch based on what type of trap occurred
    trap_dispatch(tf);
}
```
传入的参数是trapframe结构体指针，这个地址就是给a0的sp。这个结构体在trap.h中定义，内容恰好是36个寄存器，所以这个函数就可以访问栈顶向高地址依次存储的36个寄存器的内容。

trap函数中只有trap_dispatch函数调用，这个函数的定义如下：
```c
static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
    }
}
```
tf->cause被强制转为有符号整数类型，所以最高位起作用（最高位为1，则判断为<0，所以处理中断，否则处理异常）。至于具体的处理过程，我们在报告的其他部分有所涉及，主要是对不同case的识别和处理（各种case是riscv ISA 标准里规定的，我们在riscv.h里定义了这些常量）。

处理结束之后，trap函数也执行完毕，回到trapentry的代码，执行 **__trapret**，调用**RESTORE_ALL**宏，这与SAVE_ALL是相反的顺序，先把栈中的sstatus和sepc寄存器的值保存回寄存器，因为它们直接影响后续执行权限和返回地址。具体而言（下面的过程是在中断、异常处理进行的，也就是修改结构体中的内容，相当于修改了栈上保存的内容，所以恢复得到的是处理后的寄存器值），根据中断或者异常的类型重新设置sepc，确保程序能够从正确的地址继续执行。对于系统调用，这通常是 ecall指令的下一条指令地址（即sepc + 4）；对于中断，这是被中断打断的指令地址（即sepc）；对于进程切换，这是新进程的起始地址。然后，将sstatus.SPP设置为 0，表示要返回到 U 模式。然后恢复通用寄存器，最后恢复栈顶指针寄存器。

这个宏执行结束后，调用**sret**指令，根据sstatus.SPP的值（此时为 0）切换回 U 模式。随后，恢复中断使能状态，将sstatus.SIE恢复为sstatus.SPIE的值。由于在 U 模式下总是使能中断，因此中断会重新开启。接着，更新sstatus，将sstatus.SPIE设置为 1,sstatus.SPP设置为 0，为下一次中断做准备。最后，将sepc的值赋给pc，并跳转回用户程序（sepc指向的地址）继续执行。此时，系统已经安全地从 S 模式返回到 U 模式，用户程序继续执行。

整体的执行流是：set_sbi_timer()通过OpenSBI的时钟事件触发一个中断，CPU 自动读取 stvec，跳转到处理入口，开始执行__alltraps的代码，也就是我们上面大篇幅介绍的内容。至此，我们分析了中断异常的触发、处理流程

## Challenge2：理解上下文切换机制
首先我们分析SAVE_ALL宏中的指令**csrw sscratch, sp**和**csrrw s0, sscratch, x0**的作用。由于宏中需要改变栈顶指针，所以要把原栈顶指针先保存起来。不过栈顶指针不能一直放在sscratch中，所以通过一个交换指令，把sscratch中保存的原栈顶指针给s0寄存器，这样后续的指令 **STORE s0, 2*REGBYTES(sp)** 就可以完成原栈顶的保存。同时sscratch被零寄存器x0覆盖，让它能区分 “当前中断 / 异常是来自内核态”，即使发生 “递归异常” 也不会处理混乱。

接下来我们回答另一个问题：为什么有的寄存器保存在栈中但在RESTORE_ALL中没有恢复：在代码中，sbadaddr和scause没有恢复，而我们恢复了sstatus和sepc，这是因为不同寄存器的功能不同。
1. sstatus 寄存器存储的是 CPU 的核心运行状态，比如SIE位、SPP位等。如果不恢复 sstatus，返回后程序可能进入错误的特权级，或者出现其他混乱，所以sstatus寄存器必须恢复；
1. sepc 寄存器存储的是 “程序被中断/异常打断时的指令地址”，如果不恢复 sepc，sret 会跳转到错误的地址，所以也需要恢复；
1. scause 存储的是当前中断/异常的类型，处理完成之后，不仅没有什么恢复的必要，并且如果恢复旧的 scause，会导致下一次处理逻辑误判；
1. sbadaddr 记录 “本次异常的错误地址”，同样的，不仅没有必要恢复，海=还很有可能扰乱后续的错误定位。

store 是为了保留异常现场供处理时分析（作为tf结构体在代码中使用），不 restore 是因为这些信息仅对本次异常有用，恢复甚至有副作用
## Challenge3：完善异常中断
我们处理过中断的情况，下面我们还需要补充两种异常的情况，分别是**非法指令异常处理**和**断点异常处理**。
非法指令异常处理：
1. 输出指令异常类型（ Illegal instruction）
1. 输出异常指令地址
1. 更新 tf->epc寄存器
断点异常处理：
1. 输出指令异常类型（ breakpoint）
2. 输出异常指令地址
3. 更新 tf->epc寄存器
我们原本代码是这么写的：
```c
    case CAUSE_ILLEGAL_INSTRUCTION:
            cprintf("Exception type:Illegal instruction\n");
            cprintf("Illegal instruction caught at 0x%08x\n", tf->epc);
            tf->epc += 4;
            break;
    case CAUSE_BREAKPOINT:
            cprintf("Exception type: breakpoint\n");
            cprintf("ebreak caught at 0x%08x\n", tf->epc);
            tf->epc += 4;
            break;
```
我们要注意，存放异常指令地址的寄存器为epc寄存器。我们认为，由于RISC-V指令长度固定为4字节，+4的原因是要跳过当前的异常指令，但测试ebreak过程中出现了无穷的输出，似乎是epc一直在递增，然后一直报异常，这只有可能是epc的处理不到位。经查询,RISC-V有两字节压缩指令，所以我们最好做一层判断，代码如下：
```c
uint16_t instr = *(uint16_t *)tf->epc;
switch...
...
    if ((instr & 0x03) != 0x03) 
        tf->epc+=2;  // 压缩指令，2字节
    else tf->epc+=4;  
```
4 字节指令最低 2 位固定为 11，便于硬件识别，我们利用这一特性进行判断。最后，我们写入断点指令和非法指令进行验证：
```c
__asm__ __volatile__("ebreak");  // RISC-V 断点指令
__asm__ __volatile__ (".word 0xdeadbfff");
```
结果如下：
```
Exception type: breakpoint
ebreak caught at 0xc020009c
Exception type:Illegal instruction
Illegal instruction caught at 0xc020009e
```
之后我们还尝试了mret，由于只能在M mode执行，所以也可以触发非法指令异常。但似乎有一部分指令无法正确处理（比如0xdeadbeef）,具体原因有待进一步研究。

## 与理论课的联系
宫老师在讲进程调度时，举了音乐播放器的例子，即播放一段时间音乐后遇到时间中断，会修改时间片。很显然，时间片不会存在用户态的数据中，这样大概率会被你修改，所以存在特权态数据中，这就涉及权限提升了。这是老师就提到了中断发生、中断向量表、特权提升等知识，与我们的实验内容契合。并且中断返回时，要注意特权收回，忘记回收特权会导致系统安全问题。

此外，老师还讲到了中断和异常的区别，异常可以打断指令的执行，而中断总是在某一条指令已经执行完了之后再发生。这也就对应我们实验中的“中断为异步、异常为同步”的知识点。