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
                if(PRINT_COUNT==10) 
                    sbi_shutdown();
                if(ticks%TICK_NUM==0)
                {   
                    print_ticks();
                    PRINT_COUNT++;
                }
                
                break;
```
设置时钟中断采用**clock_set_next_event()**，这个函数在clock.c中实现：
```c
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
```
使用了sbi中的接口，基本逻辑是timer的数值变为当前时间 + timebase 后，触发一次时钟中断。在代码中，已经定义了timebase=100000,对于QEMU, timer增加1，过去了10^-7 s， 也就是100ns，所以单次中断的时间间隔是0.01s，那么100次大约就是1s。我们的结果也是1s输出一次"100ticks"。至于停止，我设置了一个全局变量**PRINT_COUNT**，每次打印加1，10次打印之后，调用sbi.h中提供的接口**sbi_shutdown()**，关闭机器。

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
代码如下：
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
我们要注意，存放异常指令地址的寄存器为epc寄存器。