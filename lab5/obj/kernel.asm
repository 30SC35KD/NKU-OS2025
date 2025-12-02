
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	0000b297          	auipc	t0,0xb
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc020b000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	0000b297          	auipc	t0,0xb
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc020b008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c020a2b7          	lui	t0,0xc020a
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c020a137          	lui	sp,0xc020a

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	04a28293          	addi	t0,t0,74 # ffffffffc020004a <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <kern_init>:
void grade_backtrace(void);

int kern_init(void)
{
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc020004a:	000a6517          	auipc	a0,0xa6
ffffffffc020004e:	21e50513          	addi	a0,a0,542 # ffffffffc02a6268 <buf>
ffffffffc0200052:	000aa617          	auipc	a2,0xaa
ffffffffc0200056:	6ba60613          	addi	a2,a2,1722 # ffffffffc02aa70c <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	5a8050ef          	jal	ra,ffffffffc020560a <memset>
    dtb_init();
ffffffffc0200066:	598000ef          	jal	ra,ffffffffc02005fe <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	522000ef          	jal	ra,ffffffffc020058c <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00005597          	auipc	a1,0x5
ffffffffc0200072:	5ca58593          	addi	a1,a1,1482 # ffffffffc0205638 <etext+0x4>
ffffffffc0200076:	00005517          	auipc	a0,0x5
ffffffffc020007a:	5e250513          	addi	a0,a0,1506 # ffffffffc0205658 <etext+0x24>
ffffffffc020007e:	116000ef          	jal	ra,ffffffffc0200194 <cprintf>

    print_kerninfo();
ffffffffc0200082:	19a000ef          	jal	ra,ffffffffc020021c <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	674020ef          	jal	ra,ffffffffc02026fa <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	131000ef          	jal	ra,ffffffffc02009ba <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	12f000ef          	jal	ra,ffffffffc02009bc <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc0200092:	11f030ef          	jal	ra,ffffffffc02039b0 <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	4c7040ef          	jal	ra,ffffffffc0204d5c <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	4a0000ef          	jal	ra,ffffffffc020053a <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	111000ef          	jal	ra,ffffffffc02009ae <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	653040ef          	jal	ra,ffffffffc0204ef4 <cpu_idle>

ffffffffc02000a6 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02000a6:	715d                	addi	sp,sp,-80
ffffffffc02000a8:	e486                	sd	ra,72(sp)
ffffffffc02000aa:	e0a6                	sd	s1,64(sp)
ffffffffc02000ac:	fc4a                	sd	s2,56(sp)
ffffffffc02000ae:	f84e                	sd	s3,48(sp)
ffffffffc02000b0:	f452                	sd	s4,40(sp)
ffffffffc02000b2:	f056                	sd	s5,32(sp)
ffffffffc02000b4:	ec5a                	sd	s6,24(sp)
ffffffffc02000b6:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc02000b8:	c901                	beqz	a0,ffffffffc02000c8 <readline+0x22>
ffffffffc02000ba:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc02000bc:	00005517          	auipc	a0,0x5
ffffffffc02000c0:	5a450513          	addi	a0,a0,1444 # ffffffffc0205660 <etext+0x2c>
ffffffffc02000c4:	0d0000ef          	jal	ra,ffffffffc0200194 <cprintf>
readline(const char *prompt) {
ffffffffc02000c8:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000ca:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000cc:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000ce:	4aa9                	li	s5,10
ffffffffc02000d0:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02000d2:	000a6b97          	auipc	s7,0xa6
ffffffffc02000d6:	196b8b93          	addi	s7,s7,406 # ffffffffc02a6268 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000da:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02000de:	12e000ef          	jal	ra,ffffffffc020020c <getchar>
        if (c < 0) {
ffffffffc02000e2:	00054a63          	bltz	a0,ffffffffc02000f6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000e6:	00a95a63          	bge	s2,a0,ffffffffc02000fa <readline+0x54>
ffffffffc02000ea:	029a5263          	bge	s4,s1,ffffffffc020010e <readline+0x68>
        c = getchar();
ffffffffc02000ee:	11e000ef          	jal	ra,ffffffffc020020c <getchar>
        if (c < 0) {
ffffffffc02000f2:	fe055ae3          	bgez	a0,ffffffffc02000e6 <readline+0x40>
            return NULL;
ffffffffc02000f6:	4501                	li	a0,0
ffffffffc02000f8:	a091                	j	ffffffffc020013c <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc02000fa:	03351463          	bne	a0,s3,ffffffffc0200122 <readline+0x7c>
ffffffffc02000fe:	e8a9                	bnez	s1,ffffffffc0200150 <readline+0xaa>
        c = getchar();
ffffffffc0200100:	10c000ef          	jal	ra,ffffffffc020020c <getchar>
        if (c < 0) {
ffffffffc0200104:	fe0549e3          	bltz	a0,ffffffffc02000f6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200108:	fea959e3          	bge	s2,a0,ffffffffc02000fa <readline+0x54>
ffffffffc020010c:	4481                	li	s1,0
            cputchar(c);
ffffffffc020010e:	e42a                	sd	a0,8(sp)
ffffffffc0200110:	0ba000ef          	jal	ra,ffffffffc02001ca <cputchar>
            buf[i ++] = c;
ffffffffc0200114:	6522                	ld	a0,8(sp)
ffffffffc0200116:	009b87b3          	add	a5,s7,s1
ffffffffc020011a:	2485                	addiw	s1,s1,1
ffffffffc020011c:	00a78023          	sb	a0,0(a5)
ffffffffc0200120:	bf7d                	j	ffffffffc02000de <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0200122:	01550463          	beq	a0,s5,ffffffffc020012a <readline+0x84>
ffffffffc0200126:	fb651ce3          	bne	a0,s6,ffffffffc02000de <readline+0x38>
            cputchar(c);
ffffffffc020012a:	0a0000ef          	jal	ra,ffffffffc02001ca <cputchar>
            buf[i] = '\0';
ffffffffc020012e:	000a6517          	auipc	a0,0xa6
ffffffffc0200132:	13a50513          	addi	a0,a0,314 # ffffffffc02a6268 <buf>
ffffffffc0200136:	94aa                	add	s1,s1,a0
ffffffffc0200138:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc020013c:	60a6                	ld	ra,72(sp)
ffffffffc020013e:	6486                	ld	s1,64(sp)
ffffffffc0200140:	7962                	ld	s2,56(sp)
ffffffffc0200142:	79c2                	ld	s3,48(sp)
ffffffffc0200144:	7a22                	ld	s4,40(sp)
ffffffffc0200146:	7a82                	ld	s5,32(sp)
ffffffffc0200148:	6b62                	ld	s6,24(sp)
ffffffffc020014a:	6bc2                	ld	s7,16(sp)
ffffffffc020014c:	6161                	addi	sp,sp,80
ffffffffc020014e:	8082                	ret
            cputchar(c);
ffffffffc0200150:	4521                	li	a0,8
ffffffffc0200152:	078000ef          	jal	ra,ffffffffc02001ca <cputchar>
            i --;
ffffffffc0200156:	34fd                	addiw	s1,s1,-1
ffffffffc0200158:	b759                	j	ffffffffc02000de <readline+0x38>

ffffffffc020015a <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt)
{
ffffffffc020015a:	1141                	addi	sp,sp,-16
ffffffffc020015c:	e022                	sd	s0,0(sp)
ffffffffc020015e:	e406                	sd	ra,8(sp)
ffffffffc0200160:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200162:	42c000ef          	jal	ra,ffffffffc020058e <cons_putc>
    (*cnt)++;
ffffffffc0200166:	401c                	lw	a5,0(s0)
}
ffffffffc0200168:	60a2                	ld	ra,8(sp)
    (*cnt)++;
ffffffffc020016a:	2785                	addiw	a5,a5,1
ffffffffc020016c:	c01c                	sw	a5,0(s0)
}
ffffffffc020016e:	6402                	ld	s0,0(sp)
ffffffffc0200170:	0141                	addi	sp,sp,16
ffffffffc0200172:	8082                	ret

ffffffffc0200174 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap)
{
ffffffffc0200174:	1101                	addi	sp,sp,-32
ffffffffc0200176:	862a                	mv	a2,a0
ffffffffc0200178:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020017a:	00000517          	auipc	a0,0x0
ffffffffc020017e:	fe050513          	addi	a0,a0,-32 # ffffffffc020015a <cputch>
ffffffffc0200182:	006c                	addi	a1,sp,12
{
ffffffffc0200184:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200186:	c602                	sw	zero,12(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc0200188:	05e050ef          	jal	ra,ffffffffc02051e6 <vprintfmt>
    return cnt;
}
ffffffffc020018c:	60e2                	ld	ra,24(sp)
ffffffffc020018e:	4532                	lw	a0,12(sp)
ffffffffc0200190:	6105                	addi	sp,sp,32
ffffffffc0200192:	8082                	ret

ffffffffc0200194 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...)
{
ffffffffc0200194:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200196:	02810313          	addi	t1,sp,40 # ffffffffc020a028 <boot_page_table_sv39+0x28>
{
ffffffffc020019a:	8e2a                	mv	t3,a0
ffffffffc020019c:	f42e                	sd	a1,40(sp)
ffffffffc020019e:	f832                	sd	a2,48(sp)
ffffffffc02001a0:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001a2:	00000517          	auipc	a0,0x0
ffffffffc02001a6:	fb850513          	addi	a0,a0,-72 # ffffffffc020015a <cputch>
ffffffffc02001aa:	004c                	addi	a1,sp,4
ffffffffc02001ac:	869a                	mv	a3,t1
ffffffffc02001ae:	8672                	mv	a2,t3
{
ffffffffc02001b0:	ec06                	sd	ra,24(sp)
ffffffffc02001b2:	e0ba                	sd	a4,64(sp)
ffffffffc02001b4:	e4be                	sd	a5,72(sp)
ffffffffc02001b6:	e8c2                	sd	a6,80(sp)
ffffffffc02001b8:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02001ba:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02001bc:	c202                	sw	zero,4(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001be:	028050ef          	jal	ra,ffffffffc02051e6 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001c2:	60e2                	ld	ra,24(sp)
ffffffffc02001c4:	4512                	lw	a0,4(sp)
ffffffffc02001c6:	6125                	addi	sp,sp,96
ffffffffc02001c8:	8082                	ret

ffffffffc02001ca <cputchar>:

/* cputchar - writes a single character to stdout */
void cputchar(int c)
{
    cons_putc(c);
ffffffffc02001ca:	a6d1                	j	ffffffffc020058e <cons_putc>

ffffffffc02001cc <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int cputs(const char *str)
{
ffffffffc02001cc:	1101                	addi	sp,sp,-32
ffffffffc02001ce:	e822                	sd	s0,16(sp)
ffffffffc02001d0:	ec06                	sd	ra,24(sp)
ffffffffc02001d2:	e426                	sd	s1,8(sp)
ffffffffc02001d4:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str++) != '\0')
ffffffffc02001d6:	00054503          	lbu	a0,0(a0)
ffffffffc02001da:	c51d                	beqz	a0,ffffffffc0200208 <cputs+0x3c>
ffffffffc02001dc:	0405                	addi	s0,s0,1
ffffffffc02001de:	4485                	li	s1,1
ffffffffc02001e0:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc02001e2:	3ac000ef          	jal	ra,ffffffffc020058e <cons_putc>
    while ((c = *str++) != '\0')
ffffffffc02001e6:	00044503          	lbu	a0,0(s0)
ffffffffc02001ea:	008487bb          	addw	a5,s1,s0
ffffffffc02001ee:	0405                	addi	s0,s0,1
ffffffffc02001f0:	f96d                	bnez	a0,ffffffffc02001e2 <cputs+0x16>
    (*cnt)++;
ffffffffc02001f2:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001f6:	4529                	li	a0,10
ffffffffc02001f8:	396000ef          	jal	ra,ffffffffc020058e <cons_putc>
    {
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001fc:	60e2                	ld	ra,24(sp)
ffffffffc02001fe:	8522                	mv	a0,s0
ffffffffc0200200:	6442                	ld	s0,16(sp)
ffffffffc0200202:	64a2                	ld	s1,8(sp)
ffffffffc0200204:	6105                	addi	sp,sp,32
ffffffffc0200206:	8082                	ret
    while ((c = *str++) != '\0')
ffffffffc0200208:	4405                	li	s0,1
ffffffffc020020a:	b7f5                	j	ffffffffc02001f6 <cputs+0x2a>

ffffffffc020020c <getchar>:

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc020020c:	1141                	addi	sp,sp,-16
ffffffffc020020e:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200210:	3b2000ef          	jal	ra,ffffffffc02005c2 <cons_getc>
ffffffffc0200214:	dd75                	beqz	a0,ffffffffc0200210 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200216:	60a2                	ld	ra,8(sp)
ffffffffc0200218:	0141                	addi	sp,sp,16
ffffffffc020021a:	8082                	ret

ffffffffc020021c <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void)
{
ffffffffc020021c:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc020021e:	00005517          	auipc	a0,0x5
ffffffffc0200222:	44a50513          	addi	a0,a0,1098 # ffffffffc0205668 <etext+0x34>
{
ffffffffc0200226:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200228:	f6dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc020022c:	00000597          	auipc	a1,0x0
ffffffffc0200230:	e1e58593          	addi	a1,a1,-482 # ffffffffc020004a <kern_init>
ffffffffc0200234:	00005517          	auipc	a0,0x5
ffffffffc0200238:	45450513          	addi	a0,a0,1108 # ffffffffc0205688 <etext+0x54>
ffffffffc020023c:	f59ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200240:	00005597          	auipc	a1,0x5
ffffffffc0200244:	3f458593          	addi	a1,a1,1012 # ffffffffc0205634 <etext>
ffffffffc0200248:	00005517          	auipc	a0,0x5
ffffffffc020024c:	46050513          	addi	a0,a0,1120 # ffffffffc02056a8 <etext+0x74>
ffffffffc0200250:	f45ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200254:	000a6597          	auipc	a1,0xa6
ffffffffc0200258:	01458593          	addi	a1,a1,20 # ffffffffc02a6268 <buf>
ffffffffc020025c:	00005517          	auipc	a0,0x5
ffffffffc0200260:	46c50513          	addi	a0,a0,1132 # ffffffffc02056c8 <etext+0x94>
ffffffffc0200264:	f31ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200268:	000aa597          	auipc	a1,0xaa
ffffffffc020026c:	4a458593          	addi	a1,a1,1188 # ffffffffc02aa70c <end>
ffffffffc0200270:	00005517          	auipc	a0,0x5
ffffffffc0200274:	47850513          	addi	a0,a0,1144 # ffffffffc02056e8 <etext+0xb4>
ffffffffc0200278:	f1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020027c:	000ab597          	auipc	a1,0xab
ffffffffc0200280:	88f58593          	addi	a1,a1,-1905 # ffffffffc02aab0b <end+0x3ff>
ffffffffc0200284:	00000797          	auipc	a5,0x0
ffffffffc0200288:	dc678793          	addi	a5,a5,-570 # ffffffffc020004a <kern_init>
ffffffffc020028c:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200290:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200294:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200296:	3ff5f593          	andi	a1,a1,1023
ffffffffc020029a:	95be                	add	a1,a1,a5
ffffffffc020029c:	85a9                	srai	a1,a1,0xa
ffffffffc020029e:	00005517          	auipc	a0,0x5
ffffffffc02002a2:	46a50513          	addi	a0,a0,1130 # ffffffffc0205708 <etext+0xd4>
}
ffffffffc02002a6:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002a8:	b5f5                	j	ffffffffc0200194 <cprintf>

ffffffffc02002aa <print_stackframe>:
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void)
{
ffffffffc02002aa:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02002ac:	00005617          	auipc	a2,0x5
ffffffffc02002b0:	48c60613          	addi	a2,a2,1164 # ffffffffc0205738 <etext+0x104>
ffffffffc02002b4:	04f00593          	li	a1,79
ffffffffc02002b8:	00005517          	auipc	a0,0x5
ffffffffc02002bc:	49850513          	addi	a0,a0,1176 # ffffffffc0205750 <etext+0x11c>
{
ffffffffc02002c0:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002c2:	1cc000ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02002c6 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int mon_help(int argc, char **argv, struct trapframe *tf)
{
ffffffffc02002c6:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i++)
    {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002c8:	00005617          	auipc	a2,0x5
ffffffffc02002cc:	4a060613          	addi	a2,a2,1184 # ffffffffc0205768 <etext+0x134>
ffffffffc02002d0:	00005597          	auipc	a1,0x5
ffffffffc02002d4:	4b858593          	addi	a1,a1,1208 # ffffffffc0205788 <etext+0x154>
ffffffffc02002d8:	00005517          	auipc	a0,0x5
ffffffffc02002dc:	4b850513          	addi	a0,a0,1208 # ffffffffc0205790 <etext+0x15c>
{
ffffffffc02002e0:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002e2:	eb3ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc02002e6:	00005617          	auipc	a2,0x5
ffffffffc02002ea:	4ba60613          	addi	a2,a2,1210 # ffffffffc02057a0 <etext+0x16c>
ffffffffc02002ee:	00005597          	auipc	a1,0x5
ffffffffc02002f2:	4da58593          	addi	a1,a1,1242 # ffffffffc02057c8 <etext+0x194>
ffffffffc02002f6:	00005517          	auipc	a0,0x5
ffffffffc02002fa:	49a50513          	addi	a0,a0,1178 # ffffffffc0205790 <etext+0x15c>
ffffffffc02002fe:	e97ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0200302:	00005617          	auipc	a2,0x5
ffffffffc0200306:	4d660613          	addi	a2,a2,1238 # ffffffffc02057d8 <etext+0x1a4>
ffffffffc020030a:	00005597          	auipc	a1,0x5
ffffffffc020030e:	4ee58593          	addi	a1,a1,1262 # ffffffffc02057f8 <etext+0x1c4>
ffffffffc0200312:	00005517          	auipc	a0,0x5
ffffffffc0200316:	47e50513          	addi	a0,a0,1150 # ffffffffc0205790 <etext+0x15c>
ffffffffc020031a:	e7bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    return 0;
}
ffffffffc020031e:	60a2                	ld	ra,8(sp)
ffffffffc0200320:	4501                	li	a0,0
ffffffffc0200322:	0141                	addi	sp,sp,16
ffffffffc0200324:	8082                	ret

ffffffffc0200326 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int mon_kerninfo(int argc, char **argv, struct trapframe *tf)
{
ffffffffc0200326:	1141                	addi	sp,sp,-16
ffffffffc0200328:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020032a:	ef3ff0ef          	jal	ra,ffffffffc020021c <print_kerninfo>
    return 0;
}
ffffffffc020032e:	60a2                	ld	ra,8(sp)
ffffffffc0200330:	4501                	li	a0,0
ffffffffc0200332:	0141                	addi	sp,sp,16
ffffffffc0200334:	8082                	ret

ffffffffc0200336 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int mon_backtrace(int argc, char **argv, struct trapframe *tf)
{
ffffffffc0200336:	1141                	addi	sp,sp,-16
ffffffffc0200338:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020033a:	f71ff0ef          	jal	ra,ffffffffc02002aa <print_stackframe>
    return 0;
}
ffffffffc020033e:	60a2                	ld	ra,8(sp)
ffffffffc0200340:	4501                	li	a0,0
ffffffffc0200342:	0141                	addi	sp,sp,16
ffffffffc0200344:	8082                	ret

ffffffffc0200346 <kmonitor>:
{
ffffffffc0200346:	7115                	addi	sp,sp,-224
ffffffffc0200348:	ed5e                	sd	s7,152(sp)
ffffffffc020034a:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020034c:	00005517          	auipc	a0,0x5
ffffffffc0200350:	4bc50513          	addi	a0,a0,1212 # ffffffffc0205808 <etext+0x1d4>
{
ffffffffc0200354:	ed86                	sd	ra,216(sp)
ffffffffc0200356:	e9a2                	sd	s0,208(sp)
ffffffffc0200358:	e5a6                	sd	s1,200(sp)
ffffffffc020035a:	e1ca                	sd	s2,192(sp)
ffffffffc020035c:	fd4e                	sd	s3,184(sp)
ffffffffc020035e:	f952                	sd	s4,176(sp)
ffffffffc0200360:	f556                	sd	s5,168(sp)
ffffffffc0200362:	f15a                	sd	s6,160(sp)
ffffffffc0200364:	e962                	sd	s8,144(sp)
ffffffffc0200366:	e566                	sd	s9,136(sp)
ffffffffc0200368:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020036a:	e2bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020036e:	00005517          	auipc	a0,0x5
ffffffffc0200372:	4c250513          	addi	a0,a0,1218 # ffffffffc0205830 <etext+0x1fc>
ffffffffc0200376:	e1fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    if (tf != NULL)
ffffffffc020037a:	000b8563          	beqz	s7,ffffffffc0200384 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020037e:	855e                	mv	a0,s7
ffffffffc0200380:	025000ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
ffffffffc0200384:	00005c17          	auipc	s8,0x5
ffffffffc0200388:	51cc0c13          	addi	s8,s8,1308 # ffffffffc02058a0 <commands>
        if ((buf = readline("K> ")) != NULL)
ffffffffc020038c:	00005917          	auipc	s2,0x5
ffffffffc0200390:	4cc90913          	addi	s2,s2,1228 # ffffffffc0205858 <etext+0x224>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200394:	00005497          	auipc	s1,0x5
ffffffffc0200398:	4cc48493          	addi	s1,s1,1228 # ffffffffc0205860 <etext+0x22c>
        if (argc == MAXARGS - 1)
ffffffffc020039c:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020039e:	00005b17          	auipc	s6,0x5
ffffffffc02003a2:	4cab0b13          	addi	s6,s6,1226 # ffffffffc0205868 <etext+0x234>
        argv[argc++] = buf;
ffffffffc02003a6:	00005a17          	auipc	s4,0x5
ffffffffc02003aa:	3e2a0a13          	addi	s4,s4,994 # ffffffffc0205788 <etext+0x154>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003ae:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL)
ffffffffc02003b0:	854a                	mv	a0,s2
ffffffffc02003b2:	cf5ff0ef          	jal	ra,ffffffffc02000a6 <readline>
ffffffffc02003b6:	842a                	mv	s0,a0
ffffffffc02003b8:	dd65                	beqz	a0,ffffffffc02003b0 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc02003ba:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02003be:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc02003c0:	e1bd                	bnez	a1,ffffffffc0200426 <kmonitor+0xe0>
    if (argc == 0)
ffffffffc02003c2:	fe0c87e3          	beqz	s9,ffffffffc02003b0 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003c6:	6582                	ld	a1,0(sp)
ffffffffc02003c8:	00005d17          	auipc	s10,0x5
ffffffffc02003cc:	4d8d0d13          	addi	s10,s10,1240 # ffffffffc02058a0 <commands>
        argv[argc++] = buf;
ffffffffc02003d0:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003d2:	4401                	li	s0,0
ffffffffc02003d4:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003d6:	1da050ef          	jal	ra,ffffffffc02055b0 <strcmp>
ffffffffc02003da:	c919                	beqz	a0,ffffffffc02003f0 <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003dc:	2405                	addiw	s0,s0,1
ffffffffc02003de:	0b540063          	beq	s0,s5,ffffffffc020047e <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003e2:	000d3503          	ld	a0,0(s10)
ffffffffc02003e6:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003e8:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003ea:	1c6050ef          	jal	ra,ffffffffc02055b0 <strcmp>
ffffffffc02003ee:	f57d                	bnez	a0,ffffffffc02003dc <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003f0:	00141793          	slli	a5,s0,0x1
ffffffffc02003f4:	97a2                	add	a5,a5,s0
ffffffffc02003f6:	078e                	slli	a5,a5,0x3
ffffffffc02003f8:	97e2                	add	a5,a5,s8
ffffffffc02003fa:	6b9c                	ld	a5,16(a5)
ffffffffc02003fc:	865e                	mv	a2,s7
ffffffffc02003fe:	002c                	addi	a1,sp,8
ffffffffc0200400:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200404:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0)
ffffffffc0200406:	fa0555e3          	bgez	a0,ffffffffc02003b0 <kmonitor+0x6a>
}
ffffffffc020040a:	60ee                	ld	ra,216(sp)
ffffffffc020040c:	644e                	ld	s0,208(sp)
ffffffffc020040e:	64ae                	ld	s1,200(sp)
ffffffffc0200410:	690e                	ld	s2,192(sp)
ffffffffc0200412:	79ea                	ld	s3,184(sp)
ffffffffc0200414:	7a4a                	ld	s4,176(sp)
ffffffffc0200416:	7aaa                	ld	s5,168(sp)
ffffffffc0200418:	7b0a                	ld	s6,160(sp)
ffffffffc020041a:	6bea                	ld	s7,152(sp)
ffffffffc020041c:	6c4a                	ld	s8,144(sp)
ffffffffc020041e:	6caa                	ld	s9,136(sp)
ffffffffc0200420:	6d0a                	ld	s10,128(sp)
ffffffffc0200422:	612d                	addi	sp,sp,224
ffffffffc0200424:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200426:	8526                	mv	a0,s1
ffffffffc0200428:	1cc050ef          	jal	ra,ffffffffc02055f4 <strchr>
ffffffffc020042c:	c901                	beqz	a0,ffffffffc020043c <kmonitor+0xf6>
ffffffffc020042e:	00144583          	lbu	a1,1(s0)
            *buf++ = '\0';
ffffffffc0200432:	00040023          	sb	zero,0(s0)
ffffffffc0200436:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200438:	d5c9                	beqz	a1,ffffffffc02003c2 <kmonitor+0x7c>
ffffffffc020043a:	b7f5                	j	ffffffffc0200426 <kmonitor+0xe0>
        if (*buf == '\0')
ffffffffc020043c:	00044783          	lbu	a5,0(s0)
ffffffffc0200440:	d3c9                	beqz	a5,ffffffffc02003c2 <kmonitor+0x7c>
        if (argc == MAXARGS - 1)
ffffffffc0200442:	033c8963          	beq	s9,s3,ffffffffc0200474 <kmonitor+0x12e>
        argv[argc++] = buf;
ffffffffc0200446:	003c9793          	slli	a5,s9,0x3
ffffffffc020044a:	0118                	addi	a4,sp,128
ffffffffc020044c:	97ba                	add	a5,a5,a4
ffffffffc020044e:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc0200452:	00044583          	lbu	a1,0(s0)
        argv[argc++] = buf;
ffffffffc0200456:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc0200458:	e591                	bnez	a1,ffffffffc0200464 <kmonitor+0x11e>
ffffffffc020045a:	b7b5                	j	ffffffffc02003c6 <kmonitor+0x80>
ffffffffc020045c:	00144583          	lbu	a1,1(s0)
            buf++;
ffffffffc0200460:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc0200462:	d1a5                	beqz	a1,ffffffffc02003c2 <kmonitor+0x7c>
ffffffffc0200464:	8526                	mv	a0,s1
ffffffffc0200466:	18e050ef          	jal	ra,ffffffffc02055f4 <strchr>
ffffffffc020046a:	d96d                	beqz	a0,ffffffffc020045c <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc020046c:	00044583          	lbu	a1,0(s0)
ffffffffc0200470:	d9a9                	beqz	a1,ffffffffc02003c2 <kmonitor+0x7c>
ffffffffc0200472:	bf55                	j	ffffffffc0200426 <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200474:	45c1                	li	a1,16
ffffffffc0200476:	855a                	mv	a0,s6
ffffffffc0200478:	d1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc020047c:	b7e9                	j	ffffffffc0200446 <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020047e:	6582                	ld	a1,0(sp)
ffffffffc0200480:	00005517          	auipc	a0,0x5
ffffffffc0200484:	40850513          	addi	a0,a0,1032 # ffffffffc0205888 <etext+0x254>
ffffffffc0200488:	d0dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
ffffffffc020048c:	b715                	j	ffffffffc02003b0 <kmonitor+0x6a>

ffffffffc020048e <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void __panic(const char *file, int line, const char *fmt, ...)
{
    if (is_panic)
ffffffffc020048e:	000aa317          	auipc	t1,0xaa
ffffffffc0200492:	20230313          	addi	t1,t1,514 # ffffffffc02aa690 <is_panic>
ffffffffc0200496:	00033e03          	ld	t3,0(t1)
{
ffffffffc020049a:	715d                	addi	sp,sp,-80
ffffffffc020049c:	ec06                	sd	ra,24(sp)
ffffffffc020049e:	e822                	sd	s0,16(sp)
ffffffffc02004a0:	f436                	sd	a3,40(sp)
ffffffffc02004a2:	f83a                	sd	a4,48(sp)
ffffffffc02004a4:	fc3e                	sd	a5,56(sp)
ffffffffc02004a6:	e0c2                	sd	a6,64(sp)
ffffffffc02004a8:	e4c6                	sd	a7,72(sp)
    if (is_panic)
ffffffffc02004aa:	020e1a63          	bnez	t3,ffffffffc02004de <__panic+0x50>
    {
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02004ae:	4785                	li	a5,1
ffffffffc02004b0:	00f33023          	sd	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02004b4:	8432                	mv	s0,a2
ffffffffc02004b6:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004b8:	862e                	mv	a2,a1
ffffffffc02004ba:	85aa                	mv	a1,a0
ffffffffc02004bc:	00005517          	auipc	a0,0x5
ffffffffc02004c0:	42c50513          	addi	a0,a0,1068 # ffffffffc02058e8 <commands+0x48>
    va_start(ap, fmt);
ffffffffc02004c4:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004c6:	ccfff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02004ca:	65a2                	ld	a1,8(sp)
ffffffffc02004cc:	8522                	mv	a0,s0
ffffffffc02004ce:	ca7ff0ef          	jal	ra,ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc02004d2:	00006517          	auipc	a0,0x6
ffffffffc02004d6:	50e50513          	addi	a0,a0,1294 # ffffffffc02069e0 <default_pmm_manager+0x578>
ffffffffc02004da:	cbbff0ef          	jal	ra,ffffffffc0200194 <cprintf>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc02004de:	4501                	li	a0,0
ffffffffc02004e0:	4581                	li	a1,0
ffffffffc02004e2:	4601                	li	a2,0
ffffffffc02004e4:	48a1                	li	a7,8
ffffffffc02004e6:	00000073          	ecall
    va_end(ap);

panic_dead:
    // No debug monitor here
    sbi_shutdown();
    intr_disable();
ffffffffc02004ea:	4ca000ef          	jal	ra,ffffffffc02009b4 <intr_disable>
    while (1)
    {
        kmonitor(NULL);
ffffffffc02004ee:	4501                	li	a0,0
ffffffffc02004f0:	e57ff0ef          	jal	ra,ffffffffc0200346 <kmonitor>
    while (1)
ffffffffc02004f4:	bfed                	j	ffffffffc02004ee <__panic+0x60>

ffffffffc02004f6 <__warn>:
    }
}

/* __warn - like panic, but don't */
void __warn(const char *file, int line, const char *fmt, ...)
{
ffffffffc02004f6:	715d                	addi	sp,sp,-80
ffffffffc02004f8:	832e                	mv	t1,a1
ffffffffc02004fa:	e822                	sd	s0,16(sp)
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004fc:	85aa                	mv	a1,a0
{
ffffffffc02004fe:	8432                	mv	s0,a2
ffffffffc0200500:	fc3e                	sd	a5,56(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200502:	861a                	mv	a2,t1
    va_start(ap, fmt);
ffffffffc0200504:	103c                	addi	a5,sp,40
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200506:	00005517          	auipc	a0,0x5
ffffffffc020050a:	40250513          	addi	a0,a0,1026 # ffffffffc0205908 <commands+0x68>
{
ffffffffc020050e:	ec06                	sd	ra,24(sp)
ffffffffc0200510:	f436                	sd	a3,40(sp)
ffffffffc0200512:	f83a                	sd	a4,48(sp)
ffffffffc0200514:	e0c2                	sd	a6,64(sp)
ffffffffc0200516:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0200518:	e43e                	sd	a5,8(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc020051a:	c7bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc020051e:	65a2                	ld	a1,8(sp)
ffffffffc0200520:	8522                	mv	a0,s0
ffffffffc0200522:	c53ff0ef          	jal	ra,ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc0200526:	00006517          	auipc	a0,0x6
ffffffffc020052a:	4ba50513          	addi	a0,a0,1210 # ffffffffc02069e0 <default_pmm_manager+0x578>
ffffffffc020052e:	c67ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    va_end(ap);
}
ffffffffc0200532:	60e2                	ld	ra,24(sp)
ffffffffc0200534:	6442                	ld	s0,16(sp)
ffffffffc0200536:	6161                	addi	sp,sp,80
ffffffffc0200538:	8082                	ret

ffffffffc020053a <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc020053a:	67e1                	lui	a5,0x18
ffffffffc020053c:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_exit_out_size+0xd580>
ffffffffc0200540:	000aa717          	auipc	a4,0xaa
ffffffffc0200544:	16f73023          	sd	a5,352(a4) # ffffffffc02aa6a0 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200548:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc020054c:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020054e:	953e                	add	a0,a0,a5
ffffffffc0200550:	4601                	li	a2,0
ffffffffc0200552:	4881                	li	a7,0
ffffffffc0200554:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc0200558:	02000793          	li	a5,32
ffffffffc020055c:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc0200560:	00005517          	auipc	a0,0x5
ffffffffc0200564:	3c850513          	addi	a0,a0,968 # ffffffffc0205928 <commands+0x88>
    ticks = 0;
ffffffffc0200568:	000aa797          	auipc	a5,0xaa
ffffffffc020056c:	1207b823          	sd	zero,304(a5) # ffffffffc02aa698 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200570:	b115                	j	ffffffffc0200194 <cprintf>

ffffffffc0200572 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200572:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200576:	000aa797          	auipc	a5,0xaa
ffffffffc020057a:	12a7b783          	ld	a5,298(a5) # ffffffffc02aa6a0 <timebase>
ffffffffc020057e:	953e                	add	a0,a0,a5
ffffffffc0200580:	4581                	li	a1,0
ffffffffc0200582:	4601                	li	a2,0
ffffffffc0200584:	4881                	li	a7,0
ffffffffc0200586:	00000073          	ecall
ffffffffc020058a:	8082                	ret

ffffffffc020058c <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020058c:	8082                	ret

ffffffffc020058e <cons_putc>:
#include <riscv.h>
#include <assert.h>

static inline bool __intr_save(void)
{
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020058e:	100027f3          	csrr	a5,sstatus
ffffffffc0200592:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc0200594:	0ff57513          	zext.b	a0,a0
ffffffffc0200598:	e799                	bnez	a5,ffffffffc02005a6 <cons_putc+0x18>
ffffffffc020059a:	4581                	li	a1,0
ffffffffc020059c:	4601                	li	a2,0
ffffffffc020059e:	4885                	li	a7,1
ffffffffc02005a0:	00000073          	ecall
    return 0;
}

static inline void __intr_restore(bool flag)
{
    if (flag)
ffffffffc02005a4:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc02005a6:	1101                	addi	sp,sp,-32
ffffffffc02005a8:	ec06                	sd	ra,24(sp)
ffffffffc02005aa:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02005ac:	408000ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02005b0:	6522                	ld	a0,8(sp)
ffffffffc02005b2:	4581                	li	a1,0
ffffffffc02005b4:	4601                	li	a2,0
ffffffffc02005b6:	4885                	li	a7,1
ffffffffc02005b8:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc02005bc:	60e2                	ld	ra,24(sp)
ffffffffc02005be:	6105                	addi	sp,sp,32
    {
        intr_enable();
ffffffffc02005c0:	a6fd                	j	ffffffffc02009ae <intr_enable>

ffffffffc02005c2 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02005c2:	100027f3          	csrr	a5,sstatus
ffffffffc02005c6:	8b89                	andi	a5,a5,2
ffffffffc02005c8:	eb89                	bnez	a5,ffffffffc02005da <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc02005ca:	4501                	li	a0,0
ffffffffc02005cc:	4581                	li	a1,0
ffffffffc02005ce:	4601                	li	a2,0
ffffffffc02005d0:	4889                	li	a7,2
ffffffffc02005d2:	00000073          	ecall
ffffffffc02005d6:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc02005d8:	8082                	ret
int cons_getc(void) {
ffffffffc02005da:	1101                	addi	sp,sp,-32
ffffffffc02005dc:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc02005de:	3d6000ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02005e2:	4501                	li	a0,0
ffffffffc02005e4:	4581                	li	a1,0
ffffffffc02005e6:	4601                	li	a2,0
ffffffffc02005e8:	4889                	li	a7,2
ffffffffc02005ea:	00000073          	ecall
ffffffffc02005ee:	2501                	sext.w	a0,a0
ffffffffc02005f0:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02005f2:	3bc000ef          	jal	ra,ffffffffc02009ae <intr_enable>
}
ffffffffc02005f6:	60e2                	ld	ra,24(sp)
ffffffffc02005f8:	6522                	ld	a0,8(sp)
ffffffffc02005fa:	6105                	addi	sp,sp,32
ffffffffc02005fc:	8082                	ret

ffffffffc02005fe <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc02005fe:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200600:	00005517          	auipc	a0,0x5
ffffffffc0200604:	34850513          	addi	a0,a0,840 # ffffffffc0205948 <commands+0xa8>
void dtb_init(void) {
ffffffffc0200608:	fc86                	sd	ra,120(sp)
ffffffffc020060a:	f8a2                	sd	s0,112(sp)
ffffffffc020060c:	e8d2                	sd	s4,80(sp)
ffffffffc020060e:	f4a6                	sd	s1,104(sp)
ffffffffc0200610:	f0ca                	sd	s2,96(sp)
ffffffffc0200612:	ecce                	sd	s3,88(sp)
ffffffffc0200614:	e4d6                	sd	s5,72(sp)
ffffffffc0200616:	e0da                	sd	s6,64(sp)
ffffffffc0200618:	fc5e                	sd	s7,56(sp)
ffffffffc020061a:	f862                	sd	s8,48(sp)
ffffffffc020061c:	f466                	sd	s9,40(sp)
ffffffffc020061e:	f06a                	sd	s10,32(sp)
ffffffffc0200620:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200622:	b73ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200626:	0000b597          	auipc	a1,0xb
ffffffffc020062a:	9da5b583          	ld	a1,-1574(a1) # ffffffffc020b000 <boot_hartid>
ffffffffc020062e:	00005517          	auipc	a0,0x5
ffffffffc0200632:	32a50513          	addi	a0,a0,810 # ffffffffc0205958 <commands+0xb8>
ffffffffc0200636:	b5fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020063a:	0000b417          	auipc	s0,0xb
ffffffffc020063e:	9ce40413          	addi	s0,s0,-1586 # ffffffffc020b008 <boot_dtb>
ffffffffc0200642:	600c                	ld	a1,0(s0)
ffffffffc0200644:	00005517          	auipc	a0,0x5
ffffffffc0200648:	32450513          	addi	a0,a0,804 # ffffffffc0205968 <commands+0xc8>
ffffffffc020064c:	b49ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200650:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200654:	00005517          	auipc	a0,0x5
ffffffffc0200658:	32c50513          	addi	a0,a0,812 # ffffffffc0205980 <commands+0xe0>
    if (boot_dtb == 0) {
ffffffffc020065c:	120a0463          	beqz	s4,ffffffffc0200784 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200660:	57f5                	li	a5,-3
ffffffffc0200662:	07fa                	slli	a5,a5,0x1e
ffffffffc0200664:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200668:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020066a:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020066e:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200670:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200674:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200678:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020067c:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200680:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200684:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200686:	8ec9                	or	a3,a3,a0
ffffffffc0200688:	0087979b          	slliw	a5,a5,0x8
ffffffffc020068c:	1b7d                	addi	s6,s6,-1
ffffffffc020068e:	0167f7b3          	and	a5,a5,s6
ffffffffc0200692:	8dd5                	or	a1,a1,a3
ffffffffc0200694:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc0200696:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020069a:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc020069c:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfe357e1>
ffffffffc02006a0:	10f59163          	bne	a1,a5,ffffffffc02007a2 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02006a4:	471c                	lw	a5,8(a4)
ffffffffc02006a6:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02006a8:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006aa:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02006ae:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02006b2:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b6:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ba:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006be:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006c2:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006c6:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ca:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006ce:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006d2:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006d4:	01146433          	or	s0,s0,a7
ffffffffc02006d8:	0086969b          	slliw	a3,a3,0x8
ffffffffc02006dc:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006e0:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006e2:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006e6:	8c49                	or	s0,s0,a0
ffffffffc02006e8:	0166f6b3          	and	a3,a3,s6
ffffffffc02006ec:	00ca6a33          	or	s4,s4,a2
ffffffffc02006f0:	0167f7b3          	and	a5,a5,s6
ffffffffc02006f4:	8c55                	or	s0,s0,a3
ffffffffc02006f6:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02006fa:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02006fc:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02006fe:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200700:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200704:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200706:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200708:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc020070c:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020070e:	00005917          	auipc	s2,0x5
ffffffffc0200712:	2c290913          	addi	s2,s2,706 # ffffffffc02059d0 <commands+0x130>
ffffffffc0200716:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200718:	4d91                	li	s11,4
ffffffffc020071a:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020071c:	00005497          	auipc	s1,0x5
ffffffffc0200720:	2ac48493          	addi	s1,s1,684 # ffffffffc02059c8 <commands+0x128>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200724:	000a2703          	lw	a4,0(s4)
ffffffffc0200728:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020072c:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200730:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200734:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200738:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020073c:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200740:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200742:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200746:	0087171b          	slliw	a4,a4,0x8
ffffffffc020074a:	8fd5                	or	a5,a5,a3
ffffffffc020074c:	00eb7733          	and	a4,s6,a4
ffffffffc0200750:	8fd9                	or	a5,a5,a4
ffffffffc0200752:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc0200754:	09778c63          	beq	a5,s7,ffffffffc02007ec <dtb_init+0x1ee>
ffffffffc0200758:	00fbea63          	bltu	s7,a5,ffffffffc020076c <dtb_init+0x16e>
ffffffffc020075c:	07a78663          	beq	a5,s10,ffffffffc02007c8 <dtb_init+0x1ca>
ffffffffc0200760:	4709                	li	a4,2
ffffffffc0200762:	00e79763          	bne	a5,a4,ffffffffc0200770 <dtb_init+0x172>
ffffffffc0200766:	4c81                	li	s9,0
ffffffffc0200768:	8a56                	mv	s4,s5
ffffffffc020076a:	bf6d                	j	ffffffffc0200724 <dtb_init+0x126>
ffffffffc020076c:	ffb78ee3          	beq	a5,s11,ffffffffc0200768 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200770:	00005517          	auipc	a0,0x5
ffffffffc0200774:	2d850513          	addi	a0,a0,728 # ffffffffc0205a48 <commands+0x1a8>
ffffffffc0200778:	a1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020077c:	00005517          	auipc	a0,0x5
ffffffffc0200780:	30450513          	addi	a0,a0,772 # ffffffffc0205a80 <commands+0x1e0>
}
ffffffffc0200784:	7446                	ld	s0,112(sp)
ffffffffc0200786:	70e6                	ld	ra,120(sp)
ffffffffc0200788:	74a6                	ld	s1,104(sp)
ffffffffc020078a:	7906                	ld	s2,96(sp)
ffffffffc020078c:	69e6                	ld	s3,88(sp)
ffffffffc020078e:	6a46                	ld	s4,80(sp)
ffffffffc0200790:	6aa6                	ld	s5,72(sp)
ffffffffc0200792:	6b06                	ld	s6,64(sp)
ffffffffc0200794:	7be2                	ld	s7,56(sp)
ffffffffc0200796:	7c42                	ld	s8,48(sp)
ffffffffc0200798:	7ca2                	ld	s9,40(sp)
ffffffffc020079a:	7d02                	ld	s10,32(sp)
ffffffffc020079c:	6de2                	ld	s11,24(sp)
ffffffffc020079e:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02007a0:	bad5                	j	ffffffffc0200194 <cprintf>
}
ffffffffc02007a2:	7446                	ld	s0,112(sp)
ffffffffc02007a4:	70e6                	ld	ra,120(sp)
ffffffffc02007a6:	74a6                	ld	s1,104(sp)
ffffffffc02007a8:	7906                	ld	s2,96(sp)
ffffffffc02007aa:	69e6                	ld	s3,88(sp)
ffffffffc02007ac:	6a46                	ld	s4,80(sp)
ffffffffc02007ae:	6aa6                	ld	s5,72(sp)
ffffffffc02007b0:	6b06                	ld	s6,64(sp)
ffffffffc02007b2:	7be2                	ld	s7,56(sp)
ffffffffc02007b4:	7c42                	ld	s8,48(sp)
ffffffffc02007b6:	7ca2                	ld	s9,40(sp)
ffffffffc02007b8:	7d02                	ld	s10,32(sp)
ffffffffc02007ba:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007bc:	00005517          	auipc	a0,0x5
ffffffffc02007c0:	1e450513          	addi	a0,a0,484 # ffffffffc02059a0 <commands+0x100>
}
ffffffffc02007c4:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007c6:	b2f9                	j	ffffffffc0200194 <cprintf>
                int name_len = strlen(name);
ffffffffc02007c8:	8556                	mv	a0,s5
ffffffffc02007ca:	59f040ef          	jal	ra,ffffffffc0205568 <strlen>
ffffffffc02007ce:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d0:	4619                	li	a2,6
ffffffffc02007d2:	85a6                	mv	a1,s1
ffffffffc02007d4:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02007d6:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d8:	5f7040ef          	jal	ra,ffffffffc02055ce <strncmp>
ffffffffc02007dc:	e111                	bnez	a0,ffffffffc02007e0 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc02007de:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02007e0:	0a91                	addi	s5,s5,4
ffffffffc02007e2:	9ad2                	add	s5,s5,s4
ffffffffc02007e4:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02007e8:	8a56                	mv	s4,s5
ffffffffc02007ea:	bf2d                	j	ffffffffc0200724 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007ec:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007f0:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007f4:	0087d71b          	srliw	a4,a5,0x8
ffffffffc02007f8:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007fc:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200800:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200804:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200808:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020080c:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200810:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200814:	00eaeab3          	or	s5,s5,a4
ffffffffc0200818:	00fb77b3          	and	a5,s6,a5
ffffffffc020081c:	00faeab3          	or	s5,s5,a5
ffffffffc0200820:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200822:	000c9c63          	bnez	s9,ffffffffc020083a <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200826:	1a82                	slli	s5,s5,0x20
ffffffffc0200828:	00368793          	addi	a5,a3,3
ffffffffc020082c:	020ada93          	srli	s5,s5,0x20
ffffffffc0200830:	9abe                	add	s5,s5,a5
ffffffffc0200832:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200836:	8a56                	mv	s4,s5
ffffffffc0200838:	b5f5                	j	ffffffffc0200724 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020083a:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020083e:	85ca                	mv	a1,s2
ffffffffc0200840:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200842:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200846:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020084a:	0187971b          	slliw	a4,a5,0x18
ffffffffc020084e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200852:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200856:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200858:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020085c:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200860:	8d59                	or	a0,a0,a4
ffffffffc0200862:	00fb77b3          	and	a5,s6,a5
ffffffffc0200866:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200868:	1502                	slli	a0,a0,0x20
ffffffffc020086a:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020086c:	9522                	add	a0,a0,s0
ffffffffc020086e:	543040ef          	jal	ra,ffffffffc02055b0 <strcmp>
ffffffffc0200872:	66a2                	ld	a3,8(sp)
ffffffffc0200874:	f94d                	bnez	a0,ffffffffc0200826 <dtb_init+0x228>
ffffffffc0200876:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200826 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020087a:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc020087e:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200882:	00005517          	auipc	a0,0x5
ffffffffc0200886:	15650513          	addi	a0,a0,342 # ffffffffc02059d8 <commands+0x138>
           fdt32_to_cpu(x >> 32);
ffffffffc020088a:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020088e:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc0200892:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200896:	0187de1b          	srliw	t3,a5,0x18
ffffffffc020089a:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020089e:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008a2:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008a6:	0187d693          	srli	a3,a5,0x18
ffffffffc02008aa:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02008ae:	0087579b          	srliw	a5,a4,0x8
ffffffffc02008b2:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008b6:	0106561b          	srliw	a2,a2,0x10
ffffffffc02008ba:	010f6f33          	or	t5,t5,a6
ffffffffc02008be:	0187529b          	srliw	t0,a4,0x18
ffffffffc02008c2:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008c6:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008ca:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008ce:	0186f6b3          	and	a3,a3,s8
ffffffffc02008d2:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02008d6:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008da:	0107581b          	srliw	a6,a4,0x10
ffffffffc02008de:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008e2:	8361                	srli	a4,a4,0x18
ffffffffc02008e4:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008e8:	0105d59b          	srliw	a1,a1,0x10
ffffffffc02008ec:	01e6e6b3          	or	a3,a3,t5
ffffffffc02008f0:	00cb7633          	and	a2,s6,a2
ffffffffc02008f4:	0088181b          	slliw	a6,a6,0x8
ffffffffc02008f8:	0085959b          	slliw	a1,a1,0x8
ffffffffc02008fc:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200900:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200904:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200908:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020090c:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200910:	011b78b3          	and	a7,s6,a7
ffffffffc0200914:	005eeeb3          	or	t4,t4,t0
ffffffffc0200918:	00c6e733          	or	a4,a3,a2
ffffffffc020091c:	006c6c33          	or	s8,s8,t1
ffffffffc0200920:	010b76b3          	and	a3,s6,a6
ffffffffc0200924:	00bb7b33          	and	s6,s6,a1
ffffffffc0200928:	01d7e7b3          	or	a5,a5,t4
ffffffffc020092c:	016c6b33          	or	s6,s8,s6
ffffffffc0200930:	01146433          	or	s0,s0,a7
ffffffffc0200934:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200936:	1702                	slli	a4,a4,0x20
ffffffffc0200938:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020093a:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020093c:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020093e:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200940:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200944:	0167eb33          	or	s6,a5,s6
ffffffffc0200948:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc020094a:	84bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc020094e:	85a2                	mv	a1,s0
ffffffffc0200950:	00005517          	auipc	a0,0x5
ffffffffc0200954:	0a850513          	addi	a0,a0,168 # ffffffffc02059f8 <commands+0x158>
ffffffffc0200958:	83dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020095c:	014b5613          	srli	a2,s6,0x14
ffffffffc0200960:	85da                	mv	a1,s6
ffffffffc0200962:	00005517          	auipc	a0,0x5
ffffffffc0200966:	0ae50513          	addi	a0,a0,174 # ffffffffc0205a10 <commands+0x170>
ffffffffc020096a:	82bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc020096e:	008b05b3          	add	a1,s6,s0
ffffffffc0200972:	15fd                	addi	a1,a1,-1
ffffffffc0200974:	00005517          	auipc	a0,0x5
ffffffffc0200978:	0bc50513          	addi	a0,a0,188 # ffffffffc0205a30 <commands+0x190>
ffffffffc020097c:	819ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc0200980:	00005517          	auipc	a0,0x5
ffffffffc0200984:	10050513          	addi	a0,a0,256 # ffffffffc0205a80 <commands+0x1e0>
        memory_base = mem_base;
ffffffffc0200988:	000aa797          	auipc	a5,0xaa
ffffffffc020098c:	d287b023          	sd	s0,-736(a5) # ffffffffc02aa6a8 <memory_base>
        memory_size = mem_size;
ffffffffc0200990:	000aa797          	auipc	a5,0xaa
ffffffffc0200994:	d367b023          	sd	s6,-736(a5) # ffffffffc02aa6b0 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200998:	b3f5                	j	ffffffffc0200784 <dtb_init+0x186>

ffffffffc020099a <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020099a:	000aa517          	auipc	a0,0xaa
ffffffffc020099e:	d0e53503          	ld	a0,-754(a0) # ffffffffc02aa6a8 <memory_base>
ffffffffc02009a2:	8082                	ret

ffffffffc02009a4 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc02009a4:	000aa517          	auipc	a0,0xaa
ffffffffc02009a8:	d0c53503          	ld	a0,-756(a0) # ffffffffc02aa6b0 <memory_size>
ffffffffc02009ac:	8082                	ret

ffffffffc02009ae <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02009ae:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02009b2:	8082                	ret

ffffffffc02009b4 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02009b4:	100177f3          	csrrci	a5,sstatus,2
ffffffffc02009b8:	8082                	ret

ffffffffc02009ba <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc02009ba:	8082                	ret

ffffffffc02009bc <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc02009bc:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc02009c0:	00000797          	auipc	a5,0x0
ffffffffc02009c4:	46878793          	addi	a5,a5,1128 # ffffffffc0200e28 <__alltraps>
ffffffffc02009c8:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc02009cc:	000407b7          	lui	a5,0x40
ffffffffc02009d0:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc02009d4:	8082                	ret

ffffffffc02009d6 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009d6:	610c                	ld	a1,0(a0)
{
ffffffffc02009d8:	1141                	addi	sp,sp,-16
ffffffffc02009da:	e022                	sd	s0,0(sp)
ffffffffc02009dc:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009de:	00005517          	auipc	a0,0x5
ffffffffc02009e2:	0ba50513          	addi	a0,a0,186 # ffffffffc0205a98 <commands+0x1f8>
{
ffffffffc02009e6:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009e8:	facff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02009ec:	640c                	ld	a1,8(s0)
ffffffffc02009ee:	00005517          	auipc	a0,0x5
ffffffffc02009f2:	0c250513          	addi	a0,a0,194 # ffffffffc0205ab0 <commands+0x210>
ffffffffc02009f6:	f9eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02009fa:	680c                	ld	a1,16(s0)
ffffffffc02009fc:	00005517          	auipc	a0,0x5
ffffffffc0200a00:	0cc50513          	addi	a0,a0,204 # ffffffffc0205ac8 <commands+0x228>
ffffffffc0200a04:	f90ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200a08:	6c0c                	ld	a1,24(s0)
ffffffffc0200a0a:	00005517          	auipc	a0,0x5
ffffffffc0200a0e:	0d650513          	addi	a0,a0,214 # ffffffffc0205ae0 <commands+0x240>
ffffffffc0200a12:	f82ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200a16:	700c                	ld	a1,32(s0)
ffffffffc0200a18:	00005517          	auipc	a0,0x5
ffffffffc0200a1c:	0e050513          	addi	a0,a0,224 # ffffffffc0205af8 <commands+0x258>
ffffffffc0200a20:	f74ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200a24:	740c                	ld	a1,40(s0)
ffffffffc0200a26:	00005517          	auipc	a0,0x5
ffffffffc0200a2a:	0ea50513          	addi	a0,a0,234 # ffffffffc0205b10 <commands+0x270>
ffffffffc0200a2e:	f66ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200a32:	780c                	ld	a1,48(s0)
ffffffffc0200a34:	00005517          	auipc	a0,0x5
ffffffffc0200a38:	0f450513          	addi	a0,a0,244 # ffffffffc0205b28 <commands+0x288>
ffffffffc0200a3c:	f58ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200a40:	7c0c                	ld	a1,56(s0)
ffffffffc0200a42:	00005517          	auipc	a0,0x5
ffffffffc0200a46:	0fe50513          	addi	a0,a0,254 # ffffffffc0205b40 <commands+0x2a0>
ffffffffc0200a4a:	f4aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200a4e:	602c                	ld	a1,64(s0)
ffffffffc0200a50:	00005517          	auipc	a0,0x5
ffffffffc0200a54:	10850513          	addi	a0,a0,264 # ffffffffc0205b58 <commands+0x2b8>
ffffffffc0200a58:	f3cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200a5c:	642c                	ld	a1,72(s0)
ffffffffc0200a5e:	00005517          	auipc	a0,0x5
ffffffffc0200a62:	11250513          	addi	a0,a0,274 # ffffffffc0205b70 <commands+0x2d0>
ffffffffc0200a66:	f2eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200a6a:	682c                	ld	a1,80(s0)
ffffffffc0200a6c:	00005517          	auipc	a0,0x5
ffffffffc0200a70:	11c50513          	addi	a0,a0,284 # ffffffffc0205b88 <commands+0x2e8>
ffffffffc0200a74:	f20ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200a78:	6c2c                	ld	a1,88(s0)
ffffffffc0200a7a:	00005517          	auipc	a0,0x5
ffffffffc0200a7e:	12650513          	addi	a0,a0,294 # ffffffffc0205ba0 <commands+0x300>
ffffffffc0200a82:	f12ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200a86:	702c                	ld	a1,96(s0)
ffffffffc0200a88:	00005517          	auipc	a0,0x5
ffffffffc0200a8c:	13050513          	addi	a0,a0,304 # ffffffffc0205bb8 <commands+0x318>
ffffffffc0200a90:	f04ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200a94:	742c                	ld	a1,104(s0)
ffffffffc0200a96:	00005517          	auipc	a0,0x5
ffffffffc0200a9a:	13a50513          	addi	a0,a0,314 # ffffffffc0205bd0 <commands+0x330>
ffffffffc0200a9e:	ef6ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200aa2:	782c                	ld	a1,112(s0)
ffffffffc0200aa4:	00005517          	auipc	a0,0x5
ffffffffc0200aa8:	14450513          	addi	a0,a0,324 # ffffffffc0205be8 <commands+0x348>
ffffffffc0200aac:	ee8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200ab0:	7c2c                	ld	a1,120(s0)
ffffffffc0200ab2:	00005517          	auipc	a0,0x5
ffffffffc0200ab6:	14e50513          	addi	a0,a0,334 # ffffffffc0205c00 <commands+0x360>
ffffffffc0200aba:	edaff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200abe:	604c                	ld	a1,128(s0)
ffffffffc0200ac0:	00005517          	auipc	a0,0x5
ffffffffc0200ac4:	15850513          	addi	a0,a0,344 # ffffffffc0205c18 <commands+0x378>
ffffffffc0200ac8:	eccff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200acc:	644c                	ld	a1,136(s0)
ffffffffc0200ace:	00005517          	auipc	a0,0x5
ffffffffc0200ad2:	16250513          	addi	a0,a0,354 # ffffffffc0205c30 <commands+0x390>
ffffffffc0200ad6:	ebeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200ada:	684c                	ld	a1,144(s0)
ffffffffc0200adc:	00005517          	auipc	a0,0x5
ffffffffc0200ae0:	16c50513          	addi	a0,a0,364 # ffffffffc0205c48 <commands+0x3a8>
ffffffffc0200ae4:	eb0ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200ae8:	6c4c                	ld	a1,152(s0)
ffffffffc0200aea:	00005517          	auipc	a0,0x5
ffffffffc0200aee:	17650513          	addi	a0,a0,374 # ffffffffc0205c60 <commands+0x3c0>
ffffffffc0200af2:	ea2ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200af6:	704c                	ld	a1,160(s0)
ffffffffc0200af8:	00005517          	auipc	a0,0x5
ffffffffc0200afc:	18050513          	addi	a0,a0,384 # ffffffffc0205c78 <commands+0x3d8>
ffffffffc0200b00:	e94ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200b04:	744c                	ld	a1,168(s0)
ffffffffc0200b06:	00005517          	auipc	a0,0x5
ffffffffc0200b0a:	18a50513          	addi	a0,a0,394 # ffffffffc0205c90 <commands+0x3f0>
ffffffffc0200b0e:	e86ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200b12:	784c                	ld	a1,176(s0)
ffffffffc0200b14:	00005517          	auipc	a0,0x5
ffffffffc0200b18:	19450513          	addi	a0,a0,404 # ffffffffc0205ca8 <commands+0x408>
ffffffffc0200b1c:	e78ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200b20:	7c4c                	ld	a1,184(s0)
ffffffffc0200b22:	00005517          	auipc	a0,0x5
ffffffffc0200b26:	19e50513          	addi	a0,a0,414 # ffffffffc0205cc0 <commands+0x420>
ffffffffc0200b2a:	e6aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200b2e:	606c                	ld	a1,192(s0)
ffffffffc0200b30:	00005517          	auipc	a0,0x5
ffffffffc0200b34:	1a850513          	addi	a0,a0,424 # ffffffffc0205cd8 <commands+0x438>
ffffffffc0200b38:	e5cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200b3c:	646c                	ld	a1,200(s0)
ffffffffc0200b3e:	00005517          	auipc	a0,0x5
ffffffffc0200b42:	1b250513          	addi	a0,a0,434 # ffffffffc0205cf0 <commands+0x450>
ffffffffc0200b46:	e4eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200b4a:	686c                	ld	a1,208(s0)
ffffffffc0200b4c:	00005517          	auipc	a0,0x5
ffffffffc0200b50:	1bc50513          	addi	a0,a0,444 # ffffffffc0205d08 <commands+0x468>
ffffffffc0200b54:	e40ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200b58:	6c6c                	ld	a1,216(s0)
ffffffffc0200b5a:	00005517          	auipc	a0,0x5
ffffffffc0200b5e:	1c650513          	addi	a0,a0,454 # ffffffffc0205d20 <commands+0x480>
ffffffffc0200b62:	e32ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200b66:	706c                	ld	a1,224(s0)
ffffffffc0200b68:	00005517          	auipc	a0,0x5
ffffffffc0200b6c:	1d050513          	addi	a0,a0,464 # ffffffffc0205d38 <commands+0x498>
ffffffffc0200b70:	e24ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200b74:	746c                	ld	a1,232(s0)
ffffffffc0200b76:	00005517          	auipc	a0,0x5
ffffffffc0200b7a:	1da50513          	addi	a0,a0,474 # ffffffffc0205d50 <commands+0x4b0>
ffffffffc0200b7e:	e16ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200b82:	786c                	ld	a1,240(s0)
ffffffffc0200b84:	00005517          	auipc	a0,0x5
ffffffffc0200b88:	1e450513          	addi	a0,a0,484 # ffffffffc0205d68 <commands+0x4c8>
ffffffffc0200b8c:	e08ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b90:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200b92:	6402                	ld	s0,0(sp)
ffffffffc0200b94:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b96:	00005517          	auipc	a0,0x5
ffffffffc0200b9a:	1ea50513          	addi	a0,a0,490 # ffffffffc0205d80 <commands+0x4e0>
}
ffffffffc0200b9e:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200ba0:	df4ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200ba4 <print_trapframe>:
{
ffffffffc0200ba4:	1141                	addi	sp,sp,-16
ffffffffc0200ba6:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200ba8:	85aa                	mv	a1,a0
{
ffffffffc0200baa:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200bac:	00005517          	auipc	a0,0x5
ffffffffc0200bb0:	1ec50513          	addi	a0,a0,492 # ffffffffc0205d98 <commands+0x4f8>
{
ffffffffc0200bb4:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200bb6:	ddeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200bba:	8522                	mv	a0,s0
ffffffffc0200bbc:	e1bff0ef          	jal	ra,ffffffffc02009d6 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200bc0:	10043583          	ld	a1,256(s0)
ffffffffc0200bc4:	00005517          	auipc	a0,0x5
ffffffffc0200bc8:	1ec50513          	addi	a0,a0,492 # ffffffffc0205db0 <commands+0x510>
ffffffffc0200bcc:	dc8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200bd0:	10843583          	ld	a1,264(s0)
ffffffffc0200bd4:	00005517          	auipc	a0,0x5
ffffffffc0200bd8:	1f450513          	addi	a0,a0,500 # ffffffffc0205dc8 <commands+0x528>
ffffffffc0200bdc:	db8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200be0:	11043583          	ld	a1,272(s0)
ffffffffc0200be4:	00005517          	auipc	a0,0x5
ffffffffc0200be8:	1fc50513          	addi	a0,a0,508 # ffffffffc0205de0 <commands+0x540>
ffffffffc0200bec:	da8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf0:	11843583          	ld	a1,280(s0)
}
ffffffffc0200bf4:	6402                	ld	s0,0(sp)
ffffffffc0200bf6:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf8:	00005517          	auipc	a0,0x5
ffffffffc0200bfc:	1f850513          	addi	a0,a0,504 # ffffffffc0205df0 <commands+0x550>
}
ffffffffc0200c00:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200c02:	d92ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200c06 <interrupt_handler>:

extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200c06:	11853783          	ld	a5,280(a0)
ffffffffc0200c0a:	472d                	li	a4,11
ffffffffc0200c0c:	0786                	slli	a5,a5,0x1
ffffffffc0200c0e:	8385                	srli	a5,a5,0x1
ffffffffc0200c10:	06f76763          	bltu	a4,a5,ffffffffc0200c7e <interrupt_handler+0x78>
ffffffffc0200c14:	00005717          	auipc	a4,0x5
ffffffffc0200c18:	29470713          	addi	a4,a4,660 # ffffffffc0205ea8 <commands+0x608>
ffffffffc0200c1c:	078a                	slli	a5,a5,0x2
ffffffffc0200c1e:	97ba                	add	a5,a5,a4
ffffffffc0200c20:	439c                	lw	a5,0(a5)
ffffffffc0200c22:	97ba                	add	a5,a5,a4
ffffffffc0200c24:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200c26:	00005517          	auipc	a0,0x5
ffffffffc0200c2a:	24250513          	addi	a0,a0,578 # ffffffffc0205e68 <commands+0x5c8>
ffffffffc0200c2e:	d66ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200c32:	00005517          	auipc	a0,0x5
ffffffffc0200c36:	21650513          	addi	a0,a0,534 # ffffffffc0205e48 <commands+0x5a8>
ffffffffc0200c3a:	d5aff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200c3e:	00005517          	auipc	a0,0x5
ffffffffc0200c42:	1ca50513          	addi	a0,a0,458 # ffffffffc0205e08 <commands+0x568>
ffffffffc0200c46:	d4eff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200c4a:	00005517          	auipc	a0,0x5
ffffffffc0200c4e:	1de50513          	addi	a0,a0,478 # ffffffffc0205e28 <commands+0x588>
ffffffffc0200c52:	d42ff06f          	j	ffffffffc0200194 <cprintf>
{
ffffffffc0200c56:	1141                	addi	sp,sp,-16
ffffffffc0200c58:	e406                	sd	ra,8(sp)
        /*(1)设置下次时钟中断- clock_set_next_event()
         *(2)计数器（ticks）加一
         *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
         * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
         */
         clock_set_next_event();
ffffffffc0200c5a:	919ff0ef          	jal	ra,ffffffffc0200572 <clock_set_next_event>
            ticks++;
ffffffffc0200c5e:	000aa717          	auipc	a4,0xaa
ffffffffc0200c62:	a3a70713          	addi	a4,a4,-1478 # ffffffffc02aa698 <ticks>
ffffffffc0200c66:	631c                	ld	a5,0(a4)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200c68:	60a2                	ld	ra,8(sp)
            ticks++;
ffffffffc0200c6a:	0785                	addi	a5,a5,1
ffffffffc0200c6c:	e31c                	sd	a5,0(a4)
}
ffffffffc0200c6e:	0141                	addi	sp,sp,16
ffffffffc0200c70:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200c72:	00005517          	auipc	a0,0x5
ffffffffc0200c76:	21650513          	addi	a0,a0,534 # ffffffffc0205e88 <commands+0x5e8>
ffffffffc0200c7a:	d1aff06f          	j	ffffffffc0200194 <cprintf>
        print_trapframe(tf);
ffffffffc0200c7e:	b71d                	j	ffffffffc0200ba4 <print_trapframe>

ffffffffc0200c80 <exception_handler>:
void kernel_execve_ret(struct trapframe *tf, uintptr_t kstacktop);
void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200c80:	11853783          	ld	a5,280(a0)
{
ffffffffc0200c84:	1141                	addi	sp,sp,-16
ffffffffc0200c86:	e022                	sd	s0,0(sp)
ffffffffc0200c88:	e406                	sd	ra,8(sp)
ffffffffc0200c8a:	473d                	li	a4,15
ffffffffc0200c8c:	842a                	mv	s0,a0
ffffffffc0200c8e:	0cf76463          	bltu	a4,a5,ffffffffc0200d56 <exception_handler+0xd6>
ffffffffc0200c92:	00005717          	auipc	a4,0x5
ffffffffc0200c96:	3d670713          	addi	a4,a4,982 # ffffffffc0206068 <commands+0x7c8>
ffffffffc0200c9a:	078a                	slli	a5,a5,0x2
ffffffffc0200c9c:	97ba                	add	a5,a5,a4
ffffffffc0200c9e:	439c                	lw	a5,0(a5)
ffffffffc0200ca0:	97ba                	add	a5,a5,a4
ffffffffc0200ca2:	8782                	jr	a5
        // cprintf("Environment call from U-mode\n");
        tf->epc += 4;
        syscall();
        break;
    case CAUSE_SUPERVISOR_ECALL:
        cprintf("Environment call from S-mode\n");
ffffffffc0200ca4:	00005517          	auipc	a0,0x5
ffffffffc0200ca8:	31c50513          	addi	a0,a0,796 # ffffffffc0205fc0 <commands+0x720>
ffffffffc0200cac:	ce8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        tf->epc += 4;
ffffffffc0200cb0:	10843783          	ld	a5,264(s0)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200cb4:	60a2                	ld	ra,8(sp)
        tf->epc += 4;
ffffffffc0200cb6:	0791                	addi	a5,a5,4
ffffffffc0200cb8:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200cbc:	6402                	ld	s0,0(sp)
ffffffffc0200cbe:	0141                	addi	sp,sp,16
        syscall();
ffffffffc0200cc0:	4240406f          	j	ffffffffc02050e4 <syscall>
        cprintf("Environment call from H-mode\n");
ffffffffc0200cc4:	00005517          	auipc	a0,0x5
ffffffffc0200cc8:	31c50513          	addi	a0,a0,796 # ffffffffc0205fe0 <commands+0x740>
}
ffffffffc0200ccc:	6402                	ld	s0,0(sp)
ffffffffc0200cce:	60a2                	ld	ra,8(sp)
ffffffffc0200cd0:	0141                	addi	sp,sp,16
        cprintf("Instruction access fault\n");
ffffffffc0200cd2:	cc2ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from M-mode\n");
ffffffffc0200cd6:	00005517          	auipc	a0,0x5
ffffffffc0200cda:	32a50513          	addi	a0,a0,810 # ffffffffc0206000 <commands+0x760>
ffffffffc0200cde:	b7fd                	j	ffffffffc0200ccc <exception_handler+0x4c>
        cprintf("Instruction page fault\n");
ffffffffc0200ce0:	00005517          	auipc	a0,0x5
ffffffffc0200ce4:	34050513          	addi	a0,a0,832 # ffffffffc0206020 <commands+0x780>
ffffffffc0200ce8:	b7d5                	j	ffffffffc0200ccc <exception_handler+0x4c>
        cprintf("Load page fault\n");
ffffffffc0200cea:	00005517          	auipc	a0,0x5
ffffffffc0200cee:	34e50513          	addi	a0,a0,846 # ffffffffc0206038 <commands+0x798>
ffffffffc0200cf2:	bfe9                	j	ffffffffc0200ccc <exception_handler+0x4c>
        cprintf("Store/AMO page fault\n");
ffffffffc0200cf4:	00005517          	auipc	a0,0x5
ffffffffc0200cf8:	35c50513          	addi	a0,a0,860 # ffffffffc0206050 <commands+0x7b0>
ffffffffc0200cfc:	bfc1                	j	ffffffffc0200ccc <exception_handler+0x4c>
        cprintf("Instruction address misaligned\n");
ffffffffc0200cfe:	00005517          	auipc	a0,0x5
ffffffffc0200d02:	1da50513          	addi	a0,a0,474 # ffffffffc0205ed8 <commands+0x638>
ffffffffc0200d06:	b7d9                	j	ffffffffc0200ccc <exception_handler+0x4c>
        cprintf("Instruction access fault\n");
ffffffffc0200d08:	00005517          	auipc	a0,0x5
ffffffffc0200d0c:	1f050513          	addi	a0,a0,496 # ffffffffc0205ef8 <commands+0x658>
ffffffffc0200d10:	bf75                	j	ffffffffc0200ccc <exception_handler+0x4c>
        cprintf("Illegal instruction\n");
ffffffffc0200d12:	00005517          	auipc	a0,0x5
ffffffffc0200d16:	20650513          	addi	a0,a0,518 # ffffffffc0205f18 <commands+0x678>
ffffffffc0200d1a:	bf4d                	j	ffffffffc0200ccc <exception_handler+0x4c>
        cprintf("Breakpoint\n");
ffffffffc0200d1c:	00005517          	auipc	a0,0x5
ffffffffc0200d20:	21450513          	addi	a0,a0,532 # ffffffffc0205f30 <commands+0x690>
ffffffffc0200d24:	c70ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        if (tf->gpr.a7 == 10)
ffffffffc0200d28:	6458                	ld	a4,136(s0)
ffffffffc0200d2a:	47a9                	li	a5,10
ffffffffc0200d2c:	04f70663          	beq	a4,a5,ffffffffc0200d78 <exception_handler+0xf8>
}
ffffffffc0200d30:	60a2                	ld	ra,8(sp)
ffffffffc0200d32:	6402                	ld	s0,0(sp)
ffffffffc0200d34:	0141                	addi	sp,sp,16
ffffffffc0200d36:	8082                	ret
        cprintf("Load address misaligned\n");
ffffffffc0200d38:	00005517          	auipc	a0,0x5
ffffffffc0200d3c:	20850513          	addi	a0,a0,520 # ffffffffc0205f40 <commands+0x6a0>
ffffffffc0200d40:	b771                	j	ffffffffc0200ccc <exception_handler+0x4c>
        cprintf("Load access fault\n");
ffffffffc0200d42:	00005517          	auipc	a0,0x5
ffffffffc0200d46:	21e50513          	addi	a0,a0,542 # ffffffffc0205f60 <commands+0x6c0>
ffffffffc0200d4a:	b749                	j	ffffffffc0200ccc <exception_handler+0x4c>
        cprintf("Store/AMO access fault\n");
ffffffffc0200d4c:	00005517          	auipc	a0,0x5
ffffffffc0200d50:	25c50513          	addi	a0,a0,604 # ffffffffc0205fa8 <commands+0x708>
ffffffffc0200d54:	bfa5                	j	ffffffffc0200ccc <exception_handler+0x4c>
        print_trapframe(tf);
ffffffffc0200d56:	8522                	mv	a0,s0
}
ffffffffc0200d58:	6402                	ld	s0,0(sp)
ffffffffc0200d5a:	60a2                	ld	ra,8(sp)
ffffffffc0200d5c:	0141                	addi	sp,sp,16
        print_trapframe(tf);
ffffffffc0200d5e:	b599                	j	ffffffffc0200ba4 <print_trapframe>
        panic("AMO address misaligned\n");
ffffffffc0200d60:	00005617          	auipc	a2,0x5
ffffffffc0200d64:	21860613          	addi	a2,a2,536 # ffffffffc0205f78 <commands+0x6d8>
ffffffffc0200d68:	0c200593          	li	a1,194
ffffffffc0200d6c:	00005517          	auipc	a0,0x5
ffffffffc0200d70:	22450513          	addi	a0,a0,548 # ffffffffc0205f90 <commands+0x6f0>
ffffffffc0200d74:	f1aff0ef          	jal	ra,ffffffffc020048e <__panic>
            tf->epc += 4;
ffffffffc0200d78:	10843783          	ld	a5,264(s0)
ffffffffc0200d7c:	0791                	addi	a5,a5,4
ffffffffc0200d7e:	10f43423          	sd	a5,264(s0)
            syscall();
ffffffffc0200d82:	362040ef          	jal	ra,ffffffffc02050e4 <syscall>
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200d86:	000aa797          	auipc	a5,0xaa
ffffffffc0200d8a:	96a7b783          	ld	a5,-1686(a5) # ffffffffc02aa6f0 <current>
ffffffffc0200d8e:	6b9c                	ld	a5,16(a5)
ffffffffc0200d90:	8522                	mv	a0,s0
}
ffffffffc0200d92:	6402                	ld	s0,0(sp)
ffffffffc0200d94:	60a2                	ld	ra,8(sp)
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200d96:	6589                	lui	a1,0x2
ffffffffc0200d98:	95be                	add	a1,a1,a5
}
ffffffffc0200d9a:	0141                	addi	sp,sp,16
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200d9c:	aaa9                	j	ffffffffc0200ef6 <kernel_execve_ret>

ffffffffc0200d9e <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
ffffffffc0200d9e:	1101                	addi	sp,sp,-32
ffffffffc0200da0:	e822                	sd	s0,16(sp)
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
ffffffffc0200da2:	000aa417          	auipc	s0,0xaa
ffffffffc0200da6:	94e40413          	addi	s0,s0,-1714 # ffffffffc02aa6f0 <current>
ffffffffc0200daa:	6018                	ld	a4,0(s0)
{
ffffffffc0200dac:	ec06                	sd	ra,24(sp)
ffffffffc0200dae:	e426                	sd	s1,8(sp)
ffffffffc0200db0:	e04a                	sd	s2,0(sp)
    if ((intptr_t)tf->cause < 0)
ffffffffc0200db2:	11853683          	ld	a3,280(a0)
    if (current == NULL)
ffffffffc0200db6:	cf1d                	beqz	a4,ffffffffc0200df4 <trap+0x56>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200db8:	10053483          	ld	s1,256(a0)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
ffffffffc0200dbc:	0a073903          	ld	s2,160(a4)
        current->tf = tf;
ffffffffc0200dc0:	f348                	sd	a0,160(a4)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200dc2:	1004f493          	andi	s1,s1,256
    if ((intptr_t)tf->cause < 0)
ffffffffc0200dc6:	0206c463          	bltz	a3,ffffffffc0200dee <trap+0x50>
        exception_handler(tf);
ffffffffc0200dca:	eb7ff0ef          	jal	ra,ffffffffc0200c80 <exception_handler>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200dce:	601c                	ld	a5,0(s0)
ffffffffc0200dd0:	0b27b023          	sd	s2,160(a5)
        if (!in_kernel)
ffffffffc0200dd4:	e499                	bnez	s1,ffffffffc0200de2 <trap+0x44>
        {
            if (current->flags & PF_EXITING)
ffffffffc0200dd6:	0b07a703          	lw	a4,176(a5)
ffffffffc0200dda:	8b05                	andi	a4,a4,1
ffffffffc0200ddc:	e329                	bnez	a4,ffffffffc0200e1e <trap+0x80>
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
ffffffffc0200dde:	6f9c                	ld	a5,24(a5)
ffffffffc0200de0:	eb85                	bnez	a5,ffffffffc0200e10 <trap+0x72>
            {
                schedule();
            }
        }
    }
}
ffffffffc0200de2:	60e2                	ld	ra,24(sp)
ffffffffc0200de4:	6442                	ld	s0,16(sp)
ffffffffc0200de6:	64a2                	ld	s1,8(sp)
ffffffffc0200de8:	6902                	ld	s2,0(sp)
ffffffffc0200dea:	6105                	addi	sp,sp,32
ffffffffc0200dec:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200dee:	e19ff0ef          	jal	ra,ffffffffc0200c06 <interrupt_handler>
ffffffffc0200df2:	bff1                	j	ffffffffc0200dce <trap+0x30>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200df4:	0006c863          	bltz	a3,ffffffffc0200e04 <trap+0x66>
}
ffffffffc0200df8:	6442                	ld	s0,16(sp)
ffffffffc0200dfa:	60e2                	ld	ra,24(sp)
ffffffffc0200dfc:	64a2                	ld	s1,8(sp)
ffffffffc0200dfe:	6902                	ld	s2,0(sp)
ffffffffc0200e00:	6105                	addi	sp,sp,32
        exception_handler(tf);
ffffffffc0200e02:	bdbd                	j	ffffffffc0200c80 <exception_handler>
}
ffffffffc0200e04:	6442                	ld	s0,16(sp)
ffffffffc0200e06:	60e2                	ld	ra,24(sp)
ffffffffc0200e08:	64a2                	ld	s1,8(sp)
ffffffffc0200e0a:	6902                	ld	s2,0(sp)
ffffffffc0200e0c:	6105                	addi	sp,sp,32
        interrupt_handler(tf);
ffffffffc0200e0e:	bbe5                	j	ffffffffc0200c06 <interrupt_handler>
}
ffffffffc0200e10:	6442                	ld	s0,16(sp)
ffffffffc0200e12:	60e2                	ld	ra,24(sp)
ffffffffc0200e14:	64a2                	ld	s1,8(sp)
ffffffffc0200e16:	6902                	ld	s2,0(sp)
ffffffffc0200e18:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200e1a:	1de0406f          	j	ffffffffc0204ff8 <schedule>
                do_exit(-E_KILLED);
ffffffffc0200e1e:	555d                	li	a0,-9
ffffffffc0200e20:	51e030ef          	jal	ra,ffffffffc020433e <do_exit>
            if (current->need_resched)
ffffffffc0200e24:	601c                	ld	a5,0(s0)
ffffffffc0200e26:	bf65                	j	ffffffffc0200dde <trap+0x40>

ffffffffc0200e28 <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200e28:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200e2c:	00011463          	bnez	sp,ffffffffc0200e34 <__alltraps+0xc>
ffffffffc0200e30:	14002173          	csrr	sp,sscratch
ffffffffc0200e34:	712d                	addi	sp,sp,-288
ffffffffc0200e36:	e002                	sd	zero,0(sp)
ffffffffc0200e38:	e406                	sd	ra,8(sp)
ffffffffc0200e3a:	ec0e                	sd	gp,24(sp)
ffffffffc0200e3c:	f012                	sd	tp,32(sp)
ffffffffc0200e3e:	f416                	sd	t0,40(sp)
ffffffffc0200e40:	f81a                	sd	t1,48(sp)
ffffffffc0200e42:	fc1e                	sd	t2,56(sp)
ffffffffc0200e44:	e0a2                	sd	s0,64(sp)
ffffffffc0200e46:	e4a6                	sd	s1,72(sp)
ffffffffc0200e48:	e8aa                	sd	a0,80(sp)
ffffffffc0200e4a:	ecae                	sd	a1,88(sp)
ffffffffc0200e4c:	f0b2                	sd	a2,96(sp)
ffffffffc0200e4e:	f4b6                	sd	a3,104(sp)
ffffffffc0200e50:	f8ba                	sd	a4,112(sp)
ffffffffc0200e52:	fcbe                	sd	a5,120(sp)
ffffffffc0200e54:	e142                	sd	a6,128(sp)
ffffffffc0200e56:	e546                	sd	a7,136(sp)
ffffffffc0200e58:	e94a                	sd	s2,144(sp)
ffffffffc0200e5a:	ed4e                	sd	s3,152(sp)
ffffffffc0200e5c:	f152                	sd	s4,160(sp)
ffffffffc0200e5e:	f556                	sd	s5,168(sp)
ffffffffc0200e60:	f95a                	sd	s6,176(sp)
ffffffffc0200e62:	fd5e                	sd	s7,184(sp)
ffffffffc0200e64:	e1e2                	sd	s8,192(sp)
ffffffffc0200e66:	e5e6                	sd	s9,200(sp)
ffffffffc0200e68:	e9ea                	sd	s10,208(sp)
ffffffffc0200e6a:	edee                	sd	s11,216(sp)
ffffffffc0200e6c:	f1f2                	sd	t3,224(sp)
ffffffffc0200e6e:	f5f6                	sd	t4,232(sp)
ffffffffc0200e70:	f9fa                	sd	t5,240(sp)
ffffffffc0200e72:	fdfe                	sd	t6,248(sp)
ffffffffc0200e74:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200e78:	100024f3          	csrr	s1,sstatus
ffffffffc0200e7c:	14102973          	csrr	s2,sepc
ffffffffc0200e80:	143029f3          	csrr	s3,stval
ffffffffc0200e84:	14202a73          	csrr	s4,scause
ffffffffc0200e88:	e822                	sd	s0,16(sp)
ffffffffc0200e8a:	e226                	sd	s1,256(sp)
ffffffffc0200e8c:	e64a                	sd	s2,264(sp)
ffffffffc0200e8e:	ea4e                	sd	s3,272(sp)
ffffffffc0200e90:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200e92:	850a                	mv	a0,sp
    jal trap
ffffffffc0200e94:	f0bff0ef          	jal	ra,ffffffffc0200d9e <trap>

ffffffffc0200e98 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200e98:	6492                	ld	s1,256(sp)
ffffffffc0200e9a:	6932                	ld	s2,264(sp)
ffffffffc0200e9c:	1004f413          	andi	s0,s1,256
ffffffffc0200ea0:	e401                	bnez	s0,ffffffffc0200ea8 <__trapret+0x10>
ffffffffc0200ea2:	1200                	addi	s0,sp,288
ffffffffc0200ea4:	14041073          	csrw	sscratch,s0
ffffffffc0200ea8:	10049073          	csrw	sstatus,s1
ffffffffc0200eac:	14191073          	csrw	sepc,s2
ffffffffc0200eb0:	60a2                	ld	ra,8(sp)
ffffffffc0200eb2:	61e2                	ld	gp,24(sp)
ffffffffc0200eb4:	7202                	ld	tp,32(sp)
ffffffffc0200eb6:	72a2                	ld	t0,40(sp)
ffffffffc0200eb8:	7342                	ld	t1,48(sp)
ffffffffc0200eba:	73e2                	ld	t2,56(sp)
ffffffffc0200ebc:	6406                	ld	s0,64(sp)
ffffffffc0200ebe:	64a6                	ld	s1,72(sp)
ffffffffc0200ec0:	6546                	ld	a0,80(sp)
ffffffffc0200ec2:	65e6                	ld	a1,88(sp)
ffffffffc0200ec4:	7606                	ld	a2,96(sp)
ffffffffc0200ec6:	76a6                	ld	a3,104(sp)
ffffffffc0200ec8:	7746                	ld	a4,112(sp)
ffffffffc0200eca:	77e6                	ld	a5,120(sp)
ffffffffc0200ecc:	680a                	ld	a6,128(sp)
ffffffffc0200ece:	68aa                	ld	a7,136(sp)
ffffffffc0200ed0:	694a                	ld	s2,144(sp)
ffffffffc0200ed2:	69ea                	ld	s3,152(sp)
ffffffffc0200ed4:	7a0a                	ld	s4,160(sp)
ffffffffc0200ed6:	7aaa                	ld	s5,168(sp)
ffffffffc0200ed8:	7b4a                	ld	s6,176(sp)
ffffffffc0200eda:	7bea                	ld	s7,184(sp)
ffffffffc0200edc:	6c0e                	ld	s8,192(sp)
ffffffffc0200ede:	6cae                	ld	s9,200(sp)
ffffffffc0200ee0:	6d4e                	ld	s10,208(sp)
ffffffffc0200ee2:	6dee                	ld	s11,216(sp)
ffffffffc0200ee4:	7e0e                	ld	t3,224(sp)
ffffffffc0200ee6:	7eae                	ld	t4,232(sp)
ffffffffc0200ee8:	7f4e                	ld	t5,240(sp)
ffffffffc0200eea:	7fee                	ld	t6,248(sp)
ffffffffc0200eec:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200eee:	10200073          	sret

ffffffffc0200ef2 <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200ef2:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200ef4:	b755                	j	ffffffffc0200e98 <__trapret>

ffffffffc0200ef6 <kernel_execve_ret>:

    .global kernel_execve_ret
kernel_execve_ret:
    // adjust sp to beneath kstacktop of current process
    addi a1, a1, -36*REGBYTES
ffffffffc0200ef6:	ee058593          	addi	a1,a1,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7cc8>

    // copy from previous trapframe to new trapframe
    LOAD s1, 35*REGBYTES(a0)
ffffffffc0200efa:	11853483          	ld	s1,280(a0)
    STORE s1, 35*REGBYTES(a1)
ffffffffc0200efe:	1095bc23          	sd	s1,280(a1)
    LOAD s1, 34*REGBYTES(a0)
ffffffffc0200f02:	11053483          	ld	s1,272(a0)
    STORE s1, 34*REGBYTES(a1)
ffffffffc0200f06:	1095b823          	sd	s1,272(a1)
    LOAD s1, 33*REGBYTES(a0)
ffffffffc0200f0a:	10853483          	ld	s1,264(a0)
    STORE s1, 33*REGBYTES(a1)
ffffffffc0200f0e:	1095b423          	sd	s1,264(a1)
    LOAD s1, 32*REGBYTES(a0)
ffffffffc0200f12:	10053483          	ld	s1,256(a0)
    STORE s1, 32*REGBYTES(a1)
ffffffffc0200f16:	1095b023          	sd	s1,256(a1)
    LOAD s1, 31*REGBYTES(a0)
ffffffffc0200f1a:	7d64                	ld	s1,248(a0)
    STORE s1, 31*REGBYTES(a1)
ffffffffc0200f1c:	fde4                	sd	s1,248(a1)
    LOAD s1, 30*REGBYTES(a0)
ffffffffc0200f1e:	7964                	ld	s1,240(a0)
    STORE s1, 30*REGBYTES(a1)
ffffffffc0200f20:	f9e4                	sd	s1,240(a1)
    LOAD s1, 29*REGBYTES(a0)
ffffffffc0200f22:	7564                	ld	s1,232(a0)
    STORE s1, 29*REGBYTES(a1)
ffffffffc0200f24:	f5e4                	sd	s1,232(a1)
    LOAD s1, 28*REGBYTES(a0)
ffffffffc0200f26:	7164                	ld	s1,224(a0)
    STORE s1, 28*REGBYTES(a1)
ffffffffc0200f28:	f1e4                	sd	s1,224(a1)
    LOAD s1, 27*REGBYTES(a0)
ffffffffc0200f2a:	6d64                	ld	s1,216(a0)
    STORE s1, 27*REGBYTES(a1)
ffffffffc0200f2c:	ede4                	sd	s1,216(a1)
    LOAD s1, 26*REGBYTES(a0)
ffffffffc0200f2e:	6964                	ld	s1,208(a0)
    STORE s1, 26*REGBYTES(a1)
ffffffffc0200f30:	e9e4                	sd	s1,208(a1)
    LOAD s1, 25*REGBYTES(a0)
ffffffffc0200f32:	6564                	ld	s1,200(a0)
    STORE s1, 25*REGBYTES(a1)
ffffffffc0200f34:	e5e4                	sd	s1,200(a1)
    LOAD s1, 24*REGBYTES(a0)
ffffffffc0200f36:	6164                	ld	s1,192(a0)
    STORE s1, 24*REGBYTES(a1)
ffffffffc0200f38:	e1e4                	sd	s1,192(a1)
    LOAD s1, 23*REGBYTES(a0)
ffffffffc0200f3a:	7d44                	ld	s1,184(a0)
    STORE s1, 23*REGBYTES(a1)
ffffffffc0200f3c:	fdc4                	sd	s1,184(a1)
    LOAD s1, 22*REGBYTES(a0)
ffffffffc0200f3e:	7944                	ld	s1,176(a0)
    STORE s1, 22*REGBYTES(a1)
ffffffffc0200f40:	f9c4                	sd	s1,176(a1)
    LOAD s1, 21*REGBYTES(a0)
ffffffffc0200f42:	7544                	ld	s1,168(a0)
    STORE s1, 21*REGBYTES(a1)
ffffffffc0200f44:	f5c4                	sd	s1,168(a1)
    LOAD s1, 20*REGBYTES(a0)
ffffffffc0200f46:	7144                	ld	s1,160(a0)
    STORE s1, 20*REGBYTES(a1)
ffffffffc0200f48:	f1c4                	sd	s1,160(a1)
    LOAD s1, 19*REGBYTES(a0)
ffffffffc0200f4a:	6d44                	ld	s1,152(a0)
    STORE s1, 19*REGBYTES(a1)
ffffffffc0200f4c:	edc4                	sd	s1,152(a1)
    LOAD s1, 18*REGBYTES(a0)
ffffffffc0200f4e:	6944                	ld	s1,144(a0)
    STORE s1, 18*REGBYTES(a1)
ffffffffc0200f50:	e9c4                	sd	s1,144(a1)
    LOAD s1, 17*REGBYTES(a0)
ffffffffc0200f52:	6544                	ld	s1,136(a0)
    STORE s1, 17*REGBYTES(a1)
ffffffffc0200f54:	e5c4                	sd	s1,136(a1)
    LOAD s1, 16*REGBYTES(a0)
ffffffffc0200f56:	6144                	ld	s1,128(a0)
    STORE s1, 16*REGBYTES(a1)
ffffffffc0200f58:	e1c4                	sd	s1,128(a1)
    LOAD s1, 15*REGBYTES(a0)
ffffffffc0200f5a:	7d24                	ld	s1,120(a0)
    STORE s1, 15*REGBYTES(a1)
ffffffffc0200f5c:	fda4                	sd	s1,120(a1)
    LOAD s1, 14*REGBYTES(a0)
ffffffffc0200f5e:	7924                	ld	s1,112(a0)
    STORE s1, 14*REGBYTES(a1)
ffffffffc0200f60:	f9a4                	sd	s1,112(a1)
    LOAD s1, 13*REGBYTES(a0)
ffffffffc0200f62:	7524                	ld	s1,104(a0)
    STORE s1, 13*REGBYTES(a1)
ffffffffc0200f64:	f5a4                	sd	s1,104(a1)
    LOAD s1, 12*REGBYTES(a0)
ffffffffc0200f66:	7124                	ld	s1,96(a0)
    STORE s1, 12*REGBYTES(a1)
ffffffffc0200f68:	f1a4                	sd	s1,96(a1)
    LOAD s1, 11*REGBYTES(a0)
ffffffffc0200f6a:	6d24                	ld	s1,88(a0)
    STORE s1, 11*REGBYTES(a1)
ffffffffc0200f6c:	eda4                	sd	s1,88(a1)
    LOAD s1, 10*REGBYTES(a0)
ffffffffc0200f6e:	6924                	ld	s1,80(a0)
    STORE s1, 10*REGBYTES(a1)
ffffffffc0200f70:	e9a4                	sd	s1,80(a1)
    LOAD s1, 9*REGBYTES(a0)
ffffffffc0200f72:	6524                	ld	s1,72(a0)
    STORE s1, 9*REGBYTES(a1)
ffffffffc0200f74:	e5a4                	sd	s1,72(a1)
    LOAD s1, 8*REGBYTES(a0)
ffffffffc0200f76:	6124                	ld	s1,64(a0)
    STORE s1, 8*REGBYTES(a1)
ffffffffc0200f78:	e1a4                	sd	s1,64(a1)
    LOAD s1, 7*REGBYTES(a0)
ffffffffc0200f7a:	7d04                	ld	s1,56(a0)
    STORE s1, 7*REGBYTES(a1)
ffffffffc0200f7c:	fd84                	sd	s1,56(a1)
    LOAD s1, 6*REGBYTES(a0)
ffffffffc0200f7e:	7904                	ld	s1,48(a0)
    STORE s1, 6*REGBYTES(a1)
ffffffffc0200f80:	f984                	sd	s1,48(a1)
    LOAD s1, 5*REGBYTES(a0)
ffffffffc0200f82:	7504                	ld	s1,40(a0)
    STORE s1, 5*REGBYTES(a1)
ffffffffc0200f84:	f584                	sd	s1,40(a1)
    LOAD s1, 4*REGBYTES(a0)
ffffffffc0200f86:	7104                	ld	s1,32(a0)
    STORE s1, 4*REGBYTES(a1)
ffffffffc0200f88:	f184                	sd	s1,32(a1)
    LOAD s1, 3*REGBYTES(a0)
ffffffffc0200f8a:	6d04                	ld	s1,24(a0)
    STORE s1, 3*REGBYTES(a1)
ffffffffc0200f8c:	ed84                	sd	s1,24(a1)
    LOAD s1, 2*REGBYTES(a0)
ffffffffc0200f8e:	6904                	ld	s1,16(a0)
    STORE s1, 2*REGBYTES(a1)
ffffffffc0200f90:	e984                	sd	s1,16(a1)
    LOAD s1, 1*REGBYTES(a0)
ffffffffc0200f92:	6504                	ld	s1,8(a0)
    STORE s1, 1*REGBYTES(a1)
ffffffffc0200f94:	e584                	sd	s1,8(a1)
    LOAD s1, 0*REGBYTES(a0)
ffffffffc0200f96:	6104                	ld	s1,0(a0)
    STORE s1, 0*REGBYTES(a1)
ffffffffc0200f98:	e184                	sd	s1,0(a1)

    // acutually adjust sp
    move sp, a1
ffffffffc0200f9a:	812e                	mv	sp,a1
ffffffffc0200f9c:	bdf5                	j	ffffffffc0200e98 <__trapret>

ffffffffc0200f9e <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200f9e:	000a5797          	auipc	a5,0xa5
ffffffffc0200fa2:	6ca78793          	addi	a5,a5,1738 # ffffffffc02a6668 <free_area>
ffffffffc0200fa6:	e79c                	sd	a5,8(a5)
ffffffffc0200fa8:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200faa:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200fae:	8082                	ret

ffffffffc0200fb0 <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0200fb0:	000a5517          	auipc	a0,0xa5
ffffffffc0200fb4:	6c856503          	lwu	a0,1736(a0) # ffffffffc02a6678 <free_area+0x10>
ffffffffc0200fb8:	8082                	ret

ffffffffc0200fba <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc0200fba:	715d                	addi	sp,sp,-80
ffffffffc0200fbc:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200fbe:	000a5417          	auipc	s0,0xa5
ffffffffc0200fc2:	6aa40413          	addi	s0,s0,1706 # ffffffffc02a6668 <free_area>
ffffffffc0200fc6:	641c                	ld	a5,8(s0)
ffffffffc0200fc8:	e486                	sd	ra,72(sp)
ffffffffc0200fca:	fc26                	sd	s1,56(sp)
ffffffffc0200fcc:	f84a                	sd	s2,48(sp)
ffffffffc0200fce:	f44e                	sd	s3,40(sp)
ffffffffc0200fd0:	f052                	sd	s4,32(sp)
ffffffffc0200fd2:	ec56                	sd	s5,24(sp)
ffffffffc0200fd4:	e85a                	sd	s6,16(sp)
ffffffffc0200fd6:	e45e                	sd	s7,8(sp)
ffffffffc0200fd8:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0200fda:	2a878d63          	beq	a5,s0,ffffffffc0201294 <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc0200fde:	4481                	li	s1,0
ffffffffc0200fe0:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200fe2:	ff07b703          	ld	a4,-16(a5)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200fe6:	8b09                	andi	a4,a4,2
ffffffffc0200fe8:	2a070a63          	beqz	a4,ffffffffc020129c <default_check+0x2e2>
        count++, total += p->property;
ffffffffc0200fec:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200ff0:	679c                	ld	a5,8(a5)
ffffffffc0200ff2:	2905                	addiw	s2,s2,1
ffffffffc0200ff4:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0200ff6:	fe8796e3          	bne	a5,s0,ffffffffc0200fe2 <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200ffa:	89a6                	mv	s3,s1
ffffffffc0200ffc:	6df000ef          	jal	ra,ffffffffc0201eda <nr_free_pages>
ffffffffc0201000:	6f351e63          	bne	a0,s3,ffffffffc02016fc <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201004:	4505                	li	a0,1
ffffffffc0201006:	657000ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
ffffffffc020100a:	8aaa                	mv	s5,a0
ffffffffc020100c:	42050863          	beqz	a0,ffffffffc020143c <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201010:	4505                	li	a0,1
ffffffffc0201012:	64b000ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
ffffffffc0201016:	89aa                	mv	s3,a0
ffffffffc0201018:	70050263          	beqz	a0,ffffffffc020171c <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020101c:	4505                	li	a0,1
ffffffffc020101e:	63f000ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
ffffffffc0201022:	8a2a                	mv	s4,a0
ffffffffc0201024:	48050c63          	beqz	a0,ffffffffc02014bc <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201028:	293a8a63          	beq	s5,s3,ffffffffc02012bc <default_check+0x302>
ffffffffc020102c:	28aa8863          	beq	s5,a0,ffffffffc02012bc <default_check+0x302>
ffffffffc0201030:	28a98663          	beq	s3,a0,ffffffffc02012bc <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201034:	000aa783          	lw	a5,0(s5)
ffffffffc0201038:	2a079263          	bnez	a5,ffffffffc02012dc <default_check+0x322>
ffffffffc020103c:	0009a783          	lw	a5,0(s3)
ffffffffc0201040:	28079e63          	bnez	a5,ffffffffc02012dc <default_check+0x322>
ffffffffc0201044:	411c                	lw	a5,0(a0)
ffffffffc0201046:	28079b63          	bnez	a5,ffffffffc02012dc <default_check+0x322>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc020104a:	000a9797          	auipc	a5,0xa9
ffffffffc020104e:	68e7b783          	ld	a5,1678(a5) # ffffffffc02aa6d8 <pages>
ffffffffc0201052:	40fa8733          	sub	a4,s5,a5
ffffffffc0201056:	00006617          	auipc	a2,0x6
ffffffffc020105a:	70a63603          	ld	a2,1802(a2) # ffffffffc0207760 <nbase>
ffffffffc020105e:	8719                	srai	a4,a4,0x6
ffffffffc0201060:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201062:	000a9697          	auipc	a3,0xa9
ffffffffc0201066:	66e6b683          	ld	a3,1646(a3) # ffffffffc02aa6d0 <npage>
ffffffffc020106a:	06b2                	slli	a3,a3,0xc
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc020106c:	0732                	slli	a4,a4,0xc
ffffffffc020106e:	28d77763          	bgeu	a4,a3,ffffffffc02012fc <default_check+0x342>
    return page - pages + nbase;
ffffffffc0201072:	40f98733          	sub	a4,s3,a5
ffffffffc0201076:	8719                	srai	a4,a4,0x6
ffffffffc0201078:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc020107a:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020107c:	4cd77063          	bgeu	a4,a3,ffffffffc020153c <default_check+0x582>
    return page - pages + nbase;
ffffffffc0201080:	40f507b3          	sub	a5,a0,a5
ffffffffc0201084:	8799                	srai	a5,a5,0x6
ffffffffc0201086:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0201088:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc020108a:	30d7f963          	bgeu	a5,a3,ffffffffc020139c <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc020108e:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0201090:	00043c03          	ld	s8,0(s0)
ffffffffc0201094:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0201098:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc020109c:	e400                	sd	s0,8(s0)
ffffffffc020109e:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc02010a0:	000a5797          	auipc	a5,0xa5
ffffffffc02010a4:	5c07ac23          	sw	zero,1496(a5) # ffffffffc02a6678 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc02010a8:	5b5000ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
ffffffffc02010ac:	2c051863          	bnez	a0,ffffffffc020137c <default_check+0x3c2>
    free_page(p0);
ffffffffc02010b0:	4585                	li	a1,1
ffffffffc02010b2:	8556                	mv	a0,s5
ffffffffc02010b4:	5e7000ef          	jal	ra,ffffffffc0201e9a <free_pages>
    free_page(p1);
ffffffffc02010b8:	4585                	li	a1,1
ffffffffc02010ba:	854e                	mv	a0,s3
ffffffffc02010bc:	5df000ef          	jal	ra,ffffffffc0201e9a <free_pages>
    free_page(p2);
ffffffffc02010c0:	4585                	li	a1,1
ffffffffc02010c2:	8552                	mv	a0,s4
ffffffffc02010c4:	5d7000ef          	jal	ra,ffffffffc0201e9a <free_pages>
    assert(nr_free == 3);
ffffffffc02010c8:	4818                	lw	a4,16(s0)
ffffffffc02010ca:	478d                	li	a5,3
ffffffffc02010cc:	28f71863          	bne	a4,a5,ffffffffc020135c <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02010d0:	4505                	li	a0,1
ffffffffc02010d2:	58b000ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
ffffffffc02010d6:	89aa                	mv	s3,a0
ffffffffc02010d8:	26050263          	beqz	a0,ffffffffc020133c <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02010dc:	4505                	li	a0,1
ffffffffc02010de:	57f000ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
ffffffffc02010e2:	8aaa                	mv	s5,a0
ffffffffc02010e4:	3a050c63          	beqz	a0,ffffffffc020149c <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02010e8:	4505                	li	a0,1
ffffffffc02010ea:	573000ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
ffffffffc02010ee:	8a2a                	mv	s4,a0
ffffffffc02010f0:	38050663          	beqz	a0,ffffffffc020147c <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc02010f4:	4505                	li	a0,1
ffffffffc02010f6:	567000ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
ffffffffc02010fa:	36051163          	bnez	a0,ffffffffc020145c <default_check+0x4a2>
    free_page(p0);
ffffffffc02010fe:	4585                	li	a1,1
ffffffffc0201100:	854e                	mv	a0,s3
ffffffffc0201102:	599000ef          	jal	ra,ffffffffc0201e9a <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0201106:	641c                	ld	a5,8(s0)
ffffffffc0201108:	20878a63          	beq	a5,s0,ffffffffc020131c <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc020110c:	4505                	li	a0,1
ffffffffc020110e:	54f000ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
ffffffffc0201112:	30a99563          	bne	s3,a0,ffffffffc020141c <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc0201116:	4505                	li	a0,1
ffffffffc0201118:	545000ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
ffffffffc020111c:	2e051063          	bnez	a0,ffffffffc02013fc <default_check+0x442>
    assert(nr_free == 0);
ffffffffc0201120:	481c                	lw	a5,16(s0)
ffffffffc0201122:	2a079d63          	bnez	a5,ffffffffc02013dc <default_check+0x422>
    free_page(p);
ffffffffc0201126:	854e                	mv	a0,s3
ffffffffc0201128:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc020112a:	01843023          	sd	s8,0(s0)
ffffffffc020112e:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0201132:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0201136:	565000ef          	jal	ra,ffffffffc0201e9a <free_pages>
    free_page(p1);
ffffffffc020113a:	4585                	li	a1,1
ffffffffc020113c:	8556                	mv	a0,s5
ffffffffc020113e:	55d000ef          	jal	ra,ffffffffc0201e9a <free_pages>
    free_page(p2);
ffffffffc0201142:	4585                	li	a1,1
ffffffffc0201144:	8552                	mv	a0,s4
ffffffffc0201146:	555000ef          	jal	ra,ffffffffc0201e9a <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc020114a:	4515                	li	a0,5
ffffffffc020114c:	511000ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
ffffffffc0201150:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0201152:	26050563          	beqz	a0,ffffffffc02013bc <default_check+0x402>
ffffffffc0201156:	651c                	ld	a5,8(a0)
ffffffffc0201158:	8385                	srli	a5,a5,0x1
ffffffffc020115a:	8b85                	andi	a5,a5,1
    assert(!PageProperty(p0));
ffffffffc020115c:	54079063          	bnez	a5,ffffffffc020169c <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0201160:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0201162:	00043b03          	ld	s6,0(s0)
ffffffffc0201166:	00843a83          	ld	s5,8(s0)
ffffffffc020116a:	e000                	sd	s0,0(s0)
ffffffffc020116c:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc020116e:	4ef000ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
ffffffffc0201172:	50051563          	bnez	a0,ffffffffc020167c <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0201176:	08098a13          	addi	s4,s3,128
ffffffffc020117a:	8552                	mv	a0,s4
ffffffffc020117c:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc020117e:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0201182:	000a5797          	auipc	a5,0xa5
ffffffffc0201186:	4e07ab23          	sw	zero,1270(a5) # ffffffffc02a6678 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc020118a:	511000ef          	jal	ra,ffffffffc0201e9a <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc020118e:	4511                	li	a0,4
ffffffffc0201190:	4cd000ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
ffffffffc0201194:	4c051463          	bnez	a0,ffffffffc020165c <default_check+0x6a2>
ffffffffc0201198:	0889b783          	ld	a5,136(s3)
ffffffffc020119c:	8385                	srli	a5,a5,0x1
ffffffffc020119e:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02011a0:	48078e63          	beqz	a5,ffffffffc020163c <default_check+0x682>
ffffffffc02011a4:	0909a703          	lw	a4,144(s3)
ffffffffc02011a8:	478d                	li	a5,3
ffffffffc02011aa:	48f71963          	bne	a4,a5,ffffffffc020163c <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02011ae:	450d                	li	a0,3
ffffffffc02011b0:	4ad000ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
ffffffffc02011b4:	8c2a                	mv	s8,a0
ffffffffc02011b6:	46050363          	beqz	a0,ffffffffc020161c <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc02011ba:	4505                	li	a0,1
ffffffffc02011bc:	4a1000ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
ffffffffc02011c0:	42051e63          	bnez	a0,ffffffffc02015fc <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc02011c4:	418a1c63          	bne	s4,s8,ffffffffc02015dc <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc02011c8:	4585                	li	a1,1
ffffffffc02011ca:	854e                	mv	a0,s3
ffffffffc02011cc:	4cf000ef          	jal	ra,ffffffffc0201e9a <free_pages>
    free_pages(p1, 3);
ffffffffc02011d0:	458d                	li	a1,3
ffffffffc02011d2:	8552                	mv	a0,s4
ffffffffc02011d4:	4c7000ef          	jal	ra,ffffffffc0201e9a <free_pages>
ffffffffc02011d8:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc02011dc:	04098c13          	addi	s8,s3,64
ffffffffc02011e0:	8385                	srli	a5,a5,0x1
ffffffffc02011e2:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02011e4:	3c078c63          	beqz	a5,ffffffffc02015bc <default_check+0x602>
ffffffffc02011e8:	0109a703          	lw	a4,16(s3)
ffffffffc02011ec:	4785                	li	a5,1
ffffffffc02011ee:	3cf71763          	bne	a4,a5,ffffffffc02015bc <default_check+0x602>
ffffffffc02011f2:	008a3783          	ld	a5,8(s4)
ffffffffc02011f6:	8385                	srli	a5,a5,0x1
ffffffffc02011f8:	8b85                	andi	a5,a5,1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02011fa:	3a078163          	beqz	a5,ffffffffc020159c <default_check+0x5e2>
ffffffffc02011fe:	010a2703          	lw	a4,16(s4)
ffffffffc0201202:	478d                	li	a5,3
ffffffffc0201204:	38f71c63          	bne	a4,a5,ffffffffc020159c <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201208:	4505                	li	a0,1
ffffffffc020120a:	453000ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
ffffffffc020120e:	36a99763          	bne	s3,a0,ffffffffc020157c <default_check+0x5c2>
    free_page(p0);
ffffffffc0201212:	4585                	li	a1,1
ffffffffc0201214:	487000ef          	jal	ra,ffffffffc0201e9a <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201218:	4509                	li	a0,2
ffffffffc020121a:	443000ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
ffffffffc020121e:	32aa1f63          	bne	s4,a0,ffffffffc020155c <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc0201222:	4589                	li	a1,2
ffffffffc0201224:	477000ef          	jal	ra,ffffffffc0201e9a <free_pages>
    free_page(p2);
ffffffffc0201228:	4585                	li	a1,1
ffffffffc020122a:	8562                	mv	a0,s8
ffffffffc020122c:	46f000ef          	jal	ra,ffffffffc0201e9a <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201230:	4515                	li	a0,5
ffffffffc0201232:	42b000ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
ffffffffc0201236:	89aa                	mv	s3,a0
ffffffffc0201238:	48050263          	beqz	a0,ffffffffc02016bc <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc020123c:	4505                	li	a0,1
ffffffffc020123e:	41f000ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
ffffffffc0201242:	2c051d63          	bnez	a0,ffffffffc020151c <default_check+0x562>

    assert(nr_free == 0);
ffffffffc0201246:	481c                	lw	a5,16(s0)
ffffffffc0201248:	2a079a63          	bnez	a5,ffffffffc02014fc <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc020124c:	4595                	li	a1,5
ffffffffc020124e:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0201250:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0201254:	01643023          	sd	s6,0(s0)
ffffffffc0201258:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc020125c:	43f000ef          	jal	ra,ffffffffc0201e9a <free_pages>
    return listelm->next;
ffffffffc0201260:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0201262:	00878963          	beq	a5,s0,ffffffffc0201274 <default_check+0x2ba>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc0201266:	ff87a703          	lw	a4,-8(a5)
ffffffffc020126a:	679c                	ld	a5,8(a5)
ffffffffc020126c:	397d                	addiw	s2,s2,-1
ffffffffc020126e:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0201270:	fe879be3          	bne	a5,s0,ffffffffc0201266 <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc0201274:	26091463          	bnez	s2,ffffffffc02014dc <default_check+0x522>
    assert(total == 0);
ffffffffc0201278:	46049263          	bnez	s1,ffffffffc02016dc <default_check+0x722>
}
ffffffffc020127c:	60a6                	ld	ra,72(sp)
ffffffffc020127e:	6406                	ld	s0,64(sp)
ffffffffc0201280:	74e2                	ld	s1,56(sp)
ffffffffc0201282:	7942                	ld	s2,48(sp)
ffffffffc0201284:	79a2                	ld	s3,40(sp)
ffffffffc0201286:	7a02                	ld	s4,32(sp)
ffffffffc0201288:	6ae2                	ld	s5,24(sp)
ffffffffc020128a:	6b42                	ld	s6,16(sp)
ffffffffc020128c:	6ba2                	ld	s7,8(sp)
ffffffffc020128e:	6c02                	ld	s8,0(sp)
ffffffffc0201290:	6161                	addi	sp,sp,80
ffffffffc0201292:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc0201294:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0201296:	4481                	li	s1,0
ffffffffc0201298:	4901                	li	s2,0
ffffffffc020129a:	b38d                	j	ffffffffc0200ffc <default_check+0x42>
        assert(PageProperty(p));
ffffffffc020129c:	00005697          	auipc	a3,0x5
ffffffffc02012a0:	e0c68693          	addi	a3,a3,-500 # ffffffffc02060a8 <commands+0x808>
ffffffffc02012a4:	00005617          	auipc	a2,0x5
ffffffffc02012a8:	e1460613          	addi	a2,a2,-492 # ffffffffc02060b8 <commands+0x818>
ffffffffc02012ac:	11000593          	li	a1,272
ffffffffc02012b0:	00005517          	auipc	a0,0x5
ffffffffc02012b4:	e2050513          	addi	a0,a0,-480 # ffffffffc02060d0 <commands+0x830>
ffffffffc02012b8:	9d6ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02012bc:	00005697          	auipc	a3,0x5
ffffffffc02012c0:	eac68693          	addi	a3,a3,-340 # ffffffffc0206168 <commands+0x8c8>
ffffffffc02012c4:	00005617          	auipc	a2,0x5
ffffffffc02012c8:	df460613          	addi	a2,a2,-524 # ffffffffc02060b8 <commands+0x818>
ffffffffc02012cc:	0db00593          	li	a1,219
ffffffffc02012d0:	00005517          	auipc	a0,0x5
ffffffffc02012d4:	e0050513          	addi	a0,a0,-512 # ffffffffc02060d0 <commands+0x830>
ffffffffc02012d8:	9b6ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02012dc:	00005697          	auipc	a3,0x5
ffffffffc02012e0:	eb468693          	addi	a3,a3,-332 # ffffffffc0206190 <commands+0x8f0>
ffffffffc02012e4:	00005617          	auipc	a2,0x5
ffffffffc02012e8:	dd460613          	addi	a2,a2,-556 # ffffffffc02060b8 <commands+0x818>
ffffffffc02012ec:	0dc00593          	li	a1,220
ffffffffc02012f0:	00005517          	auipc	a0,0x5
ffffffffc02012f4:	de050513          	addi	a0,a0,-544 # ffffffffc02060d0 <commands+0x830>
ffffffffc02012f8:	996ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02012fc:	00005697          	auipc	a3,0x5
ffffffffc0201300:	ed468693          	addi	a3,a3,-300 # ffffffffc02061d0 <commands+0x930>
ffffffffc0201304:	00005617          	auipc	a2,0x5
ffffffffc0201308:	db460613          	addi	a2,a2,-588 # ffffffffc02060b8 <commands+0x818>
ffffffffc020130c:	0de00593          	li	a1,222
ffffffffc0201310:	00005517          	auipc	a0,0x5
ffffffffc0201314:	dc050513          	addi	a0,a0,-576 # ffffffffc02060d0 <commands+0x830>
ffffffffc0201318:	976ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(!list_empty(&free_list));
ffffffffc020131c:	00005697          	auipc	a3,0x5
ffffffffc0201320:	f3c68693          	addi	a3,a3,-196 # ffffffffc0206258 <commands+0x9b8>
ffffffffc0201324:	00005617          	auipc	a2,0x5
ffffffffc0201328:	d9460613          	addi	a2,a2,-620 # ffffffffc02060b8 <commands+0x818>
ffffffffc020132c:	0f700593          	li	a1,247
ffffffffc0201330:	00005517          	auipc	a0,0x5
ffffffffc0201334:	da050513          	addi	a0,a0,-608 # ffffffffc02060d0 <commands+0x830>
ffffffffc0201338:	956ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020133c:	00005697          	auipc	a3,0x5
ffffffffc0201340:	dcc68693          	addi	a3,a3,-564 # ffffffffc0206108 <commands+0x868>
ffffffffc0201344:	00005617          	auipc	a2,0x5
ffffffffc0201348:	d7460613          	addi	a2,a2,-652 # ffffffffc02060b8 <commands+0x818>
ffffffffc020134c:	0f000593          	li	a1,240
ffffffffc0201350:	00005517          	auipc	a0,0x5
ffffffffc0201354:	d8050513          	addi	a0,a0,-640 # ffffffffc02060d0 <commands+0x830>
ffffffffc0201358:	936ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 3);
ffffffffc020135c:	00005697          	auipc	a3,0x5
ffffffffc0201360:	eec68693          	addi	a3,a3,-276 # ffffffffc0206248 <commands+0x9a8>
ffffffffc0201364:	00005617          	auipc	a2,0x5
ffffffffc0201368:	d5460613          	addi	a2,a2,-684 # ffffffffc02060b8 <commands+0x818>
ffffffffc020136c:	0ee00593          	li	a1,238
ffffffffc0201370:	00005517          	auipc	a0,0x5
ffffffffc0201374:	d6050513          	addi	a0,a0,-672 # ffffffffc02060d0 <commands+0x830>
ffffffffc0201378:	916ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc020137c:	00005697          	auipc	a3,0x5
ffffffffc0201380:	eb468693          	addi	a3,a3,-332 # ffffffffc0206230 <commands+0x990>
ffffffffc0201384:	00005617          	auipc	a2,0x5
ffffffffc0201388:	d3460613          	addi	a2,a2,-716 # ffffffffc02060b8 <commands+0x818>
ffffffffc020138c:	0e900593          	li	a1,233
ffffffffc0201390:	00005517          	auipc	a0,0x5
ffffffffc0201394:	d4050513          	addi	a0,a0,-704 # ffffffffc02060d0 <commands+0x830>
ffffffffc0201398:	8f6ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc020139c:	00005697          	auipc	a3,0x5
ffffffffc02013a0:	e7468693          	addi	a3,a3,-396 # ffffffffc0206210 <commands+0x970>
ffffffffc02013a4:	00005617          	auipc	a2,0x5
ffffffffc02013a8:	d1460613          	addi	a2,a2,-748 # ffffffffc02060b8 <commands+0x818>
ffffffffc02013ac:	0e000593          	li	a1,224
ffffffffc02013b0:	00005517          	auipc	a0,0x5
ffffffffc02013b4:	d2050513          	addi	a0,a0,-736 # ffffffffc02060d0 <commands+0x830>
ffffffffc02013b8:	8d6ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 != NULL);
ffffffffc02013bc:	00005697          	auipc	a3,0x5
ffffffffc02013c0:	ee468693          	addi	a3,a3,-284 # ffffffffc02062a0 <commands+0xa00>
ffffffffc02013c4:	00005617          	auipc	a2,0x5
ffffffffc02013c8:	cf460613          	addi	a2,a2,-780 # ffffffffc02060b8 <commands+0x818>
ffffffffc02013cc:	11800593          	li	a1,280
ffffffffc02013d0:	00005517          	auipc	a0,0x5
ffffffffc02013d4:	d0050513          	addi	a0,a0,-768 # ffffffffc02060d0 <commands+0x830>
ffffffffc02013d8:	8b6ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 0);
ffffffffc02013dc:	00005697          	auipc	a3,0x5
ffffffffc02013e0:	eb468693          	addi	a3,a3,-332 # ffffffffc0206290 <commands+0x9f0>
ffffffffc02013e4:	00005617          	auipc	a2,0x5
ffffffffc02013e8:	cd460613          	addi	a2,a2,-812 # ffffffffc02060b8 <commands+0x818>
ffffffffc02013ec:	0fd00593          	li	a1,253
ffffffffc02013f0:	00005517          	auipc	a0,0x5
ffffffffc02013f4:	ce050513          	addi	a0,a0,-800 # ffffffffc02060d0 <commands+0x830>
ffffffffc02013f8:	896ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02013fc:	00005697          	auipc	a3,0x5
ffffffffc0201400:	e3468693          	addi	a3,a3,-460 # ffffffffc0206230 <commands+0x990>
ffffffffc0201404:	00005617          	auipc	a2,0x5
ffffffffc0201408:	cb460613          	addi	a2,a2,-844 # ffffffffc02060b8 <commands+0x818>
ffffffffc020140c:	0fb00593          	li	a1,251
ffffffffc0201410:	00005517          	auipc	a0,0x5
ffffffffc0201414:	cc050513          	addi	a0,a0,-832 # ffffffffc02060d0 <commands+0x830>
ffffffffc0201418:	876ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc020141c:	00005697          	auipc	a3,0x5
ffffffffc0201420:	e5468693          	addi	a3,a3,-428 # ffffffffc0206270 <commands+0x9d0>
ffffffffc0201424:	00005617          	auipc	a2,0x5
ffffffffc0201428:	c9460613          	addi	a2,a2,-876 # ffffffffc02060b8 <commands+0x818>
ffffffffc020142c:	0fa00593          	li	a1,250
ffffffffc0201430:	00005517          	auipc	a0,0x5
ffffffffc0201434:	ca050513          	addi	a0,a0,-864 # ffffffffc02060d0 <commands+0x830>
ffffffffc0201438:	856ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020143c:	00005697          	auipc	a3,0x5
ffffffffc0201440:	ccc68693          	addi	a3,a3,-820 # ffffffffc0206108 <commands+0x868>
ffffffffc0201444:	00005617          	auipc	a2,0x5
ffffffffc0201448:	c7460613          	addi	a2,a2,-908 # ffffffffc02060b8 <commands+0x818>
ffffffffc020144c:	0d700593          	li	a1,215
ffffffffc0201450:	00005517          	auipc	a0,0x5
ffffffffc0201454:	c8050513          	addi	a0,a0,-896 # ffffffffc02060d0 <commands+0x830>
ffffffffc0201458:	836ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc020145c:	00005697          	auipc	a3,0x5
ffffffffc0201460:	dd468693          	addi	a3,a3,-556 # ffffffffc0206230 <commands+0x990>
ffffffffc0201464:	00005617          	auipc	a2,0x5
ffffffffc0201468:	c5460613          	addi	a2,a2,-940 # ffffffffc02060b8 <commands+0x818>
ffffffffc020146c:	0f400593          	li	a1,244
ffffffffc0201470:	00005517          	auipc	a0,0x5
ffffffffc0201474:	c6050513          	addi	a0,a0,-928 # ffffffffc02060d0 <commands+0x830>
ffffffffc0201478:	816ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020147c:	00005697          	auipc	a3,0x5
ffffffffc0201480:	ccc68693          	addi	a3,a3,-820 # ffffffffc0206148 <commands+0x8a8>
ffffffffc0201484:	00005617          	auipc	a2,0x5
ffffffffc0201488:	c3460613          	addi	a2,a2,-972 # ffffffffc02060b8 <commands+0x818>
ffffffffc020148c:	0f200593          	li	a1,242
ffffffffc0201490:	00005517          	auipc	a0,0x5
ffffffffc0201494:	c4050513          	addi	a0,a0,-960 # ffffffffc02060d0 <commands+0x830>
ffffffffc0201498:	ff7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020149c:	00005697          	auipc	a3,0x5
ffffffffc02014a0:	c8c68693          	addi	a3,a3,-884 # ffffffffc0206128 <commands+0x888>
ffffffffc02014a4:	00005617          	auipc	a2,0x5
ffffffffc02014a8:	c1460613          	addi	a2,a2,-1004 # ffffffffc02060b8 <commands+0x818>
ffffffffc02014ac:	0f100593          	li	a1,241
ffffffffc02014b0:	00005517          	auipc	a0,0x5
ffffffffc02014b4:	c2050513          	addi	a0,a0,-992 # ffffffffc02060d0 <commands+0x830>
ffffffffc02014b8:	fd7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02014bc:	00005697          	auipc	a3,0x5
ffffffffc02014c0:	c8c68693          	addi	a3,a3,-884 # ffffffffc0206148 <commands+0x8a8>
ffffffffc02014c4:	00005617          	auipc	a2,0x5
ffffffffc02014c8:	bf460613          	addi	a2,a2,-1036 # ffffffffc02060b8 <commands+0x818>
ffffffffc02014cc:	0d900593          	li	a1,217
ffffffffc02014d0:	00005517          	auipc	a0,0x5
ffffffffc02014d4:	c0050513          	addi	a0,a0,-1024 # ffffffffc02060d0 <commands+0x830>
ffffffffc02014d8:	fb7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(count == 0);
ffffffffc02014dc:	00005697          	auipc	a3,0x5
ffffffffc02014e0:	f1468693          	addi	a3,a3,-236 # ffffffffc02063f0 <commands+0xb50>
ffffffffc02014e4:	00005617          	auipc	a2,0x5
ffffffffc02014e8:	bd460613          	addi	a2,a2,-1068 # ffffffffc02060b8 <commands+0x818>
ffffffffc02014ec:	14600593          	li	a1,326
ffffffffc02014f0:	00005517          	auipc	a0,0x5
ffffffffc02014f4:	be050513          	addi	a0,a0,-1056 # ffffffffc02060d0 <commands+0x830>
ffffffffc02014f8:	f97fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 0);
ffffffffc02014fc:	00005697          	auipc	a3,0x5
ffffffffc0201500:	d9468693          	addi	a3,a3,-620 # ffffffffc0206290 <commands+0x9f0>
ffffffffc0201504:	00005617          	auipc	a2,0x5
ffffffffc0201508:	bb460613          	addi	a2,a2,-1100 # ffffffffc02060b8 <commands+0x818>
ffffffffc020150c:	13a00593          	li	a1,314
ffffffffc0201510:	00005517          	auipc	a0,0x5
ffffffffc0201514:	bc050513          	addi	a0,a0,-1088 # ffffffffc02060d0 <commands+0x830>
ffffffffc0201518:	f77fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc020151c:	00005697          	auipc	a3,0x5
ffffffffc0201520:	d1468693          	addi	a3,a3,-748 # ffffffffc0206230 <commands+0x990>
ffffffffc0201524:	00005617          	auipc	a2,0x5
ffffffffc0201528:	b9460613          	addi	a2,a2,-1132 # ffffffffc02060b8 <commands+0x818>
ffffffffc020152c:	13800593          	li	a1,312
ffffffffc0201530:	00005517          	auipc	a0,0x5
ffffffffc0201534:	ba050513          	addi	a0,a0,-1120 # ffffffffc02060d0 <commands+0x830>
ffffffffc0201538:	f57fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020153c:	00005697          	auipc	a3,0x5
ffffffffc0201540:	cb468693          	addi	a3,a3,-844 # ffffffffc02061f0 <commands+0x950>
ffffffffc0201544:	00005617          	auipc	a2,0x5
ffffffffc0201548:	b7460613          	addi	a2,a2,-1164 # ffffffffc02060b8 <commands+0x818>
ffffffffc020154c:	0df00593          	li	a1,223
ffffffffc0201550:	00005517          	auipc	a0,0x5
ffffffffc0201554:	b8050513          	addi	a0,a0,-1152 # ffffffffc02060d0 <commands+0x830>
ffffffffc0201558:	f37fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc020155c:	00005697          	auipc	a3,0x5
ffffffffc0201560:	e5468693          	addi	a3,a3,-428 # ffffffffc02063b0 <commands+0xb10>
ffffffffc0201564:	00005617          	auipc	a2,0x5
ffffffffc0201568:	b5460613          	addi	a2,a2,-1196 # ffffffffc02060b8 <commands+0x818>
ffffffffc020156c:	13200593          	li	a1,306
ffffffffc0201570:	00005517          	auipc	a0,0x5
ffffffffc0201574:	b6050513          	addi	a0,a0,-1184 # ffffffffc02060d0 <commands+0x830>
ffffffffc0201578:	f17fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc020157c:	00005697          	auipc	a3,0x5
ffffffffc0201580:	e1468693          	addi	a3,a3,-492 # ffffffffc0206390 <commands+0xaf0>
ffffffffc0201584:	00005617          	auipc	a2,0x5
ffffffffc0201588:	b3460613          	addi	a2,a2,-1228 # ffffffffc02060b8 <commands+0x818>
ffffffffc020158c:	13000593          	li	a1,304
ffffffffc0201590:	00005517          	auipc	a0,0x5
ffffffffc0201594:	b4050513          	addi	a0,a0,-1216 # ffffffffc02060d0 <commands+0x830>
ffffffffc0201598:	ef7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc020159c:	00005697          	auipc	a3,0x5
ffffffffc02015a0:	dcc68693          	addi	a3,a3,-564 # ffffffffc0206368 <commands+0xac8>
ffffffffc02015a4:	00005617          	auipc	a2,0x5
ffffffffc02015a8:	b1460613          	addi	a2,a2,-1260 # ffffffffc02060b8 <commands+0x818>
ffffffffc02015ac:	12e00593          	li	a1,302
ffffffffc02015b0:	00005517          	auipc	a0,0x5
ffffffffc02015b4:	b2050513          	addi	a0,a0,-1248 # ffffffffc02060d0 <commands+0x830>
ffffffffc02015b8:	ed7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02015bc:	00005697          	auipc	a3,0x5
ffffffffc02015c0:	d8468693          	addi	a3,a3,-636 # ffffffffc0206340 <commands+0xaa0>
ffffffffc02015c4:	00005617          	auipc	a2,0x5
ffffffffc02015c8:	af460613          	addi	a2,a2,-1292 # ffffffffc02060b8 <commands+0x818>
ffffffffc02015cc:	12d00593          	li	a1,301
ffffffffc02015d0:	00005517          	auipc	a0,0x5
ffffffffc02015d4:	b0050513          	addi	a0,a0,-1280 # ffffffffc02060d0 <commands+0x830>
ffffffffc02015d8:	eb7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 + 2 == p1);
ffffffffc02015dc:	00005697          	auipc	a3,0x5
ffffffffc02015e0:	d5468693          	addi	a3,a3,-684 # ffffffffc0206330 <commands+0xa90>
ffffffffc02015e4:	00005617          	auipc	a2,0x5
ffffffffc02015e8:	ad460613          	addi	a2,a2,-1324 # ffffffffc02060b8 <commands+0x818>
ffffffffc02015ec:	12800593          	li	a1,296
ffffffffc02015f0:	00005517          	auipc	a0,0x5
ffffffffc02015f4:	ae050513          	addi	a0,a0,-1312 # ffffffffc02060d0 <commands+0x830>
ffffffffc02015f8:	e97fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02015fc:	00005697          	auipc	a3,0x5
ffffffffc0201600:	c3468693          	addi	a3,a3,-972 # ffffffffc0206230 <commands+0x990>
ffffffffc0201604:	00005617          	auipc	a2,0x5
ffffffffc0201608:	ab460613          	addi	a2,a2,-1356 # ffffffffc02060b8 <commands+0x818>
ffffffffc020160c:	12700593          	li	a1,295
ffffffffc0201610:	00005517          	auipc	a0,0x5
ffffffffc0201614:	ac050513          	addi	a0,a0,-1344 # ffffffffc02060d0 <commands+0x830>
ffffffffc0201618:	e77fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc020161c:	00005697          	auipc	a3,0x5
ffffffffc0201620:	cf468693          	addi	a3,a3,-780 # ffffffffc0206310 <commands+0xa70>
ffffffffc0201624:	00005617          	auipc	a2,0x5
ffffffffc0201628:	a9460613          	addi	a2,a2,-1388 # ffffffffc02060b8 <commands+0x818>
ffffffffc020162c:	12600593          	li	a1,294
ffffffffc0201630:	00005517          	auipc	a0,0x5
ffffffffc0201634:	aa050513          	addi	a0,a0,-1376 # ffffffffc02060d0 <commands+0x830>
ffffffffc0201638:	e57fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc020163c:	00005697          	auipc	a3,0x5
ffffffffc0201640:	ca468693          	addi	a3,a3,-860 # ffffffffc02062e0 <commands+0xa40>
ffffffffc0201644:	00005617          	auipc	a2,0x5
ffffffffc0201648:	a7460613          	addi	a2,a2,-1420 # ffffffffc02060b8 <commands+0x818>
ffffffffc020164c:	12500593          	li	a1,293
ffffffffc0201650:	00005517          	auipc	a0,0x5
ffffffffc0201654:	a8050513          	addi	a0,a0,-1408 # ffffffffc02060d0 <commands+0x830>
ffffffffc0201658:	e37fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc020165c:	00005697          	auipc	a3,0x5
ffffffffc0201660:	c6c68693          	addi	a3,a3,-916 # ffffffffc02062c8 <commands+0xa28>
ffffffffc0201664:	00005617          	auipc	a2,0x5
ffffffffc0201668:	a5460613          	addi	a2,a2,-1452 # ffffffffc02060b8 <commands+0x818>
ffffffffc020166c:	12400593          	li	a1,292
ffffffffc0201670:	00005517          	auipc	a0,0x5
ffffffffc0201674:	a6050513          	addi	a0,a0,-1440 # ffffffffc02060d0 <commands+0x830>
ffffffffc0201678:	e17fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc020167c:	00005697          	auipc	a3,0x5
ffffffffc0201680:	bb468693          	addi	a3,a3,-1100 # ffffffffc0206230 <commands+0x990>
ffffffffc0201684:	00005617          	auipc	a2,0x5
ffffffffc0201688:	a3460613          	addi	a2,a2,-1484 # ffffffffc02060b8 <commands+0x818>
ffffffffc020168c:	11e00593          	li	a1,286
ffffffffc0201690:	00005517          	auipc	a0,0x5
ffffffffc0201694:	a4050513          	addi	a0,a0,-1472 # ffffffffc02060d0 <commands+0x830>
ffffffffc0201698:	df7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(!PageProperty(p0));
ffffffffc020169c:	00005697          	auipc	a3,0x5
ffffffffc02016a0:	c1468693          	addi	a3,a3,-1004 # ffffffffc02062b0 <commands+0xa10>
ffffffffc02016a4:	00005617          	auipc	a2,0x5
ffffffffc02016a8:	a1460613          	addi	a2,a2,-1516 # ffffffffc02060b8 <commands+0x818>
ffffffffc02016ac:	11900593          	li	a1,281
ffffffffc02016b0:	00005517          	auipc	a0,0x5
ffffffffc02016b4:	a2050513          	addi	a0,a0,-1504 # ffffffffc02060d0 <commands+0x830>
ffffffffc02016b8:	dd7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02016bc:	00005697          	auipc	a3,0x5
ffffffffc02016c0:	d1468693          	addi	a3,a3,-748 # ffffffffc02063d0 <commands+0xb30>
ffffffffc02016c4:	00005617          	auipc	a2,0x5
ffffffffc02016c8:	9f460613          	addi	a2,a2,-1548 # ffffffffc02060b8 <commands+0x818>
ffffffffc02016cc:	13700593          	li	a1,311
ffffffffc02016d0:	00005517          	auipc	a0,0x5
ffffffffc02016d4:	a0050513          	addi	a0,a0,-1536 # ffffffffc02060d0 <commands+0x830>
ffffffffc02016d8:	db7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(total == 0);
ffffffffc02016dc:	00005697          	auipc	a3,0x5
ffffffffc02016e0:	d2468693          	addi	a3,a3,-732 # ffffffffc0206400 <commands+0xb60>
ffffffffc02016e4:	00005617          	auipc	a2,0x5
ffffffffc02016e8:	9d460613          	addi	a2,a2,-1580 # ffffffffc02060b8 <commands+0x818>
ffffffffc02016ec:	14700593          	li	a1,327
ffffffffc02016f0:	00005517          	auipc	a0,0x5
ffffffffc02016f4:	9e050513          	addi	a0,a0,-1568 # ffffffffc02060d0 <commands+0x830>
ffffffffc02016f8:	d97fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(total == nr_free_pages());
ffffffffc02016fc:	00005697          	auipc	a3,0x5
ffffffffc0201700:	9ec68693          	addi	a3,a3,-1556 # ffffffffc02060e8 <commands+0x848>
ffffffffc0201704:	00005617          	auipc	a2,0x5
ffffffffc0201708:	9b460613          	addi	a2,a2,-1612 # ffffffffc02060b8 <commands+0x818>
ffffffffc020170c:	11300593          	li	a1,275
ffffffffc0201710:	00005517          	auipc	a0,0x5
ffffffffc0201714:	9c050513          	addi	a0,a0,-1600 # ffffffffc02060d0 <commands+0x830>
ffffffffc0201718:	d77fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020171c:	00005697          	auipc	a3,0x5
ffffffffc0201720:	a0c68693          	addi	a3,a3,-1524 # ffffffffc0206128 <commands+0x888>
ffffffffc0201724:	00005617          	auipc	a2,0x5
ffffffffc0201728:	99460613          	addi	a2,a2,-1644 # ffffffffc02060b8 <commands+0x818>
ffffffffc020172c:	0d800593          	li	a1,216
ffffffffc0201730:	00005517          	auipc	a0,0x5
ffffffffc0201734:	9a050513          	addi	a0,a0,-1632 # ffffffffc02060d0 <commands+0x830>
ffffffffc0201738:	d57fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020173c <default_free_pages>:
{
ffffffffc020173c:	1141                	addi	sp,sp,-16
ffffffffc020173e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201740:	14058463          	beqz	a1,ffffffffc0201888 <default_free_pages+0x14c>
    for (; p != base + n; p++)
ffffffffc0201744:	00659693          	slli	a3,a1,0x6
ffffffffc0201748:	96aa                	add	a3,a3,a0
ffffffffc020174a:	87aa                	mv	a5,a0
ffffffffc020174c:	02d50263          	beq	a0,a3,ffffffffc0201770 <default_free_pages+0x34>
ffffffffc0201750:	6798                	ld	a4,8(a5)
ffffffffc0201752:	8b05                	andi	a4,a4,1
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201754:	10071a63          	bnez	a4,ffffffffc0201868 <default_free_pages+0x12c>
ffffffffc0201758:	6798                	ld	a4,8(a5)
ffffffffc020175a:	8b09                	andi	a4,a4,2
ffffffffc020175c:	10071663          	bnez	a4,ffffffffc0201868 <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc0201760:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc0201764:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201768:	04078793          	addi	a5,a5,64
ffffffffc020176c:	fed792e3          	bne	a5,a3,ffffffffc0201750 <default_free_pages+0x14>
    base->property = n;
ffffffffc0201770:	2581                	sext.w	a1,a1
ffffffffc0201772:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201774:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201778:	4789                	li	a5,2
ffffffffc020177a:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc020177e:	000a5697          	auipc	a3,0xa5
ffffffffc0201782:	eea68693          	addi	a3,a3,-278 # ffffffffc02a6668 <free_area>
ffffffffc0201786:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201788:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc020178a:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc020178e:	9db9                	addw	a1,a1,a4
ffffffffc0201790:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc0201792:	0ad78463          	beq	a5,a3,ffffffffc020183a <default_free_pages+0xfe>
            struct Page *page = le2page(le, page_link);
ffffffffc0201796:	fe878713          	addi	a4,a5,-24
ffffffffc020179a:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc020179e:	4581                	li	a1,0
            if (base < page)
ffffffffc02017a0:	00e56a63          	bltu	a0,a4,ffffffffc02017b4 <default_free_pages+0x78>
    return listelm->next;
ffffffffc02017a4:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc02017a6:	04d70c63          	beq	a4,a3,ffffffffc02017fe <default_free_pages+0xc2>
    for (; p != base + n; p++)
ffffffffc02017aa:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02017ac:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc02017b0:	fee57ae3          	bgeu	a0,a4,ffffffffc02017a4 <default_free_pages+0x68>
ffffffffc02017b4:	c199                	beqz	a1,ffffffffc02017ba <default_free_pages+0x7e>
ffffffffc02017b6:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02017ba:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02017bc:	e390                	sd	a2,0(a5)
ffffffffc02017be:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02017c0:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02017c2:	ed18                	sd	a4,24(a0)
    if (le != &free_list)
ffffffffc02017c4:	00d70d63          	beq	a4,a3,ffffffffc02017de <default_free_pages+0xa2>
        if (p + p->property == base)
ffffffffc02017c8:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc02017cc:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base)
ffffffffc02017d0:	02059813          	slli	a6,a1,0x20
ffffffffc02017d4:	01a85793          	srli	a5,a6,0x1a
ffffffffc02017d8:	97b2                	add	a5,a5,a2
ffffffffc02017da:	02f50c63          	beq	a0,a5,ffffffffc0201812 <default_free_pages+0xd6>
    return listelm->next;
ffffffffc02017de:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc02017e0:	00d78c63          	beq	a5,a3,ffffffffc02017f8 <default_free_pages+0xbc>
        if (base + base->property == p)
ffffffffc02017e4:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc02017e6:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p)
ffffffffc02017ea:	02061593          	slli	a1,a2,0x20
ffffffffc02017ee:	01a5d713          	srli	a4,a1,0x1a
ffffffffc02017f2:	972a                	add	a4,a4,a0
ffffffffc02017f4:	04e68a63          	beq	a3,a4,ffffffffc0201848 <default_free_pages+0x10c>
}
ffffffffc02017f8:	60a2                	ld	ra,8(sp)
ffffffffc02017fa:	0141                	addi	sp,sp,16
ffffffffc02017fc:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02017fe:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201800:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201802:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201804:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201806:	02d70763          	beq	a4,a3,ffffffffc0201834 <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc020180a:	8832                	mv	a6,a2
ffffffffc020180c:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc020180e:	87ba                	mv	a5,a4
ffffffffc0201810:	bf71                	j	ffffffffc02017ac <default_free_pages+0x70>
            p->property += base->property;
ffffffffc0201812:	491c                	lw	a5,16(a0)
ffffffffc0201814:	9dbd                	addw	a1,a1,a5
ffffffffc0201816:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020181a:	57f5                	li	a5,-3
ffffffffc020181c:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201820:	01853803          	ld	a6,24(a0)
ffffffffc0201824:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc0201826:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201828:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc020182c:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc020182e:	0105b023          	sd	a6,0(a1)
ffffffffc0201832:	b77d                	j	ffffffffc02017e0 <default_free_pages+0xa4>
ffffffffc0201834:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201836:	873e                	mv	a4,a5
ffffffffc0201838:	bf41                	j	ffffffffc02017c8 <default_free_pages+0x8c>
}
ffffffffc020183a:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc020183c:	e390                	sd	a2,0(a5)
ffffffffc020183e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201840:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201842:	ed1c                	sd	a5,24(a0)
ffffffffc0201844:	0141                	addi	sp,sp,16
ffffffffc0201846:	8082                	ret
            base->property += p->property;
ffffffffc0201848:	ff87a703          	lw	a4,-8(a5)
ffffffffc020184c:	ff078693          	addi	a3,a5,-16
ffffffffc0201850:	9e39                	addw	a2,a2,a4
ffffffffc0201852:	c910                	sw	a2,16(a0)
ffffffffc0201854:	5775                	li	a4,-3
ffffffffc0201856:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc020185a:	6398                	ld	a4,0(a5)
ffffffffc020185c:	679c                	ld	a5,8(a5)
}
ffffffffc020185e:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201860:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0201862:	e398                	sd	a4,0(a5)
ffffffffc0201864:	0141                	addi	sp,sp,16
ffffffffc0201866:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201868:	00005697          	auipc	a3,0x5
ffffffffc020186c:	bb068693          	addi	a3,a3,-1104 # ffffffffc0206418 <commands+0xb78>
ffffffffc0201870:	00005617          	auipc	a2,0x5
ffffffffc0201874:	84860613          	addi	a2,a2,-1976 # ffffffffc02060b8 <commands+0x818>
ffffffffc0201878:	09400593          	li	a1,148
ffffffffc020187c:	00005517          	auipc	a0,0x5
ffffffffc0201880:	85450513          	addi	a0,a0,-1964 # ffffffffc02060d0 <commands+0x830>
ffffffffc0201884:	c0bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(n > 0);
ffffffffc0201888:	00005697          	auipc	a3,0x5
ffffffffc020188c:	b8868693          	addi	a3,a3,-1144 # ffffffffc0206410 <commands+0xb70>
ffffffffc0201890:	00005617          	auipc	a2,0x5
ffffffffc0201894:	82860613          	addi	a2,a2,-2008 # ffffffffc02060b8 <commands+0x818>
ffffffffc0201898:	09000593          	li	a1,144
ffffffffc020189c:	00005517          	auipc	a0,0x5
ffffffffc02018a0:	83450513          	addi	a0,a0,-1996 # ffffffffc02060d0 <commands+0x830>
ffffffffc02018a4:	bebfe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02018a8 <default_alloc_pages>:
    assert(n > 0);
ffffffffc02018a8:	c941                	beqz	a0,ffffffffc0201938 <default_alloc_pages+0x90>
    if (n > nr_free)
ffffffffc02018aa:	000a5597          	auipc	a1,0xa5
ffffffffc02018ae:	dbe58593          	addi	a1,a1,-578 # ffffffffc02a6668 <free_area>
ffffffffc02018b2:	0105a803          	lw	a6,16(a1)
ffffffffc02018b6:	872a                	mv	a4,a0
ffffffffc02018b8:	02081793          	slli	a5,a6,0x20
ffffffffc02018bc:	9381                	srli	a5,a5,0x20
ffffffffc02018be:	00a7ee63          	bltu	a5,a0,ffffffffc02018da <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc02018c2:	87ae                	mv	a5,a1
ffffffffc02018c4:	a801                	j	ffffffffc02018d4 <default_alloc_pages+0x2c>
        if (p->property >= n)
ffffffffc02018c6:	ff87a683          	lw	a3,-8(a5)
ffffffffc02018ca:	02069613          	slli	a2,a3,0x20
ffffffffc02018ce:	9201                	srli	a2,a2,0x20
ffffffffc02018d0:	00e67763          	bgeu	a2,a4,ffffffffc02018de <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc02018d4:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc02018d6:	feb798e3          	bne	a5,a1,ffffffffc02018c6 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc02018da:	4501                	li	a0,0
}
ffffffffc02018dc:	8082                	ret
    return listelm->prev;
ffffffffc02018de:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02018e2:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc02018e6:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc02018ea:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc02018ee:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc02018f2:	01133023          	sd	a7,0(t1)
        if (page->property > n)
ffffffffc02018f6:	02c77863          	bgeu	a4,a2,ffffffffc0201926 <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc02018fa:	071a                	slli	a4,a4,0x6
ffffffffc02018fc:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc02018fe:	41c686bb          	subw	a3,a3,t3
ffffffffc0201902:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201904:	00870613          	addi	a2,a4,8
ffffffffc0201908:	4689                	li	a3,2
ffffffffc020190a:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc020190e:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc0201912:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc0201916:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc020191a:	e290                	sd	a2,0(a3)
ffffffffc020191c:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc0201920:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc0201922:	01173c23          	sd	a7,24(a4)
ffffffffc0201926:	41c8083b          	subw	a6,a6,t3
ffffffffc020192a:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020192e:	5775                	li	a4,-3
ffffffffc0201930:	17c1                	addi	a5,a5,-16
ffffffffc0201932:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0201936:	8082                	ret
{
ffffffffc0201938:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc020193a:	00005697          	auipc	a3,0x5
ffffffffc020193e:	ad668693          	addi	a3,a3,-1322 # ffffffffc0206410 <commands+0xb70>
ffffffffc0201942:	00004617          	auipc	a2,0x4
ffffffffc0201946:	77660613          	addi	a2,a2,1910 # ffffffffc02060b8 <commands+0x818>
ffffffffc020194a:	06c00593          	li	a1,108
ffffffffc020194e:	00004517          	auipc	a0,0x4
ffffffffc0201952:	78250513          	addi	a0,a0,1922 # ffffffffc02060d0 <commands+0x830>
{
ffffffffc0201956:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201958:	b37fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020195c <default_init_memmap>:
{
ffffffffc020195c:	1141                	addi	sp,sp,-16
ffffffffc020195e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201960:	c5f1                	beqz	a1,ffffffffc0201a2c <default_init_memmap+0xd0>
    for (; p != base + n; p++)
ffffffffc0201962:	00659693          	slli	a3,a1,0x6
ffffffffc0201966:	96aa                	add	a3,a3,a0
ffffffffc0201968:	87aa                	mv	a5,a0
ffffffffc020196a:	00d50f63          	beq	a0,a3,ffffffffc0201988 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020196e:	6798                	ld	a4,8(a5)
ffffffffc0201970:	8b05                	andi	a4,a4,1
        assert(PageReserved(p));
ffffffffc0201972:	cf49                	beqz	a4,ffffffffc0201a0c <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc0201974:	0007a823          	sw	zero,16(a5)
ffffffffc0201978:	0007b423          	sd	zero,8(a5)
ffffffffc020197c:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201980:	04078793          	addi	a5,a5,64
ffffffffc0201984:	fed795e3          	bne	a5,a3,ffffffffc020196e <default_init_memmap+0x12>
    base->property = n;
ffffffffc0201988:	2581                	sext.w	a1,a1
ffffffffc020198a:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020198c:	4789                	li	a5,2
ffffffffc020198e:	00850713          	addi	a4,a0,8
ffffffffc0201992:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201996:	000a5697          	auipc	a3,0xa5
ffffffffc020199a:	cd268693          	addi	a3,a3,-814 # ffffffffc02a6668 <free_area>
ffffffffc020199e:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02019a0:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02019a2:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02019a6:	9db9                	addw	a1,a1,a4
ffffffffc02019a8:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc02019aa:	04d78a63          	beq	a5,a3,ffffffffc02019fe <default_init_memmap+0xa2>
            struct Page *page = le2page(le, page_link);
ffffffffc02019ae:	fe878713          	addi	a4,a5,-24
ffffffffc02019b2:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc02019b6:	4581                	li	a1,0
            if (base < page)
ffffffffc02019b8:	00e56a63          	bltu	a0,a4,ffffffffc02019cc <default_init_memmap+0x70>
    return listelm->next;
ffffffffc02019bc:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc02019be:	02d70263          	beq	a4,a3,ffffffffc02019e2 <default_init_memmap+0x86>
    for (; p != base + n; p++)
ffffffffc02019c2:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02019c4:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc02019c8:	fee57ae3          	bgeu	a0,a4,ffffffffc02019bc <default_init_memmap+0x60>
ffffffffc02019cc:	c199                	beqz	a1,ffffffffc02019d2 <default_init_memmap+0x76>
ffffffffc02019ce:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02019d2:	6398                	ld	a4,0(a5)
}
ffffffffc02019d4:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02019d6:	e390                	sd	a2,0(a5)
ffffffffc02019d8:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02019da:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02019dc:	ed18                	sd	a4,24(a0)
ffffffffc02019de:	0141                	addi	sp,sp,16
ffffffffc02019e0:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02019e2:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02019e4:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02019e6:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02019e8:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc02019ea:	00d70663          	beq	a4,a3,ffffffffc02019f6 <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc02019ee:	8832                	mv	a6,a2
ffffffffc02019f0:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc02019f2:	87ba                	mv	a5,a4
ffffffffc02019f4:	bfc1                	j	ffffffffc02019c4 <default_init_memmap+0x68>
}
ffffffffc02019f6:	60a2                	ld	ra,8(sp)
ffffffffc02019f8:	e290                	sd	a2,0(a3)
ffffffffc02019fa:	0141                	addi	sp,sp,16
ffffffffc02019fc:	8082                	ret
ffffffffc02019fe:	60a2                	ld	ra,8(sp)
ffffffffc0201a00:	e390                	sd	a2,0(a5)
ffffffffc0201a02:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201a04:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201a06:	ed1c                	sd	a5,24(a0)
ffffffffc0201a08:	0141                	addi	sp,sp,16
ffffffffc0201a0a:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201a0c:	00005697          	auipc	a3,0x5
ffffffffc0201a10:	a3468693          	addi	a3,a3,-1484 # ffffffffc0206440 <commands+0xba0>
ffffffffc0201a14:	00004617          	auipc	a2,0x4
ffffffffc0201a18:	6a460613          	addi	a2,a2,1700 # ffffffffc02060b8 <commands+0x818>
ffffffffc0201a1c:	04b00593          	li	a1,75
ffffffffc0201a20:	00004517          	auipc	a0,0x4
ffffffffc0201a24:	6b050513          	addi	a0,a0,1712 # ffffffffc02060d0 <commands+0x830>
ffffffffc0201a28:	a67fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(n > 0);
ffffffffc0201a2c:	00005697          	auipc	a3,0x5
ffffffffc0201a30:	9e468693          	addi	a3,a3,-1564 # ffffffffc0206410 <commands+0xb70>
ffffffffc0201a34:	00004617          	auipc	a2,0x4
ffffffffc0201a38:	68460613          	addi	a2,a2,1668 # ffffffffc02060b8 <commands+0x818>
ffffffffc0201a3c:	04700593          	li	a1,71
ffffffffc0201a40:	00004517          	auipc	a0,0x4
ffffffffc0201a44:	69050513          	addi	a0,a0,1680 # ffffffffc02060d0 <commands+0x830>
ffffffffc0201a48:	a47fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201a4c <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201a4c:	c94d                	beqz	a0,ffffffffc0201afe <slob_free+0xb2>
{
ffffffffc0201a4e:	1141                	addi	sp,sp,-16
ffffffffc0201a50:	e022                	sd	s0,0(sp)
ffffffffc0201a52:	e406                	sd	ra,8(sp)
ffffffffc0201a54:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc0201a56:	e9c1                	bnez	a1,ffffffffc0201ae6 <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201a58:	100027f3          	csrr	a5,sstatus
ffffffffc0201a5c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201a5e:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201a60:	ebd9                	bnez	a5,ffffffffc0201af6 <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201a62:	000a4617          	auipc	a2,0xa4
ffffffffc0201a66:	7f660613          	addi	a2,a2,2038 # ffffffffc02a6258 <slobfree>
ffffffffc0201a6a:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a6c:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201a6e:	679c                	ld	a5,8(a5)
ffffffffc0201a70:	02877a63          	bgeu	a4,s0,ffffffffc0201aa4 <slob_free+0x58>
ffffffffc0201a74:	00f46463          	bltu	s0,a5,ffffffffc0201a7c <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a78:	fef76ae3          	bltu	a4,a5,ffffffffc0201a6c <slob_free+0x20>
			break;

	if (b + b->units == cur->next)
ffffffffc0201a7c:	400c                	lw	a1,0(s0)
ffffffffc0201a7e:	00459693          	slli	a3,a1,0x4
ffffffffc0201a82:	96a2                	add	a3,a3,s0
ffffffffc0201a84:	02d78a63          	beq	a5,a3,ffffffffc0201ab8 <slob_free+0x6c>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc0201a88:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc0201a8a:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201a8c:	00469793          	slli	a5,a3,0x4
ffffffffc0201a90:	97ba                	add	a5,a5,a4
ffffffffc0201a92:	02f40e63          	beq	s0,a5,ffffffffc0201ace <slob_free+0x82>
	{
		cur->units += b->units;
		cur->next = b->next;
	}
	else
		cur->next = b;
ffffffffc0201a96:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc0201a98:	e218                	sd	a4,0(a2)
    if (flag)
ffffffffc0201a9a:	e129                	bnez	a0,ffffffffc0201adc <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201a9c:	60a2                	ld	ra,8(sp)
ffffffffc0201a9e:	6402                	ld	s0,0(sp)
ffffffffc0201aa0:	0141                	addi	sp,sp,16
ffffffffc0201aa2:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201aa4:	fcf764e3          	bltu	a4,a5,ffffffffc0201a6c <slob_free+0x20>
ffffffffc0201aa8:	fcf472e3          	bgeu	s0,a5,ffffffffc0201a6c <slob_free+0x20>
	if (b + b->units == cur->next)
ffffffffc0201aac:	400c                	lw	a1,0(s0)
ffffffffc0201aae:	00459693          	slli	a3,a1,0x4
ffffffffc0201ab2:	96a2                	add	a3,a3,s0
ffffffffc0201ab4:	fcd79ae3          	bne	a5,a3,ffffffffc0201a88 <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc0201ab8:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201aba:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201abc:	9db5                	addw	a1,a1,a3
ffffffffc0201abe:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b)
ffffffffc0201ac0:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0201ac2:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201ac4:	00469793          	slli	a5,a3,0x4
ffffffffc0201ac8:	97ba                	add	a5,a5,a4
ffffffffc0201aca:	fcf416e3          	bne	s0,a5,ffffffffc0201a96 <slob_free+0x4a>
		cur->units += b->units;
ffffffffc0201ace:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc0201ad0:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc0201ad2:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc0201ad4:	9ebd                	addw	a3,a3,a5
ffffffffc0201ad6:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc0201ad8:	e70c                	sd	a1,8(a4)
ffffffffc0201ada:	d169                	beqz	a0,ffffffffc0201a9c <slob_free+0x50>
}
ffffffffc0201adc:	6402                	ld	s0,0(sp)
ffffffffc0201ade:	60a2                	ld	ra,8(sp)
ffffffffc0201ae0:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0201ae2:	ecdfe06f          	j	ffffffffc02009ae <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc0201ae6:	25bd                	addiw	a1,a1,15
ffffffffc0201ae8:	8191                	srli	a1,a1,0x4
ffffffffc0201aea:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201aec:	100027f3          	csrr	a5,sstatus
ffffffffc0201af0:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201af2:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201af4:	d7bd                	beqz	a5,ffffffffc0201a62 <slob_free+0x16>
        intr_disable();
ffffffffc0201af6:	ebffe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0201afa:	4505                	li	a0,1
ffffffffc0201afc:	b79d                	j	ffffffffc0201a62 <slob_free+0x16>
ffffffffc0201afe:	8082                	ret

ffffffffc0201b00 <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b00:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201b02:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b04:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201b08:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b0a:	352000ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
	if (!page)
ffffffffc0201b0e:	c91d                	beqz	a0,ffffffffc0201b44 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201b10:	000a9697          	auipc	a3,0xa9
ffffffffc0201b14:	bc86b683          	ld	a3,-1080(a3) # ffffffffc02aa6d8 <pages>
ffffffffc0201b18:	8d15                	sub	a0,a0,a3
ffffffffc0201b1a:	8519                	srai	a0,a0,0x6
ffffffffc0201b1c:	00006697          	auipc	a3,0x6
ffffffffc0201b20:	c446b683          	ld	a3,-956(a3) # ffffffffc0207760 <nbase>
ffffffffc0201b24:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc0201b26:	00c51793          	slli	a5,a0,0xc
ffffffffc0201b2a:	83b1                	srli	a5,a5,0xc
ffffffffc0201b2c:	000a9717          	auipc	a4,0xa9
ffffffffc0201b30:	ba473703          	ld	a4,-1116(a4) # ffffffffc02aa6d0 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0201b34:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201b36:	00e7fa63          	bgeu	a5,a4,ffffffffc0201b4a <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201b3a:	000a9697          	auipc	a3,0xa9
ffffffffc0201b3e:	bae6b683          	ld	a3,-1106(a3) # ffffffffc02aa6e8 <va_pa_offset>
ffffffffc0201b42:	9536                	add	a0,a0,a3
}
ffffffffc0201b44:	60a2                	ld	ra,8(sp)
ffffffffc0201b46:	0141                	addi	sp,sp,16
ffffffffc0201b48:	8082                	ret
ffffffffc0201b4a:	86aa                	mv	a3,a0
ffffffffc0201b4c:	00005617          	auipc	a2,0x5
ffffffffc0201b50:	95460613          	addi	a2,a2,-1708 # ffffffffc02064a0 <default_pmm_manager+0x38>
ffffffffc0201b54:	07100593          	li	a1,113
ffffffffc0201b58:	00005517          	auipc	a0,0x5
ffffffffc0201b5c:	97050513          	addi	a0,a0,-1680 # ffffffffc02064c8 <default_pmm_manager+0x60>
ffffffffc0201b60:	92ffe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201b64 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201b64:	1101                	addi	sp,sp,-32
ffffffffc0201b66:	ec06                	sd	ra,24(sp)
ffffffffc0201b68:	e822                	sd	s0,16(sp)
ffffffffc0201b6a:	e426                	sd	s1,8(sp)
ffffffffc0201b6c:	e04a                	sd	s2,0(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201b6e:	01050713          	addi	a4,a0,16
ffffffffc0201b72:	6785                	lui	a5,0x1
ffffffffc0201b74:	0cf77363          	bgeu	a4,a5,ffffffffc0201c3a <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201b78:	00f50493          	addi	s1,a0,15
ffffffffc0201b7c:	8091                	srli	s1,s1,0x4
ffffffffc0201b7e:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b80:	10002673          	csrr	a2,sstatus
ffffffffc0201b84:	8a09                	andi	a2,a2,2
ffffffffc0201b86:	e25d                	bnez	a2,ffffffffc0201c2c <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc0201b88:	000a4917          	auipc	s2,0xa4
ffffffffc0201b8c:	6d090913          	addi	s2,s2,1744 # ffffffffc02a6258 <slobfree>
ffffffffc0201b90:	00093683          	ld	a3,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201b94:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta)
ffffffffc0201b96:	4398                	lw	a4,0(a5)
ffffffffc0201b98:	08975e63          	bge	a4,s1,ffffffffc0201c34 <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree)
ffffffffc0201b9c:	00f68b63          	beq	a3,a5,ffffffffc0201bb2 <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201ba0:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201ba2:	4018                	lw	a4,0(s0)
ffffffffc0201ba4:	02975a63          	bge	a4,s1,ffffffffc0201bd8 <slob_alloc.constprop.0+0x74>
		if (cur == slobfree)
ffffffffc0201ba8:	00093683          	ld	a3,0(s2)
ffffffffc0201bac:	87a2                	mv	a5,s0
ffffffffc0201bae:	fef699e3          	bne	a3,a5,ffffffffc0201ba0 <slob_alloc.constprop.0+0x3c>
    if (flag)
ffffffffc0201bb2:	ee31                	bnez	a2,ffffffffc0201c0e <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201bb4:	4501                	li	a0,0
ffffffffc0201bb6:	f4bff0ef          	jal	ra,ffffffffc0201b00 <__slob_get_free_pages.constprop.0>
ffffffffc0201bba:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0201bbc:	cd05                	beqz	a0,ffffffffc0201bf4 <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201bbe:	6585                	lui	a1,0x1
ffffffffc0201bc0:	e8dff0ef          	jal	ra,ffffffffc0201a4c <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201bc4:	10002673          	csrr	a2,sstatus
ffffffffc0201bc8:	8a09                	andi	a2,a2,2
ffffffffc0201bca:	ee05                	bnez	a2,ffffffffc0201c02 <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0201bcc:	00093783          	ld	a5,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201bd0:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201bd2:	4018                	lw	a4,0(s0)
ffffffffc0201bd4:	fc974ae3          	blt	a4,s1,ffffffffc0201ba8 <slob_alloc.constprop.0+0x44>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201bd8:	04e48763          	beq	s1,a4,ffffffffc0201c26 <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0201bdc:	00449693          	slli	a3,s1,0x4
ffffffffc0201be0:	96a2                	add	a3,a3,s0
ffffffffc0201be2:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0201be4:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc0201be6:	9f05                	subw	a4,a4,s1
ffffffffc0201be8:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201bea:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0201bec:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0201bee:	00f93023          	sd	a5,0(s2)
    if (flag)
ffffffffc0201bf2:	e20d                	bnez	a2,ffffffffc0201c14 <slob_alloc.constprop.0+0xb0>
}
ffffffffc0201bf4:	60e2                	ld	ra,24(sp)
ffffffffc0201bf6:	8522                	mv	a0,s0
ffffffffc0201bf8:	6442                	ld	s0,16(sp)
ffffffffc0201bfa:	64a2                	ld	s1,8(sp)
ffffffffc0201bfc:	6902                	ld	s2,0(sp)
ffffffffc0201bfe:	6105                	addi	sp,sp,32
ffffffffc0201c00:	8082                	ret
        intr_disable();
ffffffffc0201c02:	db3fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
			cur = slobfree;
ffffffffc0201c06:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc0201c0a:	4605                	li	a2,1
ffffffffc0201c0c:	b7d1                	j	ffffffffc0201bd0 <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc0201c0e:	da1fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201c12:	b74d                	j	ffffffffc0201bb4 <slob_alloc.constprop.0+0x50>
ffffffffc0201c14:	d9bfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
}
ffffffffc0201c18:	60e2                	ld	ra,24(sp)
ffffffffc0201c1a:	8522                	mv	a0,s0
ffffffffc0201c1c:	6442                	ld	s0,16(sp)
ffffffffc0201c1e:	64a2                	ld	s1,8(sp)
ffffffffc0201c20:	6902                	ld	s2,0(sp)
ffffffffc0201c22:	6105                	addi	sp,sp,32
ffffffffc0201c24:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201c26:	6418                	ld	a4,8(s0)
ffffffffc0201c28:	e798                	sd	a4,8(a5)
ffffffffc0201c2a:	b7d1                	j	ffffffffc0201bee <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0201c2c:	d89fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0201c30:	4605                	li	a2,1
ffffffffc0201c32:	bf99                	j	ffffffffc0201b88 <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta)
ffffffffc0201c34:	843e                	mv	s0,a5
ffffffffc0201c36:	87b6                	mv	a5,a3
ffffffffc0201c38:	b745                	j	ffffffffc0201bd8 <slob_alloc.constprop.0+0x74>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201c3a:	00005697          	auipc	a3,0x5
ffffffffc0201c3e:	89e68693          	addi	a3,a3,-1890 # ffffffffc02064d8 <default_pmm_manager+0x70>
ffffffffc0201c42:	00004617          	auipc	a2,0x4
ffffffffc0201c46:	47660613          	addi	a2,a2,1142 # ffffffffc02060b8 <commands+0x818>
ffffffffc0201c4a:	06300593          	li	a1,99
ffffffffc0201c4e:	00005517          	auipc	a0,0x5
ffffffffc0201c52:	8aa50513          	addi	a0,a0,-1878 # ffffffffc02064f8 <default_pmm_manager+0x90>
ffffffffc0201c56:	839fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201c5a <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201c5a:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201c5c:	00005517          	auipc	a0,0x5
ffffffffc0201c60:	8b450513          	addi	a0,a0,-1868 # ffffffffc0206510 <default_pmm_manager+0xa8>
{
ffffffffc0201c64:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201c66:	d2efe0ef          	jal	ra,ffffffffc0200194 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201c6a:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201c6c:	00005517          	auipc	a0,0x5
ffffffffc0201c70:	8bc50513          	addi	a0,a0,-1860 # ffffffffc0206528 <default_pmm_manager+0xc0>
}
ffffffffc0201c74:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201c76:	d1efe06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0201c7a <kallocated>:

size_t
kallocated(void)
{
	return slob_allocated();
}
ffffffffc0201c7a:	4501                	li	a0,0
ffffffffc0201c7c:	8082                	ret

ffffffffc0201c7e <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201c7e:	1101                	addi	sp,sp,-32
ffffffffc0201c80:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201c82:	6905                	lui	s2,0x1
{
ffffffffc0201c84:	e822                	sd	s0,16(sp)
ffffffffc0201c86:	ec06                	sd	ra,24(sp)
ffffffffc0201c88:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201c8a:	fef90793          	addi	a5,s2,-17 # fef <_binary_obj___user_faultread_out_size-0x8bb9>
{
ffffffffc0201c8e:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201c90:	04a7f963          	bgeu	a5,a0,ffffffffc0201ce2 <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201c94:	4561                	li	a0,24
ffffffffc0201c96:	ecfff0ef          	jal	ra,ffffffffc0201b64 <slob_alloc.constprop.0>
ffffffffc0201c9a:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201c9c:	c929                	beqz	a0,ffffffffc0201cee <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0201c9e:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201ca2:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201ca4:	00f95763          	bge	s2,a5,ffffffffc0201cb2 <kmalloc+0x34>
ffffffffc0201ca8:	6705                	lui	a4,0x1
ffffffffc0201caa:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201cac:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201cae:	fef74ee3          	blt	a4,a5,ffffffffc0201caa <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201cb2:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201cb4:	e4dff0ef          	jal	ra,ffffffffc0201b00 <__slob_get_free_pages.constprop.0>
ffffffffc0201cb8:	e488                	sd	a0,8(s1)
ffffffffc0201cba:	842a                	mv	s0,a0
	if (bb->pages)
ffffffffc0201cbc:	c525                	beqz	a0,ffffffffc0201d24 <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201cbe:	100027f3          	csrr	a5,sstatus
ffffffffc0201cc2:	8b89                	andi	a5,a5,2
ffffffffc0201cc4:	ef8d                	bnez	a5,ffffffffc0201cfe <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0201cc6:	000a9797          	auipc	a5,0xa9
ffffffffc0201cca:	9f278793          	addi	a5,a5,-1550 # ffffffffc02aa6b8 <bigblocks>
ffffffffc0201cce:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201cd0:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201cd2:	e898                	sd	a4,16(s1)
	return __kmalloc(size, 0);
}
ffffffffc0201cd4:	60e2                	ld	ra,24(sp)
ffffffffc0201cd6:	8522                	mv	a0,s0
ffffffffc0201cd8:	6442                	ld	s0,16(sp)
ffffffffc0201cda:	64a2                	ld	s1,8(sp)
ffffffffc0201cdc:	6902                	ld	s2,0(sp)
ffffffffc0201cde:	6105                	addi	sp,sp,32
ffffffffc0201ce0:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201ce2:	0541                	addi	a0,a0,16
ffffffffc0201ce4:	e81ff0ef          	jal	ra,ffffffffc0201b64 <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201ce8:	01050413          	addi	s0,a0,16
ffffffffc0201cec:	f565                	bnez	a0,ffffffffc0201cd4 <kmalloc+0x56>
ffffffffc0201cee:	4401                	li	s0,0
}
ffffffffc0201cf0:	60e2                	ld	ra,24(sp)
ffffffffc0201cf2:	8522                	mv	a0,s0
ffffffffc0201cf4:	6442                	ld	s0,16(sp)
ffffffffc0201cf6:	64a2                	ld	s1,8(sp)
ffffffffc0201cf8:	6902                	ld	s2,0(sp)
ffffffffc0201cfa:	6105                	addi	sp,sp,32
ffffffffc0201cfc:	8082                	ret
        intr_disable();
ffffffffc0201cfe:	cb7fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201d02:	000a9797          	auipc	a5,0xa9
ffffffffc0201d06:	9b678793          	addi	a5,a5,-1610 # ffffffffc02aa6b8 <bigblocks>
ffffffffc0201d0a:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201d0c:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201d0e:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0201d10:	c9ffe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
		return bb->pages;
ffffffffc0201d14:	6480                	ld	s0,8(s1)
}
ffffffffc0201d16:	60e2                	ld	ra,24(sp)
ffffffffc0201d18:	64a2                	ld	s1,8(sp)
ffffffffc0201d1a:	8522                	mv	a0,s0
ffffffffc0201d1c:	6442                	ld	s0,16(sp)
ffffffffc0201d1e:	6902                	ld	s2,0(sp)
ffffffffc0201d20:	6105                	addi	sp,sp,32
ffffffffc0201d22:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201d24:	45e1                	li	a1,24
ffffffffc0201d26:	8526                	mv	a0,s1
ffffffffc0201d28:	d25ff0ef          	jal	ra,ffffffffc0201a4c <slob_free>
	return __kmalloc(size, 0);
ffffffffc0201d2c:	b765                	j	ffffffffc0201cd4 <kmalloc+0x56>

ffffffffc0201d2e <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201d2e:	c169                	beqz	a0,ffffffffc0201df0 <kfree+0xc2>
{
ffffffffc0201d30:	1101                	addi	sp,sp,-32
ffffffffc0201d32:	e822                	sd	s0,16(sp)
ffffffffc0201d34:	ec06                	sd	ra,24(sp)
ffffffffc0201d36:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201d38:	03451793          	slli	a5,a0,0x34
ffffffffc0201d3c:	842a                	mv	s0,a0
ffffffffc0201d3e:	e3d9                	bnez	a5,ffffffffc0201dc4 <kfree+0x96>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201d40:	100027f3          	csrr	a5,sstatus
ffffffffc0201d44:	8b89                	andi	a5,a5,2
ffffffffc0201d46:	e7d9                	bnez	a5,ffffffffc0201dd4 <kfree+0xa6>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201d48:	000a9797          	auipc	a5,0xa9
ffffffffc0201d4c:	9707b783          	ld	a5,-1680(a5) # ffffffffc02aa6b8 <bigblocks>
    return 0;
ffffffffc0201d50:	4601                	li	a2,0
ffffffffc0201d52:	cbad                	beqz	a5,ffffffffc0201dc4 <kfree+0x96>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201d54:	000a9697          	auipc	a3,0xa9
ffffffffc0201d58:	96468693          	addi	a3,a3,-1692 # ffffffffc02aa6b8 <bigblocks>
ffffffffc0201d5c:	a021                	j	ffffffffc0201d64 <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201d5e:	01048693          	addi	a3,s1,16
ffffffffc0201d62:	c3a5                	beqz	a5,ffffffffc0201dc2 <kfree+0x94>
		{
			if (bb->pages == block)
ffffffffc0201d64:	6798                	ld	a4,8(a5)
ffffffffc0201d66:	84be                	mv	s1,a5
			{
				*last = bb->next;
ffffffffc0201d68:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201d6a:	fe871ae3          	bne	a4,s0,ffffffffc0201d5e <kfree+0x30>
				*last = bb->next;
ffffffffc0201d6e:	e29c                	sd	a5,0(a3)
    if (flag)
ffffffffc0201d70:	ee2d                	bnez	a2,ffffffffc0201dea <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc0201d72:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201d76:	4098                	lw	a4,0(s1)
ffffffffc0201d78:	08f46963          	bltu	s0,a5,ffffffffc0201e0a <kfree+0xdc>
ffffffffc0201d7c:	000a9697          	auipc	a3,0xa9
ffffffffc0201d80:	96c6b683          	ld	a3,-1684(a3) # ffffffffc02aa6e8 <va_pa_offset>
ffffffffc0201d84:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage)
ffffffffc0201d86:	8031                	srli	s0,s0,0xc
ffffffffc0201d88:	000a9797          	auipc	a5,0xa9
ffffffffc0201d8c:	9487b783          	ld	a5,-1720(a5) # ffffffffc02aa6d0 <npage>
ffffffffc0201d90:	06f47163          	bgeu	s0,a5,ffffffffc0201df2 <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201d94:	00006517          	auipc	a0,0x6
ffffffffc0201d98:	9cc53503          	ld	a0,-1588(a0) # ffffffffc0207760 <nbase>
ffffffffc0201d9c:	8c09                	sub	s0,s0,a0
ffffffffc0201d9e:	041a                	slli	s0,s0,0x6
	free_pages(kva2page(kva), 1 << order);
ffffffffc0201da0:	000a9517          	auipc	a0,0xa9
ffffffffc0201da4:	93853503          	ld	a0,-1736(a0) # ffffffffc02aa6d8 <pages>
ffffffffc0201da8:	4585                	li	a1,1
ffffffffc0201daa:	9522                	add	a0,a0,s0
ffffffffc0201dac:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201db0:	0ea000ef          	jal	ra,ffffffffc0201e9a <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201db4:	6442                	ld	s0,16(sp)
ffffffffc0201db6:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201db8:	8526                	mv	a0,s1
}
ffffffffc0201dba:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201dbc:	45e1                	li	a1,24
}
ffffffffc0201dbe:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201dc0:	b171                	j	ffffffffc0201a4c <slob_free>
ffffffffc0201dc2:	e20d                	bnez	a2,ffffffffc0201de4 <kfree+0xb6>
ffffffffc0201dc4:	ff040513          	addi	a0,s0,-16
}
ffffffffc0201dc8:	6442                	ld	s0,16(sp)
ffffffffc0201dca:	60e2                	ld	ra,24(sp)
ffffffffc0201dcc:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201dce:	4581                	li	a1,0
}
ffffffffc0201dd0:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201dd2:	b9ad                	j	ffffffffc0201a4c <slob_free>
        intr_disable();
ffffffffc0201dd4:	be1fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201dd8:	000a9797          	auipc	a5,0xa9
ffffffffc0201ddc:	8e07b783          	ld	a5,-1824(a5) # ffffffffc02aa6b8 <bigblocks>
        return 1;
ffffffffc0201de0:	4605                	li	a2,1
ffffffffc0201de2:	fbad                	bnez	a5,ffffffffc0201d54 <kfree+0x26>
        intr_enable();
ffffffffc0201de4:	bcbfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201de8:	bff1                	j	ffffffffc0201dc4 <kfree+0x96>
ffffffffc0201dea:	bc5fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201dee:	b751                	j	ffffffffc0201d72 <kfree+0x44>
ffffffffc0201df0:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201df2:	00004617          	auipc	a2,0x4
ffffffffc0201df6:	77e60613          	addi	a2,a2,1918 # ffffffffc0206570 <default_pmm_manager+0x108>
ffffffffc0201dfa:	06900593          	li	a1,105
ffffffffc0201dfe:	00004517          	auipc	a0,0x4
ffffffffc0201e02:	6ca50513          	addi	a0,a0,1738 # ffffffffc02064c8 <default_pmm_manager+0x60>
ffffffffc0201e06:	e88fe0ef          	jal	ra,ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201e0a:	86a2                	mv	a3,s0
ffffffffc0201e0c:	00004617          	auipc	a2,0x4
ffffffffc0201e10:	73c60613          	addi	a2,a2,1852 # ffffffffc0206548 <default_pmm_manager+0xe0>
ffffffffc0201e14:	07700593          	li	a1,119
ffffffffc0201e18:	00004517          	auipc	a0,0x4
ffffffffc0201e1c:	6b050513          	addi	a0,a0,1712 # ffffffffc02064c8 <default_pmm_manager+0x60>
ffffffffc0201e20:	e6efe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201e24 <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201e24:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201e26:	00004617          	auipc	a2,0x4
ffffffffc0201e2a:	74a60613          	addi	a2,a2,1866 # ffffffffc0206570 <default_pmm_manager+0x108>
ffffffffc0201e2e:	06900593          	li	a1,105
ffffffffc0201e32:	00004517          	auipc	a0,0x4
ffffffffc0201e36:	69650513          	addi	a0,a0,1686 # ffffffffc02064c8 <default_pmm_manager+0x60>
pa2page(uintptr_t pa)
ffffffffc0201e3a:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201e3c:	e52fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201e40 <pte2page.part.0>:
pte2page(pte_t pte)
ffffffffc0201e40:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc0201e42:	00004617          	auipc	a2,0x4
ffffffffc0201e46:	74e60613          	addi	a2,a2,1870 # ffffffffc0206590 <default_pmm_manager+0x128>
ffffffffc0201e4a:	07f00593          	li	a1,127
ffffffffc0201e4e:	00004517          	auipc	a0,0x4
ffffffffc0201e52:	67a50513          	addi	a0,a0,1658 # ffffffffc02064c8 <default_pmm_manager+0x60>
pte2page(pte_t pte)
ffffffffc0201e56:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0201e58:	e36fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201e5c <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e5c:	100027f3          	csrr	a5,sstatus
ffffffffc0201e60:	8b89                	andi	a5,a5,2
ffffffffc0201e62:	e799                	bnez	a5,ffffffffc0201e70 <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201e64:	000a9797          	auipc	a5,0xa9
ffffffffc0201e68:	87c7b783          	ld	a5,-1924(a5) # ffffffffc02aa6e0 <pmm_manager>
ffffffffc0201e6c:	6f9c                	ld	a5,24(a5)
ffffffffc0201e6e:	8782                	jr	a5
{
ffffffffc0201e70:	1141                	addi	sp,sp,-16
ffffffffc0201e72:	e406                	sd	ra,8(sp)
ffffffffc0201e74:	e022                	sd	s0,0(sp)
ffffffffc0201e76:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201e78:	b3dfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201e7c:	000a9797          	auipc	a5,0xa9
ffffffffc0201e80:	8647b783          	ld	a5,-1948(a5) # ffffffffc02aa6e0 <pmm_manager>
ffffffffc0201e84:	6f9c                	ld	a5,24(a5)
ffffffffc0201e86:	8522                	mv	a0,s0
ffffffffc0201e88:	9782                	jalr	a5
ffffffffc0201e8a:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201e8c:	b23fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201e90:	60a2                	ld	ra,8(sp)
ffffffffc0201e92:	8522                	mv	a0,s0
ffffffffc0201e94:	6402                	ld	s0,0(sp)
ffffffffc0201e96:	0141                	addi	sp,sp,16
ffffffffc0201e98:	8082                	ret

ffffffffc0201e9a <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e9a:	100027f3          	csrr	a5,sstatus
ffffffffc0201e9e:	8b89                	andi	a5,a5,2
ffffffffc0201ea0:	e799                	bnez	a5,ffffffffc0201eae <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201ea2:	000a9797          	auipc	a5,0xa9
ffffffffc0201ea6:	83e7b783          	ld	a5,-1986(a5) # ffffffffc02aa6e0 <pmm_manager>
ffffffffc0201eaa:	739c                	ld	a5,32(a5)
ffffffffc0201eac:	8782                	jr	a5
{
ffffffffc0201eae:	1101                	addi	sp,sp,-32
ffffffffc0201eb0:	ec06                	sd	ra,24(sp)
ffffffffc0201eb2:	e822                	sd	s0,16(sp)
ffffffffc0201eb4:	e426                	sd	s1,8(sp)
ffffffffc0201eb6:	842a                	mv	s0,a0
ffffffffc0201eb8:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201eba:	afbfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201ebe:	000a9797          	auipc	a5,0xa9
ffffffffc0201ec2:	8227b783          	ld	a5,-2014(a5) # ffffffffc02aa6e0 <pmm_manager>
ffffffffc0201ec6:	739c                	ld	a5,32(a5)
ffffffffc0201ec8:	85a6                	mv	a1,s1
ffffffffc0201eca:	8522                	mv	a0,s0
ffffffffc0201ecc:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201ece:	6442                	ld	s0,16(sp)
ffffffffc0201ed0:	60e2                	ld	ra,24(sp)
ffffffffc0201ed2:	64a2                	ld	s1,8(sp)
ffffffffc0201ed4:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201ed6:	ad9fe06f          	j	ffffffffc02009ae <intr_enable>

ffffffffc0201eda <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201eda:	100027f3          	csrr	a5,sstatus
ffffffffc0201ede:	8b89                	andi	a5,a5,2
ffffffffc0201ee0:	e799                	bnez	a5,ffffffffc0201eee <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201ee2:	000a8797          	auipc	a5,0xa8
ffffffffc0201ee6:	7fe7b783          	ld	a5,2046(a5) # ffffffffc02aa6e0 <pmm_manager>
ffffffffc0201eea:	779c                	ld	a5,40(a5)
ffffffffc0201eec:	8782                	jr	a5
{
ffffffffc0201eee:	1141                	addi	sp,sp,-16
ffffffffc0201ef0:	e406                	sd	ra,8(sp)
ffffffffc0201ef2:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201ef4:	ac1fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201ef8:	000a8797          	auipc	a5,0xa8
ffffffffc0201efc:	7e87b783          	ld	a5,2024(a5) # ffffffffc02aa6e0 <pmm_manager>
ffffffffc0201f00:	779c                	ld	a5,40(a5)
ffffffffc0201f02:	9782                	jalr	a5
ffffffffc0201f04:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201f06:	aa9fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201f0a:	60a2                	ld	ra,8(sp)
ffffffffc0201f0c:	8522                	mv	a0,s0
ffffffffc0201f0e:	6402                	ld	s0,0(sp)
ffffffffc0201f10:	0141                	addi	sp,sp,16
ffffffffc0201f12:	8082                	ret

ffffffffc0201f14 <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201f14:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201f18:	1ff7f793          	andi	a5,a5,511
{
ffffffffc0201f1c:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201f1e:	078e                	slli	a5,a5,0x3
{
ffffffffc0201f20:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201f22:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201f26:	6094                	ld	a3,0(s1)
{
ffffffffc0201f28:	f04a                	sd	s2,32(sp)
ffffffffc0201f2a:	ec4e                	sd	s3,24(sp)
ffffffffc0201f2c:	e852                	sd	s4,16(sp)
ffffffffc0201f2e:	fc06                	sd	ra,56(sp)
ffffffffc0201f30:	f822                	sd	s0,48(sp)
ffffffffc0201f32:	e456                	sd	s5,8(sp)
ffffffffc0201f34:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201f36:	0016f793          	andi	a5,a3,1
{
ffffffffc0201f3a:	892e                	mv	s2,a1
ffffffffc0201f3c:	8a32                	mv	s4,a2
ffffffffc0201f3e:	000a8997          	auipc	s3,0xa8
ffffffffc0201f42:	79298993          	addi	s3,s3,1938 # ffffffffc02aa6d0 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201f46:	efbd                	bnez	a5,ffffffffc0201fc4 <get_pte+0xb0>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201f48:	14060c63          	beqz	a2,ffffffffc02020a0 <get_pte+0x18c>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f4c:	100027f3          	csrr	a5,sstatus
ffffffffc0201f50:	8b89                	andi	a5,a5,2
ffffffffc0201f52:	14079963          	bnez	a5,ffffffffc02020a4 <get_pte+0x190>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201f56:	000a8797          	auipc	a5,0xa8
ffffffffc0201f5a:	78a7b783          	ld	a5,1930(a5) # ffffffffc02aa6e0 <pmm_manager>
ffffffffc0201f5e:	6f9c                	ld	a5,24(a5)
ffffffffc0201f60:	4505                	li	a0,1
ffffffffc0201f62:	9782                	jalr	a5
ffffffffc0201f64:	842a                	mv	s0,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201f66:	12040d63          	beqz	s0,ffffffffc02020a0 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201f6a:	000a8b17          	auipc	s6,0xa8
ffffffffc0201f6e:	76eb0b13          	addi	s6,s6,1902 # ffffffffc02aa6d8 <pages>
ffffffffc0201f72:	000b3503          	ld	a0,0(s6)
ffffffffc0201f76:	00080ab7          	lui	s5,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201f7a:	000a8997          	auipc	s3,0xa8
ffffffffc0201f7e:	75698993          	addi	s3,s3,1878 # ffffffffc02aa6d0 <npage>
ffffffffc0201f82:	40a40533          	sub	a0,s0,a0
ffffffffc0201f86:	8519                	srai	a0,a0,0x6
ffffffffc0201f88:	9556                	add	a0,a0,s5
ffffffffc0201f8a:	0009b703          	ld	a4,0(s3)
ffffffffc0201f8e:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201f92:	4685                	li	a3,1
ffffffffc0201f94:	c014                	sw	a3,0(s0)
ffffffffc0201f96:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201f98:	0532                	slli	a0,a0,0xc
ffffffffc0201f9a:	16e7f763          	bgeu	a5,a4,ffffffffc0202108 <get_pte+0x1f4>
ffffffffc0201f9e:	000a8797          	auipc	a5,0xa8
ffffffffc0201fa2:	74a7b783          	ld	a5,1866(a5) # ffffffffc02aa6e8 <va_pa_offset>
ffffffffc0201fa6:	6605                	lui	a2,0x1
ffffffffc0201fa8:	4581                	li	a1,0
ffffffffc0201faa:	953e                	add	a0,a0,a5
ffffffffc0201fac:	65e030ef          	jal	ra,ffffffffc020560a <memset>
    return page - pages + nbase;
ffffffffc0201fb0:	000b3683          	ld	a3,0(s6)
ffffffffc0201fb4:	40d406b3          	sub	a3,s0,a3
ffffffffc0201fb8:	8699                	srai	a3,a3,0x6
ffffffffc0201fba:	96d6                	add	a3,a3,s5
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201fbc:	06aa                	slli	a3,a3,0xa
ffffffffc0201fbe:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201fc2:	e094                	sd	a3,0(s1)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201fc4:	77fd                	lui	a5,0xfffff
ffffffffc0201fc6:	068a                	slli	a3,a3,0x2
ffffffffc0201fc8:	0009b703          	ld	a4,0(s3)
ffffffffc0201fcc:	8efd                	and	a3,a3,a5
ffffffffc0201fce:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201fd2:	10e7ff63          	bgeu	a5,a4,ffffffffc02020f0 <get_pte+0x1dc>
ffffffffc0201fd6:	000a8a97          	auipc	s5,0xa8
ffffffffc0201fda:	712a8a93          	addi	s5,s5,1810 # ffffffffc02aa6e8 <va_pa_offset>
ffffffffc0201fde:	000ab403          	ld	s0,0(s5)
ffffffffc0201fe2:	01595793          	srli	a5,s2,0x15
ffffffffc0201fe6:	1ff7f793          	andi	a5,a5,511
ffffffffc0201fea:	96a2                	add	a3,a3,s0
ffffffffc0201fec:	00379413          	slli	s0,a5,0x3
ffffffffc0201ff0:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V))
ffffffffc0201ff2:	6014                	ld	a3,0(s0)
ffffffffc0201ff4:	0016f793          	andi	a5,a3,1
ffffffffc0201ff8:	ebad                	bnez	a5,ffffffffc020206a <get_pte+0x156>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201ffa:	0a0a0363          	beqz	s4,ffffffffc02020a0 <get_pte+0x18c>
ffffffffc0201ffe:	100027f3          	csrr	a5,sstatus
ffffffffc0202002:	8b89                	andi	a5,a5,2
ffffffffc0202004:	efcd                	bnez	a5,ffffffffc02020be <get_pte+0x1aa>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202006:	000a8797          	auipc	a5,0xa8
ffffffffc020200a:	6da7b783          	ld	a5,1754(a5) # ffffffffc02aa6e0 <pmm_manager>
ffffffffc020200e:	6f9c                	ld	a5,24(a5)
ffffffffc0202010:	4505                	li	a0,1
ffffffffc0202012:	9782                	jalr	a5
ffffffffc0202014:	84aa                	mv	s1,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0202016:	c4c9                	beqz	s1,ffffffffc02020a0 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0202018:	000a8b17          	auipc	s6,0xa8
ffffffffc020201c:	6c0b0b13          	addi	s6,s6,1728 # ffffffffc02aa6d8 <pages>
ffffffffc0202020:	000b3503          	ld	a0,0(s6)
ffffffffc0202024:	00080a37          	lui	s4,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202028:	0009b703          	ld	a4,0(s3)
ffffffffc020202c:	40a48533          	sub	a0,s1,a0
ffffffffc0202030:	8519                	srai	a0,a0,0x6
ffffffffc0202032:	9552                	add	a0,a0,s4
ffffffffc0202034:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0202038:	4685                	li	a3,1
ffffffffc020203a:	c094                	sw	a3,0(s1)
ffffffffc020203c:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc020203e:	0532                	slli	a0,a0,0xc
ffffffffc0202040:	0ee7f163          	bgeu	a5,a4,ffffffffc0202122 <get_pte+0x20e>
ffffffffc0202044:	000ab783          	ld	a5,0(s5)
ffffffffc0202048:	6605                	lui	a2,0x1
ffffffffc020204a:	4581                	li	a1,0
ffffffffc020204c:	953e                	add	a0,a0,a5
ffffffffc020204e:	5bc030ef          	jal	ra,ffffffffc020560a <memset>
    return page - pages + nbase;
ffffffffc0202052:	000b3683          	ld	a3,0(s6)
ffffffffc0202056:	40d486b3          	sub	a3,s1,a3
ffffffffc020205a:	8699                	srai	a3,a3,0x6
ffffffffc020205c:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc020205e:	06aa                	slli	a3,a3,0xa
ffffffffc0202060:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0202064:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0202066:	0009b703          	ld	a4,0(s3)
ffffffffc020206a:	068a                	slli	a3,a3,0x2
ffffffffc020206c:	757d                	lui	a0,0xfffff
ffffffffc020206e:	8ee9                	and	a3,a3,a0
ffffffffc0202070:	00c6d793          	srli	a5,a3,0xc
ffffffffc0202074:	06e7f263          	bgeu	a5,a4,ffffffffc02020d8 <get_pte+0x1c4>
ffffffffc0202078:	000ab503          	ld	a0,0(s5)
ffffffffc020207c:	00c95913          	srli	s2,s2,0xc
ffffffffc0202080:	1ff97913          	andi	s2,s2,511
ffffffffc0202084:	96aa                	add	a3,a3,a0
ffffffffc0202086:	00391513          	slli	a0,s2,0x3
ffffffffc020208a:	9536                	add	a0,a0,a3
}
ffffffffc020208c:	70e2                	ld	ra,56(sp)
ffffffffc020208e:	7442                	ld	s0,48(sp)
ffffffffc0202090:	74a2                	ld	s1,40(sp)
ffffffffc0202092:	7902                	ld	s2,32(sp)
ffffffffc0202094:	69e2                	ld	s3,24(sp)
ffffffffc0202096:	6a42                	ld	s4,16(sp)
ffffffffc0202098:	6aa2                	ld	s5,8(sp)
ffffffffc020209a:	6b02                	ld	s6,0(sp)
ffffffffc020209c:	6121                	addi	sp,sp,64
ffffffffc020209e:	8082                	ret
            return NULL;
ffffffffc02020a0:	4501                	li	a0,0
ffffffffc02020a2:	b7ed                	j	ffffffffc020208c <get_pte+0x178>
        intr_disable();
ffffffffc02020a4:	911fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02020a8:	000a8797          	auipc	a5,0xa8
ffffffffc02020ac:	6387b783          	ld	a5,1592(a5) # ffffffffc02aa6e0 <pmm_manager>
ffffffffc02020b0:	6f9c                	ld	a5,24(a5)
ffffffffc02020b2:	4505                	li	a0,1
ffffffffc02020b4:	9782                	jalr	a5
ffffffffc02020b6:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02020b8:	8f7fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02020bc:	b56d                	j	ffffffffc0201f66 <get_pte+0x52>
        intr_disable();
ffffffffc02020be:	8f7fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02020c2:	000a8797          	auipc	a5,0xa8
ffffffffc02020c6:	61e7b783          	ld	a5,1566(a5) # ffffffffc02aa6e0 <pmm_manager>
ffffffffc02020ca:	6f9c                	ld	a5,24(a5)
ffffffffc02020cc:	4505                	li	a0,1
ffffffffc02020ce:	9782                	jalr	a5
ffffffffc02020d0:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc02020d2:	8ddfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02020d6:	b781                	j	ffffffffc0202016 <get_pte+0x102>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc02020d8:	00004617          	auipc	a2,0x4
ffffffffc02020dc:	3c860613          	addi	a2,a2,968 # ffffffffc02064a0 <default_pmm_manager+0x38>
ffffffffc02020e0:	0fa00593          	li	a1,250
ffffffffc02020e4:	00004517          	auipc	a0,0x4
ffffffffc02020e8:	4d450513          	addi	a0,a0,1236 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc02020ec:	ba2fe0ef          	jal	ra,ffffffffc020048e <__panic>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc02020f0:	00004617          	auipc	a2,0x4
ffffffffc02020f4:	3b060613          	addi	a2,a2,944 # ffffffffc02064a0 <default_pmm_manager+0x38>
ffffffffc02020f8:	0ed00593          	li	a1,237
ffffffffc02020fc:	00004517          	auipc	a0,0x4
ffffffffc0202100:	4bc50513          	addi	a0,a0,1212 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc0202104:	b8afe0ef          	jal	ra,ffffffffc020048e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202108:	86aa                	mv	a3,a0
ffffffffc020210a:	00004617          	auipc	a2,0x4
ffffffffc020210e:	39660613          	addi	a2,a2,918 # ffffffffc02064a0 <default_pmm_manager+0x38>
ffffffffc0202112:	0e900593          	li	a1,233
ffffffffc0202116:	00004517          	auipc	a0,0x4
ffffffffc020211a:	4a250513          	addi	a0,a0,1186 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc020211e:	b70fe0ef          	jal	ra,ffffffffc020048e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202122:	86aa                	mv	a3,a0
ffffffffc0202124:	00004617          	auipc	a2,0x4
ffffffffc0202128:	37c60613          	addi	a2,a2,892 # ffffffffc02064a0 <default_pmm_manager+0x38>
ffffffffc020212c:	0f700593          	li	a1,247
ffffffffc0202130:	00004517          	auipc	a0,0x4
ffffffffc0202134:	48850513          	addi	a0,a0,1160 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc0202138:	b56fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020213c <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc020213c:	1141                	addi	sp,sp,-16
ffffffffc020213e:	e022                	sd	s0,0(sp)
ffffffffc0202140:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202142:	4601                	li	a2,0
{
ffffffffc0202144:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202146:	dcfff0ef          	jal	ra,ffffffffc0201f14 <get_pte>
    if (ptep_store != NULL)
ffffffffc020214a:	c011                	beqz	s0,ffffffffc020214e <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc020214c:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc020214e:	c511                	beqz	a0,ffffffffc020215a <get_page+0x1e>
ffffffffc0202150:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0202152:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0202154:	0017f713          	andi	a4,a5,1
ffffffffc0202158:	e709                	bnez	a4,ffffffffc0202162 <get_page+0x26>
}
ffffffffc020215a:	60a2                	ld	ra,8(sp)
ffffffffc020215c:	6402                	ld	s0,0(sp)
ffffffffc020215e:	0141                	addi	sp,sp,16
ffffffffc0202160:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0202162:	078a                	slli	a5,a5,0x2
ffffffffc0202164:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202166:	000a8717          	auipc	a4,0xa8
ffffffffc020216a:	56a73703          	ld	a4,1386(a4) # ffffffffc02aa6d0 <npage>
ffffffffc020216e:	00e7ff63          	bgeu	a5,a4,ffffffffc020218c <get_page+0x50>
ffffffffc0202172:	60a2                	ld	ra,8(sp)
ffffffffc0202174:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc0202176:	fff80537          	lui	a0,0xfff80
ffffffffc020217a:	97aa                	add	a5,a5,a0
ffffffffc020217c:	079a                	slli	a5,a5,0x6
ffffffffc020217e:	000a8517          	auipc	a0,0xa8
ffffffffc0202182:	55a53503          	ld	a0,1370(a0) # ffffffffc02aa6d8 <pages>
ffffffffc0202186:	953e                	add	a0,a0,a5
ffffffffc0202188:	0141                	addi	sp,sp,16
ffffffffc020218a:	8082                	ret
ffffffffc020218c:	c99ff0ef          	jal	ra,ffffffffc0201e24 <pa2page.part.0>

ffffffffc0202190 <unmap_range>:
        tlb_invalidate(pgdir, la);
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end)
{
ffffffffc0202190:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202192:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc0202196:	f486                	sd	ra,104(sp)
ffffffffc0202198:	f0a2                	sd	s0,96(sp)
ffffffffc020219a:	eca6                	sd	s1,88(sp)
ffffffffc020219c:	e8ca                	sd	s2,80(sp)
ffffffffc020219e:	e4ce                	sd	s3,72(sp)
ffffffffc02021a0:	e0d2                	sd	s4,64(sp)
ffffffffc02021a2:	fc56                	sd	s5,56(sp)
ffffffffc02021a4:	f85a                	sd	s6,48(sp)
ffffffffc02021a6:	f45e                	sd	s7,40(sp)
ffffffffc02021a8:	f062                	sd	s8,32(sp)
ffffffffc02021aa:	ec66                	sd	s9,24(sp)
ffffffffc02021ac:	e86a                	sd	s10,16(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02021ae:	17d2                	slli	a5,a5,0x34
ffffffffc02021b0:	e3ed                	bnez	a5,ffffffffc0202292 <unmap_range+0x102>
    assert(USER_ACCESS(start, end));
ffffffffc02021b2:	002007b7          	lui	a5,0x200
ffffffffc02021b6:	842e                	mv	s0,a1
ffffffffc02021b8:	0ef5ed63          	bltu	a1,a5,ffffffffc02022b2 <unmap_range+0x122>
ffffffffc02021bc:	8932                	mv	s2,a2
ffffffffc02021be:	0ec5fa63          	bgeu	a1,a2,ffffffffc02022b2 <unmap_range+0x122>
ffffffffc02021c2:	4785                	li	a5,1
ffffffffc02021c4:	07fe                	slli	a5,a5,0x1f
ffffffffc02021c6:	0ec7e663          	bltu	a5,a2,ffffffffc02022b2 <unmap_range+0x122>
ffffffffc02021ca:	89aa                	mv	s3,a0
        }
        if (*ptep != 0)
        {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc02021cc:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc02021ce:	000a8c97          	auipc	s9,0xa8
ffffffffc02021d2:	502c8c93          	addi	s9,s9,1282 # ffffffffc02aa6d0 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc02021d6:	000a8c17          	auipc	s8,0xa8
ffffffffc02021da:	502c0c13          	addi	s8,s8,1282 # ffffffffc02aa6d8 <pages>
ffffffffc02021de:	fff80bb7          	lui	s7,0xfff80
        pmm_manager->free_pages(base, n);
ffffffffc02021e2:	000a8d17          	auipc	s10,0xa8
ffffffffc02021e6:	4fed0d13          	addi	s10,s10,1278 # ffffffffc02aa6e0 <pmm_manager>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02021ea:	00200b37          	lui	s6,0x200
ffffffffc02021ee:	ffe00ab7          	lui	s5,0xffe00
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc02021f2:	4601                	li	a2,0
ffffffffc02021f4:	85a2                	mv	a1,s0
ffffffffc02021f6:	854e                	mv	a0,s3
ffffffffc02021f8:	d1dff0ef          	jal	ra,ffffffffc0201f14 <get_pte>
ffffffffc02021fc:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc02021fe:	cd29                	beqz	a0,ffffffffc0202258 <unmap_range+0xc8>
        if (*ptep != 0)
ffffffffc0202200:	611c                	ld	a5,0(a0)
ffffffffc0202202:	e395                	bnez	a5,ffffffffc0202226 <unmap_range+0x96>
        start += PGSIZE;
ffffffffc0202204:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0202206:	ff2466e3          	bltu	s0,s2,ffffffffc02021f2 <unmap_range+0x62>
}
ffffffffc020220a:	70a6                	ld	ra,104(sp)
ffffffffc020220c:	7406                	ld	s0,96(sp)
ffffffffc020220e:	64e6                	ld	s1,88(sp)
ffffffffc0202210:	6946                	ld	s2,80(sp)
ffffffffc0202212:	69a6                	ld	s3,72(sp)
ffffffffc0202214:	6a06                	ld	s4,64(sp)
ffffffffc0202216:	7ae2                	ld	s5,56(sp)
ffffffffc0202218:	7b42                	ld	s6,48(sp)
ffffffffc020221a:	7ba2                	ld	s7,40(sp)
ffffffffc020221c:	7c02                	ld	s8,32(sp)
ffffffffc020221e:	6ce2                	ld	s9,24(sp)
ffffffffc0202220:	6d42                	ld	s10,16(sp)
ffffffffc0202222:	6165                	addi	sp,sp,112
ffffffffc0202224:	8082                	ret
    if (*ptep & PTE_V)
ffffffffc0202226:	0017f713          	andi	a4,a5,1
ffffffffc020222a:	df69                	beqz	a4,ffffffffc0202204 <unmap_range+0x74>
    if (PPN(pa) >= npage)
ffffffffc020222c:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202230:	078a                	slli	a5,a5,0x2
ffffffffc0202232:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202234:	08e7ff63          	bgeu	a5,a4,ffffffffc02022d2 <unmap_range+0x142>
    return &pages[PPN(pa) - nbase];
ffffffffc0202238:	000c3503          	ld	a0,0(s8)
ffffffffc020223c:	97de                	add	a5,a5,s7
ffffffffc020223e:	079a                	slli	a5,a5,0x6
ffffffffc0202240:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0202242:	411c                	lw	a5,0(a0)
ffffffffc0202244:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202248:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc020224a:	cf11                	beqz	a4,ffffffffc0202266 <unmap_range+0xd6>
        *ptep = 0;
ffffffffc020224c:	0004b023          	sd	zero,0(s1)

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202250:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc0202254:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0202256:	bf45                	j	ffffffffc0202206 <unmap_range+0x76>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202258:	945a                	add	s0,s0,s6
ffffffffc020225a:	01547433          	and	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc020225e:	d455                	beqz	s0,ffffffffc020220a <unmap_range+0x7a>
ffffffffc0202260:	f92469e3          	bltu	s0,s2,ffffffffc02021f2 <unmap_range+0x62>
ffffffffc0202264:	b75d                	j	ffffffffc020220a <unmap_range+0x7a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202266:	100027f3          	csrr	a5,sstatus
ffffffffc020226a:	8b89                	andi	a5,a5,2
ffffffffc020226c:	e799                	bnez	a5,ffffffffc020227a <unmap_range+0xea>
        pmm_manager->free_pages(base, n);
ffffffffc020226e:	000d3783          	ld	a5,0(s10)
ffffffffc0202272:	4585                	li	a1,1
ffffffffc0202274:	739c                	ld	a5,32(a5)
ffffffffc0202276:	9782                	jalr	a5
    if (flag)
ffffffffc0202278:	bfd1                	j	ffffffffc020224c <unmap_range+0xbc>
ffffffffc020227a:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020227c:	f38fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202280:	000d3783          	ld	a5,0(s10)
ffffffffc0202284:	6522                	ld	a0,8(sp)
ffffffffc0202286:	4585                	li	a1,1
ffffffffc0202288:	739c                	ld	a5,32(a5)
ffffffffc020228a:	9782                	jalr	a5
        intr_enable();
ffffffffc020228c:	f22fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202290:	bf75                	j	ffffffffc020224c <unmap_range+0xbc>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202292:	00004697          	auipc	a3,0x4
ffffffffc0202296:	33668693          	addi	a3,a3,822 # ffffffffc02065c8 <default_pmm_manager+0x160>
ffffffffc020229a:	00004617          	auipc	a2,0x4
ffffffffc020229e:	e1e60613          	addi	a2,a2,-482 # ffffffffc02060b8 <commands+0x818>
ffffffffc02022a2:	12000593          	li	a1,288
ffffffffc02022a6:	00004517          	auipc	a0,0x4
ffffffffc02022aa:	31250513          	addi	a0,a0,786 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc02022ae:	9e0fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc02022b2:	00004697          	auipc	a3,0x4
ffffffffc02022b6:	34668693          	addi	a3,a3,838 # ffffffffc02065f8 <default_pmm_manager+0x190>
ffffffffc02022ba:	00004617          	auipc	a2,0x4
ffffffffc02022be:	dfe60613          	addi	a2,a2,-514 # ffffffffc02060b8 <commands+0x818>
ffffffffc02022c2:	12100593          	li	a1,289
ffffffffc02022c6:	00004517          	auipc	a0,0x4
ffffffffc02022ca:	2f250513          	addi	a0,a0,754 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc02022ce:	9c0fe0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc02022d2:	b53ff0ef          	jal	ra,ffffffffc0201e24 <pa2page.part.0>

ffffffffc02022d6 <exit_range>:
{
ffffffffc02022d6:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02022d8:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc02022dc:	fc86                	sd	ra,120(sp)
ffffffffc02022de:	f8a2                	sd	s0,112(sp)
ffffffffc02022e0:	f4a6                	sd	s1,104(sp)
ffffffffc02022e2:	f0ca                	sd	s2,96(sp)
ffffffffc02022e4:	ecce                	sd	s3,88(sp)
ffffffffc02022e6:	e8d2                	sd	s4,80(sp)
ffffffffc02022e8:	e4d6                	sd	s5,72(sp)
ffffffffc02022ea:	e0da                	sd	s6,64(sp)
ffffffffc02022ec:	fc5e                	sd	s7,56(sp)
ffffffffc02022ee:	f862                	sd	s8,48(sp)
ffffffffc02022f0:	f466                	sd	s9,40(sp)
ffffffffc02022f2:	f06a                	sd	s10,32(sp)
ffffffffc02022f4:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02022f6:	17d2                	slli	a5,a5,0x34
ffffffffc02022f8:	20079a63          	bnez	a5,ffffffffc020250c <exit_range+0x236>
    assert(USER_ACCESS(start, end));
ffffffffc02022fc:	002007b7          	lui	a5,0x200
ffffffffc0202300:	24f5e463          	bltu	a1,a5,ffffffffc0202548 <exit_range+0x272>
ffffffffc0202304:	8ab2                	mv	s5,a2
ffffffffc0202306:	24c5f163          	bgeu	a1,a2,ffffffffc0202548 <exit_range+0x272>
ffffffffc020230a:	4785                	li	a5,1
ffffffffc020230c:	07fe                	slli	a5,a5,0x1f
ffffffffc020230e:	22c7ed63          	bltu	a5,a2,ffffffffc0202548 <exit_range+0x272>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc0202312:	c00009b7          	lui	s3,0xc0000
ffffffffc0202316:	0135f9b3          	and	s3,a1,s3
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc020231a:	ffe00937          	lui	s2,0xffe00
ffffffffc020231e:	400007b7          	lui	a5,0x40000
    return KADDR(page2pa(page));
ffffffffc0202322:	5cfd                	li	s9,-1
ffffffffc0202324:	8c2a                	mv	s8,a0
ffffffffc0202326:	0125f933          	and	s2,a1,s2
ffffffffc020232a:	99be                	add	s3,s3,a5
    if (PPN(pa) >= npage)
ffffffffc020232c:	000a8d17          	auipc	s10,0xa8
ffffffffc0202330:	3a4d0d13          	addi	s10,s10,932 # ffffffffc02aa6d0 <npage>
    return KADDR(page2pa(page));
ffffffffc0202334:	00ccdc93          	srli	s9,s9,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc0202338:	000a8717          	auipc	a4,0xa8
ffffffffc020233c:	3a070713          	addi	a4,a4,928 # ffffffffc02aa6d8 <pages>
        pmm_manager->free_pages(base, n);
ffffffffc0202340:	000a8d97          	auipc	s11,0xa8
ffffffffc0202344:	3a0d8d93          	addi	s11,s11,928 # ffffffffc02aa6e0 <pmm_manager>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc0202348:	c0000437          	lui	s0,0xc0000
ffffffffc020234c:	944e                	add	s0,s0,s3
ffffffffc020234e:	8079                	srli	s0,s0,0x1e
ffffffffc0202350:	1ff47413          	andi	s0,s0,511
ffffffffc0202354:	040e                	slli	s0,s0,0x3
ffffffffc0202356:	9462                	add	s0,s0,s8
ffffffffc0202358:	00043a03          	ld	s4,0(s0) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4ee0>
        if (pde1 & PTE_V)
ffffffffc020235c:	001a7793          	andi	a5,s4,1
ffffffffc0202360:	eb99                	bnez	a5,ffffffffc0202376 <exit_range+0xa0>
    } while (d1start != 0 && d1start < end);
ffffffffc0202362:	12098463          	beqz	s3,ffffffffc020248a <exit_range+0x1b4>
ffffffffc0202366:	400007b7          	lui	a5,0x40000
ffffffffc020236a:	97ce                	add	a5,a5,s3
ffffffffc020236c:	894e                	mv	s2,s3
ffffffffc020236e:	1159fe63          	bgeu	s3,s5,ffffffffc020248a <exit_range+0x1b4>
ffffffffc0202372:	89be                	mv	s3,a5
ffffffffc0202374:	bfd1                	j	ffffffffc0202348 <exit_range+0x72>
    if (PPN(pa) >= npage)
ffffffffc0202376:	000d3783          	ld	a5,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc020237a:	0a0a                	slli	s4,s4,0x2
ffffffffc020237c:	00ca5a13          	srli	s4,s4,0xc
    if (PPN(pa) >= npage)
ffffffffc0202380:	1cfa7263          	bgeu	s4,a5,ffffffffc0202544 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202384:	fff80637          	lui	a2,0xfff80
ffffffffc0202388:	9652                	add	a2,a2,s4
    return page - pages + nbase;
ffffffffc020238a:	000806b7          	lui	a3,0x80
ffffffffc020238e:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0202390:	0196f5b3          	and	a1,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc0202394:	061a                	slli	a2,a2,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc0202396:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202398:	18f5fa63          	bgeu	a1,a5,ffffffffc020252c <exit_range+0x256>
ffffffffc020239c:	000a8817          	auipc	a6,0xa8
ffffffffc02023a0:	34c80813          	addi	a6,a6,844 # ffffffffc02aa6e8 <va_pa_offset>
ffffffffc02023a4:	00083b03          	ld	s6,0(a6)
            free_pd0 = 1;
ffffffffc02023a8:	4b85                	li	s7,1
    return &pages[PPN(pa) - nbase];
ffffffffc02023aa:	fff80e37          	lui	t3,0xfff80
    return KADDR(page2pa(page));
ffffffffc02023ae:	9b36                	add	s6,s6,a3
    return page - pages + nbase;
ffffffffc02023b0:	00080337          	lui	t1,0x80
ffffffffc02023b4:	6885                	lui	a7,0x1
ffffffffc02023b6:	a819                	j	ffffffffc02023cc <exit_range+0xf6>
                    free_pd0 = 0;
ffffffffc02023b8:	4b81                	li	s7,0
                d0start += PTSIZE;
ffffffffc02023ba:	002007b7          	lui	a5,0x200
ffffffffc02023be:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc02023c0:	08090c63          	beqz	s2,ffffffffc0202458 <exit_range+0x182>
ffffffffc02023c4:	09397a63          	bgeu	s2,s3,ffffffffc0202458 <exit_range+0x182>
ffffffffc02023c8:	0f597063          	bgeu	s2,s5,ffffffffc02024a8 <exit_range+0x1d2>
                pde0 = pd0[PDX0(d0start)];
ffffffffc02023cc:	01595493          	srli	s1,s2,0x15
ffffffffc02023d0:	1ff4f493          	andi	s1,s1,511
ffffffffc02023d4:	048e                	slli	s1,s1,0x3
ffffffffc02023d6:	94da                	add	s1,s1,s6
ffffffffc02023d8:	609c                	ld	a5,0(s1)
                if (pde0 & PTE_V)
ffffffffc02023da:	0017f693          	andi	a3,a5,1
ffffffffc02023de:	dee9                	beqz	a3,ffffffffc02023b8 <exit_range+0xe2>
    if (PPN(pa) >= npage)
ffffffffc02023e0:	000d3583          	ld	a1,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc02023e4:	078a                	slli	a5,a5,0x2
ffffffffc02023e6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02023e8:	14b7fe63          	bgeu	a5,a1,ffffffffc0202544 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc02023ec:	97f2                	add	a5,a5,t3
    return page - pages + nbase;
ffffffffc02023ee:	006786b3          	add	a3,a5,t1
    return KADDR(page2pa(page));
ffffffffc02023f2:	0196feb3          	and	t4,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc02023f6:	00679513          	slli	a0,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc02023fa:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02023fc:	12bef863          	bgeu	t4,a1,ffffffffc020252c <exit_range+0x256>
ffffffffc0202400:	00083783          	ld	a5,0(a6)
ffffffffc0202404:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc0202406:	011685b3          	add	a1,a3,a7
                        if (pt[i] & PTE_V)
ffffffffc020240a:	629c                	ld	a5,0(a3)
ffffffffc020240c:	8b85                	andi	a5,a5,1
ffffffffc020240e:	f7d5                	bnez	a5,ffffffffc02023ba <exit_range+0xe4>
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc0202410:	06a1                	addi	a3,a3,8
ffffffffc0202412:	fed59ce3          	bne	a1,a3,ffffffffc020240a <exit_range+0x134>
    return &pages[PPN(pa) - nbase];
ffffffffc0202416:	631c                	ld	a5,0(a4)
ffffffffc0202418:	953e                	add	a0,a0,a5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020241a:	100027f3          	csrr	a5,sstatus
ffffffffc020241e:	8b89                	andi	a5,a5,2
ffffffffc0202420:	e7d9                	bnez	a5,ffffffffc02024ae <exit_range+0x1d8>
        pmm_manager->free_pages(base, n);
ffffffffc0202422:	000db783          	ld	a5,0(s11)
ffffffffc0202426:	4585                	li	a1,1
ffffffffc0202428:	e032                	sd	a2,0(sp)
ffffffffc020242a:	739c                	ld	a5,32(a5)
ffffffffc020242c:	9782                	jalr	a5
    if (flag)
ffffffffc020242e:	6602                	ld	a2,0(sp)
ffffffffc0202430:	000a8817          	auipc	a6,0xa8
ffffffffc0202434:	2b880813          	addi	a6,a6,696 # ffffffffc02aa6e8 <va_pa_offset>
ffffffffc0202438:	fff80e37          	lui	t3,0xfff80
ffffffffc020243c:	00080337          	lui	t1,0x80
ffffffffc0202440:	6885                	lui	a7,0x1
ffffffffc0202442:	000a8717          	auipc	a4,0xa8
ffffffffc0202446:	29670713          	addi	a4,a4,662 # ffffffffc02aa6d8 <pages>
                        pd0[PDX0(d0start)] = 0;
ffffffffc020244a:	0004b023          	sd	zero,0(s1)
                d0start += PTSIZE;
ffffffffc020244e:	002007b7          	lui	a5,0x200
ffffffffc0202452:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc0202454:	f60918e3          	bnez	s2,ffffffffc02023c4 <exit_range+0xee>
            if (free_pd0)
ffffffffc0202458:	f00b85e3          	beqz	s7,ffffffffc0202362 <exit_range+0x8c>
    if (PPN(pa) >= npage)
ffffffffc020245c:	000d3783          	ld	a5,0(s10)
ffffffffc0202460:	0efa7263          	bgeu	s4,a5,ffffffffc0202544 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202464:	6308                	ld	a0,0(a4)
ffffffffc0202466:	9532                	add	a0,a0,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202468:	100027f3          	csrr	a5,sstatus
ffffffffc020246c:	8b89                	andi	a5,a5,2
ffffffffc020246e:	efad                	bnez	a5,ffffffffc02024e8 <exit_range+0x212>
        pmm_manager->free_pages(base, n);
ffffffffc0202470:	000db783          	ld	a5,0(s11)
ffffffffc0202474:	4585                	li	a1,1
ffffffffc0202476:	739c                	ld	a5,32(a5)
ffffffffc0202478:	9782                	jalr	a5
ffffffffc020247a:	000a8717          	auipc	a4,0xa8
ffffffffc020247e:	25e70713          	addi	a4,a4,606 # ffffffffc02aa6d8 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202482:	00043023          	sd	zero,0(s0)
    } while (d1start != 0 && d1start < end);
ffffffffc0202486:	ee0990e3          	bnez	s3,ffffffffc0202366 <exit_range+0x90>
}
ffffffffc020248a:	70e6                	ld	ra,120(sp)
ffffffffc020248c:	7446                	ld	s0,112(sp)
ffffffffc020248e:	74a6                	ld	s1,104(sp)
ffffffffc0202490:	7906                	ld	s2,96(sp)
ffffffffc0202492:	69e6                	ld	s3,88(sp)
ffffffffc0202494:	6a46                	ld	s4,80(sp)
ffffffffc0202496:	6aa6                	ld	s5,72(sp)
ffffffffc0202498:	6b06                	ld	s6,64(sp)
ffffffffc020249a:	7be2                	ld	s7,56(sp)
ffffffffc020249c:	7c42                	ld	s8,48(sp)
ffffffffc020249e:	7ca2                	ld	s9,40(sp)
ffffffffc02024a0:	7d02                	ld	s10,32(sp)
ffffffffc02024a2:	6de2                	ld	s11,24(sp)
ffffffffc02024a4:	6109                	addi	sp,sp,128
ffffffffc02024a6:	8082                	ret
            if (free_pd0)
ffffffffc02024a8:	ea0b8fe3          	beqz	s7,ffffffffc0202366 <exit_range+0x90>
ffffffffc02024ac:	bf45                	j	ffffffffc020245c <exit_range+0x186>
ffffffffc02024ae:	e032                	sd	a2,0(sp)
        intr_disable();
ffffffffc02024b0:	e42a                	sd	a0,8(sp)
ffffffffc02024b2:	d02fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02024b6:	000db783          	ld	a5,0(s11)
ffffffffc02024ba:	6522                	ld	a0,8(sp)
ffffffffc02024bc:	4585                	li	a1,1
ffffffffc02024be:	739c                	ld	a5,32(a5)
ffffffffc02024c0:	9782                	jalr	a5
        intr_enable();
ffffffffc02024c2:	cecfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02024c6:	6602                	ld	a2,0(sp)
ffffffffc02024c8:	000a8717          	auipc	a4,0xa8
ffffffffc02024cc:	21070713          	addi	a4,a4,528 # ffffffffc02aa6d8 <pages>
ffffffffc02024d0:	6885                	lui	a7,0x1
ffffffffc02024d2:	00080337          	lui	t1,0x80
ffffffffc02024d6:	fff80e37          	lui	t3,0xfff80
ffffffffc02024da:	000a8817          	auipc	a6,0xa8
ffffffffc02024de:	20e80813          	addi	a6,a6,526 # ffffffffc02aa6e8 <va_pa_offset>
                        pd0[PDX0(d0start)] = 0;
ffffffffc02024e2:	0004b023          	sd	zero,0(s1)
ffffffffc02024e6:	b7a5                	j	ffffffffc020244e <exit_range+0x178>
ffffffffc02024e8:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc02024ea:	ccafe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02024ee:	000db783          	ld	a5,0(s11)
ffffffffc02024f2:	6502                	ld	a0,0(sp)
ffffffffc02024f4:	4585                	li	a1,1
ffffffffc02024f6:	739c                	ld	a5,32(a5)
ffffffffc02024f8:	9782                	jalr	a5
        intr_enable();
ffffffffc02024fa:	cb4fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02024fe:	000a8717          	auipc	a4,0xa8
ffffffffc0202502:	1da70713          	addi	a4,a4,474 # ffffffffc02aa6d8 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202506:	00043023          	sd	zero,0(s0)
ffffffffc020250a:	bfb5                	j	ffffffffc0202486 <exit_range+0x1b0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020250c:	00004697          	auipc	a3,0x4
ffffffffc0202510:	0bc68693          	addi	a3,a3,188 # ffffffffc02065c8 <default_pmm_manager+0x160>
ffffffffc0202514:	00004617          	auipc	a2,0x4
ffffffffc0202518:	ba460613          	addi	a2,a2,-1116 # ffffffffc02060b8 <commands+0x818>
ffffffffc020251c:	13500593          	li	a1,309
ffffffffc0202520:	00004517          	auipc	a0,0x4
ffffffffc0202524:	09850513          	addi	a0,a0,152 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc0202528:	f67fd0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc020252c:	00004617          	auipc	a2,0x4
ffffffffc0202530:	f7460613          	addi	a2,a2,-140 # ffffffffc02064a0 <default_pmm_manager+0x38>
ffffffffc0202534:	07100593          	li	a1,113
ffffffffc0202538:	00004517          	auipc	a0,0x4
ffffffffc020253c:	f9050513          	addi	a0,a0,-112 # ffffffffc02064c8 <default_pmm_manager+0x60>
ffffffffc0202540:	f4ffd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0202544:	8e1ff0ef          	jal	ra,ffffffffc0201e24 <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc0202548:	00004697          	auipc	a3,0x4
ffffffffc020254c:	0b068693          	addi	a3,a3,176 # ffffffffc02065f8 <default_pmm_manager+0x190>
ffffffffc0202550:	00004617          	auipc	a2,0x4
ffffffffc0202554:	b6860613          	addi	a2,a2,-1176 # ffffffffc02060b8 <commands+0x818>
ffffffffc0202558:	13600593          	li	a1,310
ffffffffc020255c:	00004517          	auipc	a0,0x4
ffffffffc0202560:	05c50513          	addi	a0,a0,92 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc0202564:	f2bfd0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0202568 <page_remove>:
{
ffffffffc0202568:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020256a:	4601                	li	a2,0
{
ffffffffc020256c:	ec26                	sd	s1,24(sp)
ffffffffc020256e:	f406                	sd	ra,40(sp)
ffffffffc0202570:	f022                	sd	s0,32(sp)
ffffffffc0202572:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202574:	9a1ff0ef          	jal	ra,ffffffffc0201f14 <get_pte>
    if (ptep != NULL)
ffffffffc0202578:	c511                	beqz	a0,ffffffffc0202584 <page_remove+0x1c>
    if (*ptep & PTE_V)
ffffffffc020257a:	611c                	ld	a5,0(a0)
ffffffffc020257c:	842a                	mv	s0,a0
ffffffffc020257e:	0017f713          	andi	a4,a5,1
ffffffffc0202582:	e711                	bnez	a4,ffffffffc020258e <page_remove+0x26>
}
ffffffffc0202584:	70a2                	ld	ra,40(sp)
ffffffffc0202586:	7402                	ld	s0,32(sp)
ffffffffc0202588:	64e2                	ld	s1,24(sp)
ffffffffc020258a:	6145                	addi	sp,sp,48
ffffffffc020258c:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc020258e:	078a                	slli	a5,a5,0x2
ffffffffc0202590:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202592:	000a8717          	auipc	a4,0xa8
ffffffffc0202596:	13e73703          	ld	a4,318(a4) # ffffffffc02aa6d0 <npage>
ffffffffc020259a:	06e7f363          	bgeu	a5,a4,ffffffffc0202600 <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc020259e:	fff80537          	lui	a0,0xfff80
ffffffffc02025a2:	97aa                	add	a5,a5,a0
ffffffffc02025a4:	079a                	slli	a5,a5,0x6
ffffffffc02025a6:	000a8517          	auipc	a0,0xa8
ffffffffc02025aa:	13253503          	ld	a0,306(a0) # ffffffffc02aa6d8 <pages>
ffffffffc02025ae:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc02025b0:	411c                	lw	a5,0(a0)
ffffffffc02025b2:	fff7871b          	addiw	a4,a5,-1
ffffffffc02025b6:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc02025b8:	cb11                	beqz	a4,ffffffffc02025cc <page_remove+0x64>
        *ptep = 0;
ffffffffc02025ba:	00043023          	sd	zero,0(s0)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02025be:	12048073          	sfence.vma	s1
}
ffffffffc02025c2:	70a2                	ld	ra,40(sp)
ffffffffc02025c4:	7402                	ld	s0,32(sp)
ffffffffc02025c6:	64e2                	ld	s1,24(sp)
ffffffffc02025c8:	6145                	addi	sp,sp,48
ffffffffc02025ca:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02025cc:	100027f3          	csrr	a5,sstatus
ffffffffc02025d0:	8b89                	andi	a5,a5,2
ffffffffc02025d2:	eb89                	bnez	a5,ffffffffc02025e4 <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc02025d4:	000a8797          	auipc	a5,0xa8
ffffffffc02025d8:	10c7b783          	ld	a5,268(a5) # ffffffffc02aa6e0 <pmm_manager>
ffffffffc02025dc:	739c                	ld	a5,32(a5)
ffffffffc02025de:	4585                	li	a1,1
ffffffffc02025e0:	9782                	jalr	a5
    if (flag)
ffffffffc02025e2:	bfe1                	j	ffffffffc02025ba <page_remove+0x52>
        intr_disable();
ffffffffc02025e4:	e42a                	sd	a0,8(sp)
ffffffffc02025e6:	bcefe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02025ea:	000a8797          	auipc	a5,0xa8
ffffffffc02025ee:	0f67b783          	ld	a5,246(a5) # ffffffffc02aa6e0 <pmm_manager>
ffffffffc02025f2:	739c                	ld	a5,32(a5)
ffffffffc02025f4:	6522                	ld	a0,8(sp)
ffffffffc02025f6:	4585                	li	a1,1
ffffffffc02025f8:	9782                	jalr	a5
        intr_enable();
ffffffffc02025fa:	bb4fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02025fe:	bf75                	j	ffffffffc02025ba <page_remove+0x52>
ffffffffc0202600:	825ff0ef          	jal	ra,ffffffffc0201e24 <pa2page.part.0>

ffffffffc0202604 <page_insert>:
{
ffffffffc0202604:	7139                	addi	sp,sp,-64
ffffffffc0202606:	e852                	sd	s4,16(sp)
ffffffffc0202608:	8a32                	mv	s4,a2
ffffffffc020260a:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020260c:	4605                	li	a2,1
{
ffffffffc020260e:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202610:	85d2                	mv	a1,s4
{
ffffffffc0202612:	f426                	sd	s1,40(sp)
ffffffffc0202614:	fc06                	sd	ra,56(sp)
ffffffffc0202616:	f04a                	sd	s2,32(sp)
ffffffffc0202618:	ec4e                	sd	s3,24(sp)
ffffffffc020261a:	e456                	sd	s5,8(sp)
ffffffffc020261c:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020261e:	8f7ff0ef          	jal	ra,ffffffffc0201f14 <get_pte>
    if (ptep == NULL)
ffffffffc0202622:	c961                	beqz	a0,ffffffffc02026f2 <page_insert+0xee>
    page->ref += 1;
ffffffffc0202624:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V)
ffffffffc0202626:	611c                	ld	a5,0(a0)
ffffffffc0202628:	89aa                	mv	s3,a0
ffffffffc020262a:	0016871b          	addiw	a4,a3,1
ffffffffc020262e:	c018                	sw	a4,0(s0)
ffffffffc0202630:	0017f713          	andi	a4,a5,1
ffffffffc0202634:	ef05                	bnez	a4,ffffffffc020266c <page_insert+0x68>
    return page - pages + nbase;
ffffffffc0202636:	000a8717          	auipc	a4,0xa8
ffffffffc020263a:	0a273703          	ld	a4,162(a4) # ffffffffc02aa6d8 <pages>
ffffffffc020263e:	8c19                	sub	s0,s0,a4
ffffffffc0202640:	000807b7          	lui	a5,0x80
ffffffffc0202644:	8419                	srai	s0,s0,0x6
ffffffffc0202646:	943e                	add	s0,s0,a5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202648:	042a                	slli	s0,s0,0xa
ffffffffc020264a:	8cc1                	or	s1,s1,s0
ffffffffc020264c:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc0202650:	0099b023          	sd	s1,0(s3) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4ee0>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202654:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc0202658:	4501                	li	a0,0
}
ffffffffc020265a:	70e2                	ld	ra,56(sp)
ffffffffc020265c:	7442                	ld	s0,48(sp)
ffffffffc020265e:	74a2                	ld	s1,40(sp)
ffffffffc0202660:	7902                	ld	s2,32(sp)
ffffffffc0202662:	69e2                	ld	s3,24(sp)
ffffffffc0202664:	6a42                	ld	s4,16(sp)
ffffffffc0202666:	6aa2                	ld	s5,8(sp)
ffffffffc0202668:	6121                	addi	sp,sp,64
ffffffffc020266a:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc020266c:	078a                	slli	a5,a5,0x2
ffffffffc020266e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202670:	000a8717          	auipc	a4,0xa8
ffffffffc0202674:	06073703          	ld	a4,96(a4) # ffffffffc02aa6d0 <npage>
ffffffffc0202678:	06e7ff63          	bgeu	a5,a4,ffffffffc02026f6 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc020267c:	000a8a97          	auipc	s5,0xa8
ffffffffc0202680:	05ca8a93          	addi	s5,s5,92 # ffffffffc02aa6d8 <pages>
ffffffffc0202684:	000ab703          	ld	a4,0(s5)
ffffffffc0202688:	fff80937          	lui	s2,0xfff80
ffffffffc020268c:	993e                	add	s2,s2,a5
ffffffffc020268e:	091a                	slli	s2,s2,0x6
ffffffffc0202690:	993a                	add	s2,s2,a4
        if (p == page)
ffffffffc0202692:	01240c63          	beq	s0,s2,ffffffffc02026aa <page_insert+0xa6>
    page->ref -= 1;
ffffffffc0202696:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fcd58f4>
ffffffffc020269a:	fff7869b          	addiw	a3,a5,-1
ffffffffc020269e:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) == 0)
ffffffffc02026a2:	c691                	beqz	a3,ffffffffc02026ae <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02026a4:	120a0073          	sfence.vma	s4
}
ffffffffc02026a8:	bf59                	j	ffffffffc020263e <page_insert+0x3a>
ffffffffc02026aa:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc02026ac:	bf49                	j	ffffffffc020263e <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02026ae:	100027f3          	csrr	a5,sstatus
ffffffffc02026b2:	8b89                	andi	a5,a5,2
ffffffffc02026b4:	ef91                	bnez	a5,ffffffffc02026d0 <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc02026b6:	000a8797          	auipc	a5,0xa8
ffffffffc02026ba:	02a7b783          	ld	a5,42(a5) # ffffffffc02aa6e0 <pmm_manager>
ffffffffc02026be:	739c                	ld	a5,32(a5)
ffffffffc02026c0:	4585                	li	a1,1
ffffffffc02026c2:	854a                	mv	a0,s2
ffffffffc02026c4:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc02026c6:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02026ca:	120a0073          	sfence.vma	s4
ffffffffc02026ce:	bf85                	j	ffffffffc020263e <page_insert+0x3a>
        intr_disable();
ffffffffc02026d0:	ae4fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02026d4:	000a8797          	auipc	a5,0xa8
ffffffffc02026d8:	00c7b783          	ld	a5,12(a5) # ffffffffc02aa6e0 <pmm_manager>
ffffffffc02026dc:	739c                	ld	a5,32(a5)
ffffffffc02026de:	4585                	li	a1,1
ffffffffc02026e0:	854a                	mv	a0,s2
ffffffffc02026e2:	9782                	jalr	a5
        intr_enable();
ffffffffc02026e4:	acafe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02026e8:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02026ec:	120a0073          	sfence.vma	s4
ffffffffc02026f0:	b7b9                	j	ffffffffc020263e <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc02026f2:	5571                	li	a0,-4
ffffffffc02026f4:	b79d                	j	ffffffffc020265a <page_insert+0x56>
ffffffffc02026f6:	f2eff0ef          	jal	ra,ffffffffc0201e24 <pa2page.part.0>

ffffffffc02026fa <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc02026fa:	00004797          	auipc	a5,0x4
ffffffffc02026fe:	d6e78793          	addi	a5,a5,-658 # ffffffffc0206468 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202702:	638c                	ld	a1,0(a5)
{
ffffffffc0202704:	7159                	addi	sp,sp,-112
ffffffffc0202706:	f85a                	sd	s6,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202708:	00004517          	auipc	a0,0x4
ffffffffc020270c:	f0850513          	addi	a0,a0,-248 # ffffffffc0206610 <default_pmm_manager+0x1a8>
    pmm_manager = &default_pmm_manager;
ffffffffc0202710:	000a8b17          	auipc	s6,0xa8
ffffffffc0202714:	fd0b0b13          	addi	s6,s6,-48 # ffffffffc02aa6e0 <pmm_manager>
{
ffffffffc0202718:	f486                	sd	ra,104(sp)
ffffffffc020271a:	e8ca                	sd	s2,80(sp)
ffffffffc020271c:	e4ce                	sd	s3,72(sp)
ffffffffc020271e:	f0a2                	sd	s0,96(sp)
ffffffffc0202720:	eca6                	sd	s1,88(sp)
ffffffffc0202722:	e0d2                	sd	s4,64(sp)
ffffffffc0202724:	fc56                	sd	s5,56(sp)
ffffffffc0202726:	f45e                	sd	s7,40(sp)
ffffffffc0202728:	f062                	sd	s8,32(sp)
ffffffffc020272a:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc020272c:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202730:	a65fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    pmm_manager->init();
ffffffffc0202734:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202738:	000a8997          	auipc	s3,0xa8
ffffffffc020273c:	fb098993          	addi	s3,s3,-80 # ffffffffc02aa6e8 <va_pa_offset>
    pmm_manager->init();
ffffffffc0202740:	679c                	ld	a5,8(a5)
ffffffffc0202742:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202744:	57f5                	li	a5,-3
ffffffffc0202746:	07fa                	slli	a5,a5,0x1e
ffffffffc0202748:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc020274c:	a4efe0ef          	jal	ra,ffffffffc020099a <get_memory_base>
ffffffffc0202750:	892a                	mv	s2,a0
    uint64_t mem_size = get_memory_size();
ffffffffc0202752:	a52fe0ef          	jal	ra,ffffffffc02009a4 <get_memory_size>
    if (mem_size == 0)
ffffffffc0202756:	200505e3          	beqz	a0,ffffffffc0203160 <pmm_init+0xa66>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc020275a:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc020275c:	00004517          	auipc	a0,0x4
ffffffffc0202760:	eec50513          	addi	a0,a0,-276 # ffffffffc0206648 <default_pmm_manager+0x1e0>
ffffffffc0202764:	a31fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc0202768:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc020276c:	fff40693          	addi	a3,s0,-1
ffffffffc0202770:	864a                	mv	a2,s2
ffffffffc0202772:	85a6                	mv	a1,s1
ffffffffc0202774:	00004517          	auipc	a0,0x4
ffffffffc0202778:	eec50513          	addi	a0,a0,-276 # ffffffffc0206660 <default_pmm_manager+0x1f8>
ffffffffc020277c:	a19fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0202780:	c8000737          	lui	a4,0xc8000
ffffffffc0202784:	87a2                	mv	a5,s0
ffffffffc0202786:	54876163          	bltu	a4,s0,ffffffffc0202cc8 <pmm_init+0x5ce>
ffffffffc020278a:	757d                	lui	a0,0xfffff
ffffffffc020278c:	000a9617          	auipc	a2,0xa9
ffffffffc0202790:	f7f60613          	addi	a2,a2,-129 # ffffffffc02ab70b <end+0xfff>
ffffffffc0202794:	8e69                	and	a2,a2,a0
ffffffffc0202796:	000a8497          	auipc	s1,0xa8
ffffffffc020279a:	f3a48493          	addi	s1,s1,-198 # ffffffffc02aa6d0 <npage>
ffffffffc020279e:	00c7d513          	srli	a0,a5,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02027a2:	000a8b97          	auipc	s7,0xa8
ffffffffc02027a6:	f36b8b93          	addi	s7,s7,-202 # ffffffffc02aa6d8 <pages>
    npage = maxpa / PGSIZE;
ffffffffc02027aa:	e088                	sd	a0,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02027ac:	00cbb023          	sd	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02027b0:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02027b4:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02027b6:	02f50863          	beq	a0,a5,ffffffffc02027e6 <pmm_init+0xec>
ffffffffc02027ba:	4781                	li	a5,0
ffffffffc02027bc:	4585                	li	a1,1
ffffffffc02027be:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc02027c2:	00679513          	slli	a0,a5,0x6
ffffffffc02027c6:	9532                	add	a0,a0,a2
ffffffffc02027c8:	00850713          	addi	a4,a0,8 # fffffffffffff008 <end+0x3fd548fc>
ffffffffc02027cc:	40b7302f          	amoor.d	zero,a1,(a4)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02027d0:	6088                	ld	a0,0(s1)
ffffffffc02027d2:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc02027d4:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02027d8:	00d50733          	add	a4,a0,a3
ffffffffc02027dc:	fee7e3e3          	bltu	a5,a4,ffffffffc02027c2 <pmm_init+0xc8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02027e0:	071a                	slli	a4,a4,0x6
ffffffffc02027e2:	00e606b3          	add	a3,a2,a4
ffffffffc02027e6:	c02007b7          	lui	a5,0xc0200
ffffffffc02027ea:	2ef6ece3          	bltu	a3,a5,ffffffffc02032e2 <pmm_init+0xbe8>
ffffffffc02027ee:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc02027f2:	77fd                	lui	a5,0xfffff
ffffffffc02027f4:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02027f6:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc02027f8:	5086eb63          	bltu	a3,s0,ffffffffc0202d0e <pmm_init+0x614>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc02027fc:	00004517          	auipc	a0,0x4
ffffffffc0202800:	e8c50513          	addi	a0,a0,-372 # ffffffffc0206688 <default_pmm_manager+0x220>
ffffffffc0202804:	991fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0202808:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc020280c:	000a8917          	auipc	s2,0xa8
ffffffffc0202810:	ebc90913          	addi	s2,s2,-324 # ffffffffc02aa6c8 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc0202814:	7b9c                	ld	a5,48(a5)
ffffffffc0202816:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202818:	00004517          	auipc	a0,0x4
ffffffffc020281c:	e8850513          	addi	a0,a0,-376 # ffffffffc02066a0 <default_pmm_manager+0x238>
ffffffffc0202820:	975fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202824:	00007697          	auipc	a3,0x7
ffffffffc0202828:	7dc68693          	addi	a3,a3,2012 # ffffffffc020a000 <boot_page_table_sv39>
ffffffffc020282c:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0202830:	c02007b7          	lui	a5,0xc0200
ffffffffc0202834:	28f6ebe3          	bltu	a3,a5,ffffffffc02032ca <pmm_init+0xbd0>
ffffffffc0202838:	0009b783          	ld	a5,0(s3)
ffffffffc020283c:	8e9d                	sub	a3,a3,a5
ffffffffc020283e:	000a8797          	auipc	a5,0xa8
ffffffffc0202842:	e8d7b123          	sd	a3,-382(a5) # ffffffffc02aa6c0 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202846:	100027f3          	csrr	a5,sstatus
ffffffffc020284a:	8b89                	andi	a5,a5,2
ffffffffc020284c:	4a079763          	bnez	a5,ffffffffc0202cfa <pmm_init+0x600>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202850:	000b3783          	ld	a5,0(s6)
ffffffffc0202854:	779c                	ld	a5,40(a5)
ffffffffc0202856:	9782                	jalr	a5
ffffffffc0202858:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc020285a:	6098                	ld	a4,0(s1)
ffffffffc020285c:	c80007b7          	lui	a5,0xc8000
ffffffffc0202860:	83b1                	srli	a5,a5,0xc
ffffffffc0202862:	66e7e363          	bltu	a5,a4,ffffffffc0202ec8 <pmm_init+0x7ce>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202866:	00093503          	ld	a0,0(s2)
ffffffffc020286a:	62050f63          	beqz	a0,ffffffffc0202ea8 <pmm_init+0x7ae>
ffffffffc020286e:	03451793          	slli	a5,a0,0x34
ffffffffc0202872:	62079b63          	bnez	a5,ffffffffc0202ea8 <pmm_init+0x7ae>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202876:	4601                	li	a2,0
ffffffffc0202878:	4581                	li	a1,0
ffffffffc020287a:	8c3ff0ef          	jal	ra,ffffffffc020213c <get_page>
ffffffffc020287e:	60051563          	bnez	a0,ffffffffc0202e88 <pmm_init+0x78e>
ffffffffc0202882:	100027f3          	csrr	a5,sstatus
ffffffffc0202886:	8b89                	andi	a5,a5,2
ffffffffc0202888:	44079e63          	bnez	a5,ffffffffc0202ce4 <pmm_init+0x5ea>
        page = pmm_manager->alloc_pages(n);
ffffffffc020288c:	000b3783          	ld	a5,0(s6)
ffffffffc0202890:	4505                	li	a0,1
ffffffffc0202892:	6f9c                	ld	a5,24(a5)
ffffffffc0202894:	9782                	jalr	a5
ffffffffc0202896:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202898:	00093503          	ld	a0,0(s2)
ffffffffc020289c:	4681                	li	a3,0
ffffffffc020289e:	4601                	li	a2,0
ffffffffc02028a0:	85d2                	mv	a1,s4
ffffffffc02028a2:	d63ff0ef          	jal	ra,ffffffffc0202604 <page_insert>
ffffffffc02028a6:	26051ae3          	bnez	a0,ffffffffc020331a <pmm_init+0xc20>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc02028aa:	00093503          	ld	a0,0(s2)
ffffffffc02028ae:	4601                	li	a2,0
ffffffffc02028b0:	4581                	li	a1,0
ffffffffc02028b2:	e62ff0ef          	jal	ra,ffffffffc0201f14 <get_pte>
ffffffffc02028b6:	240502e3          	beqz	a0,ffffffffc02032fa <pmm_init+0xc00>
    assert(pte2page(*ptep) == p1);
ffffffffc02028ba:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc02028bc:	0017f713          	andi	a4,a5,1
ffffffffc02028c0:	5a070263          	beqz	a4,ffffffffc0202e64 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc02028c4:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02028c6:	078a                	slli	a5,a5,0x2
ffffffffc02028c8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02028ca:	58e7fb63          	bgeu	a5,a4,ffffffffc0202e60 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02028ce:	000bb683          	ld	a3,0(s7)
ffffffffc02028d2:	fff80637          	lui	a2,0xfff80
ffffffffc02028d6:	97b2                	add	a5,a5,a2
ffffffffc02028d8:	079a                	slli	a5,a5,0x6
ffffffffc02028da:	97b6                	add	a5,a5,a3
ffffffffc02028dc:	14fa17e3          	bne	s4,a5,ffffffffc020322a <pmm_init+0xb30>
    assert(page_ref(p1) == 1);
ffffffffc02028e0:	000a2683          	lw	a3,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8ba8>
ffffffffc02028e4:	4785                	li	a5,1
ffffffffc02028e6:	12f692e3          	bne	a3,a5,ffffffffc020320a <pmm_init+0xb10>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc02028ea:	00093503          	ld	a0,0(s2)
ffffffffc02028ee:	77fd                	lui	a5,0xfffff
ffffffffc02028f0:	6114                	ld	a3,0(a0)
ffffffffc02028f2:	068a                	slli	a3,a3,0x2
ffffffffc02028f4:	8efd                	and	a3,a3,a5
ffffffffc02028f6:	00c6d613          	srli	a2,a3,0xc
ffffffffc02028fa:	0ee67ce3          	bgeu	a2,a4,ffffffffc02031f2 <pmm_init+0xaf8>
ffffffffc02028fe:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202902:	96e2                	add	a3,a3,s8
ffffffffc0202904:	0006ba83          	ld	s5,0(a3)
ffffffffc0202908:	0a8a                	slli	s5,s5,0x2
ffffffffc020290a:	00fafab3          	and	s5,s5,a5
ffffffffc020290e:	00cad793          	srli	a5,s5,0xc
ffffffffc0202912:	0ce7f3e3          	bgeu	a5,a4,ffffffffc02031d8 <pmm_init+0xade>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202916:	4601                	li	a2,0
ffffffffc0202918:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020291a:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020291c:	df8ff0ef          	jal	ra,ffffffffc0201f14 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202920:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202922:	55551363          	bne	a0,s5,ffffffffc0202e68 <pmm_init+0x76e>
ffffffffc0202926:	100027f3          	csrr	a5,sstatus
ffffffffc020292a:	8b89                	andi	a5,a5,2
ffffffffc020292c:	3a079163          	bnez	a5,ffffffffc0202cce <pmm_init+0x5d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202930:	000b3783          	ld	a5,0(s6)
ffffffffc0202934:	4505                	li	a0,1
ffffffffc0202936:	6f9c                	ld	a5,24(a5)
ffffffffc0202938:	9782                	jalr	a5
ffffffffc020293a:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc020293c:	00093503          	ld	a0,0(s2)
ffffffffc0202940:	46d1                	li	a3,20
ffffffffc0202942:	6605                	lui	a2,0x1
ffffffffc0202944:	85e2                	mv	a1,s8
ffffffffc0202946:	cbfff0ef          	jal	ra,ffffffffc0202604 <page_insert>
ffffffffc020294a:	060517e3          	bnez	a0,ffffffffc02031b8 <pmm_init+0xabe>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc020294e:	00093503          	ld	a0,0(s2)
ffffffffc0202952:	4601                	li	a2,0
ffffffffc0202954:	6585                	lui	a1,0x1
ffffffffc0202956:	dbeff0ef          	jal	ra,ffffffffc0201f14 <get_pte>
ffffffffc020295a:	02050fe3          	beqz	a0,ffffffffc0203198 <pmm_init+0xa9e>
    assert(*ptep & PTE_U);
ffffffffc020295e:	611c                	ld	a5,0(a0)
ffffffffc0202960:	0107f713          	andi	a4,a5,16
ffffffffc0202964:	7c070e63          	beqz	a4,ffffffffc0203140 <pmm_init+0xa46>
    assert(*ptep & PTE_W);
ffffffffc0202968:	8b91                	andi	a5,a5,4
ffffffffc020296a:	7a078b63          	beqz	a5,ffffffffc0203120 <pmm_init+0xa26>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc020296e:	00093503          	ld	a0,0(s2)
ffffffffc0202972:	611c                	ld	a5,0(a0)
ffffffffc0202974:	8bc1                	andi	a5,a5,16
ffffffffc0202976:	78078563          	beqz	a5,ffffffffc0203100 <pmm_init+0xa06>
    assert(page_ref(p2) == 1);
ffffffffc020297a:	000c2703          	lw	a4,0(s8)
ffffffffc020297e:	4785                	li	a5,1
ffffffffc0202980:	76f71063          	bne	a4,a5,ffffffffc02030e0 <pmm_init+0x9e6>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202984:	4681                	li	a3,0
ffffffffc0202986:	6605                	lui	a2,0x1
ffffffffc0202988:	85d2                	mv	a1,s4
ffffffffc020298a:	c7bff0ef          	jal	ra,ffffffffc0202604 <page_insert>
ffffffffc020298e:	72051963          	bnez	a0,ffffffffc02030c0 <pmm_init+0x9c6>
    assert(page_ref(p1) == 2);
ffffffffc0202992:	000a2703          	lw	a4,0(s4)
ffffffffc0202996:	4789                	li	a5,2
ffffffffc0202998:	70f71463          	bne	a4,a5,ffffffffc02030a0 <pmm_init+0x9a6>
    assert(page_ref(p2) == 0);
ffffffffc020299c:	000c2783          	lw	a5,0(s8)
ffffffffc02029a0:	6e079063          	bnez	a5,ffffffffc0203080 <pmm_init+0x986>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02029a4:	00093503          	ld	a0,0(s2)
ffffffffc02029a8:	4601                	li	a2,0
ffffffffc02029aa:	6585                	lui	a1,0x1
ffffffffc02029ac:	d68ff0ef          	jal	ra,ffffffffc0201f14 <get_pte>
ffffffffc02029b0:	6a050863          	beqz	a0,ffffffffc0203060 <pmm_init+0x966>
    assert(pte2page(*ptep) == p1);
ffffffffc02029b4:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc02029b6:	00177793          	andi	a5,a4,1
ffffffffc02029ba:	4a078563          	beqz	a5,ffffffffc0202e64 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc02029be:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02029c0:	00271793          	slli	a5,a4,0x2
ffffffffc02029c4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02029c6:	48d7fd63          	bgeu	a5,a3,ffffffffc0202e60 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02029ca:	000bb683          	ld	a3,0(s7)
ffffffffc02029ce:	fff80ab7          	lui	s5,0xfff80
ffffffffc02029d2:	97d6                	add	a5,a5,s5
ffffffffc02029d4:	079a                	slli	a5,a5,0x6
ffffffffc02029d6:	97b6                	add	a5,a5,a3
ffffffffc02029d8:	66fa1463          	bne	s4,a5,ffffffffc0203040 <pmm_init+0x946>
    assert((*ptep & PTE_U) == 0);
ffffffffc02029dc:	8b41                	andi	a4,a4,16
ffffffffc02029de:	64071163          	bnez	a4,ffffffffc0203020 <pmm_init+0x926>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc02029e2:	00093503          	ld	a0,0(s2)
ffffffffc02029e6:	4581                	li	a1,0
ffffffffc02029e8:	b81ff0ef          	jal	ra,ffffffffc0202568 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc02029ec:	000a2c83          	lw	s9,0(s4)
ffffffffc02029f0:	4785                	li	a5,1
ffffffffc02029f2:	60fc9763          	bne	s9,a5,ffffffffc0203000 <pmm_init+0x906>
    assert(page_ref(p2) == 0);
ffffffffc02029f6:	000c2783          	lw	a5,0(s8)
ffffffffc02029fa:	5e079363          	bnez	a5,ffffffffc0202fe0 <pmm_init+0x8e6>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc02029fe:	00093503          	ld	a0,0(s2)
ffffffffc0202a02:	6585                	lui	a1,0x1
ffffffffc0202a04:	b65ff0ef          	jal	ra,ffffffffc0202568 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202a08:	000a2783          	lw	a5,0(s4)
ffffffffc0202a0c:	52079a63          	bnez	a5,ffffffffc0202f40 <pmm_init+0x846>
    assert(page_ref(p2) == 0);
ffffffffc0202a10:	000c2783          	lw	a5,0(s8)
ffffffffc0202a14:	50079663          	bnez	a5,ffffffffc0202f20 <pmm_init+0x826>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202a18:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202a1c:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a1e:	000a3683          	ld	a3,0(s4)
ffffffffc0202a22:	068a                	slli	a3,a3,0x2
ffffffffc0202a24:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a26:	42b6fd63          	bgeu	a3,a1,ffffffffc0202e60 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a2a:	000bb503          	ld	a0,0(s7)
ffffffffc0202a2e:	96d6                	add	a3,a3,s5
ffffffffc0202a30:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc0202a32:	00d507b3          	add	a5,a0,a3
ffffffffc0202a36:	439c                	lw	a5,0(a5)
ffffffffc0202a38:	4d979463          	bne	a5,s9,ffffffffc0202f00 <pmm_init+0x806>
    return page - pages + nbase;
ffffffffc0202a3c:	8699                	srai	a3,a3,0x6
ffffffffc0202a3e:	00080637          	lui	a2,0x80
ffffffffc0202a42:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0202a44:	00c69713          	slli	a4,a3,0xc
ffffffffc0202a48:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202a4a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202a4c:	48b77e63          	bgeu	a4,a1,ffffffffc0202ee8 <pmm_init+0x7ee>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202a50:	0009b703          	ld	a4,0(s3)
ffffffffc0202a54:	96ba                	add	a3,a3,a4
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a56:	629c                	ld	a5,0(a3)
ffffffffc0202a58:	078a                	slli	a5,a5,0x2
ffffffffc0202a5a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a5c:	40b7f263          	bgeu	a5,a1,ffffffffc0202e60 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a60:	8f91                	sub	a5,a5,a2
ffffffffc0202a62:	079a                	slli	a5,a5,0x6
ffffffffc0202a64:	953e                	add	a0,a0,a5
ffffffffc0202a66:	100027f3          	csrr	a5,sstatus
ffffffffc0202a6a:	8b89                	andi	a5,a5,2
ffffffffc0202a6c:	30079963          	bnez	a5,ffffffffc0202d7e <pmm_init+0x684>
        pmm_manager->free_pages(base, n);
ffffffffc0202a70:	000b3783          	ld	a5,0(s6)
ffffffffc0202a74:	4585                	li	a1,1
ffffffffc0202a76:	739c                	ld	a5,32(a5)
ffffffffc0202a78:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a7a:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202a7e:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a80:	078a                	slli	a5,a5,0x2
ffffffffc0202a82:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a84:	3ce7fe63          	bgeu	a5,a4,ffffffffc0202e60 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a88:	000bb503          	ld	a0,0(s7)
ffffffffc0202a8c:	fff80737          	lui	a4,0xfff80
ffffffffc0202a90:	97ba                	add	a5,a5,a4
ffffffffc0202a92:	079a                	slli	a5,a5,0x6
ffffffffc0202a94:	953e                	add	a0,a0,a5
ffffffffc0202a96:	100027f3          	csrr	a5,sstatus
ffffffffc0202a9a:	8b89                	andi	a5,a5,2
ffffffffc0202a9c:	2c079563          	bnez	a5,ffffffffc0202d66 <pmm_init+0x66c>
ffffffffc0202aa0:	000b3783          	ld	a5,0(s6)
ffffffffc0202aa4:	4585                	li	a1,1
ffffffffc0202aa6:	739c                	ld	a5,32(a5)
ffffffffc0202aa8:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202aaa:	00093783          	ld	a5,0(s2)
ffffffffc0202aae:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fd548f4>
    asm volatile("sfence.vma");
ffffffffc0202ab2:	12000073          	sfence.vma
ffffffffc0202ab6:	100027f3          	csrr	a5,sstatus
ffffffffc0202aba:	8b89                	andi	a5,a5,2
ffffffffc0202abc:	28079b63          	bnez	a5,ffffffffc0202d52 <pmm_init+0x658>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202ac0:	000b3783          	ld	a5,0(s6)
ffffffffc0202ac4:	779c                	ld	a5,40(a5)
ffffffffc0202ac6:	9782                	jalr	a5
ffffffffc0202ac8:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202aca:	4b441b63          	bne	s0,s4,ffffffffc0202f80 <pmm_init+0x886>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202ace:	00004517          	auipc	a0,0x4
ffffffffc0202ad2:	efa50513          	addi	a0,a0,-262 # ffffffffc02069c8 <default_pmm_manager+0x560>
ffffffffc0202ad6:	ebefd0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0202ada:	100027f3          	csrr	a5,sstatus
ffffffffc0202ade:	8b89                	andi	a5,a5,2
ffffffffc0202ae0:	24079f63          	bnez	a5,ffffffffc0202d3e <pmm_init+0x644>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202ae4:	000b3783          	ld	a5,0(s6)
ffffffffc0202ae8:	779c                	ld	a5,40(a5)
ffffffffc0202aea:	9782                	jalr	a5
ffffffffc0202aec:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202aee:	6098                	ld	a4,0(s1)
ffffffffc0202af0:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202af4:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202af6:	00c71793          	slli	a5,a4,0xc
ffffffffc0202afa:	6a05                	lui	s4,0x1
ffffffffc0202afc:	02f47c63          	bgeu	s0,a5,ffffffffc0202b34 <pmm_init+0x43a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202b00:	00c45793          	srli	a5,s0,0xc
ffffffffc0202b04:	00093503          	ld	a0,0(s2)
ffffffffc0202b08:	2ee7ff63          	bgeu	a5,a4,ffffffffc0202e06 <pmm_init+0x70c>
ffffffffc0202b0c:	0009b583          	ld	a1,0(s3)
ffffffffc0202b10:	4601                	li	a2,0
ffffffffc0202b12:	95a2                	add	a1,a1,s0
ffffffffc0202b14:	c00ff0ef          	jal	ra,ffffffffc0201f14 <get_pte>
ffffffffc0202b18:	32050463          	beqz	a0,ffffffffc0202e40 <pmm_init+0x746>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202b1c:	611c                	ld	a5,0(a0)
ffffffffc0202b1e:	078a                	slli	a5,a5,0x2
ffffffffc0202b20:	0157f7b3          	and	a5,a5,s5
ffffffffc0202b24:	2e879e63          	bne	a5,s0,ffffffffc0202e20 <pmm_init+0x726>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202b28:	6098                	ld	a4,0(s1)
ffffffffc0202b2a:	9452                	add	s0,s0,s4
ffffffffc0202b2c:	00c71793          	slli	a5,a4,0xc
ffffffffc0202b30:	fcf468e3          	bltu	s0,a5,ffffffffc0202b00 <pmm_init+0x406>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202b34:	00093783          	ld	a5,0(s2)
ffffffffc0202b38:	639c                	ld	a5,0(a5)
ffffffffc0202b3a:	42079363          	bnez	a5,ffffffffc0202f60 <pmm_init+0x866>
ffffffffc0202b3e:	100027f3          	csrr	a5,sstatus
ffffffffc0202b42:	8b89                	andi	a5,a5,2
ffffffffc0202b44:	24079963          	bnez	a5,ffffffffc0202d96 <pmm_init+0x69c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202b48:	000b3783          	ld	a5,0(s6)
ffffffffc0202b4c:	4505                	li	a0,1
ffffffffc0202b4e:	6f9c                	ld	a5,24(a5)
ffffffffc0202b50:	9782                	jalr	a5
ffffffffc0202b52:	8a2a                	mv	s4,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202b54:	00093503          	ld	a0,0(s2)
ffffffffc0202b58:	4699                	li	a3,6
ffffffffc0202b5a:	10000613          	li	a2,256
ffffffffc0202b5e:	85d2                	mv	a1,s4
ffffffffc0202b60:	aa5ff0ef          	jal	ra,ffffffffc0202604 <page_insert>
ffffffffc0202b64:	44051e63          	bnez	a0,ffffffffc0202fc0 <pmm_init+0x8c6>
    assert(page_ref(p) == 1);
ffffffffc0202b68:	000a2703          	lw	a4,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8ba8>
ffffffffc0202b6c:	4785                	li	a5,1
ffffffffc0202b6e:	42f71963          	bne	a4,a5,ffffffffc0202fa0 <pmm_init+0x8a6>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202b72:	00093503          	ld	a0,0(s2)
ffffffffc0202b76:	6405                	lui	s0,0x1
ffffffffc0202b78:	4699                	li	a3,6
ffffffffc0202b7a:	10040613          	addi	a2,s0,256 # 1100 <_binary_obj___user_faultread_out_size-0x8aa8>
ffffffffc0202b7e:	85d2                	mv	a1,s4
ffffffffc0202b80:	a85ff0ef          	jal	ra,ffffffffc0202604 <page_insert>
ffffffffc0202b84:	72051363          	bnez	a0,ffffffffc02032aa <pmm_init+0xbb0>
    assert(page_ref(p) == 2);
ffffffffc0202b88:	000a2703          	lw	a4,0(s4)
ffffffffc0202b8c:	4789                	li	a5,2
ffffffffc0202b8e:	6ef71e63          	bne	a4,a5,ffffffffc020328a <pmm_init+0xb90>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202b92:	00004597          	auipc	a1,0x4
ffffffffc0202b96:	f7e58593          	addi	a1,a1,-130 # ffffffffc0206b10 <default_pmm_manager+0x6a8>
ffffffffc0202b9a:	10000513          	li	a0,256
ffffffffc0202b9e:	201020ef          	jal	ra,ffffffffc020559e <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202ba2:	10040593          	addi	a1,s0,256
ffffffffc0202ba6:	10000513          	li	a0,256
ffffffffc0202baa:	207020ef          	jal	ra,ffffffffc02055b0 <strcmp>
ffffffffc0202bae:	6a051e63          	bnez	a0,ffffffffc020326a <pmm_init+0xb70>
    return page - pages + nbase;
ffffffffc0202bb2:	000bb683          	ld	a3,0(s7)
ffffffffc0202bb6:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0202bba:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc0202bbc:	40da06b3          	sub	a3,s4,a3
ffffffffc0202bc0:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0202bc2:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0202bc4:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0202bc6:	8031                	srli	s0,s0,0xc
ffffffffc0202bc8:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc0202bcc:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202bce:	30f77d63          	bgeu	a4,a5,ffffffffc0202ee8 <pmm_init+0x7ee>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202bd2:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202bd6:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202bda:	96be                	add	a3,a3,a5
ffffffffc0202bdc:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202be0:	189020ef          	jal	ra,ffffffffc0205568 <strlen>
ffffffffc0202be4:	66051363          	bnez	a0,ffffffffc020324a <pmm_init+0xb50>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202be8:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202bec:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202bee:	000ab683          	ld	a3,0(s5) # fffffffffffff000 <end+0x3fd548f4>
ffffffffc0202bf2:	068a                	slli	a3,a3,0x2
ffffffffc0202bf4:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202bf6:	26f6f563          	bgeu	a3,a5,ffffffffc0202e60 <pmm_init+0x766>
    return KADDR(page2pa(page));
ffffffffc0202bfa:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0202bfc:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202bfe:	2ef47563          	bgeu	s0,a5,ffffffffc0202ee8 <pmm_init+0x7ee>
ffffffffc0202c02:	0009b403          	ld	s0,0(s3)
ffffffffc0202c06:	9436                	add	s0,s0,a3
ffffffffc0202c08:	100027f3          	csrr	a5,sstatus
ffffffffc0202c0c:	8b89                	andi	a5,a5,2
ffffffffc0202c0e:	1e079163          	bnez	a5,ffffffffc0202df0 <pmm_init+0x6f6>
        pmm_manager->free_pages(base, n);
ffffffffc0202c12:	000b3783          	ld	a5,0(s6)
ffffffffc0202c16:	4585                	li	a1,1
ffffffffc0202c18:	8552                	mv	a0,s4
ffffffffc0202c1a:	739c                	ld	a5,32(a5)
ffffffffc0202c1c:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c1e:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage)
ffffffffc0202c20:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c22:	078a                	slli	a5,a5,0x2
ffffffffc0202c24:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202c26:	22e7fd63          	bgeu	a5,a4,ffffffffc0202e60 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202c2a:	000bb503          	ld	a0,0(s7)
ffffffffc0202c2e:	fff80737          	lui	a4,0xfff80
ffffffffc0202c32:	97ba                	add	a5,a5,a4
ffffffffc0202c34:	079a                	slli	a5,a5,0x6
ffffffffc0202c36:	953e                	add	a0,a0,a5
ffffffffc0202c38:	100027f3          	csrr	a5,sstatus
ffffffffc0202c3c:	8b89                	andi	a5,a5,2
ffffffffc0202c3e:	18079d63          	bnez	a5,ffffffffc0202dd8 <pmm_init+0x6de>
ffffffffc0202c42:	000b3783          	ld	a5,0(s6)
ffffffffc0202c46:	4585                	li	a1,1
ffffffffc0202c48:	739c                	ld	a5,32(a5)
ffffffffc0202c4a:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c4c:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage)
ffffffffc0202c50:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c52:	078a                	slli	a5,a5,0x2
ffffffffc0202c54:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202c56:	20e7f563          	bgeu	a5,a4,ffffffffc0202e60 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202c5a:	000bb503          	ld	a0,0(s7)
ffffffffc0202c5e:	fff80737          	lui	a4,0xfff80
ffffffffc0202c62:	97ba                	add	a5,a5,a4
ffffffffc0202c64:	079a                	slli	a5,a5,0x6
ffffffffc0202c66:	953e                	add	a0,a0,a5
ffffffffc0202c68:	100027f3          	csrr	a5,sstatus
ffffffffc0202c6c:	8b89                	andi	a5,a5,2
ffffffffc0202c6e:	14079963          	bnez	a5,ffffffffc0202dc0 <pmm_init+0x6c6>
ffffffffc0202c72:	000b3783          	ld	a5,0(s6)
ffffffffc0202c76:	4585                	li	a1,1
ffffffffc0202c78:	739c                	ld	a5,32(a5)
ffffffffc0202c7a:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202c7c:	00093783          	ld	a5,0(s2)
ffffffffc0202c80:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0202c84:	12000073          	sfence.vma
ffffffffc0202c88:	100027f3          	csrr	a5,sstatus
ffffffffc0202c8c:	8b89                	andi	a5,a5,2
ffffffffc0202c8e:	10079f63          	bnez	a5,ffffffffc0202dac <pmm_init+0x6b2>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202c92:	000b3783          	ld	a5,0(s6)
ffffffffc0202c96:	779c                	ld	a5,40(a5)
ffffffffc0202c98:	9782                	jalr	a5
ffffffffc0202c9a:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202c9c:	4c8c1e63          	bne	s8,s0,ffffffffc0203178 <pmm_init+0xa7e>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202ca0:	00004517          	auipc	a0,0x4
ffffffffc0202ca4:	ee850513          	addi	a0,a0,-280 # ffffffffc0206b88 <default_pmm_manager+0x720>
ffffffffc0202ca8:	cecfd0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0202cac:	7406                	ld	s0,96(sp)
ffffffffc0202cae:	70a6                	ld	ra,104(sp)
ffffffffc0202cb0:	64e6                	ld	s1,88(sp)
ffffffffc0202cb2:	6946                	ld	s2,80(sp)
ffffffffc0202cb4:	69a6                	ld	s3,72(sp)
ffffffffc0202cb6:	6a06                	ld	s4,64(sp)
ffffffffc0202cb8:	7ae2                	ld	s5,56(sp)
ffffffffc0202cba:	7b42                	ld	s6,48(sp)
ffffffffc0202cbc:	7ba2                	ld	s7,40(sp)
ffffffffc0202cbe:	7c02                	ld	s8,32(sp)
ffffffffc0202cc0:	6ce2                	ld	s9,24(sp)
ffffffffc0202cc2:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202cc4:	f97fe06f          	j	ffffffffc0201c5a <kmalloc_init>
    npage = maxpa / PGSIZE;
ffffffffc0202cc8:	c80007b7          	lui	a5,0xc8000
ffffffffc0202ccc:	bc7d                	j	ffffffffc020278a <pmm_init+0x90>
        intr_disable();
ffffffffc0202cce:	ce7fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202cd2:	000b3783          	ld	a5,0(s6)
ffffffffc0202cd6:	4505                	li	a0,1
ffffffffc0202cd8:	6f9c                	ld	a5,24(a5)
ffffffffc0202cda:	9782                	jalr	a5
ffffffffc0202cdc:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202cde:	cd1fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202ce2:	b9a9                	j	ffffffffc020293c <pmm_init+0x242>
        intr_disable();
ffffffffc0202ce4:	cd1fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202ce8:	000b3783          	ld	a5,0(s6)
ffffffffc0202cec:	4505                	li	a0,1
ffffffffc0202cee:	6f9c                	ld	a5,24(a5)
ffffffffc0202cf0:	9782                	jalr	a5
ffffffffc0202cf2:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202cf4:	cbbfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202cf8:	b645                	j	ffffffffc0202898 <pmm_init+0x19e>
        intr_disable();
ffffffffc0202cfa:	cbbfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202cfe:	000b3783          	ld	a5,0(s6)
ffffffffc0202d02:	779c                	ld	a5,40(a5)
ffffffffc0202d04:	9782                	jalr	a5
ffffffffc0202d06:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202d08:	ca7fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202d0c:	b6b9                	j	ffffffffc020285a <pmm_init+0x160>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202d0e:	6705                	lui	a4,0x1
ffffffffc0202d10:	177d                	addi	a4,a4,-1
ffffffffc0202d12:	96ba                	add	a3,a3,a4
ffffffffc0202d14:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202d16:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202d1a:	14a77363          	bgeu	a4,a0,ffffffffc0202e60 <pmm_init+0x766>
    pmm_manager->init_memmap(base, n);
ffffffffc0202d1e:	000b3683          	ld	a3,0(s6)
    return &pages[PPN(pa) - nbase];
ffffffffc0202d22:	fff80537          	lui	a0,0xfff80
ffffffffc0202d26:	972a                	add	a4,a4,a0
ffffffffc0202d28:	6a94                	ld	a3,16(a3)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202d2a:	8c1d                	sub	s0,s0,a5
ffffffffc0202d2c:	00671513          	slli	a0,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc0202d30:	00c45593          	srli	a1,s0,0xc
ffffffffc0202d34:	9532                	add	a0,a0,a2
ffffffffc0202d36:	9682                	jalr	a3
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202d38:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202d3c:	b4c1                	j	ffffffffc02027fc <pmm_init+0x102>
        intr_disable();
ffffffffc0202d3e:	c77fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202d42:	000b3783          	ld	a5,0(s6)
ffffffffc0202d46:	779c                	ld	a5,40(a5)
ffffffffc0202d48:	9782                	jalr	a5
ffffffffc0202d4a:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202d4c:	c63fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202d50:	bb79                	j	ffffffffc0202aee <pmm_init+0x3f4>
        intr_disable();
ffffffffc0202d52:	c63fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202d56:	000b3783          	ld	a5,0(s6)
ffffffffc0202d5a:	779c                	ld	a5,40(a5)
ffffffffc0202d5c:	9782                	jalr	a5
ffffffffc0202d5e:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202d60:	c4ffd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202d64:	b39d                	j	ffffffffc0202aca <pmm_init+0x3d0>
ffffffffc0202d66:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202d68:	c4dfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202d6c:	000b3783          	ld	a5,0(s6)
ffffffffc0202d70:	6522                	ld	a0,8(sp)
ffffffffc0202d72:	4585                	li	a1,1
ffffffffc0202d74:	739c                	ld	a5,32(a5)
ffffffffc0202d76:	9782                	jalr	a5
        intr_enable();
ffffffffc0202d78:	c37fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202d7c:	b33d                	j	ffffffffc0202aaa <pmm_init+0x3b0>
ffffffffc0202d7e:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202d80:	c35fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202d84:	000b3783          	ld	a5,0(s6)
ffffffffc0202d88:	6522                	ld	a0,8(sp)
ffffffffc0202d8a:	4585                	li	a1,1
ffffffffc0202d8c:	739c                	ld	a5,32(a5)
ffffffffc0202d8e:	9782                	jalr	a5
        intr_enable();
ffffffffc0202d90:	c1ffd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202d94:	b1dd                	j	ffffffffc0202a7a <pmm_init+0x380>
        intr_disable();
ffffffffc0202d96:	c1ffd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202d9a:	000b3783          	ld	a5,0(s6)
ffffffffc0202d9e:	4505                	li	a0,1
ffffffffc0202da0:	6f9c                	ld	a5,24(a5)
ffffffffc0202da2:	9782                	jalr	a5
ffffffffc0202da4:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202da6:	c09fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202daa:	b36d                	j	ffffffffc0202b54 <pmm_init+0x45a>
        intr_disable();
ffffffffc0202dac:	c09fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202db0:	000b3783          	ld	a5,0(s6)
ffffffffc0202db4:	779c                	ld	a5,40(a5)
ffffffffc0202db6:	9782                	jalr	a5
ffffffffc0202db8:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202dba:	bf5fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202dbe:	bdf9                	j	ffffffffc0202c9c <pmm_init+0x5a2>
ffffffffc0202dc0:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202dc2:	bf3fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202dc6:	000b3783          	ld	a5,0(s6)
ffffffffc0202dca:	6522                	ld	a0,8(sp)
ffffffffc0202dcc:	4585                	li	a1,1
ffffffffc0202dce:	739c                	ld	a5,32(a5)
ffffffffc0202dd0:	9782                	jalr	a5
        intr_enable();
ffffffffc0202dd2:	bddfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202dd6:	b55d                	j	ffffffffc0202c7c <pmm_init+0x582>
ffffffffc0202dd8:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202dda:	bdbfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202dde:	000b3783          	ld	a5,0(s6)
ffffffffc0202de2:	6522                	ld	a0,8(sp)
ffffffffc0202de4:	4585                	li	a1,1
ffffffffc0202de6:	739c                	ld	a5,32(a5)
ffffffffc0202de8:	9782                	jalr	a5
        intr_enable();
ffffffffc0202dea:	bc5fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202dee:	bdb9                	j	ffffffffc0202c4c <pmm_init+0x552>
        intr_disable();
ffffffffc0202df0:	bc5fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202df4:	000b3783          	ld	a5,0(s6)
ffffffffc0202df8:	4585                	li	a1,1
ffffffffc0202dfa:	8552                	mv	a0,s4
ffffffffc0202dfc:	739c                	ld	a5,32(a5)
ffffffffc0202dfe:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e00:	baffd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e04:	bd29                	j	ffffffffc0202c1e <pmm_init+0x524>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202e06:	86a2                	mv	a3,s0
ffffffffc0202e08:	00003617          	auipc	a2,0x3
ffffffffc0202e0c:	69860613          	addi	a2,a2,1688 # ffffffffc02064a0 <default_pmm_manager+0x38>
ffffffffc0202e10:	24d00593          	li	a1,589
ffffffffc0202e14:	00003517          	auipc	a0,0x3
ffffffffc0202e18:	7a450513          	addi	a0,a0,1956 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc0202e1c:	e72fd0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202e20:	00004697          	auipc	a3,0x4
ffffffffc0202e24:	c0868693          	addi	a3,a3,-1016 # ffffffffc0206a28 <default_pmm_manager+0x5c0>
ffffffffc0202e28:	00003617          	auipc	a2,0x3
ffffffffc0202e2c:	29060613          	addi	a2,a2,656 # ffffffffc02060b8 <commands+0x818>
ffffffffc0202e30:	24e00593          	li	a1,590
ffffffffc0202e34:	00003517          	auipc	a0,0x3
ffffffffc0202e38:	78450513          	addi	a0,a0,1924 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc0202e3c:	e52fd0ef          	jal	ra,ffffffffc020048e <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202e40:	00004697          	auipc	a3,0x4
ffffffffc0202e44:	ba868693          	addi	a3,a3,-1112 # ffffffffc02069e8 <default_pmm_manager+0x580>
ffffffffc0202e48:	00003617          	auipc	a2,0x3
ffffffffc0202e4c:	27060613          	addi	a2,a2,624 # ffffffffc02060b8 <commands+0x818>
ffffffffc0202e50:	24d00593          	li	a1,589
ffffffffc0202e54:	00003517          	auipc	a0,0x3
ffffffffc0202e58:	76450513          	addi	a0,a0,1892 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc0202e5c:	e32fd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0202e60:	fc5fe0ef          	jal	ra,ffffffffc0201e24 <pa2page.part.0>
ffffffffc0202e64:	fddfe0ef          	jal	ra,ffffffffc0201e40 <pte2page.part.0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202e68:	00004697          	auipc	a3,0x4
ffffffffc0202e6c:	97868693          	addi	a3,a3,-1672 # ffffffffc02067e0 <default_pmm_manager+0x378>
ffffffffc0202e70:	00003617          	auipc	a2,0x3
ffffffffc0202e74:	24860613          	addi	a2,a2,584 # ffffffffc02060b8 <commands+0x818>
ffffffffc0202e78:	21d00593          	li	a1,541
ffffffffc0202e7c:	00003517          	auipc	a0,0x3
ffffffffc0202e80:	73c50513          	addi	a0,a0,1852 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc0202e84:	e0afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202e88:	00004697          	auipc	a3,0x4
ffffffffc0202e8c:	89868693          	addi	a3,a3,-1896 # ffffffffc0206720 <default_pmm_manager+0x2b8>
ffffffffc0202e90:	00003617          	auipc	a2,0x3
ffffffffc0202e94:	22860613          	addi	a2,a2,552 # ffffffffc02060b8 <commands+0x818>
ffffffffc0202e98:	21000593          	li	a1,528
ffffffffc0202e9c:	00003517          	auipc	a0,0x3
ffffffffc0202ea0:	71c50513          	addi	a0,a0,1820 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc0202ea4:	deafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202ea8:	00004697          	auipc	a3,0x4
ffffffffc0202eac:	83868693          	addi	a3,a3,-1992 # ffffffffc02066e0 <default_pmm_manager+0x278>
ffffffffc0202eb0:	00003617          	auipc	a2,0x3
ffffffffc0202eb4:	20860613          	addi	a2,a2,520 # ffffffffc02060b8 <commands+0x818>
ffffffffc0202eb8:	20f00593          	li	a1,527
ffffffffc0202ebc:	00003517          	auipc	a0,0x3
ffffffffc0202ec0:	6fc50513          	addi	a0,a0,1788 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc0202ec4:	dcafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202ec8:	00003697          	auipc	a3,0x3
ffffffffc0202ecc:	7f868693          	addi	a3,a3,2040 # ffffffffc02066c0 <default_pmm_manager+0x258>
ffffffffc0202ed0:	00003617          	auipc	a2,0x3
ffffffffc0202ed4:	1e860613          	addi	a2,a2,488 # ffffffffc02060b8 <commands+0x818>
ffffffffc0202ed8:	20e00593          	li	a1,526
ffffffffc0202edc:	00003517          	auipc	a0,0x3
ffffffffc0202ee0:	6dc50513          	addi	a0,a0,1756 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc0202ee4:	daafd0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0202ee8:	00003617          	auipc	a2,0x3
ffffffffc0202eec:	5b860613          	addi	a2,a2,1464 # ffffffffc02064a0 <default_pmm_manager+0x38>
ffffffffc0202ef0:	07100593          	li	a1,113
ffffffffc0202ef4:	00003517          	auipc	a0,0x3
ffffffffc0202ef8:	5d450513          	addi	a0,a0,1492 # ffffffffc02064c8 <default_pmm_manager+0x60>
ffffffffc0202efc:	d92fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202f00:	00004697          	auipc	a3,0x4
ffffffffc0202f04:	a7068693          	addi	a3,a3,-1424 # ffffffffc0206970 <default_pmm_manager+0x508>
ffffffffc0202f08:	00003617          	auipc	a2,0x3
ffffffffc0202f0c:	1b060613          	addi	a2,a2,432 # ffffffffc02060b8 <commands+0x818>
ffffffffc0202f10:	23600593          	li	a1,566
ffffffffc0202f14:	00003517          	auipc	a0,0x3
ffffffffc0202f18:	6a450513          	addi	a0,a0,1700 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc0202f1c:	d72fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202f20:	00004697          	auipc	a3,0x4
ffffffffc0202f24:	a0868693          	addi	a3,a3,-1528 # ffffffffc0206928 <default_pmm_manager+0x4c0>
ffffffffc0202f28:	00003617          	auipc	a2,0x3
ffffffffc0202f2c:	19060613          	addi	a2,a2,400 # ffffffffc02060b8 <commands+0x818>
ffffffffc0202f30:	23400593          	li	a1,564
ffffffffc0202f34:	00003517          	auipc	a0,0x3
ffffffffc0202f38:	68450513          	addi	a0,a0,1668 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc0202f3c:	d52fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0202f40:	00004697          	auipc	a3,0x4
ffffffffc0202f44:	a1868693          	addi	a3,a3,-1512 # ffffffffc0206958 <default_pmm_manager+0x4f0>
ffffffffc0202f48:	00003617          	auipc	a2,0x3
ffffffffc0202f4c:	17060613          	addi	a2,a2,368 # ffffffffc02060b8 <commands+0x818>
ffffffffc0202f50:	23300593          	li	a1,563
ffffffffc0202f54:	00003517          	auipc	a0,0x3
ffffffffc0202f58:	66450513          	addi	a0,a0,1636 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc0202f5c:	d32fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc0202f60:	00004697          	auipc	a3,0x4
ffffffffc0202f64:	ae068693          	addi	a3,a3,-1312 # ffffffffc0206a40 <default_pmm_manager+0x5d8>
ffffffffc0202f68:	00003617          	auipc	a2,0x3
ffffffffc0202f6c:	15060613          	addi	a2,a2,336 # ffffffffc02060b8 <commands+0x818>
ffffffffc0202f70:	25100593          	li	a1,593
ffffffffc0202f74:	00003517          	auipc	a0,0x3
ffffffffc0202f78:	64450513          	addi	a0,a0,1604 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc0202f7c:	d12fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202f80:	00004697          	auipc	a3,0x4
ffffffffc0202f84:	a2068693          	addi	a3,a3,-1504 # ffffffffc02069a0 <default_pmm_manager+0x538>
ffffffffc0202f88:	00003617          	auipc	a2,0x3
ffffffffc0202f8c:	13060613          	addi	a2,a2,304 # ffffffffc02060b8 <commands+0x818>
ffffffffc0202f90:	23e00593          	li	a1,574
ffffffffc0202f94:	00003517          	auipc	a0,0x3
ffffffffc0202f98:	62450513          	addi	a0,a0,1572 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc0202f9c:	cf2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p) == 1);
ffffffffc0202fa0:	00004697          	auipc	a3,0x4
ffffffffc0202fa4:	af868693          	addi	a3,a3,-1288 # ffffffffc0206a98 <default_pmm_manager+0x630>
ffffffffc0202fa8:	00003617          	auipc	a2,0x3
ffffffffc0202fac:	11060613          	addi	a2,a2,272 # ffffffffc02060b8 <commands+0x818>
ffffffffc0202fb0:	25600593          	li	a1,598
ffffffffc0202fb4:	00003517          	auipc	a0,0x3
ffffffffc0202fb8:	60450513          	addi	a0,a0,1540 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc0202fbc:	cd2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202fc0:	00004697          	auipc	a3,0x4
ffffffffc0202fc4:	a9868693          	addi	a3,a3,-1384 # ffffffffc0206a58 <default_pmm_manager+0x5f0>
ffffffffc0202fc8:	00003617          	auipc	a2,0x3
ffffffffc0202fcc:	0f060613          	addi	a2,a2,240 # ffffffffc02060b8 <commands+0x818>
ffffffffc0202fd0:	25500593          	li	a1,597
ffffffffc0202fd4:	00003517          	auipc	a0,0x3
ffffffffc0202fd8:	5e450513          	addi	a0,a0,1508 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc0202fdc:	cb2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202fe0:	00004697          	auipc	a3,0x4
ffffffffc0202fe4:	94868693          	addi	a3,a3,-1720 # ffffffffc0206928 <default_pmm_manager+0x4c0>
ffffffffc0202fe8:	00003617          	auipc	a2,0x3
ffffffffc0202fec:	0d060613          	addi	a2,a2,208 # ffffffffc02060b8 <commands+0x818>
ffffffffc0202ff0:	23000593          	li	a1,560
ffffffffc0202ff4:	00003517          	auipc	a0,0x3
ffffffffc0202ff8:	5c450513          	addi	a0,a0,1476 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc0202ffc:	c92fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0203000:	00003697          	auipc	a3,0x3
ffffffffc0203004:	7c868693          	addi	a3,a3,1992 # ffffffffc02067c8 <default_pmm_manager+0x360>
ffffffffc0203008:	00003617          	auipc	a2,0x3
ffffffffc020300c:	0b060613          	addi	a2,a2,176 # ffffffffc02060b8 <commands+0x818>
ffffffffc0203010:	22f00593          	li	a1,559
ffffffffc0203014:	00003517          	auipc	a0,0x3
ffffffffc0203018:	5a450513          	addi	a0,a0,1444 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc020301c:	c72fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0203020:	00004697          	auipc	a3,0x4
ffffffffc0203024:	92068693          	addi	a3,a3,-1760 # ffffffffc0206940 <default_pmm_manager+0x4d8>
ffffffffc0203028:	00003617          	auipc	a2,0x3
ffffffffc020302c:	09060613          	addi	a2,a2,144 # ffffffffc02060b8 <commands+0x818>
ffffffffc0203030:	22c00593          	li	a1,556
ffffffffc0203034:	00003517          	auipc	a0,0x3
ffffffffc0203038:	58450513          	addi	a0,a0,1412 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc020303c:	c52fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0203040:	00003697          	auipc	a3,0x3
ffffffffc0203044:	77068693          	addi	a3,a3,1904 # ffffffffc02067b0 <default_pmm_manager+0x348>
ffffffffc0203048:	00003617          	auipc	a2,0x3
ffffffffc020304c:	07060613          	addi	a2,a2,112 # ffffffffc02060b8 <commands+0x818>
ffffffffc0203050:	22b00593          	li	a1,555
ffffffffc0203054:	00003517          	auipc	a0,0x3
ffffffffc0203058:	56450513          	addi	a0,a0,1380 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc020305c:	c32fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0203060:	00003697          	auipc	a3,0x3
ffffffffc0203064:	7f068693          	addi	a3,a3,2032 # ffffffffc0206850 <default_pmm_manager+0x3e8>
ffffffffc0203068:	00003617          	auipc	a2,0x3
ffffffffc020306c:	05060613          	addi	a2,a2,80 # ffffffffc02060b8 <commands+0x818>
ffffffffc0203070:	22a00593          	li	a1,554
ffffffffc0203074:	00003517          	auipc	a0,0x3
ffffffffc0203078:	54450513          	addi	a0,a0,1348 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc020307c:	c12fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203080:	00004697          	auipc	a3,0x4
ffffffffc0203084:	8a868693          	addi	a3,a3,-1880 # ffffffffc0206928 <default_pmm_manager+0x4c0>
ffffffffc0203088:	00003617          	auipc	a2,0x3
ffffffffc020308c:	03060613          	addi	a2,a2,48 # ffffffffc02060b8 <commands+0x818>
ffffffffc0203090:	22900593          	li	a1,553
ffffffffc0203094:	00003517          	auipc	a0,0x3
ffffffffc0203098:	52450513          	addi	a0,a0,1316 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc020309c:	bf2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 2);
ffffffffc02030a0:	00004697          	auipc	a3,0x4
ffffffffc02030a4:	87068693          	addi	a3,a3,-1936 # ffffffffc0206910 <default_pmm_manager+0x4a8>
ffffffffc02030a8:	00003617          	auipc	a2,0x3
ffffffffc02030ac:	01060613          	addi	a2,a2,16 # ffffffffc02060b8 <commands+0x818>
ffffffffc02030b0:	22800593          	li	a1,552
ffffffffc02030b4:	00003517          	auipc	a0,0x3
ffffffffc02030b8:	50450513          	addi	a0,a0,1284 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc02030bc:	bd2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc02030c0:	00004697          	auipc	a3,0x4
ffffffffc02030c4:	82068693          	addi	a3,a3,-2016 # ffffffffc02068e0 <default_pmm_manager+0x478>
ffffffffc02030c8:	00003617          	auipc	a2,0x3
ffffffffc02030cc:	ff060613          	addi	a2,a2,-16 # ffffffffc02060b8 <commands+0x818>
ffffffffc02030d0:	22700593          	li	a1,551
ffffffffc02030d4:	00003517          	auipc	a0,0x3
ffffffffc02030d8:	4e450513          	addi	a0,a0,1252 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc02030dc:	bb2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 1);
ffffffffc02030e0:	00003697          	auipc	a3,0x3
ffffffffc02030e4:	7e868693          	addi	a3,a3,2024 # ffffffffc02068c8 <default_pmm_manager+0x460>
ffffffffc02030e8:	00003617          	auipc	a2,0x3
ffffffffc02030ec:	fd060613          	addi	a2,a2,-48 # ffffffffc02060b8 <commands+0x818>
ffffffffc02030f0:	22500593          	li	a1,549
ffffffffc02030f4:	00003517          	auipc	a0,0x3
ffffffffc02030f8:	4c450513          	addi	a0,a0,1220 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc02030fc:	b92fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0203100:	00003697          	auipc	a3,0x3
ffffffffc0203104:	7a868693          	addi	a3,a3,1960 # ffffffffc02068a8 <default_pmm_manager+0x440>
ffffffffc0203108:	00003617          	auipc	a2,0x3
ffffffffc020310c:	fb060613          	addi	a2,a2,-80 # ffffffffc02060b8 <commands+0x818>
ffffffffc0203110:	22400593          	li	a1,548
ffffffffc0203114:	00003517          	auipc	a0,0x3
ffffffffc0203118:	4a450513          	addi	a0,a0,1188 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc020311c:	b72fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(*ptep & PTE_W);
ffffffffc0203120:	00003697          	auipc	a3,0x3
ffffffffc0203124:	77868693          	addi	a3,a3,1912 # ffffffffc0206898 <default_pmm_manager+0x430>
ffffffffc0203128:	00003617          	auipc	a2,0x3
ffffffffc020312c:	f9060613          	addi	a2,a2,-112 # ffffffffc02060b8 <commands+0x818>
ffffffffc0203130:	22300593          	li	a1,547
ffffffffc0203134:	00003517          	auipc	a0,0x3
ffffffffc0203138:	48450513          	addi	a0,a0,1156 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc020313c:	b52fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(*ptep & PTE_U);
ffffffffc0203140:	00003697          	auipc	a3,0x3
ffffffffc0203144:	74868693          	addi	a3,a3,1864 # ffffffffc0206888 <default_pmm_manager+0x420>
ffffffffc0203148:	00003617          	auipc	a2,0x3
ffffffffc020314c:	f7060613          	addi	a2,a2,-144 # ffffffffc02060b8 <commands+0x818>
ffffffffc0203150:	22200593          	li	a1,546
ffffffffc0203154:	00003517          	auipc	a0,0x3
ffffffffc0203158:	46450513          	addi	a0,a0,1124 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc020315c:	b32fd0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("DTB memory info not available");
ffffffffc0203160:	00003617          	auipc	a2,0x3
ffffffffc0203164:	4c860613          	addi	a2,a2,1224 # ffffffffc0206628 <default_pmm_manager+0x1c0>
ffffffffc0203168:	06500593          	li	a1,101
ffffffffc020316c:	00003517          	auipc	a0,0x3
ffffffffc0203170:	44c50513          	addi	a0,a0,1100 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc0203174:	b1afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0203178:	00004697          	auipc	a3,0x4
ffffffffc020317c:	82868693          	addi	a3,a3,-2008 # ffffffffc02069a0 <default_pmm_manager+0x538>
ffffffffc0203180:	00003617          	auipc	a2,0x3
ffffffffc0203184:	f3860613          	addi	a2,a2,-200 # ffffffffc02060b8 <commands+0x818>
ffffffffc0203188:	26800593          	li	a1,616
ffffffffc020318c:	00003517          	auipc	a0,0x3
ffffffffc0203190:	42c50513          	addi	a0,a0,1068 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc0203194:	afafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0203198:	00003697          	auipc	a3,0x3
ffffffffc020319c:	6b868693          	addi	a3,a3,1720 # ffffffffc0206850 <default_pmm_manager+0x3e8>
ffffffffc02031a0:	00003617          	auipc	a2,0x3
ffffffffc02031a4:	f1860613          	addi	a2,a2,-232 # ffffffffc02060b8 <commands+0x818>
ffffffffc02031a8:	22100593          	li	a1,545
ffffffffc02031ac:	00003517          	auipc	a0,0x3
ffffffffc02031b0:	40c50513          	addi	a0,a0,1036 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc02031b4:	adafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02031b8:	00003697          	auipc	a3,0x3
ffffffffc02031bc:	65868693          	addi	a3,a3,1624 # ffffffffc0206810 <default_pmm_manager+0x3a8>
ffffffffc02031c0:	00003617          	auipc	a2,0x3
ffffffffc02031c4:	ef860613          	addi	a2,a2,-264 # ffffffffc02060b8 <commands+0x818>
ffffffffc02031c8:	22000593          	li	a1,544
ffffffffc02031cc:	00003517          	auipc	a0,0x3
ffffffffc02031d0:	3ec50513          	addi	a0,a0,1004 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc02031d4:	abafd0ef          	jal	ra,ffffffffc020048e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02031d8:	86d6                	mv	a3,s5
ffffffffc02031da:	00003617          	auipc	a2,0x3
ffffffffc02031de:	2c660613          	addi	a2,a2,710 # ffffffffc02064a0 <default_pmm_manager+0x38>
ffffffffc02031e2:	21c00593          	li	a1,540
ffffffffc02031e6:	00003517          	auipc	a0,0x3
ffffffffc02031ea:	3d250513          	addi	a0,a0,978 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc02031ee:	aa0fd0ef          	jal	ra,ffffffffc020048e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc02031f2:	00003617          	auipc	a2,0x3
ffffffffc02031f6:	2ae60613          	addi	a2,a2,686 # ffffffffc02064a0 <default_pmm_manager+0x38>
ffffffffc02031fa:	21b00593          	li	a1,539
ffffffffc02031fe:	00003517          	auipc	a0,0x3
ffffffffc0203202:	3ba50513          	addi	a0,a0,954 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc0203206:	a88fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc020320a:	00003697          	auipc	a3,0x3
ffffffffc020320e:	5be68693          	addi	a3,a3,1470 # ffffffffc02067c8 <default_pmm_manager+0x360>
ffffffffc0203212:	00003617          	auipc	a2,0x3
ffffffffc0203216:	ea660613          	addi	a2,a2,-346 # ffffffffc02060b8 <commands+0x818>
ffffffffc020321a:	21900593          	li	a1,537
ffffffffc020321e:	00003517          	auipc	a0,0x3
ffffffffc0203222:	39a50513          	addi	a0,a0,922 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc0203226:	a68fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc020322a:	00003697          	auipc	a3,0x3
ffffffffc020322e:	58668693          	addi	a3,a3,1414 # ffffffffc02067b0 <default_pmm_manager+0x348>
ffffffffc0203232:	00003617          	auipc	a2,0x3
ffffffffc0203236:	e8660613          	addi	a2,a2,-378 # ffffffffc02060b8 <commands+0x818>
ffffffffc020323a:	21800593          	li	a1,536
ffffffffc020323e:	00003517          	auipc	a0,0x3
ffffffffc0203242:	37a50513          	addi	a0,a0,890 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc0203246:	a48fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc020324a:	00004697          	auipc	a3,0x4
ffffffffc020324e:	91668693          	addi	a3,a3,-1770 # ffffffffc0206b60 <default_pmm_manager+0x6f8>
ffffffffc0203252:	00003617          	auipc	a2,0x3
ffffffffc0203256:	e6660613          	addi	a2,a2,-410 # ffffffffc02060b8 <commands+0x818>
ffffffffc020325a:	25f00593          	li	a1,607
ffffffffc020325e:	00003517          	auipc	a0,0x3
ffffffffc0203262:	35a50513          	addi	a0,a0,858 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc0203266:	a28fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc020326a:	00004697          	auipc	a3,0x4
ffffffffc020326e:	8be68693          	addi	a3,a3,-1858 # ffffffffc0206b28 <default_pmm_manager+0x6c0>
ffffffffc0203272:	00003617          	auipc	a2,0x3
ffffffffc0203276:	e4660613          	addi	a2,a2,-442 # ffffffffc02060b8 <commands+0x818>
ffffffffc020327a:	25c00593          	li	a1,604
ffffffffc020327e:	00003517          	auipc	a0,0x3
ffffffffc0203282:	33a50513          	addi	a0,a0,826 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc0203286:	a08fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p) == 2);
ffffffffc020328a:	00004697          	auipc	a3,0x4
ffffffffc020328e:	86e68693          	addi	a3,a3,-1938 # ffffffffc0206af8 <default_pmm_manager+0x690>
ffffffffc0203292:	00003617          	auipc	a2,0x3
ffffffffc0203296:	e2660613          	addi	a2,a2,-474 # ffffffffc02060b8 <commands+0x818>
ffffffffc020329a:	25800593          	li	a1,600
ffffffffc020329e:	00003517          	auipc	a0,0x3
ffffffffc02032a2:	31a50513          	addi	a0,a0,794 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc02032a6:	9e8fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02032aa:	00004697          	auipc	a3,0x4
ffffffffc02032ae:	80668693          	addi	a3,a3,-2042 # ffffffffc0206ab0 <default_pmm_manager+0x648>
ffffffffc02032b2:	00003617          	auipc	a2,0x3
ffffffffc02032b6:	e0660613          	addi	a2,a2,-506 # ffffffffc02060b8 <commands+0x818>
ffffffffc02032ba:	25700593          	li	a1,599
ffffffffc02032be:	00003517          	auipc	a0,0x3
ffffffffc02032c2:	2fa50513          	addi	a0,a0,762 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc02032c6:	9c8fd0ef          	jal	ra,ffffffffc020048e <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc02032ca:	00003617          	auipc	a2,0x3
ffffffffc02032ce:	27e60613          	addi	a2,a2,638 # ffffffffc0206548 <default_pmm_manager+0xe0>
ffffffffc02032d2:	0c900593          	li	a1,201
ffffffffc02032d6:	00003517          	auipc	a0,0x3
ffffffffc02032da:	2e250513          	addi	a0,a0,738 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc02032de:	9b0fd0ef          	jal	ra,ffffffffc020048e <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02032e2:	00003617          	auipc	a2,0x3
ffffffffc02032e6:	26660613          	addi	a2,a2,614 # ffffffffc0206548 <default_pmm_manager+0xe0>
ffffffffc02032ea:	08100593          	li	a1,129
ffffffffc02032ee:	00003517          	auipc	a0,0x3
ffffffffc02032f2:	2ca50513          	addi	a0,a0,714 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc02032f6:	998fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc02032fa:	00003697          	auipc	a3,0x3
ffffffffc02032fe:	48668693          	addi	a3,a3,1158 # ffffffffc0206780 <default_pmm_manager+0x318>
ffffffffc0203302:	00003617          	auipc	a2,0x3
ffffffffc0203306:	db660613          	addi	a2,a2,-586 # ffffffffc02060b8 <commands+0x818>
ffffffffc020330a:	21700593          	li	a1,535
ffffffffc020330e:	00003517          	auipc	a0,0x3
ffffffffc0203312:	2aa50513          	addi	a0,a0,682 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc0203316:	978fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc020331a:	00003697          	auipc	a3,0x3
ffffffffc020331e:	43668693          	addi	a3,a3,1078 # ffffffffc0206750 <default_pmm_manager+0x2e8>
ffffffffc0203322:	00003617          	auipc	a2,0x3
ffffffffc0203326:	d9660613          	addi	a2,a2,-618 # ffffffffc02060b8 <commands+0x818>
ffffffffc020332a:	21400593          	li	a1,532
ffffffffc020332e:	00003517          	auipc	a0,0x3
ffffffffc0203332:	28a50513          	addi	a0,a0,650 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc0203336:	958fd0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020333a <copy_range>:
{
ffffffffc020333a:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020333c:	00d667b3          	or	a5,a2,a3
{
ffffffffc0203340:	f486                	sd	ra,104(sp)
ffffffffc0203342:	f0a2                	sd	s0,96(sp)
ffffffffc0203344:	eca6                	sd	s1,88(sp)
ffffffffc0203346:	e8ca                	sd	s2,80(sp)
ffffffffc0203348:	e4ce                	sd	s3,72(sp)
ffffffffc020334a:	e0d2                	sd	s4,64(sp)
ffffffffc020334c:	fc56                	sd	s5,56(sp)
ffffffffc020334e:	f85a                	sd	s6,48(sp)
ffffffffc0203350:	f45e                	sd	s7,40(sp)
ffffffffc0203352:	f062                	sd	s8,32(sp)
ffffffffc0203354:	ec66                	sd	s9,24(sp)
ffffffffc0203356:	e86a                	sd	s10,16(sp)
ffffffffc0203358:	e46e                	sd	s11,8(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020335a:	17d2                	slli	a5,a5,0x34
ffffffffc020335c:	1e079e63          	bnez	a5,ffffffffc0203558 <copy_range+0x21e>
    assert(USER_ACCESS(start, end));
ffffffffc0203360:	002007b7          	lui	a5,0x200
ffffffffc0203364:	8432                	mv	s0,a2
ffffffffc0203366:	1af66963          	bltu	a2,a5,ffffffffc0203518 <copy_range+0x1de>
ffffffffc020336a:	8936                	mv	s2,a3
ffffffffc020336c:	1ad67663          	bgeu	a2,a3,ffffffffc0203518 <copy_range+0x1de>
ffffffffc0203370:	4785                	li	a5,1
ffffffffc0203372:	07fe                	slli	a5,a5,0x1f
ffffffffc0203374:	1ad7e263          	bltu	a5,a3,ffffffffc0203518 <copy_range+0x1de>
ffffffffc0203378:	5b7d                	li	s6,-1
ffffffffc020337a:	8aaa                	mv	s5,a0
ffffffffc020337c:	89ae                	mv	s3,a1
        start += PGSIZE;
ffffffffc020337e:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc0203380:	000a7c17          	auipc	s8,0xa7
ffffffffc0203384:	350c0c13          	addi	s8,s8,848 # ffffffffc02aa6d0 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0203388:	000a7b97          	auipc	s7,0xa7
ffffffffc020338c:	350b8b93          	addi	s7,s7,848 # ffffffffc02aa6d8 <pages>
    return KADDR(page2pa(page));
ffffffffc0203390:	00cb5b13          	srli	s6,s6,0xc
        page = pmm_manager->alloc_pages(n);
ffffffffc0203394:	000a7c97          	auipc	s9,0xa7
ffffffffc0203398:	34cc8c93          	addi	s9,s9,844 # ffffffffc02aa6e0 <pmm_manager>
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc020339c:	4601                	li	a2,0
ffffffffc020339e:	85a2                	mv	a1,s0
ffffffffc02033a0:	854e                	mv	a0,s3
ffffffffc02033a2:	b73fe0ef          	jal	ra,ffffffffc0201f14 <get_pte>
ffffffffc02033a6:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc02033a8:	cd61                	beqz	a0,ffffffffc0203480 <copy_range+0x146>
        if (*ptep & PTE_V)
ffffffffc02033aa:	611c                	ld	a5,0(a0)
ffffffffc02033ac:	8b85                	andi	a5,a5,1
ffffffffc02033ae:	e785                	bnez	a5,ffffffffc02033d6 <copy_range+0x9c>
        start += PGSIZE;
ffffffffc02033b0:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc02033b2:	ff2465e3          	bltu	s0,s2,ffffffffc020339c <copy_range+0x62>
    return 0;
ffffffffc02033b6:	4501                	li	a0,0
}
ffffffffc02033b8:	70a6                	ld	ra,104(sp)
ffffffffc02033ba:	7406                	ld	s0,96(sp)
ffffffffc02033bc:	64e6                	ld	s1,88(sp)
ffffffffc02033be:	6946                	ld	s2,80(sp)
ffffffffc02033c0:	69a6                	ld	s3,72(sp)
ffffffffc02033c2:	6a06                	ld	s4,64(sp)
ffffffffc02033c4:	7ae2                	ld	s5,56(sp)
ffffffffc02033c6:	7b42                	ld	s6,48(sp)
ffffffffc02033c8:	7ba2                	ld	s7,40(sp)
ffffffffc02033ca:	7c02                	ld	s8,32(sp)
ffffffffc02033cc:	6ce2                	ld	s9,24(sp)
ffffffffc02033ce:	6d42                	ld	s10,16(sp)
ffffffffc02033d0:	6da2                	ld	s11,8(sp)
ffffffffc02033d2:	6165                	addi	sp,sp,112
ffffffffc02033d4:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL)
ffffffffc02033d6:	4605                	li	a2,1
ffffffffc02033d8:	85a2                	mv	a1,s0
ffffffffc02033da:	8556                	mv	a0,s5
ffffffffc02033dc:	b39fe0ef          	jal	ra,ffffffffc0201f14 <get_pte>
ffffffffc02033e0:	c569                	beqz	a0,ffffffffc02034aa <copy_range+0x170>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc02033e2:	609c                	ld	a5,0(s1)
    if (!(pte & PTE_V))
ffffffffc02033e4:	0017f713          	andi	a4,a5,1
ffffffffc02033e8:	01f7f493          	andi	s1,a5,31
ffffffffc02033ec:	10070a63          	beqz	a4,ffffffffc0203500 <copy_range+0x1c6>
    if (PPN(pa) >= npage)
ffffffffc02033f0:	000c3683          	ld	a3,0(s8)
    return pa2page(PTE_ADDR(pte));
ffffffffc02033f4:	078a                	slli	a5,a5,0x2
ffffffffc02033f6:	00c7d713          	srli	a4,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02033fa:	0ed77763          	bgeu	a4,a3,ffffffffc02034e8 <copy_range+0x1ae>
    return &pages[PPN(pa) - nbase];
ffffffffc02033fe:	000bb783          	ld	a5,0(s7)
ffffffffc0203402:	fff806b7          	lui	a3,0xfff80
ffffffffc0203406:	9736                	add	a4,a4,a3
ffffffffc0203408:	071a                	slli	a4,a4,0x6
ffffffffc020340a:	00e78db3          	add	s11,a5,a4
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020340e:	10002773          	csrr	a4,sstatus
ffffffffc0203412:	8b09                	andi	a4,a4,2
ffffffffc0203414:	e341                	bnez	a4,ffffffffc0203494 <copy_range+0x15a>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203416:	000cb703          	ld	a4,0(s9)
ffffffffc020341a:	4505                	li	a0,1
ffffffffc020341c:	6f18                	ld	a4,24(a4)
ffffffffc020341e:	9702                	jalr	a4
ffffffffc0203420:	8d2a                	mv	s10,a0
            assert(page != NULL);
ffffffffc0203422:	0a0d8363          	beqz	s11,ffffffffc02034c8 <copy_range+0x18e>
            assert(npage != NULL);
ffffffffc0203426:	100d0963          	beqz	s10,ffffffffc0203538 <copy_range+0x1fe>
    return page - pages + nbase;
ffffffffc020342a:	000bb703          	ld	a4,0(s7)
ffffffffc020342e:	000805b7          	lui	a1,0x80
    return KADDR(page2pa(page));
ffffffffc0203432:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc0203436:	40ed86b3          	sub	a3,s11,a4
ffffffffc020343a:	8699                	srai	a3,a3,0x6
ffffffffc020343c:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc020343e:	0166f7b3          	and	a5,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc0203442:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203444:	06c7f663          	bgeu	a5,a2,ffffffffc02034b0 <copy_range+0x176>
    return page - pages + nbase;
ffffffffc0203448:	40ed07b3          	sub	a5,s10,a4
    return KADDR(page2pa(page));
ffffffffc020344c:	000a7717          	auipc	a4,0xa7
ffffffffc0203450:	29c70713          	addi	a4,a4,668 # ffffffffc02aa6e8 <va_pa_offset>
ffffffffc0203454:	6308                	ld	a0,0(a4)
    return page - pages + nbase;
ffffffffc0203456:	8799                	srai	a5,a5,0x6
ffffffffc0203458:	97ae                	add	a5,a5,a1
    return KADDR(page2pa(page));
ffffffffc020345a:	0167f733          	and	a4,a5,s6
ffffffffc020345e:	00a685b3          	add	a1,a3,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0203462:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0203464:	04c77563          	bgeu	a4,a2,ffffffffc02034ae <copy_range+0x174>
            memcpy(dst_kvaddr, src_kvaddr, PGSIZE); // Copy the content of the source page to the destination page.
ffffffffc0203468:	6605                	lui	a2,0x1
ffffffffc020346a:	953e                	add	a0,a0,a5
ffffffffc020346c:	1b0020ef          	jal	ra,ffffffffc020561c <memcpy>
            ret = page_insert(to, npage, start, perm); // Insert the destination page into the page table of the target process.
ffffffffc0203470:	8622                	mv	a2,s0
ffffffffc0203472:	86a6                	mv	a3,s1
ffffffffc0203474:	85ea                	mv	a1,s10
ffffffffc0203476:	8556                	mv	a0,s5
ffffffffc0203478:	98cff0ef          	jal	ra,ffffffffc0202604 <page_insert>
        start += PGSIZE;
ffffffffc020347c:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc020347e:	bf15                	j	ffffffffc02033b2 <copy_range+0x78>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0203480:	00200637          	lui	a2,0x200
ffffffffc0203484:	9432                	add	s0,s0,a2
ffffffffc0203486:	ffe00637          	lui	a2,0xffe00
ffffffffc020348a:	8c71                	and	s0,s0,a2
    } while (start != 0 && start < end);
ffffffffc020348c:	d40d                	beqz	s0,ffffffffc02033b6 <copy_range+0x7c>
ffffffffc020348e:	f12467e3          	bltu	s0,s2,ffffffffc020339c <copy_range+0x62>
ffffffffc0203492:	b715                	j	ffffffffc02033b6 <copy_range+0x7c>
        intr_disable();
ffffffffc0203494:	d20fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203498:	000cb703          	ld	a4,0(s9)
ffffffffc020349c:	4505                	li	a0,1
ffffffffc020349e:	6f18                	ld	a4,24(a4)
ffffffffc02034a0:	9702                	jalr	a4
ffffffffc02034a2:	8d2a                	mv	s10,a0
        intr_enable();
ffffffffc02034a4:	d0afd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02034a8:	bfad                	j	ffffffffc0203422 <copy_range+0xe8>
                return -E_NO_MEM;
ffffffffc02034aa:	5571                	li	a0,-4
ffffffffc02034ac:	b731                	j	ffffffffc02033b8 <copy_range+0x7e>
ffffffffc02034ae:	86be                	mv	a3,a5
ffffffffc02034b0:	00003617          	auipc	a2,0x3
ffffffffc02034b4:	ff060613          	addi	a2,a2,-16 # ffffffffc02064a0 <default_pmm_manager+0x38>
ffffffffc02034b8:	07100593          	li	a1,113
ffffffffc02034bc:	00003517          	auipc	a0,0x3
ffffffffc02034c0:	00c50513          	addi	a0,a0,12 # ffffffffc02064c8 <default_pmm_manager+0x60>
ffffffffc02034c4:	fcbfc0ef          	jal	ra,ffffffffc020048e <__panic>
            assert(page != NULL);
ffffffffc02034c8:	00003697          	auipc	a3,0x3
ffffffffc02034cc:	6e068693          	addi	a3,a3,1760 # ffffffffc0206ba8 <default_pmm_manager+0x740>
ffffffffc02034d0:	00003617          	auipc	a2,0x3
ffffffffc02034d4:	be860613          	addi	a2,a2,-1048 # ffffffffc02060b8 <commands+0x818>
ffffffffc02034d8:	19400593          	li	a1,404
ffffffffc02034dc:	00003517          	auipc	a0,0x3
ffffffffc02034e0:	0dc50513          	addi	a0,a0,220 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc02034e4:	fabfc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02034e8:	00003617          	auipc	a2,0x3
ffffffffc02034ec:	08860613          	addi	a2,a2,136 # ffffffffc0206570 <default_pmm_manager+0x108>
ffffffffc02034f0:	06900593          	li	a1,105
ffffffffc02034f4:	00003517          	auipc	a0,0x3
ffffffffc02034f8:	fd450513          	addi	a0,a0,-44 # ffffffffc02064c8 <default_pmm_manager+0x60>
ffffffffc02034fc:	f93fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0203500:	00003617          	auipc	a2,0x3
ffffffffc0203504:	09060613          	addi	a2,a2,144 # ffffffffc0206590 <default_pmm_manager+0x128>
ffffffffc0203508:	07f00593          	li	a1,127
ffffffffc020350c:	00003517          	auipc	a0,0x3
ffffffffc0203510:	fbc50513          	addi	a0,a0,-68 # ffffffffc02064c8 <default_pmm_manager+0x60>
ffffffffc0203514:	f7bfc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0203518:	00003697          	auipc	a3,0x3
ffffffffc020351c:	0e068693          	addi	a3,a3,224 # ffffffffc02065f8 <default_pmm_manager+0x190>
ffffffffc0203520:	00003617          	auipc	a2,0x3
ffffffffc0203524:	b9860613          	addi	a2,a2,-1128 # ffffffffc02060b8 <commands+0x818>
ffffffffc0203528:	17c00593          	li	a1,380
ffffffffc020352c:	00003517          	auipc	a0,0x3
ffffffffc0203530:	08c50513          	addi	a0,a0,140 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc0203534:	f5bfc0ef          	jal	ra,ffffffffc020048e <__panic>
            assert(npage != NULL);
ffffffffc0203538:	00003697          	auipc	a3,0x3
ffffffffc020353c:	68068693          	addi	a3,a3,1664 # ffffffffc0206bb8 <default_pmm_manager+0x750>
ffffffffc0203540:	00003617          	auipc	a2,0x3
ffffffffc0203544:	b7860613          	addi	a2,a2,-1160 # ffffffffc02060b8 <commands+0x818>
ffffffffc0203548:	19500593          	li	a1,405
ffffffffc020354c:	00003517          	auipc	a0,0x3
ffffffffc0203550:	06c50513          	addi	a0,a0,108 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc0203554:	f3bfc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203558:	00003697          	auipc	a3,0x3
ffffffffc020355c:	07068693          	addi	a3,a3,112 # ffffffffc02065c8 <default_pmm_manager+0x160>
ffffffffc0203560:	00003617          	auipc	a2,0x3
ffffffffc0203564:	b5860613          	addi	a2,a2,-1192 # ffffffffc02060b8 <commands+0x818>
ffffffffc0203568:	17b00593          	li	a1,379
ffffffffc020356c:	00003517          	auipc	a0,0x3
ffffffffc0203570:	04c50513          	addi	a0,a0,76 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc0203574:	f1bfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203578 <pgdir_alloc_page>:
{
ffffffffc0203578:	7179                	addi	sp,sp,-48
ffffffffc020357a:	ec26                	sd	s1,24(sp)
ffffffffc020357c:	e84a                	sd	s2,16(sp)
ffffffffc020357e:	e052                	sd	s4,0(sp)
ffffffffc0203580:	f406                	sd	ra,40(sp)
ffffffffc0203582:	f022                	sd	s0,32(sp)
ffffffffc0203584:	e44e                	sd	s3,8(sp)
ffffffffc0203586:	8a2a                	mv	s4,a0
ffffffffc0203588:	84ae                	mv	s1,a1
ffffffffc020358a:	8932                	mv	s2,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020358c:	100027f3          	csrr	a5,sstatus
ffffffffc0203590:	8b89                	andi	a5,a5,2
        page = pmm_manager->alloc_pages(n);
ffffffffc0203592:	000a7997          	auipc	s3,0xa7
ffffffffc0203596:	14e98993          	addi	s3,s3,334 # ffffffffc02aa6e0 <pmm_manager>
ffffffffc020359a:	ef8d                	bnez	a5,ffffffffc02035d4 <pgdir_alloc_page+0x5c>
ffffffffc020359c:	0009b783          	ld	a5,0(s3)
ffffffffc02035a0:	4505                	li	a0,1
ffffffffc02035a2:	6f9c                	ld	a5,24(a5)
ffffffffc02035a4:	9782                	jalr	a5
ffffffffc02035a6:	842a                	mv	s0,a0
    if (page != NULL)
ffffffffc02035a8:	cc09                	beqz	s0,ffffffffc02035c2 <pgdir_alloc_page+0x4a>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc02035aa:	86ca                	mv	a3,s2
ffffffffc02035ac:	8626                	mv	a2,s1
ffffffffc02035ae:	85a2                	mv	a1,s0
ffffffffc02035b0:	8552                	mv	a0,s4
ffffffffc02035b2:	852ff0ef          	jal	ra,ffffffffc0202604 <page_insert>
ffffffffc02035b6:	e915                	bnez	a0,ffffffffc02035ea <pgdir_alloc_page+0x72>
        assert(page_ref(page) == 1);
ffffffffc02035b8:	4018                	lw	a4,0(s0)
        page->pra_vaddr = la;
ffffffffc02035ba:	fc04                	sd	s1,56(s0)
        assert(page_ref(page) == 1);
ffffffffc02035bc:	4785                	li	a5,1
ffffffffc02035be:	04f71e63          	bne	a4,a5,ffffffffc020361a <pgdir_alloc_page+0xa2>
}
ffffffffc02035c2:	70a2                	ld	ra,40(sp)
ffffffffc02035c4:	8522                	mv	a0,s0
ffffffffc02035c6:	7402                	ld	s0,32(sp)
ffffffffc02035c8:	64e2                	ld	s1,24(sp)
ffffffffc02035ca:	6942                	ld	s2,16(sp)
ffffffffc02035cc:	69a2                	ld	s3,8(sp)
ffffffffc02035ce:	6a02                	ld	s4,0(sp)
ffffffffc02035d0:	6145                	addi	sp,sp,48
ffffffffc02035d2:	8082                	ret
        intr_disable();
ffffffffc02035d4:	be0fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02035d8:	0009b783          	ld	a5,0(s3)
ffffffffc02035dc:	4505                	li	a0,1
ffffffffc02035de:	6f9c                	ld	a5,24(a5)
ffffffffc02035e0:	9782                	jalr	a5
ffffffffc02035e2:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02035e4:	bcafd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02035e8:	b7c1                	j	ffffffffc02035a8 <pgdir_alloc_page+0x30>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02035ea:	100027f3          	csrr	a5,sstatus
ffffffffc02035ee:	8b89                	andi	a5,a5,2
ffffffffc02035f0:	eb89                	bnez	a5,ffffffffc0203602 <pgdir_alloc_page+0x8a>
        pmm_manager->free_pages(base, n);
ffffffffc02035f2:	0009b783          	ld	a5,0(s3)
ffffffffc02035f6:	8522                	mv	a0,s0
ffffffffc02035f8:	4585                	li	a1,1
ffffffffc02035fa:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc02035fc:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc02035fe:	9782                	jalr	a5
    if (flag)
ffffffffc0203600:	b7c9                	j	ffffffffc02035c2 <pgdir_alloc_page+0x4a>
        intr_disable();
ffffffffc0203602:	bb2fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0203606:	0009b783          	ld	a5,0(s3)
ffffffffc020360a:	8522                	mv	a0,s0
ffffffffc020360c:	4585                	li	a1,1
ffffffffc020360e:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc0203610:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc0203612:	9782                	jalr	a5
        intr_enable();
ffffffffc0203614:	b9afd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203618:	b76d                	j	ffffffffc02035c2 <pgdir_alloc_page+0x4a>
        assert(page_ref(page) == 1);
ffffffffc020361a:	00003697          	auipc	a3,0x3
ffffffffc020361e:	5ae68693          	addi	a3,a3,1454 # ffffffffc0206bc8 <default_pmm_manager+0x760>
ffffffffc0203622:	00003617          	auipc	a2,0x3
ffffffffc0203626:	a9660613          	addi	a2,a2,-1386 # ffffffffc02060b8 <commands+0x818>
ffffffffc020362a:	1f500593          	li	a1,501
ffffffffc020362e:	00003517          	auipc	a0,0x3
ffffffffc0203632:	f8a50513          	addi	a0,a0,-118 # ffffffffc02065b8 <default_pmm_manager+0x150>
ffffffffc0203636:	e59fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020363a <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc020363a:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc020363c:	00003697          	auipc	a3,0x3
ffffffffc0203640:	5a468693          	addi	a3,a3,1444 # ffffffffc0206be0 <default_pmm_manager+0x778>
ffffffffc0203644:	00003617          	auipc	a2,0x3
ffffffffc0203648:	a7460613          	addi	a2,a2,-1420 # ffffffffc02060b8 <commands+0x818>
ffffffffc020364c:	07400593          	li	a1,116
ffffffffc0203650:	00003517          	auipc	a0,0x3
ffffffffc0203654:	5b050513          	addi	a0,a0,1456 # ffffffffc0206c00 <default_pmm_manager+0x798>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0203658:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc020365a:	e35fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020365e <mm_create>:
{
ffffffffc020365e:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203660:	04000513          	li	a0,64
{
ffffffffc0203664:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203666:	e18fe0ef          	jal	ra,ffffffffc0201c7e <kmalloc>
    if (mm != NULL)
ffffffffc020366a:	cd19                	beqz	a0,ffffffffc0203688 <mm_create+0x2a>
    elm->prev = elm->next = elm;
ffffffffc020366c:	e508                	sd	a0,8(a0)
ffffffffc020366e:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203670:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203674:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203678:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc020367c:	02053423          	sd	zero,40(a0)
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
ffffffffc0203680:	02052823          	sw	zero,48(a0)
typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock)
{
    *lock = 0;
ffffffffc0203684:	02053c23          	sd	zero,56(a0)
}
ffffffffc0203688:	60a2                	ld	ra,8(sp)
ffffffffc020368a:	0141                	addi	sp,sp,16
ffffffffc020368c:	8082                	ret

ffffffffc020368e <find_vma>:
{
ffffffffc020368e:	86aa                	mv	a3,a0
    if (mm != NULL)
ffffffffc0203690:	c505                	beqz	a0,ffffffffc02036b8 <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc0203692:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0203694:	c501                	beqz	a0,ffffffffc020369c <find_vma+0xe>
ffffffffc0203696:	651c                	ld	a5,8(a0)
ffffffffc0203698:	02f5f263          	bgeu	a1,a5,ffffffffc02036bc <find_vma+0x2e>
    return listelm->next;
ffffffffc020369c:	669c                	ld	a5,8(a3)
            while ((le = list_next(le)) != list)
ffffffffc020369e:	00f68d63          	beq	a3,a5,ffffffffc02036b8 <find_vma+0x2a>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc02036a2:	fe87b703          	ld	a4,-24(a5) # 1fffe8 <_binary_obj___user_exit_out_size+0x1f4ec8>
ffffffffc02036a6:	00e5e663          	bltu	a1,a4,ffffffffc02036b2 <find_vma+0x24>
ffffffffc02036aa:	ff07b703          	ld	a4,-16(a5)
ffffffffc02036ae:	00e5ec63          	bltu	a1,a4,ffffffffc02036c6 <find_vma+0x38>
ffffffffc02036b2:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc02036b4:	fef697e3          	bne	a3,a5,ffffffffc02036a2 <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc02036b8:	4501                	li	a0,0
}
ffffffffc02036ba:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc02036bc:	691c                	ld	a5,16(a0)
ffffffffc02036be:	fcf5ffe3          	bgeu	a1,a5,ffffffffc020369c <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc02036c2:	ea88                	sd	a0,16(a3)
ffffffffc02036c4:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc02036c6:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc02036ca:	ea88                	sd	a0,16(a3)
ffffffffc02036cc:	8082                	ret

ffffffffc02036ce <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc02036ce:	6590                	ld	a2,8(a1)
ffffffffc02036d0:	0105b803          	ld	a6,16(a1) # 80010 <_binary_obj___user_exit_out_size+0x74ef0>
{
ffffffffc02036d4:	1141                	addi	sp,sp,-16
ffffffffc02036d6:	e406                	sd	ra,8(sp)
ffffffffc02036d8:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc02036da:	01066763          	bltu	a2,a6,ffffffffc02036e8 <insert_vma_struct+0x1a>
ffffffffc02036de:	a085                	j	ffffffffc020373e <insert_vma_struct+0x70>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc02036e0:	fe87b703          	ld	a4,-24(a5)
ffffffffc02036e4:	04e66863          	bltu	a2,a4,ffffffffc0203734 <insert_vma_struct+0x66>
ffffffffc02036e8:	86be                	mv	a3,a5
ffffffffc02036ea:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc02036ec:	fef51ae3          	bne	a0,a5,ffffffffc02036e0 <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc02036f0:	02a68463          	beq	a3,a0,ffffffffc0203718 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc02036f4:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc02036f8:	fe86b883          	ld	a7,-24(a3)
ffffffffc02036fc:	08e8f163          	bgeu	a7,a4,ffffffffc020377e <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203700:	04e66f63          	bltu	a2,a4,ffffffffc020375e <insert_vma_struct+0x90>
    }
    if (le_next != list)
ffffffffc0203704:	00f50a63          	beq	a0,a5,ffffffffc0203718 <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0203708:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc020370c:	05076963          	bltu	a4,a6,ffffffffc020375e <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc0203710:	ff07b603          	ld	a2,-16(a5)
ffffffffc0203714:	02c77363          	bgeu	a4,a2,ffffffffc020373a <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0203718:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc020371a:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc020371c:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0203720:	e390                	sd	a2,0(a5)
ffffffffc0203722:	e690                	sd	a2,8(a3)
}
ffffffffc0203724:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0203726:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0203728:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc020372a:	0017079b          	addiw	a5,a4,1
ffffffffc020372e:	d11c                	sw	a5,32(a0)
}
ffffffffc0203730:	0141                	addi	sp,sp,16
ffffffffc0203732:	8082                	ret
    if (le_prev != list)
ffffffffc0203734:	fca690e3          	bne	a3,a0,ffffffffc02036f4 <insert_vma_struct+0x26>
ffffffffc0203738:	bfd1                	j	ffffffffc020370c <insert_vma_struct+0x3e>
ffffffffc020373a:	f01ff0ef          	jal	ra,ffffffffc020363a <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc020373e:	00003697          	auipc	a3,0x3
ffffffffc0203742:	4d268693          	addi	a3,a3,1234 # ffffffffc0206c10 <default_pmm_manager+0x7a8>
ffffffffc0203746:	00003617          	auipc	a2,0x3
ffffffffc020374a:	97260613          	addi	a2,a2,-1678 # ffffffffc02060b8 <commands+0x818>
ffffffffc020374e:	07a00593          	li	a1,122
ffffffffc0203752:	00003517          	auipc	a0,0x3
ffffffffc0203756:	4ae50513          	addi	a0,a0,1198 # ffffffffc0206c00 <default_pmm_manager+0x798>
ffffffffc020375a:	d35fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc020375e:	00003697          	auipc	a3,0x3
ffffffffc0203762:	4f268693          	addi	a3,a3,1266 # ffffffffc0206c50 <default_pmm_manager+0x7e8>
ffffffffc0203766:	00003617          	auipc	a2,0x3
ffffffffc020376a:	95260613          	addi	a2,a2,-1710 # ffffffffc02060b8 <commands+0x818>
ffffffffc020376e:	07300593          	li	a1,115
ffffffffc0203772:	00003517          	auipc	a0,0x3
ffffffffc0203776:	48e50513          	addi	a0,a0,1166 # ffffffffc0206c00 <default_pmm_manager+0x798>
ffffffffc020377a:	d15fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc020377e:	00003697          	auipc	a3,0x3
ffffffffc0203782:	4b268693          	addi	a3,a3,1202 # ffffffffc0206c30 <default_pmm_manager+0x7c8>
ffffffffc0203786:	00003617          	auipc	a2,0x3
ffffffffc020378a:	93260613          	addi	a2,a2,-1742 # ffffffffc02060b8 <commands+0x818>
ffffffffc020378e:	07200593          	li	a1,114
ffffffffc0203792:	00003517          	auipc	a0,0x3
ffffffffc0203796:	46e50513          	addi	a0,a0,1134 # ffffffffc0206c00 <default_pmm_manager+0x798>
ffffffffc020379a:	cf5fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020379e <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc020379e:	591c                	lw	a5,48(a0)
{
ffffffffc02037a0:	1141                	addi	sp,sp,-16
ffffffffc02037a2:	e406                	sd	ra,8(sp)
ffffffffc02037a4:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc02037a6:	e78d                	bnez	a5,ffffffffc02037d0 <mm_destroy+0x32>
ffffffffc02037a8:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc02037aa:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc02037ac:	00a40c63          	beq	s0,a0,ffffffffc02037c4 <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc02037b0:	6118                	ld	a4,0(a0)
ffffffffc02037b2:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc02037b4:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc02037b6:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02037b8:	e398                	sd	a4,0(a5)
ffffffffc02037ba:	d74fe0ef          	jal	ra,ffffffffc0201d2e <kfree>
    return listelm->next;
ffffffffc02037be:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc02037c0:	fea418e3          	bne	s0,a0,ffffffffc02037b0 <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc02037c4:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc02037c6:	6402                	ld	s0,0(sp)
ffffffffc02037c8:	60a2                	ld	ra,8(sp)
ffffffffc02037ca:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc02037cc:	d62fe06f          	j	ffffffffc0201d2e <kfree>
    assert(mm_count(mm) == 0);
ffffffffc02037d0:	00003697          	auipc	a3,0x3
ffffffffc02037d4:	4a068693          	addi	a3,a3,1184 # ffffffffc0206c70 <default_pmm_manager+0x808>
ffffffffc02037d8:	00003617          	auipc	a2,0x3
ffffffffc02037dc:	8e060613          	addi	a2,a2,-1824 # ffffffffc02060b8 <commands+0x818>
ffffffffc02037e0:	09e00593          	li	a1,158
ffffffffc02037e4:	00003517          	auipc	a0,0x3
ffffffffc02037e8:	41c50513          	addi	a0,a0,1052 # ffffffffc0206c00 <default_pmm_manager+0x798>
ffffffffc02037ec:	ca3fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02037f0 <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
ffffffffc02037f0:	7139                	addi	sp,sp,-64
ffffffffc02037f2:	f822                	sd	s0,48(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc02037f4:	6405                	lui	s0,0x1
ffffffffc02037f6:	147d                	addi	s0,s0,-1
ffffffffc02037f8:	77fd                	lui	a5,0xfffff
ffffffffc02037fa:	9622                	add	a2,a2,s0
ffffffffc02037fc:	962e                	add	a2,a2,a1
{
ffffffffc02037fe:	f426                	sd	s1,40(sp)
ffffffffc0203800:	fc06                	sd	ra,56(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203802:	00f5f4b3          	and	s1,a1,a5
{
ffffffffc0203806:	f04a                	sd	s2,32(sp)
ffffffffc0203808:	ec4e                	sd	s3,24(sp)
ffffffffc020380a:	e852                	sd	s4,16(sp)
ffffffffc020380c:	e456                	sd	s5,8(sp)
    if (!USER_ACCESS(start, end))
ffffffffc020380e:	002005b7          	lui	a1,0x200
ffffffffc0203812:	00f67433          	and	s0,a2,a5
ffffffffc0203816:	06b4e363          	bltu	s1,a1,ffffffffc020387c <mm_map+0x8c>
ffffffffc020381a:	0684f163          	bgeu	s1,s0,ffffffffc020387c <mm_map+0x8c>
ffffffffc020381e:	4785                	li	a5,1
ffffffffc0203820:	07fe                	slli	a5,a5,0x1f
ffffffffc0203822:	0487ed63          	bltu	a5,s0,ffffffffc020387c <mm_map+0x8c>
ffffffffc0203826:	89aa                	mv	s3,a0
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc0203828:	cd21                	beqz	a0,ffffffffc0203880 <mm_map+0x90>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc020382a:	85a6                	mv	a1,s1
ffffffffc020382c:	8ab6                	mv	s5,a3
ffffffffc020382e:	8a3a                	mv	s4,a4
ffffffffc0203830:	e5fff0ef          	jal	ra,ffffffffc020368e <find_vma>
ffffffffc0203834:	c501                	beqz	a0,ffffffffc020383c <mm_map+0x4c>
ffffffffc0203836:	651c                	ld	a5,8(a0)
ffffffffc0203838:	0487e263          	bltu	a5,s0,ffffffffc020387c <mm_map+0x8c>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020383c:	03000513          	li	a0,48
ffffffffc0203840:	c3efe0ef          	jal	ra,ffffffffc0201c7e <kmalloc>
ffffffffc0203844:	892a                	mv	s2,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc0203846:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc0203848:	02090163          	beqz	s2,ffffffffc020386a <mm_map+0x7a>

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc020384c:	854e                	mv	a0,s3
        vma->vm_start = vm_start;
ffffffffc020384e:	00993423          	sd	s1,8(s2)
        vma->vm_end = vm_end;
ffffffffc0203852:	00893823          	sd	s0,16(s2)
        vma->vm_flags = vm_flags;
ffffffffc0203856:	01592c23          	sw	s5,24(s2)
    insert_vma_struct(mm, vma);
ffffffffc020385a:	85ca                	mv	a1,s2
ffffffffc020385c:	e73ff0ef          	jal	ra,ffffffffc02036ce <insert_vma_struct>
    if (vma_store != NULL)
    {
        *vma_store = vma;
    }
    ret = 0;
ffffffffc0203860:	4501                	li	a0,0
    if (vma_store != NULL)
ffffffffc0203862:	000a0463          	beqz	s4,ffffffffc020386a <mm_map+0x7a>
        *vma_store = vma;
ffffffffc0203866:	012a3023          	sd	s2,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8ba8>

out:
    return ret;
}
ffffffffc020386a:	70e2                	ld	ra,56(sp)
ffffffffc020386c:	7442                	ld	s0,48(sp)
ffffffffc020386e:	74a2                	ld	s1,40(sp)
ffffffffc0203870:	7902                	ld	s2,32(sp)
ffffffffc0203872:	69e2                	ld	s3,24(sp)
ffffffffc0203874:	6a42                	ld	s4,16(sp)
ffffffffc0203876:	6aa2                	ld	s5,8(sp)
ffffffffc0203878:	6121                	addi	sp,sp,64
ffffffffc020387a:	8082                	ret
        return -E_INVAL;
ffffffffc020387c:	5575                	li	a0,-3
ffffffffc020387e:	b7f5                	j	ffffffffc020386a <mm_map+0x7a>
    assert(mm != NULL);
ffffffffc0203880:	00003697          	auipc	a3,0x3
ffffffffc0203884:	40868693          	addi	a3,a3,1032 # ffffffffc0206c88 <default_pmm_manager+0x820>
ffffffffc0203888:	00003617          	auipc	a2,0x3
ffffffffc020388c:	83060613          	addi	a2,a2,-2000 # ffffffffc02060b8 <commands+0x818>
ffffffffc0203890:	0b300593          	li	a1,179
ffffffffc0203894:	00003517          	auipc	a0,0x3
ffffffffc0203898:	36c50513          	addi	a0,a0,876 # ffffffffc0206c00 <default_pmm_manager+0x798>
ffffffffc020389c:	bf3fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02038a0 <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc02038a0:	7139                	addi	sp,sp,-64
ffffffffc02038a2:	fc06                	sd	ra,56(sp)
ffffffffc02038a4:	f822                	sd	s0,48(sp)
ffffffffc02038a6:	f426                	sd	s1,40(sp)
ffffffffc02038a8:	f04a                	sd	s2,32(sp)
ffffffffc02038aa:	ec4e                	sd	s3,24(sp)
ffffffffc02038ac:	e852                	sd	s4,16(sp)
ffffffffc02038ae:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc02038b0:	c52d                	beqz	a0,ffffffffc020391a <dup_mmap+0x7a>
ffffffffc02038b2:	892a                	mv	s2,a0
ffffffffc02038b4:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc02038b6:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc02038b8:	e595                	bnez	a1,ffffffffc02038e4 <dup_mmap+0x44>
ffffffffc02038ba:	a085                	j	ffffffffc020391a <dup_mmap+0x7a>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc02038bc:	854a                	mv	a0,s2
        vma->vm_start = vm_start;
ffffffffc02038be:	0155b423          	sd	s5,8(a1) # 200008 <_binary_obj___user_exit_out_size+0x1f4ee8>
        vma->vm_end = vm_end;
ffffffffc02038c2:	0145b823          	sd	s4,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc02038c6:	0135ac23          	sw	s3,24(a1)
        insert_vma_struct(to, nvma);
ffffffffc02038ca:	e05ff0ef          	jal	ra,ffffffffc02036ce <insert_vma_struct>

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc02038ce:	ff043683          	ld	a3,-16(s0) # ff0 <_binary_obj___user_faultread_out_size-0x8bb8>
ffffffffc02038d2:	fe843603          	ld	a2,-24(s0)
ffffffffc02038d6:	6c8c                	ld	a1,24(s1)
ffffffffc02038d8:	01893503          	ld	a0,24(s2)
ffffffffc02038dc:	4701                	li	a4,0
ffffffffc02038de:	a5dff0ef          	jal	ra,ffffffffc020333a <copy_range>
ffffffffc02038e2:	e105                	bnez	a0,ffffffffc0203902 <dup_mmap+0x62>
    return listelm->prev;
ffffffffc02038e4:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc02038e6:	02848863          	beq	s1,s0,ffffffffc0203916 <dup_mmap+0x76>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02038ea:	03000513          	li	a0,48
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc02038ee:	fe843a83          	ld	s5,-24(s0)
ffffffffc02038f2:	ff043a03          	ld	s4,-16(s0)
ffffffffc02038f6:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02038fa:	b84fe0ef          	jal	ra,ffffffffc0201c7e <kmalloc>
ffffffffc02038fe:	85aa                	mv	a1,a0
    if (vma != NULL)
ffffffffc0203900:	fd55                	bnez	a0,ffffffffc02038bc <dup_mmap+0x1c>
            return -E_NO_MEM;
ffffffffc0203902:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc0203904:	70e2                	ld	ra,56(sp)
ffffffffc0203906:	7442                	ld	s0,48(sp)
ffffffffc0203908:	74a2                	ld	s1,40(sp)
ffffffffc020390a:	7902                	ld	s2,32(sp)
ffffffffc020390c:	69e2                	ld	s3,24(sp)
ffffffffc020390e:	6a42                	ld	s4,16(sp)
ffffffffc0203910:	6aa2                	ld	s5,8(sp)
ffffffffc0203912:	6121                	addi	sp,sp,64
ffffffffc0203914:	8082                	ret
    return 0;
ffffffffc0203916:	4501                	li	a0,0
ffffffffc0203918:	b7f5                	j	ffffffffc0203904 <dup_mmap+0x64>
    assert(to != NULL && from != NULL);
ffffffffc020391a:	00003697          	auipc	a3,0x3
ffffffffc020391e:	37e68693          	addi	a3,a3,894 # ffffffffc0206c98 <default_pmm_manager+0x830>
ffffffffc0203922:	00002617          	auipc	a2,0x2
ffffffffc0203926:	79660613          	addi	a2,a2,1942 # ffffffffc02060b8 <commands+0x818>
ffffffffc020392a:	0cf00593          	li	a1,207
ffffffffc020392e:	00003517          	auipc	a0,0x3
ffffffffc0203932:	2d250513          	addi	a0,a0,722 # ffffffffc0206c00 <default_pmm_manager+0x798>
ffffffffc0203936:	b59fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020393a <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc020393a:	1101                	addi	sp,sp,-32
ffffffffc020393c:	ec06                	sd	ra,24(sp)
ffffffffc020393e:	e822                	sd	s0,16(sp)
ffffffffc0203940:	e426                	sd	s1,8(sp)
ffffffffc0203942:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203944:	c531                	beqz	a0,ffffffffc0203990 <exit_mmap+0x56>
ffffffffc0203946:	591c                	lw	a5,48(a0)
ffffffffc0203948:	84aa                	mv	s1,a0
ffffffffc020394a:	e3b9                	bnez	a5,ffffffffc0203990 <exit_mmap+0x56>
    return listelm->next;
ffffffffc020394c:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc020394e:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc0203952:	02850663          	beq	a0,s0,ffffffffc020397e <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203956:	ff043603          	ld	a2,-16(s0)
ffffffffc020395a:	fe843583          	ld	a1,-24(s0)
ffffffffc020395e:	854a                	mv	a0,s2
ffffffffc0203960:	831fe0ef          	jal	ra,ffffffffc0202190 <unmap_range>
ffffffffc0203964:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203966:	fe8498e3          	bne	s1,s0,ffffffffc0203956 <exit_mmap+0x1c>
ffffffffc020396a:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc020396c:	00848c63          	beq	s1,s0,ffffffffc0203984 <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203970:	ff043603          	ld	a2,-16(s0)
ffffffffc0203974:	fe843583          	ld	a1,-24(s0)
ffffffffc0203978:	854a                	mv	a0,s2
ffffffffc020397a:	95dfe0ef          	jal	ra,ffffffffc02022d6 <exit_range>
ffffffffc020397e:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203980:	fe8498e3          	bne	s1,s0,ffffffffc0203970 <exit_mmap+0x36>
    }
}
ffffffffc0203984:	60e2                	ld	ra,24(sp)
ffffffffc0203986:	6442                	ld	s0,16(sp)
ffffffffc0203988:	64a2                	ld	s1,8(sp)
ffffffffc020398a:	6902                	ld	s2,0(sp)
ffffffffc020398c:	6105                	addi	sp,sp,32
ffffffffc020398e:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203990:	00003697          	auipc	a3,0x3
ffffffffc0203994:	32868693          	addi	a3,a3,808 # ffffffffc0206cb8 <default_pmm_manager+0x850>
ffffffffc0203998:	00002617          	auipc	a2,0x2
ffffffffc020399c:	72060613          	addi	a2,a2,1824 # ffffffffc02060b8 <commands+0x818>
ffffffffc02039a0:	0e800593          	li	a1,232
ffffffffc02039a4:	00003517          	auipc	a0,0x3
ffffffffc02039a8:	25c50513          	addi	a0,a0,604 # ffffffffc0206c00 <default_pmm_manager+0x798>
ffffffffc02039ac:	ae3fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02039b0 <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc02039b0:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02039b2:	04000513          	li	a0,64
{
ffffffffc02039b6:	fc06                	sd	ra,56(sp)
ffffffffc02039b8:	f822                	sd	s0,48(sp)
ffffffffc02039ba:	f426                	sd	s1,40(sp)
ffffffffc02039bc:	f04a                	sd	s2,32(sp)
ffffffffc02039be:	ec4e                	sd	s3,24(sp)
ffffffffc02039c0:	e852                	sd	s4,16(sp)
ffffffffc02039c2:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02039c4:	abafe0ef          	jal	ra,ffffffffc0201c7e <kmalloc>
    if (mm != NULL)
ffffffffc02039c8:	2e050663          	beqz	a0,ffffffffc0203cb4 <vmm_init+0x304>
ffffffffc02039cc:	84aa                	mv	s1,a0
    elm->prev = elm->next = elm;
ffffffffc02039ce:	e508                	sd	a0,8(a0)
ffffffffc02039d0:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc02039d2:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc02039d6:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc02039da:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc02039de:	02053423          	sd	zero,40(a0)
ffffffffc02039e2:	02052823          	sw	zero,48(a0)
ffffffffc02039e6:	02053c23          	sd	zero,56(a0)
ffffffffc02039ea:	03200413          	li	s0,50
ffffffffc02039ee:	a811                	j	ffffffffc0203a02 <vmm_init+0x52>
        vma->vm_start = vm_start;
ffffffffc02039f0:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc02039f2:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc02039f4:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
ffffffffc02039f8:	146d                	addi	s0,s0,-5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc02039fa:	8526                	mv	a0,s1
ffffffffc02039fc:	cd3ff0ef          	jal	ra,ffffffffc02036ce <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0203a00:	c80d                	beqz	s0,ffffffffc0203a32 <vmm_init+0x82>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203a02:	03000513          	li	a0,48
ffffffffc0203a06:	a78fe0ef          	jal	ra,ffffffffc0201c7e <kmalloc>
ffffffffc0203a0a:	85aa                	mv	a1,a0
ffffffffc0203a0c:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203a10:	f165                	bnez	a0,ffffffffc02039f0 <vmm_init+0x40>
        assert(vma != NULL);
ffffffffc0203a12:	00003697          	auipc	a3,0x3
ffffffffc0203a16:	43e68693          	addi	a3,a3,1086 # ffffffffc0206e50 <default_pmm_manager+0x9e8>
ffffffffc0203a1a:	00002617          	auipc	a2,0x2
ffffffffc0203a1e:	69e60613          	addi	a2,a2,1694 # ffffffffc02060b8 <commands+0x818>
ffffffffc0203a22:	12c00593          	li	a1,300
ffffffffc0203a26:	00003517          	auipc	a0,0x3
ffffffffc0203a2a:	1da50513          	addi	a0,a0,474 # ffffffffc0206c00 <default_pmm_manager+0x798>
ffffffffc0203a2e:	a61fc0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0203a32:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203a36:	1f900913          	li	s2,505
ffffffffc0203a3a:	a819                	j	ffffffffc0203a50 <vmm_init+0xa0>
        vma->vm_start = vm_start;
ffffffffc0203a3c:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203a3e:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203a40:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203a44:	0415                	addi	s0,s0,5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203a46:	8526                	mv	a0,s1
ffffffffc0203a48:	c87ff0ef          	jal	ra,ffffffffc02036ce <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203a4c:	03240a63          	beq	s0,s2,ffffffffc0203a80 <vmm_init+0xd0>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203a50:	03000513          	li	a0,48
ffffffffc0203a54:	a2afe0ef          	jal	ra,ffffffffc0201c7e <kmalloc>
ffffffffc0203a58:	85aa                	mv	a1,a0
ffffffffc0203a5a:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203a5e:	fd79                	bnez	a0,ffffffffc0203a3c <vmm_init+0x8c>
        assert(vma != NULL);
ffffffffc0203a60:	00003697          	auipc	a3,0x3
ffffffffc0203a64:	3f068693          	addi	a3,a3,1008 # ffffffffc0206e50 <default_pmm_manager+0x9e8>
ffffffffc0203a68:	00002617          	auipc	a2,0x2
ffffffffc0203a6c:	65060613          	addi	a2,a2,1616 # ffffffffc02060b8 <commands+0x818>
ffffffffc0203a70:	13300593          	li	a1,307
ffffffffc0203a74:	00003517          	auipc	a0,0x3
ffffffffc0203a78:	18c50513          	addi	a0,a0,396 # ffffffffc0206c00 <default_pmm_manager+0x798>
ffffffffc0203a7c:	a13fc0ef          	jal	ra,ffffffffc020048e <__panic>
    return listelm->next;
ffffffffc0203a80:	649c                	ld	a5,8(s1)
ffffffffc0203a82:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0203a84:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0203a88:	16f48663          	beq	s1,a5,ffffffffc0203bf4 <vmm_init+0x244>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203a8c:	fe87b603          	ld	a2,-24(a5) # ffffffffffffefe8 <end+0x3fd548dc>
ffffffffc0203a90:	ffe70693          	addi	a3,a4,-2
ffffffffc0203a94:	10d61063          	bne	a2,a3,ffffffffc0203b94 <vmm_init+0x1e4>
ffffffffc0203a98:	ff07b683          	ld	a3,-16(a5)
ffffffffc0203a9c:	0ed71c63          	bne	a4,a3,ffffffffc0203b94 <vmm_init+0x1e4>
    for (i = 1; i <= step2; i++)
ffffffffc0203aa0:	0715                	addi	a4,a4,5
ffffffffc0203aa2:	679c                	ld	a5,8(a5)
ffffffffc0203aa4:	feb712e3          	bne	a4,a1,ffffffffc0203a88 <vmm_init+0xd8>
ffffffffc0203aa8:	4a1d                	li	s4,7
ffffffffc0203aaa:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203aac:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0203ab0:	85a2                	mv	a1,s0
ffffffffc0203ab2:	8526                	mv	a0,s1
ffffffffc0203ab4:	bdbff0ef          	jal	ra,ffffffffc020368e <find_vma>
ffffffffc0203ab8:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0203aba:	16050d63          	beqz	a0,ffffffffc0203c34 <vmm_init+0x284>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0203abe:	00140593          	addi	a1,s0,1
ffffffffc0203ac2:	8526                	mv	a0,s1
ffffffffc0203ac4:	bcbff0ef          	jal	ra,ffffffffc020368e <find_vma>
ffffffffc0203ac8:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0203aca:	14050563          	beqz	a0,ffffffffc0203c14 <vmm_init+0x264>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0203ace:	85d2                	mv	a1,s4
ffffffffc0203ad0:	8526                	mv	a0,s1
ffffffffc0203ad2:	bbdff0ef          	jal	ra,ffffffffc020368e <find_vma>
        assert(vma3 == NULL);
ffffffffc0203ad6:	16051f63          	bnez	a0,ffffffffc0203c54 <vmm_init+0x2a4>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0203ada:	00340593          	addi	a1,s0,3
ffffffffc0203ade:	8526                	mv	a0,s1
ffffffffc0203ae0:	bafff0ef          	jal	ra,ffffffffc020368e <find_vma>
        assert(vma4 == NULL);
ffffffffc0203ae4:	1a051863          	bnez	a0,ffffffffc0203c94 <vmm_init+0x2e4>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0203ae8:	00440593          	addi	a1,s0,4
ffffffffc0203aec:	8526                	mv	a0,s1
ffffffffc0203aee:	ba1ff0ef          	jal	ra,ffffffffc020368e <find_vma>
        assert(vma5 == NULL);
ffffffffc0203af2:	18051163          	bnez	a0,ffffffffc0203c74 <vmm_init+0x2c4>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203af6:	00893783          	ld	a5,8(s2)
ffffffffc0203afa:	0a879d63          	bne	a5,s0,ffffffffc0203bb4 <vmm_init+0x204>
ffffffffc0203afe:	01093783          	ld	a5,16(s2)
ffffffffc0203b02:	0b479963          	bne	a5,s4,ffffffffc0203bb4 <vmm_init+0x204>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203b06:	0089b783          	ld	a5,8(s3)
ffffffffc0203b0a:	0c879563          	bne	a5,s0,ffffffffc0203bd4 <vmm_init+0x224>
ffffffffc0203b0e:	0109b783          	ld	a5,16(s3)
ffffffffc0203b12:	0d479163          	bne	a5,s4,ffffffffc0203bd4 <vmm_init+0x224>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203b16:	0415                	addi	s0,s0,5
ffffffffc0203b18:	0a15                	addi	s4,s4,5
ffffffffc0203b1a:	f9541be3          	bne	s0,s5,ffffffffc0203ab0 <vmm_init+0x100>
ffffffffc0203b1e:	4411                	li	s0,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203b20:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203b22:	85a2                	mv	a1,s0
ffffffffc0203b24:	8526                	mv	a0,s1
ffffffffc0203b26:	b69ff0ef          	jal	ra,ffffffffc020368e <find_vma>
ffffffffc0203b2a:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL)
ffffffffc0203b2e:	c90d                	beqz	a0,ffffffffc0203b60 <vmm_init+0x1b0>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203b30:	6914                	ld	a3,16(a0)
ffffffffc0203b32:	6510                	ld	a2,8(a0)
ffffffffc0203b34:	00003517          	auipc	a0,0x3
ffffffffc0203b38:	2a450513          	addi	a0,a0,676 # ffffffffc0206dd8 <default_pmm_manager+0x970>
ffffffffc0203b3c:	e58fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0203b40:	00003697          	auipc	a3,0x3
ffffffffc0203b44:	2c068693          	addi	a3,a3,704 # ffffffffc0206e00 <default_pmm_manager+0x998>
ffffffffc0203b48:	00002617          	auipc	a2,0x2
ffffffffc0203b4c:	57060613          	addi	a2,a2,1392 # ffffffffc02060b8 <commands+0x818>
ffffffffc0203b50:	15900593          	li	a1,345
ffffffffc0203b54:	00003517          	auipc	a0,0x3
ffffffffc0203b58:	0ac50513          	addi	a0,a0,172 # ffffffffc0206c00 <default_pmm_manager+0x798>
ffffffffc0203b5c:	933fc0ef          	jal	ra,ffffffffc020048e <__panic>
    for (i = 4; i >= 0; i--)
ffffffffc0203b60:	147d                	addi	s0,s0,-1
ffffffffc0203b62:	fd2410e3          	bne	s0,s2,ffffffffc0203b22 <vmm_init+0x172>
    }

    mm_destroy(mm);
ffffffffc0203b66:	8526                	mv	a0,s1
ffffffffc0203b68:	c37ff0ef          	jal	ra,ffffffffc020379e <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203b6c:	00003517          	auipc	a0,0x3
ffffffffc0203b70:	2ac50513          	addi	a0,a0,684 # ffffffffc0206e18 <default_pmm_manager+0x9b0>
ffffffffc0203b74:	e20fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0203b78:	7442                	ld	s0,48(sp)
ffffffffc0203b7a:	70e2                	ld	ra,56(sp)
ffffffffc0203b7c:	74a2                	ld	s1,40(sp)
ffffffffc0203b7e:	7902                	ld	s2,32(sp)
ffffffffc0203b80:	69e2                	ld	s3,24(sp)
ffffffffc0203b82:	6a42                	ld	s4,16(sp)
ffffffffc0203b84:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203b86:	00003517          	auipc	a0,0x3
ffffffffc0203b8a:	2b250513          	addi	a0,a0,690 # ffffffffc0206e38 <default_pmm_manager+0x9d0>
}
ffffffffc0203b8e:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203b90:	e04fc06f          	j	ffffffffc0200194 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203b94:	00003697          	auipc	a3,0x3
ffffffffc0203b98:	15c68693          	addi	a3,a3,348 # ffffffffc0206cf0 <default_pmm_manager+0x888>
ffffffffc0203b9c:	00002617          	auipc	a2,0x2
ffffffffc0203ba0:	51c60613          	addi	a2,a2,1308 # ffffffffc02060b8 <commands+0x818>
ffffffffc0203ba4:	13d00593          	li	a1,317
ffffffffc0203ba8:	00003517          	auipc	a0,0x3
ffffffffc0203bac:	05850513          	addi	a0,a0,88 # ffffffffc0206c00 <default_pmm_manager+0x798>
ffffffffc0203bb0:	8dffc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203bb4:	00003697          	auipc	a3,0x3
ffffffffc0203bb8:	1c468693          	addi	a3,a3,452 # ffffffffc0206d78 <default_pmm_manager+0x910>
ffffffffc0203bbc:	00002617          	auipc	a2,0x2
ffffffffc0203bc0:	4fc60613          	addi	a2,a2,1276 # ffffffffc02060b8 <commands+0x818>
ffffffffc0203bc4:	14e00593          	li	a1,334
ffffffffc0203bc8:	00003517          	auipc	a0,0x3
ffffffffc0203bcc:	03850513          	addi	a0,a0,56 # ffffffffc0206c00 <default_pmm_manager+0x798>
ffffffffc0203bd0:	8bffc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203bd4:	00003697          	auipc	a3,0x3
ffffffffc0203bd8:	1d468693          	addi	a3,a3,468 # ffffffffc0206da8 <default_pmm_manager+0x940>
ffffffffc0203bdc:	00002617          	auipc	a2,0x2
ffffffffc0203be0:	4dc60613          	addi	a2,a2,1244 # ffffffffc02060b8 <commands+0x818>
ffffffffc0203be4:	14f00593          	li	a1,335
ffffffffc0203be8:	00003517          	auipc	a0,0x3
ffffffffc0203bec:	01850513          	addi	a0,a0,24 # ffffffffc0206c00 <default_pmm_manager+0x798>
ffffffffc0203bf0:	89ffc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203bf4:	00003697          	auipc	a3,0x3
ffffffffc0203bf8:	0e468693          	addi	a3,a3,228 # ffffffffc0206cd8 <default_pmm_manager+0x870>
ffffffffc0203bfc:	00002617          	auipc	a2,0x2
ffffffffc0203c00:	4bc60613          	addi	a2,a2,1212 # ffffffffc02060b8 <commands+0x818>
ffffffffc0203c04:	13b00593          	li	a1,315
ffffffffc0203c08:	00003517          	auipc	a0,0x3
ffffffffc0203c0c:	ff850513          	addi	a0,a0,-8 # ffffffffc0206c00 <default_pmm_manager+0x798>
ffffffffc0203c10:	87ffc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma2 != NULL);
ffffffffc0203c14:	00003697          	auipc	a3,0x3
ffffffffc0203c18:	12468693          	addi	a3,a3,292 # ffffffffc0206d38 <default_pmm_manager+0x8d0>
ffffffffc0203c1c:	00002617          	auipc	a2,0x2
ffffffffc0203c20:	49c60613          	addi	a2,a2,1180 # ffffffffc02060b8 <commands+0x818>
ffffffffc0203c24:	14600593          	li	a1,326
ffffffffc0203c28:	00003517          	auipc	a0,0x3
ffffffffc0203c2c:	fd850513          	addi	a0,a0,-40 # ffffffffc0206c00 <default_pmm_manager+0x798>
ffffffffc0203c30:	85ffc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma1 != NULL);
ffffffffc0203c34:	00003697          	auipc	a3,0x3
ffffffffc0203c38:	0f468693          	addi	a3,a3,244 # ffffffffc0206d28 <default_pmm_manager+0x8c0>
ffffffffc0203c3c:	00002617          	auipc	a2,0x2
ffffffffc0203c40:	47c60613          	addi	a2,a2,1148 # ffffffffc02060b8 <commands+0x818>
ffffffffc0203c44:	14400593          	li	a1,324
ffffffffc0203c48:	00003517          	auipc	a0,0x3
ffffffffc0203c4c:	fb850513          	addi	a0,a0,-72 # ffffffffc0206c00 <default_pmm_manager+0x798>
ffffffffc0203c50:	83ffc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma3 == NULL);
ffffffffc0203c54:	00003697          	auipc	a3,0x3
ffffffffc0203c58:	0f468693          	addi	a3,a3,244 # ffffffffc0206d48 <default_pmm_manager+0x8e0>
ffffffffc0203c5c:	00002617          	auipc	a2,0x2
ffffffffc0203c60:	45c60613          	addi	a2,a2,1116 # ffffffffc02060b8 <commands+0x818>
ffffffffc0203c64:	14800593          	li	a1,328
ffffffffc0203c68:	00003517          	auipc	a0,0x3
ffffffffc0203c6c:	f9850513          	addi	a0,a0,-104 # ffffffffc0206c00 <default_pmm_manager+0x798>
ffffffffc0203c70:	81ffc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma5 == NULL);
ffffffffc0203c74:	00003697          	auipc	a3,0x3
ffffffffc0203c78:	0f468693          	addi	a3,a3,244 # ffffffffc0206d68 <default_pmm_manager+0x900>
ffffffffc0203c7c:	00002617          	auipc	a2,0x2
ffffffffc0203c80:	43c60613          	addi	a2,a2,1084 # ffffffffc02060b8 <commands+0x818>
ffffffffc0203c84:	14c00593          	li	a1,332
ffffffffc0203c88:	00003517          	auipc	a0,0x3
ffffffffc0203c8c:	f7850513          	addi	a0,a0,-136 # ffffffffc0206c00 <default_pmm_manager+0x798>
ffffffffc0203c90:	ffefc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma4 == NULL);
ffffffffc0203c94:	00003697          	auipc	a3,0x3
ffffffffc0203c98:	0c468693          	addi	a3,a3,196 # ffffffffc0206d58 <default_pmm_manager+0x8f0>
ffffffffc0203c9c:	00002617          	auipc	a2,0x2
ffffffffc0203ca0:	41c60613          	addi	a2,a2,1052 # ffffffffc02060b8 <commands+0x818>
ffffffffc0203ca4:	14a00593          	li	a1,330
ffffffffc0203ca8:	00003517          	auipc	a0,0x3
ffffffffc0203cac:	f5850513          	addi	a0,a0,-168 # ffffffffc0206c00 <default_pmm_manager+0x798>
ffffffffc0203cb0:	fdefc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(mm != NULL);
ffffffffc0203cb4:	00003697          	auipc	a3,0x3
ffffffffc0203cb8:	fd468693          	addi	a3,a3,-44 # ffffffffc0206c88 <default_pmm_manager+0x820>
ffffffffc0203cbc:	00002617          	auipc	a2,0x2
ffffffffc0203cc0:	3fc60613          	addi	a2,a2,1020 # ffffffffc02060b8 <commands+0x818>
ffffffffc0203cc4:	12400593          	li	a1,292
ffffffffc0203cc8:	00003517          	auipc	a0,0x3
ffffffffc0203ccc:	f3850513          	addi	a0,a0,-200 # ffffffffc0206c00 <default_pmm_manager+0x798>
ffffffffc0203cd0:	fbefc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203cd4 <user_mem_check>:
}
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc0203cd4:	7179                	addi	sp,sp,-48
ffffffffc0203cd6:	f022                	sd	s0,32(sp)
ffffffffc0203cd8:	f406                	sd	ra,40(sp)
ffffffffc0203cda:	ec26                	sd	s1,24(sp)
ffffffffc0203cdc:	e84a                	sd	s2,16(sp)
ffffffffc0203cde:	e44e                	sd	s3,8(sp)
ffffffffc0203ce0:	e052                	sd	s4,0(sp)
ffffffffc0203ce2:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc0203ce4:	c135                	beqz	a0,ffffffffc0203d48 <user_mem_check+0x74>
    {
        if (!USER_ACCESS(addr, addr + len))
ffffffffc0203ce6:	002007b7          	lui	a5,0x200
ffffffffc0203cea:	04f5e663          	bltu	a1,a5,ffffffffc0203d36 <user_mem_check+0x62>
ffffffffc0203cee:	00c584b3          	add	s1,a1,a2
ffffffffc0203cf2:	0495f263          	bgeu	a1,s1,ffffffffc0203d36 <user_mem_check+0x62>
ffffffffc0203cf6:	4785                	li	a5,1
ffffffffc0203cf8:	07fe                	slli	a5,a5,0x1f
ffffffffc0203cfa:	0297ee63          	bltu	a5,s1,ffffffffc0203d36 <user_mem_check+0x62>
ffffffffc0203cfe:	892a                	mv	s2,a0
ffffffffc0203d00:	89b6                	mv	s3,a3
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203d02:	6a05                	lui	s4,0x1
ffffffffc0203d04:	a821                	j	ffffffffc0203d1c <user_mem_check+0x48>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203d06:	0027f693          	andi	a3,a5,2
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203d0a:	9752                	add	a4,a4,s4
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203d0c:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203d0e:	c685                	beqz	a3,ffffffffc0203d36 <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203d10:	c399                	beqz	a5,ffffffffc0203d16 <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203d12:	02e46263          	bltu	s0,a4,ffffffffc0203d36 <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0203d16:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc0203d18:	04947663          	bgeu	s0,s1,ffffffffc0203d64 <user_mem_check+0x90>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc0203d1c:	85a2                	mv	a1,s0
ffffffffc0203d1e:	854a                	mv	a0,s2
ffffffffc0203d20:	96fff0ef          	jal	ra,ffffffffc020368e <find_vma>
ffffffffc0203d24:	c909                	beqz	a0,ffffffffc0203d36 <user_mem_check+0x62>
ffffffffc0203d26:	6518                	ld	a4,8(a0)
ffffffffc0203d28:	00e46763          	bltu	s0,a4,ffffffffc0203d36 <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203d2c:	4d1c                	lw	a5,24(a0)
ffffffffc0203d2e:	fc099ce3          	bnez	s3,ffffffffc0203d06 <user_mem_check+0x32>
ffffffffc0203d32:	8b85                	andi	a5,a5,1
ffffffffc0203d34:	f3ed                	bnez	a5,ffffffffc0203d16 <user_mem_check+0x42>
            return 0;
ffffffffc0203d36:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203d38:	70a2                	ld	ra,40(sp)
ffffffffc0203d3a:	7402                	ld	s0,32(sp)
ffffffffc0203d3c:	64e2                	ld	s1,24(sp)
ffffffffc0203d3e:	6942                	ld	s2,16(sp)
ffffffffc0203d40:	69a2                	ld	s3,8(sp)
ffffffffc0203d42:	6a02                	ld	s4,0(sp)
ffffffffc0203d44:	6145                	addi	sp,sp,48
ffffffffc0203d46:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203d48:	c02007b7          	lui	a5,0xc0200
ffffffffc0203d4c:	4501                	li	a0,0
ffffffffc0203d4e:	fef5e5e3          	bltu	a1,a5,ffffffffc0203d38 <user_mem_check+0x64>
ffffffffc0203d52:	962e                	add	a2,a2,a1
ffffffffc0203d54:	fec5f2e3          	bgeu	a1,a2,ffffffffc0203d38 <user_mem_check+0x64>
ffffffffc0203d58:	c8000537          	lui	a0,0xc8000
ffffffffc0203d5c:	0505                	addi	a0,a0,1
ffffffffc0203d5e:	00a63533          	sltu	a0,a2,a0
ffffffffc0203d62:	bfd9                	j	ffffffffc0203d38 <user_mem_check+0x64>
        return 1;
ffffffffc0203d64:	4505                	li	a0,1
ffffffffc0203d66:	bfc9                	j	ffffffffc0203d38 <user_mem_check+0x64>

ffffffffc0203d68 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0203d68:	8526                	mv	a0,s1
	jalr s0
ffffffffc0203d6a:	9402                	jalr	s0

	jal do_exit
ffffffffc0203d6c:	5d2000ef          	jal	ra,ffffffffc020433e <do_exit>

ffffffffc0203d70 <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0203d70:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203d72:	10800513          	li	a0,264
{
ffffffffc0203d76:	e022                	sd	s0,0(sp)
ffffffffc0203d78:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203d7a:	f05fd0ef          	jal	ra,ffffffffc0201c7e <kmalloc>
ffffffffc0203d7e:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0203d80:	cd21                	beqz	a0,ffffffffc0203dd8 <alloc_proc+0x68>
         *       struct trapframe *tf;                       // Trap frame for current interrupt
         *       uintptr_t pgdir;                            // the base addr of Page Directroy Table(PDT)
         *       uint32_t flags;                             // Process flag
         *       char name[PROC_NAME_LEN + 1];               // Process name
         */
         proc->state = 0;//初始值PROC_UNINIT
ffffffffc0203d82:	57fd                	li	a5,-1
ffffffffc0203d84:	1782                	slli	a5,a5,0x20
ffffffffc0203d86:	e11c                	sd	a5,0(a0)
         proc->runs = 0;
         proc->kstack = 0;
         proc->need_resched = 0; //不用schedule调度其他进程
         proc->parent = NULL;
         proc->mm = NULL;
         memset(&proc->context, 0, sizeof(struct context));
ffffffffc0203d88:	07000613          	li	a2,112
ffffffffc0203d8c:	4581                	li	a1,0
         proc->runs = 0;
ffffffffc0203d8e:	00052423          	sw	zero,8(a0) # ffffffffc8000008 <end+0x7d558fc>
         proc->kstack = 0;
ffffffffc0203d92:	00053823          	sd	zero,16(a0)
         proc->need_resched = 0; //不用schedule调度其他进程
ffffffffc0203d96:	00053c23          	sd	zero,24(a0)
         proc->parent = NULL;
ffffffffc0203d9a:	02053023          	sd	zero,32(a0)
         proc->mm = NULL;
ffffffffc0203d9e:	02053423          	sd	zero,40(a0)
         memset(&proc->context, 0, sizeof(struct context));
ffffffffc0203da2:	03050513          	addi	a0,a0,48
ffffffffc0203da6:	065010ef          	jal	ra,ffffffffc020560a <memset>
         proc->tf = NULL;
         proc->pgdir = boot_pgdir_pa;
ffffffffc0203daa:	000a7797          	auipc	a5,0xa7
ffffffffc0203dae:	9167b783          	ld	a5,-1770(a5) # ffffffffc02aa6c0 <boot_pgdir_pa>
         proc->tf = NULL;
ffffffffc0203db2:	0a043023          	sd	zero,160(s0)
         proc->pgdir = boot_pgdir_pa;
ffffffffc0203db6:	f45c                	sd	a5,168(s0)
         //cprintf("boot_pgdir_pa: %lx\n", boot_pgdir_pa);
         proc->flags = 0;
ffffffffc0203db8:	0a042823          	sw	zero,176(s0)
         memset(proc->name, 0, sizeof(proc->name));
ffffffffc0203dbc:	4641                	li	a2,16
ffffffffc0203dbe:	4581                	li	a1,0
ffffffffc0203dc0:	0b440513          	addi	a0,s0,180
ffffffffc0203dc4:	047010ef          	jal	ra,ffffffffc020560a <memset>
        /*
         * below fields(add in LAB5) in proc_struct need to be initialized
         *       uint32_t wait_state;                        // waiting state
         *       struct proc_struct *cptr, *yptr, *optr;     // relations between processes
         */
         proc->wait_state = 0;
ffffffffc0203dc8:	0e042623          	sw	zero,236(s0)
            proc->cptr = NULL;
ffffffffc0203dcc:	0e043823          	sd	zero,240(s0)
            proc->yptr = NULL;
ffffffffc0203dd0:	0e043c23          	sd	zero,248(s0)
            proc->optr = NULL;
ffffffffc0203dd4:	10043023          	sd	zero,256(s0)
    }
    return proc;
}
ffffffffc0203dd8:	60a2                	ld	ra,8(sp)
ffffffffc0203dda:	8522                	mv	a0,s0
ffffffffc0203ddc:	6402                	ld	s0,0(sp)
ffffffffc0203dde:	0141                	addi	sp,sp,16
ffffffffc0203de0:	8082                	ret

ffffffffc0203de2 <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0203de2:	000a7797          	auipc	a5,0xa7
ffffffffc0203de6:	90e7b783          	ld	a5,-1778(a5) # ffffffffc02aa6f0 <current>
ffffffffc0203dea:	73c8                	ld	a0,160(a5)
ffffffffc0203dec:	906fd06f          	j	ffffffffc0200ef2 <forkrets>

ffffffffc0203df0 <user_main>:
// user_main - kernel thread used to exec a user program
static int
user_main(void *arg)
{
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0203df0:	000a7797          	auipc	a5,0xa7
ffffffffc0203df4:	9007b783          	ld	a5,-1792(a5) # ffffffffc02aa6f0 <current>
ffffffffc0203df8:	43cc                	lw	a1,4(a5)
{
ffffffffc0203dfa:	7139                	addi	sp,sp,-64
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0203dfc:	00003617          	auipc	a2,0x3
ffffffffc0203e00:	06460613          	addi	a2,a2,100 # ffffffffc0206e60 <default_pmm_manager+0x9f8>
ffffffffc0203e04:	00003517          	auipc	a0,0x3
ffffffffc0203e08:	06c50513          	addi	a0,a0,108 # ffffffffc0206e70 <default_pmm_manager+0xa08>
{
ffffffffc0203e0c:	fc06                	sd	ra,56(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0203e0e:	b86fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0203e12:	3fe06797          	auipc	a5,0x3fe06
ffffffffc0203e16:	d9678793          	addi	a5,a5,-618 # 9ba8 <_binary_obj___user_faultread_out_size>
ffffffffc0203e1a:	e43e                	sd	a5,8(sp)
ffffffffc0203e1c:	00003517          	auipc	a0,0x3
ffffffffc0203e20:	04450513          	addi	a0,a0,68 # ffffffffc0206e60 <default_pmm_manager+0x9f8>
ffffffffc0203e24:	00032797          	auipc	a5,0x32
ffffffffc0203e28:	80c78793          	addi	a5,a5,-2036 # ffffffffc0235630 <_binary_obj___user_faultread_out_start>
ffffffffc0203e2c:	f03e                	sd	a5,32(sp)
ffffffffc0203e2e:	f42a                	sd	a0,40(sp)
    int64_t ret = 0, len = strlen(name);
ffffffffc0203e30:	e802                	sd	zero,16(sp)
ffffffffc0203e32:	736010ef          	jal	ra,ffffffffc0205568 <strlen>
ffffffffc0203e36:	ec2a                	sd	a0,24(sp)
    asm volatile(
ffffffffc0203e38:	4511                	li	a0,4
ffffffffc0203e3a:	55a2                	lw	a1,40(sp)
ffffffffc0203e3c:	4662                	lw	a2,24(sp)
ffffffffc0203e3e:	5682                	lw	a3,32(sp)
ffffffffc0203e40:	4722                	lw	a4,8(sp)
ffffffffc0203e42:	48a9                	li	a7,10
ffffffffc0203e44:	9002                	ebreak
ffffffffc0203e46:	c82a                	sw	a0,16(sp)
    cprintf("ret = %d\n", ret);
ffffffffc0203e48:	65c2                	ld	a1,16(sp)
ffffffffc0203e4a:	00003517          	auipc	a0,0x3
ffffffffc0203e4e:	04e50513          	addi	a0,a0,78 # ffffffffc0206e98 <default_pmm_manager+0xa30>
ffffffffc0203e52:	b42fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
#else
    KERNEL_EXECVE(exit);
#endif
    panic("user_main execve failed.\n");
ffffffffc0203e56:	00003617          	auipc	a2,0x3
ffffffffc0203e5a:	05260613          	addi	a2,a2,82 # ffffffffc0206ea8 <default_pmm_manager+0xa40>
ffffffffc0203e5e:	3ab00593          	li	a1,939
ffffffffc0203e62:	00003517          	auipc	a0,0x3
ffffffffc0203e66:	06650513          	addi	a0,a0,102 # ffffffffc0206ec8 <default_pmm_manager+0xa60>
ffffffffc0203e6a:	e24fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203e6e <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0203e6e:	6d14                	ld	a3,24(a0)
{
ffffffffc0203e70:	1141                	addi	sp,sp,-16
ffffffffc0203e72:	e406                	sd	ra,8(sp)
ffffffffc0203e74:	c02007b7          	lui	a5,0xc0200
ffffffffc0203e78:	02f6ee63          	bltu	a3,a5,ffffffffc0203eb4 <put_pgdir+0x46>
ffffffffc0203e7c:	000a7517          	auipc	a0,0xa7
ffffffffc0203e80:	86c53503          	ld	a0,-1940(a0) # ffffffffc02aa6e8 <va_pa_offset>
ffffffffc0203e84:	8e89                	sub	a3,a3,a0
    if (PPN(pa) >= npage)
ffffffffc0203e86:	82b1                	srli	a3,a3,0xc
ffffffffc0203e88:	000a7797          	auipc	a5,0xa7
ffffffffc0203e8c:	8487b783          	ld	a5,-1976(a5) # ffffffffc02aa6d0 <npage>
ffffffffc0203e90:	02f6fe63          	bgeu	a3,a5,ffffffffc0203ecc <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc0203e94:	00004517          	auipc	a0,0x4
ffffffffc0203e98:	8cc53503          	ld	a0,-1844(a0) # ffffffffc0207760 <nbase>
}
ffffffffc0203e9c:	60a2                	ld	ra,8(sp)
ffffffffc0203e9e:	8e89                	sub	a3,a3,a0
ffffffffc0203ea0:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc0203ea2:	000a7517          	auipc	a0,0xa7
ffffffffc0203ea6:	83653503          	ld	a0,-1994(a0) # ffffffffc02aa6d8 <pages>
ffffffffc0203eaa:	4585                	li	a1,1
ffffffffc0203eac:	9536                	add	a0,a0,a3
}
ffffffffc0203eae:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc0203eb0:	febfd06f          	j	ffffffffc0201e9a <free_pages>
    return pa2page(PADDR(kva));
ffffffffc0203eb4:	00002617          	auipc	a2,0x2
ffffffffc0203eb8:	69460613          	addi	a2,a2,1684 # ffffffffc0206548 <default_pmm_manager+0xe0>
ffffffffc0203ebc:	07700593          	li	a1,119
ffffffffc0203ec0:	00002517          	auipc	a0,0x2
ffffffffc0203ec4:	60850513          	addi	a0,a0,1544 # ffffffffc02064c8 <default_pmm_manager+0x60>
ffffffffc0203ec8:	dc6fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203ecc:	00002617          	auipc	a2,0x2
ffffffffc0203ed0:	6a460613          	addi	a2,a2,1700 # ffffffffc0206570 <default_pmm_manager+0x108>
ffffffffc0203ed4:	06900593          	li	a1,105
ffffffffc0203ed8:	00002517          	auipc	a0,0x2
ffffffffc0203edc:	5f050513          	addi	a0,a0,1520 # ffffffffc02064c8 <default_pmm_manager+0x60>
ffffffffc0203ee0:	daefc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203ee4 <proc_run>:
{
ffffffffc0203ee4:	7179                	addi	sp,sp,-48
ffffffffc0203ee6:	f026                	sd	s1,32(sp)
    if (proc != current)
ffffffffc0203ee8:	000a7497          	auipc	s1,0xa7
ffffffffc0203eec:	80848493          	addi	s1,s1,-2040 # ffffffffc02aa6f0 <current>
ffffffffc0203ef0:	6098                	ld	a4,0(s1)
{
ffffffffc0203ef2:	f406                	sd	ra,40(sp)
ffffffffc0203ef4:	ec4a                	sd	s2,24(sp)
    if (proc != current)
ffffffffc0203ef6:	02a70763          	beq	a4,a0,ffffffffc0203f24 <proc_run+0x40>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203efa:	100027f3          	csrr	a5,sstatus
ffffffffc0203efe:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203f00:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203f02:	ef85                	bnez	a5,ffffffffc0203f3a <proc_run+0x56>
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned long pgdir)
{
  write_csr(satp, 0x8000000000000000 | (pgdir >> RISCV_PGSHIFT));
ffffffffc0203f04:	755c                	ld	a5,168(a0)
ffffffffc0203f06:	56fd                	li	a3,-1
ffffffffc0203f08:	16fe                	slli	a3,a3,0x3f
ffffffffc0203f0a:	83b1                	srli	a5,a5,0xc
         current = proc;
ffffffffc0203f0c:	e088                	sd	a0,0(s1)
ffffffffc0203f0e:	8fd5                	or	a5,a5,a3
ffffffffc0203f10:	18079073          	csrw	satp,a5
         switch_to(&prev->context,&current->context);
ffffffffc0203f14:	03050593          	addi	a1,a0,48
ffffffffc0203f18:	03070513          	addi	a0,a4,48
ffffffffc0203f1c:	7f3000ef          	jal	ra,ffffffffc0204f0e <switch_to>
    if (flag)
ffffffffc0203f20:	00091763          	bnez	s2,ffffffffc0203f2e <proc_run+0x4a>
}
ffffffffc0203f24:	70a2                	ld	ra,40(sp)
ffffffffc0203f26:	7482                	ld	s1,32(sp)
ffffffffc0203f28:	6962                	ld	s2,24(sp)
ffffffffc0203f2a:	6145                	addi	sp,sp,48
ffffffffc0203f2c:	8082                	ret
ffffffffc0203f2e:	70a2                	ld	ra,40(sp)
ffffffffc0203f30:	7482                	ld	s1,32(sp)
ffffffffc0203f32:	6962                	ld	s2,24(sp)
ffffffffc0203f34:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc0203f36:	a79fc06f          	j	ffffffffc02009ae <intr_enable>
ffffffffc0203f3a:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0203f3c:	a79fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
         struct proc_struct *prev = current;
ffffffffc0203f40:	6098                	ld	a4,0(s1)
        return 1;
ffffffffc0203f42:	6522                	ld	a0,8(sp)
ffffffffc0203f44:	4905                	li	s2,1
ffffffffc0203f46:	bf7d                	j	ffffffffc0203f04 <proc_run+0x20>

ffffffffc0203f48 <do_fork>:
{
ffffffffc0203f48:	7119                	addi	sp,sp,-128
ffffffffc0203f4a:	f0ca                	sd	s2,96(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0203f4c:	000a6917          	auipc	s2,0xa6
ffffffffc0203f50:	7bc90913          	addi	s2,s2,1980 # ffffffffc02aa708 <nr_process>
ffffffffc0203f54:	00092703          	lw	a4,0(s2)
{
ffffffffc0203f58:	fc86                	sd	ra,120(sp)
ffffffffc0203f5a:	f8a2                	sd	s0,112(sp)
ffffffffc0203f5c:	f4a6                	sd	s1,104(sp)
ffffffffc0203f5e:	ecce                	sd	s3,88(sp)
ffffffffc0203f60:	e8d2                	sd	s4,80(sp)
ffffffffc0203f62:	e4d6                	sd	s5,72(sp)
ffffffffc0203f64:	e0da                	sd	s6,64(sp)
ffffffffc0203f66:	fc5e                	sd	s7,56(sp)
ffffffffc0203f68:	f862                	sd	s8,48(sp)
ffffffffc0203f6a:	f466                	sd	s9,40(sp)
ffffffffc0203f6c:	f06a                	sd	s10,32(sp)
ffffffffc0203f6e:	ec6e                	sd	s11,24(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0203f70:	6785                	lui	a5,0x1
ffffffffc0203f72:	2ef75c63          	bge	a4,a5,ffffffffc020426a <do_fork+0x322>
ffffffffc0203f76:	8a2a                	mv	s4,a0
ffffffffc0203f78:	89ae                	mv	s3,a1
ffffffffc0203f7a:	8432                	mv	s0,a2
    proc = alloc_proc();
ffffffffc0203f7c:	df5ff0ef          	jal	ra,ffffffffc0203d70 <alloc_proc>
ffffffffc0203f80:	84aa                	mv	s1,a0
    if(proc == NULL)
ffffffffc0203f82:	2c050863          	beqz	a0,ffffffffc0204252 <do_fork+0x30a>
    proc->parent = current;          // 父进程为当前进程
ffffffffc0203f86:	000a6c17          	auipc	s8,0xa6
ffffffffc0203f8a:	76ac0c13          	addi	s8,s8,1898 # ffffffffc02aa6f0 <current>
ffffffffc0203f8e:	000c3783          	ld	a5,0(s8)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0203f92:	4509                	li	a0,2
    proc->parent = current;          // 父进程为当前进程
ffffffffc0203f94:	f09c                	sd	a5,32(s1)
    current->wait_state = 0; // 确保当前进程的 wait_state 为 0
ffffffffc0203f96:	0e07a623          	sw	zero,236(a5) # 10ec <_binary_obj___user_faultread_out_size-0x8abc>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0203f9a:	ec3fd0ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
    if (page != NULL)
ffffffffc0203f9e:	2a050763          	beqz	a0,ffffffffc020424c <do_fork+0x304>
    return page - pages + nbase;
ffffffffc0203fa2:	000a6a97          	auipc	s5,0xa6
ffffffffc0203fa6:	736a8a93          	addi	s5,s5,1846 # ffffffffc02aa6d8 <pages>
ffffffffc0203faa:	000ab683          	ld	a3,0(s5)
ffffffffc0203fae:	00003b17          	auipc	s6,0x3
ffffffffc0203fb2:	7b2b0b13          	addi	s6,s6,1970 # ffffffffc0207760 <nbase>
ffffffffc0203fb6:	000b3783          	ld	a5,0(s6)
ffffffffc0203fba:	40d506b3          	sub	a3,a0,a3
    return KADDR(page2pa(page));
ffffffffc0203fbe:	000a6b97          	auipc	s7,0xa6
ffffffffc0203fc2:	712b8b93          	addi	s7,s7,1810 # ffffffffc02aa6d0 <npage>
    return page - pages + nbase;
ffffffffc0203fc6:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0203fc8:	5dfd                	li	s11,-1
ffffffffc0203fca:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc0203fce:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0203fd0:	00cddd93          	srli	s11,s11,0xc
ffffffffc0203fd4:	01b6f633          	and	a2,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc0203fd8:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203fda:	2ce67563          	bgeu	a2,a4,ffffffffc02042a4 <do_fork+0x35c>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc0203fde:	000c3603          	ld	a2,0(s8)
ffffffffc0203fe2:	000a6c17          	auipc	s8,0xa6
ffffffffc0203fe6:	706c0c13          	addi	s8,s8,1798 # ffffffffc02aa6e8 <va_pa_offset>
ffffffffc0203fea:	000c3703          	ld	a4,0(s8)
ffffffffc0203fee:	02863d03          	ld	s10,40(a2)
ffffffffc0203ff2:	e43e                	sd	a5,8(sp)
ffffffffc0203ff4:	96ba                	add	a3,a3,a4
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc0203ff6:	e894                	sd	a3,16(s1)
    if (oldmm == NULL)
ffffffffc0203ff8:	020d0863          	beqz	s10,ffffffffc0204028 <do_fork+0xe0>
    if (clone_flags & CLONE_VM)
ffffffffc0203ffc:	100a7a13          	andi	s4,s4,256
ffffffffc0204000:	180a0863          	beqz	s4,ffffffffc0204190 <do_fork+0x248>
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    mm->mm_count += 1;
ffffffffc0204004:	030d2703          	lw	a4,48(s10)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204008:	018d3783          	ld	a5,24(s10)
ffffffffc020400c:	c02006b7          	lui	a3,0xc0200
ffffffffc0204010:	2705                	addiw	a4,a4,1
ffffffffc0204012:	02ed2823          	sw	a4,48(s10)
    proc->mm = mm;
ffffffffc0204016:	03a4b423          	sd	s10,40(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc020401a:	2ad7e163          	bltu	a5,a3,ffffffffc02042bc <do_fork+0x374>
ffffffffc020401e:	000c3703          	ld	a4,0(s8)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204022:	6894                	ld	a3,16(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204024:	8f99                	sub	a5,a5,a4
ffffffffc0204026:	f4dc                	sd	a5,168(s1)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204028:	6789                	lui	a5,0x2
ffffffffc020402a:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7cc8>
ffffffffc020402e:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc0204030:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204032:	f0d4                	sd	a3,160(s1)
    *(proc->tf) = *tf;
ffffffffc0204034:	87b6                	mv	a5,a3
ffffffffc0204036:	12040893          	addi	a7,s0,288
ffffffffc020403a:	00063803          	ld	a6,0(a2)
ffffffffc020403e:	6608                	ld	a0,8(a2)
ffffffffc0204040:	6a0c                	ld	a1,16(a2)
ffffffffc0204042:	6e18                	ld	a4,24(a2)
ffffffffc0204044:	0107b023          	sd	a6,0(a5)
ffffffffc0204048:	e788                	sd	a0,8(a5)
ffffffffc020404a:	eb8c                	sd	a1,16(a5)
ffffffffc020404c:	ef98                	sd	a4,24(a5)
ffffffffc020404e:	02060613          	addi	a2,a2,32
ffffffffc0204052:	02078793          	addi	a5,a5,32
ffffffffc0204056:	ff1612e3          	bne	a2,a7,ffffffffc020403a <do_fork+0xf2>
    proc->tf->gpr.a0 = 0;
ffffffffc020405a:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x6>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc020405e:	12098763          	beqz	s3,ffffffffc020418c <do_fork+0x244>
    if (++last_pid >= MAX_PID)
ffffffffc0204062:	000a2817          	auipc	a6,0xa2
ffffffffc0204066:	1fe80813          	addi	a6,a6,510 # ffffffffc02a6260 <last_pid.1>
ffffffffc020406a:	00082783          	lw	a5,0(a6)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc020406e:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204072:	00000717          	auipc	a4,0x0
ffffffffc0204076:	d7070713          	addi	a4,a4,-656 # ffffffffc0203de2 <forkret>
    if (++last_pid >= MAX_PID)
ffffffffc020407a:	0017851b          	addiw	a0,a5,1
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020407e:	f898                	sd	a4,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0204080:	fc94                	sd	a3,56(s1)
    if (++last_pid >= MAX_PID)
ffffffffc0204082:	00a82023          	sw	a0,0(a6)
ffffffffc0204086:	6789                	lui	a5,0x2
ffffffffc0204088:	08f55b63          	bge	a0,a5,ffffffffc020411e <do_fork+0x1d6>
    if (last_pid >= next_safe)
ffffffffc020408c:	000a2317          	auipc	t1,0xa2
ffffffffc0204090:	1d830313          	addi	t1,t1,472 # ffffffffc02a6264 <next_safe.0>
ffffffffc0204094:	00032783          	lw	a5,0(t1)
ffffffffc0204098:	000a6417          	auipc	s0,0xa6
ffffffffc020409c:	5e840413          	addi	s0,s0,1512 # ffffffffc02aa680 <proc_list>
ffffffffc02040a0:	08f55763          	bge	a0,a5,ffffffffc020412e <do_fork+0x1e6>
    proc->pid = get_pid();           // 分配唯一 PID
ffffffffc02040a4:	c0c8                	sw	a0,4(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02040a6:	45a9                	li	a1,10
ffffffffc02040a8:	2501                	sext.w	a0,a0
ffffffffc02040aa:	0ba010ef          	jal	ra,ffffffffc0205164 <hash32>
ffffffffc02040ae:	02051793          	slli	a5,a0,0x20
ffffffffc02040b2:	01c7d513          	srli	a0,a5,0x1c
ffffffffc02040b6:	000a2797          	auipc	a5,0xa2
ffffffffc02040ba:	5ca78793          	addi	a5,a5,1482 # ffffffffc02a6680 <hash_list>
ffffffffc02040be:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc02040c0:	650c                	ld	a1,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02040c2:	7094                	ld	a3,32(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02040c4:	0d848793          	addi	a5,s1,216
    prev->next = next->prev = elm;
ffffffffc02040c8:	e19c                	sd	a5,0(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc02040ca:	6410                	ld	a2,8(s0)
    prev->next = next->prev = elm;
ffffffffc02040cc:	e51c                	sd	a5,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02040ce:	7af8                	ld	a4,240(a3)
    list_add(&proc_list, &(proc->list_link));
ffffffffc02040d0:	0c848793          	addi	a5,s1,200
    elm->next = next;
ffffffffc02040d4:	f0ec                	sd	a1,224(s1)
    elm->prev = prev;
ffffffffc02040d6:	ece8                	sd	a0,216(s1)
    prev->next = next->prev = elm;
ffffffffc02040d8:	e21c                	sd	a5,0(a2)
ffffffffc02040da:	e41c                	sd	a5,8(s0)
    elm->next = next;
ffffffffc02040dc:	e8f0                	sd	a2,208(s1)
    elm->prev = prev;
ffffffffc02040de:	e4e0                	sd	s0,200(s1)
    proc->yptr = NULL;
ffffffffc02040e0:	0e04bc23          	sd	zero,248(s1)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02040e4:	10e4b023          	sd	a4,256(s1)
ffffffffc02040e8:	c311                	beqz	a4,ffffffffc02040ec <do_fork+0x1a4>
        proc->optr->yptr = proc;
ffffffffc02040ea:	ff64                	sd	s1,248(a4)
    nr_process++;
ffffffffc02040ec:	00092783          	lw	a5,0(s2)
    wakeup_proc(proc);
ffffffffc02040f0:	8526                	mv	a0,s1
    proc->parent->cptr = proc;
ffffffffc02040f2:	fae4                	sd	s1,240(a3)
    nr_process++;
ffffffffc02040f4:	2785                	addiw	a5,a5,1
ffffffffc02040f6:	00f92023          	sw	a5,0(s2)
    wakeup_proc(proc);
ffffffffc02040fa:	67f000ef          	jal	ra,ffffffffc0204f78 <wakeup_proc>
    ret = proc->pid;
ffffffffc02040fe:	40c8                	lw	a0,4(s1)
}
ffffffffc0204100:	70e6                	ld	ra,120(sp)
ffffffffc0204102:	7446                	ld	s0,112(sp)
ffffffffc0204104:	74a6                	ld	s1,104(sp)
ffffffffc0204106:	7906                	ld	s2,96(sp)
ffffffffc0204108:	69e6                	ld	s3,88(sp)
ffffffffc020410a:	6a46                	ld	s4,80(sp)
ffffffffc020410c:	6aa6                	ld	s5,72(sp)
ffffffffc020410e:	6b06                	ld	s6,64(sp)
ffffffffc0204110:	7be2                	ld	s7,56(sp)
ffffffffc0204112:	7c42                	ld	s8,48(sp)
ffffffffc0204114:	7ca2                	ld	s9,40(sp)
ffffffffc0204116:	7d02                	ld	s10,32(sp)
ffffffffc0204118:	6de2                	ld	s11,24(sp)
ffffffffc020411a:	6109                	addi	sp,sp,128
ffffffffc020411c:	8082                	ret
        last_pid = 1;
ffffffffc020411e:	4785                	li	a5,1
ffffffffc0204120:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc0204124:	4505                	li	a0,1
ffffffffc0204126:	000a2317          	auipc	t1,0xa2
ffffffffc020412a:	13e30313          	addi	t1,t1,318 # ffffffffc02a6264 <next_safe.0>
    return listelm->next;
ffffffffc020412e:	000a6417          	auipc	s0,0xa6
ffffffffc0204132:	55240413          	addi	s0,s0,1362 # ffffffffc02aa680 <proc_list>
ffffffffc0204136:	00843e03          	ld	t3,8(s0)
        next_safe = MAX_PID;
ffffffffc020413a:	6789                	lui	a5,0x2
ffffffffc020413c:	00f32023          	sw	a5,0(t1)
ffffffffc0204140:	86aa                	mv	a3,a0
ffffffffc0204142:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc0204144:	6e89                	lui	t4,0x2
ffffffffc0204146:	108e0d63          	beq	t3,s0,ffffffffc0204260 <do_fork+0x318>
ffffffffc020414a:	88ae                	mv	a7,a1
ffffffffc020414c:	87f2                	mv	a5,t3
ffffffffc020414e:	6609                	lui	a2,0x2
ffffffffc0204150:	a811                	j	ffffffffc0204164 <do_fork+0x21c>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc0204152:	00e6d663          	bge	a3,a4,ffffffffc020415e <do_fork+0x216>
ffffffffc0204156:	00c75463          	bge	a4,a2,ffffffffc020415e <do_fork+0x216>
ffffffffc020415a:	863a                	mv	a2,a4
ffffffffc020415c:	4885                	li	a7,1
ffffffffc020415e:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204160:	00878d63          	beq	a5,s0,ffffffffc020417a <do_fork+0x232>
            if (proc->pid == last_pid)
ffffffffc0204164:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_faultread_out_size-0x7c6c>
ffffffffc0204168:	fed715e3          	bne	a4,a3,ffffffffc0204152 <do_fork+0x20a>
                if (++last_pid >= next_safe)
ffffffffc020416c:	2685                	addiw	a3,a3,1
ffffffffc020416e:	0ec6d463          	bge	a3,a2,ffffffffc0204256 <do_fork+0x30e>
ffffffffc0204172:	679c                	ld	a5,8(a5)
ffffffffc0204174:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc0204176:	fe8797e3          	bne	a5,s0,ffffffffc0204164 <do_fork+0x21c>
ffffffffc020417a:	c581                	beqz	a1,ffffffffc0204182 <do_fork+0x23a>
ffffffffc020417c:	00d82023          	sw	a3,0(a6)
ffffffffc0204180:	8536                	mv	a0,a3
ffffffffc0204182:	f20881e3          	beqz	a7,ffffffffc02040a4 <do_fork+0x15c>
ffffffffc0204186:	00c32023          	sw	a2,0(t1)
ffffffffc020418a:	bf29                	j	ffffffffc02040a4 <do_fork+0x15c>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc020418c:	89b6                	mv	s3,a3
ffffffffc020418e:	bdd1                	j	ffffffffc0204062 <do_fork+0x11a>
    if ((mm = mm_create()) == NULL)
ffffffffc0204190:	cceff0ef          	jal	ra,ffffffffc020365e <mm_create>
ffffffffc0204194:	8caa                	mv	s9,a0
ffffffffc0204196:	c159                	beqz	a0,ffffffffc020421c <do_fork+0x2d4>
    if ((page = alloc_page()) == NULL)
ffffffffc0204198:	4505                	li	a0,1
ffffffffc020419a:	cc3fd0ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
ffffffffc020419e:	cd25                	beqz	a0,ffffffffc0204216 <do_fork+0x2ce>
    return page - pages + nbase;
ffffffffc02041a0:	000ab683          	ld	a3,0(s5)
ffffffffc02041a4:	67a2                	ld	a5,8(sp)
    return KADDR(page2pa(page));
ffffffffc02041a6:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc02041aa:	40d506b3          	sub	a3,a0,a3
ffffffffc02041ae:	8699                	srai	a3,a3,0x6
ffffffffc02041b0:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc02041b2:	01b6fdb3          	and	s11,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc02041b6:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02041b8:	0eedf663          	bgeu	s11,a4,ffffffffc02042a4 <do_fork+0x35c>
ffffffffc02041bc:	000c3a03          	ld	s4,0(s8)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc02041c0:	6605                	lui	a2,0x1
ffffffffc02041c2:	000a6597          	auipc	a1,0xa6
ffffffffc02041c6:	5065b583          	ld	a1,1286(a1) # ffffffffc02aa6c8 <boot_pgdir_va>
ffffffffc02041ca:	9a36                	add	s4,s4,a3
ffffffffc02041cc:	8552                	mv	a0,s4
ffffffffc02041ce:	44e010ef          	jal	ra,ffffffffc020561c <memcpy>
static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        lock(&(mm->mm_lock));
ffffffffc02041d2:	038d0d93          	addi	s11,s10,56
    mm->pgdir = pgdir;
ffffffffc02041d6:	014cbc23          	sd	s4,24(s9)
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02041da:	4785                	li	a5,1
ffffffffc02041dc:	40fdb7af          	amoor.d	a5,a5,(s11)
}

static inline void
lock(lock_t *lock)
{
    while (!try_lock(lock))
ffffffffc02041e0:	8b85                	andi	a5,a5,1
ffffffffc02041e2:	4a05                	li	s4,1
ffffffffc02041e4:	c799                	beqz	a5,ffffffffc02041f2 <do_fork+0x2aa>
    {
        schedule();
ffffffffc02041e6:	613000ef          	jal	ra,ffffffffc0204ff8 <schedule>
ffffffffc02041ea:	414db7af          	amoor.d	a5,s4,(s11)
    while (!try_lock(lock))
ffffffffc02041ee:	8b85                	andi	a5,a5,1
ffffffffc02041f0:	fbfd                	bnez	a5,ffffffffc02041e6 <do_fork+0x29e>
        ret = dup_mmap(mm, oldmm);
ffffffffc02041f2:	85ea                	mv	a1,s10
ffffffffc02041f4:	8566                	mv	a0,s9
ffffffffc02041f6:	eaaff0ef          	jal	ra,ffffffffc02038a0 <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02041fa:	57f9                	li	a5,-2
ffffffffc02041fc:	60fdb7af          	amoand.d	a5,a5,(s11)
ffffffffc0204200:	8b85                	andi	a5,a5,1
}

static inline void
unlock(lock_t *lock)
{
    if (!test_and_clear_bit(0, lock))
ffffffffc0204202:	cbad                	beqz	a5,ffffffffc0204274 <do_fork+0x32c>
good_mm:
ffffffffc0204204:	8d66                	mv	s10,s9
    if (ret != 0)
ffffffffc0204206:	de050fe3          	beqz	a0,ffffffffc0204004 <do_fork+0xbc>
    exit_mmap(mm);
ffffffffc020420a:	8566                	mv	a0,s9
ffffffffc020420c:	f2eff0ef          	jal	ra,ffffffffc020393a <exit_mmap>
    put_pgdir(mm);
ffffffffc0204210:	8566                	mv	a0,s9
ffffffffc0204212:	c5dff0ef          	jal	ra,ffffffffc0203e6e <put_pgdir>
    mm_destroy(mm);
ffffffffc0204216:	8566                	mv	a0,s9
ffffffffc0204218:	d86ff0ef          	jal	ra,ffffffffc020379e <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc020421c:	6894                	ld	a3,16(s1)
    return pa2page(PADDR(kva));
ffffffffc020421e:	c02007b7          	lui	a5,0xc0200
ffffffffc0204222:	0af6ea63          	bltu	a3,a5,ffffffffc02042d6 <do_fork+0x38e>
ffffffffc0204226:	000c3783          	ld	a5,0(s8)
    if (PPN(pa) >= npage)
ffffffffc020422a:	000bb703          	ld	a4,0(s7)
    return pa2page(PADDR(kva));
ffffffffc020422e:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage)
ffffffffc0204232:	83b1                	srli	a5,a5,0xc
ffffffffc0204234:	04e7fc63          	bgeu	a5,a4,ffffffffc020428c <do_fork+0x344>
    return &pages[PPN(pa) - nbase];
ffffffffc0204238:	000b3703          	ld	a4,0(s6)
ffffffffc020423c:	000ab503          	ld	a0,0(s5)
ffffffffc0204240:	4589                	li	a1,2
ffffffffc0204242:	8f99                	sub	a5,a5,a4
ffffffffc0204244:	079a                	slli	a5,a5,0x6
ffffffffc0204246:	953e                	add	a0,a0,a5
ffffffffc0204248:	c53fd0ef          	jal	ra,ffffffffc0201e9a <free_pages>
    kfree(proc);
ffffffffc020424c:	8526                	mv	a0,s1
ffffffffc020424e:	ae1fd0ef          	jal	ra,ffffffffc0201d2e <kfree>
    ret = -E_NO_MEM;
ffffffffc0204252:	5571                	li	a0,-4
    return ret;
ffffffffc0204254:	b575                	j	ffffffffc0204100 <do_fork+0x1b8>
                    if (last_pid >= MAX_PID)
ffffffffc0204256:	01d6c363          	blt	a3,t4,ffffffffc020425c <do_fork+0x314>
                        last_pid = 1;
ffffffffc020425a:	4685                	li	a3,1
                    goto repeat;
ffffffffc020425c:	4585                	li	a1,1
ffffffffc020425e:	b5e5                	j	ffffffffc0204146 <do_fork+0x1fe>
ffffffffc0204260:	c599                	beqz	a1,ffffffffc020426e <do_fork+0x326>
ffffffffc0204262:	00d82023          	sw	a3,0(a6)
    return last_pid;
ffffffffc0204266:	8536                	mv	a0,a3
ffffffffc0204268:	bd35                	j	ffffffffc02040a4 <do_fork+0x15c>
    int ret = -E_NO_FREE_PROC;
ffffffffc020426a:	556d                	li	a0,-5
ffffffffc020426c:	bd51                	j	ffffffffc0204100 <do_fork+0x1b8>
    return last_pid;
ffffffffc020426e:	00082503          	lw	a0,0(a6)
ffffffffc0204272:	bd0d                	j	ffffffffc02040a4 <do_fork+0x15c>
    {
        panic("Unlock failed.\n");
ffffffffc0204274:	00003617          	auipc	a2,0x3
ffffffffc0204278:	c6c60613          	addi	a2,a2,-916 # ffffffffc0206ee0 <default_pmm_manager+0xa78>
ffffffffc020427c:	03f00593          	li	a1,63
ffffffffc0204280:	00003517          	auipc	a0,0x3
ffffffffc0204284:	c7050513          	addi	a0,a0,-912 # ffffffffc0206ef0 <default_pmm_manager+0xa88>
ffffffffc0204288:	a06fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020428c:	00002617          	auipc	a2,0x2
ffffffffc0204290:	2e460613          	addi	a2,a2,740 # ffffffffc0206570 <default_pmm_manager+0x108>
ffffffffc0204294:	06900593          	li	a1,105
ffffffffc0204298:	00002517          	auipc	a0,0x2
ffffffffc020429c:	23050513          	addi	a0,a0,560 # ffffffffc02064c8 <default_pmm_manager+0x60>
ffffffffc02042a0:	9eefc0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc02042a4:	00002617          	auipc	a2,0x2
ffffffffc02042a8:	1fc60613          	addi	a2,a2,508 # ffffffffc02064a0 <default_pmm_manager+0x38>
ffffffffc02042ac:	07100593          	li	a1,113
ffffffffc02042b0:	00002517          	auipc	a0,0x2
ffffffffc02042b4:	21850513          	addi	a0,a0,536 # ffffffffc02064c8 <default_pmm_manager+0x60>
ffffffffc02042b8:	9d6fc0ef          	jal	ra,ffffffffc020048e <__panic>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02042bc:	86be                	mv	a3,a5
ffffffffc02042be:	00002617          	auipc	a2,0x2
ffffffffc02042c2:	28a60613          	addi	a2,a2,650 # ffffffffc0206548 <default_pmm_manager+0xe0>
ffffffffc02042c6:	18b00593          	li	a1,395
ffffffffc02042ca:	00003517          	auipc	a0,0x3
ffffffffc02042ce:	bfe50513          	addi	a0,a0,-1026 # ffffffffc0206ec8 <default_pmm_manager+0xa60>
ffffffffc02042d2:	9bcfc0ef          	jal	ra,ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc02042d6:	00002617          	auipc	a2,0x2
ffffffffc02042da:	27260613          	addi	a2,a2,626 # ffffffffc0206548 <default_pmm_manager+0xe0>
ffffffffc02042de:	07700593          	li	a1,119
ffffffffc02042e2:	00002517          	auipc	a0,0x2
ffffffffc02042e6:	1e650513          	addi	a0,a0,486 # ffffffffc02064c8 <default_pmm_manager+0x60>
ffffffffc02042ea:	9a4fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02042ee <kernel_thread>:
{
ffffffffc02042ee:	7129                	addi	sp,sp,-320
ffffffffc02042f0:	fa22                	sd	s0,304(sp)
ffffffffc02042f2:	f626                	sd	s1,296(sp)
ffffffffc02042f4:	f24a                	sd	s2,288(sp)
ffffffffc02042f6:	84ae                	mv	s1,a1
ffffffffc02042f8:	892a                	mv	s2,a0
ffffffffc02042fa:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02042fc:	4581                	li	a1,0
ffffffffc02042fe:	12000613          	li	a2,288
ffffffffc0204302:	850a                	mv	a0,sp
{
ffffffffc0204304:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0204306:	304010ef          	jal	ra,ffffffffc020560a <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc020430a:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc020430c:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc020430e:	100027f3          	csrr	a5,sstatus
ffffffffc0204312:	edd7f793          	andi	a5,a5,-291
ffffffffc0204316:	1207e793          	ori	a5,a5,288
ffffffffc020431a:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020431c:	860a                	mv	a2,sp
ffffffffc020431e:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0204322:	00000797          	auipc	a5,0x0
ffffffffc0204326:	a4678793          	addi	a5,a5,-1466 # ffffffffc0203d68 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020432a:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc020432c:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020432e:	c1bff0ef          	jal	ra,ffffffffc0203f48 <do_fork>
}
ffffffffc0204332:	70f2                	ld	ra,312(sp)
ffffffffc0204334:	7452                	ld	s0,304(sp)
ffffffffc0204336:	74b2                	ld	s1,296(sp)
ffffffffc0204338:	7912                	ld	s2,288(sp)
ffffffffc020433a:	6131                	addi	sp,sp,320
ffffffffc020433c:	8082                	ret

ffffffffc020433e <do_exit>:
{
ffffffffc020433e:	7179                	addi	sp,sp,-48
ffffffffc0204340:	f022                	sd	s0,32(sp)
    if (current == idleproc)
ffffffffc0204342:	000a6417          	auipc	s0,0xa6
ffffffffc0204346:	3ae40413          	addi	s0,s0,942 # ffffffffc02aa6f0 <current>
ffffffffc020434a:	601c                	ld	a5,0(s0)
{
ffffffffc020434c:	f406                	sd	ra,40(sp)
ffffffffc020434e:	ec26                	sd	s1,24(sp)
ffffffffc0204350:	e84a                	sd	s2,16(sp)
ffffffffc0204352:	e44e                	sd	s3,8(sp)
ffffffffc0204354:	e052                	sd	s4,0(sp)
    if (current == idleproc)
ffffffffc0204356:	000a6717          	auipc	a4,0xa6
ffffffffc020435a:	3a273703          	ld	a4,930(a4) # ffffffffc02aa6f8 <idleproc>
ffffffffc020435e:	0ce78c63          	beq	a5,a4,ffffffffc0204436 <do_exit+0xf8>
    if (current == initproc)
ffffffffc0204362:	000a6497          	auipc	s1,0xa6
ffffffffc0204366:	39e48493          	addi	s1,s1,926 # ffffffffc02aa700 <initproc>
ffffffffc020436a:	6098                	ld	a4,0(s1)
ffffffffc020436c:	0ee78b63          	beq	a5,a4,ffffffffc0204462 <do_exit+0x124>
    struct mm_struct *mm = current->mm;
ffffffffc0204370:	0287b983          	ld	s3,40(a5)
ffffffffc0204374:	892a                	mv	s2,a0
    if (mm != NULL)
ffffffffc0204376:	02098663          	beqz	s3,ffffffffc02043a2 <do_exit+0x64>
ffffffffc020437a:	000a6797          	auipc	a5,0xa6
ffffffffc020437e:	3467b783          	ld	a5,838(a5) # ffffffffc02aa6c0 <boot_pgdir_pa>
ffffffffc0204382:	577d                	li	a4,-1
ffffffffc0204384:	177e                	slli	a4,a4,0x3f
ffffffffc0204386:	83b1                	srli	a5,a5,0xc
ffffffffc0204388:	8fd9                	or	a5,a5,a4
ffffffffc020438a:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc020438e:	0309a783          	lw	a5,48(s3)
ffffffffc0204392:	fff7871b          	addiw	a4,a5,-1
ffffffffc0204396:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc020439a:	cb55                	beqz	a4,ffffffffc020444e <do_exit+0x110>
        current->mm = NULL;
ffffffffc020439c:	601c                	ld	a5,0(s0)
ffffffffc020439e:	0207b423          	sd	zero,40(a5)
    current->state = PROC_ZOMBIE;
ffffffffc02043a2:	601c                	ld	a5,0(s0)
ffffffffc02043a4:	470d                	li	a4,3
ffffffffc02043a6:	c398                	sw	a4,0(a5)
    current->exit_code = error_code;
ffffffffc02043a8:	0f27a423          	sw	s2,232(a5)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02043ac:	100027f3          	csrr	a5,sstatus
ffffffffc02043b0:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02043b2:	4a01                	li	s4,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02043b4:	e3f9                	bnez	a5,ffffffffc020447a <do_exit+0x13c>
        proc = current->parent;
ffffffffc02043b6:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)
ffffffffc02043b8:	800007b7          	lui	a5,0x80000
ffffffffc02043bc:	0785                	addi	a5,a5,1
        proc = current->parent;
ffffffffc02043be:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc02043c0:	0ec52703          	lw	a4,236(a0)
ffffffffc02043c4:	0af70f63          	beq	a4,a5,ffffffffc0204482 <do_exit+0x144>
        while (current->cptr != NULL)
ffffffffc02043c8:	6018                	ld	a4,0(s0)
ffffffffc02043ca:	7b7c                	ld	a5,240(a4)
ffffffffc02043cc:	c3a1                	beqz	a5,ffffffffc020440c <do_exit+0xce>
                if (initproc->wait_state == WT_CHILD)
ffffffffc02043ce:	800009b7          	lui	s3,0x80000
            if (proc->state == PROC_ZOMBIE)
ffffffffc02043d2:	490d                	li	s2,3
                if (initproc->wait_state == WT_CHILD)
ffffffffc02043d4:	0985                	addi	s3,s3,1
ffffffffc02043d6:	a021                	j	ffffffffc02043de <do_exit+0xa0>
        while (current->cptr != NULL)
ffffffffc02043d8:	6018                	ld	a4,0(s0)
ffffffffc02043da:	7b7c                	ld	a5,240(a4)
ffffffffc02043dc:	cb85                	beqz	a5,ffffffffc020440c <do_exit+0xce>
            current->cptr = proc->optr;
ffffffffc02043de:	1007b683          	ld	a3,256(a5) # ffffffff80000100 <_binary_obj___user_exit_out_size+0xffffffff7fff4fe0>
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc02043e2:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc02043e4:	fb74                	sd	a3,240(a4)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc02043e6:	7978                	ld	a4,240(a0)
            proc->yptr = NULL;
ffffffffc02043e8:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc02043ec:	10e7b023          	sd	a4,256(a5)
ffffffffc02043f0:	c311                	beqz	a4,ffffffffc02043f4 <do_exit+0xb6>
                initproc->cptr->yptr = proc;
ffffffffc02043f2:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc02043f4:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc02043f6:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc02043f8:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc02043fa:	fd271fe3          	bne	a4,s2,ffffffffc02043d8 <do_exit+0x9a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc02043fe:	0ec52783          	lw	a5,236(a0)
ffffffffc0204402:	fd379be3          	bne	a5,s3,ffffffffc02043d8 <do_exit+0x9a>
                    wakeup_proc(initproc);
ffffffffc0204406:	373000ef          	jal	ra,ffffffffc0204f78 <wakeup_proc>
ffffffffc020440a:	b7f9                	j	ffffffffc02043d8 <do_exit+0x9a>
    if (flag)
ffffffffc020440c:	020a1263          	bnez	s4,ffffffffc0204430 <do_exit+0xf2>
    schedule();
ffffffffc0204410:	3e9000ef          	jal	ra,ffffffffc0204ff8 <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc0204414:	601c                	ld	a5,0(s0)
ffffffffc0204416:	00003617          	auipc	a2,0x3
ffffffffc020441a:	b1260613          	addi	a2,a2,-1262 # ffffffffc0206f28 <default_pmm_manager+0xac0>
ffffffffc020441e:	23300593          	li	a1,563
ffffffffc0204422:	43d4                	lw	a3,4(a5)
ffffffffc0204424:	00003517          	auipc	a0,0x3
ffffffffc0204428:	aa450513          	addi	a0,a0,-1372 # ffffffffc0206ec8 <default_pmm_manager+0xa60>
ffffffffc020442c:	862fc0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_enable();
ffffffffc0204430:	d7efc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0204434:	bff1                	j	ffffffffc0204410 <do_exit+0xd2>
        panic("idleproc exit.\n");
ffffffffc0204436:	00003617          	auipc	a2,0x3
ffffffffc020443a:	ad260613          	addi	a2,a2,-1326 # ffffffffc0206f08 <default_pmm_manager+0xaa0>
ffffffffc020443e:	1ff00593          	li	a1,511
ffffffffc0204442:	00003517          	auipc	a0,0x3
ffffffffc0204446:	a8650513          	addi	a0,a0,-1402 # ffffffffc0206ec8 <default_pmm_manager+0xa60>
ffffffffc020444a:	844fc0ef          	jal	ra,ffffffffc020048e <__panic>
            exit_mmap(mm);
ffffffffc020444e:	854e                	mv	a0,s3
ffffffffc0204450:	ceaff0ef          	jal	ra,ffffffffc020393a <exit_mmap>
            put_pgdir(mm);
ffffffffc0204454:	854e                	mv	a0,s3
ffffffffc0204456:	a19ff0ef          	jal	ra,ffffffffc0203e6e <put_pgdir>
            mm_destroy(mm);
ffffffffc020445a:	854e                	mv	a0,s3
ffffffffc020445c:	b42ff0ef          	jal	ra,ffffffffc020379e <mm_destroy>
ffffffffc0204460:	bf35                	j	ffffffffc020439c <do_exit+0x5e>
        panic("initproc exit.\n");
ffffffffc0204462:	00003617          	auipc	a2,0x3
ffffffffc0204466:	ab660613          	addi	a2,a2,-1354 # ffffffffc0206f18 <default_pmm_manager+0xab0>
ffffffffc020446a:	20300593          	li	a1,515
ffffffffc020446e:	00003517          	auipc	a0,0x3
ffffffffc0204472:	a5a50513          	addi	a0,a0,-1446 # ffffffffc0206ec8 <default_pmm_manager+0xa60>
ffffffffc0204476:	818fc0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_disable();
ffffffffc020447a:	d3afc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc020447e:	4a05                	li	s4,1
ffffffffc0204480:	bf1d                	j	ffffffffc02043b6 <do_exit+0x78>
            wakeup_proc(proc);
ffffffffc0204482:	2f7000ef          	jal	ra,ffffffffc0204f78 <wakeup_proc>
ffffffffc0204486:	b789                	j	ffffffffc02043c8 <do_exit+0x8a>

ffffffffc0204488 <do_wait.part.0>:
int do_wait(int pid, int *code_store)
ffffffffc0204488:	715d                	addi	sp,sp,-80
ffffffffc020448a:	f84a                	sd	s2,48(sp)
ffffffffc020448c:	f44e                	sd	s3,40(sp)
        current->wait_state = WT_CHILD;
ffffffffc020448e:	80000937          	lui	s2,0x80000
    if (0 < pid && pid < MAX_PID)
ffffffffc0204492:	6989                	lui	s3,0x2
int do_wait(int pid, int *code_store)
ffffffffc0204494:	fc26                	sd	s1,56(sp)
ffffffffc0204496:	f052                	sd	s4,32(sp)
ffffffffc0204498:	ec56                	sd	s5,24(sp)
ffffffffc020449a:	e85a                	sd	s6,16(sp)
ffffffffc020449c:	e45e                	sd	s7,8(sp)
ffffffffc020449e:	e486                	sd	ra,72(sp)
ffffffffc02044a0:	e0a2                	sd	s0,64(sp)
ffffffffc02044a2:	84aa                	mv	s1,a0
ffffffffc02044a4:	8a2e                	mv	s4,a1
        proc = current->cptr;
ffffffffc02044a6:	000a6b97          	auipc	s7,0xa6
ffffffffc02044aa:	24ab8b93          	addi	s7,s7,586 # ffffffffc02aa6f0 <current>
    if (0 < pid && pid < MAX_PID)
ffffffffc02044ae:	00050b1b          	sext.w	s6,a0
ffffffffc02044b2:	fff50a9b          	addiw	s5,a0,-1
ffffffffc02044b6:	19f9                	addi	s3,s3,-2
        current->wait_state = WT_CHILD;
ffffffffc02044b8:	0905                	addi	s2,s2,1
    if (pid != 0)
ffffffffc02044ba:	ccbd                	beqz	s1,ffffffffc0204538 <do_wait.part.0+0xb0>
    if (0 < pid && pid < MAX_PID)
ffffffffc02044bc:	0359e863          	bltu	s3,s5,ffffffffc02044ec <do_wait.part.0+0x64>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc02044c0:	45a9                	li	a1,10
ffffffffc02044c2:	855a                	mv	a0,s6
ffffffffc02044c4:	4a1000ef          	jal	ra,ffffffffc0205164 <hash32>
ffffffffc02044c8:	02051793          	slli	a5,a0,0x20
ffffffffc02044cc:	01c7d513          	srli	a0,a5,0x1c
ffffffffc02044d0:	000a2797          	auipc	a5,0xa2
ffffffffc02044d4:	1b078793          	addi	a5,a5,432 # ffffffffc02a6680 <hash_list>
ffffffffc02044d8:	953e                	add	a0,a0,a5
ffffffffc02044da:	842a                	mv	s0,a0
        while ((le = list_next(le)) != list)
ffffffffc02044dc:	a029                	j	ffffffffc02044e6 <do_wait.part.0+0x5e>
            if (proc->pid == pid)
ffffffffc02044de:	f2c42783          	lw	a5,-212(s0)
ffffffffc02044e2:	02978163          	beq	a5,s1,ffffffffc0204504 <do_wait.part.0+0x7c>
ffffffffc02044e6:	6400                	ld	s0,8(s0)
        while ((le = list_next(le)) != list)
ffffffffc02044e8:	fe851be3          	bne	a0,s0,ffffffffc02044de <do_wait.part.0+0x56>
    return -E_BAD_PROC;
ffffffffc02044ec:	5579                	li	a0,-2
}
ffffffffc02044ee:	60a6                	ld	ra,72(sp)
ffffffffc02044f0:	6406                	ld	s0,64(sp)
ffffffffc02044f2:	74e2                	ld	s1,56(sp)
ffffffffc02044f4:	7942                	ld	s2,48(sp)
ffffffffc02044f6:	79a2                	ld	s3,40(sp)
ffffffffc02044f8:	7a02                	ld	s4,32(sp)
ffffffffc02044fa:	6ae2                	ld	s5,24(sp)
ffffffffc02044fc:	6b42                	ld	s6,16(sp)
ffffffffc02044fe:	6ba2                	ld	s7,8(sp)
ffffffffc0204500:	6161                	addi	sp,sp,80
ffffffffc0204502:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc0204504:	000bb683          	ld	a3,0(s7)
ffffffffc0204508:	f4843783          	ld	a5,-184(s0)
ffffffffc020450c:	fed790e3          	bne	a5,a3,ffffffffc02044ec <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204510:	f2842703          	lw	a4,-216(s0)
ffffffffc0204514:	478d                	li	a5,3
ffffffffc0204516:	0ef70b63          	beq	a4,a5,ffffffffc020460c <do_wait.part.0+0x184>
        current->state = PROC_SLEEPING;
ffffffffc020451a:	4785                	li	a5,1
ffffffffc020451c:	c29c                	sw	a5,0(a3)
        current->wait_state = WT_CHILD;
ffffffffc020451e:	0f26a623          	sw	s2,236(a3)
        schedule();
ffffffffc0204522:	2d7000ef          	jal	ra,ffffffffc0204ff8 <schedule>
        if (current->flags & PF_EXITING)
ffffffffc0204526:	000bb783          	ld	a5,0(s7)
ffffffffc020452a:	0b07a783          	lw	a5,176(a5)
ffffffffc020452e:	8b85                	andi	a5,a5,1
ffffffffc0204530:	d7c9                	beqz	a5,ffffffffc02044ba <do_wait.part.0+0x32>
            do_exit(-E_KILLED);
ffffffffc0204532:	555d                	li	a0,-9
ffffffffc0204534:	e0bff0ef          	jal	ra,ffffffffc020433e <do_exit>
        proc = current->cptr;
ffffffffc0204538:	000bb683          	ld	a3,0(s7)
ffffffffc020453c:	7ae0                	ld	s0,240(a3)
        for (; proc != NULL; proc = proc->optr)
ffffffffc020453e:	d45d                	beqz	s0,ffffffffc02044ec <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204540:	470d                	li	a4,3
ffffffffc0204542:	a021                	j	ffffffffc020454a <do_wait.part.0+0xc2>
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204544:	10043403          	ld	s0,256(s0)
ffffffffc0204548:	d869                	beqz	s0,ffffffffc020451a <do_wait.part.0+0x92>
            if (proc->state == PROC_ZOMBIE)
ffffffffc020454a:	401c                	lw	a5,0(s0)
ffffffffc020454c:	fee79ce3          	bne	a5,a4,ffffffffc0204544 <do_wait.part.0+0xbc>
    if (proc == idleproc || proc == initproc)
ffffffffc0204550:	000a6797          	auipc	a5,0xa6
ffffffffc0204554:	1a87b783          	ld	a5,424(a5) # ffffffffc02aa6f8 <idleproc>
ffffffffc0204558:	0c878963          	beq	a5,s0,ffffffffc020462a <do_wait.part.0+0x1a2>
ffffffffc020455c:	000a6797          	auipc	a5,0xa6
ffffffffc0204560:	1a47b783          	ld	a5,420(a5) # ffffffffc02aa700 <initproc>
ffffffffc0204564:	0cf40363          	beq	s0,a5,ffffffffc020462a <do_wait.part.0+0x1a2>
    if (code_store != NULL)
ffffffffc0204568:	000a0663          	beqz	s4,ffffffffc0204574 <do_wait.part.0+0xec>
        *code_store = proc->exit_code;
ffffffffc020456c:	0e842783          	lw	a5,232(s0)
ffffffffc0204570:	00fa2023          	sw	a5,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8ba8>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204574:	100027f3          	csrr	a5,sstatus
ffffffffc0204578:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020457a:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020457c:	e7c1                	bnez	a5,ffffffffc0204604 <do_wait.part.0+0x17c>
    __list_del(listelm->prev, listelm->next);
ffffffffc020457e:	6c70                	ld	a2,216(s0)
ffffffffc0204580:	7074                	ld	a3,224(s0)
    if (proc->optr != NULL)
ffffffffc0204582:	10043703          	ld	a4,256(s0)
        proc->optr->yptr = proc->yptr;
ffffffffc0204586:	7c7c                	ld	a5,248(s0)
    prev->next = next;
ffffffffc0204588:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc020458a:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc020458c:	6470                	ld	a2,200(s0)
ffffffffc020458e:	6874                	ld	a3,208(s0)
    prev->next = next;
ffffffffc0204590:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0204592:	e290                	sd	a2,0(a3)
    if (proc->optr != NULL)
ffffffffc0204594:	c319                	beqz	a4,ffffffffc020459a <do_wait.part.0+0x112>
        proc->optr->yptr = proc->yptr;
ffffffffc0204596:	ff7c                	sd	a5,248(a4)
    if (proc->yptr != NULL)
ffffffffc0204598:	7c7c                	ld	a5,248(s0)
ffffffffc020459a:	c3b5                	beqz	a5,ffffffffc02045fe <do_wait.part.0+0x176>
        proc->yptr->optr = proc->optr;
ffffffffc020459c:	10e7b023          	sd	a4,256(a5)
    nr_process--;
ffffffffc02045a0:	000a6717          	auipc	a4,0xa6
ffffffffc02045a4:	16870713          	addi	a4,a4,360 # ffffffffc02aa708 <nr_process>
ffffffffc02045a8:	431c                	lw	a5,0(a4)
ffffffffc02045aa:	37fd                	addiw	a5,a5,-1
ffffffffc02045ac:	c31c                	sw	a5,0(a4)
    if (flag)
ffffffffc02045ae:	e5a9                	bnez	a1,ffffffffc02045f8 <do_wait.part.0+0x170>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc02045b0:	6814                	ld	a3,16(s0)
ffffffffc02045b2:	c02007b7          	lui	a5,0xc0200
ffffffffc02045b6:	04f6ee63          	bltu	a3,a5,ffffffffc0204612 <do_wait.part.0+0x18a>
ffffffffc02045ba:	000a6797          	auipc	a5,0xa6
ffffffffc02045be:	12e7b783          	ld	a5,302(a5) # ffffffffc02aa6e8 <va_pa_offset>
ffffffffc02045c2:	8e9d                	sub	a3,a3,a5
    if (PPN(pa) >= npage)
ffffffffc02045c4:	82b1                	srli	a3,a3,0xc
ffffffffc02045c6:	000a6797          	auipc	a5,0xa6
ffffffffc02045ca:	10a7b783          	ld	a5,266(a5) # ffffffffc02aa6d0 <npage>
ffffffffc02045ce:	06f6fa63          	bgeu	a3,a5,ffffffffc0204642 <do_wait.part.0+0x1ba>
    return &pages[PPN(pa) - nbase];
ffffffffc02045d2:	00003517          	auipc	a0,0x3
ffffffffc02045d6:	18e53503          	ld	a0,398(a0) # ffffffffc0207760 <nbase>
ffffffffc02045da:	8e89                	sub	a3,a3,a0
ffffffffc02045dc:	069a                	slli	a3,a3,0x6
ffffffffc02045de:	000a6517          	auipc	a0,0xa6
ffffffffc02045e2:	0fa53503          	ld	a0,250(a0) # ffffffffc02aa6d8 <pages>
ffffffffc02045e6:	9536                	add	a0,a0,a3
ffffffffc02045e8:	4589                	li	a1,2
ffffffffc02045ea:	8b1fd0ef          	jal	ra,ffffffffc0201e9a <free_pages>
    kfree(proc);
ffffffffc02045ee:	8522                	mv	a0,s0
ffffffffc02045f0:	f3efd0ef          	jal	ra,ffffffffc0201d2e <kfree>
    return 0;
ffffffffc02045f4:	4501                	li	a0,0
ffffffffc02045f6:	bde5                	j	ffffffffc02044ee <do_wait.part.0+0x66>
        intr_enable();
ffffffffc02045f8:	bb6fc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02045fc:	bf55                	j	ffffffffc02045b0 <do_wait.part.0+0x128>
        proc->parent->cptr = proc->optr;
ffffffffc02045fe:	701c                	ld	a5,32(s0)
ffffffffc0204600:	fbf8                	sd	a4,240(a5)
ffffffffc0204602:	bf79                	j	ffffffffc02045a0 <do_wait.part.0+0x118>
        intr_disable();
ffffffffc0204604:	bb0fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0204608:	4585                	li	a1,1
ffffffffc020460a:	bf95                	j	ffffffffc020457e <do_wait.part.0+0xf6>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc020460c:	f2840413          	addi	s0,s0,-216
ffffffffc0204610:	b781                	j	ffffffffc0204550 <do_wait.part.0+0xc8>
    return pa2page(PADDR(kva));
ffffffffc0204612:	00002617          	auipc	a2,0x2
ffffffffc0204616:	f3660613          	addi	a2,a2,-202 # ffffffffc0206548 <default_pmm_manager+0xe0>
ffffffffc020461a:	07700593          	li	a1,119
ffffffffc020461e:	00002517          	auipc	a0,0x2
ffffffffc0204622:	eaa50513          	addi	a0,a0,-342 # ffffffffc02064c8 <default_pmm_manager+0x60>
ffffffffc0204626:	e69fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("wait idleproc or initproc.\n");
ffffffffc020462a:	00003617          	auipc	a2,0x3
ffffffffc020462e:	91e60613          	addi	a2,a2,-1762 # ffffffffc0206f48 <default_pmm_manager+0xae0>
ffffffffc0204632:	35300593          	li	a1,851
ffffffffc0204636:	00003517          	auipc	a0,0x3
ffffffffc020463a:	89250513          	addi	a0,a0,-1902 # ffffffffc0206ec8 <default_pmm_manager+0xa60>
ffffffffc020463e:	e51fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204642:	00002617          	auipc	a2,0x2
ffffffffc0204646:	f2e60613          	addi	a2,a2,-210 # ffffffffc0206570 <default_pmm_manager+0x108>
ffffffffc020464a:	06900593          	li	a1,105
ffffffffc020464e:	00002517          	auipc	a0,0x2
ffffffffc0204652:	e7a50513          	addi	a0,a0,-390 # ffffffffc02064c8 <default_pmm_manager+0x60>
ffffffffc0204656:	e39fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020465a <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc020465a:	1141                	addi	sp,sp,-16
ffffffffc020465c:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc020465e:	87dfd0ef          	jal	ra,ffffffffc0201eda <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc0204662:	e18fd0ef          	jal	ra,ffffffffc0201c7a <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc0204666:	4601                	li	a2,0
ffffffffc0204668:	4581                	li	a1,0
ffffffffc020466a:	fffff517          	auipc	a0,0xfffff
ffffffffc020466e:	78650513          	addi	a0,a0,1926 # ffffffffc0203df0 <user_main>
ffffffffc0204672:	c7dff0ef          	jal	ra,ffffffffc02042ee <kernel_thread>
    if (pid <= 0)
ffffffffc0204676:	00a04563          	bgtz	a0,ffffffffc0204680 <init_main+0x26>
ffffffffc020467a:	a071                	j	ffffffffc0204706 <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0)
    {
        schedule();
ffffffffc020467c:	17d000ef          	jal	ra,ffffffffc0204ff8 <schedule>
    if (code_store != NULL)
ffffffffc0204680:	4581                	li	a1,0
ffffffffc0204682:	4501                	li	a0,0
ffffffffc0204684:	e05ff0ef          	jal	ra,ffffffffc0204488 <do_wait.part.0>
    while (do_wait(0, NULL) == 0)
ffffffffc0204688:	d975                	beqz	a0,ffffffffc020467c <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc020468a:	00003517          	auipc	a0,0x3
ffffffffc020468e:	8fe50513          	addi	a0,a0,-1794 # ffffffffc0206f88 <default_pmm_manager+0xb20>
ffffffffc0204692:	b03fb0ef          	jal	ra,ffffffffc0200194 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204696:	000a6797          	auipc	a5,0xa6
ffffffffc020469a:	06a7b783          	ld	a5,106(a5) # ffffffffc02aa700 <initproc>
ffffffffc020469e:	7bf8                	ld	a4,240(a5)
ffffffffc02046a0:	e339                	bnez	a4,ffffffffc02046e6 <init_main+0x8c>
ffffffffc02046a2:	7ff8                	ld	a4,248(a5)
ffffffffc02046a4:	e329                	bnez	a4,ffffffffc02046e6 <init_main+0x8c>
ffffffffc02046a6:	1007b703          	ld	a4,256(a5)
ffffffffc02046aa:	ef15                	bnez	a4,ffffffffc02046e6 <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc02046ac:	000a6697          	auipc	a3,0xa6
ffffffffc02046b0:	05c6a683          	lw	a3,92(a3) # ffffffffc02aa708 <nr_process>
ffffffffc02046b4:	4709                	li	a4,2
ffffffffc02046b6:	0ae69463          	bne	a3,a4,ffffffffc020475e <init_main+0x104>
    return listelm->next;
ffffffffc02046ba:	000a6697          	auipc	a3,0xa6
ffffffffc02046be:	fc668693          	addi	a3,a3,-58 # ffffffffc02aa680 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc02046c2:	6698                	ld	a4,8(a3)
ffffffffc02046c4:	0c878793          	addi	a5,a5,200
ffffffffc02046c8:	06f71b63          	bne	a4,a5,ffffffffc020473e <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc02046cc:	629c                	ld	a5,0(a3)
ffffffffc02046ce:	04f71863          	bne	a4,a5,ffffffffc020471e <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc02046d2:	00003517          	auipc	a0,0x3
ffffffffc02046d6:	99e50513          	addi	a0,a0,-1634 # ffffffffc0207070 <default_pmm_manager+0xc08>
ffffffffc02046da:	abbfb0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
}
ffffffffc02046de:	60a2                	ld	ra,8(sp)
ffffffffc02046e0:	4501                	li	a0,0
ffffffffc02046e2:	0141                	addi	sp,sp,16
ffffffffc02046e4:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc02046e6:	00003697          	auipc	a3,0x3
ffffffffc02046ea:	8ca68693          	addi	a3,a3,-1846 # ffffffffc0206fb0 <default_pmm_manager+0xb48>
ffffffffc02046ee:	00002617          	auipc	a2,0x2
ffffffffc02046f2:	9ca60613          	addi	a2,a2,-1590 # ffffffffc02060b8 <commands+0x818>
ffffffffc02046f6:	3c100593          	li	a1,961
ffffffffc02046fa:	00002517          	auipc	a0,0x2
ffffffffc02046fe:	7ce50513          	addi	a0,a0,1998 # ffffffffc0206ec8 <default_pmm_manager+0xa60>
ffffffffc0204702:	d8dfb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("create user_main failed.\n");
ffffffffc0204706:	00003617          	auipc	a2,0x3
ffffffffc020470a:	86260613          	addi	a2,a2,-1950 # ffffffffc0206f68 <default_pmm_manager+0xb00>
ffffffffc020470e:	3b800593          	li	a1,952
ffffffffc0204712:	00002517          	auipc	a0,0x2
ffffffffc0204716:	7b650513          	addi	a0,a0,1974 # ffffffffc0206ec8 <default_pmm_manager+0xa60>
ffffffffc020471a:	d75fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc020471e:	00003697          	auipc	a3,0x3
ffffffffc0204722:	92268693          	addi	a3,a3,-1758 # ffffffffc0207040 <default_pmm_manager+0xbd8>
ffffffffc0204726:	00002617          	auipc	a2,0x2
ffffffffc020472a:	99260613          	addi	a2,a2,-1646 # ffffffffc02060b8 <commands+0x818>
ffffffffc020472e:	3c400593          	li	a1,964
ffffffffc0204732:	00002517          	auipc	a0,0x2
ffffffffc0204736:	79650513          	addi	a0,a0,1942 # ffffffffc0206ec8 <default_pmm_manager+0xa60>
ffffffffc020473a:	d55fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc020473e:	00003697          	auipc	a3,0x3
ffffffffc0204742:	8d268693          	addi	a3,a3,-1838 # ffffffffc0207010 <default_pmm_manager+0xba8>
ffffffffc0204746:	00002617          	auipc	a2,0x2
ffffffffc020474a:	97260613          	addi	a2,a2,-1678 # ffffffffc02060b8 <commands+0x818>
ffffffffc020474e:	3c300593          	li	a1,963
ffffffffc0204752:	00002517          	auipc	a0,0x2
ffffffffc0204756:	77650513          	addi	a0,a0,1910 # ffffffffc0206ec8 <default_pmm_manager+0xa60>
ffffffffc020475a:	d35fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_process == 2);
ffffffffc020475e:	00003697          	auipc	a3,0x3
ffffffffc0204762:	8a268693          	addi	a3,a3,-1886 # ffffffffc0207000 <default_pmm_manager+0xb98>
ffffffffc0204766:	00002617          	auipc	a2,0x2
ffffffffc020476a:	95260613          	addi	a2,a2,-1710 # ffffffffc02060b8 <commands+0x818>
ffffffffc020476e:	3c200593          	li	a1,962
ffffffffc0204772:	00002517          	auipc	a0,0x2
ffffffffc0204776:	75650513          	addi	a0,a0,1878 # ffffffffc0206ec8 <default_pmm_manager+0xa60>
ffffffffc020477a:	d15fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020477e <do_execve>:
{
ffffffffc020477e:	7171                	addi	sp,sp,-176
ffffffffc0204780:	e4ee                	sd	s11,72(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204782:	000a6d97          	auipc	s11,0xa6
ffffffffc0204786:	f6ed8d93          	addi	s11,s11,-146 # ffffffffc02aa6f0 <current>
ffffffffc020478a:	000db783          	ld	a5,0(s11)
{
ffffffffc020478e:	e54e                	sd	s3,136(sp)
ffffffffc0204790:	ed26                	sd	s1,152(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204792:	0287b983          	ld	s3,40(a5)
{
ffffffffc0204796:	e94a                	sd	s2,144(sp)
ffffffffc0204798:	f4de                	sd	s7,104(sp)
ffffffffc020479a:	892a                	mv	s2,a0
ffffffffc020479c:	8bb2                	mv	s7,a2
ffffffffc020479e:	84ae                	mv	s1,a1
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc02047a0:	862e                	mv	a2,a1
ffffffffc02047a2:	4681                	li	a3,0
ffffffffc02047a4:	85aa                	mv	a1,a0
ffffffffc02047a6:	854e                	mv	a0,s3
{
ffffffffc02047a8:	f506                	sd	ra,168(sp)
ffffffffc02047aa:	f122                	sd	s0,160(sp)
ffffffffc02047ac:	e152                	sd	s4,128(sp)
ffffffffc02047ae:	fcd6                	sd	s5,120(sp)
ffffffffc02047b0:	f8da                	sd	s6,112(sp)
ffffffffc02047b2:	f0e2                	sd	s8,96(sp)
ffffffffc02047b4:	ece6                	sd	s9,88(sp)
ffffffffc02047b6:	e8ea                	sd	s10,80(sp)
ffffffffc02047b8:	f05e                	sd	s7,32(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc02047ba:	d1aff0ef          	jal	ra,ffffffffc0203cd4 <user_mem_check>
ffffffffc02047be:	40050a63          	beqz	a0,ffffffffc0204bd2 <do_execve+0x454>
    memset(local_name, 0, sizeof(local_name));
ffffffffc02047c2:	4641                	li	a2,16
ffffffffc02047c4:	4581                	li	a1,0
ffffffffc02047c6:	1808                	addi	a0,sp,48
ffffffffc02047c8:	643000ef          	jal	ra,ffffffffc020560a <memset>
    memcpy(local_name, name, len);
ffffffffc02047cc:	47bd                	li	a5,15
ffffffffc02047ce:	8626                	mv	a2,s1
ffffffffc02047d0:	1e97e263          	bltu	a5,s1,ffffffffc02049b4 <do_execve+0x236>
ffffffffc02047d4:	85ca                	mv	a1,s2
ffffffffc02047d6:	1808                	addi	a0,sp,48
ffffffffc02047d8:	645000ef          	jal	ra,ffffffffc020561c <memcpy>
    if (mm != NULL)
ffffffffc02047dc:	1e098363          	beqz	s3,ffffffffc02049c2 <do_execve+0x244>
        cputs("mm != NULL");
ffffffffc02047e0:	00002517          	auipc	a0,0x2
ffffffffc02047e4:	4a850513          	addi	a0,a0,1192 # ffffffffc0206c88 <default_pmm_manager+0x820>
ffffffffc02047e8:	9e5fb0ef          	jal	ra,ffffffffc02001cc <cputs>
ffffffffc02047ec:	000a6797          	auipc	a5,0xa6
ffffffffc02047f0:	ed47b783          	ld	a5,-300(a5) # ffffffffc02aa6c0 <boot_pgdir_pa>
ffffffffc02047f4:	577d                	li	a4,-1
ffffffffc02047f6:	177e                	slli	a4,a4,0x3f
ffffffffc02047f8:	83b1                	srli	a5,a5,0xc
ffffffffc02047fa:	8fd9                	or	a5,a5,a4
ffffffffc02047fc:	18079073          	csrw	satp,a5
ffffffffc0204800:	0309a783          	lw	a5,48(s3) # 2030 <_binary_obj___user_faultread_out_size-0x7b78>
ffffffffc0204804:	fff7871b          	addiw	a4,a5,-1
ffffffffc0204808:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc020480c:	2c070463          	beqz	a4,ffffffffc0204ad4 <do_execve+0x356>
        current->mm = NULL;
ffffffffc0204810:	000db783          	ld	a5,0(s11)
ffffffffc0204814:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc0204818:	e47fe0ef          	jal	ra,ffffffffc020365e <mm_create>
ffffffffc020481c:	84aa                	mv	s1,a0
ffffffffc020481e:	1c050d63          	beqz	a0,ffffffffc02049f8 <do_execve+0x27a>
    if ((page = alloc_page()) == NULL)
ffffffffc0204822:	4505                	li	a0,1
ffffffffc0204824:	e38fd0ef          	jal	ra,ffffffffc0201e5c <alloc_pages>
ffffffffc0204828:	3a050963          	beqz	a0,ffffffffc0204bda <do_execve+0x45c>
    return page - pages + nbase;
ffffffffc020482c:	000a6c97          	auipc	s9,0xa6
ffffffffc0204830:	eacc8c93          	addi	s9,s9,-340 # ffffffffc02aa6d8 <pages>
ffffffffc0204834:	000cb683          	ld	a3,0(s9)
    return KADDR(page2pa(page));
ffffffffc0204838:	000a6c17          	auipc	s8,0xa6
ffffffffc020483c:	e98c0c13          	addi	s8,s8,-360 # ffffffffc02aa6d0 <npage>
    return page - pages + nbase;
ffffffffc0204840:	00003717          	auipc	a4,0x3
ffffffffc0204844:	f2073703          	ld	a4,-224(a4) # ffffffffc0207760 <nbase>
ffffffffc0204848:	40d506b3          	sub	a3,a0,a3
ffffffffc020484c:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc020484e:	5afd                	li	s5,-1
ffffffffc0204850:	000c3783          	ld	a5,0(s8)
    return page - pages + nbase;
ffffffffc0204854:	96ba                	add	a3,a3,a4
ffffffffc0204856:	e83a                	sd	a4,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204858:	00cad713          	srli	a4,s5,0xc
ffffffffc020485c:	ec3a                	sd	a4,24(sp)
ffffffffc020485e:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204860:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204862:	38f77063          	bgeu	a4,a5,ffffffffc0204be2 <do_execve+0x464>
ffffffffc0204866:	000a6b17          	auipc	s6,0xa6
ffffffffc020486a:	e82b0b13          	addi	s6,s6,-382 # ffffffffc02aa6e8 <va_pa_offset>
ffffffffc020486e:	000b3903          	ld	s2,0(s6)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc0204872:	6605                	lui	a2,0x1
ffffffffc0204874:	000a6597          	auipc	a1,0xa6
ffffffffc0204878:	e545b583          	ld	a1,-428(a1) # ffffffffc02aa6c8 <boot_pgdir_va>
ffffffffc020487c:	9936                	add	s2,s2,a3
ffffffffc020487e:	854a                	mv	a0,s2
ffffffffc0204880:	59d000ef          	jal	ra,ffffffffc020561c <memcpy>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204884:	7782                	ld	a5,32(sp)
ffffffffc0204886:	4398                	lw	a4,0(a5)
ffffffffc0204888:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc020488c:	0124bc23          	sd	s2,24(s1)
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204890:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_exit_out_size+0x464b945f>
ffffffffc0204894:	14f71863          	bne	a4,a5,ffffffffc02049e4 <do_execve+0x266>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204898:	7682                	ld	a3,32(sp)
ffffffffc020489a:	0386d703          	lhu	a4,56(a3)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc020489e:	0206b983          	ld	s3,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc02048a2:	00371793          	slli	a5,a4,0x3
ffffffffc02048a6:	8f99                	sub	a5,a5,a4
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc02048a8:	99b6                	add	s3,s3,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc02048aa:	078e                	slli	a5,a5,0x3
ffffffffc02048ac:	97ce                	add	a5,a5,s3
ffffffffc02048ae:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++)
ffffffffc02048b0:	00f9fc63          	bgeu	s3,a5,ffffffffc02048c8 <do_execve+0x14a>
        if (ph->p_type != ELF_PT_LOAD)
ffffffffc02048b4:	0009a783          	lw	a5,0(s3)
ffffffffc02048b8:	4705                	li	a4,1
ffffffffc02048ba:	14e78163          	beq	a5,a4,ffffffffc02049fc <do_execve+0x27e>
    for (; ph < ph_end; ph++)
ffffffffc02048be:	77a2                	ld	a5,40(sp)
ffffffffc02048c0:	03898993          	addi	s3,s3,56
ffffffffc02048c4:	fef9e8e3          	bltu	s3,a5,ffffffffc02048b4 <do_execve+0x136>
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc02048c8:	4701                	li	a4,0
ffffffffc02048ca:	46ad                	li	a3,11
ffffffffc02048cc:	00100637          	lui	a2,0x100
ffffffffc02048d0:	7ff005b7          	lui	a1,0x7ff00
ffffffffc02048d4:	8526                	mv	a0,s1
ffffffffc02048d6:	f1bfe0ef          	jal	ra,ffffffffc02037f0 <mm_map>
ffffffffc02048da:	8a2a                	mv	s4,a0
ffffffffc02048dc:	1e051263          	bnez	a0,ffffffffc0204ac0 <do_execve+0x342>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc02048e0:	6c88                	ld	a0,24(s1)
ffffffffc02048e2:	467d                	li	a2,31
ffffffffc02048e4:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc02048e8:	c91fe0ef          	jal	ra,ffffffffc0203578 <pgdir_alloc_page>
ffffffffc02048ec:	38050363          	beqz	a0,ffffffffc0204c72 <do_execve+0x4f4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc02048f0:	6c88                	ld	a0,24(s1)
ffffffffc02048f2:	467d                	li	a2,31
ffffffffc02048f4:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc02048f8:	c81fe0ef          	jal	ra,ffffffffc0203578 <pgdir_alloc_page>
ffffffffc02048fc:	34050b63          	beqz	a0,ffffffffc0204c52 <do_execve+0x4d4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204900:	6c88                	ld	a0,24(s1)
ffffffffc0204902:	467d                	li	a2,31
ffffffffc0204904:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc0204908:	c71fe0ef          	jal	ra,ffffffffc0203578 <pgdir_alloc_page>
ffffffffc020490c:	32050363          	beqz	a0,ffffffffc0204c32 <do_execve+0x4b4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204910:	6c88                	ld	a0,24(s1)
ffffffffc0204912:	467d                	li	a2,31
ffffffffc0204914:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc0204918:	c61fe0ef          	jal	ra,ffffffffc0203578 <pgdir_alloc_page>
ffffffffc020491c:	2e050b63          	beqz	a0,ffffffffc0204c12 <do_execve+0x494>
    mm->mm_count += 1;
ffffffffc0204920:	589c                	lw	a5,48(s1)
    current->mm = mm;
ffffffffc0204922:	000db603          	ld	a2,0(s11)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204926:	6c94                	ld	a3,24(s1)
ffffffffc0204928:	2785                	addiw	a5,a5,1
ffffffffc020492a:	d89c                	sw	a5,48(s1)
    current->mm = mm;
ffffffffc020492c:	f604                	sd	s1,40(a2)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc020492e:	c02007b7          	lui	a5,0xc0200
ffffffffc0204932:	2cf6e463          	bltu	a3,a5,ffffffffc0204bfa <do_execve+0x47c>
ffffffffc0204936:	000b3783          	ld	a5,0(s6)
ffffffffc020493a:	577d                	li	a4,-1
ffffffffc020493c:	177e                	slli	a4,a4,0x3f
ffffffffc020493e:	8e9d                	sub	a3,a3,a5
ffffffffc0204940:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204944:	f654                	sd	a3,168(a2)
ffffffffc0204946:	8fd9                	or	a5,a5,a4
ffffffffc0204948:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc020494c:	7240                	ld	s0,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc020494e:	4581                	li	a1,0
ffffffffc0204950:	12000613          	li	a2,288
ffffffffc0204954:	8522                	mv	a0,s0
    uintptr_t sstatus = tf->status;
ffffffffc0204956:	10043483          	ld	s1,256(s0)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc020495a:	4b1000ef          	jal	ra,ffffffffc020560a <memset>
    tf->epc = elf->e_entry;
ffffffffc020495e:	7782                	ld	a5,32(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204960:	000db903          	ld	s2,0(s11)
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204964:	edf4f493          	andi	s1,s1,-289
    tf->epc = elf->e_entry;
ffffffffc0204968:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP;
ffffffffc020496a:	4785                	li	a5,1
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020496c:	0b490913          	addi	s2,s2,180 # ffffffff800000b4 <_binary_obj___user_exit_out_size+0xffffffff7fff4f94>
    tf->gpr.sp = USTACKTOP;
ffffffffc0204970:	07fe                	slli	a5,a5,0x1f
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204972:	0204e493          	ori	s1,s1,32
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204976:	4641                	li	a2,16
ffffffffc0204978:	4581                	li	a1,0
    tf->gpr.sp = USTACKTOP;
ffffffffc020497a:	e81c                	sd	a5,16(s0)
    tf->epc = elf->e_entry;
ffffffffc020497c:	10e43423          	sd	a4,264(s0)
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204980:	10943023          	sd	s1,256(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204984:	854a                	mv	a0,s2
ffffffffc0204986:	485000ef          	jal	ra,ffffffffc020560a <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc020498a:	463d                	li	a2,15
ffffffffc020498c:	180c                	addi	a1,sp,48
ffffffffc020498e:	854a                	mv	a0,s2
ffffffffc0204990:	48d000ef          	jal	ra,ffffffffc020561c <memcpy>
}
ffffffffc0204994:	70aa                	ld	ra,168(sp)
ffffffffc0204996:	740a                	ld	s0,160(sp)
ffffffffc0204998:	64ea                	ld	s1,152(sp)
ffffffffc020499a:	694a                	ld	s2,144(sp)
ffffffffc020499c:	69aa                	ld	s3,136(sp)
ffffffffc020499e:	7ae6                	ld	s5,120(sp)
ffffffffc02049a0:	7b46                	ld	s6,112(sp)
ffffffffc02049a2:	7ba6                	ld	s7,104(sp)
ffffffffc02049a4:	7c06                	ld	s8,96(sp)
ffffffffc02049a6:	6ce6                	ld	s9,88(sp)
ffffffffc02049a8:	6d46                	ld	s10,80(sp)
ffffffffc02049aa:	6da6                	ld	s11,72(sp)
ffffffffc02049ac:	8552                	mv	a0,s4
ffffffffc02049ae:	6a0a                	ld	s4,128(sp)
ffffffffc02049b0:	614d                	addi	sp,sp,176
ffffffffc02049b2:	8082                	ret
    memcpy(local_name, name, len);
ffffffffc02049b4:	463d                	li	a2,15
ffffffffc02049b6:	85ca                	mv	a1,s2
ffffffffc02049b8:	1808                	addi	a0,sp,48
ffffffffc02049ba:	463000ef          	jal	ra,ffffffffc020561c <memcpy>
    if (mm != NULL)
ffffffffc02049be:	e20991e3          	bnez	s3,ffffffffc02047e0 <do_execve+0x62>
    if (current->mm != NULL)
ffffffffc02049c2:	000db783          	ld	a5,0(s11)
ffffffffc02049c6:	779c                	ld	a5,40(a5)
ffffffffc02049c8:	e40788e3          	beqz	a5,ffffffffc0204818 <do_execve+0x9a>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc02049cc:	00002617          	auipc	a2,0x2
ffffffffc02049d0:	6c460613          	addi	a2,a2,1732 # ffffffffc0207090 <default_pmm_manager+0xc28>
ffffffffc02049d4:	23f00593          	li	a1,575
ffffffffc02049d8:	00002517          	auipc	a0,0x2
ffffffffc02049dc:	4f050513          	addi	a0,a0,1264 # ffffffffc0206ec8 <default_pmm_manager+0xa60>
ffffffffc02049e0:	aaffb0ef          	jal	ra,ffffffffc020048e <__panic>
    put_pgdir(mm);
ffffffffc02049e4:	8526                	mv	a0,s1
ffffffffc02049e6:	c88ff0ef          	jal	ra,ffffffffc0203e6e <put_pgdir>
    mm_destroy(mm);
ffffffffc02049ea:	8526                	mv	a0,s1
ffffffffc02049ec:	db3fe0ef          	jal	ra,ffffffffc020379e <mm_destroy>
        ret = -E_INVAL_ELF;
ffffffffc02049f0:	5a61                	li	s4,-8
    do_exit(ret);
ffffffffc02049f2:	8552                	mv	a0,s4
ffffffffc02049f4:	94bff0ef          	jal	ra,ffffffffc020433e <do_exit>
    int ret = -E_NO_MEM;
ffffffffc02049f8:	5a71                	li	s4,-4
ffffffffc02049fa:	bfe5                	j	ffffffffc02049f2 <do_execve+0x274>
        if (ph->p_filesz > ph->p_memsz)
ffffffffc02049fc:	0289b603          	ld	a2,40(s3)
ffffffffc0204a00:	0209b783          	ld	a5,32(s3)
ffffffffc0204a04:	1cf66d63          	bltu	a2,a5,ffffffffc0204bde <do_execve+0x460>
        if (ph->p_flags & ELF_PF_X)
ffffffffc0204a08:	0049a783          	lw	a5,4(s3)
ffffffffc0204a0c:	0017f693          	andi	a3,a5,1
ffffffffc0204a10:	c291                	beqz	a3,ffffffffc0204a14 <do_execve+0x296>
            vm_flags |= VM_EXEC;
ffffffffc0204a12:	4691                	li	a3,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204a14:	0027f713          	andi	a4,a5,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204a18:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204a1a:	e779                	bnez	a4,ffffffffc0204ae8 <do_execve+0x36a>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204a1c:	4d45                	li	s10,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204a1e:	c781                	beqz	a5,ffffffffc0204a26 <do_execve+0x2a8>
            vm_flags |= VM_READ;
ffffffffc0204a20:	0016e693          	ori	a3,a3,1
            perm |= PTE_R;
ffffffffc0204a24:	4d4d                	li	s10,19
        if (vm_flags & VM_WRITE)
ffffffffc0204a26:	0026f793          	andi	a5,a3,2
ffffffffc0204a2a:	e3f1                	bnez	a5,ffffffffc0204aee <do_execve+0x370>
        if (vm_flags & VM_EXEC)
ffffffffc0204a2c:	0046f793          	andi	a5,a3,4
ffffffffc0204a30:	c399                	beqz	a5,ffffffffc0204a36 <do_execve+0x2b8>
            perm |= PTE_X;
ffffffffc0204a32:	008d6d13          	ori	s10,s10,8
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc0204a36:	0109b583          	ld	a1,16(s3)
ffffffffc0204a3a:	4701                	li	a4,0
ffffffffc0204a3c:	8526                	mv	a0,s1
ffffffffc0204a3e:	db3fe0ef          	jal	ra,ffffffffc02037f0 <mm_map>
ffffffffc0204a42:	8a2a                	mv	s4,a0
ffffffffc0204a44:	ed35                	bnez	a0,ffffffffc0204ac0 <do_execve+0x342>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204a46:	0109bb83          	ld	s7,16(s3)
ffffffffc0204a4a:	77fd                	lui	a5,0xfffff
        end = ph->p_va + ph->p_filesz;
ffffffffc0204a4c:	0209ba03          	ld	s4,32(s3)
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204a50:	0089b903          	ld	s2,8(s3)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204a54:	00fbfab3          	and	s5,s7,a5
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204a58:	7782                	ld	a5,32(sp)
        end = ph->p_va + ph->p_filesz;
ffffffffc0204a5a:	9a5e                	add	s4,s4,s7
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204a5c:	993e                	add	s2,s2,a5
        while (start < end)
ffffffffc0204a5e:	054be963          	bltu	s7,s4,ffffffffc0204ab0 <do_execve+0x332>
ffffffffc0204a62:	aa95                	j	ffffffffc0204bd6 <do_execve+0x458>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204a64:	6785                	lui	a5,0x1
ffffffffc0204a66:	415b8533          	sub	a0,s7,s5
ffffffffc0204a6a:	9abe                	add	s5,s5,a5
ffffffffc0204a6c:	417a8633          	sub	a2,s5,s7
            if (end < la)
ffffffffc0204a70:	015a7463          	bgeu	s4,s5,ffffffffc0204a78 <do_execve+0x2fa>
                size -= la - end;
ffffffffc0204a74:	417a0633          	sub	a2,s4,s7
    return page - pages + nbase;
ffffffffc0204a78:	000cb683          	ld	a3,0(s9)
ffffffffc0204a7c:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204a7e:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204a82:	40d406b3          	sub	a3,s0,a3
ffffffffc0204a86:	8699                	srai	a3,a3,0x6
ffffffffc0204a88:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204a8a:	67e2                	ld	a5,24(sp)
ffffffffc0204a8c:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204a90:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204a92:	14b87863          	bgeu	a6,a1,ffffffffc0204be2 <do_execve+0x464>
ffffffffc0204a96:	000b3803          	ld	a6,0(s6)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204a9a:	85ca                	mv	a1,s2
            start += size, from += size;
ffffffffc0204a9c:	9bb2                	add	s7,s7,a2
ffffffffc0204a9e:	96c2                	add	a3,a3,a6
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204aa0:	9536                	add	a0,a0,a3
            start += size, from += size;
ffffffffc0204aa2:	e432                	sd	a2,8(sp)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204aa4:	379000ef          	jal	ra,ffffffffc020561c <memcpy>
            start += size, from += size;
ffffffffc0204aa8:	6622                	ld	a2,8(sp)
ffffffffc0204aaa:	9932                	add	s2,s2,a2
        while (start < end)
ffffffffc0204aac:	054bf363          	bgeu	s7,s4,ffffffffc0204af2 <do_execve+0x374>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204ab0:	6c88                	ld	a0,24(s1)
ffffffffc0204ab2:	866a                	mv	a2,s10
ffffffffc0204ab4:	85d6                	mv	a1,s5
ffffffffc0204ab6:	ac3fe0ef          	jal	ra,ffffffffc0203578 <pgdir_alloc_page>
ffffffffc0204aba:	842a                	mv	s0,a0
ffffffffc0204abc:	f545                	bnez	a0,ffffffffc0204a64 <do_execve+0x2e6>
        ret = -E_NO_MEM;
ffffffffc0204abe:	5a71                	li	s4,-4
    exit_mmap(mm);
ffffffffc0204ac0:	8526                	mv	a0,s1
ffffffffc0204ac2:	e79fe0ef          	jal	ra,ffffffffc020393a <exit_mmap>
    put_pgdir(mm);
ffffffffc0204ac6:	8526                	mv	a0,s1
ffffffffc0204ac8:	ba6ff0ef          	jal	ra,ffffffffc0203e6e <put_pgdir>
    mm_destroy(mm);
ffffffffc0204acc:	8526                	mv	a0,s1
ffffffffc0204ace:	cd1fe0ef          	jal	ra,ffffffffc020379e <mm_destroy>
    return ret;
ffffffffc0204ad2:	b705                	j	ffffffffc02049f2 <do_execve+0x274>
            exit_mmap(mm);
ffffffffc0204ad4:	854e                	mv	a0,s3
ffffffffc0204ad6:	e65fe0ef          	jal	ra,ffffffffc020393a <exit_mmap>
            put_pgdir(mm);
ffffffffc0204ada:	854e                	mv	a0,s3
ffffffffc0204adc:	b92ff0ef          	jal	ra,ffffffffc0203e6e <put_pgdir>
            mm_destroy(mm);
ffffffffc0204ae0:	854e                	mv	a0,s3
ffffffffc0204ae2:	cbdfe0ef          	jal	ra,ffffffffc020379e <mm_destroy>
ffffffffc0204ae6:	b32d                	j	ffffffffc0204810 <do_execve+0x92>
            vm_flags |= VM_WRITE;
ffffffffc0204ae8:	0026e693          	ori	a3,a3,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204aec:	fb95                	bnez	a5,ffffffffc0204a20 <do_execve+0x2a2>
            perm |= (PTE_W | PTE_R);
ffffffffc0204aee:	4d5d                	li	s10,23
ffffffffc0204af0:	bf35                	j	ffffffffc0204a2c <do_execve+0x2ae>
        end = ph->p_va + ph->p_memsz;
ffffffffc0204af2:	0109b683          	ld	a3,16(s3)
ffffffffc0204af6:	0289b903          	ld	s2,40(s3)
ffffffffc0204afa:	9936                	add	s2,s2,a3
        if (start < la)
ffffffffc0204afc:	075bfd63          	bgeu	s7,s5,ffffffffc0204b76 <do_execve+0x3f8>
            if (start == end)
ffffffffc0204b00:	db790fe3          	beq	s2,s7,ffffffffc02048be <do_execve+0x140>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204b04:	6785                	lui	a5,0x1
ffffffffc0204b06:	00fb8533          	add	a0,s7,a5
ffffffffc0204b0a:	41550533          	sub	a0,a0,s5
                size -= la - end;
ffffffffc0204b0e:	41790a33          	sub	s4,s2,s7
            if (end < la)
ffffffffc0204b12:	0b597d63          	bgeu	s2,s5,ffffffffc0204bcc <do_execve+0x44e>
    return page - pages + nbase;
ffffffffc0204b16:	000cb683          	ld	a3,0(s9)
ffffffffc0204b1a:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204b1c:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc0204b20:	40d406b3          	sub	a3,s0,a3
ffffffffc0204b24:	8699                	srai	a3,a3,0x6
ffffffffc0204b26:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204b28:	67e2                	ld	a5,24(sp)
ffffffffc0204b2a:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204b2e:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204b30:	0ac5f963          	bgeu	a1,a2,ffffffffc0204be2 <do_execve+0x464>
ffffffffc0204b34:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204b38:	8652                	mv	a2,s4
ffffffffc0204b3a:	4581                	li	a1,0
ffffffffc0204b3c:	96c2                	add	a3,a3,a6
ffffffffc0204b3e:	9536                	add	a0,a0,a3
ffffffffc0204b40:	2cb000ef          	jal	ra,ffffffffc020560a <memset>
            start += size;
ffffffffc0204b44:	017a0733          	add	a4,s4,s7
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0204b48:	03597463          	bgeu	s2,s5,ffffffffc0204b70 <do_execve+0x3f2>
ffffffffc0204b4c:	d6e909e3          	beq	s2,a4,ffffffffc02048be <do_execve+0x140>
ffffffffc0204b50:	00002697          	auipc	a3,0x2
ffffffffc0204b54:	56868693          	addi	a3,a3,1384 # ffffffffc02070b8 <default_pmm_manager+0xc50>
ffffffffc0204b58:	00001617          	auipc	a2,0x1
ffffffffc0204b5c:	56060613          	addi	a2,a2,1376 # ffffffffc02060b8 <commands+0x818>
ffffffffc0204b60:	2a800593          	li	a1,680
ffffffffc0204b64:	00002517          	auipc	a0,0x2
ffffffffc0204b68:	36450513          	addi	a0,a0,868 # ffffffffc0206ec8 <default_pmm_manager+0xa60>
ffffffffc0204b6c:	923fb0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0204b70:	ff5710e3          	bne	a4,s5,ffffffffc0204b50 <do_execve+0x3d2>
ffffffffc0204b74:	8bd6                	mv	s7,s5
        while (start < end)
ffffffffc0204b76:	d52bf4e3          	bgeu	s7,s2,ffffffffc02048be <do_execve+0x140>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204b7a:	6c88                	ld	a0,24(s1)
ffffffffc0204b7c:	866a                	mv	a2,s10
ffffffffc0204b7e:	85d6                	mv	a1,s5
ffffffffc0204b80:	9f9fe0ef          	jal	ra,ffffffffc0203578 <pgdir_alloc_page>
ffffffffc0204b84:	842a                	mv	s0,a0
ffffffffc0204b86:	dd05                	beqz	a0,ffffffffc0204abe <do_execve+0x340>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204b88:	6785                	lui	a5,0x1
ffffffffc0204b8a:	415b8533          	sub	a0,s7,s5
ffffffffc0204b8e:	9abe                	add	s5,s5,a5
ffffffffc0204b90:	417a8633          	sub	a2,s5,s7
            if (end < la)
ffffffffc0204b94:	01597463          	bgeu	s2,s5,ffffffffc0204b9c <do_execve+0x41e>
                size -= la - end;
ffffffffc0204b98:	41790633          	sub	a2,s2,s7
    return page - pages + nbase;
ffffffffc0204b9c:	000cb683          	ld	a3,0(s9)
ffffffffc0204ba0:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204ba2:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204ba6:	40d406b3          	sub	a3,s0,a3
ffffffffc0204baa:	8699                	srai	a3,a3,0x6
ffffffffc0204bac:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204bae:	67e2                	ld	a5,24(sp)
ffffffffc0204bb0:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204bb4:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204bb6:	02b87663          	bgeu	a6,a1,ffffffffc0204be2 <do_execve+0x464>
ffffffffc0204bba:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204bbe:	4581                	li	a1,0
            start += size;
ffffffffc0204bc0:	9bb2                	add	s7,s7,a2
ffffffffc0204bc2:	96c2                	add	a3,a3,a6
            memset(page2kva(page) + off, 0, size);
ffffffffc0204bc4:	9536                	add	a0,a0,a3
ffffffffc0204bc6:	245000ef          	jal	ra,ffffffffc020560a <memset>
ffffffffc0204bca:	b775                	j	ffffffffc0204b76 <do_execve+0x3f8>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204bcc:	417a8a33          	sub	s4,s5,s7
ffffffffc0204bd0:	b799                	j	ffffffffc0204b16 <do_execve+0x398>
        return -E_INVAL;
ffffffffc0204bd2:	5a75                	li	s4,-3
ffffffffc0204bd4:	b3c1                	j	ffffffffc0204994 <do_execve+0x216>
        while (start < end)
ffffffffc0204bd6:	86de                	mv	a3,s7
ffffffffc0204bd8:	bf39                	j	ffffffffc0204af6 <do_execve+0x378>
    int ret = -E_NO_MEM;
ffffffffc0204bda:	5a71                	li	s4,-4
ffffffffc0204bdc:	bdc5                	j	ffffffffc0204acc <do_execve+0x34e>
            ret = -E_INVAL_ELF;
ffffffffc0204bde:	5a61                	li	s4,-8
ffffffffc0204be0:	b5c5                	j	ffffffffc0204ac0 <do_execve+0x342>
ffffffffc0204be2:	00002617          	auipc	a2,0x2
ffffffffc0204be6:	8be60613          	addi	a2,a2,-1858 # ffffffffc02064a0 <default_pmm_manager+0x38>
ffffffffc0204bea:	07100593          	li	a1,113
ffffffffc0204bee:	00002517          	auipc	a0,0x2
ffffffffc0204bf2:	8da50513          	addi	a0,a0,-1830 # ffffffffc02064c8 <default_pmm_manager+0x60>
ffffffffc0204bf6:	899fb0ef          	jal	ra,ffffffffc020048e <__panic>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204bfa:	00002617          	auipc	a2,0x2
ffffffffc0204bfe:	94e60613          	addi	a2,a2,-1714 # ffffffffc0206548 <default_pmm_manager+0xe0>
ffffffffc0204c02:	2c700593          	li	a1,711
ffffffffc0204c06:	00002517          	auipc	a0,0x2
ffffffffc0204c0a:	2c250513          	addi	a0,a0,706 # ffffffffc0206ec8 <default_pmm_manager+0xa60>
ffffffffc0204c0e:	881fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204c12:	00002697          	auipc	a3,0x2
ffffffffc0204c16:	5be68693          	addi	a3,a3,1470 # ffffffffc02071d0 <default_pmm_manager+0xd68>
ffffffffc0204c1a:	00001617          	auipc	a2,0x1
ffffffffc0204c1e:	49e60613          	addi	a2,a2,1182 # ffffffffc02060b8 <commands+0x818>
ffffffffc0204c22:	2c200593          	li	a1,706
ffffffffc0204c26:	00002517          	auipc	a0,0x2
ffffffffc0204c2a:	2a250513          	addi	a0,a0,674 # ffffffffc0206ec8 <default_pmm_manager+0xa60>
ffffffffc0204c2e:	861fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204c32:	00002697          	auipc	a3,0x2
ffffffffc0204c36:	55668693          	addi	a3,a3,1366 # ffffffffc0207188 <default_pmm_manager+0xd20>
ffffffffc0204c3a:	00001617          	auipc	a2,0x1
ffffffffc0204c3e:	47e60613          	addi	a2,a2,1150 # ffffffffc02060b8 <commands+0x818>
ffffffffc0204c42:	2c100593          	li	a1,705
ffffffffc0204c46:	00002517          	auipc	a0,0x2
ffffffffc0204c4a:	28250513          	addi	a0,a0,642 # ffffffffc0206ec8 <default_pmm_manager+0xa60>
ffffffffc0204c4e:	841fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204c52:	00002697          	auipc	a3,0x2
ffffffffc0204c56:	4ee68693          	addi	a3,a3,1262 # ffffffffc0207140 <default_pmm_manager+0xcd8>
ffffffffc0204c5a:	00001617          	auipc	a2,0x1
ffffffffc0204c5e:	45e60613          	addi	a2,a2,1118 # ffffffffc02060b8 <commands+0x818>
ffffffffc0204c62:	2c000593          	li	a1,704
ffffffffc0204c66:	00002517          	auipc	a0,0x2
ffffffffc0204c6a:	26250513          	addi	a0,a0,610 # ffffffffc0206ec8 <default_pmm_manager+0xa60>
ffffffffc0204c6e:	821fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204c72:	00002697          	auipc	a3,0x2
ffffffffc0204c76:	48668693          	addi	a3,a3,1158 # ffffffffc02070f8 <default_pmm_manager+0xc90>
ffffffffc0204c7a:	00001617          	auipc	a2,0x1
ffffffffc0204c7e:	43e60613          	addi	a2,a2,1086 # ffffffffc02060b8 <commands+0x818>
ffffffffc0204c82:	2bf00593          	li	a1,703
ffffffffc0204c86:	00002517          	auipc	a0,0x2
ffffffffc0204c8a:	24250513          	addi	a0,a0,578 # ffffffffc0206ec8 <default_pmm_manager+0xa60>
ffffffffc0204c8e:	801fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204c92 <do_yield>:
    current->need_resched = 1;
ffffffffc0204c92:	000a6797          	auipc	a5,0xa6
ffffffffc0204c96:	a5e7b783          	ld	a5,-1442(a5) # ffffffffc02aa6f0 <current>
ffffffffc0204c9a:	4705                	li	a4,1
ffffffffc0204c9c:	ef98                	sd	a4,24(a5)
}
ffffffffc0204c9e:	4501                	li	a0,0
ffffffffc0204ca0:	8082                	ret

ffffffffc0204ca2 <do_wait>:
{
ffffffffc0204ca2:	1101                	addi	sp,sp,-32
ffffffffc0204ca4:	e822                	sd	s0,16(sp)
ffffffffc0204ca6:	e426                	sd	s1,8(sp)
ffffffffc0204ca8:	ec06                	sd	ra,24(sp)
ffffffffc0204caa:	842e                	mv	s0,a1
ffffffffc0204cac:	84aa                	mv	s1,a0
    if (code_store != NULL)
ffffffffc0204cae:	c999                	beqz	a1,ffffffffc0204cc4 <do_wait+0x22>
    struct mm_struct *mm = current->mm;
ffffffffc0204cb0:	000a6797          	auipc	a5,0xa6
ffffffffc0204cb4:	a407b783          	ld	a5,-1472(a5) # ffffffffc02aa6f0 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204cb8:	7788                	ld	a0,40(a5)
ffffffffc0204cba:	4685                	li	a3,1
ffffffffc0204cbc:	4611                	li	a2,4
ffffffffc0204cbe:	816ff0ef          	jal	ra,ffffffffc0203cd4 <user_mem_check>
ffffffffc0204cc2:	c909                	beqz	a0,ffffffffc0204cd4 <do_wait+0x32>
ffffffffc0204cc4:	85a2                	mv	a1,s0
}
ffffffffc0204cc6:	6442                	ld	s0,16(sp)
ffffffffc0204cc8:	60e2                	ld	ra,24(sp)
ffffffffc0204cca:	8526                	mv	a0,s1
ffffffffc0204ccc:	64a2                	ld	s1,8(sp)
ffffffffc0204cce:	6105                	addi	sp,sp,32
ffffffffc0204cd0:	fb8ff06f          	j	ffffffffc0204488 <do_wait.part.0>
ffffffffc0204cd4:	60e2                	ld	ra,24(sp)
ffffffffc0204cd6:	6442                	ld	s0,16(sp)
ffffffffc0204cd8:	64a2                	ld	s1,8(sp)
ffffffffc0204cda:	5575                	li	a0,-3
ffffffffc0204cdc:	6105                	addi	sp,sp,32
ffffffffc0204cde:	8082                	ret

ffffffffc0204ce0 <do_kill>:
{
ffffffffc0204ce0:	1141                	addi	sp,sp,-16
    if (0 < pid && pid < MAX_PID)
ffffffffc0204ce2:	6789                	lui	a5,0x2
{
ffffffffc0204ce4:	e406                	sd	ra,8(sp)
ffffffffc0204ce6:	e022                	sd	s0,0(sp)
    if (0 < pid && pid < MAX_PID)
ffffffffc0204ce8:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204cec:	17f9                	addi	a5,a5,-2
ffffffffc0204cee:	02e7e963          	bltu	a5,a4,ffffffffc0204d20 <do_kill+0x40>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204cf2:	842a                	mv	s0,a0
ffffffffc0204cf4:	45a9                	li	a1,10
ffffffffc0204cf6:	2501                	sext.w	a0,a0
ffffffffc0204cf8:	46c000ef          	jal	ra,ffffffffc0205164 <hash32>
ffffffffc0204cfc:	02051793          	slli	a5,a0,0x20
ffffffffc0204d00:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204d04:	000a2797          	auipc	a5,0xa2
ffffffffc0204d08:	97c78793          	addi	a5,a5,-1668 # ffffffffc02a6680 <hash_list>
ffffffffc0204d0c:	953e                	add	a0,a0,a5
ffffffffc0204d0e:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc0204d10:	a029                	j	ffffffffc0204d1a <do_kill+0x3a>
            if (proc->pid == pid)
ffffffffc0204d12:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0204d16:	00870b63          	beq	a4,s0,ffffffffc0204d2c <do_kill+0x4c>
ffffffffc0204d1a:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204d1c:	fef51be3          	bne	a0,a5,ffffffffc0204d12 <do_kill+0x32>
    return -E_INVAL;
ffffffffc0204d20:	5475                	li	s0,-3
}
ffffffffc0204d22:	60a2                	ld	ra,8(sp)
ffffffffc0204d24:	8522                	mv	a0,s0
ffffffffc0204d26:	6402                	ld	s0,0(sp)
ffffffffc0204d28:	0141                	addi	sp,sp,16
ffffffffc0204d2a:	8082                	ret
        if (!(proc->flags & PF_EXITING))
ffffffffc0204d2c:	fd87a703          	lw	a4,-40(a5)
ffffffffc0204d30:	00177693          	andi	a3,a4,1
ffffffffc0204d34:	e295                	bnez	a3,ffffffffc0204d58 <do_kill+0x78>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204d36:	4bd4                	lw	a3,20(a5)
            proc->flags |= PF_EXITING;
ffffffffc0204d38:	00176713          	ori	a4,a4,1
ffffffffc0204d3c:	fce7ac23          	sw	a4,-40(a5)
            return 0;
ffffffffc0204d40:	4401                	li	s0,0
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204d42:	fe06d0e3          	bgez	a3,ffffffffc0204d22 <do_kill+0x42>
                wakeup_proc(proc);
ffffffffc0204d46:	f2878513          	addi	a0,a5,-216
ffffffffc0204d4a:	22e000ef          	jal	ra,ffffffffc0204f78 <wakeup_proc>
}
ffffffffc0204d4e:	60a2                	ld	ra,8(sp)
ffffffffc0204d50:	8522                	mv	a0,s0
ffffffffc0204d52:	6402                	ld	s0,0(sp)
ffffffffc0204d54:	0141                	addi	sp,sp,16
ffffffffc0204d56:	8082                	ret
        return -E_KILLED;
ffffffffc0204d58:	545d                	li	s0,-9
ffffffffc0204d5a:	b7e1                	j	ffffffffc0204d22 <do_kill+0x42>

ffffffffc0204d5c <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0204d5c:	1101                	addi	sp,sp,-32
ffffffffc0204d5e:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0204d60:	000a6797          	auipc	a5,0xa6
ffffffffc0204d64:	92078793          	addi	a5,a5,-1760 # ffffffffc02aa680 <proc_list>
ffffffffc0204d68:	ec06                	sd	ra,24(sp)
ffffffffc0204d6a:	e822                	sd	s0,16(sp)
ffffffffc0204d6c:	e04a                	sd	s2,0(sp)
ffffffffc0204d6e:	000a2497          	auipc	s1,0xa2
ffffffffc0204d72:	91248493          	addi	s1,s1,-1774 # ffffffffc02a6680 <hash_list>
ffffffffc0204d76:	e79c                	sd	a5,8(a5)
ffffffffc0204d78:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0204d7a:	000a6717          	auipc	a4,0xa6
ffffffffc0204d7e:	90670713          	addi	a4,a4,-1786 # ffffffffc02aa680 <proc_list>
ffffffffc0204d82:	87a6                	mv	a5,s1
ffffffffc0204d84:	e79c                	sd	a5,8(a5)
ffffffffc0204d86:	e39c                	sd	a5,0(a5)
ffffffffc0204d88:	07c1                	addi	a5,a5,16
ffffffffc0204d8a:	fef71de3          	bne	a4,a5,ffffffffc0204d84 <proc_init+0x28>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0204d8e:	fe3fe0ef          	jal	ra,ffffffffc0203d70 <alloc_proc>
ffffffffc0204d92:	000a6917          	auipc	s2,0xa6
ffffffffc0204d96:	96690913          	addi	s2,s2,-1690 # ffffffffc02aa6f8 <idleproc>
ffffffffc0204d9a:	00a93023          	sd	a0,0(s2)
ffffffffc0204d9e:	0e050f63          	beqz	a0,ffffffffc0204e9c <proc_init+0x140>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0204da2:	4789                	li	a5,2
ffffffffc0204da4:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204da6:	00003797          	auipc	a5,0x3
ffffffffc0204daa:	25a78793          	addi	a5,a5,602 # ffffffffc0208000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204dae:	0b450413          	addi	s0,a0,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204db2:	e91c                	sd	a5,16(a0)
    idleproc->need_resched = 1;
ffffffffc0204db4:	4785                	li	a5,1
ffffffffc0204db6:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204db8:	4641                	li	a2,16
ffffffffc0204dba:	4581                	li	a1,0
ffffffffc0204dbc:	8522                	mv	a0,s0
ffffffffc0204dbe:	04d000ef          	jal	ra,ffffffffc020560a <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204dc2:	463d                	li	a2,15
ffffffffc0204dc4:	00002597          	auipc	a1,0x2
ffffffffc0204dc8:	46c58593          	addi	a1,a1,1132 # ffffffffc0207230 <default_pmm_manager+0xdc8>
ffffffffc0204dcc:	8522                	mv	a0,s0
ffffffffc0204dce:	04f000ef          	jal	ra,ffffffffc020561c <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0204dd2:	000a6717          	auipc	a4,0xa6
ffffffffc0204dd6:	93670713          	addi	a4,a4,-1738 # ffffffffc02aa708 <nr_process>
ffffffffc0204dda:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc0204ddc:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204de0:	4601                	li	a2,0
    nr_process++;
ffffffffc0204de2:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204de4:	4581                	li	a1,0
ffffffffc0204de6:	00000517          	auipc	a0,0x0
ffffffffc0204dea:	87450513          	addi	a0,a0,-1932 # ffffffffc020465a <init_main>
    nr_process++;
ffffffffc0204dee:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc0204df0:	000a6797          	auipc	a5,0xa6
ffffffffc0204df4:	90d7b023          	sd	a3,-1792(a5) # ffffffffc02aa6f0 <current>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204df8:	cf6ff0ef          	jal	ra,ffffffffc02042ee <kernel_thread>
ffffffffc0204dfc:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0204dfe:	08a05363          	blez	a0,ffffffffc0204e84 <proc_init+0x128>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204e02:	6789                	lui	a5,0x2
ffffffffc0204e04:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204e08:	17f9                	addi	a5,a5,-2
ffffffffc0204e0a:	2501                	sext.w	a0,a0
ffffffffc0204e0c:	02e7e363          	bltu	a5,a4,ffffffffc0204e32 <proc_init+0xd6>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204e10:	45a9                	li	a1,10
ffffffffc0204e12:	352000ef          	jal	ra,ffffffffc0205164 <hash32>
ffffffffc0204e16:	02051793          	slli	a5,a0,0x20
ffffffffc0204e1a:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0204e1e:	96a6                	add	a3,a3,s1
ffffffffc0204e20:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc0204e22:	a029                	j	ffffffffc0204e2c <proc_init+0xd0>
            if (proc->pid == pid)
ffffffffc0204e24:	f2c7a703          	lw	a4,-212(a5) # 1f2c <_binary_obj___user_faultread_out_size-0x7c7c>
ffffffffc0204e28:	04870b63          	beq	a4,s0,ffffffffc0204e7e <proc_init+0x122>
    return listelm->next;
ffffffffc0204e2c:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204e2e:	fef69be3          	bne	a3,a5,ffffffffc0204e24 <proc_init+0xc8>
    return NULL;
ffffffffc0204e32:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204e34:	0b478493          	addi	s1,a5,180
ffffffffc0204e38:	4641                	li	a2,16
ffffffffc0204e3a:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0204e3c:	000a6417          	auipc	s0,0xa6
ffffffffc0204e40:	8c440413          	addi	s0,s0,-1852 # ffffffffc02aa700 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204e44:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc0204e46:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204e48:	7c2000ef          	jal	ra,ffffffffc020560a <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204e4c:	463d                	li	a2,15
ffffffffc0204e4e:	00002597          	auipc	a1,0x2
ffffffffc0204e52:	40a58593          	addi	a1,a1,1034 # ffffffffc0207258 <default_pmm_manager+0xdf0>
ffffffffc0204e56:	8526                	mv	a0,s1
ffffffffc0204e58:	7c4000ef          	jal	ra,ffffffffc020561c <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0204e5c:	00093783          	ld	a5,0(s2)
ffffffffc0204e60:	cbb5                	beqz	a5,ffffffffc0204ed4 <proc_init+0x178>
ffffffffc0204e62:	43dc                	lw	a5,4(a5)
ffffffffc0204e64:	eba5                	bnez	a5,ffffffffc0204ed4 <proc_init+0x178>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0204e66:	601c                	ld	a5,0(s0)
ffffffffc0204e68:	c7b1                	beqz	a5,ffffffffc0204eb4 <proc_init+0x158>
ffffffffc0204e6a:	43d8                	lw	a4,4(a5)
ffffffffc0204e6c:	4785                	li	a5,1
ffffffffc0204e6e:	04f71363          	bne	a4,a5,ffffffffc0204eb4 <proc_init+0x158>
}
ffffffffc0204e72:	60e2                	ld	ra,24(sp)
ffffffffc0204e74:	6442                	ld	s0,16(sp)
ffffffffc0204e76:	64a2                	ld	s1,8(sp)
ffffffffc0204e78:	6902                	ld	s2,0(sp)
ffffffffc0204e7a:	6105                	addi	sp,sp,32
ffffffffc0204e7c:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0204e7e:	f2878793          	addi	a5,a5,-216
ffffffffc0204e82:	bf4d                	j	ffffffffc0204e34 <proc_init+0xd8>
        panic("create init_main failed.\n");
ffffffffc0204e84:	00002617          	auipc	a2,0x2
ffffffffc0204e88:	3b460613          	addi	a2,a2,948 # ffffffffc0207238 <default_pmm_manager+0xdd0>
ffffffffc0204e8c:	3e700593          	li	a1,999
ffffffffc0204e90:	00002517          	auipc	a0,0x2
ffffffffc0204e94:	03850513          	addi	a0,a0,56 # ffffffffc0206ec8 <default_pmm_manager+0xa60>
ffffffffc0204e98:	df6fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc0204e9c:	00002617          	auipc	a2,0x2
ffffffffc0204ea0:	37c60613          	addi	a2,a2,892 # ffffffffc0207218 <default_pmm_manager+0xdb0>
ffffffffc0204ea4:	3d800593          	li	a1,984
ffffffffc0204ea8:	00002517          	auipc	a0,0x2
ffffffffc0204eac:	02050513          	addi	a0,a0,32 # ffffffffc0206ec8 <default_pmm_manager+0xa60>
ffffffffc0204eb0:	ddefb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0204eb4:	00002697          	auipc	a3,0x2
ffffffffc0204eb8:	3d468693          	addi	a3,a3,980 # ffffffffc0207288 <default_pmm_manager+0xe20>
ffffffffc0204ebc:	00001617          	auipc	a2,0x1
ffffffffc0204ec0:	1fc60613          	addi	a2,a2,508 # ffffffffc02060b8 <commands+0x818>
ffffffffc0204ec4:	3ee00593          	li	a1,1006
ffffffffc0204ec8:	00002517          	auipc	a0,0x2
ffffffffc0204ecc:	00050513          	mv	a0,a0
ffffffffc0204ed0:	dbefb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0204ed4:	00002697          	auipc	a3,0x2
ffffffffc0204ed8:	38c68693          	addi	a3,a3,908 # ffffffffc0207260 <default_pmm_manager+0xdf8>
ffffffffc0204edc:	00001617          	auipc	a2,0x1
ffffffffc0204ee0:	1dc60613          	addi	a2,a2,476 # ffffffffc02060b8 <commands+0x818>
ffffffffc0204ee4:	3ed00593          	li	a1,1005
ffffffffc0204ee8:	00002517          	auipc	a0,0x2
ffffffffc0204eec:	fe050513          	addi	a0,a0,-32 # ffffffffc0206ec8 <default_pmm_manager+0xa60>
ffffffffc0204ef0:	d9efb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204ef4 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc0204ef4:	1141                	addi	sp,sp,-16
ffffffffc0204ef6:	e022                	sd	s0,0(sp)
ffffffffc0204ef8:	e406                	sd	ra,8(sp)
ffffffffc0204efa:	000a5417          	auipc	s0,0xa5
ffffffffc0204efe:	7f640413          	addi	s0,s0,2038 # ffffffffc02aa6f0 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc0204f02:	6018                	ld	a4,0(s0)
ffffffffc0204f04:	6f1c                	ld	a5,24(a4)
ffffffffc0204f06:	dffd                	beqz	a5,ffffffffc0204f04 <cpu_idle+0x10>
        {
            schedule();
ffffffffc0204f08:	0f0000ef          	jal	ra,ffffffffc0204ff8 <schedule>
ffffffffc0204f0c:	bfdd                	j	ffffffffc0204f02 <cpu_idle+0xe>

ffffffffc0204f0e <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0204f0e:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0204f12:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0204f16:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0204f18:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0204f1a:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0204f1e:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0204f22:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0204f26:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc0204f2a:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0204f2e:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0204f32:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0204f36:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc0204f3a:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0204f3e:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0204f42:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc0204f46:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc0204f4a:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc0204f4c:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0204f4e:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0204f52:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc0204f56:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc0204f5a:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc0204f5e:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0204f62:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0204f66:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc0204f6a:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc0204f6e:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc0204f72:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc0204f76:	8082                	ret

ffffffffc0204f78 <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0204f78:	4118                	lw	a4,0(a0)
{
ffffffffc0204f7a:	1101                	addi	sp,sp,-32
ffffffffc0204f7c:	ec06                	sd	ra,24(sp)
ffffffffc0204f7e:	e822                	sd	s0,16(sp)
ffffffffc0204f80:	e426                	sd	s1,8(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0204f82:	478d                	li	a5,3
ffffffffc0204f84:	04f70b63          	beq	a4,a5,ffffffffc0204fda <wakeup_proc+0x62>
ffffffffc0204f88:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204f8a:	100027f3          	csrr	a5,sstatus
ffffffffc0204f8e:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204f90:	4481                	li	s1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204f92:	ef9d                	bnez	a5,ffffffffc0204fd0 <wakeup_proc+0x58>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
ffffffffc0204f94:	4789                	li	a5,2
ffffffffc0204f96:	02f70163          	beq	a4,a5,ffffffffc0204fb8 <wakeup_proc+0x40>
        {
            proc->state = PROC_RUNNABLE;
ffffffffc0204f9a:	c01c                	sw	a5,0(s0)
            proc->wait_state = 0;
ffffffffc0204f9c:	0e042623          	sw	zero,236(s0)
    if (flag)
ffffffffc0204fa0:	e491                	bnez	s1,ffffffffc0204fac <wakeup_proc+0x34>
        {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0204fa2:	60e2                	ld	ra,24(sp)
ffffffffc0204fa4:	6442                	ld	s0,16(sp)
ffffffffc0204fa6:	64a2                	ld	s1,8(sp)
ffffffffc0204fa8:	6105                	addi	sp,sp,32
ffffffffc0204faa:	8082                	ret
ffffffffc0204fac:	6442                	ld	s0,16(sp)
ffffffffc0204fae:	60e2                	ld	ra,24(sp)
ffffffffc0204fb0:	64a2                	ld	s1,8(sp)
ffffffffc0204fb2:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0204fb4:	9fbfb06f          	j	ffffffffc02009ae <intr_enable>
            warn("wakeup runnable process.\n");
ffffffffc0204fb8:	00002617          	auipc	a2,0x2
ffffffffc0204fbc:	33060613          	addi	a2,a2,816 # ffffffffc02072e8 <default_pmm_manager+0xe80>
ffffffffc0204fc0:	45d1                	li	a1,20
ffffffffc0204fc2:	00002517          	auipc	a0,0x2
ffffffffc0204fc6:	30e50513          	addi	a0,a0,782 # ffffffffc02072d0 <default_pmm_manager+0xe68>
ffffffffc0204fca:	d2cfb0ef          	jal	ra,ffffffffc02004f6 <__warn>
ffffffffc0204fce:	bfc9                	j	ffffffffc0204fa0 <wakeup_proc+0x28>
        intr_disable();
ffffffffc0204fd0:	9e5fb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        if (proc->state != PROC_RUNNABLE)
ffffffffc0204fd4:	4018                	lw	a4,0(s0)
        return 1;
ffffffffc0204fd6:	4485                	li	s1,1
ffffffffc0204fd8:	bf75                	j	ffffffffc0204f94 <wakeup_proc+0x1c>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0204fda:	00002697          	auipc	a3,0x2
ffffffffc0204fde:	2d668693          	addi	a3,a3,726 # ffffffffc02072b0 <default_pmm_manager+0xe48>
ffffffffc0204fe2:	00001617          	auipc	a2,0x1
ffffffffc0204fe6:	0d660613          	addi	a2,a2,214 # ffffffffc02060b8 <commands+0x818>
ffffffffc0204fea:	45a5                	li	a1,9
ffffffffc0204fec:	00002517          	auipc	a0,0x2
ffffffffc0204ff0:	2e450513          	addi	a0,a0,740 # ffffffffc02072d0 <default_pmm_manager+0xe68>
ffffffffc0204ff4:	c9afb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204ff8 <schedule>:

void schedule(void)
{
ffffffffc0204ff8:	1141                	addi	sp,sp,-16
ffffffffc0204ffa:	e406                	sd	ra,8(sp)
ffffffffc0204ffc:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204ffe:	100027f3          	csrr	a5,sstatus
ffffffffc0205002:	8b89                	andi	a5,a5,2
ffffffffc0205004:	4401                	li	s0,0
ffffffffc0205006:	efbd                	bnez	a5,ffffffffc0205084 <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc0205008:	000a5897          	auipc	a7,0xa5
ffffffffc020500c:	6e88b883          	ld	a7,1768(a7) # ffffffffc02aa6f0 <current>
ffffffffc0205010:	0008bc23          	sd	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0205014:	000a5517          	auipc	a0,0xa5
ffffffffc0205018:	6e453503          	ld	a0,1764(a0) # ffffffffc02aa6f8 <idleproc>
ffffffffc020501c:	04a88e63          	beq	a7,a0,ffffffffc0205078 <schedule+0x80>
ffffffffc0205020:	0c888693          	addi	a3,a7,200
ffffffffc0205024:	000a5617          	auipc	a2,0xa5
ffffffffc0205028:	65c60613          	addi	a2,a2,1628 # ffffffffc02aa680 <proc_list>
        le = last;
ffffffffc020502c:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc020502e:	4581                	li	a1,0
        do
        {
            if ((le = list_next(le)) != &proc_list)
            {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE)
ffffffffc0205030:	4809                	li	a6,2
ffffffffc0205032:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list)
ffffffffc0205034:	00c78863          	beq	a5,a2,ffffffffc0205044 <schedule+0x4c>
                if (next->state == PROC_RUNNABLE)
ffffffffc0205038:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc020503c:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE)
ffffffffc0205040:	03070163          	beq	a4,a6,ffffffffc0205062 <schedule+0x6a>
                {
                    break;
                }
            }
        } while (le != last);
ffffffffc0205044:	fef697e3          	bne	a3,a5,ffffffffc0205032 <schedule+0x3a>
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc0205048:	ed89                	bnez	a1,ffffffffc0205062 <schedule+0x6a>
        {
            next = idleproc;
        }
        next->runs++;
ffffffffc020504a:	451c                	lw	a5,8(a0)
ffffffffc020504c:	2785                	addiw	a5,a5,1
ffffffffc020504e:	c51c                	sw	a5,8(a0)
        if (next != current)
ffffffffc0205050:	00a88463          	beq	a7,a0,ffffffffc0205058 <schedule+0x60>
        {
            proc_run(next);
ffffffffc0205054:	e91fe0ef          	jal	ra,ffffffffc0203ee4 <proc_run>
    if (flag)
ffffffffc0205058:	e819                	bnez	s0,ffffffffc020506e <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc020505a:	60a2                	ld	ra,8(sp)
ffffffffc020505c:	6402                	ld	s0,0(sp)
ffffffffc020505e:	0141                	addi	sp,sp,16
ffffffffc0205060:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc0205062:	4198                	lw	a4,0(a1)
ffffffffc0205064:	4789                	li	a5,2
ffffffffc0205066:	fef712e3          	bne	a4,a5,ffffffffc020504a <schedule+0x52>
ffffffffc020506a:	852e                	mv	a0,a1
ffffffffc020506c:	bff9                	j	ffffffffc020504a <schedule+0x52>
}
ffffffffc020506e:	6402                	ld	s0,0(sp)
ffffffffc0205070:	60a2                	ld	ra,8(sp)
ffffffffc0205072:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0205074:	93bfb06f          	j	ffffffffc02009ae <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0205078:	000a5617          	auipc	a2,0xa5
ffffffffc020507c:	60860613          	addi	a2,a2,1544 # ffffffffc02aa680 <proc_list>
ffffffffc0205080:	86b2                	mv	a3,a2
ffffffffc0205082:	b76d                	j	ffffffffc020502c <schedule+0x34>
        intr_disable();
ffffffffc0205084:	931fb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0205088:	4405                	li	s0,1
ffffffffc020508a:	bfbd                	j	ffffffffc0205008 <schedule+0x10>

ffffffffc020508c <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc020508c:	000a5797          	auipc	a5,0xa5
ffffffffc0205090:	6647b783          	ld	a5,1636(a5) # ffffffffc02aa6f0 <current>
}
ffffffffc0205094:	43c8                	lw	a0,4(a5)
ffffffffc0205096:	8082                	ret

ffffffffc0205098 <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc0205098:	4501                	li	a0,0
ffffffffc020509a:	8082                	ret

ffffffffc020509c <sys_putc>:
    cputchar(c);
ffffffffc020509c:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc020509e:	1141                	addi	sp,sp,-16
ffffffffc02050a0:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc02050a2:	928fb0ef          	jal	ra,ffffffffc02001ca <cputchar>
}
ffffffffc02050a6:	60a2                	ld	ra,8(sp)
ffffffffc02050a8:	4501                	li	a0,0
ffffffffc02050aa:	0141                	addi	sp,sp,16
ffffffffc02050ac:	8082                	ret

ffffffffc02050ae <sys_kill>:
    return do_kill(pid);
ffffffffc02050ae:	4108                	lw	a0,0(a0)
ffffffffc02050b0:	c31ff06f          	j	ffffffffc0204ce0 <do_kill>

ffffffffc02050b4 <sys_yield>:
    return do_yield();
ffffffffc02050b4:	bdfff06f          	j	ffffffffc0204c92 <do_yield>

ffffffffc02050b8 <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc02050b8:	6d14                	ld	a3,24(a0)
ffffffffc02050ba:	6910                	ld	a2,16(a0)
ffffffffc02050bc:	650c                	ld	a1,8(a0)
ffffffffc02050be:	6108                	ld	a0,0(a0)
ffffffffc02050c0:	ebeff06f          	j	ffffffffc020477e <do_execve>

ffffffffc02050c4 <sys_wait>:
    return do_wait(pid, store);
ffffffffc02050c4:	650c                	ld	a1,8(a0)
ffffffffc02050c6:	4108                	lw	a0,0(a0)
ffffffffc02050c8:	bdbff06f          	j	ffffffffc0204ca2 <do_wait>

ffffffffc02050cc <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc02050cc:	000a5797          	auipc	a5,0xa5
ffffffffc02050d0:	6247b783          	ld	a5,1572(a5) # ffffffffc02aa6f0 <current>
ffffffffc02050d4:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc02050d6:	4501                	li	a0,0
ffffffffc02050d8:	6a0c                	ld	a1,16(a2)
ffffffffc02050da:	e6ffe06f          	j	ffffffffc0203f48 <do_fork>

ffffffffc02050de <sys_exit>:
    return do_exit(error_code);
ffffffffc02050de:	4108                	lw	a0,0(a0)
ffffffffc02050e0:	a5eff06f          	j	ffffffffc020433e <do_exit>

ffffffffc02050e4 <syscall>:
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
ffffffffc02050e4:	715d                	addi	sp,sp,-80
ffffffffc02050e6:	fc26                	sd	s1,56(sp)
    struct trapframe *tf = current->tf;
ffffffffc02050e8:	000a5497          	auipc	s1,0xa5
ffffffffc02050ec:	60848493          	addi	s1,s1,1544 # ffffffffc02aa6f0 <current>
ffffffffc02050f0:	6098                	ld	a4,0(s1)
syscall(void) {
ffffffffc02050f2:	e0a2                	sd	s0,64(sp)
ffffffffc02050f4:	f84a                	sd	s2,48(sp)
    struct trapframe *tf = current->tf;
ffffffffc02050f6:	7340                	ld	s0,160(a4)
syscall(void) {
ffffffffc02050f8:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc02050fa:	47fd                	li	a5,31
    int num = tf->gpr.a0;
ffffffffc02050fc:	05042903          	lw	s2,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205100:	0327ee63          	bltu	a5,s2,ffffffffc020513c <syscall+0x58>
        if (syscalls[num] != NULL) {
ffffffffc0205104:	00391713          	slli	a4,s2,0x3
ffffffffc0205108:	00002797          	auipc	a5,0x2
ffffffffc020510c:	24878793          	addi	a5,a5,584 # ffffffffc0207350 <syscalls>
ffffffffc0205110:	97ba                	add	a5,a5,a4
ffffffffc0205112:	639c                	ld	a5,0(a5)
ffffffffc0205114:	c785                	beqz	a5,ffffffffc020513c <syscall+0x58>
            arg[0] = tf->gpr.a1;
ffffffffc0205116:	6c28                	ld	a0,88(s0)
            arg[1] = tf->gpr.a2;
ffffffffc0205118:	702c                	ld	a1,96(s0)
            arg[2] = tf->gpr.a3;
ffffffffc020511a:	7430                	ld	a2,104(s0)
            arg[3] = tf->gpr.a4;
ffffffffc020511c:	7834                	ld	a3,112(s0)
            arg[4] = tf->gpr.a5;
ffffffffc020511e:	7c38                	ld	a4,120(s0)
            arg[0] = tf->gpr.a1;
ffffffffc0205120:	e42a                	sd	a0,8(sp)
            arg[1] = tf->gpr.a2;
ffffffffc0205122:	e82e                	sd	a1,16(sp)
            arg[2] = tf->gpr.a3;
ffffffffc0205124:	ec32                	sd	a2,24(sp)
            arg[3] = tf->gpr.a4;
ffffffffc0205126:	f036                	sd	a3,32(sp)
            arg[4] = tf->gpr.a5;
ffffffffc0205128:	f43a                	sd	a4,40(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc020512a:	0028                	addi	a0,sp,8
ffffffffc020512c:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc020512e:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0205130:	e828                	sd	a0,80(s0)
}
ffffffffc0205132:	6406                	ld	s0,64(sp)
ffffffffc0205134:	74e2                	ld	s1,56(sp)
ffffffffc0205136:	7942                	ld	s2,48(sp)
ffffffffc0205138:	6161                	addi	sp,sp,80
ffffffffc020513a:	8082                	ret
    print_trapframe(tf);
ffffffffc020513c:	8522                	mv	a0,s0
ffffffffc020513e:	a67fb0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc0205142:	609c                	ld	a5,0(s1)
ffffffffc0205144:	86ca                	mv	a3,s2
ffffffffc0205146:	00002617          	auipc	a2,0x2
ffffffffc020514a:	1c260613          	addi	a2,a2,450 # ffffffffc0207308 <default_pmm_manager+0xea0>
ffffffffc020514e:	43d8                	lw	a4,4(a5)
ffffffffc0205150:	06200593          	li	a1,98
ffffffffc0205154:	0b478793          	addi	a5,a5,180
ffffffffc0205158:	00002517          	auipc	a0,0x2
ffffffffc020515c:	1e050513          	addi	a0,a0,480 # ffffffffc0207338 <default_pmm_manager+0xed0>
ffffffffc0205160:	b2efb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0205164 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc0205164:	9e3707b7          	lui	a5,0x9e370
ffffffffc0205168:	2785                	addiw	a5,a5,1
ffffffffc020516a:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc020516e:	02000793          	li	a5,32
ffffffffc0205172:	9f8d                	subw	a5,a5,a1
}
ffffffffc0205174:	00f5553b          	srlw	a0,a0,a5
ffffffffc0205178:	8082                	ret

ffffffffc020517a <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc020517a:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020517e:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0205180:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205184:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0205186:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020518a:	f022                	sd	s0,32(sp)
ffffffffc020518c:	ec26                	sd	s1,24(sp)
ffffffffc020518e:	e84a                	sd	s2,16(sp)
ffffffffc0205190:	f406                	sd	ra,40(sp)
ffffffffc0205192:	e44e                	sd	s3,8(sp)
ffffffffc0205194:	84aa                	mv	s1,a0
ffffffffc0205196:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0205198:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc020519c:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc020519e:	03067e63          	bgeu	a2,a6,ffffffffc02051da <printnum+0x60>
ffffffffc02051a2:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02051a4:	00805763          	blez	s0,ffffffffc02051b2 <printnum+0x38>
ffffffffc02051a8:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02051aa:	85ca                	mv	a1,s2
ffffffffc02051ac:	854e                	mv	a0,s3
ffffffffc02051ae:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02051b0:	fc65                	bnez	s0,ffffffffc02051a8 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02051b2:	1a02                	slli	s4,s4,0x20
ffffffffc02051b4:	00002797          	auipc	a5,0x2
ffffffffc02051b8:	29c78793          	addi	a5,a5,668 # ffffffffc0207450 <syscalls+0x100>
ffffffffc02051bc:	020a5a13          	srli	s4,s4,0x20
ffffffffc02051c0:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc02051c2:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02051c4:	000a4503          	lbu	a0,0(s4)
}
ffffffffc02051c8:	70a2                	ld	ra,40(sp)
ffffffffc02051ca:	69a2                	ld	s3,8(sp)
ffffffffc02051cc:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02051ce:	85ca                	mv	a1,s2
ffffffffc02051d0:	87a6                	mv	a5,s1
}
ffffffffc02051d2:	6942                	ld	s2,16(sp)
ffffffffc02051d4:	64e2                	ld	s1,24(sp)
ffffffffc02051d6:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02051d8:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02051da:	03065633          	divu	a2,a2,a6
ffffffffc02051de:	8722                	mv	a4,s0
ffffffffc02051e0:	f9bff0ef          	jal	ra,ffffffffc020517a <printnum>
ffffffffc02051e4:	b7f9                	j	ffffffffc02051b2 <printnum+0x38>

ffffffffc02051e6 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02051e6:	7119                	addi	sp,sp,-128
ffffffffc02051e8:	f4a6                	sd	s1,104(sp)
ffffffffc02051ea:	f0ca                	sd	s2,96(sp)
ffffffffc02051ec:	ecce                	sd	s3,88(sp)
ffffffffc02051ee:	e8d2                	sd	s4,80(sp)
ffffffffc02051f0:	e4d6                	sd	s5,72(sp)
ffffffffc02051f2:	e0da                	sd	s6,64(sp)
ffffffffc02051f4:	fc5e                	sd	s7,56(sp)
ffffffffc02051f6:	f06a                	sd	s10,32(sp)
ffffffffc02051f8:	fc86                	sd	ra,120(sp)
ffffffffc02051fa:	f8a2                	sd	s0,112(sp)
ffffffffc02051fc:	f862                	sd	s8,48(sp)
ffffffffc02051fe:	f466                	sd	s9,40(sp)
ffffffffc0205200:	ec6e                	sd	s11,24(sp)
ffffffffc0205202:	892a                	mv	s2,a0
ffffffffc0205204:	84ae                	mv	s1,a1
ffffffffc0205206:	8d32                	mv	s10,a2
ffffffffc0205208:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020520a:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc020520e:	5b7d                	li	s6,-1
ffffffffc0205210:	00002a97          	auipc	s5,0x2
ffffffffc0205214:	26ca8a93          	addi	s5,s5,620 # ffffffffc020747c <syscalls+0x12c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205218:	00002b97          	auipc	s7,0x2
ffffffffc020521c:	480b8b93          	addi	s7,s7,1152 # ffffffffc0207698 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205220:	000d4503          	lbu	a0,0(s10)
ffffffffc0205224:	001d0413          	addi	s0,s10,1
ffffffffc0205228:	01350a63          	beq	a0,s3,ffffffffc020523c <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc020522c:	c121                	beqz	a0,ffffffffc020526c <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc020522e:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205230:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0205232:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205234:	fff44503          	lbu	a0,-1(s0)
ffffffffc0205238:	ff351ae3          	bne	a0,s3,ffffffffc020522c <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020523c:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0205240:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0205244:	4c81                	li	s9,0
ffffffffc0205246:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0205248:	5c7d                	li	s8,-1
ffffffffc020524a:	5dfd                	li	s11,-1
ffffffffc020524c:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0205250:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205252:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0205256:	0ff5f593          	zext.b	a1,a1
ffffffffc020525a:	00140d13          	addi	s10,s0,1
ffffffffc020525e:	04b56263          	bltu	a0,a1,ffffffffc02052a2 <vprintfmt+0xbc>
ffffffffc0205262:	058a                	slli	a1,a1,0x2
ffffffffc0205264:	95d6                	add	a1,a1,s5
ffffffffc0205266:	4194                	lw	a3,0(a1)
ffffffffc0205268:	96d6                	add	a3,a3,s5
ffffffffc020526a:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc020526c:	70e6                	ld	ra,120(sp)
ffffffffc020526e:	7446                	ld	s0,112(sp)
ffffffffc0205270:	74a6                	ld	s1,104(sp)
ffffffffc0205272:	7906                	ld	s2,96(sp)
ffffffffc0205274:	69e6                	ld	s3,88(sp)
ffffffffc0205276:	6a46                	ld	s4,80(sp)
ffffffffc0205278:	6aa6                	ld	s5,72(sp)
ffffffffc020527a:	6b06                	ld	s6,64(sp)
ffffffffc020527c:	7be2                	ld	s7,56(sp)
ffffffffc020527e:	7c42                	ld	s8,48(sp)
ffffffffc0205280:	7ca2                	ld	s9,40(sp)
ffffffffc0205282:	7d02                	ld	s10,32(sp)
ffffffffc0205284:	6de2                	ld	s11,24(sp)
ffffffffc0205286:	6109                	addi	sp,sp,128
ffffffffc0205288:	8082                	ret
            padc = '0';
ffffffffc020528a:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc020528c:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205290:	846a                	mv	s0,s10
ffffffffc0205292:	00140d13          	addi	s10,s0,1
ffffffffc0205296:	fdd6059b          	addiw	a1,a2,-35
ffffffffc020529a:	0ff5f593          	zext.b	a1,a1
ffffffffc020529e:	fcb572e3          	bgeu	a0,a1,ffffffffc0205262 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc02052a2:	85a6                	mv	a1,s1
ffffffffc02052a4:	02500513          	li	a0,37
ffffffffc02052a8:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02052aa:	fff44783          	lbu	a5,-1(s0)
ffffffffc02052ae:	8d22                	mv	s10,s0
ffffffffc02052b0:	f73788e3          	beq	a5,s3,ffffffffc0205220 <vprintfmt+0x3a>
ffffffffc02052b4:	ffed4783          	lbu	a5,-2(s10)
ffffffffc02052b8:	1d7d                	addi	s10,s10,-1
ffffffffc02052ba:	ff379de3          	bne	a5,s3,ffffffffc02052b4 <vprintfmt+0xce>
ffffffffc02052be:	b78d                	j	ffffffffc0205220 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc02052c0:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc02052c4:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02052c8:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc02052ca:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc02052ce:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02052d2:	02d86463          	bltu	a6,a3,ffffffffc02052fa <vprintfmt+0x114>
                ch = *fmt;
ffffffffc02052d6:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02052da:	002c169b          	slliw	a3,s8,0x2
ffffffffc02052de:	0186873b          	addw	a4,a3,s8
ffffffffc02052e2:	0017171b          	slliw	a4,a4,0x1
ffffffffc02052e6:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc02052e8:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02052ec:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02052ee:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc02052f2:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02052f6:	fed870e3          	bgeu	a6,a3,ffffffffc02052d6 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc02052fa:	f40ddce3          	bgez	s11,ffffffffc0205252 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc02052fe:	8de2                	mv	s11,s8
ffffffffc0205300:	5c7d                	li	s8,-1
ffffffffc0205302:	bf81                	j	ffffffffc0205252 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0205304:	fffdc693          	not	a3,s11
ffffffffc0205308:	96fd                	srai	a3,a3,0x3f
ffffffffc020530a:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020530e:	00144603          	lbu	a2,1(s0)
ffffffffc0205312:	2d81                	sext.w	s11,s11
ffffffffc0205314:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0205316:	bf35                	j	ffffffffc0205252 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0205318:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020531c:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0205320:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205322:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0205324:	bfd9                	j	ffffffffc02052fa <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0205326:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205328:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020532c:	01174463          	blt	a4,a7,ffffffffc0205334 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0205330:	1a088e63          	beqz	a7,ffffffffc02054ec <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0205334:	000a3603          	ld	a2,0(s4)
ffffffffc0205338:	46c1                	li	a3,16
ffffffffc020533a:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc020533c:	2781                	sext.w	a5,a5
ffffffffc020533e:	876e                	mv	a4,s11
ffffffffc0205340:	85a6                	mv	a1,s1
ffffffffc0205342:	854a                	mv	a0,s2
ffffffffc0205344:	e37ff0ef          	jal	ra,ffffffffc020517a <printnum>
            break;
ffffffffc0205348:	bde1                	j	ffffffffc0205220 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc020534a:	000a2503          	lw	a0,0(s4)
ffffffffc020534e:	85a6                	mv	a1,s1
ffffffffc0205350:	0a21                	addi	s4,s4,8
ffffffffc0205352:	9902                	jalr	s2
            break;
ffffffffc0205354:	b5f1                	j	ffffffffc0205220 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0205356:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205358:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020535c:	01174463          	blt	a4,a7,ffffffffc0205364 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0205360:	18088163          	beqz	a7,ffffffffc02054e2 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0205364:	000a3603          	ld	a2,0(s4)
ffffffffc0205368:	46a9                	li	a3,10
ffffffffc020536a:	8a2e                	mv	s4,a1
ffffffffc020536c:	bfc1                	j	ffffffffc020533c <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020536e:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0205372:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205374:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0205376:	bdf1                	j	ffffffffc0205252 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0205378:	85a6                	mv	a1,s1
ffffffffc020537a:	02500513          	li	a0,37
ffffffffc020537e:	9902                	jalr	s2
            break;
ffffffffc0205380:	b545                	j	ffffffffc0205220 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205382:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0205386:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205388:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020538a:	b5e1                	j	ffffffffc0205252 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc020538c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020538e:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205392:	01174463          	blt	a4,a7,ffffffffc020539a <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0205396:	14088163          	beqz	a7,ffffffffc02054d8 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc020539a:	000a3603          	ld	a2,0(s4)
ffffffffc020539e:	46a1                	li	a3,8
ffffffffc02053a0:	8a2e                	mv	s4,a1
ffffffffc02053a2:	bf69                	j	ffffffffc020533c <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc02053a4:	03000513          	li	a0,48
ffffffffc02053a8:	85a6                	mv	a1,s1
ffffffffc02053aa:	e03e                	sd	a5,0(sp)
ffffffffc02053ac:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc02053ae:	85a6                	mv	a1,s1
ffffffffc02053b0:	07800513          	li	a0,120
ffffffffc02053b4:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02053b6:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc02053b8:	6782                	ld	a5,0(sp)
ffffffffc02053ba:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02053bc:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc02053c0:	bfb5                	j	ffffffffc020533c <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02053c2:	000a3403          	ld	s0,0(s4)
ffffffffc02053c6:	008a0713          	addi	a4,s4,8
ffffffffc02053ca:	e03a                	sd	a4,0(sp)
ffffffffc02053cc:	14040263          	beqz	s0,ffffffffc0205510 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc02053d0:	0fb05763          	blez	s11,ffffffffc02054be <vprintfmt+0x2d8>
ffffffffc02053d4:	02d00693          	li	a3,45
ffffffffc02053d8:	0cd79163          	bne	a5,a3,ffffffffc020549a <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02053dc:	00044783          	lbu	a5,0(s0)
ffffffffc02053e0:	0007851b          	sext.w	a0,a5
ffffffffc02053e4:	cf85                	beqz	a5,ffffffffc020541c <vprintfmt+0x236>
ffffffffc02053e6:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02053ea:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02053ee:	000c4563          	bltz	s8,ffffffffc02053f8 <vprintfmt+0x212>
ffffffffc02053f2:	3c7d                	addiw	s8,s8,-1
ffffffffc02053f4:	036c0263          	beq	s8,s6,ffffffffc0205418 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc02053f8:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02053fa:	0e0c8e63          	beqz	s9,ffffffffc02054f6 <vprintfmt+0x310>
ffffffffc02053fe:	3781                	addiw	a5,a5,-32
ffffffffc0205400:	0ef47b63          	bgeu	s0,a5,ffffffffc02054f6 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0205404:	03f00513          	li	a0,63
ffffffffc0205408:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020540a:	000a4783          	lbu	a5,0(s4)
ffffffffc020540e:	3dfd                	addiw	s11,s11,-1
ffffffffc0205410:	0a05                	addi	s4,s4,1
ffffffffc0205412:	0007851b          	sext.w	a0,a5
ffffffffc0205416:	ffe1                	bnez	a5,ffffffffc02053ee <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0205418:	01b05963          	blez	s11,ffffffffc020542a <vprintfmt+0x244>
ffffffffc020541c:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc020541e:	85a6                	mv	a1,s1
ffffffffc0205420:	02000513          	li	a0,32
ffffffffc0205424:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0205426:	fe0d9be3          	bnez	s11,ffffffffc020541c <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020542a:	6a02                	ld	s4,0(sp)
ffffffffc020542c:	bbd5                	j	ffffffffc0205220 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020542e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205430:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0205434:	01174463          	blt	a4,a7,ffffffffc020543c <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0205438:	08088d63          	beqz	a7,ffffffffc02054d2 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc020543c:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0205440:	0a044d63          	bltz	s0,ffffffffc02054fa <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0205444:	8622                	mv	a2,s0
ffffffffc0205446:	8a66                	mv	s4,s9
ffffffffc0205448:	46a9                	li	a3,10
ffffffffc020544a:	bdcd                	j	ffffffffc020533c <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc020544c:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205450:	4761                	li	a4,24
            err = va_arg(ap, int);
ffffffffc0205452:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0205454:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0205458:	8fb5                	xor	a5,a5,a3
ffffffffc020545a:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020545e:	02d74163          	blt	a4,a3,ffffffffc0205480 <vprintfmt+0x29a>
ffffffffc0205462:	00369793          	slli	a5,a3,0x3
ffffffffc0205466:	97de                	add	a5,a5,s7
ffffffffc0205468:	639c                	ld	a5,0(a5)
ffffffffc020546a:	cb99                	beqz	a5,ffffffffc0205480 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc020546c:	86be                	mv	a3,a5
ffffffffc020546e:	00000617          	auipc	a2,0x0
ffffffffc0205472:	1f260613          	addi	a2,a2,498 # ffffffffc0205660 <etext+0x2c>
ffffffffc0205476:	85a6                	mv	a1,s1
ffffffffc0205478:	854a                	mv	a0,s2
ffffffffc020547a:	0ce000ef          	jal	ra,ffffffffc0205548 <printfmt>
ffffffffc020547e:	b34d                	j	ffffffffc0205220 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0205480:	00002617          	auipc	a2,0x2
ffffffffc0205484:	ff060613          	addi	a2,a2,-16 # ffffffffc0207470 <syscalls+0x120>
ffffffffc0205488:	85a6                	mv	a1,s1
ffffffffc020548a:	854a                	mv	a0,s2
ffffffffc020548c:	0bc000ef          	jal	ra,ffffffffc0205548 <printfmt>
ffffffffc0205490:	bb41                	j	ffffffffc0205220 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0205492:	00002417          	auipc	s0,0x2
ffffffffc0205496:	fd640413          	addi	s0,s0,-42 # ffffffffc0207468 <syscalls+0x118>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020549a:	85e2                	mv	a1,s8
ffffffffc020549c:	8522                	mv	a0,s0
ffffffffc020549e:	e43e                	sd	a5,8(sp)
ffffffffc02054a0:	0e2000ef          	jal	ra,ffffffffc0205582 <strnlen>
ffffffffc02054a4:	40ad8dbb          	subw	s11,s11,a0
ffffffffc02054a8:	01b05b63          	blez	s11,ffffffffc02054be <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc02054ac:	67a2                	ld	a5,8(sp)
ffffffffc02054ae:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02054b2:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc02054b4:	85a6                	mv	a1,s1
ffffffffc02054b6:	8552                	mv	a0,s4
ffffffffc02054b8:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02054ba:	fe0d9ce3          	bnez	s11,ffffffffc02054b2 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02054be:	00044783          	lbu	a5,0(s0)
ffffffffc02054c2:	00140a13          	addi	s4,s0,1
ffffffffc02054c6:	0007851b          	sext.w	a0,a5
ffffffffc02054ca:	d3a5                	beqz	a5,ffffffffc020542a <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02054cc:	05e00413          	li	s0,94
ffffffffc02054d0:	bf39                	j	ffffffffc02053ee <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc02054d2:	000a2403          	lw	s0,0(s4)
ffffffffc02054d6:	b7ad                	j	ffffffffc0205440 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc02054d8:	000a6603          	lwu	a2,0(s4)
ffffffffc02054dc:	46a1                	li	a3,8
ffffffffc02054de:	8a2e                	mv	s4,a1
ffffffffc02054e0:	bdb1                	j	ffffffffc020533c <vprintfmt+0x156>
ffffffffc02054e2:	000a6603          	lwu	a2,0(s4)
ffffffffc02054e6:	46a9                	li	a3,10
ffffffffc02054e8:	8a2e                	mv	s4,a1
ffffffffc02054ea:	bd89                	j	ffffffffc020533c <vprintfmt+0x156>
ffffffffc02054ec:	000a6603          	lwu	a2,0(s4)
ffffffffc02054f0:	46c1                	li	a3,16
ffffffffc02054f2:	8a2e                	mv	s4,a1
ffffffffc02054f4:	b5a1                	j	ffffffffc020533c <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc02054f6:	9902                	jalr	s2
ffffffffc02054f8:	bf09                	j	ffffffffc020540a <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc02054fa:	85a6                	mv	a1,s1
ffffffffc02054fc:	02d00513          	li	a0,45
ffffffffc0205500:	e03e                	sd	a5,0(sp)
ffffffffc0205502:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0205504:	6782                	ld	a5,0(sp)
ffffffffc0205506:	8a66                	mv	s4,s9
ffffffffc0205508:	40800633          	neg	a2,s0
ffffffffc020550c:	46a9                	li	a3,10
ffffffffc020550e:	b53d                	j	ffffffffc020533c <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0205510:	03b05163          	blez	s11,ffffffffc0205532 <vprintfmt+0x34c>
ffffffffc0205514:	02d00693          	li	a3,45
ffffffffc0205518:	f6d79de3          	bne	a5,a3,ffffffffc0205492 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc020551c:	00002417          	auipc	s0,0x2
ffffffffc0205520:	f4c40413          	addi	s0,s0,-180 # ffffffffc0207468 <syscalls+0x118>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205524:	02800793          	li	a5,40
ffffffffc0205528:	02800513          	li	a0,40
ffffffffc020552c:	00140a13          	addi	s4,s0,1
ffffffffc0205530:	bd6d                	j	ffffffffc02053ea <vprintfmt+0x204>
ffffffffc0205532:	00002a17          	auipc	s4,0x2
ffffffffc0205536:	f37a0a13          	addi	s4,s4,-201 # ffffffffc0207469 <syscalls+0x119>
ffffffffc020553a:	02800513          	li	a0,40
ffffffffc020553e:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205542:	05e00413          	li	s0,94
ffffffffc0205546:	b565                	j	ffffffffc02053ee <vprintfmt+0x208>

ffffffffc0205548 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205548:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc020554a:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020554e:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0205550:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205552:	ec06                	sd	ra,24(sp)
ffffffffc0205554:	f83a                	sd	a4,48(sp)
ffffffffc0205556:	fc3e                	sd	a5,56(sp)
ffffffffc0205558:	e0c2                	sd	a6,64(sp)
ffffffffc020555a:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc020555c:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020555e:	c89ff0ef          	jal	ra,ffffffffc02051e6 <vprintfmt>
}
ffffffffc0205562:	60e2                	ld	ra,24(sp)
ffffffffc0205564:	6161                	addi	sp,sp,80
ffffffffc0205566:	8082                	ret

ffffffffc0205568 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0205568:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc020556c:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc020556e:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0205570:	cb81                	beqz	a5,ffffffffc0205580 <strlen+0x18>
        cnt ++;
ffffffffc0205572:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0205574:	00a707b3          	add	a5,a4,a0
ffffffffc0205578:	0007c783          	lbu	a5,0(a5)
ffffffffc020557c:	fbfd                	bnez	a5,ffffffffc0205572 <strlen+0xa>
ffffffffc020557e:	8082                	ret
    }
    return cnt;
}
ffffffffc0205580:	8082                	ret

ffffffffc0205582 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0205582:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0205584:	e589                	bnez	a1,ffffffffc020558e <strnlen+0xc>
ffffffffc0205586:	a811                	j	ffffffffc020559a <strnlen+0x18>
        cnt ++;
ffffffffc0205588:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc020558a:	00f58863          	beq	a1,a5,ffffffffc020559a <strnlen+0x18>
ffffffffc020558e:	00f50733          	add	a4,a0,a5
ffffffffc0205592:	00074703          	lbu	a4,0(a4)
ffffffffc0205596:	fb6d                	bnez	a4,ffffffffc0205588 <strnlen+0x6>
ffffffffc0205598:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc020559a:	852e                	mv	a0,a1
ffffffffc020559c:	8082                	ret

ffffffffc020559e <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc020559e:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc02055a0:	0005c703          	lbu	a4,0(a1)
ffffffffc02055a4:	0785                	addi	a5,a5,1
ffffffffc02055a6:	0585                	addi	a1,a1,1
ffffffffc02055a8:	fee78fa3          	sb	a4,-1(a5)
ffffffffc02055ac:	fb75                	bnez	a4,ffffffffc02055a0 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc02055ae:	8082                	ret

ffffffffc02055b0 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02055b0:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02055b4:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02055b8:	cb89                	beqz	a5,ffffffffc02055ca <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc02055ba:	0505                	addi	a0,a0,1
ffffffffc02055bc:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02055be:	fee789e3          	beq	a5,a4,ffffffffc02055b0 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02055c2:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02055c6:	9d19                	subw	a0,a0,a4
ffffffffc02055c8:	8082                	ret
ffffffffc02055ca:	4501                	li	a0,0
ffffffffc02055cc:	bfed                	j	ffffffffc02055c6 <strcmp+0x16>

ffffffffc02055ce <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02055ce:	c20d                	beqz	a2,ffffffffc02055f0 <strncmp+0x22>
ffffffffc02055d0:	962e                	add	a2,a2,a1
ffffffffc02055d2:	a031                	j	ffffffffc02055de <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc02055d4:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02055d6:	00e79a63          	bne	a5,a4,ffffffffc02055ea <strncmp+0x1c>
ffffffffc02055da:	00b60b63          	beq	a2,a1,ffffffffc02055f0 <strncmp+0x22>
ffffffffc02055de:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc02055e2:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02055e4:	fff5c703          	lbu	a4,-1(a1)
ffffffffc02055e8:	f7f5                	bnez	a5,ffffffffc02055d4 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02055ea:	40e7853b          	subw	a0,a5,a4
}
ffffffffc02055ee:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02055f0:	4501                	li	a0,0
ffffffffc02055f2:	8082                	ret

ffffffffc02055f4 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc02055f4:	00054783          	lbu	a5,0(a0)
ffffffffc02055f8:	c799                	beqz	a5,ffffffffc0205606 <strchr+0x12>
        if (*s == c) {
ffffffffc02055fa:	00f58763          	beq	a1,a5,ffffffffc0205608 <strchr+0x14>
    while (*s != '\0') {
ffffffffc02055fe:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0205602:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0205604:	fbfd                	bnez	a5,ffffffffc02055fa <strchr+0x6>
    }
    return NULL;
ffffffffc0205606:	4501                	li	a0,0
}
ffffffffc0205608:	8082                	ret

ffffffffc020560a <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc020560a:	ca01                	beqz	a2,ffffffffc020561a <memset+0x10>
ffffffffc020560c:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc020560e:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0205610:	0785                	addi	a5,a5,1
ffffffffc0205612:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0205616:	fec79de3          	bne	a5,a2,ffffffffc0205610 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc020561a:	8082                	ret

ffffffffc020561c <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc020561c:	ca19                	beqz	a2,ffffffffc0205632 <memcpy+0x16>
ffffffffc020561e:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0205620:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0205622:	0005c703          	lbu	a4,0(a1)
ffffffffc0205626:	0585                	addi	a1,a1,1
ffffffffc0205628:	0785                	addi	a5,a5,1
ffffffffc020562a:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc020562e:	fec59ae3          	bne	a1,a2,ffffffffc0205622 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0205632:	8082                	ret
